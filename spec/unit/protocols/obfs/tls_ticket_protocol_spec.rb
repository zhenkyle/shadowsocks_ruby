require "spec_helper"
require 'shared_examples_for_protocol'

RSpec.describe ShadowsocksRuby::Protocols::TlsTicketProtocol do
  it_behaves_like "a protocol"
  it_behaves_like "an obfs protocol"


  describe "#tcp_send_to_remoteserver" do
    subject {
      str =""
      obfs_param = nil
      make_an_obfs_protocol(str, {host: '127.0.0.1', key: 'akey' * 4, obfs_param: obfs_param})
    }
    it "should look like a ClinetChangeCipherSpec + HandShake + Application Pharse" do
      # see integration test
    end
  end

  describe "#tcp_receive_from_remoteserver" do
    it "should send ClientHello and receive ServerHello" do
      # see integration test
    end
  end

  describe "#tcp_receive_from_localbackend" do
    subject {
      str = [0x17, 3, 3].pack("C*") \
      + ["opaque".length].pack("n") \
      + "opaque"
      obfs_param = nil
      sub = make_an_obfs_protocol(str ,{host: '127.0.0.1', key: 'akey' * 4, compatible: false, obfs_param: obfs_param})
      sub
    }
    it "should riase on invalid data when compatible: false" do
      expect{subject.tcp_receive_from_localbackend(-1)}.to raise_error(ShadowsocksRuby::PharseError,"decode error")
    end
  end

  describe "#tcp_send_to_localbackend" do
    subject {
      obfs_param = nil
      make_an_obfs_protocol("",{host: '127.0.0.1', key: 'akey' * 4, obfs_param: obfs_param})
    }
    it_behaves_like "#tcp_send_to_localbackend", \
      [0x17, 3, 3].pack("C*") + ["some data".length].pack("n") + "some data",  \
      [0x17, 3, 3].pack("C*") + ["some other data".length].pack("n") + "some other data"
  end
 
end
