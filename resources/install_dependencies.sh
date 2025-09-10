#!/bin/bash

# Exit on error and print each command for debugging
set -ex

echo "**** Installing Dependencies ****"
# Install packages non-interactively with minimal recommendations
DEBIAN_FRONTEND=noninteractive apt-get update && \
apt-get install -y --no-install-recommends --no-install-suggests \
    sudo \
    gosu \
    libicu-dev \
    ncurses-bin \
    alsa-utils \
    curl \
    rsync \
    unzip \
    wget \
    openssl \
    gnupg \
    ca-certificates \
    locales \
    tzdata \
    libgdiplus \
    g++ \
    gcc \
    adduser