#!/usr/bin/env python3
"""Verify Rust converter's ecs_node output against PC ground truth.

Finds shared ecs_node entries (present in both Xbox and PC WADs),
converts the Xbox block with the fixed Rust binary, and compares
the Name component data byte-for-byte against the PC version.
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
from x360_dlc_io import parse_be_ffcs, decompress_be_sges
from ucfx_byteswap_wrapper import byteswap_block_rust

_TYPE_ECS_NODE = 0xE6B81A54
_SEGS_MAGIC = b"segs"


def parse_be_block_entries(data: bytes) -> list[dict]:
    """Parse entry table from a BE block (u32s are big-endian)."""
    if len(data) < 4:
        return []
    entry_count = struct.unpack_from(">I", data, 0)[0]
    if entry_count > 50000:
        return []
    entries = []
    header_size = 4 + entry_count * 16
    offset = header_size
    for i in range(entry_count):
        eoff = 4 + i * 16
        name_hash = struct.unpack_from(">I", data, eoff)[0]
        type_hash = struct.unpack_from(">I", data, eoff + 4)[0]
        field_c = struct.unpack_from(">I", data, eoff + 8)[0]
        chunk_size = struct.unpack_from(">I", data, eoff + 12)[0]
        entries.append({
            "hash": name_hash,
            "type_hash": type_hash,
            "offset": offset,
            "size": chunk_size,
        })
        offset += chunk_size
    return entries


def extract_name_data(block_data: bytes, target_hash: int) -> bytes | None:
    """Extract the Name component data body from an ecs_node entry (LE block)."""
    for ent in parse_block_entries(block_data):
        if ent["hash"] != target_hash:
            continue
        raw = block_data[ent["offset"]:ent["offset"] + ent["size"]]
        ucfx = raw
        if len(raw) >= 8 and raw[-8:-4] == b"CSUM":
            ucfx = raw[:-8]
        if len(ucfx) < 20 or ucfx[:4] != b"UCFX":
            return None

        dao = struct.unpack_from("<I", ucfx, 4)[0]
        n_desc = struct.unpack_from("<I", ucfx, 16)[0]
        data_start = dao if dao > 0 else 8

        descs = []
        for di in range(n_desc):
            ro = 20 + di * 20
            if ro + 20 > len(ucfx):
                break
            tag = ucfx[ro:ro + 4].decode("ascii", "replace")
            u0 = struct.unpack_from("<I", ucfx, ro + 4)[0]
            bs = struct.unpack_from("<I", ucfx, ro + 8)[0]
            descs.append({"tag": tag, "u0": u0, "body_size": bs,
                          "sentinel": u0 == 0xFFFFFFFF})

        i = 0
        while i < len(descs):
            d = descs[i]
            if d["tag"] == "COMP" and d["sentinel"]:
                i += 1
                children = {}
                while i < len(descs) and not descs[i]["sentinel"]:
                    children[descs[i]["tag"]] = descs[i]
                    i += 1
                if "info" in children:
                    info_d = children["info"]
                    off = data_start + info_d["u0"]
                    end = off + info_d["body_size"]
                    if end <= len(ucfx):
                        body = ucfx[off:end]
                        nul = body.find(b"\x00")
                        name = None
                        if nul > 0:
                            try:
                                name = body[:nul].decode("ascii")
                            except UnicodeDecodeError:
                                pass
                        if name == "Name" and "data" in children:
                            dd = children["data"]
                            doff = data_start + dd["u0"]
                            dend = doff + dd["body_size"]
                            if dend <= len(ucfx):
                                return ucfx[doff:dend]
            else:
                i += 1
    return None


def main():
    xbox_wad = Path("game-files/xbox-vz.wad")
    pc_wad = Path("game-files/pc-game-vz.wad")

    # Index PC WAD for ecs_node entries
    print("Indexing PC WAD for ecs_node entries...")
    pc_ecs_blocks: dict[int, bytes] = {}
    dc = find_data_chunk(pc_wad)
    with open(pc_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                if ent["type_hash"] == _TYPE_ECS_NODE:
                    pc_ecs_blocks[ent["hash"]] = data
        mm.close()
    print(f"  Found {len(pc_ecs_blocks)} ecs_node entries in PC WAD")

    # Parse Xbox WAD BE FFCS header to find DATA chunk
    print("\nParsing Xbox WAD BE FFCS header...")
    xbox_raw = xbox_wad.read_bytes()
    version, chunk_rows = parse_be_ffcs(xbox_raw)
    data_row = next((r for r in chunk_rows if r.tag == "DATA"), None)
    if data_row is None:
        print("  ERROR: no DATA chunk in Xbox WAD")
        return

    # The meta field for DATA should give us the size, but let's use offset
    # and scan for segs magic
    data_offset = data_row.offset
    print(f"  DATA chunk at offset 0x{data_offset:X}")

    # Find segs offsets in the data area
    print("  Scanning for segs blocks...")
    segs_offsets: list[int] = []
    pos = data_offset
    while True:
        idx = xbox_raw.find(_SEGS_MAGIC, pos)
        if idx < 0:
            break
        segs_offsets.append(idx)
        pos = idx + 1
    print(f"  Found {len(segs_offsets)} segs blocks")

    # Build boundaries from segs offsets
    segs_boundaries: list[tuple[int, int]] = []
    for i, off in enumerate(segs_offsets):
        end = segs_offsets[i + 1] if i + 1 < len(segs_offsets) else len(xbox_raw)
        segs_boundaries.append((off, end))

    tested = 0
    passed = 0
    failed = 0
    converted_blocks = 0

    print("\nConverting shared ecs_node blocks and comparing Name data...")
    for blk_idx, (s, e) in enumerate(segs_boundaries):
        try:
            data = decompress_be_sges(xbox_raw, s, e - s)
        except Exception:
            continue

        entries = parse_be_block_entries(data)
        shared_ecs = [ent for ent in entries
                      if ent["type_hash"] == _TYPE_ECS_NODE and ent["hash"] in pc_ecs_blocks]
        if not shared_ecs:
            continue

        # Convert with Rust binary
        try:
            le_data = byteswap_block_rust(data, validate=False)
        except Exception as ex:
            print(f"  Block {blk_idx}: conversion failed: {ex}")
            failed += len(shared_ecs)
            continue
        converted_blocks += 1

        for ent in shared_ecs:
            h = ent["hash"]
            pc_name = extract_name_data(pc_ecs_blocks[h], h)
            if pc_name is None:
                continue

            converted_name = extract_name_data(le_data, h)
            if converted_name is None:
                print(f"  0x{h:08X}: Name data not found in converted output")
                failed += 1
                tested += 1
                continue

            tested += 1
            if pc_name == converted_name:
                passed += 1
            else:
                failed += 1
                min_len = min(len(pc_name), len(converted_name))
                diff_pos = next(
                    (i for i in range(min_len) if pc_name[i] != converted_name[i]),
                    min_len
                )
                print(f"  0x{h:08X}: MISMATCH at byte {diff_pos}")
                print(f"    PC:        {pc_name[diff_pos:diff_pos+16].hex()}")
                print(f"    Converted: {converted_name[diff_pos:diff_pos+16].hex()}")
                if len(pc_name) != len(converted_name):
                    print(f"    Size diff: PC={len(pc_name)} converted={len(converted_name)}")

        if converted_blocks % 50 == 0:
            print(f"  Progress: {converted_blocks} blocks, {tested} entries "
                  f"({passed} pass, {failed} fail)")

    print(f"\n{'='*60}")
    print(f"Name component ground truth comparison")
    print(f"  Xbox blocks converted: {converted_blocks}")
    print(f"  Entries tested:        {tested}")
    print(f"  Passed:                {passed}")
    print(f"  Failed:                {failed}")
    if tested > 0:
        print(f"  Rate:                  {100*passed/tested:.1f}%")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()
