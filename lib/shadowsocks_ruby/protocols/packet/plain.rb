module ShadowsocksRuby
  module Protocols
    # Relay data from peer to plexer without any process.
    # This is a packet protocol, so no need to implement @buffer
    class PlainProtocol
      include DummyHelper

      attr_accessor :next_protocol

      # @param [Hash] params                         Configuration parameters
      def initialize params = {}
        @params = {}.merge(params)
      end

      def tcp_receive_from_destination n
        async_recv n
      end

      def tcp_send_to_destination data
        send_data data
      end

      def udp_receive_from_destination n
        async_recv n
      end

      def udp_send_to_destination data
        send_data data
      end

      alias tcp_receive_from_client raise_me
      alias tcp_send_to_client raise_me
      alias tcp_receive_from_remoteserver raise_me
      alias tcp_send_to_remoteserver raise_me
      alias tcp_receive_from_localbackend raise_me
      alias tcp_send_to_localbackend raise_me
      #alias tcp_receive_from_destination raise_me
      #alias tcp_send_to_destination raise_me

      alias udp_receive_from_client raise_me
      alias udp_send_to_client raise_me
      alias udp_receive_from_remoteserver raise_me
      alias udp_send_to_remoteserver raise_me
      alias udp_receive_from_localbackend raise_me
      alias udp_send_to_localbackend raise_me
      #alias udp_receive_from_destination raise_me
      #alias udp_send_to_destination raise_me

    end
  end
end
