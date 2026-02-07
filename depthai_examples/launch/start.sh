#!/bin/bash

shell_path=$(cd $(dirname $0);pwd)
cd ${shell_path}

source /userdata/jazzy_aarch64/local_setup.bash

export ROS_LOG_DIR=/userlog/logs

source ${shell_path}/local_setup.bash

ros2 launch depthai_examples stereo_imu.launch.py  > /userlog/depthai.log &

wait