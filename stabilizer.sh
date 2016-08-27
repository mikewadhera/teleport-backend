#!/bin/bash

WIDTH=960
HEIGHT=540

cd tmp
dir=`mktemp -d` && cd $dir
mkdir images

# 1st
videostab $1 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.jpg -s "$WIDTH"X"$HEIGHT" -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy stable.mp4
rm *.jpg
cd ..

# 2nd
videostab images/stable.mp4 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.jpg -s "$WIDTH"X"$HEIGHT" -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy stable2.mp4
rm *.jpg
cd ..

# 3rd
videostab images/stable2.mp4 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.jpg -s "$WIDTH"X"$HEIGHT" -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy $2
rm *.jpg

# Cleanup
rm stable.mp4
rm stable2.mp4

cd .. # images
cd .. # $dir
rm -rf $dir
cd .. # tmp
