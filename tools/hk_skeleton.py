# -*- coding: utf-8 -*-
"""
Skeleton helpers for the Mercenaries 2 animation pipeline.

**Important**: ``DEFAULT_BIPED`` / ``DEFAULT_BIPED_PARENT_INDICES`` /
``_DEFAULT_BIPED_LOCAL_T`` / ``default_skeleton_document`` are **unverified guesses**.
Investigation of the extracted game data found:

* 0 / 190 Havok slices contain an ``hkaSkeleton`` object instance (only classname table).
* ``Bip01`` / ``Pelvis`` / ``Spine`` / ``Hand`` etc. strings appear in **zero** extracted blocks.
* No separate skeleton files exist in the FFCS paths index.

These constants are preserved for reference only. The pipeline should never silently use
them as ground truth. Use :func:`unknown_skeleton_document` for honest output when no
decoded skeleton is available.
"""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

DEFAULT_BIPED = [
    "Root",
    "Pelvis",
    "Spine",
    "Spine1",
    "Spine2",
    "Neck",
    "Head",
    "HeadTop",
    "L_Clavicle",
    "L_UpperArm",
    "L_Forearm",
    "L_Hand",
    "L_Thumb1",
    "L_Thumb2",
    "L_Index1",
    "L_Index2",
    "L_Middle1",
    "L_Middle2",
    "L_Ring1",
    "L_Ring2",
    "L_Pinky1",
    "L_Pinky2",
    "R_Clavicle",
    "R_UpperArm",
    "R_Forearm",
    "R_Hand",
    "R_Thumb1",
    "R_Thumb2",
    "R_Index1",
    "R_Index2",
    "R_Middle1",
    "R_Middle2",
    "R_Ring1",
    "R_Ring2",
    "R_Pinky1",
    "R_Pinky2",
    "L_Thigh",
    "L_Calf",
    "L_Foot",
    "L_Toe",
    "R_Thigh",
    "R_Calf",
    "R_Foot",
    "R_Toe",
    "L_FingerA1",
    "L_FingerA2",
    "L_FingerB1",
    "L_FingerB2",
    "R_FingerA1",
    "R_FingerA2",
    "R_FingerB1",
    "R_FingerB2",
    "Weapon_R",
    "Weapon_L",
    "Holster_R",
    "Holster_L",
    "Prop_R",
    "Prop_L",
    "Attach_Back",
    "Attach_Head",
]

# Anatomically plausible parent indices aligned with :data:`DEFAULT_BIPED` (60 bones).
# Used when no ``hkaSkeleton`` can be parsed from Mercs2 blocks (virtual fixups missing).
DEFAULT_BIPED_PARENT_INDICES: list[int] = [
    -1,
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    5,
    8,
    9,
    10,
    11,
    12,
    11,
    14,
    11,
    16,
    11,
    18,
    11,
    20,
    5,
    22,
    23,
    24,
    25,
    26,
    25,
    28,
    25,
    30,
    25,
    32,
    25,
    34,
    1,
    36,
    37,
    38,
    1,
    40,
    41,
    42,
    11,
    44,
    11,
    46,
    25,
    48,
    25,
    50,
    25,
    11,
    22,
    8,
    25,
    11,
    4,
    6,
]

# Tiny local translations (meters-ish) so bind-pose ``glTF`` nodes are not stacked at one point.
_DEFAULT_BIPED_LOCAL_T: dict[int, tuple[float, float, float]] = {
    1: (0.0, 0.02, 0.0),
    2: (0.0, 0.03, 0.0),
    3: (0.0, 0.03, 0.0),
    4: (0.0, 0.03, 0.0),
    5: (0.0, 0.025, 0.0),
    6: (0.0, 0.04, 0.0),
    7: (0.0, 0.05, 0.0),
    8: (0.04, 0.0, 0.0),
    9: (0.0, -0.06, 0.02),
    10: (0.0, -0.07, 0.0),
    11: (0.0, -0.05, 0.0),
    22: (-0.04, 0.0, 0.0),
    23: (0.0, -0.06, 0.02),
    24: (0.0, -0.07, 0.0),
    25: (0.0, -0.05, 0.0),
    36: (0.08, -0.02, 0.0),
    37: (0.0, -0.09, 0.0),
    38: (0.0, -0.08, 0.02),
    39: (0.0, -0.03, 0.05),
    40: (-0.08, -0.02, 0.0),
    41: (0.0, -0.09, 0.0),
    42: (0.0, -0.08, 0.02),
    43: (0.0, -0.03, 0.05),
    12: (0.015, 0.0, 0.02),
    13: (0.02, 0.0, 0.0),
    14: (0.02, 0.0, 0.015),
    15: (0.025, 0.0, 0.0),
    16: (0.02, 0.0, 0.0),
    17: (0.025, 0.0, 0.0),
    18: (0.02, 0.0, 0.0),
    19: (0.025, 0.0, 0.0),
    20: (0.02, 0.0, 0.0),
    21: (0.025, 0.0, 0.0),
    26: (0.015, 0.0, 0.02),
    27: (0.02, 0.0, 0.0),
    28: (0.02, 0.0, 0.015),
    29: (0.025, 0.0, 0.0),
    30: (0.02, 0.0, 0.0),
    31: (0.025, 0.0, 0.0),
    32: (0.02, 0.0, 0.0),
    33: (0.025, 0.0, 0.0),
    34: (0.02, 0.0, 0.0),
    35: (0.025, 0.0, 0.0),
    44: (0.03, 0.0, 0.0),
    45: (0.025, 0.0, 0.0),
    46: (0.03, 0.0, 0.0),
    47: (0.025, 0.0, 0.0),
    48: (0.03, 0.0, 0.0),
    49: (0.025, 0.0, 0.0),
    50: (0.03, 0.0, 0.0),
    51: (0.025, 0.0, 0.0),
    52: (0.04, 0.0, 0.0),
    53: (-0.04, 0.0, 0.0),
    54: (0.0, 0.0, 0.06),
    55: (0.0, 0.0, -0.06),
    56: (0.03, 0.0, 0.0),
    57: (-0.03, 0.0, 0.0),
    58: (0.0, 0.04, -0.02),
    59: (0.0, 0.06, 0.0),
}

_BIP_TOKEN = re.compile(rb"(?:Bip01|bip01)(?:[\s_][^\x00\x01\x02]{0,80})?")


def load_classnames(path: Path) -> list[str]:
    if not path.is_file():
        return []
    rows: list[str] = []
    try:
        data: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return []
    if isinstance(data, list):
        for row in data:
            if isinstance(row, dict) and isinstance(row.get("name"), str):
                rows.append(row["name"])
    return rows


def suggest_bone_names(classnames_json: Path | None, n_bones: int) -> list[str]:
    names = load_classnames(classnames_json) if classnames_json else []
    picked = [n for n in names if re.search(r"(Pelvis|Spine|Head|Arm|Leg|Hand|Foot|Neck|Clavicle)", n)]
    if len(picked) >= n_bones:
        return picked[:n_bones]
    out = list(DEFAULT_BIPED)
    while len(out) < n_bones:
        out.append(f"bone_{len(out)}")
    return out[:n_bones]


def load_skeleton_json(path: Path) -> dict[str, Any] | None:
    """Load ``skeleton.json`` — works for decoded, unknown, and legacy biped docs."""
    if not path.is_file():
        return None
    try:
        data: Any = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return None
    if not isinstance(data, dict):
        return None
    return data


def save_skeleton_json(doc: dict[str, Any], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")


def default_skeleton_document(
    n_bones: int,
    *,
    classnames_json: Path | None = None,
) -> dict[str, Any]:
    """
    **DEPRECATED / quarantined** — unverified biped guess.

    Preserved for reference only. Pipeline code should call
    :func:`unknown_skeleton_document` instead.
    """
    names = suggest_bone_names(classnames_json, n_bones)
    parents: list[int] = []
    for i in range(n_bones):
        if i < len(DEFAULT_BIPED_PARENT_INDICES):
            parents.append(int(DEFAULT_BIPED_PARENT_INDICES[i]))
        else:
            parents.append(59 if i > 59 else max(-1, i - 1))

    ref: list[list[float]] = []
    for i in range(n_bones):
        tx, ty, tz = _DEFAULT_BIPED_LOCAL_T.get(i, (0.0, 0.0, 0.0))
        ref.append([float(tx), float(ty), float(tz), 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0])

    return {
        "bone_count": int(n_bones),
        "bone_names": names,
        "parent_indices": parents,
        "reference_pose": ref,
        "source": "default_biped_template",
    }


def unknown_skeleton_document(n_tracks: int) -> dict[str, Any]:
    """Honest skeleton placeholder when no decoded skeleton data exists.

    Emits flat (no parent chain) numbered tracks with identity transforms.
    The caller or viewer should treat ``source == "none_decoded"`` as an
    explicit signal that no real skeleton was found.
    """
    names = [f"track_{i}" for i in range(n_tracks)]
    parents = [-1] * n_tracks
    ref = [[0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0] for _ in range(n_tracks)]
    return {
        "bone_count": int(n_tracks),
        "bone_names": names,
        "parent_indices": parents,
        "reference_pose": ref,
        "source": "none_decoded",
    }


def harvest_bone_names_from_bytes(data: bytes, max_n: int = 200) -> list[str]:
    """Collect ``Bip01 …``-style NUL-terminated bone name candidates from raw packfile bytes."""
    found: list[str] = []
    seen: set[str] = set()
    for m in _BIP_TOKEN.finditer(data):
        raw = m.group(0)
        name = raw.split(b"\x00")[0].decode("ascii", errors="replace").strip()
        if len(name) < 4:
            continue
        if name not in seen:
            seen.add(name)
            found.append(name)
        if len(found) >= max_n:
            break
    return found


def build_skeleton_export(
    patched_or_raw: bytes,
    classnames_json: Path | None,
    *,
    n_bones_hint: int | None = None,
) -> dict[str, Any]:
    """
    Produce ``mesh_skin.json``-shaped dict: resolved ``bone_names`` plus empty mesh payload.

    When ≥8 Biped-like strings are harvested, they become the authoritative ordered list;
    otherwise :func:`suggest_bone_names` fills the chain to ``n_bones_hint`` (default 22).
    """
    harvested = harvest_bone_names_from_bytes(patched_or_raw)
    n_need = n_bones_hint or max(len(harvested), 22)
    if harvested:
        n_need = max(n_need, len(harvested))
    fallback = suggest_bone_names(classnames_json, n_need)
    bone_names = harvested if len(harvested) >= 8 else fallback[:n_need]

    return {
        "bone_names": bone_names,
        "bone_count": len(bone_names),
        "harvested_bip_strings": len(harvested),
        "mesh_skin": {
            "vertices": [],
            "indices": [],
            "bone_indices": [],
            "bone_weights": [],
            "note": "hkxMesh / hkaMeshBinding decode not implemented — use for bind-pose naming only; compare to review mesh.obj when skinning lands.",
        },
    }


def write_mesh_skin_json(doc: dict[str, Any], out_path: Path) -> None:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(doc, indent=2), encoding="utf-8")
