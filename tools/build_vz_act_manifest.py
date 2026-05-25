#!/usr/bin/env python3
"""Build vz_act_layer_manifest.json from placement sources and save-game layers.

Output: output/placements/vz_act_layer_manifest.json
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

_REPO = Path(__file__).resolve().parents[1]
_GAME_SCRIPTS = _REPO / "game-scripts"
if str(_GAME_SCRIPTS) not in sys.path:
    sys.path.insert(0, str(_GAME_SCRIPTS))

import mercs2_vz_taxonomy as vz_tax  # noqa: E402


def _load_json(path: Path) -> object:
    if not path.is_file():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def _placements_from_vz_state(path: Path) -> list[dict]:
    data = _load_json(path)
    if data is None:
        return []
    if isinstance(data, list):
        return data
    return list(data.get("placements", data.get("records", [])))


def _save_profiles() -> list[dict]:
    path = _REPO / "output" / "knowledge" / "saves.json"
    data = _load_json(path)
    if not isinstance(data, dict):
        return []
    profiles = data.get("profiles", [])
    return profiles if isinstance(profiles, list) else []


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--output",
        type=Path,
        default=_REPO / "output" / "placements" / "vz_act_layer_manifest.json",
    )
    args = parser.parse_args()

    vz_path = _REPO / "output" / "placements" / "vz_state" / "all_vz_state.json"
    placements = _placements_from_vz_state(vz_path)

    by_source: dict[str, int] = Counter()
    overlays: dict[str, dict] = {}
    for p in placements:
        src = str(p.get("source", ""))
        if not src:
            continue
        by_source[src] += 1

    for src, count in sorted(by_source.items()):
        info = vz_tax.parse_overlay_source(src)
        parent, region, leaf = vz_tax.data_layer_hierarchy(src)
        pmc_parent, pmc_region, pmc_leaf = vz_tax.pmc_data_layer_hierarchy(src)
        overlays[src] = {
            "stem": info.stem,
            "placement_count": count,
            "act": info.act,
            "region": info.region,
            "parent_kind": info.parent_kind,
            "faction": info.faction,
            "mission_id": info.mission_id,
            "tags": sorted(info.tags),
            "initial_activated": vz_tax.initial_runtime_activated(info),
            "data_layers": {
                "parent": parent,
                "region": region,
                "leaf": leaf,
            },
            "pmc_data_layers": {
                "parent": pmc_parent,
                "region": pmc_region,
                "leaf": pmc_leaf,
            },
        }

    save_act_layers: dict[str, list[str]] = {}
    for i, prof in enumerate(_save_profiles()):
        harvested = prof.get("harvested", {}) if isinstance(prof, dict) else {}
        layers = harvested.get("vz_layer_strings", [])
        if not isinstance(layers, list):
            continue
        act_layers = sorted(
            {
                s.replace("vz_state_", "")
                for s in layers
                if isinstance(s, str) and any(a in s for a in ("act1", "act2", "act3"))
            }
        )
        mission = prof.get("last_mission") or prof.get("header", {}).get("mission")
        save_act_layers[f"profile_{i}"] = {
            "mission": mission,
            "act_layer_stems": act_layers,
            "act_layer_count": len(act_layers),
        }

    act_blocks = [
        o for o in overlays.values()
        if o.get("act") is not None
    ]

    out_doc = {
        "overlay_count": len(overlays),
        "placement_count": sum(by_source.values()),
        "act_overlay_count": len({o["stem"] for o in act_blocks}),
        "by_parent_kind": dict(Counter(o["parent_kind"] for o in overlays.values())),
        "overlays": overlays,
        "save_game_act_layers": save_act_layers,
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(out_doc, indent=2, ensure_ascii=False) + "\n",
        encoding="utf-8",
    )
    print(f"Wrote {args.output} ({len(overlays)} overlays)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
