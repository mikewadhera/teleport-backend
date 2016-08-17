
require 'lib/youtube_oauth'
require 'google/apis/youtube_v3'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class StabilizerService
  include YoutubeOauth
  
  SOURCE_FORMAT = "mp4"
  
  # Test ID: 20160804_132848
  # Test Left: /var/folders/1d/mbrdr0jn0xdcfj_fqxgjhsg80000gn/T/splitter20160816-21686-ehawou.mp4
  # Test Right: /var/folders/1d/mbrdr0jn0xdcfj_fqxgjhsg80000gn/T/splitter20160816-21686-swl2bw.mp4
  
  def initialize(id, left, right)
    @id = id
    @left = left
    @right = right
  end
  
  def submit!
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.request_options.timeout_sec = 600
    youtube.request_options.open_timeout_sec = 600
    youtube.request_options.retries = 3
    youtube.authorization = user_credentials(Google::Apis::YoutubeV3::AUTH_YOUTUBE_UPLOAD)
    
    results = []
    
    [@left, @right].each_with_index do |path, i|

      metadata = {
        snippet: {
          title: @id,
          description: i.to_s
        },
        status: {
          privacy_status: "unlisted"
        }
      }
    
      results << youtube.insert_video('snippet,status', 
                                      metadata, 
                                      upload_source: path, 
                                      content_type: "video/#{SOURCE_FORMAT}",
                                      stabilize: true)
    end
    results
  end
  
end