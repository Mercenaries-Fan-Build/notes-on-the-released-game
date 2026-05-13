#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a global hash→chunk-locations index for Mercenaries 2 texture streaming.

The game distributes texture mip levels across multiple .block.bin files,
identified by a per-texture asset hash. This module scans all block files
and records where each texture hash's body data lives, enabling the texture
extractor to assemble full-resolution mip chains from scattered blocks.
"""

from __future__ import annotations

import argparse
import json
import os
import struct
import sys
from pathlib import Path

TEXTURE_TYPE_HASH = 0xF011157A
MESH_TYPE_HASH = 0x5B724250


def iter_block_entries(
    data: bytes,
) -> list[tuple[int, int, int, int]]:
    """Parse the block-file header table.

    Returns a list of ``(asset_hash, type_hash, body_offset, size)`` tuples.
    ``body_offset`` is the absolute byte offset of the entry's payload within
    the file (immediately after the header, packed sequentially).
    """
    if len(data) < 4:
        return []
    count = struct.unpack_from("<I", data, 0)[0]
    if count < 1 or count > 50_000:
        return []
    header_end = 4 + count * 16
    if header_end > len(data):
        return []
    entries: list[tuple[int, int, int, int]] = []
    cumulative = header_end
    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(data):
            break
        asset_hash, type_hash, _reserved, size = struct.unpack_from("<IIII", data, off)
        entries.append((asset_hash, type_hash, cumulative, size))
        cumulative += size
    return entries


CHUNK_HDR = 20


def _read_ucfx_name(path: Path, entry_offset: int, entry_size: int) -> str | None:
    """Read the NAME string from a UCFX texture container, if present."""
    try:
        with open(path, "rb") as f:
            f.seek(entry_offset)
            chunk = f.read(min(entry_size, 4096))
    except OSError:
        return None
    if len(chunk) < CHUNK_HDR * 2 or chunk[:4] != b"UCFX":
        return None
    u0 = struct.unpack_from("<I", chunk, 4)[0]
    u3 = struct.unpack_from("<I", chunk, 16)[0]
    data_base = int(u0)
    for ci in range(min(int(u3), 16)):
        cpos = CHUNK_HDR + ci * CHUNK_HDR
        if cpos + CHUNK_HDR > len(chunk):
            break
        tag = chunk[cpos : cpos + 4]
        cu0 = struct.unpack_from("<I", chunk, cpos + 4)[0]
        cu1 = struct.unpack_from("<I", chunk, cpos + 8)[0]
        if tag == b"NAME" and cu1 > 0:
            start = data_base + int(cu0)
            end = start + min(int(cu1), 256)
            if end <= len(chunk):
                try:
                    raw = chunk[start:end]
                    return raw.split(b"\x00", 1)[0].decode("ascii", errors="replace")
                except Exception:
                    pass
    return None


def build_texture_index(
    blocks_dirs: list[Path],
    *,
    verbose: bool = False,
) -> dict[int, list[dict[str, object]]]:
    """Scan all ``.block.bin`` files and return ``{asset_hash: [chunk_info, ...]}``."""
    index: dict[int, list[dict[str, object]]] = {}
    hash_names: dict[int, str] = {}
    scanned = 0
    for blocks_dir in blocks_dirs:
        if not blocks_dir.is_dir():
            continue
        for fn in sorted(os.listdir(blocks_dir)):
            if not fn.endswith(".block.bin"):
                continue
            path = blocks_dir / fn
            try:
                with open(path, "rb") as f:
                    header = f.read(min(path.stat().st_size, 16 * 1024))
            except OSError:
                continue
            entries = iter_block_entries(header)
            for asset_hash, type_hash, body_offset, size in entries:
                if type_hash != TEXTURE_TYPE_HASH:
                    continue
                index.setdefault(asset_hash, []).append(
                    {
                        "block": str(path),
                        "body_offset": body_offset,
                        "size": size,
                    }
                )
                # Try to extract texture name from containers that have one
                if asset_hash not in hash_names and size > CHUNK_HDR * 3:
                    name = _read_ucfx_name(path, body_offset, size)
                    if name:
                        hash_names[asset_hash] = name
            scanned += 1

    # Attach resolved names to the top-level index entries
    for h, name in hash_names.items():
        if h in index:
            for entry in index[h]:
                entry["name"] = name

    if verbose:
        unique = len(index)
        total_chunks = sum(len(v) for v in index.values())
        named = len(hash_names)
        print(
            f"Scanned {scanned} blocks, found {total_chunks} texture chunks "
            f"for {unique} unique hashes ({named} named)"
        )
    return index


def save_index(index: dict[int, list[dict[str, object]]], out_path: Path) -> None:
    """Persist the index as JSON (keys are hex strings for JSON compat)."""
    serializable = {f"0x{k:08x}": v for k, v in index.items()}
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(serializable, indent=1), encoding="utf-8")
    print(f"Wrote texture index: {out_path} ({len(index)} hashes)")


def load_index(path: Path) -> dict[int, list[dict[str, object]]]:
    """Load a previously saved index."""
    raw = json.loads(path.read_text(encoding="utf-8"))
    return {int(k, 16): v for k, v in raw.items()}


def hash_to_name_map(index: dict[int, list[dict[str, object]]]) -> dict[int, str]:
    """Extract a hash→texture_name mapping from a loaded index."""
    names: dict[int, str] = {}
    for h, entries in index.items():
        for e in entries:
            if "name" in e:
                names[h] = e["name"]
                break
    return names


def main() -> int:
    ap = argparse.ArgumentParser(description="Build Mercenaries 2 texture streaming index")
    ap.add_argument(
        "blocks_dirs",
        nargs="+",
        type=Path,
        help="Directories containing .block.bin files (e.g. output/extracted/batch_vz/blocks)",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("output/extracted/texture_index.json"),
        help="Output path for the index JSON",
    )
    args = ap.parse_args()

    index = build_texture_index(args.blocks_dirs, verbose=True)
    save_index(index, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
