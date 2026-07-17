#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# clone and install xbot2_diagnosics
cd ~
git clone https://github.com/advrhumanoids/xbot2_diagnostics.git
cd xbot2_diagnostics
python3 -m venv .venv
source .venv/bin/activate
python3 -m pip install --upgrade pip setuptools wheel
python3 -m pip install -e python


