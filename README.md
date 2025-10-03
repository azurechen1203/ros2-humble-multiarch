# ROS2 Humble Multi-Architecture Docker Environment

A flexible Docker setup for ROS2 Humble that supports both AMD64 and ARM64 architectures with proper user permissions and GUI support.

## Features

- Multi-architecture support (AMD64/ARM64)
- Non-root user with matching host UID/GID (prevents permission issues)
- X11 GUI support (e.g., RViz, PlotJuggler)
- USB device access
- Configurable image names for different projects

## Prerequisites

- Docker installed
- Linux host (for X11 support)
- `xhost` command available

## File Structure

```
.
├── Dockerfile       # Multi-arch ROS2 image with dependencies
├── build.sh         # Builds the Docker image
├── run.sh           # Creates and runs a container
├── attach.sh        # Attaches to a running container
├── entrypoint.sh    # Container startup script
└── ros2_ws/         # ROS2 workspace (mounted into container)
```

## Usage

### Building the Image

**Default build (uses cache):**

```bash
./build.sh
```

**Clean rebuild (no cache):**

```bash
./build.sh --no-cache
```

**Custom image name:**

```bash
./build.sh my_custom_image
```

**Custom image name with no cache:**

```bash
./build.sh my_custom_image --no-cache
```

### Running a Container

```bash
./run.sh <container_name> [image_name]
```

**Default image:**

```bash
./run.sh my_robot
```

**Custom image:**

```bash
./run.sh my_robot my_custom_image
```

This creates a container with:

- GUI support (X11)
- USB device access
- Workspace mounted from `./ros2_ws`

### Attaching to a Running Container

```bash
./attach.sh <container_name>
```

Example:

```bash
./attach.sh my_robot
```

## How It Works

### Multi-Architecture Support

The build automatically detects your architecture:

- `x86_64` → uses `osrf/ros:humble-desktop-full`
- `aarch64` → uses `arm64v8/ros:humble`

### UID/GID Matching

The Dockerfile creates a user with the same UID/GID as your host user:

1. `build.sh` passes your UID/GID via `$(id -u)` and `$(id -g)`
2. Dockerfile creates `rosuser` with matching IDs
3. Files created in the container match your host user ownership
4. No permission issues when editing files on the host

### Workspace Management

- The `ros2_ws` directory is mounted into the container at `/ros2_ws`
- Changes persist between container runs
- Multiple containers can use the same or different workspaces

## Installed Packages

- ROS2 Humble Desktop Full
- Python 3 with pip
- PlotJuggler (ROS visualization tool)

## Multi-User Setup

Each developer can build their own image and have the correct permissions:

```bash
# Developer_1 laptop (UID=1000)
./build.sh
./run.sh Developer_1

# Developer_2 laptop (UID=1001)
./build.sh
./run.sh Developer_2
```

## Customization

To adapt this for different projects:

1. Modify `Dockerfile` dependencies as needed
2. Use custom image names: `./build.sh my_project`
3. Update `run.sh` if you need different mount points or permissions
4. Adjust `entrypoint.sh` for project-specific startup commands
