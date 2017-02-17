module ShadowsocksRuby
  module Connections
    module UDP
      # (see TCP::DestinationConnection)
      class DestinationConnection < ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          data = packet_protocol.udp_receive_from_destination(-1)
          plexer.packet_protocol.udp_send_to_localbackend(data)
        end

        alias udp_receive_from_destination async_recv
        alias udp_send_to_destination send_data

      end
    end
  end
end