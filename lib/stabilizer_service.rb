
require 'lib/youtube_oauth'
require 'google/apis/youtube_v3'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class StabilizerService
  include YoutubeOauth
  extend YoutubeOauth
  
  SOURCE_FORMAT = "mp4"
  
  def self.urls_for(job_id)
    job_id.split(',').map { |video_id| "http://www.youtube.com/watch?v=#{video_id}" }
  end
    
  def self.part1_complete?(job_id)
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.authorization = user_credentials
    videos = youtube.list_videos('processingDetails', id: job_id) # ID can be CSV
    videos.items.size == 2 && videos.items.all? { |item| item.processing_details.processing_status == "succeeded" }
  end
  
  def self.part2_complete?(job_id, part1_size)
    part1_sizes = part1_size.split(',')
    current_sizes = current_filesize(job_id).split(',')
    (part1_sizes[0] != current_sizes[0]) && (part1_sizes[1] != current_sizes[1])
  end
  
  def self.current_filesize(job_id)
    urls_for(job_id).map do |url|
      lines = `youtube-dl -F #{url}`
      lines.split("\n").find { |l| l =~ /^137/ }.split(",").last.strip
    end.join(",")
  end
  
  def self.cleanup(job_id)
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.authorization = user_credentials
    job_id.split(',').each do |id|
      youtube.delete_video(id)
    end
    true
  end
  
  def initialize(left, right)
    @left = left
    @right = right
  end
  
  def submit!
    youtube = Google::Apis::YoutubeV3::YouTubeService.new
    youtube.request_options.timeout_sec = 600
    youtube.request_options.open_timeout_sec = 600
    youtube.request_options.retries = 3
    youtube.authorization = user_credentials
    
    results = []
    
    [@left, @right].each_with_index do |path, i|

      metadata = {
        snippet: {
          title: "Teleport #{i}",
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
    
    results.map { |video| video.id }.join(',')
  end
  
end