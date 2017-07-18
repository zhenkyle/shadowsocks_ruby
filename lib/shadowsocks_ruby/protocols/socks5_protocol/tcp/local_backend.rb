require 'shadowsocks_ruby/protocols/socks5_protocol/tcp/client'
module ShadowsocksRuby
  module Protocols
    # SOCKS 5 protocol
    #
    # specification : 
    # * http://tools.ieft.org/html/rfc1928
    # * http://en.wikipedia.org/wiki/SOCKS
    # @note Now only implemented the server side protocol, not the client side protocol.
    module Socks5Protocol
      module TCP
        class LocalBackend < Client
        end
      end
    end
  end
end
