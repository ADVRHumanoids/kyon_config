#!/bin/bash 
set -e

export USER_NAME=kyon_ros2
export USER_ID=1000

export KERNEL_VER=5
docker compose build 
docker tag kyon-cetc-noble-ros2-base hhcmhub/kyon-cetc-noble-ros2-base:latest
docker tag kyon-cetc-noble-ros2-xeno hhcmhub/kyon-cetc-noble-ros2-xeno-v$KERNEL_VER:latest
# docker tag kyon-cetc-noble-ros2-locomotion hhcmhub/kyon-cetc-noble-ros2-locomotion:latest


export KERNEL_VER=6
docker compose build 
docker tag kyon-cetc-noble-ros2-xeno hhcmhub/kyon-cetc-noble-ros2-xeno-v$KERNEL_VER:latest

docker push hhcmhub/kyon-cetc-noble-ros2-base:latest
docker push hhcmhub/kyon-cetc-noble-ros2-xeno-v5:latest
docker push hhcmhub/kyon-cetc-noble-ros2-xeno-v6:latest
# docker push hhcmhub/kyon-cetc-noble-ros2-locomotion:latest