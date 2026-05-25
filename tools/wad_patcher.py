#!/usr/bin/env python3
"""Unified WAD patching tool for Mercenaries 2 modding.

All-in-one script that reads a WAD file directly, finds target blocks
via FFCS INDX + PTHS, decompresses sges blocks in memory, locates
target script UCFX chunks, applies modifications, recomputes CSUMs,
recompresses, and writes back — no intermediate files needed.

Usage:
  # List all scripts in the WAD's scripts_vz block
  python3 tools/wad_patcher.py --wad path/to/vz.wad --list-scripts

  # Corrupt a specific script's CSUM (for testing validation)
  python3 tools/wad_patcher.py --wad path/to/vz.wad --script wiftutorialtank --corrupt-csum

  # Replace a script's bytecode with compiled Lua
  python3 tools/wad_patcher.py --wad path/to/vz.wad --script wiftutorialtank --lua-bytecode path/to/compiled.luac

  # Replace raw UCFX chunk content
  python3 tools/wad_patcher.py --wad path/to/vz.wad --script wiftutorialtank --ucfx-payload path/to/modified_ucfx.bin

  # Disable backup / dry-run
  python3 tools/wad_patcher.py --wad path/to/vz.wad --script wiftutorialtank --corrupt-csum --no-backup
  python3 tools/wad_patcher.py --wad path/to/vz.wad --script wiftutorialtank --corrupt-csum --dry-run

  # Low-level block patching (backward-compat with csum_corruption_test.py)
  python3 tools/wad_patcher.py vz.wad --index 1257 --sges-file modified.sges.bin --output vz_patched.wad
"""

from __future__ import annotations

import argparse
import mmap as mmap_mod
import shutil
import struct
import sys
import zlib
from pathlib import Path

SGES_MAGIC = b"sges"
UCFX_MAGIC = b"UCFX"
CSUM_TAG = b"CSUM"
BINN_TAG = b"BINN"
LUAQ_SIG = b"LuaQ"
PAGE_SIZE = 0x8000  # 32 KB

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import FFCSChunk, dump_paths_from_pths, extract_slice, parse_ffcs  # noqa: E402
from sges_compress import compress_sges  # noqa: E402
from sges_decompress import (  # noqa: E402
    decompress_sges_block,
    find_sges_offsets,
    parse_sges_header,
)


# ── CRC-32 (Mercenaries 2 CSUM: init=0, no final XOR) ──────────────

def crc32_mercs2(data: bytes) -> int:
    """CRC-32 with init=0, no final XOR (Mercenaries 2 CSUM algorithm).

    Uses Python zlib internals: zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF
    gives table-CRC with init=0 and no final XOR.
    """
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


# Script UCFX entries use type_hash 0x42498680 → ASET type_id 35 (see docs/aset_format.md).
SCRIPT_TYPE_HASH = 0x42498680
SCRIPT_ASET_TYPE_ID = 35


def script_aset_entry(asset_hash: int) -> dict:
    """ASET row for a Lua script module (required for import() lookup)."""
    return {
        "asset_hash": asset_hash,
        "u32_1": 0xFFFFFFFF,
        "u32_2": 0,
        "u32_3": SCRIPT_ASET_TYPE_ID,
    }


# ── Block header / entry parsing ─────────────────────────────────────

def parse_block_entries(data: bytes) -> list[dict]:
    """Parse the decompressed block header: count(4) + count * entry(16).

    Each entry: u32 name_hash, u32 type_hash, u32 field_c, u32 chunk_size.
    Returns list of dicts with index, hash, type_hash, size, offset, csum_offset.
    """
    if len(data) < 4:
        raise ValueError("Block data too short for header")
    count = struct.unpack_from("<I", data, 0)[0]
    header_end = 4 + count * 16

    entries: list[dict] = []
    pos = header_end
    for i in range(count):
        h, th, fc, s = struct.unpack_from("<IIII", data, 4 + i * 16)
        entry_start = pos
        csum_off = pos + s - 8
        entries.append({
            "index": i,
            "hash": h,
            "type_hash": th,
            "field_c": fc,
            "size": s,
            "offset": entry_start,
            "csum_offset": csum_off,
        })
        pos += s
    return entries


def get_binn_script_ref_name(data: bytes, entry: dict) -> str | None:
    """Parse a resident-style BINN script-reference record (no inline LuaQ).

    Layout (see docs/dlc_mission_loading.md): u32 bytecode_size, two u32 zeros,
    u8 marker 0x05, u8 meta, u8 zero, then ASCII module name at offset 0x0F.
    """
    chunk = data[entry["offset"]:entry["offset"] + entry["size"] - 8]
    binn_off = chunk.find(BINN_TAG)
    if binn_off < 0:
        return None
    body = chunk[binn_off + 4:]
    if len(body) < 16 or body[12] != 0x05:
        return None
    name_start = 15
    chars: list[str] = []
    for i in range(name_start, min(len(body), name_start + 64)):
        b = body[i]
        if 32 <= b < 127:
            chars.append(chr(b))
        else:
            break
    return "".join(chars) if len(chars) >= 4 else None


def get_script_name(data: bytes, entry: dict) -> str:
    """Extract the script name from a BINN section within an entry."""
    ref = get_binn_script_ref_name(data, entry)
    if ref:
        return ref
    chunk = data[entry["offset"]:entry["offset"] + entry["size"] - 8]
    binn_off = chunk.find(BINN_TAG)
    if binn_off < 0:
        return "(unknown)"
    region = chunk[binn_off + 4:binn_off + 300]
    i = 0
    while i < len(region):
        if 32 <= region[i] < 127:
            j = i
            while j < len(region) and 32 <= region[j] < 127:
                j += 1
            s = region[i:j].decode("ascii")
            if len(s) >= 4 and s not in ("BINN", "LuaQ", "UCFX"):
                return s
            i = j
        else:
            i += 1
    return "(unknown)"


def verify_entry_csum(data: bytes, entry: dict) -> tuple[int, int, bool]:
    """Verify a single entry's CSUM. Returns (stored, computed, match)."""
    csum_off = entry["csum_offset"]
    if data[csum_off:csum_off + 4] != CSUM_TAG:
        return 0, 0, False
    stored = struct.unpack_from("<I", data, csum_off + 4)[0]
    ucfx_data = data[entry["offset"]:csum_off]
    computed = crc32_mercs2(ucfx_data)
    return stored, computed, stored == computed


# ── FFCS helpers ─────────────────────────────────────────────────────

def find_data_chunk(wad_path: Path) -> FFCSChunk:
    """Parse FFCS and return the DATA chunk descriptor."""
    arch = parse_ffcs(wad_path)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None or data_chunk.size == 0:
        raise ValueError("No DATA chunk found in WAD")
    return data_chunk


def get_block_boundaries(
    mm: mmap_mod.mmap, data_offset: int, data_size: int
) -> list[tuple[int, int]]:
    """Scan DATA chunk for sges blocks.

    Returns list of (absolute_start, absolute_end) pairs for each block.
    """
    data_blob = mm[data_offset:data_offset + data_size]
    relative_offsets = find_sges_offsets(data_blob)

    boundaries: list[tuple[int, int]] = []
    for i, rel_off in enumerate(relative_offsets):
        abs_start = data_offset + rel_off
        abs_end = (
            (data_offset + relative_offsets[i + 1])
            if i + 1 < len(relative_offsets)
            else (data_offset + data_size)
        )
        boundaries.append((abs_start, abs_end))

    return boundaries


def load_wad_paths(wad_path: Path) -> list[str]:
    """Extract path strings from the WAD's PTHS chunk."""
    raw = wad_path.read_bytes()
    arch = parse_ffcs(wad_path)
    pths = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    if pths is None or pths.size == 0:
        return []
    pb = extract_slice(raw, pths)
    return dump_paths_from_pths(pb)


def find_scripts_block_index(paths: list[str]) -> list[tuple[int, str]]:
    """Find all block indices whose path contains 'scripts_vz'."""
    results: list[tuple[int, str]] = []
    for i, p in enumerate(paths):
        if "scripts_vz" in p.lower():
            results.append((i, p))
    return results


# Retail PC vz.wad: scripts_vz is block 3197 (PTHS: scripts_vz_P000_Q3.block).
# Block 1257 is c30624_P000_Q3.block (27 entries) — NOT scripts_vz (old doc typo).
SCRIPTS_VZ_BLOCK_INDEX_RETAIL = 3197

# PC retail scripts_vz has no Lua chunk named "vz"; chain-load via these if --vz-inject.
DLC_BOOTSTRAP_HOOK_SCRIPTS = (
    "vz",
    "wifmissionflow",
    "wifpmcinterior",
)


def resolve_scripts_vz_block_index(
    source_wad: Path,
    *,
    explicit_index: int | None = None,
) -> int:
    """Resolve the scripts_vz block index in a retail vz.wad."""
    if explicit_index is not None:
        return explicit_index

    paths = load_wad_paths(source_wad)
    matches = find_scripts_block_index(paths)
    if not matches:
        raise ValueError(
            f"No scripts_vz block in PTHS for {source_wad}. "
            "Pass --scripts-block-index explicitly."
        )
    if len(matches) > 1:
        # Prefer canonical scripts_vz_P000_Q3 over other matches.
        for idx, path in matches:
            if "scripts_vz_p000" in path.lower().replace("\\", "/"):
                return idx
        return matches[0][0]
    return matches[0][0]


def find_dlc_bootstrap_hook_script(
    decompressed: bytes,
    entries: list[dict],
    *,
    preferred_names: tuple[str, ...] = DLC_BOOTSTRAP_HOOK_SCRIPTS,
) -> tuple[str, dict] | None:
    """Pick a script entry to receive import('dlc01') wrapper bytecode."""
    by_name: dict[str, dict] = {}
    for entry in entries:
        name = get_script_name(decompressed, entry)
        if name and name != "(unknown)":
            by_name[name] = entry

    for name in preferred_names:
        if name in by_name:
            return name, by_name[name]

    return None


# ── patch_inplace (backward-compat API for csum_corruption_test.py) ──

def patch_inplace(
    wad_path: Path,
    output_path: Path,
    block_index: int,
    new_sges_data: bytes,
    *,
    dry_run: bool = False,
) -> dict:
    """Patch a single sges block in the WAD.

    Strategy:
      - If new_sges fits within the old block's space: overwrite + zero-pad.
      - If new_sges is larger: abort with clear error.
    """
    if new_sges_data[:4] != SGES_MAGIC:
        raise ValueError("new_sges_data does not start with sges magic")

    data_chunk = find_data_chunk(wad_path)
    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)

        if block_index < 0 or block_index >= len(boundaries):
            raise IndexError(
                f"Block index {block_index} out of range (0..{len(boundaries) - 1})"
            )

        old_start, old_end = boundaries[block_index]
        old_size = old_end - old_start
        new_size = len(new_sges_data)

        result: dict = {
            "block_index": block_index,
            "old_offset": old_start,
            "old_size": old_size,
            "new_size": new_size,
            "strategy": "unknown",
        }

        try:
            _maj, _min, old_total_u, _tc = parse_sges_header(
                mm[old_start:old_start + 16]
            )
            result["old_uncompressed"] = old_total_u
        except Exception:
            pass

        _maj2, _min2, new_total_u, _tc2 = parse_sges_header(new_sges_data[:16])
        result["new_uncompressed"] = new_total_u

        if new_size > old_size:
            result["strategy"] = "too_large"
            result["overshoot"] = new_size - old_size
            if dry_run:
                result["dry_run"] = True
                return result
            raise ValueError(
                f"Recompressed block is {new_size:,} bytes but slot is only "
                f"{old_size:,} bytes ({new_size - old_size:,} bytes over). "
                f"Cannot patch in-place."
            )

        if dry_run:
            result["strategy"] = "inplace"
            result["dry_run"] = True
            return result

        wad_bytes = bytearray(mm[:])
    finally:
        mm.close()

    result["strategy"] = "inplace"
    wad_bytes[old_start:old_start + new_size] = new_sges_data
    if new_size < old_size:
        wad_bytes[old_start + new_size:old_end] = b"\x00" * (old_size - new_size)
    result["patched_offset"] = old_start

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(bytes(wad_bytes))
    result["output"] = str(output_path)

    return result


# ── Unified high-level operations ────────────────────────────────────

def _decompress_block_at(mm: mmap_mod.mmap, start: int, end: int) -> bytes:
    """Decompress an sges block from a memory-mapped WAD region."""
    return decompress_sges_block(mm, start, end)


def _update_block_header_size(block_data: bytearray, entry_index: int, new_chunk_size: int) -> None:
    """Update the chunk_size field in the block's header table for a given entry."""
    struct.pack_into("<I", block_data, 4 + entry_index * 16 + 12, new_chunk_size)


def cmd_list_scripts(wad_path: Path) -> int:
    """List all scripts in the WAD's scripts_vz block."""
    print(f"Reading WAD: {wad_path}")

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: Not an FFCS WAD file", file=sys.stderr)
        return 1

    paths = load_wad_paths(wad_path)
    if not paths:
        print("ERROR: No paths found in WAD PTHS chunk", file=sys.stderr)
        return 1

    script_blocks = find_scripts_block_index(paths)
    if not script_blocks:
        print("ERROR: No scripts_vz block found in paths", file=sys.stderr)
        return 1

    arch = parse_ffcs(wad_path)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None:
        print("ERROR: No DATA chunk", file=sys.stderr)
        return 1

    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)

        for block_idx, block_path in script_blocks:
            if block_idx >= len(boundaries):
                print(f"WARNING: Block {block_idx} ({block_path}) beyond boundary range", file=sys.stderr)
                continue

            start, end = boundaries[block_idx]
            print(f"\nFound {block_path} at block {block_idx} (offset 0x{start:x})")
            print(f"Decompressing sges ({end - start:,} bytes)...")

            try:
                decompressed = _decompress_block_at(mm, start, end)
            except Exception as exc:
                print(f"  ERROR: Failed to decompress: {exc}", file=sys.stderr)
                continue

            print(f"Decompressed to {len(decompressed):,} bytes")

            entries = parse_block_entries(decompressed)
            print(f"UCFX entries: {len(entries)}")
            print()
            print(f"{'Idx':>4}  {'Hash':>10}  {'Size':>8}  {'CSUM':>10}  {'Valid':>5}  Name")
            print("-" * 70)

            for entry in entries:
                name = get_script_name(decompressed, entry)
                stored, computed, match = verify_entry_csum(decompressed, entry)
                csum_str = f"0x{stored:08X}" if stored else "  (none)"
                valid_str = "OK" if match else "BAD"
                print(
                    f"{entry['index']:4d}  0x{entry['hash']:08X}  "
                    f"{entry['size']:8,}  {csum_str}  {valid_str:>5}  {name}"
                )
    finally:
        mm.close()

    return 0


def cmd_patch_script(
    wad_path: Path,
    script_name: str,
    *,
    corrupt_csum: bool = False,
    corrupt_data: bool = False,
    lua_bytecode_path: Path | None = None,
    ucfx_payload_path: Path | None = None,
    no_backup: bool = False,
    dry_run: bool = False,
    segment_size: int = 65536,
    compression_level: int = 6,
    _bytecode_override: bytes | None = None,
) -> int:
    """Patch a specific script within the WAD's scripts_vz block."""
    print(f"Reading WAD: {wad_path}")

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: Not an FFCS WAD file", file=sys.stderr)
        return 1

    paths = load_wad_paths(wad_path)
    if not paths:
        print("ERROR: No paths found in WAD PTHS chunk", file=sys.stderr)
        return 1

    script_blocks = find_scripts_block_index(paths)
    if not script_blocks:
        print("ERROR: No scripts_vz block found", file=sys.stderr)
        return 1

    arch = parse_ffcs(wad_path)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None:
        print("ERROR: No DATA chunk", file=sys.stderr)
        return 1

    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)

        target_block_idx: int | None = None
        target_block_path: str = ""
        target_entry: dict | None = None
        target_decompressed: bytes = b""
        all_script_names: list[str] = []

        for block_idx, block_path in script_blocks:
            if block_idx >= len(boundaries):
                continue

            start, end = boundaries[block_idx]
            print(f"Found {block_path} at block {block_idx} (offset 0x{start:x})")
            print(f"Decompressing sges ({end - start:,} bytes)...")

            try:
                decompressed = _decompress_block_at(mm, start, end)
            except Exception as exc:
                print(f"  ERROR: Failed to decompress: {exc}", file=sys.stderr)
                continue

            print(f"Decompressed to {len(decompressed):,} bytes")
            entries = parse_block_entries(decompressed)
            print(f"UCFX entries: {len(entries)}")

            for entry in entries:
                name = get_script_name(decompressed, entry)
                all_script_names.append(name)
                if script_name.lower() in name.lower():
                    target_block_idx = block_idx
                    target_block_path = block_path
                    target_entry = entry
                    target_decompressed = decompressed
                    break

            if target_entry is not None:
                break

        if target_entry is None:
            print(f"\nERROR: Script '{script_name}' not found.", file=sys.stderr)
            print(f"\nAvailable scripts ({len(all_script_names)}):", file=sys.stderr)
            for sn in all_script_names:
                print(f"  {sn}", file=sys.stderr)
            return 1

        assert target_block_idx is not None
        target_name = get_script_name(target_decompressed, target_entry)
        print(f"\nFound script '{target_name}' at UCFX chunk {target_entry['index']}")
        print(f"  Block:     {target_block_path} (index {target_block_idx})")
        print(f"  Hash:      0x{target_entry['hash']:08X}")
        print(f"  Size:      {target_entry['size']:,} bytes")
        print(f"  Offset:    0x{target_entry['offset']:x} (in decompressed block)")

        stored_csum, computed_csum, csum_ok = verify_entry_csum(
            target_decompressed, target_entry
        )
        print(f"  CSUM:      0x{stored_csum:08X} ({'OK' if csum_ok else 'BAD'})")

        block_start, block_end = boundaries[target_block_idx]
        original_sges_size = block_end - block_start
        max_slot_bytes = original_sges_size
        print(f"  sges slot: {max_slot_bytes:,} bytes (max for recompressed data)")

        modified = bytearray(target_decompressed)

        if corrupt_csum:
            print(f"\nCorrupting CSUM: 0x{stored_csum:08X} → 0xDEADBEEF")
            csum_off = target_entry["csum_offset"]
            if modified[csum_off:csum_off + 4] != CSUM_TAG:
                print("ERROR: CSUM tag not found at expected offset", file=sys.stderr)
                return 1
            struct.pack_into("<I", modified, csum_off + 4, 0xDEADBEEF)

        elif corrupt_data:
            entry_start = target_entry["offset"]
            entry_end = target_entry["offset"] + target_entry["size"] - 8
            chunk = modified[entry_start:entry_end]
            luaq_rel = chunk.find(LUAQ_SIG)
            if luaq_rel < 0:
                print("ERROR: No LuaQ signature in target UCFX chunk", file=sys.stderr)
                return 1
            flip_abs = entry_start + luaq_rel + 16
            old_byte = modified[flip_abs]
            new_byte = old_byte ^ 0xFF
            modified[flip_abs] = new_byte
            print(f"\nFlipped bytecode byte at offset 0x{flip_abs:x}: 0x{old_byte:02X} → 0x{new_byte:02X}")

            csum_off = target_entry["csum_offset"]
            ucfx_data = bytes(modified[entry_start:csum_off])
            new_csum = crc32_mercs2(ucfx_data)
            struct.pack_into("<I", modified, csum_off + 4, new_csum)
            print(f"Recomputed CSUM: 0x{stored_csum:08X} → 0x{new_csum:08X}")

        elif lua_bytecode_path is not None or _bytecode_override is not None:
            if _bytecode_override is not None:
                new_bytecode = _bytecode_override
            elif not lua_bytecode_path.is_file():
                print(f"ERROR: Lua bytecode file not found: {lua_bytecode_path}", file=sys.stderr)
                return 1
            else:
                new_bytecode = lua_bytecode_path.read_bytes()
            if new_bytecode[:4] != b"\x1bLua" and new_bytecode[:4] != LUAQ_SIG:
                print("WARNING: File does not start with LuaQ signature", file=sys.stderr)

            entry_start = target_entry["offset"]
            entry_end = target_entry["offset"] + target_entry["size"] - 8
            chunk = target_decompressed[entry_start:entry_end]
            luaq_rel = chunk.find(LUAQ_SIG)
            if luaq_rel < 0:
                print("ERROR: No LuaQ signature in target UCFX chunk", file=sys.stderr)
                return 1

            old_luaq_abs = entry_start + luaq_rel
            old_luaq_end = entry_end  # bytecode runs to end of UCFX body
            old_bytecode_len = old_luaq_end - old_luaq_abs
            new_bytecode_len = len(new_bytecode)
            size_delta = new_bytecode_len - old_bytecode_len

            print(f"\n  LuaQ at:     0x{old_luaq_abs:x} (entry +{luaq_rel})")
            print(f"  Old bytecode: {old_bytecode_len:,} bytes")
            print(f"  New bytecode: {new_bytecode_len:,} bytes")
            print(f"  Size delta:   {size_delta:+,} bytes")

            pre_luaq = bytes(modified[:old_luaq_abs])
            post_entry = bytes(modified[entry_end:])
            csum_trailer = bytes(modified[entry_end:entry_end + 8])

            new_ucfx_body = pre_luaq[entry_start:] + new_bytecode
            new_chunk = bytes(modified[entry_start:entry_start + 0]) \
                if False else pre_luaq[entry_start:old_luaq_abs] + new_bytecode
            new_chunk_with_csum = new_chunk + CSUM_TAG + b"\x00\x00\x00\x00"
            new_chunk_size = len(new_chunk_with_csum)

            rebuilt = bytearray(modified[:entry_start])
            rebuilt.extend(new_chunk)
            new_csum = crc32_mercs2(bytes(rebuilt[entry_start:]))
            rebuilt.extend(CSUM_TAG)
            rebuilt.extend(struct.pack("<I", new_csum))
            rebuilt.extend(post_entry)

            _update_block_header_size(rebuilt, target_entry["index"], new_chunk_size)

            modified = rebuilt
            print(f"  New CSUM:    0x{new_csum:08X}")

        elif ucfx_payload_path is not None:
            if not ucfx_payload_path.is_file():
                print(f"ERROR: UCFX payload file not found: {ucfx_payload_path}", file=sys.stderr)
                return 1
            new_payload = ucfx_payload_path.read_bytes()

            entry_start = target_entry["offset"]
            entry_end = target_entry["offset"] + target_entry["size"] - 8
            post_entry = bytes(modified[entry_end + 8:])
            old_chunk_size = target_entry["size"]
            new_chunk_with_csum_size = len(new_payload) + 8

            print(f"\n  Old UCFX body: {entry_end - entry_start:,} bytes")
            print(f"  New UCFX body: {len(new_payload):,} bytes")

            rebuilt = bytearray(modified[:entry_start])
            rebuilt.extend(new_payload)
            new_csum = crc32_mercs2(new_payload)
            rebuilt.extend(CSUM_TAG)
            rebuilt.extend(struct.pack("<I", new_csum))
            rebuilt.extend(post_entry)

            _update_block_header_size(rebuilt, target_entry["index"], new_chunk_with_csum_size)

            modified = rebuilt
            print(f"  New CSUM:    0x{new_csum:08X}")

        else:
            print("ERROR: No modification specified (use --corrupt-csum, --corrupt-data, "
                  "--lua-bytecode, or --ucfx-payload)", file=sys.stderr)
            return 1

        print(f"\nRecompressing ({len(modified):,} bytes)...")
        new_sges = compress_sges(
            bytes(modified),
            segment_size=segment_size,
            level=compression_level,
        )
        ratio = len(new_sges) / len(modified) * 100
        print(
            f"Recompressed: {len(new_sges):,} bytes ({ratio:.1f}%), "
            f"slot has {max_slot_bytes:,} bytes"
        )

        if len(new_sges) > max_slot_bytes:
            print(
                f"\nERROR: Recompressed block is {len(new_sges):,} bytes "
                f"but slot is only {max_slot_bytes:,} bytes "
                f"({len(new_sges) - max_slot_bytes:,} bytes over). "
                f"Cannot patch in-place. Try a higher compression level "
                f"(--compression-level 9) or smaller payload.",
                file=sys.stderr,
            )
            return 1

        print(f"Fits in slot: {len(new_sges):,} <= {max_slot_bytes:,} "
              f"({max_slot_bytes - len(new_sges):,} bytes to spare)")

        print(f"\nVerifying recompressed data round-trips correctly...")
        verify_decomp = decompress_sges_block(new_sges, 0, len(new_sges))
        if verify_decomp != bytes(modified):
            print("ERROR: Roundtrip verification failed! Decompressed data differs.", file=sys.stderr)
            return 1
        print("Roundtrip verification OK")

        if dry_run:
            print(f"\n[DRY RUN] Would patch WAD at offset 0x{block_start:x}")
            print(f"[DRY RUN] Would write {len(new_sges):,} bytes + "
                  f"{max_slot_bytes - len(new_sges):,} bytes zero-padding")
            print("[DRY RUN] No files modified.")
            return 0

        wad_bytes = bytearray(mm[:])
    finally:
        mm.close()

    if not no_backup:
        bak = wad_path.with_suffix(wad_path.suffix + ".bak")
        if not bak.exists():
            print(f"Creating backup: {bak}")
            shutil.copy2(wad_path, bak)
        else:
            print(f"Backup already exists: {bak}")

    print(f"Patching WAD at offset 0x{block_start:x}...")
    wad_bytes[block_start:block_start + len(new_sges)] = new_sges
    padding = max_slot_bytes - len(new_sges)
    if padding > 0:
        wad_bytes[block_start + len(new_sges):block_end] = b"\x00" * padding

    try:
        wad_path.write_bytes(bytes(wad_bytes))
    except PermissionError:
        print(f"ERROR: WAD file is read-only: {wad_path}", file=sys.stderr)
        print("Tip: chmod u+w the file or copy it first.", file=sys.stderr)
        return 1

    print("Done.")
    return 0


# ── Auto-complete oilcon001 contract ──────────────────────────────────

OILCON001_MOD_SOURCE = '''\
inherit("MrxTaskContract")
import("MrxUtil")

function Activated(self)
 MrxTaskContract.Activated(self)
 self:_CreateEvent(Event.TimerRelative, {5}, AutoComplete, {self})
end

function AutoComplete(self)
 self:Complete()
end

function Cancel(self)
 MrxTaskContract.Cancel(self)
end

function Cleanup(self)
 MrxTaskContract.Cleanup(self)
end

function LoadAssets()
end
'''


def cmd_auto_complete_oilcon001(
    wad_path: Path,
    *,
    no_backup: bool = False,
    dry_run: bool = False,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Replace oilcon001 with a script that auto-completes on contract accept.

    Compiles a minimal Lua script that inherits MrxTaskContract, calls the
    parent Activated(), then immediately calls self:Complete(). The compiled
    bytecode is injected into the WAD via the standard script-patching pipeline.

    Requires lua-5.1.5/src/luac (the Mercs2-compatible Lua compiler) to be
    built in the repo root.
    """
    import subprocess
    import tempfile

    repo_root = Path(__file__).resolve().parent.parent
    luac = repo_root / "lua-5.1.5" / "src" / "luac"
    if not luac.is_file():
        print(f"ERROR: Lua compiler not found at {luac}", file=sys.stderr)
        print("Build it with: cd lua-5.1.5 && make posix", file=sys.stderr)
        return 1

    print("Auto-Complete OilCon001 — compiling mod...")

    with tempfile.TemporaryDirectory() as tmp:
        src = Path(tmp) / "oilcon001_mod.lua"
        out = Path(tmp) / "oilcon001_mod.luac"
        src.write_text(OILCON001_MOD_SOURCE)

        result = subprocess.run(
            [str(luac), "-o", str(out), str(src)],
            capture_output=True, text=True,
        )
        if result.returncode != 0:
            print(f"ERROR: luac compilation failed:\n{result.stderr}", file=sys.stderr)
            return 1

        bytecode = out.read_bytes()
        print(f"  Compiled: {len(bytecode):,} bytes")

        if bytecode[:4] != b"\x1bLua":
            print("ERROR: Compiled output has wrong signature", file=sys.stderr)
            return 1

        print(f"  Header: version=0x{bytecode[4]:02x} "
              f"int={bytecode[7]} size_t={bytecode[8]} "
              f"number={bytecode[10]} (float={'yes' if bytecode[11]==0 else 'no'})")

    return cmd_patch_script(
        wad_path,
        "oilcon001",
        lua_bytecode_path=None,
        no_backup=no_backup,
        dry_run=dry_run,
        segment_size=segment_size,
        compression_level=compression_level,
        _bytecode_override=bytecode,
    )


# ── String-mod oilcon001 command ──────────────────────────────────────

OILCON001_STRING_SWAPS = [
    (b"[yellow]Threat: \x00",
     b"[yellow]MODDED! \x00",
     "HUD threat meter label"),
    (b"Deliver exec to \x00",
     b"MODDED! exec to \x00",
     "Objective text"),
    (b"[OilCon001.Objectives.filesBurned][objt][yellow][bar\x00",
     b"[OilCon001.Objectives.filesBurned][objt][yellow][MOD\x00",
     "HUD progress bar suffix"),
    (b"[yellow][OilCon001.Objectives.timer]\x00",
     b"[yellow][MODDED!!!.Objectives.timer]\x00",
     "Timer objective label"),
    (b"oc001 defend office\x00",
     b"MODDED defend ofc!!\x00",
     "Defend objective debug name"),
    (b"Error in SetupObjective: no spawnFn, must issue 'setpath' command first \x00",
     b"MODDED!! SetupObjective: no spawnFn, must issue 'setpath' command first \x00",
     "Error message string"),
]

for _old, _new, _desc in OILCON001_STRING_SWAPS:
    assert len(_old) == len(_new), f"Length mismatch for {_desc}: {len(_old)} vs {len(_new)}"


def cmd_string_mod_oilcon001(
    wad_path: Path,
    *,
    no_backup: bool = False,
    dry_run: bool = False,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Apply 6 same-length string swaps to oilcon001's Lua bytecode constant pool.

    Replaces user-visible strings (HUD labels, objective text, error messages)
    with 'MODDED' variants to prove Lua modding works. All replacements are
    the exact same byte length — no structural changes, no recompilation needed.
    """
    print(f"String-Mod OilCon001 — reading WAD: {wad_path}")
    print(f"Strategy: apply {len(OILCON001_STRING_SWAPS)} same-length string "
          "swaps in Lua constant pool")

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: Not an FFCS WAD file", file=sys.stderr)
        return 1

    paths = load_wad_paths(wad_path)
    if not paths:
        print("ERROR: No paths found in WAD PTHS chunk", file=sys.stderr)
        return 1

    script_blocks = find_scripts_block_index(paths)
    if not script_blocks:
        print("ERROR: No scripts_vz block found", file=sys.stderr)
        return 1

    arch = parse_ffcs(wad_path)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None:
        print("ERROR: No DATA chunk", file=sys.stderr)
        return 1

    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)

        target_block_idx: int | None = None
        target_decompressed: bytes = b""
        target_entry: dict | None = None

        for block_idx, block_path in script_blocks:
            if block_idx >= len(boundaries):
                continue

            start, end = boundaries[block_idx]
            print(f"\nFound {block_path} at block {block_idx} "
                  f"(WAD offset 0x{start:x}, {end - start:,} bytes compressed)")

            try:
                decompressed = _decompress_block_at(mm, start, end)
            except Exception as exc:
                print(f"  ERROR: Failed to decompress: {exc}", file=sys.stderr)
                continue

            print(f"  Decompressed: {len(decompressed):,} bytes")
            entries = parse_block_entries(decompressed)

            for entry in entries:
                name = get_script_name(decompressed, entry)
                if "oilcon001" in name.lower():
                    target_block_idx = block_idx
                    target_decompressed = decompressed
                    target_entry = entry
                    break

            if target_entry is not None:
                break

        if target_entry is None or target_block_idx is None:
            print("\nERROR: oilcon001 script not found in WAD", file=sys.stderr)
            return 1

        entry_start = target_entry["offset"]
        entry_body_end = target_entry["offset"] + target_entry["size"] - 8
        chunk = target_decompressed[entry_start:entry_body_end]

        modified = bytearray(target_decompressed)
        patch_count = 0

        print(f"\n  Applying {len(OILCON001_STRING_SWAPS)} string swaps:")
        for old_bytes, new_bytes, desc in OILCON001_STRING_SWAPS:
            hit_pos = chunk.find(old_bytes)
            if hit_pos < 0:
                print(f"    SKIP: {desc} — not found in bytecode", file=sys.stderr)
                continue
            abs_off = entry_start + hit_pos
            modified[abs_off:abs_off + len(old_bytes)] = new_bytes
            patch_count += 1
            print(f"    OK: {desc} (offset 0x{abs_off:x}, {len(old_bytes)} bytes)")

        if patch_count == 0:
            print("\nERROR: No string swaps were applied", file=sys.stderr)
            return 1

        print(f"\n  {patch_count}/{len(OILCON001_STRING_SWAPS)} swaps applied")

        csum_off = target_entry["csum_offset"]
        if modified[csum_off:csum_off + 4] != CSUM_TAG:
            print("ERROR: CSUM tag not found at expected offset", file=sys.stderr)
            return 1

        old_csum = struct.unpack_from("<I", modified, csum_off + 4)[0]
        ucfx_body = bytes(modified[entry_start:csum_off])
        new_csum = crc32_mercs2(ucfx_body)
        struct.pack_into("<I", modified, csum_off + 4, new_csum)
        print(f"  CSUM: 0x{old_csum:08X} → 0x{new_csum:08X}")

        block_start, block_end = boundaries[target_block_idx]
        max_slot_bytes = block_end - block_start

        print(f"\nRecompressing ({len(modified):,} bytes)...")
        new_sges = compress_sges(
            bytes(modified),
            segment_size=segment_size,
            level=compression_level,
        )
        ratio = len(new_sges) / len(modified) * 100
        print(f"Recompressed: {len(new_sges):,} bytes ({ratio:.1f}%), "
              f"slot has {max_slot_bytes:,} bytes")

        if len(new_sges) > max_slot_bytes:
            print(
                f"\nERROR: Recompressed block is {len(new_sges):,} bytes "
                f"but slot is only {max_slot_bytes:,} bytes "
                f"({len(new_sges) - max_slot_bytes:,} over).",
                file=sys.stderr,
            )
            return 1

        spare = max_slot_bytes - len(new_sges)
        print(f"Fits in slot: {len(new_sges):,} <= {max_slot_bytes:,} "
              f"({spare:,} bytes to spare)")

        print("Verifying roundtrip...")
        verify_decomp = decompress_sges_block(new_sges, 0, len(new_sges))
        if verify_decomp != bytes(modified):
            print("ERROR: Roundtrip verification failed!", file=sys.stderr)
            return 1
        print("Roundtrip OK")

        if dry_run:
            print(f"\n[DRY RUN] Would patch WAD at offset 0x{block_start:x}")
            print(f"[DRY RUN] Would write {len(new_sges):,} bytes + "
                  f"{spare:,} bytes zero-padding")
            print("[DRY RUN] No files modified.")
            return 0

        wad_bytes = bytearray(mm[:])
    finally:
        mm.close()

    if not no_backup:
        bak = wad_path.with_suffix(wad_path.suffix + ".bak")
        if not bak.exists():
            print(f"Creating backup: {bak}")
            shutil.copy2(wad_path, bak)
        else:
            print(f"Backup already exists: {bak}")

    print(f"Patching WAD at offset 0x{block_start:x}...")
    wad_bytes[block_start:block_start + len(new_sges)] = new_sges
    if spare > 0:
        wad_bytes[block_start + len(new_sges):block_end] = b"\x00" * spare

    try:
        wad_path.write_bytes(bytes(wad_bytes))
    except PermissionError:
        print(f"ERROR: WAD file is read-only: {wad_path}", file=sys.stderr)
        print("Tip: chmod u+w the file or copy it first.", file=sys.stderr)
        return 1

    print(f"\nDone. {patch_count} string(s) modded in oilcon001 bytecode.")
    return 0


# ── Extend demo timer command ────────────────────────────────────────

DEMO_QUIT_METHOD = b"ShowDemoOutroAndQuitToShell"
DEMO_QUIT_REPLACEMENT = b"_DisabledDemoQuitToShell___"

assert len(DEMO_QUIT_METHOD) == len(DEMO_QUIT_REPLACEMENT)


def cmd_extend_demo_timer(
    wad_path: Path,
    *,
    no_backup: bool = False,
    dry_run: bool = False,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Extend the demo timer by disabling the ShowDemoOutroAndQuitToShell calls.

    The 15-minute demo timer is hardcoded in the C++ engine (MrxPlayState::
    StartSessionTimer). When it expires, the engine fires a Lua callback that
    calls MrxGuiCinematic:ShowDemoOutroAndQuitToShell(), which plays the outro
    video and boots the player to the main menu.

    This command replaces every occurrence of the method name string in the Lua
    bytecode constant pool with a same-length nonsense name. When Lua tries to
    call this non-existent method, the call silently fails (nil method on the
    object), and the demo continues running.

    Both scripts that invoke this method are patched:
      - oilcon002  (chunk 77): calls it on mission-complete/dialog-dismiss
      - wifmissionflow (chunk 78): calls it on demo timer expiry
    """
    print(f"Extend Demo Timer — reading WAD: {wad_path}")
    print(f"Strategy: replace \"{DEMO_QUIT_METHOD.decode()}\" → "
          f"\"{DEMO_QUIT_REPLACEMENT.decode()}\" in Lua constant pools")

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        print("ERROR: Not an FFCS WAD file", file=sys.stderr)
        return 1

    paths = load_wad_paths(wad_path)
    if not paths:
        print("ERROR: No paths found in WAD PTHS chunk", file=sys.stderr)
        return 1

    script_blocks = find_scripts_block_index(paths)
    if not script_blocks:
        print("ERROR: No scripts_vz block found", file=sys.stderr)
        return 1

    arch = parse_ffcs(wad_path)
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if data_chunk is None:
        print("ERROR: No DATA chunk", file=sys.stderr)
        return 1

    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)

        target_block_idx: int | None = None
        target_decompressed: bytes = b""
        target_block_path: str = ""

        for block_idx, block_path in script_blocks:
            if block_idx >= len(boundaries):
                continue

            start, end = boundaries[block_idx]
            print(f"\nFound {block_path} at block {block_idx} "
                  f"(WAD offset 0x{start:x}, {end - start:,} bytes compressed)")

            try:
                decompressed = _decompress_block_at(mm, start, end)
            except Exception as exc:
                print(f"  ERROR: Failed to decompress: {exc}", file=sys.stderr)
                continue

            print(f"  Decompressed: {len(decompressed):,} bytes")

            hit_count = decompressed.count(DEMO_QUIT_METHOD)
            if hit_count == 0:
                print(f"  No \"{DEMO_QUIT_METHOD.decode()}\" found — skipping")
                continue

            print(f"  Found {hit_count} occurrence(s) of \"{DEMO_QUIT_METHOD.decode()}\"")
            target_block_idx = block_idx
            target_decompressed = decompressed
            target_block_path = block_path
            break

        if target_block_idx is None:
            print(f"\nERROR: \"{DEMO_QUIT_METHOD.decode()}\" not found in any "
                  "scripts block", file=sys.stderr)
            return 1

        modified = bytearray(target_decompressed)
        entries = parse_block_entries(target_decompressed)

        patch_count = 0
        affected_entries: list[int] = []

        for entry in entries:
            entry_start = entry["offset"]
            entry_body_end = entry["offset"] + entry["size"] - 8
            chunk = modified[entry_start:entry_body_end]

            hits_in_chunk = chunk.count(DEMO_QUIT_METHOD)
            if hits_in_chunk == 0:
                continue

            name = get_script_name(target_decompressed, entry)
            print(f"\n  Patching chunk {entry['index']} ({name}): "
                  f"{hits_in_chunk} replacement(s)")
            affected_entries.append(entry["index"])

            pos = 0
            while True:
                idx = chunk.find(DEMO_QUIT_METHOD, pos)
                if idx < 0:
                    break
                abs_off = entry_start + idx
                modified[abs_off:abs_off + len(DEMO_QUIT_METHOD)] = DEMO_QUIT_REPLACEMENT
                print(f"    0x{abs_off:06x}: replaced")
                patch_count += 1
                pos = idx + len(DEMO_QUIT_METHOD)

            csum_off = entry["csum_offset"]
            if modified[csum_off:csum_off + 4] != CSUM_TAG:
                print(f"    WARNING: CSUM tag not found at 0x{csum_off:x}",
                      file=sys.stderr)
                continue

            old_csum = struct.unpack_from("<I", modified, csum_off + 4)[0]
            ucfx_body = bytes(modified[entry_start:csum_off])
            new_csum = crc32_mercs2(ucfx_body)
            struct.pack_into("<I", modified, csum_off + 4, new_csum)
            print(f"    CSUM: 0x{old_csum:08X} → 0x{new_csum:08X}")

        if patch_count == 0:
            print("\nERROR: No replacements made", file=sys.stderr)
            return 1

        print(f"\n{patch_count} replacement(s) in {len(affected_entries)} chunk(s)")

        assert target_block_idx is not None
        block_start, block_end = boundaries[target_block_idx]
        max_slot_bytes = block_end - block_start

        print(f"\nRecompressing ({len(modified):,} bytes)...")
        new_sges = compress_sges(
            bytes(modified),
            segment_size=segment_size,
            level=compression_level,
        )
        ratio = len(new_sges) / len(modified) * 100
        print(f"Recompressed: {len(new_sges):,} bytes ({ratio:.1f}%), "
              f"slot has {max_slot_bytes:,} bytes")

        if len(new_sges) > max_slot_bytes:
            print(
                f"\nERROR: Recompressed block is {len(new_sges):,} bytes "
                f"but slot is only {max_slot_bytes:,} bytes "
                f"({len(new_sges) - max_slot_bytes:,} over).",
                file=sys.stderr,
            )
            return 1

        spare = max_slot_bytes - len(new_sges)
        print(f"Fits in slot: {len(new_sges):,} <= {max_slot_bytes:,} "
              f"({spare:,} bytes to spare)")

        print("Verifying roundtrip...")
        verify_decomp = decompress_sges_block(new_sges, 0, len(new_sges))
        if verify_decomp != bytes(modified):
            print("ERROR: Roundtrip verification failed!", file=sys.stderr)
            return 1
        print("Roundtrip OK")

        if dry_run:
            print(f"\n[DRY RUN] Would patch WAD at offset 0x{block_start:x}")
            print(f"[DRY RUN] Would write {len(new_sges):,} bytes + "
                  f"{spare:,} bytes zero-padding")
            print("[DRY RUN] No files modified.")
            return 0

        wad_bytes = bytearray(mm[:])
    finally:
        mm.close()

    if not no_backup:
        bak = wad_path.with_suffix(wad_path.suffix + ".bak")
        if not bak.exists():
            print(f"Creating backup: {bak}")
            shutil.copy2(wad_path, bak)
        else:
            print(f"Backup already exists: {bak}")

    print(f"Patching WAD at offset 0x{block_start:x}...")
    wad_bytes[block_start:block_start + len(new_sges)] = new_sges
    if spare > 0:
        wad_bytes[block_start + len(new_sges):block_end] = b"\x00" * spare

    try:
        wad_path.write_bytes(bytes(wad_bytes))
    except PermissionError:
        print(f"ERROR: WAD file is read-only: {wad_path}", file=sys.stderr)
        print("Tip: chmod u+w the file or copy it first.", file=sys.stderr)
        return 1

    print(f"\nDone. Demo quit function disabled in {patch_count} location(s).")
    print("The engine's 15-minute timer will still count down, but the quit")
    print("action will silently fail, allowing play to continue indefinitely.")
    return 0


# ── Legacy list-blocks command ───────────────────────────────────────

def list_blocks(wad_path: Path, paths: list[str] | None = None) -> None:
    """List all sges blocks in the WAD."""
    data_chunk = find_data_chunk(wad_path)

    with open(wad_path, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)

    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        print(f"WAD: {wad_path}")
        print(f"DATA chunk: offset=0x{data_chunk.offset:x} size={data_chunk.size:,}")
        print(f"Blocks found: {len(boundaries)}")
        print()
        print(f"{'Index':>6}  {'Offset':>12}  {'Size':>10}  {'Uncompr':>10}  {'Segs':>5}  Path")
        print("-" * 80)

        for i, (start, end) in enumerate(boundaries):
            size = end - start
            try:
                _maj, minor, total_u, _tc = parse_sges_header(mm[start:start + 16])
                seg_str = str(minor)
                u_str = f"{total_u:,}"
            except Exception:
                seg_str = "?"
                u_str = "?"
            path_str = paths[i] if paths and i < len(paths) else ""
            print(f"{i:6d}  0x{start:010x}  {size:10,}  {u_str:>10}  {seg_str:>5}  {path_str}")
    finally:
        mm.close()


# ── CLI ──────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Unified WAD patching tool for Mercenaries 2 modding",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  %(prog)s --wad vz.wad --list-scripts\n"
            "  %(prog)s --wad vz.wad --script wiftutorialtank --corrupt-csum --dry-run\n"
            "  %(prog)s --wad vz.wad --script wiftutorialtank --lua-bytecode compiled.luac\n"
            "  %(prog)s --wad vz.wad --extend-demo-timer\n"
            "  %(prog)s --wad vz.wad --auto-complete-oilcon001\n"
            "  %(prog)s --wad vz.wad --string-mod-oilcon001\n"
            "  %(prog)s vz.wad --index 1257 --sges-file modified.sges.bin --output patched.wad\n"
        ),
    )

    # Unified mode args
    ap.add_argument("--wad", type=Path, help="Path to .wad file (unified mode)")
    ap.add_argument("--list-scripts", action="store_true",
                    help="List all scripts in the scripts_vz block")
    ap.add_argument("--script", type=str,
                    help="Target script name (substring match)")
    ap.add_argument("--corrupt-csum", action="store_true",
                    help="Set the target script's CSUM to 0xDEADBEEF")
    ap.add_argument("--corrupt-data", action="store_true",
                    help="Flip one bytecode byte and recompute CSUM (test content modification)")
    ap.add_argument("--lua-bytecode", type=Path,
                    help="Replace script's LuaQ bytecode with this file")
    ap.add_argument("--ucfx-payload", type=Path,
                    help="Replace the entire UCFX chunk body with this file")
    ap.add_argument("--extend-demo-timer", action="store_true",
                    help="Disable the demo quit function so the 15-minute "
                         "timer expiry no longer boots the player")
    ap.add_argument("--auto-complete-oilcon001", action="store_true",
                    help="Replace oilcon001 with a script that auto-completes "
                         "the contract on accept (proof-of-concept mod)")
    ap.add_argument("--string-mod-oilcon001", action="store_true",
                    help="Replace '[yellow]Threat: ' with '[yellow]MODDED! ' "
                         "in oilcon001 bytecode (simplest string-swap mod)")
    ap.add_argument("--no-backup", action="store_true",
                    help="Skip creating .wad.bak backup before patching")
    ap.add_argument("--dry-run", action="store_true",
                    help="Show what would change without writing")

    # Legacy positional + block-level args
    ap.add_argument("wad_positional", type=Path, nargs="?", default=None,
                    help=argparse.SUPPRESS)
    ap.add_argument("--output", "-o", type=Path,
                    help="Output .wad file (legacy block-patch mode)")
    ap.add_argument("--index", type=int,
                    help="Block index for legacy patching (0-based)")
    ap.add_argument("--sges-file", type=Path,
                    help="Pre-compressed sges file to inject (legacy mode)")
    ap.add_argument("--block-file", type=Path,
                    help="Decompressed block file (legacy mode, auto-compressed)")
    ap.add_argument("--segment-size", type=int, default=65536,
                    help="Segment size for sges compression (default 65536)")
    ap.add_argument("--compression-level", type=int, default=6,
                    help="zlib compression level 1-9 (default 6)")
    ap.add_argument("--list-blocks", action="store_true",
                    help="List all sges blocks in the WAD (legacy mode)")
    ap.add_argument("--paths", type=Path,
                    help="paths.txt for block name annotation (legacy mode)")

    args = ap.parse_args()

    wad_path = args.wad or args.wad_positional
    if wad_path is None:
        ap.error("--wad is required")
    if not wad_path.is_file():
        print(f"ERROR: WAD file not found: {wad_path}", file=sys.stderr)
        return 1

    # Verify FFCS magic
    with open(wad_path, "rb") as f:
        magic = f.read(4)
    if magic != b"FFCS":
        print(f"ERROR: Not an FFCS WAD file (magic: {magic!r})", file=sys.stderr)
        return 1

    # ── Unified script commands ──────────────────────────────────
    if args.list_scripts:
        return cmd_list_scripts(wad_path)

    if args.auto_complete_oilcon001:
        return cmd_auto_complete_oilcon001(
            wad_path,
            no_backup=args.no_backup,
            dry_run=args.dry_run,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    if args.string_mod_oilcon001:
        return cmd_string_mod_oilcon001(
            wad_path,
            no_backup=args.no_backup,
            dry_run=args.dry_run,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    if args.extend_demo_timer:
        return cmd_extend_demo_timer(
            wad_path,
            no_backup=args.no_backup,
            dry_run=args.dry_run,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    if args.script:
        if not (args.corrupt_csum or args.corrupt_data or args.lua_bytecode or args.ucfx_payload):
            ap.error("--script requires one of: --corrupt-csum, --corrupt-data, --lua-bytecode, --ucfx-payload")

        return cmd_patch_script(
            wad_path,
            args.script,
            corrupt_csum=args.corrupt_csum,
            corrupt_data=args.corrupt_data,
            lua_bytecode_path=args.lua_bytecode,
            ucfx_payload_path=args.ucfx_payload,
            no_backup=args.no_backup,
            dry_run=args.dry_run,
            segment_size=args.segment_size,
            compression_level=args.compression_level,
        )

    # ── Legacy block-level commands ──────────────────────────────
    if args.list_blocks:
        block_paths = None
        if args.paths and args.paths.is_file():
            block_paths = [
                ln
                for ln in args.paths.read_text(encoding="utf-8", errors="replace").splitlines()
                if ln.strip()
            ]
        list_blocks(wad_path, block_paths)
        return 0

    if args.index is not None:
        if args.output is None:
            ap.error("--output is required for block-level patching")

        if args.sges_file:
            if not args.sges_file.is_file():
                print(f"sges file not found: {args.sges_file}", file=sys.stderr)
                return 1
            new_data = args.sges_file.read_bytes()
            if new_data[:4] != SGES_MAGIC:
                print("ERROR: sges file does not start with sges magic", file=sys.stderr)
                return 1
        elif args.block_file:
            if not args.block_file.is_file():
                print(f"Block file not found: {args.block_file}", file=sys.stderr)
                return 1
            raw = args.block_file.read_bytes()
            print(f"Compressing {args.block_file} ({len(raw):,} bytes)...")
            new_data = compress_sges(
                raw,
                segment_size=args.segment_size,
                level=args.compression_level,
            )
            ratio = len(new_data) / len(raw) * 100
            print(f"Compressed to {len(new_data):,} bytes ({ratio:.1f}%)")
        else:
            ap.error("Provide --sges-file or --block-file for block-level patching")
            return 1

        print(f"Patching block {args.index} in {wad_path}...")
        result = patch_inplace(
            wad_path, args.output, args.index, new_data, dry_run=args.dry_run,
        )

        print(f"Strategy: {result['strategy']}")
        print(f"Old block: offset=0x{result['old_offset']:x}, size={result['old_size']:,}")
        print(f"New block: size={result['new_size']:,}")
        if "old_uncompressed" in result:
            print(f"Old uncompressed: {result['old_uncompressed']:,}")
        if "new_uncompressed" in result:
            print(f"New uncompressed: {result['new_uncompressed']:,}")

        if args.dry_run:
            print("(dry run — no files written)")
        else:
            print(f"Output: {result['output']}")

        return 0

    ap.error("Specify --list-scripts, --extend-demo-timer, --auto-complete-oilcon001, "
             "--string-mod-oilcon001, --script <name>, --list-blocks, or --index <N>")
    return 1


if __name__ == "__main__":
    sys.exit(main())
