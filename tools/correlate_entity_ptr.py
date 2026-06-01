#!/usr/bin/env python3
"""Correlate runtime spatial-hash entity pointer with on-disk Transform COMP records.

The engine reads world XYZ from ``[entity+4]``, ``[entity+8]``, ``[entity+0xC]`` at
``0x00516EF6`` / ``0x00516B10``. When those u32s look like garbage but the Transform
COMP blob is clean, the entity base may be misaligned (e.g. Transform record + 26).

Usage:
  .venv/Scripts/python.exe tools/correlate_entity_ptr.py \\
      --block output/_scratch/byte_analysis/block_00018/...block.bin \\
      --u32-at-plus4 0x8E290015 --u32-at-plus8 0x4E01BCEC

  .venv/Scripts/python.exe tools/correlate_entity_ptr.py \\
      --block path/to.block.bin --list-transforms --near-key 0x155E12

  .venv/Scripts/python.exe tools/correlate_entity_ptr.py \\
      --block path/to.block.bin --compare-comp-inventory
"""
from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from probe_schm_fields import extract_comp_groups, parse_component_name, parse_schm_fields
from ucfx_ecs_codec import TRANSFORM_STRIDE

# Candidate mis-bases: engine may point into middle of Transform payload (after u32 key).
CANDIDATE_ENTITY_DELTAS = (
    0,  # entity == record start (key at +0, XYZ at +4 — canonical)
    4,  # entity == after key (XYZ at +0 — unlikely)
    22,  # prior notes: payload+22
    26,  # 2026-05-31: Transform_record + 26 → [+8] reads record+34
    30,
    34,
)


def _find_ucfx_chunks(data: bytes) -> list[tuple[int, int]]:
    pos = 0
    starts: list[int] = []
    while True:
        i = data.find(b"UCFX", pos)
        if i < 0:
            break
        starts.append(i)
        pos = i + 1
    spans: list[tuple[int, int]] = []
    for si, start in enumerate(starts):
        end = starts[si + 1] if si + 1 < len(starts) else len(data)
        spans.append((start, end))
    return spans


def _iter_transform_records(data: bytes) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []
    for ucfx_pos, block_end in _find_ucfx_chunks(data):
        chunk = data[ucfx_pos:block_end]
        for g in extract_comp_groups(chunk, big_endian=False):
            name = parse_component_name(g["info"]) if g.get("info") else ""
            if name != "Transform" or not g.get("data"):
                continue
            d = g["data"]
            blob_off = data.find(d)
            if blob_off < 0:
                blob_off = -1
            for ri in range(len(d) // TRANSFORM_STRIDE):
                rec_off = ri * TRANSFORM_STRIDE
                rec = d[rec_off : rec_off + TRANSFORM_STRIDE]
                if len(rec) < TRANSFORM_STRIDE:
                    continue
                key = struct.unpack_from("<I", rec, 0)[0]
                x, y, z = struct.unpack_from("<3f", rec, 4)
                pad = struct.unpack_from("<f", rec, 16)[0]
                qx, qy, qz, qw = struct.unpack_from("<4f", rec, 20)
                tail = rec[36:42].hex()
                abs_rec = blob_off + rec_off if blob_off >= 0 else None
                records.append(
                    {
                        "ucfx_pos": ucfx_pos,
                        "record_index": ri,
                        "blob_file_offset": abs_rec,
                        "entity_key": key,
                        "entity_key_hex": f"0x{key:08x}",
                        "x": x,
                        "y": y,
                        "z": z,
                        "pad": pad,
                        "qx": qx,
                        "qy": qy,
                        "qz": qz,
                        "qw": qw,
                        "tail_hex": tail,
                        "record_bytes": rec,
                    }
                )
    return records


def _comp_inventory(data: bytes) -> dict[str, dict[str, Any]]:
    inv: dict[str, dict[str, Any]] = {}
    for ucfx_pos, block_end in _find_ucfx_chunks(data):
        chunk = data[ucfx_pos:block_end]
        for g in extract_comp_groups(chunk, big_endian=False):
            name = parse_component_name(g["info"]) if g.get("info") else "<unknown>"
            schm = g.get("schm")
            d = g.get("data") or b""
            ps = None
            nf = None
            if schm and len(schm) >= 8:
                nf = struct.unpack_from("<I", schm, 0)[0]
                ps = struct.unpack_from("<I", schm, 4)[0]
            stride = None
            if name == "Transform":
                stride = TRANSFORM_STRIDE
            elif ps is not None:
                stride = 4 + ps
            nrec = len(d) // stride if stride and stride > 0 else 0
            rem = len(d) % stride if stride and stride > 0 else len(d)
            entry = inv.setdefault(
                name,
                {
                    "count": 0,
                    "data_bytes": 0,
                    "schm_payload_stride": ps,
                    "schm_n_fields": nf,
                    "record_stride": stride,
                    "remainder": 0,
                    "compact": schm is None or len(schm) < 8,
                },
            )
            entry["count"] += 1
            entry["data_bytes"] += len(d)
            if stride and stride > 0:
                entry["remainder"] = rem
    return inv


def _u32_at_record_plus(rec: bytes, record_plus: int) -> int | None:
    off = record_plus
    if off < 0 or off + 4 > len(rec):
        return None
    return struct.unpack_from("<I", rec, off)[0]


def _field_name_at_record_offset(off: int) -> str:
    names = {
        0: "entity_key",
        4: "position_x",
        8: "position_y",
        12: "position_z",
        16: "zero_pad",
        20: "quat_x",
        24: "quat_y",
        28: "quat_z",
        32: "quat_w",
        34: "tail+2 (byte 34)",
        36: "tail+0",
    }
    if off in names:
        return names[off]
    if 36 <= off < 42:
        return f"tail+{off - 36}"
    return f"+0x{off:02x}"


def correlate_runtime_u32s(
    records: list[dict[str, Any]],
    u32_plus4: int | None,
    u32_plus8: int | None,
    u32_plus_c: int | None,
) -> list[dict[str, Any]]:
    targets = {
        4: u32_plus4,
        8: u32_plus8,
        0xC: u32_plus_c,
    }
    active = {k: v for k, v in targets.items() if v is not None}
    if not active:
        return []

    hits: list[dict[str, Any]] = []
    for rec in records:
        raw: bytes = rec["record_bytes"]
        for delta in CANDIDATE_ENTITY_DELTAS:
            match_fields: dict[str, Any] = {}
            ok = True
            for ent_off, want in active.items():
                rec_off = delta + ent_off
                got = _u32_at_record_plus(raw, rec_off)
                if got != want:
                    ok = False
                    break
                match_fields[f"record{_field_name_at_record_offset(rec_off)}"] = (
                    f"0x{got:08x}"
                )
            if ok:
                hits.append(
                    {
                        "entity_key": rec["entity_key_hex"],
                        "record_index": rec["record_index"],
                        "entity_base_delta": delta,
                        "entity_base_note": (
                            "canonical (XYZ at entity+4)"
                            if delta == 0
                            else f"mis-base: entity = Transform record + {delta}"
                        ),
                        "sane_xyz_at_canonical": (
                            abs(rec["x"]) < 5000
                            and abs(rec["y"]) < 5000
                            and abs(rec["z"]) < 5000
                        ),
                        "canonical_xyz": (rec["x"], rec["y"], rec["z"]),
                        "matched_fields": match_fields,
                    }
                )
    return hits


def search_u32_in_file(data: bytes, value: int) -> list[int]:
    pat = struct.pack("<I", value)
    hits: list[int] = []
    pos = 0
    while True:
        i = data.find(pat, pos)
        if i < 0:
            break
        hits.append(i)
        pos = i + 1
    return hits


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--block", type=Path, required=True, help="Decompressed .block.bin")
    ap.add_argument("--u32-at-plus4", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--u32-at-plus8", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--u32-at-plusc", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--search-u32", type=lambda s: int(s, 0), action="append", default=[])
    ap.add_argument("--near-key", type=lambda s: int(s, 0), default=None)
    ap.add_argument("--list-transforms", action="store_true")
    ap.add_argument("--compare-comp-inventory", type=Path, default=None,
                    help="Second block.bin to diff COMP inventory")
    ap.add_argument("--max-list", type=int, default=20)
    args = ap.parse_args()

    if not args.block.is_file():
        print(f"ERROR: not found: {args.block}", file=sys.stderr)
        return 2

    data = args.block.read_bytes()
    print(f"block={args.block.name} size={len(data)}")

    records = _iter_transform_records(data)
    print(f"transform_records={len(records)}")

    inv = _comp_inventory(data)
    print("\nCOMP inventory:")
    for name in sorted(inv, key=lambda n: (-inv[n]["data_bytes"], n)):
        e = inv[name]
        print(
            f"  {name:24s} groups={e['count']:3d}  data={e['data_bytes']:7d} B  "
            f"stride={e['record_stride']}  rem={e['remainder']}  compact={e['compact']}"
        )

    if args.compare_comp_inventory:
        other = args.compare_comp_inventory.read_bytes()
        inv2 = _comp_inventory(other)
        names = sorted(set(inv) | set(inv2))
        print(f"\nCOMP diff vs {args.compare_comp_inventory.name}:")
        for name in names:
            a, b = inv.get(name), inv2.get(name)
            ac = a["count"] if a else 0
            bc = b["count"] if b else 0
            ad = a["data_bytes"] if a else 0
            bd = b["data_bytes"] if b else 0
            if ac != bc or ad != bd:
                print(f"  {name:24s}  this groups={ac} bytes={ad}  other groups={bc} bytes={bd}")

    for val in args.search_u32:
        offs = search_u32_in_file(data, val)
        print(f"\nu32 0x{val:08x} in file: {len(offs)} hit(s)  sample offsets: {offs[:15]}")
        for off in offs[:5]:
            # Map to Transform record field if inside a record
            for rec in records:
                base = rec.get("blob_file_offset")
                if base is None or base < 0:
                    continue
                rel = off - base
                if 0 <= rel < TRANSFORM_STRIDE:
                    print(
                        f"    file 0x{off:x} -> Transform rec {rec['record_index']} "
                        f"key {rec['entity_key_hex']} {_field_name_at_record_offset(rel)}"
                    )
                    break

    if args.near_key is not None:
        print(f"\nTransforms near key 0x{args.near_key:08x}:")
        for rec in records:
            if abs(rec["entity_key"] - args.near_key) < 0x10000:
                print(
                    f"  idx={rec['record_index']:4d} key={rec['entity_key_hex']} "
                    f"xyz=({rec['x']:.2f}, {rec['y']:.2f}, {rec['z']:.2f}) "
                    f"+34=0x{struct.unpack_from('<I', rec['record_bytes'], 34)[0]:08x}"
                )

    hits = correlate_runtime_u32s(
        records, args.u32_at_plus4, args.u32_at_plus8, args.u32_at_plusc
    )
    if args.u32_at_plus4 is not None or args.u32_at_plus8 is not None or args.u32_at_plusc is not None:
        print("\nRuntime [entity+N] correlation (Transform records):")
        if not hits:
            print("  NO matching record for given deltas in", CANDIDATE_ENTITY_DELTAS)
        for h in hits[: args.max_list]:
            print(f"  key={h['entity_key']} rec={h['record_index']} delta={h['entity_base_delta']}")
            print(f"    {h['entity_base_note']}")
            print(f"    canonical_xyz={h['canonical_xyz']} sane={h['sane_xyz_at_canonical']}")
            for k, v in h["matched_fields"].items():
                print(f"    {k}={v}")

    if args.list_transforms:
        print(f"\nFirst {args.max_list} Transform records:")
        for rec in records[: args.max_list]:
            r = rec["record_bytes"]
            u34 = struct.unpack_from("<I", r, 34)[0]
            print(
                f"  [{rec['record_index']:4d}] {rec['entity_key_hex']} "
                f"xyz=({rec['x']:.2f},{rec['y']:.2f},{rec['z']:.2f}) "
                f"+26/+8_u32=0x{struct.unpack_from('<I', r, 26+8)[0]:08x} +34=0x{u34:08x}"
            )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
