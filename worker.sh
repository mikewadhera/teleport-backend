#!/bin/bash
source env/$1
MONGOID_ENV=$1 bundle exec ruby -KU -W0 worker.rb $2