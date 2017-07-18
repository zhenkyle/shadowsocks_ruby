require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::VerifySha1Protocol::TCP::RemoteServer do
  subject { make_a_protocol "iv" * 8 + "OPAQUE"}
  it_behaves_like "a protocol"

  it_behaves_like "#send_data", "some data", "iv" * 8 + "SOME DATA" + "HMACSHA1OK", \
    "some other data", ["SOME OTHER DATA".length].pack("n") + "hmacsha1ok" + "SOME OTHER DATA"

  it_behaves_like "#async_recv", "opaque" , nil
end
