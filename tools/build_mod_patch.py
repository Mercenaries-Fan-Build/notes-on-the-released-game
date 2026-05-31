#!/usr/bin/env python3
"""Build a patch WAD for custom Lua mod scripts (nohook approach).

Appends new UCFX entries to the scripts_vz block WITHOUT modifying any
existing retail entries.  An ASI plugin triggers import("modloader") at
runtime after the world loads.

Usage:
    python build_mod_patch.py --source-wad data/vz.wad \
        --mod-dir mods/patrol \
        --output output/vz-patch.wad

The --mod-dir must contain:
    modloader.lua    — entry point (imported by ASI after world load)
    *.lua            — additional scripts referenced by modloader
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from build_patch_wad import (  # noqa: E402
    _build_ucfx_script_chunk,
    _add_ucfx_entry_to_block,
    compile_lua_source,
    extract_block_metadata,
    parse_block_entries,
    _resolve_luac,
)
from ffcs_patch_wad import (  # noqa: E402
    PatchBlock,
    PAGE_SIZE,
    _align_up,
    build_patch_wad_single,
    read_patch_wad,
)
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_compress import compress_sges  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    script_aset_entry,
    resolve_scripts_vz_block_index,
)


def discover_mod_scripts(mod_dir: Path) -> tuple[Path, list[Path]]:
    """Find modloader.lua and all other .lua files in the mod directory."""
    modloader = mod_dir / "modloader.lua"
    if not modloader.is_file():
        raise FileNotFoundError(
            f"No modloader.lua found in {mod_dir}. "
            f"This file is the entry point that registers missions."
        )
    others = sorted(
        p for p in mod_dir.glob("*.lua")
        if p.name != "modloader.lua"
    )
    return modloader, others


def cmd_build_mod_patch(
    source_wad: Path,
    mod_dir: Path,
    output: Path,
    *,
    merge_from: Path | None = None,
    segment_size: int = 65536,
    compression_level: int = 6,
) -> int:
    """Build a nohook patch WAD: append new entries, never modify existing ones."""
    print("Custom Mod Patch Builder (nohook)")
    print("=" * 60)
    print(f"  Source WAD: {source_wad}")
    print(f"  Mod dir:    {mod_dir}")
    print(f"  Output:     {output}")

    print("\n[1/6] Discovering mod scripts...")
    modloader_path, other_scripts = discover_mod_scripts(mod_dir)
    all_scripts = [modloader_path] + other_scripts
    print(f"  Modloader:  {modloader_path.name}")
    for s in other_scripts:
        print(f"  Script:     {s.name}")

    print("\n[2/6] Compiling mod scripts...")
    try:
        luac = _resolve_luac()
    except FileNotFoundError as e:
        print(f"ERROR: {e}", file=sys.stderr)
        return 1
    print(f"  Lua compiler: {luac}")

    compiled: list[tuple[str, bytes, int]] = []
    for script_path in all_scripts:
        name = script_path.stem
        source = script_path.read_text()
        print(f"\n  Compiling {name}...")
        bytecode = compile_lua_source(source, luac)
        asset_hash = pandemic_hash_m2(name)
        print(f"    Asset hash: 0x{asset_hash:08X}")
        compiled.append((name, bytecode, asset_hash))

    print("\n[3/6] Locating scripts_vz block...")
    scripts_idx = resolve_scripts_vz_block_index(source_wad)
    print(f"  Block index: {scripts_idx}")

    meta = extract_block_metadata(source_wad, scripts_idx)
    print(f"  ASET entries: {meta['aset_entry_count']}")
    print(f"  PTHS: {meta['pths_string']}")

    print("\n[4/6] Decompressing scripts_vz block...")
    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(
        compressed_data, 0, len(compressed_data)
    )
    print(f"  Decompressed: {len(decompressed):,} bytes")

    entries = parse_block_entries(decompressed)
    print(f"  UCFX entries: {len(entries)}")

    print("\n[5/6] Appending mod UCFX entries (nohook — no retail modifications)...")
    modified = decompressed
    aset_entries = list(meta["aset_entries"])

    for name, bytecode, asset_hash in compiled:
        print(f"  Building UCFX for {name}...")
        ucfx_chunk = _build_ucfx_script_chunk(
            name, bytecode, asset_hash,
        )
        print(f"    UCFX size: {len(ucfx_chunk):,} bytes")

        modified = _add_ucfx_entry_to_block(
            modified, ucfx_chunk, asset_hash,
        )
        aset_entries.append(script_aset_entry(asset_hash))

    new_entries = parse_block_entries(modified)
    print(f"  Block now has {len(new_entries)} entries "
          f"(was {len(entries)}, added {len(compiled)})")
    print(f"  All {len(entries)} retail entries UNMODIFIED")

    print("\n[6/6] Recompressing and building patch WAD...")
    new_sges = compress_sges(
        modified,
        segment_size=segment_size,
        level=compression_level,
        major=4,
    )
    ratio = len(new_sges) / len(modified) * 100
    print(f"  Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("ERROR: Roundtrip verification failed!", file=sys.stderr)
        return 1
    print("  Roundtrip verification OK")

    if merge_from and merge_from.is_file():
        print(f"\n  Merging into existing patch WAD: {merge_from}")
        existing = read_patch_wad(merge_from)
        new_block = PatchBlock(
            compressed_data=new_sges,
            path_string=meta["pths_string"],
            aset_entries=aset_entries,
            packed_field=meta["indx_entry"].get("packed_field", 1),
            flags=meta["indx_entry"].get("flags", 0x8000),
        )
        existing.blocks.append(new_block)
        from ffcs_patch_wad import build_patch_wad_multi
        patch_wad = build_patch_wad_multi(
            blocks=existing.blocks,
            csum_value=existing.csum_value,
        )
    else:
        patch_wad = build_patch_wad_single(
            indx_entry=meta["indx_entry"],
            aset_entries=aset_entries,
            pths_string=meta["pths_string"],
            compressed_block=new_sges,
            csum_value=meta.get("csum_value", 0),
        )

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_bytes(patch_wad)
    print(f"\n  Wrote: {output} ({len(patch_wad):,} bytes)")

    print(f"\n{'=' * 60}")
    print("Mod Patch Build Complete (nohook)")
    print(f"{'=' * 60}")
    print(f"\nScripts appended (no retail entries modified):")
    for name, bytecode, asset_hash in compiled:
        print(f"  {name}: {len(bytecode):,} bytes, hash 0x{asset_hash:08X}")
    print(f"\nTo install:")
    print(f"  1. Copy {output.name} to the game's data/ directory")
    print(f"  2. Copy mod_enable.asi to the game's scripts/ directory")
    print(f"  3. The ASI calls import(\"modloader\") after the world loads")

    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Build a nohook patch WAD for custom Mercenaries 2 Lua mods",
    )
    ap.add_argument("--source-wad", type=Path, required=True,
                    help="Path to the retail vz.wad")
    ap.add_argument("--mod-dir", type=Path, required=True,
                    help="Directory containing modloader.lua + script .lua files")
    ap.add_argument("--output", "-o", type=Path, required=True,
                    help="Output path for the patch WAD")
    ap.add_argument("--merge-from", type=Path, default=None,
                    help="Merge into an existing patch WAD")
    ap.add_argument("--segment-size", type=int, default=65536,
                    help="Segment size for sges compression (default 65536)")
    ap.add_argument("--compression-level", type=int, default=6,
                    help="zlib compression level 1-9 (default 6)")

    args = ap.parse_args()
    return cmd_build_mod_patch(
        source_wad=args.source_wad,
        mod_dir=args.mod_dir,
        output=args.output,
        merge_from=args.merge_from,
        segment_size=args.segment_size,
        compression_level=args.compression_level,
    )


if __name__ == "__main__":
    sys.exit(main())
