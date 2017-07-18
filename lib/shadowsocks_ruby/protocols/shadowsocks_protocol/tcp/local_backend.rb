module ShadowsocksRuby
  module Protocols
    # Shadowsocks packet protocol for both origin shadowsocks protocol and OTA shadowsocks protocol.
    #
    # specification: 
    # * https://shadowsocks.org/en/spec/protocol.html
    # * https://shadowsocks.org/en/spec/one-time-auth.html
    #
    # This is a packet protocol, so no need to implement @buffer
    module ShadowsocksProtocol
      ATYP_IPV4      = 1
      ATYP_DOMAIN    = 3
      ATYP_IPV6      = 4

      module TCP
        class LocalBackend
          attr_accessor :next_protocol


          # @param [Hash] params                         Configuration parameters
          def initialize params = {}
            @params = {}.merge(params)
          end

          def async_recv_first_packet n
            buf = ""
            s = @next_protocol.async_recv(1)
            buf << s
            address_type = s.unpack("C").first
            case address_type
            when ATYP_IPV4
              buf << @next_protocol.async_recv(4)
            when ATYP_IPV6
              buf << @next_protocol.async_recv(16)
            when ATYP_DOMAIN
              buf << (s = @next_protocol.async_recv(1))
              domain_len = s.unpack("C").first
              buf << @next_protocol.async_recv(domain_len)
              buf << @next_protocol.async_recv(2) # port
            else
              raise PharseError, "unknown address_type: #{address_type}"
            end 

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
