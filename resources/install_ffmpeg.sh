#!/bin/bash
set -ex

default_ffmpeg() {
    echo "***** Installing Default FFMPEG from Debian repo *****"
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
    apt-get -t sid install -y --no-install-recommends --no-install-suggests ffmpeg libldap-common
    ln -sfv /usr/bin/ffmpeg "${LIB_DIRECTORY}/"
    echo "**** Default FFMPEG installation completed ****"
}

jellyfin_ffmpeg() {
    echo "***** Installing Jellyfin FFMPEG *****"
    # Ensure keyrings directory exists
    mkdir -p /etc/apt/keyrings

    # Save Jellyfin GPG key directly (no gnupg needed)
    curl -fsSL https://repo.jellyfin.org/jellyfin_team.gpg.key \
        -o /etc/apt/keyrings/jellyfin.gpg

    # Detect codename
    VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2)

    # Add Jellyfin repo
    cat <<EOF | tee /etc/apt/sources.list.d/jellyfin.sources
Types: deb
URIs: https://repo.jellyfin.org/debian
Suites: ${VERSION_CODENAME}
Components: main
Architectures: $(dpkg --print-architecture)
EOF

    # Allow insecure repo only for Jellyfin
    cat <<EOF | tee /etc/apt/apt.conf.d/99jellyfin-allow-unsigned
Acquire::AllowInsecureRepositories "true";
Acquire::AllowDowngradeToInsecureRepositories "true";
Acquire::https::repo.jellyfin.org::Verify-Peer "false";
Acquire::https::repo.jellyfin.org::Verify-Host "false";
EOF

    # Install Jellyfin FFmpeg
    JELLYFIN_FFMPEG_MAJOR_VERSION="$(cat /resources/build_data/JELLYFIN_FFMPEG_MAJOR_VERSION)"
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
    apt-get install -y --allow-unauthenticated --no-install-recommends --no-install-suggests \
        jellyfin-ffmpeg${JELLYFIN_FFMPEG_MAJOR_VERSION}

    echo "****		Copying FFMPEG Library Files to Library destination		****"

    # Only copy dri/ if it exists
    if [ -d "/usr/share/jellyfin-ffmpeg/lib/dri" ]; then
        rsync -avh --remove-source-files /usr/share/jellyfin-ffmpeg/lib/dri/ "${LIB_DIRECTORY}/dri/"
        rm -vrf /usr/share/jellyfin-ffmpeg/lib/dri
    fi

    # Copy remaining lib files
    if [ -d "/usr/share/jellyfin-ffmpeg/lib" ]; then
        rsync -avh --remove-source-files /usr/share/jellyfin-ffmpeg/lib/ "${LIB_DIRECTORY}/"
        rm -vrf /usr/share/jellyfin-ffmpeg/lib
    fi

    echo "***** Copying FFMPEG Bin Files to Bin destination     *****"

    # Copy share files if they exist
    if [ -d "/usr/share/jellyfin-ffmpeg/share" ]; then
        rsync -avh --remove-source-files /usr/share/jellyfin-ffmpeg/share/ /usr/bin/share/
        rm -vrf /usr/share/jellyfin-ffmpeg/share
    fi

    # Copy remaining files
    if [ -d "/usr/share/jellyfin-ffmpeg" ]; then
        rsync -avh --remove-source-files /usr/share/jellyfin-ffmpeg/ /usr/bin/
        rm -vrf /usr/share/jellyfin-ffmpeg
    fi

    ln -sfv /usr/bin/ffprobe "${LIB_DIRECTORY}/"
    ln -sfv /usr/bin/ffmpeg "${LIB_DIRECTORY}/"
    ln -sfv /usr/bin/vainfo "${LIB_DIRECTORY}/"

    echo "**** Jellyfin FFMPEG installation completed ****"
}

main() {
    case $(arch) in
        'arm' | 'armv6l' | 'armv7l' )
            default_ffmpeg
            FFMPEG_VERSION=$(apt-cache policy ffmpeg | grep -oP 'Candidate: \K[^ ]+' | sed 's/^[0-9]\+://')
            ;;
        *)
            if [ -f /resources/build_data/JELLYFIN_FFMPEG_VERSION ]; then
                jellyfin_ffmpeg
                FFMPEG_VERSION=$(apt-cache policy "jellyfin-ffmpeg${JELLYFIN_FFMPEG_MAJOR_VERSION}" | grep -oP 'Candidate: \K[^ ]+' | sed 's/^[0-9]\+://')
            else
                default_ffmpeg
                FFMPEG_VERSION=$(apt-cache policy ffmpeg | grep -oP 'Candidate: \K[^ ]+' | sed 's/^[0-9]\+://')
            fi
            ;;
    esac
    touch /usr/bin/share/ffmpeg_version
	echo "FFMPEG_VERSION=\"$FFMPEG_VERSION\"" > /usr/bin/share/ffmpeg_version
}

main