require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::NoIvCipherProtocol::TCP::RemoteServer do
  subject { make_a_protocol "OPAQUE"}
  it_behaves_like "a protocol"
  it_behaves_like "#send_data", "some data", "SOME DATA", "some other data", "SOME OTHER DATA"
  it_behaves_like "#async_recv", "opaque" , "opa"
end
