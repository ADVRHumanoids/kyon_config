#!/bin/bash 

set -e

export USER_NAME=kyon_ros1
export KERNEL_VER=6
export USER_ID=1000

TAG=$(date '+%Y%m%d')
docker compose build 

docker tag kyon-cetc-focal-ros1-base hhcmhub/kyon-cetc-focal-ros1-base:latest
docker tag kyon-cetc-focal-ros1-base hhcmhub/kyon-cetc-focal-ros1-base:$TAG

docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno:latest
docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno:$TAG