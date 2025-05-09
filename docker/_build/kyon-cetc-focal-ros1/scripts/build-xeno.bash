set -e 

cd xbot2_ws
forest grow circulo9_xbot2_device -j8 -v -m xeno --clone-depth 1

# rm build to save space
rm -rf build
rm -rf src/xbot2 src/ec_xbot2_client src/circulo9_xbot2_device src/ecat_master