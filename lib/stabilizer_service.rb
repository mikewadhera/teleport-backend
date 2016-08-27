
require "tempfile"

class StabilizerService
  
  def initialize(path)
    @path = path
  end
  
  def stabilize!
    output = Tempfile.new("stabilizer_service")
    
    command = "./stabilizer.sh '#{@path}' '#{output.path}'"
    
    `#{command}`
    
    output.path
  end
  
end