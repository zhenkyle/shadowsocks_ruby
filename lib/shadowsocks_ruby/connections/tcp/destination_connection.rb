module ShadowsocksRuby
  module Connections
    module TCP
      # (see TCP::ClientConnection)
      module DestinationConnection
        include ShadowsocksRuby::Connections::Connection
        include ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          #plexer.packet_protocol.tcp_send_to_localbackend(packet_protocol.tcp_receive_from_destination(-1))
          data = packet_protocol.tcp_receive_from_destination(-1)
          plexer.packet_protocol.tcp_send_to_localbackend(data)
        end

      end
    end
  end
end