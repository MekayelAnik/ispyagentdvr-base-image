#!/bin/bash

# Exit on error and print each command for debugging
set -ex

bash /resources/add_debian_sid.sh

amd64_driver(){
#    bash /resources/add_debian_backports.sh
    ### Note SID is used because the VAAPI driver stack (iHD/libva 2.23,
    ### libigdgmm12 >=22.10) and a more recent libc6 are not available in
    ### trixie/backports. All VAAPI UMDs must share one libva ABI, so the
    ### whole amd64 driver set is pulled from sid (libva-driver-abi-1.23).
    echo "Installing drivers from Debian sources:"

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    libc6 openssl

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers mesa-vdpau-drivers vulkan-tools vdpau-driver-all vainfo

    # Intel VAAPI drivers: iHD (Gen8+/Broadwell+) with fallback to the free
    # variant, plus i965 for pre-Broadwell. This is what FFmpeg's VAAPI path
    # actually loads for Intel QuickSync - the OpenCL compute-runtime
    # previously installed here was never used by FFmpeg (no --enable-opencl).
    # Pulled from sid so libva2 2.23 / libigdgmm12 22.10 resolve consistently
    # with the rest of the VAAPI stack.
    echo "Installing Intel VAAPI drivers:"
    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver-non-free || \
    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver || { echo "ERROR: Intel media driver (iHD) install failed - aborting build"; exit 1; }
    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    i965-va-driver || { echo "ERROR: i965 driver install failed - aborting build"; exit 1; }

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    nvidia-vaapi-driver libnvidia-encode1 || { echo "ERROR: NVIDIA VAAPI driver install failed - aborting build"; exit 1; }

    verify_amd64_drivers
}

# Fail the build if any expected VAAPI driver .so is missing. apt can exit 0
# on partial states and a missing driver must never ship in the image.
verify_amd64_drivers() {
    echo "Verifying VAAPI driver installation:"
    local dri_dir="/usr/lib/x86_64-linux-gnu/dri"
    local required="radeonsi_drv_video.so iHD_drv_video.so i965_drv_video.so nvidia_drv_video.so"
    local missing=0
    for drv in $required; do
        if [ -e "$dri_dir/$drv" ]; then
            echo "OK: $drv"
        else
            echo "ERROR: required VAAPI driver missing: $dri_dir/$drv"
            missing=1
        fi
    done
    if [ "$missing" -ne 0 ]; then
        echo "ERROR: VAAPI driver verification failed - refusing to ship broken image"
        exit 1
    fi
    echo "All required VAAPI drivers present."
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