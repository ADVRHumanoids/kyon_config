SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ros2 middleware config
export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# cl config
export CONCERT_LAUNCHER_DEFAULT_CONFIG=$SCRIPT_DIR/../gui/launcher_config.yaml

# argcomplete
eval "$(register-python-argcomplete forest)"
eval "$(register-python-argcomplete concert_launcher)"
eval "$(register-python-argcomplete ecat)"

