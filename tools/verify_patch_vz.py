#!/usr/bin/env python3
"""Verify G2b: retail ``vz`` masterscript preserved in vz-patch.wad.

Checks scripts_vz for the UCFX entry with pandemic_hash_m2('vz') (0xB4420059):
  - LuaQ bytecode present, size >= 30_000 (not a minimal import stub)
  - Source name ``vz`` at bytecode offset 0x10 (0x76 0x7A)
  - Full UCFX chunk SHA256 matches the reference retail vz.wad entry

FAIL if vz entry missing, bytecode < 2048 bytes, or SHA256 mismatch vs reference.

Usage:
  python3 tools/verify_patch_vz.py --wad path/to/vz-patch.wad
  python3 tools/verify_patch_vz.py --wad fresh-rebuilt/data/vz-patch.wad \\
      --reference-wad game-files/vz.wad
"""
from __future__ import annotations

import argparse
import hashlib
import mmap as mmap_mod
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    find_data_chunk,
    get_block_boundaries,
    get_script_name,
    parse_block_entries,
    resolve_scripts_vz_block_index,
)

LUAQ_SIG = b"\x1bLuaQ"
VZ_HASH = pandemic_hash_m2("vz")
VZ_ORIG_HASH = pandemic_hash_m2("vz_orig")
# Full UCFX chunk (BINN + LuaQ + CSUM trailer) for retail vz entry index 10.
RETAIL_VZ_CHUNK_SHA256 = (
    "0d08a3bf1a095901dca0b573402fa9076fddddc22fe95c69432c39ea9528fff5"
)
MIN_VZ_BYTECODE_SIZE = 30_000
STUB_BYTECODE_SIZE = 2048
VZ_SOURCE_NAME_OFFSET = 0x10
VZ_SOURCE_NAME_BYTES = b"vz"


def _decompress_scripts_vz(wad: Path, block_index: int) -> tuple[bytes, int]:
    """Decompress scripts_vz block; return (decompressed, block_index)."""
    data_chunk = find_data_chunk(wad)
    arch = parse_ffcs(wad)
    with open(wad, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        try:
            bounds = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
            start, end = bounds[block_index]
            dec = decompress_sges_block(mm, start, end)
        finally:
            mm.close()
    return dec, block_index


def _find_entry_by_hash(entries: list[dict], asset_hash: int) -> dict | None:
    hits = [e for e in entries if e["hash"] == asset_hash]
    if not hits:
        return None
    if len(hits) > 1:
        return max(hits, key=lambda e: e["size"])
    return hits[0]


def _entry_chunk(decompressed: bytes, entry: dict) -> bytes:
    """Full UCFX entry bytes (matches cross_platform_vz_compare slice)."""
    start = entry["offset"]
    return decompressed[start : start + entry["size"]]


def _extract_luaq_bytecode(decompressed: bytes, entry: dict) -> bytes | None:
    """LuaQ tail from entry start through chunk end (includes CSUM trailer bytes)."""
    chunk = _entry_chunk(decompressed, entry)
    luaq = chunk.find(LUAQ_SIG)
    if luaq < 0:
        return None
    return chunk[luaq:]


def _analyze_vz_entry(
    label: str,
    decompressed: bytes,
    entry: dict | None,
) -> tuple[bool, dict]:
    """Return (ok, info dict) for one WAD's vz entry."""
    info: dict = {"label": label, "ok": False}
    if entry is None:
        info["error"] = "vz entry missing (no UCFX chunk with hash 0x{:08X})".format(VZ_HASH)
        return False, info

    name = get_script_name(decompressed, entry)
    chunk = _entry_chunk(decompressed, entry)
    bc = _extract_luaq_bytecode(decompressed, entry)
    info.update(
        {
            "index": entry["index"],
            "name": name,
            "chunk_size": entry["size"],
            "bytecode_size": len(bc) if bc else 0,
            "chunk_sha256": hashlib.sha256(chunk).hexdigest(),
        }
    )

    if bc is None:
        info["error"] = "no LuaQ bytecode in vz entry"
        return False, info

    info["bytecode_sha256"] = hashlib.sha256(bc).hexdigest()

    if len(bc) < STUB_BYTECODE_SIZE:
        info["error"] = (
            f"bytecode only {len(bc):,} bytes (< {STUB_BYTECODE_SIZE:,}) — "
            "minimal import stub, not retail masterscript"
        )
        return False, info

    if len(bc) < MIN_VZ_BYTECODE_SIZE:
        info["warn_size"] = (
            f"bytecode {len(bc):,} bytes < expected {MIN_VZ_BYTECODE_SIZE:,} "
            "(retail masterscript is ~38k)"
        )

    if len(bc) <= VZ_SOURCE_NAME_OFFSET + 1:
        info["error"] = "bytecode too short for source name check at 0x10"
        return False, info

    src_at_10 = bc[VZ_SOURCE_NAME_OFFSET : VZ_SOURCE_NAME_OFFSET + 2]
    info["source_at_0x10"] = src_at_10.hex()
    if src_at_10 != VZ_SOURCE_NAME_BYTES:
        info["error"] = (
            f'source name at 0x10 is {src_at_10!r}, expected {VZ_SOURCE_NAME_BYTES!r} ("vz")'
        )
        return False, info

    info["ok"] = True
    return True, info


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True, help="Patch WAD (vz-patch.wad)")
    ap.add_argument(
        "--reference-wad",
        type=Path,
        default=Path("game-files/vz.wad"),
        help="Retail vz.wad for SHA256 reference (default: game-files/vz.wad)",
    )
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1
    if not args.reference_wad.is_file():
        print(f"ERROR: not found: {args.reference_wad}", file=sys.stderr)
        return 1

    try:
        ref_idx = resolve_scripts_vz_block_index(args.reference_wad)
        patch_idx = resolve_scripts_vz_block_index(args.wad)
    except ValueError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    try:
        ref_dec, _ = _decompress_scripts_vz(args.reference_wad, ref_idx)
        patch_dec, _ = _decompress_scripts_vz(args.wad, patch_idx)
    except (IndexError, OSError) as e:
        print(f"ERROR: decompress scripts_vz: {e}", file=sys.stderr)
        return 1

    ref_entries = parse_block_entries(ref_dec)
    patch_entries = parse_block_entries(patch_dec)

    ref_entry = _find_entry_by_hash(ref_entries, VZ_HASH)
    patch_entry = _find_entry_by_hash(patch_entries, VZ_HASH)

    print("G2b verify: vz masterscript in patch WAD")
    print(f"  vz hash:     0x{VZ_HASH:08X} (pandemic_hash_m2('vz'))")
    print(f"  reference:   {args.reference_wad} (scripts_vz block {ref_idx})")
    print(f"  patch WAD:   {args.wad} (scripts_vz block {patch_idx})")
    print(f"  retail chunk SHA256: {RETAIL_VZ_CHUNK_SHA256}")
    print()

    ref_ok, ref_info = _analyze_vz_entry("retail", ref_dec, ref_entry)
    patch_ok, patch_info = _analyze_vz_entry("patch", patch_dec, patch_entry)

    for info in (ref_info, patch_info):
        label = info["label"]
        print(f"  [{label}]")
        if "error" in info and info.get("index") is None:
            print(f"    FAIL: {info['error']}")
            continue
        print(
            f"    entry index={info.get('index')} name={info.get('name')!r} "
            f"chunk={info.get('chunk_size', 0):,} bytecode={info.get('bytecode_size', 0):,}"
        )
        if "chunk_sha256" in info:
            print(f"    chunk SHA256: {info['chunk_sha256']}")
        if "bytecode_sha256" in info:
            print(f"    bytecode SHA256: {info['bytecode_sha256']}")
        if "source_at_0x10" in info:
            print(f"    source@0x10: {info['source_at_0x10']} (expect 767a)")
        if info.get("warn_size"):
            print(f"    WARN: {info['warn_size']}")
        if "error" in info:
            print(f"    FAIL: {info['error']}")

    # vz_orig warning on patch
    orig_entry = _find_entry_by_hash(patch_entries, VZ_ORIG_HASH)
    orig_by_name = None
    for e in patch_entries:
        n = get_script_name(patch_dec, e)
        if n == "vz_orig":
            orig_by_name = e
            break

    if orig_entry or orig_by_name:
        oe = orig_entry or orig_by_name
        on = get_script_name(patch_dec, oe)
        print()
        print(
            f"  WARN: vz_orig backup present (hash 0x{VZ_ORIG_HASH:08X}, "
            f"name={on!r}, chunk={oe['size']:,}) — patch may chain-load via wrapper"
        )

    print()
    passed = True

    if not ref_ok:
        print("  FAIL: reference retail vz entry invalid (cannot establish baseline)")
        passed = False
    elif ref_info.get("chunk_sha256") != RETAIL_VZ_CHUNK_SHA256:
        print(
            f"  FAIL: reference chunk SHA256 mismatch "
            f"(got {ref_info.get('chunk_sha256')}, expected {RETAIL_VZ_CHUNK_SHA256})"
        )
        passed = False

    if not patch_ok:
        print("  FAIL: patch WAD vz entry missing or invalid")
        passed = False
    elif patch_info.get("chunk_sha256") != ref_info.get("chunk_sha256"):
        print("  FAIL: patch vz UCFX chunk SHA256 != reference retail")
        print(f"         patch:  {patch_info.get('chunk_sha256')}")
        print(f"         retail: {ref_info.get('chunk_sha256')}")
        passed = False
    elif patch_info.get("bytecode_size", 0) < MIN_VZ_BYTECODE_SIZE:
        print(
            f"  FAIL: patch vz bytecode {patch_info.get('bytecode_size', 0):,} bytes "
            f"< {MIN_VZ_BYTECODE_SIZE:,}"
        )
        passed = False

    if passed:
        print(
            f"  PASS: vz masterscript preserved "
            f"({patch_info.get('bytecode_size', 0):,} bytes LuaQ, chunk SHA256 matches retail)"
        )
        return 0

    print("  G2b: FAIL")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
