#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Pair animgroup pipeline slugs with extracted ``batch_*/blocks/*.block.bin`` and review folders."""

from __future__ import annotations

import re
from pathlib import Path


def _mesh_scene_max_position_count(gltf_path: Path) -> int:
    """Largest POSITION accessor count on ``mesh_scene.gltf`` (JSON only; no bin read)."""
    try:
        from pygltflib import GLTF2
    except ImportError:
        return 0
    try:
        g = GLTF2().load(str(gltf_path))
    except (OSError, ValueError, KeyError):
        return 0
    mx = 0
    for mesh in g.meshes or []:
        for prim in mesh.primitives or []:
            attrs = prim.attributes
            if attrs is None:
                continue
            pos = getattr(attrs, "POSITION", None)
            if pos is None:
                continue
            ai = int(pos)
            if 0 <= ai < len(g.accessors):
                mx = max(mx, int(g.accessors[ai].count))
    return mx


def review_key_to_extracted_block_bin(pipeline_root: Path, key: str) -> Path | None:
    """
    ``batch_vz/03047_blocks__VZ__pmc_hum_mattias_v2_P000_Q3.block`` →
    ``<pipeline_root>/extracted/batch_vz/blocks/03047_blocks__VZ__pmc_hum_mattias_v2_P000_Q3.block.bin``.
    """
    key = key.strip().replace("\\", "/")
    if "/" not in key:
        return None
    batch, stem = key.split("/", 1)
    if not stem.endswith(".block"):
        return None
    p = pipeline_root / "extracted" / batch / "blocks" / f"{stem}.bin"
    return p if p.is_file() else None


def review_key_to_review_dir(pipeline_root: Path, key: str) -> Path | None:
    """``batch_vz/03047_….block`` → ``<pipeline_root>/extracted/review/batch_vz/03047_….block``."""
    key = key.strip().replace("\\", "/")
    if "/" not in key:
        return None
    p = pipeline_root / "extracted" / "review" / key.replace("\\", "/")
    return p if p.is_dir() else None


def find_review_mesh_scene_gltf(
    pipeline_root: Path,
    *,
    slug: str,
    related_keys: list[str],
    stem_numeric_id: str | None,
) -> Path | None:
    """
    Pick the best ``mesh_scene.gltf`` under ``extracted/review`` for this animation slug.

    Prefers review folders linked from ``related_keys``, then folders whose names match the
    slug token (e.g. ``mattias``) and look like character mesh blocks (``pmc_hum_*``) over
    ``briefing_job`` stubs.
    """
    review = pipeline_root / "extracted" / "review"
    if not review.is_dir():
        return None

    base = slug.split("_")[0].lower()
    candidates: list[tuple[int, Path]] = []

    def score_for_dir(d: Path) -> int:
        name_l = d.name.lower()
        s = 0
        if stem_numeric_id and stem_numeric_id in d.name:
            s += 25
        for rk in related_keys:
            tail = rk.split("/")[-1].lower()
            if tail == name_l:
                s += 80
        if base and base in name_l:
            s += 12
        if "pmc_hum" in name_l or "civ_veh" in name_l or "veh_" in name_l or "pmc_" in name_l:
            s += 30
        # ``related_review_keys`` often lists ``briefing_*`` blocks; those meshes are tiny vs body rigs.
        if "briefing_" in name_l:
            s -= 62
        if "animgroup" in name_l:
            s -= 40
        if (d / "mesh_scene.gltf").is_file() and (d / "mesh_scene.bin").is_file():
            s += 5
        return s

    seen: set[Path] = set()
    for rk in related_keys:
        d = review_key_to_review_dir(pipeline_root, rk)
        if d is None or d in seen:
            continue
        seen.add(d)
        gltf = d / "mesh_scene.gltf"
        if gltf.is_file():
            candidates.append((score_for_dir(d), gltf))

    for pack in sorted(review.iterdir()):
        if not pack.is_dir() or not pack.name.startswith("batch_"):
            continue
        try:
            for ent in pack.iterdir():
                if not ent.is_dir():
                    continue
                if ent in seen:
                    continue
                gltf = ent / "mesh_scene.gltf"
                if not gltf.is_file() or not (ent / "mesh_scene.bin").is_file():
                    continue
                name_l = ent.name.lower()
                if base and base not in name_l:
                    continue
                seen.add(ent)
                candidates.append((score_for_dir(ent), gltf))
        except OSError:
            continue

    if not candidates:
        return None
    candidates.sort(key=lambda x: (-x[0], len(x[1].parent.name)))
    best = candidates[0][0]
    # Among near-ties, prefer a ``mesh_scene`` with real geometry (briefing stubs lose here).
    near = [(sc, gl) for sc, gl in candidates if sc >= best - 28]
    if len(near) == 1:
        return near[0][1]
    ranked: list[tuple[int, int, Path]] = []
    for sc, gl in near:
        ranked.append((sc, _mesh_scene_max_position_count(gl), gl))
    ranked.sort(key=lambda x: (-x[0], -x[1], len(x[2].parent.name)))
    return ranked[0][2]


def ordered_skeleton_block_bins(
    pipeline_root: Path,
    animgroup_block_bin: Path,
    slug: str,
    related_keys: list[str],
) -> list[Path]:
    """
    Return ``*.block.bin`` paths to try for ``hkaSkeleton`` extraction (most promising first).

    Includes blocks derived from ``related_review_keys``, then the existing heuristics
    (``briefing_job*``, ``pmc_hum*`` globs), then the animgroup block itself.
    """
    ordered: list[Path] = []
    seen: set[Path] = set()

    def push(p: Path | None) -> None:
        if p is None or not p.is_file():
            return
        rp = p.resolve()
        if rp not in seen:
            seen.add(rp)
            ordered.append(rp)

    for rk in related_keys:
        push(review_key_to_extracted_block_bin(pipeline_root, rk))

    base = slug.split("_")[0]
    extr = pipeline_root / "extracted"
    if extr.is_dir():
        for pat in (
            f"batch_*/blocks/*briefing_job*{base}*.block.bin",
            f"batch_*/blocks/*pmc_hum*{base}*.block.bin",
            f"batch_*/blocks/*veh*{base}*.block.bin",
            f"batch_*/blocks/*{base}*.block.bin",
        ):
            for hit in sorted(extr.glob(pat)):
                push(hit)

    push(animgroup_block_bin.resolve())
    return ordered
