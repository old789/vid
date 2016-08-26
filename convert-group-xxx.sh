#!/bin/sh

# source: 

prefix="xyz"
# resolution of output video
res="854x480"
# bitrate of output video
bratvid="1024k"
# bitrate of output audio
brataud="192k"
# mapping video and aurio channels in input stream
map="-map 0:0 -map 0:1"
# framerate of output video ( keep as in input stream )
framerate=23.98
# mapping subtitles channel in case of internal subtitles
mapintsub="-map 0:2"

# directory with input video files
indir="/dog/old/dump/___/"

# if internal subtitles? set to 'y'
intsubs='n'

# test render subtitles
rendertest='n'
#rendertest='y'

# test converting ( usually 120s )
testattempt='n'
#testattempt='-t 120'
#testattempt='-ss 00:02:00 -t 120'

oudir="/dog/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

tempsubs="${wrkdir}temp.ass"
tempmp4="${wrkdir}temp.mp4"

testimg="${wrkdir}img/test.png"

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

    if [ $intsubs = 'n' ]; then
	if [ -f "$assfile" ]; then
	    cp "$assfile" $tempsubs
	    flt="-vf ass=$tempsubs"
	fi
    else
	export FFREPORT=file=${wrkdir}"${oufile%mp4}ass.log":level=24
	${ffmpegbin} -hide_banner -y -i "$FILE" $mapintsub $tempsubs
	if [ -f "$tempsubs" ]; then
	    flt="-vf ass=$tempsubs"
	fi
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
	    ${map} $timerange \
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
