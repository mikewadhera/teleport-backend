
require "tempfile"

class Merger
  BITRATE = 8_000_000
  FORMAT  = "mp4"
  PROFILE = "baseline"
  PRESET  = "llhq"
  ENCODER = `ffmpeg -hide_banner -codecs| grep nvenc_h264`.empty? ? "libx264" : "nvenc_h264"
  
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
        -i #{@left}
        -i #{@right}
        -filter_complex "[0:v:0]pad=iw*2:ih[bg]; [bg][1:v:0]overlay=w" 
        -c:v #{ENCODER}
        -b:v #{BITRATE}
        -preset #{PRESET}
        -profile:v #{PROFILE}
        -c:a copy 
        -c:s copy 
        #{join_path}
    }.squish
    
    #puts join_command
    `#{join_command}`
    
    join_path
  end
  
end