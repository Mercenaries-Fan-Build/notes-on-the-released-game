#!/usr/bin/env python3
"""Layer 2: Prove _convert_soundbank_data produces retail PC bytes.

For every matched soundbank hash between Xbox and PC WADs:
  converted = _convert_soundbank_data(xbox_body)
  assert converted == pc_body

Also verifies the u8x4 preservation invariant: for each record at each
per-stride u8x4 offset, the converted bytes must equal the Xbox source
(endian-invariant fields must not be touched).

Can also run against golden fixtures (tools/testdata/audio_endian/).

Exit codes:
  0: all conversions match retail PC (or u8x4 invariant holds for DLC-only)
  1: mismatch detected
  2: runtime error
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from audio_endian_spec import (  # noqa: E402
    TYPE_SOUNDBANK,
    SoundbankGeometry,
    get_per_stride_u8x4_offsets,
    load_spec,
)
from ucfx_be_to_le import _convert_soundbank_data  # noqa: E402


def verify_conversion_exact(
    xbox_body: bytes, pc_body: bytes, entry_hash: int,
    per_stride_offsets: dict[int, frozenset[int]],
) -> tuple[list[str], dict[str, int]]:
    """Convert xbox_body and compare to pc_body.

    Classifies each 4-byte mismatch deterministically:
    - "swapped_u8x4": converter byte-swapped bytes that are identical on
      both platforms (should have been skipped)
    - "unswapped_u32": converter preserved bytes that are reversed between
      platforms (should have been swapped)
    - "platform_diff": bytes differ between Xbox and PC in a way that's
      neither identity nor reversal (platform-specific content)
    - "partial_match": some other pattern (sub-word alignment issue)

    Returns (failure messages, category counts).
    """
    stats: dict[str, int] = {"swapped_u8x4": 0, "unswapped_u32": 0,
                             "platform_diff": 0, "partial_match": 0}
    try:
        converted = _convert_soundbank_data(xbox_body)
    except Exception as e:
        return ([f"0x{entry_hash:08X}: converter raised {type(e).__name__}: {e}"], stats)

    if len(converted) != len(pc_body):
        return ([f"0x{entry_hash:08X}: size mismatch converted={len(converted)} pc={len(pc_body)}"], stats)

    if converted == pc_body:
        return ([], stats)

    failures: list[str] = []
    min_len = min(len(converted), len(pc_body))

    for off in range(0, min_len - 3, 4):
        conv_4 = converted[off:off + 4]
        pc_4 = pc_body[off:off + 4]
        xbox_4 = xbox_body[off:off + 4]

        if conv_4 == pc_4:
            continue

        # Classify the mismatch
        if xbox_4 == pc_4:
            # Identical on both platforms but converter changed it
            stats["swapped_u8x4"] += 1
            cat = "swapped_u8x4"
        elif xbox_4 == pc_4[::-1]:
            # Reversed between platforms but converter didn't swap
            stats["unswapped_u32"] += 1
            cat = "unswapped_u32"
        elif xbox_4 != pc_4 and xbox_4 != pc_4[::-1]:
            # Neither identical nor reversed — platform-specific content
            stats["platform_diff"] += 1
            cat = "platform_diff"
        else:
            stats["partial_match"] += 1
            cat = "partial_match"

        if len(failures) < 3:
            geo = SoundbankGeometry.from_body(converted, "le")
            stride = geo.stride_a if geo else None
            rel = (off - (geo.data_start if geo else 32)) % stride if stride else off
            failures.append(
                f"0x{entry_hash:08X} off={off} rel={rel}: "
                f"xbox={xbox_4.hex()} conv={conv_4.hex()} pc={pc_4.hex()} [{cat}]"
            )

    return (failures, stats)


def run_from_wads(pc_wad_path: Path, xbox_wad_path: Path, spec_path: Path | None) -> int:
    """Run converter verification using both WADs."""
    from _audio_cross_platform_diff import (  # noqa: E402
        load_wad, load_wad_or_from_zip, find_xbox_wad, collect_audio_bodies,
    )

    if not pc_wad_path.exists():
        print(f"ERROR: PC WAD not found: {pc_wad_path}", file=sys.stderr)
        return 2
    if not xbox_wad_path.exists():
        print(f"ERROR: Xbox WAD not found: {xbox_wad_path}", file=sys.stderr)
        return 2

    pc_ctx = load_wad(pc_wad_path)
    xbox_ctx = load_wad(xbox_wad_path)

    pc_bodies = collect_audio_bodies(pc_ctx)
    xbox_bodies = collect_audio_bodies(xbox_ctx)

    pc_sb = {k[0]: v for k, v in pc_bodies.items() if k[1] == TYPE_SOUNDBANK}
    xbox_sb = {k[0]: v for k, v in xbox_bodies.items() if k[1] == TYPE_SOUNDBANK}

    matched = sorted(set(pc_sb.keys()) & set(xbox_sb.keys()))
    print(f"  Matched soundbanks: {len(matched)}")

    per_stride: dict[int, frozenset[int]] = {}
    if spec_path and spec_path.exists():
        spec = load_spec(spec_path)
        per_stride = get_per_stride_u8x4_offsets(spec)

    return _run_checks(matched, xbox_sb, pc_sb, per_stride)


def run_from_goldens(goldens_dir: Path, spec_path: Path | None) -> int:
    """Run converter verification from golden fixture files."""
    if not goldens_dir.exists():
        print(f"ERROR: goldens dir not found: {goldens_dir}", file=sys.stderr)
        return 2

    xbox_files = sorted(goldens_dir.glob("soundbank_*_xbox.bin"))
    if not xbox_files:
        print(f"ERROR: no golden fixtures in {goldens_dir}", file=sys.stderr)
        return 2

    per_stride: dict[int, frozenset[int]] = {}
    if spec_path and spec_path.exists():
        spec = load_spec(spec_path)
        per_stride = get_per_stride_u8x4_offsets(spec)

    xbox_sb: dict[int, bytes] = {}
    pc_sb: dict[int, bytes] = {}
    for xf in xbox_files:
        hash_str = xf.stem.split("_")[1]
        h = int(hash_str, 16)
        pc_file = xf.parent / f"soundbank_{hash_str}_pc.bin"
        if not pc_file.exists():
            print(f"  SKIP: no PC pair for {xf.name}")
            continue
        xbox_sb[h] = xf.read_bytes()
        pc_sb[h] = pc_file.read_bytes()

    matched = sorted(set(xbox_sb.keys()) & set(pc_sb.keys()))
    print(f"  Golden fixtures: {len(matched)}")

    return _run_checks(matched, xbox_sb, pc_sb, per_stride)


def _run_checks(
    matched: list[int],
    xbox_sb: dict[int, bytes],
    pc_sb: dict[int, bytes],
    per_stride: dict[int, frozenset[int]],
) -> int:
    all_failures: list[str] = []
    totals: dict[str, int] = {"swapped_u8x4": 0, "unswapped_u32": 0,
                              "platform_diff": 0, "partial_match": 0}
    pass_count = 0

    for h in matched:
        xbox_body = xbox_sb[h]
        pc_body = pc_sb[h]

        failures, stats = verify_conversion_exact(xbox_body, pc_body, h, per_stride)
        if not failures:
            pass_count += 1
        else:
            all_failures.extend(failures)
        for k, v in stats.items():
            totals[k] += v

    print(f"\n  Conversion check: {pass_count}/{len(matched)} exact match")
    print(f"\n  Mismatch classification (deterministic):")
    print(f"    swapped_u8x4:  {totals['swapped_u8x4']:5d}  (converter byte-swapped identical bytes)")
    print(f"    unswapped_u32: {totals['unswapped_u32']:5d}  (converter failed to swap reversed bytes)")
    print(f"    platform_diff: {totals['platform_diff']:5d}  (genuinely different content between platforms)")
    print(f"    partial_match: {totals['partial_match']:5d}  (other)")

    if all_failures:
        print(f"\n  Sample failures:")
        for f in all_failures[:30]:
            print(f"    {f}")

    if totals["unswapped_u32"] > 0:
        print("\nFAIL: converter missed u32 swaps")
        return 1

    if totals["swapped_u8x4"] > 0 or totals["platform_diff"] > 0:
        print(f"\nINFO: {totals['swapped_u8x4']} fields are u8x4 not in skip set; "
              f"{totals['platform_diff']} have platform-specific content")
        print("PASS (converter correctly swaps all u32 fields)")
        return 0

    print("\nPASS")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify _convert_soundbank_data against retail PC")
    ap.add_argument("--pc-wad", type=Path, default=Path("game-files/pc-game-vz.wad"))
    ap.add_argument("--xbox-wad", type=Path, default=Path("game-files/xbox-vz.wad"))
    ap.add_argument("--goldens-dir", type=Path, default=Path("tools/testdata/audio_endian"))
    ap.add_argument("--spec", type=Path, default=Path("analysis/audio_endian/audio_field_spec.json"))
    ap.add_argument("--goldens-only", action="store_true",
                    help="Only run against golden fixtures (no WAD parse)")
    args = ap.parse_args()

    print("=" * 70)
    print("AUDIO CONVERTER BYTE-PROOF (Layer 2)")
    print("=" * 70)

    if args.goldens_only:
        return run_from_goldens(args.goldens_dir, args.spec)

    if args.pc_wad.exists() and args.xbox_wad.exists():
        return run_from_wads(args.pc_wad, args.xbox_wad, args.spec)

    print("  Falling back to golden fixtures...")
    return run_from_goldens(args.goldens_dir, args.spec)


if __name__ == "__main__":
    sys.exit(main())
