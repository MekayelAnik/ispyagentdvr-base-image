#!/bin/bash
mkdir -p /usr/bin/share
mv -vf /resources/build_data/base-image-timestamp /usr/bin/share/
if [ -f /resources/build_data/JELLYFIN_FFMPEG_VERSION ]; then
    echo "*****     Installing GPU Hardware Acceleration Enabled Jellyfin FFMPEG with all of its dependencies       *****"
    bash /resources/install-jellyfin-ffmpeg.sh
else
    echo "*****     Installing Default FFMPEG, available for this Base Image from APT Repository      *****"
    bash /resources/default-ffmpeg.sh
fi
if [ -f /resources/build_data/vlc ]; then
    echo "*****     Installing VLC with all of its dependencies       *****"
    bash /resources/vlc.sh
fi
# apt-get install coturn -y --no-install-recommends --no-install-suggests
echo "*****     Cleaning Up before publishing the image       *****"
bash /resources/cleanup.sh