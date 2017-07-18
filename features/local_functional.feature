Feature: I can use sslocal-ruby to work with python version ssserver-ruby
  As a user I want to use shadowsocks_ruby to accept incomming
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
  And I wait 15 seconds for the command to start up
  When I run `docker run --rm --net=host --entrypoint "ssserver" zhenkyle/docker-sslocal -k secret` in background
  And I wait 1 seconds for a command to start up
  And I run `sslocal-ruby -k secret -s 127.0.0.1` in background
  When I run the following script:
  """bash
  curl --socks5-hostname 127.0.0.1 http://$(ip route get 1 | awk '{print $NF;exit}'):5000/
  """
  Then the output should contain "<h1>Example Domain</h1>"

Scenario: shadowsocks origin version with http_simple obfuscator
  And I wait 15 seconds for the command to start up
  When I run `docker run --rm --net=host zhenkyle/shadowsocksr ssserver -k secret -o http_simple` in background
  And I wait 1 seconds for a command to start up
  And I run `sslocal-ruby -s 127.0.0.1 -k secret -o http_simple` in background
  When I run the following script:
  """bash
  curl --socks5-hostname 127.0.0.1 http://$(ip route get 1 | awk '{print $NF;exit}'):5000/
  """
  Then the output should contain "<h1>Example Domain</h1>"

Scenario: shadowsocks origin version with tls_ticket obfuscator
  And I wait 15 seconds for the command to start up
  When I run `docker run --rm --net=host zhenkyle/shadowsocksr ssserver -k secret -o tls1.2_ticket_auth_compatible` in background
  And I wait 1 seconds for a command to start up
  And I run `sslocal-ruby -s 127.0.0.1 -k secret -o tls1.2_ticket_auth_compatible` in background
  When I run the following script:
  """bash
  curl --socks5-hostname 127.0.0.1 http://$(ip route get 1 | awk '{print $NF;exit}'):5000/
  """
  Then the output should contain "<h1>Example Domain</h1>"
