#!/usr/bin/env python3
"""Verify DLC bootstrap hook script in vz-patch.wad (G2 PC activation gate).

Checks scripts_vz for:
  - Presence of hook candidates (vz, wifmissionflow, wifpmcinterior)
  - dlc01 UCFX entry (string in chunk body)
  - Hook script bytecode containing ``dlc01`` (import wrapper was applied)

Usage:
  .venv/bin/python3 tools/verify_patch_dlc_hook.py --wad path/to/vz-patch.wad
  .venv/bin/python3 tools/verify_patch_dlc_hook.py --wad path/to/vz-patch.wad --scripts-block 2196
"""
from __future__ import annotations

import argparse
import mmap as mmap_mod
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_wad import parse_ffcs  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    DLC_BOOTSTRAP_HOOK_SCRIPTS,
    find_dlc_bootstrap_hook_script,
    find_scripts_block_index,
    get_block_boundaries,
    get_script_name,
    load_wad_paths,
    parse_block_entries,
)

DLC01_HASH = pandemic_hash_m2("dlc01")
LUAQ_SIG = b"\x1bLuaQ"


def _decompress_scripts_vz(wad: Path, block_index: int | None) -> tuple[bytes, int, str]:
    paths = load_wad_paths(wad)
    matches = find_scripts_block_index(paths)
    if not matches:
        raise ValueError("no scripts_vz block in PTHS")

    if block_index is None:
        for idx, path in matches:
            if "scripts_vz_p000" in path.lower().replace("\\", "/"):
                block_index = idx
                block_path = path
                break
        else:
            block_index, block_path = matches[0]
    else:
        block_path = paths[block_index] if block_index < len(paths) else "?"

    arch = parse_ffcs(wad)
    data = next(c for c in arch.chunks if c.tag == "DATA")
    with open(wad, "rb") as f:
        mm = mmap_mod.mmap(f.fileno(), 0, access=mmap_mod.ACCESS_READ)
        try:
            bounds = get_block_boundaries(mm, data.offset, data.size)
            start, end = bounds[block_index]
            dec = decompress_sges_block(mm, start, end)
        finally:
            mm.close()

    return dec, block_index, block_path


def _entry_has_dlc01_string(data: bytes, entry: dict) -> bool:
    start = entry["offset"]
    end = start + entry["size"]
    body = data[start:end]
    return b"dlc01" in body


def _hook_bytecode_has_dlc01(data: bytes, entry: dict) -> bool:
    start = entry["offset"]
    end = start + entry["size"] - 8
    chunk = data[start:end]
    luaq = chunk.find(LUAQ_SIG)
    if luaq < 0:
        return False
    return b"dlc01" in chunk[luaq:]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--wad", type=Path, required=True)
    ap.add_argument(
        "--scripts-block",
        type=int,
        default=None,
        help="scripts_vz block index (default: auto from PTHS)",
    )
    args = ap.parse_args()

    if not args.wad.is_file():
        print(f"ERROR: not found: {args.wad}", file=sys.stderr)
        return 1

    try:
        dec, bi, path = _decompress_scripts_vz(args.wad, args.scripts_block)
    except (ValueError, IndexError, OSError) as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1

    entries = parse_block_entries(dec)
    by_name: dict[str, dict] = {}
    for e in entries:
        name = get_script_name(dec, e)
        if name and name != "(unknown)":
            by_name[name] = e

    print(f"WAD: {args.wad}")
    print(f"  scripts_vz block: {bi} ({path})")
    print(f"  UCFX entries: {len(entries)}")
    print(f"  dlc01 hash: 0x{DLC01_HASH:08X}")

    dlc01_entries = [e for e in entries if e["hash"] == DLC01_HASH]
    if not dlc01_entries:
        print("  FAIL: no UCFX entry with dlc01 asset hash")
        return 1
    for e in dlc01_entries:
        name = get_script_name(dec, e)
        print(f"  dlc01 chunk: index={e['index']} name={name!r} size={e['size']:,}")

    print("\n  Hook candidates:")
    hook_found = None
    for cand in DLC_BOOTSTRAP_HOOK_SCRIPTS:
        if cand in by_name:
            e = by_name[cand]
            has_str = _entry_has_dlc01_string(dec, e)
            has_bc = _hook_bytecode_has_dlc01(dec, e)
            status = "IMPORT_WRAPPER" if has_bc else ("dlc01 in chunk" if has_str else "no dlc01 ref")
            print(f"    {cand}: present, size={e['size']:,}, {status}")
            if hook_found is None:
                hook_found = cand
        else:
            print(f"    {cand}: absent")

    hook = find_dlc_bootstrap_hook_script(dec, entries)
    if hook:
        name, entry = hook
        print(f"\n  find_dlc_bootstrap_hook_script -> {name!r}")
        if _hook_bytecode_has_dlc01(dec, entry):
            orig_name = f"{name}_orig"
            if orig_name in by_name:
                oe = by_name[orig_name]
                print(
                    f"  OK: chain wrapper + {orig_name!r} preserved "
                    f"({oe['size']:,} bytes)"
                )
            elif entry["size"] < 2048:
                print(
                    f"  FAIL: hook is only {entry['size']:,} bytes and no {orig_name!r} — "
                    "minimal import stub will hang VZ load (re-run dlc-port with chain-load fix)"
                )
                return 1
            else:
                print(
                    "  OK: hook bytecode references dlc01 "
                    "(no _orig entry — legacy vz-only hook?)"
                )
            return 0
        print(
            "  FAIL: hook script exists but bytecode has no dlc01 — "
            "dlc-port did not apply import wrapper (PC needs patch or ASI)"
        )
        return 1

    print("\n  FAIL: no hook script (vz / wifmissionflow / wifpmcinterior) in scripts_vz")
    print("        WAD-only activation will not run; use ASI or fix dlc_port hook inject.")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
