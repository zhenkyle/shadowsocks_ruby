require 'optparse'

module ShadowsocksRuby
  module Cli
    class SslocalRunner
      def initialize(argv = ARGV, stdin = $stdin, stdout = $stdout, stderr = $stderr, kernel = Kernel)
        @argv   = argv
        $kernel = kernel
        $stdin  = stdin
        $stdout = stdout
        $stderr = stderr
      end

      def execute!
        # here sets default options
        options        = {
                           :port => 8388,
                           :local_addr => '0.0.0.0',
                           :local_port => 1080,
                           :packet_name => 'origin',
                           :cipher_name => 'aes-256-cfb',
                           :timeout => 300
                         }
        lazy_default   = {
                           :config => 'config.json',
                           :obfs_name => 'http_simple'
                         }

        version        = ShadowsocksRuby::VERSION
        config_help    = "path to config file (lazy default: #{lazy_default[:config]})"
        server_addr_help    = "server address"
        server_port_help = "server port (default: #{options[:port]})"
        local_addr_help = "local binding address (default: #{options[:local_addr]})"
        local_port_help = "local port  (default: default: #{options[:local_port]})"
        password_help = "password"
        packet_protocol_help = "packet protocol (default: #{options[:packet_name]})"
        packet_param_help = "packet protocol parameters"
        cipher_help = "cipher protocol (default: #{options[:cipher_name]})"
        obfs_protocol_help = "obfuscate protocol (lazy default: #{lazy_default[:obfs_name]})"
        obfs_param_help = "obfuscate protocol parameters"
        timeout_help = "timeout in seconds, default: #{options[:timeout]}"
        fast_open_help = "use TCP_FASTOPEN, requires Linux 3.7+"
        einhorn_help = "Use Einhorn socket manager"

        help_help = "display help message"
        version_help = "show version information"
        verbose_help = "verbose mode"
        quiet_help = "quiet mode, only show warnings/errors"
        get_help = "run #{File.basename($0)} -h to get help"

        option_parser = OptionParser.new do |op|

          op.banner =  "A SOCKS like tunnel proxy that helps you bypass firewalls."
          op.separator ""
          op.separator "Usage: #{File.basename($0)} [options]"
          op.separator ""

          op.separator "Proxy options:"
          op.on("-c", "--config [CONFIG]", config_help) { |value| options[:config] = value }
          op.on("-s", "--server SERVER_ADDR", server_addr_help)   { |value| options[:server] = value }
          op.on("-p", "--port SERVER_PORT", server_port_help)   { |value| options[:port] = value.to_i }
          op.on("-b", "--bind_addr LOCAL_ADDR", local_addr_help)   { |value| options[:local_addr] = value }
          op.on("-l", "--local_port LOCAL_PORT", local_port_help)   { |value| options[:local_port] = value.to_i }
          op.on("-k", "--password PASSWORD", password_help)   { |value| options[:password] = value }
          op.on("-O", "--packet-protocol NAME", packet_protocol_help)   { |value| options[:packet_name] = value }
          op.on("-G", "--packet-param PARAM", packet_param_help)   { |value| options[:packet_param] = value }
          op.on("-m", "--cipher-protocol NAME", cipher_help)   { |value| options[:cipher_name] = value }
          op.on("-o", "--obfs-protocol [NAME]", obfs_protocol_help)   { |value| options[:obfs_name] = value }
          op.on("-g", "--obfs-param PARAM", obfs_param_help)   { |value| options[:obfs_param] = value }
          op.on("-t", "--timeout TIMEOUT", timeout_help)   { |value| options[:timeout] = value.to_i }
          op.on(      "--fast-open", fast_open_help)   { |value| options[:tcp_fast_open] = value }
          op.on('-E', '--einhorn', einhorn_help) { |value| @options[:einhorn] = true }
          op.separator ""

          op.separator "Common options:"
          op.on("-h", "--help", help_help)    { puts op.to_s; $kernel.exit }
          op.on("-v", "--vv", verbose_help) { options[:verbose]   = true }
          op.on("-q", "--qq", quiet_help) { options[:quiet]   = true }
          op.on(      "--version", version_help) { puts version; $kernel.exit }
          op.separator ""

        end

        begin
          option_parser.parse!(@argv)
        rescue OptionParser::MissingArgument => e
          $kernel.abort("#{e.message}\n#{get_help}")
        end

        if options.include?(:config)
          options[:config] = 'config.json' if options[:config] == nil
          config_options = {}
          begin
            open(options[:config], 'r') do |f|
            config_options = JSON.load(f, nil, {:symbolize_names => true})
            end
          rescue Errno::ENOENT
            $kernel.abort("#{options[:config]} doesn't exists")
          rescue JSON::ParserError
            $kernel.abort("#{options[:config]} parse error")
          end
          options = config_options.merge(options)
        end

        if options.include?(:obfs_name)
          options[:obfs_name] = lazy_default[:obfs_name] if options[:obfs_name] == nil
        end

        if !options.include?(:password)
          $kernel.abort("--password is required\n#{get_help}")
        end

        if !options.include?(:server)
          $kernel.abort("--server is required\n#{get_help}")
        end


        options[:__client] = true

        App.options = options
        App.instance.run!
      end
    end
  end
end