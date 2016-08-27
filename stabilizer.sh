#!/bin/bash
videostab $1 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.jpg -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy stable.mp4
rm *.jpg
cd ..
videostab images/stable.mp4 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.jpg -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy stable2.mp4
rm *.jpg
cd ..
videostab images/stable2.mp4 -gpu=yes -ws=yes -r=12 -q --raw
ffmpeg -i %08d.jpg -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -c:s copy final.mp4
