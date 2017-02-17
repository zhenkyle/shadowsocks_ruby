module ShadowsocksRuby
  module Connections
    # Provides various class for a TCP Connection.
    module UDP
      # (see TCP::ClientConnection)
      class ClientConnection < ServerConnection

        # (see TCP::ClientConnection#initialize)
        def initialize protocol_stack, params, backend_protocol_stack, backend_params
          super
        end

        def process_first_packet
          address_bin = packet_protocol.udp_receive_from_client(-1)
          create_plexer(@params[:host], @params[:port], RemoteServerConnection)
          plexer.packet_protocol.udp_send_to_remoteserver address_bin
          class << self
            alias process_hook process_other_packet
          end
        end

        # This is Called by process loop 
        alias process_hook process_first_packet

        def process_other_packet
          data = packet_protocol.udp_receive_from_client(-1)
          plexer.packet_protocol.udp_send_to_remoteserver(data)
        end

        alias udp_receive_from_client async_recv
        alias udp_send_to_client send_data

      end
    end
  end
end