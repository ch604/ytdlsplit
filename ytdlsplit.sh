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

usage: ytdlsplit -u \"URL\" -o path/to/output

arguments:
	-u \"URL\"	quoted URL to youtube-dl compatible video URL
	-o PATH		path to output directory, will be created if missing

"
exit 0
}

argparse() {
	while getopts :hu:o: arg; do
		case "${arg}" in
			h) printhelp;;
			u) url=${OPTARG};;
			o) output=${OPTARG};;
			?) error "Unknown option ${OPTARG}";;
		esac
	done
}

argparse
timestamps=$(mktemp)
youtube-dl --get-description "$url" 2> /dev/null | awk '{for(i=1; i<=NF; i++){if($i~/[0-9]+\:[0-9]+/){print substr($0,index($0,$i))}}}' > $timestamps
if ! egrep -q '[0-9]+\:[0-9]+' $timestamps; then
	error "no timestamps detected in description!"
fi
