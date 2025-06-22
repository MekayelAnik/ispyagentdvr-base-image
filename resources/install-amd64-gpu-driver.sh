#!/bin/bash
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
    # Final verification
    for sumFile in *.sum; do
        echo "🔍 Verifying existing files against $sumFile (excluding .ddeb files)..."
        
        passed_count=0
        skipped_count=0
        failed_count=0
        excluded_count=0
        
        while read -r line; do
            filename=$(echo "$line" | awk '{print $2}')
            
            # Skip .ddeb files
            if [[ "$filename" == *.ddeb ]]; then
                echo "↩️ EXCLUDED: $filename (.ddeb file)"
                ((excluded_count++))
                continue
            fi
            
            if [ -f "$filename" ]; then
                if echo "$line" | sha256sum -c --quiet 2>/dev/null; then
                    echo "✅ PASSED: $filename"
                    ((passed_count++))
                else
                    echo "❌ FAILED: $filename (checksum mismatch)"
                    ((failed_count++))
                    exit 1
                fi
            else
                echo "⚠️ SKIPPED: $filename (not present)"
                ((skipped_count++))
            fi
        done < "$sumFile"
        
        echo "Verification complete for $sumFile:"
        echo "  PASSED: $passed_count files"
        echo "  SKIPPED: $skipped_count files"
        echo "  EXCLUDED: $excluded_count .ddeb files"
        echo "  FAILED: $failed_count files"
        echo ""
    done

    [ "$failed_count" -eq 0 ] && echo "✅ All checked files passed verification" || exit 1
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
add-sid() {
echo "**** Adding SID Repository ****"
cat <<EOF | tee /etc/apt/sources.list.d/sid.sources
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: sid
Components: main contrib non-free non-free-firmware
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
}
main(){
    add-sid
    ### Note SID is used because intel drivers require much more recent libc6 than available in backports
    echo "Installing drivers from Debian sources:"
   	DEBIAN_FRONTEND=noninteractive apt-get install libc6 mesa-va-drivers vdpau-driver-all nvidia-vaapi-driver openssl ocl-icd-libopencl1 -y --no-install-recommends --no-install-suggests
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

main


