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
   - **Documentation**: For detailed documentation on the Concert Launcher, see the [Concert Launcher README](https://github.com/ADVRHumanoids/concert_launcher/tree/Documentation).

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
