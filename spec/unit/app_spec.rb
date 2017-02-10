require "spec_helper"

RSpec.describe ShadowsocksRuby::App do
  subject {
    described_class.options = { :port=>8388, 
                                :local_addr=>"0.0.0.0", 
                                :local_port=>1080, 
                                :packet_name=>"origin", 
                                :cipher_name=>"none", 
                                :timeout=>300, 
                                :password=>"password",
                                :server=>"127.0.0.1",
                                :__server=>true}
    described_class.instance
  }
  it "should be initialized with out raise" do
    evm_double = class_double("EventMachine").as_stubbed_const(:transfer_nested_constants => true).as_null_object
    expect(evm_double).to receive(:run)
    expect(evm_double).to receive(:epoll)
    subject.run!
  end
end