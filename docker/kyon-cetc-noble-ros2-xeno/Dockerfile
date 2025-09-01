FROM hhcmhub/kyon-cetc-noble-ros2-xeno-v5:master

ARG ROS_IP=localhost

RUN git clone https://github.com/advrhumanoids/ros2_config.git && \
    cd ros2_config && \
    mkdir build && cd build && \
    cmake .. -DROS2_IP=$ROS_IP 

RUN echo source ~/ros2_config/dds/cyclonedds/setup.bash >> ~/.bashrc     

