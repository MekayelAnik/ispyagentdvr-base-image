#!/bin/bash

install-drivers() {
#########################	INSTALL BASED ON PLATFORM	#########################
	arch=$(uname -m)
	echo "**** Installing DRIVERS ****"
	case $(arch) in
	'arm' | 'armv6l' | 'armv7l')
		LIB_DIRECTORY='/usr/lib/arm-linux-gnueabihf'
		DEBIAN_FRONTEND=noninteractive apt-get install libatlas-base-dev libatlas3-base libssl-dev libfontconfig1 libfreetype6 libva2 vainfo -y --no-install-recommends --no-install-suggests
		;;
	'aarch64' | 'arm64')
		LIB_DIRECTORY='/usr/lib/aarch64-linux-gnu'
		DEBIAN_FRONTEND=noninteractive apt-get install libssl-dev libfontconfig1 libfreetype6 libomxil-bellagio0 libomxil-bellagio-bin vainfo -y --no-install-recommends --no-install-suggests
		;;
	'x86_64' | 'amd64')
		LIB_DIRECTORY='/usr/lib/x86_64-linux-gnu'
		bash /resources/install-amd64-gpu-driver.sh
		;;
	esac
}

echo "**** Upgrading Debian ****"
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update

echo "Upgrading Debian:"
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y

#########################	INSTALL BASED ON ALL PLATFORM	#########################


apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update

echo "**** Installing Dependencies ****"
DEBIAN_FRONTEND=noninteractive apt-get install -y sudo gosu libicu-dev ncurses-bin alsa-utils curl sudo unzip wget openssl gnupg ca-certificates locales software-properties-common tzdata libgdiplus g++ gcc adduser --no-install-recommends --no-install-suggests

install-drivers

echo "**** Adding Jellyfin Repository ****"
sudo add-apt-repository universe -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
export VERSION_OS="debian"
export VERSION_CODENAME="bookworm"
export DPKG_ARCHITECTURE="$(dpkg --print-architecture)"

cat <<EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/${VERSION_OS}
Suites: ${VERSION_CODENAME}
Components: main
Architectures: ${DPKG_ARCHITECTURE}
Signed-By: /etc/apt/keyrings/jellyfin.gpg
EOF
JELLYFIN_FFMPEG_MAJOR_VERSION="$(cat /resources/build_data/JELLYFIN_FFMPEG_MAJOR_VERSION)"
echo "**** Installing FFMPEG ****"
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt-get install jellyfin-ffmpeg${JELLYFIN_FFMPEG_MAJOR_VERSION} -y --no-install-recommends --no-install-suggests

echo "****		Copying FFMPEG Library Files to Library destination		****"
mv -vf /usr/share/jellyfin-ffmpeg/lib/dri/* "${LIB_DIRECTORY}/dri/"
rm -vrf /usr/share/jellyfin-ffmpeg/lib/dri
mv -vf /usr/share/jellyfin-ffmpeg/lib/* "${LIB_DIRECTORY}/"
rm -vrf /usr/share/jellyfin-ffmpeg/lib
echo "*****		Copying FFMPEG Bin Files to Bin destination		*****"
mv -vf /usr/share/jellyfin-ffmpeg/* /usr/bin/
ln -s /usr/bin/share /usr/lib/jellyfin-ffmpeg/
rm -vrf /usr/share/jellyfin-ffmpeg
echo "****		Completed Installing Drivers		****"
echo "****		Removing Residue Files, Folders. Cleaning up the Image		****"
echo "****		Completed Installing FFMPEG		****"
