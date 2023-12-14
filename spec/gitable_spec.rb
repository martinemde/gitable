require 'spec_helper'

describe Gitable::URI do
  describe_uri "git://github.com/martinemde/gitable" do
    it "sets the .git extname" do
      expect(subject.extname).to eq("")
      subject.set_git_extname
      expect(subject.extname).to eq(".git")
      expect(subject.to_s).to eq(@uri + ".git")
    end

    it "does not duplicate the extname" do
      subject.extname = "git"
      expect(subject.to_s).to eq(@uri + ".git")
      subject.set_git_extname
      expect(subject.to_s).to eq(@uri + ".git")
    end

    it "sets a new basename" do
      expect(subject.basename).to eq("gitable")
      subject.basename = "gitable.git"
      expect(subject.basename).to eq("gitable.git")
      expect(subject.extname).to eq(".git")
    end
  end

  describe_uri "git://github.com/" do
    it "does not set a new extname" do
      expect(subject.extname).to eq("")
      subject.set_git_extname
      expect(subject.extname).to eq("")
      expect(subject.to_s).to eq(@uri)
    end

    it "sets a new basename" do
      expect(subject.basename).to eq("")
      subject.basename = "gitable.git"
      expect(subject.basename).to eq("gitable.git")
      expect(subject.extname).to eq(".git")
      expect(subject.to_s).to eq(@uri + "gitable.git")
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
  require "uri"

  describe ".parse" do
    before { @uri = "ssh://git@github.com/martinemde/gitable.git" }

    it "returns a Gitable::URI" do
      expect(Gitable::URI.parse(@uri)).to be_a_kind_of(Gitable::URI)
    end

    it "returns nil when passed a nil uri" do
      expect(Gitable::URI.parse(nil)).to be_nil
    end

    it "returns a Gitable::URI when passed a URI" do
      stdlib_uri = URI.parse(@uri)
      gitable = Gitable::URI.parse(stdlib_uri)
      expect(gitable).to be_a_kind_of(Gitable::URI)
      expect(gitable.to_s).to eq(stdlib_uri.to_s)
    end

    it "returns a Gitable::URI when passed an Addressable::URI" do
      addr_uri = Addressable::URI.parse(@uri)
      gitable = Gitable::URI.parse(addr_uri)
      expect(gitable).to be_a_kind_of(Gitable::URI)
      expect(gitable.to_s).to eq(addr_uri.to_s)
    end

    it "returns a duplicate of the uri when passed a Gitable::URI" do
      gitable = Gitable::URI.parse(@uri)
      parsed = Gitable::URI.parse(gitable)
      expect(parsed).to eq(gitable)
      expect(parsed).to_not eq(gitable.object_id)
    end

    it "raises a TypeError on bad type" do
      expect {
        Gitable::URI.parse(5)
      }.to raise_error(TypeError)
    end

    it "returns nil with bad type on parse_when_valid" do
      expect(Gitable::URI.parse_when_valid(42)).to be_nil
    end

    context "(bad uris)" do
      [
        "http://", # nothing but scheme
        "blah:", # pretty much nothing
        "user@:path.git", # no host
        "user@host:", # no path
      ].each do |uri|
        context uri.inspect do
          it "raises an Gitable::URI::InvalidURIError" do
            expect {
              puts Gitable::URI.parse(uri).to_hash.inspect
            }.to raise_error(Gitable::URI::InvalidURIError)
          end

          it "returns nil on parse_when_valid" do
            expect(Gitable::URI.parse_when_valid(uri)).to be_nil
          end

          it "is not equivalent to a bad uri" do
            expect(Gitable::URI.parse('git://github.com/martinemde/gitable.git')).to_not be_equivalent(uri)
          end
        end
      end

      context "scp uris" do
        it "raises without path" do
          expect {
            Gitable::ScpURI.new(:user => 'git', :host => 'github.com')
          }.to raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises without host" do
          expect {
            Gitable::ScpURI.new(:user => 'git', :path => 'path')
          }.to raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises with any scheme" do
          expect {
            Gitable::ScpURI.new(:scheme => 'ssh', :host => 'github.com', :path => 'path')
          }.to raise_error(Gitable::URI::InvalidURIError)
        end

        it "raises with any port" do
          expect {
            Gitable::ScpURI.new(:port => 88, :host => 'github.com', :path => 'path')
          }.to raise_error(Gitable::URI::InvalidURIError)
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme       => "rsync",
        :project_name => "repo"
      })
    end

    describe_uri "rsync://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme   => "rsync",
      })
    end

    describe_uri "http://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme   => "http",
      })
    end

    describe_uri "http://host.xz:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "http",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "http://12.34.56.78:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "http",
        :host           => "12.34.56.78",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://12.34.56.78:8888/path/to/repo")
      })
    end

    describe_uri "https://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme   => "https",
      })
    end

    describe_uri "https://user@host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme                     => "https",
        :user                       => "user",
        :interactive_authenticated? => true,
        :authenticated?             => true,
      })
    end

    describe_uri "https://host.xz:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "https",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "git+ssh://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "git+ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "git://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme   => "git",
      })
    end

    describe_uri "git://host.xz:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "git",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "git://host.xz/~user/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "git",
        :path           => "/~user/path/to/repo.git/",
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~user/path/to/repo")
      })
    end

    describe_uri "git://host.xz:8888/~user/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "git",
        :path           => "/~user/path/to/repo.git/",
        :port           => 8888,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/~user/path/to/repo")
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "ssh",
        :user           => "user",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://host.xz:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "ssh",
        :port           => 8888,
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz:8888/path/to/repo")
      })
    end

    describe_uri "ssh://user@host.xz/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :user           => "user",
        :scheme         => "ssh",
        :ssh?           => true,
        :authenticated? => true,
      })
    end

    describe_uri "ssh://user@host.xz:8888/path/to/repo.git/" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it_sets expected.merge({
        :scheme         => "ssh",
        :path           => "/~/path/to/repo.git",
        :ssh?           => true,
        :authenticated? => true,
        :to_web_uri     => Addressable::URI.parse("https://host.xz/~/path/to/repo")
      })
    end

    describe_uri "ssh://user@host.xz/~/path/to/repo.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject).to be_equivalent('ssh://user@host.xz/path/to/repo.git') }
      it { expect(subject).to be_equivalent('user@host.xz:/path/to/repo.git') }
      it { expect(subject).to_not be_equivalent('user@host.xz:path/to/repo.git') } # not absolute
      it { expect(subject).to_not be_equivalent('/path/to/repo.git') }
      it { expect(subject).to_not be_equivalent('host.xz:path/to/repo.git') }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject).to_not be_equivalent('ssh://user@host.xz/path/to/repo.git') } # not absolute
      it { expect(subject).to_not be_equivalent('path/to/repo.git') }
      it { expect(subject).to_not be_equivalent('host.xz:path/to/repo.git') }
      it { expect(subject).to_not be_equivalent('user@host.xz:/path/to/repo.git') }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('/path/to/repo.git') }
      it { expect(subject).to be_equivalent('file:///path/to/repo.git') }
      it { expect(subject).to be_equivalent('file:///path/to/repo.git/') }
      it { expect(subject).to_not be_equivalent('/path/to/repo/.git') }
      it { expect(subject).to_not be_equivalent('file:///not/path/repo.git') }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('/path/to/repo.git') }
      it { expect(subject).to be_equivalent('file:///path/to/repo.git') }
      it { expect(subject).to be_equivalent('/path/to/repo.git/') }
      it { expect(subject).to_not be_equivalent('/path/to/repo/.git') }
      it { expect(subject).to_not be_equivalent('file:///not/path/repo.git') }
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
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('git://github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
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
        :bitbucket?        => false,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "https://github.com/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
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
        :bitbucket?        => false,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "https://martinemde@github.com/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://github.com/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
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
        :bitbucket?        => false,
        :authenticated?    => true,
        :interactive_authenticated? => true,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "git://github.com/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@github.com:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
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
        :bitbucket?        => false,
        :authenticated?    => false,
        :interactive_authenticated? => false,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "git@github.com:martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::ScpURI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://github.com/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@github.com/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@github.com:martinemde/not_gitable.git') }
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
        :bitbucket?        => false,
        :to_web_uri        => Addressable::URI.parse("https://github.com/martinemde/gitable"),
      })
    end

    describe_uri "ssh://git@bitbucket.org/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('git://bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@bitbucket.org:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "ssh",
        :user              => "git",
        :password          => nil,
        :host              => "bitbucket.org",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => true,
        :scp?              => false,
        :authenticated?    => true,
        :interactive_authenticated? => false,
        :github?           => false,
        :bitbucket?        => true,
        :to_web_uri        => Addressable::URI.parse("https://bitbucket.org/martinemde/gitable"),
      })
    end

    describe_uri "https://bitbucket.org/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@bitbucket.org:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "https",
        :user              => nil,
        :password          => nil,
        :host              => "bitbucket.org",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => false,
        :bitbucket?        => true,
        :to_web_uri        => Addressable::URI.parse("https://bitbucket.org/martinemde/gitable"),
      })
    end

    describe_uri "https://martinemde@bitbucket.org/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@bitbucket.org:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "https",
        :user              => "martinemde",
        :password          => nil,
        :host              => "bitbucket.org",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => false,
        :bitbucket?        => true,
        :authenticated?    => true,
        :interactive_authenticated? => true,
        :to_web_uri        => Addressable::URI.parse("https://bitbucket.org/martinemde/gitable"),
      })
    end

    describe_uri "git://bitbucket.org/martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::URI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git@bitbucket.org:/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@bitbucket.org:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => "git",
        :user              => nil,
        :password          => nil,
        :host              => "bitbucket.org",
        :port              => nil,
        :path              => "/martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :ssh?              => false,
        :scp?              => false,
        :github?           => false,
        :bitbucket?        => true,
        :authenticated?    => false,
        :interactive_authenticated? => false,
        :to_web_uri        => Addressable::URI.parse("https://bitbucket.org/martinemde/gitable"),
      })
    end

    describe_uri "git@bitbucket.org:martinemde/gitable.git" do
      it { expect(subject.to_s).to eq(@uri) }
      it { expect("#{subject}").to eq(@uri) }
      it { expect(subject.inspect).to match(%r|^#<Gitable::ScpURI #{@uri}>$|) }
      it { expect(subject).to be_equivalent(@uri) }
      it { expect(subject).to be_equivalent('ssh://git@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('git://bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to be_equivalent('https://martinemde@bitbucket.org/martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@othergit.com:martinemde/gitable.git') }
      it { expect(subject).to_not be_equivalent('git@bitbucket.org:martinemde/not_gitable.git') }
      it_sets({
        :scheme            => nil,
        :inferred_scheme   => 'ssh',
        :user              => "git",
        :password          => nil,
        :host              => "bitbucket.org",
        :port              => nil,
        :path              => "martinemde/gitable.git",
        :fragment          => nil,
        :basename          => "gitable.git",
        :project_name      => "gitable",
        :ssh?              => true,
        :scp?              => true,
        :authenticated?    => true,
        :interactive_authenticated? => false,
        :github?           => false,
        :bitbucket?        => true,
        :to_web_uri        => Addressable::URI.parse("https://bitbucket.org/martinemde/gitable"),
      })
    end
  end
end
