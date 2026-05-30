#!/usr/bin/env python3
"""Diagnose size invariance issue with block conversion.

Checks whether Xbox block entries have CSUM inside/outside chunk_size.
"""
from __future__ import annotations

import io
import mmap
import struct
import sys
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries
from ucfx_byteswap_wrapper import byteswap_block_rust

_TYPE_ECS_NODE = 0xE6B81A54


def analyze_block_structure(data: bytes, label: str):
    """Analyze a block's entry table vs actual container positions."""
    if len(data) < 4:
        print(f"  [{label}] Too small")
        return

    entry_count = struct.unpack_from("<I", data, 0)[0]
    # Check if it might be BE
    if entry_count > 50000:
        entry_count = struct.unpack_from(">I", data, 0)[0]
        endian = "BE"
        fmt = ">"
    else:
        endian = "LE"
        fmt = "<"

    header_size = 4 + entry_count * 16
    print(f"  [{label}] {endian} entry_count={entry_count}  header_size={header_size}  total={len(data)}")

    offset = header_size
    entries_with_csum = 0
    entries_without_csum = 0
    total_container_size = 0

    for i in range(min(entry_count, 5)):
        eoff = 4 + i * 16
        name_hash = struct.unpack_from(f"{fmt}I", data, eoff)[0]
        type_hash = struct.unpack_from(f"{fmt}I", data, eoff + 4)[0]
        field_c = struct.unpack_from(f"{fmt}I", data, eoff + 8)[0]
        chunk_size = struct.unpack_from(f"{fmt}I", data, eoff + 12)[0]

        if offset + chunk_size > len(data):
            print(f"    Entry {i}: chunk_size={chunk_size} exceeds block at offset {offset}")
            break

        container = data[offset:offset + chunk_size]
        magic_4 = container[:4] if len(container) >= 4 else b""

        # Check what's at offset + chunk_size
        after_container = data[offset + chunk_size:offset + chunk_size + 8] if offset + chunk_size + 8 <= len(data) else b""
        has_csum_after = after_container[:4] in (b"CSUM", b"MUSC")

        # Check if CSUM is at the END of the container (chunk_size includes CSUM)
        has_csum_inside = container[-8:-4] in (b"CSUM", b"MUSC") if len(container) >= 8 else False

        # Check magic at start
        is_ucfx = magic_4 in (b"UCFX", b"XFCU")

        type_name = f"0x{type_hash:08X}"
        if type_hash == _TYPE_ECS_NODE:
            type_name = "ecs_node"

        print(f"    Entry {i}: name=0x{name_hash:08X} type={type_name} "
              f"field_c=0x{field_c:08X} chunk_size={chunk_size}")
        print(f"      magic={magic_4!r} csum_inside={has_csum_inside} "
              f"csum_after={has_csum_after}")

        if has_csum_after:
            entries_with_csum += 1
            offset = offset + chunk_size + 8
        elif has_csum_inside:
            entries_with_csum += 1
            offset = offset + chunk_size
        else:
            entries_without_csum += 1
            offset = offset + chunk_size

    # Summary: walk ALL entries to check structure
    offset = header_size
    csum_inside_count = 0
    csum_after_count = 0
    csum_none_count = 0
    for i in range(entry_count):
        eoff = 4 + i * 16
        chunk_size = struct.unpack_from(f"{fmt}I", data, eoff + 12)[0]
        if offset + chunk_size > len(data):
            break

        container = data[offset:offset + chunk_size]
        after = data[offset + chunk_size:offset + chunk_size + 8] if offset + chunk_size + 8 <= len(data) else b""

        has_after = after[:4] in (b"CSUM", b"MUSC")
        has_inside = container[-8:-4] in (b"CSUM", b"MUSC") if len(container) >= 8 else False

        if has_after:
            csum_after_count += 1
            offset = offset + chunk_size + 8
        elif has_inside:
            csum_inside_count += 1
            offset = offset + chunk_size
        else:
            csum_none_count += 1
            offset = offset + chunk_size

    remaining = len(data) - offset
    print(f"  CSUM placement summary:")
    print(f"    csum AFTER container (excl from chunk_size): {csum_after_count}")
    print(f"    csum INSIDE container (incl in chunk_size):  {csum_inside_count}")
    print(f"    NO csum found:                               {csum_none_count}")
    print(f"    Remaining bytes after last entry:            {remaining}")


def main():
    be_block = Path("output/data/block_0464_be.bin")
    if not be_block.exists():
        print("No BE block file. Checking Xbox WAD directly...")

        # Find a DLC-unique ecs_node block from Xbox WAD
        xbox_wad = Path("game-files/xbox-vz.wad")
        pc_wad = Path("game-files/pc-game-vz.wad")

        # Build PC hash set
        print("Building PC hash index (quick)...")
        pc_hashes: set[int] = set()
        dc = find_data_chunk(pc_wad)
        with open(pc_wad, "rb") as f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            boundaries = get_block_boundaries(mm, dc.offset, dc.size)
            for blk_idx in range(len(boundaries)):
                s, e = boundaries[blk_idx]
                try:
                    data = decompress_sges_block(mm, s, e)
                    for ent in parse_block_entries(data):
                        pc_hashes.add(ent["hash"])
                except Exception:
                    continue
            mm.close()
        print(f"  {len(pc_hashes)} PC hashes")

        # Find first ecs_node block in Xbox WAD
        print("Scanning Xbox WAD for ecs_node blocks...")
        dc = find_data_chunk(xbox_wad)
        with open(xbox_wad, "rb") as f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            boundaries = get_block_boundaries(mm, dc.offset, dc.size)
            for blk_idx in range(len(boundaries)):
                s, e = boundaries[blk_idx]
                try:
                    data = decompress_sges_block(mm, s, e)
                    entries = parse_block_entries(data)
                except Exception:
                    continue
                has_dlc_ecs = False
                for ent in entries:
                    if ent["type_hash"] == _TYPE_ECS_NODE and ent["hash"] not in pc_hashes:
                        has_dlc_ecs = True
                        break
                if has_dlc_ecs:
                    print(f"\n=== Xbox block #{blk_idx} (BE) ===")
                    analyze_block_structure(data, f"Xbox#{blk_idx}")

                    print(f"\n  Converting with Rust binary...")
                    try:
                        le_data = byteswap_block_rust(data, validate=False)
                        print(f"  BE size: {len(data)}  LE size: {len(le_data)}  diff: {len(le_data) - len(data)}")
                        print(f"\n=== Converted block (LE) ===")
                        analyze_block_structure(le_data, "Converted")
                    except Exception as ex:
                        print(f"  Conversion failed: {ex}")
                    break
            mm.close()
        return

    print(f"Analyzing BE block: {be_block}")
    be_data = be_block.read_bytes()
    analyze_block_structure(be_data, "BE")

    print(f"\nConverting with Rust binary...")
    le_data = byteswap_block_rust(be_data, validate=False)
    print(f"BE size: {len(be_data)}  LE size: {len(le_data)}  diff: {len(le_data) - len(be_data)}")
    analyze_block_structure(le_data, "LE")

    # Also compare with patch WAD block
    patch_wad = Path("output/data/vz-patch.wad")
    if patch_wad.exists():
        dc = find_data_chunk(patch_wad)
        with open(patch_wad, "rb") as f:
            mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            boundaries = get_block_boundaries(mm, dc.offset, dc.size)
            # Block 1 in patch WAD
            s, e = boundaries[1]
            patch_data = decompress_sges_block(mm, s, e)
            print(f"\n=== Patch WAD block 1 (LE) ===")
            analyze_block_structure(patch_data, "Patch")
            mm.close()


if __name__ == "__main__":
    main()
