require "spec_helper"

describe "Echo server" do

  it "should send the same thing to client / testing by real client" do
    class Client < EM::Connection
      def post_init
        #puts "connected to server"
        send_data "hello,world"
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
      EM.start_server "127.0.0.1", 8081, Shadowsocks::EchoServer
      EM.connect '127.0.0.1', 8081, Client
    }
    expect($recv).to eq("hello,world")
  end

  it "should call send the same thing to client / testing by mock" do
    class MockEchoServer    
      include Shadowsocks::EchoServer

      attr_reader :output_buffer

      def send_data data
        @sent = data
      end
    end
    mock = MockEchoServer.new
    mock.receive_data 'abc xyz'
    expect(mock.sent).to eq('abc xyz')
  end
end

