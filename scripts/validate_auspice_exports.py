#!/usr/bin/env python3
"""Validate Auspice JSON exports before publishing them to GitHub."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


DEFAULT_MAX_BYTES = 100 * 1024 * 1024
DEFAULT_WARNING_BYTES = 95 * 1024 * 1024


def validate_export(path: Path, max_bytes: int, warning_bytes: int) -> bool:
    if not path.is_file():
        print(f"ERROR: Auspice export not found: {path}", file=sys.stderr)
        return False

    size = path.stat().st_size
    if size >= max_bytes:
        print(
            f"ERROR: {path.name} is {size:,} bytes; GitHub files must remain "
            f"below {max_bytes:,} bytes.",
            file=sys.stderr,
        )
        return False

    try:
        with path.open(encoding="utf-8") as handle:
            document = json.load(handle)
    except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        print(f"ERROR: invalid JSON in {path}: {exc}", file=sys.stderr)
        return False

    if not isinstance(document, dict):
        print(f"ERROR: expected a JSON object in {path}", file=sys.stderr)
        return False

    if path.name == "ncov_Pakistan.json":
        missing = {"meta", "tree"} - document.keys()
        if missing:
            print(
                f"ERROR: {path.name} is missing required Auspice keys: "
                f"{', '.join(sorted(missing))}",
                file=sys.stderr,
            )
            return False

    if size >= warning_bytes:
        print(
            f"WARNING: {path.name} is {size:,} bytes and is approaching "
            "GitHub's file-size limit.",
            file=sys.stderr,
        )

    print(f"Validated {path.name}: {size:,} bytes")
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Validate Auspice JSON structure and GitHub file-size limits."
    )
    parser.add_argument("files", nargs="+", type=Path)
    parser.add_argument("--max-bytes", type=int, default=DEFAULT_MAX_BYTES)
    parser.add_argument("--warning-bytes", type=int, default=DEFAULT_WARNING_BYTES)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.max_bytes <= 0 or args.warning_bytes < 0:
        print("ERROR: size thresholds must be non-negative.", file=sys.stderr)
        return 2

    results = [
        validate_export(path, args.max_bytes, args.warning_bytes)
        for path in args.files
    ]
    return 0 if all(results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
