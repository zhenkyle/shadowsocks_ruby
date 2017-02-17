require "spec_helper"
require 'evented-spec'

RSpec.describe "ShadowsocksRuby::Connections::BackendConnection" do
  include EventedSpec::SpecHelper
  it "should be created by ServerConnection" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data, conn_obj|
        expect(data).to eq("hello, world")
        expect(conn_obj.plexer).not_to eq(nil)
        expect(conn_obj.plexer.packet_protocol).not_to eq(nil)
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::ServerConnection
        def process_hook
          data = async_recv(-1)
          create_plexer('127.0.0.1', 8388, DummyBackendConnection)
          $dd.succeed data, self
        end
      end

      Object.send(:remove_const, :DummyBackendConnection) if Object.constants.include?(:DummyBackendConnection)
      class DummyBackendConnection < ShadowsocksRuby::Connections::BackendConnection
        def process_hook
          async_recv(-1)
        end
      end

      server_args = [
        instance_double("ShadowsocksRuby::Protocols::ProtocolStack").as_null_object,
        {},
        instance_double("ShadowsocksRuby::Protocols::ProtocolStack").as_null_object,
        {}
      ]
      EventMachine.start_server '127.0.0.1', 8388, DummyConnection, *server_args

      EventMachine.connect '127.0.0.1', 8388 do |c|
        def c.connection_completed
          send_data "hello, world"
        end
      end
    end      
  end
end