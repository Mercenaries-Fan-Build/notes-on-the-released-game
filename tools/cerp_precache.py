#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Inspect Mercenaries 2 PC Precache (CERP) files — header + first records."""

from __future__ import annotations

import argparse
import json
import struct
from pathlib import Path
from typing import Any


def inspect_cerp(path: Path, dump: int) -> dict[str, Any]:
    data = path.read_bytes()
    preview = data[: min(dump, len(data))].hex(" ", 1)
    if data[:4] != b"CERP":
        return {
            "path": str(path.resolve()),
            "valid": False,
            "magic_ascii": data[:4].decode("ascii", errors="replace"),
            "size": len(data),
            "header_hex_preview": preview,
        }
    ver, = struct.unpack_from("<I", data, 4)
    return {
        "path": str(path.resolve()),
        "valid": True,
        "magic": "CERP",
        "version": ver,
        "size": len(data),
        "header_hex_preview": preview,
    }


def read_cerp_cli(path: Path, dump: int) -> None:
    info = inspect_cerp(path, dump)
    if not info.get("valid"):
        print(f"{path}: not CERP (magic {info.get('magic_ascii', info.get('magic'))!r})")
        return
    print(f"{path.name}: CERP version={info['version']} size={info['size']}")
    print(info["header_hex_preview"])


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 CERP precache header inspect")
    ap.add_argument("precache", type=Path, nargs="+")
    ap.add_argument("--bytes", type=int, default=256, help="Bytes included in header_hex_preview")
    ap.add_argument("--json", action="store_true", help="Print JSON array to stdout")
    ap.add_argument("--out", type=Path, help="Write same JSON array to this file")
    args = ap.parse_args()

    rows = [inspect_cerp(p, args.bytes) for p in args.precache if p.is_file()]

    if args.json or args.out:
        text = json.dumps(rows, indent=2)
        if args.out:
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_text(text, encoding="utf-8")
            print(f"Wrote {args.out}")
        if args.json:
            print(text)
        return 0

    for p in args.precache:
        if p.is_file():
            read_cerp_cli(p, args.bytes)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
