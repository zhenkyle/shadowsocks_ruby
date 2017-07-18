require "spec_helper"
require 'evented-spec'
require 'em-http'

RSpec.describe "socks5 proxy server" do
  include EventedSpec::SpecHelper
  it "should be act like a proxy server" do
    em do
      stack1 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["socks5", {}]
      ], "aes-256-cfb", "secret", "TCP")

      stack2 = ShadowsocksRuby::Protocols::ProtocolStack.new([
          ["plain", {}]
      ], "aes-256-cfb", "secret", "TCP")

      server_args = [
        stack1,
        {},
        stack2,
        {}
      ]
      EventMachine.start_server '127.0.0.1', 8388, ShadowsocksRuby::Connections::LocalBackendConnection, *server_args

      connection_opts = {:proxy => {:host => '127.0.0.1', :port => 8388, :type => :socks5 }}

      2.times {
        http = EventMachine::HttpRequest.new('http://www.example.com/', connection_opts).get
        http.callback {
          expect(http.response_header.status).to eq(200)
        }
      }
      
      http = EventMachine::HttpRequest.new('http://www.example.com/', connection_opts).get
      http.callback {
        expect(http.response_header.status).to eq(200)
        done
      }
    end      
  end
end
