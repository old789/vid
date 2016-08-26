#!/bin/sh

# source: 

prefix="xyz"
# season/chapter/part/etc mark, added to prefix
season=""
# resolution of output video
res="854x480"
# bitrate of output video
bratvid="1024k"
# bitrate of output audio
brataud="192k"
# mapping video and audio channels in input stream
map="-map 0:0 -map 0:1"
# framerate of output video ( keep as in input stream )
framerate=23.98
# mapping subtitles channel in case of internal subtitles
mapintsub="n"
#mapintsub="-map 0:2"

# directory with input video files (with finished slash)
indir="/dog/old/dump/___/"

# directory with subtitles files (with finished slash) or null string
subsdir="RUS Sub [Dreamers Team]/"

# portion for cut of begin of filename
beginofname="begin\ of\ name\ "

# portion for cut of end of filename
endofname="\ end\ of\ name"

# subtitles type
substype='ass'
#substype='srt'

# videofile type
videotype="mkv"

# for convert 5.1 or higher sound to stereo
force_stereo=""
#force_stereo=" -ac 2 -af volume=4.0"

# add paddings to the input image
padding=''
#padding="pad=${res//x/:}:(ow-iw)/2,setdar=dar=16/9"  # auto x:y -> ${res} where y=y(${res})
#padding='pad=854:480:107:0'           # 640x480 -> 854x480
#padding='scale=-1:480,pad=854:480:(ow-iw)/2" # scale ?x576 and padding to 854x480

# covert codepage if needed
iconvert=''
#iconvert='-f cp1251 -t utf-8'

# test render subtitles
rendertest='n'
#rendertest='y'

# test converting ( usually 120s )
testattempt='n'
#testattempt='-t 120'
#testattempt='-ss 00:02:00 -t 120'

debug_level=24

oudir="/dog/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

tempsubs="${wrkdir}temp.${substype}"
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

if [ "$testattempt" != 'n' ] || [ "$rendertest" != 'n' ]; then
    debug_level=32
fi

for FILE in *.${videotype};
do
    # cut the end of filename
    oufile="${FILE%${endofname}.${videotype}}.mp4"
    # cut the begin of filename
    oufile="${prefix}${season}${oufile#${beginofname}}"

    if [ -f "$tempsubs" ];then
	rm -f "$tempsubs"
    fi

    flt=' '

    if [ $mapintsub = 'n' ];then
	substitlefile="${subsdir}${FILE%${videotype}}${substype}"
	if [ -f "$substitlefile" ]; then
	    cp "$substitlefile" $tempsubs
	fi
    else
	export FFREPORT=file=${wrkdir}"${oufile%mp4}subs.log":level=$debug_level
	${ffmpegbin} -hide_banner -y -i "$FILE" $mapintsub $tempsubs
    fi

    if [ -f "$tempsubs" ]; then
	if [ "${iconvert}x" != 'x' ]; then
	    mv $tempsubs $tempsubs".prev"
	    iconv ${iconvert} $tempsubs".prev" > $tempsubs
	    rm -f $tempsubs".prev"
	fi
	if [ ${substype} = 'ass' ];then
	    flt="-vf ass=$tempsubs"
	else
	    flt="-vf subtitles=$tempsubs"
	fi
    fi

    export FFREPORT=file=${wrkdir}"${oufile%mp4}log":level=$debug_level

    if [ $rendertest != 'n' ]; then
	if [ "$testattempt" != 'n' ]; then
	    echo "Disable test attempt first"
	    exit 1
	fi
	if [ ${substype} = 'n' ] || [ "$flt" = " " ]; then
	    echo "No subs file"
	    exit 1
	fi
	duration=`${ffmpegbin} -hide_banner -i "$FILE" 2>&1 | awk '/Duration/{print $2}' | sed 's/\,//g'`
	${ffmpegbin} -hide_banner -loop 1 -y -i $testimg -t $duration \
	    -c:v libx264 -preset ultrafast -b:v 100k -pix_fmt yuv420p -an -threads 0 \
	    $flt $tempmp4
    else
	if [ "${padding}x" != 'x' ]; then
	    if [ "$flt" = " " ]; then
		flt="-vf ${padding}"
	    else
		flt="$flt,${padding}"
	    fi
	fi
	${ffmpegbin} -hide_banner -report -y -i "$FILE" \
	    ${map} $timerange \
	    -s ${res} -c:v libx264 -preset slow -b:v ${bratvid} -c:a libfdk_aac -b:a ${brataud}${force_stereo} \
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
