
# require 'google/api_client'
# require 'google/api_client/client_secrets'
# require 'google/api_client/auth/file_storage'
# require 'google/api_client/auth/installed_app'
# require "httpclient"

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/youtube_v3'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class StabilizerService
  
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
    youtube.request_options.timeout_sec = 1200
    youtube.request_options.open_timeout_sec = 1200
    youtube.request_options.retries = 3
    youtube.authorization = user_credentials
    
    results = []
    
    [@left, @right].each_with_index do |path, i|

      metadata = {
        snippet: {
          title: @id,
          :description => i.to_s
        },
        :status => {
          :privacyStatus => "unlisted"
        }
      }
    
      results << youtube.insert_video('snippet,status', 
                                      metadata, 
                                      upload_source: path, 
                                      content_type: "video/#{SOURCE_FORMAT}",
                                      stabilize: true)
    end
    results
    # client, youtube = get_authenticated_service
#
#     [@left, @right].each_with_index do |path, i|
#
#       body = {
#         :snippet => {
#           :title => @id,
#           :description => i.to_s,
#           :tags => "",
#           :categoryId => 22,
#         },
#         :status => {
#           :privacyStatus => "unlisted"
#         }
#       }
#
#       videos_insert_response = client.execute!(
#         :api_method => youtube.videos.insert,
#         :body_object => body,
#         :media => Google::APIClient::UploadIO.new(path, 'video/*'),
#         :parameters => {
#           :uploadType => 'resumable',
#           :part => body.keys.join(','),
#           :stabilize => true
#         }
#       )
#
#       videos_insert_response.resumable_upload.send_all(client)
#     end
  end
  
  # def get_authenticated_service
  #   client = Google::APIClient.new(
  #     :application_name => $PROGRAM_NAME,
  #     :application_version => '1.0.0'
  #   )
  #   youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)
  #
  #   file_storage = Google::APIClient::FileStorage.new("./oauth2.json")
  #   if file_storage.authorization.nil?
  #     flow = Google::APIClient::InstalledAppFlow.new(
  #       :client_id => GOOGLE_API_CLIENT_ID,
  #       :client_secret => GOOGLE_API_CLIENT_SECRET,
  #       :scope => [YOUTUBE_UPLOAD_SCOPE],
  #       :redirect_uri => "http://localhost:4567/oauth2callback"
  #     )
  #     client.authorization = flow.authorize(file_storage)
  #   else
  #     client.authorization = file_storage.authorization
  #   end
  #
  #   return client, youtube
  # end
  
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  def user_credentials
    scope = Google::Apis::YoutubeV3::AUTH_YOUTUBE_UPLOAD
    client_secrets_path = "./client_secrets.json"    
    token_store_path = "./oauth_tokens.json"

    if ENV['GOOGLE_CLIENT_ID']
      client_id = Google::Auth::ClientId.new(ENV['GOOGLE_CLIENT_ID'], ENV['GOOGLE_CLIENT_SECRET'])
    else
      client_id = Google::Auth::ClientId.from_file(client_secrets_path)
    end
    token_store = Google::Auth::Stores::FileTokenStore.new(:file => token_store_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, scope, token_store)

    user_id = 'default'

    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      # TODO raise expcetion if we're in production
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in your browser and authorize the application."
      puts url
      puts "Enter the authorization code:"
      code = gets
      code.strip!
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
  
end