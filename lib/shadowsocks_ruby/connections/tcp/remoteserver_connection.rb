module ShadowsocksRuby
  module Connections
    module TCP
      # A RemoteServerConnection's job is relay data from remoteserver to client.
      class RemoteServerConnection < ShadowsocksRuby::Connections::BackendConnection

        # (see TCP::ClientConnection#process_hook)
        def process_hook
          data = packet_protocol.tcp_receive_from_remoteserver(-1)
          plexer.packet_protocol.tcp_send_to_client(data)
        end

        alias tcp_receive_from_remoteserver async_recv
        alias tcp_send_to_remoteserver send_data

      end
    end
  end
end