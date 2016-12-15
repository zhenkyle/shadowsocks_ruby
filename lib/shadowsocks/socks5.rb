require 'fiber'
require 'ipaddr'

module Shadowsocks
  module Socks5Server
    METHOD_NO_AUTH = 0
    CMD_CONNECT    = 1
    REP_SUCCESS    = 0
    RESERVED       = 0
    ATYP_IPV4      = 1
    ATYP_DOMAIN    = 3
    ATYP_IPV6      = 4
    SOCKS5         = 5

    def post_init
      @buffer = ''
      @fiber = Fiber.new do
        client_handshake
      end
      @fiber.resume
    end

    # Communicates with a client application as described by the SOCKS 5
    # specification : http://tools.ieft.org/html/rfc1928 and
    # http://en.wikipedia.org/wiki/SOCKS
    # returns the host and port
    def client_handshake
      version = async_recv(1).unpack("C").first
      case version
      when SOCKS5 then client_handshake_v5
      else
        raise "SOCKS version not supported: #{version.inspect}"
      end
    end

    def client_handshake_v5
      nmethods = async_recv(1).unpack("C").first
      *methods = async_recv(nmethods).unpack("C*")
      if methods.include?(METHOD_NO_AUTH)
        packet = [SOCKS5, METHOD_NO_AUTH].pack("C*")
        send_data packet
      else
        raise 'Unsupported authentication method. Only "No Authentication" is supported'
      end

      version, command, reserved, address_type = async_recv(4).unpack("C4")
      remote_host, remote_port = case address_type
      when ATYP_IPV4
        host = IPAddr.ntop async_recv(4)
        port = async_recv(2).unpack('n').first
        [host, port]
      when ATYP_IPV6
        host = IPAddr.ntop async_recv(16)
        port = async_recv(2).unpack('n').first
        [host, port]
      when ATYP_DOMAIN
        domain_len = async_recv(1).unpack("C").first
        host = async_recv(domain_len)
        port = async_recv(2).unpack('n').first
        puts host, port
        [host, port]
      else
        raise "unknown address_type: #{address_type}"
      end 

      @backend = EM.connect host, port, Socks5Backend
      @backend.plexer = self
      packet = ([SOCKS5, REP_SUCCESS, RESERVED, 1, 0, 0, 0, 0, 0]).pack("C8n")
      send_data packet
      puts "buffer is not zero: #{@buffer.unpack("C*")}" if @buffer.bytesize != 0
      @backend.send_data @buffer if @buffer.bytesize != 0

    end

    def async_recv n
      if @buffer.bytesize >= n
        s = @buffer.byteslice(0, n)
        @buffer = @buffer.byteslice(n .. -1)
        puts "async_recv #{n}: #{s.unpack("C*")}"
        return s
      end
      @wait_length = n
      a = Fiber.yield
      puts "async_recv #{n}: #{a.unpack("C*")}"
      a
    end
    
    def receive_data data
      if @fiber.alive?
        @buffer << data
        if @buffer.bytesize >= @wait_length
          s = @buffer.byteslice(0, @wait_length)
          @buffer = @buffer.byteslice(@wait_length .. -1)
          @fiber.resume s
        end
      else
        @backend.send_data data
      end
    end
  end

  module Socks5Backend
    attr_accessor :plexer

    def post_init
    end

    def receive_data data
      @plexer.send_data data
    end

    def unbind
      @plexer.close_connection_after_writing
    end
  end
end