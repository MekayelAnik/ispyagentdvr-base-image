#!/bin/bash
REPO_NAME='ispyagentdvr-base-image'
echo -e '# Use DEBIAN AS BASE-IMAGE' > ./"Dockerfile.$REPO_NAME"
echo "$(cat "./resources/build_data/BASE_IMAGE")"
if [ -e ./resources/build_data/BASE_IMAGE ]; then
  BASE_IMAGE=$(cat "./resources/build_data/BASE_IMAGE")
  BASE_IMAGE="FROM debian:${BASE_IMAGE}"
else
  echo "Could not found Base Image to build Image on. Exitting..."
  exit 1
fi
echo -e "$BASE_IMAGE" >> ./"Dockerfile.$REPO_NAME"
echo -e 'ARG TZ="Asia/Dhaka"
# https://askubuntu.com/questions/972516/debian-frontend-environment-variable
ARG DEBIAN_FRONTEND="noninteractive"
# http://stackoverflow.com/questions/48162574/ddg#49462622
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="DontWarn"
LABEL maintainer="MUHAMMAD MEKAYEL ANIK"' >> ./"Dockerfile.$REPO_NAME"
if [ -e ./resources/build_data/JELLYFIN_FFMPEG_VERSION ]; then
    echo -e 'LABEL idea_credit="Jellyfin & Linuxserver.io"' >> ./"Dockerfile.$REPO_NAME"
    echo -e "LABEL FFMPEG_VERSION='$(cat ./resources/build_data/JELLYFIN_FFMPEG_VERSION)'" >> ./"Dockerfile.$REPO_NAME"
fi
echo -e '# https://github.com/NVIDIA/nvidia-docker/wiki/Installation-(Native-GPU-Support)
ENV \
  NVIDIA_DRIVER_CAPABILITIES="compute,video,utility" \
  NVIDIA_VISIBLE_DEVICES="all"
# Add all the ingredienes
ADD --chmod=555 ./resources /resources
RUN bash /resources/setup.sh
RUN \
echo "**** Final Clean Up ****" && \
  rm -vrf \
  /resources \
  /var/lib/apt/lists/* \
  /var/tmp/*' >> ./"Dockerfile.$REPO_NAME"
echo "Dockerfile generation completed!"
echo "######      DOCKERFILE START     ######"
cat ./"Dockerfile.$REPO_NAME"
echo "######      DOCKERFILE END     ######"