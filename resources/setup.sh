#!/bin/bash

# Exit on error and print each command for debugging
set -ex

touch /etc/profile.d/env_vars.sh

arch=$(uname -m)
VERSION_OS=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
VERSION_CODENAME=$(grep '^VERSION_CODENAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
DPKG_ARCHITECTURE="$(dpkg --print-architecture)"

echo "export arch=\"$arch\"" > /etc/profile.d/env_vars.sh
echo "export VERSION_OS=\"$VERSION_OS\"" >> /etc/profile.d/env_vars.sh
echo "export VERSION_CODENAME=\"$VERSION_CODENAME\"" >> /etc/profile.d/env_vars.sh
echo "export DPKG_ARCHITECTURE=\"$DPKG_ARCHITECTURE\"" >> /etc/profile.d/env_vars.sh

chmod +x /etc/profile.d/env_vars.sh

mkdir -p /usr/bin/share

mv -vf /resources/build_data/base-image-timestamp /usr/bin/share/

bash -c "source /etc/profile.d/env_vars.sh && source /resources/update_image.sh"

bash -c "source /etc/profile.d/env_vars.sh && /resources/install_dependencies.sh"

bash -c "source /etc/profile.d/env_vars.sh && /resources/install_gpu_driver.sh"

# FFmpeg is no longer installed here: the AgentDVR package bundles its own
# FFmpeg (LGPL) build, and the optional GPL build is downloaded by the app
# at runtime to the persisted config volume.

if [ -f /resources/build_data/vlc ]; then
	bash -c "/resources/install_vlc.sh"
fi

bash -c "/resources/cleanup.sh"

echo "****		Completed Setup Procedure		****"
