require 'addressable/uri'
require 'gitable/uri'

module Gitable
  class ScpURI < Gitable::URI
    REGEXP = %r|^([^:/?#]+):([^:?#]*)$|

    ##
    # Expected to be an scp style URI if Addressable interprets it wrong and
    # it matches our scp regexp
    #
    # nil host is an Addressable misunderstanding (therefore it might be scp style)
    def self.scp?(uri)
      uri && uri.match(REGEXP) && Addressable::URI.parse(uri).normalized_host.nil?
    end

    ##
    # Parse an Scp style git repository URI into a URI object.
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

      if scp?(uri)
        authority, path = uri.scan(REGEXP).flatten
        Gitable::ScpURI.new(:authority => authority, :path => path)
      else
        raise InvalidURIError, "Unable to parse scp style URI: #{uri}"
      end
    end


    # Keep URIs like this as they were input:
    #
    #     git@github.com:martinemde/gitable.git
    #
    # Without breaking URIs like these:
    #
    #     git@host.com:/home/martinemde/gitable.git
    #
    # @param [String] new_path The new path to be set.
    # @return [String] The same path passed in.
    def path=(new_path)
      super
      if new_path[0..0] != '/' # addressable adds a / but scp-style uris are altered by this behavior
        @path = path.sub(%r|^/+|,'')
        @normalized_path = normalized_path.sub(%r|^/+|,'')
        validate
      end
      path
    end

    # Get the URI as a string in the same form it was input.
    #
    # Taken from Addressable::URI.
    #
    # @return [String] The URI as a string.
    def to_s
      @uri_string ||=
        begin
          uri_string = "#{normalized_authority}:#{normalized_path}"
          if uri_string.respond_to?(:force_encoding)
            uri_string.force_encoding(Encoding::UTF_8)
          end
          uri_string
        end
    end

    # Return the actual scheme even though we don't show it
    #
    # @return [String] always 'ssh' for scp style URIs
    def inferred_scheme
      'ssh'
    end

    # Scp style URIs are always ssh
    #
    # @return [true] always ssh
    def ssh?
      true
    end

    protected

    def validate
      return if @validation_deferred

      if normalized_host.to_s.empty?
        raise InvalidURIError, "Hostname segment missing: '#{to_s}'"
      end

      unless normalized_scheme.to_s.empty?
        raise InvalidURIError, "Scp style URI must not have a scheme: '#{to_s}'"
      end

      if !normalized_port.to_s.empty?
        raise InvalidURIError, "Scp style URI cannot have a port: '#{to_s}'"
      end

      if normalized_path.to_s.empty?
        raise InvalidURIError, "Absolute URI missing hierarchical segment: '#{to_s}'"
      end

      nil
    end
  end
end
