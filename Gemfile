source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

group :development do
  gem 'evented-spec', github: 'ruby-amqp/evented-spec'
  gem 'coveralls', require: false
end
# Specify your gem's dependencies in shadowsocks_ruby.gemspec
gemspec
