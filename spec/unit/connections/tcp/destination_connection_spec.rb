require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::TCP::DestinationConnection" do
  it_behaves_like "a backend connection", ShadowsocksRuby::Connections::TCP::DestinationConnection, ShadowsocksRuby::Connections::TCP::LocalBackendConnection
end
