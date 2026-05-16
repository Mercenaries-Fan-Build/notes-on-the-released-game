#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan decompressed ``.bin`` blocks and emit ECS ``COMP`` metadata + optional merge.

Writes ``output/placements/ecs_components.json`` and can merge ``ecs`` payloads into
``layers_static.json`` / ``vz_state/all_vz_state.json`` (see ``ucfx_ecs_codec``).
"""

from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from placement_extractor import detect_block_type  # noqa: E402
from ucfx_ecs_codec import (  # noqa: E402
    extract_ecs_layers_static,
    extract_ecs_vz_state,
    merge_ecs_into_placements,
)


def _load_json(path: Path) -> list | dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")


def _scan_vz_state_dir(blocks_dir: Path, filt: str | None) -> list[dict]:
    records: list[dict] = []
    for p in sorted(blocks_dir.glob("*.bin")):
        if filt and filt not in p.name:
            continue
        data = p.read_bytes()
        if detect_block_type(data) != "vz_state":
            continue
        try:
            records.extend(extract_ecs_vz_state(data, p.name))
        except (struct.error, KeyError, ValueError):
            continue
    return records


def main() -> int:
    ap = argparse.ArgumentParser(description="ECS COMP harvest + merge into placements JSON")
    ap.add_argument(
        "--layers-static-bin",
        type=Path,
        default=Path("output/extracted/batch_vz/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin"),
    )
    ap.add_argument(
        "--vz-state-dir",
        type=Path,
        default=Path("output/extracted/batch_vz/blocks"),
    )
    ap.add_argument(
        "--vz-state-filter",
        default="vz_state",
        help="Substring filter for vz_state batch filenames (default: all vz_state)",
    )
    ap.add_argument(
        "--out-ecs",
        type=Path,
        default=Path("output/placements/ecs_components.json"),
    )
    ap.add_argument(
        "--merge-layers-static-json",
        type=Path,
        default=Path("output/placements/layers_static.json"),
        help="If set and exists, merge ECS rows into this placements file (mutates file)",
    )
    ap.add_argument(
        "--merge-vz-state-json",
        type=Path,
        default=Path("output/placements/vz_state/all_vz_state.json"),
    )
    ap.add_argument("--skip-vz-state-scan", action="store_true", help="Only layers_static ECS (faster)")
    args = ap.parse_args()

    import struct  # noqa: PLC0415 — late import for except clause

    all_records: list[dict] = []
    if args.layers_static_bin.is_file():
        data = args.layers_static_bin.read_bytes()
        if detect_block_type(data) == "layers_static":
            all_records.extend(extract_ecs_layers_static(data, args.layers_static_bin.name))
    else:
        print(f"warning: missing layers_static bin {args.layers_static_bin}", file=sys.stderr)

    if not args.skip_vz_state_scan and args.vz_state_dir.is_dir():
        all_records.extend(_scan_vz_state_dir(args.vz_state_dir, args.vz_state_filter))

    portals = [r for r in all_records if r.get("comp_info_name") in {"EntranceLink", "EntranceParameters", "EntranceToSeat", "Door", "DoorCoupling", "SoundInterior"}]
    regions = [r for r in all_records if r.get("comp_info_name") in {"SphereRegion", "CircleRegion", "LineRegion", "LandingZone", "FactionZone", "FactionMarker", "PointLocation"}]

    doc = {
        "record_count": len(all_records),
        "portal_record_count": len(portals),
        "region_record_count": len(regions),
        "records": all_records,
        "portals": portals,
        "regions": regions,
    }
    _write_json(args.out_ecs, doc)
    print(f"Wrote {args.out_ecs} ({len(all_records)} records)")

    if args.merge_layers_static_json.is_file():
        pl_doc = _load_json(args.merge_layers_static_json)
        placements = pl_doc if isinstance(pl_doc, list) else pl_doc.get("placements", [])
        ls_rows = [r for r in all_records if r.get("block_type") == "layers_static"]
        merge_ecs_into_placements(placements, ls_rows, block_type="layers_static")
        out_obj = placements if isinstance(pl_doc, list) else {**pl_doc, "placements": placements}
        _write_json(args.merge_layers_static_json, out_obj)
        print(f"Merged ECS into {args.merge_layers_static_json}")

    if args.merge_vz_state_json.is_file():
        vz_doc = _load_json(args.merge_vz_state_json)
        vz_pl = vz_doc if isinstance(vz_doc, list) else vz_doc.get("placements", [])
        vz_rows = [r for r in all_records if r.get("block_type") == "vz_state"]
        merge_ecs_into_placements(vz_pl, vz_rows, block_type="vz_state")
        out_vz = vz_pl if isinstance(vz_doc, list) else {**vz_doc, "placements": vz_pl}
        _write_json(args.merge_vz_state_json, out_vz)
        print(f"Merged ECS into {args.merge_vz_state_json}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
