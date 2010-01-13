require 'gitable/uri'

module Gitable
  class ScpURI < Gitable::URI
    # Keep URIs like this relative:
    #
    #     git@github.com:martinemde/gitable.git
    #
    # Without breaking URIs like these:
    # 
    #     git@host.com:/home/martinemde/gitable.git
    #
    def path=(new_path)
      super
      if new_path[0..0] != "/"
        @path = path.sub(%r|^/|,'')
      end
      path
    end

    def to_s
      @uri_string ||= begin
                        uri_string = "#{authority}:#{path.to_s}"
                        if uri_string.respond_to?(:force_encoding)
                          uri_string.force_encoding(Encoding::UTF_8)
                        end
                        uri_string
                      end
    end
  end
end
