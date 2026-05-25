"""Decode Mercenaries 2 c3XXXX world streaming cell IDs to game-world XYZ (metres).

Cell blocks use names like ``c30001`` (single cell) or shared bundles
``c30087-c20113-c10033-__shared__``. Positions are grid-derived; per-mesh
``world_translation`` in review metadata is often zero.

Grid parameters are approximate — see ``docs/placement_data_format.md``.
"""

from __future__ import annotations

import re
from typing import Iterable

# Game world horizontal extent (metres) — matches populate_world / placement docs.
WORLD_MIN_X = -3900.0
WORLD_MAX_X = 3850.0
WORLD_MIN_Z = -3900.0
WORLD_MAX_Z = 3850.0

# c3 cell IDs span c30001–c39999 in retail vz.wad (linear slot in a 100×100 grid).
CELL_ID_BASE = 30001
GRID_COLS = 100
WORLD_WIDTH_X = WORLD_MAX_X - WORLD_MIN_X
WORLD_WIDTH_Z = WORLD_MAX_Z - WORLD_MIN_Z
CELL_SIZE_X = WORLD_WIDTH_X / GRID_COLS
CELL_SIZE_Z = WORLD_WIDTH_Z / GRID_COLS

_C3_ID_RE = re.compile(r"c3(\d{4})", re.IGNORECASE)
_C3_SIMPLE_RE = re.compile(r"^c3(\d{4})$", re.IGNORECASE)


def parse_cell_ids_from_stem(stem: str) -> list[int]:
    """Return all c3#### numeric IDs embedded in a block folder stem."""
    return [int(m.group(1)) for m in _C3_ID_RE.finditer(stem)]


def primary_cell_id_from_stem(stem: str) -> int | None:
    """Pick the anchor cell ID for placement (first c3#### in the stem)."""
    ids = parse_cell_ids_from_stem(stem)
    return ids[0] if ids else None


def cell_id_to_row_col(cell_id: int) -> tuple[int, int]:
    """Map a c3#### id to (row, col) in the 100×100 streaming grid."""
    linear = max(0, int(cell_id) - CELL_ID_BASE)
    row = linear // GRID_COLS
    col = linear % GRID_COLS
    return row, col


def cell_id_to_world_xyz(cell_id: int, *, y: float = 0.0) -> tuple[float, float, float]:
    """Return game-space (x, y, z) centre for a streaming cell (metres).

    Coordinates are **left-handed Y-up** (same as placement JSON). Only mesh GLB
    geometry is Z-negated at glTF export; actor placement uses these values as-is.
    """
    row, col = cell_id_to_row_col(cell_id)
    x = WORLD_MIN_X + (col + 0.5) * CELL_SIZE_X
    z = WORLD_MIN_Z + (row + 0.5) * CELL_SIZE_Z
    return x, y, z


def cell_stem_to_world_xyz(stem: str, *, y: float = 0.0) -> tuple[float, float, float] | None:
    """Decode world XYZ from a review/UE block folder stem."""
    cell_id = primary_cell_id_from_stem(stem)
    if cell_id is None:
        return None
    return cell_id_to_world_xyz(cell_id, y=y)


def is_c3_block_stem(stem: str) -> bool:
    """True when *stem* names a c3 world-cell block (not a hero vehicle/building)."""
    lower = stem.lower()
    if re.search(r"blocks__vz__c3\d{4}", lower):
        return True
    if "__shared__" in lower and _C3_ID_RE.search(lower):
        return True
    return bool(_C3_SIMPLE_RE.match(lower))


def is_c3_canonical_name(canonical: str) -> bool:
    """True for mesh lookup keys that refer to c3 cell geometry."""
    c = canonical.lower().strip()
    if _C3_SIMPLE_RE.match(c):
        return True
    if c.startswith("c3") and _C3_ID_RE.search(c):
        return True
    return False


def iter_c3_cell_ids_in_range(
    cell_id_min: int = CELL_ID_BASE,
    cell_id_max: int = 39999,
) -> Iterable[int]:
    for cid in range(cell_id_min, cell_id_max + 1):
        yield cid
