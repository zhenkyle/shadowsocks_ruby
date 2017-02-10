require "spec_helper"
require "shared_examples_for_connection"

RSpec.describe "ShadowsocksRuby::Connections::TCP::LocalBackendConnection" do
  it_behaves_like "a server connection", ShadowsocksRuby::Connections::TCP::LocalBackendConnection
end
