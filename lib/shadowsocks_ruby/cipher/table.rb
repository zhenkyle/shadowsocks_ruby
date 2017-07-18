require 'openssl'

module ShadowsocksRuby
  module Cipher

    # Implementation of the Table cipher method.
    #
    # Note: this cipher method have neither IV nor key, so may be
    # incompatible with protocols which needs IV or key.
    # 
    # Normally you should use {ShadowsocksRuby::Cipher#build} to get an
    # instance of this class.
    class Table
      # @param [String] password         Password
      def initialize password
        @encrypt_table, @decrypt_table = get_table(password)
      end

      # Encrypt message by provided IV
      # @param [String] message
      # @return [String]                  Encrypted Message
      def encrypt(message)
        translate @encrypt_table, message
      end

      # Decrypt message by provided IV
      # @param [String] message
      # @return [String]                   Decrypted Message
      def decrypt(message)
        translate @decrypt_table, message
      end

      # (see OpenSSL#iv_len)
      #
      # returns 0 for Table
      def iv_len
        0
      end

      # (see OpenSSL#key)
      #
      # returns nil for Table
      def key
        nil
      end

      private

      def get_table(key)
        table = [*0..255]
        a = ::OpenSSL::Digest::MD5.digest(key).unpack('Q<')[0]

        (1...1024).each do |i|
          table.sort! { |x, y| a % (x + i) - a % (y + i) }
        end

        decrypt_table = Array.new(256)
        table.each_with_index {|x, i| decrypt_table[x] = i}

        [table, decrypt_table]
      end

      def translate(table, buf)
        buf.bytes.map!{|x| table[x]}.pack("C*")
      end

    end
  end
end
