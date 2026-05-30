#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a script asset-hash → Lua chunk index map from extraction outputs.

Reads the decompressed ``scripts_vz`` block (authoritative UCFX entry table) and
optionally:

  - ``resident`` block BINN references (name-only entries pointing at scripts_vz)
  - ``output/placements/pmc_lua_string_harvest.json`` (LuaQ split metadata)
  - ``tools/rainbow_table.json`` (name verification via ``hash_resolver``)

Outputs ``output/placements/script_hash_map.json`` with:

  - ``by_hash`` — keyed by ``0xXXXXXXXX`` asset hash
  - ``by_name`` — keyed by lower-case module name (``pmccon001``)
  - ``by_chunk_index`` — keyed by LuaQ split index (``lua_script_chunks.py``)
  - ``by_entry_index`` — keyed by UCFX entry index inside scripts_vz

Designed to run after ``make extract-placements`` (or standalone when block paths
are supplied explicitly). Does not touch WADs or run decompression.

Usage:
  python3 tools/script_hash_map.py
  python3 tools/script_hash_map.py \\
    --scripts-block output/extracted/batch_vz/blocks/03197_blocks__VZ__scripts_vz_P000_Q3.block.bin \\
    --out output/placements/script_hash_map.json
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

_REPO_ROOT = Path(__file__).resolve().parent.parent
if str(_REPO_ROOT / "tools") not in sys.path:
    sys.path.insert(0, str(_REPO_ROOT / "tools"))

from hash_resolver import HashResolver  # noqa: E402
from pandemic_hash import pandemic_hash_m2  # noqa: E402
from wad_patcher import (  # noqa: E402
    get_binn_script_ref_name,
    get_script_name,
    parse_block_entries,
)

SCRIPT_TYPE_HASH = 0x42498680
LUAQ_SIG = b"\x1bLua"

DEFAULT_SCRIPTS_BLOCK = (
    _REPO_ROOT / "output/extracted/batch_vz/blocks"
    / "03197_blocks__VZ__scripts_vz_P000_Q3.block.bin"
)
DEFAULT_RESIDENT_BLOCK = (
    _REPO_ROOT / "output/extracted/batch_vz/blocks"
    / "00464_blocks__VZ__resident_P000_Q3.block.bin"
)
DEFAULT_HARVEST = _REPO_ROOT / "output/placements/pmc_lua_string_harvest.json"
DEFAULT_OUT = _REPO_ROOT / "output/placements/script_hash_map.json"


def _find_luaq_offsets(data: bytes) -> list[int]:
    out: list[int] = []
    pos = 0
    while True:
        i = data.find(LUAQ_SIG, pos)
        if i < 0:
            break
        out.append(i)
        pos = i + 1
    return out


def _chunk_index_for_offset(luaq_offsets: list[int], byte_offset: int) -> int | None:
    for idx, off in enumerate(luaq_offsets):
        end = luaq_offsets[idx + 1] if idx + 1 < len(luaq_offsets) else None
        if off <= byte_offset and (end is None or byte_offset < end):
            return idx
    return None


def _load_harvest_chunks(path: Path | None) -> dict[int, dict[str, object]]:
    """Return chunk_index → harvest row from pmc_lua_string_harvest.json."""
    if path is None or not path.is_file():
        return {}
    doc = json.loads(path.read_text(encoding="utf-8"))
    out: dict[int, dict[str, object]] = {}
    for row in doc.get("chunks", []):
        idx = int(row["chunk_index"])
        out[idx] = row
    return out


def _base_record(
    *,
    name: str,
    asset_hash: int,
    entry_index: int | None,
    source: str,
    block_path: str,
) -> dict[str, object]:
    computed = pandemic_hash_m2(name) if name and not name.startswith("(") else None
    return {
        "name": name,
        "name_lower": name.lower() if name else "",
        "asset_hash": f"0x{asset_hash:08X}",
        "asset_hash_int": asset_hash,
        "computed_hash": f"0x{computed:08X}" if computed is not None else None,
        "hash_matches_name": computed == asset_hash if computed is not None else None,
        "type_hash": f"0x{SCRIPT_TYPE_HASH:08X}",
        "entry_index": entry_index,
        "luaq_chunk_index": None,
        "luaq_byte_offset": None,
        "has_inline_bytecode": False,
        "bytecode_size": None,
        "source": source,
        "block_path": block_path,
        "resident_ref": False,
        "pmc_related_strings": [],
    }


def index_scripts_block(
    block_path: Path,
    *,
    harvest_chunks: dict[int, dict[str, object]],
    resolver: HashResolver,
) -> tuple[list[dict[str, object]], list[int]]:
    """Index all script entries in the scripts_vz block."""
    data = block_path.read_bytes()
    entries = parse_block_entries(data)
    luaq_offsets = _find_luaq_offsets(data)

    records: list[dict[str, object]] = []
    for entry in entries:
        if entry.get("type_hash") not in (SCRIPT_TYPE_HASH, 0):
            # Some blocks use 0 for legacy rows; still try name extraction.
            pass

        name = get_script_name(data, entry)
        rec = _base_record(
            name=name,
            asset_hash=int(entry["hash"]),
            entry_index=int(entry["index"]),
            source="scripts_vz",
            block_path=str(block_path),
        )

        chunk = data[entry["offset"] : entry["offset"] + entry["size"] - 8]
        luaq_rel = chunk.find(LUAQ_SIG)
        if luaq_rel >= 0:
            abs_off = entry["offset"] + luaq_rel
            rec["has_inline_bytecode"] = True
            rec["luaq_byte_offset"] = abs_off
            rec["bytecode_size"] = len(chunk) - luaq_rel
            rec["luaq_chunk_index"] = _chunk_index_for_offset(luaq_offsets, abs_off)
        else:
            ref_name = get_binn_script_ref_name(data, entry)
            if ref_name:
                rec["name"] = ref_name
                rec["name_lower"] = ref_name.lower()

        if rec["luaq_chunk_index"] is not None:
            harvest = harvest_chunks.get(int(rec["luaq_chunk_index"]))
            if harvest:
                rec["pmc_related_strings"] = harvest.get("pmc_related_strings", [])

        if name.startswith("(") or name.startswith("unknown_"):
            resolved = resolver.resolve_m2(int(entry["hash"]))
            if resolved:
                rec["name"] = resolved
                rec["name_lower"] = resolved.lower()
                rec["computed_hash"] = f"0x{pandemic_hash_m2(resolved):08X}"
                rec["hash_matches_name"] = pandemic_hash_m2(resolved) == int(entry["hash"])

        records.append(rec)

    return records, luaq_offsets


def index_resident_refs(
    block_path: Path,
    *,
    scripts_by_name: dict[str, dict[str, object]],
) -> list[dict[str, object]]:
    """Index resident BINN script-reference rows (no inline LuaQ)."""
    if not block_path.is_file():
        return []

    data = block_path.read_bytes()
    entries = parse_block_entries(data)
    refs: list[dict[str, object]] = []

    for entry in entries:
        if entry.get("type_hash") != SCRIPT_TYPE_HASH:
            continue
        ref_name = get_binn_script_ref_name(data, entry)
        if not ref_name:
            continue

        rec = _base_record(
            name=ref_name,
            asset_hash=int(entry["hash"]),
            entry_index=int(entry["index"]),
            source="resident_binn_ref",
            block_path=str(block_path),
        )
        rec["resident_ref"] = True

        chunk = data[entry["offset"] : entry["offset"] + entry["size"] - 8]
        if len(chunk) >= 4:
            import struct

            rec["bytecode_size"] = struct.unpack_from("<I", chunk, 0)[0]

        target = scripts_by_name.get(ref_name.lower())
        if target:
            rec["scripts_vz_entry_index"] = target.get("entry_index")
            rec["luaq_chunk_index"] = target.get("luaq_chunk_index")
            if target.get("luaq_byte_offset") is not None:
                rec["luaq_byte_offset"] = target["luaq_byte_offset"]

        refs.append(rec)

    return refs


def build_map(
    *,
    scripts_block: Path,
    resident_block: Path | None,
    harvest_json: Path | None,
    resolver: HashResolver,
) -> dict[str, object]:
    if not scripts_block.is_file():
        raise FileNotFoundError(f"scripts block not found: {scripts_block}")

    harvest_chunks = _load_harvest_chunks(harvest_json)
    scripts_records, luaq_offsets = index_scripts_block(
        scripts_block,
        harvest_chunks=harvest_chunks,
        resolver=resolver,
    )

    by_name: dict[str, dict[str, object]] = {}
    by_hash: dict[str, dict[str, object]] = {}
    by_entry: dict[str, dict[str, object]] = {}
    by_chunk: dict[str, dict[str, object]] = {}

    mismatches: list[dict[str, object]] = []
    for rec in scripts_records:
        by_hash[str(rec["asset_hash"])] = rec
        if rec["name_lower"]:
            by_name[str(rec["name_lower"])] = rec
        if rec["entry_index"] is not None:
            by_entry[str(rec["entry_index"])] = rec
        if rec["luaq_chunk_index"] is not None:
            by_chunk[str(rec["luaq_chunk_index"])] = rec
        if rec["hash_matches_name"] is False:
            mismatches.append(
                {
                    "name": rec["name"],
                    "asset_hash": rec["asset_hash"],
                    "computed_hash": rec["computed_hash"],
                }
            )

    resident_refs = index_resident_refs(
        resident_block,
        scripts_by_name=by_name,
    ) if resident_block else []

    return {
        "version": 1,
        "scripts_block": str(scripts_block),
        "resident_block": str(resident_block) if resident_block and resident_block.is_file() else None,
        "harvest_json": str(harvest_json) if harvest_json and harvest_json.is_file() else None,
        "luaq_signature_count": len(luaq_offsets),
        "scripts_vz_entry_count": len(scripts_records),
        "resident_ref_count": len(resident_refs),
        "hash_name_mismatches": mismatches,
        "by_hash": by_hash,
        "by_name": by_name,
        "by_entry_index": by_entry,
        "by_chunk_index": by_chunk,
        "resident_refs": resident_refs,
    }


def _self_test() -> int:
    """Validate hash computation against known script names (no block I/O)."""
    cases = [
        ("pmccon001", 0x97DFCCC2),
        ("wifmissiondata", 0xA998325D),
        ("wifmissionflow", 0xCE4166ED),
    ]
    resolver = HashResolver.load()
    ok = True
    for name, expected in cases:
        got = pandemic_hash_m2(name)
        if got != expected:
            print(f"FAIL hash {name}: got 0x{got:08X}, expected 0x{expected:08X}", file=sys.stderr)
            ok = False
        resolved = resolver.resolve_m2(expected)
        if resolved and resolved.lower() != name.lower():
            print(f"WARN rainbow table alias for 0x{expected:08X}: {resolved}", file=sys.stderr)
    if ok:
        print("self-test: PASS (hash + rainbow table spot checks)")
    return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser(description="Build script asset-hash → Lua chunk index map")
    ap.add_argument(
        "--scripts-block",
        type=Path,
        default=DEFAULT_SCRIPTS_BLOCK,
        help="Decompressed scripts_vz block .bin",
    )
    ap.add_argument(
        "--resident-block",
        type=Path,
        default=DEFAULT_RESIDENT_BLOCK,
        help="Decompressed resident block .bin (BINN refs); optional",
    )
    ap.add_argument(
        "--harvest-json",
        type=Path,
        default=DEFAULT_HARVEST,
        help="pmc_lua_string_harvest.json from lua_script_chunks.py",
    )
    ap.add_argument(
        "--rainbow-table",
        type=Path,
        default=_REPO_ROOT / "tools/rainbow_table.json",
        help="Rainbow table for unresolved name annotation",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=DEFAULT_OUT,
        help="Output JSON path",
    )
    ap.add_argument(
        "--no-resident",
        action="store_true",
        help="Skip resident block indexing",
    )
    ap.add_argument(
        "--self-test",
        action="store_true",
        help="Run hash spot checks and exit (no block I/O)",
    )
    args = ap.parse_args()

    if args.self_test:
        return _self_test()

    resolver = HashResolver.load(args.rainbow_table)
    resident = None if args.no_resident else args.resident_block

    try:
        doc = build_map(
            scripts_block=args.scripts_block,
            resident_block=resident,
            harvest_json=args.harvest_json,
            resolver=resolver,
        )
    except FileNotFoundError as exc:
        print(f"error: {exc}", file=sys.stderr)
        print(
            "hint: run make extract-placements OUTPUT=./output first, or pass --scripts-block",
            file=sys.stderr,
        )
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    print(f"Wrote {args.out}")
    print(
        f"  scripts_vz entries: {doc['scripts_vz_entry_count']}, "
        f"LuaQ signatures: {doc['luaq_signature_count']}, "
        f"resident refs: {doc['resident_ref_count']}, "
        f"hash mismatches: {len(doc['hash_name_mismatches'])}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
