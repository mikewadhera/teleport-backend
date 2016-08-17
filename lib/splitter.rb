
require "tempfile"
require "active_support/core_ext/string"

class Splitter
  
  SOURCE_FORMAT = "mp4"
  SOURCE_WIDTH = 1920
  SOURCE_HEIGHT = 1080
  SOURCE_URL_TEMPLATE = "http://s3.amazonaws.com/teleport-beta/sources/%s.#{SOURCE_FORMAT}"
  
  # Test ID: 20160804_132848
  # Test URL: http://s3.amazonaws.com/teleport-beta/sources/20160804_132848.mp4
  
  def initialize(id)
    @id = id
  end
  
  def split!
    download_source
    return crop_left, crop_right
  end
  
  private
  
  def download_source
    url = SOURCE_URL_TEMPLATE % @id
    @source = open(url)
  end
  
  def crop_left
    ratio = SOURCE_WIDTH/SOURCE_HEIGHT.to_f
    width = SOURCE_WIDTH/2
    height = width / ratio
    x_offset = 0
    y_offset = (SOURCE_HEIGHT - height)/2
    crop(@source, width, height, x_offset, y_offset)
  end
  
  def crop_right
    ratio = SOURCE_WIDTH/SOURCE_HEIGHT.to_f
    width = SOURCE_WIDTH/2
    height = width / ratio
    x_offset = SOURCE_WIDTH/2
    y_offset = (SOURCE_HEIGHT - height)/2
    crop(@source, width, height, x_offset, y_offset)
  end
  
  def crop(input, width, height, x_offset, y_offset)
    output = Tempfile.new("splitter")
    
    path = "#{output.path}.#{SOURCE_FORMAT}"
    
    command = %{
      ffmpeg
          -i #{input.path}
          -vf "crop=#{width.to_i}:#{height.to_i}:#{x_offset.to_i}:#{y_offset.to_i},setdar=1:1,setsar=1:1" 
          -s #{width.to_i}X#{height.to_i}
          -c:v libx264 
          -profile:v high 
          -preset:v faster 
          -tune film 
          -b:v 10000000 
          -c:a copy 
          -c:s copy 
          -map 0 
          #{path}
    }.squish
    
    #puts command
    `#{command}`
    
    path
  end
  
end