#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse the Mercenaries 2 global fxdict singleton (INFO+DICT) to JSON.

The fxdict lives in the always-loaded ``resident`` block (ASET type_id 25,
type_hash ``0xFA46D8A8``, asset name hash ``pandemic_hash_m2("fx")``).

Usage::

    .venv/Scripts/python.exe tools/fxdict_parser.py --wad game-files/pc-game-vz.wad
    .venv/Scripts/python.exe tools/fxdict_parser.py --block-bin path/to/resident.block.bin
    .venv/Scripts/python.exe tools/fxdict_parser.py --block-bin ... --out output/_scratch/fx_probe/fxdict.json
"""

from __future__ import annotations

import argparse
import json
import mmap
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from fxdict_codec import (  # noqa: E402
    FXDICT_ASSET_HASH,
    FXDICT_TYPE_HASH,
    find_block_entry,
    parse_fxdict_ucfx,
)
from pandemic_hash import pandemic_hash_m2  # noqa: E402

DEFAULT_WAD = _TOOLS.parent / "game-files" / "pc-game-vz.wad"

# Niagara mapping hypotheses (unverified string names — hash-only in retail data).
_NIAGARA_GUESS_BY_HASH: dict[int, tuple[str, str]] = {
    # Heuristic buckets from default/min patterns across the 630-entry table.
    0x80115B9C: ("Particle.Size", "Sprite size scale (default ~0.78)"),
    0x80AF9DC4: ("Spawn.Rate", "Emission rate / bursts per second"),
    0x80B41AF2: ("Particle.Lifetime", "Seconds before particle death"),
    0x80EF95DF: ("Particle.Velocity", "Initial speed magnitude"),
    0x81658159: ("Particle.Drag", "Velocity damping over life"),
    0x81790911: ("Particle.GravityScale", "Gravity multiplier"),
    0x820492CF: ("Particle.Rotation", "Initial rotation / spin"),
    0x82FC873E: ("Particle.Alpha", "Opacity (default ~0.9)"),
    0x831F1980: ("Particle.ColorIntensity", "Color multiplier"),
    0x8410A32A: ("Material.TextureIndex", "Texture slot / atlas index (referenced from effect TEXT)"),
}


def _load_rainbow_reverse() -> dict[int, list[str]]:
    path = _TOOLS / "rainbow_table.json"
    if not path.is_file():
        return {}
    doc = json.loads(path.read_text(encoding="utf-8"))
    table = doc.get("pandemic_hash_m2", {})
    rev: dict[int, list[str]] = {}
    for hex_key, names in table.items():
        try:
            h = int(hex_key, 16)
        except ValueError:
            continue
        if isinstance(names, list):
            rev[h] = [str(n) for n in names[:5]]
    return rev


def _load_resident_from_wad(wad_path: Path) -> tuple[bytes, str]:
    from sges_decompress import decompress_sges_block
    from wad_patcher import find_data_chunk, get_block_boundaries, load_wad_paths

    paths = load_wad_paths(wad_path)
    resident_indices = [
        i
        for i, p in enumerate(paths)
        if "resident" in p.lower() and "resident2" not in p.lower() and "sound_" not in p.lower()
    ]
    if not resident_indices:
        raise FileNotFoundError(f"no resident block path in {wad_path}")
    idx = resident_indices[0]
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        dc = find_data_chunk(wad_path)
        s, e = get_block_boundaries(mm, dc.offset, dc.size)[idx]
        data = decompress_sges_block(mm, s, e)
        mm.close()
    return data, paths[idx]


def _niagara_hypothesis(param_hash: int, default: float, value_c: float) -> dict[str, str]:
    if param_hash in _NIAGARA_GUESS_BY_HASH:
        name, note = _NIAGARA_GUESS_BY_HASH[param_hash]
        return {"niagara_guess": name, "note": note, "confidence": "hypothesis"}
    if abs(value_c - 0.03125) < 1e-6:
        return {
            "niagara_guess": "User.MinScalar",
            "note": "value_c is 1/32 on many rows — likely normalized min bound",
            "confidence": "hypothesis",
        }
    if 0.0 <= default <= 1.0:
        return {
            "niagara_guess": "User.Float",
            "note": "Unit-range default; map to Niagara user float",
            "confidence": "hypothesis",
        }
    return {
        "niagara_guess": "User.Float",
        "note": "Unclassified scalar; hash not in rainbow table",
        "confidence": "hypothesis",
    }


def build_fxdict_report(
    data: bytes,
    *,
    source: str,
    rainbow: dict[int, list[str]] | None = None,
) -> dict[str, Any]:
    rainbow = rainbow if rainbow is not None else _load_rainbow_reverse()
    hit = find_block_entry(
        data, type_hash=FXDICT_TYPE_HASH, asset_hash=FXDICT_ASSET_HASH
    ) or find_block_entry(data, type_hash=FXDICT_TYPE_HASH)
    if hit is None:
        return {
            "version": 1,
            "source": source,
            "error": "fxdict entry not found",
            "type_hash": f"0x{FXDICT_TYPE_HASH:08X}",
            "expected_asset_hash": f"0x{FXDICT_ASSET_HASH:08X}",
        }

    idx, asset_hash, type_hash, size, body = hit
    parsed = parse_fxdict_ucfx(body)
    params_out: list[dict[str, Any]] = []
    for p in parsed["parameters"]:
        names = rainbow.get(p.name_hash, [])
        row = p.to_dict()
        row["resolved_names"] = names
        row["niagara"] = _niagara_hypothesis(p.name_hash, p.default, p.value_c)
        params_out.append(row)

    # Top 10 by |default| for quick review (often the visually dominant scalars).
    top10 = sorted(parsed["parameters"], key=lambda p: abs(p.default), reverse=True)[:10]
    top10_out = []
    for p in top10:
        guess = _niagara_hypothesis(p.name_hash, p.default, p.value_c)
        top10_out.append(
            {
                "index": p.index,
                "name_hash": f"0x{p.name_hash:08X}",
                "default": round(p.default, 6),
                "value_b": round(p.value_b, 6),
                "value_c": round(p.value_c, 6),
                "resolved_names": rainbow.get(p.name_hash, []),
                **guess,
            }
        )

    return {
        "version": 1,
        "source": source,
        "type_hash": f"0x{type_hash:08X}",
        "asset_hash": f"0x{asset_hash:08X}",
        "asset_name_hash_guess": "fx",
        "asset_name_hash_verified": asset_hash == FXDICT_ASSET_HASH,
        "pandemic_hash_m2_fx": f"0x{pandemic_hash_m2('fx'):08X}",
        "block_entry_index": idx,
        "body_size": size,
        "entry_count": parsed["entry_count"],
        "dict_bytes": parsed["dict_bytes"],
        "dict_trailing_bytes": parsed["dict_trailing_bytes"],
        "parameters": params_out,
        "top10_by_default_magnitude": top10_out,
        "chunks": parsed["chunks"],
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Parse fxdict INFO+DICT from resident block")
    ap.add_argument("--block-bin", type=Path, help="Decompressed resident .block.bin")
    ap.add_argument("--wad", type=Path, help="Retail FFCS .wad (decompresses resident only)")
    ap.add_argument(
        "--out",
        type=Path,
        default=_TOOLS.parent / "output" / "_scratch" / "fx_probe" / "fxdict.json",
        help="JSON output path",
    )
    args = ap.parse_args()

    if args.block_bin is not None:
        path = args.block_bin.resolve()
        if not path.is_file():
            print(f"error: block not found: {path}", file=sys.stderr)
            return 1
        data = path.read_bytes()
        source = str(path)
    elif args.wad is not None:
        wad = args.wad.resolve()
        if not wad.is_file():
            print(f"error: wad not found: {wad}", file=sys.stderr)
            return 1
        data, path_str = _load_resident_from_wad(wad)
        source = f"{wad} :: {path_str}"
    elif DEFAULT_WAD.is_file():
        data, path_str = _load_resident_from_wad(DEFAULT_WAD)
        source = f"{DEFAULT_WAD} :: {path_str}"
    else:
        print("error: pass --block-bin or --wad", file=sys.stderr)
        return 1

    doc = build_fxdict_report(data, source=source)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {args.out} ({doc.get('entry_count', 0)} parameters)", file=sys.stderr)
    if doc.get("error"):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
