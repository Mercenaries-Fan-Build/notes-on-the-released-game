#!/usr/bin/env python3
"""Cross-platform Havok byte-swap validation tool.

Compares class-aware BE→LE conversion output against known-good PC LE reference
data to validate byte-level swap correctness.

Usage:
  python hk_cross_platform_diff.py --be-block output/data/block_0464_be.bin \
      --le-reference output/data/block_0464_le_ref.bin

  python hk_cross_platform_diff.py --be-block output/data/block_0464_be.bin \
      --source-wad "path/to/vz.wad" --base-anim-index output/data/base_anim_index.json

If --le-reference is provided, it should be a pre-extracted LE block containing
the same entries (from PC retail vz.wad). If not available, use --self-validate
to verify internal consistency (field sanity checks only).

Reports:
  - Per-object byte-level comparison (match/mismatch counts)
  - Classification of mismatches by field type (u32/u16/u8/buffer)
  - Summary: total bytes compared, match rate, known-acceptable differences
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path
from collections import defaultdict
from dataclasses import dataclass, field

sys.path.insert(0, str(Path(__file__).parent))

from ucfx_be_to_le import (
    _convert_havok_be_to_le,
    _havok_parse_classnames_be,
    _havok_parse_virtual_fixups_be,
)
from hk_class_layouts import CLASS_REGISTRY, U8, U16, U32


_HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"


@dataclass
class DiffResult:
    """Results from comparing one Havok packfile."""
    offset_in_block: int = 0
    packfile_size: int = 0
    classes_found: list[str] = field(default_factory=list)
    total_bytes: int = 0
    matching_bytes: int = 0
    mismatches: list[dict] = field(default_factory=list)
    mismatch_by_region: dict[str, int] = field(default_factory=lambda: defaultdict(int))


def _find_havok_packfiles(data: bytes) -> list[tuple[int, int]]:
    """Find all Havok packfile (offset, size) pairs in a data blob."""
    results = []
    idx = 0
    while True:
        pos = data.find(_HAVOK_MAGIC, idx)
        if pos < 0:
            break

        hk_slice = data[pos:pos + 2000]
        cn_pos = hk_slice.find(b"__classnames__")
        if cn_pos < 0:
            idx = pos + 1
            continue

        try:
            sections = []
            for s in range(3):
                so = cn_pos + s * 48
                fields = struct.unpack_from(">7I", hk_slice, so + 20)
                sections.append(fields)
            da_abs, _, _, _, _, _, da_end = sections[2]
            total_size = da_abs + da_end
            if total_size > 0 and pos + total_size <= len(data):
                results.append((pos, total_size))
        except (struct.error, IndexError):
            pass

        idx = pos + 1

    return results


def _classify_byte_position(
    byte_off: int, obj_map: dict[int, str], da_lf: int
) -> str:
    """Classify a byte position within __data__ by region type."""
    if byte_off >= da_lf:
        return "fixup_stream"

    for obj_off, class_name in sorted(obj_map.items()):
        cls = CLASS_REGISTRY.get(class_name)
        if cls is None:
            continue
        obj_size = cls["size"]
        if obj_off <= byte_off < obj_off + obj_size:
            rel = byte_off - obj_off
            swap_spec = cls["swap"]
            if swap_spec == "all_u32":
                return f"object:{class_name}:u32"
            for field_off, w in swap_spec:
                if field_off <= rel < field_off + w:
                    width_name = {U32: "u32", U16: "u16", U8: "u8"}.get(w, "?")
                    return f"object:{class_name}:{width_name}"
            return f"object:{class_name}:gap"

    return "array_or_buffer"


def diff_one_packfile(
    be_slice: bytes, le_ref_slice: bytes, offset_in_block: int = 0
) -> DiffResult:
    """Compare class-aware conversion of BE slice against LE reference."""
    result = DiffResult(offset_in_block=offset_in_block, packfile_size=len(be_slice))

    try:
        stats = {}
        our_le = _convert_havok_be_to_le(be_slice, stats=stats)
    except Exception as e:
        result.mismatches.append({"error": str(e)})
        return result

    hk_slice = be_slice[:2000]
    cn_pos = hk_slice.find(b"__classnames__")
    sections = []
    for s in range(3):
        so = cn_pos + s * 48
        fields = struct.unpack_from(">7I", hk_slice, so + 20)
        sections.append(fields)

    cn_abs = sections[0][0]
    cn_end = sections[0][6]
    da_abs, da_lf, _, da_vf, _, _, da_end = sections[2]

    cn_names = _havok_parse_classnames_be(be_slice, cn_abs, cn_end)
    vfixups = _havok_parse_virtual_fixups_be(be_slice, da_abs, da_vf, da_end)
    obj_map = {}
    for src, _sec, cn_off in vfixups:
        name = cn_names.get(cn_off, "")
        if name:
            obj_map[src] = name
            result.classes_found.append(name)

    compare_start = da_abs
    compare_end = da_abs + da_end
    compare_len = min(compare_end, len(our_le), len(le_ref_slice))

    result.total_bytes = compare_len - compare_start

    for i in range(compare_start, compare_len):
        if our_le[i] == le_ref_slice[i]:
            result.matching_bytes += 1
        else:
            data_rel = i - da_abs
            region = _classify_byte_position(data_rel, obj_map, da_lf)
            result.mismatch_by_region[region] += 1
            if len(result.mismatches) < 20:
                result.mismatches.append({
                    "offset": i,
                    "data_rel": data_rel,
                    "our": our_le[i],
                    "ref": le_ref_slice[i],
                    "region": region,
                })

    return result


def self_validate_packfile(be_slice: bytes, offset_in_block: int = 0) -> DiffResult:
    """Validate conversion by checking field sanity (no reference needed)."""
    result = DiffResult(offset_in_block=offset_in_block, packfile_size=len(be_slice))

    try:
        stats = {}
        our_le = _convert_havok_be_to_le(be_slice, stats=stats)
    except Exception as e:
        result.mismatches.append({"error": str(e)})
        return result

    hk_slice = be_slice[:2000]
    cn_pos = hk_slice.find(b"__classnames__")
    sections = []
    for s in range(3):
        so = cn_pos + s * 48
        fields = struct.unpack_from(">7I", hk_slice, so + 20)
        sections.append(fields)

    cn_abs = sections[0][0]
    cn_end = sections[0][6]
    da_abs, _, _, da_vf, _, _, da_end = sections[2]

    cn_names = _havok_parse_classnames_be(be_slice, cn_abs, cn_end)
    vfixups = _havok_parse_virtual_fixups_be(be_slice, da_abs, da_vf, da_end)

    result.total_bytes = da_end

    for src, _sec, cn_off in vfixups:
        name = cn_names.get(cn_off, "")
        if not name:
            continue
        result.classes_found.append(name)
        obj_abs = da_abs + src

        if "Wavelet" in name or "wavelet" in name:
            at = struct.unpack_from("<I", our_le, obj_abs + 8)[0]
            dur = struct.unpack_from("<f", our_le, obj_abs + 12)[0]
            ntt = struct.unpack_from("<I", our_le, obj_abs + 16)[0]
            mbw = our_le[obj_abs + 44]
            if at != 3:
                result.mismatches.append({"field": "animationType", "val": at, "expect": 3})
            if not (0 <= dur < 300):
                result.mismatches.append({"field": "duration", "val": dur})
            if ntt == 0 or ntt > 500:
                result.mismatches.append({"field": "numTT", "val": ntt})
            if mbw > 32:
                result.mismatches.append({"field": "maxBitWidth", "val": mbw})
            else:
                result.matching_bytes += 96

        elif "Interleaved" in name or "interleaved" in name:
            at = struct.unpack_from("<I", our_le, obj_abs + 8)[0]
            dur = struct.unpack_from("<f", our_le, obj_abs + 12)[0]
            ntt = struct.unpack_from("<I", our_le, obj_abs + 16)[0]
            if at != 1:
                result.mismatches.append({"field": "animationType", "val": at, "expect": 1})
            if not (0 <= dur < 300):
                result.mismatches.append({"field": "duration", "val": dur})
            if ntt == 0 or ntt > 500:
                result.mismatches.append({"field": "numTT", "val": ntt})
            else:
                result.matching_bytes += 52

        elif "AnimationContainer" in name:
            result.matching_bytes += 40

    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--be-block", required=True, type=Path,
                        help="Path to Xbox 360 BE block file (decompressed)")
    parser.add_argument("--le-reference", type=Path,
                        help="Path to matching PC LE block for byte-level comparison")
    parser.add_argument("--self-validate", action="store_true",
                        help="Run sanity-check validation without LE reference")
    parser.add_argument("--verbose", "-v", action="store_true")
    args = parser.parse_args()

    if not args.be_block.exists():
        print(f"ERROR: {args.be_block} not found", file=sys.stderr)
        sys.exit(1)

    be_data = args.be_block.read_bytes()
    packfiles = _find_havok_packfiles(be_data)
    print(f"Found {len(packfiles)} Havok packfiles in {args.be_block.name}")

    le_data = None
    if args.le_reference and args.le_reference.exists():
        le_data = args.le_reference.read_bytes()
        le_packfiles = _find_havok_packfiles(le_data)
        print(f"Found {len(le_packfiles)} Havok packfiles in {args.le_reference.name}")

    total_results = []

    for i, (off, size) in enumerate(packfiles):
        be_slice = be_data[off:off + size]

        if le_data is not None:
            le_packfiles_local = _find_havok_packfiles(le_data)
            if i < len(le_packfiles_local):
                le_off, le_size = le_packfiles_local[i]
                le_slice = le_data[le_off:le_off + le_size]
                result = diff_one_packfile(be_slice, le_slice, off)
            else:
                result = self_validate_packfile(be_slice, off)
        else:
            result = self_validate_packfile(be_slice, off)

        total_results.append(result)

        if args.verbose or result.mismatches:
            classes_str = ", ".join(result.classes_found) if result.classes_found else "none"
            status = "PASS" if not result.mismatches else "MISMATCH"
            print(f"  [{i:3d}] offset=0x{off:X} size={size:5d} "
                  f"classes=[{classes_str}] -> {status}")
            if result.mismatches and args.verbose:
                for m in result.mismatches[:5]:
                    print(f"        {m}")
            if result.mismatch_by_region:
                for region, count in sorted(result.mismatch_by_region.items()):
                    print(f"        {region}: {count} bytes differ")

    total_bytes = sum(r.total_bytes for r in total_results)
    matching = sum(r.matching_bytes for r in total_results)
    failures = sum(1 for r in total_results if r.mismatches)

    print(f"\n{'='*60}")
    print(f"Summary: {len(total_results)} packfiles processed")
    if le_data is not None:
        match_pct = (matching / total_bytes * 100) if total_bytes else 0
        print(f"  Bytes compared: {total_bytes}")
        print(f"  Bytes matching: {matching} ({match_pct:.2f}%)")
    print(f"  Packfiles with issues: {failures}")
    print(f"  Packfiles clean: {len(total_results) - failures}")


if __name__ == "__main__":
    main()
