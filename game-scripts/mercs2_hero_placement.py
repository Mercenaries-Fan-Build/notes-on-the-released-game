"""Hero block GLB placement — match aggregate meshes to placement clusters.

Each hero ``mesh_scene`` GLB (e.g. ``pmcoutpost_bld_hq``, ``pmcoutpost_misc``) is a
pre-composed scene at a single origin. Do **not** assign every entity containing
``pmcoutpost`` to every mesh — that stacks all buildings at one centroid.
"""

from __future__ import annotations

import re
from typing import Callable

# Canonical stem → entity-name substrings (match if any pattern hits).
_AGGREGATE_ENTITY_PATTERNS: dict[str, list[str]] = {
    "pmcoutpost_misc": [
        "pmcoutpost_planter",
        "pmcoutpost_road_sidewalk",
        "pmcoutpost_gate",
        "pmcoutpost_column",
        "pmcoutpost_statue",
        "pmcoutpost_fountain",
    ],
}

# Building meshes: match on bld_* token shared with entity, not bare compound prefix.
_BLD_TOKEN_RE = re.compile(r"bld_[a-z0-9_]+", re.IGNORECASE)


def _normalize_entity(name: str) -> str:
    s = name.lower().strip()
    s = re.sub(r"\s+0x[0-9a-fA-F]+$", "", s)
    return s.replace(" ", "_").lstrip("_")


def _compact(s: str) -> str:
    return s.replace("_", "")


def entity_matches_hero_canonical(entity_name: str, canonical: str) -> bool:
    """Return True if *entity_name* should cluster with hero mesh *canonical*."""
    if not entity_name or not canonical:
        return False

    ent = _normalize_entity(entity_name)
    canon = canonical.lower().strip()

    # Compound review stems: pmcoutpost_misc-pmcoutpost_column
    if "-" in canon:
        for part in canon.split("-"):
            part = part.strip()
            if part and entity_matches_hero_canonical(entity_name, part):
                return True
        return False

    # Explicit aggregate rules (misc props, sidewalks, …)
    for stem, patterns in _AGGREGATE_ENTITY_PATTERNS.items():
        if canon == stem or canon.startswith(stem + "-") or canon.startswith(stem + "_"):
            return any(pat in ent for pat in patterns)
    if canon in _AGGREGATE_ENTITY_PATTERNS:
        return any(pat in ent for pat in _AGGREGATE_ENTITY_PATTERNS[canon])

    # Building: require matching bld_* token (hq, dock, pool, …)
    canon_bld = _BLD_TOKEN_RE.search(canon)
    if canon_bld:
        token = canon_bld.group(0).lower()
        return token in ent

    # Resident / special stems
    if "resident" in canon and "pmcoutpost" in canon:
        return "pmcoutpost" in ent and "fountain" in ent

    # Default: full canonical stem must appear in entity (underscore-insensitive)
    return _compact(canon) in _compact(ent)


def _placement_xyz(p: dict) -> tuple[float, float, float] | None:
    pos = p.get("position")
    if isinstance(pos, dict):
        return (
            float(pos.get("x", 0.0)),
            float(pos.get("y", 0.0)),
            float(pos.get("z", 0.0)),
        )
    if "position_x" in p:
        return (
            float(p.get("position_x", 0.0)),
            float(p.get("position_y", 0.0)),
            float(p.get("position_z", 0.0)),
        )
    return None


def _placement_key(p: dict) -> str:
    return str(p.get("entity_id", id(p)))


def cluster_centroid(placements: list[dict]) -> tuple[float, float, float, int] | None:
    sx = sy = sz = 0.0
    n = 0
    for p in placements:
        xyz = _placement_xyz(p)
        if xyz is None:
            continue
        sx += xyz[0]
        sy += xyz[1]
        sz += xyz[2]
        n += 1
    if n == 0:
        return None
    return sx / n, sy / n, sz / n, n


def compute_hero_block_spawns(
    placements: list[dict],
    mesh_lookup: dict[str, str],
    *,
    min_cluster: int = 1,
    placement_filter: Callable[[dict], bool] | None = None,
    is_layers_static: Callable[[dict], bool] | None = None,
    skip_entity: Callable[[str], bool] | None = None,
) -> dict[str, tuple[float, float, float, int]]:
    """Assign placements to hero meshes (longest canonical wins, each record once)."""
    if is_layers_static is None:
        is_layers_static = lambda p: True  # noqa: E731

    canons = sorted(
        (c for c in mesh_lookup if c),
        key=lambda c: len(c),
        reverse=True,
    )

    used: set[str] = set()
    spawns: dict[str, tuple[float, float, float, int]] = {}

    for canon in canons:
        cluster: list[dict] = []
        for p in placements:
            if not is_layers_static(p):
                continue
            if placement_filter is not None and not placement_filter(p):
                continue
            key = _placement_key(p)
            if key in used:
                continue
            ent = p.get("entity_name") or ""
            if skip_entity and skip_entity(ent):
                continue
            if entity_matches_hero_canonical(ent, canon):
                cluster.append(p)

        if len(cluster) < min_cluster:
            continue

        centroid = cluster_centroid(cluster)
        if centroid is None:
            continue

        for p in cluster:
            used.add(_placement_key(p))

        spawns[canon] = centroid

    return spawns
