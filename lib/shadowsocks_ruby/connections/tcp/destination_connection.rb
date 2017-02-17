module ShadowsocksRuby
  module Connections
    module TCP
      # A DestinationConnection's job is relay data from destination to localbackend.
      class DestinationConnection < ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          #plexer.packet_protocol.tcp_send_to_localbackend(packet_protocol.tcp_receive_from_destination(-1))
          data = packet_protocol.tcp_receive_from_destination(-1)
          plexer.packet_protocol.tcp_send_to_localbackend(data)
        end

        alias tcp_receive_from_destination async_recv
        alias tcp_send_to_destination send_data

      end
    end
  end
end