require 'addressable/uri'

module Gitable
  class URI < Addressable::URI
    SCP_URI_REGEXP = %r|^([^:/?#]+):([^?#]*)$|

    ##
    # Parse a git repository URI into a URI object.
    #
    # @param [Addressable::URI, #to_str] uri URI of a git repository.
    #
    # @return [Gitable::URI, nil] the URI object or nil if nil was passed in.
    #
    # @raise [TypeError] The uri must respond to #to_str.
    # @raise [Gitable::URI::InvalidURIError] When the uri is *total* rubbish.
    #
    def self.parse(uri)
      return uri if uri.nil? || uri.kind_of?(self)

      # addressable::URI.parse always returns an instance of Addressable::URI.
      add = super # >:( at inconsistency

      authority = uri.scan(SCP_URI_REGEXP).flatten.first

      if add.host.nil? && authority
        Gitable::ScpURI.new(
          :authority  => authority,
          :path       => add.path
        )
      else
        new(add.omit(:password,:query,:fragment).to_hash)
      end
    end

    ##
    # Attempts to make a copied URL bar into a git repository URI.
    #
    # First line of defense is for URIs without .git as a basename:
    # * Change the scheme from http:// to git://
    # * Add .git to the basename
    #
    # @param [Addressable::URI, #to_str] uri URI of a git repository.
    #
    # @return [Gitable::URI, nil] the URI object or nil if nil was passed in.
    #
    # @raise [TypeError] The uri must respond to #to_str.
    # @raise [Gitable::URI::InvalidURIError] When the uri is *total* rubbish.
    #
    def self.heuristic_parse(uri)
      return uri if uri.nil? || uri.kind_of?(self)

      # Addressable::URI.heuristic_parse _does_ return the correct type :)
      add = super # boo inconsistency

      if add.extname != ".git"
        add.extname = "git"
        add.scheme = "git" if add.scheme == "http"
      end
      add
    end

    ##
    # Tries to guess the project name of the repository.
    #
    # @return [String] Project name without .git
    def project_name
      basename.sub(/\.git$/,'')
    end

    def local?
      scheme == 'file' || (scheme.nil? && host.nil?)
    end

    # Set an extension name, replacing one if it exists.
    #
    # If there is no basename (i.e. no words in the path) this method call will
    # be ignored because it is likely to break the uri.
    #
    # @param [String] New extension name
    # @return [String] extname result
    def extname=(ext)
      base = basename
      return nil if base.nil? || base == ""
      self.basename = "#{base}.#{ext.sub(/^\.+/,'')}"
      extname
    end

    # Addressable does basename wrong when there's no basename.
    # It returns "/" for something like "http://host.com/"
    def basename
      base = super
      base == "/" ? "" : base
    end

    # Set the basename, replacing it if it exists.
    #
    # @param [String] New basename
    # @return [String] basename result
    def basename=(new_basename)
      base = basename
      if base.nil? || base == ""
        self.path += new_basename
      else
        rpath = path.reverse
        # replace the last occurrence of the basename with basename.ext
        self.path = rpath.sub(%r|#{Regexp.escape(base.reverse)}|, new_basename.reverse).reverse
      end
      basename
    end

    protected

    def validate
      return if @validation_deferred
      super

      if user && scheme != 'ssh'
        raise InvalidURIError, "Git does not support URIs with 'user@' other than ssh:// and scp-style"
      end
    end
  end
end
