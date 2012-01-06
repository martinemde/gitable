require 'spec_helper'

describe Gitable::URI do
  describe_uri "git://github.com/martinemde/gitable" do
    it "sets the .git extname" do
      subject.extname.should == ""
      subject.set_git_extname
      subject.extname.should == ".git"
      subject.to_s.should == @uri + ".git"
    end

    it "does not duplicate the extname" do
      subject.extname = "git"
      subject.to_s.should == @uri + ".git"
      subject.set_git_extname
      subject.to_s.should == @uri + ".git"
    end

    it "sets a new basename" do
      subject.basename.should == "gitable"
      subject.basename = "gitable.git"
      subject.basename.should == "gitable.git"
      subject.extname.should == ".git"
    end
  end

  describe_uri "git://github.com/" do
    it "does not set a new extname" do
      subject.extname.should == ""
      subject.set_git_extname
      subject.extname.should == ""
      subject.to_s.should == @uri
    end

    it "sets a new basename" do
      subject.basename.should == ""
      subject.basename = "gitable.git"
      subject.basename.should == "gitable.git"
      subject.extname.should == ".git"
      subject.to_s.should == @uri + "gitable.git"
    end
  end

  # Valid Git URIs according to git-clone documentation at this url:
  # http://www.kernel.org/pub/software/scm/git/docs/git-clone.html#_git_urls_a_id_urls_a
  #
  # Git natively supports ssh, git, http, https, ftp, ftps, and rsync protocols. The following syntaxes may be used with them:
  #
  # ssh://[user@]host.xz[:port]/path/to/repo.git/
  # git://host.xz[:port]/path/to/repo.git/
  # http[s]://host.xz[:port]/path/to/repo.git/
  # ftp[s]://host.xz[:port]/path/to/repo.git/
  # rsync://host.xz/path/to/repo.git/
  #
  # An alternative scp-like syntax may also be used with the ssh protocol:
  #
  # [user@]host.xz:path/to/repo.git/
  #
  # The ssh and git protocols additionally support ~username expansion:
  #
  # ssh://[user@]host.xz[:port]/~[user]/path/to/repo.git/
  # git://host.xz[:port]/~[user]/path/to/repo.git/
  # [user@]host.xz:/~[user]/path/to/repo.git/
  #
  # For local repositories, also supported by git natively, the following syntaxes may be used:
  #
  # /path/to/repo.git/
  # file:///path/to/repo.git/
  #

  describe ".parse" do
    before { @uri = "ssh://git@github.com/martinemde/gitable.git" }

    it "returns a Gitable::URI" do
      Gitable::URI.parse(@uri).should be_a_kind_of(Gitable::URI)
    end

    it "returns nil when passed a nil uri" do
      Gitable::URI.parse(nil).should be_nil
    end

    it "returns the same uri when passed a Gitable::URI" do
      gitable = Gitable::URI.parse(@uri)
      Gitable::URI.parse(gitable).should be_eql(gitable)
    end

    it "raises a TypeError on bad type" do
      lambda {
        Gitable::URI.parse(5)
      }.should raise_error(TypeError)
    end

    context "(bad uris)" do
      [
        "http://", # nothing but scheme
        "blah:", # pretty much nothing
        "user@:path.git", # no host
        "user@host:", # no path
      ].each do |uri|
        it "raises an Gitable::URI::InvalidURIError with #{uri.inspect}" do
          lambda {
            Gitable::URI.parse(uri)
          }.should raise_error(Gitable::URI::InvalidURIError)
        end
      end

      context "scp uris" do
        it "raises without path" do
          lambda {
            Gitable::ScpURI.parse("http://github.com/path.git")
          }.should raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises without path" do
          lambda {
            Gitable::ScpURI.new(:user => 'git', :host => 'github.com')
          }.should raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises without host" do
          lambda {
            Gitable::ScpURI.new(:user => 'git', :path => 'path')
          }.should raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises with any scheme" do
          lambda {
            Gitable::ScpURI.new(:scheme => 'ssh', :host => 'github.com', :path => 'path')
          }.should raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises with any port" do
          lambda {
            Gitable::ScpURI.new(:port => 88, :host => 'github.com', :path => 'path')
          }.should raise_error(Gitable::URI::InvalidURIError)
        end
      end
    end

    expected = {
      :user           => nil,
      :password       => nil,
      :host           => "host.xz",
      :port           => nil,
      :path           => "/path/to/repo.git/",
      :basename       => "repo.git",
      :query          => nil,
      :fragment       => nil,
      :project_name   => "repo",
      :local?         => false,
      :ssh?           => false,
      :authenticated? => false,
      :interactive_authenticated? => false,
      :to_web_uri     => Addressable::URI.parse("https://host.xz/path/to/repo"),
    }

    describe_uri "rsync://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme       => "rsync",
        :project_name => "repo"
      })
    end

    describe_uri "rsync://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "rsync",
      })
    end

    describe_uri "http://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "http",
      })
    end

    describe_uri "http://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "http",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "http://12.34.56.78:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "http",
        :host           => "12.34.56.78",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://12.34.56.78:8888/path/to/repo")
      })
    end

    describe_uri "https://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "https",
      })
    end

    describe_uri "https://user@host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme                     => "https",
        :user                       => "user",
        :interactive_authenticated? => true,
        :authenticated?             => true,
      })
    end

    describe_uri "https://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "https",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "git+ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "git+ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "git://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "git",
      })
    end

    describe_uri "git://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "git",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "git://host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "git",
        :path           => "/~user/path/to/repo.git/",
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "git://host.xz:8888/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "git",
        :path           => "/~user/path/to/repo.git/",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/~user/path/to/repo")
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => "user",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :port           => 8888,
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :user           => "user",
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://user@host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => "user",
        :port           => 8888,
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "ssh://host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => nil,
        :path           => "/~user/path/to/repo.git/",
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "ssh://user@host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => "user",
        :path           => "/~user/path/to/repo.git/",
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "ssh://host.xz/~/path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :path           => "/~/path/to/repo.git",
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~/path/to/repo")
      })
    end

    describe_uri "ssh://user@host.xz/~/path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => "user",
        :path           => "/~/path/to/repo.git",
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~/path/to/repo")
      })
    end

    describe_uri "host.xz:/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => nil,
        :path              => "/path/to/repo.git/",
        :ssh?              => true,
        :authenticated?    => true,
      })
    end

    describe_uri "user@host.xz:/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it { subject.should be_equivalent('ssh://user@host.xz/path/to/repo.git') }
      it { subject.should be_equivalent('user@host.xz:/path/to/repo.git') }
      it { subject.should_not be_equivalent('user@host.xz:path/to/repo.git') } # not absolute
      it { subject.should_not be_equivalent('/path/to/repo.git') }
      it { subject.should_not be_equivalent('host.xz:path/to/repo.git') }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => "user",
        :path              => "/path/to/repo.git/",
        :ssh?              => true,
        :authenticated?    => true,
      })
    end

    describe_uri "host.xz:~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => nil,
        :path              => "~user/path/to/repo.git/",
        :ssh?              => true,
        :authenticated?    => true,
        :to_web_uri        => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "user@host.xz:~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => "user",
        :path              => "~user/path/to/repo.git/",
        :ssh?              => true,
        :authenticated?    => true,
        :to_web_uri        => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "host.xz:path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => nil,
        :path              => "path/to/repo.git",
        :ssh?              => true,
        :authenticated?    => true,
      })
    end

    describe_uri "user@host.xz:path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it { subject.should_not be_equivalent('ssh://user@host.xz/path/to/repo.git') } # not absolute
      it { subject.should_not be_equivalent('path/to/repo.git') }
      it { subject.should_not be_equivalent('host.xz:path/to/repo.git') }
      it { subject.should_not be_equivalent('user@host.xz:/path/to/repo.git') }
      it_sets expected.merge({
        :scheme            => nil,
        :inferred_scheme   => "ssh",
        :user              => "user",
        :path              => "path/to/repo.git",
        :ssh?              => true,
        :authenticated?    => true,
      })
    end

    describe_uri "/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('/path/to/repo.git') }
      it { subject.should be_equivalent('file:///path/to/repo.git') }
      it { subject.should be_equivalent('file:///path/to/repo.git/') }
      it { subject.should_not be_equivalent('/path/to/repo/.git') }
      it { subject.should_not be_equivalent('file:///not/path/repo.git') }
      it_sets expected.merge({
        :scheme          => nil,
        :inferred_scheme => "file",
        :host            => nil,
        :path            => "/path/to/repo.git/",
        :local?          => true,
        :to_web_uri      => nil,
      })
    end

    describe_uri "file:///path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('/path/to/repo.git') }
      it { subject.should be_equivalent('file:///path/to/repo.git') }
      it { subject.should be_equivalent('/path/to/repo.git/') }
      it { subject.should_not be_equivalent('/path/to/repo/.git') }
      it { subject.should_not be_equivalent('file:///not/path/repo.git') }
      it_sets expected.merge({
        :scheme          => "file",
        :inferred_scheme => "file",
        :host            => "",
        :path            => "/path/to/repo.git/",
        :local?          => true,
        :to_web_uri      => nil,
      })
    end

    describe_uri "ssh://git@github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('git://github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { subject.should be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "ssh",
        :user              => "git",
        :password          => nil,
        :host              => "github.com",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => true,
        :scp?              => false,
        :authenticated?    => true,
        :interactive_authenticated? => false,
        :github?           => true,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "https://github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git://github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "https",
        :user              => nil,
        :password          => nil,
        :host              => "github.com",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => true,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "https://martinemde@github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git://github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { subject.should be_equivalent('https://github.com/martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "https",
        :user              => "martinemde",
        :password          => nil,
        :host              => "github.com",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => true,
        :authenticated?    => true,
        :interactive_authenticated? => true,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "git://github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::URI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:martinemde/gitable.git') }
      it { subject.should be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { subject.should be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "git",
        :user              => nil,
        :password          => nil,
        :host              => "github.com",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => true,
        :authenticated?    => false,
        :interactive_authenticated? => false,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "git@github.com:martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it { subject.inspect.should =~ %r|^#<Gitable::ScpURI #{@uri}>$| }
      it { subject.should be_equivalent(@uri) }
      it { subject.should be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('git://github.com/martinemde/gitable.git') }
      it { subject.should be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { subject.should_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => "git",
        :password          => nil,
        :host              => "github.com",
        :port              => nil,
        :path              => "martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :project_name      => "gitable",
        :ssh?              => true,
        :scp?              => true,
        :authenticated?    => true,
        :interactive_authenticated? => false,
        :github?           => true,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end
  end
end
