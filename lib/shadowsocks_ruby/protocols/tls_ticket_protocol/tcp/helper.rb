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
    module TlsTicketProtocol
      module TCP
        module Helper

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

          # helpers
          def get_random
            verifyid = [Time.now.to_i].pack("N") << Random.new.bytes(18)
            hello = ""
            hello << verifyid # Random part 1
            hello << ShadowsocksRuby::Cipher.hmac_sha1_digest(@params[:key] + @client_id, verifyid) # Random part 2
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
            @next_protocol.send_data buf
          end

        end
      end
    end
  end
end