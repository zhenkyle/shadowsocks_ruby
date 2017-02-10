require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::Socks5Protocol do
  subject { make_a_packet_protocol( \
    [5].pack("C") +
    [1].pack("C") + \
    [0].pack("C") + \
    [5,0,0].pack("C*") + \
    [3,7].pack("C*") + \
    "abc.com" + \
    [80].pack("n") + "opaque" ) 
  }
  it_behaves_like "a protocol"
  it_behaves_like "a packet protocol"

  describe "methods" do
    it_behaves_like "#tcp_send_to_client", "some data", "some other data"
    it_behaves_like "#tcp_receive_from_client", [3,7].pack("C*") + "abc.com" + [80].pack("n") , nil

    it_behaves_like "#tcp_send_to_localbackend", "some data", "some other data"
    it_behaves_like "#tcp_receive_from_localbackend", [3,7].pack("C*") + "abc.com" + [80].pack("n") , nil

  end


end
