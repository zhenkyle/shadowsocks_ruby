require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::UDP::RemoteServerConnection" do
  it_behaves_like "a backend connection", ShadowsocksRuby::Connections::UDP::RemoteServerConnection, ShadowsocksRuby::Connections::UDP::ClientConnection
end
