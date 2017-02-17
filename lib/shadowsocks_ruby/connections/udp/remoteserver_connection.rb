module ShadowsocksRuby
  module Connections
    module UDP
      # (see TCP::RemoteServerConnection)
      class RemoteServerConnection < ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          data = packet_protocol.udp_receive_from_remoteserver(-1)
          plexer.packet_protocol.udp_send_to_client(data)
        end

        alias udp_receive_from_remoteserver async_recv
        alias udp_send_to_remoteserver send_data

      end
    end
  end
end