
require "mongoid"

class Teleport
  include Mongoid::Document
  include Mongoid::Timestamps
  
  module Status
    UPLOADED    = 0
    STABILIZING = 1
    MERGING     = 2
    ENABLED     = 3
    DISABLED    = 4
  end
  
  field :id, type: String
  field :username, type: String
  field :url, type: String
  field :timestamp, type: Integer
  field :utc_offset, type: Integer
  field :latitude, type: String
  field :longitude, type: String
  field :placemark, type: String
  field :source_url, type: String
  field :source_duration, type: Integer
  field :status, type: Integer
  field :stabilizer_job_id, type: String
  field :stabilizer_part1_size, type: String
  field :stabilizer_part2_size, type: String
    
end