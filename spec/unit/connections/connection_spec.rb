require "spec_helper"
require 'evented-spec'

RSpec.describe "ShadowsocksRuby::Connections::Connection" do
  include EventedSpec::SpecHelper
  it "can receive data in process_hook" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data|
        expect(data).to eq("hello, world")
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::Connection
        def process_hook
          data = async_recv(-1)
          $dd.succeed data
        end
      end

      EventMachine.start_server '127.0.0.1', 8388, DummyConnection

      EventMachine.connect '127.0.0.1', 8388 do |c|
        def c.connection_completed
          send_data "hello, world"
        end
      end
    end
  end

  it "can receive data with specific length in process_hook" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data|
        expect(data).to eq("hello")
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::Connection
        def process_hook
          data = async_recv 5
          $dd.succeed data
        end
      end

      EventMachine.start_server '127.0.0.1', 8388, DummyConnection

      EventMachine.connect '127.0.0.1', 8388 do |c|
        def c.connection_completed
          send_data "hello, world"
        end
      end
    end
  end

  it "can receive data until some str appears in process_hook" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data|
        expect(data).to eq("hello, world\r\n")
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::Connection
        def process_hook
          data = async_recv_until("\r\n")
          $dd.succeed data
        end
      end

      EventMachine.start_server '127.0.0.1', 8388, DummyConnection

      EventMachine.connect '127.0.0.1', 8388 do |c|
        def c.connection_completed
          send_data "hello, world\r\n and more!"
        end
      end
    end
  end

  it "can send data in process_hook" do
    em do
      $dd = EventMachine::DefaultDeferrable.new
      $dd.callback do |data|
        expect(data).to eq("hello, world")
        done
      end

      Object.send(:remove_const, :DummyConnection) if Object.constants.include?(:DummyConnection)
      class DummyConnection < ShadowsocksRuby::Connections::Connection
        def process_hook
          send_data "hello, world"
          Fiber.yield
        end
      end

      EventMachine.start_server '127.0.0.1', 8388, DummyConnection

      EventMachine.connect '127.0.0.1', 8388 do |c|
        def c.receive_data data
          $dd.succeed data
        end
      end
    end
  end

  it "can send data with pressure control" do
    # made hand change to the following line in pressure_control
    # if get_outbound_data_size >= PressureLevel
    # to see if it works
  end

end
