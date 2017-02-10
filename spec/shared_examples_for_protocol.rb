ALL_METHODS = [:tcp_receive_from_client, :tcp_send_to_client, \
               :tcp_receive_from_remoteserver, :tcp_send_to_remoteserver, \
               :tcp_receive_from_localbackend, :tcp_send_to_localbackend, \
               :tcp_receive_from_destination, :tcp_send_to_destination, \
               :udp_receive_from_client, :udp_send_to_client, \
               :udp_receive_from_remoteserver, :udp_send_to_remoteserver, \
               :udp_receive_from_localbackend, :udp_send_to_localbackend, \
               :udp_receive_from_destination, :udp_send_to_destination
               ]

RSpec.shared_examples "a protocol" do
  it "should have :next_protocol attribute, which is to be set by caller" do
    expect(subject).to respond_to(:next_protocol)
  end
  it "should respond to :send_data, which is to be injected by caller" do
    expect(subject).to respond_to(:send_data)
  end
  it "should respond to :receive_data, which is to be injected by caller" do
    expect(subject).to respond_to(:async_recv)
  end
  it "should respond to all methods" do
    ALL_METHODS.each do |x|
      expect(subject).to respond_to(x)
    end
  end
end

RSpec.shared_examples "a packet protocol" do
end

RSpec.shared_examples "a cipher protocol" do
end

RSpec.shared_examples "an obfs protocol" do
end


########################################################
#
# method behavies
#
########################################################
RSpec.shared_examples "#tcp_receive_from_client" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.tcp_receive_from_client(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.tcp_receive_from_client(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#tcp_send_to_client" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.tcp_send_to_client("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.tcp_send_to_client("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.tcp_send_to_client("some other data")
  end
end

RSpec.shared_examples "#tcp_receive_from_remoteserver" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.tcp_receive_from_remoteserver(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.tcp_receive_from_remoteserver(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#tcp_send_to_remoteserver" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.tcp_send_to_remoteserver("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.tcp_send_to_remoteserver("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.tcp_send_to_remoteserver("some other data")
  end
end

RSpec.shared_examples "#tcp_receive_from_localbackend" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.tcp_receive_from_localbackend(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.tcp_receive_from_localbackend(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#tcp_send_to_localbackend" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.tcp_send_to_localbackend("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.tcp_send_to_localbackend("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.tcp_send_to_localbackend("some other data")
  end
end

RSpec.shared_examples "#tcp_receive_from_destination" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.tcp_receive_from_destination(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.tcp_receive_from_destination(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#tcp_send_to_destination" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.tcp_send_to_destination("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.tcp_send_to_destination("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.tcp_send_to_destination("some other data")
  end
end

RSpec.shared_examples "#udp_receive_from_client" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.udp_receive_from_client(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.udp_receive_from_client(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#udp_send_to_client" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.udp_send_to_client("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.udp_send_to_client("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.udp_send_to_client("some other data")
  end
end

RSpec.shared_examples "#udp_receive_from_remoteserver" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.udp_receive_from_remoteserver(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.udp_receive_from_remoteserver(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#udp_send_to_remoteserver" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.udp_send_to_remoteserver("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.udp_send_to_remoteserver("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.udp_send_to_remoteserver("some other data")
  end
end

RSpec.shared_examples "#udp_receive_from_localbackend" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.udp_receive_from_localbackend(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.udp_receive_from_localbackend(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#udp_send_to_localbackend" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.udp_send_to_localbackend("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.udp_send_to_localbackend("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.udp_send_to_localbackend("some other data")
  end
end

RSpec.shared_examples "#udp_receive_from_destination" do |expect_all_data, expect_partial_data|
  it "should return all data with parameter -1" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.udp_receive_from_destination(-1)).to eq(expect_all_data)
  end
  it "should return 3 bytes data with parameter 3" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    if (expect_partial_data != nil)
      expect(subject.udp_receive_from_destination(3)).to eq(expect_partial_data)
    end
  end
end

RSpec.shared_examples "#udp_send_to_destination" do |expect_send_first, expect_send_second|
  it "should send first packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_first)
    subject.udp_send_to_destination("some data")
  end
  it "should send other packet data" do
    allow(ShadowsocksRuby::Cipher).to receive(:hmac_sha1_digest).and_return("hmacsha1ok")
    subject.udp_send_to_destination("some data")
    expect(subject.next_protocol).to receive(:send_data).with(expect_send_second)
    subject.udp_send_to_destination("some other data")
  end
end

##########################################################


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

def make_a_packet_protocol str = "", params = {}
  next_protocol = DummyNextProtocol.new
  next_protocol.buffer = str
  allow(next_protocol).to receive(:send_data)
  p = described_class.new(params)
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
  end
  p
end

def make_an_iv_protocol str = "", params = {}
  next_protocol = DummyNextProtocol.new
  next_protocol.buffer = str
  allow(next_protocol).to receive(:send_data)
  cipher = DummyCipher.new
  p = described_class.new({:cipher => cipher}.merge(params))
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
  end
  p
end

def make_an_iv_protocol_v2 ary, params = {}
  next_protocol = instance_double(DummyNextProtocol)
  allow(next_protocol).to receive(:async_recv).and_return(*ary)
  allow(next_protocol).to receive(:send_data)
  cipher = DummyCipher.new  
  p = described_class.new({:cipher => cipher}.merge(params))
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
  end
  p
end

def make_a_no_iv_protocol str = "", params = {}
  next_protocol = DummyNextProtocol.new
  next_protocol.buffer = str
  allow(next_protocol).to receive(:send_data)
  cipher = DummyCipher.new
  p = described_class.new({:cipher => cipher}.merge(params))
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
  end
  p
end

def make_an_obfs_protocol str, params = {}
  next_protocol = DummyNextProtocol.new
  next_protocol.buffer = str
  allow(next_protocol).to receive(:send_data)
  p = described_class.new({}.merge(params))
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
  end
  p
end

def make_an_obfs_protocol_v2 ary, params = {}
  next_protocol = DummyNextProtocol.new
  allow(next_protocol).to receive(:async_recv).and_return(*ary)
  allow(next_protocol).to receive(:send_data)
  class << next_protocol
    def async_recv_until str
    end
  end
  p = described_class.new({}.merge(params))
  p.next_protocol = next_protocol
  class << p
    def async_recv n
      @next_protocol.async_recv n
    end
    def send_data data
      @next_protocol.send_data data
    end
    def async_recv_until str
      @next_protocol.async_recv_until str
    end
  end
  p
end

