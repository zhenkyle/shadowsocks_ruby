require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::PlainProtocol do
  subject {make_a_packet_protocol("opaque")}
  it_behaves_like "a protocol"
  it_behaves_like "a packet protocol"

  describe "methods" do
    it_behaves_like "#tcp_send_to_destination", "some data", "some other data"
    it_behaves_like "#tcp_receive_from_destination", "opaque", nil
    it_behaves_like "#udp_send_to_destination", "some data", "some other data"
    it_behaves_like "#udp_receive_from_destination", "opaque", nil
  end
end
