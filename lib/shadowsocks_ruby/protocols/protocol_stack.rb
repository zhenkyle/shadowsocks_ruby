require "to_camel_case"

module ShadowsocksRuby
  module Protocols

    # Factory class for build protocol stacks
    #
    # @see Protocols
    class ProtocolStack

      # @example This is what a cfg_ary Array look like
      #   [ 
      #     ["some_packet_protocol_name"], # a packet protocol is required
      #     ["some_cipher_protocol_name", {:cipher => "some_cipher_object"}], # a cipher protocol is optional
      #     ["some_obfs_protocol_name", {:obfs_params => "..."}] # a obfs protocol is optional
      #   ]
      #
      # @param [Array] cfg_ary
      # @param [String] cipher_name
      # @param [password] password
      def initialize cfg_ary, cipher_name, password
        @cfg_ary = cfg_ary.map do |protocol_name, param|
          protocol_class = protocol_name.to_camel_case + "Protocol"
          protocol_class = Protocols.const_get(protocol_class)
          [protocol_class, param ||= {}]
        end
        @cipher_name = cipher_name
        @password = password
      end

      # Factory method for build a protocol stack
      #
      # @param [EventMachine::Connection] conn
      # @return top protocol (packet protocol) in the stack
      def build! conn
        cipher = nil

        protocols = @cfg_ary.map do | klass, params|
          case klass.to_s
          when Protocols::PlainProtocol.to_s, Protocols::Socks5Protocol.to_s, \
            Protocols::ShadowsocksProtocol.to_s, Protocols::HttpSimpleProtocol.to_s
            # do nothing, these are known protocols don't need cipher
          when Protocols::TlsTicketProtocol.to_s
            # this protocol need a key
            params = {:key => (cipher ||= Cipher.build(@cipher_name, @password)).key}.merge(params)
          else
            params = {:cipher => (cipher ||= Cipher.build(@cipher_name, @password))}.merge(params)
          end
            klass.new(params)
        end

        protocols.each_cons(2) do | p, p1 |
          p.next_protocol = p1
        end

        protocols.last.tap do |p|
          p.next_protocol = conn
        end

        protocols.each do |p|
          case
          when conn.is_a?(ShadowsocksRuby::Connections::TCP::ClientConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :tcp_receive_from_client, :async_recv
              def_delegator :@next_protocol, :tcp_send_to_client, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::TCP::RemoteServerConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :tcp_receive_from_remoteserver, :async_recv
              def_delegator :@next_protocol, :tcp_send_to_remoteserver, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::TCP::LocalBackendConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :tcp_receive_from_localbackend, :async_recv
              def_delegator :@next_protocol, :tcp_send_to_localbackend, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::TCP::DestinationConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :tcp_receive_from_destination, :async_recv
              def_delegator :@next_protocol, :tcp_send_to_destination, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::UDP::ClientConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :udp_receive_from_client, :async_recv
              def_delegator :@next_protocol, :udp_send_to_client, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::UDP::RemoteServerConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :udp_receive_from_remoteserver, :async_recv
              def_delegator :@next_protocol, :udp_send_to_remoteserver, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::UDP::LocalBackendConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :udp_receive_from_localbackend, :async_recv
              def_delegator :@next_protocol, :udp_send_to_localbackend, :send_data
            end
          when conn.is_a?(ShadowsocksRuby::Connections::UDP::DestinationConnection)
            class << p
              extend Forwardable
              def_delegator :@next_protocol, :udp_receive_from_destination, :async_recv
              def_delegator :@next_protocol, :udp_send_to_destination, :send_data
            end
          end
        end          
        
        protocols.first
      end
    end
  end
end