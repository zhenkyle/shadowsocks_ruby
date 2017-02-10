require "spec_helper"

RSpec.describe ShadowsocksRuby::Util do

  describe "hex encoding" do
    let(:bytes) { [0xDE, 0xAD, 0xBE, 0xEF].pack("c*") }
    let(:hex)   { "deadbeef" }
    it "encodes to hex with bin2hex" do
      expect(ShadowsocksRuby::Util.bin2hex(bytes)).to eq hex
    end
    it "decodes from hex with hex2bin" do
      expect(ShadowsocksRuby::Util.hex2bin(hex)).to eq bytes
    end
  end
  describe "#parse_address_bin" do
    it "should return host, port" do
      str = [3,7].pack("C*") + "abc.com" + [80].pack("n")
      expect(ShadowsocksRuby::Util.parse_address_bin(str)).to eq(["abc.com", 80])
    end
  end

end
