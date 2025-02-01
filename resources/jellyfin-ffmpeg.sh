#!/bin/bash
#########################	INSTALL BASED ON ALL PLATFORM	#########################
echo "**** Installing Dependencies ****"
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
apt-get dist-upgrade -y
apt-get install -y alsa-utils
apt-get install -y curl unzip wget gnupg ca-certificates software-properties-common tzdata libgdiplus --no-install-recommends --no-install-suggests
add-apt-repository universe -y
mkdir -p /etc/apt/keyrings
curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key | gpg --dearmor -o /etc/apt/keyrings/jellyfin.gpg
export VERSION_OS="$(awk -F'=' '/^ID=/{ print $NF }' /etc/os-release)"
export VERSION_CODENAME="$(awk -F'=' '/^VERSION_CODENAME=/{ print $NF }' /etc/os-release)"
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
apt-get update
apt-get install g++ gcc locales jellyfin-ffmpeg${JELLYFIN_FFMPEG_MAJOR_VERSION} -y --no-install-recommends --no-install-suggests

call-local-binary-address() {
	if [ -e /resources/build_data/binary_server_url ]; then
		BINARY_SERVER_URL=$(cat /resources/build_data/binary_server_url)
		INTEL_DRIVER_URL="$BINARY_SERVER_URL/intel-drivers/"
		IGC=""
		NEO=""
	else
		INTEL_DRIVER_URL="https://github.com/intel"
		IGC="/intel-graphics-compiler/releases/download/v$IGC_VERSION/"
		NEO="/compute-runtime/releases/download/$NEO_VERSION/"
	fi
}
arch=$(uname -m)
#########################	INSTALL BASED ON PLATFORM	#########################
echo "**** Installing DRIVERS ****"
case $(arch) in
'arm' | 'armv6l' | 'armv7l')
	LIB_DIRECTORY='/usr/lib/arm-linux-gnueabihf'
	apt-get install libatlas-base-dev libatlas3-base libssl-dev libfontconfig1 libfreetype6 libva2 vainfo -y --no-install-recommends --no-install-suggests
	;;
'aarch64' | 'arm64')
	LIB_DIRECTORY='/usr/lib/aarch64-linux-gnu'
	apt-get install libssl-dev libfontconfig1 libfreetype6 libomxil-bellagio0 libomxil-bellagio-bin vainfo -y --no-install-recommends --no-install-suggests
	;;
'x86_64' | 'amd64')
	LIB_DIRECTORY='/usr/lib/x86_64-linux-gnu'
	if [  -e /resources/build_data//GMMLIB_VERSION ]; then
		GMMLIB_VERSION=$(cat /resources/build_data/GMMLIB_VERSION)
	else
		echo "FILE: /resources/build_data/GMMLIB_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	if [  -e /resources/build_data/IGC_MAJOR_VERSION ]; then
		IGC_MAJOR_VERSION=$(cat /resources/build_data/IGC_MAJOR_VERSION)
	else
		echo "FILE: /resources/build_data/IGC_MAJOR_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	if [  -e /resources/build_data/IGC_VERSION ]; then
		IGC_VERSION=$(cat /resources/build_data/IGC_VERSION)
	else
		echo "FILE: /resources/build_data/IGC_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	if [  -e /resources/build_data/IGC_SUB_VERSION ]; then
		IGC_SUB_VERSION=$(cat /resources/build_data/IGC_SUB_VERSION)
	else
		echo "FILE: /resources/build_data/IGC_SUB_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	if [  -e /resources/build_data/NEO_VERSION ]; then
		NEO_VERSION=$(cat /resources/build_data/NEO_VERSION)
	else
		echo "FILE: /resources/build_data/NEO_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	if [  -e /resources/build_data/LEVEL_ZERO_VERSION ]; then
		LEVEL_ZERO_VERSION=$(cat /resources/build_data/LEVEL_ZERO_VERSION)
	else
		echo "FILE: /resources/build_data/LEVEL_ZERO_VERSION NOT FOUND!!!! Exitting..."
		exit 1
	fi
	apt-get install mesa-va-drivers openssl -y --no-install-recommends --no-install-suggests
	apt-get install ocl-icd-libopencl1 -y --no-install-recommends --no-install-suggests #####	Needed for intel-opencl-icd	#####
	call-local-binary-address
	mkdir intel-compute-runtime
	cd intel-compute-runtime
	echo "The Intel GPU Driver URL is: $INTEL_DRIVER_URL"
	echo "Download & installing Intel Drivers:"
	curl -LO ${INTEL_DRIVER_URL}${IGC}intel-igc-core-${IGC_MAJOR_VERSION}_${IGC_VERSION}${IGC_SUB_VERSION}_amd64.deb \
			-LO ${INTEL_DRIVER_URL}${IGC}intel-igc-opencl-${IGC_MAJOR_VERSION}_${IGC_VERSION}${IGC_SUB_VERSION}_amd64.deb \
			-LO ${INTEL_DRIVER_URL}${NEO}intel-level-zero-gpu_${LEVEL_ZERO_VERSION}_amd64.deb \
			-LO ${INTEL_DRIVER_URL}${NEO}intel-opencl-icd_${NEO_VERSION}_amd64.deb \
			-LO ${INTEL_DRIVER_URL}${NEO}libigdgmm${GMMLIB_VERSION}_amd64.deb
		ls -l
		dpkg -i *.deb
	cd ..
	echo "****		Cleaning Up driver residues		****"
	rm -vrf intel-compute-runtime
	echo "****		Copying FFMPEG Bin Files to Bin destination		****"
	;;
esac
echo "****		Copying Library Files to Library destination		****"
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
