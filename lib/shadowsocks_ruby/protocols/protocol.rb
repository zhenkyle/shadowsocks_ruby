module ShadowsocksRuby
  # Protocols are layered. Each layer know nothing about other layers.
  #        (data)   |   TOP: HTTP, FTP, STMP ...     ^   (data)
  #          Pack   |   layer 3 protocol packet      |   Unpack
  #       Encrypt   |   layer 2 protocol cipher      |   Decrypt
  #     Obfuscate   |   layer 1 protocol obfuscate   |   DeObfuscate
  #      (opaque)   V   Bottom: TCP/UDP              |   (opaque)
  #
  #
  # === Protocols
  # There are 2 hooks can be called on each protocol:
  # * async_recv
  # * send_data
  # 
  # Each async_recv hook's job is to return data of exact length required by upper level protocol.
  #
  # Each send_data hook's job is to get the send work done, with the data it received from the upper level protocol.
  #
  # Each hook can call next layer protocols's corresponding async_recv and send_data hook,
  #
  # The bottom layer calls +Connection+'s corresponding async_recv and send_data hook.
  #
  # The +Connection+ then map corresponding async_recv and send_data hook to real data transfer 
  # methods +async_recv+ and +send_data+.
  #
  #
  # @see Connections
  # @see ProtocolStack
  module Protocols

    # This module include helper methods for deal with @buffer.
    #
    module BufferHelper
      def async_recv_other_packet_helper n
        if n == -1
          return @buffer.slice!(0, @buffer.length)          
        elsif n < @buffer.length
          class << self
            alias async_recv async_recv_in_buffer
          end
          return @buffer.slice!(0, n)
        else
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = @next_protocol.async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end

      def async_recv_in_buffer n
        if n == -1
          class << self
            alias async_recv async_recv_other_packet
          end
          return @buffer.slice!(0, @buffer.length)          
        elsif n < @buffer.length
          return @buffer.slice!(0, n)
        else
          class << self
            alias async_recv async_recv_other_packet
          end
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = @next_protocol.async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end
      
    end
  end
end