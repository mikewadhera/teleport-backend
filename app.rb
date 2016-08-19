
$:.unshift "."

require "json"
require "sinatra"
require "sinatra/json"
require "mongoid"
require "lib/teleport"
require "aws-sdk"

QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/088595515160/teleport-backend-dev"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new("AKIAJC7WZR3RQKPSSEPQ", "qv5Uf802tD1ctqT89aoh7yFIfokZG3pQlYgeG+y/")
})

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

get "/heartbeat" do
  "bump"
end

post "/teleports" do
  id = params[:id]
  url = params[:url]
  
  teleport = Teleport.create(
    id: id,
    username: "mike",
    timestamp: Time.now,
    utc_offset: 0,    
    latitude: nil,
    longitude: nil,
    placemark: nil,
    source_url: url,
    source_duration: nil,
    status: Teleport::Status::UPLOADED
  )
  
  sqs = Aws::SQS::Client.new
  
  job = { command: "stabilize", id: id }
  
  sqs.send_message(
    queue_url: QUEUE_URL,
    message_body: job.to_json
  )
  
  json(teleport)
end
