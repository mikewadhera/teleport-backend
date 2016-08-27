
$:.unshift "."

require "lib/teleport"
require "lib/splitter"
require "lib/stabilizer_service"
require "lib/merger"
require "lib/uploader"
require "lib/push_delivery"
require "mongoid"
require "aws-sdk"

if ARGV.empty?
  STDERR.puts "Missing queue id (A or B)"
  exit
end

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})

QUEUE_A_URL = ENV['QUEUE_A_URL']
QUEUE_B_URL = ENV['QUEUE_B_URL']

if ARGV[0].upcase == 'B'
  QUEUE_URL = QUEUE_B_URL
else
  QUEUE_URL = QUEUE_A_URL
end

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

poller = Aws::SQS::QueuePoller.new(QUEUE_URL)

puts "Listening on: #{QUEUE_URL}"

begin
  poller.poll do |message|
    begin
      params = JSON.parse(message.body, symbolize_names: true)
    
      puts "[PROCESSING] #{params[:command]}"
    
      case params[:command]
      when "post_process"
        
        # Set to stabilizing
        teleport = Teleport.find(params[:id])
        teleport.status = Teleport::Status::STABILIZING
        teleport.save
  
        # Submit stabilize job for each side
        sqs = Aws::SQS::Client.new
        { left: QUEUE_A_URL, right: QUEUE_B_URL }.each do |side, queue_url|
          sqs.send_message(
            queue_url: queue_url,
            message_body: { command: "stabilize", id: id, side: side }.to_json
          )
        end
        
      when "stabilize"
        teleport  = Teleport.find(params[:id])
        side      = params[:side]
        
        puts "Splitting"
        splitter  = Splitter.new(teleport.source_url)
        crop      = splitter.send("crop_#{side}")
        
        puts "Stabilizing"
        stabilizer = StabilizerService.new(crop)
        path       = stabilizer.stabilize!
        
        puts "Updating"
        teleport.send("stabilized_#{side}_path=", path)
        teleport.save
        
        puts "Cleaning"
        `rm -f '#{crop}'`
        
      when "upload"
        teleport = Teleport.find(params[:id])

        puts "Merging"
        merger   = Merger.new(teleport.stabilized_left_path, teleport.stabilized_right_path)
        path     = merger.merge!
        
        puts "Uploading"
        uploader = Uploader.new(teleport.id, path)
        url = uploader.upload!
        
        puts "Updating"
        teleport.url = url
        teleport.status = Teleport::Status::ENABLED
        teleport.save
        
        puts "Notifying"
        if teleport.push_token
          push = PushDelivery.new(teleport.push_token)
          push.title = teleport.title
          push.body = "Ready to watch"
          push.deliver!
        end
        
        puts "Cleaning"
        `rm -f '#{teleport.stabilized_left_path}' '#{teleport.stabilized_right_path}'`
        teleport.stabilized_left_path = nil
        teleport.stabilized_right_path = nil
        teleport.save
      end
    
      puts "[PROCESSED] #{params[:command]}"
    rescue Exception => e
      STDERR.puts "[ERROR] #{params[:command]}: #{e.message}"
      throw :skip_delete
    end
  end
rescue SystemExit, Interrupt
end

