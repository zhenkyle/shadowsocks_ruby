module ShadowsocksRuby
  module Protocols

    # To be used with protocols without an IV, like {Cipher::Table}
    module NoIvCipherProtocol
      module TCP
        class LocalBackend

          attr_accessor :next_protocol

          # @param [Hash] params                                              Configuration parameters
          # @option params [Cipher::Table] :cipher                            a cipher object without IV,  +required+
          def initialize params = {}
            @cipher = params[:cipher] or raise ProtocolError, "params[:cipher] is required"
          end

          def async_recv n
            @cipher.decrypt(@next_protocol.async_recv n)
          end

          def send_data data
            @next_protocol.send_data(@cipher.encrypt data)
          end
        end
      end
    end
  end
end
