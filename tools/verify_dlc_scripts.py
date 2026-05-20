#!/usr/bin/env python3
"""Verify DLC contract scripts in a vz-patch.wad for correctness.

Checks:
  1. Finds the scripts_vz block within the patch WAD
  2. Decompresses and lists all UCFX script entries
  3. For each DLC contract script (dlccon001-004):
     - Locates the LuaQ bytecode
     - Checks the Lua header for endianness (byte 6: 0x01=LE, 0x00=BE)
     - Validates integer/float/pointer sizes match PC Lua 5.1
  4. Reports any issues

Usage:
  python3 tools/verify_dlc_scripts.py --wad path/to/vz-patch.wad
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths
from sges_decompress import decompress_sges_block, find_sges_offsets, parse_sges_header
from wad_patcher import (
    parse_block_entries,
    get_script_name,
    verify_entry_csum,
    get_block_boundaries,
    LUAQ_SIG,
    BINN_TAG,
)

DLC_CONTRACT_NAMES = {"dlccon001", "dlccon002", "dlccon003", "dlccon004"}

# Expected Lua 5.1 PC header: \x1bLua Q \x00 \x01 \x04 \x04 \x04 \x04 \x00
# Byte layout:
#   0-3: \x1bLua  (signature)
#   4:   0x51     (version 5.1, encoded as 0x50 + 0x01)
#   5:   0x00     (format version, official = 0)
#   6:   0x01     (endianness: 1=LE, 0=BE)  *** KEY CHECK ***
#   7:   0x04     (sizeof(int))
#   8:   0x04     (sizeof(size_t))
#   9:   0x04     (sizeof(Instruction))
#  10:   0x04 or 0x08  (sizeof(lua_Number) — 4=float, 8=double)
#  11:   0x00     (integral flag: 0=floating, 1=integer)

EXPECTED_LE_HEADER = b"\x1bLua" + bytes([
    0x51,  # Lua 5.1
    0x00,  # official format
    0x01,  # little-endian
    0x04,  # sizeof(int) = 4
    0x04,  # sizeof(size_t) = 4
    0x04,  # sizeof(Instruction) = 4
])


def describe_lua_header(data: bytes, offset: int) -> dict:
    """Parse the Lua 5.1 bytecode header starting at the given offset."""
    if len(data) < offset + 12:
        return {"error": "Data too short for Lua header"}

    sig = data[offset:offset + 4]
    if sig != b"\x1bLua":
        return {"error": f"Bad signature: {sig.hex()}"}

    version = data[offset + 4]
    fmt = data[offset + 5]
    endian = data[offset + 6]
    int_size = data[offset + 7]
    size_t_size = data[offset + 8]
    instr_size = data[offset + 9]
    number_size = data[offset + 10]
    integral = data[offset + 11]

    return {
        "version": f"{(version >> 4) & 0xF}.{version & 0xF}",
        "version_byte": version,
        "format": fmt,
        "endianness": "LE" if endian == 1 else ("BE" if endian == 0 else f"UNKNOWN(0x{endian:02x})"),
        "endian_byte": endian,
        "sizeof_int": int_size,
        "sizeof_size_t": size_t_size,
        "sizeof_instruction": instr_size,
        "sizeof_number": number_size,
        "number_type": "integer" if integral else "float",
        "header_bytes": data[offset:offset + 12].hex(),
    }


def verify_wad(wad_path: Path, *, verbose: bool = False) -> int:
    """Verify all DLC contract scripts in the WAD."""
    print(f"Verifying DLC scripts in: {wad_path}")
    print(f"  File size: {wad_path.stat().st_size:,} bytes")
    print()

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: Not an FFCS WAD file", file=sys.stderr)
        return 1

    arch = parse_ffcs(wad_path)
    print(f"FFCS chunks: {[c.tag for c in arch.chunks]}")

    pths_chunk = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)

    if not data_chunk:
        print("ERROR: No DATA chunk in WAD", file=sys.stderr)
        return 1

    # Get paths
    paths = []
    if pths_chunk and pths_chunk.size > 0:
        pths_data = extract_slice(raw, pths_chunk)
        paths = dump_paths_from_pths(pths_data)
        print(f"PTHS entries: {len(paths)}")
        for i, p in enumerate(paths):
            print(f"  [{i}] {p}")
    print()

    # Find sges blocks in DATA
    import mmap as mmap_mod
    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        print(f"sges blocks found: {len(boundaries)}")

        for block_idx, (start, end) in enumerate(boundaries):
            block_size = end - start
            path_name = paths[block_idx] if block_idx < len(paths) else "(no path)"

            is_scripts = "scripts" in path_name.lower()
            if not is_scripts and not verbose:
                continue

            print(f"\n{'=' * 70}")
            print(f"Block {block_idx}: {path_name}")
            print(f"  Compressed: {block_size:,} bytes (offset 0x{start:x})")

            try:
                header_data = mm[start:start + 16]
                maj, minor, total_u, total_c = parse_sges_header(header_data)
                print(f"  sges v{maj}.{minor}: uncompressed={total_u:,}")
            except Exception as e:
                print(f"  sges header parse error: {e}")
                continue

            try:
                decompressed = decompress_sges_block(mm, start, end)
            except Exception as e:
                print(f"  ERROR decompressing: {e}", file=sys.stderr)
                continue

            print(f"  Decompressed: {len(decompressed):,} bytes")

            try:
                entries = parse_block_entries(decompressed)
            except Exception as e:
                print(f"  ERROR parsing block entries: {e}", file=sys.stderr)
                continue

            print(f"  UCFX entries: {len(entries)}")
            print()

            dlc_found = {}
            issues = []

            for entry in entries:
                name = get_script_name(decompressed, entry)
                stored, computed, csum_ok = verify_entry_csum(decompressed, entry)

                is_dlc = name.lower() in DLC_CONTRACT_NAMES or name.lower() == "dlc01"
                marker = " ***" if is_dlc else ""

                if verbose or is_dlc or not csum_ok:
                    print(f"  [{entry['index']:3d}] {name:30s}  size={entry['size']:8,}  "
                          f"CSUM={'OK' if csum_ok else 'BAD':>3}{marker}")

                # Check Lua bytecode header for DLC scripts
                entry_start = entry["offset"]
                entry_end = entry_start + entry["size"] - 8
                chunk = decompressed[entry_start:entry_end]

                luaq_pos = chunk.find(b"\x1bLua")
                if luaq_pos >= 0:
                    lua_info = describe_lua_header(chunk, luaq_pos)

                    if is_dlc or verbose:
                        bc_size = entry_end - (entry_start + luaq_pos)
                        print(f"         Lua bytecode: {bc_size:,} bytes at entry+0x{luaq_pos:x}")
                        print(f"         Header: {lua_info.get('header_bytes', 'N/A')}")
                        print(f"         Version: {lua_info.get('version', '?')}, "
                              f"Endianness: {lua_info.get('endianness', '?')}, "
                              f"int={lua_info.get('sizeof_int', '?')}, "
                              f"size_t={lua_info.get('sizeof_size_t', '?')}, "
                              f"number={lua_info.get('sizeof_number', '?')} "
                              f"({lua_info.get('number_type', '?')})")

                    if is_dlc:
                        dlc_found[name.lower()] = lua_info

                        if lua_info.get("endian_byte") == 0:
                            issues.append(f"{name}: BIG-ENDIAN bytecode (Xbox 360 format, will crash on PC)")
                        elif lua_info.get("endian_byte") != 1:
                            issues.append(f"{name}: Unknown endianness byte 0x{lua_info.get('endian_byte', 0):02x}")

                        if lua_info.get("sizeof_int") != 4:
                            issues.append(f"{name}: sizeof(int)={lua_info.get('sizeof_int')} (expected 4)")
                        if lua_info.get("sizeof_size_t") != 4:
                            issues.append(f"{name}: sizeof(size_t)={lua_info.get('sizeof_size_t')} (expected 4)")

                        # Check for 4-byte floats (Mercs2 uses float, not double)
                        if lua_info.get("sizeof_number") == 8:
                            issues.append(f"{name}: sizeof(lua_Number)=8 (double) — Mercs2 uses 4 (float)")

                    if not csum_ok and not is_dlc:
                        issues.append(f"{name}: CSUM mismatch (stored=0x{stored:08X}, computed=0x{computed:08X})")
                    elif not csum_ok:
                        issues.append(f"{name}: CSUM mismatch (stored=0x{stored:08X}, computed=0x{computed:08X})")

                elif is_dlc:
                    issues.append(f"{name}: No Lua bytecode found in UCFX chunk!")

            # Summary for this block
            if is_scripts:
                print(f"\n  --- DLC Script Summary ---")
                for expected in sorted(DLC_CONTRACT_NAMES | {"dlc01"}):
                    if expected in dlc_found:
                        info = dlc_found[expected]
                        status = "OK" if info.get("endian_byte") == 1 else "PROBLEM"
                        print(f"  {expected:15s}: PRESENT  endian={info.get('endianness', '?'):3s}  "
                              f"number_size={info.get('sizeof_number', '?')}  [{status}]")
                    else:
                        print(f"  {expected:15s}: MISSING")

                if issues:
                    print(f"\n  !!! ISSUES FOUND ({len(issues)}) !!!")
                    for issue in issues:
                        print(f"    - {issue}")
                else:
                    print(f"\n  All DLC scripts look correct (LE, proper sizes).")

    finally:
        mm.close()

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Verify DLC contract scripts in a vz-patch.wad",
    )
    ap.add_argument("--wad", type=Path, required=True,
                    help="Path to vz-patch.wad to verify")
    ap.add_argument("--verbose", "-v", action="store_true",
                    help="Show all entries, not just DLC-related ones")

    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: WAD file not found: {args.wad}", file=sys.stderr)
        return 1

    return verify_wad(args.wad, verbose=args.verbose)


if __name__ == "__main__":
    sys.exit(main())
