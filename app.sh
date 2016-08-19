#!/bin/sh
source env/$1
bundle exec ruby -KU app.rb -e $1