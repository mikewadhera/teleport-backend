
require "aws-sdk"

Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new("AKIAJC7WZR3RQKPSSEPQ", "qv5Uf802tD1ctqT89aoh7yFIfokZG3pQlYgeG+y/")
})

poller = Aws::SQS::QueuePoller.new("https://sqs.us-east-1.amazonaws.com/088595515160/teleport-backend-dev")
 
poller.poll do |msg|
  begin
    params = JSON.parse(msg, symbolize_keys: true)
    # Split
    splitter    = Splitter.new(params[:id])
    left, right = splitter.split!
    # Stabilize
    stabilizer_service = StabilizerService.new(params[:id], left, right)
    stabilizer_service.submit!
  rescue Exception => e
    STDERR.puts "[ERROR] #{e.message}"
    throw :skip_delete
  end
end

