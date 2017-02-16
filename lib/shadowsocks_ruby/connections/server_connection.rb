module ShadowsocksRuby
  module Connections

    # Mixed-in code to provide functionality to a ServerConnection
    # ,whose peer is a downstream peer, like a Client or a LocalBackend.
    module ServerConnection
      
      # Packet Protocol
      #
      # A Strategy Pattern for replacing protocol algorithm
      #
      # the first read from {ServerConnection}'s {packet_protocol} is an address_bin,
      # other read from {packet_protocol} is just data
      # 
      # all send to {packet_protocol} should be just data
      #
      # @return [ShadowsocksRuby::Protocols::SomePacketProtocol]
      # @see ShadowsocksRuby::Protocols
      attr_accessor :packet_protocol

      # Params
      # @return [Hash]
      attr_reader :params

      # If clild class override initialize, make sure to call super
      #
      # @param [Protocols::ProtocolStack] protocol_stack
      # @param [Hash] params
      # @param [Protocols::ProtocolStack] backend_protocol_stack
      # @param [Hash] backend_params
      # @return [Connection_Object]
      def initialize protocol_stack, params, backend_protocol_stack, backend_params
        super()

        @packet_protocol = protocol_stack.build!(self)      

        @params = params

        @backend_protocol_stack = backend_protocol_stack
        @backend_params = backend_params
      end

      def post_init
        logger.info {"Accepted #{peer}"}
        App.instance.incr
        super()
      end

      # Create a plexer -- a backend connection
      # @param [String] host
      # @param [Integer] port
      # @param [Class] backend_klass
      # @return [Connection_Object]
      def create_plexer(host, port, backend_klass)
        @plexer = EventMachine.connect host, port, backend_klass, @backend_protocol_stack, @backend_params
        @plexer.plexer = self
        @plexer
      rescue EventMachine::ConnectionError => e
        raise ConnectionError, e.message + " when connect to #{host}:#{port}"
      end

      def unbind
        App.instance.decr
        super()
      end

    end
  end
end