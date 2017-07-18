require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::HttpSimpleProtocol::TCP::RemoteServer do

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
    sub = make_a_protocol_v2([str2],{host: '127.0.0.1', port: '80', obfs_param: obfs_param})
    allow(sub.next_protocol).to receive(:async_recv_until).and_return(str1)
    sub
  }

  it_behaves_like "a protocol"


  it "should send data with http header to :next_protocol" do
    expect(subject.next_protocol).to receive(:send_data) do |arg|
      expect(arg).to match(/^GET \//)
      expect(arg).to match(/^Host: baidu.com:80/)
      expect(arg).to match(/^User-Agent: abc/)
      expect(arg).to match(/^Accept: text\/html/)
      expect(arg).to match(/^Connection: keep-alive/)
      expect(arg).to match(/\r\n\r\n/)
    end
    subject.send_data 'abcdefg' * 20
  end

  it_behaves_like "#async_recv", "abcdefg" * 20 , nil

end
