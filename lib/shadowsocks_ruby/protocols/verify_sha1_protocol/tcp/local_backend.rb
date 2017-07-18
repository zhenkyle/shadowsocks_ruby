module ShadowsocksRuby
  module Protocols
    # Origin shadowsocks protocols with One Time Authenticate
    #
    # specification: https://shadowsocks.org/en/spec/protocol.html
    module VerifySha1Protocol
      module TCP
        class LocalBackend
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
            class << self
              alias async_recv async_recv_other_packet
            end
            data = @next_protocol.async_recv(-1) # first packet
            @recv_iv = data.slice!(0, @cipher.iv_len)
            data = @cipher.decrypt(data, @recv_iv)
            @atyp = data.unpack("C")[0]
            if @atyp & 0x10 == 0x10 # OTA mode
              hmac = data[-10, 10]
              raise PharseError, "hmac_sha1 is not correct" \
                unless ShadowsocksRuby::Cipher.hmac_sha1_digest(@recv_iv + @cipher.key, data[0 ... -10]) == hmac
              data[0] = [0x0F & @atyp].pack("C") # clear ota flag
              @buffer << data[0 ... -10]
              async_recv_other_packet_helper n
            else # origin mode
              if @params[:compatible] == false
                raise PharseError, "invalid OTA first packet in strict OTA mode"
              end
              @buffer << data
              async_recv_other_packet_helper n
            end

          end

          alias async_recv async_recv_first_packet

          def async_recv_other_packet n
            if @atyp & 0x10 == 0x10 # OTA mode
              len = @next_protocol.async_recv(2).unpack("n").first
              hmac = @next_protocol.async_recv(10)
              data = @next_protocol.async_recv(len)
              raise PharseError, "hmac_sha1 is not correct" \
                unless ShadowsocksRuby::Cipher.hmac_sha1_digest(@recv_iv + [@counter].pack("n"), data) == hmac
              @buffer << @cipher.decrypt(data, @recv_iv)
              @counter += 1
              async_recv_other_packet_helper n
            else # origin mode
              @buffer << @cipher.decrypt(@next_protocol.async_recv(-1), @recv_iv)
              async_recv_other_packet_helper n
            end
          end

          def send_data_first_packet data
            @send_iv = @cipher.random_iv
            @next_protocol.send_data @send_iv + @cipher.encrypt(data, @send_iv)
            class << self
              alias send_data send_data_other_packet
            end
          end

          alias send_data send_data_first_packet

          def send_data_other_packet data
            @next_protocol.send_data @cipher.encrypt(data, @send_iv)
          end

        end
      end
    end
  end
end
