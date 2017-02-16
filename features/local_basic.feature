Feature: We can use the shadowsocks cli to get enought help to run
  As a user I want to use shadowsocks,
  and I begin to try

Scenario: I run sslocal-ruby with no arguments
  When I run `sslocal-ruby`
  Then the exit status should be 1
  And the stderr should contain "password is required"

Scenario: I run sslocal-ruby with -h
  When I get help for "sslocal-ruby"
  Then the stdout should contain "A SOCKS like tunnel proxy that helps you bypass firewalls."
  Then the exit status should be 0

Scenario: I run sslocal-ruby with -k but with no password
  When I run `sslocal-ruby -k`
  Then the stderr should contain "missing argument: -k"
  Then the exit status should be 1

Scenario: I run sslocal-ruby with -k secret
  When I run `sslocal-ruby -k secret`
  Then the stderr should contain "--server is required"
  Then the exit status should be 1

Scenario: I run sslocal-ruby with -k secret -s 1.2.3.4
  Given the default aruba exit timeout is 1 second
  When I run `sslocal-ruby -k secret -s 1.2.3.4`
  Then the output should contain "Listening on"
  And the exit status should be 0
