SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros config
export ROS_IP=10.24.12.100
export ROS_MASTER_URI=http://$ROS_IP:11311

# enable ros1 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-cetc-focal-ros1-xeno/setup.sh