SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros config
export ROS_IP=10.24.13.102
export ROS_MASTER_URI=http://10.24.12.100:11311

# enable ros1 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-cetc-focal-ros1/setup.sh
source $SCRIPT_DIR/../docker/kyon-cetc-noble-ros2/setup.sh