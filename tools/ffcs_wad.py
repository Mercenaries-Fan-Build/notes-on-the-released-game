#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Mercenaries 2 (PC) FFCS .wad container parser."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import BinaryIO, List

HEADER_MAGIC = b"FFCS"


@dataclass
class FFCSChunk:
    tag: str
    offset: int
    meta: int
    size: int


@dataclass
class FFCSArchive:
    path: str
    version: int
    chunk_count: int
    chunks: List[FFCSChunk]
    file_size: int


def read_u32(f: BinaryIO) -> int:
    return struct.unpack("<I", f.read(4))[0]


def read_chunk_raw(f: BinaryIO, chunk_count: int) -> List[tuple[str, int, int]]:
    """Read five 12-byte chunk rows; file reports chunk_count=7 but 0x48 signature follows row five."""
    out: List[tuple[str, int, int]] = []
    start = f.tell()
    end_fixed = start + 60  # 5 * 12
    while f.tell() < end_fixed:
        tag = f.read(4)
        if len(tag) < 4:
            raise ValueError("truncated chunk tag")
        offset = read_u32(f)
        meta = read_u32(f)
        out.append((tag.decode("ascii", errors="replace"), offset, meta))
    return out


def infer_spatial_chunks(rows: List[tuple[str, int, int]], file_size: int) -> List[tuple[str, int, int]]:
    """CSUM rows store hashes, not byte offsets."""
    spatial = []
    for tag, off, meta in rows:
        if tag == "CSUM":
            continue
        if off >= file_size:
            continue
        spatial.append((tag, off, meta))
    return spatial


def parse_ffcs(path: Path) -> FFCSArchive:
    raw = path.read_bytes()
    size = len(raw)
    with path.open("rb") as f:
        magic = f.read(4)
        if magic != HEADER_MAGIC:
            raise ValueError(f"expected {HEADER_MAGIC!r}, got {magic!r}")
        version = read_u32(f)
        _declared_chunks = read_u32(f)
        rows = read_chunk_raw(f, _declared_chunks)

    spatial = infer_spatial_chunks(rows, size)
    entries = sorted(spatial, key=lambda t: t[1])
    span: dict[tuple[str, int, int], int] = {}
    for i, key in enumerate(entries):
        tag, off, meta = key
        nxt = entries[i + 1][1] if i + 1 < len(entries) else size
        span[(tag, off, meta)] = max(0, nxt - off)

    chunks: List[FFCSChunk] = []
    for tag, off, meta in rows:
        if tag == "CSUM":
            chunks.append(FFCSChunk(tag=tag, offset=off, meta=meta, size=0))
        else:
            chunks.append(FFCSChunk(tag=tag, offset=off, meta=meta, size=span.get((tag, off, meta), 0)))

    return FFCSArchive(path=str(path), version=version, chunk_count=len(rows), chunks=chunks, file_size=size)


def extract_slice(data: bytes, chunk: FFCSChunk) -> bytes:
    end = chunk.offset + chunk.size
    if chunk.offset < 0 or end > len(data):
        raise ValueError(f"chunk {chunk.tag} out of range: offset={chunk.offset} size={chunk.size}")
    return data[chunk.offset : end]


def dump_paths_from_pths(pt_blob: bytes, limit: int = 500_000) -> List[str]:
    paths: List[str] = []
    seen = set()
    for seq in pt_blob.split(b"\x00"):
        if len(seq) < 6:
            continue
        try:
            s = seq.decode("utf-8")
        except UnicodeDecodeError:
            s = seq.decode("latin-1", errors="ignore")
        if "\\" in s or "/" in s:
            if s not in seen:
                seen.add(s)
                paths.append(s)
                if len(paths) >= limit:
                    break
    return paths


def main() -> int:
    ap = argparse.ArgumentParser(description="Parse Mercenaries 2 FFCS .wad archives")
    ap.add_argument("wad", type=Path, help="Path to .wad file")
    ap.add_argument("--json", action="store_true", help="Print chunk table as JSON")
    ap.add_argument("--out-dir", type=Path, help="Extract raw chunk blobs + paths_sample.txt")
    args = ap.parse_args()

    arch = parse_ffcs(args.wad)
    data = args.wad.read_bytes()

    if args.json:
        print(
            json.dumps(
                {
                    "path": arch.path,
                    "version": arch.version,
                    "chunk_count": arch.chunk_count,
                    "file_size": arch.file_size,
                    "chunks": [asdict(c) for c in arch.chunks],
                },
                indent=2,
            )
        )
        return 0

    print(f"File: {args.wad}")
    print(f"Version: {arch.version}, chunks: {arch.chunk_count}, size: {arch.file_size}")
    for c in arch.chunks:
        print(f"  {c.tag}: offset=0x{c.offset:x} meta={c.meta} size={c.size} end=0x{c.offset + c.size:x}")

    if args.out_dir:
        args.out_dir.mkdir(parents=True, exist_ok=True)
        for c in arch.chunks:
            if c.size == 0:
                continue
            out_path = args.out_dir / f"{c.tag.strip().lower()}.bin"
            out_path.write_bytes(extract_slice(data, c))
            digest = hashlib.sha256(out_path.read_bytes()).hexdigest()[:16]
            print(f"Wrote {out_path} ({out_path.stat().st_size} bytes) sha256={digest}...")
        pths = next((c for c in arch.chunks if c.tag == "PTHS"), None)
        if pths:
            pb = extract_slice(data, pths)
            paths = dump_paths_from_pths(pb)
            (args.out_dir / "paths_sample.txt").write_text("\n".join(paths), encoding="utf-8")
            print(f"paths_sample.txt: {len(paths)} path-like strings")

    return 0


if __name__ == "__main__":
    sys.exit(main())
