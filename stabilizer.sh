#!/bin/bash

WIDTH=960
HEIGHT=540

cd tmp
dir=`mktemp -d` && cd $dir
mkdir images

videostab $1 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -r 24 -i $1 -r 24 -i %08d.png -r 24 -s "$WIDTH"X"$HEIGHT" -vcodec libx264 -preset:v ultrafast -qp 0 -c:a aac -strict experimental -map 0:a:0 -map 1:v:0 $2
rm *.png

cd .. # images
cd .. # $dir
rm -rf $dir
cd .. # tmp
