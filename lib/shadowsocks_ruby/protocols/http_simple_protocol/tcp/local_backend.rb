module ShadowsocksRuby
  module Protocols
    # Http Simple Obfuscation Protocol
    #
    # Specification:
    # * https://github.com/shadowsocksr/shadowsocksr/blob/manyuser/shadowsocks/obfsplugin/http_simple.py
    # * https://github.com/shadowsocksr/obfsplugin/blob/master/c/http_simple.c
    module HttpSimpleProtocol
      module TCP
        class LocalBackend
          include BufferHelper

          attr_accessor :next_protocol

          # @param [Hash] params                          Configuration parameters
          # @option params [String]                :host  shadowsocks server address, required by remoteserver protocol
          # @option params [String]                :port  shadowsocks server port, required by remoteserver protocol
          # @option params [Boolean]               :compatible  compatibility with origin mode, default _true_
          # @option params [String]                :obfs_param   obfs param, optional
          def initialize params = {}
            @params = {:compatible => true }.merge(params)
            @buffer = ''
          end

          def async_recv_first_packet n
            data = @next_protocol.async_recv 10
            if (data =~ /^GET|^POST/) == nil
              if @params[:compatible]
                @buffer << data << @next_protocol.async_recv(n - data.length)
              else
                raise PharseError, "not a valid http_simple first packet in strict mode"
              end
            else
              buf = ""
              buf << data << @next_protocol.async_recv_until("\r\n\r\n")
              host = get_host_from_http_header(buf)
              if host != nil && @params[:obfs_param] != nil
                hosts = @params[:obfs_param]
                if hosts.include?('#')
                  hosts, body = hosts.split('#')
                  body = body.gsub(/\n/,"\r\n")
                  body = body.gsub(/\\n/,"\r\n")
                end
                hosts = hosts.split(",") 
                if !hosts.include?(host)
                  raise PharseError, "request host not in :obfs_param"
                end
              end
              ret_buf = get_data_from_http_header(buf)
              raise PharseError, "not a valid request" if ret_buf.length < 4
              @buffer << ret_buf
            end

            class << self
              alias async_recv async_recv_other_packet
            end
            async_recv_other_packet_helper n
          end

          alias async_recv async_recv_first_packet

          def async_recv_other_packet n
            @next_protocol.async_recv(n)
          end

          def send_data_first_packet data
            class << self
              alias send_data send_data_other_packet
            end

            header = "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nContent-Encoding: gzip\r\nContent-Type: text/html\r\nDate: "
            header << Time.now.strftime('%a, %d %b %Y %H:%M:%S GMT')
            header << "\r\nServer: nginx\r\nVary: Accept-Encoding\r\n\r\n"
            send_data header << data
          end

          alias send_data send_data_first_packet

          def send_data_other_packet data
            @next_protocol.send_data data
          end

          # helper
          def get_data_from_http_header buf
            [buf.split("\r\n")[0][/(%..)+/].gsub(/%/,'')].pack("H*")
          end

          def get_host_from_http_header buf
            buf[/^Host: (.+):/,1]
          end

        end
      end
    end
  end
end