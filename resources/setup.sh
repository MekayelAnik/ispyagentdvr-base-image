#!/bin/bash

# Exit on error and print each command for debugging
set -ex

touch /etc/profile.d/env_vars.sh

arch=$(uname -m)
VERSION_OS=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
DPKG_ARCHITECTURE="$(dpkg --print-architecture)"
JELLYFIN_FFMPEG_MAJOR_VERSION="$(cat /resources/build_data/JELLYFIN_FFMPEG_MAJOR_VERSION)"

echo "export arch=\"$arch\"" > /etc/profile.d/env_vars.sh
echo "export VERSION_OS=\"$VERSION_OS\"" >> /etc/profile.d/env_vars.sh
echo "export VERSION_CODENAME=\"$VERSION_CODENAME\"" >> /etc/profile.d/env_vars.sh
echo "export DPKG_ARCHITECTURE=\"$DPKG_ARCHITECTURE\"" >> /etc/profile.d/env_vars.sh

case $(arch) in
'arm' | 'armv6l' | 'armv7l')
	echo "export LIB_DIRECTORY=\"/usr/lib/arm-linux-gnueabihf\"" >> /etc/profile.d/env_vars.sh
	;;
'aarch64' | 'arm64')
	echo "export LIB_DIRECTORY=\"/usr/lib/aarch64-linux-gnu\"" >> /etc/profile.d/env_vars.sh
	echo "export JELLYFIN_FFMPEG_MAJOR_VERSION=\"$JELLYFIN_FFMPEG_MAJOR_VERSION\"" >> /etc/profile.d/env_vars.sh
	;;
'x86_64' | 'amd64')
	echo "export LIB_DIRECTORY=\"/usr/lib/x86_64-linux-gnu\"" >> /etc/profile.d/env_vars.sh
	echo "export JELLYFIN_FFMPEG_MAJOR_VERSION=\"$JELLYFIN_FFMPEG_MAJOR_VERSION\"" >> /etc/profile.d/env_vars.sh
	;;
esac

chmod +x /etc/profile.d/env_vars.sh

mkdir -p /usr/bin/share

mv -vf /resources/build_data/base-image-timestamp /usr/bin/share/

bash -c "source /etc/profile.d/env_vars.sh && source /resources/update_image.sh"

bash -c "source /etc/profile.d/env_vars.sh && /resources/install_dependencies.sh"

bash -c "source /etc/profile.d/env_vars.sh && /resources/install_gpu_driver.sh"

bash -c "source /etc/profile.d/env_vars.sh && /resources/install_ffmpeg.sh"

if [ -f /resources/build_data/vlc ]; then
	bash -c "/resources/install_vlc.sh"
fi

bash -c "/resources/cleanup.sh"

echo "****		Completed Setup Procedure		****"
