FROM ros:jazzy-ros-base

ARG USER_ID
ARG ROS_IP
# ARG, not ENV: keeps noninteractive out of the runtime environment
ARG DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

# ---------------------------------------------------------------- build args
RUN test -n "$USER_ID" || { echo "USER_ID build arg is required" >&2; exit 1; }; \
    test -n "$ROS_IP"  || { echo "ROS_IP build arg is required"  >&2; exit 1; }

# ---------------------------------------------------------------- base system
# removing docker-clean keeps the apt lists, needed for apt autocompletion
RUN rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
      sudo ca-certificates curl wget gnupg gnupg2 lsb-release && \
    rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------- packages
# NVIDIA GStreamer plugins are NOT installed here: the nvidia runtime mounts
# them from the host. kmod is required or nvv4l2*enc misdetects the platform.
RUN apt-get update && apt-get install -y \
      ros-$ROS_DISTRO-desktop \
      ros-$ROS_DISTRO-rmw-cyclonedds-cpp \
      libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
      gstreamer1.0-tools gstreamer1.0-plugins-base gstreamer1.0-plugins-good \
      gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly \
      libboost-all-dev libboost-test-dev libboost-filesystem-dev \
      libboost-timer-dev libboost-tools-dev libzmq3-dev \
      build-essential cmake cmake-curses-gui clang gdb \
      git openssh-client \
      vim neovim tmux bash-completion \
      python3-venv python3-pip \
      libxcb-cursor-dev kmod file locate && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------- shell setup
# /etc/bash.bashrc and /etc/tmux.conf are system-wide: write them while root
RUN echo "alias vim=nvim" >> /etc/bash.bashrc && \
    echo '[ -n "$CONFIG_PATH_DOCKER" ] && source ~/xbot2_ws/src/kyon_config/$CONFIG_PATH_DOCKER' \
      >> /etc/bash.bashrc && \
    touch /etc/modules

RUN cat >> /etc/tmux.conf <<'EOF'
bind-key k kill-session
set -g mouse on
set -g window-status-current-style "bg=brightyellow,fg=black"
EOF

# ---------------------------------------------------------------- user
# Ubuntu 24.04 ships a 'ubuntu' user at uid 1000, which collides with USER_ID
RUN userdel -r ubuntu 2>/dev/null || true; \
    useradd -u ${USER_ID} -ms /bin/bash user && \
    usermod -aG sudo,dialout,video,plugdev user && \
    echo 'user:user' | chpasswd && \
    echo 'user ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/user && \
    chmod 0440 /etc/sudoers.d/user

USER user
WORKDIR /home/user

# ---------------------------------------------------------------- environment
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp
# required by the nvidia container runtime in csv mode
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc && \
    echo "source ~/env/bin/activate"              >> ~/.bashrc

# ---------------------------------------------------------------- python venv
RUN python3 -m venv --system-site-packages ~/env && \
    source ~/env/bin/activate && \
    pip install --no-cache-dir setuptools hhcm-forest && \
    python3 -c "from importlib.metadata import version; from packaging.version import Version; \
v = version('hhcm-forest'); assert Version(v) >= Version('1.1.23'), f'hhcm-forest {v} < 1.1.23'"

# ---------------------------------------------------------------- ros2 config
RUN git clone https://github.com/advrhumanoids/ros2_config.git ~/ros2_config && \
    cmake -S ~/ros2_config -B ~/ros2_config/build -DROS2_IP=$ROS_IP

# ---------------------------------------------------------------- workspace
RUN source ~/env/bin/activate && \
    mkdir -p ~/ros2_ws && cd ~/ros2_ws && forest init && \
    echo "source ~/ros2_ws/setup.bash" >> ~/.bashrc && forest add-recipes https://github.com/ADVRHumanoids/multidof_recipes.git --tag ros2

WORKDIR /home/user/ros2_ws
CMD ["/bin/bash"]
