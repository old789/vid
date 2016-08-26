#!/bin/sh

# source: 
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

testimg="${wrkdir}img/test.png"

testattempt='n'
#testattempt='-t 120'
#testattempt='-ss 00:02:00 -t 120'

rendertest='n'
#rendertest='y'

ffmpegbin='ffmpeg'

if [ ! -d "${indir}" ]; then
    echo Input dir not ready
    exit
fi

cd "${indir}"

if [ ! -d ${oudir} ]; then
    mkdir -p ${oudir}
fi

timerange=' '
if [ "$testattempt" != 'n' ]; then
    timerange=$testattempt
fi

for FILE in *.mkv;
do
    # cut the end of filename
    oufile="${FILE%\ end\ of\ name.mkv}.mp4"
    # cut the begin of filename
    oufile="${prefix}${oufile#begin\ of\ name\ }"
    # set name of subtitles file
    assfile="RUS Subs/${FILE%mkv}ass"

    flt=' '
    if [ -f "$assfile" ]; then
	cp "$assfile" $tempsubs
	flt="-vf ass=$tempsubs"
    fi

    export FFREPORT=file=${wrkdir}"${oufile%mp4}log":level=24

    if [ $rendertest != 'n' ]; then
	if [ "$testattempt" != 'n' ]; then
	    echo "Disable test attempt first"
	    exit 1
	fi
	if [ "$flt" = "\ " ]; then
	    echo "No subs file"
	    exit 1
	fi
	duration=`${ffmpegbin} -hide_banner -i "$FILE" 2>&1 | awk '/Duration/{print $2}' | sed 's/\,//g'`
	${ffmpegbin} -hide_banner -loop 1 -y -i $testimg -t $duration \
	    -c:v libx264 -preset ultrafast -b:v 100k -pix_fmt yuv420p -an -threads 0 \
	    $flt $tempmp4
    else
	${ffmpegbin} -hide_banner -report -y -i "$FILE" \
	    -map 0:0 -map 0:1 $timerange \
	    -s ${res} -c:v libx264 -preset slow -b:v ${bratvid} -c:a libfdk_aac -b:a ${brataud} \
	    -movflags +faststart -threads 0 -g 12 -r ${framerate} \
	    $flt $tempmp4
    fi

    if [ -f $tempmp4 ];then
	if [ $rendertest != 'n' ]; then
	    rm $tempmp4
	else
	    mv $tempmp4 "${oudir}${oufile}"
	fi
    fi

    if [ -f $tempsubs ];then
	rm $tempsubs
    fi

    if [ "$testattempt" != 'n' ]; then
	exit
    fi

done
