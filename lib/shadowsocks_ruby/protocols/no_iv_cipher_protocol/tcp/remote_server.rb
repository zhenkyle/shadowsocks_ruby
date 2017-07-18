require 'shadowsocks_ruby/protocols/no_iv_cipher_protocol/tcp/local_backend'
module ShadowsocksRuby
  module Protocols

    # To be used with protocols without an IV, like {Cipher::Table}
    module NoIvCipherProtocol
      module TCP
        class RemoteServer < LocalBackend
        end
      end
    end
  end
end
