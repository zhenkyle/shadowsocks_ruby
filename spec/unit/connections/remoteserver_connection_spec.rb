require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::RemoteServerConnection" do
  it_behaves_like "a backend connection", \
    ShadowsocksRuby::Connections::RemoteServerConnection, \
    ShadowsocksRuby::Connections::ClientConnection
end
