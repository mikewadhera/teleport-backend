
require "tempfile"
require "open-uri"

class StabilizerService
  
  def self.cleanup(output_path)
    # /tmp/tmp.NWO4f6A5zN/images/%08d.png => /tmp/tmp.NWO4f6A5zN/images/*.png
    wildcard_path = output_path.sub(/%08d.png$/, "*.png")
    `rm #{wildcard_path}`
  end
  
  def initialize(url, side)
    @url = url
    @side = side
  end
  
  def stabilize!
    source = open(@url)
    
    command = "./stabilizer.sh '#{@side}' '#{source.path}'"
    
    output_path = `#{command}`
    
    `rm -f '#{source.path}'`
    
    output_path.chomp
  end
  
end