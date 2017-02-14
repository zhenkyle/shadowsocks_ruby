When(/^I get help for "([^"]*)"$/) do |app_name|
  @app_name = app_name
  step %(I run `#{app_name} --help`)
end

# Add more step definitions here

Given(/^docker is installed$/) do
  step %(I run `docker --version`)
  step %(the output should contain "Docker version")
end

Given(/^curl is installed$/) do
  step %(I run `curl`)
  step %(the output should contain "try 'curl --help' or 'curl --manual' for more information")
end
