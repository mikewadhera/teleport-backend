#!/bin/bash

WIDTH=960
HEIGHT=540

cd tmp
dir=`mktemp -d` && cd $dir
mkdir images

videostab $1 -gpu=yes -ws=yes -r=12 -q --raw
cd images
ffmpeg -i %08d.png -i $1 -s "$WIDTH"X"$HEIGHT" -vcodec libx264 -preset:v ultrafast -qp 0 -c:a copy -map 0:v:0 -map 1:a:0 $2
rm *.png

cd .. # images
cd .. # $dir
rm -rf $dir
cd .. # tmp
