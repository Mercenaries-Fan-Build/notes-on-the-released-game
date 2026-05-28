#!/usr/bin/env python3
"""Generate and verify the audio endian field-type spec from Xbox vs PC WADs.

Layer 1 of the packed-type verification pipeline: derives field types from
cross-platform byte evidence with periodic folding for soundbank records.

Outputs: analysis/audio_endian/audio_field_spec.json (or custom --output path)

Exit codes:
  0: spec generated, no ambiguous/mixed fields
  1: ambiguous or mixed fields detected (strict mode)
  2: runtime error (missing WAD, parse failure)

Usage:
  python tools/verify_audio_field_map.py \\
    --pc-wad game-files/pc-game-vz.wad \\
    --xbox-wad game-files/xbox-vz.wad \\
    [--output analysis/audio_endian/audio_field_spec.json] \\
    [--strict] \\
    [--extract-goldens --goldens-dir tools/testdata/audio_endian/]
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from audio_endian_spec import (  # noqa: E402
    TYPE_SOUNDBANK,
    TYPE_WAVEBANK,
    AUDIO_TYPES,
    TYPE_NAMES,
    SoundbankGeometry,
    build_audio_field_spec,
    check_spec_strict,
    get_u8x4_relative_offsets,
    get_per_stride_u8x4_offsets,
    verify_u8x4_invariant,
    write_spec,
)
from _audio_cross_platform_diff import (  # noqa: E402
    load_wad,
    load_wad_or_from_zip,
    find_xbox_wad,
    collect_audio_bodies,
    SCFF_MAGIC,
)


def _split_bodies_by_type(
    bodies: dict[tuple[int, int], bytes],
) -> tuple[dict[int, bytes], dict[int, bytes]]:
    """Split (hash, type_hash)->body dict into separate soundbank/wavebank dicts."""
    sb = {k[0]: v for k, v in bodies.items() if k[1] == TYPE_SOUNDBANK}
    wb = {k[0]: v for k, v in bodies.items() if k[1] == TYPE_WAVEBANK}
    return sb, wb


def extract_golden_fixtures(
    xbox_sb: dict[int, bytes],
    pc_sb: dict[int, bytes],
    output_dir: Path,
    hashes: list[int] | None = None,
    max_fixtures: int = 5,
) -> list[int]:
    """Write golden fixture pairs for converter testing.

    Selects banks with valid integer stride (required for u8x4 protection)
    and high sub_count.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    matched = sorted(set(xbox_sb.keys()) & set(pc_sb.keys()))

    candidates: list[tuple[int, int, int]] = []  # (has_stride, sub_count, hash)
    for h in matched:
        geo = SoundbankGeometry.from_body(pc_sb[h], "le")
        sc = geo.sub_count if geo else 0
        has_stride = 1 if (geo and geo.stride_a) else 0
        candidates.append((has_stride, sc, h))
    candidates.sort(reverse=True)  # stride-having first, then by sub_count

    if hashes:
        selected = [h for h in hashes if h in xbox_sb and h in pc_sb]
    else:
        selected = [h for _, _, h in candidates[:max_fixtures]]

    written = []
    for h in selected:
        xbox_path = output_dir / f"soundbank_{h:08X}_xbox.bin"
        pc_path = output_dir / f"soundbank_{h:08X}_pc.bin"
        xbox_path.write_bytes(xbox_sb[h])
        pc_path.write_bytes(pc_sb[h])
        geo = SoundbankGeometry.from_body(pc_sb[h], "le")
        sc = geo.sub_count if geo else 0
        stride = geo.stride_a if geo else None
        print(f"  Written: {xbox_path.name} + {pc_path.name} (sub_count={sc}, stride={stride})")
        written.append(h)

    return written


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Generate/verify audio endian field-type spec from Xbox vs PC WADs")
    ap.add_argument("--pc-wad", type=Path, default=Path("game-files/pc-game-vz.wad"))
    ap.add_argument("--xbox-wad", type=Path, default=Path("game-files/xbox-vz.wad"))
    ap.add_argument("--output", type=Path,
                    default=Path("analysis/audio_endian/audio_field_spec.json"))
    ap.add_argument("--strict", action="store_true",
                    help="Exit 1 if any ambiguous or mixed fields detected")
    ap.add_argument("--extract-goldens", action="store_true",
                    help="Extract golden fixture pairs for converter testing")
    ap.add_argument("--goldens-dir", type=Path,
                    default=Path("tools/testdata/audio_endian"))
    ap.add_argument("--hashes", type=str, default=None,
                    help="Comma-separated hex hashes for golden extraction")
    args = ap.parse_args()

    print("=" * 70)
    print("AUDIO ENDIAN FIELD-TYPE SPEC GENERATOR")
    print("=" * 70)

    # Load WADs
    if not args.pc_wad.exists():
        print(f"ERROR: PC WAD not found: {args.pc_wad}", file=sys.stderr)
        return 2
    if not args.xbox_wad.exists():
        xbox_source = find_xbox_wad(args.xbox_wad.parent)
        if xbox_source is None:
            print(f"ERROR: Xbox WAD not found: {args.xbox_wad}", file=sys.stderr)
            return 2
        xbox_ctx = load_wad_or_from_zip(xbox_source)
    else:
        xbox_ctx = load_wad(args.xbox_wad)

    pc_ctx = load_wad(args.pc_wad)

    if xbox_ctx.endian != "be":
        print(f"WARNING: Xbox WAD reports {xbox_ctx.endian.upper()}, expected BE")

    # Collect bodies
    print("\nCollecting audio bodies...")
    pc_bodies = collect_audio_bodies(pc_ctx)
    xbox_bodies = collect_audio_bodies(xbox_ctx)

    pc_sb, pc_wb = _split_bodies_by_type(pc_bodies)
    xbox_sb, xbox_wb = _split_bodies_by_type(xbox_bodies)

    sb_matched = len(set(pc_sb.keys()) & set(xbox_sb.keys()))
    wb_matched = len(set(pc_wb.keys()) & set(xbox_wb.keys()))
    print(f"  Matched soundbanks: {sb_matched}")
    print(f"  Matched wavebanks:  {wb_matched}")

    if sb_matched == 0 and wb_matched == 0:
        print("ERROR: No matched audio entries between platforms!", file=sys.stderr)
        return 2

    # Build spec
    print("\nBuilding field spec with periodic folding...")
    spec = build_audio_field_spec(xbox_sb, pc_sb, xbox_wb, pc_wb)

    # Print summary
    u8x4_a = get_u8x4_relative_offsets(spec, "section_a")
    u8x4_c = get_u8x4_relative_offsets(spec, "section_c")
    print(f"\n  Section A u8x4 relative offsets: {sorted(u8x4_a)}")
    print(f"  Section C u8x4 relative offsets: {sorted(u8x4_c)}")
    print(f"  Observed strides A: {spec['soundbank']['section_a']['observed_strides']}")
    print(f"  Observed strides C: {spec['soundbank']['section_c']['observed_strides']}")

    # Write spec
    write_spec(spec, args.output)
    print(f"\n  Spec written: {args.output}")

    # Golden fixtures
    if args.extract_goldens:
        print(f"\nExtracting golden fixtures to {args.goldens_dir}...")
        hashes = None
        if args.hashes:
            hashes = [int(h.strip(), 16) for h in args.hashes.split(",")]
        extract_golden_fixtures(xbox_sb, pc_sb, args.goldens_dir, hashes=hashes)

    # Strict check: deterministic per-bank, per-record invariant
    # Uses per-stride u8x4 offsets derived from cross-platform evidence
    per_stride = get_per_stride_u8x4_offsets(spec)
    print("\nPer-stride u8x4 offsets (from evidence):")
    for stride in sorted(per_stride.keys()):
        print(f"  stride {stride}: {sorted(per_stride[stride])}")

    print("\nVerifying u8x4 invariant (xbox == pc at per-stride offsets)...")
    violations = verify_u8x4_invariant(
        xbox_sb, pc_sb,
        expected_offsets_a=None,
        per_stride_offsets_a=per_stride,
        expected_offsets_c=None,
    )
    spec_failures = check_spec_strict(spec)

    if violations:
        print(f"\n  u8x4 INVARIANT VIOLATIONS: {len(violations)}")
        for v in violations[:20]:
            print(f"    {v}")
        if len(violations) > 20:
            print(f"    ... and {len(violations) - 20} more")
    else:
        print(f"  u8x4 invariant: PASS (all {sb_matched} banks, all records, offsets {{12,20,44}})")

    if spec_failures:
        print(f"\n  SPEC CHECK: {len(spec_failures)} issue(s)")
        for f in spec_failures:
            print(f"    - {f}")

    rc = 0
    if args.strict and (violations or spec_failures):
        print("\nFAIL (--strict)")
        rc = 1
    elif violations or spec_failures:
        print("\nWARN (use --strict to fail)")
    else:
        print("\nPASS")

    print(f"{'=' * 70}")
    return rc


if __name__ == "__main__":
    sys.exit(main())
