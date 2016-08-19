#!/bin/sh
source env/$1
while true
do
	MONGOID_ENV=$1 bundle exec ruby -KU -W0 check_stabilizer.rb
  echo Sleeping...
	sleep 10
done