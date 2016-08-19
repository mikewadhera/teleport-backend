
$:.unshift "."

require "lib/teleport"
require "lib/splitter"
require "lib/stabilizer_service"
require "lib/merger"
require "lib/uploader"
require "mongoid"
require "aws-sdk"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
})

QUEUE_URL = ENV['QUEUE_URL']

Mongoid.load!(File.expand_path(File.join(".", "mongoid.yml")))

poller = Aws::SQS::QueuePoller.new(QUEUE_URL)

puts "Listening on: #{QUEUE_URL}"

begin
  poller.poll do |message|
    begin
      params = JSON.parse(message.body, symbolize_names: true)
    
      puts "[PROCESSING] #{params[:command]}"
    
      case params[:command]
      when "stabilize"
        teleport = Teleport.find(params[:id])
        puts "Splitting"
        splitter    = Splitter.new(teleport.source_url)
        left, right = splitter.split!
        puts "Submitting to stabilizer service"
        stabilizer_service = StabilizerService.new(left, right)
        job_id = stabilizer_service.submit!
        # Update
        teleport.stabilizer_job_id = job_id
        teleport.status = Teleport::Status::STABILIZING
        teleport.save
      when "upload"
        teleport = Teleport.find(params[:id])
        # Merge left and right
        left_url, right_url = StabilizerService.urls_for(teleport.stabilizer_job_id)
        merger = Merger.new(left_url, right_url)
        path = merger.merge!
        # Upload
        uploader = Uploader.new(teleport.id, path)
        url = uploader.upload!
        # Update
        teleport.url = url
        teleport.status = Teleport::Status::ENABLED
        teleport.save
        # Cleanup
        StabilizerService.cleanup(teleport.stabilizer_job_id)
      end
    
      puts "[PROCESSED] #{params[:command]}"
    rescue Exception => e
      STDERR.puts "[ERROR] #{params[:command]}: #{e.message}"
      throw :skip_delete
    end
  end
rescue SystemExit, Interrupt
end

