# -*- encoding: utf-8 -*-
require File.expand_path('../lib/encoding_sampler/version', __FILE__)

Gem::Specification.new do |s|
  s.authors       = ["Tom Wilson"]
  s.email         = ["tom@rollnorocks.com"]
  s.summary       = %q{Encoding Sampler extracts a concise sample from a text file to simplify selecting the right encoding.}
  s.description   = %q{EncodingSampler helps solve the problem of what to do when the character encoding is unknown, for example when a user is uploading a file but has no idea of its encoding (or typically, even what "character encoding" means.) EncodingSampler extracts a concise set of samples from the selected file for display so the user can choose wisely.}
  s.homepage      = ""

  s.files         = `git ls-files`.split($\)
  s.executables   = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.name          = "encoding_sampler"
  s.require_paths = ["lib"]
  s.version       = EncodingSampler::VERSION

  s.add_dependency('diff-lcs', '1.1.3')

  s.add_development_dependency("rake")
  s.add_development_dependency("debugger")

  s.add_development_dependency("rspec")
  s.add_development_dependency("fakefs")
  s.add_development_dependency("simplecov")

  s.add_development_dependency("yard")
  s.add_development_dependency("redcarpet")
end
