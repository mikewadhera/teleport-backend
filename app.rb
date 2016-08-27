
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

QUEUE_A_URL = ENV['QUEUE_A_URL']
QUEUE_B_URL = ENV['QUEUE_B_URL']

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

get "/heartbeat" do
  Teleport.count
  "bump"
end

get "/inspect" do
  puts params.inspect
end

post "/inspect" do
  puts params.inspect
end

post "/teleports" do
  id = params[:id]
  url = params[:url]
  placemark = params[:placemark]
  timemark = params[:timemark]
  push_token = params[:push_token]
  
  teleport = Teleport.create(
    id: id,
    username: "mike",
    timestamp: Time.now,
    utc_offset: 0,    
    latitude: nil,
    longitude: nil,
    placemark: placemark,
    timemark: timemark,
    source_url: url,
    source_duration: nil,
    status: Teleport::Status::UPLOADED,
    push_token: push_token
  )
  
  sqs = Aws::SQS::Client.new
  
  sqs.send_message(
    queue_url: QUEUE_A_URL,
    message_body: { command: "post_process", id: id }.to_json
  )
  
  json(teleport)
end

get "/teleports" do
  
  teleports = Teleport.where(status: Teleport::Status::ENABLED).order_by(created_at: :desc)
  
  json({results: teleports, count: teleports.size})
end
