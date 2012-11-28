require "cgi"

module EncodingSampler
  
  class DiffCallbacks
    attr_accessor :output
    attr_reader :difference_start, :difference_end
  
    def initialize(output, options = {})
      @output = output
      options ||= {}
      @difference_start = options[:difference_start] ||= '<span class="difference">'
      @difference_end = options[:difference_end] ||= '</span>'
    end
  
    # This will be called with both strings are the same
    def match(event)
      output_matched event.old_element
    end
  
    # This will be called when there is a substring in A that isn't in B
    def discard_a(event)
      output_changed event.old_element
    end
  
    # This will be called when there is a line in B that isn't in A
    def discard_b(event)
      output_changed event.new_element
    end
    
  private
   
    def output_matched(element)
      element = CGI.escapeHTML(element.chomp)
      @output << "#{element}" unless element.empty?
    end
  
    def output_changed(element)
      element = CGI.escapeHTML(element.chomp)
      return if element.empty?   
      @output << "#{@difference_start}#{element}#{@difference_end}"
      @output.gsub "#{element}#{@difference_end}#{@difference_start}", ''
    end
     
  end

end