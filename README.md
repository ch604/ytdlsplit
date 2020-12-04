# ytdlsplit
Wrapper for youtube-dl and ffmpeg to collect mp3 output and split to individual files at timestamps from youtube descriptions. Checks the description of the video first for available timestamps and validates them before downloading. Calculates number of tracks for adding leading 0's to track numbers.
```
[user@host2 ~]# ./ytdlsplit.sh -u https://www.youtube.com/watch?v=0nBYI0owpeY -o "/data/FFVII LoFi"
creating storage directory...
scraping timestamps...
downloading music and emailing the RIAA...
[youtube] 0nBYI0owpeY: Downloading webpage
[download] Destination: /data/FFVII LoFi/temp.file
[download] 100% of 23.84MiB in 00:01
[ffmpeg] Destination: /data/FFVII LoFi/temp.mp3
Deleting original file /data/FFVII LoFi/temp.file (pass -k to keep)
splitting...
 writing file "1 - Main Theme lofi" from 0 for 209 seconds...
 writing file "2 - Ahead on Our Way lofi" from 209 for 221 seconds...
 writing file "3 - Anxious Heart lofi" from 430 for 201 seconds...
 writing file "4 - Battle Theme lofi" from 631 for 121 seconds...
 writing file "5 - Victory Fanfare lofi" from 752 for 106 seconds...
 writing file "6 - Tifa lofi" from 858 for 190 seconds...
 writing file "7 - The Turks lofi" from 1048 for 162 seconds...
 writing file "8 - Jenova lofi" from 1210 for remainder of track...
cleaning up...
share and enjoy!
```
# Requirements
youtube-dl (min 2020 version) and ffmpeg (compiled with mp3 support) in your $PATH
# Installation
 `wget https://raw.githubusercontent.com/ch604/ytdlsplit/main/ytdlsplit.sh`
# Use
```
bash ytdlsplit.sh -u "URL" -o "/path/to/output directory" [-q QUALITY]
 
-u URL"      URL to youtube-dl compatible video
-o PATH      path to output directory, will be created if missing
-q QUALITY   pass a Vx level (0-9) or specific bitrate (192K) for output audio quality (default is 160K)
```
# Known Issues
- Older versions of youtube-dl do not support full description download, and may not pull the full tracklist. An upgrade to version 2020.12.02 or later is recommended.
- Doesn't support playlists, but you /probably/ wouldn't want to split those at timestamps anyway. Just use youtube-dl.
- Timestamps are only scraped when they are not wrapped in other characters, like parentheses, and preceed the tracak name, as follows:
```
00:00 track 1
next is 02:00 track 2

and then we have 04:03 track 3
```
Preceeding characters and extra lines are OK, as above. For instance, however, the following formats will not work:
```
track 1 (00:00)

02:00
track 2

[04:05] track 3
```
