FROM hhcmhub/xbot2-noble-robot:v1.0.18

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
    cd recipes/multidof_recipes && git pull origin ros2 && \
    forest grow iit-kyon-ros-pkg xbot2_diagnostics

# source mounted kyon_config
RUN echo 'source ~/xbot2_ws/src/kyon_config/$CONFIG_PATH_DOCKER' >> ~/.bashrc

# realsense and Intel VAAPI runtime (needed by rtsp_image_transport's H.264 VAAPI encoder)
RUN sudo apt update && sudo apt install -y \
    ros-$ROS_DISTRO-realsense2-camera \
    ros-$ROS_DISTRO-rtsp-image-transport \
    intel-media-va-driver-non-free \
    vainfo
