
require "tempfile"

class Merger
  
  BITRATE = 8_000_000
  FORMAT  = "mp4"
  
  def initialize(left, right)
    @left = left
    @right = right
  end
  
  def merge!
    paths = [@left, @right]
    
    join_output = Tempfile.new("merger")
    
    join_path = "#{join_output.path}.#{FORMAT}"
    
    join_command = %{
      ffmpeg 
        -i #{paths[0]}
        -i #{paths[1]}
        -filter_complex "[0:v:0]pad=iw*2:ih[bg]; [bg][1:v:0]overlay=w" 
        -c:v libx264 
        -qp 0 
        -preset:v ultrafast
        -c:a copy 
        -c:s copy 
        -map 0 
        #{join_path}
    }.squish
    
    #puts join_command
    `#{join_command}`
    
    box_output = Tempfile.new("merger")
    
    box_path = "#{box_output.path}.#{FORMAT}"
    
    if `ffmpeg -codecs| grep nvenc_h264`.empty?
      encoder = "libx264"
    else
      encoder = "nvenc_h264"
    end
    
    box_command = %{
      ffmpeg 
        -i #{join_path}
        -vf pad="1920:960:0:210"
        -c:v #{encoder}
        -b:v #{BITRATE}
        -profile:v baseline
        -c:a copy
        -c:s copy
        -map 0 
        #{box_path}
    }.squish
    
    #puts box_command
    `#{box_command}`
    
    # Cleanup
    `rm -f #{paths[0]} #{paths[1]} #{join_path}`
    
    box_path
  end
  
end