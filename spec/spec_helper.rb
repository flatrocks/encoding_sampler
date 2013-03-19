if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start { add_filter '/test/' }
end

require 'encoding_sampler'
require 'fakefs/spec_helpers'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.include FakeFS::SpecHelpers, fakefs: true
end
