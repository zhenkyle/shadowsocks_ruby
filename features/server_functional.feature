Feature: I can use ssserver-ruby to work with python version sslocal
  As a user I want to use ssserver-ruby to accept incomming
  traffic from python version sslocal

Background:
  Given docker is installed
  Given curl is installed
  Given the default aruba stop signal is "INT"
  Given I wait 1 seconds for a command to start up
  Given a file named "index.html" with: 
  """
  <h1>Example Domain</h1>
  """
  And I run `ruby -run -e httpd . -p 5000` in background

Scenario: shadowsocks origin version
  When I run `ssserver-ruby -k secret` in background
  And I wait 15 seconds for the command to start up
  And I run `docker run --rm --net=host zhenkyle/docker-sslocal -k secret -s 127.0.0.1` in background
  And I wait 1 seconds for a command to start up
  And I run `curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/`
  Then the output from "curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/" should contain "<h1>Example Domain</h1>"

Scenario: shadowsocks origin version with http_simple obfuscator
  When I run `ssserver-ruby -k secret -o http_simple` in background
  And I wait 15 seconds for the command to start up
  And I run `docker run --rm --net=host zhenkyle/shadowsocksr sslocal -s 127.0.0.1 -k secret -o http_simple` in background
  And I wait 1 seconds for a command to start up
  And I run `curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/`
  Then the output from "curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/" should contain "<h1>Example Domain</h1>"

Scenario: shadowsocks origin version with tls_ticket obfuscator
  When I run `ssserver-ruby -k secret -o tls1.2_ticket_auth_compatible` in background
  And I wait 15 seconds for the command to start up
  And I run `docker run --rm --net=host zhenkyle/shadowsocksr sslocal -s 127.0.0.1 -k secret -o tls1.2_ticket_auth_compatible` in background
  And I wait 1 seconds for a command to start up
  And I run `curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/`
  Then the output from "curl --socks5-hostname 127.0.0.1 http://127.0.0.1:5000/" should contain "<h1>Example Domain</h1>"
