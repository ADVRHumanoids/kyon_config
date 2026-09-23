SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros config
export ROS_IP=10.24.15.101
export ROS_MASTER_URI=http://$ROS_IP:11311

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-noble-ros2-jetpack-r36.5/setup.sh

# config path
export CONFIG_PATH_DOCKER=docker/vision_profile_docker.bash

# set concert launcher output folder
export CONCERT_LAUNCHER_STDOUT_PATH=/var/log/concert_launcher