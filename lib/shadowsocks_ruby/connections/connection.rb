require 'fiber'
require 'ipaddr'

module ShadowsocksRuby

  # This module contains various functionality code to be mixed-in 
  # with EventMachine::Connection
  # when Connection object is instantiated.
  #
  # There are 4 kinds of connection: client, local backend, remote server and destination. Which are demonstrated below:
  #
  #                  -------------------------------------------       -------------------------------------------------
  #                  |                                         |       |                                               |
  #     Client <---> |ClientConnection -- RemoteServerConnecton| <---> |LocalBackendConnection -- DestinationConnection| <---> Destination
  #             net  |           Shadowsocks Client            |  net  |               Shadowsocks Server              |  net
  #                  -------------------------------------------       -------------------------------------------------
  #
  #    
  module Connections
    # This class added fiber enabled asynchronously receive 
    # function and pressure controled +send_data+ to EventMachine::Connection
    #
    # User code should define +process_hook+ which hopefully implement a state machine .
    #
    # *Note:* User code should not override +post_init+ and +receive_data+, it is by design.
    #
    # @example
    #     class DummyConnection < ShadowsocksRuby::Connections::Connection
    #       def process_hook
    #         @i ||= 0
    #         @i += 1
    #         puts "I'm now in a fiber enabled context: #{@fiber}"
    #         Fiber.yield if @i >= 3
    #       end
    #     end
    #
    class Connection < EventMachine::Connection
      # 512K, used to pause plexer when plexer.get_outbound_data_size > this value
      PressureLevel = 524288

      # It is where to relay peer's traffic to
      # For a server connection, plexer is backend connection.
      # For a backend connection, plexer is server connection.
      # @return [Connection]
      attr_accessor :plexer

      # you can set logger in test code
      attr_writer :logger

      # get the logger object, the defautl logger is App.instance.logger
      def logger
        @logger ||= App.instance.logger
      end


      # send_data with pressure control
      # @param[String] data       Data to send asynchronously
      def send_data data
        pressure_control
        super data
      end

      # Call process_hook, which should be defined in user code
      # @private
      def process
        process_hook
      end

      # Initialize a fiber context and enter the process loop
      # normally, a child class should not override post_init, it is by design
      # @private
      def post_init
        @buffer = String.new('', encoding: Encoding::ASCII_8BIT)
        @fiber = Fiber.new do
          # poor man's state machine
          while true
            process
          end
        end
        @fiber.resume
      end

      def peer
        @peer ||=
        begin
          port, ip = Socket.unpack_sockaddr_in(get_peername)
          "#{ip}:#{port}"
        end
      end

      # Asynchronously receive n bytes from @buffer
      # @param [Integer] n             Bytes to receive, if n = -1 returns all data in @buffer
      # @return [String]               Returned n bytes data
      def async_recv n
        # wait n bytes
        if n == -1 && @buffer.size == 0 || @buffer.size < n
          @wait_length = n
          Fiber.yield
        end
        # read n bytes from buffer
        if n == -1
          s, @buffer = @buffer, String.new('', encoding: Encoding::ASCII_8BIT)
          return s
        else
          return @buffer.slice!(0, n)
        end
      end

      # Asynchronously receive data until str (eg: "\\r\\n\r\\n") appears.
      # @param [String] str            Desired endding str
      # @raise BufferOversizeError          raise if cannot find str in first 65536 bytes (64K bytes)of @buffer,
      #                                  enough for a HTTP request head.
      # @return [String]               Returned data, with str at end
      def async_recv_until str
        # wait for str
        pos = @buffer =~ Regexp.new(str)
        while pos == nil
          @wait_length = -1
          Fiber.yield
          pos = @buffer =~ Regexp.new(str)
          raise BufferOversizeError, "oversized async_recv_until read" if @buffer.size > 65536
        end
        # read until str from buffer
        return @buffer.slice!(0, pos + str.length)
      end


      # Provide fiber enabled data receiving, should be always be called 
      # in a fiber context.
      #
      # Normally, client class should not call receive_data directlly,
      # instead should call async_recv or async_recv_until
      # 
      # @param [String] data
      # @raise OutOfFiberConextError
      #
      # @private
      def receive_data data
        if @fiber.alive?
          @buffer << data
          if @wait_length == -1 || @buffer.size >= @wait_length
            @fiber.resume
          end
        else
          raise OutOfFiberContextError, "should not go here"
        end
      rescue MyErrorModule => e
        logger.error("connection") {e.message}
        close_connection
      rescue => e
        logger.error("connection") {e}
        close_connection
      end

      # if peer receving data is too slow, pause plexer sending data to me
      # ,prevent memery usage to be too high
      # @private
      def pressure_control
        @plexer ||= nil
        if @plexer != nil
          if get_outbound_data_size >= PressureLevel
            @plexer.pause unless @plexer.paused?
            EventMachine.next_tick self.method(:pressure_control)
          else
            @plexer.resume if @plexer.paused?
          end
        end
      end

      # Close plexer first if it exists
      def unbind
        @plexer ||= nil
        @plexer.close_connection_after_writing if @plexer != nil
      end

    end
  end
end