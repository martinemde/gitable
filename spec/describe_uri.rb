module DescribeURI
  def describe_uri(uri, &block)
    describe "with uri: #{uri.inspect}" do
      before { @uri = uri }
      subject { Gitable::URI.parse(@uri) }
      URIChecker.new(self, &block)
    end
  end

  class URIChecker
    def initialize(example_group, &block)
      @example_group = example_group
      instance_eval(&block)
    end

    def it_sets(parts)
      parts.each do |part, value|
        it "sets #{part} to #{value.inspect}" do
          subject.send(part).should == value
        end
      end
    end

    def method_missing(*args, &block)
      @example_group.send(*args, &block)
    end
  end
end
