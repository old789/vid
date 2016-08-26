#!/bin/sh

res="854x480"
bratvid="1560k"
brataud="192k"
framerate=23.98

indir="/dog/old/dump/xyz/"
oudir="/dog/old/vid/xyz/"

if [ ! -d "${indir}" ]; then
    echo Input dir not ready
    exit
fi

cd "${indir}"

if [ ! -d ${oudir} ]; then
    mkdir -p ${oudir}
fi

cp "RUS Sub/xyz.ass" /home/old/temp.ass
ffmpeg -y -i "xyz.mkv" \
 -map 0:0 -map 0:1 \
 -s ${res} -c:v libx264 -preset slower -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
 -movflags +faststart -threads 0 -g 25 -r ${framerate} \
 -vf "ass=/home/old/temp.ass" \
 /home/old/temp.mp4

if [ -f /home/old/temp.mp4 ];then
    mv /home/old/temp.mp4  ${oudir}xyz.mp4
fi

if [ -f /home/old/temp.ass ];then
    rm /home/old/temp.ass
fi
