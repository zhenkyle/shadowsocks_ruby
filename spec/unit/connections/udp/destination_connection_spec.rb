require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::UDP::DestinationConnection" do
  it_behaves_like "a backend connection", ShadowsocksRuby::Connections::UDP::DestinationConnection, ShadowsocksRuby::Connections::UDP::LocalBackendConnection
end
