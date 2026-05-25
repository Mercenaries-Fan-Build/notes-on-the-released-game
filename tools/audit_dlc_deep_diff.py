#!/usr/bin/env python3
"""Focused deep-diff of non-texture mismatches between patch and base game.

For each mismatched entry that isn't a texture/animation, does a tag-by-tag
comparison showing exactly which UCFX chunk bodies differ and where.
"""
from __future__ import annotations

import argparse
import mmap
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries

TYPE_NAMES = {
    0xF011157A: "texture",
    0x42498680: "script",
    0x207359C7: "stance",
    0x18166555: "animation",
    0xBCFE6314: "path",
    0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node",
    0x5B724250: "mesh_B",
    0x7C569307: "mesh_A",
    0x600B904E: "mesh_C",
    0x39E5E978: "stringdb",
    0xE5273C14: "unknown_E5",
}

_SKIP_TYPES = {0xF011157A, 0x18166555}


def _parse_ucfx_chunks(data: bytes) -> list[dict]:
    """Parse a raw entry into its UCFX chunks."""
    pos = data.find(b"UCFX")
    if pos < 0:
        return []
    c = data[pos:]
    if len(c) < 20:
        return []
    dao = struct.unpack_from("<I", c, 4)[0]
    n = struct.unpack_from("<I", c, 16)[0]
    if n > 5000:
        return []
    base = dao if dao else 8
    chunks = []
    for i in range(n):
        doff = 20 + i * 20
        if doff + 20 > len(c):
            break
        tag = c[doff:doff+4]
        u0 = struct.unpack_from("<I", c, doff + 4)[0]
        bs = struct.unpack_from("<I", c, doff + 8)[0]
        bstart = base + u0
        if bstart + bs <= len(c):
            body = c[bstart:bstart + bs]
        else:
            body = b""
        chunks.append({"tag": tag.decode("ascii", "replace"), "size": bs, "body": body})
    return chunks


def _extract_all_entries(wad_path: Path, skip_types: set[int] | None = None) -> dict[int, tuple[int, bytes]]:
    """Extract non-skipped entries → {hash: (type_hash, raw_bytes)}."""
    dc = find_data_chunk(wad_path)
    result: dict[int, tuple[int, bytes]] = {}
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception:
                continue
            try:
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                eh = ent["hash"]
                th = ent["type_hash"]
                if skip_types and th in skip_types:
                    continue
                eoff = ent["offset"]
                esize = ent["size"]
                if eoff + esize > len(data):
                    continue
                if eh not in result:
                    result[eh] = (th, data[eoff:eoff + esize])
        mm.close()
    return result


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--patch-wad", type=Path, required=True)
    parser.add_argument("--source-wad", type=Path, required=True)
    args = parser.parse_args()

    print("Loading base game (non-texture/animation entries)...")
    base = _extract_all_entries(args.source_wad, skip_types=_SKIP_TYPES)
    print(f"  {len(base)} entries\n")

    print("Loading patch WAD (non-texture/animation entries)...")
    patch = _extract_all_entries(args.patch_wad, skip_types=_SKIP_TYPES)
    print(f"  {len(patch)} entries\n")

    # Find mismatches
    mismatches = []
    for eh, (pth, pdata) in patch.items():
        if eh in base:
            bth, bdata = base[eh]
            if pdata != bdata:
                mismatches.append((eh, pth, pdata, bdata))

    print(f"Non-texture/animation mismatches: {len(mismatches)}\n")
    print("=" * 80)

    for eh, th, pdata, bdata in mismatches:
        tname = TYPE_NAMES.get(th, f"0x{th:08X}")
        print(f"\nhash=0x{eh:08X}  type={tname}")
        print("-" * 60)

        p_chunks = _parse_ucfx_chunks(pdata)
        b_chunks = _parse_ucfx_chunks(bdata)

        p_tags = {c["tag"]: c for c in p_chunks}
        b_tags = {c["tag"]: c for c in b_chunks}

        all_tags = sorted(set(list(p_tags.keys()) + list(b_tags.keys())))

        for tag in all_tags:
            pc = p_tags.get(tag)
            bc = b_tags.get(tag)

            if pc is None:
                print(f"  {tag}: MISSING in patch (base has {bc['size']} bytes)")
                continue
            if bc is None:
                print(f"  {tag}: MISSING in base (patch has {pc['size']} bytes)")
                continue

            if pc["body"] == bc["body"]:
                print(f"  {tag}: OK ({pc['size']} bytes)")
                continue

            # Differ - show details
            pb = pc["body"]
            bb = bc["body"]
            print(f"  {tag}: DIFFERS (patch={len(pb)} bytes, base={len(bb)} bytes)")

            if len(pb) != len(bb):
                print(f"    SIZE MISMATCH")

            # Show first divergence
            min_len = min(len(pb), len(bb))
            diff_count = 0
            first_diffs = []
            for i in range(min_len):
                if pb[i] != bb[i]:
                    diff_count += 1
                    if len(first_diffs) < 8:
                        first_diffs.append(i)

            if diff_count:
                print(f"    {diff_count} byte(s) differ out of {min_len}")
                for i in first_diffs:
                    # Show context around difference
                    ctx_start = max(0, i - 3)
                    ctx_end = min(min_len, i + 4)
                    p_ctx = pb[ctx_start:ctx_end].hex()
                    b_ctx = bb[ctx_start:ctx_end].hex()
                    print(f"    off 0x{i:04X}: patch[{ctx_start}:{ctx_end}]={p_ctx}")
                    print(f"              base [{ctx_start}:{ctx_end}]={b_ctx}")

            # For small bodies, show full hex
            if len(pb) <= 64:
                print(f"    patch full: {pb.hex()}")
                print(f"    base  full: {bb.hex()}")

    print("\n" + "=" * 80)
    print(f"TOTAL non-texture/animation mismatches: {len(mismatches)}")


if __name__ == "__main__":
    main()
