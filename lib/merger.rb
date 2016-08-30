
require "tempfile"

class Merger
  WIDTH   = 1920
  HEIGHT  = 1080
  BITRATE = 8_000_000
  FORMAT  = "mp4"
  PROFILE = "baseline"
  PRESET  = "llhq"
  ENCODER = `ffmpeg -hide_banner -codecs| grep nvenc_h264`.empty? ? "libx264" : "nvenc_h264"
  AUDIO   = "aac"
  
  def initialize(left, right)
    @left = left
    @right = right
  end
  
  def merge!
    paths = [@left, @right]
    
    join_output = Tempfile.new("merger")
    
    join_path = "#{join_output.path}.#{FORMAT}"
    
    # Take two 960X540 and create one 1920x540
    
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
    
    # Take 1920X540 and letterbox to 1920X1080 (4:3)
    
    box_output = Tempfile.new("merger")
    
    box_path = "#{box_output.path}.#{FORMAT}"
    
    box_command = %{
      ffmpeg 
        -i #{join_path}
        -vf pad="#{WIDTH}:#{HEIGHT}:0:270"
        -c:v #{ENCODER}
        -b:v #{BITRATE}
        -preset #{PRESET}
        -profile:v #{PROFILE}
        -c:a #{AUDIO}
        #{box_path}
    }.squish
    
    #puts box_command
    `#{box_command}`
    
    # Cleanup
    `rm -f #{paths[0]} #{paths[1]} #{join_path}`
    
    box_path
  end
  
end