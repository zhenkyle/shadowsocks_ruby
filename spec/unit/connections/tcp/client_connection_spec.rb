require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::TCP::ClientConnection" do
  it_behaves_like "a server connection", ShadowsocksRuby::Connections::TCP::ClientConnection
end
