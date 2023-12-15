# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "standard/rake"

task default: %i[spec standard]

task coverage: [:coverage_env, :spec]
task :coverage_env do
  ENV["COVERAGE"] = "1"
end

task :benchmark do
  require "benchmark/ips"
  require "uri"
  require File.expand_path("lib/gitable/uri", File.dirname(__FILE__))
  scp = "git@github.com:martinemde/gitable.git"
  uri = "git://github.com/martinemde/gitable.git"
  dup = Gitable::URI.parse(uri)
  Benchmark.ips do |x|
    x.report("dup") { Gitable::URI.parse(dup) }
    x.report(uri) { Gitable::URI.parse(uri) }
    x.report(scp) { Gitable::URI.parse(scp) }
    x.report("addressable") { Addressable::URI.parse(uri) }
    x.report("uri") { URI.parse(uri) }
  end
end
