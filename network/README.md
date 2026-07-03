# Kyon 03 network setup

## Router setup

- IP: `10.24.15.1`
- Hostname: `kyon03-robot`
- User: admin
- Password: you should know...
- DHCP server enabled, with the following static IP addresses

| Hostname        | IPv4-Address | MAC-Address       | Remaining Lease Time |
|-----------------|--------------|-------------------|----------------------|
| ed-power-board  | 10.24.15.200 | 02:80:E1:09:B5:89 | 23h 50m 54s          |
| amax-kyon-iit   | 10.24.15.100 | CC:82:7F:92:44:13 | 23h 49m 1s           |
| kyon-control    | 10.24.15.102 | A8:2B:DD:CE:AA:25 | 23h 48m 26s          |

 - Port forwarding is enabled:
   - `*:22` --> `kyon-control:22` (ssh, control pc)
   - `*:23` --> `amax-kyon-iit:22` (ssh, embedded pc)
   - `*:9001` --> `ed-power-board:80` (power board gui)