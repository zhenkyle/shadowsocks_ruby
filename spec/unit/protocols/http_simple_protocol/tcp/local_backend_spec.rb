require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::HttpSimpleProtocol::TCP::LocalBackend do
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
    sub = make_a_protocol_v2([str1],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
    allow(sub.next_protocol).to receive(:async_recv_until).and_return(str2)
    sub
  }

  it_behaves_like "a protocol"


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
    subject.send_data 'abcdefg' * 20
  end

  it_behaves_like "#async_recv", "abcdefg" * 9 + "abcde" , "abc"
end
