# Kyon Robot Configuration

Configuration files for the Kyon robot: shell profiles, Docker containers, WireGuard VPN, CycloneDDS, EtherCAT, and the GUI launcher.

---

## Network overview

The robot network is a dedicated LAN (`10.24.15.0/24`) managed by the onboard router. Two PCs live on this LAN:

| Host | Role | IP | 
|---|---|---|
| `amax-kyon-iit` | Embedded PC | `10.24.15.100` | 
| `kyon-orin` | Vision PC | `10.24.15.101` | 
| `kyon-control` | Control PC | `10.24.15.102` | 
| `kyon03-robot` | Router / gateway | `10.24.15.1` | 

*Note:* the router's DHCP server is **enabled**. The IPs in the table above have been obtained by
pinning each machine's MAC address to  a specific static IP from the router settings.

*Note:* you must not connect any of the router's LAN ports to the corporate network.

Because the robot LAN port is internally wired to the router's WAN port, accessing the robot local network from outside (WAN)
is not directly possible. To circumvent this limitation, a WireGuard-based VPN is run by the `kyon-control` PC.
The router then forwards WireGuard (UDP `51820`) to `kyon-control`, allowing remote VPN access into the robot LAN.

The router also allows SSH access to all robot PCs from the WAN thanks to the following forwarding rules
```
kyon03-robot:22 --> kyon-control:22(sshd)
kyon03-robot:23 --> amax-kyon-iit:22(sshd)
kyon03-robot:24 --> kyon-orin:22(sshd)
```

Therefore, it is possible to SSH into the `amax-kyon-iit` machine from the WAN with
```bash
$ ssh -p 23 embedded@kyon03-robot
```

Connecting to the robot VPN is explained below in this document.

---

## A · Setting up the robot PCs
This section is meant for robot maintainers, to help them with the robot commissioning operations.

### 1. Clone this repo

Clone the repository to the same path on both PCs:

```bash
$ git clone <repo-url> <path/to/kyon_config>
```

### 2. Source the host profile

Each PC has a host-side shell profile that sets environment variables, SSH aliases, and sources the Docker helper scripts. Add the appropriate line to `~/.bashrc` so it is loaded on every login:

- **kyon-control:**
  ```bash
  $ source <path/to/kyon_config>/host/control_profile.bash
  ```
  Sets `ROS_IP=10.24.15.102`, `ROS_MASTER_URI`, and sources the `kyon-noble-ros2` Docker helper (which provides the `kyon` shell function — see below).

- **amax-kyon-iit (embedded):**
  ```bash
  $ source <path/to/kyon_config>/host/embedded_profile.bash
  ```
  Sets `ROS_IP=10.24.15.100`, `ROS_MASTER_URI`, `KERNEL_VER`, and sources the `kyon-noble-ros2-xeno` Docker helper.

### 3. Start a Docker container with the `kyon` alias

Sourcing the host profile above makes the `kyon` shell function available. It takes a Docker Compose service name as its argument, starts the container if it is not already running, and opens an interactive shell inside it. The service name is always `dev`:

```bash
$ kyon dev
```

The function runs `docker compose up <service> -d --no-recreate` followed by `docker compose exec <service> bash`, and also calls `xhost +local:root` to allow GUI applications inside the container.

### 4. Environment inside the container

When a shell is opened inside a container, the corresponding Docker profile is sourced automatically to configure the ROS 2 middleware environment:

| Container | Profile |
|---|---|
| `kyon-noble-ros2` (control) | `docker/control_profile_docker.bash` |
| `kyon-noble-ros2-xeno` (embedded) | `docker/embedded_profile_docker.bash` |

Both profiles source `docker/generic_profile_docker.bash`, which sets `RMW_IMPLEMENTATION=rmw_cyclonedds_cpp`. Each then sets the appropriate `CYCLONEDDS_URI` pointing to the corresponding CycloneDDS XML config under `network/cyclone/`. The embedded profile additionally sets `ECAT_MASTER_CONFIG` and the `ecat_master` / `ecat_master_gdb` aliases for the EtherCAT master.

### 5. WireGuard server (kyon-control only)

The WireGuard VPN server must be set up once on `kyon-control` before any remote client can connect. Follow the full instructions in [network/wg/README.md](network/wg/README.md) to generate the server keypair, write `/etc/wireguard/wg0.conf`, and bring up the `wg-quick@wg0` systemd service. Any static peer (e.g. the pilot PC) must have its public key added to `wg0.conf` before the service is started.

---

## B · Setting up a remote client / pilot

### 1. Clone this repo and source the client profile

On the remote machine, clone the repository and add the client profile to `~/.bashrc`:

```bash
$ source <path/to/kyon_config>/host/client_profile.bash
```

This profile sets up:
- SSH aliases `ssh_control` and `ssh_embedded` for quick access to the robot PCs.
- `ROS_DOMAIN_ID=42` and `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST` to isolate the client's ROS 2 graph from any local network traffic.
- `ZENOH_BRIDGE_ARGS` pointing at `kyon-control`'s Zenoh endpoint (`tcp/10.24.15.102:7447`).
- The `kyon` shell function (via `docker/kyon-noble-ros2/setup.sh`) to enter the client-side ROS 2 container.
- Helper functions `kyon_connect_wg`, `kyon_connect_zenoh`, and `kyon_connect` (see below).

### 2. Connect to the robot

The `kyon_connect` function performs the full connection sequence in one step:

```bash
$ kyon_connect          # connect VPN + start Zenoh bridge
$ kyon_connect down     # disconnect VPN
```

Internally it runs two steps, which can also be invoked independently:

1. **`kyon_connect_wg`** — calls `network/wg/connect-wg.bash` to establish a WireGuard tunnel into the robot LAN. On first run it generates a local keypair under `~/.wireguard/` and registers a dynamic peer on `kyon-control`. You will be prompted once for the remote machine password. The tunnel gives the client full IP-level access to the robot LAN (`10.24.15.0/24`) and the VPN subnet (`10.0.0.0/24`).

2. **`kyon_connect_zenoh`** — starts the `zenoh_bridge_client` container, which connects to the `zenoh_bridge_server` running on `kyon-control` over the WireGuard tunnel. This bridges ROS 2 topics across the link without relying on DDS multicast, which does not work over a routed VPN.

### 3. Zenoh-over-WireGuard architecture

Direct ROS 2 / DDS discovery relies on multicast, which is unavailable across a routed WireGuard tunnel. Instead, a pair of Zenoh bridges are used to forward ROS 2 traffic over a unicast TCP connection:

```
  [ Remote client ]                          [ kyon-control  10.24.15.102 ]
  ┌───────────────────────────────┐          ┌───────────────────────────────────┐
  │  ROS 2 (CycloneDDS, :localhost)│          │  ROS 2 (CycloneDDS, robot LAN)    │
  │          ↕                    │          │          ↕                        │
  │  zenoh_bridge_client          │          │  zenoh_bridge_server              │
  │  (eclipse/zenoh-bridge-ros2dds│          │  (eclipse/zenoh-bridge-ros2dds)   │
  │   -e tcp/10.24.15.102:7447)   │          │   listens on :7447                │
  └───────────────┬───────────────┘          └──────────────▲────────────────────┘
                  │        WireGuard tunnel (TCP/7447)       │
                  └──────────────────────────────────────────┘
```

- **`zenoh_bridge_server`** runs on `kyon-control` as part of the `kyon-noble-ros2` Docker stack. It bridges the local CycloneDDS network (using `network/cyclone/cyclonedds-control.xml`) to a Zenoh endpoint that listens on port `7447`.
- **`zenoh_bridge_client`** runs on the remote client. It connects to `kyon-control:7447` through the WireGuard tunnel and re-exposes the bridged topics as a local ROS 2 network. `ROS_AUTOMATIC_DISCOVERY_RANGE=LOCALHOST` ensures the client's ROS 2 graph stays isolated from any other local DDS traffic.

### 4. Reaching the robot over VPN

Once the VPN tunnel is up, the full robot LAN is reachable:

```bash
$ ssh_control    # → kyon@kyon-control  (10.24.15.102)
$ ssh_embedded   # → embedded@amax-kyon-iit  (10.24.15.100)
```

