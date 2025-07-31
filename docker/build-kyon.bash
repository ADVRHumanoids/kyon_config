#!/bin/bash
set -e
# Parse command line arguments
CONFIG_TYPE=""
PUSH_IMAGES=false
PULL_IMAGES=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --ros1)
      CONFIG_TYPE="ros1"
      shift
      ;;
    --ros2)
      CONFIG_TYPE="ros2"
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
    --help)
      echo "Usage: $0 --ros1|--ros2 [OPTIONS]"
      echo ""
      echo "This script builds complete Docker image stacks for the Kyon robot."
      echo "All images in a stack (base, xeno, locomotion/sim) are built together"
      echo "to ensure consistency."
      echo ""
      echo "Required (choose one):"
      echo "  --ros1     Build all ROS1 images (focal: base, xeno, locomotion)"
      echo "  --ros2     Build all ROS2 images (noble: base, xeno, sim)"
      echo ""
      echo "Options:"
      echo "  --push     Push images to registry after building"
      echo "  --pull     Pull images from registry instead of building"
      echo "  --help     Show this help message"
      echo ""
      echo "Examples:"
      echo "  $0 --ros1              # Build all ROS1 images locally"
      echo "  $0 --ros2 --push       # Build and push all ROS2 images"
      echo "  $0 --ros1 --pull       # Pull pre-built ROS1 images"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate that a ROS version was specified
if [[ -z "$CONFIG_TYPE" ]]; then
  echo "Error: You must specify either --ros1 or --ros2"
  echo "Use --help for usage information"
  exit 1
fi

# Navigate to script directory to ensure relative paths work correctly
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Determine configuration file and build directory based on ROS version
# Each ROS version has its own environment configuration and build location
if [[ "$CONFIG_TYPE" == "ros2" ]]; then
  CONFIG_FILE="kyon-config_ros2.env"
  BUILD_DIR="../docker-base/robot-template/_build/robot-noble-ros2/"
  IMAGE_SET="base, xeno, sim"
else
  CONFIG_FILE="kyon-config_ros1.env"
  BUILD_DIR="../docker-base/robot-template/_build/robot-focal-ros1/"
  IMAGE_SET="base, xeno, locomotion"
fi

# Load the robot-specific configuration
# This file contains all the parameters like ROBOT_NAME, TAGNAME, etc.
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "Error: Configuration file '$CONFIG_FILE' not found!"
  echo "Make sure you're running this script from the docker/ directory"
  exit 1
fi

echo "Loading configuration from: $CONFIG_FILE"
source "$CONFIG_FILE"

# Allow tag override from environment (useful for CI/CD)
# Priority: TAGNAME from env < GITHUB_REF_NAME config file default
if [[ -n "$GITHUB_REF_NAME" ]]; then
  export TAGNAME="$GITHUB_REF_NAME"
  echo "Using tag from GitHub: $TAGNAME"
fi

# Display the build configuration for transparency
# This helps users verify they're building with the correct settings
echo ""
echo "=================================="
echo "Kyon Docker Build Configuration"
echo "=================================="
echo "  ROS Version: ${CONFIG_TYPE^^}"
echo "  Image Set: ${IMAGE_SET}"
echo "  Robot Name: $ROBOT_NAME"
echo "  Recipe Tag: $RECIPES_TAG"
echo "  Base Image: $BASE_IMAGE_NAME"
echo "  Docker Tag: $TAGNAME"
echo "  Registry: $DOCKER_REGISTRY"
echo "  Packages: $ROBOT_PACKAGES"
if [[ -n "$ADDITIONAL_PACKAGES" ]]; then
  echo "  Additional: $ADDITIONAL_PACKAGES"
fi
echo "=================================="
echo ""

# Verify the docker-base submodule is properly initialized
if [[ ! -d "$BUILD_DIR" ]]; then
  echo "Error: Build directory '$BUILD_DIR' not found!"
  echo ""
  echo "This usually means the docker-base submodule isn't initialized."
  echo "To fix this, run:"
  echo "  git submodule update --init --recursive"
  echo ""
  echo "Then try building again."
  exit 1
fi

# Navigate to the submodule build directory
echo "Navigating to build directory: $BUILD_DIR"
cd "$BUILD_DIR"

# Prepare arguments for the generic build script
BUILD_ARGS=""
if [[ "$PULL_IMAGES" == "true" ]]; then
  BUILD_ARGS="$BUILD_ARGS --pull"
fi
if [[ "$PUSH_IMAGES" == "true" ]]; then
  BUILD_ARGS="$BUILD_ARGS --push"
fi

# Execute the generic build script
# This script will find all Dockerfiles in the directory and build them
echo "Starting Docker build process..."
echo "Executing: ./build.bash $BUILD_ARGS"
echo ""

# Run the build and capture the exit code
./build.bash $BUILD_ARGS
BUILD_EXIT_CODE=$?

# Return to original directory
cd "$SCRIPT_DIR"

# Check if build was successful
if [[ $BUILD_EXIT_CODE -ne 0 ]]; then
  echo ""
  echo "Error: Build failed with exit code $BUILD_EXIT_CODE"
  exit $BUILD_EXIT_CODE
fi

echo ""
echo "Build completed successfully!"
echo ""

# Show a summary of what should now be available
echo "Expected images for ${CONFIG_TYPE^^}:"
if [[ "$CONFIG_TYPE" == "ros1" ]]; then
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:${TAGNAME}"
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v${KERNEL_VER}:${TAGNAME}"
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-locomotion:${TAGNAME}"
else
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-base:${TAGNAME}"
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-xeno-v${KERNEL_VER}:${TAGNAME}"
  echo "  - ${DOCKER_REGISTRY}/${BASE_IMAGE_NAME}-sim:${TAGNAME}"
fi

echo ""
echo "Verifying images exist locally:"
# Show actual images that match our pattern
docker images | grep "$DOCKER_REGISTRY/$ROBOT_NAME" | grep "$TAGNAME" || {
  echo "Warning: No images found matching expected pattern."
  echo "This might indicate a build problem or different naming convention."
}

# Provide next steps based on what the user did
echo ""
if [[ "$PUSH_IMAGES" == "true" ]]; then
  echo "✓ Images have been built and pushed to $DOCKER_REGISTRY"
  echo "  Other systems can now pull these images using --pull"
elif [[ "$PULL_IMAGES" == "true" ]]; then
  echo "✓ Images have been pulled from $DOCKER_REGISTRY"
  echo "  You can now use these images in your runtime environment"
else
  echo "✓ Images have been built locally"
  echo "  Use --push to upload them to the registry"
  echo "  Use the runtime scripts in docker/kyon-cetc-*/ to run containers"
fi
