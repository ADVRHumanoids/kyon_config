SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# ssh aliases
alias ssh_embedded='ssh embedded@amax-kyon-iit'
alias ssh_control='ssh kyon@kyon-control'

# enable ros2 alias to login into docker container
source $SCRIPT_DIR/../docker/kyon-noble-ros2/setup.sh

# configure zenoh bridge to connect to the robot ip
export ZENOH_BRIDGE_ARGS="-e tcp/10.24.15.102:7447"

# specific ros domain id for clients to avoid any overlap with the local ros2 network
export ROS_DOMAIN_ID=42

# configure ros automatic discovery range to localhost only, to avoid any overlap with the robot's lan
export ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST

# connect to the robot's vpn via wireguard
function kyon_connect_wg() {
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    $SCRIPT_DIR/../network/wg/connect-wg.bash "$@"
}

# enable zenoh bridge 
function kyon_connect_zenoh() {
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    cd $SCRIPT_DIR/../docker/kyon-noble-ros2 
    docker compose up -d zenoh_bridge_client
}

# do it all
function kyon_connect() {
    kyon_connect_wg "$@"
    kyon_connect_zenoh
}