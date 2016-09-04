
require "tempfile"
require "open-uri"

class StabilizerService
  
  FORMAT = "mp4"
  
  def initialize(url, side)
    @url = url
    @side = side
  end
  
  def stabilize!
    source = open(@url)
    
    command = "./stabilizer.sh '#{@side}' '#{source.path}'"
    
    output_path = `#{command}`
    
    output_path
  end
  
end