require 'openssl'
module ShadowsocksRuby
  
  # This module provide classes to encapsulate different underlying crypto library,
  # to utilize them with an unique interface.
  #
  # It also provide some useful utility functions like 
  # {.hmac_sha1_digest} and {.bytes_to_key}.
  #
  # @example
  #    # Demonstrate how to build a cipher object and it's typical use case.
  #    cipher = ShadowsocksRuby::Cipher.build('aes-256-cfb', 'secret123')
  #    iv = cipher.random_id
  #    encrypted_text = cipher.encrypt("hello world!", iv)
  #    puts cipher.decrypt(encrypted_text, iv) # hello world!
  #    puts cipher.key # ...... # in case key need to be used in some Digest algorithm.

  module Cipher
    extend self

    # Builder for cipher object
    #
    # Supported methods are:
    # * table
    # * rc4-md5
    # * chacha20, chacha2-ietf, salsa20 which are provided by RbNaCl
    # * all cipher methods supported by ruby gems OpenSSL, use
    #
    #        ruby -e "require 'openssl'; puts OpenSSL::Cipher.ciphers" 
    #
    #   to get a full list.
    # @param [String] method         Cipher methods
    # @param [String] password       Password
    # @return [OpenSSL, Table, RC4_MD5, RbNaCl] A duck type cipher object
    #
    def build method, password
      case method
      when 'table'
        ShadowsocksRuby::Cipher::Table.new password
      when 'rc4-md5'
        ShadowsocksRuby::Cipher::RC4_MD5.new password
      when 'chacha20','chacha20-ietf','salsa20'
        ShadowsocksRuby::Cipher::RbNaCl.new method, password
      else
        ShadowsocksRuby::Cipher::OpenSSL.new method, password
      end
    end

    # Generate <b>first 10 bytes</b> of HMAC using sha1 Digest
    #
    # @param [String] key             Key, use {#bytes_to_key} to convert a password to key if you need
    # @param [String] message         Message to digest
    # @return [String]                Digest, <b> only first 10 bytes</b>
    def hmac_sha1_digest(key, message)
      @digest ||= ::OpenSSL::Digest.new('sha1')
      ::OpenSSL::HMAC.digest(@digest, key, message)[0,10]
    end

    # Equivalent to OpenSSL's EVP_BytesToKey() with count = 1
    #
    # @param [String] Password        Password bytes
    # @param [Integer] key_len        Key length, the length of key bytes to generate 
    # @param [Integer] iv_len         IV length, needed by internal algorithm
    # @return [String]                Key bytes, of *key_len* length
    def bytes_to_key(password, key_len, iv_len)
      bytes_to_key1(nil, password, 1, key_len, iv_len)[0]
    end

    private

    def bytes_to_key0(md_buf, salt, data, count)
      src = md_buf.empty? ? '' : md_buf
      src << data
      src << salt if salt

      dst = ::OpenSSL::Digest::MD5.digest(src)

      (count - 1).times do
        dst = ::OpenSSL::Digest::MD5.digest(dst)
      end

      return dst
    end

    # Equivalent to OpenSSL's EVP_BytesToKey()
    # Taken from http://d.hatena.ne.jp/winebarrel/20081208/p1
    # Fixed by Zhenkyle
    def bytes_to_key1(salt, data, count, nkey, niv)
      key = ''
      iv = ''
      md_buf = ''

      loop do
        md_buf = bytes_to_key0(md_buf, salt, data, count)

        if nkey.nonzero?
          key << (nkey > md_buf.length ? md_buf : md_buf[0, nkey])
          nkey -= nkey > md_buf.length ? md_buf.length : nkey
        elsif niv.nonzero?
          iv << (niv > md_buf.length ? md_buf : md_buf[0, niv])
          niv -= niv > md_buf.length ? md_buf.length : niv
        end

        if nkey.zero? and niv.zero?
          break
        end
      end

      return [key, iv]
    end
  end
end
