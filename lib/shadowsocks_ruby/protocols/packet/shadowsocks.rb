module ShadowsocksRuby
  module Protocols
    # Shadowsocks packet protocol for both origin shadowsocks protocol and OTA shadowsocks protocol.
    #
    # specification: 
    # * https://shadowsocks.org/en/spec/protocol.html
    # * https://shadowsocks.org/en/spec/one-time-auth.html
    #
    # This is a packet protocol, so no need to implement @buffer
    class ShadowsocksProtocol
      include DummyHelper

      attr_accessor :next_protocol

      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4

      # @param [Hash] params                         Configuration parameters
      def initialize params = {}
      end

      def tcp_receive_from_localbackend_first_packet n
        buf = ""
        s = async_recv(1)
        buf << s
        address_type = s.unpack("C").first
        case address_type
        when ATYP_IPV4
          buf << async_recv(4)
        when ATYP_IPV6
          buf << async_recv(16)
        when ATYP_DOMAIN
          buf << (s = async_recv(1))
          domain_len = s.unpack("C").first
          buf << async_recv(domain_len)
          buf << async_recv(2) # port
        else
          raise PharseError, "unknown address_type: #{address_type}"
        end 

        class << self
          alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
        end
        # first packet is special:
        # ATYP + Destination Address + Destination Port
        buf
      end

      alias tcp_receive_from_localbackend tcp_receive_from_localbackend_first_packet

      def tcp_receive_from_localbackend_other_packet n
        async_recv(n)
      end

      def tcp_send_to_localbackend data
        send_data data
      end

      def tcp_receive_from_remoteserver n
        async_recv(n)
      end

      def tcp_send_to_remoteserver data
        send_data data
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
