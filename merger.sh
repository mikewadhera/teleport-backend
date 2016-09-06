#!/bin/bash

function firstFile() {
  dirname=`dirname $1` &&
  firstfile=`ls $dirname|head -n1` &&
  echo "$dirname/$firstfile"
}

function calculateLeftXOffset() {
  eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=width $1) &&
  echo $(( (960-$streams_stream_0_width)/2 ))
}

function calculateLeftYOffset() { 
  eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height $1) &&
  echo $(( (1080-$streams_stream_0_height)/2 ))
}

function calculateRightXOffset() {
  eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=width $1) &&
  echo $(( ((960-$streams_stream_0_width)/2) + 960 ))
}

function calculateRightYOffset() {
  local filename=$(firstFile $1)  
  eval $(ffprobe -v error -of flat=s=_ -select_streams v:0 -show_entries stream=height $filename) &&
  echo $(( (1080-$streams_stream_0_height)/2 ))
}

# Calculate Offsets (since stabilizer crops original 960x540 frames)
# HACK: Use first file in directory for width and height
leftFile=$(firstFile $1)
rightFile=$(firstFile $2)
leftXOffset=$(calculateLeftXOffset $leftFile)
leftYOffset=$(calculateLeftYOffset $leftFile)
rightXOffset=$(calculateRightXOffset $rightFile)
rightYOffset=$(calculateRightYOffset $rightFile)

file=`mktemp` &&
path="$file.mp4" &&
ffmpeg -y -r 24 -i $1 -r 24 -i $2 -r 24 -i $3 \
  -filter_complex "[0:v:0]pad=1920:1080:$leftXOffset:$leftYOffset[bg]; [bg][1:v:0]overlay=$rightXOffset:$rightYOffset" \
  -c:v libx264 \
  -tune film \
  -crf 18 \
  -preset slow \
  -c:a aac -strict experimental \
  -map 0:v:0 -map 1:v:0 -map 2:a:0 \
  $path > /dev/null &&
echo $path
