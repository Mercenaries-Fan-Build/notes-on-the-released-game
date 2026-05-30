#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Dump MTRL / PRMT / SCRB / texture INFO fields from one decompressed block file."""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path
from typing import Any

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from hash_resolver import get_resolver  # noqa: E402
from texture_streaming_index import TEXTURE_TYPE_HASH, iter_block_entries  # noqa: E402
from ucfx_mesh_codec import (  # noqa: E402
    CHUNK_HDR,
    CONTAINER_SENTINEL,
    _MTRL_PREAMBLE,
    iter_ucfx_containers,
    parse_mtrl,
    parse_mtrl_raw,
    parse_prmt,
    read_chunk_header,
)


def _hex_u32s(data: bytes, off: int, count: int) -> list[str]:
    out: list[str] = []
    for i in range(count):
        p = off + i * 4
        if p + 4 > len(data):
            break
        v = struct.unpack_from("<I", data, p)[0]
        out.append(f"0x{v:08X}")
    return out


def _enrich_hashes(hashes: list[int], resolver: Any) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for h in hashes:
        name = resolver.resolve_m2(h)
        rows.append({"hash": f"0x{h:08X}", "name": name})
    return rows


def _local_texture_names(data: bytes) -> dict[int, str]:
    names: dict[int, str] = {}
    for asset_hash, type_hash, body_offset, size in iter_block_entries(data):
        if type_hash != TEXTURE_TYPE_HASH or body_offset + size > len(data):
            continue
        if data[body_offset : body_offset + 4] != b"UCFX":
            continue
        u0 = struct.unpack_from("<I", data, body_offset + 4)[0]
        u3 = struct.unpack_from("<I", data, body_offset + 16)[0]
        db = body_offset + int(u0)
        for ci in range(min(int(u3), 16)):
            cp = body_offset + 20 + ci * CHUNK_HDR
            if cp + CHUNK_HDR > len(data):
                break
            tag = data[cp : cp + 4]
            cu0 = struct.unpack_from("<I", data, cp + 4)[0]
            cu1 = struct.unpack_from("<I", data, cp + 8)[0]
            if tag == b"NAME" and cu1 > 0:
                start = db + int(cu0)
                end = min(start + int(cu1), len(data))
                raw = data[start:end].split(b"\x00", 1)[0]
                try:
                    names[asset_hash] = raw.decode("ascii", errors="replace")
                except Exception:
                    pass
                break
    return names


def _scan_scrb_chunks(data: bytes, limit: int = 8) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    pos = 0
    while len(out) < limit:
        i = data.find(b"SCRB", pos)
        if i < 0:
            break
        # Heuristic: 20-byte chunk row before body, or inline after tag
        preview = data[i : min(i + 64, len(data))]
        out.append(
            {
                "offset": i,
                "preview_hex": preview.hex(),
                "size_guess": len(data) - i if i + 4 < len(data) else 0,
            }
        )
        pos = i + 4
    return out


def probe_block(data: bytes, *, max_containers: int = 12) -> dict[str, Any]:
    resolver = get_resolver()
    local_tex = _local_texture_names(data)

    toc: list[dict[str, Any]] = []
    if len(data) >= 4:
        count = struct.unpack_from("<I", data, 0)[0]
        for ei in range(min(count, 64)):
            ent_off = 4 + ei * 16
            if ent_off + 16 > len(data):
                break
            name_h, type_h, _c, sz = struct.unpack_from("<4I", data, ent_off)
            toc.append(
                {
                    "index": ei,
                    "name_hash": f"0x{name_h:08X}",
                    "name_resolved": resolver.resolve_m2(name_h),
                    "type_hash": f"0x{type_h:08X}",
                    "type_resolved": resolver.resolve_m2(type_h),
                    "size": sz,
                }
            )

    containers_out: list[dict[str, Any]] = []
    for ci, container in enumerate(iter_ucfx_containers(data)):
        if ci >= max_containers:
            break
        db = int(container["data_base"])
        entry: dict[str, Any] = {
            "container_index": ci,
            "data_base": db,
            "chunk_tags": [t.decode("ascii", errors="replace") for t, _ in container["chunks"]],
        }

        mtrl_abs, mtrl_len = parse_mtrl_raw(data, db, container["chunks"])
        if mtrl_abs > 0 and mtrl_len > 0:
            body = data[mtrl_abs : mtrl_abs + mtrl_len]
            records = parse_mtrl(data, mtrl_abs, mtrl_len)
            enriched: list[dict[str, Any]] = []
            for ri, rec in enumerate(records):
                slots = []
                for si, h in enumerate(rec.get("tex_hashes", [])):
                    slot = ["diffuse", "specular", "normal"][si] if si < 3 else f"slot{si}"
                    slots.append(
                        {
                            "slot": slot,
                            "hash": f"0x{h:08X}",
                            "name": local_tex.get(h) or resolver.resolve_m2(h),
                        }
                    )
                enriched.append(
                    {
                        "material_index": ri,
                        "flags": f"0x{rec.get('flags', 0):08X}",
                        "tex_count": rec.get("tex_count"),
                        "specular_power": rec.get("specular_power"),
                        "specular_intensity": rec.get("specular_intensity"),
                        "textures": slots,
                    }
                )
            entry["mtrl"] = {
                "offset": mtrl_abs,
                "length": mtrl_len,
                "preamble_u32": _hex_u32s(body, 0, min(26, _MTRL_PREAMBLE // 4)),
                "record_count": len(records),
                "records": enriched,
            }

        # First PRMT under GEOM (if any)
        for tag, u in container["chunks"]:
            if tag == b"GEOM" and u[0] != CONTAINER_SENTINEL:
                geom_base = db + int(u[0])
                # Walk GEOM child chunk table at geom_base
                if geom_base + 8 <= len(data):
                    n_child = struct.unpack_from("<I", data, geom_base + 4)[0]
                    for gi in range(min(n_child, 32)):
                        cp = geom_base + 8 + gi * CHUNK_HDR
                        if cp + CHUNK_HDR > len(data):
                            break
                        ctag, cu = read_chunk_header(data, cp)
                        if ctag == b"PRMT" and cu[1] > 0:
                            prmt = parse_prmt(data, db, int(cu[0]), int(cu[1]))
                            entry["prmt_sample"] = prmt[:6]
                            break
                break

        containers_out.append(entry)

    return {
        "size": len(data),
        "toc_entry_count": struct.unpack_from("<I", data, 0)[0] if len(data) >= 4 else 0,
        "toc_sample": toc[:20],
        "tag_counts": {
            "MTRL": data.count(b"MTRL"),
            "PRMT": data.count(b"PRMT"),
            "SCRB": data.count(b"SCRB"),
            "GEOM": data.count(b"GEOM"),
        },
        "scrb_hits": _scan_scrb_chunks(data),
        "containers": containers_out,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Probe material/texture metadata in one .block.bin")
    ap.add_argument("blob", type=Path, help="Decompressed block file")
    ap.add_argument("--out", type=Path, help="Write JSON here (default: stdout)")
    ap.add_argument("--max-containers", type=int, default=12)
    args = ap.parse_args()

    data = args.blob.read_bytes()
    doc = probe_block(data, max_containers=args.max_containers)
    doc["source"] = str(args.blob.resolve())

    text = json.dumps(doc, indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
        print(args.out)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
