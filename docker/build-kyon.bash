#!/bin/bash
set -e

# Enhanced build script that supports different variants and configurations

# Parse command line arguments
BUILD_XENO=false
PUSH_IMAGES=false
PULL_IMAGES=false
CONFIG_TYPE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --xeno)
      BUILD_XENO=true
      shift
      ;;
    --push)
      PUSH_IMAGES=true
      shift
      ;;
    --pull)
      PULL_IMAGES=true
      shift
      ;;
    --ros1)
      CONFIG_TYPE="ros1"
      shift
      ;;
    --ros2)
      CONFIG_TYPE="ros2"
      shift
      ;;
    --help)
      echo "Usage: $0 [OPTIONS]"
      echo "Options:"
      echo "  --xeno     Build Xenomai (real-time) variant"
      echo "  --push     Push images to registry after building"
      echo "  --pull     Pull images instead of building"
      echo "  --ros1     Force ROS1 configuration"
      echo "  --ros2     Force ROS2 configuration"
      echo "  --help     Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Navigate to script directory for reliable relative path operations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Auto-detect configuration type if not specified
if [[ -z "$CONFIG_TYPE" ]]; then
  # Check if we have environment variable hints or default based on current environment
  if [[ -n "$ROS_VERSION" ]]; then
    CONFIG_TYPE="$ROS_VERSION"
fi

# Determine configuration file based on CONFIG_TYPE and BUILD_XENO
if [[ "$CONFIG_TYPE" == "ros2" ]]; then
  CONFIG_FILE="kyon-config_ros2.env"
  BUILD_DIR="../docker-base/robot-template/_build/robot-noble-ros2/"
else
  CONFIG_FILE="kyon-config_ros1.env"
  BUILD_DIR="../docker-base/robot-template/_build/robot-focal-ros1/"
fi

# Load Kyon-specific configuration into environment
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found!"
  exit 1
fi

echo "Loading configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Override TAGNAME if provided via environment (e.g., from GitHub Actions)
if [[ -n "$GITHUB_REF_NAME" ]]; then
  export TAGNAME="$GITHUB_REF_NAME"
  echo "Using tag from GitHub: $TAGNAME"
elif [[ -n "$TAG_OVERRIDE" ]]; then
  export TAGNAME="$TAG_OVERRIDE"
  echo "Using tag override: $TAGNAME"
fi

# Modify image naming for Xeno builds
if [[ "$BUILD_XENO" == "true" ]]; then
  if [[ "$CONFIG_TYPE" == "ros2" ]]; then
    export BASE_IMAGE_NAME="${BASE_IMAGE_NAME}-xeno-v${KERNEL_VER}"
  else
    export BASE_IMAGE_NAME="${BASE_IMAGE_NAME}-xeno-v${KERNEL_VER}"
  fi
  echo "Building Xenomai variant"
fi

# Display configuration for user verification
echo "=================================="
echo "Building kyon docker images with configuration:"
echo "  ROBOT_NAME: $ROBOT_NAME"
echo "  CONFIG_TYPE: $CONFIG_TYPE"
echo "  RECIPES_TAG: $RECIPES_TAG"
echo "  BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "  ROBOT_PACKAGES: $ROBOT_PACKAGES"
echo "  ADDITIONAL_PACKAGES: $ADDITIONAL_PACKAGES"
echo "  TAGNAME: $TAGNAME"
echo "  DOCKER_REGISTRY: $DOCKER_REGISTRY"
echo "  BUILD_XENO: $BUILD_XENO"
echo "  KERNEL_VER: $KERNEL_VER"
echo "=================================="

# Show what arguments are being passed to help with debugging
if [ $# -gt 0 ]; then
    echo "  REMAINING ARGUMENTS: $@"
else
    echo "  REMAINING ARGUMENTS: (none - using submodule defaults)"
fi

# Check if build directory exists
if [[ ! -d "$BUILD_DIR" ]]; then
  echo "Error: Build directory '$BUILD_DIR' not found!"
  echo "Make sure the docker-base submodule is properly initialized:"
  echo "  git submodule update --init --recursive"
  exit 1
fi

# Navigate to the submodule build directory
echo "Navigating to build directory: $BUILD_DIR"
cd "$BUILD_DIR"

# Prepare build arguments
BUILD_ARGS=""
if [[ "$PULL_IMAGES" == "true" ]]; then
  BUILD_ARGS="$BUILD_ARGS --pull"
fi
if [[ "$PUSH_IMAGES" == "true" ]]; then
  BUILD_ARGS="$BUILD_ARGS --push"
fi

# Execute the submodule build script with arguments
echo "Delegating to submodule build script..."
echo "Command: ./build.bash $BUILD_ARGS $@"

if [[ "$BUILD_XENO" == "true" ]]; then
  # For Xeno builds, we might need to call a different target or pass additional parameters
  # This depends on how your docker-base submodule handles Xeno builds
  echo "Building Xenomai-enabled images..."
  ./build.bash $BUILD_ARGS --variant=xeno "$@"
else
  ./build.bash $BUILD_ARGS "$@"
fi

echo "Build completed successfully!"

# Return to original directory
cd "$SCRIPT_DIR"

echo "Available images after build:"
docker images | grep "$DOCKER_REGISTRY/$ROBOT_NAME" || echo "No images found with prefix $DOCKER_REGISTRY/$ROBOT_NAME"