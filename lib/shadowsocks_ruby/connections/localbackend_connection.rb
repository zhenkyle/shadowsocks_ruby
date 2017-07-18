module ShadowsocksRuby
  module Connections
    # A LocalBackendConnection's job is relay data from localbackend to destination.
    class LocalBackendConnection < ServerConnection

      def process_first_packet
        address_bin = packet_protocol.async_recv(-1)
        host, port = Util::parse_address_bin(address_bin)
        logger.info('connection') { "connecting #{host}:#{port} from #{peer}" }
        create_plexer(host, port, DestinationConnection)
        class << self
          alias process_hook process_other_packet
        end
      end

      # (see TCP::ClientConnection#process_hook)
      alias process_hook process_first_packet

      def process_other_packet
        data = packet_protocol.async_recv(-1)
        plexer.packet_protocol.send_data(data)
      end

    end
  end
end