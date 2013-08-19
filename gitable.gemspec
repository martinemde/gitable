# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name        = "gitable"
  s.version     = "0.2.4"
  s.authors     = ["Martin Emde"]
  s.email       = ["martin.emde@gmail.com"]
  s.homepage    = "http://github.org/martinemde/gitable"
  s.summary     = %q{Addressable::URI for Git. Gitable::URI.}
  s.description = %q{Addressable::URI for Git URIs with special handling for scp-style URIs that Addressable doesn't like.}
  s.license     = 'MIT'

  s.add_dependency "addressable", ">= 2.2.7"
  s.add_development_dependency "rspec", "~>2.11"
  s.add_development_dependency "rake"
  s.add_development_dependency "simplecov"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.extra_rdoc_files = ["LICENSE", "README.rdoc"]
end
