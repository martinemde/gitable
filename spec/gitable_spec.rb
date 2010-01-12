require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Gitable::URI do
  before do
    @uri = "ssh://git@github.com/martinemde/gitable.git"
  end

  # Valid Git URIs according to git-clone documentation at this url:
  # http://www.kernel.org/pub/software/scm/git/docs/git-clone.html#_git_urls_a_id_urls_a
  #
  # rsync://host.xz/path/to/repo.git/
  # http://host.xz[:port]/path/to/repo.git/
  # https://host.xz[:port]/path/to/repo.git/
  # git://host.xz[:port]/path/to/repo.git/
  # git://host.xz[:port]/~user/path/to/repo.git/
  # ssh://[user@]host.xz[:port]/path/to/repo.git/
  # ssh://[user@]host.xz/path/to/repo.git/
  # ssh://[user@]host.xz/~user/path/to/repo.git/
  # ssh://[user@]host.xz/~/path/to/repo.git
  #
  # (from the git docs)
  # SSH is the default transport protocol over the network. You can optionally specify which user to log-in as, and an alternate, scp-like syntax is also supported. Both syntaxes support username expansion, as does the native git protocol, but only the former supports port specification. The following three are identical to the last three above, respectively:
  #
  # [user@]host.xz:/path/to/repo.git/
  # [user@]host.xz:~user/path/to/repo.git/
  # [user@]host.xz:path/to/repo.git
  #
  # To sync with a local directory, you can use:
  #
  # /path/to/repo.git/
  # file:///path/to/repo.git/
  # 
  {
    "rsync://host.xz/path/to/repo.git/" => {
      :scheme   => "rsync",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => nil,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "http://host.xz/path/to/repo.git/" => {
      :scheme   => "http",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => nil,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "http://host.xz:8888/path/to/repo.git/" => {
      :scheme   => "http",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => 8888,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "https://host.xz/path/to/repo.git/" => {
      :scheme   => "https",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => nil,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "https://host.xz:8888/path/to/repo.git/" => {
      :scheme   => "https",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => 8888,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "git://host.xz/path/to/repo.git/" => {
      :scheme   => "git",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => nil,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "git://host.xz:8888/path/to/repo.git/" => {
      :scheme   => "git",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => 8888,
      :path     => "/path/to/repo.git/",
      :basename => "repo.git",
    },
    "git://host.xz/~user/path/to/repo.git/" => {
      :scheme   => "git",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => nil,
      :path     => "/~user/path/to/repo.git/",
      :basename => "repo.git",
    },
    "git://host.xz:8888/~user/path/to/repo.git/" => {
      :scheme   => "git",
      :user     => nil,
      :password => nil,
      :host     => "host.xz",
      :port     => 8888,
      :path     => "/~user/path/to/repo.git/",
      :basename => "repo.git",
    },
    "ssh://git@github.com/martinemde/gitable.git" => {
      :scheme   => "ssh",
      :user     => "git",
      :password => nil,
      :host     => "github.com",
      :port     => nil,
      :path     => "/martinemde/gitable.git",
      :fragment => nil,
      :basename => "gitable.git",
    },
    "http://github.com/martinemde/gitable.git" => {
      :scheme   => "http",
      :user     => nil,
      :password => nil,
      :host     => "github.com",
      :port     => nil,
      :path     => "/martinemde/gitable.git",
      :fragment => nil,
      :basename => "gitable.git",
    },
    "https://github.com/martinemde/gitable.git" => {
      :scheme   => "https",
      :user     => nil,
      :password => nil,
      :host     => "github.com",
      :port     => nil,
      :path     => "/martinemde/gitable.git",
      :fragment => nil,
      :basename => "gitable.git",
    },
    "rsync://github.com/martinemde/gitable.git" => {
      :scheme   => "rsync",
      :user     => nil,
      :password => nil,
      :host     => "github.com",
      :port     => nil,
      :path     => "/martinemde/gitable.git",
      :fragment => nil,
      :basename => "gitable.git",
    },
  }.each do |uri, parts|
    describe "with #{uri.inspect}" do
      subject { Gitable::URI.parse(uri) }

      parts.each do |part, value|
        it "sets #{part} to #{value.inspect}" do
          subject.send(part).should == value
        end
      end
    end
  end

  describe ".parse" do
    it "returns a Gitable::URI" do
      Gitable::URI.parse(@uri).should be_a_kind_of(Gitable::URI)
    end
  end
end
