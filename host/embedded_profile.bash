SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# kernel version
export KERNEL_VER=$(uname -r | cut -d '.' -f 1)

# ros config
export ROS_IP=10.24.15.100
export ROS_MASTER_URI=http://$ROS_IP:11311

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-cetc-noble-ros2-xeno/setup.sh

# config path
export CONFIG_PATH_DOCKER=docker/embedded_profile_docker.bash