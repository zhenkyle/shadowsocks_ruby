module ShadowsocksRuby
  module Connections
    module UDP
      # (see TCP::ClientConnection)
      module RemoteServerConnection
        include ShadowsocksRuby::Connections::Connection
        include ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          data = packet_protocol.udp_receive_from_remoteserver(-1)
          plexer.packet_protocol.udp_send_to_client(data)
        end

      end
    end
  end
end