unless defined? Bundler
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'gitable'
require 'spec'
require 'spec/autorun'
require 'describe_uri'

Spec::Runner.configure do |config|
  config.extend DescribeURI
end
