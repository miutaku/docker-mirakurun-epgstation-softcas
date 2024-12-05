#!/bin/bash

ffprobe_cmd=/usr/local/bin/ffprobe
ffmpeg_cmd=/usr/local/bin/ffmpeg
mode=$1

if [ "$mode" = "" ]; then
    mode="main"
fi

function getHeight() {
    echo `$ffprobe_cmd -v 0 -show_streams -of flat=s=_:h=0 "$INPUT" | grep stream_0_width | awk -F= '{print \$2}'`
}

if [ `getHeight` -gt 1080 ]; then
    $ffmpeg_cmd -dual_mono_mode $mode -vaapi_device /dev/dri/renderD128 -i "$INPUT" -vf 'format=nv12|vaapi,hwupload,deinterlace_vaapi,scale_vaapi=w=1920:h=1080' -c:v h264_vaapi -level 40 -qp 21 -aspect 16:9 -acodec aac -ar 48000 -ab 192k -ac 2 "$OUTPUT"
else
    $ffmpeg_cmd -dual_mono_mode $mode -vaapi_device /dev/dri/renderD128 -i "$INPUT" -vf 'format=nv12|vaapi,hwupload,deinterlace_vaapi,scale_vaapi=w=1280:h=720' -c:v h264_vaapi -level 40 -qp 21 -aspect 16:9 -acodec aac -ar 48000 -ab 128k -ac 2 "$OUTPUT"
fi
