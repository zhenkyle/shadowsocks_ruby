module ShadowsocksRuby
  module Protocols
    # Http Simple Obfuscation Protocol
    #
    # Specification:
    # * https://github.com/shadowsocksr/shadowsocksr/blob/manyuser/shadowsocks/obfsplugin/http_simple.py
    # * https://github.com/shadowsocksr/obfsplugin/blob/master/c/http_simple.c
    class HttpSimpleProtocol
      include DummyHelper
      include BufferHelper

      attr_accessor :next_protocol

      USER_AGENTS = ["Mozilla/5.0 (Windows NT 6.3; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0",
            "Mozilla/5.0 (Windows NT 6.3; WOW64; rv:40.0) Gecko/20100101 Firefox/44.0",
            "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36",
            "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/535.11 (KHTML, like Gecko) Ubuntu/11.10 Chromium/27.0.1453.93 Chrome/27.0.1453.93 Safari/537.36",
            "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:35.0) Gecko/20100101 Firefox/35.0",
            "Mozilla/5.0 (compatible; WOW64; MSIE 10.0; Windows NT 6.2)",
            "Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27",
            "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.3; Trident/7.0; .NET4.0E; .NET4.0C)",
            "Mozilla/5.0 (Windows NT 6.3; Trident/7.0; rv:11.0) like Gecko",
            "Mozilla/5.0 (Linux; Android 4.4; Nexus 5 Build/BuildID) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/30.0.0.0 Mobile Safari/537.36",
            "Mozilla/5.0 (iPad; CPU OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 5_0 like Mac OS X) AppleWebKit/534.46 (KHTML, like Gecko) Version/5.1 Mobile/9A334 Safari/7534.48.3"]

      # @param [Hash] params                          Configuration parameters
      # @option params [String]                :host  shadowsocks server address, required by remoteserver protocol
      # @option params [String]                :port  shadowsocks server port, required by remoteserver protocol
      # @option params [Boolean]               :compatible  compatibility with origin mode, default _true_
      # @option params [String]                :obfs_param   obfs param, optional
      def initialize params = {}
        @params = {:compatible => true }.merge(params)
        @buffer = ''
      end

      def tcp_receive_from_remoteserver_first_packet n
        class << self
          alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_other_packet
        end

        async_recv_until("\r\n\r\n")
        async_recv n
      end

      alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_first_packet

      def tcp_receive_from_remoteserver_other_packet n
        async_recv n
      end

      def tcp_send_to_remoteserver_first_packet data
        if data.length > 30 + 64
          headlen = 30 + Random.rand(64 + 1)
        else
          headlen = data.length
        end
        headdata = data.slice!(0, headlen)
        port = ''
        raise ProtocolError, "No :port params" if @params[:port] == nil
        if @params[:port] != 80
          port = ':' << @params[:port].to_s 
        end

        body = nil
        hosts = @params[:obfs_param] || @params[:host]
        raise ProtocolError, "No :host or :obfs_param parameters" if hosts == nil
        if hosts.include?('#')
          hosts, body = hosts.split('#')
          body = body.gsub(/\n/,"\r\n")
          body = body.gsub(/\\n/,"\r\n")
        end
        hosts = hosts.split(",")
        host = hosts[Random.rand(hosts.length)]

        http_head = "GET /" << headdata.unpack("H*")[0].gsub(/../,'%\0') << " HTTP/1.1\r\n"
        http_head << "Host: " << host << port << "\r\n"

        if body != nil
          http_head << body << "\r\n\r\n"
        else
          http_head << "User-Agent: " + USER_AGENTS[Random.rand(USER_AGENTS.length)] << "\r\n"
          http_head << "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\nAccept-Language: en-US,en;q=0.8\r\nAccept-Encoding: gzip, deflate\r\nDNT: 1\r\nConnection: keep-alive\r\n\r\n"
        end
        send_data(http_head << data)
        class << self
          alias tcp_send_to_remoteserver tcp_send_to_remoteserver_other_packet
        end

      end

      alias tcp_send_to_remoteserver tcp_send_to_remoteserver_first_packet

      def tcp_send_to_remoteserver_other_packet data
        send_data data
      end


      def tcp_receive_from_localbackend_first_packet n
        data = async_recv 10
        if (data =~ /^GET|^POST/) == nil
          if @params[:compatible]
            @buffer << data << async_recv(n - data.length)
          else
            raise PharseError, "not a valid http_simple first packet in strict mode"
          end
        else
          buf = ""
          buf << data << async_recv_until("\r\n\r\n")
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
          alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
        end
        tcp_receive_from_localbackend_other_packet_helper n
      end

      alias tcp_receive_from_localbackend tcp_receive_from_localbackend_first_packet

      def tcp_receive_from_localbackend_other_packet n
        async_recv(n)
      end

      def tcp_send_to_localbackend_first_packet data
        class << self
          alias tcp_send_to_localbackend tcp_send_to_localbackend_other_packet
        end

        header = "HTTP/1.1 200 OK\r\nConnection: keep-alive\r\nContent-Encoding: gzip\r\nContent-Type: text/html\r\nDate: "
        header << Time.now.strftime('%a, %d %b %Y %H:%M:%S GMT')
        header << "\r\nServer: nginx\r\nVary: Accept-Encoding\r\n\r\n"
        send_data header << data
      end

      alias tcp_send_to_localbackend tcp_send_to_localbackend_first_packet

      def tcp_send_to_localbackend_other_packet data
        send_data data
      end

      # helpers
      def get_data_from_http_header buf
        [buf.split("\r\n")[0][/(%..)+/].gsub(/%/,'')].pack("H*")
      end

      def get_host_from_http_header buf
        buf[/^Host: (.+):/,1]
      end

      def async_recv_until str
        @next_protocol.async_recv_until str
      end

      alias tcp_receive_from_client raise_me
      alias tcp_send_to_client raise_me
      #alias tcp_receive_from_remoteserver raise_me
      #alias tcp_send_to_remoteserver raise_me
      #alias tcp_receive_from_localbackend raise_me
      #alias tcp_send_to_localbackend raise_me
      alias tcp_receive_from_destination raise_me
      alias tcp_send_to_destination raise_me

      alias udp_receive_from_client raise_me
      alias udp_send_to_client raise_me
      alias udp_receive_from_remoteserver raise_me
      alias udp_send_to_remoteserver raise_me
      alias udp_receive_from_localbackend raise_me
      alias udp_send_to_localbackend raise_me
      alias udp_receive_from_destination raise_me
      alias udp_send_to_destination raise_me
    end
  end
end