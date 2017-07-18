module ShadowsocksRuby
  module Connections
    # A ClientConnection's job is relay data from client to remoteserver.
    class ClientConnection < ServerConnection
      # (see ServerConnection#initialize)
      # @option params [String]                :host  shadowsocks server address, required
      # @option params [Integer]               :port  shadowsocks server port, required
      def initialize protocol_stack, params, backend_protocol_stack, backend_params
        super
      end

      def process_first_packet
        address_bin = packet_protocol.async_recv(-1)
        host, port = Util::parse_address_bin(address_bin)
        logger.info('connection') { "connecting #{host}:#{port} from #{peer}" }
        create_plexer(@params[:host], @params[:port], RemoteServerConnection)
        plexer.packet_protocol.send_data address_bin
        class << self
          alias process_hook process_other_packet
        end
      end

      # This is Called by process loop 
      alias process_hook process_first_packet

      def process_other_packet
        data = packet_protocol.async_recv(-1)
        plexer.packet_protocol.send_data(data)
      end

    end
  end
end