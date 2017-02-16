module ShadowsocksRuby
  # Various utility functions
  module Util
    module_function

    ATYP_IPV4      = 1
    ATYP_DOMAIN    = 3
    ATYP_IPV6      = 4

    # Hex encodes a message
    #
    # @param [String] bytes The bytes to encode
    #
    # @return [String] Tasty, tasty hexadecimal
    def bin2hex(bytes)
      bytes.to_s.unpack("H*").first
    end

    # Hex decodes a message
    #
    # @param [String] hex hex to decode.
    #
    # @return [String] crisp and clean bytes
    def hex2bin(hex)
      [hex.to_s].pack("H*")
    end

    # Parse address bytes
    # @param [String] bytes The bytes to parse
    # @return [Array<String, Integer>] Return Host, Port
    def parse_address_bin(bytes)
      bytes = bytes.dup
      address_type = bytes.slice!(0, 1).unpack("C").first
      case address_type
      when ATYP_IPV4
        host = IPAddr.ntop bytes.slice!(0, 4)
        port = bytes.slice!(0, 2).unpack('n').first
        [host, port]
      when ATYP_IPV6
        host = IPAddr.ntop bytes.slice!(0, 16)
        port = bytes.slice!(0, 2).unpack('n').first
        [host, port]
      when ATYP_DOMAIN
        domain_len = bytes.slice!(0, 1).unpack("C").first
        host = bytes.slice!(0, domain_len)
        port = bytes.slice!(0, 2).unpack('n').first
        [host, port]
      else
        raise PharseError, "unknown address_type: #{address_type}"
      end
    end
  end
end