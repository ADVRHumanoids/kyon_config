#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cd $SCRIPT_DIR/../diagnostics
source ~/xbot2_diagnostics/.venv/bin/activate
xbot2-host-monitor --config host_monitor.yaml