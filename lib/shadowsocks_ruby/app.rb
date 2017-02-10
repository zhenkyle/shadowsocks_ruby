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
    attr_reader :logger

    @@options = {}
    
    def self.options= options
      @@options = options
    end

    def initialize
      @options = @@options

      @logger = Logger.new(STDOUT).tap do |log|
      
        if options[:__server]
          log.progname = "ssserver-ruby"
        elsif options[:__client]
          log.progname = "sslocal-ruby"
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

    def run!
      if options[:__server]
        start_server
      elsif options[:__client]
        start_client
      end
    #rescue Exception => e
    #  logger.fatal { e.message + "\n" + e.backtrace.join("\n")}
    end

    def trap_signals
      STDOUT.sync = true
      STDERR.sync = true
       trap('QUIT') do
        self.fast_shutdown('QUIT')
      end
      trap('TERM') do
        self.fast_shutdown('TERM')
      end
      trap('INT') do
        self.fast_shutdown('INT')
      end
    end

    # TODO: next_tick can't be called from trap context
    def graceful_shutdown(signal)
      EventMachine.stop_server(@server) if @server
      Thread.new{ logger.info "Received #{signal} signal. No longer accepting new connections." }
      Thread.new{ logger.info "Waiting for #{EventMachine.connection_count} connections to finish." }
      @server = nil
      graceful_shutdown_check
    end

    # TODO: next_tick can't be called from trap context
    def graceful_shutdown_check
      EventMachine.next_tick do
        count = EventMachine.connection_count
        if count == 0
          EventMachine.stop_event_loop
        else
          @wait_count ||= count
          Thread.new{ logger.info "Waiting for #{EventMachine.connection_count} connections to finish." if @wait_count != count }
          EventMachine.next_tick self.method(:graceful_shutdown_check)
        end
      end
    end

    # TODO: where does EventMachine.connection_count come from?
    def fast_shutdown(signal)
      EventMachine.stop_server(@server) if @server
      Thread.new{ logger.info "Received #{signal} signal. No longer accepting new connections." }
      Thread.new{ logger.info "Maximum time to wait for connections is #{MAX_FAST_SHUTDOWN_SECONDS} seconds." }
      Thread.new{ logger.info "Waiting for #{EventMachine.connection_count} connections to finish." }
      @server = nil
      EventMachine.stop_event_loop
      #EventMachine.stop_event_loop if EventMachine.connection_count == 0
      #Thread.new do
      #  sleep MAX_FAST_SHUTDOWN_SECONDS
      #  $kernel.exit!
      #end
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
        {},
        stack4,
        {}
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
        {:host => options[:server], :port => options[:port]},
        stack2,
        {}
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
        logger.info "server started"
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
      when "http_simple"
        ["http_simple", {:host => options[:server], :port => options[:port], :obfs_param => options[:obfs_param]}]
      when "http_simple_strict"
        ["http_simple", {:host => options[:server], :port => options[:port], :obfs_param => options[:obfs_param], :compatible => false}]
      when "tls_ticket"
        ["tls_ticket", {:host => options[:server], :obfs_param => options[:obfs_param]}]
      when "tls_ticket_strict"
        ["tls_ticket", {:host => options[:server], :obfs_param => options[:obfs_param], :compatible => false}]
      else
        raise AppError, "no such protocol: #{options[:obfs_name]}"
      end
    end

  end
end