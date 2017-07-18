require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::TlsTicketProtocol::TCP::LocalBackend do
  subject {
    str = [0x17, 3, 3].pack("C*") \
    + ["opaque".length].pack("n") \
    + "opaque"
    obfs_param = nil
    sub = make_a_protocol(str ,{host: '127.0.0.1', key: 'akey' * 4, compatible: false, obfs_param: obfs_param})
    sub
  }

  it_behaves_like "a protocol"

  it "#async_recv should riase on invalid data when compatible: false" do
    expect{subject.async_recv(-1)}.to raise_error(ShadowsocksRuby::PharseError,"decode error")
  end

  it_behaves_like "#send_data", \
    "some data", \
    [0x17, 3, 3].pack("C*") + ["some data".length].pack("n") + "some data",  \
    "some other data", \
    [0x17, 3, 3].pack("C*") + ["some other data".length].pack("n") + "some other data"
end
