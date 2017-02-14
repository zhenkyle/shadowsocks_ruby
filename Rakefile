require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'cucumber/rake/task'
require "yard"
RSpec::Core::RakeTask.new(:spec)

Cucumber::Rake::Task.new(:features) do |t|
t.cucumber_opts = "features --format pretty -x"
t.fork = false
end

YARD::Rake::YardocTask.new

task :default => [:spec, :features]
