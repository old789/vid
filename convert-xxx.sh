#!/bin/sh

# source: 

rendertest='n'
#rendertest='y'

testattempt="n"
testattempt="-t 120"
#testattempt="-ss 00:02:00 -t 120"

debug_level=24

prefix="xyz"

indir="/dog/home/old/dump/"
infile="___.mkv"

subsdir=""
substitlefile='' # if set, used this value, otherwise created from ${infile}

res="854x480"
bratvid="1536k"
brataud="192k"
framerate="24000/1001"
map="-map 0:0 -map 0:1"

mapintsub='n'
#mapintsub="-map 0:2"

substype='ass'
#substype='srt'
#substype='n'

iconvert=''
#iconvert='-f cp1251 -t utf-8'

afilt=''
#afilt=" -ac 2 -af volume=4.0" # for convert 5.1 or higher sound to stereo

vfsuffix=''
#vfsuffix="pad=${res//x/:}:(ow-iw)/2,setdar=dar=16/9"          # auto padding x:y -> ${res} where y=y(${res})
#vfsuffix='scale=-1:480,pad=854:480:(ow-iw)/2,setdar=dar=16/9' # scale ?x576 and padding to 854x480
#vfsuffix='pad=854:480:107:0,setdar=dar=16/9'                  # hardcode padding 640x480 -> 854x480

vfprefix=''
#vfprefix="yadif=1:-1:0" # deinterlace input image

twoPass='n'

# ----- end of config  -----

oufile="${prefix}.mp4"

oudir="/dog/home/old/vid/${prefix}/"
wrkdir="/home/old/vid/"

tempsubs="${wrkdir}temp.${oufile%mp4}${substype}"
tempmp4="${wrkdir}temp.${oufile}"

testimg="${wrkdir}img/test.png"

ffmpegbin='ffmpeg'

baseoufile=${oufile%mp4} # for some reason

function MakeVfilter {
    if [ "x$1" = 'x' ]; then
	echo "-vf $2"
    else
	echo "$1,$2"
    fi
}

if [ "$testattempt" != 'n' ] || [ "$rendertest" != 'n' ]; then
    debug_level=32
fi

if [ ! -d "${indir}" ]; then
    echo Input dir not ready
    exit 1
fi

if [ ! -d "${wrkdir}" ]; then
    echo Work dir not ready
    exit 1
fi

cd "${wrkdir}"

if [ ! -d ${oudir} ]; then
    mkdir -p ${oudir}
fi

if [ -f "$tempsubs" ];then
    rm -f "$tempsubs"
fi

flt=''
fltsub=''
if [ ${substype} != 'n' ];then
    if [ "$mapintsub" = 'n' ];then
	if [ "x${substitlefile}" = 'x' ]; then
	    videotype="${infile##*.}"
	    if [ "x$videotype" = 'x' ]; then
		echo Unknown video type
		exit 1
	    fi
	    substitlefile="${infile%$videotype}${substype}"
	fi
	if [ -f "${indir}${subsdir}${substitlefile}" ]; then
	    cp "${indir}${subsdir}${substitlefile}" $tempsubs
	else
	    echo  "${indir}${subsdir}${substitlefile}" not found
	    exit 1
	fi
    else
	export FFREPORT=file="${wrkdir}${baseoufile}subs.log":level=$debug_level
	${ffmpegbin} -hide_banner -report -y -i "${indir}${infile}" $mapintsub $tempsubs
    fi

    if [ ! -f "$tempsubs" ]; then
	echo "No subs file"
	exit 1
    else
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

timerange=' '
if [ "$testattempt" != 'n' ]; then
    timerange="$testattempt"
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
    duration=`${ffmpegbin} -hide_banner -i "${indir}${infile}" 2>&1 | awk '/Duration/{print $2}' | sed 's/\,//g'`
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
    pass=''
    preset='slow'
    if [ "${twoPass}" != 'y' ]; then
	export FFREPORT=file="${wrkdir}${baseoufile}log":level=$debug_level
    else
	export FFREPORT=file="${wrkdir}${baseoufile}pass1.log":level=$debug_level
	${ffmpegbin} -hide_banner -report -y -i "${indir}${infile}" \
	    $map $timerange \
	    -s ${res} -c:v libx264 -preset medium -b:v ${bratvid} -an \
	    -threads 0 -g 12 -r ${framerate} \
	    $flt -pass 1 -passlogfile ${baseoufile}ffmpeg2pass -f mp4 /dev/null || exit 1
	export FFREPORT=file="${wrkdir}${baseoufile}pass2.log":level=$debug_level
	pass="-pass 2 -passlogfile ${baseoufile}ffmpeg2pass"
	preset='slower'
    fi
    ${ffmpegbin} -hide_banner -report -y -i "${indir}${infile}" \
	$map $timerange \
	-s ${res} -c:v libx264 -preset $preset -b:v ${bratvid} -c:a libfdk_aac -b:a ${brataud} ${afilt} \
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
