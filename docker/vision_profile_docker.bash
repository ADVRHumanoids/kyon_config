SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# generic
source $SCRIPT_DIR/generic_profile_docker.bash

# vision cyclonedds config
export CYCLONEDDS_URI=file://$SCRIPT_DIR/../network/cyclone/cyclonedds-vision.xml
