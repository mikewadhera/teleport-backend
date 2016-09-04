
require "tempfile"
require "open-uri"

class MergerService
  
  def initialize(url, left, right)
    @url = url
    @left = left
    @right = right
  end
  
  def merge!
    source = open(@url)
    
    command = "./merger.sh '#{@left}' '#{@right}' '#{source.path}'"
    
    output_path = `#{command}`
    
    `rm -f '#{source.path}'`
    
    output_path.chomp
  end
  
end