require 'gitable/uri'

module Gitable
  class ScpURI < Gitable::URI

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
      if new_path[0] != ?/ # addressable likes to add a / but scp-style uris are altered by this behaviour
        @path = path.sub(%r|^/|,'')
        @normalized_path = normalized_path.sub(%r|^/|,'')
      end
      @path
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

      if !normalized_scheme.to_s.empty? && normalized_host.to_s.empty? && normalized_path.to_s.empty?
        raise InvalidURIError, "Absolute URI missing hierarchical segment: '#{to_s}'"
      end

      if normalized_host.nil? && !path_only?
        raise InvalidURIError, "Hostname not supplied: '#{to_s}'"
      end

      nil
    end

    def path_only?
      normalized_host.nil? && normalized_port.nil? && normalized_user.nil? && normalized_password.nil?
    end
  end
end
