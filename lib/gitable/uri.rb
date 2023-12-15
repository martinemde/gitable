# frozen_string_literal: true

require "addressable/uri"

module Gitable
  class URI < Addressable::URI
    SCP_REGEXP = %r{^([^:/?#]+):([^:?#]*)$}
    URIREGEX = %r{^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?$}

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
      return unless uri
      return uri.dup if uri.is_a?(self)

      # Copied from Addressable to speed up our parsing.
      #
      # If a URI object of the Ruby standard library variety is passed,
      # convert it to a string, then parse the string.
      # We do the check this way because we don't want to accidentally
      # cause a missing constant exception to be thrown.
      if /^URI\b/.match?(uri.class.name)
        uri = uri.to_s
      end

      # Otherwise, convert to a String
      begin
        uri = uri.to_str
      rescue TypeError, NoMethodError
        raise TypeError, "Can't convert #{uri.class} into String."
      end

      # This Regexp supplied as an example in RFC 3986, and it works great.
      fragments = uri.scan(URIREGEX)[0]
      scheme = fragments[1]
      authority = fragments[3]
      path = fragments[4]
      query = fragments[6]
      fragment = fragments[8]
      host = nil

      if authority
        host = authority.gsub(/^([^\[\]]*)@/, "").gsub(/:([^:@\[\]]*?)$/, "")
      else
        authority = scheme
      end

      if host.nil? && uri =~ SCP_REGEXP
        Gitable::ScpURI.new(authority: $1, path: $2)
      else
        new(
          scheme: scheme,
          authority: authority,
          path: path,
          query: query,
          fragment: fragment
        )
      end
    end

    ##
    # Parse a git repository URI into a URI object.
    # Rescue parse errors and return nil if uri is not parseable.
    #
    # @param [Addressable::URI, #to_str] uri URI of a git repository.
    #
    # @return [Gitable::URI, nil] The parsed uri, or nil if not parseable.
    def self.parse_when_valid(uri)
      parse(uri)
    rescue TypeError, Gitable::URI::InvalidURIError
      nil
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
      return unless uri
      return uri if uri.is_a?(self)

      # Addressable::URI.heuristic_parse _does_ return the correct type :)
      gitable = super # boo inconsistency

      if gitable.github? || gitable.bitbucket? || gitable.gitlab?
        gitable.extname = "git"
      end
      gitable
    end

    # Is this uri a github uri?
    #
    # @return [Boolean] github.com is the host?
    def github?
      host_match?("github.com")
    end

    # Is this uri a gitlab uri?
    #
    # @return [Boolean] gitlab.com is the host?
    def gitlab?
      host_match?("gitlab.com")
    end

    # Is this uri a bitbucket uri?
    #
    # @return [Boolean] bitbucket.org is the host?
    def bitbucket?
      host_match?("bitbucket.org")
    end

    def host_match?(host)
      normalized_host&.include?(host)
    end

    # Create a web link uri for repositories that follow the github pattern.
    #
    # This probably won't work for all git hosts, so it's a good idea to use
    # this in conjunction with #github? or #bitbucket? to help ensure correct
    # links.
    #
    # @param [String] Scheme of the web uri (smart defaults)
    # @return [Addressable::URI] https://#{host}/#{path_without_git_extension}
    def to_web_uri(uri_scheme = "https")
      return nil if normalized_host.to_s.empty?
      Addressable::URI.new(scheme: uri_scheme, host: normalized_host, port: normalized_port, path: normalized_path.sub(%r{\.git/?$}, ""))
    end

    # Tries to guess the project name of the repository.
    #
    # @return [String] Project name without .git
    def project_name
      p = basename.delete_suffix("/")
      p.delete_suffix!(".git")
      p
    end

    def org_project
      op = normalized_path.delete_prefix("/")
      op.delete_suffix!("/")
      op.delete_suffix!(".git")
      op
    end

    # Detect local filesystem URIs.
    #
    # @return [Boolean] Is the URI local
    def local?
      inferred_scheme == "file"
    end

    # Scheme inferred by the URI (URIs without hosts or schemes are assumed to be 'file')
    #
    # @return [Boolean] Is the URI local
    def inferred_scheme
      if normalized_scheme == "file"
        "file"
      elsif (normalized_scheme.nil? || normalized_scheme.empty?) && (normalized_host.nil? || normalized_host.empty?)
        "file"
      else
        normalized_scheme
      end
    end

    # Detect URIs that connect over ssh
    #
    # @return [Boolean] true if the URI uses ssh?
    def ssh?
      !normalized_scheme.nil? && normalized_scheme.include?("ssh")
    end

    # Is this an scp formatted uri? (No, always)
    #
    # @return [false] always false (overridden by scp formatted uris)
    def scp?
      false
    end

    # Detect URIs that will require some sort of authentication
    #
    # @return [Boolean] true if the URI uses ssh or has a user but no password
    def authenticated?
      ssh? || interactive_authenticated?
    end

    # Detect URIs that will require interactive authentication
    #
    # @return [Boolean] true if the URI has a user, but is not using ssh
    def interactive_authenticated?
      !ssh? && (!normalized_user.nil? && normalized_password.nil?)
    end

    # Detect if two URIs are equivalent versions of the same uri.
    #
    # When both uris are github repositories, uses a more lenient matching
    # system is used that takes github's repository organization into account.
    #
    # For non-github URIs this method requires the two URIs to have the same
    # host, equivalent paths, and either the same user or an absolute path.
    #
    # @return [Boolean] true if the URI probably indicates the same repository.
    def equivalent?(other_uri)
      other = Gitable::URI.parse_when_valid(other_uri)
      return false unless other
      return false unless normalized_host.to_s == other.normalized_host.to_s

      if github? || bitbucket?
        # github doesn't care about relative vs absolute paths in scp uris
        org_project == other.org_project
      else
        # if the path is absolute, we can assume it's the same for all users (so the user doesn't have to match).
        normalized_path.delete_suffix("/") == other.normalized_path.delete_suffix("/") &&
          (path[0] == "/" || normalized_user == other.normalized_user)
      end
    end

    # Dun da dun da dun, Inspector Gadget.
    #
    # @return [String] I'll get you next time Gadget, NEXT TIME!
    def inspect
      "#<#{self.class} #{self}>"
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
      return if basename.to_s.empty?
      self.basename = "#{basename.sub(%r{\.git/?$}, "")}.#{new_ext.sub(/^\.+/, "")}"
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
      (super == "/") ? "" : super
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
        self.path = rpath.sub(%r{#{Regexp.escape(base.reverse)}}, new_basename.reverse).reverse
      end
      basename
    end
  end
end

require "gitable/scp_uri"
