#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Resolve DestructionLink ECS ref keys to placement entity pairs.

Reads ``layers_static.json`` (with merged ``ecs.DestructionLink`` payloads from
``ecs_metadata_extract.py``) and emits a destruction graph JSON suitable for UE5
Chaos swap wiring and overlay cross-reference.

Usage::

    .venv/bin/python3 tools/destruction_link_resolver.py \\
      --layers-static output/placements/layers_static.json \\
      --out output/placements/destruction_graph.json

    .venv/bin/python3 tools/destruction_link_resolver.py \\
      --layers-static output/placements/layers_static.json \\
      --vz-state-glob "output/placements/vz_state/*.json" \\
      --out output/placements/destruction_graph.json

Self-test (no pipeline output required)::

    .venv/bin/python3 tools/destruction_link_resolver.py --self-test
"""

from __future__ import annotations

import argparse
import json
import math
import re
import sys
from glob import glob
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from hash_resolver import get_resolver  # noqa: E402
from ucfx_ecs_codec import placement_entity_key  # noqa: E402

_RE_ENTITY_KEY_SUFFIX = re.compile(r"\s+0x[0-9a-fA-F]{8}$")
_VARIANT_SUFFIX_PATTERNS: tuple[str, ...] = (
    r"_destroyed$",
    r"_ruined$",
    r"_rubble$",
    r"_dest$",
    r"_pristine$",
    r"_intact$",
    r"_broken$",
    r"_burn$",
    r"_wreck$",
    r"_dmg\d*$",
)


def placement_entity_key_from(p: dict[str, Any]) -> int | None:
    """Return the u32 entity key for a placement dict."""
    eid_raw = p.get("entity_id")
    if isinstance(eid_raw, str) and eid_raw.startswith("0x"):
        try:
            return int(eid_raw, 16)
        except ValueError:
            pass
    return placement_entity_key(p.get("entity_name"))


def _hex_key(value: int | str | None) -> str | None:
    if value is None:
        return None
    if isinstance(value, str):
        return value.lower() if value.startswith("0x") else None
    return f"0x{value:08x}"


def _parse_hex_key(raw: str | None) -> int | None:
    if not raw or not isinstance(raw, str) or not raw.startswith("0x"):
        return None
    try:
        return int(raw, 16)
    except ValueError:
        return None


def _placement_summary(p: dict[str, Any]) -> dict[str, Any]:
    ek = placement_entity_key_from(p)
    pos = p.get("position")
    if isinstance(pos, dict):
        xyz = (
            round(float(pos.get("x", 0.0)), 3),
            round(float(pos.get("y", 0.0)), 3),
            round(float(pos.get("z", 0.0)), 3),
        )
    else:
        xyz = (
            round(float(p.get("x", 0.0)), 3),
            round(float(p.get("y", 0.0)), 3),
            round(float(p.get("z", 0.0)), 3),
        )
    out: dict[str, Any] = {
        "entity_id": _hex_key(ek) or p.get("entity_id"),
        "entity_name": p.get("entity_name"),
        "position": {"x": xyz[0], "y": xyz[1], "z": xyz[2]},
    }
    if p.get("source"):
        out["source"] = p["source"]
    if p.get("model_name_hash"):
        out["model_name_hash"] = p["model_name_hash"]
        resolved = get_resolver().resolve_m2(_parse_hex_key(p["model_name_hash"]) or 0)
        if resolved:
            out["model_name_resolved"] = resolved
    mesh_stem = mesh_base_from_entity_name(p.get("entity_name"))
    if mesh_stem:
        out["mesh_stem"] = mesh_stem
    return out


def mesh_base_from_entity_name(name: str | None) -> str | None:
    """Strip entity-key suffix and destruction/LOD variant tokens for pairing."""
    if not name or not isinstance(name, str):
        return None
    stem = _RE_ENTITY_KEY_SUFFIX.sub("", name.strip())
    for pat in _VARIANT_SUFFIX_PATTERNS:
        stem = re.sub(pat, "", stem, flags=re.IGNORECASE)
    stem = stem.strip("_ ")
    return stem.lower() if stem else None


def overlay_state_tag(p: dict[str, Any]) -> str | None:
    """Classify vz_state overlay as destroyed/ruined vs pristine from source or name."""
    blob = f"{p.get('source', '')} {p.get('entity_name', '')}".lower()
    if any(t in blob for t in ("destroyed", "ruined", "rubble", "_dest")):
        return "destroyed"
    if "pristine" in blob:
        return "pristine"
    return None


def _distance_m(a: dict[str, Any], b: dict[str, Any]) -> float:
    def _xyz(row: dict[str, Any]) -> tuple[float, float, float]:
        pos = row.get("position")
        if isinstance(pos, dict):
            return float(pos["x"]), float(pos["y"]), float(pos["z"])
        return float(row.get("x", 0)), float(row.get("y", 0)), float(row.get("z", 0))

    ax, ay, az = _xyz(a)
    bx, by, bz = _xyz(b)
    return math.sqrt((ax - bx) ** 2 + (ay - by) ** 2 + (az - bz) ** 2)


def _destruction_fields(ecs_entry: dict[str, Any]) -> dict[str, Any]:
    out = {
        "destruction_ref_key": ecs_entry.get("destruction_ref_key"),
        "destruction_u32_1": ecs_entry.get("destruction_u32_1"),
        "destruction_link_key": ecs_entry.get("destruction_link_key"),
        "destruction_u32_3": ecs_entry.get("destruction_u32_3"),
    }
    h3 = _parse_hex_key(ecs_entry.get("destruction_u32_3"))
    if h3 is not None and h3 != 0:
        name = get_resolver().resolve_m2(h3)
        if name:
            out["destruction_u32_3_resolved"] = name
    return out


def build_entity_index(placements: list[dict[str, Any]]) -> dict[int, list[dict[str, Any]]]:
    """Map entity_key → placement rows (normally one row per key)."""
    index: dict[int, list[dict[str, Any]]] = {}
    for p in placements:
        ek = placement_entity_key_from(p)
        if ek is not None:
            index.setdefault(ek, []).append(p)
    return index


def load_vz_state_placements(glob_pattern: str) -> list[dict[str, Any]]:
    """Load vz_state placement rows from JSON files matching a glob."""
    rows: list[dict[str, Any]] = []
    for path_str in sorted(glob(glob_pattern)):
        path = Path(path_str)
        if not path.is_file():
            continue
        doc = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(doc, list):
            chunk = doc
        elif isinstance(doc, dict):
            if isinstance(doc.get("placements"), list):
                chunk = doc["placements"]
            elif doc.get("block_type") == "vz_state":
                chunk = [doc]
            else:
                continue
        else:
            continue
        for p in chunk:
            if p.get("block_type", "vz_state") == "vz_state":
                rows.append(p)
    return rows


def cross_reference_vz_state(
    layers_static: list[dict[str, Any]],
    vz_state: list[dict[str, Any]],
    graph: dict[str, Any],
    *,
    mesh_pair_max_distance_m: float = 5.0,
) -> dict[str, Any]:
    """Match destroyed/ruined vz_state overlays to layers_static destruction pairs."""
    static_by_id: dict[int, dict[str, Any]] = {}
    static_by_mesh: dict[str, list[dict[str, Any]]] = {}
    for p in layers_static:
        if p.get("block_type", "layers_static") != "layers_static":
            continue
        ek = placement_entity_key_from(p)
        if ek is None:
            continue
        static_by_id[ek] = p
        stem = mesh_base_from_entity_name(p.get("entity_name"))
        if stem:
            static_by_mesh.setdefault(stem, []).append(p)

    destroyed_overlays: list[dict[str, Any]] = []
    pristine_overlays: list[dict[str, Any]] = []
    overlay_by_entity_id: dict[int, dict[str, Any]] = {}
    overlay_by_mesh: dict[str, list[dict[str, Any]]] = {}

    for p in vz_state:
        tag = overlay_state_tag(p)
        if tag is None:
            continue
        ek = placement_entity_key_from(p)
        summary = _placement_summary(p)
        summary["overlay_state"] = tag
        if tag == "destroyed":
            destroyed_overlays.append(summary)
        else:
            pristine_overlays.append(summary)
        if ek is not None:
            overlay_by_entity_id[ek] = summary
        stem = mesh_base_from_entity_name(p.get("entity_name"))
        if stem:
            overlay_by_mesh.setdefault(stem, []).append(summary)

    entity_id_matches: list[dict[str, Any]] = []
    for row in graph.get("links", []):
        for side in ("source", "target"):
            ent = row.get(side)
            if not isinstance(ent, dict):
                continue
            eid = _parse_hex_key(ent.get("entity_id"))
            if eid is None:
                continue
            overlay = overlay_by_entity_id.get(eid)
            if overlay and overlay.get("overlay_state") == "destroyed":
                entity_id_matches.append(
                    {
                        "layers_static_side": side,
                        "entity": ent,
                        "vz_state_overlay": overlay,
                        "match_method": "entity_id",
                    }
                )

    mesh_name_pairs: list[dict[str, Any]] = []
    seen_mesh_pairs: set[tuple[str, str, str]] = set()
    for stem, static_rows in static_by_mesh.items():
        overlays = [
            o
            for o in overlay_by_mesh.get(stem, [])
            if o.get("overlay_state") == "destroyed"
        ]
        if not overlays:
            continue
        for sp in static_rows:
            s_sum = _placement_summary(sp)
            for ov in overlays:
                dist = _distance_m(sp, {"position": ov.get("position")})
                if dist > mesh_pair_max_distance_m:
                    continue
                key = (stem, s_sum.get("entity_id", ""), ov.get("entity_id", ""))
                if key in seen_mesh_pairs:
                    continue
                seen_mesh_pairs.add(key)
                mesh_name_pairs.append(
                    {
                        "mesh_stem": stem,
                        "intact": s_sum,
                        "destroyed_overlay": ov,
                        "distance_m": round(dist, 3),
                        "match_method": "mesh_stem+proximity",
                    }
                )

    for pair in graph.get("pairs", []):
        for ek_label in ("entity_a_key", "entity_b_key"):
            ek = _parse_hex_key(pair.get(ek_label))
            if ek is None:
                continue
            ov = overlay_by_entity_id.get(ek)
            if ov:
                pair.setdefault("vz_state_by_entity_id", {})[ek_label] = ov

    return {
        "vz_state_placement_count": len(vz_state),
        "destroyed_overlay_count": len(destroyed_overlays),
        "pristine_overlay_count": len(pristine_overlays),
        "entity_id_overlay_matches": entity_id_matches,
        "mesh_name_pairs": mesh_name_pairs,
        "mesh_name_pair_count": len(mesh_name_pairs),
        "destroyed_overlays_sample": destroyed_overlays[:16],
    }


def resolve_destruction_links(
    placements: list[dict[str, Any]],
    *,
    block_type: str = "layers_static",
) -> dict[str, Any]:
    """Build a destruction link graph from placement ECS payloads."""
    entity_index = build_entity_index(placements)
    all_keys = set(entity_index)

    links: list[dict[str, Any]] = []
    unresolved: list[dict[str, Any]] = []
    self_refs: list[dict[str, Any]] = []
    dangerous: list[dict[str, Any]] = []
    building_roots: list[dict[str, Any]] = []

    for p in placements:
        if p.get("block_type", block_type) != block_type:
            continue
        source_key = placement_entity_key_from(p)
        if source_key is None:
            continue

        ecs = p.get("ecs") or {}
        dl = ecs.get("DestructionLink")
        if dl:
            ref0 = _parse_hex_key(dl.get("destruction_ref_key"))
            ref8 = _parse_hex_key(dl.get("destruction_link_key"))
            candidate_keys = [k for k in (ref0, ref8) if k is not None and k != 0]
            resolved_key: int | None = None
            resolution_field: str | None = None

            for field_name, ref_key in (
                ("destruction_ref_key", ref0),
                ("destruction_link_key", ref8),
            ):
                if ref_key is None or ref_key == 0:
                    continue
                if ref_key == source_key:
                    self_refs.append(
                        {
                            "entity": _placement_summary(p),
                            "ref_field": field_name,
                            **_destruction_fields(dl),
                        }
                    )
                    continue
                if ref_key in all_keys:
                    resolved_key = ref_key
                    resolution_field = field_name
                    break

            link_row: dict[str, Any] = {
                "source": _placement_summary(p),
                "source_entity_key": _hex_key(source_key),
                **_destruction_fields(dl),
                "resolved_via": resolution_field,
                "target_entity_key": _hex_key(resolved_key),
            }

            if resolved_key is not None:
                targets = entity_index.get(resolved_key, [])
                link_row["target"] = _placement_summary(targets[0])
                if len(targets) > 1:
                    link_row["target_duplicates"] = len(targets)
                link_row["distance_m"] = round(_distance_m(p, targets[0]), 3)
                links.append(link_row)
            else:
                link_row["unresolved_keys"] = [
                    _hex_key(k) for k in candidate_keys if k != source_key
                ]
                unresolved.append(link_row)

        if ecs.get("DangerousBuilding"):
            dangerous.append(_placement_summary(p))
        if ecs.get("BuildingDestruction"):
            building_roots.append(_placement_summary(p))

    pair_keys: set[frozenset[int]] = set()
    by_source: dict[int, dict[str, Any]] = {}
    for row in links:
        sk = _parse_hex_key(row.get("source_entity_key"))
        tk = _parse_hex_key(row.get("target_entity_key"))
        if sk is not None:
            by_source[sk] = row
        if sk is not None and tk is not None:
            rev = by_source.get(tk)
            if rev and _parse_hex_key(rev.get("target_entity_key")) == sk:
                pair_keys.add(frozenset((sk, tk)))

    pairs: list[dict[str, Any]] = []
    seen_pairs: set[frozenset[int]] = set()
    for row in links:
        sk = _parse_hex_key(row.get("source_entity_key"))
        tk = _parse_hex_key(row.get("target_entity_key"))
        if sk is None or tk is None:
            continue
        key = frozenset((sk, tk))
        if key not in pair_keys or key in seen_pairs:
            continue
        seen_pairs.add(key)
        pairs.append(
            {
                "entity_a": row["source"],
                "entity_b": row["target"],
                "entity_a_key": row["source_entity_key"],
                "entity_b_key": row["target_entity_key"],
                "distance_m": row.get("distance_m"),
                "bidirectional": True,
            }
        )

    return {
        "block_type": block_type,
        "placement_count": len(placements),
        "entity_key_count": len(entity_index),
        "destruction_link_count": len(links) + len(unresolved),
        "resolved_link_count": len(links),
        "unresolved_link_count": len(unresolved),
        "self_ref_count": len(self_refs),
        "bidirectional_pair_count": len(pairs),
        "dangerous_building_count": len(dangerous),
        "building_destruction_root_count": len(building_roots),
        "links": links,
        "pairs": pairs,
        "unresolved": unresolved,
        "self_refs": self_refs,
        "dangerous_buildings": dangerous,
        "building_destruction_roots": building_roots,
    }


def _load_placements(path: Path) -> list[dict[str, Any]]:
    doc = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(doc, list):
        return doc
    if isinstance(doc, dict) and isinstance(doc.get("placements"), list):
        return doc["placements"]
    raise ValueError(f"unsupported placements JSON shape: {path}")


def _write_json(path: Path, obj: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(obj, indent=2), encoding="utf-8")


def _self_test() -> int:
    """Synthetic graph: mutual refs, orphan, and vz_state mesh-stem overlay pairing."""
    placements = [
        {
            "block_type": "layers_static",
            "entity_id": "0xaaaaaaaa",
            "entity_name": "Mar_Building_A_intact 0xaaaaaaaa",
            "x": 100.0,
            "y": 10.0,
            "z": 200.0,
            "model_name_hash": "0x5b724250",
            "ecs": {
                "DestructionLink": {
                    "destruction_ref_key": "0xbbbbbbbb",
                    "destruction_u32_1": 1,
                    "destruction_link_key": "0x00000000",
                    "destruction_u32_3": "0x00000000",
                }
            },
        },
        {
            "block_type": "layers_static",
            "entity_id": "0xbbbbbbbb",
            "entity_name": "Mar_Building_A_rubble 0xbbbbbbbb",
            "x": 100.0,
            "y": 10.0,
            "z": 200.0,
            "ecs": {
                "DestructionLink": {
                    "destruction_ref_key": "0xaaaaaaaa",
                    "destruction_u32_1": 1,
                    "destruction_link_key": "0x00000000",
                    "destruction_u32_3": "0x00000000",
                }
            },
        },
        {
            "block_type": "layers_static",
            "entity_id": "0xcccccccc",
            "entity_name": "OrphanBuilding 0xcccccccc",
            "x": 0.0,
            "y": 0.0,
            "z": 0.0,
            "ecs": {
                "DestructionLink": {
                    "destruction_ref_key": "0xdeadbeef",
                    "destruction_u32_1": 0,
                    "destruction_link_key": "0x00000000",
                    "destruction_u32_3": "0x00000000",
                }
            },
        },
    ]
    vz_state = [
        {
            "block_type": "vz_state",
            "entity_id": "0xdddddddd",
            "entity_name": "Mar_Building_A_destroyed 0xdddddddd",
            "source": "vz_state_mar_city_destroyed_P000_Q3.block",
            "position": {"x": 100.1, "y": 10.0, "z": 200.1},
        },
    ]
    graph = resolve_destruction_links(placements)
    assert graph["resolved_link_count"] == 2, graph
    assert graph["unresolved_link_count"] == 1, graph
    assert graph["bidirectional_pair_count"] == 1, graph

    xref = cross_reference_vz_state(placements, vz_state, graph)
    assert xref["destroyed_overlay_count"] == 1, xref
    assert xref["mesh_name_pair_count"] >= 2, xref  # both intact entities near overlay

    print("destruction_link_resolver self-test OK")
    print(
        f"  resolved={graph['resolved_link_count']} "
        f"mesh_pairs={xref['mesh_name_pair_count']}"
    )
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Resolve DestructionLink ref keys to entity pairs")
    ap.add_argument(
        "--layers-static",
        type=Path,
        default=Path("output/placements/layers_static.json"),
        help="Placements JSON with merged ECS (from ecs_metadata_extract.py)",
    )
    ap.add_argument(
        "--vz-state-glob",
        default=None,
        help='Glob for vz_state JSON (e.g. "output/placements/vz_state/*.json")',
    )
    ap.add_argument(
        "--vz-state-json",
        type=Path,
        default=None,
        help="Single merged all_vz_state.json (alternative to --vz-state-glob)",
    )
    ap.add_argument(
        "--mesh-pair-distance",
        type=float,
        default=5.0,
        help="Max metres between layers_static and vz_state for mesh_stem pairing",
    )
    ap.add_argument(
        "--out",
        type=Path,
        default=Path("output/placements/destruction_graph.json"),
    )
    ap.add_argument("--self-test", action="store_true", help="Run synthetic resolver test")
    args = ap.parse_args()

    if args.self_test:
        return _self_test()

    if not args.layers_static.is_file():
        print(
            f"error: missing {args.layers_static} — run make extract-placements, "
            "or use --self-test",
            file=sys.stderr,
        )
        return 1

    placements = _load_placements(args.layers_static)
    graph = resolve_destruction_links(placements)

    vz_rows: list[dict[str, Any]] = []
    if args.vz_state_json is not None and args.vz_state_json.is_file():
        doc = json.loads(args.vz_state_json.read_text(encoding="utf-8"))
        if isinstance(doc, list):
            vz_rows = [p for p in doc if p.get("block_type") == "vz_state"]
        elif isinstance(doc, dict) and isinstance(doc.get("placements"), list):
            vz_rows = [p for p in doc["placements"] if p.get("block_type") == "vz_state"]
    elif args.vz_state_glob:
        vz_rows = load_vz_state_placements(args.vz_state_glob)

    if vz_rows:
        graph["vz_state_cross_reference"] = cross_reference_vz_state(
            placements,
            vz_rows,
            graph,
            mesh_pair_max_distance_m=args.mesh_pair_distance,
        )

    _write_json(args.out, graph)
    print_msg = (
        f"Wrote {args.out}: "
        f"{graph['resolved_link_count']} resolved, "
        f"{graph['unresolved_link_count']} unresolved, "
        f"{graph['bidirectional_pair_count']} bidirectional pairs"
    )
    if vz_rows:
        xref = graph["vz_state_cross_reference"]
        print_msg += (
            f", {xref['mesh_name_pair_count']} mesh-name overlay pairs "
            f"({xref['destroyed_overlay_count']} destroyed overlays)"
        )
    print(print_msg)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
