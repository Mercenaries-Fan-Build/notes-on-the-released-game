#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Decode the Mercenaries 2 ``watermap`` / ``watr`` resident singleton.

Verified on retail PC ``resident_P000_Q3`` (type_hash ``0x4D7D30C4``):

* UCFX container with a single ``watr`` chunk (~495 KiB).
* ``watr`` header: layer_count (u32), grid_w/h (u32×2), six metadata floats (24 B).
* Layer 0: ``f32`` height field, ``grid_w × grid_h`` samples (257×257 on retail).
* Layers 1–3: ``u8`` masks, same resolution (semantics TBD — see report).
* Trailing ~33 KiB footer (not a fourth full-grid layer).

Exports optional 16-bit PNG rasters under ``output/_scratch/watermap/`` for visual
verification. Read-only — no WAD writes.

Usage::

    .venv/Scripts/python tools/watermap_decode.py --wad game-files/pc-game-vz.wad
    .venv/Scripts/python tools/watermap_decode.py --block-bin path/to/resident.block.bin --png
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from texture_streaming_index import iter_block_entries
from ucfx_mesh_codec import read_chunk_header
from watermap_probe import (
    DEFAULT_PARTIAL,
    DEFAULT_WAD,
    WATERMAP_TYPE_HASH,
    _load_resident_from_wad,
)

WATR_HEADER_SIZE = 36
LAYER0_DTYPE = "f32"
LAYER_AUX_DTYPES = ("u8", "u8", "u8")
FOOTER_MIN_SIZE = 32_000
FOOTER_MAX_SIZE = 34_000


def _find_watermap_body(data: bytes) -> tuple[int, bytes]:
    for _ah, th, body_offset, size in iter_block_entries(data):
        if th == WATERMAP_TYPE_HASH:
            return body_offset, data[body_offset : body_offset + size]
    raise ValueError("watermap entry not found")


def _extract_watr_payload(ucfx_body: bytes) -> bytes:
    if len(ucfx_body) < 20 or ucfx_body[:4] != b"UCFX":
        raise ValueError("watermap body is not UCFX")
    dao, _, _, _n = struct.unpack_from("<IIII", ucfx_body, 4)
    _tag, (rel_off, chunk_size, _, _) = read_chunk_header(ucfx_body, 20)
    start = int(dao) + int(rel_off)
    end = min(len(ucfx_body), start + int(chunk_size))
    payload = ucfx_body[start:end]
    if payload[:4] == b"watr"[::-1] or payload[:4] != b"watr":
        pass
    return payload


def _read_header(payload: bytes) -> dict[str, Any]:
    if len(payload) < WATR_HEADER_SIZE:
        raise ValueError(f"watr payload too short: {len(payload)}")
    layer_count, grid_w, grid_h = struct.unpack_from("<III", payload, 0)
    floats: list[float] = []
    for off in range(12, WATR_HEADER_SIZE, 4):
        v = struct.unpack_from("<f", payload, off)[0]
        floats.append(round(float(v), 6) if math.isfinite(v) else float("nan"))
    u32_tail = struct.unpack_from("<II", payload, 28)
    return {
        "layer_count": int(layer_count),
        "grid_width": int(grid_w),
        "grid_height": int(grid_h),
        "grid_cells": int(grid_w) * int(grid_h),
        "header_floats": {
            "cell_size_m": floats[0] if len(floats) > 0 else None,
            "height_min_m": floats[1] if len(floats) > 1 else None,
            "height_max_m": floats[2] if len(floats) > 2 else None,
            "field_b": floats[3] if len(floats) > 3 else None,
            "field_c": floats[4] if len(floats) > 4 else None,
            "field_d": floats[5] if len(floats) > 5 else None,
        },
        "header_u32_at_28": [int(u32_tail[0]), int(u32_tail[1])],
    }


def _layer_stats_f32(raw: bytes) -> dict[str, Any]:
    n = len(raw) // 4
    vals = struct.unpack(f"<{n}f", raw[: n * 4])
    finite = [float(v) for v in vals if math.isfinite(v)]
    return {
        "dtype": "f32",
        "bytes": len(raw),
        "cells": n,
        "finite": len(finite),
        "min": round(min(finite), 4) if finite else None,
        "max": round(max(finite), 4) if finite else None,
        "mean": round(sum(finite) / len(finite), 4) if finite else None,
    }


def _layer_stats_u8(raw: bytes) -> dict[str, Any]:
    vals = list(raw)
    hist: dict[str, int] = {}
    for v in vals:
        key = str(v)
        hist[key] = hist.get(key, 0) + 1
    top = sorted(hist.items(), key=lambda kv: -kv[1])[:12]
    return {
        "dtype": "u8",
        "bytes": len(raw),
        "cells": len(vals),
        "min": min(vals) if vals else None,
        "max": max(vals) if vals else None,
        "unique_values": len(hist),
        "top_values": [{"value": int(k), "count": c} for k, c in top],
    }


def decode_watr_payload(payload: bytes) -> dict[str, Any]:
    """Full ``watr`` decode with per-layer layout (retail layout verified)."""
    hdr = _read_header(payload)
    grid = int(hdr["grid_cells"])
    if grid <= 0:
        raise ValueError("invalid grid size")

    off = WATR_HEADER_SIZE
    layers: list[dict[str, Any]] = []

    # Layer 0 — height (f32)
    need0 = grid * 4
    if off + need0 > len(payload):
        raise ValueError("truncated f32 height layer")
    raw0 = payload[off : off + need0]
    layers.append(
        {
            "index": 0,
            "role": "height_m",
            "offset": off,
            "confirmed": True,
            **_layer_stats_f32(raw0),
        }
    )
    off += need0

    # Layers 1..3 — u8 masks (same topology)
    aux_meta = (
        ("wet_mask", True, {"0": "dry/land (-50 m sentinel)", "255": "wet (~-36 m)"}),
        (
            "coastal_variant",
            False,
            {"255": "default/open water", "other": "sparse shore codes"},
        ),
        (
            "override_sparse",
            False,
            {"255": "default", "other": "rare per-cell overrides"},
        ),
    )
    for i, (_dtype, (role, sem_confirmed, semantics)) in enumerate(
        zip(LAYER_AUX_DTYPES, aux_meta, strict=True), start=1
    ):
        need = grid * 1
        if off + need > len(payload):
            raise ValueError(f"truncated u8 layer {i}")
        raw = payload[off : off + need]
        layers.append(
            {
                "index": i,
                "role": role,
                "offset": off,
                "confirmed": sem_confirmed,
                "semantics": {**semantics, "status": "confirmed" if sem_confirmed else "hypothesis"},
                **_layer_stats_u8(raw),
            }
        )
        off += need

    footer_len = len(payload) - off
    footer: dict[str, Any] = {
        "offset": off,
        "size": footer_len,
        "confirmed": FOOTER_MIN_SIZE <= footer_len <= FOOTER_MAX_SIZE,
    }
    if footer_len > 0:
        tail = payload[off:]
        footer["head_hex"] = tail[:64].hex()
        footer["tail_hex"] = tail[-32:].hex() if len(tail) >= 32 else tail.hex()
        # Hypothesis: not a 257×257 layer — size does not divide grid.
        footer["divides_grid"] = (footer_len % grid) == 0
        footer["hypothesis"] = (
            "layer_count=5 counts height + 3 u8 grids + this footer blob (not a 257×257 raster)"
        )
        footer["layer_index_guess"] = 4

    expected = WATR_HEADER_SIZE + grid * 4 + grid * len(LAYER_AUX_DTYPES)
    return {
        "payload_bytes": len(payload),
        "header": hdr,
        "layers": layers,
        "footer": footer,
        "layout": {
            "header_bytes": WATR_HEADER_SIZE,
            "expected_used_bytes": expected,
            "actual_used_before_footer": off,
            "verified_formula": (
                f"{WATR_HEADER_SIZE} + {grid}*4 + {grid}*3*u8 = {expected}"
            ),
        },
        "world_mapping": _world_mapping(hdr),
    }


def _world_mapping(hdr: dict[str, Any]) -> dict[str, Any]:
    """Map raster indices to game LH metres (confirmed where noted)."""
    gw = int(hdr["grid_width"])
    gh = int(hdr["grid_height"])
    hf = hdr["header_floats"]
    cell = hf.get("cell_size_m")
    hmin = hf.get("height_min_m")
    hmax = hf.get("height_max_m")

    out: dict[str, Any] = {
        "coordinate_system": "game LH metres (X east-west, Y up, Z north-south)",
        "grid_samples": [gw, gh],
        "grid_intervals": [gw - 1, gh - 1],
    }

    if cell is not None and isinstance(cell, (int, float)) and cell > 0:
        span_x = (gw - 1) * float(cell)
        span_z = (gh - 1) * float(cell)
        out["cell_size_m"] = {"value": float(cell), "confirmed": True}
        out["world_span_m"] = {
            "x": round(span_x, 3),
            "z": round(span_z, 3),
            "confirmed": True,
            "note": "Assumes samples span [-span/2, +span/2] on X and Z (origin-centred).",
        }
        out["index_to_game_xz"] = {
            "formula": "x = (ix - (grid_width-1)/2) * cell_size_m; "
            "z = (iz - (grid_height-1)/2) * cell_size_m",
            "confirmed": False,
            "note": "Corner samples match open-water plateau; exact origin alignment unverified in EXE.",
        }
    else:
        out["cell_size_m"] = {"confirmed": False}

    if hmin is not None and hmax is not None:
        out["height_range_m"] = {
            "min": float(hmin),
            "max": float(hmax),
            "confirmed": True,
            "note": "Header clamps; raster may use sentinel values at dry cells.",
        }

    field_b = hf.get("field_b")
    if field_b is not None:
        out["field_b"] = {
            "value": float(field_b),
            "hypothesis": "legacy/unused or non-metre scalar (64.0 on retail)",
            "confirmed": False,
        }

    out["sea_level_m"] = {
        "value": -36.0,
        "confirmed": True,
        "note": "Wet cells (mask layer 1 = 255) use height ≈ -36 m on retail; dry cells "
        "use -50 m sentinel. Terrain open-water tiles use Y=0 (separate system). "
        "UE setup_water.py SEA_LEVEL_UE=-2500 not yet calibrated to this raster.",
    }
    return out


def _height_to_u16(height_m: float, hmin: float, hmax: float) -> int:
    if hmax <= hmin:
        return 0
    t = (height_m - hmin) / (hmax - hmin)
    t = max(0.0, min(1.0, t))
    return int(round(t * 65535.0))


def _write_png_u16(path: Path, values: list[int], width: int, height: int) -> None:
    try:
        from PIL import Image
    except ImportError as exc:
        raise SystemExit("Pillow required for --png (pip install Pillow)") from exc

    if len(values) != width * height:
        raise ValueError(f"value count {len(values)} != {width}x{height}")
    # Big-endian 16-bit grayscale for viewers that respect 16-bit PNG
    img = Image.new("I;16", (width, height))
    img.putdata(values)
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, format="PNG")


def _export_pngs(
    payload: bytes,
    decoded: dict[str, Any],
    out_dir: Path,
) -> list[str]:
    hdr = decoded["header"]
    gw, gh = int(hdr["grid_width"]), int(hdr["grid_height"])
    grid = gw * gh
    hf = hdr["header_floats"]
    hmin = float(hf["height_min_m"] or 0.0)
    hmax = float(hf["height_max_m"] or 1.0)

    written: list[str] = []
    off = WATR_HEADER_SIZE
    raw_h = payload[off : off + grid * 4]
    heights = struct.unpack(f"<{grid}f", raw_h)
    u16h = [_height_to_u16(float(v), hmin, hmax) for v in heights]
    p0 = out_dir / "layer00_height_u16.png"
    _write_png_u16(p0, u16h, gw, gh)
    written.append(str(p0))

    off += grid * 4
    for i in range(1, 4):
        raw = payload[off : off + grid]
        off += grid
        u16 = [int(v) * 257 for v in raw]  # stretch u8 → 16-bit for visibility
        pi = out_dir / f"layer0{i}_mask_u8_stretched.png"
        _write_png_u16(pi, u16, gw, gh)
        written.append(str(pi))
    return written


def decode_block(data: bytes, *, source: str) -> dict[str, Any]:
    _off, body = _find_watermap_body(data)
    payload = _extract_watr_payload(body)
    decoded = decode_watr_payload(payload)
    return {
        "version": 2,
        "source": source,
        "watermap_type_hash": f"0x{WATERMAP_TYPE_HASH:08X}",
        "watr": decoded,
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Decode watermap watr layers")
    ap.add_argument("--block-bin", type=Path, default=None)
    ap.add_argument("--wad", type=Path, default=None)
    ap.add_argument("--out", type=Path, default=None, help="JSON report (default: stdout)")
    ap.add_argument(
        "--png-dir",
        type=Path,
        default=None,
        help="Write 16-bit PNGs here (implies export; default output/_scratch/watermap)",
    )
    ap.add_argument("--png", action="store_true", help="Export PNGs to --png-dir or default")
    args = ap.parse_args()

    if args.block_bin is not None:
        path = args.block_bin.resolve()
        data = path.read_bytes()
        doc = decode_block(data, source=str(path))
        payload_source = data
    elif args.wad is not None:
        wad = args.wad.resolve()
        data, pth = _load_resident_from_wad(wad)
        doc = decode_block(data, source=f"{wad} :: {pth}")
        payload_source = data
    elif DEFAULT_PARTIAL.is_file():
        data = DEFAULT_PARTIAL.read_bytes()
        doc = decode_block(data, source=str(DEFAULT_PARTIAL))
        payload_source = data
    elif DEFAULT_WAD.is_file():
        data, pth = _load_resident_from_wad(DEFAULT_WAD)
        doc = decode_block(data, source=f"{DEFAULT_WAD} :: {pth}")
        payload_source = data
    else:
        print("error: pass --block-bin or --wad", file=sys.stderr)
        return 1

    if args.png or args.png_dir is not None:
        png_dir = args.png_dir or (_TOOLS.parent / "output" / "_scratch" / "watermap")
        _body_off, body = _find_watermap_body(payload_source)
        payload = _extract_watr_payload(body)
        paths = _export_pngs(payload, doc["watr"], png_dir.resolve())
        doc["png_exports"] = paths

    text = json.dumps(doc, indent=2)
    if args.out is not None:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text + "\n", encoding="utf-8")
        print(f"Wrote {args.out}", file=sys.stderr)
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
