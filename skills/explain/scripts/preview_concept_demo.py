#!/usr/bin/env python3
"""Serve a local concept demo over HTTP for browser preview."""

from __future__ import annotations

import argparse
import os
import socketserver
from functools import partial
from http.server import SimpleHTTPRequestHandler
from pathlib import Path
from urllib.parse import quote


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Preview a local HTML concept demo through a temporary HTTP server.")
    parser.add_argument("target", type=Path, help="HTML file or directory to serve.")
    parser.add_argument("--bind", default="127.0.0.1", help="Bind address. Default: 127.0.0.1")
    parser.add_argument("--port", type=int, default=8137, help="Port to serve on. Default: 8137")
    return parser.parse_args()


def build_url(root: Path, target: Path, bind: str, port: int) -> str:
    if target.is_dir():
        return f"http://{bind}:{port}/"

    relative = target.relative_to(root).as_posix()
    return f"http://{bind}:{port}/{quote(relative)}"


def main() -> int:
    args = parse_args()
    target = args.target.resolve()
    if not target.exists():
        raise SystemExit(f"Target does not exist: {target}")

    root = target if target.is_dir() else target.parent

    handler = partial(SimpleHTTPRequestHandler, directory=os.fspath(root))
    with socketserver.TCPServer((args.bind, args.port), handler) as httpd:
        url = build_url(root, target, args.bind, args.port)
        print(f"serving -> {root}")
        print(f"url -> {url}")
        print("press Ctrl+C to stop")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nstopped")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
