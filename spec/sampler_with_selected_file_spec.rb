require "spec_helper.rb"
  
include EncodingSampler

describe Sampler do
   
  context 'with a selected file' do
    let(:encodings) {%w(ASCII-8BIT UTF-8 WINDOWS-1252 ISO-8859-1 ISO-8859-2 ISO-8859-15)}
    
    it 'can be created for each file encoding' do
      sampler = nil
      filename = nil

      pp 'set filename= to a real filename for testing... (must be debug mode)'
      debugger
      if filename.nil?
        pp "No filename given, skipped."
      else
        expect { sampler = Sampler.new(filename, encodings) }.to_not raise_error
        p ''
        p "Results for #{filename}:"
        pp sampler.inspect
        pp sampler.unique_diffed_samples
      end

    end
    
  end
  
end