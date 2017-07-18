require "spec_helper"
require 'shared_examples_for_protocols'

describe ShadowsocksRuby::Protocols do
  describe "Protocol is a duck type" do
    Object.send(:remove_const, :DummyProtocol) if Object.constants.include?(:DummyProtocol)
    class DummyProtocol
      attr_accessor :next_protocol
      def async_recv n
        # should respond to this method
      end
      def send_data data
        # should respond to this method
      end

    end
    describe DummyProtocol do
      it_behaves_like "a protocol"
    end
  end
  describe "A protocol can include BufferHelper to help deal with @buffer" do
    Object.send(:remove_const, :DummyProtocol) if Object.constants.include?(:DummyProtocol)
    class DummyProtocol
      include ShadowsocksRuby::Protocols::BufferHelper
      attr_accessor :next_protocol
      def async_recv n
        # should respond to this method
      end
      def send_data data
        # should respond to this method
      end

    end
    describe DummyProtocol do
      it_behaves_like "a protocol"
    end
  end
end
