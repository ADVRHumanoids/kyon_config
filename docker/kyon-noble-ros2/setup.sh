kyon(){
    if [ -z "$1" ]
    then
        echo "No argument supplied" >&2
        return 1
    fi

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    cd $SCRIPT_DIR
    xhost +local:root
    if [ "$1" = "dev-intel-va" ]; then
        if [ ! -e /dev/dri/renderD128 ]; then
            echo "Intel DRM render node /dev/dri/renderD128 is not available" >&2
            return 1
        fi
        export RENDER_GID="$(stat -c '%g' /dev/dri/renderD128)"
    fi
    echo "Running docker image from $PWD..."
    docker compose up $1 -d --no-recreate
    docker compose exec $1 bash
}
