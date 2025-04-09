SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# kernel version
export KERNEL_VER=$(uname -r | cut -d '.' -f 1)

# ros config
export ROS_IP=10.24.12.100
export ROS_MASTER_URI=http://$ROS_IP:11311

# enable ros1 and ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-cetc-focal-ros1-xeno/setup.sh
source $SCRIPT_DIR/../docker/kyon-cetc-noble-ros2-xeno/setup.sh