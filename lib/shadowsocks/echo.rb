module Shadowsocks
  module EchoServer
    def receive_data data
      send_data data
    end
  end
end