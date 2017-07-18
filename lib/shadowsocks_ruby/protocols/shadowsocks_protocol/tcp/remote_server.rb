require 'shadowsocks_ruby/protocols/plain_protocol/tcp/destination'

module ShadowsocksRuby
  module Protocols
    # Shadowsocks packet protocol for both origin shadowsocks protocol and OTA shadowsocks protocol.
    #
    # specification: 
    # * https://shadowsocks.org/en/spec/protocol.html
    # * https://shadowsocks.org/en/spec/one-time-auth.html
    #
    # This is a packet protocol, so no need to implement @buffer
    module ShadowsocksProtocol
      module TCP
        class RemoteServer < Protocols::PlainProtocol::TCP::Destination
        end
      end
    end
  end
end
