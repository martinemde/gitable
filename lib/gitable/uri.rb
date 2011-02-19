require 'addressable/uri'

module Gitable
  class URI < Addressable::URI

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

      if Gitable::ScpURI.scp?(uri)
        # nil host is an Addressable misunderstanding (therefore it might be scp style)
        Gitable::ScpURI.parse(uri)
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
      gitable = super # boo inconsistency

      if gitable.github?
        gitable.extname = "git"
      end
      gitable
    end

    # Is this uri a github uri?
    #
    # @return [Boolean] github.com is the host?
    def github?
      !!normalized_host.to_s.match(/\.?github.com$/)
    end

    # Create a web uri for repositories that follow the github pattern.
    # This probably won't work for all git hosts, so it's a good idea to use
    # this in conjunction with #github? to help ensure correct links.
    #
    # @param [String] Scheme of the web uri (smart defaults)
    # @return [Addressable::URI] https://#{host}/#{path_without_git_extension}
    def to_web_uri(uri_scheme='https')
      return nil if normalized_host.to_s.empty?
      Addressable::URI.new(:scheme => uri_scheme, :host => normalized_host, :port => normalized_port, :path => normalized_path.sub(%r#\.git/?#, ''))
    end

    # Tries to guess the project name of the repository.
    #
    # @return [String] Project name without .git
    def project_name
      basename.sub(/\.git$/,'')
    end

    # Detect local filesystem URIs.
    #
    # @return [Boolean] Is the URI local
    def local?
      inferred_scheme == 'file'
    end

    # Scheme inferred by the URI (URIs without hosts or schemes are assumed to be 'file')
    #
    # @return [Boolean] Is the URI local
    def inferred_scheme
      if normalized_scheme == 'file' || (normalized_scheme.to_s.empty? && normalized_host.to_s.empty?)
        'file'
      else
        normalized_scheme
      end
    end

    # Detect URIs that connect over ssh
    #
    # @return [Boolean] true if the URI uses ssh?
    def ssh?
      !!normalized_scheme.to_s.match(/ssh/)
    end

    # Detect URIs that will require some sort of authentication
    #
    # @return [Boolean] true if the URI uses ssh or has a user but no password
    def authenticated?
      ssh? || (!normalized_user.nil? && normalized_password.nil?)
    end

    # Set an extension name, replacing one if it exists.
    #
    # If there is no basename (i.e. no words in the path) this method call will
    # be ignored because it is likely to break the uri.
    #
    # Use the public method #set_git_extname unless you actually need some other ext
    #
    # @param [String] New extension name
    # @return [String] extname result
    def extname=(new_ext)
      return nil if basename.to_s.empty?
      self.basename = "#{basename.sub(%r#\.git/?$#, '')}.#{new_ext.sub(/^\.+/,'')}"
      extname
    end

    # Set the '.git' extension name, replacing one if it exists.
    #
    # If there is no basename (i.e. no words in the path) this method call will
    # be ignored because it is likely to break the uri.
    #
    # @return [String] extname result
    def set_git_extname
      self.extname = "git"
    end

    # Addressable does basename wrong when there's no basename.
    # It returns "/" for something like "http://host.com/"
    def basename
      super == "/" ? "" : super
    end

    # Set the basename, replacing it if it exists.
    #
    # @param [String] New basename
    # @return [String] basename result
    def basename=(new_basename)
      base = basename
      if base.to_s.empty?
        self.path += new_basename
      else
        rpath = normalized_path.reverse
        # replace the last occurrence of the basename with basename.ext
        self.path = rpath.sub(%r|#{Regexp.escape(base.reverse)}|, new_basename.reverse).reverse
      end
      basename
    end

    protected

    def validate
      return if @validation_deferred
      super

      if normalized_user && normalized_scheme != 'ssh'
        raise InvalidURIError, "URIs with 'user@' other than ssh:// and scp-style are not supported."
      end
    end
  end
end
