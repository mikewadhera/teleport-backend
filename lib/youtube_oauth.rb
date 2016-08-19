
require 'googleauth'
require 'googleauth/stores/file_token_store'

module YoutubeOauth
  
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  def user_credentials
    scope = Google::Apis::YoutubeV3::AUTH_YOUTUBE
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