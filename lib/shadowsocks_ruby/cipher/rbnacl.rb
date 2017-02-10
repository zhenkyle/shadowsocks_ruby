require 'rbnacl'

module ShadowsocksRuby
  module Cipher

    # Encapsulate RbNaCl ruby library, cipher methods provided by this Class are:
    # * chacha20 -- ChaCha20Poly1305Legacy without ad
    # * chacha2-ietf -- ChaCha20Poly1305IETF without ad
    # * salsa20 -- XSalsa20Poly1305 without ad
    #
    # Normally you should use {ShadowsocksRuby::Cipher#build} to get an
    # instance of this class.

    class RbNaCl

      attr_reader :key
      # (see OpenSSL#initialize)
      def initialize method, password
        klass = case method
          when 'chacha20'
            ::RbNaCl::AEAD::ChaCha20Poly1305Legacy
          when 'chacha20-ietf'
            ::RbNaCl::AEAD::ChaCha20Poly1305IETF
          when 'salsa20'
            ::RbNaCl::SecretBoxes::XSalsa20Poly1305
          else
            raise CipherError, "unsupported method: " + method
          end
        key_len = klass.key_bytes
        iv_len = klass.nonce_bytes
        @key = ShadowsocksRuby::Cipher.bytes_to_key(password, key_len, iv_len)
        @cipher = klass.new(@key)
      end

      # (see OpenSSL#random_iv)
      def random_iv
        ::RbNaCl::Random.random_bytes(@cipher.nonce_bytes)
      end

      # (see OpenSSL#encrypt)
      def encrypt(message, iv)
        if @cipher.class == ::RbNaCl::SecretBoxes::XSalsa20Poly1305
          @cipher.encrypt(iv, message)
        else
          @cipher.encrypt(iv, message, nil)
        end
      end

      # (see OpenSSL#decrypt)
      def decrypt(message, iv)
        if @cipher.class == ::RbNaCl::SecretBoxes::XSalsa20Poly1305
          @cipher.decrypt(iv, message)
        else
          @cipher.decrypt(iv, message, nil)
        end
      end

      # (see OpenSSL#iv_len)
      def iv_len
        @cipher.iv_bytes
      end
    end
  end
end
