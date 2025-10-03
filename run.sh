#!/bin/bash

# Validate arguments
if [ -z "$1" ]; then
    echo "Usage: ./run.sh <container_name> [image_name]"
    echo "Example: ./run.sh my_robot"
    echo "Example: ./run.sh my_robot my_custom_image"
    exit 1
fi

CONTAINER_NAME=$1
IMAGE_NAME="${2:-ros2_humble_multiarch}"

# Allow X11 connections
xhost +local:docker

sudo docker run \
	--rm -it \
	--name $CONTAINER_NAME \
    -v /run/udev:/run/udev:ro \
    -v /dev/bus/usb:/dev/bus/usb \
    -v /dev:/dev \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v $HOME/.Xauthority:/home/rosuser/.Xauthority:rw \
    -e XAUTHORITY=/home/rosuser/.Xauthority \
    -e DISPLAY=$DISPLAY \
    --privileged \
    --network=host \
    -v $(pwd)/ros2_ws:/ros2_ws \
	$IMAGE_NAME

# Restore X11 security
xhost -local:docker