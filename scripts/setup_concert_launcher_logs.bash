#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# create log dir with current user permissions
sudo install -d -o $(id -u) -g $(id -g) -m 0755 /var/log/concert_launcher

# copy logrotate conf file
sudo cp $SCRIPT_DIR/../diagnostics/concert_launcher_logrotate.conf /etc/logrotate.d/concert-launcher