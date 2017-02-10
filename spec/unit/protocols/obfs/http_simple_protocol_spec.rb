require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::HttpSimpleProtocol do
  it_behaves_like "a protocol"
  it_behaves_like "an obfs protocol"


  describe "#tcp_send_to_remoteserver" do
    subject {
      obfs_param = <<HEREDOC
baidu.com#User-Agent: abc\nAccept: text/html\nConnection: keep-alive
HEREDOC
      obfs_param = obfs_param.chop
      make_an_obfs_protocol_v2([""],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
    }

    it "should send data with http header to :next_protocol" do
      expect(subject.next_protocol).to receive(:send_data) do |arg|
        expect(arg).to match(/^GET \//)
        expect(arg).to match(/^Host: baidu.com:80/)
        expect(arg).to match(/^User-Agent: abc/)
        expect(arg).to match(/^Accept: text\/html/)
        expect(arg).to match(/^Connection: keep-alive/)
        expect(arg).to match(/\r\n\r\n/)
      end
      subject.tcp_send_to_remoteserver 'abcdefg' * 20
    end
  end

  describe "#tcp_send_to_localbackend" do
    subject {
      obfs_param = <<HEREDOC
baidu.com#User-Agent: abc\nAccept: text/html\nConnection: keep-alive
HEREDOC
      obfs_param = obfs_param.chop
      make_an_obfs_protocol_v2([""],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
    }
    it "should send data with http header to :next_protocol" do
      expect(subject.next_protocol).to receive(:send_data) do |arg|
        expect(arg).to match(/^HTTP\/1.1 200 OK/)
        expect(arg).to match(/^Connection: keep-alive/)
        expect(arg).to match(/^Content-Encoding: gzip/)
        expect(arg).to match(/^Content-Type: text\/html/)
        expect(arg).to match(/^Server: nginx/)
        expect(arg).to match(/^Vary: Accept-Encoding/)
        expect(arg).to match(/\r\n\r\n/)
        expect(arg).to match('abcdefg' * 20)
      end
      subject.tcp_send_to_localbackend 'abcdefg' * 20
    end
  end

  describe "#tcp_receive_from_remoteserver" do
    subject {

    str1 = "HTTP/1.1 200 OK" + "\r\n" +
           "Connection: keep-alive" + "\r\n" +
           "Content-Encoding: gzip" + "\r\n" +
           "Content-Type: text/html" + "\r\n" +
           "Date: Wed, 25 Jan 2017 20:49:42 GMT" + "\r\n" +
           "Server: nginx" + "\r\n" +
           "Vary: Accept-Encoding" + "\r\n\r\n"
    str2 = "abcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefgabcdefg"
       obfs_param = <<HEREDOC
baidu.com#User-Agent: abc\nAccept: text/html\nConnection: keep-alive
HEREDOC
      obfs_param = obfs_param.chop
      sub = make_an_obfs_protocol_v2([str2],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
      allow(sub.next_protocol).to receive(:async_recv_until).and_return(str1)
      sub
    }
    it_behaves_like "#tcp_receive_from_remoteserver", "abcdefg" * 20 , nil
  end

  describe "#tcp_receive_from_localbackend" do
    subject {
      str1 = "GET /%61%6"
      str2 = "2%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65%66%67%61%62%63%64%65 HTTP/1.1" + "\r\n" \
           + "Host: baidu.com:80" + "\r\n" \
           + "User-Agent: abc" + "\r\n" \
           + "Accept: text/html" + "\r\n" \
           + "Connection: keep-alive" + "\r\n\r\n"
       obfs_param = <<HEREDOC
baidu.com#User-Agent: abc\nAccept: text/html\nConnection: keep-alive
HEREDOC
      obfs_param = obfs_param.chop
      sub = make_an_obfs_protocol_v2([str1],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
      allow(sub.next_protocol).to receive(:async_recv_until).and_return(str2)
      sub
    }
    it_behaves_like "#tcp_receive_from_localbackend", "abcdefg" * 9 + "abcde" , "abc"
  end

end
