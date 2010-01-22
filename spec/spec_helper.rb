$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'gitable'
require 'spec'
require 'spec/autorun'
require File.join(File.dirname(__FILE__), 'describe_uri')

Spec::Runner.configure do |config|
  config.extend DescribeURI
end
