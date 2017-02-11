# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "shadowsocks_ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "shadowsocks_ruby"
  spec.version       = ShadowsocksRuby::VERSION
  spec.author        = "zhenkyle"
  spec.email         = "zhenkyle@gmail.com"

  spec.summary       = %q{A flexible platform for writing tunnel proxy to help you bypass firewalls.}
  spec.description   = %q{ShadowsocksRuby is a flexible platform for writing SOCKS (layer 4) like tunnel proxy to help you bypass firewalls.}
  spec.homepage      = "https://github.com/zhenkyle/shadowsocks_ruby"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
    spec.metadata["yard.run"] = "yri" # use "yard" to build full HTML docs.
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "evented-spec", "~> 1.0.0.beta2"
  spec.add_development_dependency "em-http-request", "~> 1.1.5"
  spec.add_development_dependency('aruba', '~> 0.14.2')
  spec.add_development_dependency('yard', '~> 0.9.8')

  spec.add_runtime_dependency "eventmachine", "~> 1.2.1"
  spec.add_runtime_dependency "rbnacl-libsodium", "~> 1.0.11"
  spec.add_runtime_dependency "openssl", "~> 2.0.2"
  spec.add_runtime_dependency "lrucache", "~> 0.1.4"
  spec.add_runtime_dependency "to_camel_case", "~>1.0.0"
  spec.add_runtime_dependency 'einhorn'
end
