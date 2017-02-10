require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::VerifySha1Protocol do
  subject { make_an_iv_protocol_v2 ["iv"*8 + [0x10 | 0x03 ,7].pack("C*") + "ABC.COM" + [80].pack("n") + "HMACSHA1OK",
       [6].pack("n"),
       "hmacsha1ok",
       "OPAQUE"]}
  it_behaves_like "a protocol"
  it_behaves_like "a cipher protocol"

  describe "localbackend methods" do
    it_behaves_like "#tcp_send_to_localbackend", "iv" * 8 + "SOME DATA", "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_localbackend", [0x03 ,7].pack("C*") + "ABC.COM" + [80].pack("n") , nil
  end

  describe "remoteserver methods" do
    subject { make_an_iv_protocol "iv" * 8 + "OPAQUE"}
    it_behaves_like "#tcp_send_to_remoteserver", "iv" * 8 + "SOME DATA" + "HMACSHA1OK", \
    ["SOME OTHER DATA".length].pack("n") + "hmacsha1ok" + "SOME OTHER DATA"
    it_behaves_like "#tcp_receive_from_remoteserver", "opaque" , nil
  end

  describe "with :compatible => true" do
    subject { make_an_iv_protocol("iv" * 8 + "OPAQUE") }
    it_behaves_like "#tcp_receive_from_localbackend", "opaque" , "opa"
  end

  describe "with :compatible => false" do
    subject { make_an_iv_protocol("iv" * 8 + "OPAQUE", {:compatible => false}) }
    it "should raise error on invalid data" do
      expect {subject.tcp_receive_from_localbackend(-1)}.to raise_error(ShadowsocksRuby::PharseError)
    end
  end

end
