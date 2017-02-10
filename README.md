# ShadowsocksRuby

ShadowsocksRuby is a flexible platform for writing [shadowsocks](https://github.com/shadowsocks/shadowsocks) like tunnel proxy to help you bypass firewalls. With layered protocol strategy, TCP/UDP/(even TLS) connection object and powerful DSL backended by ruby, it make your life easy to develop new tunnel protocols.

Main features include:

* **Popular event-driven I/O model:** utilize very little resource but provding extremely high scalability, performance and stability
* **Vanilla shadowsocks protocol support:** comes with shadowsocks's original version and OTA version protocol support and [shadowsocksr](https://github.com/shadowsocksr/shadowsocksr) 's "http_simple" and "tls_ticket" obfuscation protocol support
* **Cipher method support:** all known shadowsocks cipher method, including `table` and `chacha20`
* **Parallel execution support:** support multi workers by using [Einhorn](https://github.com/stripe/einhorn) socket manager to enable parallelism on multi-core CPU, and extra drb server to exchange data within workers
* **Easy develop your own protocol:** see "Example SOCKS4 Client Proxy in 35 lines"

## Installation

    $ gem install shadowsocks_ruby

## Usage

### Running

After Installation, ShadowsockRuby install 2 executable files for you:

```
$ ssserver-ruby -h
A SOCKS like tunnel proxy that helps you bypass firewalls.

Usage: ssserver-ruby [options]

Proxy options:
    -c, --config [CONFIG]            path to config file (lazy default: config.json)
    -s, --server SERVER_ADDR         server address (default: 0.0.0.0)
    -p, --port SERVER_PORT           server port (default: 8388)
    -k, --password PASSWORD          password
    -O, --packet-protocol NAME       packet protocol (default: origin)
    -G, --packet-param PARAM         packet protocol parameters
    -m, --cipher-protocol NAME       cipher protocol (default: aes-256-cfb)
    -o, --obfs-protocol [NAME]       obfuscate protocol (lazy default: http_simple)
    -g, --obfs-param PARAM           obfuscate protocol parameters
    -t, --timeout TIMEOUT            timeout in seconds, default: 300
        --fast-open                  use TCP_FASTOPEN, requires Linux 3.7+
    -E, --einhorn                    Use Einhorn socket manager

Common options:
    -h, --help                       display help message
    -v, --vv                         verbose mode
    -q, --qq                         quiet mode, only show warnings/errors
        --version                    show version information
```

and

```
$ sslocal-ruby -h
A SOCKS like tunnel proxy that helps you bypass firewalls.

Usage: sslocal-ruby [options]

Proxy options:
    -c, --config [CONFIG]            path to config file (lazy default: config.json)
    -s, --server SERVER_ADDR         server address
    -p, --port SERVER_PORT           server port (default: 8388)
    -b, --bind_addr LOCAL_ADDR       local binding address (default: 0.0.0.0)
    -l, --local_port LOCAL_PORT      local port  (default: default: 1080)
    -k, --password PASSWORD          password
    -O, --packet-protocol NAME       packet protocol (default: origin)
    -G, --packet-param PARAM         packet protocol parameters
    -m, --cipher-protocol NAME       cipher protocol (default: aes-256-cfb)
    -o, --obfs-protocol [NAME]       obfuscate protocol (lazy default: http_simple)
    -g, --obfs-param PARAM           obfuscate protocol parameters
    -t, --timeout TIMEOUT            timeout in seconds, default: 300
        --fast-open                  use TCP_FASTOPEN, requires Linux 3.7+
    -E, --einhorn                    Use Einhorn socket manager

Common options:
    -h, --help                       display help message
    -v, --vv                         verbose mode
    -q, --qq                         quiet mode, only show warnings/errors
        --version                    show version information
```

### Signals

    QUIT - Graceful shutdown. Stop accepting connections immediately and
           wait as long as necessary for all connections to close.

    TERM - Fast shutdown. Stop accepting connections immediately and wait
           up to 10 seconds for connections to close before forcing
           termination.

    INT  - Same as TERM


### Example to establish a basic tunnel proxy

    # On remote machine (eg IP: 1.2.3.4)
    ssserver-ruby -k secret

    # Then on local machine
    sslocal-ruby -k secret -s 1.2.3.4

    #Then using `127.0.0.1:1080` as your local SOCKS5 server.


## Development
To get started, check out [documentation](http://www.rubydoc.info/github/zhenkyle/shadowsocks_ruby) then check out [spec](https://github.com/zhenkyle/shadowsocks_ruby/tree/master/spec) and [features](https://github.com/zhenkyle/shadowsocks_ruby/tree/master/features).

### Example SOCKS4 Client Protocol in 35 lines

Here's a fully-functional protocol to make ShadowsocksRuby support SOCKS4 client:

```ruby
module ShadowsocksRuby
  module Protocols
    class Socks4Protocol
      attr_accessor :next_protocol
      def initialize params = {}; end

      def tcp_receive_from_client_first_packet n
        data = async_recv(8)
        v, c, port, o1, o2, o3, o4, user = data.unpack("CCnC4a*")
        data << async_recv_until("\0")
        if v != 4 or c != 1
          send_data "\0\x5b\0\0\0\0\0\0" 
          raise PharseError, "SOCKS version or command not supported: #{v}, #{c}"
        end
        send_data "\0\x5a\0\0\0\0\0\0"
        class << self
          alias tcp_receive_from_client tcp_receive_from_client_other_packet
        end
        "\x01" + [o1, o2, o3, o4, port].pack("C4n") # return address_bin
      end

      alias tcp_receive_from_client tcp_receive_from_client_first_packet

      def tcp_receive_from_client_other_packet n
        async_recv(n)
      end

      def tcp_send_to_client data
        send_data data
      end

      def async_recv_until(str) @next_protocol.async_recv_until(str); end
    end
  end
end
```



## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zhenkyle/shadowsocks_ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

If you send pull request to add a new protocol, please include a RSpec spec (for unit and integration test) or a Cucumber feature (for acceptance test). 

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

