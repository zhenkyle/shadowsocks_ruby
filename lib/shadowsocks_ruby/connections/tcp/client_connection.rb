module ShadowsocksRuby
  module Connections
    # Provides various functionality code of a TCP Connection.
    #
    # @example
    #     class DummyConnection < EventMachine::Connection
    #       include ShadowsocksRuby::Connections::TCP::ClientConnection
    #     end
    #     # some how get a DummyConnection object
    #     # dummy_connection = ...
    #     # dummy_connection.plexer_protocol.tcp_process_client will be called looply
    module TCP
      # Mixed-in with an EventMachine::Connection Object to use this.
      module ClientConnection
        include ShadowsocksRuby::Connections::Connection
        include ShadowsocksRuby::Connections::ServerConnection
        # (see ServerConnection#initialize)
        # @option params [String]                :host  shadowsocks server address, required
        # @option params [Integer]                :port  shadowsocks server port, required
        def initialize protocol_stack, params, backend_protocol_stack, backend_params
          super
        end

        def process_first_packet
          address_bin = packet_protocol.tcp_receive_from_client(-1)
          create_plexer(@params[:host], @params[:port], RemoteServerConnection)
          plexer.packet_protocol.tcp_send_to_remoteserver address_bin
          class << self
            alias process_hook process_other_packet
          end
        end

        # This is Called by process loop 
        alias process_hook process_first_packet

        def process_other_packet
          data = packet_protocol.tcp_receive_from_client(-1)
          plexer.packet_protocol.tcp_send_to_remoteserver(data)
        end
      end
    end
  end
end