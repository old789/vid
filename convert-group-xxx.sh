#!/bin/sh

res="854x480"
bratvid="1024k"
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

for FILE in *.mkv;
do
    cp "RUS Subs/${FILE%mkv}ass" /home/old/temp.ass
    ffmpeg -y -i "$FILE" \
	-map 0:0 -map 0:1 \
	-s ${res} -c:v libx264 -preset medium -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
	-movflags +faststart -threads 0 -g 12 -r ${framerate} \
	-vf "ass=/home/old/temp.ass" \
	/home/old/temp.mp4

    if [ -f /home/old/temp.mp4 ];then
	oufile="${FILE%\ end\ of\ name.mkv}.mp4"
	oufile="aobs${oufile#begin\ of\ name\ }"
	mv /home/old/temp.mp4  ${oudir}${oufile}
    fi

    if [ -f /home/old/temp.ass ];then
	rm /home/old/temp.ass
    fi

done

