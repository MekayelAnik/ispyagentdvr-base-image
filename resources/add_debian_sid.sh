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
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update