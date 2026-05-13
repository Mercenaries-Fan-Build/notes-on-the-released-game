#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Harvest localization-like bracket keys from Mercenaries 2 blobs (full lists, no truncation)."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

_RE_BRACKET = re.compile(rb"\[[A-Za-z][A-Za-z0-9_.]+\]")
_RE_GENERIC = re.compile(rb"\[Generic\.[^\]]+\]")


def harvest_blob(path: Path) -> dict[str, object]:
    """Scan blob bytes for bracket-like keys. Each key list is complete; ``len(list) == *_count``."""
    data = path.read_bytes()
    keys = sorted(set(m.group().decode("ascii", errors="replace") for m in _RE_BRACKET.finditer(data)))
    generic = sorted(set(m.group().decode("ascii", errors="replace") for m in _RE_GENERIC.finditer(data)))
    utf16_keys: list[str] = []
    # naive UTF-16LE bracket scan (slow paths only when small)
    if len(data) < 50_000_000:
        try:
            txt = data.decode("utf-16-le", errors="ignore")
            utf16_keys = sorted(set(re.findall(r"\[[A-Za-z][A-Za-z0-9_.]+\]", txt)))
        except Exception:
            pass
    return {
        "file": str(path),
        "size": len(data),
        "bracket_keys": keys,
        "bracket_keys_count": len(keys),
        "generic_keys": generic,
        "generic_keys_count": len(generic),
        "utf16_bracket_keys": utf16_keys,
        "utf16_bracket_keys_count": len(utf16_keys),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 dialog / localization string harvest")
    ap.add_argument("blobs", nargs="+", type=Path)
    ap.add_argument("--out", type=Path, help="Combined JSON output")
    args = ap.parse_args()

    rows = [harvest_blob(p) for p in args.blobs]
    text = json.dumps(rows if len(rows) > 1 else rows[0], indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
        print(f"Wrote {args.out}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
