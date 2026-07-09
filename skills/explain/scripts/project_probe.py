#!/usr/bin/env python3
"""Collect lightweight repository facts for project explanation tasks."""

from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
from collections import Counter
from pathlib import Path


MANIFEST_NAMES = {
    "package.json",
    "Cargo.toml",
    "pyproject.toml",
    "CMakeLists.txt",
    "Makefile",
    "platformio.ini",
    "pom.xml",
    "go.mod",
    "requirements.txt",
}

CONTEXT_NAMES = {
    "PROJECT_CONTEXT.md",
    "project_index.md",
    "README.md",
    "README",
    "AGENTS.md",
    "CLAUDE.md",
    "00_阅读引导.md",
}

NUMBERED_CONTENT_DIR = re.compile(r"^\d{2}_")
SUPPORT_DIRS = ("_scripts", "_demos", "_figures")

EXT_LANG = {
    ".c": "C",
    ".cc": "C++",
    ".cpp": "C++",
    ".cxx": "C++",
    ".h": "C/C++ header",
    ".hpp": "C++ header",
    ".ino": "Arduino",
    ".py": "Python",
    ".js": "JavaScript",
    ".ts": "TypeScript",
    ".tsx": "TSX",
    ".jsx": "JSX",
    ".rs": "Rust",
    ".go": "Go",
    ".java": "Java",
    ".md": "Markdown",
    ".toml": "TOML",
    ".ini": "INI",
    ".yml": "YAML",
    ".yaml": "YAML",
    ".json": "JSON",
}


def run_git(root: Path, args: list[str]) -> tuple[int, str]:
    proc = subprocess.run(
        ["git", *args],
        cwd=root,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    return proc.returncode, proc.stdout.strip()


def git_files(root: Path) -> list[str] | None:
    code, out = run_git(root, ["-c", "core.quotepath=false", "ls-files", "--cached", "--others", "--exclude-standard"])
    if code != 0:
        return None
    return [line for line in out.splitlines() if line]


def walk_files(root: Path) -> list[str]:
    ignored = {".git", ".hg", ".svn", ".pio", "node_modules", "__pycache__"}
    files: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in ignored]
        base = Path(dirpath)
        for name in filenames:
            path = base / name
            try:
                files.append(path.relative_to(root).as_posix())
            except ValueError:
                continue
    return files


def collect(root: Path) -> dict:
    root = root.resolve()
    files = git_files(root)
    source = "git ls-files"
    if files is None:
        files = walk_files(root)
        source = "filesystem walk"

    ext_counts = Counter(Path(f).suffix.lower() or "[no extension]" for f in files)
    lang_counts = Counter(EXT_LANG.get(ext, ext) for ext, count in ext_counts.items() for _ in range(count))

    manifests = [f for f in files if Path(f).name in MANIFEST_NAMES]
    context_docs = [f for f in files if Path(f).name in CONTEXT_NAMES or f.startswith("docs/")]

    code, status = run_git(root, ["status", "--short"])
    git_status = status.splitlines() if code == 0 and status else []
    code, recent = run_git(root, ["log", "-5", "--name-only", "--pretty=format:%h %s"])
    recent_lines = recent.splitlines() if code == 0 and recent else []

    top_dirs = Counter(Path(f).parts[0] if Path(f).parts else "." for f in files)
    root_dir_names = {path.name for path in root.iterdir() if path.is_dir()}
    numbered_dirs = sorted(name for name in root_dir_names if NUMBERED_CONTENT_DIR.match(name))
    support_dirs = [name for name in SUPPORT_DIRS if name in root_dir_names]
    entry_docs = [f for f in files if Path(f).name in {"00_阅读引导.md", "README.md", "README", "project_index.md"}]

    repo_shape = "code-first"
    if "00_阅读引导.md" in {Path(f).name for f in files} or (numbered_dirs and support_dirs):
        repo_shape = "docs-first"

    return {
        "root": str(root),
        "repo_shape": repo_shape,
        "file_source": source,
        "file_count": len(files),
        "top_directories": top_dirs.most_common(20),
        "entry_docs": entry_docs[:20],
        "numbered_content_dirs": numbered_dirs[:20],
        "support_dirs": support_dirs,
        "languages": lang_counts.most_common(20),
        "manifests": manifests[:50],
        "context_docs": context_docs[:80],
        "git_status": git_status[:80],
        "recent_git_activity": recent_lines[:120],
    }


def print_markdown(data: dict) -> None:
    print(f"# Project Probe\n\nRoot: `{data['root']}`")
    print(f"\nRepo shape: `{data['repo_shape']}`")
    print(f"\nFiles: {data['file_count']} ({data['file_source']})")
    print("\n## Entry Docs")
    for item in data["entry_docs"] or ["[none found]"]:
        print(f"- `{item}`")
    print("\n## Numbered Content Directories")
    for item in data["numbered_content_dirs"] or ["[none found]"]:
        print(f"- `{item}`")
    print("\n## Support Directories")
    for item in data["support_dirs"] or ["[none found]"]:
        print(f"- `{item}`")
    print("\n## Languages")
    for name, count in data["languages"]:
        print(f"- {name}: {count}")
    print("\n## Top Directories")
    for name, count in data["top_directories"]:
        print(f"- `{name}`: {count}")
    print("\n## Manifests")
    for item in data["manifests"] or ["[none found]"]:
        print(f"- `{item}`")
    print("\n## Context Docs")
    for item in data["context_docs"] or ["[none found]"]:
        print(f"- `{item}`")
    print("\n## Git Status")
    for item in data["git_status"] or ["clean or unavailable"]:
        print(f"- `{item}`")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", nargs="?", default=".", help="Project root to inspect.")
    parser.add_argument("--format", choices=["json", "md"], default="md")
    args = parser.parse_args()

    data = collect(Path(args.root))
    if args.format == "json":
        print(json.dumps(data, ensure_ascii=False, indent=2))
    else:
        print_markdown(data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
