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
  # There are 16 hooks can be called on protocols, which are:
  # * tcp_receive_from_client
  # * tcp_send_to_client
  # * tcp_receive_from_remoteserver
  # * tcp_send_to_remoteserver
  # * tcp_receive_from_localbackend
  # * tcp_send_to_localbackend
  # * tcp_receive_from_destination
  # * tcp_send_to_destination
  # * udp_receive_from_client
  # * udp_send_to_client
  # * udp_receive_from_remoteserver
  # * udp_send_to_remoteserver
  # * udp_receive_from_localbackend
  # * udp_send_to_localbackend
  # * udp_receive_from_destination
  # * udp_send_to_destination
  # 
  # Each receive_from hook's job is to return data of exact length required by upper level protocol.
  #
  # Each send_to hook's job is to get the send work done, with the data it received from the upper level protocol.
  #
  # Each hook can call next layer protocols's corresponding receive_from and send_to hook,
  #
  # The bottom layer calls +Connection+'s corresponding receive_from and send_to hook.
  #
  # The +Connection+ then map corresponding receive_from and send_to hook to real data transfer 
  # methods +async_recv+ and +send_data+.
  #
  #
  # @see Connections
  # @see ProtocolStack
  module Protocols

    # This module include helper methods for a Packet/Cipher/Obfs Protocol.
    #
    # To simplify boring long method name writing (eg: tcp_receive_from_client, tcp_send_to_client),
    # two Adapter method are introduced and could be untilized: 
    # +#async_recv+ and +#send_data+,
    # they will be adapted to long method names (eg: tcp_receive_from_client, tcp_send_to_client) at runtime.
    # 
    # This helper module implement dummy {#async_recv} and {#send_data}, do nothing but just raise,
    # in order to make things clear.
    #
    # To use it, use +include DummyHelper+ to include it into your protocol implementation.
    module DummyHelper

      # Receive n bytes of data
      # @param[Integer] n            length of data to receive
      # @raise ProtocolError
      # @return [String]             Should return real data on runtime
      def async_recv n
        raise ProtocolError, "async_recv must be set before use"
      end

      # Send data 
      # @param[String] data          data to send
      # @raise ProtocolError
      def send_data data
        raise ProtocolError, "send_data must be set before use"
      end

      # If user code don't want to implement a method, it can call this to raise Error.
      # @raise UnimplementError
      def raise_me *args
        raise UnimplementError, "Some day may implement this: " + caller[0][/`.*'/][1..-2]
      end
    end

    # This module include helper methods for deal with @buffer.
    #
    module BufferHelper
      def tcp_receive_from_remoteserver_other_packet_helper n
        if n == -1
          return @buffer.slice!(0, @buffer.length)          
        elsif n < @buffer.length
          class << self
            alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_in_buffer
          end
          return @buffer.slice!(0, n)
        else
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end

      def tcp_receive_from_remoteserver_in_buffer n
        if n == -1
          class << self
            alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_other_packet
          end
          return @buffer.slice!(0, @buffer.length)          
        elsif n < @buffer.length
          return @buffer.slice!(0, n)
        else
          class << self
            alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_other_packet
          end
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end

      def tcp_receive_from_localbackend_other_packet_helper n
        if n == -1
          return @buffer.slice!(0, @buffer.length)
        elsif n < @buffer.length
          class << self
            alias tcp_receive_from_localbackend tcp_receive_from_localbackend_in_buffer
          end
          return @buffer.slice!(0, n)
        else
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end


      def tcp_receive_from_localbackend_in_buffer n
        if n == -1
          class << self
            alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
          end
          return @buffer.slice!(0, @buffer.length)
        elsif n < @buffer.length
          return @buffer.slice!(0, n)
        else
          class << self
            alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
          end
          if n == @buffer.length
            return @buffer.slice!(0, n)
          else
            data = async_recv(n - @buffer.length)
            return @buffer.slice!(0, n) << data 
          end
        end
      end

    end
  end
end