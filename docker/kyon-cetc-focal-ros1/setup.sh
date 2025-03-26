ros1(){
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    cd $SCRIPT_DIR
    xhost +local:root
    echo "Running docker image from $PWD..."
    docker compose up dev -d --no-recreate
    docker compose exec dev bash
}
