module ShadowsocksRuby
  module Protocols

    # To be used with protocols without an IV, like {Cipher::Table}
    class NoIvCipherProtocol
      include DummyHelper

      attr_accessor :next_protocol

      # @param [Hash]                                                     configuration parameters
      # @option params [Cipher::Table] :cipher                            a cipher object without IV,  +required+
      def initialize params = {}
        @cipher = params[:cipher] or raise ProtocolError, "params[:cipher] is required"
      end

      def tcp_receive_from_remoteserver n
        @cipher.decrypt(async_recv n)
      end

      def tcp_send_to_remoteserver data
        send_data(@cipher.encrypt data)
      end

      def tcp_receive_from_localbackend n
        @cipher.decrypt(async_recv n)
      end

      def tcp_send_to_localbackend data
        send_data(@cipher.encrypt data)
      end

      private

      alias tcp_receive_from_client raise_me
      alias tcp_send_to_client raise_me
      #alias tcp_receive_from_remoteserver raise_me
      #alias tcp_send_to_remoteserver raise_me
      #alias tcp_receive_from_localbackend raise_me
      #alias tcp_send_to_localbackend raise_me
      alias tcp_receive_from_destination raise_me
      alias tcp_send_to_destination raise_me

      alias udp_receive_from_client raise_me
      alias udp_send_to_client raise_me
      alias udp_receive_from_remoteserver raise_me
      alias udp_send_to_remoteserver raise_me
      alias udp_receive_from_localbackend raise_me
      alias udp_send_to_localbackend raise_me
      alias udp_receive_from_destination raise_me
      alias udp_send_to_destination raise_me
    end
  end
end
