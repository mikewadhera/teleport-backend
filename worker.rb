
require "aws-sdk"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new("AKIAJC7WZR3RQKPSSEPQ", "qv5Uf802tD1ctqT89aoh7yFIfokZG3pQlYgeG+y/")
})

poller = Aws::SQS::QueuePoller.new("https://sqs.us-east-1.amazonaws.com/088595515160/teleport-backend-dev")
 
poller.poll do |msg|
  begin
    params = JSON.parse(msg, symbolize_keys: true)
    case params[:command]
    when "stabilize"
      # Split
      splitter    = Splitter.new(params[:id])
      left, right = splitter.split!
      # Stabilize
      stabilizer_service = StabilizerService.new(params[:id], left, right)
      stabilizer_service.submit!
    when "merge"
      # Merge left and right
      merger = Merger.new(params[:id])
      merger.merge!
    end
  rescue Exception => e
    STDERR.puts "[ERROR] #{e.message}"
    throw :skip_delete
  end
end

