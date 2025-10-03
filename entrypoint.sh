#!/bin/bash
set -e

# Source ROS2 setup script
source /opt/ros/humble/setup.bash

cd /ros2_ws
colcon build
source install/setup.bash

# Execute the command
exec "$@"