require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::DestinationConnection" do
  it_behaves_like "a backend connection", \
    ShadowsocksRuby::Connections::DestinationConnection, \
    ShadowsocksRuby::Connections::LocalBackendConnection
end
