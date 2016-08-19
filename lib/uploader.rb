
require "aws-sdk"

class Uploader
  
  SOURCE_FORMAT = "mp4"
  S3_BUCKET = ENV['S3_BUCKET']
  S3_KEY_TEMPLATE = "teleports/%s"
  
  def initialize(id, path)
    @id = id
    @path = path
  end
  
  def upload!
    s3 = Aws::S3::Client.new
    key = S3_KEY_TEMPLATE % @id
    File.open(@path) do |file|
      s3.put_object(
        acl: "public-read",
        bucket: S3_BUCKET,
        key: key,
        body: file,
        content_type: "video/#{SOURCE_FORMAT}"
      )
    end
    
    "http://s3.amazonaws.com/#{S3_BUCKET}/#{key}"
  end
  
end