# frozen_string_literal: true

require "addressable/uri"
require "gitable/uri"

module Gitable
  class ScpURI < Gitable::URI
    ##
    # Deprecated: This serves no purpose. You might as well just parse the URI.
    def self.scp?(uri)
      warn "DEPRECATED: Gitable::ScpURI.scp?. You're better off parsing the URI and checking #scp?."
      Gitable::URI.parse(uri).scp?
    end

    ##
    # Deprecated: This serves no purpose. Just use Gitable::URI.parse.
    def self.parse(uri)
      warn "DEPRECATED: Gitable::ScpURI.parse just runs Gitable::URI.parse. Please use this directly."
      Gitable::URI.parse(uri)
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
      if new_path[0] != "/" # addressable adds a / but scp-style uris are altered by this behavior
        @path = path.delete_prefix("/")
        @normalized_path = nil
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
      @uri_string ||= "#{normalized_authority}:#{normalized_path}".force_encoding(Encoding::UTF_8)
    end
    alias_method :to_str, :to_s

    # Return the actual scheme even though we don't show it
    #
    # @return [String] always 'ssh' for scp style URIs
    def inferred_scheme
      "ssh"
    end

    # Scp style URIs are always ssh
    #
    # @return [true] always ssh
    def ssh?
      true
    end

    # Is this an scp formatted uri? (Yes, always)
    #
    # @return [true] always scp formatted uri
    def scp?
      true
    end

    protected

    def validate
      return if @validation_deferred

      if host.nil? || host.empty?
        invalid! "Hostname segment missing"
      end

      if scheme && !scheme.empty?
        invalid! "Scp style URI must not have a scheme"
      end

      if port
        invalid! "Scp style URI cannot have a port"
      end

      if path.nil? || path.empty?
        invalid! "Absolute URI missing hierarchical segment"
      end

      nil
    end

    def invalid!(reason)
      raise InvalidURIError, "#{reason}: '#{self}'"
    end
  end
end
