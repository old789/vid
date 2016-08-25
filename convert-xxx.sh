#!/bin/sh

avconv -y -i /dog/old/dump/xyz.mp4 \
 -s 854x480 -vcodec libx264 -acodec libfaac -threads 0 -b:v 1024k -ab 96k -g 50 -r 25 \
 temp.480.mp4

MP4Box -add temp.480.mp4 /dog/old/vid/xyz.mp4

avconv -y -i temp.480.mp4 -ss 00:00:05 -vframes 1 /dog/old/vid/xyz.jpg

rm temp.480.mp4
