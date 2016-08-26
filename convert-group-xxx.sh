#!/bin/sh

res="854x480"
bratvid="1024k"
brataud="192k"
framerate=23.98

indir="/dog/old/dump/xyz/"
oudir="/dog/old/vid/xyz/"

tempsubs="/home/old/temp.ass"
tempmp4="/home/old/temp.mp4"

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
    oufile="${FILE%\ end\ of\ name.mkv}.mp4"
    oufile="xyz${oufile#begin\ of\ name\ }"
    flt=' '
    assfile="RUS Subs/${FILE%mkv}ass"
    if [ -f "$assfile" ]; then
	cp "$assfile" $tempsubs
	flt="-vf ass=$tempsubs"
    fi
    export FFREPORT=file=/home/old/"${oufile%mp4}log":level=16
    ffmpeg -report -y -i "$FILE" \
	-map 0:0 -map 0:1 \
	-s ${res} -c:v libx264 -preset medium -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
	-movflags +faststart -threads 0 -g 12 -r ${framerate} \
	$flt $tempmp4

    if [ -f $tempmp4 ];then
	mv $tempmp4 "${oudir}${oufile}"
    fi

    if [ -f $tempsubs ];then
	rm $tempsubs
    fi

done
