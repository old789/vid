#!/bin/sh

prefix="xyz"
res="854x480"
bratvid="1024k"
brataud="192k"
framerate=23.98

indir="/dog/old/dump/___/"
oudir="/dog/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

tempsubs="${wrkdir}temp.ass"
tempmp4="${wrkdir}temp.mp4"

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
    # cut the end of filename
    oufile="${FILE%\ end\ of\ name.mkv}.mp4"
    # cut the begin of filename
    oufile="${prefix}${oufile#begin\ of\ name\ }"

    flt=' '
    assfile="RUS Subs/${FILE%mkv}ass"
    if [ -f "$assfile" ]; then
	cp "$assfile" $tempsubs
	flt="-vf ass=$tempsubs"
    fi
    export FFREPORT=file=${wrkdir}"${oufile%mp4}log":level=24
    ffmpeg -hide_banner -report -y -i "$FILE" \
	-map 0:0 -map 0:1 \
	-s ${res} -c:v libx264 -preset slower -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
	-movflags +faststart -threads 0 -g 12 -r ${framerate} \
	$flt $tempmp4

    if [ -f $tempmp4 ];then
	mv $tempmp4 "${oudir}${oufile}"
    fi

    if [ -f $tempsubs ];then
	rm $tempsubs
    fi

done
