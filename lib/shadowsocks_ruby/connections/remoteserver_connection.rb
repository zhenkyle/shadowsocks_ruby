module ShadowsocksRuby
  module Connections
    # A RemoteServerConnection's job is relay data from remoteserver to client.
    class RemoteServerConnection < BackendConnection

      # (see TCP::ClientConnection#process_hook)
      def process_hook
        data = packet_protocol.async_recv(-1)
        plexer.packet_protocol.send_data(data)
      end

    end
  end
end