require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::NoIvCipherProtocol do
  subject { make_a_no_iv_protocol "OPAQUE"}
  it_behaves_like "a protocol"
  it_behaves_like "a cipher protocol"

  describe "methods" do
    it_behaves_like "#tcp_send_to_remoteserver", "SOME DATA", "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_remoteserver", "opaque" , "opa"

    it_behaves_like "#tcp_send_to_localbackend", "SOME DATA", "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_localbackend", "opaque" , "opa"
  end
end
