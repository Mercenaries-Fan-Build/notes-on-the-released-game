#!/usr/bin/env python3
"""Unified DLC porter — Xbox 360 DLC to PC ``vz-patch.wad``.

Replaces both ``port_xbox_dlc.py`` and ``dlc_port_x360_to_pc.py`` with a
single CLI that uses shared modules:
  - x360_dlc_io: STFS I/O, BE sges decompression, FFCS parsing
  - ucfx_be_to_le: UCFX byte-swap (BE → LE)
  - ffcs_patch_wad: patch WAD assembly + merge

The ``--source-wad`` option enables integrated DLC bootstrap injection:
the tool extracts the ``scripts_vz`` block from the retail WAD, adds the
``dlc01`` master script, and modifies the ``vz`` master script to chain-load
it — producing a single complete ``vz-patch.wad`` with no separate merge step.

Usage:
  # Full pipeline (DLC port + bootstrap injection in one command):
  python3 tools/dlc_port.py --x360-rar Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar \\
      --source-wad path/to/vz.wad \\
      --output vz-patch.wad

  # From Xbox 360 DLC RAR (without bootstrap):
  python3 tools/dlc_port.py --x360-rar Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar \\
      --output vz-patch.wad

  # From pre-extracted STFS container or raw DLC01.doh:
  python3 tools/dlc_port.py --x360-stfs /path/to/stfs_file \\
      --output vz-patch.wad

  # Merge DLC into an existing mod patch WAD:
  python3 tools/dlc_port.py --x360-rar DLC.rar \\
      --merge-into data/vz-patch.wad \\
      --output data/vz-patch.wad

  # List blocks only:
  python3 tools/dlc_port.py --x360-stfs /path/to/stfs --list-blocks
"""
from __future__ import annotations

import argparse
import struct
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from ffcs_patch_wad import (  # noqa: E402
    PatchBlock,
    build_patch_wad_multi,
    merge_patch_wads,
)
from sges_compress import compress_sges  # noqa: E402
from ucfx_be_to_le import byteswap_ucfx_block  # noqa: E402
from x360_dlc_io import (  # noqa: E402
    PAGE_SIZE,
    StfsReader,
    decompress_be_sges,
    extract_stfs_from_rar,
    load_stfs_or_doh,
    parse_be_aset,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)

from build_patch_wad import (  # noqa: E402
    _build_ucfx_script_chunk,
    _add_ucfx_entry_to_block,
    apply_bytecode_replacement_to_block,
    apply_string_mod_to_block,
    compile_lua_source,
    extract_block_metadata,
    VZ_DLC_WRAPPER_SOURCE,
    DLC_CONTRACT_NAMES,
)
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import parse_block_entries, get_script_name  # noqa: E402


# ── Pipeline ──────────────────────────────────────────────────────────

def port_x360_dlc(
    doh: bytes,
    *,
    output_path: Path,
    merge_into: Path | None = None,
    source_wad: Path | None = None,
    max_blocks: int | None = None,
    start_block: int = 0,
    verbose: bool = False,
    dump_dir: Path | None = None,
    dlc_contracts: list[str] | None = None,
    no_bootstrap: bool = False,
) -> int:
    """Convert a big-endian DOH (DLC01.doh content) into a PC vz-patch.wad.

    If *source_wad* is provided (path to retail vz.wad), the bootstrap
    injection is performed automatically: the scripts_vz block is extracted,
    modified with a ``dlc01`` master script, and the ``vz`` master script is
    replaced with a minimal wrapper that chain-loads it.  The resulting WAD
    contains both the DLC asset blocks and the bootstrap block.
    """
    print("Xbox 360 DLC → PC Patch WAD Porter (unified)")
    print("=" * 60)

    # Parse BE FFCS
    version, rows = parse_be_ffcs(doh)
    print(f"  FFCS version: {version}, chunks: {len(rows)}")

    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    aset_row = next((r for r in rows if r.tag == "ASET"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    data_row = next((r for r in rows if r.tag == "DATA"), None)

    if not all([indx_row, aset_row, pths_row, data_row]):
        print("ERROR: Missing required FFCS chunks", file=sys.stderr)
        return 1

    num_blocks = indx_row.meta
    print(f"  INDX: {num_blocks} blocks")
    print(f"  ASET: {aset_row.meta} entries")

    # Parse metadata
    indx_entries = parse_be_indx(doh, indx_row.offset, num_blocks)
    aset_entries = parse_be_aset(doh, aset_row.offset, aset_row.meta)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta)

    print(f"  PTHS: {len(path_strings)} paths")
    if verbose:
        for i, p in enumerate(path_strings[:10]):
            print(f"    [{i}] {p}")
        if len(path_strings) > 10:
            print(f"    ... ({len(path_strings) - 10} more)")

    # Build ASET lookup: block_index → list of entries
    # Xbox ASET block indices may start from a base offset
    aset_block_indices = set()
    for ae in aset_entries:
        aset_block_indices.add(ae.block_index)
    if aset_block_indices:
        aset_base_idx = min(aset_block_indices)
    else:
        aset_base_idx = 0

    aset_by_block: dict[int, list[dict]] = {}
    for ae in aset_entries:
        local_idx = ae.block_index - aset_base_idx
        entry_dict = {
            "asset_hash": ae.asset_hash,
            "u32_1": ae.u1,
            "u32_2": ae.u2,
            "u32_3": ae.u3,
        }
        aset_by_block.setdefault(local_idx, []).append(entry_dict)

    # Determine block range
    end_block = min(num_blocks, start_block + (max_blocks or num_blocks))
    blocks_to_process = range(start_block, end_block)
    print(f"\n  Processing blocks {start_block}..{end_block - 1} "
          f"({len(blocks_to_process)} blocks)")

    # Convert each block
    converted: list[PatchBlock] = []
    skipped = 0
    total_swap_stats: dict = {"tags_seen": {}}

    for blk_idx in blocks_to_process:
        indx = indx_entries[blk_idx]
        path = path_strings[blk_idx] if blk_idx < len(path_strings) else f"block_{blk_idx:05d}"
        block_offset = indx.file_offset
        block_size = indx.page_count * PAGE_SIZE

        if block_offset + 4 > len(doh):
            print(f"  [{blk_idx}] SKIP: offset 0x{block_offset:X} beyond DOH")
            skipped += 1
            continue

        magic = doh[block_offset:block_offset + 4]
        is_raw_xfcu = False

        if magic == b"segs":
            if verbose:
                print(f"  [{blk_idx}] {path}")
                print(f"         offset=0x{block_offset:X}, pages={indx.page_count}")
            try:
                decompressed = decompress_be_sges(doh, block_offset, block_size)
            except Exception as e:
                print(f"  [{blk_idx}] SKIP: decompress failed: {e}")
                skipped += 1
                continue
        else:
            # Check for raw (uncompressed) XFCU block — no segs wrapper.
            # The block starts with a BE u32 record count; after the header
            # table the first container should be XFCU (BE bytes b"XFCU").
            rec_count_be = struct.unpack_from(">I", doh, block_offset)[0]
            header_end = block_offset + 4 + rec_count_be * 16
            first_container_tag = doh[header_end:header_end + 4] if header_end + 4 <= len(doh) else b""
            if rec_count_be > 0 and rec_count_be < 5000 and first_container_tag == b"XFCU":
                is_raw_xfcu = True
                if verbose:
                    print(f"  [{blk_idx}] {path} (RAW XFCU, no segs wrapper)")
                    print(f"         offset=0x{block_offset:X}, pages={indx.page_count}, "
                          f"records={rec_count_be}")
                decompressed = doh[block_offset:block_offset + block_size]
                # Trim trailing zero padding to actual content
                actual_end = block_size
                while actual_end > 4 and decompressed[actual_end - 1] == 0:
                    actual_end -= 1
                actual_end = (actual_end + 3) & ~3  # align to 4
                decompressed = decompressed[:actual_end]
            else:
                print(f"  [{blk_idx}] SKIP: no segs magic at 0x{block_offset:X} "
                      f"(got {magic!r}, rec_count={rec_count_be}, "
                      f"first_tag={first_container_tag!r})")
                skipped += 1
                continue

        if verbose:
            label = "raw_xfcu" if is_raw_xfcu else "decompressed"
            print(f"         {label}={len(decompressed):,} bytes")

        # Dump raw if requested
        if dump_dir:
            dump_dir.mkdir(parents=True, exist_ok=True)
            (dump_dir / f"block_{blk_idx:04d}_be.bin").write_bytes(decompressed)

        # Byte-swap BE → LE
        swapped, stats = byteswap_ucfx_block(decompressed)

        if dump_dir:
            (dump_dir / f"block_{blk_idx:04d}_le.bin").write_bytes(swapped)

        for tag, cnt in stats.get("tags_seen", {}).items():
            total_swap_stats["tags_seen"][tag] = (
                total_swap_stats["tags_seen"].get(tag, 0) + cnt)

        # Recompress as PC sges
        pc_sges = compress_sges(swapped, segment_size=65536, level=6, major=4)

        if verbose:
            ratio = len(pc_sges) / len(swapped) * 100
            print(f"         compressed={len(pc_sges):,} bytes ({ratio:.1f}%)")

        # Build PatchBlock
        block_asets = aset_by_block.get(blk_idx, [])
        converted.append(PatchBlock(
            compressed_data=pc_sges,
            path_string=path,
            aset_entries=block_asets,
            packed_field=indx.packed_field,
            flags=indx.flags,
        ))

    print(f"\n  Converted: {len(converted)}, Skipped: {skipped}")
    if total_swap_stats["tags_seen"]:
        print("  Chunk tags swapped:")
        for tag, cnt in sorted(total_swap_stats["tags_seen"].items(), key=lambda x: -x[1]):
            print(f"    {tag}: {cnt}")

    if not converted:
        print("ERROR: No blocks converted", file=sys.stderr)
        return 1

    # ── DLC Bootstrap Injection ──────────────────────────────────────
    # When --source-wad is provided, extract the scripts_vz block from the
    # retail WAD, inject the dlc01 master script, modify the vz master
    # script to chain-load it, and include the modified block in the WAD.
    if source_wad and not no_bootstrap:
        print("\n" + "─" * 60)
        print("DLC Bootstrap Injection (integrated)")
        print("─" * 60)

        bootstrap_block = _build_bootstrap_block(
            source_wad,
            dlc_contracts=dlc_contracts or DLC_CONTRACT_NAMES,
            verbose=verbose,
        )
        if bootstrap_block is None:
            print("ERROR: Bootstrap injection failed", file=sys.stderr)
            return 1
        converted.append(bootstrap_block)
        print(f"\n  Added scripts_vz bootstrap block "
              f"({len(bootstrap_block.compressed_data):,} bytes compressed)")
    elif source_wad is None and not no_bootstrap:
        print("\n  NOTE: --source-wad not provided; skipping DLC bootstrap injection.")
        print("        Run with --source-wad path/to/vz.wad for a complete patch WAD.")

    # Build or merge patch WAD
    if merge_into and merge_into.is_file():
        print(f"\n  Merging into existing: {merge_into}")
        patch_wad = merge_patch_wads(merge_into, converted)
    else:
        patch_wad = build_patch_wad_multi(blocks=converted)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(patch_wad)
    print(f"\n  Output: {output_path} ({len(patch_wad):,} bytes / "
          f"{len(patch_wad) / 1024 / 1024:.1f} MB)")

    total_blocks = len(converted)
    dlc_blocks = total_blocks - (1 if source_wad and not no_bootstrap else 0)
    print(f"\n  Contents:")
    print(f"    - {dlc_blocks} DLC asset blocks (Xbox 360 → PC)")
    if source_wad and not no_bootstrap:
        print(f"    - 1 modified scripts_vz block (DLC bootstrap)")

    print("\n  Remaining gaps (render correctness):")
    print("    - STRM vertex data (mixed f16/f32/u8 — needs per-format swapping)")
    print("    - BODY texture data (possible Xbox 360 tile swizzle)")
    print("    - Havok binary data (class-aware field swapping)")
    print("    - Lua bytecode (endianness flag + opcode/constant swapping)")
    print("    - COMP/CHDR placement data (42-byte records)")

    return 0


def _build_bootstrap_block(
    source_wad: Path,
    *,
    dlc_contracts: list[str],
    verbose: bool = False,
) -> PatchBlock | None:
    """Extract scripts_vz from vz.wad, inject DLC bootstrap, return as PatchBlock.

    Returns None on failure.
    """
    repo_root = Path(__file__).resolve().parent.parent
    luac = repo_root / "lua-backup-dont-delete" / "src" / "luac"
    if not luac.is_file():
        luac_alt = repo_root / "lua-5.1.5" / "src" / "luac"
        if luac_alt.is_file():
            luac = luac_alt
        else:
            print(f"  ERROR: Lua compiler not found.", file=sys.stderr)
            print(f"    Checked: {luac}", file=sys.stderr)
            print(f"    Checked: {luac_alt}", file=sys.stderr)
            print(f"    Build with: cd lua-backup-dont-delete && make macosx",
                  file=sys.stderr)
            return None

    print(f"  Lua compiler: {luac}")

    # Step 1: Compile the DLC master script (dlc01)
    print("\n  [bootstrap 1/5] Compiling DLC master script (dlc01)...")
    import_lines = "\n".join(f'    import("{c}")' for c in dlc_contracts)
    dlc01_source = f'''\
function ScriptInit()
{import_lines}
end
'''
    try:
        dlc01_bytecode = compile_lua_source(dlc01_source, luac)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return None

    # Step 2: Compile the vz wrapper
    print("  [bootstrap 2/5] Compiling vz DLC import wrapper...")
    try:
        vz_import_bytecode = compile_lua_source(VZ_DLC_WRAPPER_SOURCE, luac)
    except (FileNotFoundError, RuntimeError) as e:
        print(f"  ERROR: {e}", file=sys.stderr)
        return None

    # Step 3: Extract block 1257 (scripts_vz) from the retail WAD
    print("  [bootstrap 3/5] Extracting scripts_vz block from retail WAD...")
    try:
        meta = extract_block_metadata(source_wad, 1257)
    except Exception as e:
        print(f"  ERROR extracting block 1257: {e}", file=sys.stderr)
        return None

    print(f"    PTHS: {meta['pths_string']}")
    print(f"    ASET entries: {meta['aset_entry_count']}")
    print(f"    Compressed size: {meta['block_compressed_size']:,} bytes")

    compressed_data = meta["compressed_block_data"]
    decompressed = decompress_sges_block(compressed_data, 0, len(compressed_data))
    print(f"    Decompressed: {len(decompressed):,} bytes")

    entries = parse_block_entries(decompressed)
    print(f"    UCFX entries: {len(entries)}")

    # Verify vz master script exists
    vz_found = any(get_script_name(decompressed, e) == "vz" for e in entries)
    if not vz_found:
        print("  ERROR: 'vz' master script not found in block 1257", file=sys.stderr)
        return None

    # Step 4: Modify the block
    print("  [bootstrap 4/5] Injecting DLC bootstrap into scripts_vz block...")

    dlc01_asset_hash = pandemic_hash_m2("dlc01")
    if verbose:
        print(f"    dlc01 asset hash: 0x{dlc01_asset_hash:08X}")

    dlc01_ucfx = _build_ucfx_script_chunk(
        "dlc01", dlc01_bytecode, dlc01_asset_hash,
    )

    # Add dlc01 entry to block
    modified = _add_ucfx_entry_to_block(
        decompressed, dlc01_ucfx, dlc01_asset_hash,
    )

    # Replace vz bytecode with the import("dlc01") wrapper
    modified = apply_bytecode_replacement_to_block(modified, "vz", vz_import_bytecode)

    # Apply existing mods (oilcon001 string swaps + demo timer disable)
    modified = apply_string_mod_to_block(modified)

    new_entries = parse_block_entries(modified)
    print(f"    Block entries: {len(entries)} → {len(new_entries)}")
    print(f"    Modified size: {len(modified):,} bytes "
          f"(delta {len(modified) - len(decompressed):+,})")

    # Step 5: Recompress
    print("  [bootstrap 5/5] Recompressing scripts_vz block...")
    new_sges = compress_sges(modified, segment_size=65536, level=6, major=4)
    ratio = len(new_sges) / len(modified) * 100
    print(f"    Compressed: {len(new_sges):,} bytes ({ratio:.1f}%)")

    # Verify roundtrip
    verify = decompress_sges_block(new_sges, 0, len(new_sges))
    if verify != modified:
        print("  ERROR: Roundtrip verification failed!", file=sys.stderr)
        return None
    if verbose:
        print("    Roundtrip verification OK")

    # Build PatchBlock with updated ASET
    aset_entries = list(meta["aset_entries"])
    aset_entries.append({
        "asset_hash": dlc01_asset_hash,
        "u32_1": 0xFFFFFFFF,
        "u32_2": 0,
        "u32_3": 0,
    })

    return PatchBlock(
        compressed_data=new_sges,
        path_string=meta["pths_string"],
        aset_entries=aset_entries,
        packed_field=meta["indx_entry"].get("packed_field", 1),
        flags=meta["indx_entry"].get("flags", 0x8000),
    )


def cmd_list_blocks(doh: bytes) -> int:
    """Print block inventory and exit."""
    _, rows = parse_be_ffcs(doh)
    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)

    if not indx_row or not pths_row:
        print("ERROR: Missing INDX/PTHS", file=sys.stderr)
        return 1

    num_blocks = indx_row.meta
    indx_entries = parse_be_indx(doh, indx_row.offset, num_blocks)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta)

    print(f"DLC blocks: {num_blocks}")
    print(f"{'#':>4}  {'Pages':>5}  {'Offset':>10}  Path")
    print("-" * 70)
    for i, indx in enumerate(indx_entries):
        path = path_strings[i] if i < len(path_strings) else "???"
        print(f"{i:4d}  {indx.page_count:5d}  0x{indx.file_offset:08X}  {path}")

    return 0


# ── Audio extraction ──────────────────────────────────────────────────

def extract_dlc_audio(stfs_data: bytes, audio_dir: Path) -> int:
    """Extract .pws audio files from the STFS container to audio_dir.

    Audio files live alongside DLC01.doh in the STFS file table as
    entries whose block chains are walked via hash table pointers.
    They are byte-for-byte identical on PC and Xbox (no endian issues
    with .pws streams).
    """
    reader = StfsReader(stfs_data)
    pws_entries = [e for e in reader.file_table if e["name"].endswith(".pws")]

    if not pws_entries:
        print("  No .pws audio files found in STFS")
        return 0

    audio_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n  Extracting {len(pws_entries)} audio files to {audio_dir}/")

    for entry in pws_entries:
        data = reader.read_file(entry)
        out_path = audio_dir / entry["name"]
        out_path.write_bytes(data)
        print(f"    {entry['name']} ({entry['file_size']:,} bytes)")

    return 0


# ── CLI ───────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description="Port Xbox 360 DLC to PC vz-patch.wad (unified tool)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    source = ap.add_mutually_exclusive_group(required=True)
    source.add_argument("--x360-rar", type=Path,
                        help="Xbox 360 DLC RAR file")
    source.add_argument("--x360-zip", type=Path,
                        help="Xbox 360 DLC ZIP file (bsdtar handles both)")
    source.add_argument("--x360-stfs", type=Path,
                        help="STFS LIVE container or raw DLC01.doh file")

    ap.add_argument("--output", "-o", type=Path,
                    help="Output vz-patch.wad path")
    ap.add_argument("--merge-into", type=Path,
                    help="Merge DLC blocks into an existing patch WAD")
    ap.add_argument("--source-wad", type=Path, default=None,
                    help="Path to retail vz.wad. When provided, the DLC "
                         "bootstrap (dlc01 master script + modified vz script) "
                         "is injected automatically into the output WAD.")
    ap.add_argument("--no-bootstrap", action="store_true",
                    help="Skip DLC bootstrap injection even when --source-wad "
                         "is provided (produce DLC blocks only)")
    ap.add_argument("--dlc-contracts", type=str, default=None,
                    help="Comma-separated DLC contract names to import "
                         "(default: dlccon001,dlccon002,dlccon003,dlccon004)")
    ap.add_argument("--max-blocks", type=int, default=None,
                    help="Limit to first N blocks (for testing)")
    ap.add_argument("--start-block", type=int, default=0,
                    help="Start at block N (default 0)")
    ap.add_argument("--verbose", "-v", action="store_true")
    ap.add_argument("--dump-dir", type=Path, default=None,
                    help="Dump intermediate block files to directory")
    ap.add_argument("--list-blocks", action="store_true",
                    help="List all DLC blocks and exit")
    ap.add_argument("--extract-audio", type=Path, default=None,
                    help="Extract .pws audio files to this directory")
    ap.add_argument("--work-dir", type=Path, default=None,
                    help="Working directory for temp files")

    args = ap.parse_args()

    # Load DOH bytes from source
    archive_path = args.x360_rar or args.x360_zip
    if archive_path:
        work = args.work_dir or Path(tempfile.mkdtemp(prefix="dlc_port_"))
        ext = archive_path.suffix.lower()
        print(f"Step 1: Extracting STFS from {ext.lstrip('.')} archive...")
        reader = extract_stfs_from_rar(archive_path, work)
        doh_entry = next(
            (e for e in reader.file_table if "doh" in e["name"].lower()), None)
        if doh_entry is None:
            print("  ERROR: No DOH file found in STFS file table")
            return 1
        doh_size = doh_entry["file_size"]
        print(f"  Reading DOH ({doh_size:,} bytes)...")
        doh = reader.read(0, doh_size)
    else:
        print(f"Step 1: Loading {args.x360_stfs}...")
        doh, src_type = load_stfs_or_doh(args.x360_stfs)
        print(f"  Source: {src_type}, size: {len(doh):,} bytes")

    if args.list_blocks:
        return cmd_list_blocks(doh)

    # Extract audio if requested (only works with archive or STFS source)
    if args.extract_audio:
        if archive_path:
            extract_dlc_audio(reader.stfs_data, args.extract_audio)
        elif args.x360_stfs:
            header = args.x360_stfs.read_bytes()[:4]
            if header in (b"CON ", b"LIVE", b"PIRS"):
                extract_dlc_audio(args.x360_stfs.read_bytes(), args.extract_audio)
            else:
                print("  NOTE: --extract-audio requires STFS source (not raw DOH)")

    if args.output is None:
        if args.extract_audio and not args.list_blocks:
            return 0
        ap.error("--output is required (unless using --list-blocks or --extract-audio only)")

    dlc_contracts = None
    if args.dlc_contracts:
        dlc_contracts = [c.strip() for c in args.dlc_contracts.split(",")]

    return port_x360_dlc(
        doh,
        output_path=args.output,
        merge_into=args.merge_into,
        source_wad=args.source_wad,
        max_blocks=args.max_blocks,
        start_block=args.start_block,
        verbose=args.verbose,
        dump_dir=args.dump_dir,
        dlc_contracts=dlc_contracts,
        no_bootstrap=args.no_bootstrap,
    )


if __name__ == "__main__":
    sys.exit(main())
