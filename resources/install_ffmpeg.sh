#!/bin/bash
set -ex

FFMPEG_VERSION_URL="https://files.ispyconnect.com/libs/ffmpeg_version.txt"
FFMPEG_BASE_URL="https://files.ispyconnect.com/libs"
AGENTDVR_DIRECTORY="/AgentDVR"

# The un-suffixed folder name ffmpeg<version>/ is AgentDVR's GPL variant slot;
# the bundled LGPL build uses ffmpeg<version>-lgpl/. Agent searches only the
# folder matching the "Software Encoders (FFmpeg GPL)" setting, in the order
# persisted volume -> in-image copy -> system lib paths. This baked-in copy is
# the in-image GPL fallback, so users get GPL encoders without a runtime
# download. Do not rename or remove it, and keep FFMPEG_VERSION aligned with
# the version AgentDVR looks for or the folder will not be found.
ispy_ffmpeg() {
    echo "***** Installing iSpy prebuilt FFMPEG *****"

    # Resolve version, e.g. "8.1" — pinned by CI via build_data, else fetch live
    if [ -f /resources/build_data/FFMPEG_VERSION ]; then
        FFMPEG_VERSION="$(tr -d '[:space:]' < /resources/build_data/FFMPEG_VERSION)"
    fi
    if [ -z "${FFMPEG_VERSION:-}" ]; then
        FFMPEG_VERSION="$(curl -fsSL "${FFMPEG_VERSION_URL}" | tr -d '[:space:]')"
    fi
    if [ -z "${FFMPEG_VERSION}" ]; then
        echo "ERROR: failed to resolve FFMPEG version (build_data + ${FFMPEG_VERSION_URL})" >&2
        exit 1
    fi

    # Map runtime arch to iSpy tarball arch
    case "$(arch)" in
        'aarch64' | 'arm64')
            FFMPEG_ARCH='arm64'
            ;;
        'armv7l' | 'armv6l' | 'arm' | 'armhf')
            FFMPEG_ARCH='armhf'
            ;;
        'x86_64' | 'amd64')
            FFMPEG_ARCH='x86_64'
            ;;
        *)
            echo "ERROR: unsupported arch $(arch)" >&2
            exit 1
            ;;
    esac

    FFMPEG_TARBALL="ffmpeg${FFMPEG_VERSION}-linux-${FFMPEG_ARCH}.tar.xz"
    FFMPEG_URL="${FFMPEG_BASE_URL}/${FFMPEG_TARBALL}"
    FFMPEG_DEST="${AGENTDVR_DIRECTORY}/ffmpeg${FFMPEG_VERSION}"

    echo "***** Downloading ${FFMPEG_URL} *****"
    mkdir -p "${FFMPEG_DEST}"
    curl -fsSL "${FFMPEG_URL}" -o /tmp/ffmpeg.tar.xz

    echo "***** Extracting to ${FFMPEG_DEST} *****"
    # Tarball top-level is bin/ and lib/ -> ffmpeg<VER>/bin, ffmpeg<VER>/lib
    tar -vxJf /tmp/ffmpeg.tar.xz -C "${FFMPEG_DEST}"
    rm -vf /tmp/ffmpeg.tar.xz

    echo "**** iSpy FFMPEG installation completed (${FFMPEG_DEST}) ****"
}

main() {
    ispy_ffmpeg

    mkdir -p /usr/bin/share
    touch /usr/bin/share/ffmpeg_version
    echo "FFMPEG_VERSION=\"$FFMPEG_VERSION\"" > /usr/bin/share/ffmpeg_version
}

main
