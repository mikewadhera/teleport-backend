
file=`mktemp` &&
path="$file.mp4" &&
ffmpeg -y -r 24 -i $1 -r 24 -i $2 -r 24 -i $3 \
  -filter_complex "[0:v:0]pad=1920:1080:0:270[bg]; [bg][1:v:0]overlay=960:270" \
  -c:v libx264 \
  -tune film \
  -crf 18 \
  -preset slow \
  -c:a aac -strict experimental \
  -map 0:v:0 -map 1:v:0 -map 2:a:0 \
  $path > /dev/null && 
echo $path
  