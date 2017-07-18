require "spec_helper"
require 'shared_examples_for_protocols'

RSpec.describe ShadowsocksRuby::Protocols::TlsTicketProtocol::TCP::RemoteServer do
  subject {
    str =""
    obfs_param = nil
    make_a_protocol(str, {host: '127.0.0.1', key: 'akey' * 4, obfs_param: obfs_param})
  }

  it_behaves_like "a protocol"

  it "#send_data should look like a ClinetChangeCipherSpec + HandShake + Application Pharse" do
    # see integration test
  end

  it "#async_recv should send ClientHello and receive ServerHello" do
    # see integration test
  end
end
