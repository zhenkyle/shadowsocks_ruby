require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::VerifySha1Protocol::TCP::LocalBackend do
  subject { make_a_protocol_v2 ["iv"*8 + [0x10 | 0x03 ,7].pack("C*") + "ABC.COM" + [80].pack("n") + "HMACSHA1OK",
       [6].pack("n"),
       "hmacsha1ok",
       "OPAQUE"]}
  it_behaves_like "a protocol"

  it_behaves_like "#send_data", "some data", "iv" * 8 + "SOME DATA", "some other data", "SOME OTHER DATA"
  it_behaves_like "#async_recv", [0x03 ,7].pack("C*") + "ABC.COM" + [80].pack("n") , nil

  describe "with :compatible => true" do
    subject { make_a_protocol("iv" * 8 + "OPAQUE") }
    it_behaves_like "#async_recv", "opaque" , "opa"
  end

  describe "with :compatible => false" do
    subject { make_a_protocol("iv" * 8 + "OPAQUE", {:compatible => false}) }
    it "should raise error on invalid data" do
      expect {subject.async_recv(-1)}.to raise_error(ShadowsocksRuby::PharseError)
    end
  end

end
