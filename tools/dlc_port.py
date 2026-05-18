#!/usr/bin/env python3
"""Unified DLC porter — Xbox 360 DLC to PC ``vz-patch.wad``.

Replaces both ``port_xbox_dlc.py`` and ``dlc_port_x360_to_pc.py`` with a
single CLI that uses shared modules:
  - x360_dlc_io: STFS I/O, BE sges decompression, FFCS parsing
  - ucfx_be_to_le: UCFX byte-swap (BE → LE)
  - ffcs_patch_wad: patch WAD assembly + merge

Usage:
  # From Xbox 360 DLC RAR:
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
    parse_stfs_file_table,
)


# ── Pipeline ──────────────────────────────────────────────────────────

def port_x360_dlc(
    doh: bytes,
    *,
    output_path: Path,
    merge_into: Path | None = None,
    max_blocks: int | None = None,
    start_block: int = 0,
    verbose: bool = False,
    dump_dir: Path | None = None,
) -> int:
    """Convert a big-endian DOH (DLC01.doh content) into a PC vz-patch.wad."""
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

    print("\n  Remaining gaps (render correctness):")
    print("    - STRM vertex data (mixed f16/f32/u8 — needs per-format swapping)")
    print("    - BODY texture data (possible Xbox 360 tile swizzle)")
    print("    - Havok binary data (class-aware field swapping)")
    print("    - Lua bytecode (endianness flag + opcode/constant swapping)")
    print("    - COMP/CHDR placement data (42-byte records)")

    return 0


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
    consecutive-block entries. They are byte-for-byte identical on
    PC and Xbox (no endian issues with .pws streams).
    """
    from x360_dlc_io import STFS_BLOCK_SIZE, STFS_DATA_OFFSET

    file_table = parse_stfs_file_table(stfs_data)
    pws_entries = [e for e in file_table if e["name"].endswith(".pws")]

    if not pws_entries:
        print("  No .pws audio files found in STFS")
        return 0

    audio_dir.mkdir(parents=True, exist_ok=True)
    print(f"\n  Extracting {len(pws_entries)} audio files to {audio_dir}/")

    for entry in pws_entries:
        name = entry["name"]
        first_block = entry["first_block"]
        file_size = entry["file_size"]

        # STFS consecutive-block files: data blocks start at first_block
        # We skip hash blocks using the standard 170-block formula
        out = bytearray()
        remaining = file_size
        block_idx = first_block
        while remaining > 0:
            # Simple consecutive read — skip hash blocks every 170 data blocks
            phys_block = block_idx + (block_idx // 170)
            abs_offset = STFS_DATA_OFFSET + phys_block * STFS_BLOCK_SIZE
            chunk = min(STFS_BLOCK_SIZE, remaining)
            if abs_offset + chunk > len(stfs_data):
                print(f"    WARNING: {name} — read past EOF at block {block_idx}")
                break
            out.extend(stfs_data[abs_offset:abs_offset + chunk])
            remaining -= chunk
            block_idx += 1

        out_path = audio_dir / name
        out_path.write_bytes(bytes(out[:file_size]))
        print(f"    {name} ({file_size:,} bytes)")

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
        # Read full DOH via reader
        ffcs_header = reader.read(0, 0x100)
        chunk_count = struct.unpack_from(">I", ffcs_header, 8)[0]
        data_off = 0
        for i in range(min(chunk_count, 5)):
            off = 0x0C + i * 12
            tag = ffcs_header[off:off + 4][::-1].decode("ascii", errors="replace")
            val = struct.unpack_from(">I", ffcs_header, off + 4)[0]
            if tag == "DATA":
                data_off = val
                break
        file_table = parse_stfs_file_table(reader.stfs_data)
        doh_entry = next((e for e in file_table if "doh" in e["name"].lower()), None)
        doh_size = doh_entry["file_size"] if doh_entry else data_off + 0x10000000
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

    return port_x360_dlc(
        doh,
        output_path=args.output,
        merge_into=args.merge_into,
        max_blocks=args.max_blocks,
        start_block=args.start_block,
        verbose=args.verbose,
        dump_dir=args.dump_dir,
    )


if __name__ == "__main__":
    sys.exit(main())
