# -*- encoding: utf-8 -*-
require File.expand_path('../lib/encoding_sampler/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Tom Wilson"]
  gem.email         = ["tom@rollnorocks.com"]
  gem.description   = %q{Encoding Sampler description here}
  gem.summary       = %q{Encoding Sampler summary here}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "encoding_sampler"
  gem.require_paths = ["lib"]
  gem.version       = EncodingSampler::VERSION
end
