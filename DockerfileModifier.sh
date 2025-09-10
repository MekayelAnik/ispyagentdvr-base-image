#!/bin/bash

# Exit on error and print each command for debugging
set -ex

# Set variables first
REPO_NAME='ispyagentdvr-base-image'
DOCKERFILE_NAME="Dockerfile.$REPO_NAME"
# Check for base image file
if [ -e ./resources/build_data/BASE_IMAGE ]; then
  BASE_IMAGE=$(cat "./resources/build_data/BASE_IMAGE")
  BASE_IMAGE="FROM debian:${BASE_IMAGE}"
else
  echo "Could not find Base Image to build Image on. Exiting..."
  exit 1
fi

# Create a temporary file safely
TEMP_FILE=$(mktemp "${DOCKERFILE_NAME}.XXXXXX") || {
    echo "Error creating temporary file" >&2
    exit 1
}

# Write the Dockerfile content to the temporary file
{
    echo "# Using DEBIAN AS BASE-IMAGE"
    echo "$BASE_IMAGE"
    cat << 'EOF'
ARG TZ="Asia/Dhaka"
# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND="noninteractive"
# http://stackoverflow.com/questions/48162574/ddg#49462622
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"
LABEL maintainer="MOHAMMAD MEKAYEL ANIK"
EOF

    cat << 'EOF'
# https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(Native-GPU-Support)
ENV \
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all"
# Add all the ingredients
ADD --chmod=555 ./resources /resources

RUN bash /resources/setup.sh

RUN \
echo "**** Final Clean Up ****" && \
  rm -vrf \
  /resources \
  /var/lib/apt/lists/* \
  /var/tmp/*
EOF
} > "$TEMP_FILE"

# Atomically replace the target file with the temporary file
if mv -f "$TEMP_FILE" "$DOCKERFILE_NAME"; then
    echo "Dockerfile generation completed!"
    echo "######      DOCKERFILE START     ######"
    cat "$DOCKERFILE_NAME"
    echo "######      DOCKERFILE END     ######"
else
    echo "Error: Failed to create Dockerfile for $REPO_NAME" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi