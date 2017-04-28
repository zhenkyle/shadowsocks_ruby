module ShadowsocksRuby
  module Connections
    # A BackendConnection is a connection whose peer is a upstream peer, like a Destinatiion or a RemoteServer.
    class BackendConnection < Connection
      
      # A Strategy Pattern for replacing protocol algorithm
      #
      # All read packet returned from a {packet_protocol} ({TCP::RemoteServerConnection} and {TCP::DestinationConnection} etc. ) 
      # is just data.
      #
      # The first packet send to {packet_protocol} must be address_bin for a {TCP::RemoteServerConnection} and 
      # data for a {TCP::DestinationConnection},
      # The second and other send to {packet_protocol} must be data
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