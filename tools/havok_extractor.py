#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Slice Havok binary tags (hkxp / packfile snippets) from Mercenaries 2 blobs."""

from __future__ import annotations

import argparse
import json
import math
import re
import struct
from pathlib import Path

HK_TAGS = (b"hkxp", b"<hkpackfile", b"Havok")
CONVEX_KW = b"hkpConvexVerticesShape"


def valid_vec3(x: float, y: float, z: float) -> bool:
    if not all(math.isfinite(v) for v in (x, y, z)):
        return False
    if max(abs(x), abs(y), abs(z)) > 5e6:
        return False
    return True


def longest_vec3_run(data: bytes, start: int, end: int, limit: int = 4096) -> list[tuple[float, float, float]]:
    best: list[tuple[float, float, float]] = []
    cur: list[tuple[float, float, float]] = []
    i = start
    while i + 12 <= min(end, start + limit * 12):
        x, y, z = struct.unpack_from("<fff", data, i)
        if valid_vec3(x, y, z):
            cur.append((x, y, z))
        else:
            if len(cur) > len(best):
                best = cur
            cur = []
        i += 12
    if len(cur) > len(best):
        best = cur
    return best


def write_obj_lines(path: Path, verts: list[tuple[float, float, float]]) -> None:
    lines = ["# Mercenaries 2 Havok heuristic convex hull vertices", "o hull"]
    for x, y, z in verts:
        lines.append(f"v {x:.6g} {y:.6g} {z:.6g}")
    if len(verts) >= 3:
        for i in range(len(verts) - 2):
            lines.append(f"f {i+1} {i+2} {i+3}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def find_all(data: bytes, needle: bytes) -> list[int]:
    out = []
    start = 0
    while True:
        i = data.find(needle, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out


def extract_slice(data: bytes, start: int, max_len: int) -> bytes:
    end = min(len(data), start + max_len)
    return data[start:end]


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract Havok-related binary slices")
    ap.add_argument("blob", type=Path)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument("--max-len", type=int, default=262144, help="Max bytes per slice")
    ap.add_argument("--emit-convex-obj", action="store_true", help="Best-effort OBJ from vec3 runs near hkpConvexVerticesShape")
    args = ap.parse_args()

    data = args.blob.read_bytes()
    args.out_dir.mkdir(parents=True, exist_ok=True)

    hits: list[dict[str, object]] = []
    n = 0
    for tag in HK_TAGS:
        for off in find_all(data, tag):
            chunk = extract_slice(data, off, args.max_len)
            fn = args.out_dir / f"havok_{n:04d}_{tag.decode('ascii', errors='replace').strip('<')}.bin"
            fn.write_bytes(chunk)
            ascii_snips = re.findall(rb"[ -~]{8,}", chunk[:4096])
            preview = ascii_snips[0].decode("ascii", errors="replace")[:120] if ascii_snips else ""
            hits.append({"file": fn.name, "offset": off, "tag": tag.decode("ascii", errors="replace"), "size_written": len(chunk), "preview": preview})
            n += 1

    convex_meta: list[dict[str, object]] = []
    if args.emit_convex_obj:
        c = 0
        for off in find_all(data, CONVEX_KW):
            verts = longest_vec3_run(data, off + len(CONVEX_KW), min(len(data), off + 65536))
            if len(verts) >= 4:
                fn = args.out_dir / f"convex_hull_{c:04d}.obj"
                write_obj_lines(fn, verts)
                convex_meta.append({"offset": off, "vertices": len(verts), "obj": fn.name})
                c += 1

    manifest = {"havok_slices": hits}
    if convex_meta:
        manifest["convex_heuristic"] = convex_meta

    (args.out_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(f"Wrote {len(hits)} slices to {args.out_dir}" + (f", {len(convex_meta)} convex OBJ" if convex_meta else ""))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
