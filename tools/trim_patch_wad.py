#!/usr/bin/env python3
"""Trim a patch WAD by removing blocks to reduce descriptor count.

Reads the existing vz-patch.wad, removes blocks based on either:
  - An exclusion JSON file (from plan_patch_wad_trim.py)
  - Automatic redundancy detection (--auto mode)
  - Explicit block indices (--exclude-indices)

Rebuilds a new patch WAD with fewer blocks/descriptors.

Usage:
  # Auto-trim: remove redundant blocks until target met
  python tools/trim_patch_wad.py --auto --target-descriptors 15450 \\
      --base-wad game-files/pc-game-vz.wad \\
      --input output/data/vz-patch.wad \\
      --output output/data/vz-patch-trimmed.wad

  # From exclusion list:
  python tools/trim_patch_wad.py --exclusions output/data/patch_wad_exclusions.json \\
      --input output/data/vz-patch.wad \\
      --output output/data/vz-patch-trimmed.wad

  # Explicit indices:
  python tools/trim_patch_wad.py --exclude-indices 748,404 \\
      --input output/data/vz-patch.wad \\
      --output output/data/vz-patch-trimmed.wad

  # List all block indices/paths (bisect planning):
  python tools/trim_patch_wad.py -i output/data/vz-patch.wad -o NUL --list

  # Exclude by path substring (comma-separated, case-insensitive):
  python tools/trim_patch_wad.py --exclude-path-substr c30061,dlc01_base \\
      -i output/data/vz-patch.wad -o output/data/vz-patch-trim.wad

  # Half-WAD bisect: keep only indices 1–1099 (original numbering):
  python tools/trim_patch_wad.py --keep-only-indices 1-1099 \\
      -i output/data/vz-patch.wad -o output/data/vz-patch-lo.wad
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_patch_wad import (  # noqa: E402
    PatchBlock,
    build_patch_wad_multi,
    read_patch_wad,
)
from sges_decompress import decompress_sges_block  # noqa: E402


def get_block_entry_count(blk: PatchBlock) -> int:
    """Decompress a block and return its entry table count."""
    compressed = blk.compressed_data
    try:
        if compressed[:4] == b"sges":
            decompressed = decompress_sges_block(compressed, 0, len(compressed))
        else:
            decompressed = compressed
        if len(decompressed) >= 4:
            count = struct.unpack_from("<I", decompressed, 0)[0]
            return count if count < 50000 else 0
    except Exception:
        pass
    return 0


def get_block_entry_hashes(blk: PatchBlock) -> list[int]:
    """Get name_hashes from a block's entry table."""
    compressed = blk.compressed_data
    try:
        if compressed[:4] == b"sges":
            decompressed = decompress_sges_block(compressed, 0, len(compressed))
        else:
            decompressed = compressed
        if len(decompressed) < 4:
            return []
        count = struct.unpack_from("<I", decompressed, 0)[0]
        if count > 50000:
            return []
        hashes = []
        for i in range(count):
            off = 4 + i * 16
            if off + 16 > len(decompressed):
                break
            h = struct.unpack_from("<I", decompressed, off)[0]
            hashes.append(h)
        return hashes
    except Exception:
        return []


def parse_index_spec(spec: str) -> set[int]:
    """Parse comma-separated indices and inclusive ranges (e.g. ``1-1099,2196``)."""
    out: set[int] = set()
    for part in spec.split(","):
        part = part.strip()
        if not part:
            continue
        if "-" in part:
            a, b = part.split("-", 1)
            lo, hi = int(a.strip()), int(b.strip())
            if lo > hi:
                lo, hi = hi, lo
            out.update(range(lo, hi + 1))
        else:
            out.add(int(part))
    return out


def path_matches_substr(path: str, substrings: list[str]) -> bool:
    p = path.replace("\\", "/").lower()
    return any(s.lower() in p for s in substrings)


def list_blocks(blocks: list[PatchBlock], *, prefix: str | None = None) -> None:
    """Print ``[index] entries  path`` for every block."""
    for i, blk in enumerate(blocks):
        if prefix and not path_matches_substr(blk.path_string, [prefix]):
            continue
        ec = get_block_entry_count(blk)
        print(f"  [{i:4d}] {ec:3d} entries  {blk.path_string}")


def build_base_aset_set(base_wad_path: Path) -> set[int]:
    """Get set of all asset hashes in base game ASET table."""
    raw = base_wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        raise ValueError("Not an FFCS file")
    _ver, num_chunks = struct.unpack_from("<II", raw, 4)
    chunks = {}
    for i in range(num_chunks):
        off = 0x0C + i * 12
        tag_bytes = raw[off:off + 4]
        if not all(32 <= b < 127 for b in tag_bytes):
            break
        tag = tag_bytes.decode("ascii")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (offset, meta)

    aset_off, aset_count = chunks.get("ASET", (0, 0))
    hashes = set()
    for i in range(aset_count):
        off = aset_off + i * 16
        asset_hash = struct.unpack_from("<I", raw, off)[0]
        if asset_hash != 0:
            hashes.add(asset_hash)
    return hashes


def auto_select_exclusions(
    blocks: list[PatchBlock],
    base_hashes: set[int],
    target_reduction: int,
) -> list[int]:
    """Automatically select block indices to remove.

    Strategy: remove fully-redundant blocks (all entries exist in base game)
    starting from the largest (fewest blocks removed = least disruption).
    """
    redundant: list[tuple[int, int]] = []  # (entry_count, block_index)
    for i, blk in enumerate(blocks):
        entry_hashes = get_block_entry_hashes(blk)
        if not entry_hashes:
            continue
        if all(h in base_hashes for h in entry_hashes):
            redundant.append((len(entry_hashes), i))

    # Sort by entry count descending (remove biggest first = fewer removals)
    redundant.sort(reverse=True)

    excluded = []
    removed_descriptors = 0
    for entry_count, idx in redundant:
        if removed_descriptors >= target_reduction:
            break
        excluded.append(idx)
        removed_descriptors += entry_count

    return excluded


def main():
    parser = argparse.ArgumentParser(description="Trim patch WAD by removing blocks")
    parser.add_argument("--input", "-i", required=True, help="Input vz-patch.wad")
    parser.add_argument("--output", "-o", required=True, help="Output trimmed WAD")
    parser.add_argument("--exclusions", help="JSON file with excluded_block_indices list")
    parser.add_argument("--exclude-indices", help="Comma-separated block indices to exclude")
    parser.add_argument("--auto", action="store_true",
                       help="Auto-detect redundant blocks to remove")
    parser.add_argument("--base-wad", help="Base game vz.wad (needed for --auto)")
    parser.add_argument("--target-reduction", type=int, default=157,
                       help="Target descriptor reduction for --auto mode (default: 157)")
    parser.add_argument("--verbose", "-v", action="store_true")
    parser.add_argument(
        "--list",
        action="store_true",
        help="Print all block indices/paths (optional --list-prefix filter) and exit",
    )
    parser.add_argument(
        "--list-prefix",
        help="With --list: only paths containing this substring",
    )
    parser.add_argument(
        "--list-state-blocks",
        action="store_true",
        help="Print indices/paths for dlc01_state* blocks and exit",
    )
    parser.add_argument(
        "--exclude-path-substr",
        help="Comma-separated path substrings; matching blocks are removed",
    )
    parser.add_argument(
        "--keep-only-indices",
        help="Keep only these indices/ranges (original numbering); comma or 1-1099",
    )
    args = parser.parse_args()

    input_path = Path(args.input)

    if args.list or args.list_state_blocks:
        contents = read_patch_wad(input_path)
        if args.list_state_blocks:
            print(f"dlc01_state* blocks in {input_path} ({len(contents.blocks)} total):\n")
            list_blocks(contents.blocks, prefix="dlc01_state")
        else:
            label = f"blocks in {input_path}"
            if args.list_prefix:
                label += f" (prefix filter: {args.list_prefix!r})"
            print(f"{len(contents.blocks)} {label}:\n")
            list_blocks(contents.blocks, prefix=args.list_prefix)
        return

    output_path = Path(args.output)

    # Determine exclusion set
    exclude_indices: set[int] = set()
    keep_only: set[int] | None = None
    trim_mode = False

    if args.exclusions:
        data = json.loads(Path(args.exclusions).read_text())
        exclude_indices = set(data["excluded_block_indices"])
        print(f"Loaded {len(exclude_indices)} exclusions from {args.exclusions}")
        trim_mode = True
    if args.exclude_indices:
        exclude_indices |= parse_index_spec(args.exclude_indices)
        print(f"Excluding {len(exclude_indices)} blocks by index (cumulative)")
        trim_mode = True
    if args.exclude_path_substr:
        substrs = [s.strip() for s in args.exclude_path_substr.split(",") if s.strip()]
        contents = read_patch_wad(input_path)
        path_excluded = {
            i
            for i, blk in enumerate(contents.blocks)
            if path_matches_substr(blk.path_string, substrs)
        }
        exclude_indices |= path_excluded
        print(
            f"Excluding {len(path_excluded)} blocks by path substring "
            f"({', '.join(substrs)!r})"
        )
        trim_mode = True
    if args.keep_only_indices:
        keep_only = parse_index_spec(args.keep_only_indices)
        print(f"Keep-only filter: {len(keep_only)} indices")
        trim_mode = True
    if args.auto:
        if not args.base_wad:
            parser.error("--base-wad is required with --auto")
        print("Auto-detecting redundant blocks...")
        print(f"  Loading base game ASET from {args.base_wad}...")
        base_hashes = build_base_aset_set(Path(args.base_wad))
        print(f"  Base game has {len(base_hashes)} unique asset hashes")

        print(f"  Reading patch WAD...")
        contents = read_patch_wad(input_path)
        print(f"  Patch WAD has {len(contents.blocks)} blocks")

        auto_excluded = auto_select_exclusions(
            contents.blocks, base_hashes, args.target_reduction
        )
        exclude_indices |= set(auto_excluded)
        print(f"  Auto-selected {len(auto_excluded)} blocks to remove")
        trim_mode = True

    if not trim_mode:
        parser.error(
            "Must specify --exclusions, --exclude-indices, --exclude-path-substr, "
            "--keep-only-indices, or --auto"
        )

    # Read and rebuild
    print(f"\nReading {input_path}...")
    contents = read_patch_wad(input_path)
    original_blocks = contents.blocks

    # Count original descriptors
    original_descriptors = 0
    for blk in original_blocks:
        original_descriptors += get_block_entry_count(blk)

    # Filter blocks
    kept_blocks: list[PatchBlock] = []
    removed_descriptors = 0
    removed_paths: list[str] = []

    for i, blk in enumerate(original_blocks):
        if keep_only is not None and i not in keep_only:
            entry_count = get_block_entry_count(blk)
            removed_descriptors += entry_count
            removed_paths.append(blk.path_string)
            if args.verbose:
                print(f"  REMOVING [{i:4d}] {entry_count:3d} entries (keep-only): {blk.path_string}")
        elif i in exclude_indices:
            entry_count = get_block_entry_count(blk)
            removed_descriptors += entry_count
            removed_paths.append(blk.path_string)
            if args.verbose:
                print(f"  REMOVING [{i:4d}] {entry_count:3d} entries: {blk.path_string}")
        else:
            kept_blocks.append(blk)

    trimmed_descriptors = original_descriptors - removed_descriptors

    print(f"\nOriginal: {len(original_blocks)} blocks, {original_descriptors} descriptors")
    print(f"Removed:  {len(removed_paths)} blocks, {removed_descriptors} descriptors")
    print(f"Trimmed:  {len(kept_blocks)} blocks, {trimmed_descriptors} descriptors")
    print()

    # Rebuild WAD
    print("Rebuilding trimmed patch WAD...")
    wad_bytes = build_patch_wad_multi(
        blocks=kept_blocks,
        csum_value=contents.csum_value,
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_bytes(wad_bytes)
    print(f"Written: {output_path} ({len(wad_bytes):,} bytes)")
    print()

    # Verify
    print("Verifying trimmed WAD...")
    verify_contents = read_patch_wad(output_path)
    verify_descriptors = 0
    for blk in verify_contents.blocks:
        verify_descriptors += get_block_entry_count(blk)
    print(f"  Verified blocks: {len(verify_contents.blocks)}")
    print(f"  Verified descriptors: {verify_descriptors}")

    # Summary
    print()
    print("=" * 60)
    print("SUMMARY")
    print("=" * 60)
    print(f"  Original descriptors: {original_descriptors}")
    print(f"  Removed descriptors:  {removed_descriptors}")
    print(f"  Final descriptors:    {verify_descriptors}")
    print(f"  Blocks removed:       {len(removed_paths)}")
    print(f"  Output WAD:           {output_path}")

    if args.verbose and removed_paths:
        print()
        print("Removed block paths:")
        for p in sorted(removed_paths):
            print(f"  {p}")


if __name__ == "__main__":
    main()
