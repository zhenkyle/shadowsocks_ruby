require "spec_helper"

describe ShadowsocksRuby::Protocols::ProtocolStack do
  Object.send(:remove_const, :DummyProtocol) if Object.constants.include?(:DummyProtocol)
  module DummyProtocol
    module TCP
      class Client
        attr_accessor :next_protocol
        def initialize params
        end
      end
    end
  end
  subject {described_class.new([["dummy", {}], ["dummy", {}]], "aes-256-cfb", "secret", "TCP")}
  it "should build a protocol stack" do
    conn = instance_double("ShadowsocksRuby::Connections::ClientConnection")
    allow(conn).to receive(:is_a?).and_return(true)
    p = subject.build!(conn)
    expect(p.next_protocol.next_protocol).to eq(conn)
  end
end
