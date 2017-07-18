require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::Socks5Protocol::TCP::LocalBackend do
  subject { make_a_protocol( \
    [5].pack("C") +
    [1].pack("C") + \
    [0].pack("C") + \
    [5,0,0].pack("C*") + \
    [3,7].pack("C*") + \
    "abc.com" + \
    [80].pack("n") + "opaque" ) 
  }
  it_behaves_like "a protocol"
  it_behaves_like "#send_data", "some data", "some data", "some other data", "some other data"
  it_behaves_like "#async_recv", [3,7].pack("C*") + "abc.com" + [80].pack("n") , nil
end
