RSpec.shared_examples "a protocol" do
  it "should have :next_protocol attribute, which is to be set by caller" do
    expect(subject).to respond_to(:next_protocol)
  end
  it "should respond to :send_data" do
    expect(subject).to respond_to(:send_data)
  end
  it "should respond to :async_recv" do
    expect(subject).to respond_to(:async_recv)
  end
end


########################################################
#
# method behavies
#
########################################################

RSpec.shared_examples "#send_data" do |send_first, expect_send_first, send_second, expect_send_second|
  it "should send_data to @next_protocol witch expected value" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.send_data(send_first)
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.send_data(send_second)
  end
end

RSpec.shared_examples "#async_recv" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.async_recv(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.async_recv(3)).to eq(expect_partial_data)
    end
  end
end

##########################################################
# 
# helper classes
#
########################################################

# When async_recv is called, return data in buffer
class DummyNextProtocol
  attr_accessor :buffer
  def initialize params = {}
    @params = params
  end
  def async_recv n
    @buffer ||= ''
    if n == -1
      len = @buffer.length
    else
      len = n
    end
    @buffer.slice!(0, len)
  end
  def send_data data
  end
  def async_recv_until str
  end
end

class DummyCipher
  def iv_len
    16
  end
  def key
    "key1" * 4
  end
  def random_iv
    "iv" * 8
  end
  def encrypt data, iv =""
    data.gsub!(/iv/,"IV")
    data.gsub!(/some data/,"SOME DATA")
    data.gsub!(/some other data/,"SOME OTHER DATA")
    data.gsub!(/opaque/,"OPAQUE")
    data.gsub!(/opa/,"OPA")
    data.gsub!(/hmacsha1ok/,"HMACSHA1OK")
    data
  end
  def decrypt data, iv = ""
    data.gsub!(/IV/,"iv")
    data.gsub!(/SOME DATA/,"some data")
    data.gsub!(/SOME OTHER DATA/,"some other data")
    data.gsub!(/OPAQUE/,"opaque")
    data.gsub!(/OPA/,"opa")
    data.gsub!(/HMACSHA1OK/,"hmacsha1ok")
    data
  end
end

##########################################################
# 
# helper methods
#
########################################################

def make_a_protocol str = "", params = {}
  next_protocol = DummyNextProtocol.new
  next_protocol.buffer = str
  cipher = DummyCipher.new  
  p = described_class.new({:cipher => cipher}.merge(params))
  p.next_protocol = next_protocol
  p
end

def make_a_protocol_v2 ary, params = {}
  next_protocol = DummyNextProtocol.new
  allow(next_protocol).to receive(:async_recv).and_return(*ary)
  cipher = DummyCipher.new  
  p = described_class.new({:cipher => cipher}.merge(params))
  p.next_protocol = next_protocol
  p
end
