# WireGuard Setup

Remote access VPN into the Kyon 03 LAN (`10.24.15.0/24`).  
The WireGuard **server** runs on `kyon-control` (`10.24.15.102`), reachable from the WAN on UDP port `51820`.

Peer model:
- **Pilot PC** — static peer, always in `wg0.conf`
- **Additional clients** — added at runtime with `wg set`; non-persistent, cleared on reboot or tunnel restart

---

## 1 · Install (server and each client)

```bash
sudo apt update && sudo apt install -y wireguard
```

---

## 2 · Generate server keypair

Run on **kyon-control**:

```bash
wg genkey | sudo tee /etc/wireguard/server.key | wg pubkey | sudo tee /etc/wireguard/server.pub
sudo chmod 600 /etc/wireguard/server.key
sudo chmod 644 /etc/wireguard/server.pub  # public key should be world readable
sudo chmod +x /etc/wireguard
```

---

## 3 · Configure the server

First, find the LAN interface name:

```bash
ip -br link   # typically eno1, enp3s0, etc.
```

Create `/etc/wireguard/wg0.conf` on **kyon-control**:

```ini
[Interface]
Address    = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <contents of /etc/wireguard/server.key>

# Route traffic into the robot LAN — replace <LAN_IFACE> with actual interface
PostUp   = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eno2 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eno2 -j MASQUERADE

# ── Static peer: Pilot PC ──────────────────────────────────────────────────
[Peer]
# pilot-pc
PublicKey  = <pilot-pc public key>
AllowedIPs = 10.0.0.2/32
```

Enable IPv4 forwarding (persist across reboots):

```bash
echo "net.ipv4.ip_forward=1" | sudo tee /etc/sysctl.d/99-wireguard.conf
sudo sysctl -p /etc/sysctl.d/99-wireguard.conf
```

---

## 4 · Start the server

```bash
sudo systemctl enable --now wg-quick@wg0
sudo wg show   # verify
```

---

## 5 · Pilot PC client setup

Generate a keypair on the **pilot PC**:

```bash
wg genkey | tee ~/pilot.key | wg pubkey | tee ~/pilot.pub
```

Hand `~/pilot.pub` to whoever manages `wg0.conf` to fill in the static peer block above.

Create `~/wg-kyon.conf` on the **pilot PC**:

```ini
[Interface]
Address    = 10.0.0.2/24
PrivateKey = <contents of ~/pilot.key>

[Peer]
PublicKey           = <contents of /etc/wireguard/server.pub on kyon-control>
Endpoint            = <kyon-control public IP>:51820
AllowedIPs          = 10.0.0.0/24, 10.24.15.0/24
PersistentKeepalive = 25
```

```bash
sudo wg-quick up ~/wg-kyon.conf
```

---

## 6 · Dynamic peers (non-persistent)

Use `wg set` to register a peer at runtime without editing any config file.  
The peer is **removed automatically** when the tunnel is restarted or the machine reboots.

### Add a dynamic peer (run on kyon-control)

```bash
sudo wg set wg0 peer <CLIENT_PUBKEY> allowed-ips 10.0.0.<N>/32
```

### Remove a dynamic peer manually

```bash
sudo wg set wg0 peer <CLIENT_PUBKEY> remove
```

### Client config for a dynamic peer

```ini
[Interface]
Address    = 10.0.0.<N>/24
PrivateKey = <client private key>

[Peer]
PublicKey           = <contents of /etc/wireguard/server.pub on kyon-control>
Endpoint            = <kyon-control public IP>:51820
AllowedIPs          = 10.0.0.0/24, 10.24.15.0/24
PersistentKeepalive = 25
```

---

## 7 · Dynamic peers via `connect-wg.bash`

`connect-wg.bash` automates the dynamic peer workflow (section 6) for any client machine.  
It SSHs into `kyon-control`, picks the next free VPN address (`10.0.0.10–254`), registers the peer, writes a temporary tunnel config to `/tmp/wg-kyon.conf`, and brings up the tunnel — all in one step.

### Prerequisites

Install the required tools on the **client**:

```bash
sudo apt install -y wireguard sshpass
```

SSH access to `kyon@kyon03-robot` must be reachable from the client (either on the LAN or via a jump host).

### Connect

```bash
./connect-wg.bash
```

You will be prompted for the password of `kyon@kyon03-robot`.  
On first run the script generates a keypair under `~/.wireguard/` (`kyon.key` / `kyon.pub`).  
After connecting it prints the assigned VPN IP and reachable hosts:

```
Connected as 10.0.0.10
  kyon-control   10.24.15.102  (10.0.0.1)
  amax-kyon-iit  10.24.15.100
  ed-power-board 10.24.15.200
```

### Disconnect

```bash
./connect-wg.bash down
```

This removes the peer from the server and tears down the local tunnel.  
The peer is also cleared automatically on server reboot or tunnel restart.

---

## 8 · Verify connectivity

```bash
# from any client
ping 10.0.0.1        # kyon-control VPN address
ping 10.24.15.102    # kyon-control LAN
ping 10.24.15.100    # amax-kyon-iit
ping 10.24.15.200    # ed-power-board

# on the server — show active tunnels and last handshake times
sudo wg show
```

---

## Quick reference

| Host           | LAN IP        | VPN IP    | Peer type |
|----------------|---------------|-----------|-----------|
| kyon-control   | 10.24.15.102  | 10.0.0.1  | server    |
| pilot-pc       | —             | 10.0.0.2  | static    |
| amax-kyon-iit  | 10.24.15.100  | —         | —         |
| ed-power-board | 10.24.15.200  | —         | —         |
| *dynamic-N*    | —             | 10.0.0.N  | dynamic   |
