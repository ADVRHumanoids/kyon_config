#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $SCRIPT_DIR/../diagnostics
source ~/xbot2_diagnostics/.venv/bin/activate
XBOT_DIAG_ENDPOINT=tcp://10.24.15.102:9268 xbot2-host-monitor --config host_monitor.yaml