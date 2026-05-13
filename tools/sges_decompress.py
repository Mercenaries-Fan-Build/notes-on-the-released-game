#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Decompress Mercenaries 2 DATA chunks: each logical `.block` is an `sges` segment."""

from __future__ import annotations

import argparse
import json
import math
import mmap as mmap_mod
import re
import struct
import sys
import zlib
from pathlib import Path as PathLib

import typing as _t

THIS_DIR = PathLib(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402

SGES_MAGIC = b"sges"


def sges_data_offset(num_segments: int) -> int:
    return math.ceil((16 + num_segments * 8) / 16) * 16


def parse_sges_header(blob: bytes, off: int = 0) -> tuple[int, int, int, int]:
    if blob[off : off + 4] != SGES_MAGIC:
        raise ValueError("bad sges magic")
    major, minor = struct.unpack_from("<HH", blob, off + 4)
    total_u, total_c = struct.unpack_from("<II", blob, off + 8)
    return major, minor, total_u, total_c


def decompress_sges_block(mm: mmap_mod.mmap | bytes, block_start: int, block_end: int, *, max_out: int | None = None) -> bytes:
    if isinstance(mm, bytes):
        data = mm
        length = len(data)

        def read_slice(a: int, b: int) -> bytes:
            return data[a:b]
    else:
        length = len(mm)

        def read_slice(a: int, b: int) -> bytes:
            return mm[a:b]

    _maj, minor, total_u, _tc = parse_sges_header(read_slice(block_start, block_start + 16))
    start_payload = block_start + sges_data_offset(minor)
    target = total_u if max_out is None else min(total_u, max_out)

    out = bytearray()
    pos = start_payload
    end = min(block_end, length)

    while len(out) < target and pos < end:
        while pos < end and read_slice(pos, pos + 1)[0] == 0:
            pos += 1
        if pos >= end:
            break
        try:
            chunk = read_slice(pos, min(pos + 131072, end))
            dec = zlib.decompressobj(-15)
            piece = dec.decompress(chunk)
            consumed = len(chunk) - len(dec.unused_data)
            out.extend(piece)
            pos += consumed
        except zlib.error:
            break

    if len(out) > target:
        del out[target:]
    return bytes(out)


def find_sges_offsets(data: bytes | mmap_mod.mmap) -> list[int]:
    out: list[int] = []
    start = 0
    while True:
        idx = data.find(SGES_MAGIC, start)
        if idx == -1:
            break
        out.append(idx)
        start = idx + 1
    return out


def load_data_blob(data_bin: PathLib | None, wad: PathLib | None) -> tuple[mmap_mod.mmap | bytes, PathLib]:
    if data_bin is not None:
        if not data_bin.is_file():
            raise FileNotFoundError(data_bin)
        f = open(data_bin, "rb")
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        f.close()
        return mm, data_bin
    if wad is None:
        raise ValueError("need --data-bin or --wad")
    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    dc = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if dc is None or dc.size == 0:
        raise ValueError("no DATA chunk")
    return extract_slice(raw, dc), wad


def load_paths(paths_txt: PathLib | None, pths_bin: PathLib | None, ffcs_out: PathLib | None) -> list[str]:
    if paths_txt and paths_txt.is_file():
        return [ln for ln in paths_txt.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
    if pths_bin and pths_bin.is_file():
        return dump_paths_from_pths(pths_bin.read_bytes())
    if ffcs_out:
        pt = ffcs_out / "paths.txt"
        if pt.is_file():
            return load_paths(pt, None, None)
    return []


def safe_filename(path_like: str) -> str:
    return path_like.replace("\\", "__").replace("/", "__")


def main() -> int:
    ap = argparse.ArgumentParser(description="Decompress Mercenaries 2 sges blocks")
    ap.add_argument("--data-bin", type=PathLib)
    ap.add_argument("--wad", type=PathLib)
    ap.add_argument("--paths", type=PathLib)
    ap.add_argument("--pths", type=PathLib)
    ap.add_argument("--ffcs-out", type=PathLib)
    ap.add_argument("--index", type=int)
    ap.add_argument("--name", type=str)
    ap.add_argument("--regex", type=str)
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--out", type=PathLib, required=True)
    ap.add_argument("--max-bytes", type=int, default=0)
    args = ap.parse_args()

    blob, src = load_data_blob(args.data_bin, args.wad)
    paths = load_paths(args.paths, args.pths, args.ffcs_out)

    try:
        size = len(blob)
        offsets = find_sges_offsets(blob)
        if not offsets:
            print("No sges magic found.", file=sys.stderr)
            return 1

        if args.list:
            n = min(len(offsets), len(paths)) if paths else len(offsets)
            for i in range(n):
                off = offsets[i]
                end = offsets[i + 1] if i + 1 < len(offsets) else size
                try:
                    maj, mn, tu, tc = parse_sges_header(blob[off : off + 16])
                except Exception:
                    maj, mn, tu, tc = 0, 0, 0, 0
                pname = paths[i] if i < len(paths) else "?"
                print(f"{i:5d}  0x{off:08x}..0x{end:08x}  v={maj}.{mn}  u={tu:9d}  {pname}")
            return 0

        def resolve_indices() -> list[int]:
            if args.index is not None:
                return [args.index]
            if args.name:
                sub = args.name.lower()
                for i, p in enumerate(paths):
                    if sub in p.lower():
                        return [i]
                raise SystemExit(f"No path containing {args.name!r}")
            if args.regex:
                rx = re.compile(args.regex)
                for i, p in enumerate(paths):
                    if rx.search(p):
                        return [i]
                raise SystemExit("regex match not found")
            if args.all:
                return list(range(min(len(offsets), len(paths) or len(offsets))))
            raise SystemExit("Specify --index, --name, --regex, or --all")

        indices = resolve_indices()

        def extract_one(idx: int) -> tuple[str, bytes]:
            off = offsets[idx]
            block_end = offsets[idx + 1] if idx + 1 < len(offsets) else size
            mx = args.max_bytes if args.max_bytes > 0 else None
            raw_out = decompress_sges_block(blob, off, block_end, max_out=mx)
            label = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
            return label, raw_out

        if len(indices) == 1 and not args.all:
            label, data = extract_one(indices[0])
            args.out.parent.mkdir(parents=True, exist_ok=True)
            args.out.write_bytes(data)
            print(f"Wrote {args.out} ({len(data)} bytes) <- {label}")
            return 0

        args.out.mkdir(parents=True, exist_ok=True)
        manifest: list[dict[str, object]] = []
        for idx in indices:
            label, data = extract_one(idx)
            fname = safe_filename(label)
            if not fname.endswith(".bin"):
                fname += ".bin"
            op = args.out / fname
            op.write_bytes(data)
            manifest.append({"index": idx, "path": label, "file": op.name, "size": len(data)})
            print(f"[{idx}] -> {op.name} ({len(data)} bytes)")

        (args.out / "manifest.json").write_text(json.dumps({"source": str(src), "blocks": manifest}, indent=2), encoding="utf-8")
        return 0
    finally:
        if isinstance(blob, mmap_mod.mmap):
            blob.close()


if __name__ == "__main__":
    raise SystemExit(main())
