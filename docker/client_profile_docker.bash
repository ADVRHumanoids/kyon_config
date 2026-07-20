SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros2 middleware config
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# specific ros domain id for clients to avoid any overlap with the local ros2 network
export ROS_DOMAIN_ID=42

# configure ros automatic discovery range to localhost only, to avoid any overlap with the robot's lan
export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST