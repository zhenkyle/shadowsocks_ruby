require 'ipaddr'

module ShadowsocksRuby
  module Protocols
    # SOCKS 5 protocol
    #
    # specification : 
    # * http://tools.ieft.org/html/rfc1928
    # * http://en.wikipedia.org/wiki/SOCKS
    # @note Now only implemented the server side protocol, not the client side protocol.
    class Socks5Protocol
      include DummyHelper

      attr_accessor :next_protocol

      METHOD_NO_AUTH = 0
      CMD_CONNECT    = 1
      REP_SUCCESS    = 0
      RESERVED       = 0
      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4
      SOCKS5         = 5

      # @param [Hash] params                         Configuration parameters
      def initialize params = {}
        @params = {}.merge(params)
      end

      def tcp_receive_from_client_first_packet n
        # check version
        version = async_recv(1).unpack("C").first
        if version != SOCKS5
          raise PharseError, "SOCKS version not supported: #{version.inspect}"
        end

        # client handshake v5
        nmethods = async_recv(1).unpack("C").first
        *methods = async_recv(nmethods).unpack("C*")
        if methods.include?(METHOD_NO_AUTH)
          packet = [SOCKS5, METHOD_NO_AUTH].pack("C*")
          send_data packet
        else
          raise PharseError, 'Unsupported authentication method. Only "No Authentication" is supported'
        end

        version, command, reserved = async_recv(3).unpack("C3")
        buf =''
        buf << (s = async_recv(1))
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

        packet = ([SOCKS5, REP_SUCCESS, RESERVED, 1, 0, 0, 0, 0, 0]).pack("C8n")
        send_data packet
        class << self
          alias tcp_receive_from_client tcp_receive_from_client_other_packet
        end

        # first packet is special:
        # ATYP + Destination Address + Destination Port
        buf        
      end

      alias tcp_receive_from_client tcp_receive_from_client_first_packet

      def tcp_receive_from_client_other_packet n
        async_recv(n)
      end

      def tcp_send_to_client data
        send_data data
      end

      def tcp_receive_from_localbackend_first_packet n
        # check version
        version = async_recv(1).unpack("C").first
        if version != SOCKS5
          raise PharseError, "SOCKS version not supported: #{version.inspect}"
        end

        # client handshake v5
        nmethods = async_recv(1).unpack("C").first
        *methods = async_recv(nmethods).unpack("C*")
        if methods.include?(METHOD_NO_AUTH)
          packet = [SOCKS5, METHOD_NO_AUTH].pack("C*")
          send_data packet
        else
          raise PharseError, 'Unsupported authentication method. Only "No Authentication" is supported'
        end

        version, command, reserved = async_recv(3).unpack("C3")
        buf =''
        buf << (s = async_recv(1))
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

        packet = ([SOCKS5, REP_SUCCESS, RESERVED, 1, 0, 0, 0, 0, 0]).pack("C8n")
        send_data packet

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

      #alias tcp_receive_from_client raise_me
      #alias tcp_send_to_client raise_me
      alias tcp_receive_from_remoteserver raise_me
      alias tcp_send_to_remoteserver raise_me
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