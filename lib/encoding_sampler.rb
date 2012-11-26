require "encoding_sampler/version"

module EncodingSampler
  
  class Sampler
    
    attr_accessor filename, encodings, valid_encodings, unique_valid_encodings
    
    def all_samples(options = {})
      # order: :original, :best
      # only_best: true/false
    end
    
    def sample(encoding)
      # return complete sample for the specified encoding.
      # may be an empty array if there are no
    end
  
  private
    def initialize(file_name, encodings)
      @filename = file_name.freeze
      @unique_valid_encodings, @differences, @binary_samples = [], [], {}, {}
 
      solutions = {}
      encodings.sort.combination(2).to_a.each {|pair| solutions[pair] = nil}
      
      # read the entire file to verify encodings and collect samples for comparison of encodings
      File.open(@filename, 'rb') do |file|
        break if file.eof?
        binary_line = file.readline.strip
        decoded_lines = @encodings.collect {|encoding| decode_binary_string(binary_line, encoding)}

        # eliminate any newly-invalid encodings from the scope
        decoded_lines.select {|encoding, decoded_line| decoded_line.nil?}.keys.each do |invalid_encoding|
          encodings.delete invalid_encoding
          solutions.delete_if {|pair, lineno| pair.include? invalid_encoding}
          @binary_samples.keep_if {|id, string| solutions.keys.flatten.include? id}
        end
        
        # add sample_id to solutions when smaple sample when binary string decodes differently for two encodings
        solutions.select {|pair, line_index| lineno.nil?}.keys.each do |unsolved_pair|
          solutions[pair], @binary_samples[file.lineno] = file.lineno, binary_line if decoded_lines[pair[0]] != decoded_lines[pair[1]]
        end
      end
      
      # combine to groups
      (solutions.select {|pair, lineno| line_index.nil?}.keys + encodings.collect {|encoding| [encoding]}).each do |subgroup|
        group_index = @unique_valid_encodings.index {|group| !(group & subgroup).empty?}
        group_index ? @unique_valid_encodings[group_index] |= subgroup : @unique_valid_encodings << subgroup
      end   
   
      @unique_valid_encodings = @unique_valid_encodings.each {|group| group.freeze}.freeze
      @binary_samples.freeze
    end
    
    def decode_binary_string(binary_string, encoding)
      begin
        encoded_string = binary_string.dup.force_encoding(encoding)
        raise unless encoded_string.valid_encoding?
        encoded_string.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
      rescue
        nil
      end
    end
  
  end
  
end
