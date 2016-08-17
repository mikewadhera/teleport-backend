
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
    return split_left, split_right
  end
  
  private
  
  def download_source
    url = SOURCE_URL_TEMPLATE % @id
    @source = open(url)
  end
  
  def split_left
    width = SOURCE_WIDTH/2
    height = SOURCE_HEIGHT
    x_offset = 0
    y_offset = 0
    split_with_box(@source, width, height, x_offset, y_offset)
  end
  
  def split_right
    width = SOURCE_WIDTH/2
    height = SOURCE_HEIGHT
    x_offset = SOURCE_WIDTH/2
    y_offset = 0
    split_with_box(@source, width, height, x_offset, y_offset)
  end
  
  def split_with_box(input, width, height, x_offset, y_offset)
    output = Tempfile.new("splitter")
    
    path = "#{output.path}.#{SOURCE_FORMAT}"
    
    command = %{
      ffmpeg -i #{input.path} 
             -vf "crop=#{width.to_i}:#{height.to_i}:#{x_offset.to_i}:#{y_offset.to_i},setdar=1:1,setsar=1:1,pad=ih*16/9:ih:(ow-iw)/2:(oh-ih)/2,scale=1920:1080"
             -s 1920X1080 
             -c:v libx264 
             -qp 0 
             -preset:v ultrafast
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