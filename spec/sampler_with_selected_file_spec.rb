require "spec_helper.rb"
  
include EncodingSampler

# For ad-hoc testing using local file.
# Set env var FILENAME='filename'
# Optionally set ENCODINGS='encoding1 encoding2' etc
describe Sampler do
   
  context "when ENV['FILENAME'] is set to a selected filename" do
    let(:default_encodings) {%w(ASCII-8BIT UTF-8 WINDOWS-1252 ISO-8859-1 ISO-8859-2 ISO-8859-15)}
    
    it 'it works and displays the results' do
      sampler, filename = nil, nil
      filename = ENV['FILENAME']
      encodings = ENV['ENCODINGS'] || default_encodings

      if filename.nil? 
        p "ENV['FILENAME'] is nil, skipping ad-hoc test."
      else        
        filename.should_not be_nil
        expect { sampler = Sampler.new(filename, encodings) }.to_not raise_error
        p ''
        p "Results for #{filename}:"
        pp sampler.inspect
        pp sampler.unique_diffed_samples
      end
    end
    
  end
  
end