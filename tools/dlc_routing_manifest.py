#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Deterministic routing manifest for `make dlc-port`.

Answers "what bytes are routed where" WITHOUT converting or diffing WADs: it
runs the *same* per-block predicates `dlc_port` uses (`_path_force_python_ecs`
+ `_block_has_ecs_layer`) over every real DLC block and reports, per block,
whether it goes to the Python or Rust byte-swapper and exactly why.

Reuses the production pipeline functions (x360_dlc_io reader, sges decompress,
the dlc_port predicates) so the manifest matches what the converter actually does.
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
import tempfile
from collections import Counter
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from x360_dlc_io import (  # noqa: E402
    extract_stfs_from_rar,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
    decompress_be_sges,
)
import dlc_port  # noqa: E402
from dlc_port import (  # noqa: E402
    PAGE_SIZE,
    _TYPE_ECS_LAYER,
    _TYPE_WORLD_ENTITY,
    _TYPE_GUIDMAP,
    _path_force_python_ecs,
)

_ECS_TYPE_NAMES = {
    _TYPE_ECS_LAYER: "ecs_layer/node(0xE6B81A54)",
    _TYPE_WORLD_ENTITY: "worldentity(0x5647C35D)",
    _TYPE_GUIDMAP: "guidmap(0x140E8728)",
}


def _decompress_block(doh_slice: bytes) -> bytes | None:
    """Mirror dlc_port._process_one_block's decompress (segs vs raw-XFCU)."""
    if len(doh_slice) < 4:
        return None
    if doh_slice[:4] == b"segs":
        try:
            return decompress_be_sges(doh_slice, 0, len(doh_slice))
        except Exception:
            return None
    rec_count_be = struct.unpack_from(">I", doh_slice, 0)[0]
    header_end = 4 + rec_count_be * 16
    tag = doh_slice[header_end:header_end + 4] if header_end + 4 <= len(doh_slice) else b""
    if 0 < rec_count_be < 5000 and tag == b"XFCU":
        end = len(doh_slice)
        while end > 4 and doh_slice[end - 1] == 0:
            end -= 1
        return bytes(doh_slice[: (end + 3) & ~3])
    return None


def _ecs_trigger(decompressed: bytes):
    """If the block's entry table contains an ECS-layer-class entry, return
    (entry_index, type_hash); else None. Mirrors _block_has_ecs_layer's scan."""
    if len(decompressed) < 20:
        return None
    try:
        n = struct.unpack_from(">I", decompressed, 0)[0]
    except struct.error:
        return None
    if n > 50_000 or 4 + n * 16 > len(decompressed):
        return None
    for i in range(n):
        th = struct.unpack_from(">I", decompressed, 4 + i * 16 + 4)[0]
        if th in (_TYPE_ECS_LAYER, _TYPE_WORLD_ENTITY, _TYPE_GUIDMAP):
            return i, th
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--x360-rar", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=Path("output/analysis/dlc_routing_manifest.json"))
    args = ap.parse_args()

    work = Path(tempfile.mkdtemp(prefix="dlc_routing_"))
    reader = extract_stfs_from_rar(args.x360_rar, work)
    doh_entry = next((e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh_entry is None:
        print("ERROR: no DOH in STFS file table", file=sys.stderr)
        return 1
    doh = reader.read(0, doh_entry["file_size"])

    _num, rows = parse_be_ffcs(doh)
    by = {r.tag: r for r in rows}
    indx = parse_be_indx(doh, by["INDX"].offset, by["INDX"].meta)
    paths = parse_be_pths(doh, by["PTHS"].offset, by["PTHS"].meta)

    entries = []
    route_counts = Counter()
    reason_counts = Counter()
    trigger_type_counts = Counter()
    bytes_by_route = Counter()
    skipped = 0

    for blk_idx, ie in enumerate(indx):
        path = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx:05d}"
        off = ie.file_offset
        size = ie.page_count * PAGE_SIZE
        if off + 4 > len(doh):
            skipped += 1
            continue
        dec = _decompress_block(bytes(doh[off:off + size]))
        if dec is None:
            skipped += 1
            continue

        # Production default routing: byteswap_python_ecs_paths=True.
        if _path_force_python_ecs(path):
            route, reason = "python", "path-force"
        else:
            trig = _ecs_trigger(dec)
            if trig is not None:
                ti, th = trig
                route, reason = "python", f"entry[{ti}] type={_ECS_TYPE_NAMES.get(th, hex(th))}"
                trigger_type_counts[_ECS_TYPE_NAMES.get(th, hex(th))] += 1
            else:
                route, reason = "rust", "no-ecs-layer"

        route_counts[route] += 1
        reason_counts[reason if reason in ("path-force", "no-ecs-layer") else "ecs-content"] += 1
        bytes_by_route[route] += len(dec)
        entries.append({"block": blk_idx, "path": path, "route": route,
                        "reason": reason, "dec_bytes": len(dec)})

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(entries, indent=1), encoding="utf-8")

    total = len(entries)
    print(f"DLC routing manifest  ({total} blocks, {skipped} skipped)  -> {args.out}")
    print(f"  PYTHON: {route_counts['python']:5d} blocks  "
          f"({bytes_by_route['python']/1e6:7.1f} MB decompressed)")
    print(f"  RUST  : {route_counts['rust']:5d} blocks  "
          f"({bytes_by_route['rust']/1e6:7.1f} MB decompressed)")
    print("  why-python:")
    print(f"    path-force : {reason_counts['path-force']}")
    print(f"    ecs-content: {reason_counts['ecs-content']}")
    for t, c in trigger_type_counts.most_common():
        print(f"      {t}: {c}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
