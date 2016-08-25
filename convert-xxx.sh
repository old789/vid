#!/bin/sh

infile='/dog/old/dump/xyz.mp4'
outfname="/dog/old/vid/xyz.mp4"
res="854x480"
bratvid="1024k"
brataud="96k"
framerate=25

ffmpeg -y -i "${infile}" \
 -s ${res} -c:v libx264 -preset slower -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
 -movflags +faststart -threads 0 -g 25 -r ${framerate} \
 temp.mp4

if [ -f temp.mp4 ];then
    cp temp.mp4 ${outfname}.mp4
    ffmpeg -y -i temp.mp4 -ss 00:00:05 -vframes 1 ${outfname}.jpg
    rm temp.mp4
fi
