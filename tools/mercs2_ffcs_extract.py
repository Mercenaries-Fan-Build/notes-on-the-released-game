#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Extract FFCS chunks + path list from Mercenaries 2 .wad files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow running as script without package install
sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract Mercenaries 2 FFCS chunks")
    ap.add_argument("wad", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    args = ap.parse_args()

    arch = parse_ffcs(args.wad)
    raw = args.wad.read_bytes()
    args.out.mkdir(parents=True, exist_ok=True)

    manifest = {
        "wad": str(args.wad),
        "version": arch.version,
        "chunk_count": arch.chunk_count,
        "file_size": arch.file_size,
        "chunks": [],
    }
    paths: list[str] = []

    for c in arch.chunks:
        manifest["chunks"].append({"tag": c.tag, "offset": c.offset, "meta": c.meta, "size": c.size})
        if c.size == 0:
            continue
        out_path = args.out / f"{c.tag.lower()}.bin"
        out_path.write_bytes(extract_slice(raw, c))

    pths = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    if pths:
        pb = extract_slice(raw, pths)
        paths = dump_paths_from_pths(pb)
        (args.out / "paths.txt").write_text("\n".join(paths), encoding="utf-8")
        manifest["path_strings"] = len(paths)

    (args.out / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} ({len(paths)} paths)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
