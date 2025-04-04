#!/bin/bash 

set -e

export USER_NAME=kyon_ros2
export KERNEL_VER=6
export USER_ID=1000

TAG=$(date '+%Y%m%d')
docker compose build 

docker tag kyon-cetc-noble-ros2-base hhcmhub/kyon-cetc-noble-ros2-base:latest
#docker tag kyon-cetc-noble-ros2-base hhcmhub/kyon-cetc-noble-ros2-base:$TAG

docker tag kyon-cetc-noble-ros2-xeno hhcmhub/kyon-cetc-noble-ros2-xeno-v$KERNEL_VER:latest
#docker tag kyon-cetc-noble-ros2-xeno hhcmhub/kyon-cetc-noble-ros2-xeno:$TAG

docker tag kyon-cetc-noble-ros2-sim hhcmhub/kyon-cetc-noble-ros2-sim:latest
#docker tag kyon-cetc-noble-ros2-sim hhcmhub/kyon-cetc-noble-ros2-sim:$TAG
