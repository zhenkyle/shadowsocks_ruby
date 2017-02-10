module ShadowsocksRuby
  module Connections
    # Provides various functionality code of a UDP Connection.
    #
    # @example
    #     class DummyConnection < EventMachine::Connection
    #       include ShadowsocksRuby::Connections::UDP::ClientConnection
    #     end
    #     # some how get a DummyConnection object
    #     # dummy_connection = ...
    #     # dummy_connection.plexer_protocol.udp_process_client will be called looply
    module UDP
      # (see TCP::ClientConnection)
      module ClientConnection
        include ShadowsocksRuby::Connections::Connection
        include ShadowsocksRuby::Connections::ServerConnection

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

      end
    end
  end
end