#!/bin/bash

# Exit on error and print each command for debugging
set -ex

bash /resources/add_debian_sid.sh

amd64_driver(){
#    bash /resources/add_debian_backports.sh
    ### Note SID is used because some driver packages require a more recent libc6 than available in backports
    echo "Installing drivers from Debian sources:"

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    libc6 openssl

    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers mesa-vdpau-drivers vulkan-tools vdpau-driver-all vainfo

    # Intel VAAPI drivers: iHD (Gen8+/Broadwell+) with fallback to the free
    # variant, plus i965 for pre-Broadwell. This is what FFmpeg's VAAPI path
    # actually loads for Intel QuickSync - the OpenCL compute-runtime
    # previously installed here was never used by FFmpeg (no --enable-opencl).
    echo "Installing Intel VAAPI drivers:"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver-non-free || \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver || echo "WARNING: Intel media driver unavailable - Intel QuickSync disabled"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    i965-va-driver || echo "WARNING: i965 driver unavailable - pre-Broadwell Intel VAAPI disabled"

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    nvidia-vaapi-driver libnvidia-encode1 || echo "WARNING: NVIDIA VAAPI packages skipped due to dependency conflict"
}

arm64_driver() {
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers v4l-utils libdrm2 vulkan-tools libssl-dev libfontconfig1 libfreetype6 vainfo
}

armv7l_driver() {
	DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers v4l-utils libdrm2 vulkan-tools libatlas3-base libssl-dev libfontconfig1 libfreetype6 libva2 vainfo
}

main() {
#########################	INSTALL BASED ON PLATFORM	#########################
	echo "**** Installing DRIVERS ****"
	case $(arch) in
	'arm' | 'armv6l' | 'armv7l')
        armv7l_driver
		;;
	'aarch64' | 'arm64')
		arm64_driver
		;;
	'x86_64' | 'amd64')
		amd64_driver
		;;
	esac
	echo "****		Completed Installing Drivers		****"
}

main