#!/bin/bash 
set -e

export USER_NAME=kyon_ros1
export USER_ID=1000
export KERNEL_VER=5

TAGNAME=v1.0.0
docker compose build
docker tag kyon-cetc-focal-ros1-base hhcmhub/kyon-cetc-focal-ros1-base:$TAGNAME
docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:$TAGNAME
docker tag kyon-cetc-focal-ros1-locomotion hhcmhub/kyon-cetc-focal-ros1-locomotion:$TAGNAME


# export KERNEL_VER=6
# docker compose build 
# docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:$TAGNAME
# docker push hhcmhub/kyon-cetc-focal-ros1-xeno-v6:latest

docker push hhcmhub/kyon-cetc-focal-ros1-base:$TAGNAME
docker push hhcmhub/kyon-cetc-focal-ros1-xeno-v5:$TAGNAME
docker push hhcmhub/kyon-cetc-focal-ros1-locomotion:$TAGNAME
