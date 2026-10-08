# Kyon systemd services

## Setup

**Control**
```bash
sudo cp services/lidar_ptp/linuxptp_lidar.cfg /etc/linuxptp/lidar.cfg
sudo cp services/lidar_ptp/ptp4l-lidar.service /etc/systemd/system/
sudo cp services/lidar_ptp/phc2sys-lidar.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ptp4l-lidar.service phc2sys-lidar.service
```
