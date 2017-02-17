module ShadowsocksRuby
  module Connections

    # A ServerConnection is a connection whose peer is a downstream peer, like a Client or a LocalBackend.
    class ServerConnection < Connection
      
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
      # @option params [Integer] :timeout set +comm_inactivity_timeout+
      # @param [Protocols::ProtocolStack] backend_protocol_stack
      # @param [Hash] backend_params
      # @option backend_params [Integer] :timeout set +comm_inactivity_timeout+
      # @return [Connection_Object]
      def initialize protocol_stack, params, backend_protocol_stack, backend_params
        super()

        @packet_protocol = protocol_stack.build!(self)

        @params = params

        @backend_protocol_stack = backend_protocol_stack
        @backend_params = backend_params
        self.comm_inactivity_timeout = @params[:timeout] if @params[:timeout] && @params[:timeout] != 0
      end

      def post_init
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