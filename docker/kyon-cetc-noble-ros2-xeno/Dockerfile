FROM hhcmhub/xbot2-noble-rt

ARG ROS_IP

# crash if ROS_IP is not set
RUN if [ -z "$ROS_IP" ]; then echo "ROS_IP is not set"; exit 1; fi

# setup ros2
RUN git clone https://github.com/advrhumanoids/ros2_config.git && \
    cd ros2_config && \
    mkdir build && cd build && \
    cmake .. -DROS2_IP=$ROS_IP 

# add robot config to bashrc
RUN echo 'source ~/xbot2_ws/src/kyon_config/$CONFIG_PATH_DOCKER' >> ~/.bashrc

# kyon specific packages
RUN cd xbot2_ws && \ 
    sudo chown user src && \ 
    forest grow iit-kyon-ros-pkg
