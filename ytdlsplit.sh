#!/bin/bash
# ytdlsplit.sh
# version 1.5
# github.com/ch604/ytdlsplit

error() { #print error and die
	echo "ERROR: $1" >&2
	exit 254
}

printhelp() {
	echo "ytdlsplit - youtube-dl and ffmpeg wrapper for splitting video
mp3s at description timestamps

usage: ytdlsplit -u \"URL\" -o path/to/output [-q 0] [-t path/to/timestamps]

arguments:
	-u \"URL\"	quoted URL to youtube-dl compatible video URL
	-o PATH		path to output directory, will be created if missing
	-q QUALITY	pass a Vx level (0-9) or specific bitrate (192K)
			for output audio quality (default is 160K)
	-t PATH		path to preformatted timestamp file, in the format:

			00:00 trackname
			03:00 trackname
			1:00:00 trackname
"
exit 0
}

argparse() {
	while getopts :hu:o:q:t: arg; do
		case "${arg}" in
			h) printhelp;;
			u) url=${OPTARG};;
			o) output=${OPTARG};;
			q) quality=${OPTARG};;
			t) tspath=${OPTARG};;
			?) error "Unknown option ${OPTARG}";;
		esac
	done
}

makeitseconds() { # take a timestamp like 05:08 or 1:15:43 and turn it into integer seconds
	local n=$(cat)
	local hr min sec
	local segments=$(echo $n | tr '[0-9]' '\n' | grep -c \:)
	if [ $segments -eq 1 ]; then #ensure base 10 for numbers like 08
		min=$((10#$(echo $n | cut -d\: -f1)))
		sec=$((10#$(echo $n | cut -d\: -f2)))
		echo $(( $sec + ($min * 60) ))
	elif [ $segments -eq 2 ]; then
		hr=$((10#$(echo $n | cut -d\: -f1)))
		min=$((10#$(echo $n | cut -d\: -f2)))
		sec=$((10#$(echo $n | cut -d\: -f3)))
		echo $(( $sec + ($min * 60) + ($hr * 3600) ))
	fi
}

#now we start the main program!
argparse "$@"
if [ ! "$(which youtube-dl 2> /dev/null)" ] || [ ! "$(which ffmpeg 2> /dev/null)" ]; then
	error "I couldnt find youtube-dl or ffmpeg binaries! Please make sure these are installed!"
elif ! ffmpeg -hide_banner -formats | grep -q mp3; then
	error "ffmpeg doesn't seem to support mp3 handling! (see ffmpeg -formats | grep mp3)"
fi
[ -z "$url" -o -z "$output" ] && error "i'm missing something... -u and -o are required!"
[ -z "$quality" ] && quality="160K"

#find and make directory
[ ! -d "$output" ] && echo "creating storage directory..." && mkdir -p "$output"

#get timestamps
if [ -f "$tspath" ]; then
	echo "using your timestamp file..."
	timestamps=$tspath
else
	echo "scraping timestamps..."
	timestamps=$(mktemp)
	youtube-dl --get-description "$url" 2> /dev/null | awk '{for(i=1; i<=NF; i++){if($i~/[0-9]+:[0-9]+/){print substr($0,index($0,$i))}}}' > $timestamps
fi
if egrep -q '^[^0-9]' $timestamps || [ $(cat $timestamps | sed '/^$/d' | wc -l) -eq 0 ]; then
	echo "bad timestamps detected (lines must start with numbers separated by colons):" >> ./ytdlsplit.err
	cat $timestamps >> ./ytdlsplit.err
	echo "" >> ./ytdlsplit.err
	error "bad timestamps detected in description! see ./ytdlsplit.err"
else
	echo "timestamps looking good!"
fi

#download the mp3
echo "downloading music and emailing the RIAA..."
youtube-dl -i --format bestaudio -x --audio-format mp3 --audio-quality $quality --output "$output"/temp.file "$url"

#calculate song lengths and split the source mp3
echo "splitting..."
i=1
#sigdig to get the number of leading 0's on the track number
sigdig=$(($(cat $timestamps | wc -l | wc -c) - 1))
while read -u9 line; do
	filename="$(printf "%0"$sigdig"d\n" $i) - $(echo $line | awk '{print substr($0,index($0,$2))}' | tr '/' '_')"
	starttime=$(echo $line | awk '{print $1}' | makeitseconds)
	endtime=$(grep -A1 -e "$line" $timestamps | tail -1 | awk '{print $1}' | makeitseconds)
	length=$(($endtime - $starttime))
	if [ $length -ne 0 ]; then
		echo " writing file \"$filename\" from $starttime for $length seconds..."
		ffmpeg -hide_banner -loglevel warning -ss $starttime -t $length -i "$output/temp.mp3" -acodec copy "$output/$filename.mp3"
	else
		echo " writing file \"$filename\" from $starttime for remainder of track..."
		ffmpeg -hide_banner -loglevel warning -ss $starttime -i "$output/temp.mp3" -acodec copy "$output/$filename.mp3"
	fi
	let i+=1
done 9< $timestamps

#get cover art
echo "getting cover art..."
wget -q -O "$output/folder.jpg" https://img.youtube.com/vi/$(youtube-dl --get-id "$url")/maxresdefault.jpg
[ $? -ne 0 ] && wget -q -O "$output/folder.jpg" https://img.youtube.com/vi/$(youtube-dl --get-id "$url")/hqdefault.jpg
[ $? -ne 0 ] && echo " couldnt get art sorry"

#cleanup temp.mp3 and $timestamps
echo "cleaning up..."
rm -f "$output/temp.mp3"
rm -f $timestamps

echo "share and enjoy!"
exit 0
