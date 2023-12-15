# frozen_string_literal: true

require_relative "lib/gitable/version"

Gem::Specification.new do |spec|
  spec.name = "gitable"
  spec.version = Gitable::VERSION
  spec.authors = ["Martin Emde"]
  spec.email = ["martin.emde@gmail.com"]
  spec.homepage = "https://github.com/martinemde/gitable"
  spec.summary = 'Addressable::URI with additional support for Git "URIs"'
  spec.description = %q(Addressable::URI for Git "URIs" with special handling for scp-style remotes that Addressable intentionally doesn't parse.)
  spec.license = "MIT"

  # spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/martinemde/gitable"
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.add_dependency "addressable", "~> 2.2", ">= 2.2.7"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
