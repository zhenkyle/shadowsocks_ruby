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
        class LocalBackend
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

          def async_recv_first_packet n
            class << self
              alias async_recv async_recv_other_packet
            end
            recv_client_hello
            @no_effect ||= nil
            if !@no_effect
              send_server_hello
              recv_client_change_cipherspec_and_finish
              async_recv_other_packet n
            else
              async_recv_other_packet_helper n
            end
          end

          alias async_recv async_recv_first_packet

          # TLS 1.2 Application Pharse
          def async_recv_other_packet n
            @no_effect ||= nil
            if !@no_effect
              begin
                head = @next_protocol.async_recv 3
                if head != [CTYPE_Application, *VERSION_TLS_1_2].pack("C3")
                  raise PharseError, "server_decode appdata error"
                end
                size = @next_protocol.async_recv(2).unpack("n")[0]
              end while size == 0
              @buffer << @next_protocol.async_recv(size)
            end

            async_recv_other_packet_helper n
          end

          def send_data data
            @no_effect ||= nil
            if !@no_effect
              send_data_application_pharse data
            else
              @next_protocol.send_data data
            end
          end

          def recv_server_hello
            data = @next_protocol.async_recv(129) # ServerHello 76 + ServerChangeSipherSpec 6 + Finished 37
            verify = data[11 ... 33]
            if ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, verify) != data[33 ... 43]
              raise PharseError, "client_decode data error"
            end
          end

          def recv_client_hello
            data = @next_protocol.async_recv 3
            if data != [CTYPE_Handshake, *VERSION_TLS_1_0].pack("C3")
              if @params[:compatible]
                @buffer = data
                @no_effect = true
                return
              else
                raise PharseError, "decode error"
              end
            end

            len_client_handshake_message = @next_protocol.async_recv(2).unpack("n")[0]
            client_handshake_message = @next_protocol.async_recv(len_client_handshake_message)

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
            @next_protocol.send_data data # len 129
          end

          def recv_client_change_cipherspec_and_finish
            data = @next_protocol.async_recv 43
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

        end
      end
    end
  end
end