#!/bin/bash 
set -e

export USER_NAME=kyon_ros1
export USER_ID=1000

export KERNEL_VER=5
docker compose build 
docker tag kyon-cetc-focal-ros1-base hhcmhub/kyon-cetc-focal-ros1-base:latest
docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:latest
docker tag kyon-cetc-focal-ros1-locomotion hhcmhub/kyon-cetc-focal-ros1-locomotion:latest


export KERNEL_VER=6
docker compose build 
docker tag kyon-cetc-focal-ros1-xeno hhcmhub/kyon-cetc-focal-ros1-xeno-v$KERNEL_VER:latest

docker push hhcmhub/kyon-cetc-focal-ros1-base:latest
docker push hhcmhub/kyon-cetc-focal-ros1-xeno-v5:latest
docker push hhcmhub/kyon-cetc-focal-ros1-xeno-v6:latest
docker push hhcmhub/kyon-cetc-focal-ros1-locomotion:latest