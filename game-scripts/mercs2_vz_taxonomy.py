"""Classify vz_state overlay sources for UE Data Layer hierarchy.

Maps block filenames / placement ``source`` strings to Act / Region / State /
Contract buckets used by populate_world.py and populate_pmc_base.py.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from typing import Literal

# Full path: 00213_blocks__VZ__vz_state_mar_city_act1_P000_Q3.block.bin
_VZ_STATE_SRC_RE = re.compile(
    r"^(\d+)_blocks__VZ__vz_state_(.+?)_P(\d{3})_Q(\d+)(?:\.block)?(?:\.bin)?$",
    re.IGNORECASE,
)
_VZ_STATE_SEARCH_RE = re.compile(
    r"vz_state_(.+?)_P\d+_Q\d+",
    re.IGNORECASE,
)
_MISSION_RE = re.compile(r"\b([a-z]{3}(?:con|job)\d{3})\b", re.IGNORECASE)

# Longest-prefix wins (lowercase stem fragments).
_REGION_PREFIXES: tuple[tuple[str, str], ...] = (
    ("mar_altagracia", "Maracaibo"),
    ("mar_industrial", "Maracaibo"),
    ("mar_outskirt", "Maracaibo"),
    ("mar_village", "Maracaibo"),
    ("mar_city", "Maracaibo"),
    ("mar_", "Maracaibo"),
    ("car_city", "Caracas"),
    ("car_dock", "Caracas"),
    ("car_estate", "Caracas"),
    ("car_shanty", "Caracas"),
    ("car_", "Caracas"),
    ("cumana", "Cumana"),
    ("amazon", "Amazon"),
    ("angel_falls", "AngelFalls"),
    ("guanare", "Guanare"),
    ("gurhq", "GurHQ"),
    ("jungle_mountain", "JungleMountain"),
    ("margarita", "Margarita"),
    ("merida", "Merida"),
    ("pmc", "PMC"),
)

ActNum = Literal[1, 2, 3]
ParentKind = Literal[
    "base",
    "pristine",
    "destroyed",
    "staging",
    "defenses",
    "captured",
    "act1",
    "act2",
    "act3",
    "contract",
    "other",
]


@dataclass(frozen=True)
class OverlayInfo:
    """Parsed vz_state overlay metadata."""

    source: str
    stem: str
    act: ActNum | None = None
    region: str | None = None
    parent_kind: ParentKind = "other"
    mission_id: str | None = None
    faction: str | None = None
    tags: frozenset[str] = field(default_factory=frozenset)


def _stem_from_source(source: str) -> str:
    m = _VZ_STATE_SRC_RE.match(source.strip())
    if m:
        return m.group(2).lower()
    m2 = _VZ_STATE_SEARCH_RE.search(source)
    if m2:
        return m2.group(1).lower()
    return source.lower().replace(".block.bin", "").replace(".bin", "")


def _detect_act(stem_lower: str) -> ActNum | None:
    if "act3" in stem_lower:
        return 3
    if "act2" in stem_lower:
        return 2
    if "act1" in stem_lower:
        return 1
    return None


def _detect_region(stem_lower: str) -> str | None:
    for prefix, label in _REGION_PREFIXES:
        if stem_lower.startswith(prefix):
            return label
    return None


def _detect_faction(stem_lower: str) -> str | None:
    if re.search(r"act\d+all", stem_lower) or re.search(r"\ball(con|job)", stem_lower):
        return "all"
    for fac in ("pmc", "oil", "gur", "pir", "chi"):
        if fac in stem_lower:
            return fac
    return None


def _collect_tags(stem_lower: str) -> frozenset[str]:
    tags: set[str] = set()
    for tag in (
        "pristine",
        "destroyed",
        "ruined",
        "rubble",
        "staging",
        "defenses",
        "captured",
        "combat",
        "act1",
        "act2",
        "act3",
    ):
        if tag in stem_lower:
            tags.add(tag)
    return frozenset(tags)


def _parent_kind(stem_lower: str, act: ActNum | None, mission_id: str | None) -> ParentKind:
    if act is not None:
        return f"act{act}"  # type: ignore[return-value]
    if "pristine" in stem_lower:
        return "pristine"
    if any(t in stem_lower for t in ("destroyed", "ruined", "rubble")):
        return "destroyed"
    if "defenses" in stem_lower:
        return "defenses"
    if "staging" in stem_lower or "combat" in stem_lower:
        return "staging"
    if "captured" in stem_lower:
        return "captured"
    if mission_id:
        return "contract"
    return "other"


def parse_overlay_source(source: str) -> OverlayInfo:
    """Parse a placement ``source`` or block filename into overlay metadata."""
    stem = _stem_from_source(source)
    act = _detect_act(stem)
    region = _detect_region(stem)
    mission_m = _MISSION_RE.search(stem)
    mission_id = mission_m.group(1).lower() if mission_m else None
    tags = _collect_tags(stem)
    parent_kind = _parent_kind(stem, act, mission_id)
    return OverlayInfo(
        source=source,
        stem=stem,
        act=act,
        region=region,
        parent_kind=parent_kind,
        mission_id=mission_id,
        faction=_detect_faction(stem),
        tags=tags,
    )


def sanitize_data_layer_label(name: str, *, max_len: int = 120) -> str:
    out = re.sub(r"[^A-Za-z0-9_]", "_", name.replace("-", "_"))
    out = re.sub(r"_+", "_", out).strip("_")
    if out and out[0].isdigit():
        out = f"A_{out}"
    return out[:max_len] or "Unnamed"


def data_layer_parent_label(info: OverlayInfo, *, prefix: str = "VZ") -> str:
    """Top-level Data Layer group (VZ_Act1, VZ_Pristine, …)."""
    kind = info.parent_kind
    if kind == "act1":
        return f"{prefix}_Act1"
    if kind == "act2":
        return f"{prefix}_Act2"
    if kind == "act3":
        return f"{prefix}_Act3"
    mapping = {
        "pristine": f"{prefix}_Pristine",
        "destroyed": f"{prefix}_Destroyed",
        "staging": f"{prefix}_Staging",
        "defenses": f"{prefix}_Defenses",
        "captured": f"{prefix}_Captured",
        "contract": f"{prefix}_Contract",
        "other": f"{prefix}_Other",
    }
    return mapping.get(kind, f"{prefix}_Other")


def data_layer_region_label(
    info: OverlayInfo,
    *,
    prefix: str = "VZ",
) -> str | None:
    """Mid-level region group for act overlays only."""
    if info.act is None or not info.region:
        return None
    return f"{prefix}_Act{info.act}_{info.region}"


def data_layer_leaf_label(info: OverlayInfo, *, prefix: str = "VZ") -> str:
    """Per-overlay leaf Data Layer."""
    return f"{prefix}_{sanitize_data_layer_label(info.stem)}"


def data_layer_hierarchy(
    source: str,
    *,
    prefix: str = "VZ",
) -> tuple[str, str | None, str]:
    """Return (parent_label, region_label|None, leaf_label) for *source*."""
    info = parse_overlay_source(source)
    parent = data_layer_parent_label(info, prefix=prefix)
    region = data_layer_region_label(info, prefix=prefix)
    leaf = data_layer_leaf_label(info, prefix=prefix)
    return parent, region, leaf


def initial_runtime_activated(info: OverlayInfo) -> bool:
    """Default PIE/runtime activation for this overlay."""
    if info.parent_kind == "pristine":
        return True
    if info.parent_kind == "act1":
        return True
    return False


def pmc_data_layer_parent_label(info: OverlayInfo) -> str:
    """PMC-specific parent labels (PMC_VZ_*)."""
    kind = info.parent_kind
    if kind == "act1":
        return "PMC_VZ_Act1"
    if kind == "act2":
        return "PMC_VZ_Act2"
    if kind == "act3":
        return "PMC_VZ_Act3"
    mapping = {
        "pristine": "PMC_VZ_Pristine",
        "destroyed": "PMC_VZ_Destroyed",
        "staging": "PMC_VZ_Staging",
        "defenses": "PMC_VZ_Defenses",
        "captured": "PMC_VZ_Captured",
        "contract": "PMC_VZ_Contract",
        "other": "PMC_VZ_Other",
    }
    return mapping.get(kind, "PMC_VZ_Other")


def pmc_data_layer_region_label(info: OverlayInfo) -> str | None:
    if info.act is None or not info.region:
        return None
    return f"PMC_VZ_Act{info.act}_{info.region}"


def pmc_data_layer_hierarchy(source: str) -> tuple[str, str | None, str]:
    info = parse_overlay_source(source)
    parent = pmc_data_layer_parent_label(info)
    region = pmc_data_layer_region_label(info)
    leaf = f"PMC_{sanitize_data_layer_label(info.stem)}"
    return parent, region, leaf
