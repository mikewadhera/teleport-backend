#!/bin/bash

cd tmp &&
dir=`mktemp -d` && 
cd $dir &&
mkdir images &&
videostab $2 -gpu=yes -r=12 -q --raw --crop=$1 > /dev/null &&
echo "$dir/images/%08d.png"