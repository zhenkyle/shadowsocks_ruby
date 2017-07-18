module ShadowsocksRuby
  module Protocols
    # SOCKS 5 protocol
    #
    # specification : 
    # * http://tools.ieft.org/html/rfc1928
    # * http://en.wikipedia.org/wiki/SOCKS
    # @note Now only implemented the server side protocol, not the client side protocol.
    module Socks5Protocol
      METHOD_NO_AUTH = 0
      CMD_CONNECT    = 1
      REP_SUCCESS    = 0
      RESERVED       = 0
      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4
      SOCKS5         = 5

      module TCP
        class Client
          attr_accessor :next_protocol

          # @param [Hash] params                         Configuration parameters
          def initialize params = {}
            @params = {}.merge(params)
          end

          def async_recv_first_packet n
            x = @next_protocol
            # check version
            version = x.async_recv(1).unpack("C").first
            if version != SOCKS5
              raise PharseError, "SOCKS version not supported: #{version.inspect}"
            end

            # client handshake v5
            nmethods = x.async_recv(1).unpack("C").first
            *methods = x.async_recv(nmethods).unpack("C*")
            if methods.include?(METHOD_NO_AUTH)
              packet = [SOCKS5, METHOD_NO_AUTH].pack("C*")
              x.send_data packet
            else
              raise PharseError, 'Unsupported authentication method. Only "No Authentication" is supported'
            end

            version, command, reserved = x.async_recv(3).unpack("C3")
            buf =''
            buf << (s = x.async_recv(1))
            address_type = s.unpack("C").first
            case address_type
            when ATYP_IPV4
              buf << x.async_recv(4)
            when ATYP_IPV6
              buf << x.async_recv(16)
            when ATYP_DOMAIN
              buf << (s = x.async_recv(1))
              domain_len = s.unpack("C").first
              buf << x.async_recv(domain_len)
              buf << x.async_recv(2) # port
            else
              raise PharseError, "unknown address_type: #{address_type}"
            end 

            packet = ([SOCKS5, REP_SUCCESS, RESERVED, 1, 0, 0, 0, 0, 0]).pack("C8n")
            x.send_data packet

            class << self
              alias async_recv async_recv_other_packet
            end

            # first packet is special:
            # ATYP + Destination Address + Destination Port
            buf        
          end

          alias async_recv async_recv_first_packet

          def async_recv_other_packet n
            @next_protocol.async_recv n
          end

          def send_data data
            @next_protocol.send_data data
          end

        end
      end
    end
  end
end
