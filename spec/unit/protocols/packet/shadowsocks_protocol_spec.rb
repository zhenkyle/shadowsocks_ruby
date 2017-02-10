require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::ShadowsocksProtocol do
  subject { make_a_packet_protocol([3,7].pack("C2") + \
    "abc.com" + \
    [80].pack("n") + "opaque" ) 
  }
  it_behaves_like "a protocol"
  it_behaves_like "a packet protocol"

  describe "methods" do
    it_behaves_like "#tcp_send_to_remoteserver", "some data", "some other data"
    it_behaves_like "#tcp_receive_from_remoteserver", [3,7].pack("C*") + "abc.com" + [80].pack("n") + "opaque" , nil

    it_behaves_like "#tcp_send_to_localbackend", "some data", "some other data"
    it_behaves_like "#tcp_receive_from_localbackend", [3,7].pack("C*") + "abc.com" + [80].pack("n") , nil
  end

  describe " with :version => OTA" do
    subject { make_a_packet_protocol([3,7].pack("C2") + \
      "abc.com" + \
      [80].pack("n") + "opaque", {:version => "OTA"} ) 
    }
    it "#tcp_send_to_remoteserver change first byte" do
      expect(subject.next_protocol).to receive(:send_data).with([3,7].pack("C2") + "abc...")
      subject.tcp_send_to_remoteserver([3,7].pack("C2") + "abc...")
    end
  end

end
