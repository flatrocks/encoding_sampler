require "spec_helper.rb"
  
include EncodingSampler

describe Sampler do
   
  context 'with real files' do
    before(:all) do
      # create some encoded strings
      @encodings = %w(ASCII-8BIT UTF-8 WINDOWS-1252 ISO-8859-1 ISO-8859-2 ISO-8859-15)
      @special_chars = "\u20AC\u201C\u201d\u00A1\u00A2\u00A3\u00A9\u00AE\u00C4\u00C5\u00E4\u00E5"
      @ascii_chars = "ABCDEFabcdef0123456789"
      @mixed_lines = []
      3.times do 
        @mixed_lines << @ascii_chars # first line the same for all
      end
      (0..(@special_chars.length - 1)).each do |i|
        @mixed_lines << @special_chars.chars.to_a[i] + @ascii_chars + @special_chars.chars.to_a[i] + @ascii_chars + @special_chars.chars.to_a[i] 
      end
      # create temp files
      @encoding_file_dir = './spec/files/'
      Dir.mkdir(@encoding_file_dir) unless Dir.exists? @encoding_file_dir
      @file_names = {}
      @encodings.each do |encoding|
        file_name = "#{@encoding_file_dir}#{encoding}.txt"
        @file_names[encoding] = file_name
        File.open(file_name, "w:#{encoding}") do |file|
          # replace: '' to omit characters unavailable for the selected encoding, creating clean valid files
          file.write @mixed_lines.join("\n").encode(encoding, invalid: :replace, undef: :replace, replace: '')
        end
      end
    end
    
    it 'can be created for each file encoding' do
      @encodings.each do |encoding|
        expect { Sampler.new(@file_names[encoding], @encodings) }.to_not raise_error
      end
    end
    
  end
  
end