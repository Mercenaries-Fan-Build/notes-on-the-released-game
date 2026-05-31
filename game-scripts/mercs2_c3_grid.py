"""Decode Mercenaries 2 c3XXXX world streaming cell IDs to game-world XYZ (metres).

Used by ``populate_world.py`` in the UE Editor (keep in ``game-scripts/`` so
``importlib.reload`` picks up fixes without a stale ``tools/`` module cache).

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
# populate_world actor labels: Cell_c3{cell_id} (e.g. Cell_c330990 → id 30990, not c33099).
_CELL_ACTOR_LABEL_RE = re.compile(r"^cell_c3(\d+)$", re.IGNORECASE)

# Sanity-check anchor: c30123 must not decode to grid corner c30001 (-3861.25 m X/Z).
_SELF_TEST_STEM = "c30123"
_SELF_TEST_CELL_ID = 30123
_SELF_TEST_GAME_X = -2156.25
_SELF_TEST_GAME_Z = -3783.75
GRID_LOGIC_VERSION = 3


def _cell_id_from_c3_digits(four_digits: str) -> int:
    """Decode ``c3`` + four digits to a retail streaming id (30001–39999).

    Names like ``c30123`` embed ``0123`` as the slot offset from ``c30001``, not
    the literal integer ``123``.
    """
    return CELL_ID_BASE - 1 + int(four_digits, 10)


def parse_cell_ids_from_stem(stem: str) -> list[int]:
    """Return all c3#### numeric IDs embedded in a block folder stem."""
    return [_cell_id_from_c3_digits(m.group(1)) for m in _C3_ID_RE.finditer(stem)]


def primary_cell_id_from_stem(stem: str) -> int | None:
    """Pick the anchor cell ID for placement (first c3#### in the stem)."""
    ids = parse_cell_ids_from_stem(stem)
    return ids[0] if ids else None


def cell_id_from_actor_label(label: str) -> int | None:
    """Decode ``Cell_c3{cell_id}`` Outliner labels from ``populate_world``."""
    if not label:
        return None
    m = _CELL_ACTOR_LABEL_RE.match(label.strip())
    if not m:
        return None
    cid = int(m.group(1))
    if CELL_ID_BASE <= cid <= 39999:
        return cid
    return None


def game_xz_to_cell_id(x: float, z: float) -> int:
    """Inverse of ``cell_id_to_world_xyz`` centre (nearest cell column/row)."""
    col = int((float(x) - WORLD_MIN_X) / CELL_SIZE_X - 0.5 + 1e-6)
    row = int((float(z) - WORLD_MIN_Z) / CELL_SIZE_Z - 0.5 + 1e-6)
    col = max(0, min(GRID_COLS - 1, col))
    row = max(0, min(GRID_COLS - 1, row))
    return CELL_ID_BASE + row * GRID_COLS + col


def cell_id_from_asset_path(asset_path: str) -> int | None:
    """Decode cell id from a UE asset path or review block folder name.

    Walks path segments (``SM_*`` leaves, ``mesh_scene``, etc.) and returns the
    first ``c3####`` anchor id found.
    """
    if not asset_path:
        return None
    parts = asset_path.replace("\\", "/").split("/")
    for seg in reversed(parts):
        if not seg:
            continue
        lower = seg.lower()
        cid = cell_id_from_actor_label(seg)
        if cid is not None:
            return cid
        if lower.startswith("sm_"):
            seg = seg[3:]
        cid = primary_cell_id_from_stem(seg)
        if cid is not None:
            return cid
    return cell_id_from_actor_label(asset_path) or primary_cell_id_from_stem(asset_path)


def cell_id_to_row_col(cell_id: int) -> tuple[int, int]:
    """Map a c3#### id to (row, col) in the 100×100 streaming grid."""
    linear = max(0, int(cell_id) - CELL_ID_BASE)
    row = linear // GRID_COLS
    col = linear % GRID_COLS
    return row, col


def cell_id_to_world_xyz(cell_id: int, *, y: float = 0.0) -> tuple[float, float, float]:
    """Return game-space (x, y, z) centre for a streaming cell (metres)."""
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


def verify_grid_logic() -> tuple[bool, str]:
    """Return (ok, detail) for editor startup diagnostics."""
    cid = primary_cell_id_from_stem(_SELF_TEST_STEM)
    if cid != _SELF_TEST_CELL_ID:
        return False, f"{_SELF_TEST_STEM} -> cell_id {cid!r} (expected {_SELF_TEST_CELL_ID})"
    xyz = cell_id_to_world_xyz(cid)
    if (
        abs(xyz[0] - _SELF_TEST_GAME_X) > 0.01
        or abs(xyz[2] - _SELF_TEST_GAME_Z) > 0.01
    ):
        return False, f"{_SELF_TEST_STEM} -> game {xyz} (stale/broken grid math)"
    label_cid = cell_id_from_actor_label("Cell_c330990")
    if label_cid != 30990:
        return False, f"Cell_c330990 -> {label_cid!r} (expected 30990; label regex broken)"
    return True, (
        f"v{GRID_LOGIC_VERSION} {_SELF_TEST_STEM} -> id={cid} "
        f"game=({xyz[0]:.2f}, {xyz[1]:.2f}, {xyz[2]:.2f})"
    )
