#!/bin/bash
apt-get install -y tzdata alsa-utils libgdiplus adduser --no-install-recommends --no-install-suggests
apt-get install -y curl unzip wget ca-certificates libldap-2.5-0 --no-install-recommends --no-install-suggests
#####		Important for ARMHF		#####
arch=$(uname -m)
case $(arch) in
'arm' | 'armv6l' | 'armv7l')
	apt-get install -y libatlas-base-dev libatlas3-base --no-install-recommends --no-install-suggests
rm -vrf /etc/apt/sources.list.d/debian.list
	;;
esac
#####		Adding Testing & Unstable Repositories		#####
echo "****	Installing Default FFMPEG	****"
echo 'deb https://deb.debian.org/debian testing main'>/etc/apt/sources.list.d/debian.list
echo 'deb https://deb.debian.org/debian unstable main'>>/etc/apt/sources.list.d/debian.list
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt-get -t unstable install ffmpeg -y --no-install-recommends --no-install-suggests
echo "****		Installation of Default FFMPEG from APT repository is completed		****"