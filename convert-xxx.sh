#!/bin/sh

# source: 
prefix="xyz"
res="854x480"
bratvid="1560k"
brataud="192k"
framerate=23.98

indir="/dog/old/dump/___/"
oudir="/dog/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

substype='ass'
#substype='srt'

tempsubs="${wrkdir}temp.${substype}"
tempmp4="${wrkdir}temp.mp4"

testattempt="x"
#testattempt="-t 120"
#testattempt="-ss 00:02:00 -t 120"

ffmpegbin='ffmpeg'

if [ ! -d "${indir}" ]; then
    echo Input dir not ready
    exit
fi

cd "${indir}"

if [ ! -d ${oudir} ]; then
    mkdir -p ${oudir}
fi

infile="xyz.mkv"
oufile="${prefix}.mp4"

#for internal subs
#export FFREPORT=file=${wrkdir}"${oufile%mp4}sub.log":level=24
#${ffmpegbin} -hide_banner -report -y -i "$infile" -map 0:4 $tempsubs
#for external subs
cp "RUS Subs/xyz.${substype}" $tempsubs
flt=' '
if [ -f "$tempsubs" ]; then
    if [ ${substype} = 'ass' ];then
	flt="-vf ass=$tempsubs"
    else
	flt="-vf subtitles=$tempsubs"
    fi
fi

export FFREPORT=file=${wrkdir}"${oufile%mp4}log":level=24

timerange=' '
if [ "$testattempt" != "x" ]; then
    timerange=$testattempt
fi

${ffmpegbin} -hide_banner -report -y -i "$infile" \
 -map 0:0 -map 0:1 $timerange \
 -s ${res} -c:v libx264 -preset slower -b:v ${bratvid} -c:a libfaac -b:a ${brataud} \
 -movflags +faststart -threads 0 -g 12 -r ${framerate} \
 $flt $tempmp4

if [ -f $tempmp4 ];then
    mv $tempmp4  "${oudir}${oufile}"
fi

if [ -f $tempsubs ];then
    rm $tempsubs
fi

