require 'lrucache'

module ShadowsocksRuby
  module Protocols
    # TLS 1.2 Obfuscation Protocol
    #
    # Specification:
    # * https://github.com/shadowsocksr/shadowsocksr/blob/manyuser/shadowsocks/obfsplugin/obfs_tls.py
    # * https://github.com/shadowsocksr/obfsplugin/blob/master/c/tls1.2_ticket.c
    #
    # TLS 1.2 Reference:
    # * https://en.wikipedia.org/wiki/Transport_Layer_Security
    # * https://tools.ietf.org/html/rfc5246
    # * https://tools.ietf.org/html/rfc5077
    # * https://tools.ietf.org/html/rfc6066
    class TlsTicketProtocol
      include DummyHelper
      include BufferHelper

      VERSION_SSL_3_0 = [3, 0]
      VERSION_TLS_1_0 = [3, 1]
      VERSION_TLS_1_1 = [3, 2]
      VERSION_TLS_1_2 = [3, 3]

      #Content types
      CTYPE_ChangeCipherSpec = 0x14
      CTYPE_Alert = 0x15
      CTYPE_Handshake = 0x16
      CTYPE_Application = 0x17
      CTYPE_Heartbeat = 0x18

      #Message types
      MTYPE_HelloRequest = 0 
      MTYPE_ClientHello = 1
      MTYPE_ServerHello = 2
      MTYPE_NewSessionTicket = 4
      MTYPE_Certificate = 11
      MTYPE_ServerKeyExchange = 12
      MTYPE_CertificateRequest = 13
      MTYPE_ServerHelloDone = 14
      MTYPE_CertificateVerify = 15
      MTYPE_ClientKeyExchange = 16
      MTYPE_Finished = 20

      attr_accessor :next_protocol

      # @param [Hash]                          configuration parameters
      # @option params [String]                :host        shadowsocks server address, required by remoteserver protocol
      # @option params [String]                :key         key, required by both remoteserver and localbackend protocol
      # @option params [Boolean]               :compatible  compatibility with origin mode, default _true_
      # @option params [String]                :obfs_param  obfs param, optional
      # @option params [LRUCache]              :lrucache    lrucache, optional, it intened to be a lrucache Proxy if provided
      def initialize params = {}
        @params = {:compatible => true}.merge(params)
        @buffer = ''
        @client_id = Random.new.bytes(32)
        @max_time_dif = 60 * 60 * 24 # time dif (second) setting
        @startup_time = Time.now.to_i - 60 * 30
        @client_data = @params[:lrucache] || LRUCache.new(:ttl => 60 * 5)
      end

      def tcp_send_to_remoteserver_first_packet data
        send_client_change_cipherspec_and_finish data

        class << self
          alias tcp_send_to_remoteserver tcp_send_to_remoteserver_other_packet
        end

      end

      alias tcp_send_to_remoteserver tcp_send_to_remoteserver_first_packet

      # TLS 1.2 Application Pharse
      def tcp_send_to_remoteserver_other_packet data
        send_data_application_pharse data
      end

      def tcp_receive_from_remoteserver_first_packet n
        send_client_hello
        recv_server_hello
        class << self
          alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_other_packet
        end
        tcp_receive_from_remoteserver_other_packet n
      end

      alias tcp_receive_from_remoteserver tcp_receive_from_remoteserver_first_packet

      # TLS 1.2 Application Pharse
      def tcp_receive_from_remoteserver_other_packet n
        head = async_recv 3
        if head != [CTYPE_Application, *VERSION_TLS_1_2].pack("C3")
          raise PharseError, "client_decode appdata error"
        end
        size = async_recv(2).unpack("n")[0]
        @buffer << async_recv(size)

        tcp_receive_from_remoteserver_other_packet_helper n
      end



      def tcp_receive_from_localbackend_first_packet n
        class << self
          alias tcp_receive_from_localbackend tcp_receive_from_localbackend_other_packet
        end
        recv_client_hello
        @no_effect ||= nil
        if !@no_effect
          send_server_hello
          recv_client_change_cipherspec_and_finish
          tcp_receive_from_localbackend_other_packet n
        else
          tcp_receive_from_localbackend_other_packet_helper n
        end
      end

      alias tcp_receive_from_localbackend tcp_receive_from_localbackend_first_packet

      # TLS 1.2 Application Pharse
      def tcp_receive_from_localbackend_other_packet n
        @no_effect ||= nil
        if !@no_effect
          head = async_recv 3
          if head != [CTYPE_Application, *VERSION_TLS_1_2].pack("C3")
            raise PharseError, "server_decode appdata error"
          end
          size = async_recv(2).unpack("n")[0]
          @buffer << async_recv(size)
        end

        tcp_receive_from_localbackend_other_packet_helper n
      end

      def tcp_send_to_localbackend data
        @no_effect ||= nil
        if !@no_effect
          send_data_application_pharse data
        else
          send_data data
        end
      end

      # helpers
      def get_random
        verifyid = [Time.now.to_i].pack("N") << Random.new.bytes(18)
        hello = ""
        hello << verifyid # Random part 1
        hello << ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, verifyid) # Random part 2
      end

      def send_client_hello
        client_hello = ""
        
        client_hello << [*VERSION_TLS_1_2].pack("C2") # ProtocolVersion
        client_hello << get_random # Random len 32
        client_hello << [32].pack("C") << @client_id # SessionID
        client_hello << Util.hex2bin("001cc02bc02fcca9cca8cc14cc13c00ac014c009c013009c0035002f000a") # CipherSuite
        client_hello << Util.hex2bin("0100") # CompressionMethod

        ext = Util.hex2bin("ff01000100") # Extension 1 (type ff01 + len 0001 + data 00 )
        
        hosts = @params[:obfs_param] || @params[:host]
        if (hosts == nil or hosts == "")
          raise PharseError, "No :host or :obfs_param parameters"
        end
        if (("0".."9").include? hosts[-1])
          hosts = ""
        end
        hosts = hosts.split(",")
        if hosts.length != 0
          host = hosts[Random.rand(hosts.length)]
        else
          host = ""
        end
        ext << make_ext_sni(host) # Extension 2
        ext << Util.hex2bin("00170000") # Extension 3 (type 0017 + len 0000)
        ext << Util.hex2bin("002300d0") << Random.new.bytes(208) # ticket, Extension 4 (type 0023 + len 00d0 + data)
        ext << Util.hex2bin("000d001600140601060305010503040104030301030302010203") # Extension 5 (type 000d + len 0016 + data)
        ext << Util.hex2bin("000500050100000000") # Extension 6 (type 0005 + len 0005 + data)
        ext << Util.hex2bin("00120000") # Extension 7 (type 0012 + len 0000)
        ext << Util.hex2bin("75500000") # Extension 8 (type 7550 + len 0000)
        ext << Util.hex2bin("000b00020100") # Extension 9 (type 000b + len 0002 + data)
        ext << Util.hex2bin("000a0006000400170018") # Extension 10 (type 000a + len 0006 + data)

        client_hello << [ext.length].pack("n") << ext # Extension List

        client_handshake_message = [MTYPE_ClientHello, 0, client_hello.length].pack("CCn") << client_hello
        handshake_message = [CTYPE_Handshake,*VERSION_TLS_1_0, client_handshake_message.length].pack("C3n") << client_handshake_message

        send_data(handshake_message)
      end

      def send_client_change_cipherspec_and_finish data
        buf = ""
        buf << [CTYPE_ChangeCipherSpec, *VERSION_TLS_1_2, 0, 1, 1].pack("C*")
        buf << [CTYPE_Handshake, *VERSION_TLS_1_2, 32].pack("C3n") << Random.new.bytes(22)
        buf << ShadowsocksRuby::Cipher::hmac_sha1_digest(@params[:key] + @client_id, buf)
        buf << [CTYPE_Application, *VERSION_TLS_1_2, data.length].pack("C3n") << data
        send_data buf
      end

      def recv_server_hello
        data = async_recv(129) # ServerHello 76 + ServerChangeSipherSpec 6 + Finished 37
        verify = data[11 ... 33]
        if ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, verify) != data[33 ... 43]
          raise PharseError, "client_decode data error"
        end
      end

      def recv_client_hello
        data = async_recv 3
        if data != [CTYPE_Handshake, *VERSION_TLS_1_0].pack("C3")
          if @params[:compatible]
            @buffer = data
            @no_effect = true
            return
          else
            raise PharseError, "decode error"
          end
        end

        len_client_handshake_message = async_recv(2).unpack("n")[0]
        client_handshake_message = async_recv(len_client_handshake_message)

        if (client_handshake_message.slice!(0, 2) != [MTYPE_ClientHello, 0].pack("C2"))
          raise PharseError, "tls_auth not client hello message"
        end

        len_client_hello = client_handshake_message.slice!(0, 2).unpack("n")[0]
        client_hello = client_handshake_message

        if (len_client_hello != client_hello.length )
          raise PharseError, "tls_auth wrong message size"
        end

        if (client_hello.slice!(0,2) != [*VERSION_TLS_1_2].pack("C2"))
          raise PharseError, "tls_auth wrong tls version"
        end

        verifyid = client_hello.slice!(0, 32)

        len_sessionid = client_hello.slice!(0,1).unpack("C")[0]
        if (len_sessionid < 32)
          raise PharseError, "tls_auth wrong sessionid_len"
        end

        sessionid = client_hello.slice!(0, len_sessionid)
        @client_id = sessionid

        sha1 = ShadowsocksRuby::Cipher::hmac_sha1_digest(@params[:key] + sessionid, verifyid[0, 22])
        utc_time = Time.at(verifyid[0, 4].unpack("N")[0])
        time_dif = Time.now.to_i - utc_time.to_i

        #if @params[:obfs_param] != nil
        #  @max_time_dif = @params[:obfs_param].to_i
        #end
        if @max_time_dif > 0 && (time_dif.abs > @max_time_dif or utc_time.to_i - @startup_time < - @max_time_dif / 2)
          raise PharseError, "tls_auth wrong time"
        end

        if sha1 != verifyid[22 .. -1]
          raise PharseError, "tls_auth wrong sha1"
        end

        if @client_data[verifyid[0, 22]]
          raise PharseError, "replay attack detect, id = #{Util.bin2hex(verifyid)}"
        end
        @client_data[verifyid[0, 22]] = sessionid
      end

      def send_server_hello
        data = [*VERSION_TLS_1_2].pack("C2")
        data << get_random
        data << Util.hex2bin("20") # len 32 in decimal
        data << @client_id
        data << Util.hex2bin("c02f000005ff01000100")
        data = Util.hex2bin("0200") << [data.length].pack("n") << data
        data = Util.hex2bin("160303") << [data.length].pack("n") << data # ServerHello len 86 (11 + 32 + 1 + 32 + 10)
        data << Util.hex2bin("14") << [*VERSION_TLS_1_2].pack("C2") << Util.hex2bin("000101") # ChangeCipherSpec len (6)
        data << Util.hex2bin("16") << [*VERSION_TLS_1_2].pack("C2") << Util.hex2bin("0020") << Random.new.bytes(22)
        data << ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, data) # Finished len(37)
        send_data data # len 129
      end

      def recv_client_change_cipherspec_and_finish
        data = async_recv 43
        if data[0, 6] !=  [CTYPE_ChangeCipherSpec, *VERSION_TLS_1_2, 0, 1, 1].pack("C*") # ChangeCipherSpec
          raise PharseError, "server_decode data error"
        end
        if data[6, 5] != [CTYPE_Handshake, *VERSION_TLS_1_2, 32].pack("C3n") # Finished
          raise PharseError, "server_decode data error"
        end
        if ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, data[0, 33]) != data[33, 10]
          raise PharseError, "server_decode data error"
        end
      end

      def send_data_application_pharse data
        buf = ""
        while data.length > 2048
          size = [Random.rand(65535) % 4096 + 100, data.length].min
          buf << [CTYPE_Application, *VERSION_TLS_1_2, size].pack("C3n") << data.slice!(0, size)
        end
        if data.length > 0
          buf << [CTYPE_Application, *VERSION_TLS_1_2, data.length].pack("C3n") << data
        end
        send_data buf
      end

      def make_ext_sni host
          name_type = 0 #host_name
          server_name = [name_type, host.length].pack("Cn") << host
          server_name_list = [server_name.length].pack("n") << server_name

          type = Util.hex2bin("0000")
          data = [server_name_list.length].pack("n") << server_name_list

          return type << data
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