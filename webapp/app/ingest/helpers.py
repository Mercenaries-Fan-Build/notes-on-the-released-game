"""Shared helpers for ingest pipeline — coordinate math, name parsing, classification."""
from __future__ import annotations

import math
import re
from pathlib import Path


# ---------------------------------------------------------------------------
# Block name / path parsing
# ---------------------------------------------------------------------------

_PQ_RE = re.compile(r"_P(\d{3})_Q(\d)")
_BLOCK_NUM_RE = re.compile(r"^(\d{5})_blocks__(\w+)__(.+?)(?:_P\d{3}_Q\d)?\.block")
_FACTION_PREFIXES = {
    "all": "all", "chi": "chi", "gur": "gur", "oil": "oil",
    "pir": "pir", "pmc": "pmc", "vza": "vza",
}
_REGION_PATTERNS = [
    "maracaibo", "caracas", "merida", "amazon", "angel_falls",
    "margarita", "cumana", "altagracia", "merida",
]

# Comprehensive block_type classifier
_BLOCK_TYPE_PATTERNS: list[tuple[str, str]] = [
    (r"^vz_state_", "state_layer"),
    (r"^vz_mar_roads", "road_network"),
    (r"^layers_static", "static_layer"),
    (r"^c3\d{4}", "world_cell"),
    (r"^low_res_terrain", "terrain"),
    (r"lrterrain_", "terrain"),
    (r"^lrterrain", "terrain"),
    (r"^scripts_vz", "script"),
    (r"^vehiclenameanimgroup_", "animgroup"),
    (r"^hijack_", "hijack"),
    (r"^ambient_", "ambient"),
    (r"_road_", "road"),
    (r"^road_", "road"),
    (r"^vo_", "vo_dialog"),
    (r"^english_base", "localization"),
    (r"^shell_", "ui_shell"),
    (r"^hud_", "ui_hud"),
    (r"^scaleform_", "scaleform"),
    (r"^guilayout_", "guilayout"),
    (r"^font_", "font"),
    (r"^subtitles", "subtitles"),
    (r"^loading_", "loading"),
    (r"^resident", "resident"),
    (r"^precache", "precache"),
    (r"^cloud_noise", "cloud_noise"),
    (r"^ps3save|^save_?assets", "save_asset"),
    (r"^music_", "music"),
    (r"sound_|_sound", "sound"),
    (r"_bld_|_building|^commercial_|^residential_|^industrial_|^military_", "building"),
    (r"_veh_|^vehicle_|^civ_veh", "vehicle"),
    (r"^terrain_tex", "terrain_texture"),
]


def classify_block_type(canonical_name: str) -> str:
    """Derive block_type from canonical_name using pattern matching."""
    lower = canonical_name.lower()
    for pattern, btype in _BLOCK_TYPE_PATTERNS:
        if re.search(pattern, lower):
            return btype
    return "unknown"


def parse_block_stem(stem: str) -> dict:
    """Parse a block stem into structured fields."""
    result: dict = {"stem": stem, "p_level": None, "q_level": None}
    pq = _PQ_RE.search(stem)
    if pq:
        result["p_level"] = int(pq.group(1))
        result["q_level"] = int(pq.group(2))

    m = _BLOCK_NUM_RE.match(stem)
    if m:
        result["block_index"] = int(m.group(1))
        result["pack"] = f"batch_{m.group(2).lower()}"
        result["canonical_name"] = m.group(3)
    else:
        clean = _PQ_RE.sub("", stem).rstrip("_").replace(".block", "")
        result["canonical_name"] = clean
        result["block_index"] = None
        result["pack"] = None

    cn = result.get("canonical_name", "")
    result["block_type"] = classify_block_type(cn)

    base = _PQ_RE.sub("", stem).rstrip("_").replace(".block", "")
    for suffix in ("_destroyed", "_broken", "_burn", "_wreck", "_damaged", "_intact"):
        base = base.replace(suffix, "")
    result["base_asset_id"] = base

    faction_hint = None
    for prefix, code in _FACTION_PREFIXES.items():
        if cn.startswith(f"{prefix}_") or f"_{prefix}_" in cn:
            faction_hint = code
            break
    result["faction_hint"] = faction_hint

    region_hint = None
    cn_lower = cn.lower()
    for rp in _REGION_PATTERNS:
        if rp in cn_lower:
            region_hint = rp
            break
    result["region_hint"] = region_hint

    return result


# ---------------------------------------------------------------------------
# Coordinate computations (matching existing pipeline conventions)
# ---------------------------------------------------------------------------

def compute_ue_coords(pos_x: float, pos_y: float, pos_z: float) -> tuple[float, float, float]:
    """Game LH metres → UE centimetres with Y/Z swap."""
    return 100.0 * pos_x, 100.0 * pos_z, 100.0 * pos_y


def compute_ue_yaw(qy: float, qw: float) -> float:
    return -math.degrees(2.0 * math.atan2(qy, qw))


def compute_distance_from_origin(x: float, z: float) -> float:
    return math.sqrt(x * x + z * z)


def elevation_band(y: float) -> str:
    if y < 0.5:
        return "sea_level"
    if y < 20:
        return "low"
    if y < 100:
        return "mid"
    if y < 250:
        return "high"
    return "peak"


def has_non_trivial_rotation(qx: float, qy: float, qz: float, qw: float) -> bool:
    return abs(qx) > 1e-4 or abs(qz) > 1e-4


# ---------------------------------------------------------------------------
# Texture name analysis
# ---------------------------------------------------------------------------

def texture_channel_from_name(name: str) -> str:
    lower = name.lower()
    if lower.endswith("_nm"):
        return "normal"
    if lower.endswith("_sm"):
        return "specular"
    if lower.endswith("_gm"):
        return "gloss"
    if lower.endswith("_em"):
        return "emissive"
    return "diffuse"


def base_texture_name(name: str) -> str:
    for suffix in ("_nm", "_sm", "_gm", "_em"):
        if name.lower().endswith(suffix):
            return name[: -len(suffix)]
    return name


# ---------------------------------------------------------------------------
# VZ state overlay parsing
# ---------------------------------------------------------------------------

_VZ_STAGE_PATTERNS = [
    (r"_pristine", "pristine"),
    (r"_destroyed", "destroyed"),
    (r"_ruined", "ruined"),
    (r"_captured", "captured"),
    (r"_staging", "staging"),
    (r"_defenses", "defenses"),
    (r"_combat", "combat"),
]

_VZ_ACT_RE = re.compile(r"_(act[123])")

_VZ_MISSION_RE = re.compile(
    r"(all|chi|gur|oil|pir|pmc|vza|jet|mec)(con|job|rec)(\d{3})"
)


def parse_vz_state_name(source_name: str) -> dict:
    """Parse a vz_state overlay source filename into structured metadata."""
    result: dict = {"stage": None, "act": None, "faction": None, "mission_id": None}

    for pat, stage in _VZ_STAGE_PATTERNS:
        if re.search(pat, source_name, re.IGNORECASE):
            result["stage"] = stage
            break

    act_m = _VZ_ACT_RE.search(source_name)
    if act_m:
        result["act"] = act_m.group(1)
        result["is_act_overlay"] = True
    else:
        result["is_act_overlay"] = False

    mission_m = _VZ_MISSION_RE.search(source_name)
    if mission_m:
        result["faction"] = mission_m.group(1)
        result["mission_id"] = f"{mission_m.group(1)}{mission_m.group(2)}{mission_m.group(3)}"
    elif not result["faction"]:
        for prefix in _FACTION_PREFIXES:
            if f"_{prefix}_" in source_name.lower() or source_name.lower().startswith(f"vz_state_{prefix}"):
                result["faction"] = prefix
                break

    stage = result.get("stage")
    if stage in ("pristine", None):
        result["visibility_default"] = True
    else:
        result["visibility_default"] = False

    return result


# ---------------------------------------------------------------------------
# Mission ID parsing
# ---------------------------------------------------------------------------

def parse_mission_id(mid: str) -> dict:
    """Parse a mission_id like 'GurJob001' into faction/type/number."""
    m = re.match(r"([A-Za-z]{2,3})(Con|Job|Rec)(\d{3})", mid, re.IGNORECASE)
    if not m:
        return {"faction": None, "type": None, "number": None}
    return {
        "faction": m.group(1).lower(),
        "type": m.group(2).lower(),
        "number": int(m.group(3)),
    }
