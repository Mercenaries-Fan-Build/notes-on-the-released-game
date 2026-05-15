#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Cluster animated assets into skeleton families and generate the families index.

A skeleton family is defined by the combination of HIER node count and dominant
animation track count. Assets within the same family can share a manually-authored
skeleton when HIER decode alone is insufficient (e.g. because bone names are stripped).

Reads ``_skeleton_audit.json`` and writes ``_skeleton_families.json``.

Usage::

    ./.venv/bin/python tools/skeleton_families.py --pipeline-root ./output
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))


def build_families(audit: dict[str, Any]) -> dict[str, Any]:
    """Cluster animgroup slugs into skeleton families."""
    track_counts: dict[str, int] = {}
    for slug, tracks in audit.get("animgroup_tracks", {}).items():
        if tracks:
            track_counts[slug] = max(set(tracks), key=tracks.count)

    hier_by_slug: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for m in audit.get("meshes_with_hier", []):
        hier_by_slug[m["slug"]].append(m)

    families: dict[str, dict[str, Any]] = {}
    for slug, tc in sorted(track_counts.items()):
        hier_matches = hier_by_slug.get(slug, [])
        hier_sizes = sorted(set(m["hier_bytes"] for m in hier_matches)) if hier_matches else []
        family_id = f"tracks_{tc}"
        if family_id not in families:
            families[family_id] = {
                "track_count": tc,
                "slugs": [],
                "hier_sizes": [],
                "representative_slug": slug,
                "representative_blocks": [],
            }
        families[family_id]["slugs"].append(slug)
        for hs in hier_sizes:
            if hs not in families[family_id]["hier_sizes"]:
                families[family_id]["hier_sizes"].append(hs)
        if not families[family_id]["representative_blocks"] and hier_matches:
            families[family_id]["representative_blocks"] = [
                m["block"] for m in hier_matches[:3]
            ]

    track_dist = Counter(track_counts.values())

    doc: dict[str, Any] = {
        "version": 1,
        "total_animated_slugs": len(track_counts),
        "track_count_distribution": {
            str(k): v for k, v in sorted(track_dist.items())
        },
        "families": families,
    }
    return doc


def main() -> int:
    ap = argparse.ArgumentParser(description="Build skeleton family clusters")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument("--audit-json", type=Path, default=None)
    ap.add_argument("--out", type=Path, default=None)
    args = ap.parse_args()

    root = args.pipeline_root.resolve()
    audit_path = (args.audit_json or (root / "animations" / "_skeleton_audit.json")).resolve()
    out = (args.out or (root / "animations" / "_skeleton_families.json")).resolve()

    if not audit_path.is_file():
        print(f"error: audit file missing: {audit_path}", file=sys.stderr)
        print("Run mesh_ucfx_skeleton_audit.py first.", file=sys.stderr)
        return 1

    audit = json.loads(audit_path.read_text(encoding="utf-8"))
    doc = build_families(audit)

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(
        f"Wrote {out} ({len(doc['families'])} families, "
        f"{doc['total_animated_slugs']} animated slugs)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
