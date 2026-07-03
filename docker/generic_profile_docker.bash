
## ros2 middleware config

# source ~/ros2_config/dds/cyclonedds/setup.bash
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST
export ROS_STATIC_PEERS="10.24.15.100;10.24.15.101;10.24.15.102"