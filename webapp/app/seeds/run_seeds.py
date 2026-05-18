"""Standalone seed runner — can be executed directly to populate reference data
into an existing (migrated) database.

Usage:
    python -m app.seeds.run_seeds [--database-url postgresql://...]
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session

from app.models.base import Base
from app.models.schema import Category, Cutscene, EcsComponentType, Faction, Mission


def parse_cdbsizes(ini_path: Path) -> list[tuple[str, int, int | None]]:
    """Parse cdbsizes.ini into (name, primary, secondary|None) tuples."""
    results = []
    for line in ini_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("[") or line.startswith(";") or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        name = parts[0]
        primary = int(parts[1])
        secondary = int(parts[2]) if len(parts) > 2 else None
        results.append((name, primary, secondary))
    return results


def categorize_ecs(name: str) -> str:
    n = name.lower()
    if n.startswith("_") and "physics" in n:
        return "Physics"
    if n.startswith("ai") or n.startswith("perception") or n.startswith("suspect"):
        return "AI"
    if "weapon" in n or n == "explosive" or n == "sticky":
        return "Weapon"
    if "vehicle" in n or "car" in n or "boat" in n or "helicopter" in n or "tank" in n or "jet" in n:
        return "Vehicle"
    if "animation" in n or "bonectrl" in n or "ragdoll" in n or "bone" in n:
        return "Animation"
    if "camera" in n:
        return "Camera"
    if "sound" in n or "music" in n or "chatter" in n:
        return "Audio"
    if "light" in n or "effect" in n or "particle" in n or "ribbon" in n:
        return "Effects"
    if "road" in n or "lane" in n or "intersection" in n or "path" in n:
        return "Road"
    if "terrain" in n:
        return "Terrain"
    if "cover" in n or "hint" in n:
        return "Cover"
    if "spawn" in n or "population" in n or "squad" in n:
        return "Spawning"
    if "health" in n or "damage" in n or "destruction" in n:
        return "Damage"
    if "entrance" in n or "seat" in n or "rider" in n or "grapple" in n:
        return "Entrance"
    if "physics" in n or "constraint" in n or "buoyancy" in n:
        return "Physics"
    if "controller" in n:
        return "Controller"
    if "runtime" in n or n.startswith("rt"):
        return "Runtime"
    if "flag" in n or "label" in n or "name" in n or "net" in n:
        return "Identity"
    if "model" in n or "material" in n or "blob" in n or "scrub" in n or "lod" in n:
        return "Rendering"
    if "script" in n or "state" in n or "timer" in n or "trigger" in n:
        return "Scripting"
    if "faction" in n or "relationship" in n:
        return "Faction"
    if "door" in n or "alarm" in n or "gate" in n:
        return "Interactive"
    if "region" in n or "zone" in n or "location" in n:
        return "Spatial"
    if "anchor" in n or "connect" in n or "link" in n:
        return "Connection"
    return "General"


CATEGORIES = [
    {"slug": "world_geometry", "name": "World Geometry", "parent": None, "depth": 0, "color_hex": "#4CAF50", "sort_order": 1},
    {"slug": "props", "name": "Props", "parent": None, "depth": 0, "color_hex": "#FF9800", "sort_order": 2},
    {"slug": "vehicles", "name": "Vehicles", "parent": None, "depth": 0, "color_hex": "#2196F3", "sort_order": 3},
    {"slug": "characters", "name": "Characters", "parent": None, "depth": 0, "color_hex": "#9C27B0", "sort_order": 4},
    {"slug": "effects", "name": "Effects", "parent": None, "depth": 0, "color_hex": "#F44336", "sort_order": 5},
    {"slug": "game_logic", "name": "Game Logic", "parent": None, "depth": 0, "color_hex": "#607D8B", "sort_order": 6},
    {"slug": "scripts", "name": "Scripts", "parent": None, "depth": 0, "color_hex": "#795548", "sort_order": 7},
    {"slug": "audio", "name": "Audio", "parent": None, "depth": 0, "color_hex": "#E91E63", "sort_order": 8},
    {"slug": "ui", "name": "UI", "parent": None, "depth": 0, "color_hex": "#00BCD4", "sort_order": 9},
    {"slug": "animations", "name": "Animations", "parent": None, "depth": 0, "color_hex": "#CDDC39", "sort_order": 10},
    {"slug": "data", "name": "Data", "parent": None, "depth": 0, "color_hex": "#9E9E9E", "sort_order": 11},
    {"slug": "meta", "name": "Meta", "parent": None, "depth": 0, "color_hex": "#455A64", "sort_order": 12},
    {"slug": "buildings", "name": "Buildings", "parent": "world_geometry", "depth": 1, "color_hex": "#66BB6A", "sort_order": 1},
    {"slug": "roads", "name": "Roads", "parent": "world_geometry", "depth": 1, "color_hex": "#78909C", "sort_order": 2},
    {"slug": "terrain", "name": "Terrain", "parent": "world_geometry", "depth": 1, "color_hex": "#8D6E63", "sort_order": 3},
    {"slug": "vegetation", "name": "Vegetation", "parent": "world_geometry", "depth": 1, "color_hex": "#43A047", "sort_order": 4},
    {"slug": "fences_walls", "name": "Fences & Walls", "parent": "world_geometry", "depth": 1, "color_hex": "#A1887F", "sort_order": 5},
    {"slug": "water", "name": "Water", "parent": "world_geometry", "depth": 1, "color_hex": "#29B6F6", "sort_order": 6},
    {"slug": "commercial", "name": "Commercial", "parent": "buildings", "depth": 2, "color_hex": "#81C784", "sort_order": 1},
    {"slug": "residential", "name": "Residential", "parent": "buildings", "depth": 2, "color_hex": "#A5D6A7", "sort_order": 2},
    {"slug": "industrial", "name": "Industrial", "parent": "buildings", "depth": 2, "color_hex": "#C8E6C9", "sort_order": 3},
    {"slug": "military", "name": "Military", "parent": "buildings", "depth": 2, "color_hex": "#4E342E", "sort_order": 4},
    {"slug": "skyscraper", "name": "Skyscraper", "parent": "buildings", "depth": 2, "color_hex": "#37474F", "sort_order": 5},
    {"slug": "shanty", "name": "Shanty", "parent": "buildings", "depth": 2, "color_hex": "#D7CCC8", "sort_order": 6},
    {"slug": "church_temple", "name": "Church / Temple", "parent": "buildings", "depth": 2, "color_hex": "#FFF9C4", "sort_order": 7},
    {"slug": "gas_station", "name": "Gas Station", "parent": "buildings", "depth": 2, "color_hex": "#FFCC80", "sort_order": 8},
    {"slug": "warehouse", "name": "Warehouse", "parent": "buildings", "depth": 2, "color_hex": "#BCAAA4", "sort_order": 9},
    {"slug": "road_segments", "name": "Road Segments", "parent": "roads", "depth": 2, "color_hex": "#90A4AE", "sort_order": 1},
    {"slug": "intersections", "name": "Intersections", "parent": "roads", "depth": 2, "color_hex": "#B0BEC5", "sort_order": 2},
    {"slug": "sidewalks", "name": "Sidewalks", "parent": "roads", "depth": 2, "color_hex": "#CFD8DC", "sort_order": 3},
    {"slug": "bridges", "name": "Bridges", "parent": "roads", "depth": 2, "color_hex": "#546E7A", "sort_order": 4},
    {"slug": "terrain_tiles", "name": "Tiles", "parent": "terrain", "depth": 2, "color_hex": "#A1887F", "sort_order": 1},
    {"slug": "terrain_heightmap", "name": "Heightmap", "parent": "terrain", "depth": 2, "color_hex": "#8D6E63", "sort_order": 2},
    {"slug": "terrain_textures", "name": "Textures", "parent": "terrain", "depth": 2, "color_hex": "#6D4C41", "sort_order": 3},
    {"slug": "grass", "name": "Grass", "parent": "vegetation", "depth": 2, "color_hex": "#7CB342", "sort_order": 1},
    {"slug": "trees", "name": "Trees", "parent": "vegetation", "depth": 2, "color_hex": "#558B2F", "sort_order": 2},
    {"slug": "rocks", "name": "Rocks", "parent": "vegetation", "depth": 2, "color_hex": "#5D4037", "sort_order": 3},
    {"slug": "bushes", "name": "Bushes", "parent": "vegetation", "depth": 2, "color_hex": "#689F38", "sort_order": 4},
    {"slug": "street_furniture", "name": "Street Furniture", "parent": "props", "depth": 1, "color_hex": "#FFA726", "sort_order": 1},
    {"slug": "barrels_containers", "name": "Barrels & Containers", "parent": "props", "depth": 1, "color_hex": "#FF7043", "sort_order": 2},
    {"slug": "signs_billboards", "name": "Signs & Billboards", "parent": "props", "depth": 1, "color_hex": "#FFCA28", "sort_order": 3},
    {"slug": "debris", "name": "Debris", "parent": "props", "depth": 1, "color_hex": "#8D6E63", "sort_order": 4},
    {"slug": "furniture_indoor", "name": "Indoor Furniture", "parent": "props", "depth": 1, "color_hex": "#BCAAA4", "sort_order": 5},
    {"slug": "electrical", "name": "Electrical / Utility", "parent": "props", "depth": 1, "color_hex": "#FDD835", "sort_order": 6},
    {"slug": "weapons_ammo", "name": "Weapons & Ammo", "parent": "props", "depth": 1, "color_hex": "#D32F2F", "sort_order": 7},
    {"slug": "vehicles_land", "name": "Land", "parent": "vehicles", "depth": 1, "color_hex": "#42A5F5", "sort_order": 1},
    {"slug": "vehicles_air", "name": "Air", "parent": "vehicles", "depth": 1, "color_hex": "#64B5F6", "sort_order": 2},
    {"slug": "vehicles_sea", "name": "Sea", "parent": "vehicles", "depth": 1, "color_hex": "#90CAF9", "sort_order": 3},
    {"slug": "vehicles_civilian", "name": "Civilian", "parent": "vehicles_land", "depth": 2, "color_hex": "#BBDEFB", "sort_order": 1},
    {"slug": "vehicles_military_land", "name": "Military", "parent": "vehicles_land", "depth": 2, "color_hex": "#1565C0", "sort_order": 2},
    {"slug": "vehicles_tanks", "name": "Tanks", "parent": "vehicles_land", "depth": 2, "color_hex": "#0D47A1", "sort_order": 3},
    {"slug": "npcs", "name": "NPCs", "parent": "characters", "depth": 1, "color_hex": "#AB47BC", "sort_order": 1},
    {"slug": "civilians", "name": "Civilians", "parent": "characters", "depth": 1, "color_hex": "#CE93D8", "sort_order": 2},
    {"slug": "soldiers", "name": "Soldiers", "parent": "characters", "depth": 1, "color_hex": "#7B1FA2", "sort_order": 3},
    {"slug": "player_characters", "name": "Player Characters", "parent": "characters", "depth": 1, "color_hex": "#E1BEE7", "sort_order": 4},
    {"slug": "lights", "name": "Lights", "parent": "effects", "depth": 1, "color_hex": "#EF5350", "sort_order": 1},
    {"slug": "particles", "name": "Particles", "parent": "effects", "depth": 1, "color_hex": "#E57373", "sort_order": 2},
    {"slug": "explosions", "name": "Explosions", "parent": "effects", "depth": 1, "color_hex": "#C62828", "sort_order": 3},
    {"slug": "fire_smoke", "name": "Fire & Smoke", "parent": "effects", "depth": 1, "color_hex": "#FF8A65", "sort_order": 4},
    {"slug": "triggers", "name": "Triggers", "parent": "game_logic", "depth": 1, "color_hex": "#78909C", "sort_order": 1},
    {"slug": "zones_logic", "name": "Zones", "parent": "game_logic", "depth": 1, "color_hex": "#90A4AE", "sort_order": 2},
    {"slug": "spawners_logic", "name": "Spawners", "parent": "game_logic", "depth": 1, "color_hex": "#B0BEC5", "sort_order": 3},
    {"slug": "cover_hints", "name": "Cover Hints", "parent": "game_logic", "depth": 1, "color_hex": "#CFD8DC", "sort_order": 4},
    {"slug": "ai_nodes", "name": "AI Nodes", "parent": "game_logic", "depth": 1, "color_hex": "#546E7A", "sort_order": 5},
    {"slug": "destruction", "name": "Destruction", "parent": "game_logic", "depth": 1, "color_hex": "#37474F", "sort_order": 6},
    {"slug": "mission_scripts", "name": "Mission Scripts", "parent": "scripts", "depth": 1, "color_hex": "#6D4C41", "sort_order": 1},
    {"slug": "patrol_scripts", "name": "Patrol Scripts", "parent": "scripts", "depth": 1, "color_hex": "#8D6E63", "sort_order": 2},
    {"slug": "spawn_scripts", "name": "Spawn Scripts", "parent": "scripts", "depth": 1, "color_hex": "#A1887F", "sort_order": 3},
    {"slug": "ambience", "name": "Ambience", "parent": "audio", "depth": 1, "color_hex": "#F06292", "sort_order": 1},
    {"slug": "music", "name": "Music", "parent": "audio", "depth": 1, "color_hex": "#EC407A", "sort_order": 2},
    {"slug": "voice_over", "name": "Voice Over", "parent": "audio", "depth": 1, "color_hex": "#AD1457", "sort_order": 3},
    {"slug": "sound_effects", "name": "Sound Effects", "parent": "audio", "depth": 1, "color_hex": "#C2185B", "sort_order": 4},
    {"slug": "ui_shell", "name": "Shell", "parent": "ui", "depth": 1, "color_hex": "#26C6DA", "sort_order": 1},
    {"slug": "ui_hud", "name": "HUD", "parent": "ui", "depth": 1, "color_hex": "#00ACC1", "sort_order": 2},
    {"slug": "ui_fonts", "name": "Fonts", "parent": "ui", "depth": 1, "color_hex": "#0097A7", "sort_order": 3},
    {"slug": "ui_loading", "name": "Loading", "parent": "ui", "depth": 1, "color_hex": "#00838F", "sort_order": 4},
    {"slug": "ui_scaleform", "name": "Scaleform", "parent": "ui", "depth": 1, "color_hex": "#006064", "sort_order": 5},
    {"slug": "anim_character", "name": "Character Animations", "parent": "animations", "depth": 1, "color_hex": "#D4E157", "sort_order": 1},
    {"slug": "anim_vehicle", "name": "Vehicle Animations", "parent": "animations", "depth": 1, "color_hex": "#C0CA33", "sort_order": 2},
    {"slug": "anim_hijack", "name": "Hijack Animations", "parent": "animations", "depth": 1, "color_hex": "#AFB42B", "sort_order": 3},
    {"slug": "anim_facial", "name": "Facial Animations", "parent": "animations", "depth": 1, "color_hex": "#9E9D24", "sort_order": 4},
    {"slug": "save_assets", "name": "Save Assets", "parent": "data", "depth": 1, "color_hex": "#BDBDBD", "sort_order": 1},
    {"slug": "precache", "name": "Precache", "parent": "data", "depth": 1, "color_hex": "#9E9E9E", "sort_order": 2},
    {"slug": "localization", "name": "Localization", "parent": "data", "depth": 1, "color_hex": "#757575", "sort_order": 3},
    {"slug": "unknown", "name": "Unknown", "parent": "meta", "depth": 1, "color_hex": "#616161", "sort_order": 1},
    {"slug": "needs_review", "name": "Needs Review", "parent": "meta", "depth": 1, "color_hex": "#FF5722", "sort_order": 2},
]

FACTIONS = [
    {"code": "all", "name": "Allied Nations", "color_hex": "#1976D2", "description": "UN peacekeeping force occupying Venezuela"},
    {"code": "chi", "name": "People's Liberation Army of Venezuela (Chinese)", "color_hex": "#D32F2F", "description": "Chinese-backed faction supporting the Venezuelan government"},
    {"code": "gur", "name": "Guerrillas (PLAV)", "color_hex": "#388E3C", "description": "Venezuelan guerrilla resistance movement"},
    {"code": "oil", "name": "Universal Petroleum", "color_hex": "#FBC02D", "description": "Multinational oil corporation with private military assets"},
    {"code": "pir", "name": "Pirates", "color_hex": "#5D4037", "description": "Caribbean pirates operating along the coast"},
    {"code": "pmc", "name": "PMC (Player)", "color_hex": "#7B1FA2", "description": "Executive Operations private military company (player faction)"},
    {"code": "vza", "name": "Venezuelan Army", "color_hex": "#FF6F00", "description": "Solano's Venezuelan military forces"},
    {"code": "jet", "name": "Jet (Helicopter Services)", "color_hex": "#0288D1", "description": "Eva's helicopter extraction and delivery service"},
    {"code": "mec", "name": "Mechanic", "color_hex": "#455A64", "description": "Misha's vehicle delivery and workshop service"},
]


def seed_database(database_url: str, cdbsizes_path: Path | None = None) -> None:
    engine = create_engine(database_url)

    with Session(engine) as session:
        # Check if already seeded
        existing = session.execute(text("SELECT count(*) FROM factions")).scalar()
        if existing and existing > 0:
            print("Database already seeded (factions exist). Skipping.")
            return

        # Factions
        for f in FACTIONS:
            session.add(Faction(**f))
        session.flush()
        print(f"  Inserted {len(FACTIONS)} factions")

        # Categories
        slug_to_id: dict[str, int] = {}
        for cat in CATEGORIES:
            parent_id = slug_to_id.get(cat["parent"]) if cat["parent"] else None
            parent_slug = cat["parent"]
            if parent_slug:
                grandparent = next((c for c in CATEGORIES if c["slug"] == parent_slug), None)
                if grandparent and grandparent["parent"]:
                    path = f"{grandparent['parent']}/{parent_slug}/{cat['slug']}"
                else:
                    path = f"{parent_slug}/{cat['slug']}"
            else:
                path = cat["slug"]

            obj = Category(
                name=cat["name"],
                slug=cat["slug"],
                parent_id=parent_id,
                depth=cat["depth"],
                path=path,
                color_hex=cat["color_hex"],
                sort_order=cat["sort_order"],
            )
            session.add(obj)
            session.flush()
            slug_to_id[cat["slug"]] = obj.id
        print(f"  Inserted {len(CATEGORIES)} categories")

        # ECS Component Types
        if cdbsizes_path and cdbsizes_path.exists():
            components = parse_cdbsizes(cdbsizes_path)
            for name, primary, secondary in components:
                is_runtime = name.startswith("Runtime") or name.startswith("Rt") or name.startswith("RT")
                session.add(EcsComponentType(
                    name=name,
                    prealloc_primary=primary,
                    prealloc_secondary=secondary,
                    is_runtime=is_runtime,
                    category=categorize_ecs(name),
                ))
            session.flush()
            print(f"  Inserted {len(components)} ECS component types")
        else:
            print("  No cdbsizes.ini provided — skipping ECS component types")

        session.commit()
        print("Seed complete.")


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed the mercs2 database with reference data")
    parser.add_argument(
        "--database-url",
        default="postgresql://mercs2:mercs2@localhost:5432/mercs2",
        help="SQLAlchemy database URL",
    )
    parser.add_argument(
        "--cdbsizes",
        type=Path,
        default=None,
        help="Path to cdbsizes.ini (auto-detected if not provided)",
    )
    args = parser.parse_args()

    if args.cdbsizes is None:
        repo_root = Path(__file__).resolve().parents[3]
        candidate = repo_root / "Mercenaries 2 World in Flames DEMO" / "data" / "cdbsizes.ini"
        if candidate.exists():
            args.cdbsizes = candidate

    seed_database(args.database_url, args.cdbsizes)


if __name__ == "__main__":
    main()
