require 'openssl'

module ShadowsocksRuby
  module Cipher

    # Implementation of the RC4_MD5 cipher method.
    #
    # Normally you should use {ShadowsocksRuby::Cipher#build} to get an
    # instance of this class.

    class RC4_MD5
      attr_reader :key

      # @param [String] password         Password
      def initialize password
        @key = ShadowsocksRuby::Cipher.bytes_to_key(password, 16, 16)
        @cipher_encrypt = ::OpenSSL::Cipher.new('rc4').encrypt
        @cipher_decrypt = ::OpenSSL::Cipher.new('rc4').decrypt
        @encrypt_iv = nil
        @decrypt_iv = nil
      end

      # (see OpenSSL#random_iv)
      def random_iv
        Random.new.bytes(16)
      end

      # (see OpenSSL#encrypt)
      def encrypt(message, iv)
        if @encrypt_iv != iv
          @encrypt_iv = iv
          key = ::OpenSSL::Digest::MD5.digest(@key + iv)
          @cipher_encrypt.key = key
        end
        @cipher_encrypt.update(message) << @cipher_encrypt.final
      end

      # (see OpenSSL#decrypt)
      def decrypt(message, iv)
        if @decrypt_iv != iv
          @decrypt_iv = iv
          key = ::OpenSSL::Digest::MD5.digest(@key + iv)
          @cipher_decrypt.key = key
        end
        @cipher_decrypt.update(message) << @cipher_decrypt.final
      end

      # (see OpenSSL#iv_len)
      def iv_len
        16
      end
    end
  end
end
