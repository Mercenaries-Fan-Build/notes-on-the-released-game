#!/usr/bin/env python3
"""Categorize all placement entity names by gameplay function."""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path


# ---------------------------------------------------------------------------
# Category definitions (order matters — first match wins)
# ---------------------------------------------------------------------------
CATEGORY_PATTERNS: list[tuple[str, re.Pattern]] = [
    ("Spawners",        re.compile(r"spawn|soldier|allied|enemy|militia|pla_|vla_|ula_|pirate|rebel|guerilla|merc_npc|guard|sniper|rpg_guy|gunner|_troops|_infantry|_squad|_patrol|reinforcement|_wave", re.I)),
    ("Vehicles",        re.compile(r"veh_|_veh|car_|truck|jeep|tank|apc|heli|chopper|boat|ship|humvee|motorcycle|buggy|technical|ambulance|btr|t72|abrams|blackhawk|huey|apache|mi24|mi28|zodiac|pibber|gunboat|destroyer|carrier|_vehicle", re.I)),
    ("Weapons/Pickups", re.compile(r"ammo|pickup|weapon|crate|supply|drop|munition|grenade|rpg_|c4_|airstrike|bomb|missile|fuel_barrel|explosive|_loot|_collect", re.I)),
    ("Lights",          re.compile(r"^light_|_light$|_light_|lamp|streetlight|floodlight|spotlight|neon_light|headlight", re.I)),
    ("Triggers/Zones",  re.compile(r"trigger|zone|region|volume|boundary|_area|killbox|safezone|checkpoint|waypoint|nav_|navmesh|path_node|spawnpoint_marker", re.I)),
    ("Mission Objects", re.compile(r"objective|target|mission_|quest|intel|briefcase|laptop|_hq|command_post|radio_tower|comm_|antenna|satellite|_emplacement|_fortif|barricade|sandbag|bunker|foxhole|trench|_defense|_outpost_obj", re.I)),
    ("Particles/FX",    re.compile(r"particle|_fx|_effect|smoke|fire|flame|explosion|debris|dust|spark|ember|steam|mist|fog_|cloud_|glow|trail|_vfx", re.I)),
    ("NPCs/Characters", re.compile(r"npc|civilian|character|person|_guy|_man|_woman|_girl|_boy|hostage|prisoner|worker|doctor|_priest|fiona|jennifer|ewan|_boss|commander|general|captain|sergeant|corporal|_leader", re.I)),
    ("Buildings/Props", re.compile(r"building|house|wall|fence|roof|door|window|floor|bridge|tower|church|shop|store|hotel|hospital|office|factory|warehouse|barn|hut|shack|shed|garage|ruin|column|arch|stair|balcony|awning|sign|billboard|pole|post|rail|pipe|cable|wire|barrel|dumpster|container|pallet|bench|table|chair|trash|debris_prop|rubble|scaffold|_prop|_bldg|_struct", re.I)),
]

def categorize(name: str | None) -> str:
    if not name:
        return "Other"
    for cat, pat in CATEGORY_PATTERNS:
        if pat.search(name):
            return cat
    return "Other"


# ---------------------------------------------------------------------------
# 1. vz_state entity categorisation
# ---------------------------------------------------------------------------
def analyse_vz_state(path: Path) -> dict:
    with open(path) as f:
        data = json.load(f)
    placements = data["placements"]

    categories: dict[str, list[str]] = defaultdict(list)
    source_groups: dict[str, list[dict]] = defaultdict(list)

    for p in placements:
        name = p.get("entity_name") or p.get("entity_id") or "unknown"
        cat = categorize(name)
        categories[cat].append(name)
        src = p.get("source", "unknown")
        source_groups[src].append(p)

    print("=" * 80)
    print("VZ_STATE ENTITY CATEGORISATION")
    print(f"Total placements: {len(placements)}  |  Unique entity names: {len(set(p.get('entity_name','') for p in placements))}")
    print("=" * 80)

    for cat in [c for c, _ in CATEGORY_PATTERNS] + ["Other"]:
        names = categories.get(cat, [])
        if not names:
            continue
        unique = sorted(set(n or "" for n in names))
        print(f"\n--- {cat} ({len(names)} placements, {len(unique)} unique names) ---")
        for n in unique[:40]:
            cnt = names.count(n)
            print(f"  [{cnt:>4}x] {n}")
        if len(unique) > 40:
            print(f"  ... and {len(unique) - 40} more unique names")

    # Source-file grouping
    print("\n" + "=" * 80)
    print("VZ_STATE PLACEMENTS BY SOURCE FILE")
    print("=" * 80)

    # Extract readable overlay name from source filename
    def overlay_name(src: str) -> str:
        m = re.search(r"vz_state_(.+?)_P\d+", src)
        return m.group(1) if m else src

    overlay_groups: dict[str, list[dict]] = defaultdict(list)
    for src, items in source_groups.items():
        overlay_groups[overlay_name(src)].extend(items)

    for oname in sorted(overlay_groups.keys()):
        items = overlay_groups[oname]
        names = [p.get("entity_name", "?") for p in items]
        name_counts = Counter(names).most_common()
        cat_counts = Counter(categorize(n) for n in names)
        print(f"\n--- {oname} ({len(items)} placements) ---")
        print(f"  Categories: {dict(cat_counts)}")
        print(f"  Top entities:")
        for n, c in name_counts[:10]:
            print(f"    [{c:>3}x] {n}")
        if len(name_counts) > 10:
            print(f"    ... {len(name_counts) - 10} more")

    return {"categories": {k: len(v) for k, v in categories.items()},
            "overlay_count": len(overlay_groups)}


# ---------------------------------------------------------------------------
# 2. layers_static prefix analysis
# ---------------------------------------------------------------------------
def analyse_layers_static(path: Path) -> None:
    with open(path) as f:
        data = json.load(f)
    placements = data["placements"]

    print("\n" + "=" * 80)
    print("LAYERS_STATIC BASE WORLD COMPOSITION")
    print(f"Total placements: {len(placements)}")
    print("=" * 80)

    # Prefix = everything up to and including the first underscore-delimited word
    prefix_counter: Counter = Counter()
    cat_counter: Counter = Counter()
    all_names: list[str] = []

    for p in placements:
        name = p.get("entity_name", "unknown")
        all_names.append(name)
        cat_counter[categorize(name)] += 1

        # Extract prefix: first token before second underscore, or first word
        parts = name.split("_")
        if len(parts) >= 2:
            prefix = parts[0] + "_" + parts[1]
        else:
            prefix = parts[0]
        prefix_counter[prefix] += 1

    print("\n--- Category breakdown ---")
    for cat, cnt in sorted(cat_counter.items(), key=lambda x: -x[1]):
        pct = 100.0 * cnt / len(placements)
        print(f"  {cat:<25s} {cnt:>6d}  ({pct:5.1f}%)")

    print(f"\n--- Top 60 name prefixes (of {len(prefix_counter)} total) ---")
    for prefix, cnt in prefix_counter.most_common(60):
        pct = 100.0 * cnt / len(placements)
        print(f"  {prefix:<45s} {cnt:>6d}  ({pct:5.1f}%)")

    # PMC-area prefixes specifically
    print("\n--- PMC-area prefixes ---")
    pmc_prefixes = {p: c for p, c in prefix_counter.items()
                    if re.search(r"pmc|_pmc", p, re.I)}
    for prefix, cnt in sorted(pmc_prefixes.items(), key=lambda x: -x[1]):
        print(f"  {prefix:<45s} {cnt:>6d}")

    # Outskirt prefixes
    print("\n--- Outskirt prefixes ---")
    out_prefixes = {p: c for p, c in prefix_counter.items()
                    if re.search(r"outskirt|_outskirt", p, re.I)}
    for prefix, cnt in sorted(out_prefixes.items(), key=lambda x: -x[1]):
        print(f"  {prefix:<45s} {cnt:>6d}")

    # Global prefixes
    print("\n--- Global prefixes ---")
    glob_prefixes = {p: c for p, c in prefix_counter.items()
                    if re.search(r"^_global|global_", p, re.I)}
    for prefix, cnt in sorted(glob_prefixes.items(), key=lambda x: -x[1]):
        print(f"  {prefix:<45s} {cnt:>6d}")


# ---------------------------------------------------------------------------
# 3. ECS component analysis
# ---------------------------------------------------------------------------
def analyse_ecs(path: Path) -> None:
    with open(path) as f:
        data = json.load(f)
    placements = data["placements"]

    print("\n" + "=" * 80)
    print("ECS COMPONENT ANALYSIS")
    print("=" * 80)

    ecs_comp_counter: Counter = Counter()
    ecs_entities: dict[str, list[dict]] = defaultdict(list)
    entities_with_ecs = 0
    entities_without_ecs = 0

    for p in placements:
        ecs = p.get("ecs")
        if ecs and isinstance(ecs, dict) and len(ecs) > 0:
            entities_with_ecs += 1
            for comp_name in ecs.keys():
                ecs_comp_counter[comp_name] += 1
                if len(ecs_entities[comp_name]) < 5:
                    ecs_entities[comp_name].append(p)
        else:
            entities_without_ecs += 1

    print(f"\nEntities WITH ECS components:    {entities_with_ecs:>6d}")
    print(f"Entities WITHOUT ECS components: {entities_without_ecs:>6d}")

    print(f"\n--- ECS Component Counts ---")
    for comp, cnt in ecs_comp_counter.most_common():
        pct = 100.0 * cnt / len(placements)
        print(f"  {comp:<30s} {cnt:>6d}  ({pct:5.1f}%)")

    # Key gameplay components
    key_components = ["ObjectScript", "HibernationControl", "DestructionLink",
                      "LightObject", "BuildingDestruction", "DangerousBuilding",
                      "LandingZone", "StateMachine", "Road", "LineRegion"]

    for comp in key_components:
        examples = ecs_entities.get(comp, [])
        if not examples:
            continue
        print(f"\n--- {comp} — {ecs_comp_counter[comp]} entities, sample names ---")
        names = set()
        for ex in examples:
            name = ex.get("entity_name", "?")
            names.add(name)
        # Get more names from full set
        comp_names: Counter = Counter()
        for p in placements:
            ecs = p.get("ecs")
            if ecs and comp in ecs:
                comp_names[p.get("entity_name", "?")] += 1
        for n, c in comp_names.most_common(15):
            cat = categorize(n)
            print(f"  [{c:>4}x] {n:<55s}  ({cat})")
        if len(comp_names) > 15:
            print(f"  ... {len(comp_names) - 15} more unique names")

    # Combination analysis: entities with multiple ECS components
    print("\n--- Multi-component entities (top combinations) ---")
    combo_counter: Counter = Counter()
    for p in placements:
        ecs = p.get("ecs")
        if ecs and isinstance(ecs, dict) and len(ecs) > 1:
            combo = tuple(sorted(ecs.keys()))
            combo_counter[combo] += 1

    for combo, cnt in combo_counter.most_common(20):
        print(f"  [{cnt:>5}x] {' + '.join(combo)}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    base = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output")

    vz_path = base / "placements" / "vz_state" / "all_vz_state.json"
    ls_path = base / "placements" / "layers_static.json"

    if not vz_path.exists():
        print(f"ERROR: {vz_path} not found"); sys.exit(1)
    if not ls_path.exists():
        print(f"ERROR: {ls_path} not found"); sys.exit(1)

    analyse_vz_state(vz_path)
    analyse_layers_static(ls_path)
    analyse_ecs(ls_path)


if __name__ == "__main__":
    main()
