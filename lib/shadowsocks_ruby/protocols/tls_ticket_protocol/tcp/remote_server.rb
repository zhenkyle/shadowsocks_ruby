require 'lrucache'
require 'shadowsocks_ruby/protocols/tls_ticket_protocol/tcp/helper'

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
    module TlsTicketProtocol
      module TCP
        class RemoteServer
          include BufferHelper
          include Helper

          attr_accessor :next_protocol

          # @param [Hash] params                                Configuration parameters
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
            @connected = EM::DefaultDeferrable.new
          end

          def send_data_first_packet data
            @connected.callback { send_client_change_cipherspec_and_finish data }
            class << self
              alias send_data send_data_other_packet
            end

          end

          alias send_data send_data_first_packet

          # TLS 1.2 Application Pharse
          def send_data_other_packet data
            @connected.callback { send_data_application_pharse data }
          end

          def async_recv_first_packet n
            send_client_hello
            recv_server_hello
            @connected.succeed
            class << self
              alias async_recv async_recv_other_packet
            end
            async_recv_other_packet n
          end

          alias async_recv async_recv_first_packet

          # TLS 1.2 Application Pharse
          def async_recv_other_packet n
            head = @next_protocol.async_recv 3
            if head != [CTYPE_Application, *VERSION_TLS_1_2].pack("C3")
              raise PharseError, "client_decode appdata error"
            end
            size = @next_protocol.async_recv(2).unpack("n")[0]
            @buffer << @next_protocol.async_recv(size)

            async_recv_other_packet_helper n
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

            @next_protocol.send_data(handshake_message)
          end

          def send_client_change_cipherspec_and_finish data
            buf = ""
            buf << [CTYPE_ChangeCipherSpec, *VERSION_TLS_1_2, 0, 1, 1].pack("C*")
            buf << [CTYPE_Handshake, *VERSION_TLS_1_2, 32].pack("C3n") << Random.new.bytes(22)
            buf << ShadowsocksRuby::Cipher::hmac_sha1_digest(@params[:key] + @client_id, buf)
            buf << [CTYPE_Application, *VERSION_TLS_1_2, data.length].pack("C3n") << data
            @next_protocol.send_data buf
          end

          def recv_server_hello
            data = @next_protocol.async_recv(129) # ServerHello 76 + ServerChangeSipherSpec 6 + Finished 37
            verify = data[11 ... 33]
            if ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, verify) != data[33 ... 43]
              raise PharseError, "client_decode data error"
            end
          end

          def make_ext_sni host
              name_type = 0 #host_name
              server_name = [name_type, host.length].pack("Cn") << host
              server_name_list = [server_name.length].pack("n") << server_name

              type = Util.hex2bin("0000")
              data = [server_name_list.length].pack("n") << server_name_list

              return type << data
          end

        end
      end
    end
  end
end