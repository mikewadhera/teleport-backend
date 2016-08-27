
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
  field :timemark, type: String
  field :source_url, type: String
  field :source_duration, type: Integer
  field :status, type: Integer
  field :stabilized_left_path, type: String
  field :stabilized_right_path, type: String
  field :push_token, type: String
  
  def title
    "📍 #{self.placemark} 🕒 #{self.timemark}"
  end
    
end