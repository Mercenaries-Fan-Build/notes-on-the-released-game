#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Parse Mercenaries 2 PC save-game .profile files into structured JSON for tooling / UE5 reference.

Harvested ``vehicle_tokens``, ``support_tokens``, ``localization_key_like``, ``mission_ids``, etc. are full sorted lists
(no truncation). ``tools/ue5_export.py`` merges them with ``paths.txt`` and other sources for
``ue_folder`` / ``label_hint`` when bundling for Unreal.
"""

from __future__ import annotations

import argparse
import json
import re
import struct
import zlib
from pathlib import Path
from typing import Any

# Lua payload starts after zlib header at this offset (matches retail saves).
ZLIB_OFFSET_DEFAULT = 1128


def read_utf16_le_z(data: bytes, start: int, max_chars: int = 128) -> str:
    out = []
    i = start
    while i + 1 < len(data) and len(out) < max_chars:
        code = struct.unpack_from("<H", data, i)[0]
        i += 2
        if code == 0:
            break
        out.append(chr(code))
    return "".join(out)


def parse_header(data: bytes) -> dict[str, Any]:
    if len(data) < ZLIB_OFFSET_DEFAULT:
        raise ValueError(f"file too short ({len(data)} bytes)")
    checksum = struct.unpack_from("<I", data, 0)[0]
    version = struct.unpack_from("<I", data, 4)[0]
    data_size = struct.unpack_from("<I", data, 8)[0]
    unk_c = struct.unpack_from("<I", data, 0x0C)[0]
    unk_10 = struct.unpack_from("<I", data, 0x10)[0]
    n_time = struct.unpack_from("<I", data, 0x14)[0]
    n_cash = struct.unpack_from("<I", data, 0x18)[0]
    n_fuel = struct.unpack_from("<I", data, 0x1C)[0]
    unk_20 = struct.unpack_from("<I", data, 0x20)[0]
    unix_ts = struct.unpack_from("<I", data, 0x24)[0]
    last_mission = data[0x2C : 0x3C].split(b"\x00", 1)[0].decode("ascii", errors="replace").strip()
    flags_4c = struct.unpack_from("<I", data, 0x4C)[0]
    costume_idx = data[0x24A] if len(data) > 0x24A else None

    return {
        "checksum_hex": f"0x{checksum:08X}",
        "version": version,
        "data_size_field": data_size,
        "unknown_0x0C": unk_c,
        "unknown_0x10": unk_10,
        "n_time_elapsed_seconds": n_time,
        "n_cash": n_cash,
        "n_fuel": n_fuel,
        "unknown_0x20": unk_20,
        "unix_timestamp": unix_ts,
        "s_last_mission_name_ascii": last_mission,
        "flags_0x4C_hex": f"0x{flags_4c:08X}",
        "character_costume_index": costume_idx,
        "reference_name_utf16": read_utf16_le_z(data, 0x20A, 64) if len(data) > 0x220 else "",
    }


def decompress_lua(data: bytes, zlib_off: int = ZLIB_OFFSET_DEFAULT) -> str:
    raw = zlib.decompress(data[zlib_off:])
    return raw.decode("utf-8", errors="replace")


_RE_MISSION = re.compile(r'"([A-Za-z]{3}(?:Con|Job|Intro)\d{3}(?:_Milestone\d)?)"')
_RE_GUID = re.compile(r"Sys\.StringToGuid\s*\(\s*['\"]?(0x[0-9A-Fa-f]{8})['\"]?\s*\)")
_RE_VEHICLE_BRACKET = re.compile(r"\[vehicle\.([a-zA-Z0-9_]+)\]")
_RE_SUPPORT_INNER = re.compile(r"\[support\.([^\]]+)\]")
_RE_LAYER = re.compile(r'"vz_state_[^"]+"')
_RE_LOCALIZE = re.compile(r"\[([A-Za-z][A-Za-z0-9_.]+)\]")


def harvest_from_lua(lua: str) -> dict[str, Any]:
    """Regex harvest from decompressed Lua. Each ``*_`` list is complete; ``len(list) == *_count``."""
    missions = sorted(set(_RE_MISSION.findall(lua)))
    guids = sorted(set(_RE_GUID.findall(lua)))
    vehicles = sorted(set(_RE_VEHICLE_BRACKET.findall(lua)))
    support = sorted(set(_RE_SUPPORT_INNER.findall(lua)))
    localize_keys = sorted(set(_RE_LOCALIZE.findall(lua)))
    layers = sorted(set(_RE_LAYER.findall(lua)))
    # Rough faction prefixes from mission IDs and known names
    factions = sorted({m[:3] for m in missions if len(m) >= 3})
    return {
        "mission_ids": missions,
        "mission_ids_count": len(missions),
        "sys_string_to_guid_hex": guids,
        "sys_string_to_guid_hex_count": len(guids),
        "vehicle_tokens": vehicles,
        "vehicle_tokens_count": len(vehicles),
        "support_tokens": support,
        "support_tokens_count": len(support),
        "localization_key_like": localize_keys,
        "localization_key_like_count": len(localize_keys),
        "vz_layer_strings": layers,
        "vz_layer_strings_count": len(layers),
        "faction_prefixes_from_missions": factions,
    }


def parse_profile(path: Path, zlib_off: int = ZLIB_OFFSET_DEFAULT) -> dict[str, Any]:
    data = path.read_bytes()
    header = parse_header(data)
    lua_text = decompress_lua(data, zlib_off)
    harvested = harvest_from_lua(lua_text)
    return {
        "source_file": str(path),
        "header": header,
        "lua_decompressed_chars": len(lua_text),
        "harvested": harvested,
        "lua_sample_first_4k": lua_text[:4096],
        "note": "Full Lua not exported by default; use --embed-lua for complete table text.",
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 .profile save parser → JSON knowledge extract")
    ap.add_argument("profiles", nargs="+", type=Path, help=".profile save files")
    ap.add_argument("--out", type=Path, help="Write combined JSON (single file)")
    ap.add_argument("--zlib-offset", type=int, default=ZLIB_OFFSET_DEFAULT, help=f"Byte offset of zlib stream (default {ZLIB_OFFSET_DEFAULT})")
    ap.add_argument("--embed-lua", action="store_true", help="Include full decompressed Lua text (large)")
    args = ap.parse_args()

    results = []
    for p in args.profiles:
        doc = parse_profile(p, args.zlib_offset)
        if args.embed_lua:
            data = p.read_bytes()
            doc["lua_full"] = decompress_lua(data, args.zlib_offset)
            doc.pop("lua_sample_first_4k", None)
        results.append(doc)

    text = json.dumps(results if len(results) > 1 else results[0], indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
        print(f"Wrote {args.out}")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
