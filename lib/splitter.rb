
require "tempfile"
require "active_support/core_ext/string"
require "open-uri"

class Splitter
  
  SOURCE_FORMAT = "mp4"
  SOURCE_WIDTH  = 1920
  SOURCE_HEIGHT = 1080
  
  # Test URL: http://s3.amazonaws.com/teleport-beta/sources/20160804_132848.mp4
  
  def initialize(url)
    @url = url
  end
      
  def crop_left
    ratio = SOURCE_WIDTH/SOURCE_HEIGHT.to_f
    width = SOURCE_WIDTH/2
    height = width / ratio
    x_offset = 0
    y_offset = (SOURCE_HEIGHT - height)/2
    
    crop(width, height, x_offset, y_offset)
  end

  def crop_right
    ratio = SOURCE_WIDTH/SOURCE_HEIGHT.to_f
    width = SOURCE_WIDTH/2
    height = width / ratio
    x_offset = SOURCE_WIDTH/2
    y_offset = (SOURCE_HEIGHT - height)/2
    
    crop(width, height, x_offset, y_offset)
  end

  def crop(width, height, x_offset, y_offset)
    download_source
    
    output = Tempfile.new("splitter")
  
    path = "#{output.path}.#{SOURCE_FORMAT}"
  
    command = %{
      ffmpeg
          -i #{@source.path}
          -vf "crop=#{width.to_i}:#{height.to_i}:#{x_offset.to_i}:#{y_offset.to_i},setdar=1:1,setsar=1:1" 
          -s #{width.to_i}X#{height.to_i}
          -c:v libx264
          -preset:v ultrafast
          -qp 0
          -c:a copy 
          -c:s copy
          #{path}
    }.squish
  
    #puts command
    `#{command}`
    
    cleanup_source
    
    path
  end
  
  private
  
  def download_source
    @source = open(@url)
  end
  
  def cleanup_source
    `rm -f #{@source.path}`
    @source = nil
  end
  
end