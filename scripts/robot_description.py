#!/usr/bin/env python3
"""Expand Kyon's URDF/SRDF using devices discovered through xbot2_cli.ecat.

Run inside a sourced Kyon ROS 2 environment. By default stdout contains two
consecutive XML documents; select 'urdf' or 'srdf' for a single XML document.
Arms, legs, wheels and Dagana are detected from mapped robot IDs; varta is true.
"""

import argparse
from contextlib import redirect_stdout
from pathlib import Path
import re
import shlex
import subprocess
import sys

import yaml


DEFAULT_JOINT_MAP = (
    Path(__file__).resolve().parents[1] / "xbot2/joint_map/joint_map.yaml"
)
FEATURE_PATTERNS = {
    "upper_body": r"(?:shoulder_yaw|shoulder_pitch|elbow_pitch|wrist_pitch|wrist_yaw)_\d+",
    "legs": r"(?:hip_roll|hip_pitch|knee_pitch)_\d+",
    "dagana": r"dagana_\d+_clamp_joint",
    "wheels": r"(?:ankle_yaw|wheel_joint)_\d+",
}
CHAIN_ORDER = {
    "arm": ("shoulder_yaw", "shoulder_pitch", "elbow_pitch", "wrist_pitch", "wrist_yaw"),
    "leg": ("hip_roll", "hip_pitch", "knee_pitch", "ankle_yaw", "wheel_joint"),
}


def load_joint_map(path):
    with path.open() as stream:
        data = yaml.safe_load(stream)
    if not isinstance(data, dict) or not isinstance(data.get("joint_map"), dict):
        raise ValueError(f"{path}: expected a 'joint_map' mapping")
    result = {}
    for board_id, name in data["joint_map"].items():
        if not isinstance(name, str):
            raise ValueError(f"{path}: invalid joint name for ID {board_id}")
        result[int(board_id)] = name
    if not result:
        raise ValueError(f"{path}: joint_map is empty")
    return result


def discover_positions(uri):
    # Redirect library diagnostics as well, leaving stdout exclusively for XML.
    with redirect_stdout(sys.stderr):
        from xbot2_cli.ecat.api import reply_cmd, set_uri
        from xbot2_cli.ecat.base_io import master_cmd_get_slave_descr

        set_uri(uri)
        try:
            slaves = reply_cmd(master_cmd_get_slave_descr)
        except KeyError as exc:
            raise RuntimeError(f"EtherCAT discovery failed at {uri}; is the master running?") from exc
    if not isinstance(slaves, dict) or not slaves:
        raise RuntimeError(f"No EtherCAT slave descriptions returned by {uri}")
    # robot_id is the logical ID in joint_map, unlike EtherCAT bus position.
    positions = {}
    for slave in slaves.values():
        board_id = int(slave["robot_id"])
        if board_id < 0:
            continue
        position = int(slave["position"])
        if board_id in positions:
            raise ValueError(
                f"Duplicate robot ID {board_id} at bus positions "
                f"{positions[board_id]} and {position}"
            )
        positions[board_id] = position
    if not positions:
        raise RuntimeError("EtherCAT discovery returned no assigned robot IDs")
    return positions


def check_joint_order(joint_map, positions):
    """Check proximal-to-distal order within each chain, allowing missing joints.

    Compare EtherCAT positions, not response/YAML insertion order. Different
    limbs need not appear in any particular order or at contiguous positions.
    """
    chains = {}
    for board_id, name in joint_map.items():
        if board_id not in positions:
            continue
        joint, separator, limb = name.rpartition("_")
        if not separator or not limb.isdigit():
            continue
        for kind, order in CHAIN_ORDER.items():
            if joint in order:
                chains.setdefault((kind, int(limb)), []).append((order.index(joint), board_id))
                break
    errors = []
    for (kind, limb), joints in sorted(chains.items()):
        expected = [board_id for _, board_id in sorted(joints)]
        actual = sorted(expected, key=positions.__getitem__)
        if actual != expected:
            def describe(ids):
                return " -> ".join(
                    f"{board_id} ({joint_map[board_id]}, bus position {positions[board_id]})"
                    for board_id in ids
                )
            errors.append(
                f"{kind} {limb}:\n  expected: {describe(expected)}\n  actual:   {describe(actual)}"
            )
    if errors:
        raise ValueError("Incorrect joint ID order on EtherCAT bus:\n" + "\n".join(errors))


def detect_arguments(joint_map, ids):
    if not ids.intersection(joint_map):
        raise ValueError("No discovered robot IDs match the joint map")
    unknown = ids.difference(joint_map)
    if unknown:
        print(f"Warning: unmapped robot IDs: {sorted(unknown)}", file=sys.stderr)
    arguments = {"varta": "true"}
    for feature, pattern in FEATURE_PATTERNS.items():
        expected = {bid for bid, name in joint_map.items() if re.fullmatch(pattern, name)}
        present = expected.intersection(ids)
        arguments[feature] = "true" if present else "false"
        if present and present != expected:
            missing = [joint_map[bid] for bid in sorted(expected - present)]
            print(
                f"Warning: partial {feature}; enabling the whole xacro section. "
                f"Missing: {', '.join(missing)}",
                file=sys.stderr,
            )
    return arguments


def xacro_command(description, arguments):
    package = f"kyon_{description}"
    prefix = subprocess.run(
        ["ros2", "pkg", "prefix", "--share", package],
        check=True, stdout=subprocess.PIPE, text=True,
    ).stdout.strip()
    source = Path(prefix) / description / f"kyon.{description}.xacro"
    return ["xacro", str(source)] + [f"{key}:={value}" for key, value in arguments.items()]


def expand(description, arguments):
    return subprocess.run(
        xacro_command(description, arguments), check=True, stdout=subprocess.PIPE, text=True,
    ).stdout


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("description", choices=("urdf", "srdf", "both"), nargs="?", default="both")
    parser.add_argument("--joint-map", type=Path, default=DEFAULT_JOINT_MAP)
    parser.add_argument("--uri", default="localhost:5555", help="EtherCAT master host:port")
    parser.add_argument(
        "--print-xacro-call", action="store_true",
        help="print shell-quoted xacro commands without invoking xacro",
    )
    parser.add_argument(
        "--warn-on-wrong-order", action="store_true",
        help="warn about incorrect joint order and continue instead of failing",
    )
    parser.add_argument(
        "--xacro-arg", action="append", default=[], metavar="NAME:=VALUE",
        help="override/add a xacro argument (repeatable); varta remains true",
    )
    args = parser.parse_args(argv)
    overrides = {}
    for assignment in args.xacro_arg:
        name, separator, value = assignment.partition(":=")
        if not separator or not name or not value:
            parser.error("--xacro-arg requires NAME:=VALUE")
        overrides[name] = value
    if overrides.get("varta", "true") != "true":
        parser.error("varta must remain true")
    try:
        joint_map = load_joint_map(args.joint_map)
        positions = discover_positions(args.uri)
        try:
            check_joint_order(joint_map, positions)
        except ValueError as exc:
            if not args.warn_on_wrong_order:
                raise
            print(f"Warning: {exc}", file=sys.stderr)
        arguments = detect_arguments(joint_map, set(positions))
        arguments.update(overrides)
        print("Xacro arguments: " + " ".join(f"{k}:={v}" for k, v in arguments.items()), file=sys.stderr)
        descriptions = ("urdf", "srdf") if args.description == "both" else (args.description,)
        if args.print_xacro_call:
            commands = [xacro_command(description, arguments) for description in descriptions]
            for command in commands:
                print(shlex.join(command))
            return 0
        # Complete both expansions before emitting output, avoiding partial output on failure.
        documents = [expand(description, arguments) for description in descriptions]
        for document in documents:
            sys.stdout.write(document)
            if not document.endswith("\n"):
                sys.stdout.write("\n")
    except (OSError, ValueError, RuntimeError, KeyError, TypeError, ImportError, yaml.YAMLError, subprocess.CalledProcessError) as exc:
        print(f"robot_description: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
