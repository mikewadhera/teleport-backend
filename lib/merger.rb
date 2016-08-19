
require "tempfile"

class Merger
  
  SOURCE_FORMAT = "mp4"
  BITRATE = 6_000_000
  
  def initialize(first_youtube_url, second_youtube_url)
    @first_yt = first_youtube_url
    @second_yt = second_youtube_url
  end
  
  def merge!
    paths = [@first_yt, @second_yt].map do |url|      
      output = Tempfile.new("merger")
      
      path = "#{output.path}.#{SOURCE_FORMAT}"
      
      command = "youtube-dl -f bestvideo+bestaudio -o #{path} '#{url}'"
      
      #puts command
      `#{command}`
      
      crop_output = Tempfile.new("merger")
      
      crop_path = "#{crop_output.path}.#{SOURCE_FORMAT}"
      
      crop_command = %{
        ffmpeg
          -i #{path}
          -vf "crop=960:540,setdar=1:1,setsar=1:1" 
          -s 960X540 
          -c:v libx264 
          -qp 0 
          -preset:v ultrafast 
          -c:a copy 
          -c:s copy 
          -map 0
          #{crop_path}
      }.squish
      
      #puts crop_command
      `#{crop_command}`

      crop_path
    end
    
    join_output = Tempfile.new("merger")
    
    join_path = "#{join_output.path}.#{SOURCE_FORMAT}"
    
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
    
    box_path = "#{box_output.path}.#{SOURCE_FORMAT}"
    
    box_command = %{
      ffmpeg 
        -i #{join_path}
        -vf pad="1920:960:0:210" 
        -c:v libx264 
        -b:v #{BITRATE} 
        -preset:v faster 
        -tune film 
        -c:a copy 
        -c:s copy 
        -map 0 
        #{box_path}
    }.squish
    
    #puts box_command
    `#{box_command}`
    
    # Cleanup intermediate files
    `rm -f #{paths[0]} #{paths[1]} #{join_path}`
    
    box_path
  end
  
end