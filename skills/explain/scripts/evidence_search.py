#!/usr/bin/env python3
"""Search repository evidence with rg-compatible output."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
from pathlib import Path


def print_limited(lines: list[str], max_total: int) -> None:
    limit = len(lines) if max_total <= 0 else min(len(lines), max_total)
    for line in lines[:limit]:
        print(line)
    if max_total > 0 and len(lines) > max_total:
        print(f"# truncated: showing {max_total} of {len(lines)} matches")


def run_rg(root: Path, patterns: list[str], globs: list[str], max_count: int, max_total: int) -> int:
    cmd = ["rg", "--line-number", "--hidden", "--glob", "!.git", "--glob", "!.pio"]
    for pattern in patterns:
        cmd.extend(["-e", pattern])
    for item in globs:
        cmd.extend(["--glob", item])
    if max_count > 0:
        cmd.extend(["--max-count", str(max_count)])
    proc = subprocess.run(
        cmd,
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    if proc.stdout:
        print_limited(proc.stdout.splitlines(), max_total)
    if proc.stderr:
        print(proc.stderr, end="")
    return proc.returncode


def fallback_search(root: Path, patterns: list[str], max_count: int, max_total: int) -> int:
    lowered = [p.lower() for p in patterns]
    ignored = {".git", ".pio", "node_modules", "__pycache__"}
    hits = 0
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ignored]
        for name in filenames:
            path = Path(dirpath) / name
            try:
                text = path.read_text(encoding="utf-8", errors="replace")
            except OSError:
                continue
            per_file = 0
            for lineno, line in enumerate(text.splitlines(), 1):
                if any(p in line.lower() for p in lowered):
                    rel = path.relative_to(root).as_posix()
                    print(f"{rel}:{lineno}:{line}")
                    hits += 1
                    per_file += 1
                    if max_total > 0 and hits >= max_total:
                        print(f"# truncated: showing {max_total} matches")
                        return 0
                    if max_count > 0 and per_file >= max_count:
                        break
    return 0 if hits else 1


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("patterns", nargs="+", help="Literal or regex patterns to search.")
    parser.add_argument("--root", default=".", help="Project root.")
    parser.add_argument("--glob", action="append", default=[], help="rg glob filter, repeatable.")
    parser.add_argument("--max-count", type=int, default=20, help="Max matches per file. 0 disables.")
    parser.add_argument("--max-total", type=int, default=200, help="Max total matches printed. 0 disables.")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    if shutil.which("rg"):
        return run_rg(root, args.patterns, args.glob, args.max_count, args.max_total)
    return fallback_search(root, args.patterns, args.max_count, args.max_total)


if __name__ == "__main__":
    raise SystemExit(main())
