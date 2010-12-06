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
      @path = path.sub(%r|^/|,'') if new_path[0] != ?/ # addressable likes to add a /
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
          uri_string = "#{authority}:#{path}"
          if uri_string.respond_to?(:force_encoding)
            uri_string.force_encoding(Encoding::UTF_8)
          end
          uri_string
        end
    end

    # Return the actual scheme even though we don't show it
    #
    # @return [String] always 'ssh' for scp style URIs
    def normalized_scheme
      'ssh'
    end

    protected

    def validate
      return if @validation_deferred

      if !scheme.to_s.empty? && host.to_s.empty? && path.to_s.empty?
        raise InvalidURIError, "Absolute URI missing hierarchical segment: '#{to_s}'"
      end

      if host.nil? && !path_only?
        raise InvalidURIError, "Hostname not supplied: '#{to_s}'"
      end

      nil
    end

    def path_only?
      host.nil? && port.nil? && user.nil? && password.nil?
    end
  end
end
