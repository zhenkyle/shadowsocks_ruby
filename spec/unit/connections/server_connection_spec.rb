require "spec_helper"
require 'evented-spec'

RSpec.describe "ShadowsocksRuby::Connections::ServerConnection" do
  include EventedSpec::SpecHelper
  it "should create protocols & function on initialize" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data, conn_obj|
        expect(data).to eq("hello, world")
        expect(conn_obj.packet_protocol).not_to eq(nil)
        expect(conn_obj).to respond_to(:create_plexer)
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::ServerConnection
        def process_hook
          data = async_recv(-1)
          $dd.succeed data, self
        end
      end

      server_args = [
        instance_double("ShadowsocksRuby::Protocols::ProtocolStack").as_null_object,
        {},
        nil,
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
