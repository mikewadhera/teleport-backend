
require "tempfile"

class StabilizerService
  
  FORMAT = "mp4"
  
  def initialize(path)
    @path = path
  end
  
  def stabilize!
    output = Tempfile.new("stabilizer_service")
    
    output_path = "#{output.path}.#{FORMAT}"
    
    command = "./stabilizer.sh '#{@path}' '#{output_path}'"
    
    `#{command}`
    
    output_path
  end
  
end