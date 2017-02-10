When(/^I get help for "([^"]*)"$/) do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} --help`)
end

# Add more step definitions here

Given(/^shadowsocks python 2.8.2 is installed$/) do
  step %(I run `ssserver --version`)
  step %(the output should contain "Shadowsocks 2.8.2")
  step %(I run `sslocal --version`)
  step %(the output should contain "Shadowsocks 2.8.2")
end

Given(/^curl is installed$/) do
  step %(I run `curl`)
  step %(the output should contain "try 'curl --help' or 'curl --manual' for more information")
end
