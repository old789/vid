#!/bin/sh

# source: 

# test render subtitles
rendertest='n'
#rendertest='y'

# test converting ( usually 120s )
testattempt='n'
#testattempt='-t 120'
#testattempt='-ss 00:02:00 -t 120'

debug_level=24

prefix="xyz"

# directory with input video files (with finished slash)
indir="/dog/home/old/dump/___/"

# directory with subtitles files (with finished slash) or null string
subsdir=""

# portion for cut of begin of filename
beginofname=""

# portion for cut of end of filename
endofname=""

# season/chapter/part/etc mark, added to prefix ( like "_1_" )
season=""
# resolution of output video
res="854x480"
# bitrate of output video
bratvid="1536k"
# bitrate of output audio
brataud="192k"
# mapping video and audio channels in input stream
map="-map 0:0 -map 0:1"
# framerate of output video ( keep as in input stream )
framerate='24000/1001'

# mapping subtitles channel in case of internal subtitles
mapintsub='n'
#mapintsub="-map 0:2"

# subtitles type or 'n' if not required
substype='ass'
#substype='srt'
#substype='n'

# videofile type
videotype='mkv'

# convert codepage if needed
iconvert=''
#iconvert='-f cp1251 -t utf-8'

# audio filter
afilt=''
#afilt="-ac 2 -af volume=4.0"  # for convert 5.1 or higher sound to stereo

# video filter suffix ( add after subtitles filter )
vfsuffix=''
#vfsuffix="pad=${res//x/:}:(ow-iw)/2,setdar=dar=16/9"          # auto padding x:y -> ${res} where y=y(${res})
#vfsuffix='scale=-1:480,pad=854:480:(ow-iw)/2,setdar=dar=16/9' # scale ?x576 and padding to 854x480
#vfsuffix='pad=854:480:107:0,setdar=dar=16/9'                  # hardcode padding 640x480 -> 854x480

# video filter prefix ( add before subtitles filter )
vfprefix=''
#vfprefix="yadif=1:-1:0" # deinterlace input image

# two pass encoding (y/n)
twoPass='n'

# ----- end of config  -----

oudir="/dog/home/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

tempsubs="${wrkdir}temp.${prefix}${season}.${substype}"
tempmp4="${wrkdir}temp.${prefix}${season}.mp4"

testimg="${wrkdir}img/test.png"

ffmpegbin='ffmpeg'

function MakeVfilter {
    if [ "x$1" = 'x' ]; then
	echo "-vf $2"
    else
	echo "$1,$2"
    fi
}

if [ ! -d "${indir}" ]; then
    echo Input dir not ready
    exit
fi

if [ $(pwd)"/" != "${wrkdir}" ]; then
    cd "${wrkdir}"
fi

if [ ! -d "${oudir}" ]; then
    mkdir -p "${oudir}"
fi

timerange=' '
if [ "$testattempt" != 'n' ]; then
    timerange=$testattempt
fi

if [ "$testattempt" != 'n' ] || [ "$rendertest" != 'n' ]; then
    debug_level=32
fi

for FILE in "${indir}"*.${videotype};
do
    infile=$(basename "$FILE")
    # cut the end of filename
    oufile="${infile%${endofname}.${videotype}}.mp4"
    # cut the begin of filename
    oufile="${prefix}${season}${oufile#${beginofname}}"

    if [ -f "$tempsubs" ];then
	rm -f "$tempsubs"
    fi

    flt=''
    fltsub=''
    pass=''
    preset='slow'
    baseoufile=${oufile%mp4} # for some reason

    if [ ${substype} != 'n' ];then
	if [ "$mapintsub" = 'n' ];then
	    substitlefile="${indir}${subsdir}${infile%${videotype}}${substype}"
	    if [ -f "$substitlefile" ]; then
		cp "$substitlefile" $tempsubs
	    fi
	else
	    export FFREPORT=file=${wrkdir}"${baseoufile}subs.log":level=$debug_level
	    ${ffmpegbin} -hide_banner -y -i "$FILE" $mapintsub $tempsubs
	fi

	if [ -f "$tempsubs" ]; then
	    if [ "${iconvert}x" != 'x' ]; then
		mv $tempsubs $tempsubs".prev"
		iconv ${iconvert} $tempsubs".prev" > $tempsubs
		rm -f $tempsubs".prev"
	    fi
	    if [ ${substype} = 'ass' ];then
		fltsub="ass=$tempsubs"
	    else
		fltsub="subtitles=$tempsubs"
	    fi
	fi
    fi

    if [ $rendertest != 'n' ]; then
	if [ "$testattempt" != 'n' ]; then
	    echo "Disable test attempt first"
	    exit 1
	fi
	if [ ${substype} = 'n' ] || [ "x$fltsub" = 'x' ]; then
	    echo "No subs file"
	    exit 1
	else
	    flt="-vf $fltsub"
	fi
	duration=`${ffmpegbin} -hide_banner -i "$FILE" 2>&1 | awk '/Duration/{print $2}' | sed 's/\,//g'`
	${ffmpegbin} -hide_banner -loop 1 -y -i $testimg -t $duration \
	    -c:v libx264 -preset ultrafast -b:v 100k -pix_fmt yuv420p -an -threads 0 \
	    $flt $tempmp4
    else
	if [ "x${vfprefix}" != 'x' ]; then
	    flt=$( MakeVfilter "$flt" "${vfprefix}" )
	fi
	if [ "x$fltsub" != 'x' ]; then
	    flt=$( MakeVfilter "$flt" "$fltsub" )
	fi
	if [ "x${vfsuffix}" != 'x' ]; then
	    flt=$( MakeVfilter "$flt" "${vfsuffix}" )
	fi
	if [ "${twoPass}" != 'y' ]; then
	    export FFREPORT=file="${wrkdir}${baseoufile}log":level=$debug_level
	else
	    export FFREPORT=file="${wrkdir}${baseoufile}pass1.log":level=$debug_level
	    ${ffmpegbin} -hide_banner -report -y -i "${FILE}" \
		$map $timerange \
		-s ${res} -c:v libx264 -preset medium -b:v ${bratvid} -an \
		-threads 0 -g 12 -r ${framerate} \
		$flt -pass 1 -passlogfile ${baseoufile}ffmpeg2pass -f mp4 /dev/null || exit 1
	    export FFREPORT=file="${wrkdir}${baseoufile}pass2.log":level=$debug_level
	    pass="-pass 2 -passlogfile ${baseoufile}ffmpeg2pass"
	    preset='slower'
	fi
	${ffmpegbin} -hide_banner -report -y -i "$FILE" \
	    ${map} $timerange \
	    -s ${res} -c:v libx264 -preset $preset -b:v ${bratvid} \
	    -c:a libfdk_aac -b:a ${brataud} ${afilt} \
	    -movflags +faststart -threads 0 -g 12 -r ${framerate} \
	    $flt $pass $tempmp4
    fi

    if [ -f $tempmp4 ];then
	if [ $rendertest != 'n' ]; then
	    rm -f $tempmp4
	else
	    mv $tempmp4  "${oudir}${oufile}"
	fi
    fi

    if [ -f $tempsubs ];then
	rm -f $tempsubs
    fi

    if [ "${twoPass}" = 'y' ];then
	rm -f "${baseoufile}ffmpeg2pass"*
    fi

    if [ "$testattempt" != 'n' ]; then
	exit
    fi

done

