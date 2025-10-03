##############################
# Base Image Setup
###############################

ARG TARGETARCH
FROM --platform=linux/amd64 osrf/ros:humble-desktop-full AS base-amd64
FROM --platform=linux/arm64 arm64v8/ros:humble AS base-arm64

# Select the appropriate base image based on target architecture
FROM base-${TARGETARCH}

ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /ros2_ws

##############################
# Basic Dependencies
##############################

RUN apt-get update &&\
    apt-get install -y \
    python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

##############################
# Project-Specific Libraries
##############################

# Example: Install architecture-specific packages
ARG TARGETARCH
RUN apt-get update && \
    if [ "$TARGETARCH" = "arm64" ]; then \
        apt-get install -y vim nano; \
    else \
        apt-get install -y vim emacs-nox; \
    fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Example: Install Python dependencies
RUN pip3 install --no-cache-dir \
    numpy \
    matplotlib

# Example: Install ROS2 packages
RUN apt-get update && \
    apt-get install -y \
    x11-apps \
    ros-humble-plotjuggler-ros && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

##############################
# Entrypoint Setup
##############################

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]

##############################
# User Setup
##############################

# Create user with matching UID/GID from host
ARG UID=1000
ARG GID=1000
RUN groupadd -g ${GID} rosuser && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash rosuser && \
    chown -R rosuser:rosuser /ros2_ws

# Switch to non-root user
USER rosuser
