require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w[--color]
  t.pattern = 'spec/**/*_spec.rb'
end
task :default => :spec

RSpec::Core::RakeTask.new(:rcov) do |t|
  t.rspec_opts = %w[--color]
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_opts = %w[--exclude spec/,gems/,Library/,.bundle]
end
