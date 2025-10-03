# ROS2 Humble Multi-Architecture Docker Environment

A flexible Docker setup for ROS2 Humble that supports both AMD64 and ARM64 architectures with proper user permissions and GUI support.

## Features

- Multi-architecture support (AMD64/ARM64)
- Non-root user with matching host UID/GID (prevents permission issues)
- X11 GUI support (e.g., RViz, PlotJuggler)
- USB device access
- Configurable image names for different projects

## Tested Platforms

| Platform         | Architecture    | Status            | Notes            |
| ---------------- | --------------- | ----------------- | ---------------- |
| Ubuntu 22.04     | x86_64 (amd64)  | ✅ Tested         | Full GUI support |
| Jetson Orin nano | aarch64 (arm64) | ✅ Tested         | Should work      |
| Raspberry Pi 4/5 | aarch64 (arm64) | ⚠️ Not tested yet | Should work      |

## Prerequisites

- Docker installed

**Jetson Orin nano:**
```bash
sudo apt-get update
sudo apt-get install -y docker.io
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

**Raspberry Pi 4/5:**
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

## Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd ros2-humble-multiarch

# 2. Build the Docker image
./build.sh

# 3. Run a container
./run.sh my_robot

# 4. Inside the container, test ROS2
ros2 topic list
ros2 run demo_nodes_cpp talker

# 5. Test GUI support (in another terminal)
./attach.sh my_robot
xeyes  # Should display a GUI window
```

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
- x11-apps (includes xeyes for X11 testing)

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
