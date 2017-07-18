require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::PlainProtocol::TCP::Destination do
  subject {make_a_protocol "opaque"}
  it_behaves_like "a protocol"
  it_behaves_like "#send_data", "some data", "some data", "some other data", "some other data"
  it_behaves_like "#async_recv", "opaque", nil
end
