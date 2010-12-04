require 'spec_helper'

describe Gitable::URI do
  before do
    @uri = "ssh://git@github.com/martinemde/gitable.git"
  end

  describe_uri "git://github.com/martinemde/gitable" do
    it "sets a new extname" do
      subject.extname.should == ""
      subject.extname = "git"
      subject.extname.should == ".git"
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
      subject.extname = "git"
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
        "http://",
        "blah:"
      ].each do |uri|
        it "raises an Gitable::URI::InvalidURIError with #{uri.inspect}" do
          lambda {
            Gitable::URI.parse(uri)
          }.should raise_error(Gitable::URI::InvalidURIError)
        end
      end
    end

    expected = {
      :user         => nil,
      :password     => nil,
      :host         => "host.xz",
      :port         => nil,
      :path         => "/path/to/repo.git/",
      :basename     => "repo.git",
      :query        => nil,
      :fragment     => nil,
      :project_name => "repo"
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
        :scheme   => "http",
        :port     => 8888,
      })
    end

    describe_uri "http://12.34.56.78:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "http",
        :host     => "12.34.56.78",
        :port     => 8888,
      })
    end

    describe_uri "https://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "https",
      })
    end

    describe_uri "https://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "https",
        :port     => 8888,
      })
    end

    describe_uri "git+ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "git+ssh",
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
        :scheme   => "git",
        :port     => 8888,
      })
    end

    describe_uri "git://host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "git",
        :path     => "/~user/path/to/repo.git/",
      })
    end

    describe_uri "git://host.xz:8888/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "git",
        :path     => "/~user/path/to/repo.git/",
        :port     => 8888,
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :user     => "user",
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
      })
    end

    describe_uri "ssh://host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :port     => 8888,
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :user     => "user",
        :scheme   => "ssh",
      })
    end

    describe_uri "ssh://user@host.xz:8888/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :user     => "user",
        :port     => 8888,
      })
    end

    describe_uri "ssh://host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :user     => nil,
        :path     => "/~user/path/to/repo.git/",
      })
    end

    describe_uri "ssh://user@host.xz/~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :user     => "user",
        :path     => "/~user/path/to/repo.git/",
      })
    end

    describe_uri "ssh://host.xz/~/path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :path     => "/~/path/to/repo.git",
      })
    end

    describe_uri "ssh://user@host.xz/~/path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "ssh",
        :user     => "user",
        :path     => "/~/path/to/repo.git",
      })
    end

    describe_uri "host.xz:/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => nil,
        :path     => "/path/to/repo.git/",
      })
    end

    describe_uri "user@host.xz:/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => "user",
        :path     => "/path/to/repo.git/",
      })
    end

    describe_uri "host.xz:~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => nil,
        :path     => "~user/path/to/repo.git/",
      })
    end

    describe_uri "user@host.xz:~user/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => "user",
        :path     => "~user/path/to/repo.git/",
      })
    end

    describe_uri "host.xz:path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => nil,
        :path     => "path/to/repo.git",
      })
    end

    describe_uri "user@host.xz:path/to/repo.git" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :user     => "user",
        :path     => "path/to/repo.git",
      })
    end

    describe_uri "/path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => nil,
        :host     => nil,
        :path     => "/path/to/repo.git/",
      })
    end

    describe_uri "file:///path/to/repo.git/" do
      it { subject.to_s.should == @uri }
      it_sets expected.merge({
        :scheme   => "file",
        :host     => "", # I don't really like this but it doesn't hurt anything.
        :path     => "/path/to/repo.git/",
      })
    end

    describe_uri "ssh://git@github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it_sets({
        :scheme   => "ssh",
        :user     => "git",
        :password => nil,
        :host     => "github.com",
        :port     => nil,
        :path     => "/martinemde/gitable.git",
        :fragment => nil,
        :basename => "gitable.git",
      })
    end

    describe_uri "http://github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it_sets({
        :scheme   => "http",
        :user     => nil,
        :password => nil,
        :host     => "github.com",
        :port     => nil,
        :path     => "/martinemde/gitable.git",
        :fragment => nil,
        :basename => "gitable.git",
      })
    end

    describe_uri "git://github.com/martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it_sets({
        :scheme   => "git",
        :user     => nil,
        :password => nil,
        :host     => "github.com",
        :port     => nil,
        :path     => "/martinemde/gitable.git",
        :fragment => nil,
        :basename => "gitable.git",
      })
    end

    describe_uri "git@github.com:martinemde/gitable.git" do
      it { subject.to_s.should == @uri }
      it_sets({
        :scheme       => nil,
        :user         => "git",
        :password     => nil,
        :host         => "github.com",
        :port         => nil,
        :path         => "martinemde/gitable.git",
        :fragment     => nil,
        :basename     => "gitable.git",
        :project_name => "gitable",
      })
    end
  end
end
