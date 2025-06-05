#!/bin/bash 
set -e

# Load configuration
if [ -f build.env ]; then
    source build.env
fi

# Use the variables with defaults
export USER_NAME=${DOCKER_USER_NAME:-robot_user}
export USER_ID=${DOCKER_USER_ID:-1000}
export KERNEL_VER=${KERNEL_VER:-5}
export IMAGE_PREFIX=${IMAGE_PREFIX:-hhcmhub/robot}

TAGNAME=${TAGNAME:-v1.0.0}

docker compose build
docker tag kyon-cetc-focal-ros1-base hhcmhub/kyon-cetc-focal-ros1-base:$TAGNAME
docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:$TAGNAME
docker tag kyon-cetc-focal-ros1-locomotion hhcmhub/kyon-cetc-focal-ros1-locomotion:$TAGNAME


# export KERNEL_VER=6
# docker compose build 
# docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:$TAGNAME
# docker push hhcmhub/kyon-cetc-focal-ros1-xeno-v6:latest

docker push ${IMAGE_PREFIX}-focal-ros1-base:$TAGNAME
docker push ${IMAGE_PREFIX}-focal-ros1-xeno-v$KERNEL_VER:$TAGNAME
docker push ${IMAGE_PREFIX}-focal-ros1-locomotion:$TAGNAME