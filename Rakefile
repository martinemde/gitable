require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = %w[--color]
  t.pattern = 'spec/**/*_spec.rb'
end
task :default => :spec

task :coverage => [:coverage_env, :spec]
task :coverage_env do
  ENV['COVERAGE'] = '1'
end

task :benchmark do
  require 'benchmark'
  require File.expand_path('lib/gitable/uri', File.dirname(__FILE__))

  n = 10000
  scp = "git@github.com:martinemde/gitable.git"
  uri = "git://github.com/martinemde/gitable.git"
  dup = Gitable::URI.parse(uri)
  Benchmark.bmbm do |x|
    x.report('dup') { n.times { Gitable::URI.parse(dup) } }
    x.report(uri)   { n.times { Gitable::URI.parse(uri) } }
    x.report(scp)   { n.times { Gitable::URI.parse(scp) } }
  end
end
