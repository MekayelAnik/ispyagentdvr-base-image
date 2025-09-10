#!/bin/bash

# Exit on error and print each command for debugging
set -ex

echo "*****     Installing VLC with all of its dependencies       *****"
DEBIAN_FRONTEND=noninteractive apt-get -t sid install -y --no-install-recommends --no-install-suggests \
libvlc-dev vlc libx11-dev 
echo "****      Installation of VLC Completed       ****"