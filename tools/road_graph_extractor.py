#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build a road-network graph from Road / RoadIntersection ECS payloads.

Reads ``layers_static.json`` (with merged ``ecs`` from ``ecs_metadata_extract.py``)
or a standalone ``ecs_components.json`` plus placements. Emits nodes (intersections
and optional road-segment anchors) and edges (road segments linking intersection keys).

Payload layouts follow ``docs/schm_type_codes.md`` (DLC roads block schm validation).
Intersection endpoint semantics (which u32 is start vs end) are inferred by
cross-checking refs against the RoadIntersection entity-key set — not confirmed
from engine source.

Usage:
    .venv/bin/python3 tools/road_graph_extractor.py \\
        --placements output/placements/layers_static.json \\
        --out output/placements/road_graph.json

    .venv/bin/python3 tools/road_graph_extractor.py \\
        --placements output/placements/layers_static.json \\
        --ecs output/placements/ecs_components.json \\
        --bbox -1200 1400 -1100 600 \\
        --out output/placements/maracaibo_road_graph.json \\
        --export-geojson output/placements/maracaibo_road_graph.geojson

    .venv/bin/python3 tools/road_graph_extractor.py --self-test
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

from ucfx_ecs_codec import (  # noqa: E402
    decode_road_intersection_payload,
    decode_road_payload,
    merge_ecs_into_placements,
    placement_entity_key,
)

ROAD_PAYLOAD_SIZE = 40
ROAD_INTERSECTION_PAYLOAD_SIZE = 124

# Maracaibo demo horizontal bbox (game LH metres); see ``make filter-maracaibo-placements``.
MARACAIBO_BBOX = (-1200.0, 1400.0, -1100.0, 600.0)

# Synthetic self-test expects these counts (fully wired mini graph).
SELF_TEST_EXPECTED_STATS = {
    "intersection_nodes": 2,
    "road_anchor_nodes": 0,
    "edges": 2,
    "edges_intersection_to_intersection": 1,
    "edges_partial": 1,
    "edges_unresolved": 0,
}


def _entity_key_from_placement(p: dict[str, Any]) -> int | None:
    eid = p.get("entity_id")
    if isinstance(eid, str) and eid.startswith("0x"):
        try:
            return int(eid, 16)
        except ValueError:
            pass
    return placement_entity_key(p.get("entity_name"))


def _key_hex(key: int) -> str:
    return f"0x{key:08x}"


def _ecs_entry_bytes(ecs_comp: dict[str, Any]) -> bytes | None:
    hx = ecs_comp.get("payload_hex")
    if isinstance(hx, str) and hx:
        try:
            return bytes.fromhex(hx)
        except ValueError:
            return None
    return None


def _road_fields_from_ecs(ecs_comp: dict[str, Any]) -> dict[str, Any] | None:
    """Prefer pre-decoded merge fields; fall back to raw hex."""
    if any(k.startswith("road_") for k in ecs_comp):
        return {k: v for k, v in ecs_comp.items() if k.startswith("road_")}
    raw = _ecs_entry_bytes(ecs_comp)
    if raw is None or len(raw) < ROAD_PAYLOAD_SIZE:
        return None
    return decode_road_payload(raw)


def _intersection_fields_from_ecs(ecs_comp: dict[str, Any]) -> dict[str, Any] | None:
    if any(k.startswith("intersection_") for k in ecs_comp):
        return {k: v for k, v in ecs_comp.items() if k.startswith("intersection_")}
    raw = _ecs_entry_bytes(ecs_comp)
    if raw is None or len(raw) < ROAD_INTERSECTION_PAYLOAD_SIZE:
        return None
    return decode_road_intersection_payload(raw)


def _position_from_placement(p: dict[str, Any]) -> dict[str, float] | None:
    pos = p.get("position")
    if isinstance(pos, dict) and {"x", "y", "z"} <= pos.keys():
        return {
            "x": float(pos["x"]),
            "y": float(pos["y"]),
            "z": float(pos["z"]),
        }
    for axis in ("x", "y", "z"):
        if axis in p:
            return {
                "x": float(p.get("x", 0.0)),
                "y": float(p.get("y", 0.0)),
                "z": float(p.get("z", 0.0)),
            }
    return None


def _dist3(a: dict[str, float], b: dict[str, float]) -> float:
    return math.sqrt(
        (a["x"] - b["x"]) ** 2 + (a["y"] - b["y"]) ** 2 + (a["z"] - b["z"]) ** 2
    )


def _in_bbox(pos: dict[str, float], bbox: dict[str, float] | None) -> bool:
    if bbox is None:
        return True
    return (
        bbox["x_min"] <= pos["x"] <= bbox["x_max"]
        and bbox["z_min"] <= pos["z"] <= bbox["z_max"]
        and bbox["y_min"] <= pos["y"] <= bbox["y_max"]
    )


def _load_placements(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("placements"), list):
        return data["placements"]
    raise ValueError(f"unexpected placements JSON shape: {path}")


def _load_ecs_records(path: Path) -> list[dict[str, Any]]:
    data = json.loads(path.read_text(encoding="utf-8"))
    if isinstance(data, list):
        return data
    if isinstance(data, dict) and isinstance(data.get("records"), list):
        return data["records"]
    raise ValueError(f"unexpected ecs JSON shape: {path}")


def validate_road_topology(graph: dict[str, Any], *, endpoint_warn_m: float = 250.0) -> dict[str, Any]:
    """Validate node/edge consistency; return errors, warnings, and counts."""
    node_ids = {n["id"] for n in graph.get("nodes", [])}
    intersection_ids = {
        n["id"] for n in graph.get("nodes", []) if n.get("kind") == "intersection"
    }
    pos_by_id = {
        n["id"]: n["position"]
        for n in graph.get("nodes", [])
        if isinstance(n.get("position"), dict)
    }

    errors: list[str] = []
    warnings: list[str] = []
    dangling_refs = 0
    self_loops = 0
    connected_intersections: set[str] = set()

    for edge in graph.get("edges", []):
        src = edge.get("source_node_id")
        dst = edge.get("target_node_id")
        topo = edge.get("topology")
        if src == dst and src is not None:
            self_loops += 1
            errors.append(f"self-loop edge {edge.get('id')}")
        for end_id, label in ((src, "source"), (dst, "target")):
            if end_id is None:
                continue
            if end_id in intersection_ids:
                connected_intersections.add(end_id)
            if end_id not in node_ids:
                dangling_refs += 1
                msg = f"edge {edge.get('id')} {label} {end_id} not in nodes"
                if topo == "intersection_to_intersection":
                    errors.append(msg)
                else:
                    warnings.append(msg)

        if topo == "intersection_to_intersection":
            for end_id in (src, dst):
                if end_id in intersection_ids:
                    connected_intersections.add(end_id)
            ep_a = edge.get("endpoint_a")
            ep_b = edge.get("endpoint_b")
            if isinstance(ep_a, dict) and isinstance(ep_b, dict):
                seg_len = _dist3(ep_a, ep_b)
                if seg_len < 1.0:
                    warnings.append(f"edge {edge.get('id')}: near-zero segment length ({seg_len:.2f}m)")
            for end_id, ep in ((src, ep_a), (dst, ep_b)):
                if end_id in pos_by_id and isinstance(ep, dict):
                    d = _dist3(pos_by_id[end_id], ep)
                    if d > endpoint_warn_m:
                        warnings.append(
                            f"edge {edge.get('id')}: endpoint {d:.1f}m from node {end_id}"
                        )

    orphan_intersections = intersection_ids - connected_intersections
    anchor_count = sum(1 for n in graph.get("nodes", []) if n.get("kind") == "road_anchor")
    stats = graph.get("stats", {})
    if anchor_count != stats.get("road_anchor_nodes"):
        errors.append(
            f"stats.road_anchor_nodes={stats.get('road_anchor_nodes')} "
            f"but {anchor_count} road_anchor nodes emitted"
        )

    return {
        "ok": len(errors) == 0,
        "errors": errors,
        "warnings": warnings,
        "counts": {
            "node_count": len(node_ids),
            "intersection_count": len(intersection_ids),
            "edge_count": len(graph.get("edges", [])),
            "orphan_intersections": len(orphan_intersections),
            "dangling_edge_refs": dangling_refs,
            "self_loop_edges": self_loops,
            "road_anchor_nodes": anchor_count,
        },
        "orphan_intersection_ids": sorted(orphan_intersections)[:32],
    }


def build_road_graph(
    placements: list[dict[str, Any]],
    *,
    bbox: dict[str, float] | None = None,
) -> dict[str, Any]:
    """Construct nodes + edges from placements that carry Road / RoadIntersection ECS."""
    intersection_keys: set[int] = set()
    intersection_by_key: dict[int, dict[str, Any]] = {}
    roads: list[dict[str, Any]] = []

    for p in placements:
        if p.get("block_type", "layers_static") != "layers_static":
            continue
        ecs = p.get("ecs")
        if not isinstance(ecs, dict):
            continue
        ek = _entity_key_from_placement(p)
        if ek is None:
            continue
        pos = _position_from_placement(p)
        if pos is not None and not _in_bbox(pos, bbox):
            continue

        if "RoadIntersection" in ecs:
            fields = _intersection_fields_from_ecs(ecs["RoadIntersection"])
            if fields is None:
                continue
            intersection_keys.add(ek)
            intersection_by_key[ek] = {
                "entity_key": ek,
                "entity_id": _key_hex(ek),
                "entity_name": p.get("entity_name"),
                "position": pos,
                "ecs": fields,
            }

        if "Road" in ecs:
            fields = _road_fields_from_ecs(ecs["Road"])
            if fields is None:
                continue
            roads.append(
                {
                    "entity_key": ek,
                    "entity_id": _key_hex(ek),
                    "entity_name": p.get("entity_name"),
                    "position": pos,
                    "ecs": fields,
                }
            )

    nodes: list[dict[str, Any]] = []
    for ek, node in sorted(intersection_by_key.items(), key=lambda t: t[0]):
        nodes.append(
            {
                "id": _key_hex(ek),
                "kind": "intersection",
                "entity_key": ek,
                "entity_name": node.get("entity_name"),
                "position": node.get("position"),
                "lane_hints": node["ecs"].get("intersection_vec3s"),
                "refs": node["ecs"].get("intersection_ref_keys"),
            }
        )

    edges: list[dict[str, Any]] = []
    road_anchor_nodes = 0
    for road in roads:
        ecs = road["ecs"]
        ref_a = ecs.get("road_ref_key_0")
        ref_b = ecs.get("road_ref_key_1")
        key_a = ecs.get("road_ref_key_0_int")
        key_b = ecs.get("road_ref_key_1_int")
        endpoint_a = ecs.get("road_endpoint_a")
        endpoint_b = ecs.get("road_endpoint_b")

        a_is_ix = isinstance(key_a, int) and key_a in intersection_keys
        b_is_ix = isinstance(key_b, int) and key_b in intersection_keys

        if a_is_ix and b_is_ix:
            topology = "intersection_to_intersection"
            src_id = ref_a
            dst_id = ref_b
        elif a_is_ix or b_is_ix:
            topology = "intersection_partial"
            src_id = ref_a if a_is_ix else ref_b
            dst_id = ref_b if a_is_ix else ref_a
        else:
            topology = "unresolved_refs"
            src_id = ref_a
            dst_id = ref_b

        edges.append(
            {
                "id": road["entity_id"],
                "kind": "road_segment",
                "entity_key": road["entity_key"],
                "entity_name": road.get("entity_name"),
                "source_node_id": src_id,
                "target_node_id": dst_id,
                "topology": topology,
                "placement_position": road.get("position"),
                "endpoint_a": endpoint_a,
                "endpoint_b": endpoint_b,
                "lane_hashes": [
                    ecs.get("road_lane_hash_0"),
                    ecs.get("road_lane_hash_1"),
                ],
            }
        )

        if topology == "unresolved_refs" and road.get("position") is not None:
            road_anchor_nodes += 1
            nodes.append(
                {
                    "id": road["entity_id"],
                    "kind": "road_anchor",
                    "entity_key": road["entity_key"],
                    "entity_name": road.get("entity_name"),
                    "position": road["position"],
                    "note": "Road segment without intersection key match on ref_0/ref_1",
                    "unmatched_refs": [ref_a, ref_b],
                }
            )

    graph: dict[str, Any] = {
        "schema_version": 1,
        "coordinate_system": "game_lh_metres",
        "source": "layers_static Road + RoadIntersection ECS",
        "topology_note": (
            "Edges link road_ref_key_0/1 to intersection nodes when those u32 keys "
            "appear in the RoadIntersection set. Lane hashes and Vec3 endpoints are "
            "exported raw; lane direction/count/speed are not decoded."
        ),
        "stats": {
            "intersection_nodes": len(intersection_by_key),
            "road_anchor_nodes": road_anchor_nodes,
            "edges": len(edges),
            "edges_intersection_to_intersection": sum(
                1 for e in edges if e["topology"] == "intersection_to_intersection"
            ),
            "edges_partial": sum(1 for e in edges if e["topology"] == "intersection_partial"),
            "edges_unresolved": sum(1 for e in edges if e["topology"] == "unresolved_refs"),
        },
        "nodes": nodes,
        "edges": edges,
    }
    graph["topology_validation"] = validate_road_topology(graph)
    return graph


def export_geojson(graph: dict[str, Any]) -> dict[str, Any]:
    """GeoJSON FeatureCollection: intersection points + road segment lines."""
    features: list[dict[str, Any]] = []
    for node in graph.get("nodes", []):
        pos = node.get("position")
        if not isinstance(pos, dict):
            continue
        features.append(
            {
                "type": "Feature",
                "properties": {
                    "id": node.get("id"),
                    "kind": node.get("kind"),
                    "entity_name": node.get("entity_name"),
                },
                "geometry": {
                    "type": "Point",
                    "coordinates": [pos["x"], pos["z"], pos["y"]],
                },
            }
        )
    for edge in graph.get("edges", []):
        ep_a = edge.get("endpoint_a")
        ep_b = edge.get("endpoint_b")
        if not (isinstance(ep_a, dict) and isinstance(ep_b, dict)):
            continue
        features.append(
            {
                "type": "Feature",
                "properties": {
                    "id": edge.get("id"),
                    "kind": "road_segment",
                    "topology": edge.get("topology"),
                    "source_node_id": edge.get("source_node_id"),
                    "target_node_id": edge.get("target_node_id"),
                },
                "geometry": {
                    "type": "LineString",
                    "coordinates": [
                        [ep_a["x"], ep_a["z"], ep_a["y"]],
                        [ep_b["x"], ep_b["z"], ep_b["y"]],
                    ],
                },
            }
        )
    return {"type": "FeatureCollection", "features": features}


def export_svg(
    graph: dict[str, Any],
    *,
    bbox: tuple[float, float, float, float] | None = None,
    size: int = 800,
    margin: int = 24,
) -> str:
    """Simple top-down XZ SVG (game X right, game Z up on screen)."""
    xs: list[float] = []
    zs: list[float] = []
    for node in graph.get("nodes", []):
        pos = node.get("position")
        if isinstance(pos, dict):
            xs.append(pos["x"])
            zs.append(pos["z"])
    for edge in graph.get("edges", []):
        for ep in (edge.get("endpoint_a"), edge.get("endpoint_b")):
            if isinstance(ep, dict):
                xs.append(ep["x"])
                zs.append(ep["z"])
    if not xs:
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}">'
            "<text x=\"10\" y=\"20\">empty graph</text></svg>"
        )

    if bbox is None:
        x_min, x_max, z_min, z_max = min(xs), max(xs), min(zs), max(zs)
    else:
        x_min, x_max, z_min, z_max = bbox

    span_x = max(x_max - x_min, 1.0)
    span_z = max(z_max - z_min, 1.0)
    inner = size - 2 * margin

    def tx(x: float) -> float:
        return margin + (x - x_min) / span_x * inner

    def tz(z: float) -> float:
        return size - margin - (z - z_min) / span_z * inner

    lines: list[str] = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {size} {size}">',
        f'<rect width="{size}" height="{size}" fill="#1a1a2e"/>',
    ]
    for edge in graph.get("edges", []):
        ep_a, ep_b = edge.get("endpoint_a"), edge.get("endpoint_b")
        if not (isinstance(ep_a, dict) and isinstance(ep_b, dict)):
            continue
        color = {
            "intersection_to_intersection": "#4ade80",
            "intersection_partial": "#fbbf24",
            "unresolved_refs": "#f87171",
        }.get(edge.get("topology", ""), "#94a3b8")
        lines.append(
            f'<line x1="{tx(ep_a["x"]):.1f}" y1="{tz(ep_a["z"]):.1f}" '
            f'x2="{tx(ep_b["x"]):.1f}" y2="{tz(ep_b["z"]):.1f}" '
            f'stroke="{color}" stroke-width="1.5" opacity="0.85"/>'
        )
    for node in graph.get("nodes", []):
        pos = node.get("position")
        if not isinstance(pos, dict):
            continue
        r = 4 if node.get("kind") == "intersection" else 2
        fill = "#60a5fa" if node.get("kind") == "intersection" else "#cbd5e1"
        lines.append(
            f'<circle cx="{tx(pos["x"]):.1f}" cy="{tz(pos["z"]):.1f}" '
            f'r="{r}" fill="{fill}"/>'
        )
    lines.append("</svg>")
    return "\n".join(lines)


def _synthetic_self_test_placements() -> list[dict[str, Any]]:
    """Mini graph: two intersections + one fully linked road + one partial road."""
    ix_a = 0x00A1B2C3
    ix_b = 0x00D4E5F6
    road_main = bytearray(ROAD_PAYLOAD_SIZE)
    struct.pack_into("<I", road_main, 0, ix_a)
    struct.pack_into("<I", road_main, 4, ix_b)
    struct.pack_into("<3f", road_main, 16, 100.0, 5.0, -200.0)
    struct.pack_into("<3f", road_main, 28, 150.0, 5.0, -180.0)

    road_partial = bytearray(ROAD_PAYLOAD_SIZE)
    struct.pack_into("<I", road_partial, 0, ix_a)
    struct.pack_into("<I", road_partial, 4, 0xDEADBEEF)
    struct.pack_into("<3f", road_partial, 16, 90.0, 5.0, -210.0)
    struct.pack_into("<3f", road_partial, 28, 95.0, 5.0, -205.0)

    return [
        {
            "block_type": "layers_static",
            "entity_id": _key_hex(ix_a),
            "entity_name": f"SampleIntersection {_key_hex(ix_a)}",
            "position": {"x": 100.0, "y": 5.0, "z": -200.0},
            "ecs": {
                "RoadIntersection": decode_road_intersection_payload(
                    bytes(ROAD_INTERSECTION_PAYLOAD_SIZE)
                ),
            },
        },
        {
            "block_type": "layers_static",
            "entity_id": _key_hex(ix_b),
            "entity_name": f"SampleIntersection {_key_hex(ix_b)}",
            "position": {"x": 150.0, "y": 5.0, "z": -180.0},
            "ecs": {
                "RoadIntersection": decode_road_intersection_payload(
                    bytes(ROAD_INTERSECTION_PAYLOAD_SIZE)
                ),
            },
        },
        {
            "block_type": "layers_static",
            "entity_id": "0x00000010",
            "entity_name": "SampleRoad_Main 0x00000010",
            "position": {"x": 125.0, "y": 5.0, "z": -190.0},
            "ecs": {"Road": decode_road_payload(bytes(road_main))},
        },
        {
            "block_type": "layers_static",
            "entity_id": "0x00000011",
            "entity_name": "SampleRoad_Partial 0x00000011",
            "position": {"x": 92.0, "y": 5.0, "z": -208.0},
            "ecs": {"Road": decode_road_payload(bytes(road_partial))},
        },
    ]


def _self_test() -> int:
    graph = build_road_graph(_synthetic_self_test_placements())
    stats = graph["stats"]
    for key, expected in SELF_TEST_EXPECTED_STATS.items():
        actual = stats.get(key)
        if actual != expected:
            raise AssertionError(f"stats[{key}]={actual}, expected {expected}")

    validation = graph["topology_validation"]
    if not validation["ok"]:
        raise AssertionError(f"topology validation failed: {validation['errors']}")
    if validation["counts"]["orphan_intersections"] != 0:
        raise AssertionError("expected no orphan intersections in synthetic graph")

    geo = export_geojson(graph)
    if len(geo["features"]) < 4:
        raise AssertionError("GeoJSON export too sparse for synthetic graph")

    svg = export_svg(graph)
    if "<circle" not in svg or "<line" not in svg:
        raise AssertionError("SVG export missing primitives")

    print("road_graph_extractor self-test OK")
    print(f"  stats: {stats}")
    print(f"  validation warnings: {len(validation['warnings'])}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Road graph from Road / RoadIntersection ECS")
    ap.add_argument(
        "--placements",
        type=Path,
        default=None,
        help="layers_static placements JSON (list or {placements: [...]})",
    )
    ap.add_argument(
        "--ecs",
        type=Path,
        default=None,
        help="Optional ecs_components.json to merge before graph build",
    )
    ap.add_argument("--out", type=Path, default=None, help="Output road_graph.json")
    ap.add_argument(
        "--bbox",
        nargs=4,
        metavar=("X_MIN", "X_MAX", "Z_MIN", "Z_MAX"),
        type=float,
        default=None,
        help="Optional horizontal bbox filter (game X/Z); Y unbounded",
    )
    ap.add_argument(
        "--y-min",
        type=float,
        default=-500.0,
        help="BBox Y minimum when --bbox is set (default -500)",
    )
    ap.add_argument(
        "--y-max",
        type=float,
        default=1000.0,
        help="BBox Y maximum when --bbox is set (default 1000)",
    )
    ap.add_argument(
        "--export-geojson",
        type=Path,
        default=None,
        help="Optional GeoJSON path (intersection points + segment lines)",
    )
    ap.add_argument(
        "--export-svg",
        type=Path,
        default=None,
        help="Optional SVG path (top-down XZ); uses --bbox when set",
    )
    ap.add_argument(
        "--self-test",
        action="store_true",
        help="Run synthetic topology test (no input files)",
    )
    ap.add_argument(
        "--sample",
        action="store_true",
        help="Deprecated alias for --self-test (prints graph JSON to stdout)",
    )
    args = ap.parse_args()

    if args.self_test or args.sample:
        if args.sample:
            graph = build_road_graph(_synthetic_self_test_placements())
            print(json.dumps(graph, indent=2))
            return 0
        return _self_test()

    if args.placements is None or args.out is None:
        ap.error("--placements and --out are required unless --self-test")

    placements = _load_placements(args.placements)
    if args.ecs is not None:
        ecs_rows = _load_ecs_records(args.ecs)
        merge_ecs_into_placements(placements, ecs_rows, block_type="layers_static")

    bbox: dict[str, float] | None = None
    bbox_tuple: tuple[float, float, float, float] | None = None
    if args.bbox is not None:
        x_min, x_max, z_min, z_max = args.bbox
        bbox = {
            "x_min": x_min,
            "x_max": x_max,
            "z_min": z_min,
            "z_max": z_max,
            "y_min": args.y_min,
            "y_max": args.y_max,
        }
        bbox_tuple = (x_min, x_max, z_min, z_max)

    graph = build_road_graph(placements, bbox=bbox)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(graph, indent=2), encoding="utf-8")

    if args.export_geojson is not None:
        args.export_geojson.parent.mkdir(parents=True, exist_ok=True)
        args.export_geojson.write_text(
            json.dumps(export_geojson(graph), indent=2), encoding="utf-8"
        )

    if args.export_svg is not None:
        args.export_svg.parent.mkdir(parents=True, exist_ok=True)
        args.export_svg.write_text(export_svg(graph, bbox=bbox_tuple), encoding="utf-8")

    stats = graph["stats"]
    val = graph["topology_validation"]
    print(
        f"Wrote {args.out}: {stats['intersection_nodes']} intersections, "
        f"{stats['edges']} road edges "
        f"({stats['edges_intersection_to_intersection']} fully linked, "
        f"{stats['edges_unresolved']} unresolved); "
        f"validation ok={val['ok']} warnings={len(val['warnings'])}",
        file=sys.stderr,
    )
    if args.export_geojson:
        print(f"Wrote {args.export_geojson}", file=sys.stderr)
    if args.export_svg:
        print(f"Wrote {args.export_svg}", file=sys.stderr)
    return 0 if val["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
