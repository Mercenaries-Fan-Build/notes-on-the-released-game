#!/usr/bin/env python3
"""Condense ``make extract-placements`` JSON into portable bundles for transfer.

After a full ``make extract-placements`` on a powerful machine, run::

    make condense-placements OUTPUT=./output

This writes:

- ``output/placements/world_bundle.json.gz`` — slim placements + deduped ECS table + spatial index
- ``output/placements/manifest.json`` — sizes, counts, SHA-256, load hints for subsets
- Optional ``maracaibo_bundle.json.gz`` / ``pmc_bundle.json.gz`` when subset files exist

On the consuming machine, expand back to standard placement JSON::

    python tools/condense_placements.py expand \\
        --bundle output/placements/world_bundle.json.gz \\
        --out-dir output/placements

Original files are never deleted (``--keep-full`` is the default behaviour).
"""

from __future__ import annotations

import argparse
import gzip
import hashlib
import json
import sys
from pathlib import Path
from typing import Any

SCHEMA_VERSION = 1
DEFAULT_CELL_M = 400.0


def _load_placements(path: Path) -> tuple[list[dict[str, Any]], dict[str, Any] | None]:
    """Return (placements, wrapper_meta)."""
    if not path.is_file():
        return [], None
    doc = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(doc, list):
        return doc, None
    if isinstance(doc, dict):
        return list(doc.get("placements", [])), doc
    return [], None


def _sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _file_meta(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {"path": str(path).replace("\\", "/"), "exists": False}
    st = path.stat()
    return {
        "path": str(path).replace("\\", "/"),
        "exists": True,
        "bytes": st.st_size,
        "sha256": _sha256_file(path),
    }


def _short_source(source: str) -> str:
    """Strip repetitive batch_vz path prefix from source filenames."""
    s = source.replace("\\", "/")
    for needle in ("blocks/VZ/", "blocks__VZ__", "blocks__vz__"):
        idx = s.lower().find(needle.lower())
        if idx >= 0:
            return s[idx + len(needle) :]
    if "/" in s:
        return s.rsplit("/", 1)[-1]
    return s


def _placement_quat(p: dict[str, Any]) -> list[float] | None:
    if "rotation_quat_w" in p:
        return [
            float(p.get("rotation_quat_x", 0.0)),
            float(p.get("rotation_quat_y", 0.0)),
            float(p.get("rotation_quat_z", 0.0)),
            float(p.get("rotation_quat_w", 1.0)),
        ]
    return None


def _slim_placement(p: dict[str, Any], *, ecs_idx: int | None) -> dict[str, Any]:
    pos = p.get("position") or {}
    out: dict[str, Any] = {
        "id": p.get("entity_id"),
        "bt": p.get("block_type", ""),
    }
    name = p.get("entity_name")
    if name:
        out["n"] = name
    try:
        out["p"] = [float(pos["x"]), float(pos["y"]), float(pos["z"])]
    except (KeyError, TypeError, ValueError):
        out["p"] = [0.0, 0.0, 0.0]

    q = _placement_quat(p)
    if q is not None:
        out["q"] = q
    elif "rotation_y_rad" in p:
        out["y"] = float(p["rotation_y_rad"])
    elif "rotation_y_sin" in p:
        out["ys"] = float(p["rotation_y_sin"])

    src = p.get("source")
    if src:
        out["src"] = _short_source(str(src))

    if p.get("sub_block") is not None:
        out["sb"] = int(p["sub_block"])
    th = p.get("type_hash")
    if th:
        out["th"] = th
    if ecs_idx is not None:
        out["ei"] = ecs_idx
    return out


def _expand_placement(slim: dict[str, Any], ecs_table: list[dict[str, Any]]) -> dict[str, Any]:
    p: dict[str, Any] = {
        "entity_id": slim.get("id"),
        "block_type": slim.get("bt", ""),
        "entity_name": slim.get("n"),
        "source": slim.get("src", ""),
    }
    if slim.get("sb") is not None:
        p["sub_block"] = slim["sb"]
    if slim.get("th"):
        p["type_hash"] = slim["th"]

    pos = slim.get("p", [0, 0, 0])
    p["position"] = {"x": pos[0], "y": pos[1], "z": pos[2]}

    if "q" in slim:
        q = slim["q"]
        p["rotation_quat_x"] = q[0]
        p["rotation_quat_y"] = q[1]
        p["rotation_quat_z"] = q[2]
        p["rotation_quat_w"] = q[3]
        import math

        p["rotation_y_rad"] = 2.0 * math.atan2(q[1], q[3])
        p["rotation_y_deg"] = math.degrees(p["rotation_y_rad"])
    elif "y" in slim:
        p["rotation_y_rad"] = float(slim["y"])
        import math

        p["rotation_y_deg"] = math.degrees(p["rotation_y_rad"])
    elif "ys" in slim:
        p["rotation_y_sin"] = float(slim["ys"])

    ei = slim.get("ei")
    if isinstance(ei, int) and 0 <= ei < len(ecs_table):
        p["ecs"] = ecs_table[ei]

    return p


def _ecs_canonical(ecs: dict[str, Any]) -> str:
    return json.dumps(ecs, sort_keys=True, separators=(",", ":"))


def _build_ecs_table(
    placements: list[dict[str, Any]],
) -> tuple[list[dict[str, Any]], dict[str, int]]:
    """Dedupe placement ``ecs`` dicts → table + per-canonical index."""
    table: list[dict[str, Any]] = []
    index: dict[str, int] = {}
    for p in placements:
        ecs = p.get("ecs")
        if not ecs:
            continue
        key = _ecs_canonical(ecs)
        if key not in index:
            index[key] = len(table)
            table.append(ecs)
    return table, index


def _ecs_idx_for_placement(p: dict[str, Any], ecs_index: dict[str, int]) -> int | None:
    ecs = p.get("ecs")
    if not ecs:
        return None
    return ecs_index.get(_ecs_canonical(ecs))


def _bbox(placements: list[dict[str, Any]]) -> dict[str, float]:
    xs: list[float] = []
    ys: list[float] = []
    zs: list[float] = []
    for p in placements:
        pos = p.get("position") or {}
        try:
            xs.append(float(pos["x"]))
            ys.append(float(pos["y"]))
            zs.append(float(pos["z"]))
        except (KeyError, TypeError, ValueError):
            continue
    if not xs:
        return {}
    return {
        "x_min": min(xs),
        "x_max": max(xs),
        "y_min": min(ys),
        "y_max": max(ys),
        "z_min": min(zs),
        "z_max": max(zs),
    }


def _spatial_index(
    slim_layers: list[dict[str, Any]],
    slim_vz: list[dict[str, Any]],
    *,
    cell_m: float,
) -> dict[str, Any]:
    cells: dict[str, list[int]] = {}

    def add(slim: dict[str, Any], idx: int) -> None:
        pos = slim.get("p", [0, 0, 0])
        cx = int(pos[0] // cell_m)
        cz = int(pos[2] // cell_m)
        key = f"{cx},{cz}"
        cells.setdefault(key, []).append(idx)

    n_ls = len(slim_layers)
    for i, s in enumerate(slim_layers):
        add(s, i)
    for i, s in enumerate(slim_vz):
        add(s, n_ls + i)

    return {"cell_m": cell_m, "cells": cells, "layers_static_count": n_ls}


def build_bundle(
    *,
    layers_static: list[dict[str, Any]],
    vz_state: list[dict[str, Any]],
    cell_m: float = DEFAULT_CELL_M,
    source_root: str = "",
) -> dict[str, Any]:
    all_pl = layers_static + vz_state
    ecs_table, ecs_index = _build_ecs_table(all_pl)

    slim_ls = [_slim_placement(p, ecs_idx=_ecs_idx_for_placement(p, ecs_index)) for p in layers_static]
    slim_vz = [_slim_placement(p, ecs_idx=_ecs_idx_for_placement(p, ecs_index)) for p in vz_state]

    return {
        "schema_version": SCHEMA_VERSION,
        "source_root": source_root.replace("\\", "/"),
        "counts": {
            "layers_static": len(slim_ls),
            "vz_state": len(slim_vz),
            "ecs_unique": len(ecs_table),
            "ecs_attached": sum(1 for p in all_pl if p.get("ecs")),
        },
        "bbox": _bbox(all_pl),
        "ecs_table": ecs_table,
        "layers_static": slim_ls,
        "vz_state": slim_vz,
        "spatial_index": _spatial_index(slim_ls, slim_vz, cell_m=cell_m),
    }


def write_bundle(path: Path, bundle: dict[str, Any]) -> int:
    path.parent.mkdir(parents=True, exist_ok=True)
    raw = json.dumps(bundle, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    if path.suffix == ".gz" or str(path).endswith(".json.gz"):
        with gzip.open(path, "wb", compresslevel=6) as fh:
            fh.write(raw)
    else:
        path.write_bytes(raw)
    return len(raw)


def read_bundle(path: Path) -> dict[str, Any]:
    if path.suffix == ".gz" or str(path).endswith(".json.gz"):
        with gzip.open(path, "rt", encoding="utf-8") as fh:
            return json.load(fh)
    return json.loads(path.read_text(encoding="utf-8"))


def build_manifest(
    placements_dir: Path,
    output_root: Path,
    *,
    bundle_path: Path,
    bundle_uncompressed_bytes: int,
    subset_paths: dict[str, Path],
) -> dict[str, Any]:
    artifacts = {
        "layers_static": placements_dir / "layers_static.json",
        "vz_state_merged": placements_dir / "vz_state" / "all_vz_state.json",
        "ecs_components": placements_dir / "ecs_components.json",
        "maracaibo_placements": placements_dir / "maracaibo_placements.json",
        "pmc_base": placements_dir / "pmc_base.json",
        "script_hash_map": placements_dir / "script_hash_map.json",
        "pmc_lua_harvest": placements_dir / "pmc_lua_string_harvest.json",
        "destruction_graph": placements_dir / "destruction_graph.json",
        "road_graph": placements_dir / "road_graph.json",
        "vz_act_manifest": placements_dir / "vz_act_layer_manifest.json",
        "c3_cell_manifest": placements_dir / "c3_cell_manifest.json",
        "block_dependency_graph": output_root / "block_dependency_graph.json",
        "pmc_base_block_set": output_root / "pmc_base_block_set.json",
    }

    files_meta = {k: _file_meta(v) for k, v in artifacts.items()}

    bundle_disk = bundle_path.stat().st_size if bundle_path.is_file() else 0

    ls_count = vz_count = 0
    ls_path = artifacts["layers_static"]
    vz_path = artifacts["vz_state_merged"]
    if ls_path.is_file():
        pl, _ = _load_placements(ls_path)
        ls_count = len(pl)
    if vz_path.is_file():
        pl, _ = _load_placements(vz_path)
        vz_count = len(pl)

    total_source_bytes = sum(
        m.get("bytes", 0) for m in files_meta.values() if m.get("exists")
    )

    return {
        "schema_version": SCHEMA_VERSION,
        "placements_dir": str(placements_dir).replace("\\", "/"),
        "artifacts": files_meta,
        "placement_counts": {
            "layers_static": ls_count,
            "vz_state": vz_count,
            "total": ls_count + vz_count,
        },
        "bundle": {
            "path": str(bundle_path).replace("\\", "/"),
            "disk_bytes": bundle_disk,
            "uncompressed_json_bytes": bundle_uncompressed_bytes,
            "compression_ratio": (
                round(total_source_bytes / bundle_disk, 2)
                if bundle_disk and total_source_bytes
                else None
            ),
        },
        "load_profiles": {
            "full_world_ue5": {
                "expand_bundle": str(bundle_path).replace("\\", "/"),
                "then_run": [
                    "game-scripts/import_world.py",
                    "game-scripts/populate_world.py",
                ],
                "env": {
                    "MERCS2_STATIC_PLACEMENTS": "output/placements/layers_static.json",
                },
            },
            "maracaibo_demo": {
                "needs": ["maracaibo_placements.json or maracaibo_bundle.json.gz"],
                "make": "filter-maracaibo-placements (on source machine) or use bundled subset",
            },
            "pmc_testbed": {
                "needs": ["pmc_base.json", "pmc_base_asset_list.json"],
                "make": "filter-pmc-base (requires ue5-bundle on source machine)",
            },
            "sidecars_optional": [
                "destruction_graph.json",
                "road_graph.json",
                "script_hash_map.json",
                "ecs_components.json",
            ],
        },
        "subsets": {
            name: _file_meta(p) for name, p in subset_paths.items() if p.is_file()
        },
    }


def cmd_condense(args: argparse.Namespace) -> int:
    placements_dir = Path(args.placements_dir)
    output_root = Path(args.output)

    ls_path = placements_dir / "layers_static.json"
    vz_path = placements_dir / "vz_state" / "all_vz_state.json"

    if not ls_path.is_file():
        print(f"error: missing {ls_path} — run make extract-placements first", file=sys.stderr)
        return 1

    layers_static, ls_wrap = _load_placements(ls_path)
    vz_state: list[dict[str, Any]] = []
    if vz_path.is_file():
        vz_state, _ = _load_placements(vz_path)

    bundle = build_bundle(
        layers_static=layers_static,
        vz_state=vz_state,
        cell_m=args.cell_m,
        source_root=str(placements_dir),
    )

    bundle_path = Path(args.bundle)
    raw_bytes = write_bundle(bundle_path, bundle)

    manifest_path = Path(args.manifest)
    subset_paths: dict[str, Path] = {}

    if args.write_subsets:
        mar_path = placements_dir / "maracaibo_placements.json"
        if mar_path.is_file():
            mar_pl, mar_wrap = _load_placements(mar_path)
            mar_ls = [p for p in mar_pl if p.get("block_type") == "layers_static"]
            mar_vz = [p for p in mar_pl if p.get("block_type") == "vz_state"]
            mar_bundle = build_bundle(
                layers_static=mar_ls,
                vz_state=mar_vz,
                cell_m=args.cell_m,
                source_root=str(placements_dir),
            )
            mar_out = placements_dir / "maracaibo_bundle.json.gz"
            write_bundle(mar_out, mar_bundle)
            subset_paths["maracaibo_bundle"] = mar_out
            print(f"Wrote {mar_out}")

        pmc_path = placements_dir / "pmc_base.json"
        if pmc_path.is_file():
            pmc_pl, _ = _load_placements(pmc_path)
            pmc_ls = [p for p in pmc_pl if p.get("block_type") == "layers_static"]
            pmc_vz = [p for p in pmc_pl if p.get("block_type") == "vz_state"]
            pmc_bundle = build_bundle(
                layers_static=pmc_ls,
                vz_state=pmc_vz,
                cell_m=args.cell_m,
                source_root=str(placements_dir),
            )
            pmc_out = placements_dir / "pmc_bundle.json.gz"
            write_bundle(pmc_out, pmc_bundle)
            subset_paths["pmc_bundle"] = pmc_out
            print(f"Wrote {pmc_out}")

    manifest = build_manifest(
        placements_dir,
        output_root,
        bundle_path=bundle_path,
        bundle_uncompressed_bytes=raw_bytes,
        subset_paths=subset_paths,
    )
    if ls_wrap:
        manifest["layers_static_meta"] = {
            k: ls_wrap.get(k)
            for k in ("file", "file_size", "block_type", "placement_count")
            if k in ls_wrap
        }
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    disk = bundle_path.stat().st_size
    print(
        f"Wrote {bundle_path} ({disk:,} bytes gzip, {raw_bytes:,} bytes JSON uncompressed)\n"
        f"  layers_static={len(layers_static):,} vz_state={len(vz_state):,} "
        f"ecs_unique={bundle['counts']['ecs_unique']:,}\n"
        f"  manifest → {manifest_path}",
        file=sys.stderr,
    )
    return 0


def cmd_expand(args: argparse.Namespace) -> int:
    bundle = read_bundle(Path(args.bundle))
    ecs_table = bundle.get("ecs_table", [])
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    ls_expanded = [_expand_placement(s, ecs_table) for s in bundle.get("layers_static", [])]
    vz_expanded = [_expand_placement(s, ecs_table) for s in bundle.get("vz_state", [])]

    ls_doc = {
        "file": "world_bundle (expanded)",
        "block_type": "layers_static",
        "placement_count": len(ls_expanded),
        "placements": ls_expanded,
    }
    vz_doc = {
        "blocks_dir": "world_bundle (expanded)",
        "total_placements": len(vz_expanded),
        "placements": vz_expanded,
    }

    ls_out = out_dir / "layers_static.json"
    vz_out = out_dir / "vz_state" / "all_vz_state.json"
    vz_out.parent.mkdir(parents=True, exist_ok=True)

    indent = 2 if args.pretty else None
    ls_out.write_text(json.dumps(ls_doc, indent=indent, ensure_ascii=False), encoding="utf-8")
    vz_out.write_text(json.dumps(vz_doc, indent=indent, ensure_ascii=False), encoding="utf-8")

    print(f"Expanded {len(ls_expanded):,} + {len(vz_expanded):,} placements → {out_dir}", file=sys.stderr)
    return 0


def cmd_self_test() -> int:
    layers = [
        {
            "entity_id": "0x00000001",
            "entity_name": "Light_Tower 0x1",
            "block_type": "layers_static",
            "source": "00029_blocks__VZ__layers_static_P000_Q3.block.bin",
            "position": {"x": 10.0, "y": 5.0, "z": -20.0},
            "rotation_quat_x": 0.0,
            "rotation_quat_y": 0.1,
            "rotation_quat_z": 0.0,
            "rotation_quat_w": 0.995,
            "ecs": {
                "LightObject": {
                    "light_r": 1.0,
                    "light_g": 0.9,
                    "light_b": 0.8,
                    "payload_size": 64,
                }
            },
        },
        {
            "entity_id": "0x00000002",
            "entity_name": "Rock_01",
            "block_type": "layers_static",
            "source": "layers_static_P000_Q3.block.bin",
            "position": {"x": 500.0, "y": 2.0, "z": 500.0},
            "rotation_quat_x": 0.0,
            "rotation_quat_y": 0.0,
            "rotation_quat_z": 0.0,
            "rotation_quat_w": 1.0,
        },
    ]
    vz = [
        {
            "entity_id": "0x00000003",
            "entity_name": "Ruined_Wall",
            "block_type": "vz_state",
            "source": "mar_city_ruined_vz_state_P000_Q3.block.bin",
            "position": {"x": 100.0, "y": 3.0, "z": 50.0},
            "rotation_y_sin": 0.5,
            "ecs": {
                "LightObject": {
                    "light_r": 1.0,
                    "light_g": 0.9,
                    "light_b": 0.8,
                    "payload_size": 64,
                }
            },
        },
    ]

    bundle = build_bundle(layers_static=layers, vz_state=vz, cell_m=400.0)
    assert bundle["counts"]["layers_static"] == 2
    assert bundle["counts"]["vz_state"] == 1
    assert bundle["counts"]["ecs_unique"] == 1
    assert bundle["layers_static"][0]["ei"] == 0
    assert bundle["vz_state"][0]["ei"] == 0

    expanded_ls = [_expand_placement(s, bundle["ecs_table"]) for s in bundle["layers_static"]]
    assert expanded_ls[0]["ecs"]["LightObject"]["light_r"] == 1.0
    assert expanded_ls[0]["position"]["x"] == 10.0
    assert "rotation_quat_w" in expanded_ls[0]

    cells = bundle["spatial_index"]["cells"]
    assert any(len(v) >= 1 for v in cells.values())

    import tempfile

    with tempfile.TemporaryDirectory() as tmp:
        bp = Path(tmp) / "test_bundle.json.gz"
        raw = write_bundle(bp, bundle)
        assert raw > 0
        back = read_bundle(bp)
        assert back["counts"] == bundle["counts"]

    print("condense_placements self-test OK", file=sys.stderr)
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Condense or expand placement JSON bundles")
    sub = ap.add_subparsers(dest="command", required=True)

    cond = sub.add_parser("condense", help="Build world_bundle.json.gz + manifest.json")
    cond.add_argument("--output", type=Path, default=Path("output"), help="Pipeline output root")
    cond.add_argument(
        "--placements-dir",
        type=Path,
        default=None,
        help="Placements directory (default: OUTPUT/placements)",
    )
    cond.add_argument(
        "--bundle",
        type=Path,
        default=None,
        help="Bundle output path (default: placements/world_bundle.json.gz)",
    )
    cond.add_argument(
        "--manifest",
        type=Path,
        default=None,
        help="Manifest path (default: placements/manifest.json)",
    )
    cond.add_argument("--cell-m", type=float, default=DEFAULT_CELL_M, help="Spatial grid cell size (metres)")
    cond.add_argument(
        "--write-subsets",
        action="store_true",
        help="Also write maracaibo_bundle.json.gz / pmc_bundle.json.gz when subset JSON exists",
    )

    exp = sub.add_parser("expand", help="Restore layers_static.json + all_vz_state.json from bundle")
    exp.add_argument("--bundle", type=Path, required=True)
    exp.add_argument("--out-dir", type=Path, default=Path("output/placements"))
    exp.add_argument("--pretty", action="store_true", help="Indent JSON (larger files)")

    sub.add_parser("self-test", help="Run built-in sanity checks")

    args = ap.parse_args()
    if args.command == "self-test":
        return cmd_self_test()

    if args.command == "condense":
        output = Path(args.output)
        placements_dir = Path(args.placements_dir or output / "placements")
        args.placements_dir = placements_dir
        args.bundle = Path(args.bundle or placements_dir / "world_bundle.json.gz")
        args.manifest = Path(args.manifest or placements_dir / "manifest.json")
        return cmd_condense(args)

    if args.command == "expand":
        return cmd_expand(args)

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
