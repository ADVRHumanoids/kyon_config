#!/usr/bin/env python3
"""Query connected Kyon parts: exit 0 if present, 1 if absent, 2 on error.

A part is present when at least one of its mapped joint IDs is discovered.
Run inside a sourced Kyon environment with the EtherCAT master running.
"""

import argparse
from pathlib import Path
import re
import sys

import yaml

from robot_description import DEFAULT_JOINT_MAP, FEATURE_PATTERNS, discover_positions, load_joint_map


PARTS = {"arms": "upper_body", "wheels": "wheels", "daganas": "dagana", "legs": "legs"}


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("part", choices=PARTS)
    parser.add_argument("--joint-map", type=Path, default=DEFAULT_JOINT_MAP)
    parser.add_argument("--uri", default="localhost:5555", help="EtherCAT master host:port")
    args = parser.parse_args(argv)
    try:
        joint_map = load_joint_map(args.joint_map)
        positions = discover_positions(args.uri)
        pattern = FEATURE_PATTERNS[PARTS[args.part]]
        present = any(
            board_id in positions and re.fullmatch(pattern, name)
            for board_id, name in joint_map.items()
        )
        return 0 if present else 1
    except (OSError, ValueError, RuntimeError, KeyError, TypeError, ImportError, yaml.YAMLError) as exc:
        print(f"kyon_detect: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
