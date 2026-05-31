#!/usr/bin/env python3
"""Merge pipeline outputs into a single Game→UE binding manifest for Editor automation.

Output:
  {output}/ue5_import/ue_game_binding.json
  {output}/ue5_import/ue_binding_report.json

See docs/ue_game_bindings.md and docs/data/ue_game_binding_schema.json.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

_REPO = Path(__file__).resolve().parents[1]
_GAME_SCRIPTS = _REPO / "game-scripts"
if str(_GAME_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_GAME_SCRIPTS))

import mercs2_vz_taxonomy as vz_tax  # noqa: E402

_SKIP_ENTITY_RE = re.compile(
    r"particle|munitions\s*spawner|waypoint|trigger|fow_|ai_?collision|blocker|spawn_?point",
    re.IGNORECASE,
)

GAME_TO_UE_SCALE = 100.0
SEA_LEVEL_M = -36.0
OCEAN_HALF_M = 5000.0


def _load_json(path: Path) -> Any:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def _placements_list(doc: Any) -> list[dict[str, Any]]:
    if doc is None:
        return []
    if isinstance(doc, list):
        return doc
    if isinstance(doc, dict):
        pls = doc.get("placements") or doc.get("records")
        if isinstance(pls, list):
            return pls
    return []


def _hibernation_min_draw_cm(u8_0: int) -> tuple[float, str]:
    """Hypothesis: larger u8_0 → closer activation → smaller draw distance."""
    tier = max(0, min(255, int(u8_0)))
    return (float((256 - tier) * 400), "hypothesis")


def _build_visibility_presets(prefix: str = "VZ") -> dict[str, Any]:
    return {
        "act1_default": {
            "activate_parents": [
                f"{prefix}_Act1",
                f"{prefix}_Pristine",
                "Mercs2_BaseWorld",
            ],
            "unload_parents": [
                f"{prefix}_Act2",
                f"{prefix}_Act3",
                f"{prefix}_Destroyed",
                f"{prefix}_Staging",
                f"{prefix}_Defenses",
                f"{prefix}_Captured",
                f"{prefix}_Contract",
                f"{prefix}_Other",
            ],
        },
        "pristine_only": {
            "activate_parents": [f"{prefix}_Act1", f"{prefix}_Pristine", "Mercs2_BaseWorld"],
            "unload_parents": [
                f"{prefix}_Act2",
                f"{prefix}_Act3",
                f"{prefix}_Destroyed",
                f"{prefix}_Staging",
                f"{prefix}_Defenses",
                f"{prefix}_Captured",
                f"{prefix}_Contract",
                f"{prefix}_Other",
            ],
        },
    }


def _placement_visibility_for_overlay(info: vz_tax.OverlayInfo) -> str:
    if vz_tax.initial_runtime_activated(info):
        return "visible"
    return "hidden"


def _build_vz_bindings(
    placements: list[dict[str, Any]],
    vz_act_manifest: dict[str, Any] | None,
) -> tuple[list[dict[str, Any]], dict[str, str]]:
    bindings: list[dict[str, Any]] = []
    placement_vis: dict[str, str] = {}
    seen_sources: set[str] = set()

    overlay_meta: dict[str, dict[str, Any]] = {}
    if isinstance(vz_act_manifest, dict):
        overlay_meta = vz_act_manifest.get("overlays") or {}

    by_source: dict[str, int] = {}
    for p in placements:
        src = str(p.get("source", ""))
        if src:
            by_source[src] = by_source.get(src, 0) + 1

    for src, count in sorted(by_source.items()):
        if src in seen_sources:
            continue
        seen_sources.add(src)
        info = vz_tax.parse_overlay_source(src)
        parent, region, leaf = vz_tax.data_layer_hierarchy(src)
        meta = overlay_meta.get(src, {})
        runtime = "activated" if vz_tax.initial_runtime_activated(info) else "unloaded"
        vis = _placement_visibility_for_overlay(info)
        placement_vis[src] = vis

        bindings.append(
            {
                "id": f"vz_overlay.{info.stem}",
                "kind": "vz_overlay",
                "confidence": "verified",
                "game_source": {
                    "type": "vz_state",
                    "source": src,
                    "stem": info.stem,
                    "placement_count": count,
                },
                "ue": {
                    "system": "DataLayer",
                    "parent": parent,
                    "region": region,
                    "leaf": leaf,
                },
                "runtime_default": runtime,
                "fields": {
                    "act": info.act,
                    "region": info.region or meta.get("region"),
                    "parent_kind": info.parent_kind,
                    "mission_id": info.mission_id,
                    "faction": info.faction,
                    "tags": sorted(info.tags),
                    "placement_visibility": vis,
                },
            }
        )

    return bindings, placement_vis


def _build_lights(placements: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for p in placements:
        ecs = p.get("ecs") or {}
        light = ecs.get("LightObject")
        if not light:
            continue
        r = float(light.get("r", light.get("light_color_r", 1.0)))
        g = float(light.get("g", light.get("light_color_g", 1.0)))
        b = float(light.get("b", light.get("light_color_b", 1.0)))
        intensity = float(light.get("intensity", light.get("light_intensity", 5000.0)))
        radius_m = float(
            light.get("attenuation_radius", light.get("light_radius", 10.0))
        )
        out.append(
            {
                "entity_id": p.get("entity_id"),
                "entity_name": p.get("entity_name"),
                "source": p.get("source"),
                "position": {
                    "x": p.get("x"),
                    "y": p.get("y"),
                    "z": p.get("z"),
                },
                "ue": {
                    "actor_class": "PointLight",
                    "intensity": intensity,
                    "radius_m": radius_m,
                    "color_rgb": [r, g, b],
                },
                "confidence": "verified",
            }
        )
    return out


def _build_hibernation(placements: list[dict[str, Any]]) -> list[dict[str, Any]]:
    out: list[dict[str, Any]] = []
    for p in placements:
        ecs = p.get("ecs") or {}
        hib = ecs.get("HibernationControl")
        if not hib:
            continue
        u8_0 = int(hib.get("hibernation_u8_0", hib.get("u8_0", 0)) or 0)
        min_cm, conf = _hibernation_min_draw_cm(u8_0)
        out.append(
            {
                "entity_id": p.get("entity_id"),
                "entity_name": p.get("entity_name"),
                "position": {"x": p.get("x"), "y": p.get("y"), "z": p.get("z")},
                "hibernation_u8_0": u8_0,
                "hibernation_u8_1": hib.get("hibernation_u8_1"),
                "min_draw_distance_cm": min_cm,
                "confidence": conf,
            }
        )
    return out


def _build_road_edges(road_graph: dict[str, Any] | None, *, max_edges: int) -> list[dict[str, Any]]:
    if not road_graph:
        return []
    edges = road_graph.get("edges") or []
    out: list[dict[str, Any]] = []
    for edge in edges:
        if len(out) >= max_edges:
            break
        ea = edge.get("endpoint_a")
        eb = edge.get("endpoint_b")
        if not ea or not eb:
            continue
        out.append(
            {
                "id": edge.get("id"),
                "entity_name": edge.get("entity_name"),
                "topology": edge.get("topology"),
                "endpoint_a": ea,
                "endpoint_b": eb,
                "confidence": "verified",
            }
        )
    return out


def _build_destruction_pairs(graph: dict[str, Any] | None) -> list[dict[str, Any]]:
    if not graph:
        return []
    out: list[dict[str, Any]] = []
    for pair in graph.get("pairs") or []:
        ent_a = pair.get("entity_a") if isinstance(pair.get("entity_a"), dict) else {}
        ent_b = pair.get("entity_b") if isinstance(pair.get("entity_b"), dict) else {}
        out.append(
            {
                "entity_a": ent_a,
                "entity_b": ent_b,
                "entity_a_key": pair.get("entity_a_key") or ent_a.get("entity_id"),
                "entity_b_key": pair.get("entity_b_key") or ent_b.get("entity_id"),
                "entity_a_name": ent_a.get("entity_name"),
                "entity_b_name": ent_b.get("entity_name"),
                "distance_m": pair.get("distance_m"),
                "rubble_data_layer": "VZ_Destroyed",
                "confidence": "verified",
            }
        )
    return out


def _static_placement_visibility(
    static_placements: list[dict[str, Any]],
) -> dict[str, str]:
    """Default visibility for layers_static sources (always visible unless skip entity)."""
    vis: dict[str, str] = {}
    for p in static_placements:
        entity = str(p.get("entity_name") or "")
        if _SKIP_ENTITY_RE.search(entity):
            vis[str(p.get("source", "layers_static"))] = "skip"
    return vis


def build_manifest(
    output_root: Path,
    *,
    road_edge_cap: int = 5000,
) -> tuple[dict[str, Any], dict[str, Any]]:
    output_root = output_root.resolve()
    placements_dir = output_root / "placements"
    ue5_dir = output_root / "ue5_import"
    ue5_dir.mkdir(parents=True, exist_ok=True)

    inputs_present: list[str] = []
    inputs_missing: list[str] = []
    gaps: list[dict[str, str]] = []

    def _track(path: Path, label: str) -> Any:
        data = _load_json(path)
        if data is None:
            inputs_missing.append(label)
            return None
        inputs_present.append(label)
        return data

    static_doc = _track(placements_dir / "layers_static.json", "layers_static.json")
    vz_doc = _track(placements_dir / "vz_state" / "all_vz_state.json", "all_vz_state.json")
    vz_act = _track(placements_dir / "vz_act_layer_manifest.json", "vz_act_layer_manifest.json")
    c3_doc = _track(placements_dir / "c3_cell_manifest.json", "c3_cell_manifest.json")
    road_graph = _track(placements_dir / "road_graph.json", "road_graph.json")
    destruction_graph = _track(placements_dir / "destruction_graph.json", "destruction_graph.json")
    water_doc = _track(output_root / "watermap_decode.json", "watermap_decode.json")

    static_placements = _placements_list(static_doc)
    vz_placements = _placements_list(vz_doc)

    vz_bindings, vz_vis = _build_vz_bindings(vz_placements, vz_act)
    static_vis = _static_placement_visibility(static_placements)
    placement_visibility = {**static_vis, **vz_vis}

    lights = _build_lights(static_placements)
    hibernation = _build_hibernation(static_placements)
    road_edges = _build_road_edges(road_graph, max_edges=road_edge_cap)
    destruction_pairs = _build_destruction_pairs(destruction_graph)

    sea_m = SEA_LEVEL_M

    def _sea_level_from_water_doc(doc: dict[str, Any]) -> float | None:
        sl = doc.get("sea_level_m")
        if isinstance(sl, dict) and sl.get("value") is not None:
            return float(sl["value"])
        if isinstance(sl, (int, float)):
            return float(sl)
        watr = doc.get("watr")
        if isinstance(watr, dict):
            inner = _sea_level_from_water_doc(watr)
            if inner is not None:
                return inner
            wm = watr.get("world_mapping")
            if isinstance(wm, dict):
                return _sea_level_from_water_doc(wm)
        return None

    if isinstance(water_doc, dict):
        parsed = _sea_level_from_water_doc(water_doc)
        if parsed is not None:
            sea_m = parsed

    water_binding = {
        "sea_level_m": sea_m,
        "sea_level_ue_cm": sea_m * GAME_TO_UE_SCALE,
        "ocean_half_m": OCEAN_HALF_M,
        "grid_size": 257,
        "cell_size_m": 32.0,
        "confidence": "verified" if water_doc else "gap",
    }
    if not water_doc:
        gaps.append(
            {
                "id": "water.raster",
                "confidence": "gap",
                "note": "Run watermap_decode.py → output/watermap_decode.json",
            }
        )

    world_cells: dict[str, Any] = {
        "data_layer": "Mercs2_BaseWorld",
        "runtime_default": "activated",
        "cell_count": 0,
        "cells": [],
        "confidence": "verified",
        "note": "c3 blocks carry no act metadata; position from grid ID only",
    }
    if isinstance(c3_doc, dict):
        cells = c3_doc.get("cells") or []
        world_cells["cell_count"] = len(cells)
        world_cells["cells"] = cells
    else:
        gaps.append(
            {
                "id": "world_cells.manifest",
                "confidence": "gap",
                "note": "make build-c3-cell-manifest",
            }
        )

    terrain_binding = {
        "kind": "low_res_terrain",
        "review_glb_hint": "review/batch_vz/**/low_res_terrain**/mesh_scene.glb",
        "placement": "origin",
        "data_layer": "Mercs2_BaseWorld",
        "confidence": "verified",
    }

    bindings: list[dict[str, Any]] = list(vz_bindings)
    bindings.append(
        {
            "id": "terrain.low_res",
            "kind": "terrain",
            "confidence": "verified",
            "game_source": {"type": "low_res_terrain"},
            "ue": {"system": "StaticMeshActor", "placement": "origin"},
            "runtime_default": "activated",
        }
    )
    bindings.append(
        {
            "id": "water.ocean",
            "kind": "water",
            "confidence": water_binding["confidence"],
            "game_source": {"type": "watermap", "watr": True},
            "ue": {"system": "WaterBodyOcean", "sea_level_ue_cm": water_binding["sea_level_ue_cm"]},
            "runtime_default": "activated",
        }
    )

    if not hibernation:
        gaps.append(
            {
                "id": "hibernation.ecs",
                "confidence": "gap",
                "note": "ECS merge required on layers_static (extract-placements)",
            }
        )
    else:
        gaps.append(
            {
                "id": "hibernation.distance_formula",
                "confidence": "hypothesis",
                "note": "min_draw_distance_cm = (256 - hibernation_u8_0) * 400",
            }
        )

    manifest: dict[str, Any] = {
        "schema_version": 1,
        "meta": {
            "output_root": str(output_root),
            "generated_by": "tools/build_ue_game_binding.py",
            "generated_at": datetime.now(timezone.utc).isoformat(),
            "inputs_present": inputs_present,
            "inputs_missing": inputs_missing,
            "gaps": gaps,
            "counts": {
                "vz_overlay_bindings": len(vz_bindings),
                "lights": len(lights),
                "hibernation": len(hibernation),
                "road_edges": len(road_edges),
                "destruction_pairs": len(destruction_pairs),
                "world_cells": world_cells.get("cell_count", 0),
                "placement_visibility_rules": len(placement_visibility),
            },
        },
        "presets": {"visibility_default": "act1_default"},
        "visibility_preset": _build_visibility_presets("VZ"),
        "bindings": bindings,
        "water": water_binding,
        "terrain": terrain_binding,
        "world_cells": world_cells,
        "lights": lights,
        "hibernation": hibernation,
        "road_edges": road_edges,
        "destruction_pairs": destruction_pairs,
        "placement_visibility": placement_visibility,
    }

    report = {
        "manifest_path": str(ue5_dir / "ue_game_binding.json"),
        "inputs_present": inputs_present,
        "inputs_missing": inputs_missing,
        "gaps": gaps,
        "counts": manifest["meta"]["counts"],
    }
    return manifest, report


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument(
        "--output",
        type=Path,
        default=_REPO / "output",
        help="Pipeline output root (default: repo output/)",
    )
    ap.add_argument(
        "--road-edge-cap",
        type=int,
        default=5000,
        help="Max road edges in manifest (default 5000)",
    )
    args = ap.parse_args()

    manifest, report = build_manifest(args.output, road_edge_cap=args.road_edge_cap)
    out_dir = args.output.resolve() / "ue5_import"
    out_dir.mkdir(parents=True, exist_ok=True)
    manifest_path = out_dir / "ue_game_binding.json"
    report_path = out_dir / "ue_binding_report.json"
    manifest_path.write_text(
        json.dumps(manifest, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {manifest_path}")
    print(f"Wrote {report_path}")
    if report["inputs_missing"]:
        print("Missing inputs:", ", ".join(report["inputs_missing"]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
