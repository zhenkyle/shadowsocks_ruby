module ShadowsocksRuby
  module Connections
    # Mixed-in code to provide functionality to a BackendConnection
    # ,whose peer is a upstream peer, like a Destinatiion or a RemoteServer.
    module BackendConnection
      
      # Packet Protocol
      #
      # A Strategy Pattern for replacing protocol algorithm
      #
      # all read from {BackendConnection}'s {packet_protocol} is just data,
      # 
      # the first send to {packet_protocol} chould be address_bin (for a {RemoteServerConnection}) 
      # or data (for a {DestinationConnection}),
      # other send to {packet_protocol} should be just data
      #
      # @return [ShadowsocksRuby::Protocols::SomePacketProtocol]
      # @see ShadowsocksRuby::Protocols
      attr_accessor :packet_protocol

      # (see ServerConnection#params)
      attr_reader :params

      # If clild class override initialize, make sure to call super
      #
      # @param [Protocols::ProtocolStack] protocol_stack
      # @param [Hash] params
      # @option params [Integer] :timeout set +comm_inactivity_timeout+
      # @return [Connection_Object]
      def initialize protocol_stack, params
        super()

        @packet_protocol = protocol_stack.build!(self)

        @params = params
        self.comm_inactivity_timeout = @params[:timeout] if @params[:timeout] && @params[:timeout] != 0
        @connected = EM::DefaultDeferrable.new
      end


      def connection_completed
        @connected.succeed
      end

      # Buffer data until the connection to the backend server
      # is established and is ready for use
      def send_data data
        @connected.callback { super data }
      end
    end
  end
end