
require "sinatra"

get "/" do
  "Hello World"
end

get "/webhooks/youtube" do
  request.inspect
end