require "spec_helper"

describe ShadowsocksRuby::Protocols::ProtocolStack do
  Object.send(:remove_const, :DummyProtocol) if Object.constants.include?(:DummyProtocol)
  class DummyProtocol
    attr_accessor :next_protocol
    def initialize params
    end
  end
  subject {described_class.new([["dummy", {}], ["dummy", {}]], "aes-256-cfb", "secret")}
  it "should build a protocol stack" do
    conn = double("Connection")
    p = subject.build!(conn)
    expect(p.next_protocol.next_protocol).to eq(conn)
  end
end
