set -e 

# refresh apt registry
sudo apt update

# install forest
pip install hhcm-forest

# do the forest magic
mkdir xbot2_ws && cd xbot2_ws
forest init
source setup.bash
forest add-recipes git@github.com:advrhumanoids/multidof_recipes.git -t kyon-cetc-ros2
forest grow iit-kyon-ros-pkg -j8 -v
forest grow kyon_config -j8 -v
