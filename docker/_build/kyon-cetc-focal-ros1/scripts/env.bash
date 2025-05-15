export PATH=~/.local/bin:$PATH

source /opt/ros/noetic/setup.bash
source /opt/xbot/setup.sh
source ~/xbot2_ws/setup.bash    
source ~/xbot2_ws/src/kyon_config/setup.sh

eval "$(register-python-argcomplete ecat)"
eval "$(register-python-argcomplete forest)"
eval "$(register-python-argcomplete concert_laucher)"

export PS1="${CUSTOM_PS}${PS1}"