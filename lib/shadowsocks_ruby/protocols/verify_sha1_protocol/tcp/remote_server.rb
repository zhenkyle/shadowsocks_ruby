module ShadowsocksRuby
  module Protocols
    # Origin shadowsocks protocols with One Time Authenticate
    #
    # specification: https://shadowsocks.org/en/spec/protocol.html
    module VerifySha1Protocol
      module TCP
        class RemoteServer
          include BufferHelper

          attr_accessor :next_protocol

          ATYP_IPV4      = 1
          ATYP_DOMAIN    = 3
          ATYP_IPV6      = 4

          # @param [Hash] params                                                           Configuration parameters
          # @option params [Cipher::OpenSSL, Cipher::RbNaCl, Cipher::RC4_MD5] :cipher      a cipher object with IV and a key, +required+
          # @option params [Boolean]                                          :compatible  compatibility with origin mode, default _true_
          def initialize params = {}
            @params = {:compatible => true}.merge(params)
            @cipher = @params[:cipher] or raise ProtocolError, "params[:cipher] is required"
            raise ProtocolError, "cipher object mush have an IV and a key" if @cipher.iv_len == 0 || @cipher.key == nil
            @buffer = ""
            @counter = 0
          end

          def async_recv_first_packet n
            @recv_iv = @next_protocol.async_recv(@cipher.iv_len)
            class << self
              alias async_recv async_recv_other_packet
            end
            async_recv_other_packet n
          end

          alias async_recv async_recv_first_packet

          def async_recv_other_packet n
            @buffer << @cipher.decrypt(@next_protocol.async_recv(-1), @recv_iv)
            async_recv_other_packet_helper n
          end

          def send_data_first_packet data
            data[0] = [0x10 | data.unpack("C").first].pack("C") # set ota flag
            @send_iv = @cipher.random_iv
            hmac = ShadowsocksRuby::Cipher.hmac_sha1_digest(@send_iv + @cipher.key, data)
            @next_protocol.send_data @send_iv + @cipher.encrypt(data + hmac, @send_iv)
            class << self
              alias send_data send_data_other_packet
            end
          end

          alias send_data send_data_first_packet

          def send_data_other_packet data
            data = @cipher.encrypt(data, @send_iv)
            hmac = ShadowsocksRuby::Cipher.hmac_sha1_digest(@send_iv + [@counter].pack("n"), data)
            @next_protocol.send_data [data.length].pack("n") << hmac << data
            @counter += 1
          end

        end
      end
    end
  end
end
