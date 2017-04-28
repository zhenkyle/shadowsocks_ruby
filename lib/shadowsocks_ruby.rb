require 'logger'
require 'eventmachine'
require 'forwardable'

require "shadowsocks_ruby/version"
require "shadowsocks_ruby/util"
require "shadowsocks_ruby/cipher/cipher"
require "shadowsocks_ruby/cipher/openssl"

%w[ openssl rbnacl rc4_md5 table ].each do |file|
  require "shadowsocks_ruby/cipher/#{file}"
end

require "shadowsocks_ruby/protocols/protocol"
require "shadowsocks_ruby/protocols/protocol_stack"

# autoload protocols in these directories
%w[ packet cipher obfs ].each do |dir|
  Dir[File.join(File.dirname(__FILE__) ,"shadowsocks_ruby", "protocols", dir , "*.rb")].each do |file|
    file = File.basename(file,".rb")
    require "shadowsocks_ruby/protocols/#{dir}/#{file}"
  end
end

require "shadowsocks_ruby/connections/connection"
require "shadowsocks_ruby/connections/server_connection"
require "shadowsocks_ruby/connections/backend_connection"

%w[ client_connection remoteserver_connection localbackend_connection destination_connection ].each do |file|
  require "shadowsocks_ruby/connections/tcp/#{file}"
end

%w[ client_connection remoteserver_connection localbackend_connection destination_connection ].each do |file|
  require "shadowsocks_ruby/connections/udp/#{file}"
end

require "shadowsocks_ruby/app"

require "shadowsocks_ruby/cli/ssserver_runner"
require "shadowsocks_ruby/cli/sslocal_runner"

module ShadowsocksRuby
  # This indicate a known failure by Shadowsock package.
  # rescue this module will rescue all Shadowsocks known failure.
  module MyErrorModule; end
  # This indicates a failure in the App Class.
  class AppError < ArgumentError
    include MyErrorModule
  end

  # This indicates a failure in the Cipher Class.
  class CipherError < ArgumentError
    include MyErrorModule
  end

  # This indicates a failure in the Protocol Class.
  class ProtocolError < ArgumentError
    include MyErrorModule
  end

  # This indicates a failure in the Protocol pharse.
  class PharseError < StandardError
    include MyErrorModule
  end

    # This indicates a failure in Connection. A function is called out of fiber context.
  class OutOfFiberContextError < StandardError
    include MyErrorModule
  end
  
    # This indicates a failure in Connection.
  class ConnectionError < StandardError
    include MyErrorModule
  end
  
    # This indicates a failure in Connection. The Buffer is oversized.
  class BufferOversizeError < StandardError
    include MyErrorModule
  end

  # This indicates something is unimplemented.
  class UnimplementError < StandardError
    include MyErrorModule
  end

end
