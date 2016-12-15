require "spec_helper"

describe "Socks5 server" do

  it "should send greeting to client / testing by real client" do
    class Client < EM::Connection
      def post_init
        #puts "connected to server"
        send_data [5, 1, 0].pack("C*")
      end

      def receive_data data
        $recv = data
        EventMachine::stop
      end

      def unbind
        #puts "disconnected to server"
      end
    end

    EM.run {
      EM.start_server "127.0.0.1", 10000, Shadowsocks::Socks5Server
      EM.connect '127.0.0.1', 10000, Client
    }
    expect($recv).to eq([5, 0].pack("C*"))
  end

  it "should call send the same thing to client / testing by mock" do
    class MockSocks5Server    
      include Shadowsocks::Socks5Server
      def initialize
        @sent = ''
      end

      attr_reader :sent

      def clear_sent
        @sent = ''
      end

      def send_data data
        @sent += data
      end
    end
    mock = MockSocks5Server.new
    mock.post_init
    mock.receive_data [5, 2].pack("C*")
    mock.receive_data [0, 1].pack("C*")
    expect(mock.sent).to eq([5, 0].pack("C*"))
    mock.clear_sent
    mock.receive_data [5, 0, 0, 1].pack("C4")
    mock.receive_data [202, 96, 181, 2].pack("C4")
    mock.receive_data [443].pack("n")
    expect(mock.sent).to eq([5, 0, 0, 1, 0, 0, 0, 0, 0].pack("C8n"))
    mock.clear_sent
  end
end

