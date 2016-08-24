
require "gcm"

class PushDelivery
  
  API_KEY = "AIzaSyDMNF2iE5z1f7fjBH30rmvbYMKgkRlL4bI"
  
  attr_accessor :title, :body, :icon
  
  def initialize(push_token)
    @token = push_token
  end
  
  def deliver!
    gcm = GCM.new(API_KEY)
    message = {
      notification: {
        title: @title,
        body: @body,
        icon: @icon
      }
    }
    gcm.send(Array(@token), message)
  end
  
end