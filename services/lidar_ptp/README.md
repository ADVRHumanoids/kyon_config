# Kyon systemd services

## Setup

**Control**
```bash
sudo cp services/lidar_ptp/ptp4l-gptp.service /etc/systemd/system/
sudo cp services/lidar_ptp/phc2sys-gptp.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ptp4l-gptp phc2sys-gptp
```
