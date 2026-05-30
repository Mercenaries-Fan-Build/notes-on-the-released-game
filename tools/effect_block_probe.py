#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Probe the Mercenaries 2 ``effects`` block (314 effect UCFX entries).

Reads a decompressed ``effects_P000_Q3`` block or decompresses it from a retail
``.wad`` via the same path resolution as ``extract_single_block.py``.

Usage::

    .venv/Scripts/python.exe tools/effect_block_probe.py --wad game-files/pc-game-vz.wad
    .venv/Scripts/python.exe tools/effect_block_probe.py --block-bin output/_scratch/fx_probe/.../effects.block.bin
"""

from __future__ import annotations

import argparse
import json
import mmap
import sys
from collections import Counter
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from fxdict_codec import EFFECT_TYPE_HASH, iter_typed_entries, parse_effect_ucfx  # noqa: E402
from texture_streaming_index import iter_block_entries  # noqa: E402

DEFAULT_WAD = _TOOLS.parent / "game-files" / "pc-game-vz.wad"
EFFECTS_PATH_FRAGMENT = "effects_p000_q3"


def _load_effects_from_wad(wad_path: Path) -> tuple[bytes, str]:
    from sges_decompress import decompress_sges_block
    from wad_patcher import find_data_chunk, get_block_boundaries, load_wad_paths

    paths = load_wad_paths(wad_path)
    key = EFFECTS_PATH_FRAGMENT
    matches = [i for i, p in enumerate(paths) if key in p.replace("\\", "/").lower()]
    if len(matches) != 1:
        raise FileNotFoundError(
            f"expected one effects block path, got {len(matches)}: "
            f"{[paths[i] for i in matches[:5]]}"
        )
    idx = matches[0]
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        dc = find_data_chunk(wad_path)
        s, e = get_block_boundaries(mm, dc.offset, dc.size)[idx]
        data = decompress_sges_block(mm, s, e)
        mm.close()
    return data, paths[idx]


def probe_effects_block(
    data: bytes,
    *,
    source: str,
    max_detail: int = 5,
) -> dict[str, Any]:
    entries = iter_block_entries(data)
    type_hist = Counter(th for _ah, th, _off, _sz in entries)

    effect_sizes: list[int] = []
    emit_u2 = Counter()
    tag_set_hist = Counter()
    catalog: list[dict[str, Any]] = []

    for i, (ah, _th, sz, body) in enumerate(iter_typed_entries(data, EFFECT_TYPE_HASH)):
        effect_sizes.append(sz)
        try:
            parsed = parse_effect_ucfx(body)
        except ValueError as exc:
            catalog.append(
                {
                    "index": i,
                    "asset_hash": f"0x{ah:08X}",
                    "size": sz,
                    "error": str(exc),
                }
            )
            continue

        tags = tuple(parsed.get("chunk_tags", []))
        tag_set_hist[tags] += 1
        emit = parsed.get("emit") or {}
        emit_u2[emit.get("header_emitter_count_u2", 0)] += 1

        row: dict[str, Any] = {
            "index": i,
            "asset_hash": f"0x{ah:08X}",
            "size": sz,
            "chunk_tags": list(tags),
        }
        if i < max_detail:
            row["detail"] = parsed
        catalog.append(row)

    mesh_count = type_hist.get(0x5B724250, 0)

    return {
        "version": 1,
        "source": source,
        "block_bytes": len(data),
        "block_entry_count": len(entries),
        "effect_type_hash": f"0x{EFFECT_TYPE_HASH:08X}",
        "effect_count": len(effect_sizes),
        "mesh_entries_in_block": mesh_count,
        "effect_size_min": min(effect_sizes) if effect_sizes else 0,
        "effect_size_max": max(effect_sizes) if effect_sizes else 0,
        "effect_size_unique": len(set(effect_sizes)),
        "emit_header_u2_histogram": {str(k): v for k, v in emit_u2.most_common()},
        "common_chunk_tag_sets": [
            {"tags": list(tags), "count": n} for tags, n in tag_set_hist.most_common(5)
        ],
        "effects": catalog,
        "note": (
            "Global fxdict parameters are in resident block (type_hash 0xFA46D8A8), "
            "not in this effects block file header table."
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Probe effects block UCFX structure")
    ap.add_argument("--block-bin", type=Path, help="Decompressed effects .block.bin")
    ap.add_argument("--wad", type=Path, help="Retail FFCS .wad")
    ap.add_argument(
        "--out",
        type=Path,
        default=_TOOLS.parent / "output" / "_scratch" / "fx_probe" / "effect_catalog_probe.json",
    )
    ap.add_argument(
        "--max-detail",
        type=int,
        default=5,
        help="Full per-chunk decode for the first N effects (default 5)",
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
        data, path_str = _load_effects_from_wad(wad)
        source = f"{wad} :: {path_str}"
    elif DEFAULT_WAD.is_file():
        data, path_str = _load_effects_from_wad(DEFAULT_WAD)
        source = f"{DEFAULT_WAD} :: {path_str}"
    else:
        print("error: pass --block-bin or --wad", file=sys.stderr)
        return 1

    doc = probe_effects_block(data, source=source, max_detail=args.max_detail)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
    print(
        f"Wrote {args.out} ({doc['effect_count']} effects, "
        f"{doc['block_entry_count']} total entries)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
