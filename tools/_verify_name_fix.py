#!/usr/bin/env python3
"""Verify that the Name component byte-swap fix works correctly.

Extracts ecs_node blocks from the Xbox WAD, converts them with the
Rust binary, and checks Name record alignment.
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


def check_name_data(ucfx: bytes, label: str) -> tuple[int, int, int]:
    """Parse Name component in LE UCFX, return (total_records, good, bad)."""
    if len(ucfx) < 20 or ucfx[:4] != b"UCFX":
        return 0, 0, 0
    dao = struct.unpack_from("<I", ucfx, 4)[0]
    n_desc = struct.unpack_from("<I", ucfx, 16)[0]
    data_start = dao if dao > 0 else 8

    # Find COMP groups, look for Name
    descs = []
    for di in range(n_desc):
        ro = 20 + di * 20
        if ro + 20 > len(ucfx):
            break
        tag = ucfx[ro:ro+4].decode("ascii", "replace")
        u0, bs = struct.unpack_from("<II", ucfx, ro + 4)
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
            # Check if this is a Name component
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
                    if name is None and len(body) >= 4:
                        h = struct.unpack_from("<I", body, 0)[0]
                        if h == 0x1DE5C824:
                            name = "Name"
                    if name == "Name" and "data" in children:
                        dd = children["data"]
                        doff = data_start + dd["u0"]
                        dend = doff + dd["body_size"]
                        if dend <= len(ucfx):
                            data_body = ucfx[doff:dend]
                            return _walk_name_records(data_body, label)
        else:
            i += 1
    return 0, 0, 0


def _walk_name_records(data: bytes, label: str) -> tuple[int, int, int]:
    """Walk Name records as [u32 key][string\0]+. Return (total, good, bad)."""
    total = 0
    good = 0
    bad = 0
    pos = 0
    while pos + 4 <= len(data):
        key = struct.unpack_from("<I", data, pos)[0]
        pos += 4
        nul = data.find(b"\x00", pos)
        if nul < 0:
            bad += 1
            total += 1
            break
        name_bytes = data[pos:nul]
        is_ascii = all(32 <= b < 127 for b in name_bytes) if name_bytes else True
        total += 1
        if is_ascii:
            good += 1
            # Also check key makes sense (small values, high byte 0x00)
            if key > 0x00FFFFFF:
                bad += 1
                good -= 1
                if bad <= 3:
                    safe = "".join(c if 32 <= ord(c) < 127 else f"\\x{ord(c):02x}"
                                   for c in name_bytes.decode("ascii", errors="replace")[:40])
                    print(f"  [{label}] Record {total-1}: MISALIGNED key=0x{key:08X} "
                          f"name='{safe}'")
        else:
            bad += 1
            if bad <= 3:
                safe = "".join(c if 32 <= ord(c) < 127 else f"\\x{ord(c):02x}"
                               for c in name_bytes.decode("ascii", errors="replace")[:40])
                print(f"  [{label}] Record {total-1}: NON-ASCII key=0x{key:08X} "
                      f"name='{safe}'")
        pos = nul + 1
    return total, good, bad


def main():
    xbox_wad = Path("game-files/xbox-vz.wad")
    pc_wad = Path("game-files/pc-game-vz.wad")
    patch_wad = Path("output/data/vz-patch.wad")

    # Build PC hash set
    print("Building PC hash index...")
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
    print(f"  {len(pc_hashes):,} PC hashes\n")

    # Find DLC-unique ecs_node blocks in patch WAD
    print("Finding DLC-unique ecs_node blocks in patch WAD...")
    dc = find_data_chunk(patch_wad)
    dlc_blocks: list[tuple[int, bytes]] = []  # (block_idx, block_data)
    with open(patch_wad, "rb") as f:
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
                dlc_blocks.append((blk_idx, data))
        mm.close()
    print(f"  Found {len(dlc_blocks)} blocks with DLC-unique ecs_node entries\n")

    # Find same blocks in Xbox WAD, convert with fixed binary, compare
    print("Finding matching blocks in Xbox WAD for re-conversion...")
    # The patch WAD blocks are indexed 0..N. The Xbox source blocks
    # were extracted by the DLC port pipeline from the STFS/DOH.
    # Since we can't easily map back, let's instead just re-convert
    # the existing patch WAD blocks and check the Name data.

    # Check OLD (existing patch WAD) Name data
    print("\n=== OLD CONVERTER (patch WAD on disk) ===")
    old_total_bad = 0
    for blk_idx, data in dlc_blocks:
        for ent in parse_block_entries(data):
            if ent["type_hash"] != _TYPE_ECS_NODE or ent["hash"] in pc_hashes:
                continue
            raw = data[ent["offset"]:ent["offset"] + ent["size"]]
            ucfx = raw
            if len(raw) >= 8 and raw[-8:-4] == b"CSUM":
                ucfx = raw[:-8]
            total, good, bad = check_name_data(ucfx, f"OLD blk{blk_idx}")
            if total > 0:
                status = "OK" if bad == 0 else f"BAD ({bad}/{total})"
                print(f"  Block {blk_idx} hash=0x{ent['hash']:08X}: "
                      f"{total} Name records, {status}")
                old_total_bad += bad

    print(f"\n  Total bad Name records (old): {old_total_bad}")

    # Now re-convert with the FIXED Rust binary
    print("\n=== NEW CONVERTER (re-converted with fixed binary) ===")
    # We need the ORIGINAL Xbox BE block data. We can get this by finding
    # the block in the Xbox DLC source. But we don't have the STFS readily.
    # Instead, let's check if the BE block data is available.
    #
    # Alternative: since the patch WAD is already LE, we can't re-convert.
    # But we CAN check if the existing debug files have the BE data.
    be_block = Path("output/data/block_0464_be.bin")
    if be_block.exists():
        print(f"  Found BE block at {be_block}, testing conversion...")
        be_data = be_block.read_bytes()
        try:
            le_data = byteswap_block_rust(be_data, validate=False)
            print(f"  Converted: {len(be_data)} BE → {len(le_data)} LE")
            for ent in parse_block_entries(le_data):
                if ent["type_hash"] == _TYPE_ECS_NODE:
                    raw = le_data[ent["offset"]:ent["offset"] + ent["size"]]
                    ucfx = raw
                    if len(raw) >= 8 and raw[-8:-4] == b"CSUM":
                        ucfx = raw[:-8]
                    total, good, bad = check_name_data(ucfx, "FIXED")
                    if total > 0:
                        status = "OK" if bad == 0 else f"BAD ({bad}/{total})"
                        print(f"  hash=0x{ent['hash']:08X}: "
                              f"{total} Name records, {status}")
        except Exception as ex:
            print(f"  Conversion failed: {ex}")
    else:
        print(f"  No BE block file found for testing. Skipping re-conversion test.")
        print(f"  To test the fix, rebuild the patch WAD:")
        print(f"    make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output")

    print("\nDone.")


if __name__ == "__main__":
    main()
