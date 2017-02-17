require 'evented-spec'

RSpec.shared_examples "a server connection" do |klass|
  include EventedSpec::SpecHelper
  it "should create connection object by EventMachine" do
    em do

      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data, conn_obj|
        expect(data).to eq("hello, world")
        expect(conn_obj.packet_protocol).not_to eq(nil)
        expect(conn_obj).to respond_to(:create_plexer)
        done
      end
      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < klass
        def process_hook
          data = async_recv(-1)
          $dd.succeed data, self
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

RSpec.shared_examples "a backend connection" do |klass, klass1|

  include EventedSpec::SpecHelper  
  it "should create connection object by create_plexer" do
    em do

      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data, conn_obj|
        expect(conn_obj.plexer).not_to eq(nil)
        expect(conn_obj.plexer).to be_instance_of(DummyBackendConnection)
        expect(conn_obj.plexer.packet_protocol).not_to eq(nil)
        done
      end
      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < klass1
        def process_hook
          data = async_recv(-1)
          create_plexer('127.0.0.1', 8388, DummyBackendConnection)
          $dd.succeed data, self
        end
      end
      Object.send(:remove_const, :DummyBackendConnection) if Object.constants.include?(:DummyBackendConnection)
      class DummyBackendConnection < klass
        def process_hook
          Fiber.yield
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