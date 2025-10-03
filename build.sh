#!/bin/bash
ARCH=$(uname -m | sed 's/x86_64/amd64/; s/aarch64/arm64/')

IMAGE_NAME="ros2_humble_multiarch"
CACHE_FLAG=""

for arg in "$@"; do
    if [ "$arg" = "--no-cache" ]; then
        CACHE_FLAG="--no-cache"
    else
        IMAGE_NAME="$arg"
    fi
done

sudo docker build \
    $CACHE_FLAG \
    --build-arg TARGETARCH=$ARCH \
    --build-arg UID=$(id -u) \
    --build-arg GID=$(id -g) \
    -t $IMAGE_NAME .