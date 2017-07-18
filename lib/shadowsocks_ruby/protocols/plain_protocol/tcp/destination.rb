module ShadowsocksRuby
  module Protocols
    # Relay data from peer to plexer without any process.
    # This is a packet protocol, so no need to implement @buffer (always be called with async_recv(-1))
    module PlainProtocol
      module TCP
        class Destination
          attr_accessor :next_protocol

          # @param [Hash] params                         Configuration parameters
          def initialize params = {}
            @params = {}.merge(params)
          end

          def async_recv n
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