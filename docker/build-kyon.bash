#!/bin/bash
set -e

# Simple but powerful wrapper script that combines kyon configuration
# with full passthrough of arguments to the submodule build system

# Navigate to script directory for reliable relative path operations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# Load Kyon-specific configuration into environment
# This makes all Kyon configuration available to the submodule script
source kyon-config_ros1.env

# Display configuration for user verification
# This helps users confirm their environment is set up correctly
echo "Building kyon docker images with configuration:"
echo "  ROBOT_NAME: $ROBOT_NAME"
echo "  RECIPES_TAG: $RECIPES_TAG"
echo "  BASE_IMAGE_NAME: $BASE_IMAGE_NAME"
echo "  ROBOT_PACKAGES: $ROBOT_PACKAGES"      # Add this line
echo "  ADDITIONAL_PACKAGES: $ADDITIONAL_PACKAGES"  # Add this line
# Show what arguments are being passed to help with debugging
if [ $# -gt 0 ]; then
    echo "  ARGUMENTS: $@"
else
    echo "  ARGUMENTS: (none - using submodule defaults)"
fi

# Navigate to the submodule build directory
cd ../docker-base/robot-template/_build/robot-focal-ros1/

# Execute the submodule build script with ALL arguments passed through
# The "$@" variable expands to all command-line arguments exactly as received
# This preserves argument quoting, spacing, and special characters
echo "Delegating to submodule build script..."
./build.bash "$@"

# Note: Any arguments you pass to this script (like --push, --pull, --help)
# will be automatically forwarded to the submodule's build.bash script
# This means your wrapper inherits all the capabilities of the submodule