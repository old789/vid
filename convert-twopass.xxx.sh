#!/bin/sh

infile='/dog/home/old/dump/xyz.mp4'
outfname="/dog/home/old/vid/xyz"
res="854x480"
bratvid="1000k"
brataud="96k"
framerate=25

if [ -f temp.mp4 ]; then
 rm temp.mp4
fi

if [ -f ffmpeg2pass-0.log ]; then
 rm ffmpeg2pass*
fi

ffmpeg -y -i "${infile}" \
 -s ${res} -c:v libx264 -preset medium -b:v ${bratvid} -an -threads 0 -g 25 -r ${framerate} \
 -pass 1 -f mp4 /dev/null && \
ffmpeg -y -i  "${infile}" \
 -s ${res} -c:v libx264 -preset slower -b:v ${bratvid} -c:a libfdk_aac -b:a ${brataud} -threads 0 -g 25 -r ${framerate} \
 -movflags +faststart \
 -pass 2 temp.mp4

if [ -f temp.mp4 ];then
    cp temp.mp4 ${outfname}.mp4
    ffmpeg -y -i temp.mp4 -ss 00:00:15 -vframes 1 ${outfname}.jpg
    rm temp.mp4
fi
