require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::IvCipherProtocol do
  subject { make_an_iv_protocol "iv" * 8 + "OPAQUE"}
  it_behaves_like "a protocol"
  it_behaves_like "a cipher protocol"

  describe "methods" do
    it_behaves_like "#tcp_send_to_remoteserver", "iv" * 8 + "SOME DATA", "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_remoteserver", "opaque" , "opa"

    it_behaves_like "#tcp_send_to_localbackend", "iv" * 8 + "SOME DATA", "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_localbackend", "opaque" , "opa"
  end
end
