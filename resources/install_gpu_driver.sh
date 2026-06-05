#!/bin/bash

# Exit on error and print each command for debugging
set -ex

bash /resources/add_debian_sid.sh

amd64_driver(){
#    bash /resources/add_debian_backports.sh
    ### SID is only used for a more recent libc6/openssl than trixie ships.
    ### Every VAAPI driver comes from trixie - one coherent release, all built
    ### against the same libva (abi-1.22). Pulling them from sid hits in-flight
    ### mesa-libgallium / libva transitions that make the set unsatisfiable
    ### (iHD wants abi-1.23, i965 still abi-1.22, mesa-va-drivers mid-rebuild).
    echo "Installing drivers from Debian sources:"

    DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    libc6 openssl

    # The Intel media driver lives in Debian's non-free component, which the
    # base image only enables for sid. Enable non-free on the release's OWN
    # sources so iHD installs from trixie instead of being dragged in from sid
    # with an unsatisfiable dependency chain. Edit the existing sources in
    # place to avoid Signed-By conflicts with a duplicate source definition.
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then
        sed -i 's/^Components: .*/Components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources
    elif [ -f /etc/apt/sources.list ]; then
        sed -i -E 's/^(deb[^#]*main)[[:space:]]*$/\1 contrib non-free non-free-firmware/' /etc/apt/sources.list
    fi
    apt-get update

    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers mesa-vdpau-drivers vulkan-tools vdpau-driver-all vainfo

    # Intel VAAPI drivers: iHD (Gen8+/Broadwell+) with fallback to the free
    # variant, plus i965 for pre-Broadwell. This is what FFmpeg's VAAPI path
    # actually loads for Intel QuickSync - the OpenCL compute-runtime
    # previously installed here was never used by FFmpeg (no --enable-opencl).
    # Install failures are FATAL: a missing driver must never ship silently.
    echo "Installing Intel VAAPI drivers:"
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver-non-free || \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    intel-media-va-driver || { echo "ERROR: Intel media driver (iHD) install failed - aborting build"; exit 1; }
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
    i965-va-driver || { echo "ERROR: i965 driver install failed - aborting build"; exit 1; }

    # NVIDIA VAAPI from trixie as well: nvidia-vaapi-driver 0.0.13 +
    # libnvidia-encode1 are coherent with the trixie libva/gstreamer set. The
    # sid build needs gstreamer-bad >= 1.28.1 (trixie ships 1.24.9) and would
    # drag a conflicting sid chain, so keep it on trixie and make it fatal.
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends --no-install-suggests \
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
