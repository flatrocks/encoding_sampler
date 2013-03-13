require 'encoding_sampler/version'
require 'encoding_sampler/diff_callbacks'
require 'diff-lcs'

module EncodingSampler
  
  class Sampler
    
    attr_accessor :filename, :unique_valid_encodings
    
    # All valid encodings.  
    def valid_encodings
      unique_valid_encodings.flatten
    end
    
    # An array of sample file lines, decoded by _encoding_
    def sample(encoding)
      @binary_samples.values.map {|line| decode_binary_string(line, encoding)}
    end
    
    # Returns a hash of samples, keyed by encoding
    def samples(encodings = valid_encodings)
      encodings.inject({}) {|hash, encoding| hash.merge! encoding => sample(encoding)}
    end
    
    # Assumes shortest strings are most likely to be correct
    def best_encodings
      candidates = samples(unique_valid_encodings.collect {|encoding_group| encoding_group.first})
      min_length = candidates.values.collect {|ary| ary.join('').size}.min
      candidates.keys.select {|key| candidates[key].join('').size == min_length}
    end
    
    # "unique" because multiple encodings often return the exact same samples, so only return the unique ones.
    # What's first in each grouping is based on original order of encodings give to the constructor.
    def unique_samples
      samples(unique_valid_encodings.collect {|encoding_group| encoding_group.first})
    end
    
    def diffed_sample(encoding)
      diffed_encoded_samples[encoding]
    end
    
    def diffed_samples(encodings = valid_encodings)
      encodings.inject({}) {|hash, encoding| hash.merge! encoding => diffed_sample(encoding)}
    end
  
    def unique_diffed_samples
      diffed_samples(unique_valid_encodings.collect {|encoding_group| encoding_group.first})
    end
  
  private
   
    def initialize(file_name, encodings, diff_options = {})
      @diff_options = diff_options
      @filename = file_name.freeze
      @unique_valid_encodings, @binary_samples, solutions = [], {}, {}
 
      solutions = {}
      encodings.sort.combination(2).to_a.each {|pair| solutions[pair] = nil}
      
      # read the entire file to verify encodings and collect samples for comparison of encodings
      File.open(@filename, 'rb') do |file|
        until file.eof?
          binary_line = file.readline.strip
          decoded_lines = multi_decode_binary_string(binary_line, encodings)

          # eliminate any newly-invalid encodings from the scope
          decoded_lines.select {|encoding, decoded_line| decoded_line.nil?}.keys.each do |invalid_encoding|
            encodings.delete invalid_encoding
            solutions.delete_if {|pair, lineno| pair.include? invalid_encoding}
            @binary_samples.keep_if {|id, string| solutions.keys.flatten.include? id}
          end        
          
          # add sample_id to solutions when smaple sample when binary string decodes differently for two encodings
          solutions.select {|pair, lineno| lineno.nil?}.keys.each do |unsolved_pair|
            solutions[unsolved_pair], @binary_samples[file.lineno] = file.lineno, binary_line if decoded_lines[unsolved_pair[0]] != decoded_lines[unsolved_pair[1]]
          end
        end
      end
      
      # combine to groups
      (solutions.select {|pair, lineno| lineno.nil?}.keys + encodings.collect {|encoding| [encoding]}).each do |subgroup|
        group_index = @unique_valid_encodings.index {|group| !(group & subgroup).empty?}
        group_index ? @unique_valid_encodings[group_index] |= subgroup : @unique_valid_encodings << subgroup
      end   
      
      @unique_valid_encodings = @unique_valid_encodings.each {|group| group.freeze}.freeze
      @binary_samples.freeze
    end
    
    def decode_binary_string(binary_string, encoding)
      encoded_string = binary_string.dup.force_encoding(encoding)
      encoded_string.valid_encoding? ? encoded_string.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') : nil
    end
    
    def multi_decode_binary_string(binary_string, encodings)
      decoded_lines = {}
      encodings.each {|encoding| decoded_lines[encoding] = decode_binary_string(binary_string, encoding)}
      decoded_lines
    end
    
    def diffed_strings(array_of_strings)
      lcs = array_of_strings.inject {|intermediate_lcs, string| Diff::LCS.LCS(intermediate_lcs, string).join }
      callbacks = DiffCallbacks.new(diff_output = '', @diff_options)
      array_of_strings.map do |string| 
        diff_output.clear
        Diff::LCS.traverse_sequences(lcs, string, callbacks)
        diff_output.dup
      end
    end

    def diffed_encoded_samples
      return @diffed_encoded_samples if @diffed_encoded_samples
      
      encodings = valid_encodings.freeze
      decoded_samples = samples(encodings)
      @diffed_encoded_samples = encodings.inject({}) {|hash, key| hash.merge! key => []}
      
      @binary_samples.values.each_index do |i|
        decoded_lines = encodings.map {|encoding| decoded_samples[encoding][i]}
        diffed_encoded_lines = diffed_strings(decoded_lines)
        encodings.each_index {|j| @diffed_encoded_samples[encodings[j]] << diffed_encoded_lines[j] }
      end
      
      @diffed_encoded_samples.freeze
    end
  
  end
  
end
