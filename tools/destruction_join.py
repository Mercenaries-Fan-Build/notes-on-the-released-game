#!/usr/bin/env python3
"""Post-stage-2 destruction join.

`destruction_extract` (Rust) writes a `destruction.json` next to each block's
review files: orchestrator blocks carry per-HIER-node states (intact / break_piece
/ static); geometry blocks carry only their INDX (mesh-group -> HIER node). The
state machine lives in the *orchestrator* block, but the meshes live in the
*geometry* block — so neither block alone can tag its submeshes.

This tool joins them. Pass 1 builds a global `model_hash -> {node: state}` index
from every orchestrator `destruction.json`. Pass 2 walks each block's
`submeshes/index.json` and, via that block's own INDX (mesh_group -> node), copies
the orchestrator's state onto each submesh — writing `destruction_state`,
`switch_group`, `hier_node_idx`, and mirroring `damage_state` (the column the
webapp ingest + viewer already read).

Usage: destruction_join.py [REVIEW_ROOT]   (default: output/extracted/review)
"""
from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    review_root = Path(sys.argv[1] if len(sys.argv) > 1 else "output/extracted/review")
    if not review_root.is_dir():
        print(f"destruction_join: no review root at {review_root}", file=sys.stderr)
        return 1

    destr_files = list(review_root.glob("*/*/destruction.json"))

    # Pass 1: global indexes keyed by model hash, from orchestrators — node
    # states (for submeshes), and the full node list + grounded collision hulls
    # (for the geometry block's destruction.json, which the viewer reads).
    states_by_hash: dict[str, dict[int, tuple[str, int | None]]] = {}
    nodes_by_hash: dict[str, list] = {}
    hulls_by_hash: dict[str, list] = {}
    for df in destr_files:
        try:
            d = json.loads(df.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        for md in d.get("orchestrated_models", []):
            nodes = md.get("nodes") or []
            if not nodes:
                continue
            h = md["model_hash"]
            # keep the richest definition if a hash appears in several orchestrators
            if h not in states_by_hash or len(nodes) > len(states_by_hash[h]):
                states_by_hash[h] = {
                    n["hier_node"]: (n["destruction_state"], n.get("switch_group"), n.get("parent"))
                    for n in nodes
                }
                nodes_by_hash[h] = nodes
                hulls_by_hash[h] = md.get("hulls") or []
    print(f"destruction_join: node states for {len(states_by_hash)} model hashes")

    # Pass 2: enrich each block's submeshes/index.json via its own INDX.
    enriched_subs = enriched_blocks = skipped = 0
    for df in destr_files:
        block_dir = df.parent
        sub_idx = block_dir / "submeshes" / "index.json"
        if not sub_idx.exists():
            continue
        try:
            d = json.loads(df.read_text())
            subs = json.loads(sub_idx.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        if not isinstance(subs, list):
            continue

        # primary model: one with an INDX whose hash has known states; pick the
        # longest INDX (covers the most mesh groups).
        cand = [
            md for md in d.get("orchestrated_models", [])
            if md.get("indx") and md["model_hash"] in states_by_hash
        ]
        if not cand:
            continue
        primary = max(cand, key=lambda m: len(m["indx"]))
        indx = primary["indx"]
        states = states_by_hash[primary["model_hash"]]

        changed = False
        unresolved = 0
        for sm in subs:
            mg = sm.get("mesh_group_id")
            if mg is None or mg >= len(indx):
                continue
            node = indx[mg]
            st = states.get(node)
            if st is None:
                unresolved += 1
                continue
            sm["destruction_state"] = st[0]
            sm["damage_state"] = st[0]  # carrier read by webapp ingest + viewer
            sm["switch_group"] = st[1]
            sm["hier_node_idx"] = node
            sm["hier_parent"] = st[2]  # parent node index → lets the viewer build the HIER tree
            enriched_subs += 1
            changed = True
        if changed:
            sub_idx.write_text(json.dumps(subs, indent=2))
            enriched_blocks += 1
        if unresolved:
            skipped += unresolved

    print(
        f"destruction_join: enriched {enriched_subs} submeshes across "
        f"{enriched_blocks} blocks ({skipped} submeshes had no node state)"
    )

    # Pass 3: enrich each block's destruction.json with its models' node tree +
    # grounded collision hulls (resolved from the orchestrator), so a geometry
    # block carries everything the viewer needs to overlay hulls on the model.
    enriched_dj = 0
    for df in destr_files:
        try:
            d = json.loads(df.read_text())
        except (json.JSONDecodeError, OSError):
            continue
        changed = False
        for md in d.get("orchestrated_models", []):
            h = md.get("model_hash")
            if h in nodes_by_hash and not md.get("nodes"):
                md["nodes"] = nodes_by_hash[h]
                md["hulls"] = hulls_by_hash.get(h, [])
                changed = True
        if changed:
            df.write_text(json.dumps(d, indent=2))
            enriched_dj += 1
    print(f"destruction_join: enriched {enriched_dj} block destruction.json with hulls/nodes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
