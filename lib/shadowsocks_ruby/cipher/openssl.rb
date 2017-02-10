require 'openssl'

module ShadowsocksRuby
  module Cipher

    # Encapsulate RubyGems version of OpenSSL, the gems version is newer than
    # the version in Ruby Standand Library.
    #
    # Cipher methods provided by Ruby OpenSSL library is dicided by
    # the OpenSSL library comes with ruby on your system.
    # To work with specific version of OpenSSL library other than the version
    # comes with ruby, you may need to specify the path where OpenSSL is installed.
    #
    #    gem install openssl -- --with-openssl-dir=/opt/openssl
    #
    # Use this command to get a full list of cipher methods supported on your system.
    #    ruby -e "require 'openssl'; puts OpenSSL::Cipher.ciphers" 
    # 
    #
    # See https://github.com/ruby/openssl for more detail.
    #
    # Normally you should use {ShadowsocksRuby::Cipher#build} to get an
    # instance of this class.
    class OpenSSL

      # Return the key, which length is decided by the cipher method.
      # @return [String] key
      attr_reader :key

      # @param [String] method           Cipher methods
      # @param [String] password         Password
      def initialize method, password
        @cipher_encrypt = ::OpenSSL::Cipher.new(method).encrypt
        @cipher_decrypt = ::OpenSSL::Cipher.new(method).decrypt
        key_len = @cipher_encrypt.key_len
        iv_len = @cipher_encrypt.iv_len
        @key = Cipher.bytes_to_key(password, key_len, iv_len)
        @cipher_encrypt.key = @key
        @cipher_decrypt.key = @key
        @encrypt_iv = nil
        @decrypt_iv = nil
      end

      # Generate a random IV for the cipher method
      # @return [String]                 random IV of the length of the cipher method
      def random_iv
        @encrypt_iv = @cipher_encrypt.random_iv
      end

      # Encrypt message by provided IV
      # @param [String] message
      # @param [String] iv
      # @return [String]                  Encrypted Message
      def encrypt(message, iv)
        if @encrypt_iv != iv
          @encrypt_iv = iv
          @cipher_encrypt.iv = iv
        end
        @cipher_encrypt.update(message) << @cipher_encrypt.final
      end

      # Decrypt message by provided IV
      # @param [String] message
      # @param [String] iv
      # @return [String]                   Decrypted Message
      def decrypt(message, iv)
        if @decrypt_iv != iv
          @decrypt_iv = iv
          @cipher_decrypt.iv = iv
        end
        @cipher_decrypt.update(message) << @cipher_decrypt.final
      end

      # Get the cipher object's IV length
      # @return [Integer]
      def iv_len
        @cipher_encrypt.iv_len
      end
    end
  end
end
