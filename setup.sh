SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ecat 
export ECAT_MASTER_CONFIG="$SCRIPT_DIR/ecat/ecat_config.yaml"
alias ecat_master="repl -f $ECAT_MASTER_CONFIG"
alias ecat_master_gdb="gdb --args repl -f $ECAT_MASTER_CONFIG"

# concert launcher 
export CONCERT_LAUNCHER_DEFAULT_CONFIG=$SCRIPT_DIR/gui/ros1/launcher_config.yaml
