SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ecat 
export ECAT_MASTER_CONFIG="$SCRIPT_DIR/../ecat/ecat_config.yaml"
alias ecat_master="repl -f $ECAT_MASTER_CONFIG"
alias ecat_master_gdb="gdb --args repl -f $ECAT_MASTER_CONFIG"

# generic
source $SCRIPT_DIR/generic_profile_docker.bash

# embedded cyclonedds config
export CYCLONEDDS_URI=file://$SCRIPT_DIR/../network/cyclone/cyclonedds-embedded.xml
