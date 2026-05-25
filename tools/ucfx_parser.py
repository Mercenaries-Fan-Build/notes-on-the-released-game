#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan decompressed Mercenaries 2 blocks for UCFX-style tags and emit JSON."""

from __future__ import annotations

import argparse
import json
import re
import struct
import sys
from pathlib import Path

from ucfx_mesh_codec import CHUNK_HDR, read_chunk_header

KNOWN_TAGS = (
    b"UCFX",
    b"NAME",
    b"INFO",
    b"BODY",
    b"CHDR",
    b"MESH",
    b"GEOM",
    b"INDX",
    b"STAT",
    b"CEXE",
    b"enum",
    b"flgt",
    b"flgs",
    b"DDS ",
    b"DXT1",
    b"DXT3",
    b"DXT5",
)
DXT_TAGS = (b"DXT1", b"DXT3", b"DXT5")


def find_all(data: bytes, needle: bytes) -> list[int]:
    out: list[int] = []
    start = 0
    while True:
        i = data.find(needle, start)
        if i < 0:
            break
        out.append(i)
        start = i + 1
    return out


def ascii_strings(data: bytes, min_len: int = 6) -> list[tuple[int, str]]:
    pat = re.compile(rb"[ -~]{%d,}" % min_len)
    out: list[tuple[int, str]] = []
    for m in pat.finditer(data):
        try:
            out.append((m.start(), m.group().decode("ascii")))
        except Exception:
            pass
    return out


def parse_ucfx_shell(data: bytes, ucfx_off: int) -> dict[str, object]:
    """Best-effort parse of bytes immediately following UCFX magic."""
    if data[ucfx_off : ucfx_off + 4] != b"UCFX":
        return {}
    off = ucfx_off + 4
    if off + 16 > len(data):
        return {}
    a, b, c, d = struct.unpack_from("<IIII", data, off)
    return {"after_ucfx_u32": [a, b, c, d], "note": "sizes/counts vary by asset"}


def chunk_walk_linear(data: bytes, start: int, max_chunks: int = 600) -> list[dict[str, object]]:
    """Best-effort linear sequence of 20-byte chunk headers starting at ``start``."""
    out: list[dict[str, object]] = []
    pos = start
    for _ in range(max_chunks):
        if pos + CHUNK_HDR > len(data):
            break
        tag, u = read_chunk_header(data, pos)
        tag_s = tag.decode("latin1", errors="replace")
        out.append({"offset": pos, "tag": tag_s, "u": [int(x) for x in u]})
        pos += CHUNK_HDR
    return out


def walk_ucfx_geometry_trees(data: bytes) -> list[dict[str, object]]:
    """
    For each GEOM tag, emit a shallow linear chunk preview (debug aid).
    """
    hits = find_all(data, b"GEOM")
    trees: list[dict[str, object]] = []
    for g in hits:
        preview = chunk_walk_linear(data, g, max_chunks=800)
        trees.append({"geom_offset": g, "chunk_preview": preview[:400], "chunk_preview_total": len(preview)})
    return trees


def analyze(path: Path) -> dict[str, object]:
    data = path.read_bytes()
    ucfx_offsets = find_all(data, b"UCFX")
    root_ucfx = ucfx_offsets[0] if ucfx_offsets else -1

    tag_hits: dict[str, list[int]] = {}
    for t in KNOWN_TAGS:
        hits = find_all(data, t)
        if hits:
            tag_hits[t.decode("ascii", errors="replace").strip()] = hits

    dxt = {}
    for t in DXT_TAGS:
        hits = find_all(data, t)
        if hits:
            dxt[t.decode()] = hits

    hk_sigs = []
    for kw in (b"hkxp", b"Havok", b"hkpConvexVerticesShape", b"<hkpackfile"):
        for i in find_all(data, kw):
            hk_sigs.append({"keyword": kw.decode("ascii", errors="replace"), "offset": i})

    manifest: dict[str, object] = {
        "file": str(path),
        "size": len(data),
        "ucfx_offsets": ucfx_offsets,
        "primary_ucfx_offset": root_ucfx,
        "tag_occurrences": tag_hits,
        "dxt_occurrences": dxt,
        "havok_hits": hk_sigs,
        "strings_sample": [{"offset": o, "text": s[:200]} for o, s in ascii_strings(data)[:400]],
    }
    if root_ucfx >= 0:
        manifest["ucfx_header_guess"] = parse_ucfx_shell(data, root_ucfx)

    geom_trees = walk_ucfx_geometry_trees(data)
    if geom_trees:
        manifest["geom_chunk_trees"] = geom_trees

    return manifest


def main() -> int:
    ap = argparse.ArgumentParser(description="UCFX / chunk manifest for decompressed .block blobs")
    ap.add_argument("inputs", nargs="+", type=Path, help="Decompressed binary files")
    ap.add_argument("--out", type=Path, help="Write combined JSON here")
    args = ap.parse_args()

    results = [analyze(p) for p in args.inputs]
    text = json.dumps(results if len(results) > 1 else results[0], indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
        print(f"Wrote {args.out}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
