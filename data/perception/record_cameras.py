#!/usr/bin/env python3
"""Record live ZED cameras until interrupted, then stop recording."""

import argparse
import json
import signal
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


class StopRequested(Exception):
    pass


def api_request(base_url, path, method="GET", data=None):
    body = None if data is None else json.dumps(data).encode("utf-8")
    request = Request(
        base_url.rstrip("/") + path,
        data=body,
        method=method,
        headers={"Content-Type": "application/json"} if body else {},
    )
    with urlopen(request, timeout=5) as response:
        content = response.read()
    return json.loads(content) if content else None


def find_live_cameras(base_url):
    paths = api_request(base_url, "/v3/paths/list")["items"]
    cameras = {}
    for camera in ("zed_up", "zed_down"):
        matches = [
            path for path in paths
            if path["name"].startswith(camera + "_") and path.get("ready")
        ]
        if len(matches) > 1:
            raise RuntimeError(f"Found multiple ready {camera} streams")
        if matches:
            cameras[camera] = matches[0]

    if not cameras:
        raise RuntimeError("No ready ZED camera streams found")
    if {path["confName"] for path in cameras.values()} != {"all"}:
        raise RuntimeError("Ready ZED cameras do not all use the 'all' configuration")
    return cameras


def request_stop(_signum, _frame):
    raise StopRequested


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--api-url", default="http://127.0.0.1:9997", help="MediaMTX API base URL"
    )
    args = parser.parse_args()

    cameras = find_live_cameras(args.api_url)
    for signum in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(signum, request_stop)

    recording_requested = False
    try:
        # A request can reach MediaMTX even if the response is interrupted.
        recording_requested = True
        api_request(args.api_url, "/v3/config/paths/patch/all", "PATCH", {"record": True})
        for camera, path in cameras.items():
            print(f"Recording enabled for {camera}: {path['name']}", flush=True)
        print("Press Ctrl+C to stop recording", flush=True)
        while True:
            signal.pause()
    except (KeyboardInterrupt, StopRequested):
        pass
    finally:
        if recording_requested:
            api_request(args.api_url, "/v3/config/paths/patch/all", "PATCH", {"record": False})
            print("Recording disabled", flush=True)


if __name__ == "__main__":
    try:
        main()
    except (HTTPError, URLError, KeyError, ValueError, RuntimeError) as exc:
        print(f"Recording error: {exc}", file=sys.stderr)
        sys.exit(1)
