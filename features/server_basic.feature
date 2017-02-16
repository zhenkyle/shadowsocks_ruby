Feature: We can use the shadowsocks cli to get enought help to run
  As a user I want to use shadowsocks,
  and I begin to try

Scenario: I run ssserver-ruby with no arguments
  When I run `ssserver-ruby`
  Then the exit status should be 1
  And the stderr should contain "password is required"

Scenario: I run ssserver-ruby with -h
  When I get help for "ssserver-ruby"
  Then the stdout should contain "A SOCKS like tunnel proxy that helps you bypass firewalls."
  Then the exit status should be 0

Scenario: I run ssserver-ruby with -k but with no password
  When I run `ssserver-ruby -k`
  Then the stderr should contain "missing argument: -k"
  Then the exit status should be 1

Scenario: I run ssserver-ruby with -k secret
  Given the default aruba exit timeout is 1 second
  When I run `ssserver-ruby -k secret`
  Then the output should contain "Listening on"
  And the exit status should be 0
