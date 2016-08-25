#!/bin/sh

ffmpeg -y -i /dog/old/dump/xyz.mp4 \
 -s 854x480 -vcodec libx264 -acodec libfaac -threads 0 -b:v 1024k -ab 96k -g 50 -r 25 \
 temp.mp4

if [ -f temp.mp4 ];then
    MP4Box -add temp.mp4 /dog/old/vid/xyz.mp4
    ffmpeg -y -i temp.mp4 -ss 00:00:05 -vframes 1 /dog/old/vid/xyz.jpg
    rm temp.mp4
fi
