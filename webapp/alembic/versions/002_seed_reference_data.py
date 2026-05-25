"""Seed reference data: categories, factions, ECS component types, block types,
review statuses, cutscene metadata, missions

Revision ID: 002
Revises: 001
Create Date: 2026-05-17

"""
from __future__ import annotations

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


# ---------------------------------------------------------------------------
# Hierarchical Categories (~80 entries, max depth 3)
# ---------------------------------------------------------------------------
CATEGORIES = [
    # Root categories (depth=0)
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

    # World Geometry > children (depth=1)
    {"slug": "buildings", "name": "Buildings", "parent": "world_geometry", "depth": 1, "color_hex": "#66BB6A", "sort_order": 1},
    {"slug": "roads", "name": "Roads", "parent": "world_geometry", "depth": 1, "color_hex": "#78909C", "sort_order": 2},
    {"slug": "terrain", "name": "Terrain", "parent": "world_geometry", "depth": 1, "color_hex": "#8D6E63", "sort_order": 3},
    {"slug": "vegetation", "name": "Vegetation", "parent": "world_geometry", "depth": 1, "color_hex": "#43A047", "sort_order": 4},
    {"slug": "fences_walls", "name": "Fences & Walls", "parent": "world_geometry", "depth": 1, "color_hex": "#A1887F", "sort_order": 5},
    {"slug": "water", "name": "Water", "parent": "world_geometry", "depth": 1, "color_hex": "#29B6F6", "sort_order": 6},

    # Buildings > children (depth=2)
    {"slug": "commercial", "name": "Commercial", "parent": "buildings", "depth": 2, "color_hex": "#81C784", "sort_order": 1},
    {"slug": "residential", "name": "Residential", "parent": "buildings", "depth": 2, "color_hex": "#A5D6A7", "sort_order": 2},
    {"slug": "industrial", "name": "Industrial", "parent": "buildings", "depth": 2, "color_hex": "#C8E6C9", "sort_order": 3},
    {"slug": "military", "name": "Military", "parent": "buildings", "depth": 2, "color_hex": "#4E342E", "sort_order": 4},
    {"slug": "skyscraper", "name": "Skyscraper", "parent": "buildings", "depth": 2, "color_hex": "#37474F", "sort_order": 5},
    {"slug": "shanty", "name": "Shanty", "parent": "buildings", "depth": 2, "color_hex": "#D7CCC8", "sort_order": 6},
    {"slug": "church_temple", "name": "Church / Temple", "parent": "buildings", "depth": 2, "color_hex": "#FFF9C4", "sort_order": 7},
    {"slug": "gas_station", "name": "Gas Station", "parent": "buildings", "depth": 2, "color_hex": "#FFCC80", "sort_order": 8},
    {"slug": "warehouse", "name": "Warehouse", "parent": "buildings", "depth": 2, "color_hex": "#BCAAA4", "sort_order": 9},

    # Roads > children (depth=2)
    {"slug": "road_segments", "name": "Road Segments", "parent": "roads", "depth": 2, "color_hex": "#90A4AE", "sort_order": 1},
    {"slug": "intersections", "name": "Intersections", "parent": "roads", "depth": 2, "color_hex": "#B0BEC5", "sort_order": 2},
    {"slug": "sidewalks", "name": "Sidewalks", "parent": "roads", "depth": 2, "color_hex": "#CFD8DC", "sort_order": 3},
    {"slug": "bridges", "name": "Bridges", "parent": "roads", "depth": 2, "color_hex": "#546E7A", "sort_order": 4},

    # Terrain > children (depth=2)
    {"slug": "terrain_tiles", "name": "Tiles", "parent": "terrain", "depth": 2, "color_hex": "#A1887F", "sort_order": 1},
    {"slug": "terrain_heightmap", "name": "Heightmap", "parent": "terrain", "depth": 2, "color_hex": "#8D6E63", "sort_order": 2},
    {"slug": "terrain_textures", "name": "Textures", "parent": "terrain", "depth": 2, "color_hex": "#6D4C41", "sort_order": 3},

    # Vegetation > children (depth=2)
    {"slug": "grass", "name": "Grass", "parent": "vegetation", "depth": 2, "color_hex": "#7CB342", "sort_order": 1},
    {"slug": "trees", "name": "Trees", "parent": "vegetation", "depth": 2, "color_hex": "#558B2F", "sort_order": 2},
    {"slug": "rocks", "name": "Rocks", "parent": "vegetation", "depth": 2, "color_hex": "#5D4037", "sort_order": 3},
    {"slug": "bushes", "name": "Bushes", "parent": "vegetation", "depth": 2, "color_hex": "#689F38", "sort_order": 4},

    # Props > children (depth=1)
    {"slug": "street_furniture", "name": "Street Furniture", "parent": "props", "depth": 1, "color_hex": "#FFA726", "sort_order": 1},
    {"slug": "barrels_containers", "name": "Barrels & Containers", "parent": "props", "depth": 1, "color_hex": "#FF7043", "sort_order": 2},
    {"slug": "signs_billboards", "name": "Signs & Billboards", "parent": "props", "depth": 1, "color_hex": "#FFCA28", "sort_order": 3},
    {"slug": "debris", "name": "Debris", "parent": "props", "depth": 1, "color_hex": "#8D6E63", "sort_order": 4},
    {"slug": "furniture_indoor", "name": "Indoor Furniture", "parent": "props", "depth": 1, "color_hex": "#BCAAA4", "sort_order": 5},
    {"slug": "electrical", "name": "Electrical / Utility", "parent": "props", "depth": 1, "color_hex": "#FDD835", "sort_order": 6},
    {"slug": "weapons_ammo", "name": "Weapons & Ammo", "parent": "props", "depth": 1, "color_hex": "#D32F2F", "sort_order": 7},

    # Vehicles > children (depth=1)
    {"slug": "vehicles_land", "name": "Land", "parent": "vehicles", "depth": 1, "color_hex": "#42A5F5", "sort_order": 1},
    {"slug": "vehicles_air", "name": "Air", "parent": "vehicles", "depth": 1, "color_hex": "#64B5F6", "sort_order": 2},
    {"slug": "vehicles_sea", "name": "Sea", "parent": "vehicles", "depth": 1, "color_hex": "#90CAF9", "sort_order": 3},

    # Vehicles > Land > children (depth=2)
    {"slug": "vehicles_civilian", "name": "Civilian", "parent": "vehicles_land", "depth": 2, "color_hex": "#BBDEFB", "sort_order": 1},
    {"slug": "vehicles_military_land", "name": "Military", "parent": "vehicles_land", "depth": 2, "color_hex": "#1565C0", "sort_order": 2},
    {"slug": "vehicles_tanks", "name": "Tanks", "parent": "vehicles_land", "depth": 2, "color_hex": "#0D47A1", "sort_order": 3},

    # Characters > children (depth=1)
    {"slug": "npcs", "name": "NPCs", "parent": "characters", "depth": 1, "color_hex": "#AB47BC", "sort_order": 1},
    {"slug": "civilians", "name": "Civilians", "parent": "characters", "depth": 1, "color_hex": "#CE93D8", "sort_order": 2},
    {"slug": "soldiers", "name": "Soldiers", "parent": "characters", "depth": 1, "color_hex": "#7B1FA2", "sort_order": 3},
    {"slug": "player_characters", "name": "Player Characters", "parent": "characters", "depth": 1, "color_hex": "#E1BEE7", "sort_order": 4},

    # Effects > children (depth=1)
    {"slug": "lights", "name": "Lights", "parent": "effects", "depth": 1, "color_hex": "#EF5350", "sort_order": 1},
    {"slug": "particles", "name": "Particles", "parent": "effects", "depth": 1, "color_hex": "#E57373", "sort_order": 2},
    {"slug": "explosions", "name": "Explosions", "parent": "effects", "depth": 1, "color_hex": "#C62828", "sort_order": 3},
    {"slug": "fire_smoke", "name": "Fire & Smoke", "parent": "effects", "depth": 1, "color_hex": "#FF8A65", "sort_order": 4},

    # Game Logic > children (depth=1)
    {"slug": "triggers", "name": "Triggers", "parent": "game_logic", "depth": 1, "color_hex": "#78909C", "sort_order": 1},
    {"slug": "zones_logic", "name": "Zones", "parent": "game_logic", "depth": 1, "color_hex": "#90A4AE", "sort_order": 2},
    {"slug": "spawners_logic", "name": "Spawners", "parent": "game_logic", "depth": 1, "color_hex": "#B0BEC5", "sort_order": 3},
    {"slug": "cover_hints", "name": "Cover Hints", "parent": "game_logic", "depth": 1, "color_hex": "#CFD8DC", "sort_order": 4},
    {"slug": "ai_nodes", "name": "AI Nodes", "parent": "game_logic", "depth": 1, "color_hex": "#546E7A", "sort_order": 5},
    {"slug": "destruction", "name": "Destruction", "parent": "game_logic", "depth": 1, "color_hex": "#37474F", "sort_order": 6},

    # Scripts > children (depth=1)
    {"slug": "mission_scripts", "name": "Mission Scripts", "parent": "scripts", "depth": 1, "color_hex": "#6D4C41", "sort_order": 1},
    {"slug": "patrol_scripts", "name": "Patrol Scripts", "parent": "scripts", "depth": 1, "color_hex": "#8D6E63", "sort_order": 2},
    {"slug": "spawn_scripts", "name": "Spawn Scripts", "parent": "scripts", "depth": 1, "color_hex": "#A1887F", "sort_order": 3},

    # Audio > children (depth=1)
    {"slug": "ambience", "name": "Ambience", "parent": "audio", "depth": 1, "color_hex": "#F06292", "sort_order": 1},
    {"slug": "music", "name": "Music", "parent": "audio", "depth": 1, "color_hex": "#EC407A", "sort_order": 2},
    {"slug": "voice_over", "name": "Voice Over", "parent": "audio", "depth": 1, "color_hex": "#AD1457", "sort_order": 3},
    {"slug": "sound_effects", "name": "Sound Effects", "parent": "audio", "depth": 1, "color_hex": "#C2185B", "sort_order": 4},

    # UI > children (depth=1)
    {"slug": "ui_shell", "name": "Shell", "parent": "ui", "depth": 1, "color_hex": "#26C6DA", "sort_order": 1},
    {"slug": "ui_hud", "name": "HUD", "parent": "ui", "depth": 1, "color_hex": "#00ACC1", "sort_order": 2},
    {"slug": "ui_fonts", "name": "Fonts", "parent": "ui", "depth": 1, "color_hex": "#0097A7", "sort_order": 3},
    {"slug": "ui_loading", "name": "Loading", "parent": "ui", "depth": 1, "color_hex": "#00838F", "sort_order": 4},
    {"slug": "ui_scaleform", "name": "Scaleform", "parent": "ui", "depth": 1, "color_hex": "#006064", "sort_order": 5},

    # Animations > children (depth=1)
    {"slug": "anim_character", "name": "Character Animations", "parent": "animations", "depth": 1, "color_hex": "#D4E157", "sort_order": 1},
    {"slug": "anim_vehicle", "name": "Vehicle Animations", "parent": "animations", "depth": 1, "color_hex": "#C0CA33", "sort_order": 2},
    {"slug": "anim_hijack", "name": "Hijack Animations", "parent": "animations", "depth": 1, "color_hex": "#AFB42B", "sort_order": 3},
    {"slug": "anim_facial", "name": "Facial Animations", "parent": "animations", "depth": 1, "color_hex": "#9E9D24", "sort_order": 4},

    # Data > children (depth=1)
    {"slug": "save_assets", "name": "Save Assets", "parent": "data", "depth": 1, "color_hex": "#BDBDBD", "sort_order": 1},
    {"slug": "precache", "name": "Precache", "parent": "data", "depth": 1, "color_hex": "#9E9E9E", "sort_order": 2},
    {"slug": "localization", "name": "Localization", "parent": "data", "depth": 1, "color_hex": "#757575", "sort_order": 3},

    # Meta > children (depth=1)
    {"slug": "unknown", "name": "Unknown", "parent": "meta", "depth": 1, "color_hex": "#616161", "sort_order": 1},
    {"slug": "needs_review", "name": "Needs Review", "parent": "meta", "depth": 1, "color_hex": "#FF5722", "sort_order": 2},
]


# ---------------------------------------------------------------------------
# Factions (9)
# ---------------------------------------------------------------------------
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


# ---------------------------------------------------------------------------
# ECS Component Types (all 338 from cdbsizes.ini)
# Category assignment based on name prefix/domain
# ---------------------------------------------------------------------------
def _categorize_ecs(name: str) -> str:
    """Assign a domain category to an ECS component type by name pattern."""
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
    if "light" in n or "effect" in n or "particle" in n or "ribbon" in n or "red" in n.split("effect"):
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


ECS_COMPONENT_TYPES = [
    # (name, prealloc_primary, prealloc_secondary_or_None)
    ("_BoatPhysics", 160, 32),
    ("_BuildingPhysics", 2048, None),
    ("_CarPhysicsV2", 768, None),
    ("_CarWheel", 2304, None),
    ("_CollapsePhysics", 8, 8),
    ("_DebrisPhysics", 256, None),
    ("_HelicopterPhysics", 160, 32),
    ("_HelicopterPhysicsAi", 160, 32),
    ("_HumanPhysics", 384, 128),
    ("_JetPhysics", 8, 8),
    ("_PropPhysics", 768, None),
    ("_TankPhysics", 128, 64),
    ("Ai", 1024, None),
    ("AiBehavior", 512, None),
    ("AiDriving", 256, None),
    ("AiHelicopter", 256, 128),
    ("AiHintNode", 128, 64),
    ("AiPatrol", 768, None),
    ("AiSkill", 256, 128),
    ("AiUnUsable", 8, 8),
    ("AiWaterZone", 16, 16),
    ("Alarm", 32, 32),
    ("Anchor", 1152, 128),
    ("AnimationController", 16, 16),
    ("AnimationResponse", 64, 64),
    ("Association", 1024, None),
    ("AtmosphereBase", 160, 32),
    ("BlobShadow", 1280, None),
    ("BoneControllerRuntime", 512, None),
    ("BoneCtrlFakeWheel", 1280, None),
    ("BoneCtrlJostle", 8, 8),
    ("BoneCtrlLocalRotation", 192, 64),
    ("BoneCtrlLocalTranslation", 16, 16),
    ("BoneCtrlLookAt", 512, None),
    ("BoneCtrlPhysicsActor", 1024, None),
    ("BoneCtrlRotationCopy", 64, 64),
    ("BoneCtrlStrapOn", 768, None),
    ("BoneCtrlTentacle", 64, 64),
    ("BoneCtrlWind", 96, 32),
    ("BuildingCollapseAnim", 1024, None),
    ("BuildingDestruction", 32, 32),
    ("Buoyancy", 256, None),
    ("CameraCarPreset", 128, 32),
    ("CameraCarPresetLink", 2048, None),
    ("CameraHelicopter", 160, 32),
    ("CameraShake", 384, 128),
    ("CameraTank", 192, 32),
    ("CameraTurret", 768, None),
    ("Carryable", 8, 8),
    ("CashValue", 1024, None),
    ("CenterOfMassInWorld", 8, 8),
    ("ChatterSet", 1280, None),
    ("CheatInfiniteAmmo", 256, 128),
    ("CheatInvincible", 96, 32),
    ("CheatUnkillable", 8, 8),
    ("CircleRegion", 8, 8),
    ("ColorAnimation", 8, 8),
    ("ConnectPoint", 256, None),
    ("ConstraintLink", 32, 32),
    ("ContextAction", 16, 16),
    ("ControlBinding", 48, 16),
    ("ControllerBoat", 64, 64),
    ("ControllerCar", 64, 64),
    ("ControllerHelicopter", 64, 64),
    ("ControllerLadder", 32, 32),
    ("ControllerLW", 16, 16),
    ("ControllerPlayer", 96, 32),
    ("ControllerTank", 32, 32),
    ("ControllerTurret", 256, None),
    ("ControllerVehicle", 16, 16),
    ("ControllerVelocity", 192, 64),
    ("ControllerWeapon", 256, None),
    ("CoverHint", 2048, None),
    ("CoverHintOffset", 1536, 256),
    ("Crusher", 32, 32),
    ("DamageChunks", 32, 32),
    ("DamageKey", 1280, None),
    ("DangerousBuilding", 768, None),
    ("DebrisEffect", 4608, None),
    ("DestructionLink", 1024, None),
    ("Disable3DDecals", 1536, None),
    ("DisableDamageEffect", 768, None),
    ("DisableDecals", 512, None),
    ("DisableMaterialEffect", 8, 8),
    ("Door", 2304, None),
    ("DoorCoupling", 256, None),
    ("DrivingKey", 8, 8),
    ("EffectAiOccluder", 64, 64),
    ("EffectModel", 64, 64),
    ("EffectTemplate", 768, None),
    ("EffectVelocityControl", 2560, None),
    ("EntranceLink", 13312, None),
    ("EntranceParameters", 192, 64),
    ("EntranceToSeat", 512, None),
    ("Equipment", 96, 32),
    ("EquipmentDock", 256, None),
    ("EquipmentLink", 768, None),
    ("ExplosionFudge", 256, 64),
    ("Explosive", 96, 32),
    ("FactionMarker", 1280, None),
    ("FactionValue", 64, 64),
    ("FactionZone", 16, 16),
    ("Flags", 14848, None),
    ("Flammable", 256, None),
    ("FlareObject", 16, 16),
    ("FlightNoise", 64, 32),
    ("GenericLOD", 128, 64),
    ("GrappleParameters", 64, 64),
    ("Health", 3328, None),
    ("HibernationControl", 14080, None),
    ("HomingProjectile", 64, 64),
    ("HomingTarget", 1024, None),
    ("HomingWeapon", 128, 64),
    ("HumanAnimationControllerNEW", 128, 64),
    ("HumanAnimationSet", 384, 128),
    ("HumanAnimationSystem", 384, 128),
    ("HumanCameraModifier", 64, 64),
    ("HumanInventory", 8, 8),
    ("HumanStateMachine", 128, 128),
    ("Ignitor", 96, 32),
    ("InitialAngularVelocity", 32, 32),
    ("InitialAngularVelocityLocalSpace", 8, 8),
    ("InitialLinearVelocity", 16, 16),
    ("InitialLinearVelocityLocalSpace", 8, 8),
    ("IntersectionToIntersection", 256, None),
    ("Label", 6400, None),
    ("LandingZone", 96, 32),
    ("LaneData", 512, 128),
    ("LaneZeroDirection", 256, None),
    ("LightAnimation", 64, 64),
    ("LightObject", 2048, None),
    ("LineRegion", 512, 128),
    ("LocalizedName", 4352, None),
    ("LowResTerrainObject", 512, None),
    ("MassiveComponent", 32, 32),
    ("MaterialControllerRuntime", 512, None),
    ("MaterialCtrlTankTread", 192, 64),
    ("MaterialEmitter", 1024, None),
    ("MaterialMapping", 256, 256),
    ("MeleeCombatant", 384, 128),
    ("Model", 8, 8),
    ("ModelMixeProfile", 512, 128),
    ("ModelName", 4608, None),
    ("ModifierKey", 6656, None),
    ("MusicRegion", 64, 64),
    ("MusicSource", 64, 32),
    ("Name", 6912, None),
    ("NetCategoryInfo", 3328, None),
    ("NodeHealth", 11264, None),
    ("ObjectHint", 1280, None),
    ("ObjectMaterial", 32, 32),
    ("ObjectScript", 2048, None),
    ("OSMParameter", 1280, None),
    ("OSMStateParameter", 768, None),
    ("ParticleEmitter", 8, 8),
    ("ParticleKey", 6144, None),
    ("Path", 512, None),
    ("PathData", 8, 8),
    ("PendingSceneObject", 2048, None),
    ("Perception", 1280, None),
    ("PhysicalLink", 2816, None),
    ("PhysicsActor", 2304, None),
    ("PhysicsActorRagdoll", 128, 64),
    ("PhysicsActorWinch", 16, 16),
    ("PhysicsDefaultActivator", 128, 64),
    ("PhysicsPropertyCrashable", 512, None),
    ("PhysicsPropertyFakeContinuous", 32, 32),
    ("PhysicsPropertyGravityScaler", 160, 32),
    ("PhysicsPropertyUncrushable", 16, 16),
    ("Pickup", 256, None),
    ("Players", 8, 8),
    ("PointLocation", 64, 64),
    ("PopulationDensity", 128, 64),
    ("PopulationDynamicRoad", 32, 32),
    ("PopulationFlow", 192, 64),
    ("PopulationList", 1024, None),
    ("PopulationSimpleSpawner", 768, None),
    ("PoweredGate", 32, 32),
    ("ProjectilePhysics", 128, 128),
    ("RagdollController", 128, 64),
    ("RedEffectComponent", 768, None),
    ("RedEffectTweak", 96, 32),
    ("Relationship", 96, 32),
    ("Ribbon", 32, 32),
    ("Rider", 1024, None),
    ("RiderLink", 1024, None),
    ("Road", 4608, None),
    ("RoadIntersection", 2304, None),
    ("RoadIntersectionHint", 32, 32),
    ("Rope", 8, 8),
    ("Rotor", 384, 128),
    ("RtAlarm", 32, 32),
    ("RtAlphaAnimation", 8, 8),
    ("RtAttachedFlowControl", 768, None),
    ("RtColorAnimation", 8, 8),
    ("RtCoverHint", 768, 256),
    ("RtDebris", 64, 64),
    ("RtDriverData", 64, 64),
    ("RtEffectVelocityControl", 256, None),
    ("RtExhaustionCounter", 8, 8),
    ("RtFactionZone", 16, 16),
    ("RtFlowControl", 192, 64),
    ("RtFlowCycleTimer", 32, 32),
    ("RtGenericLOD", 32, 32),
    ("RtGenericLODProxy", 32, 32),
    ("RTHuman", 128, 64),
    ("RtJunction", 8, 8),
    ("RtLightAnimation", 32, 32),
    ("RtLivingWorld", 16, 16),
    ("RtPathMember", 32, 32),
    ("RtPopHint", 256, 128),
    ("RtPopMembership", 32, 32),
    ("RtPoweredGate", 96, 32),
    ("RtRedEffect", 8, 8),
    ("RtRibbon", 16, 16),
    ("RtRisingRuinPhysicsAnimation", 8, 8),
    ("RtRoadIntersection", 320, 64),
    ("RtScaleAnimation", 8, 8),
    ("RtSpeedLimit", 8, 8),
    ("RtTerrainChildren", 32, 32),
    ("RtTickDamage", 16, 16),
    ("RtVFX", 768, 256),
    ("RuntimeAirstrikeAirplane", 4, 4),
    ("RuntimeAirstrikeProjectile", 8, 8),
    ("RuntimeAlternatingFire", 8, 8),
    ("RuntimeAnimationParams", 8, 8),
    ("RuntimeAssetRef", 2560, None),
    ("RuntimeClaim", 16, 16),
    ("RuntimeClaimCover", 16, 16),
    ("RuntimeConstraintLink", 32, 32),
    ("RuntimeDebrisEffect", 8, 8),
    ("RuntimeEntrance", 256, 128),
    ("RuntimeEntranceUsable", 512, 256),
    ("RuntimeEquipmentLink", 5120, None),
    ("RuntimeExplosion", 8, 8),
    ("RuntimeFacialExpression", 96, 32),
    ("RuntimeFakeProjectile", 8, 8),
    ("RuntimeFakeWheel", 8, 8),
    ("RuntimeFlightNoise", 8, 8),
    ("RuntimeFoliageModel", 8, 8),
    ("RuntimeHeadLookAt", 128, 64),
    ("RuntimeHealth", 1280, None),
    ("RuntimeHIjackState", 8, 8),
    ("RuntimeHomingProjectile", 8, 8),
    ("RuntimeHomingTarget", 64, 64),
    ("RuntimeHomingWeapon", 8, 8),
    ("RuntimeIgnitor", 8, 8),
    ("RuntimeInventory", 320, 64),
    ("RuntimeLaserDesignator", 4, 4),
    ("RuntimeLastDamageApplied", 32, 32),
    ("RuntimeLayerId", 20224, None),
    ("RuntimeModelState", 2048, None),
    ("RuntimeMusicRegion", 64, 64),
    ("RuntimeNodeHealth", 1280, None),
    ("RuntimeObjectiveMarker", 32, 32),
    ("RuntimeOwnerGuid", 96, 32),
    ("RuntimePhysicalLink", 22784, None),
    ("RuntimePickup", 192, 64),
    ("RuntimeProjectile", 512, 128),
    ("RuntimeProjectileThrown", 16, 16),
    ("RuntimeRiderCrawlExit", 8, 8),
    ("untimeRiderDiveEnter", 8, 8),
    ("RuntimeRope", 8, 8),
    ("RuntimeSceneObject", 2816, None),
    ("RuntimeScriptCallback", 8, 8),
    ("RuntimeScrub", 2816, None),
    ("RuntimeSoundAmbience", 128, 64),
    ("RuntimeSoundEffect", 1024, None),
    ("RuntimeSoundRuinKey", 16, 16),
    ("RuntimeTerrainBound", 32, 32),
    ("RuntimeTimer", 16, 16),
    ("RuntimeTravelGroup", 8, 8),
    ("RuntimeTriggerable", 8, 8),
    ("RuntimeTurret", 128, 64),
    ("RuntimeVehicleCrawlExits", 8, 8),
    ("RuntimeVehicleInventory", 64, 32),
    ("RuntimeVehiclePart", 320, 64),
    ("RuntimeVelocity", 16, 16),
    ("RuntimeWeapon", 192, 64),
    ("RuntimeWeaponProjectile", 160, 32),
    ("ScaleAnimation", 16, 16),
    ("SceneObject", 161280, None),
    ("ScrubObject", 1280, None),
    ("SeatLink", 13312, None),
    ("SeatParameters", 512, None),
    ("SeatToSeat", 512, None),
    ("SkirmishSpawnList", 16, 16),
    ("SkirmishZone", 16, 16),
    ("SocialUse", 96, 32),
    ("SoundAmbience", 96, 32),
    ("SoundEffect", 3584, None),
    ("SoundInterior", 8, 8),
    ("SoundKey", 5632, None),
    ("SoundRuinKey", 8, 8),
    ("SpawnerAdjust", 16, 16),
    ("SpawnOnDeath", 384, 128),
    ("SpeedLimit", 16, 16),
    ("SphereRegion", 32, 32),
    ("Squad", 16, 16),
    ("SquadSource", 16, 16),
    ("SquadUnitLink", 16, 16),
    ("StateMachine", 768, None),
    ("Sticky", 16, 16),
    ("Stimulus", 1792, None),
    ("StimulusModifier", 512, None),
    ("Suspect", 64, 32),
    ("SysPathIntersectionIndex", 1536, None),
    ("SysPathRoadIndex", 1792, None),
    ("Target", 64, 64),
    ("TerrainFade", 32, 32),
    ("TerrainGuidMappingHighResToLowRes", 512, None),
    ("TerrainKey", 512, None),
    ("TerrainObject", 1024, None),
    ("TickDamage", 1024, None),
    ("TimerResponse", 96, 32),
    ("TinyGeometryObject", 32, 32),
    ("TreeFoliage", 32, 32),
    ("TreeParam", 16, 16),
    ("TriggerOnTimer", 64, 64),
    ("Turret", 1024, None),
    ("TurretCoupling", 256, None),
    ("Usable", 512, 128),
    ("VehicleAnimationSet", 1024, None),
    ("VehicleDisguiseScale", 1280, None),
    ("VehiclePart", 4096, None),
    ("WeaponBarrel", 512, None),
    ("WeaponCoupling", 512, None),
    ("WeaponEffects", 384, 128),
    ("WeaponHint", 384, 128),
    ("WeaponProjectileBase", 384, 128),
    ("WeaponRecoilVehicle", 64, 64),
    ("WeaponScatter", 256, None),
    ("WeaponScope", 16, 16),
    ("WeaponThrown", 16, 16),
    ("WeaponTrigger", 16, 16),
    ("WeaponUI", 384, 128),
    ("Winch", 160, 32),
]


# ---------------------------------------------------------------------------
# Cutscene metadata (45 entries)
# Character codes: C=Chris Jacobs, J=Jennifer Mui, M=Mattias Nilsson, S=Shared
# Scene codes from known .bik filenames
# ---------------------------------------------------------------------------
CUTSCENES = [
    # Format: (filename, sequence_number, scene_code, character_code, character_name, is_menu, is_cutscene, act, description)
    ("01_AOA_C.bik", 1, "AOA", "C", "Chris Jacobs", False, True, "act1", "Act of Aggression intro - Chris"),
    ("01_AOA_J.bik", 1, "AOA", "J", "Jennifer Mui", False, True, "act1", "Act of Aggression intro - Jennifer"),
    ("01_AOA_M.bik", 1, "AOA", "M", "Mattias Nilsson", False, True, "act1", "Act of Aggression intro - Mattias"),
    ("02_VIK_C.bik", 2, "VIK", "C", "Chris Jacobs", False, True, "act1", "Villa intro/kidnapping - Chris"),
    ("02_VIK_J.bik", 2, "VIK", "J", "Jennifer Mui", False, True, "act1", "Villa intro/kidnapping - Jennifer"),
    ("02_VIK_M.bik", 2, "VIK", "M", "Mattias Nilsson", False, True, "act1", "Villa intro/kidnapping - Mattias"),
    ("03_YNH_C.bik", 3, "YNH", "C", "Chris Jacobs", False, True, "act1", "You need help - Chris"),
    ("03_YNH_J.bik", 3, "YNH", "J", "Jennifer Mui", False, True, "act1", "You need help - Jennifer"),
    ("03_YNH_M.bik", 3, "YNH", "M", "Mattias Nilsson", False, True, "act1", "You need help - Mattias"),
    ("04_BBB_C.bik", 4, "BBB", "C", "Chris Jacobs", False, True, "act1", "Building the base - Chris"),
    ("04_BBB_J.bik", 4, "BBB", "J", "Jennifer Mui", False, True, "act1", "Building the base - Jennifer"),
    ("04_BBB_M.bik", 4, "BBB", "M", "Mattias Nilsson", False, True, "act1", "Building the base - Mattias"),
    ("05_MBC_C.bik", 5, "MBC", "C", "Chris Jacobs", False, True, "act1", "Meeting Blanco/Contact - Chris"),
    ("05_MBC_J.bik", 5, "MBC", "J", "Jennifer Mui", False, True, "act1", "Meeting Blanco/Contact - Jennifer"),
    ("05_MBC_M.bik", 5, "MBC", "M", "Mattias Nilsson", False, True, "act1", "Meeting Blanco/Contact - Mattias"),
    ("06_PIR_C.bik", 6, "PIR", "C", "Chris Jacobs", False, True, "act1", "Pirates introduction - Chris"),
    ("06_PIR_J.bik", 6, "PIR", "J", "Jennifer Mui", False, True, "act1", "Pirates introduction - Jennifer"),
    ("06_PIR_M.bik", 6, "PIR", "M", "Mattias Nilsson", False, True, "act1", "Pirates introduction - Mattias"),
    ("07_OIL_C.bik", 7, "OIL", "C", "Chris Jacobs", False, True, "act1", "Universal Petroleum intro - Chris"),
    ("07_OIL_J.bik", 7, "OIL", "J", "Jennifer Mui", False, True, "act1", "Universal Petroleum intro - Jennifer"),
    ("07_OIL_M.bik", 7, "OIL", "M", "Mattias Nilsson", False, True, "act1", "Universal Petroleum intro - Mattias"),
    ("08_ACT2_C.bik", 8, "ACT2", "C", "Chris Jacobs", False, True, "act2", "Act 2 transition - Chris"),
    ("08_ACT2_J.bik", 8, "ACT2", "J", "Jennifer Mui", False, True, "act2", "Act 2 transition - Jennifer"),
    ("08_ACT2_M.bik", 8, "ACT2", "M", "Mattias Nilsson", False, True, "act2", "Act 2 transition - Mattias"),
    ("09_CHI_C.bik", 9, "CHI", "C", "Chris Jacobs", False, True, "act2", "Chinese faction intro - Chris"),
    ("09_CHI_J.bik", 9, "CHI", "J", "Jennifer Mui", False, True, "act2", "Chinese faction intro - Jennifer"),
    ("09_CHI_M.bik", 9, "CHI", "M", "Mattias Nilsson", False, True, "act2", "Chinese faction intro - Mattias"),
    ("10_ALN_C.bik", 10, "ALN", "C", "Chris Jacobs", False, True, "act2", "Allied Nations intro - Chris"),
    ("10_ALN_J.bik", 10, "ALN", "J", "Jennifer Mui", False, True, "act2", "Allied Nations intro - Jennifer"),
    ("10_ALN_M.bik", 10, "ALN", "M", "Mattias Nilsson", False, True, "act2", "Allied Nations intro - Mattias"),
    ("11_ACT3_C.bik", 11, "ACT3", "C", "Chris Jacobs", False, True, "act3", "Act 3 transition - Chris"),
    ("11_ACT3_J.bik", 11, "ACT3", "J", "Jennifer Mui", False, True, "act3", "Act 3 transition - Jennifer"),
    ("11_ACT3_M.bik", 11, "ACT3", "M", "Mattias Nilsson", False, True, "act3", "Act 3 transition - Mattias"),
    ("12_NKB_C.bik", 12, "NKB", "C", "Chris Jacobs", False, True, "act3", "Nuclear bunker - Chris"),
    ("12_NKB_J.bik", 12, "NKB", "J", "Jennifer Mui", False, True, "act3", "Nuclear bunker - Jennifer"),
    ("12_NKB_M.bik", 12, "NKB", "M", "Mattias Nilsson", False, True, "act3", "Nuclear bunker - Mattias"),
    ("13_END_C.bik", 13, "END", "C", "Chris Jacobs", False, True, "act3", "Ending - Chris"),
    ("13_END_J.bik", 13, "END", "J", "Jennifer Mui", False, True, "act3", "Ending - Jennifer"),
    ("13_END_M.bik", 13, "END", "M", "Mattias Nilsson", False, True, "act3", "Ending - Mattias"),
    ("shell_BG_loop.bik", None, None, None, None, True, False, None, "Main menu background loop"),
    ("shell_intro_attract.bik", None, None, None, None, True, False, None, "Attract mode / attract video"),
    ("EA_logo.bik", None, None, None, None, True, False, None, "EA logo splash"),
    ("Pandemic_logo.bik", None, None, None, None, True, False, None, "Pandemic Studios logo splash"),
    ("NVidia_logo.bik", None, None, None, None, True, False, None, "NVidia logo splash"),
    ("Havok_logo.bik", None, None, None, None, True, False, None, "Havok middleware logo splash"),
]


# ---------------------------------------------------------------------------
# Mission definitions from known patterns
# ---------------------------------------------------------------------------
MISSIONS = [
    # Guerrillas
    ("GurJob001", "gur", "job", 1, "act1", "maracaibo"),
    ("GurJob002", "gur", "job", 2, "act1", "maracaibo"),
    ("GurJob003", "gur", "job", 3, "act1", "maracaibo"),
    ("GurJob004", "gur", "job", 4, "act1", "maracaibo"),
    ("GurJob005", "gur", "job", 5, "act1", "maracaibo"),
    ("GurCon001", "gur", "contract", 1, "act1", "maracaibo"),
    ("GurCon002", "gur", "contract", 2, "act1", "maracaibo"),
    ("GurCon003", "gur", "contract", 3, "act1", "maracaibo"),
    ("GurCon004", "gur", "contract", 4, "act1", "maracaibo"),
    ("GurCon005", "gur", "contract", 5, "act1", "maracaibo"),
    # Pirates
    ("PirJob001", "pir", "job", 1, "act1", "maracaibo"),
    ("PirJob002", "pir", "job", 2, "act1", "maracaibo"),
    ("PirJob003", "pir", "job", 3, "act1", "maracaibo"),
    ("PirJob004", "pir", "job", 4, "act1", "maracaibo"),
    ("PirJob005", "pir", "job", 5, "act1", "maracaibo"),
    ("PirCon001", "pir", "contract", 1, "act1", "maracaibo"),
    ("PirCon002", "pir", "contract", 2, "act1", "maracaibo"),
    ("PirCon003", "pir", "contract", 3, "act1", "maracaibo"),
    ("PirCon004", "pir", "contract", 4, "act1", "maracaibo"),
    ("PirCon005", "pir", "contract", 5, "act1", "maracaibo"),
    # Universal Petroleum
    ("OilJob001", "oil", "job", 1, "act1", "maracaibo"),
    ("OilJob002", "oil", "job", 2, "act1", "maracaibo"),
    ("OilJob003", "oil", "job", 3, "act1", "maracaibo"),
    ("OilJob004", "oil", "job", 4, "act1", "maracaibo"),
    ("OilJob005", "oil", "job", 5, "act1", "maracaibo"),
    ("OilCon001", "oil", "contract", 1, "act1", "maracaibo"),
    ("OilCon002", "oil", "contract", 2, "act1", "maracaibo"),
    ("OilCon003", "oil", "contract", 3, "act1", "maracaibo"),
    ("OilCon004", "oil", "contract", 4, "act1", "maracaibo"),
    ("OilCon005", "oil", "contract", 5, "act1", "maracaibo"),
    ("OilCon006", "oil", "contract", 6, "act1", "maracaibo"),
    ("OilCon007", "oil", "contract", 7, "act1", "maracaibo"),
    ("OilCon008", "oil", "contract", 8, "act1", "maracaibo"),
    ("OilCon009", "oil", "contract", 9, "act1", "maracaibo"),
    ("OilCon010", "oil", "contract", 10, "act1", "maracaibo"),
    ("OilCon011", "oil", "contract", 11, "act2", "caracas"),
    ("OilCon012", "oil", "contract", 12, "act2", "caracas"),
    ("OilCon013", "oil", "contract", 13, "act2", "caracas"),
    ("OilCon014", "oil", "contract", 14, "act2", "caracas"),
    ("OilCon015", "oil", "contract", 15, "act2", "caracas"),
    ("OilCon016", "oil", "contract", 16, "act2", "caracas"),
    ("OilCon017", "oil", "contract", 17, "act2", "caracas"),
    ("OilCon018", "oil", "contract", 18, "act2", "caracas"),
    ("OilCon019", "oil", "contract", 19, "act2", "caracas"),
    ("OilCon020", "oil", "contract", 20, "act2", "caracas"),
    ("OilCon021", "oil", "contract", 21, "act3", "angel_falls"),
    # Chinese
    ("ChiJob001", "chi", "job", 1, "act2", "caracas"),
    ("ChiJob002", "chi", "job", 2, "act2", "caracas"),
    ("ChiJob003", "chi", "job", 3, "act2", "caracas"),
    ("ChiJob004", "chi", "job", 4, "act2", "caracas"),
    ("ChiJob005", "chi", "job", 5, "act2", "caracas"),
    ("ChiCon001", "chi", "contract", 1, "act2", "caracas"),
    ("ChiCon002", "chi", "contract", 2, "act2", "caracas"),
    ("ChiCon003", "chi", "contract", 3, "act2", "caracas"),
    ("ChiCon004", "chi", "contract", 4, "act2", "caracas"),
    ("ChiCon005", "chi", "contract", 5, "act2", "caracas"),
    # Allied Nations
    ("AllJob001", "all", "job", 1, "act2", "caracas"),
    ("AllJob002", "all", "job", 2, "act2", "caracas"),
    ("AllJob003", "all", "job", 3, "act2", "caracas"),
    ("AllJob004", "all", "job", 4, "act2", "caracas"),
    ("AllJob005", "all", "job", 5, "act2", "caracas"),
    ("AllCon001", "all", "contract", 1, "act2", "caracas"),
    ("AllCon002", "all", "contract", 2, "act2", "caracas"),
    ("AllCon003", "all", "contract", 3, "act2", "caracas"),
    ("AllCon004", "all", "contract", 4, "act2", "caracas"),
    ("AllCon005", "all", "contract", 5, "act2", "caracas"),
    # Venezuela Army
    ("VzaCon001", "vza", "contract", 1, "act3", "angel_falls"),
    ("VzaCon002", "vza", "contract", 2, "act3", "angel_falls"),
    ("VzaCon003", "vza", "contract", 3, "act3", "angel_falls"),
    ("VzaCon004", "vza", "contract", 4, "act3", "angel_falls"),
    ("VzaCon005", "vza", "contract", 5, "act3", "angel_falls"),
    # PMC main story
    ("PmcRec001", "pmc", "rec", 1, "act1", "maracaibo"),
    ("PmcRec002", "pmc", "rec", 2, "act1", "maracaibo"),
    ("PmcRec003", "pmc", "rec", 3, "act1", "maracaibo"),
    ("PmcRec004", "pmc", "rec", 4, "act2", "caracas"),
    ("PmcRec005", "pmc", "rec", 5, "act2", "caracas"),
    ("PmcRec006", "pmc", "rec", 6, "act3", "angel_falls"),
    ("PmcRec007", "pmc", "rec", 7, "act3", "angel_falls"),
]


# ---------------------------------------------------------------------------
# Block types (all known types from the pipeline)
# ---------------------------------------------------------------------------
BLOCK_TYPES = [
    "world_cell", "state_layer", "building", "vehicle", "road", "terrain",
    "terrain_texture", "script", "animation", "animgroup", "hijack",
    "ambient", "mission", "contract", "job", "base_world", "static_layer",
    "road_network", "ui_shell", "ui_hud", "font", "localization",
    "vo_dialog", "loading", "music", "scaleform", "guilayout", "subtitles",
    "resident", "precache", "cloud_noise", "save_asset", "sound", "unknown",
]

# ---------------------------------------------------------------------------
# Review statuses
# ---------------------------------------------------------------------------
REVIEW_STATUSES = [
    "unreviewed", "auto_classified", "needs_review", "in_progress",
    "reviewed", "approved", "flagged", "rejected",
]

# ---------------------------------------------------------------------------
# VZ State stages
# ---------------------------------------------------------------------------
VZ_STATE_STAGES = [
    "pristine", "staging", "defenses", "combat", "destroyed",
    "ruined", "captured", "act1", "act2", "act3",
]


def upgrade() -> None:
    conn = op.get_bind()

    # --- Insert Factions ---
    factions_table = sa.table(
        "factions",
        sa.column("code", sa.Text),
        sa.column("name", sa.Text),
        sa.column("color_hex", sa.Text),
        sa.column("description", sa.Text),
    )
    op.bulk_insert(factions_table, FACTIONS)

    # --- Insert Categories (respecting parent hierarchy) ---
    categories_table = sa.table(
        "categories",
        sa.column("id", sa.Integer),
        sa.column("name", sa.Text),
        sa.column("slug", sa.Text),
        sa.column("parent_id", sa.Integer),
        sa.column("depth", sa.SmallInteger),
        sa.column("path", sa.Text),
        sa.column("color_hex", sa.Text),
        sa.column("sort_order", sa.Integer),
    )

    # First pass: insert roots (no parent)
    slug_to_id: dict[str, int] = {}
    cat_id = 1
    for cat in CATEGORIES:
        if cat["parent"] is None:
            parent_id = None
            path = cat["slug"]
        else:
            parent_id = slug_to_id.get(cat["parent"])
            parent_cat = next((c for c in CATEGORIES if c["slug"] == cat["parent"]), None)
            if parent_cat and parent_cat["parent"]:
                path = f"{parent_cat['parent']}/{cat['parent']}/{cat['slug']}"
            elif parent_cat:
                path = f"{cat['parent']}/{cat['slug']}"
            else:
                path = cat["slug"]

        conn.execute(
            categories_table.insert().values(
                id=cat_id,
                name=cat["name"],
                slug=cat["slug"],
                parent_id=parent_id,
                depth=cat["depth"],
                path=path,
                color_hex=cat["color_hex"],
                sort_order=cat["sort_order"],
            )
        )
        slug_to_id[cat["slug"]] = cat_id
        cat_id += 1

    # Reset sequence to next available value
    op.execute(f"SELECT setval('categories_id_seq', {cat_id}, false)")

    # --- Insert ECS Component Types ---
    ecs_table = sa.table(
        "ecs_component_types",
        sa.column("name", sa.Text),
        sa.column("prealloc_primary", sa.Integer),
        sa.column("prealloc_secondary", sa.Integer),
        sa.column("is_runtime", sa.Boolean),
        sa.column("category", sa.Text),
    )
    ecs_rows = []
    for name, primary, secondary in ECS_COMPONENT_TYPES:
        is_runtime = name.startswith("Runtime") or name.startswith("Rt") or name.startswith("RT")
        category = _categorize_ecs(name)
        ecs_rows.append({
            "name": name,
            "prealloc_primary": primary,
            "prealloc_secondary": secondary,
            "is_runtime": is_runtime,
            "category": category,
        })
    op.bulk_insert(ecs_table, ecs_rows)

    # --- Insert Cutscenes ---
    cutscenes_table = sa.table(
        "cutscenes",
        sa.column("filename", sa.Text),
        sa.column("sequence_number", sa.Integer),
        sa.column("scene_code", sa.Text),
        sa.column("character_code", sa.Text),
        sa.column("character_name", sa.Text),
        sa.column("is_menu_video", sa.Boolean),
        sa.column("is_cutscene", sa.Boolean),
        sa.column("act", sa.Text),
        sa.column("description", sa.Text),
    )
    cutscene_rows = []
    for c in CUTSCENES:
        cutscene_rows.append({
            "filename": c[0],
            "sequence_number": c[1],
            "scene_code": c[2],
            "character_code": c[3],
            "character_name": c[4],
            "is_menu_video": c[5],
            "is_cutscene": c[6],
            "act": c[7],
            "description": c[8],
        })
    op.bulk_insert(cutscenes_table, cutscene_rows)

    # --- Insert Missions ---
    missions_table = sa.table(
        "missions",
        sa.column("mission_id", sa.Text),
        sa.column("faction", sa.Text),
        sa.column("type", sa.Text),
        sa.column("number", sa.Integer),
        sa.column("act", sa.Text),
        sa.column("region", sa.Text),
    )
    mission_rows = []
    for m in MISSIONS:
        mission_rows.append({
            "mission_id": m[0],
            "faction": m[1],
            "type": m[2],
            "number": m[3],
            "act": m[4],
            "region": m[5],
        })
    op.bulk_insert(missions_table, mission_rows)


def downgrade() -> None:
    conn = op.get_bind()
    conn.execute(sa.text("DELETE FROM missions"))
    conn.execute(sa.text("DELETE FROM cutscenes"))
    conn.execute(sa.text("DELETE FROM ecs_component_types"))
    conn.execute(sa.text("DELETE FROM categories"))
    conn.execute(sa.text("DELETE FROM factions"))
