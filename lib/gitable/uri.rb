require 'addressable/uri'

module Gitable
  class URI < Addressable::URI
    SCP_URI_REGEXP = /^([^:\/?#]+):([^?#]*)$/
     
    def self.parse(uri)
      return uri if uri.nil? || uri.kind_of?(self)

      # addressable::URI.parse always returns an instance of Addressable::URI.
      add = super(uri) # >:(

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

    # guesses a project name
    def project_name
      basename.sub(/\.git$/,'')
    end
  end
end
