# File: docker/build-kyon.bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Source kyon-specific configuration
source kyon-config_ros1.env

echo "Building Kyon docker images with configuration:"
echo "  ROBOT_NAME: $ROBOT_NAME"
echo "  RECIPES_TAG: $RECIPES_TAG"
echo "  BASE_IMAGE_NAME: $BASE_IMAGE_NAME"

# Use the generalized build from submodule
cd ../docker-base/robot-template/_build/robot-focal-ros1/
./build.bash