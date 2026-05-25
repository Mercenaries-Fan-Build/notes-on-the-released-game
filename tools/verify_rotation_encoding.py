#!/usr/bin/env python3
"""Verify whether layers_static rotation floats are quaternion half-angles or direct sin/cos.

Reads the raw layers_static binary and the extracted JSON, then:
1. Checks 4-component quaternion normalization: qx² + qy² + qz² + qw² ≈ 1.0
2. Compares atan2(s,c) vs 2*atan2(s,c) for well-known landmarks
3. Reports statistics on normalization residuals

If the 4 floats at offsets +0x14..+0x20 are a standard quaternion (qx, qy, qz, qw),
then for a pure Y-axis rotation: qy = sin(θ/2), qw = cos(θ/2), and the true yaw
is 2*atan2(qy, qw). The current code uses atan2(rot_sin, rot_cos) without the ×2.
"""
from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path

LAYERS_STATIC_RECORD_STRIDE = 42

LANDMARKS = {
    "pmcoutpost_bld_hq",
    "commercial_bld_firestation",
    "maracaibo_bld_skyscraper01",
    "commercial_bld_supermarket",
    "aloutpost_bld_barracks01",
    "aloutpost_bld_garage01",
    "pmcoutpost_bld_dock",
    "pmcoutpost_bld_pool",
}


def scan_binary(bin_path: Path, max_records: int = 0) -> list[dict]:
    """Extract rotation floats directly from binary without rounding."""
    data = bin_path.read_bytes()

    ucfx_positions = []
    pos = 0
    while True:
        idx = data.find(b"UCFX", pos)
        if idx == -1:
            break
        ucfx_positions.append(idx)
        pos = idx + 1

    records = []
    for si, ucfx_off in enumerate(ucfx_positions):
        search_start = ucfx_off
        search_end = ucfx_positions[si + 1] if si + 1 < len(ucfx_positions) else len(data)
        block = data[search_start:search_end]

        # Find Transform data sections by scanning for valid coordinate patterns
        roff = 0
        while roff + LAYERS_STATIC_RECORD_STRIDE <= len(block):
            rec = block[roff:roff + LAYERS_STATIC_RECORD_STRIDE]
            x = struct.unpack_from("<f", rec, 4)[0]
            y = struct.unpack_from("<f", rec, 8)[0]
            z = struct.unpack_from("<f", rec, 12)[0]

            if (abs(x) < 5000 and abs(y) < 500 and abs(z) < 5000
                    and not (x == 0.0 and y == 0.0 and z == 0.0)
                    and math.isfinite(x) and math.isfinite(y) and math.isfinite(z)):
                zero_pad = struct.unpack_from("<f", rec, 16)[0]
                qx = struct.unpack_from("<f", rec, 20)[0]
                qy = struct.unpack_from("<f", rec, 24)[0]
                qz = struct.unpack_from("<f", rec, 28)[0]
                qw = struct.unpack_from("<f", rec, 32)[0]

                if math.isfinite(qx) and math.isfinite(qy) and math.isfinite(qz) and math.isfinite(qw):
                    if abs(zero_pad) < 0.001:
                        norm4 = qx*qx + qy*qy + qz*qz + qw*qw
                        norm2 = qy*qy + qw*qw
                        records.append({
                            "x": x, "y": y, "z": z,
                            "qx": qx, "qy": qy, "qz": qz, "qw": qw,
                            "norm4": norm4,
                            "norm2": norm2,
                            "yaw_single": math.degrees(math.atan2(qy, qw)),
                            "yaw_double": math.degrees(2 * math.atan2(qy, qw)),
                        })
                        if max_records and len(records) >= max_records:
                            return records

            roff += LAYERS_STATIC_RECORD_STRIDE

    return records


def analyze_json(json_path: Path) -> None:
    """Cross-reference JSON placements with quaternion analysis."""
    data = json.loads(json_path.read_text(encoding="utf-8"))
    placements = data if isinstance(data, list) else data.get("placements", [])

    landmark_records = []
    non_yaw_records = []

    for p in placements:
        rot_sin = p.get("rot_sin")
        rot_cos = p.get("rot_cos")
        qx = p.get("rotation_quat_x", 0.0)
        qz = p.get("rotation_quat_z", 0.0)

        if rot_sin is None or rot_cos is None:
            continue

        norm4 = float(qx)**2 + float(rot_sin)**2 + float(qz)**2 + float(rot_cos)**2
        has_tilt = abs(float(qx)) > 0.01 or abs(float(qz)) > 0.01

        if has_tilt:
            non_yaw_records.append({
                "entity_name": p.get("entity_name", "?"),
                "qx": float(qx), "qy": float(rot_sin),
                "qz": float(qz), "qw": float(rot_cos),
                "norm4": norm4,
                "yaw_single": math.degrees(math.atan2(float(rot_sin), float(rot_cos))),
                "yaw_double": math.degrees(2 * math.atan2(float(rot_sin), float(rot_cos))),
                "position": p.get("position", {}),
            })

        name = (p.get("entity_name") or "").lower()
        for lm in LANDMARKS:
            if lm in name:
                landmark_records.append({
                    "entity_name": p.get("entity_name"),
                    "rot_sin": float(rot_sin),
                    "rot_cos": float(rot_cos),
                    "qx": float(qx), "qz": float(qz),
                    "norm4": norm4,
                    "yaw_single": math.degrees(math.atan2(float(rot_sin), float(rot_cos))),
                    "yaw_double": math.degrees(2 * math.atan2(float(rot_sin), float(rot_cos))),
                    "position": p.get("position", {}),
                })
                break

    print(f"\n{'='*70}")
    print("LANDMARK ROTATION ANALYSIS")
    print(f"{'='*70}")
    for r in landmark_records[:20]:
        print(f"\n  {r['entity_name']}")
        print(f"    pos: ({r['position'].get('x',0):.1f}, {r['position'].get('y',0):.1f}, {r['position'].get('z',0):.1f})")
        print(f"    qx={r['qx']:.6f}  qy(rot_sin)={r['rot_sin']:.6f}  qz={r['qz']:.6f}  qw(rot_cos)={r['rot_cos']:.6f}")
        print(f"    norm4 = {r['norm4']:.8f}  (should be 1.0 if quaternion)")
        print(f"    yaw (atan2):   {r['yaw_single']:+.2f}°")
        print(f"    yaw (2*atan2): {r['yaw_double']:+.2f}°")

    print(f"\n{'='*70}")
    print(f"RECORDS WITH NON-TRIVIAL TILT (|qx| > 0.01 or |qz| > 0.01): {len(non_yaw_records)}")
    print(f"{'='*70}")
    for r in non_yaw_records[:15]:
        print(f"\n  {r['entity_name']}")
        print(f"    qx={r['qx']:.6f}  qy={r['qy']:.6f}  qz={r['qz']:.6f}  qw={r['qw']:.6f}")
        print(f"    norm4 = {r['norm4']:.8f}")
        print(f"    yaw_single={r['yaw_single']:+.2f}°  yaw_double={r['yaw_double']:+.2f}°")


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify rotation encoding (half-angle vs direct)")
    ap.add_argument("--binary", type=Path,
                    help="Path to layers_static .bin file (for raw binary scan)")
    ap.add_argument("--json", type=Path,
                    help="Path to layers_static.json (for cross-reference)")
    ap.add_argument("--max-binary", type=int, default=5000,
                    help="Max records to scan from binary (0=all)")
    args = ap.parse_args()

    if not args.binary and not args.json:
        ap.error("Provide --binary and/or --json")

    if args.binary:
        print(f"Scanning binary: {args.binary}")
        records = scan_binary(args.binary, max_records=args.max_binary)
        print(f"Found {len(records)} candidate Transform records\n")

        if records:
            norm4_values = [r["norm4"] for r in records]
            norm2_values = [r["norm2"] for r in records]

            n4_near_one = sum(1 for n in norm4_values if abs(n - 1.0) < 0.01)
            n2_near_one = sum(1 for n in norm2_values if abs(n - 1.0) < 0.01)
            n4_mean = sum(norm4_values) / len(norm4_values)
            n2_mean = sum(norm2_values) / len(norm2_values)

            print("4-COMPONENT NORMALIZATION (qx² + qy² + qz² + qw²):")
            print(f"  Records near 1.0 (±0.01): {n4_near_one}/{len(records)} ({100*n4_near_one/len(records):.1f}%)")
            print(f"  Mean: {n4_mean:.6f}")
            print(f"  Min:  {min(norm4_values):.6f}")
            print(f"  Max:  {max(norm4_values):.6f}")

            print(f"\n2-COMPONENT NORMALIZATION (qy² + qw² only, i.e. rot_sin² + rot_cos²):")
            print(f"  Records near 1.0 (±0.01): {n2_near_one}/{len(records)} ({100*n2_near_one/len(records):.1f}%)")
            print(f"  Mean: {n2_mean:.6f}")

            has_tilt = [r for r in records if abs(r["qx"]) > 0.01 or abs(r["qz"]) > 0.01]
            print(f"\nRecords with non-trivial qx or qz (tilt): {len(has_tilt)}/{len(records)}")
            if has_tilt:
                print("  First 5 with tilt:")
                for r in has_tilt[:5]:
                    print(f"    pos=({r['x']:.1f},{r['y']:.1f},{r['z']:.1f}) "
                          f"qx={r['qx']:.4f} qy={r['qy']:.4f} qz={r['qz']:.4f} qw={r['qw']:.4f} "
                          f"norm4={r['norm4']:.6f}")

            print(f"\nSample yaw comparisons (first 10):")
            for r in records[:10]:
                print(f"  pos=({r['x']:.0f},{r['y']:.0f},{r['z']:.0f})  "
                      f"atan2={r['yaw_single']:+.1f}°  2*atan2={r['yaw_double']:+.1f}°  "
                      f"norm4={r['norm4']:.4f}")

    if args.json:
        analyze_json(args.json)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
