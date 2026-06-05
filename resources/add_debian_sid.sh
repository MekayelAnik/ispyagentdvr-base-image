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
# Keep sid at low priority. The VAAPI driver stack is installed from trixie
# (one coherent release); sid is only here so an explicit `-t sid` can pull a
# newer libc6/openssl than trixie ships. Pinning sid low prevents it from
# bleeding into the rest of the install.
cat <<EOF | tee /etc/apt/preferences.d/sid-pinning
Package: *
Pin: release a=unstable
Pin-Priority: 100
EOF

apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update