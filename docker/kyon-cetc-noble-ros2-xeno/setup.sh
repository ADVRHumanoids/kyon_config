ros2(){
    if [ -z "$1" ]
    then
        echo "No argument supplied" >&2
        return 1
    fi

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    cd $SCRIPT_DIR
    xhost +local:root
    echo "Running docker image from $PWD..."
    docker compose up $1 -d --no-recreate
    docker compose exec $1 bash
}
