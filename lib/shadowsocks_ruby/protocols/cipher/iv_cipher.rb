module ShadowsocksRuby
  module Protocols

    # To be used with any cipher methods with an IV, like {Cipher::OpenSSL},
    # {Cipher::RbNaCl} and {Cipher::RC4_MD5}.
    class IvCipherProtocol
      include DummyHelper
      include BufferHelper

      attr_accessor :next_protocol

      # @param [Hash] params                                                           Configuration parameters
      # @option params [Cipher::OpenSSL, Cipher::RbNaCl, Cipher::RC4_MD5] :cipher      a cipher object with IV and a key, +required+
      def initialize params = {}
        @cipher = params[:cipher] or raise ProtocolError, "params[:cipher] is required"
        @buffer =""
      end

      def tcp_receive_from_remoteserver_first_packet n
        iv_len = @cipher.iv_len
        @recv_iv = async_recv iv_len
        class << self
          alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_other_packet
        end
        tcp_receive_from_remoteserver_other_packet n
      end

      alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_first_packet

      def tcp_receive_from_remoteserver_other_packet n
        @buffer << @cipher.decrypt(async_recv(-1), @recv_iv)
        tcp_receive_from_remoteserver_other_packet_helper n
      end

      def tcp_send_to_remoteserver_first_packet data
        send_first_packet_process data
        class << self
          alias tcp_send_to_remoteserver send_other_packet
        end
      end

      alias tcp_send_to_remoteserver tcp_send_to_remoteserver_first_packet

      def tcp_receive_from_localbackend_first_packet n
        iv_len = @cipher.iv_len
        @recv_iv = async_recv iv_len
        class << self
          alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
        end
        tcp_receive_from_localbackend_other_packet n
      end

      alias tcp_receive_from_localbackend tcp_receive_from_localbackend_first_packet

      def tcp_receive_from_localbackend_other_packet n
        @buffer << @cipher.decrypt(async_recv(-1), @recv_iv)
        tcp_receive_from_localbackend_other_packet_helper n
      end

      def tcp_send_to_localbackend_first_packet data
        send_first_packet_process data
        class << self
          alias tcp_send_to_localbackend send_other_packet
        end
      end

      alias tcp_send_to_localbackend tcp_send_to_localbackend_first_packet


      def send_first_packet_process data
        @send_iv = @cipher.random_iv
        send_data @send_iv + @cipher.encrypt(data, @send_iv)
      end

      def send_other_packet data
        send_data @cipher.encrypt(data, @send_iv)
      end

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
