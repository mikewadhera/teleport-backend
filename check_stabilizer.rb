
$:.unshift "."

require "lib/teleport"
require "mongoid"
require "aws-sdk"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})

QUEUE_URL = ENV['QUEUE_A_URL']

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

puts "[STARTING] Looking for teleports in stabilize state"

teleports = Teleport.where(status: Teleport::Status::STABILIZING)

puts "[STARTING] Found #{teleports.size} in stabilize state"

teleports.each do |teleport|
  
  puts "Checking teleport: #{teleport.id}"
  
  if teleport.stabilized_left_path
    puts "Left complete"
  else
    puts "Left incomplete"
  end
  
  if teleport.stabilized_right_path
    puts "Right complete"
  else
    puts "Right incomplete"
  end
  
  if teleport.stabilized_left_path && teleport.stabilized_right_path
    puts "Completed"
  
    teleport.status = Teleport::Status::MERGING
    teleport.save
  
    sqs = Aws::SQS::Client.new

    job = { command: "upload", id: teleport.id }

    sqs.send_message(
      queue_url: QUEUE_URL,
      message_body: job.to_json
    )
  end
  
end
