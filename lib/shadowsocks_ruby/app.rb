require 'fileutils'
require 'singleton'
require 'socket'
require 'json'
require 'einhorn'

module ShadowsocksRuby
  # App is a singleton object which provide either Shadowsocks Client functionality
  # or Shadowsocks Server functionality. One App startup one EventMachine event loop
  # on one Native Thread / CPU core.
  # 
  # Because Ruby MRI has a GIL, it is unable to utilize execution parallelism on
  # multi-core CPU.
  # However, one can use a shared socket manager to spin off a few Apps that can be
  # executed parallelly and let the Kernel to do the load balance things.
  #
  # A few things noticeable when using a shared socket manager:
  # * At present, only {https://github.com/stripe/einhorn Einhorn socket manager} are supported.
  #   systemd shared socket manager support is in the plan.
  #
  # * At present, using socket manager could cause TLS1.2 obsfucation protocol's 
  #   replay attact detection malfunctions, because every process have it's own 
  #   copy of LRUCache. 
  #
  # * Shared socket manager does not work on Windows
  #

  class App
    include Singleton

    MAX_FAST_SHUTDOWN_SECONDS = 10

    attr_reader :options
    attr_accessor :logger

    @@options = {}
    
    def self.options= options
      @@options = options
    end

    def initialize
      @options = @@options

      @totalcounter = 0
      @maxcounter = 0
      @counter = 0
      if options[:__server]
        name = "ssserver-ruby"
        host = options[:server]
        port = options[:port]
      elsif options[:__client]
        name = "sslocal-ruby"
        host = options[:local_addr]
        port = options[:local_port]
      end
      @name = name
      @listen = "#{host}:#{port}"

      update_procline


      @logger = Logger.new(STDOUT).tap do |log|
        log.datetime_format = '%Y-%m-%d %H:%M:%S '
        if options[:__server]
          log.progname = "ssserver"
        elsif options[:__client]
          log.progname = "sslocal"
        end

        if options[:verbose]
          log.level = Logger::DEBUG 
        elsif options[:quiet]
          log.level = Logger::WARN 
        else
          log.level = Logger::INFO
        end
      end

    end

    def update_procline
      $0 = "shadowsocks_ruby #{VERSION} - #{@name} #{@listen} - #{stats} cur/max/tot conns"
    end

    def stats
      "#{@counter}/#{@maxcounter}/#{@totalcounter}"
    end

    def incr
      @totalcounter += 1
      @counter += 1
      @maxcounter = @counter if @counter > @maxcounter
      update_procline
      @counter
    end

    def decr
      @counter -= 1
      @server ||= nil # quick fix for warning in connection unit test
      if @server.nil?
        logger.info "Waiting for #{@counter} connections to finish."
      end
      update_procline
      EventMachine.stop_event_loop if @server.nil? and @counter == 0
      @counter
    end

    def run!
      if options[:__server]
        start_server
      elsif options[:__client]
        start_client
      end
    rescue => e
      logger.fatal e
    end


    def trap_signals
      STDOUT.sync = true
      STDERR.sync = true
      Signal.trap('QUIT') do
        graceful_shutdown('QUIT')
      end
      Signal.trap('TERM') do
        fast_shutdown('TERM')
      end
      Signal.trap('INT') do
        fast_shutdown('INT')
      end
    end

    def graceful_shutdown(signal)
      EventMachine.stop_server(@server) if @server
      threads = []
      threads << Thread.new{ logger.info "Received #{signal} signal. No longer accepting new connections." }
      threads << Thread.new{ logger.info "Waiting for #{@counter} connections to finish." }
      threads.each { |thr| thr.join }
      @server = nil
      EventMachine.stop_event_loop if @counter == 0
    end

    def fast_shutdown(signal)
      EventMachine.stop_server(@server) if @server
      threads = []
      threads << Thread.new{ logger.info "Received #{signal} signal. No longer accepting new connections." }
      threads << Thread.new{ logger.info "Maximum time to wait for connections is #{MAX_FAST_SHUTDOWN_SECONDS} seconds." }
      threads << Thread.new{ logger.info "Waiting for #{@counter} connections to finish." }
      threads.each { |thr| thr.join }
      @server = nil
      EventMachine.stop_event_loop if @counter == 0
      Thread.new do
        sleep MAX_FAST_SHUTDOWN_SECONDS
        $kernel.exit!
      end
    end
    

    def start_server
      stack3 = Protocols::ProtocolStack.new([
        get_packet_protocol,
        get_cipher_protocol,
        get_obfs_protocol
      ].compact, options[:cipher_name], options[:password])

      stack4 = Protocols::ProtocolStack.new([
        ["plain", {}]
      ], options[:cipher_name], options[:password])

      server_args = [
        stack3,
        {:timeout => options[:timeout]},
        stack4,
        {:timeout => options[:timeout]}
      ]

      start_em options[:server], options[:port], Connections::TCP::LocalBackendConnection, server_args
    end

    def start_client
      stack1 = Protocols::ProtocolStack.new([
          ["socks5", {}]
      ], options[:cipher_name], options[:password])

      stack2 = Protocols::ProtocolStack.new([
        get_packet_protocol,
        get_cipher_protocol,
        get_obfs_protocol
      ].compact, options[:cipher_name], options[:password])

      local_args = [
        stack1,
        {:host => options[:server], :port => options[:port], :timeout => options[:timeout]},
        stack2,
        {:timeout => options[:timeout]}
      ]

      start_em options[:local_addr], options[:local_port], Connections::TCP::ClientConnection, local_args
    end

    def start_em host, port, klass_server, server_args
      EventMachine.epoll

      EventMachine.run do
        if options[:einhorn] != true
          @server = EventMachine.start_server(host, port, klass_server, *server_args)
        else
          fd_num = Einhorn::Worker.socket!
          socket = Socket.for_fd(fd_num)

          @server = EventMachine.attach_server(socket, klass_server, *server_args)
        end
        logger.info "Listening on #{host}:#{port}"
        logger.info "Send QUIT to quit after waiting for all connections to finish."
        logger.info "Send TERM or INT to quit after waiting for up to #{MAX_FAST_SHUTDOWN_SECONDS} seconds for connections to finish."

        trap_signals
      end
    end

    def get_packet_protocol
      case options[:packet_name]
      when "origin", "verify_sha1", "verify_sha1_strict"
        ["shadowsocks", {}]
      else
        raise AppError, "no such protocol: #{options[:packet_name]}"
      end
    end

    def get_cipher_protocol
      if options[:cipher_name] == nil ||  options[:cipher_name] == "none"
        return nil
      end
      case options[:cipher_name]
      when "table"
        ["no_iv_cipher", {}]
      else
        case options[:packet_name]
        when "origin"
          ["iv_cipher", {}]
        when "verify_sha1"
          ["verify_sha1", {}]
        when "verify_sha1_strict"
          ["verify_sha1", {:compatible => false}]
        end
      end
    end

    def get_obfs_protocol
      if options[:obfs_name] == nil
        return nil
      end
      case options[:obfs_name]
      when "http_simple", "http_simple_compatible"
        ["http_simple", {:host => options[:server], :port => options[:port], :obfs_param => options[:obfs_param]}]
      when "http_simple_strict"
        ["http_simple", {:host => options[:server], :port => options[:port], :obfs_param => options[:obfs_param], :compatible => false}]
      when "tls1.2_ticket_auth", "tls1.2_ticket_auth_compatible"
        ["tls_ticket", {:host => options[:server], :obfs_param => options[:obfs_param]}]
      when "tls1.2_ticket_auth_strict"
        ["tls_ticket", {:host => options[:server], :obfs_param => options[:obfs_param], :compatible => false}]
      else
        raise AppError, "no such protocol: #{options[:obfs_name]}"
      end
    end

  end
end