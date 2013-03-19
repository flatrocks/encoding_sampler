require "spec_helper.rb"
  
include EncodingSampler

describe Sampler do
  context 'with fakefs', fakefs: true do
    before(:each) do
      @filedir = '/test'
      @filename = '/test/testfile'
      @lines = %w(one two three four five)
      FileUtils.mkdir(@filedir) unless Dir.exists?(@filedir)
      File.open(@filename, "w") do |f|
        @lines.each do |line|
          f.puts line
        end
      end
      @test_sampler = Sampler.new(@filename, %w(US-ASCII UTF-8))
    end
    
    describe 'verifying fakefs just to make sure' do
      # Make sure this works right after all the trouble with home-grown file system stubs!!
      
      it 'can open and readline without error' do
        expect {
          File.open(@filename, 'r') do |file|
            until file.eof?          
              file.readline
            end
          end
        }.to_not raise_error
      end    
      
      it 'raises EOFError when readline called past eof' do
        expect {
          File.open(@filename, 'r') do |file|
            until file.eof?          
              file.readline
            end
            file.readline
          end
        }.to raise_error(EOFError)
      end     
      
      it 'readline returns lines' do
        lines_read = []
        File.open(@filename, 'r') do |file|
          until file.eof?          
            lines_read << file.readline.chomp
          end
        end
        lines_read.should eq @lines
      end  

    end
    
    describe 'creation' do
      
      it 'works with required arguments' do
        Sampler.new(@filename, []).should be_a Sampler
      end
      
      it 'requires a filename' do
        expect {Sampler.new()}.to raise_error
      end
      
      it 'requires encodings' do
        expect {Sampler.new(@filename)}.to raise_error
      end
      
      it 'passes error raised on File.open' do
        File.stub(:open).and_raise 'some error'
        expect {Sampler.new(@filename, [])}.to raise_error('some error')
      end
      
      it 'passes error raised on file.readline' do
        File.any_instance.stub(:readline).and_raise 'some error'
        expect {Sampler.new(@filename, [])}.to raise_error('some error')
      end                
      
    end

    describe "#filename" do

      it 'returns the same filename used to create the instance' do
        Sampler.new(@filename, []).filename.should eq @filename
      end

      it 'is read-only' do
        expect {Sampler.new(@filename, []).filename = 'anything'}.to raise_error NoMethodError
      end

    end
    
    describe '#unique_valid_encoding_groups' do
      before(:each) do
        Sampler.any_instance.stub(:decode_binary_string) do |*args|
          if ['ENCODING1', 'LIKE_ENCODING1'].include? args[1]
            args[0]
          else 
            args[0].gsub(/t/, 'T')
          end
        end
      end

      it 'is read-only' do
        expect {Sampler.new(@filename, []).unique_valid_encoding_groups = 'anything'}.to raise_error NoMethodError
      end

      it 'is frozen' do
        Sampler.new(@filename, []).unique_valid_encoding_groups.should be_frozen
      end
      
      shared_examples 'unique_valid_encoding_groups format is correct' do
        
        it 'returns an array' do
          @sampler.unique_valid_encoding_groups.should be_a Array
        end
        
        it 'each array element is an array of strings (encoding names)' do
          @sampler.unique_valid_encoding_groups.each do |element|
            element.should be_a Array
            element.each do |encoding|
              encoding.should be_a String
            end
          end       
        end
        
        it 'array elements do not share members with other elements' do
          @sampler.unique_valid_encoding_groups.flatten.size.should eq @sampler.unique_valid_encoding_groups.flatten.uniq.size
        end
          
      end
      
      context 'when there are no lines read' do
        before(:each) do        
          File.any_instance.stub(:eof?).and_return true
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1))        
        end
        
        it_behaves_like 'unique_valid_encoding_groups format is correct'
        
        it 'returns all encodings in a single array element' do
          @sampler.unique_valid_encoding_groups.count.should eq 1
        end
        
        it 'contains all valid encodings' do
          @sampler.unique_valid_encoding_groups.flatten.size.should eq 3
        end
       
      end
  
      context 'when all encodings work the same' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1))
        end
        
        it_behaves_like 'unique_valid_encoding_groups format is correct'      
        
        it 'returns all encodings in a single array element' do
          @sampler.unique_valid_encoding_groups.count.should eq 1
        end
          
        it 'the single array element contains all valid encodings' do
          @sampler.unique_valid_encoding_groups[0].should eq %w(ENCODING1 LIKE_ENCODING1)
        end
  
      end
      
      context 'when encodings are different' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 UNLIKE_ENCODING1))
        end
        
        it_behaves_like 'unique_valid_encoding_groups format is correct'      
        
        it 'returns all encodings in two array elements' do
          @sampler.unique_valid_encoding_groups.count.should eq 2
        end
          
        it 'the first array element contains one of the valid encodings' do
          %w(ENCODING1 UNLIKE_ENCODING1).should include @sampler.unique_valid_encoding_groups[0][0]
        end      
        
        it 'the second array element contains one of the valid encodings' do
          %w(ENCODING1 UNLIKE_ENCODING1).should include @sampler.unique_valid_encoding_groups[1][0]
        end      
        
        it 'the array elements contains all valid encodings' do
          @sampler.unique_valid_encoding_groups.flatten.sort.should eq %w(ENCODING1 UNLIKE_ENCODING1).sort
        end
              
      end
    end

    describe '#valid_encodings' do

      it 'should contain all encodings in unique_valid_encoding_groups' do
        @test_sampler.valid_encodings.sort.should eq @test_sampler.unique_valid_encodings.flatten.sort
      end

    end
   
    describe '#sample' do
      before(:each) do
        Sampler.any_instance.stub(:decode_binary_string) do |*args|
          if ['ENCODING1', 'LIKE_ENCODING1'].include? args[1]
            args[0]
          else 
            args[0].gsub(/t/, 'T')
          end
        end
      end
      
      shared_examples 'sample format is correct' do
        
        it 'returns a hash for each valid encoding' do
          @sampler.valid_encodings.each do |encoding|
            @sampler.sample(encoding).should be_a Array
          end
        end
        
        it 'elements are strings (decoded lines)' do
          @sampler.sample('ENCODING1').each do |element|
            element.should be_a String
          end       
        end      
          
      end
      
      context 'when there are no lines read' do
        before(:each) do        
          File.any_instance.stub(:eof?).and_return true
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1))        
        end
        
        it_behaves_like 'sample format is correct'
        
        it 'it is empty' do
          %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1).each do |encoding| 
            @sampler.sample(encoding).should be_empty
          end
        end
       
      end
      
  
      context 'when all encodings work the same' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1))
        end
        
        it_behaves_like 'sample format is correct'      
        
        it 'it is empty' do
          %w(ENCODING1 LIKE_ENCODING1).each do |encoding| 
            @sampler.sample(encoding).should be_empty
          end       
        end
  
      end
      
      context 'when encoding are different' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 UNLIKE_ENCODING1))
        end
        
        it_behaves_like 'sample format is correct'      
        
        it 'it is not empty' do
          %w(ENCODING1 LIKE_ENCODING1).each do |encoding| 
            @sampler.sample(encoding).should_not be_empty
          end
        end      
        
        it 'the samples values should not be equal' do
          @sampler.sample('ENCODING1').should_not eq @sampler.sample('UNLIKE_ENCODING1')
        end 
              
      end
    end
    
    describe '#samples' do
      before(:each) do
        Sampler.any_instance.stub(:decode_binary_string) do |*args|
          if ['ENCODING1', 'LIKE_ENCODING1'].include? args[1]
            args[0]
          else 
            args[0].gsub(/t/, 'T')
          end
        end
      end
      
      context 'when there are no lines read' do
        before(:each) do        
          File.any_instance.stub(:eof?).and_return true
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1))        
        end
        
        it 'each included sample is empty' do
          @sampler.samples.each {|encoding, sample| sample.should be_empty}
        end
       
      end
      
  
      context 'when all encodings work the same' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1))
        end
        
        it 'each included sample is empty' do
          @sampler.samples.each {|encoding, sample| sample.should be_empty}
        end
  
      end
      
      context 'when encoding are different' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 UNLIKE_ENCODING1))
        end     
        
        it 'it is not empty' do
          %w(ENCODING1 LIKE_ENCODING1).each do |encoding| 
            @sampler.samples.should_not be_empty
          end
        end
        
        it 'should have a sample for each valid encoding' do
          (@sampler.samples.keys & @sampler.valid_encodings).sort.should eq @sampler.valid_encodings.sort
        end            
        
        it 'each sample value (the string samples) should be the same size' do
          sample_values = @sampler.samples.values
          sample_values.each do |sample_value|
            sample_value.size.should eq sample_values.first.size
          end
        end         
        
        # it 'the sample values should not be equal, duh' do
          # samples = @sampler.samples
          # samples.values.each do |string_array|
            # samples['ENCODING1'][key].should_not eq samples['UNLIKE_ENCODING1'][key]
          # end
        # end
              
      end      
      
    end

    describe '#best_encodings' do
      before(:each) do
       Sampler.any_instance.stub(:decode_binary_string) do |*args|
          case args[1]
          when 'SHORTEST_ENCODING' then args[0]
          when 'LIKE_SHORTEST_ENCODING' then args[0].reverse # same length and different is all that matters
          when 'INVALID_ENCODING' then nil
          else args[0].gsub(/t/, 'T&#') # force longer faked encoding for letter 't'
          end
        end
      end
      
      context 'no valid encodings' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(INVALID_ENCODING))  
        end
        it 'returns empty array' do
          @sampler.best_encodings.should eq []
        end
      end
      
      context 'one valid encoding' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(SHORTEST_ENCODING))  
        end
        it 'returns an array with the one shortest encoding' do 
          @sampler.best_encodings.should eq ['SHORTEST_ENCODING']
        end
      end      
            
      context 'when one shortest encoding' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(SHORTEST_ENCODING LONGER_ENCODING))  
        end
        it 'returns an array with the one shortest encoding' do
          @sampler.best_encodings.should eq ['SHORTEST_ENCODING']
        end
      end
      
      context 'when more than one shortest encoding' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(SHORTEST_ENCODING LIKE_SHORTEST_ENCODING LONGER_ENCODING))  
        end
        it 'returns an array with the shortest encodings' do
          @sampler.best_encodings.should eq ['SHORTEST_ENCODING', 'LIKE_SHORTEST_ENCODING']
        end
      end
            
    end   

    describe '#unique_samples' do

      it 'should return a Hash' do
        @test_sampler.unique_samples.should be_a Hash
      end

      it 'should have keys equal to first item from each valid_encoding_group' do
        @test_sampler.unique_samples.keys.should eq @test_sampler.unique_valid_encoding_groups.collect {|group| group.first}
      end

      it 'should provide the right sample value for each key' do
        @test_sampler.unique_samples.keys.each do |encoding|
          @test_sampler.unique_samples[encoding].should eq @test_sampler.sample(encoding)
        end
      end

    end

    describe 'diffed_sample' do
      before(:each) do
        Sampler.any_instance.stub(:decode_binary_string) do |*args|
          if ['ENCODING1', 'LIKE_ENCODING1'].include? args[1]
            args[0]
          else 
            args[0].gsub(/t/, 'T')
          end
        end
        @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1))          
      end
    
      it 'works' do
        @sampler.diffed_sample('ENCODING1')
      end
      
      it 'returns an array' do
        # note: two different encodings that express different results only takes one sample
        @sampler.diffed_sample('ENCODING1').should be_a Array
      end      
      
      it 'has one line for each sample' do
        # note: two different encodings that express different results only takes one sample
        @sampler.diffed_sample('ENCODING1').size.should eq 1
      end
      
      it 'returns identical results when the decoded strings are the same' do
        @sampler.diffed_sample('ENCODING1').should eq @sampler.diffed_sample('LIKE_ENCODING1')
      end      
      
      it 'returns different results when the decoded strings are different' do
        @sampler.diffed_sample('ENCODING1').should_not eq @sampler.diffed_sample('UNLIKE_ENCODING1')
      end
    
    end    
   
    describe 'diffed_samples' do
      before(:each) do
        Sampler.any_instance.stub(:decode_binary_string) do |*args|
          if ['ENCODING1', 'LIKE_ENCODING1'].include? args[1]
            args[0]
          else 
            args[0].gsub(/t/, 'T')
          end
        end
      end
      
      context 'with default options' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1)) 
        end
    
        it 'works' do
          @sampler.diffed_samples(['ENCODING1'])
        end
        
        it 'returns a hash' do
          # note: two different encodings that express different results only takes one sample
          @sampler.diffed_samples(['ENCODING1']).should be_a Hash
        end          
        
        it 'keys match encodings in argument' do
          # note: two different encodings that express different results only takes one sample
          @sampler.diffed_samples(['ENCODING1','UNLIKE_ENCODING1']).keys.should eq ['ENCODING1','UNLIKE_ENCODING1']
        end
        
        it 'values match the values from diffed_sample for the same encoding' do
          @sampler.diffed_samples(['ENCODING1'])['ENCODING1'].should eq @sampler.diffed_sample('ENCODING1')
        end
      end
      
      context 'with custom :difference_start, :difference_end options' do
        before(:each) do
          @sampler = Sampler.new(@filename, %w(ENCODING1 LIKE_ENCODING1 UNLIKE_ENCODING1), difference_start: '<start>', difference_end: '<end>') 
        end
        
        it 'uses difference_start value specified in options hash' do
          @sampler.diffed_sample('ENCODING1').join.should include '<start>'
        end
        
        it 'uses difference_end value specified in options hash' do
          @sampler.diffed_sample('ENCODING1').join.should include '<end>'
        end        
        
      end
    
    end    

    describe '#unique_diffed_samples' do

      it 'should return a Hash' do
        @test_sampler.unique_diffed_samples.should be_a Hash
      end

      it 'should have keys equal to first item from each valid_encoding_group' do
        @test_sampler.unique_diffed_samples.keys.should eq @test_sampler.unique_valid_encoding_groups.collect {|group| group.first}
      end

      it 'should provide the right sample value for each key' do
        @test_sampler.unique_diffed_samples.keys.each do |encoding|
          @test_sampler.unique_diffed_samples[encoding].should eq @test_sampler.diffed_samples[encoding]
        end
      end

    end

  end 
end