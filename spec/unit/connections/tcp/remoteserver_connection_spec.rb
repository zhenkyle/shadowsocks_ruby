require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::TCP::RemoteServerConnection" do
  it_behaves_like "a backend connection", ShadowsocksRuby::Connections::TCP::RemoteServerConnection, ShadowsocksRuby::Connections::TCP::ClientConnection
end
