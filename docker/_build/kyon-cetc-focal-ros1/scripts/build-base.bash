set -e 

# refresh apt registry
sudo apt update

# upgrade pip protobuf
pip install -U protobuf

# do the forest magic
mkdir xbot2_ws && cd xbot2_ws
forest init
source setup.bash
forest add-recipes git@github.com:advrhumanoids/multidof_recipes.git -t kyon-cetc
forest grow iit-kyon-ros-pkg -j8 -v
forest grow kyon_config -j8 -v
forest grow xbot2_gui_server
forest grow vectornav -j8
forest grow xbot2_cli -j8
forest grow pybind11
forest grow centauro_cartesio -j8
forest grow xbot2_tools -j8
forest grow pybind11
forest grow cartesio_collision_support -j8
forest grow hesai_ros_driver -j8

# rm build to save space
rm -rf build