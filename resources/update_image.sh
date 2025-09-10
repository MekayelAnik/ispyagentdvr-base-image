#!/bin/bash

# Exit on error and print each command for debugging
set -ex

echo "**** Upgrading Base Image ****"
apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update

echo "Upgrading Debian:"
DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y