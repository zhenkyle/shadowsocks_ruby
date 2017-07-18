module ShadowsocksRuby
  module Protocols

    # To be used with any cipher methods with an IV, like {Cipher::OpenSSL},
    # {Cipher::RbNaCl} and {Cipher::RC4_MD5}.
    module IvCipherProtocol
      module TCP
        class LocalBackend
          include BufferHelper

          attr_accessor :next_protocol

          # @param [Hash] params                                                           Configuration parameters
          # @option params [Cipher::OpenSSL, Cipher::RbNaCl, Cipher::RC4_MD5] :cipher      a cipher object with IV and a key, +required+
          def initialize params = {}
            @cipher = params[:cipher] or raise ProtocolError, "params[:cipher] is required"
            @buffer =""
          end

          def async_recv_first_packet n
            iv_len = @cipher.iv_len
            @recv_iv = @next_protocol.async_recv iv_len
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
            send_first_packet_process data
            class << self
              alias send_data send_other_packet
            end
          end

          alias send_data send_data_first_packet

          def send_first_packet_process data
            @send_iv = @cipher.random_iv
            @next_protocol.send_data @send_iv + @cipher.encrypt(data, @send_iv)
          end

          def send_other_packet data
            @next_protocol.send_data @cipher.encrypt(data, @send_iv)
          end
        end
      end
    end
  end
end
