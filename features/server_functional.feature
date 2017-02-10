Feature: I can use ssserver-ruby to work with python version sslocal
  As a user I want to use shadowsocks to accept incomming
  traffic from python version sslocal

Background:
  Given shadowsocks python 2.8.2 is installed
  Given curl is installed
  Given the default aruba exit timeout is 5 seconds
  Given I wait 1 seconds for a command to start up

Scenario: shadowsocks origin version
  When I run `ssserver-ruby -k secret` in background
  And I run `sslocal-ruby -k secret -s 127.0.0.1` in background
  And I run `curl --socks5-hostname 127.0.0.1 http://localhost/`
  Then the output should contain "Apache2 Ubuntu Default Page"
  #And I run `curl --socks5-hostname 127.0.0.1 http://example.com/`
  #Then the output should contain "<h1>Example Domain</h1>"
