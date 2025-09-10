#!/bin/bash

# Exit on error and print each command for debugging
set -ex

bash /resources/add_debian_sid.sh

download-files() {
    # Download all package files
    echo "📦 Downloading package files..."
    wget -qO- "$RELEASE_URL" | grep -o 'href="[^"]*\.\(sum\|deb\)"' | sed 's/href="//;s/"$//' | while read -r file; do
    OUTPUT_FILE=$(basename "$file")        
        echo "⬇️ Downloading: $OUTPUT_FILE"
        if ! wget -nc --tries=5 --timeout=60 "$DOWNLOAD_BASE_URL$file"; then
            echo "❌ Failed to download: $OUTPUT_FILE"
            [ -e "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE"
        fi

    done
}

final-integrity-check() {
    local overall_failed=0
    
    # Final verification
    for sumFile in *.sum; do
        echo "🔍 Verifying existing files against $sumFile (excluding .ddeb files)..."
        
        passed_count=0
        skipped_count=0
        failed_count=0
        excluded_count=0
        
        while IFS= read -r line || [[ -n "$line" ]]; do
            filename=$(echo "$line" | awk '{print $2}')
            
            # Skip .ddeb files
            if [[ "$filename" == *.ddeb ]]; then
                echo "↩️ EXCLUDED: $filename (.ddeb file)"
                excluded_count=$((excluded_count + 1))
                continue
            fi
            
            if [ -f "$filename" ]; then
                if echo "$line" | sha256sum -c --quiet 2>/dev/null; then
                    echo "✅ PASSED: $filename"
                    passed_count=$((passed_count + 1))
                else
                    echo "❌ FAILED: $filename (checksum mismatch)"
                    failed_count=$((failed_count + 1))
                    overall_failed=1
                fi
            else
                echo "⚠️ SKIPPED: $filename (not present)"
                skipped_count=$((skipped_count + 1))
            fi
        done < "$sumFile"
        
        echo "Verification complete for $sumFile:"
        echo "  PASSED: $passed_count files"
        echo "  SKIPPED: $skipped_count files"
        echo "  EXCLUDED: $excluded_count .ddeb files"
        echo "  FAILED: $failed_count files"
        echo ""
    done

    if [ $overall_failed -eq 0 ]; then
        echo "✅ All checked files passed verification"
    else
        echo "❌ Some files failed verification"
        exit 1
    fi
}
install-drivers() {
    # echo "📦 Installing driver package files..."
    # dpkg -i *.deb
    echo "📦 Installing driver package files..."
    # First install libigdgmm packages
    for file in libigdgmm*.deb; do
        if [ -f "$file" ]; then
            echo "🔽 Installing (priority): $file"
            if ! dpkg -i "$file"; then
                echo "❌ Installation failed for: $file"
                exit 1
            fi
        fi
    done

    # Then install all other .deb files
    for file in *.deb; do
        if [ -f "$file" ] && [[ "$file" != libigdgmm* ]]; then
            echo "🔽 Installing: $file"
            if ! dpkg -i "$file"; then
                echo "❌ Installation failed for: $file"
                exit 1
            fi
        fi
    done

    # Check if any .deb files were found at all
    if [ -z "$(ls *.deb 2>/dev/null)" ]; then
        echo "⚠️ No .deb files found to install."
        exit 1
    fi
}
amd64_driver(){
    LIB_DIRECTORY='/usr/lib/x86_64-linux-gnu'
#    bash /resources/add_debian_backports.sh
    ### Note SID is used because intel drivers require much more recent libc6 than available in backports
    echo "Installing drivers from Debian sources:"

   	DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    libc6 mesa-va-drivers mesa-vulkan-drivers mesa-vdpau-drivers vulkan-tools vdpau-driver-all nvidia-vaapi-driver libnvidia-encode1 openssl ocl-icd-libopencl1 vainfo

    echo "Download & installing Intel Drivers:"
    mkdir intel-compute-runtime
    cd intel-compute-runtime || exit 1
    # Set base URL (local mirror or GitHub)
    if [ -e /resources/build_data/COMPUTE_VERSION ]; then
        COMPUTE_VERSION=$(cat /resources/build_data/COMPUTE_VERSION)
    else
        echo "FILE: /resources/build_data/COMPUTE_VERSION NOT FOUND!!!! Exiting..."
        exit 1
    fi
    if [ -e /resources/build_data/LOCAL_URL ]; then
        RELEASE_URL=$(cat /resources/build_data/LOCAL_URL)
        DOWNLOAD_BASE_URL="$RELEASE_URL/$COMPUTE_VERSION"
        download-files
    else
        if [  -e /resources/build_data/IGC_VERSION ]; then
            IGC_VERSION=$(cat /resources/build_data/IGC_VERSION)
        else
            echo "FILE: /resources/build_data/IGC_VERSION NOT FOUND!!!! Exiting..."
            exit 1
        fi
        RELEASE_URL="https://github.com/intel/compute-runtime/releases/expanded_assets/$COMPUTE_VERSION"
        DOWNLOAD_BASE_URL="https://github.com"
        download-files
        RELEASE_URL="https://github.com/intel/intel-graphics-compiler/releases/expanded_assets/v$IGC_VERSION"
        download-files
    fi
    final-integrity-check
    install-drivers
    cd ..
    echo "****		Cleaning Up driver residues		****"
    rm -vrf intel-compute-runtime
}

arm64_driver() {
	LIB_DIRECTORY='/usr/lib/aarch64-linux-gnu'
	DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
    mesa-va-drivers mesa-vulkan-drivers v4l-utils libdrm2 vulkan-tools libssl-dev libfontconfig1 libfreetype6 vainfo 
}

armv7l_driver() {
    LIB_DIRECTORY='/usr/lib/arm-linux-gnueabihf'
	DEBIAN_FRONTEND=noninteractive apt-get install -t sid -y --no-install-recommends --no-install-suggests \
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