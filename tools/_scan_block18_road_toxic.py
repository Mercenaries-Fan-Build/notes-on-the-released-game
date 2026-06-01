#!/usr/bin/env python3
"""One-off scan: block 18 Road/RoadIntersection for toxic u32 0x4E093685 and huge floats."""
from __future__ import annotations

import struct
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from probe_schm_fields import extract_comp_groups, parse_component_name
from ucfx_ecs_codec import decode_road_payload, TRANSFORM_STRIDE

TARGET = 0x4E093685
FLOAT_LIMIT = 1e6


def main() -> None:
    bin_path = Path(
        "output/_scratch/byte_analysis/block_00018/"
        "00018_blocks__dlc01__dlc01_dlccon004_roads_P000_Q3.block.block.bin"
    )
    data = bin_path.read_bytes()
    raw_hits = [
        off
        for off in range(0, len(data) - 3, 4)
        if struct.unpack_from("<I", data, off)[0] == TARGET
    ]
    print(f"file_size={len(data)} raw_u32_hits={len(raw_hits)} sample={raw_hits[:12]}")

    ucfxs: list[int] = []
    pos = 0
    while True:
        i = data.find(b"UCFX", pos)
        if i < 0:
            break
        ucfxs.append(i)
        pos = i + 1

    road_hits: list[dict] = []
    inter_hits: list[dict] = []
    road_float_hits: list[tuple] = []
    inter_float_hits: list[tuple] = []
    quat_ok = quat_bad = 0
    transform_target_at8: list[dict] = []
    lane_as_y_huge: list[tuple] = []

    for ni, ucfx_pos in enumerate(ucfxs):
        block_end = ucfxs[ni + 1] if ni + 1 < len(ucfxs) else len(data)
        chunk = data[ucfx_pos:block_end]
        for g in extract_comp_groups(chunk, big_endian=False):
            if not g.get("data"):
                continue
            name = parse_component_name(g["info"]) if g.get("info") else ""
            d = g["data"]
            schm = g.get("schm")
            ps = (
                struct.unpack_from("<I", schm, 4)[0]
                if schm and len(schm) >= 8
                else None
            )
            if name == "Road":
                stride = 4 + (ps or 40)
                for ri in range(len(d) // stride):
                    rec = d[ri * stride : (ri + 1) * stride]
                    if len(rec) < 44:
                        continue
                    key = struct.unpack_from("<I", rec, 0)[0]
                    payload = rec[4:44]
                    fields = {0: "ref0", 4: "ref1", 8: "lane0", 12: "lane1"}
                    for off, fname in fields.items():
                        v = struct.unpack_from("<I", payload, off)[0]
                        if v == TARGET:
                            road_hits.append(
                                {"rec": ri, "key": hex(key), "field": fname, "off": off}
                            )
                        ymis = struct.unpack("<f", struct.pack("<I", v))[0]
                        if fname == "lane0" and abs(ymis) > FLOAT_LIMIT:
                            lane_as_y_huge.append((hex(key), hex(v), ymis))
                    dec = decode_road_payload(payload)
                    for label, pt in [
                        ("a", dec["road_endpoint_a"]),
                        ("b", dec["road_endpoint_b"]),
                    ]:
                        for ax, av in pt.items():
                            if abs(av) > FLOAT_LIMIT or av != av:
                                road_float_hits.append((ri, key, label, ax, av))
            elif name == "RoadIntersection":
                stride = 4 + (ps or 124)
                for ri in range(len(d) // stride):
                    rec = d[ri * stride : (ri + 1) * stride]
                    if len(rec) < 128:
                        continue
                    key = struct.unpack_from("<I", rec, 0)[0]
                    payload = rec[4 : 4 + 124]
                    for off in range(0, 28, 4):
                        v = struct.unpack_from("<I", payload, off)[0]
                        if v == TARGET:
                            inter_hits.append(
                                {"rec": ri, "key": hex(key), "off": off}
                            )
                    for vi in range(6):
                        o = 28 + vi * 12
                        x, y, z = struct.unpack_from("<3f", payload, o)
                        for ax, av in zip("xyz", (x, y, z)):
                            if abs(av) > FLOAT_LIMIT or av != av:
                                inter_float_hits.append((ri, key, vi, ax, av))
            elif name == "Transform":
                for ri in range(len(d) // TRANSFORM_STRIDE):
                    rec = d[ri * 42 : (ri + 1) * 42]
                    if len(rec) < 42:
                        continue
                    key = struct.unpack_from("<I", rec, 0)[0]
                    qx, qy, qz, qw = struct.unpack_from("<4f", rec, 20)
                    n2 = qx * qx + qy * qy + qz * qz + qw * qw
                    if 0.9 < n2 < 1.1:
                        quat_ok += 1
                    else:
                        quat_bad += 1
                    if struct.unpack_from("<I", rec, 8)[0] == TARGET:
                        transform_target_at8.append(
                            {"rec": ri, "key": hex(key), "y": struct.unpack_from("<f", rec, 8)[0]}
                        )

    print(f"road_u32_hits={len(road_hits)} sample={road_hits[:6]}")
    print(f"inter_u32_hits={len(inter_hits)} sample={inter_hits[:6]}")
    print(f"road_endpoint_big_floats={len(road_float_hits)}")
    print(f"inter_vec3_big_floats={len(inter_float_hits)}")
    print(f"quat_ok={quat_ok} quat_bad={quat_bad}")
    print(f"transform_has_TARGET_at_rec+8={transform_target_at8}")
    print(f"TARGET_as_float={struct.unpack('<f', struct.pack('<I', TARGET))[0]:.6g}")
    print(f"road_lane0_interpreted_as_Y_huge={len(lane_as_y_huge)} sample={lane_as_y_huge[:5]}")


if __name__ == "__main__":
    main()
