#!/bin/sh
bundle exec irb -W0 -I . -r lib/youtube_oauth.rb -r lib/splitter.rb -r lib/stabilizer_service.rb -r lib/merger.rb -r lib/uploader.rb