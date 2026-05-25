#!/usr/bin/env python3
"""Verify the DLC import() chain can resolve all scripts without running the game.

Simulates the engine's RedVirtualDisk overlay:
  - Opens vz.wad (base) then vz-patch.wad (overlay)
  - Builds combined ASET from both, last-opened wins
  - Walks the import() chain starting from wifmissionflow → dlc01 → dlccon*
  - Reports any missing assets that would cause a hang

Usage:
    python3 tools/verify_dlc_import_chain.py \\
        --base-wad game-files/vz.wad \\
        --patch-wad output/data/vz-patch.wad
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from dlc_aset_normalize import (
    find_block_for_script_module,
    find_dlc_script_resident_block_index,
    is_dlc_script_resident_path,
)
from wad_patcher import get_binn_script_ref_name, parse_block_entries
from ffcs_patch_wad import read_patch_wad
from pandemic_hash import pandemic_hash_m2
from sges_decompress import decompress_sges_block


def parse_ffcs_chunks(data: bytes) -> dict[str, tuple[int, int]]:
    """Parse FFCS header → {tag: (offset, meta)}."""
    if data[:4] != b"FFCS":
        raise ValueError("Not an FFCS file")
    version = struct.unpack_from("<I", data, 4)[0]
    count = struct.unpack_from("<I", data, 8)[0]
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(count):
        off = 12 + i * 12
        if off + 12 > len(data):
            break
        tag = data[off:off + 4].decode("ascii", errors="replace")
        c_off = struct.unpack_from("<I", data, off + 4)[0]
        c_meta = struct.unpack_from("<I", data, off + 8)[0]
        chunks[tag] = (c_off, c_meta)
    return chunks


def extract_aset_hashes(data: bytes, chunks: dict) -> dict[int, int]:
    """Extract ASET → {asset_hash: block_index}."""
    if "ASET" not in chunks:
        return {}
    aset_off, aset_count = chunks["ASET"]
    result: dict[int, int] = {}
    for i in range(aset_count):
        eoff = aset_off + i * 16
        if eoff + 16 > len(data):
            break
        h = struct.unpack_from("<I", data, eoff)[0]
        if h == 0:
            continue
        u2 = struct.unpack_from("<I", data, eoff + 8)[0]
        block_idx = (u2 >> 16) & 0xFFFF
        result[h] = block_idx
    return result


def extract_indx_offsets(data: bytes, chunks: dict) -> list[tuple[int, int]]:
    """Extract INDX → [(page_offset, packed_pages), ...]."""
    if "INDX" not in chunks:
        return []
    indx_off, indx_count = chunks["INDX"]
    result = []
    for i in range(indx_count):
        eoff = indx_off + i * 12
        if eoff + 12 > len(data):
            break
        page_idx = struct.unpack_from("<I", data, eoff)[0]
        packed = struct.unpack_from("<I", data, eoff + 4)[0]
        flags_pages = struct.unpack_from("<I", data, eoff + 8)[0]
        result.append((page_idx, flags_pages))
    return result


def decompress_block(data: bytes, page_offset: int, page_count: int) -> bytes | None:
    """Decompress an sges block from a WAD.

    Patch WADs store blocks at ``page_index * PAGE_SIZE`` from file start
    (see ffcs_patch_wad.build_patch_wad_multi), not DATA-chunk-relative.
    """
    PAGE = 0x8000
    abs_off = page_offset * PAGE
    raw_size = page_count * PAGE
    if abs_off + raw_size > len(data):
        return None
    compressed = data[abs_off:abs_off + raw_size]
    if compressed[:4] != b"sges":
        return None
    try:
        return zlib.decompress(compressed[16:], -15)
    except zlib.error:
        seg_count = struct.unpack_from("<I", compressed, 4)[0]
        segments = []
        pos = 8 + seg_count * 4
        for s in range(seg_count):
            seg_size = struct.unpack_from("<I", compressed, 8 + s * 4)[0]
            seg_data = compressed[pos:pos + seg_size]
            segments.append(zlib.decompress(seg_data, -15))
            pos += seg_size
        return b"".join(segments)


def get_block_script_names(block_data: bytes) -> set[int]:
    """Parse block header to get all name hashes."""
    entry_count = struct.unpack_from("<I", block_data, 0)[0]
    hashes = set()
    for i in range(entry_count):
        off = 4 + i * 16
        if off + 16 > len(block_data):
            break
        nh = struct.unpack_from("<I", block_data, off)[0]
        hashes.add(nh)
    return hashes


def find_luaq_in_block(block_data: bytes) -> list[tuple[int, str]]:
    """Find LuaQ bytecode entries and extract script names from INFO bodies."""
    entry_count = struct.unpack_from("<I", block_data, 0)[0]
    sizes = []
    for i in range(entry_count):
        off = 4 + i * 16
        sizes.append(struct.unpack_from("<I", block_data, off + 12)[0])

    results = []
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        chunk_end = pos + sizes[i]
        if pos + 20 > len(block_data):
            break
        if block_data[pos:pos + 4] == b"UCFX":
            ucfx_u0 = struct.unpack_from("<I", block_data, pos + 4)[0]
            data_base = pos + ucfx_u0
            has_luaq = b"\x1bLua" in block_data[data_base:chunk_end]
            if has_luaq:
                name_bytes = block_data[data_base:min(data_base + 80, chunk_end)]
                name = ""
                for b in name_bytes:
                    if 32 <= b < 127:
                        name += chr(b)
                    elif name and len(name) > 3:
                        break
                    else:
                        name = ""
                nh = struct.unpack_from("<I", block_data, 4 + i * 16)[0]
                results.append((nh, name.strip() if name else f"0x{nh:08X}"))
        pos = chunk_end
    return results


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base-wad", type=Path, required=True, help="Path to base vz.wad")
    ap.add_argument("--patch-wad", type=Path, required=True, help="Path to vz-patch.wad")
    args = ap.parse_args()

    print("DLC Import Chain Validator")
    print("=" * 60)

    base_data = args.base_wad.read_bytes()
    patch_data = args.patch_wad.read_bytes()

    print(f"  Base WAD:  {args.base_wad} ({len(base_data):,} bytes)")
    print(f"  Patch WAD: {args.patch_wad} ({len(patch_data):,} bytes)")

    base_chunks = parse_ffcs_chunks(base_data)
    patch_chunks = parse_ffcs_chunks(patch_data)

    base_aset = extract_aset_hashes(base_data, base_chunks)
    patch_aset = extract_aset_hashes(patch_data, patch_chunks)

    print(f"\n  Base ASET:  {len(base_aset):,} entries")
    print(f"  Patch ASET: {len(patch_aset):,} entries")

    # Overlay: patch wins over base (last-opened-file wins per RedVirtualDisk)
    combined_aset = {**base_aset, **patch_aset}
    print(f"  Combined:   {len(combined_aset):,} entries")

    # Key scripts in the import chain
    chain_scripts = [
        "wifmissionflow",
        "dlc01",
        "dlccon001",
        "dlccon002",
        "dlccon003",
        "dlccon004a",
    ]

    # Also check scripts that dlccon* might import
    extended_scripts = [
        "dlccon004_cash",
        "dlccon050",
        "dlc01_hero",
        "dlc01_missionhub",
        "dlc01_briefing",
        "dlc01_player",
        "dlc01_pausescreen",
        "dlc01_pmcinterior",
        "dlc01_mrxguipda",
        "dlc01_starterdata",
        "dlc01_assets",
        "dlc01missionflow",
        "dlcvehiclestrike",
        "dlccopterdrop",
        "dlcescalation",
        "dlcspeedtimer",
        "dlccombometer",
        "dlc_moonpatrol",
        "dlc_mrxtankbuster",
    ]

    print(f"\n{'─' * 60}")
    print("Import Chain Verification")
    print(f"{'─' * 60}")

    all_ok = True
    patch_has_resident = False

    try:
        pw = read_patch_wad(args.patch_wad)
        patch_has_resident = any(
            is_dlc_script_resident_path(b.path_string) for b in pw.blocks
        )
        if not patch_has_resident:
            print("  FAIL  resident block missing from patch WAD")
            print("        Expected: blocks\\dlc01\\resident_P000_Q3.block")
            print("        Re-run: make dlc-port OUTPUT=... SOURCE_WAD=...")
            print("        (old vz-patch.wad was built while resident was skipped)")
            all_ok = False
        else:
            ri = find_dlc_script_resident_block_index(pw.blocks)
            if ri is not None:
                print(f"  OK    resident_P000_Q3          block={ri:>5d}  (patch)")
    except Exception as exc:
        print(f"  WARN  could not scan patch paths: {exc}")

    for name in chain_scripts:
        h = pandemic_hash_m2(name)
        in_base = h in base_aset
        in_patch = h in patch_aset
        in_combined = h in combined_aset

        if in_combined:
            source = "patch" if in_patch else "base"
            block = combined_aset[h]
            status = "OK"
        else:
            source = "MISSING"
            block = -1
            status = "FAIL"
            all_ok = False
            if name.startswith("dlccon") and not patch_has_resident:
                source = "MISSING (no resident block in patch)"

        marker = "  ***" if status == "FAIL" else ""
        print(f"  {status:4s}  {name:25s}  0x{h:08X}  block={block:>5d}  ({source}){marker}")

    print(f"\n{'─' * 60}")
    print("Extended DLC Scripts")
    print(f"{'─' * 60}")

    for name in extended_scripts:
        h = pandemic_hash_m2(name)
        in_patch = h in patch_aset
        in_combined = h in combined_aset

        if in_combined:
            source = "patch" if in_patch else "base"
            block = combined_aset[h]
            print(f"  OK    {name:25s}  0x{h:08X}  block={block:>5d}  ({source})")
        else:
            print(f"  MISS  {name:25s}  0x{h:08X}  (not in ASET)")

    # Check for the BAD hash (dlccon004 without 'a')
    bad_hash = pandemic_hash_m2("dlccon004")
    if bad_hash in combined_aset:
        print(f"\n  WARNING: 'dlccon004' (0x{bad_hash:08X}) IS in ASET — "
              f"but Xbox uses 'dlccon004a'. Check your dlc01 master script.")

    # Verify the bootstrap scripts_vz block has correct bytecode
    print(f"\n{'─' * 60}")
    print("Bootstrap Block Verification")
    print(f"{'─' * 60}")

    bootstrap_ok = False
    try:
        if pw is None:
            pw = read_patch_wad(args.patch_wad)
        last_block_idx = len(pw.blocks) - 1
        last_blk = pw.blocks[last_block_idx]
        bootstrap_data = decompress_sges_block(
            last_blk.compressed_data, 0, len(last_blk.compressed_data))
        entry_count = struct.unpack_from("<I", bootstrap_data, 0)[0]
        print(f"  Bootstrap block {last_block_idx}: {entry_count} UCFX entries "
              f"({last_blk.path_string})")

        luaq_entries = find_luaq_in_block(bootstrap_data)
        print(f"  Lua scripts found: {len(luaq_entries)}")

        dlc01_hash = pandemic_hash_m2("dlc01")
        wifmf_hash = pandemic_hash_m2("wifmissionflow")
        wifmf_orig_hash = pandemic_hash_m2("wifmissionflow_orig")

        for nh, name in luaq_entries:
            if nh in (dlc01_hash, wifmf_hash, wifmf_orig_hash):
                label = {dlc01_hash: "dlc01", wifmf_hash: "wifmissionflow",
                         wifmf_orig_hash: "wifmissionflow_orig"}.get(nh, name)
                print(f"    {label:30s}  0x{nh:08X}")

        block_hashes = get_block_script_names(bootstrap_data)
        hook_mode = wifmf_orig_hash in block_hashes
        for check_name in ["dlc01", "wifmissionflow"]:
            ch = pandemic_hash_m2(check_name)
            status = "PRESENT" if ch in block_hashes else "MISSING"
            if check_name == "dlc01" and status == "MISSING":
                all_ok = False
            print(f"  {check_name:30s}  {status}")
        if hook_mode:
            status = "PRESENT" if wifmf_orig_hash in block_hashes else "MISSING"
            if status == "MISSING":
                all_ok = False
            print(f"  {'wifmissionflow_orig':30s}  {status}")
        else:
            print(f"  {'wifmissionflow_orig':30s}  N/A (nohook bootstrap)")
        bootstrap_ok = True
    except Exception as exc:
        print(f"  ERROR: Could not read/decompress bootstrap block: {exc}")
        all_ok = False
    if not bootstrap_ok:
        print("  ERROR: Could not decompress bootstrap block")

    # Verify LuaQ bytecodes in the DLC script resident block (path-based lookup)
    print(f"\n{'─' * 60}")
    print("DLC Script Resident Block LuaQ Check")
    print(f"{'─' * 60}")

    try:
        if pw is None:
            raise RuntimeError("patch WAD not loaded")
        resident_idx = find_dlc_script_resident_block_index(pw.blocks)
        if resident_idx is None:
            raise RuntimeError(
                "no dlc01 script resident block found "
                "(expected *resident*P000_Q3.block, excluding vo_resident)"
            )
        resident_blk = pw.blocks[resident_idx]
        resident_data = decompress_sges_block(
            resident_blk.compressed_data, 0, len(resident_blk.compressed_data))
        if resident_data:
            luaq_count = resident_data.count(b"\x1bLua")
            le_count = 0
            be_count = 0
            pos = 0
            while True:
                idx = resident_data.find(b"\x1bLua", pos)
                if idx < 0:
                    break
                if idx + 12 <= len(resident_data) and resident_data[idx + 4] == 0x51:
                    if resident_data[idx + 6] == 1:
                        le_count += 1
                    elif resident_data[idx + 6] == 0:
                        be_count += 1
                pos = idx + 1

            print(f"  Block index: {resident_idx}")
            print(f"  Path: {resident_blk.path_string}")
            print(f"  Total LuaQ signatures: {luaq_count}")
            print(f"  Little-endian (PC):    {le_count}")
            print(f"  Big-endian (Xbox):     {be_count}")
            if be_count > 0:
                print(f"  *** WARNING: {be_count} BE bytecodes will crash the game! ***")
                all_ok = False
            else:
                print("  Gate 0d: PASS — resident scripts are PC-LE (scripts_vz still required for Row 13)")

            for name in chain_scripts[2:]:
                h = pandemic_hash_m2(name)
                in_aset = h in combined_aset
                in_binn = False
                try:
                    for entry in parse_block_entries(resident_data):
                        ref = get_binn_script_ref_name(resident_data, entry)
                        if ref and ref.lower() == name.lower():
                            in_binn = True
                            break
                except Exception:
                    pass
                if in_aset and in_binn:
                    print(f"  {name:25s}  PRESENT (ASET + BINN ref)")
                elif in_binn:
                    print(f"  {name:25s}  PARTIAL (BINN ref, not in ASET)")
                    all_ok = False
                elif in_aset:
                    print(f"  {name:25s}  PARTIAL (ASET only)")
                    all_ok = False
                else:
                    print(f"  {name:25s}  MISSING")
                    all_ok = False
    except Exception as exc:
        print(f"  ERROR: Could not verify script resident block: {exc}")
        all_ok = False

    print(f"\n{'=' * 60}")
    if all_ok:
        print("RESULT: ALL CHECKS PASSED — import chain should resolve correctly")
    else:
        print("RESULT: ISSUES FOUND — the game will likely hang or crash")
    print(f"{'=' * 60}")

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
