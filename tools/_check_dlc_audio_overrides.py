#!/usr/bin/env python3
"""Check which DLC audio entries have base game overrides vs are unique.

This determines whether the blind u32 sweep in the record area matters:
- Entries with overrides use PC base game data directly (no conversion)
- Entries without overrides go through the potentially-broken converter
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block

PAGE_SIZE = 0x8000
_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_WAVEBANK = 0xF753F6D0


def parse_ffcs(raw: bytes) -> dict:
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off + 4)[0]
        meta = struct.unpack_from("<I", raw, off + 8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)
    return chunks


def parse_indx(raw: bytes, off: int, n: int) -> list[dict]:
    entries = []
    for i in range(n):
        o = off + i * 12
        pi = struct.unpack_from("<I", raw, o)[0]
        pk = struct.unpack_from("<I", raw, o + 4)[0]
        fp = struct.unpack_from("<I", raw, o + 8)[0]
        entries.append({
            "page_idx": pi, "packed": pk,
            "page_count": fp & 0xFFFF, "flags": (fp >> 16) & 0xFFFF,
        })
    return entries


def collect_aset_hashes(raw: bytes, aset_off: int, aset_count: int,
                        type_id: int) -> set[int]:
    hashes = set()
    for i in range(aset_count):
        off = aset_off + i * 16
        ah, _, _, tid = struct.unpack_from("<IIII", raw, off)
        if tid == type_id:
            hashes.add(ah)
    return hashes


def decompress_block(raw: bytes, entry: dict) -> bytes | None:
    offset = entry["page_idx"] * PAGE_SIZE
    size = entry["page_count"] * PAGE_SIZE
    compressed = raw[offset:offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def find_audio_entries_in_block(decomp: bytes) -> list[dict]:
    """Find all audio entries (soundbank and wavebank) in a decompressed block."""
    entry_count = struct.unpack_from("<I", decomp, 0)[0]
    results = []
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        eoff = 4 + i * 16
        h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th in (_TYPE_SOUNDBANK, _TYPE_WAVEBANK):
            type_name = "soundbank" if th == _TYPE_SOUNDBANK else "wavebank"
            results.append({"hash": h, "type": type_name, "type_hash": th, "size": sz})
        pos += sz
    return results


def main():
    base_path = Path("game-files/vz.wad")
    patch_path = Path("output/data/vz-patch.wad")

    if not base_path.exists():
        print(f"ERROR: {base_path} not found")
        return 1

    print("Loading base game WAD...")
    base_raw = base_path.read_bytes()
    base_chunks = parse_ffcs(base_raw)

    # Collect base game audio hashes via ASET
    base_sb_hashes = collect_aset_hashes(
        base_raw, base_chunks["ASET"][0], base_chunks["ASET"][1], 21)
    base_wb_hashes = collect_aset_hashes(
        base_raw, base_chunks["ASET"][0], base_chunks["ASET"][1], 6)

    print(f"Base game: {len(base_sb_hashes)} soundbank hashes, "
          f"{len(base_wb_hashes)} wavebank hashes")

    if not patch_path.exists():
        print(f"ERROR: {patch_path} not found")
        return 1

    print("\nLoading DLC patch WAD...")
    patch_raw = patch_path.read_bytes()
    patch_chunks = parse_ffcs(patch_raw)
    patch_indx = parse_indx(patch_raw, patch_chunks["INDX"][0], patch_chunks["INDX"][1])

    # Collect DLC audio hashes via ASET
    patch_sb_hashes = collect_aset_hashes(
        patch_raw, patch_chunks["ASET"][0], patch_chunks["ASET"][1], 21)
    patch_wb_hashes = collect_aset_hashes(
        patch_raw, patch_chunks["ASET"][0], patch_chunks["ASET"][1], 6)

    print(f"DLC patch: {len(patch_sb_hashes)} soundbank ASET entries, "
          f"{len(patch_wb_hashes)} wavebank ASET entries")

    # Compare
    sb_overridden = patch_sb_hashes & base_sb_hashes
    sb_unique = patch_sb_hashes - base_sb_hashes
    wb_overridden = patch_wb_hashes & base_wb_hashes
    wb_unique = patch_wb_hashes - base_wb_hashes

    print(f"\n{'=' * 70}")
    print("SOUNDBANK OVERRIDE ANALYSIS")
    print(f"{'=' * 70}")
    print(f"  Overridden (base game has same hash → will use PC data): {len(sb_overridden)}")
    for h in sorted(sb_overridden):
        print(f"    0x{h:08X}")
    print(f"  UNIQUE (no base game match → goes through converter): {len(sb_unique)}")
    for h in sorted(sb_unique):
        print(f"    0x{h:08X}")

    print(f"\n{'=' * 70}")
    print("WAVEBANK OVERRIDE ANALYSIS")
    print(f"{'=' * 70}")
    print(f"  Overridden (base game has same hash → will use PC data): {len(wb_overridden)}")
    for h in sorted(wb_overridden):
        print(f"    0x{h:08X}")
    print(f"  UNIQUE (no base game match → goes through converter): {len(wb_unique)}")
    for h in sorted(wb_unique):
        print(f"    0x{h:08X}")

    # Now scan the actual DLC blocks to find audio entries at the block level
    print(f"\n{'=' * 70}")
    print("BLOCK-LEVEL AUDIO ENTRY SCAN")
    print(f"{'=' * 70}")

    seen_blocks: set[int] = set()
    for i in range(patch_chunks["ASET"][1]):
        off = patch_chunks["ASET"][0] + i * 16
        _, _, u2, tid = struct.unpack_from("<IIII", patch_raw, off)
        if tid in (6, 21):
            blk = (u2 >> 16) & 0xFFFF
            seen_blocks.add(blk)

    for blk_idx in sorted(seen_blocks):
        if blk_idx >= len(patch_indx):
            continue
        try:
            decomp = decompress_block(patch_raw, patch_indx[blk_idx])
        except Exception:
            continue
        if not decomp:
            continue
        entries = find_audio_entries_in_block(decomp)
        if entries:
            print(f"\n  Block {blk_idx}:")
            for e in entries:
                h = e["hash"]
                tname = e["type"]
                base_set = base_sb_hashes if tname == "soundbank" else base_wb_hashes
                status = "OVERRIDE" if h in base_set else "UNIQUE"
                print(f"    {tname} 0x{h:08X} size={e['size']:,} → {status}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
