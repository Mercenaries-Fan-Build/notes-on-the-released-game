#!/usr/bin/env python3
"""Verify every ASET entry in a patch WAD resolves correctly against block content.

The Mercenaries 2 engine mounts vz-patch.wad AFTER vz.wad and searches ASET
in reverse order (last-opened-file wins).  This tool:

  1. Parses both WADs' FFCS headers (INDX, ASET, PTHS)
  2. For every patch ASET entry, classifies its ref type using the
     documented field layout (docs/aset_format.md)
  3. Decompresses each referenced block and parses its entry table
     using the documented block header format (docs/format_reference.md)
  4. Verifies:
     - block_index is within INDX range
     - For primary refs: asset_hash exists in block entry table
     - For sub-entry refs: sub-entry index < block entry count
     - type_id matches the block entry's type_hash (via aset_type_ids)
  5. Cross-references with base WAD to detect shadows and type mismatches

ASET row layout (docs/aset_format.md):
  +0  u32  asset_hash       FNV-1a hash of asset name
  +4  u32  secondary_ref    0xFFFFFFFF = single-block; else streaming dep hash
  +8  u32  packed_block_ref  high16 = block_index, low16 = 0xFFFF primary / else sub-entry
  +12 u32  type_id          maps to type_hash via aset_type_ids.py

Block entry table (docs/format_reference.md):
  count(u32) + count * (name_hash u32, type_hash u32, field_c u32, chunk_size u32)

Usage:
  python3 tools/verify_wad_overlay.py \\
      --base game-files/vz.wad \\
      --patch output/data/vz-patch.wad
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from aset_type_ids import TYPE_HASH_TO_TYPE_ID, type_id_for_type_hash  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import parse_block_entries  # noqa: E402

PAGE_SIZE = 0x8000

TYPE_ID_TO_NAME: dict[int, str] = {
    27: "texture", 28: "path", 16: "animation", 19: "model",
    12: "shader", 9: "layer", 35: "script", 30: "registry",
    32: "terrainmesh", 22: "lowresterrain", 29: "effect",
    6: "wavebank", 5: "unk_5", 13: "unk_13", 21: "soundbank",
    23: "unk_23", 34: "unk_34", 18: "unk_18", 11: "unk_11",
    3: "binary", 15: "font", 14: "unk_14", 7: "stringdb",
    20: "level", 0: "singleton", 33: "unk_33", 26: "unk_26",
    4: "unk_4", 31: "unk_31", 1: "unk_1", 8: "unk_8",
    10: "unk_10", 25: "unk_25",
}

TYPE_ID_TO_HASH: dict[int, int] = {}
for _th, _tid in TYPE_HASH_TO_TYPE_ID.items():
    if _tid not in TYPE_ID_TO_HASH:
        TYPE_ID_TO_HASH[_tid] = _th


# -- FFCS parsing (docs/format_reference.md) --

def parse_ffcs_chunks(raw: bytes) -> dict[str, tuple[int, int]]:
    """Parse FFCS header, return {tag: (offset, meta)} for the 5 chunk rows."""
    if raw[:4] != b"FFCS":
        raise ValueError(f"Bad FFCS magic: {raw[:4]!r}")
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (val, meta)
    return chunks


def parse_indx(raw: bytes, offset: int, count: int) -> list[tuple[int, int, int]]:
    """Return list of (page_index, packed_field, flags_and_pages)."""
    entries = []
    for i in range(count):
        off = offset + i * 12
        entries.append(struct.unpack_from("<III", raw, off))
    return entries


def parse_aset_rows(raw: bytes, offset: int, count: int) -> list[dict]:
    """Parse ASET rows using the documented 16-byte layout (docs/aset_format.md).

    Fields per row:
      asset_hash(u32), secondary_ref(u32), packed_block_ref(u32), type_id(u32)
    Derived:
      block_index = packed_block_ref >> 16
      sub_entry   = packed_block_ref & 0xFFFF
    """
    entries = []
    for i in range(count):
        off = offset + i * 16
        asset_hash, secondary_ref, packed_block_ref, type_id = struct.unpack_from(
            "<IIII", raw, off)
        entries.append({
            "row": i,
            "asset_hash": asset_hash,
            "secondary_ref": secondary_ref,
            "packed_block_ref": packed_block_ref,
            "block_index": (packed_block_ref >> 16) & 0xFFFF,
            "sub_entry": packed_block_ref & 0xFFFF,
            "type_id": type_id,
        })
    return entries


def classify_ref(entry: dict) -> str:
    """Classify ASET ref type per docs/aset_format.md.

    - primary:   secondary_ref == 0xFFFFFFFF AND sub_entry == 0xFFFF
    - streaming: secondary_ref != 0xFFFFFFFF
    - sub_entry: secondary_ref == 0xFFFFFFFF AND sub_entry != 0xFFFF
    """
    if entry["secondary_ref"] != 0xFFFFFFFF:
        return "streaming"
    if entry["sub_entry"] != 0xFFFF:
        return "sub_entry"
    return "primary"


def parse_pths(raw: bytes, offset: int, count: int) -> list[str]:
    """Parse null-terminated path strings from PTHS chunk."""
    paths: list[str] = []
    pos = offset
    end = len(raw)
    while len(paths) < count and pos < end:
        nul = raw.find(b"\x00", pos)
        if nul < 0:
            break
        s = raw[pos:nul].decode("utf-8", errors="replace")
        if "\\" in s or "/" in s:
            paths.append(s)
        pos = nul + 1
    return paths


def _path_label(paths: list[str], bi: int) -> str:
    if bi < len(paths):
        return paths[bi].rsplit("\\", 1)[-1].rsplit("/", 1)[-1]
    return f"block_{bi}"


# -- Block content helpers --

def get_block_data(
    wad_raw: bytes, indx: list[tuple[int, int, int]], block_index: int
) -> bytes | None:
    """Decompress a block from WAD given its INDX row. Returns None on failure."""
    if block_index >= len(indx):
        return None
    page_idx, _packed, flags_pages = indx[block_index]
    comp_pages = flags_pages & 0xFFFF
    block_off = page_idx * PAGE_SIZE
    block_sz = comp_pages * PAGE_SIZE
    if block_off + block_sz > len(wad_raw):
        return None
    try:
        return decompress_sges_block(wad_raw, block_off, block_off + block_sz)
    except Exception:
        return None


def safe_parse_block_entries(decomp: bytes) -> list[dict] | None:
    """Parse block entry table via wad_patcher.parse_block_entries."""
    try:
        return parse_block_entries(decomp)
    except Exception:
        return None


# -- Main verification --

def verify_patch_aset(
    *,
    base_raw: bytes,
    patch_raw: bytes,
    sample_limit: int = 0,
) -> int:
    """Run full ASET overlay verification. Returns 0 on pass, 1 on issues found."""

    # ================================================================
    # 1. Parse both WADs
    # ================================================================
    print("Loading base WAD...")
    base_chunks = parse_ffcs_chunks(base_raw)
    base_indx_off, base_indx_count = base_chunks["INDX"]
    base_aset_off, base_aset_count = base_chunks["ASET"]
    base_indx = parse_indx(base_raw, base_indx_off, base_indx_count)
    base_aset = parse_aset_rows(base_raw, base_aset_off, base_aset_count)
    print(f"  INDX: {base_indx_count} blocks")
    print(f"  ASET: {base_aset_count} entries")

    print("\nLoading patch WAD...")
    patch_chunks = parse_ffcs_chunks(patch_raw)
    patch_indx_off, patch_indx_count = patch_chunks["INDX"]
    patch_aset_off, patch_aset_count = patch_chunks["ASET"]
    patch_pths_off, patch_pths_count = patch_chunks["PTHS"]
    patch_indx = parse_indx(patch_raw, patch_indx_off, patch_indx_count)
    patch_aset = parse_aset_rows(patch_raw, patch_aset_off, patch_aset_count)
    patch_paths = parse_pths(patch_raw, patch_pths_off, patch_pths_count)
    print(f"  INDX: {patch_indx_count} blocks")
    print(f"  ASET: {patch_aset_count} entries")
    print(f"  PTHS: {len(patch_paths)} paths")

    # Base ASET lookup: asset_hash -> list of entries
    base_by_hash: dict[int, list[dict]] = {}
    for e in base_aset:
        base_by_hash.setdefault(e["asset_hash"], []).append(e)

    # ================================================================
    # 2. Classify all patch ASET entries
    # ================================================================
    primary_entries: list[dict] = []
    streaming_entries: list[dict] = []
    sub_entry_entries: list[dict] = []
    oob_entries: list[dict] = []
    shadows = 0

    for entry in patch_aset:
        ref_type = classify_ref(entry)
        entry["ref_type"] = ref_type

        if entry["block_index"] >= patch_indx_count:
            oob_entries.append(entry)
            continue

        if entry["asset_hash"] in base_by_hash:
            shadows += 1

        if ref_type == "primary":
            primary_entries.append(entry)
        elif ref_type == "streaming":
            streaming_entries.append(entry)
        else:
            sub_entry_entries.append(entry)

    unique = patch_aset_count - shadows

    print(f"\n{'=' * 60}")
    print("ASET Entry Classification (docs/aset_format.md)")
    print(f"{'=' * 60}")
    print(f"  Total entries:          {patch_aset_count}")
    print(f"  Primary (single-block): {len(primary_entries)}"
          f"   [secondary=0xFFFFFFFF, low16=0xFFFF]")
    print(f"  Streaming refs:         {len(streaming_entries)}"
          f"   [secondary != 0xFFFFFFFF]")
    print(f"  Sub-entry refs:         {len(sub_entry_entries)}"
          f"   [secondary=0xFFFFFFFF, low16 != 0xFFFF]")
    print(f"  Out-of-range block:     {len(oob_entries)}")
    print(f"  Shadow base game:       {shadows}")
    print(f"  New (DLC-only):         {unique}")

    if oob_entries:
        print(f"\n  ERROR: {len(oob_entries)} entries have block_index >= "
              f"INDX count ({patch_indx_count}):")
        for e in oob_entries[:20]:
            tn = TYPE_ID_TO_NAME.get(e["type_id"], f"type_{e['type_id']}")
            print(f"    row {e['row']:5d}: asset=0x{e['asset_hash']:08X} "
                  f"block={e['block_index']} type={tn}")

    # Type distribution
    type_counts: dict[int, int] = {}
    for e in patch_aset:
        type_counts[e["type_id"]] = type_counts.get(e["type_id"], 0) + 1
    print(f"\n  Type distribution:")
    for tid in sorted(type_counts, key=lambda t: -type_counts[t]):
        name = TYPE_ID_TO_NAME.get(tid, "???")
        print(f"    type_id={tid:2d} ({name:15s}): {type_counts[tid]:5d}")

    # ================================================================
    # 3. Diagnostic: sub_entry value distribution
    # ================================================================
    if sub_entry_entries:
        sub_vals = [e["sub_entry"] for e in sub_entry_entries]
        sub_eq_block = sum(
            1 for e in sub_entry_entries if e["sub_entry"] == e["block_index"]
        )
        print(f"\n  Sub-entry diagnostic:")
        print(f"    Range: {min(sub_vals)} .. {max(sub_vals)}")
        print(f"    sub_entry == block_index: {sub_eq_block} / {len(sub_entry_entries)}")
        if sub_eq_block > len(sub_entry_entries) * 0.8:
            print(f"    WARNING: sub_entry values mirror block_index in "
                  f"{sub_eq_block}/{len(sub_entry_entries)} entries.")
            print(f"    This suggests the original Xbox block index leaked into "
                  f"the low16 bits of packed_block_ref during DLC porting.")
            print(f"    Expected: 0xFFFF for primary refs (per docs/aset_format.md)")

    # ================================================================
    # 4. Decompress all referenced blocks
    # ================================================================
    print(f"\n{'=' * 60}")
    print("Block Content Verification")
    print(f"{'=' * 60}")

    blocks_needed: dict[int, list[dict]] = {}
    for entry in patch_aset:
        bi = entry["block_index"]
        if bi < patch_indx_count:
            blocks_needed.setdefault(bi, []).append(entry)

    blocks_to_check = sorted(blocks_needed.keys())
    if sample_limit and sample_limit < len(blocks_to_check):
        blocks_to_check = blocks_to_check[:sample_limit]

    decomp_ok = 0
    decomp_fail: list[tuple[int, str]] = []
    # block_index -> (decompressed_bytes, parsed_entry_table)
    block_cache: dict[int, tuple[bytes, list[dict]]] = {}

    print(f"  Decompressing {len(blocks_to_check)} blocks...")

    for bi in blocks_to_check:
        decomp = get_block_data(patch_raw, patch_indx, bi)
        if decomp is None:
            decomp_fail.append((bi, "decompression failed or beyond EOF"))
            continue

        entries_table = safe_parse_block_entries(decomp)
        if entries_table is None:
            decomp_fail.append((bi, "entry table parse failed"))
            continue

        block_cache[bi] = (decomp, entries_table)
        decomp_ok += 1

    print(f"  Blocks decompressed:   {decomp_ok}")
    print(f"  Decompression failed:  {len(decomp_fail)}")

    if decomp_fail:
        for bi, reason in decomp_fail[:10]:
            print(f"    block[{bi}] ({_path_label(patch_paths, bi)}): {reason}")

    # Build global hash -> (block_index, entry_index) map across all patch blocks
    global_hash_location: dict[int, list[tuple[int, int]]] = {}
    for bi, (_decomp, etable) in block_cache.items():
        for ei, be in enumerate(etable):
            global_hash_location.setdefault(be["hash"], []).append((bi, ei))

    # ================================================================
    # 5. Verify each ASET entry against block content
    # ================================================================
    errors: list[str] = []
    warnings: list[str] = []
    info_msgs: list[str] = []

    for entry in patch_aset:
        bi = entry["block_index"]
        if bi >= patch_indx_count or bi not in block_cache:
            continue

        _decomp, entries_table = block_cache[bi]
        ref_type = entry["ref_type"]
        path = _path_label(patch_paths, bi)
        entry_count = len(entries_table)
        block_name_hashes = {e["hash"] for e in entries_table}
        block_hash_to_entry = {e["hash"]: e for e in entries_table}

        ah = entry["asset_hash"]
        tn = TYPE_ID_TO_NAME.get(entry["type_id"], f"type_{entry['type_id']}")

        if ref_type == "primary":
            # Primary: asset_hash MUST be in block entry table
            if ah not in block_name_hashes:
                errors.append(
                    f"PRIMARY MISS: row {entry['row']:5d} "
                    f"asset=0x{ah:08X} ({tn}) "
                    f"not in block[{bi}] ({path}, {entry_count} entries)")
            else:
                be = block_hash_to_entry[ah]
                exp_tid = type_id_for_type_hash(be["type_hash"])
                if exp_tid is not None and exp_tid != entry["type_id"]:
                    errors.append(
                        f"TYPE MISMATCH: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} "
                        f"ASET type_id={entry['type_id']} "
                        f"block type_hash=0x{be['type_hash']:08X} "
                        f"(expected type_id={exp_tid})")

        elif ref_type == "sub_entry":
            # Sub-entry: index must be < entry_count
            if entry["sub_entry"] >= entry_count:
                # Check if this looks like the Xbox block index leak
                if entry["sub_entry"] == entry["block_index"]:
                    warnings.append(
                        f"SUB_ENTRY=BLOCK_IDX: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} ({tn}) "
                        f"sub_entry={entry['sub_entry']} == block_index "
                        f"(block has {entry_count} entries) -- "
                        f"likely Xbox block index in low16")
                else:
                    errors.append(
                        f"SUB_ENTRY OOB: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} ({tn}) "
                        f"sub_entry={entry['sub_entry']} >= "
                        f"{entry_count} entries in block[{bi}] ({path})")

            # Verify asset_hash exists in the block
            if ah not in block_name_hashes:
                # Check if it exists anywhere in the patch WAD
                alt_locs = global_hash_location.get(ah, [])
                if alt_locs:
                    alt_blocks = ", ".join(
                        f"block[{b}]" for b, _e in alt_locs[:3])
                    info_msgs.append(
                        f"SUB_ENTRY REDIR: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} ({tn}) "
                        f"not in block[{bi}] ({path}) "
                        f"but found in {alt_blocks}")
                else:
                    warnings.append(
                        f"SUB_ENTRY MISS: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} ({tn}) "
                        f"not in block[{bi}] ({path}, {entry_count} entries) "
                        f"and not in any other patch block")
            else:
                be = block_hash_to_entry[ah]
                exp_tid = type_id_for_type_hash(be["type_hash"])
                if exp_tid is not None and exp_tid != entry["type_id"]:
                    warnings.append(
                        f"TYPE MISMATCH: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} "
                        f"ASET type_id={entry['type_id']} vs "
                        f"block type_hash=0x{be['type_hash']:08X} "
                        f"(expected {exp_tid})")

        elif ref_type == "streaming":
            # Streaming: asset_hash may NOT be in the block_index block.
            # The block_index identifies the primary block, and secondary_ref
            # identifies a dependency block. The asset may live in either.
            if ah in block_name_hashes:
                be = block_hash_to_entry[ah]
                exp_tid = type_id_for_type_hash(be["type_hash"])
                if exp_tid is not None and exp_tid != entry["type_id"]:
                    warnings.append(
                        f"STREAMING TYPE: row {entry['row']:5d} "
                        f"asset=0x{ah:08X} "
                        f"ASET type_id={entry['type_id']} vs "
                        f"block type_hash=0x{be['type_hash']:08X} "
                        f"(expected {exp_tid})")
            else:
                alt_locs = global_hash_location.get(ah, [])
                if alt_locs:
                    pass  # asset found elsewhere in patch WAD -- normal streaming
                else:
                    # Not in any patch block -- might be in base WAD
                    if ah in base_by_hash:
                        pass  # streaming dep references base WAD asset -- OK
                    else:
                        info_msgs.append(
                            f"STREAMING UNRESOLVED: row {entry['row']:5d} "
                            f"asset=0x{ah:08X} ({tn}) "
                            f"secondary=0x{entry['secondary_ref']:08X} "
                            f"not in any patch block or base ASET")

    # Cross-reference shadows for type_id consistency
    shadow_type_changes: list[str] = []
    for entry in patch_aset:
        ah = entry["asset_hash"]
        if ah not in base_by_hash:
            continue
        for base_e in base_by_hash[ah]:
            if base_e["type_id"] != entry["type_id"]:
                shadow_type_changes.append(
                    f"row {entry['row']:5d} asset=0x{ah:08X} "
                    f"patch type_id={entry['type_id']} "
                    f"({TYPE_ID_TO_NAME.get(entry['type_id'], '?')}) vs "
                    f"base type_id={base_e['type_id']} "
                    f"({TYPE_ID_TO_NAME.get(base_e['type_id'], '?')})")
                break

    # ================================================================
    # 6. Report results
    # ================================================================
    print(f"\n{'=' * 60}")
    print("Verification Results")
    print(f"{'=' * 60}")

    total_verified = sum(
        1 for e in patch_aset
        if e["block_index"] < patch_indx_count and e["block_index"] in block_cache
    )
    print(f"  Entries verified:         {total_verified}")
    print(f"  ERRORS (likely broken):   {len(errors)}")
    print(f"  WARNINGS (suspect):       {len(warnings)}")
    print(f"  INFO (informational):     {len(info_msgs)}")
    print(f"  Shadow type changes:      {len(shadow_type_changes)}")

    if errors:
        by_prefix: dict[str, int] = {}
        for e in errors:
            p = e.split(":")[0]
            by_prefix[p] = by_prefix.get(p, 0) + 1
        print(f"\n  Error breakdown:")
        for p, c in sorted(by_prefix.items(), key=lambda x: -x[1]):
            print(f"    {p}: {c}")
        print(f"\n  First {min(30, len(errors))} errors:")
        for e in errors[:30]:
            print(f"    {e}")

    if warnings:
        by_prefix: dict[str, int] = {}
        for w in warnings:
            p = w.split(":")[0]
            by_prefix[p] = by_prefix.get(p, 0) + 1
        print(f"\n  Warning breakdown:")
        for p, c in sorted(by_prefix.items(), key=lambda x: -x[1]):
            print(f"    {p}: {c}")
        print(f"\n  First {min(30, len(warnings))} warnings:")
        for w in warnings[:30]:
            print(f"    {w}")

    if info_msgs:
        by_prefix: dict[str, int] = {}
        for m in info_msgs:
            p = m.split(":")[0]
            by_prefix[p] = by_prefix.get(p, 0) + 1
        print(f"\n  Info breakdown:")
        for p, c in sorted(by_prefix.items(), key=lambda x: -x[1]):
            print(f"    {p}: {c}")

    if shadow_type_changes:
        print(f"\n  Shadow type changes (first 20):")
        for m in shadow_type_changes[:20]:
            print(f"    {m}")

    # Per-block error summary
    if errors or warnings:
        block_issue_map: dict[int, dict[str, int]] = {}
        for msg_list, severity in [(errors, "error"), (warnings, "warning")]:
            for msg in msg_list:
                for bi in blocks_needed:
                    if f"block[{bi}]" in msg:
                        if bi not in block_issue_map:
                            block_issue_map[bi] = {"error": 0, "warning": 0}
                        block_issue_map[bi][severity] += 1

        if block_issue_map:
            print(f"\n{'=' * 60}")
            print("Per-Block Issue Summary (top 20)")
            print(f"{'=' * 60}")
            ranked = sorted(
                block_issue_map.items(),
                key=lambda x: -(x[1]["error"] + x[1]["warning"]))
            for bi, counts in ranked[:20]:
                path = _path_label(patch_paths, bi)
                total_refs = len(blocks_needed.get(bi, []))
                entry_count = 0
                if bi in block_cache:
                    entry_count = len(block_cache[bi][1])
                print(f"  block[{bi:4d}] {path:50s} "
                      f"entries={entry_count:3d} refs={total_refs:3d} "
                      f"err={counts['error']:3d} warn={counts['warning']:3d}")

    # ================================================================
    # Final verdict
    # ================================================================
    print(f"\n{'=' * 60}")
    total_issues = len(oob_entries) + len(decomp_fail) + len(errors)
    if total_issues == 0 and not warnings:
        print("PASS: All patch ASET entries resolve correctly")
        return 0
    elif total_issues == 0:
        print(f"PASS (with {len(warnings)} warnings): "
              f"No hard errors, but {len(warnings)} suspect entries")
        return 0
    else:
        print(f"FAIL: {total_issues} error(s) found")
        if oob_entries:
            print(f"  Out-of-range block refs:  {len(oob_entries)}")
        if decomp_fail:
            print(f"  Decompression failures:   {len(decomp_fail)}")
        if errors:
            print(f"  Block content errors:     {len(errors)}")
        if warnings:
            print(f"  Additionally {len(warnings)} warnings")
        return 1


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--base", type=Path, required=True, help="Base vz.wad")
    ap.add_argument("--patch", type=Path, required=True, help="Patch vz-patch.wad")
    ap.add_argument("--sample", type=int, default=0,
                    help="Decompress and verify only N patch blocks (0 = all)")
    args = ap.parse_args()

    for p in (args.base, args.patch):
        if not p.is_file():
            print(f"ERROR: {p} not found", file=sys.stderr)
            return 1

    base_raw = args.base.read_bytes()
    patch_raw = args.patch.read_bytes()

    return verify_patch_aset(
        base_raw=base_raw,
        patch_raw=patch_raw,
        sample_limit=args.sample,
    )


if __name__ == "__main__":
    raise SystemExit(main())
