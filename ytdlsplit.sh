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
	[ -z "$url" -o -z "$output" ] && error "i'm missing something..."
}

makeitseconds() {
	n=$(cat)
	local segments=$(echo $n | tr '[0-9]' '\n' | grep -c \:)
	if [ $segments -eq 1 ]; then
		min=$(echo $n | cut -d\: -f1)
		[ "$min" = "0" ] && min=00
		min=$(echo $min | sed -e 's/^0//')
		sec=$(echo $n | cut -d\: -f2)
		[ "$sec" = "0" ] && sec=00
		sec=$(echo $sec | sed -e 's/^0//')
		echo $(( $sec + ($min * 60) ))
	elif [ $segments -eq 2 ]; then
		hr=$(echo $n | cut -d\: -f1)
		min=$(echo $n | cut -d\: -f2)
		[ "$min" = "0" ] && min=00
		min=$(echo $min | sed -e 's/^0//')
		sec=$(echo $n | cut -d\: -f3)
		[ "$sec" = "0" ] && sec=00
		sec=$(echo $sec | sed -e 's/^0//')
		echo $(( $sec + ($min * 60) + ($hr * 3600) ))
	fi
	unset hr min sec n
}

argparse "$@"
#get timestamps
echo "scraping timestamps..."
timestamps=$(mktemp)
youtube-dl --get-description "$url" 2> /dev/null | awk '{for(i=1; i<=NF; i++){if($i~/[0-9]+\:[0-9]+/){print substr($0,index($0,$i))}}}' > $timestamps
if egrep -q '^[^0-9]' $timestamps; then
	echo "bad timestamps detected (lines must start with numbers separated by colons):" >> ./ytdlsplit.err
	cat $timestamps >> ./ytdlsplit.err
	echo "" >> ./ytdlsplit.err
	error "bad timestamps detected in description! see ./ytdlsplit.err"
fi

#download the mp3
echo "emailing the RIAA..."
youtube-dl --ignore-errors --format bestaudio --extract-audio --audio-format mp3 --audio-quality 160K --output $output'/temp.mp3' "$url" -q

#calculate song lengths and split the source mp3
echo "splitting..."
i=1
while read -u9 line; do
	filename=$(echo $line | awk '{print substr($0,index($0,$2))}' | tr '/' '_')
	starttime=$(echo $line | awk '{print $1}' | makeitseconds)
	#echo "my starttime is $(echo $line | awk '{print $1}') converted to $starttime"
	endtime=$(grep -A1 -e "$line" $timestamps | tail -1 | awk '{print $1}' | makeitseconds)
	#echo "my endtime is $(grep -A1 -e "$line" $timestamps | tail -1 | awk '{print $1}') converted to $endtime"
	length=$(($endtime - $starttime))
	if [ $length -ne 0 ]; then
		echo " writing file "$i - $filename" from $starttime for $length seconds..."
		ffmpeg -hide_banner -loglevel warning -ss $starttime -t $length -i $output/temp.mp3 "$output/$i - $filename.mp3"
	else
		echo " writing file "$i - $filename" from $starttime for remainder of track..."
		ffmpeg -hide_banner -loglevel warning -ss $starttime -i $output/temp.mp3 "$output/$i - $filename.mp3"
	fi
	let i+=1
done 9< $timestamps

#cleanup temp.mp3 and $timestamps
echo "cleaning up..."
rm -f $output/temp.mp3
rm -f $timestamps

echo "share and enjoy!"
