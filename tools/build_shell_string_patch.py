#!/usr/bin/env python3
"""Build a shell-patch.wad that overrides UTF-16 strings in a shell.wad block.

This is the Phase-1 spike tool for the shell-patch update system: it performs
*in-place* (equal-byte-length) UTF-16LE string replacements inside a decompressed
WAD block, recomputes the per-UCFX CSUM (CRC-32/JAMCRC) for every UCFX container
it touched, recompresses the block, and assembles a single-block FFCS patch WAD
using the same canonical builder that produced vz-patch.wad.

Because the edits are length-preserving and only the affected UCFX CSUMs are
recomputed, this exercises the entire pipeline (sges + JAMCRC + FFCS + engine
override path) with zero structural risk.

Example (relabel two main-menu items in the English stringdb, block 29):

    python tools/build_shell_string_patch.py \
        --source-wad game-files/shell.wad \
        --block-index 29 \
        --replace "NEW GAME=MOD MENU" \
        --replace "OPTIONS=MODTEST" \
        --output output/data/shell-patch.wad
"""
from __future__ import annotations

import argparse
import struct
import sys
import tempfile
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_patch_wad import crc32_mercs2  # noqa: E402  (this is JAMCRC; see ffcs_patch_wad)
from sges_decompress import decompress_sges_block  # noqa: E402
from ffcs_wad import parse_ffcs, extract_slice  # noqa: E402
from build_patch_wad import cmd_build_patch, get_block_boundaries  # noqa: E402

CSUM_TAG = b"CSUM"


def parse_block_entries(data: bytes) -> list[dict]:
    """Parse a decompressed block header: count(4) + count * 16-byte records."""
    count = struct.unpack_from("<I", data, 0)[0]
    entries: list[dict] = []
    pos = 4 + count * 16
    for i in range(count):
        h, th, fc, s = struct.unpack_from("<IIII", data, 4 + i * 16)
        entries.append({"index": i, "hash": h, "type_hash": th,
                        "field_c": fc, "size": s, "offset": pos})
        pos += s
    return entries


def decompress_block(source_wad: Path, block_index: int) -> bytes:
    import mmap as _mmap
    arch = parse_ffcs(source_wad)
    data_chunk = next(c for c in arch.chunks if c.tag == "DATA")
    with open(source_wad, "rb") as f:
        mm = _mmap.mmap(f.fileno(), 0, access=_mmap.ACCESS_READ)
    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        start, end = boundaries[block_index]
        return decompress_sges_block(mm, start, end)
    finally:
        mm.close()


def apply_replacements(block: bytearray, replacements: list[tuple[str, str]]) -> set[int]:
    """Apply equal-length UTF-16LE replacements in place. Returns touched byte offsets."""
    touched: set[int] = set()
    for old, new in replacements:
        ob, nb = old.encode("utf-16le"), new.encode("utf-16le")
        if len(ob) != len(nb):
            raise ValueError(f"length mismatch: {old!r}({len(ob)}B) != {new!r}({len(nb)}B)")
        first = block.find(ob)
        if first < 0:
            raise ValueError(f"not found: {old!r}")
        if block.find(ob, first + 1) >= 0:
            raise ValueError(f"ambiguous (multiple matches): {old!r}")
        block[first:first + len(nb)] = nb
        touched.add(first)
        print(f"  replaced {old!r} -> {new!r} @ 0x{first:x}")
    return touched


def recompute_csums(block: bytearray, entries: list[dict], touched: set[int]) -> None:
    for e in entries:
        start, size = e["offset"], e["size"]
        if not any(start <= t < start + size for t in touched):
            continue
        csum_off = start + size - 8
        if bytes(block[csum_off:csum_off + 4]) != CSUM_TAG:
            raise ValueError(f"entry {e['index']}: no CSUM trailer at 0x{csum_off:x}")
        new = crc32_mercs2(bytes(block[start:csum_off]))
        struct.pack_into("<I", block, csum_off + 4, new)
        print(f"  entry {e['index']} (type 0x{e['type_hash']:08x}) CSUM -> 0x{new:08x}")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--source-wad", type=Path, required=True)
    ap.add_argument("--block-index", type=int, required=True)
    ap.add_argument("--replace", action="append", default=[],
                    metavar="OLD=NEW", help="Equal-length UTF-16LE replacement (repeatable)")
    ap.add_argument("--output", "-o", type=Path, required=True)
    ap.add_argument("--save-block", type=Path, default=None,
                    help="Also write the patched decompressed block here (debug)")
    args = ap.parse_args()

    replacements = []
    for r in args.replace:
        if "=" not in r:
            ap.error(f"--replace must be OLD=NEW, got {r!r}")
        old, new = r.split("=", 1)
        replacements.append((old, new))
    if not replacements:
        ap.error("at least one --replace is required")

    print(f"Decompressing block {args.block_index} from {args.source_wad}...")
    block = bytearray(decompress_block(args.source_wad, args.block_index))
    print(f"  decompressed {len(block):,} bytes")
    entries = parse_block_entries(block)
    print(f"  {len(entries)} UCFX entries")

    touched = apply_replacements(block, replacements)
    recompute_csums(block, entries, touched)

    if args.save_block:
        args.save_block.parent.mkdir(parents=True, exist_ok=True)
        args.save_block.write_bytes(block)

    with tempfile.NamedTemporaryFile(suffix=".block.bin", delete=False) as tf:
        tf.write(block)
        tmp = Path(tf.name)
    try:
        rc = cmd_build_patch(args.source_wad, args.block_index, tmp,
                             args.output, is_raw=True)
    finally:
        tmp.unlink(missing_ok=True)
    return rc


if __name__ == "__main__":
    raise SystemExit(main())
