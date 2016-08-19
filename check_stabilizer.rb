
$:.unshift "."

require "lib/teleport"
require "lib/stabilizer_service"
require "mongoid"
require "aws-sdk"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new("AKIAJC7WZR3RQKPSSEPQ", "qv5Uf802tD1ctqT89aoh7yFIfokZG3pQlYgeG+y/")
})

QUEUE_URL = "https://sqs.us-east-1.amazonaws.com/088595515160/teleport-backend-dev"

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

puts "[STARTING] Looking for teleports in stabilize state"

teleports = Teleport.where(status: Teleport::Status::STABILIZING)

puts "[STARTING] Found #{teleports.size} in stabilize state"

teleports.each do |teleport|
  
  puts "Checking teleport: #{teleport.id}"
  
  if teleport.stabilizer_part1_size
    if StabilizerService.part2_complete?(teleport.stabilizer_job_id, teleport.stabilizer_part1_size)
      puts "Completed"
    
      teleport.stabilizer_part2_size = StabilizerService.current_filesize(teleport.stabilizer_job_id)
      teleport.status = Teleport::Status::MERGING
      teleport.save
    
      sqs = Aws::SQS::Client.new
  
      job = { command: "merge", id: teleport.id }
  
      sqs.send_message(
        queue_url: QUEUE_URL,
        message_body: job.to_json
      )
    else
      puts "Not completed yet"
    end
  else
    if StabilizerService.part1_complete?(teleport.stabilizer_job_id)
      puts "Part 1 complete"
      
      teleport.stabilizer_part1_size = StabilizerService.current_filesize(teleport.stabilizer_job_id)
      teleport.save
    else
      puts "Pending Part 1"
    end
  end
  
end