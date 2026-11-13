#!/bin/bash
MEDIAMTX_DIR=/home/user/ros2_ws/src/network_bridge/mediamtx
"$MEDIAMTX_DIR/mediamtx" "/home/user/ros2_ws/src/kyon_config/data/perception/mediamtx.yml" >> /tmp/mediamtx.log 2>&1 &
exec "$@"
