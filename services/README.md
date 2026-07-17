# Kyon systemd services

## Setup

**Embedded**
```
$ sudo cp services/xbot2_host_monitor_embedded.service /etc/systemd/system/
$ sudo systemctl enable xbot2_host_monitor_embedded
$ sudo systemctl start xbot2_host_monitor_embedded
```