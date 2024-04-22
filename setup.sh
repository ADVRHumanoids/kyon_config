SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

export ECAT_MASTER_CONFIG="$SCRIPT_DIR/ecat/ecat_config.yaml"
#export ROS_PACKAGE_PATH=$SCRIPT_DIR:$ROS_PACKAGE_PATH
#alias ecat_master="stdbuf --output=L --error=L repl -f $ECAT_MASTER_CONFIG 2>&1 | tee /tmp/ecat-output"
alias ecat_master="repl -f $ECAT_MASTER_CONFIG"
alias ecat_master_gdb="gdb --args repl -f $ECAT_MASTER_CONFIG"
