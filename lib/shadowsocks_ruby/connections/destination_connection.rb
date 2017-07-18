module ShadowsocksRuby
  module Connections
    # A DestinationConnection's job is relay data from destination to localbackend.
    class DestinationConnection < BackendConnection

      # (see TCP::ClientConnection#process_hook)
      def process_hook
        #plexer.packet_protocol.tcp_send_to_localbackend(packet_protocol.tcp_receive_from_destination(-1))
        data = packet_protocol.async_recv(-1)
        plexer.packet_protocol.send_data(data)
      end

    end
  end
end