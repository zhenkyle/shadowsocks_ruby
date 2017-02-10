module ShadowsocksRuby
  module Protocols
    # Origin shadowsocks protocols with One Time Authenticate
    #
    # specification: https://shadowsocks.org/en/spec/protocol.html
    class VerifySha1Protocol
      include DummyHelper
      include BufferHelper

      attr_accessor :next_protocol

      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4

      # @param [Hash]                                                     configuration parameters
      # @option params [Cipher::OpenSSL, Cipher::RbNaCl, Cipher::RC4_MD5] :cipher      a cipher object with IV and a key, +required+
      # @option params [Boolean]                                          :compatible  compatibility with origin mode, default _true_
      def initialize params = {}
        @params = {:compatible => true}.merge(params)
        @cipher = @params[:cipher] or raise ProtocolError, "params[:cipher] is required"
        raise ProtocolError, "cipher object mush have an IV and a key" if @cipher.iv_len == 0 || @cipher.key == nil
        @buffer = ""
        @counter = 0
      end

      def tcp_receive_from_remoteserver_first_packet n
        @recv_iv = async_recv(@cipher.iv_len)
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
        data[0] = [0x10 | data.unpack("C").first].pack("C") # set ota flag
        @send_iv = @cipher.random_iv
        hmac = ShadowsocksRuby::Cipher.hmac_sha1_digest(@send_iv + @cipher.key, data)
        send_data @send_iv + @cipher.encrypt(data + hmac, @send_iv)
        class << self
          alias tcp_send_to_remoteserver tcp_send_to_remoteserver_other_packet
        end
      end

      alias tcp_send_to_remoteserver tcp_send_to_remoteserver_first_packet

      def tcp_send_to_remoteserver_other_packet data
        data = @cipher.encrypt(data, @send_iv)
        hmac = ShadowsocksRuby::Cipher.hmac_sha1_digest(@send_iv + [@counter].pack("n"), data)
        send_data [data.length].pack("n") << hmac << data
        @counter += 1
      end

      def tcp_receive_from_localbackend_first_packet n
        class << self
          alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
        end
        data = async_recv(-1) # first packet
        @recv_iv = data.slice!(0, @cipher.iv_len)
        data = @cipher.decrypt(data, @recv_iv)
        @atyp = data.unpack("C")[0]
        if @atyp & 0x10 == 0x10 # OTA mode
          hmac = data[-10, 10]
          raise PharseError, "hmac_sha1 is not correct" \
            unless ShadowsocksRuby::Cipher.hmac_sha1_digest(@recv_iv + @cipher.key, data[0 ... -10]) == hmac
          data[0] = [0x0F & @atyp].pack("C") # clear ota flag
          @buffer << data[0 ... -10]
          tcp_receive_from_localbackend_other_packet_helper n
        else # origin mode
          if @params[:compatible] == false
            raise PharseError, "invalid OTA first packet in strict OTA mode"
          end
          @buffer << data
          tcp_receive_from_localbackend_other_packet_helper n
        end

      end

      alias tcp_receive_from_localbackend tcp_receive_from_localbackend_first_packet

      def tcp_receive_from_localbackend_other_packet n
        if @atyp & 0x10 == 0x10 # OTA mode
          len = async_recv(2).unpack("n").first
          hmac = async_recv(10)
          data = async_recv(len)
          raise PharseError, "hmac_sha1 is not correct" \
            unless ShadowsocksRuby::Cipher.hmac_sha1_digest(@recv_iv + [@counter].pack("n"), data) == hmac
          @buffer << @cipher.decrypt(data, @recv_iv)
          @counter += 1
          tcp_receive_from_localbackend_other_packet_helper n
        else # origin mode
          @buffer << @cipher.decrypt(async_recv(-1), @recv_iv)
          tcp_receive_from_localbackend_other_packet_helper n
        end
      end

      def tcp_send_to_localbackend_first_packet data
        @send_iv = @cipher.random_iv
        send_data @send_iv + @cipher.encrypt(data, @send_iv)
        class << self
          alias tcp_send_to_localbackend tcp_send_to_localbackend_other_packet
        end
      end

      alias tcp_send_to_localbackend tcp_send_to_localbackend_first_packet

      def tcp_send_to_localbackend_other_packet data
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
