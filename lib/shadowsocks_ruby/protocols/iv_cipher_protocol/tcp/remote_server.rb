require 'shadowsocks_ruby/protocols/iv_cipher_protocol/tcp/local_backend'
module ShadowsocksRuby
  module Protocols

    # To be used with any cipher methods with an IV, like {Cipher::OpenSSL},
    # {Cipher::RbNaCl} and {Cipher::RC4_MD5}.
    module IvCipherProtocol
      module TCP
        class RemoteServer < LocalBackend
        end
      end
    end
  end
end
