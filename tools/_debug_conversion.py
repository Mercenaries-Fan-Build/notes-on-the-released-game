#!/usr/bin/env python3
"""Debug: find why extract_name_data fails on converted blocks."""
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


def extract_name_data_debug(block_data: bytes, target_hash: int, label: str) -> bytes | None:
    """Extract Name component data with debug output."""
    entries = parse_block_entries(block_data)
    matching = [e for e in entries if e["hash"] == target_hash]
    if not matching:
        print(f"    [{label}] Hash 0x{target_hash:08X} not found in {len(entries)} entries")
        return None
    ent = matching[0]
    raw = block_data[ent["offset"]:ent["offset"] + ent["size"]]
    ucfx = raw
    if len(raw) >= 8 and raw[-8:-4] == b"CSUM":
        ucfx = raw[:-8]
    if len(ucfx) < 20 or ucfx[:4] != b"UCFX":
        print(f"    [{label}] Not UCFX: magic={ucfx[:4]!r}")
        return None

    dao = struct.unpack_from("<I", ucfx, 4)[0]
    n_desc = struct.unpack_from("<I", ucfx, 16)[0]
    data_start = dao if dao > 0 else 8
    print(f"    [{label}] UCFX size={len(ucfx)}, dao={dao}, n_desc={n_desc}")

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

    print(f"    [{label}] Tags: {[d['tag'] for d in descs]}")

    i = 0
    name_found = False
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
                    if name == "Name":
                        name_found = True
                        if "data" in children:
                            dd = children["data"]
                            doff = data_start + dd["u0"]
                            dend = doff + dd["body_size"]
                            if dend <= len(ucfx):
                                print(f"    [{label}] Found Name data: "
                                      f"size={dd['body_size']}")
                                return ucfx[doff:dend]
                            else:
                                print(f"    [{label}] Name data exceeds "
                                      f"container: end={dend}, len={len(ucfx)}")
                        else:
                            print(f"    [{label}] Name info found but no data child")
        else:
            i += 1

    if not name_found:
        print(f"    [{label}] No Name component found (ASCII info)")
    return None


def main():
    xbox_wad = Path("game-files/xbox-vz.wad")
    pc_wad = Path("game-files/pc-game-vz.wad")

    # Find PC ecs_node entries with Name data
    print("Indexing PC WAD for ecs_node entries with Name data...")
    pc_ecs_blocks: dict[int, bytes] = {}
    pc_with_name: set[int] = set()
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

    # Quick check: how many have Name on PC?
    print(f"  {len(pc_ecs_blocks)} ecs_node entries in PC WAD")
    sample_count = 0
    for h, bdata in list(pc_ecs_blocks.items())[:50]:
        nd = extract_name_data_debug(bdata, h, "PC-scan")
        if nd is not None:
            pc_with_name.add(h)
            sample_count += 1
            if sample_count >= 3:
                break
    print(f"  {len(pc_with_name)} of first 50 have Name data")

    if not pc_with_name:
        print("  No PC entries with Name data found!")
        return

    # Find those hashes in Xbox WAD
    print("\nParsing Xbox WAD...")
    xbox_raw = xbox_wad.read_bytes()
    _, chunk_rows = parse_be_ffcs(xbox_raw)
    data_row = next(r for r in chunk_rows if r.tag == "DATA")

    segs_offsets: list[int] = []
    pos = data_row.offset
    while True:
        idx = xbox_raw.find(_SEGS_MAGIC, pos)
        if idx < 0:
            break
        segs_offsets.append(idx)
        pos = idx + 1

    target_hash = list(pc_with_name)[0]
    print(f"  Looking for hash 0x{target_hash:08X} in Xbox WAD...")

    for blk_idx, soff in enumerate(segs_offsets):
        e = segs_offsets[blk_idx + 1] if blk_idx + 1 < len(segs_offsets) else len(xbox_raw)
        try:
            data = decompress_be_sges(xbox_raw, soff, e - soff)
        except Exception:
            continue

        be_count = struct.unpack_from(">I", data, 0)[0]
        if be_count > 50000:
            continue

        found = False
        for i in range(be_count):
            eoff = 4 + i * 16
            nh = struct.unpack_from(">I", data, eoff)[0]
            if nh == target_hash:
                found = True
                break
        if not found:
            continue

        print(f"\n  Found in Xbox block {blk_idx} (BE), {be_count} entries")

        # Convert
        le_data = byteswap_block_rust(data, validate=False)
        print(f"  Converted: {len(data)} → {len(le_data)}")

        # Debug extract on BOTH sides
        print(f"\n  PC Name data extraction:")
        pc_name = extract_name_data_debug(pc_ecs_blocks[target_hash], target_hash, "PC")

        print(f"\n  Converted Name data extraction:")
        conv_name = extract_name_data_debug(le_data, target_hash, "CONV")

        if pc_name and conv_name:
            if pc_name == conv_name:
                print(f"\n  MATCH! Name data is byte-identical ({len(pc_name)} bytes)")
            else:
                print(f"\n  MISMATCH!")
                print(f"    PC size: {len(pc_name)}")
                print(f"    Converted size: {len(conv_name)}")
                min_len = min(len(pc_name), len(conv_name))
                for i in range(min_len):
                    if pc_name[i] != conv_name[i]:
                        print(f"    First diff at byte {i}")
                        print(f"      PC:   {pc_name[i:i+16].hex()}")
                        print(f"      Conv: {conv_name[i:i+16].hex()}")
                        break

        break


if __name__ == "__main__":
    main()
