#!/bin/bash
set -e

# ecat master
concert_launcher run ecat

# xbot2
concert_launcher run xbot2

# ros ctrl
xbot2 plugin switch ros_control 1
sleep 1

# unpark
echo ">>> Unparking the robot"
process=unpark
concert_launcher run $process
sleep 5
while true; do
    status=$(concert_launcher status | awk -v proc="$process" '$1 == proc { print $4; exit }')

    if [[ "$status" == "DEAD" ]]; then
        echo "$process done"
        break
    fi

    echo ">>> Waiting for $process... current status: ${status:-NOT_FOUND}"
    sleep 5
done

# policy
echo ">>> Starting locomotion RL controller"
concert_launcher run loco_isaac
