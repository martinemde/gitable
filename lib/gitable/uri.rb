require 'addressable/uri'

module Gitable
  class URI < Addressable::URI
    SCP_URI_REGEXP = %r|^([^:/?#]+):([^?#]*)$|

    ##
    # Parse a git repository uri into a URI object.
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
      add = super # >:(

      scan = uri.scan(SCP_URI_REGEXP)
      fragments = scan[0]
      authority = fragments && fragments[0]

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
    # Attempts to make a copied url bar into a git repo uri
    # 
    # First line of defense is for urls without .git as a basename:
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

      add = super
      return add if add.extname == "git"
      add.scheme = "git" if add.scheme == "http"
      unless add.basename.nil?
        # replace the last occurance of the basename with basename.git
        # please tell me if there's a better way (besides rindex/slice/insert)
        rpath = add.path.reverse
        rbase = add.basename.reverse
        add.path = rpath.sub(%r|#{Regexp.escape(rbase)}|,"tig."+rbase).reverse
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
  end
end
