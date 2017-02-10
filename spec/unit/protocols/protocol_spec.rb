require "spec_helper"
require 'shared_examples_for_protocol'

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

      def raise_me
        raise ShadowsocksRuby::UnimplementError
      end

      alias tcp_receive_from_client raise_me
      alias tcp_send_to_client raise_me
      alias tcp_receive_from_remoteserver raise_me
      alias tcp_send_to_remoteserver raise_me
      alias tcp_receive_from_localbackend raise_me
      alias tcp_send_to_localbackend raise_me
      alias tcp_receive_from_destination raise_me
      alias tcp_send_to_destination raise_me

      alias udp_receive_from_client raise_me
      alias udp_send_to_client raise_me
      alias udp_receive_from_remoteserver raise_me
      alias udp_send_to_remoteserver raise_me
      alias udp_receive_from_localbackend raise_me
      alias udp_send_to_localbackend raise_me
      alias udp_receive_from_destination raise_me
      alias udp_send_to_destination raise_me

    end
    describe DummyProtocol do
      it_behaves_like "a protocol"
    end
  end
  describe "a protocol can include DummyHelper to save typeing" do
    Object.send(:remove_const, :DummyProtocol) if Object.constants.include?(:DummyProtocol)
    class DummyProtocol
      include ShadowsocksRuby::Protocols::DummyHelper
      attr_accessor :next_protocol
      def async_recv n
        # should respond to this method
      end
      def send_data data
        # should respond to this method
      end

      def raise_me
        raise ShadowsocksRuby::UnimplementError
      end

      alias tcp_receive_from_client raise_me
      alias tcp_send_to_client raise_me
      alias tcp_receive_from_remoteserver raise_me
      alias tcp_send_to_remoteserver raise_me
      alias tcp_receive_from_localbackend raise_me
      alias tcp_send_to_localbackend raise_me
      alias tcp_receive_from_destination raise_me
      alias tcp_send_to_destination raise_me

      alias udp_receive_from_client raise_me
      alias udp_send_to_client raise_me
      alias udp_receive_from_remoteserver raise_me
      alias udp_send_to_remoteserver raise_me
      alias udp_receive_from_localbackend raise_me
      alias udp_send_to_localbackend raise_me
      alias udp_receive_from_destination raise_me
      alias udp_send_to_destination raise_me
    end
    describe DummyProtocol do
      it_behaves_like "a protocol"
    end
  end
end
