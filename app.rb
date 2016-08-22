
$:.unshift "."

require "json"
require "sinatra"
require "sinatra/json"
require "mongoid"
require "lib/teleport"
require "aws-sdk"

configure(:demo) {
  Sinatra::Base.environment = "demo"
}

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})

QUEUE_URL = ENV['QUEUE_URL']

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

get "/heartbeat" do
  Teleport.count
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

get "/teleports" do
  
  teleports = Teleport.all
  
  json({results: teleports, count: teleports.size})
end
