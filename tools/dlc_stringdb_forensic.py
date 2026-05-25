#!/usr/bin/env python3
"""Forensic compare retail PC stringdb vs ported DLC stringdb blocks (Phase 0f).

Decompresses blocks from base and patch WADs, inspects SYEK/SRTS descriptor
u32s and first UTF-16LE keys. Use to decide whether _fix_stringdb_descriptors
is needed (default: off — byteswap_ucfx_block only).

Usage:
  python3 tools/dlc_stringdb_forensic.py \\
    --base-wad game-files/vz.wad --base-path blocks/VZ/english_P000_Q3.block \\
    --patch-wad output/data/vz-patch.wad --patch-path blocks/dlc01/english_dlc01_P000_Q3.block
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from aset_type_ids import STRINGDB_TYPE_HASH  # noqa: E402
from build_patch_wad import extract_block_metadata  # noqa: E402
from ffcs_patch_wad import read_patch_wad  # noqa: E402
from ffcs_wad import dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import parse_block_entries  # noqa: E402


def _find_block_index(wad: Path, path_substr: str) -> int:
    raw = wad.read_bytes()
    arch = parse_ffcs(wad)
    pths = next(c for c in arch.chunks if c.tag == "PTHS")
    paths = dump_paths_from_pths(extract_slice(raw, pths))
    needle = path_substr.replace("\\", "/").lower()
    for i, p in enumerate(paths):
        if needle in p.replace("\\", "/").lower():
            return i
    raise ValueError(f"No block matching {path_substr!r} in {wad}")


def _decompress_block_from_wad(wad: Path, block_index: int) -> bytes:
    pw = read_patch_wad(wad)
    if block_index < len(pw.blocks):
        blk = pw.blocks[block_index]
        return decompress_sges_block(blk.compressed_data, 0, len(blk.compressed_data))
    meta = extract_block_metadata(wad, block_index)
    raw = wad.read_bytes()
    off = meta["indx_entry"]["file_offset"]
    size = meta["indx_entry"]["page_count"] * 0x8000
    return decompress_sges_block(raw, off, size)


def _inspect_stringdb_ucfx(ucfx_body: bytes, data_base: int) -> list[dict]:
    """Walk UCFX chunk table; report SYEK/SRTS descriptor fields."""
    chunks: list[dict] = []
    pos = data_base
    end = len(ucfx_body)
    while pos + 8 <= end:
        tag = ucfx_body[pos:pos + 4]
        if tag not in (b"SYEK", b"SRTS", b"KEYS", b"STRS"):
            break
        u0, u1, u2, u3 = struct.unpack_from("<IIII", ucfx_body, pos + 4)
        chunks.append({
            "tag": tag.decode("ascii"),
            "body_off_le": u0,
            "body_size_le": u1,
            "body_off_be": int.from_bytes(ucfx_body[pos + 4:pos + 8], "big"),
            "body_size_be": int.from_bytes(ucfx_body[pos + 8:pos + 12], "big"),
            "u2": u2,
            "u3": u3,
        })
        pos += 20
    return chunks


def _first_utf16_key(block_data: bytes, entry_index: int) -> str | None:
    entries = parse_block_entries(block_data)
    if entry_index >= len(entries):
        return None
    sizes = []
    count = struct.unpack_from("<I", block_data, 0)[0]
    for i in range(count):
        off = 4 + i * 16
        sizes.append(struct.unpack_from("<I", block_data, off + 12)[0])
    pos = 4 + count * 16
    for i in range(entry_index):
        pos += sizes[i]
    if block_data[pos:pos + 4] != b"UCFX":
        return None
    ucfx_u0 = struct.unpack_from("<I", block_data, pos + 4)[0]
    data_base = pos + ucfx_u0
    body = block_data[data_base:pos + sizes[entry_index]]
    # First printable UTF-16LE run after SYEK/SRTS headers
    for start in range(0, min(len(body), 512), 2):
        try:
            s = body[start:start + 80].decode("utf-16-le")
            s = s.split("\x00")[0]
            if len(s) >= 3 and s.isprintable():
                return s[:60]
        except UnicodeDecodeError:
            continue
    return None


def analyze_block(wad: Path, block_index: int, label: str) -> dict:
    data = _decompress_block_from_wad(wad, block_index)
    entries = parse_block_entries(data)
    stringdb_entries = [
        (i, e) for i, e in enumerate(entries)
        if e.get("type_hash") == STRINGDB_TYPE_HASH
    ]
    report: dict = {"label": label, "block_index": block_index, "entries": []}
    for i, e in stringdb_entries:
        pos = 4 + i * 16
        for j in range(i):
            pos += struct.unpack_from("<I", data, 4 + j * 16 + 12)[0]
        ucfx_u0 = struct.unpack_from("<I", data, pos + 4)[0]
        data_base = pos + ucfx_u0
        chunks = _inspect_stringdb_ucfx(data, data_base)
        report["entries"].append({
            "index": i,
            "hash": f"0x{e.get('hash', 0):08X}",
            "chunks": chunks,
            "first_key": _first_utf16_key(data, i),
        })
    return report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--base-wad", type=Path, required=True)
    ap.add_argument("--base-path", type=str, default="blocks/VZ/english_P000_Q3.block")
    ap.add_argument("--patch-wad", type=Path, required=True)
    ap.add_argument("--patch-path", type=str, default="blocks/dlc01/english_dlc01_P000_Q3.block")
    args = ap.parse_args()

    base_idx = _find_block_index(args.base_wad, args.base_path)
    patch_idx = _find_block_index(args.patch_wad, args.patch_path)
    print(f"Base  [{base_idx}] {args.base_path}")
    print(f"Patch [{patch_idx}] {args.patch_path}\n")

    base_r = analyze_block(args.base_wad, base_idx, "retail")
    patch_r = analyze_block(args.patch_wad, patch_idx, "dlc_port")

    for r in (base_r, patch_r):
        print(f"=== {r['label']} block {r['block_index']} ===")
        for ent in r["entries"]:
            print(f"  entry {ent['index']} hash {ent['hash']}")
            for ch in ent["chunks"]:
                sane_le = ch["body_off_le"] + ch["body_size_le"] < 500_000
                sane_be = ch["body_off_be"] + ch["body_size_be"] < 500_000
                print(
                    f"    {ch['tag']}: LE off={ch['body_off_le']} size={ch['body_size_le']} "
                    f"sane={sane_le} | BE off={ch['body_off_be']} size={ch['body_size_be']} "
                    f"sane={sane_be}"
                )
            print(f"    first_key: {ent['first_key']!r}")
        print()

    print("Interpretation:")
    print("  If retail SYEK/SRTS use sane LE descriptors → do NOT run _fix_stringdb_descriptors.")
    print("  If patch matches retail descriptor style → byteswap_ucfx_block alone is sufficient.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
