set -e 


# build required software (requires valid netrc for auth)
sudo apt-get update && apt-get install -y sudo build-essential gfortran \
    git curl python3-tk python3-pip libjpeg-dev wget patchelf nano libglfw3-devsudo apt-get install -y libassimp-dev liblapack-dev libblas-dev libyaml-cpp-dev libmatio-dev libgfortran10-dev
# required for casadi python bindings
# sudo apt-get install -y swig
# # clang to generate mpc functions in c++
# sudo apt-get install -y clang
# # Install ROS catkin tools
# sudo apt-get install -y ros-noetic-catkin
# # install joy
# sudo apt-get install -y ros-noetic-joy
# # install graphviz-dev for horizon urdf modifier
# sudo apt-get install -y graphviz-dev


# # Upgrade pip and install the latest version of NumPy 
# # only required for ROS noetic
# pip3 install --upgrade pip \
#     && pip3 install --upgrade numpy \
#     && pip3 install --upgrade scipy \
    
# # required packages
# sudo pip3 install numpy_ros matplotlib
# sudo pip3 install colorama Cython networkx pygraphviz

# # grow
# cd xbot2_ws
# forest grow kyon_controller -j8 -v

