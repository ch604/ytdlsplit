#!/bin/bash
# ytdlsplit.sh
# github.com/ch604/ytdlsplit

#ensure youtube-dl installed and up to date
#ensure ffmpeg installed and supports all required flags (min ver)
#ensure mp3 libs installed for writing output

#-o $output folder
#-u $url quoted url of video

error() {
	echo "ERROR: $1" >&2
	exit 254
}

ytdl_detect() {
	which youtube-dl &> /dev/null
}

ffmpeg_detect() {
	which ffmpeg &> /dev/null
}

printhelp() {
	echo "ytdlsplit - youtube-dl ffmpeg wrapper for splitting video mp3s
at description timestamps

usage: ytdlsplit -u \"URL\" -o path/to/output [-q 0]

arguments:
	-u \"URL\"	quoted URL to youtube-dl compatible video URL
	-o PATH		path to output directory, will be created if missing
	-q QUALITY	pass a Vx level (0-9) or specific bitrate (160K)
			for output audio quality

"
exit 0
}

argparse() {
	while getopts :hu:o:q: arg; do
		case "${arg}" in
			h) printhelp;;
			u) url=${OPTARG};;
			o) output=${OPTARG};;
			q) quality=${OPTARG};;
			?) error "Unknown option ${OPTARG}";;
		esac
	done
}

argparse
#get timestamps
timestamps=$(mktemp)
youtube-dl --get-description "$url" 2> /dev/null | awk '{for(i=1; i<=NF; i++){if($i~/[0-9]+\:[0-9]+/){print substr($0,index($0,$i))}}}' > $timestamps
if egrep -q '^[^0-9]' $timestamps; then
	echo "bad timestamps detected (lines must start with numbers separated by colons):" >> ./ytdlsplit.err
	cat $timestamps >> ./ytdlsplit.err
	echo "" >> ./ytdlsplit.err
	error "bad timestamps detected in description! see ./ytdlsplit.err"
fi
#download the mp3
youtube-dl --ignore-errors --format bestaudio --extract-audio --audio-format mp3 --audio-quality 160K --output $output'/temp.%(ext)s' "$url" -q
#calculate song lengths
