# Kyon Robot Configuration

This repository contains the comprehensive configuration files and management tools for the Kyon robot system. It provides a complete framework for controlling and monitoring the robot through a web-based interface and managing its real-time control processes.

## Overall System Architecture

The Kyon robot software stack consists of several interconnected components that work together to provide a complete robot control solution:

1. **`xbot2-core`**:
   - **Role**: The central real-time robot control software.
   - **Implementation**: C++ library/middleware.
   - **Execution**: Runs directly on the robot's hardware (or in simulation), typically within a Docker container.
   - **Functionality**:
     - Interfaces with motors and sensors via a Hardware Abstraction Layer (HAL).
     - Executes real-time control algorithms (loaded as plugins).
     - Communicates with higher-level systems (e.g., ROS).
     - Configured by `xbot2/kyon_basic.yaml` and related HAL/plugin config files.

2. **Concert Launcher (`executor.py`)**: 
   - **Role**: The execution engine responsible for launching and managing software processes.
   - **Implementation**: Python library (`concert_launcher/src/concert_launcher/executor.py`).
   - **Functionality**:
     - Reads process definitions from `launcher_config.yaml`.
     - Starts, stops, and monitors processes.
     - Manages processes locally, remotely via SSH, and inside Docker containers.
     - Utilizes `tmux` for reliable background process management.
     - Provides status checking and output streaming capabilities.
   - **Documentation**: For detailed documentation on the Concert Launcher, see the [Concert Launcher README](https://github.com/ADVRHumanoids/concert_launcher).

3. **`xbot2_gui_server` (Implemented in `launcher.py`)**: 
   - **Role**: The backend web server providing a Graphical User Interface for managing the robot software.
   - **Implementation**: Python web server using `aiohttp` (`robot_monitoring/server/src/xbot2_gui_server/launcher.py`).
   - **Functionality**:
     - Acts as a bridge between the web-based GUI and the Concert Launcher.
     - Uses the Concert Launcher to manage the processes defined in `launcher_config.yaml`.
     - Provides an HTTP API and WebSocket interface for the web frontend.
     - Allows users to view process status, start/stop processes, select configuration variants, and view live console output.

In essence, the `xbot2_gui_server` serves as a web-based remote control panel that translates user actions from the GUI into commands for the Concert Launcher. The Concert Launcher then handles the low-level details of starting, stopping, and monitoring the actual robot software components based on the specifications in `launcher_config.yaml`.

## Repository Structure

The Kyon configuration repository is available at: https://github.com/ADVRHumanoids/kyon_config/tree/master/xbot2

```
kyon_config/
├── docker/                         # Docker build configurations
│   ├── build-kyon.bash            # Robot-specific build script
│   ├── kyon-config_ros1.env       # ROS1 environment configuration
│   ├── kyon-config_ros2.env       # ROS2 environment configuration
│   └── kyon-cetc-*/               # Runtime compose configurations
├── docker-base/                    # Submodule: generalized xbot2_docker
│   └── robot-template/            # Generic robot build templates
├── gui/
│   ├── gui_server_config.yaml      # Primary configuration for xbot2_gui_server
│   └── launcher_config.yaml        # Process definitions for Concert Launcher
├── xbot2/
│   ├── kyon_basic.yaml             # Main configuration for xbot2-core
│   ├── hal/                        # Hardware Abstraction Layer configurations
│   │   ├── kyon_hal_ec_idle.yaml   # EtherCAT idle mode configuration
│   │   ├── kyon_hal_ec_pos.yaml    # EtherCAT position control configuration
│   │   └── ...
│   └── friction/                    # Plugin configurations
│       ├── fc_config.yaml          # Friction compensation configuration
│       └── ...
├── ecat/                          # EtherCAT configurations
├── host/                          # Host machine setup scripts
├── compose.yaml                    # Docker Compose configuration
└── setup.sh                        # Setup and launch script
```

## Detailed Configuration Files

### 1. `gui_server_config.yaml`

This minimal file tells the `xbot2_gui_server` where to find the main process configuration file:

```yaml
launcher:
  launcher_config: launcher_config.yaml  # Path relative to this file or absolute
```

**Purpose**: This configuration file is loaded by the `xbot2_gui_server` application (`launcher.py`) and specifies the path to the main process configuration file (`launcher_config.yaml`) used by the Concert Launcher.

### 2. `launcher_config.yaml`

This is the core configuration file for the Concert Launcher (`executor.py`). It defines what software components need to be run, where they should run, and how to run them:

```yaml
context:
  session: kyon  # Default name for the tmux session where processes are grouped
  params:
    hw_type: ec_pos  # Default global parameter; can be used in 'cmd' via {hw_type}
  .defines:  # YAML Anchors (&) defining reusable aliases
    - &embedded embedded@10.24.12.100  # Alias 'embedded' -> SSH target (robot onboard)
    - &control kyon@10.24.12.102       # Alias 'control' -> SSH target (control station)
    - &vision kyon@10.24.12.101        # Alias 'vision' -> SSH target (vision computer)
    - &docker-xeno focal-ros1-xeno-dev-1  # Alias 'docker-xeno' -> Docker container name (with Xenomai)
    - &docker-base focal-ros1-dev-1       # Alias 'docker-base' -> Docker container name (base env)

# Process Definitions (each top-level key except 'context' is a process)
imu:
  cmd: roslaunch vectornav vectornav.launch  # The command to execute
  machine: *embedded  # WHERE: Run via SSH on the host referenced by 'embedded' alias
  docker: *docker-xeno  # HOW: Run inside the container named by 'docker-xeno'
  ready_check: timeout 5 rostopic echo /xbotcore/imu/imu_link -n 1  # Command to verify readiness

ecat:
  cmd: ecat_master
  machine: *embedded
  docker: *docker-xeno
  # No ready_check specified for this process

xbot2:
  cmd: xbot2-core --hw {hw_type}  # Command uses the 'hw_type' parameter
  machine: *embedded
  docker: *docker-xeno
  ready_check: timeout 5 rostopic echo /xbotcore/joint_states -n 1
  variants:  # Defines alternative ways to run this process, selectable in the GUI
    verbose:  # Simple flag variant
      cmd: "{cmd} -V"  # Appends '-V' to the base command string
    ctrl:  # Group of mutually exclusive variants (like radio buttons in GUI)
      # Select one of these to override the 'hw_type' parameter for this launch
      - ec_idle:  # Variant name
          params:  # Variant-specific parameters
            hw_type: ec_idle  # Sets hw_type to 'ec_idle' when this variant is chosen
      - ec_pos:  # Variant name
          params:
            hw_type: ec_pos  # Sets hw_type to 'ec_pos'
```

**Purpose**: This file defines all the processes that can be managed through the system, along with their execution environments and configuration options.

**Key Sections Explained**:
   * **`context`**: Defines global settings for the launcher.
     * `session`: Sets the `tmux` session name used by the launcher.
     * `params`: Defines default parameters accessible via `{param_name}` substitution.
     * `.defines`: Uses YAML Anchors to create reusable aliases for SSH targets and Docker containers.
   * **Process Definitions**: Each top-level key (except `context`) defines a manageable process.
     * `cmd`: The command-line string to execute, with optional parameter placeholders.
     * `machine`: Specifies the target machine using a defined alias. If omitted or `local`, runs on the local machine.
     * `docker`: Specifies a Docker container within which the command should be executed.
     * `ready_check`: An optional command that verifies if the process is fully operational.
     * `variants`: Defines alternative configurations or command modifications selectable via the GUI.

### 3. `xbot2/kyon_basic.yaml`

This is the primary configuration file for the `xbot2-core` process itself:

```yaml
# Defines robot model using URDF/SRDF found via ROS paths
XBotInterface:
  urdf_path: "$(command xacro $(rospack find kyon_description)/urdf/kyon.urdf upper_body:=true use_mimic_tag:=false)"
  srdf_path: "$(rospack find kyon_description)/srdf/kyon.srdf"

# Configuration for the dynamics library
ModelInterface:
  # Dynamics library settings

# Maps --hw argument values to specific HAL configuration files
xbotcore_device_configs:
  sim: "$(rospack find kyon_config)/hal/kyon_gz.yaml"
  dummy: "$(rospack find kyon_config)/hal/kyon_dummy.yaml"
  ec_idle: "$(rospack find kyon_config)/hal/kyon_hal_ec_idle.yaml"
  ec_pos: "$(rospack find kyon_config)/hal/kyon_hal_ec_pos.yaml"

# Defines execution threads and their scheduling properties
xbotcore_threads:
  rt_main: { sched: fifo, prio: 60, period: 0.001 }  # 1ms Real-Time thread
  nrt_main: { sched: other, prio: 0, period: 0.005 }  # 5ms Non-Real-Time thread

# Lists plugins to load, configure, and assign to threads
xbotcore_plugins:
  # Homing plugin configuration
  - plugin_name: homing_example
    type: XBot::Cartesian::Plugins::Homing  # Plugin class
    thread: nrt_main  # Run in non-real-time thread
    params:
      ctrl_mode_map: { l_arm_link_6: 11, r_arm_link_6: 11 }

  # ROS Interface plugin
  - plugin_name: ros_io
    type: XBot::RosIO
    thread: nrt_main
    params: { queue_size: 1, update_period: 0.01 }

  # ROS Control Interface plugin
  - plugin_name: ros_control
    type: XBot::RosControl
    thread: nrt_main
    params: { update_period: 0.01 }

  # Friction Compensation plugin loading external params
  - plugin_name: friction_comp
    type: XBot::FrictionCompensation
    thread: rt_main  # Run in real-time thread
    params:
      config_path: "$(rospack find kyon_config)/xbot2/friction/fc_config.yaml"

  # Additional plugins...

# Global framework parameters
xbotcore_param:
  sense_map_vel_from_pos_diff: true
  hal_common_config: { enable_brake_on_idle: true }
```

**Purpose**: When `xbot2-core` starts, it reads this file to understand the robot's structure, which hardware interface to use, how to schedule its internal tasks, and which control/utility plugins to load and configure.

**Key Sections Explained**:
   * **`XBotInterface`**: Defines the robot's kinematic and dynamic model.
   * **`xbotcore_device_configs`**: Maps hardware configuration names to actual HAL configuration files.
   * **`xbotcore_threads`**: Defines named execution threads with specific scheduling properties.
   * **`xbotcore_plugins`**: Lists the modular plugins to be loaded into `xbot2-core`.
   * **`xbotcore_param`**: Global parameters accessible throughout the `xbot2-core` framework.

### 4. `compose.yaml`

Defines the Docker services, their base images, configurations, networking, and volumes:

```yaml
services:
  base: &base_service  # Using YAML anchor for reusability
    image: hhcmhub/kyon-cetc-focal-ros1-base
    stdin_open: true
    tty: true
    privileged: true  # WARNING: High privileges needed for HW access
    network_mode: host  # Required for ROS networking across containers/host
    cap_add:
      - ALL  # WARNING: Grants all capabilities
    restart: "no"  # Default restart policy (overridden by specific services)
    ulimits: { core: -1 }
    volumes:
      - /tmp/.X11-unix:/tmp/.X11-unix:rw  # For X11 GUI Forwarding
      - ~/.ssh:/home/user/.ssh  # Share host SSH keys
    environment:
      - TERM=xterm-256color
      - DISPLAY  # Inherit DISPLAY from host
      - HHCM_FOREST_CLONE_DEFAULT_PROTO=https

  dev:  # Development container
    <<: *base_service  # Merge settings from base_service
    volumes:
      - ~/.cache/kyon-cetc-focal-ros1-base:/home/kyon_ros1/data
      # Add project source code mounts here if needed

  xbot2_gui_server:  # GUI backend container
    <<: *base_service  # Merge settings from base_service
    entrypoint: bash -ic "echo 'Waiting for ROS Master...'; until rostopic list > /dev/null 2>&1; do sleep 1; done; echo 'ROS Master found. Starting GUI Server.'; sleep 1; xbot2_gui_server /home/kyon_ros1/xbot2_ws/src/kyon_config/gui/gui_server_config.yaml"
    restart: always  # Keep the GUI server running
```

**Purpose**: This Docker Compose file defines the multi-container Docker application, specifying the services, their base images, configurations, networking, volumes, and dependencies needed for the system.

**Key Services Explained**:
   * **`base`**: A reusable configuration template defining common settings for other services.
   * **`dev`**: A service intended for development, providing a containerized shell environment.
   * **`xbot2_gui_server`**: The container that runs the GUI backend server, with a custom entrypoint that waits for the ROS master before starting.

### 5. `setup.sh`

A shell script designed to automate the setup and launch of the Docker Compose environment:

```bash
#!/bin/bash

# Placeholder for ROS environment setup function
ros1() {
    # Example: source /opt/ros/noetic/setup.bash
    echo "ROS1 environment setup placeholder executed."
}

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "$SCRIPT_DIR" || exit 1  # Change to script dir or exit if failed

echo "Allowing local root access to X server for Docker GUI forwarding..."
# WARNING: Modifies X server access control
xhost +local:root

echo "Bringing up Docker Compose services (dev, xbot2_gui_server)..."
# Start 'dev' and implicitly its dependencies in detached mode. Don't recreate if up-to-date.
docker compose up dev -d --no-recreate

echo "Executing shell inside the 'dev' container..."
# Attach an interactive bash shell to the running 'dev' container
docker compose exec dev bash
```

**Purpose**: This script automates the setup and launch of the Docker Compose environment, including necessary host configurations like X11 permissions.

**Key Steps**:
1. Defines helper functions (like `ros1()`)
2. Determines the script's directory and changes to it
3. Runs `xhost +local:root` to grant permissions for X display forwarding
4. Uses Docker Compose to start the services
5. Executes an interactive shell inside the `dev` container

## Web Server Implementation (`launcher.py`)

The `robot_monitoring/server/src/xbot2_gui_server/launcher.py` file implements the backend web server application (`xbot2_gui_server`) using the `aiohttp` framework. It serves as the intermediary between the user interface and the Concert Launcher.

**Key Functionality**:
- **Initialization**: Loads configuration, instantiates the Concert Launcher's Executor, and sets up web routes
- **HTTP API Handlers**:
  - `/process/get_list`: Retrieves the list of defined processes and their status
  - `/process/{name}/command/{command}`: Handles process control actions (start, stop, kill)
  - `/process/custom_command`: Allows executing arbitrary commands (if configured)
- **WebSocket Communication**: Streams real-time updates to connected clients, including process output and status changes
- **Background Tasks**: Periodically checks process status and manages streaming tasks

**Interaction Flow**:
1. The server reads `gui_server_config.yaml` to find `launcher_config.yaml`
2. It instantiates the Concert Launcher's Executor with this configuration
3. When a client connects to the web interface, it serves the frontend assets
4. The frontend establishes a WebSocket connection for real-time updates
5. User actions in the GUI generate HTTP requests to the appropriate API endpoints
6. The server translates these requests into Executor commands
7. Process output and status updates are streamed back to the client via WebSocket

## External Dependencies

This project relies on several external components:

1. **Concert Launcher**: The process management framework used by the GUI server.
   - Repository: [https://github.com/ADVRHumanoids/concert_launcher](https://github.com/ADVRHumanoids/concert_launcher)
   - The Concert Launcher README contains comprehensive documentation about the process execution engine, including detailed explanations of the configuration format, API, and integration patterns.

## Detailed Interaction Flow

The typical sequence of events when using the system via the GUI:

1. **System Startup**:
   - User runs `./setup.sh`
   - Host command `xhost +local:root` allows GUI forwarding from Docker
   - Docker Compose starts the necessary containers, including `xbot2_gui_server`
   - The user is placed inside the `dev` container shell

2. **GUI Server Initialization**:
   - The `xbot2_gui_server` container starts its entrypoint script
   - The script waits for the ROS master to be available
   - The `xbot2_gui_server` Python application starts and loads configuration
   - The web server begins listening for HTTP and WebSocket connections

3. **User Accesses GUI**:
   - User opens a web browser to the server address
   - The frontend establishes a WebSocket connection for real-time updates
   - The frontend requests the process list from `/process/get_list`
   - The server responds with process definitions and current status
   - The frontend renders the UI accordingly

4. **User Action: Start Process**:
   - User selects variant options and clicks "Start" for a process
   - Frontend sends HTTP request to `/process/xbot2/command/start` with selected variants
   - Server calls `executor.execute_process()` with appropriate parameters
   - Executor connects to the target machine, starts the process in a tmux session
   - If defined, the ready check is executed periodically
   - Status updates and process output are streamed to the frontend via WebSocket

5. **Process Execution**:
   - The target process (e.g., `xbot2-core`) starts running
   - It loads its own configuration (e.g., `xbot2/kyon_basic.yaml`)
   - For `xbot2-core`, it initializes the robot model, threads, and plugins
   - Process output is captured and streamed back to the GUI

6. **User Action: Stop Process**:
   - User clicks "Stop" for a running process
   - Frontend sends HTTP request to `/process/xbot2/command/stop`
   - Server calls `executor.kill()` with appropriate parameters
   - Executor sends the appropriate signal to the process
   - Status updates are sent to the frontend

---

# Docker Build System and Development Environment

This section explains how the Kyon configuration repository integrates with the generalized `xbot2_docker` build system to create a complete development and deployment environment. The build system follows a layered approach where robot-specific configurations leverage generalized build templates from the `xbot2_docker` submodule.

## Understanding the Build System Architecture

The build system is designed around the principle of separation of concerns, allowing multiple robot projects to share the same underlying build infrastructure while maintaining their unique configurations. This design pattern provides several key advantages:

**Robot-Specific Layer**: The `docker/` directory in this repository contains configuration files that define Kyon-specific parameters, package selections, and environment settings. This layer allows each robot project to specify exactly what software components it needs without modifying the underlying build logic.

**Generic Build Layer**: The `docker-base/` submodule provides reusable Docker build templates, compose configurations, and build scripts that work across different robot projects. This shared infrastructure ensures consistency and reduces maintenance overhead across multiple robot systems.

**Integration Layer**: The `build-kyon.bash` script serves as the bridge between these two layers, loading robot-specific configurations and delegating the actual build process to the generic build system.

### How the Build Process Works

When you initiate a build, the system follows this sequence:

1. **Environment Loading**: The build script sources the appropriate environment file (such as `kyon-config_ros1.env`) which defines all the parameters needed for the Kyon-specific build
2. **Configuration Display**: The script shows all the build parameters for verification, helping you understand exactly what will be built
3. **Delegation**: The script calls the generic build infrastructure in `docker-base/robot-template/_build/`
4. **Image Building**: Docker Compose builds multiple specialized images for different use cases (base development environment, real-time enabled environment, etc.)

## Environment Configuration Files

The environment files are the heart of the robot-specific configuration system. These files define all the parameters needed to build Docker images tailored for the Kyon robot system. Understanding these parameters is crucial for both using the system effectively and adapting it for other robots.

### Core Parameters

```bash
export ROBOT_NAME=kyon              # Identifies the robot type for logging and organization
export USER_NAME=user               # Default username in containers (should match host user patterns)
export USER_ID=1000                 # User ID (should match host user to avoid permission issues)
export KERNEL_VER=5                 # Xenomai kernel version for real-time capabilities
```

These core parameters establish the basic identity and user configuration for the Docker containers. The `ROBOT_NAME` parameter helps organize builds and logs when working with multiple robot types. The user configuration parameters ensure that files created inside containers maintain proper ownership when mounted back to the host system.

### Repository Configuration

```bash
export RECIPES_TAG=kyon-cetc        # Git tag/branch for robot recipes
export RECIPES_REPO=git@github.com:advrhumanoids/multidof_recipes.git
```

The repository configuration tells the build system where to find robot-specific software recipes and which version to use. The recipes repository contains the detailed instructions for building and configuring the software components specific to each robot. By using tags or branches, you can ensure reproducible builds and manage different versions of the software stack.

### Package Selection

```bash
export ROBOT_PACKAGES="iit-kyon-ros-pkg kyon_config"
export ADDITIONAL_PACKAGES="vectornav hesai_ros_driver"
```

The package selection parameters define what software will be installed in the Docker images. `ROBOT_PACKAGES` specifies the core packages specific to the Kyon robot, while `ADDITIONAL_PACKAGES` includes extra packages needed for sensors, drivers, and other peripherals. This modular approach allows you to build lean images with only the necessary components for specific use cases.

### Docker Naming Convention

```bash
export BASE_IMAGE_NAME=kyon-cetc-focal-ros1
export TAGNAME=v1.0.0
export DOCKER_REGISTRY=hhcmhub
```

These parameters determine how the resulting Docker images will be named and where they can be pushed for sharing. The naming convention follows a structured pattern that includes the robot name, build variant, Ubuntu distribution, and ROS version. This systematic naming helps organize images and makes it easy to identify the right image for specific deployment scenarios.

## Using the Build System

### Initial Setup Process

The setup process involves several important steps that prepare your environment for building and running the Docker images.

**Clone the repository with submodules**: Since this repository depends on the `xbot2_docker` submodule for its build infrastructure, you must ensure that submodules are properly initialized:

```bash
git clone --recursive <repository-url>
# Or if you've already cloned the repository:
git submodule update --init --recursive
```

**Verify Docker installation**: The build system requires both Docker and Docker Compose to be properly installed and accessible:

```bash
docker --version
docker compose version
```

**Set up authentication for private repositories**: If your robot configuration uses private repositories, you'll need to configure authentication. For HTTPS authentication, create a `.netrc` file:

```bash
echo "machine github.com login <username> password <token>" > ~/.netrc
chmod 600 ~/.netrc
```

For SSH access, ensure your SSH keys are properly configured and that the SSH agent is running with your keys loaded.

### Building Docker Images

The `build-kyon.bash` script provides a simple but powerful interface to the underlying build system. Understanding its options helps you use it effectively for different scenarios.

**Local development builds**: For most development work, you'll want to build images locally:

```bash
cd docker/
./build-kyon.bash
```

This command builds all the configured images locally, making them available for immediate use on your development machine.

**Building and distributing images**: When you want to share images with team members or deploy to other machines:

```bash
./build-kyon.bash --push
```

This option builds the images locally and then pushes them to the configured Docker registry, making them available for others to pull and use.

**Using pre-built images**: If someone else has already built and pushed images that you want to use:

```bash
./build-kyon.bash --pull
```

This option downloads pre-built images from the registry without building them locally, which can save significant time during initial setup or when switching between different versions.

### Understanding the Build Process

When you run `build-kyon.bash`, a sophisticated sequence of operations takes place behind the scenes. Understanding this process helps you troubleshoot issues and customize the build for your specific needs.

**Environment Loading Phase**: The script begins by sourcing the appropriate environment file (`kyon-config_ros1.env` for ROS1 builds or `kyon-config_ros2.env` for ROS2 builds). This step loads all the configuration parameters that will guide the build process.

**Configuration Verification Phase**: The script displays all the build parameters, giving you an opportunity to verify that the configuration matches your intentions. This step is particularly important when switching between different robot configurations or build variants.

**Build Delegation Phase**: The script then calls the generic build infrastructure located in `docker-base/robot-template/_build/`. This delegation pattern allows the robot-specific script to remain simple while leveraging sophisticated build logic that can be shared across multiple robot projects.

**Image Construction Phase**: Docker Compose orchestrates the building of multiple specialized images. The build process typically creates three main image types:

- **Base Image**: A core development environment with XBot2, ROS, and essential development tools
- **Real-time Image**: An enhanced version with Xenomai kernel modules for real-time control applications  
- **Locomotion Image**: A specialized image with additional locomotion control stack components

### Resulting Docker Images

After a successful build, you'll have a set of Docker images that follow a systematic naming convention. For a typical Kyon ROS1 build, you might see:

- `hhcmhub/kyon-cetc-focal-ros1-base:v1.0.0`
- `hhcmhub/kyon-cetc-focal-ros1-xeno-v5:v1.0.0`  
- `hhcmhub/kyon-cetc-focal-ros1-locomotion:v1.0.0`

Each image is optimized for specific use cases. The base image provides a general development environment, the xeno image adds real-time capabilities essential for robot control, and the locomotion image includes specialized algorithms for mobile robot navigation and control.

## Runtime Usage and Development Workflow

Once your images are built, the runtime system provides convenient ways to use them for development and deployment. The runtime configurations are organized in directories that match your build configurations.

### Development Environment Access

**For ROS1 real-time development**:
```bash
cd docker/kyon-cetc-focal-ros1-xeno/
source setup.sh
ros1  # This launches the development container
```

This sequence changes to the appropriate runtime directory, loads the environment configuration, and starts an interactive development container with real-time capabilities enabled.

**For ROS2 development**:
```bash
cd docker/kyon-cetc-noble-ros2/
source setup.sh
ros2 dev  # Specify which service to start
```

The ROS2 workflow is similar but requires you to specify which service you want to start, giving you more control over the specific environment you're working in.

### Development Workflow Considerations

The runtime system is designed to support efficient development workflows while maintaining consistency with deployment environments. When you're actively developing, you might want to mount your source code directories into the containers so that changes are immediately reflected without rebuilding images.

You can modify the compose files in the runtime directories to add volume mounts for your development folders. This approach minimizes build times during development while ensuring that your deployment images remain reproducible and well-defined.

## Customizing for Other Robots

The modular design of this build system makes it straightforward to adapt for different robot platforms. The process involves creating robot-specific configurations while reusing the proven build infrastructure.

### Creating Robot-Specific Configurations

**Duplicate and modify environment files**: Start by copying the existing configuration and adapting it for your robot:

```bash
cp kyon-config_ros1.env myrobot-config_ros1.env
# Edit the file with your robot's specific parameters
```

Key parameters to modify include the robot name, package lists, repository references, and Docker naming conventions. Take care to ensure that package names and repository references are correct for your robot's software stack.

**Create corresponding build script**: Copy and adapt the build script to use your new configuration:

```bash
cp build-kyon.bash build-myrobot.bash
# Update the source line to point to your environment file
```

**Adapt runtime configurations**: Modify the Docker Compose files in the runtime directories to match your robot's specific requirements, such as hardware access needs, network configurations, or volume mounts.

# CI/CD: Automatic Docker Image Builds & Pushes (ROS1 & ROS2)

This repository includes a GitHub Actions workflow that **automatically rebuilds the Kyon Docker images** when relevant changes are detected in the **`docker-base` submodule** (both ROS1 and ROS2 build templates), or when explicitly requested via **commit message triggers**. Images are **pushed** to the registry on tags and on pushes to `main`/`master`.

## What triggers a rebuild?

The **`detect-changes`** job computes whether ROS1 and/or ROS2 images should be rebuilt using three signals:

1. **Path-based detection** (using `dorny/paths-filter`):

   * ROS1: changes under `docker-base/robot-template/_build/robot-focal-ros1/**`
   * ROS2: changes under `docker-base/robot-template/_build/robot-noble-ros2/**`
2. **Submodule-delta detection** (manual check):

   * If the `docker-base` submodule pointer changes in a commit/PR, the workflow diffs the submodule commits and flags a rebuild if any of the above ROS1/ROS2 paths changed inside the submodule.
3. **Commit message triggers** (case-insensitive):

   * Rebuild **both**: `rebuild ros1 ros2`, `rebuild ros2 ros1`, `rebuild both`, or `rebuild all`
   * Rebuild **ROS1 only**: `rebuild ros1`
   * Rebuild **ROS2 only**: `rebuild ros2`

## Required secrets

To push images and pull private dependencies, configure these repository secrets:

* `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`
* `GH_USERNAME`, `GH_TOKEN` (used to populate a minimal `~/.netrc` for private GitHub fetches during Docker builds)

## Commit message examples (manual triggers)

```bash
# Rebuild ROS2 only
git commit -m "Update dependencies - rebuild ros2"

# Rebuild *both* ROS1 and ROS2
git commit -m "Major update - rebuild ros1 ros2"
# or
git commit -m "Update submodule - rebuild both"
# or
git commit -m "Update submodule - rebuild all"
```

> Triggers are case-insensitive
