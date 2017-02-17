module ShadowsocksRuby
  module Connections
    module TCP
      # A LocalBackendConnection's job is relay data from localbackend to destination.
      class LocalBackendConnection < ShadowsocksRuby::Connections::ServerConnection

        def process_first_packet
          address_bin = packet_protocol.tcp_receive_from_localbackend(-1)
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
          data = packet_protocol.tcp_receive_from_localbackend(-1)
          plexer.packet_protocol.tcp_send_to_destination(data)
        end

        alias tcp_receive_from_localbackend async_recv
        alias tcp_send_to_localbackend send_data

      end
    end
  end
end