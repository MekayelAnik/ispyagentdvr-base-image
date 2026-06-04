#!/bin/bash

# Exit on error and print each command for debugging
set -ex

echo "**** Adding SID Repository ****"
cat <<EOF | tee /etc/apt/sources.list.d/sid.sources
Types: deb deb-src
URIs: http://deb.debian.org/${VERSION_OS}
Suites: sid
Components: main contrib non-free non-free-firmware
Architectures: ${DPKG_ARCHITECTURE}
Enabled: yes
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

mkdir -p /etc/apt/preferences.d
# Pin priority is arch-scoped:
#  - amd64: sid pinned ABOVE trixie (default 500) so the tightly-coupled
#    graphics stack (mesa-va-drivers, mesa-libgallium, libglx-mesa0,
#    libgl1, libva2, iHD/libigdgmm12) resolves coherently from sid as one
#    set. At priority 100 only -t sid named packages came from sid while
#    their transitive deps stayed at trixie, shearing the mesa version and
#    breaking the build.
#  - arm64/armv7: kept low (100) so those builds stay trixie-native; they
#    have no libva-2.23/iHD requirement and must not be dragged into sid.
case "$(dpkg --print-architecture)" in
    amd64) SID_PRIORITY=990 ;;
    *)     SID_PRIORITY=100 ;;
esac
cat <<EOF | tee /etc/apt/preferences.d/sid-pinning
Package: *
Pin: release a=unstable
Pin-Priority: ${SID_PRIORITY}
EOF

apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update