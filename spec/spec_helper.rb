unless defined? Bundler
  require 'rubygems'
  require 'bundler'
end

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'gitable'
require 'rspec'
require 'describe_uri'

RSpec.configure do |config|
  config.extend DescribeURI
end
