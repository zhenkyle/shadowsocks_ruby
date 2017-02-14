Feature: I can use sslocal-ruby to work with python version ssserver-ruby
  As a user I want to use shadowsocks_ruby to accept incomming
  traffic from python version sslocal

Background:
  Given docker is installed
  Given curl is installed
  Given the default aruba stop signal is "INT"
  Given I wait 1 seconds for a command to start up

Scenario: shadowsocks origin version
  When I run `docker run --rm --net=host --entrypoint "ssserver" zhenkyle/docker-sslocal -k secret` in background
  And I run `sslocal-ruby -k secret -s 127.0.0.1` in background
  And I run `curl --socks5-hostname 127.0.0.1 http://www.example.com/`
  Then the output from "curl --socks5-hostname 127.0.0.1 http://www.example.com/" should contain "<h1>Example Domain</h1>"
