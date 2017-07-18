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
      # @param [String] protocol_type Protocol Type, can be "TCP", "UDP"
      def initialize cfg_ary, cipher_name, password, protocol_type
        @cfg_ary = cfg_ary.map do |protocol_name, param|
          protocol_module = protocol_name.to_camel_case + "Protocol"
          protocol_module = Protocols.const_get(protocol_module).const_get(protocol_type)
          [protocol_module, param ||= {}]
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

        protocols = @cfg_ary.map do | protocol_module, params|
          case protocol_module.to_s
          when /PlainProtocol/, /Socks5Protocol/, \
            /ShadowsocksProtocol/, /HttpSimpleProtocol/
            # do nothing, these are known protocols don't need cipher
          when /TlsTicketProtocol/
            # this protocol need a key
            params = {:key => (cipher ||= Cipher.build(@cipher_name, @password)).key}.merge(params)
          else
            params = {:cipher => (cipher ||= Cipher.build(@cipher_name, @password))}.merge(params)
          end

          klass = nil
          case
          when conn.is_a?(ShadowsocksRuby::Connections::ClientConnection)
            klass = protocol_module.const_get("Client")
          when conn.is_a?(ShadowsocksRuby::Connections::RemoteServerConnection)
            klass = protocol_module.const_get("RemoteServer")
          when conn.is_a?(ShadowsocksRuby::Connections::LocalBackendConnection)
            klass = protocol_module.const_get("LocalBackend")
          when conn.is_a?(ShadowsocksRuby::Connections::DestinationConnection)
            klass = protocol_module.const_get("Destination")
          end
          klass.new(params)
        end


        protocols.each_cons(2) do | p, p1 |
          p.next_protocol = p1
        end

        protocols.last.tap do |p|
          p.next_protocol = conn
        end
        
        protocols.first
      end
    end
  end
end