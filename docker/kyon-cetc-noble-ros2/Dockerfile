FROM hhcmhub/xbot2-noble-robot

ARG ROS_IP

# crash if ROS_IP is not set
RUN if [ -z "$ROS_IP" ]; then echo "ROS_IP is not set"; exit 1; fi

# setup ros2
RUN git clone https://github.com/advrhumanoids/ros2_config.git && \
    cd ros2_config && \
    mkdir build && cd build && \
    cmake .. -DROS2_IP=$ROS_IP 

# kyon specific packages
RUN cd xbot2_ws && \ 
    sudo chown user src && \ 
    forest grow iit-kyon-ros-pkg  

# source mounted kyon_config
RUN echo 'source ~/xbot2_ws/src/kyon_config/$CONFIG_PATH_DOCKER' >> ~/.bashrc

# realsense
RUN sudo apt update && sudo apt install -y ros-$ROS_DISTRO-realsense2-camera