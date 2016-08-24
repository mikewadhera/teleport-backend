#!/bin/sh
source env/$1
MONGOID_ENV=$1 bundle exec irb -EUTF-8 -W0 -I . -r lib/teleport.rb -r lib/youtube_oauth.rb -r lib/splitter.rb -r lib/stabilizer_service.rb -r lib/merger.rb -r lib/uploader.rb