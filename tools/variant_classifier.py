#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Classify Mercenaries 2 asset path stems into base IDs and variant tags (LOD, damage, quality)."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from typing import Any

# Quality / platform tokens often appear in block path names (from paths.txt).
_RE_PQ = re.compile(r"_P(\d+)_Q(\d+)$", re.IGNORECASE)
_RE_LOD = re.compile(r"_lod(\d+)$", re.IGNORECASE)
_RE_DMG = re.compile(r"_dmg\d*$", re.IGNORECASE)
_RE_DEST = re.compile(r"_(?:dest|destroyed)$", re.IGNORECASE)
_RE_INTACT = re.compile(r"_intact$", re.IGNORECASE)
_RE_BROKEN = re.compile(r"_broken$", re.IGNORECASE)
_RE_BURN = re.compile(r"_burn$", re.IGNORECASE)
_RE_WRECK = re.compile(r"_wreck$", re.IGNORECASE)
_RE_TEX_SUFFIX = re.compile(r"_(n|s|d|diffuse|normal|spec)(?:\.|$)", re.IGNORECASE)


def strip_block_suffix(stem: str) -> str:
    """Remove trailing .block from safe filename stem."""
    if stem.lower().endswith(".block"):
        return stem[: -len(".block")]
    return stem


def classify_path(path_like: str) -> dict[str, Any]:
    """Return variant metadata for a paths.txt line or review-folder stem."""
    raw = path_like.replace("\\", "/").strip()
    base_name = Path(raw).name
    stem = strip_block_suffix(base_name)

    tags: list[str] = []
    variant_type = "unknown"

    if _RE_PQ.search(stem):
        tags.append("quality_token")
    if _RE_LOD.search(stem):
        tags.append("lod")
        variant_type = "lod"
    if _RE_DMG.search(stem):
        tags.append("damaged")
        variant_type = "damaged"
    if _RE_DEST.search(stem):
        tags.append("destroyed")
        variant_type = "destroyed"
    if _RE_INTACT.search(stem):
        tags.append("intact")
        variant_type = "intact"
    if _RE_BROKEN.search(stem):
        tags.append("broken")
    if _RE_BURN.search(stem):
        tags.append("burn")
    if _RE_WRECK.search(stem):
        tags.append("wreck")

    ch_match = _RE_TEX_SUFFIX.search(stem)
    texture_channel = None
    if ch_match:
        texture_channel = ch_match.group(1).lower()
        if texture_channel in ("diffuse", "d"):
            texture_channel = "diffuse"
        elif texture_channel in ("normal", "n"):
            texture_channel = "normal"
        elif texture_channel in ("spec", "s"):
            texture_channel = "specular"

    # Base asset id: strip known trailing variant tokens heuristically
    base_id = stem
    for pat in (
        r"_P\d+_Q\d+$",
        r"_lod\d+$",
        r"_dmg\d*$",
        r"_(?:dest|destroyed)$",
        r"_intact$",
        r"_broken$",
        r"_burn$",
        r"_wreck$",
        r"_(?:n|s|d|diffuse|normal|spec)$",
    ):
        base_id = re.sub(pat, "", base_id, flags=re.IGNORECASE)

    return {
        "original": raw,
        "stem": stem,
        "base_asset_id": base_id,
        "variant_tags": tags,
        "variant_type": variant_type,
        "texture_channel_hint": texture_channel,
    }


def build_registry(paths_file: Path | None, stems: list[str] | None) -> dict[str, Any]:
    entries: list[dict[str, Any]] = []
    by_base: dict[str, list[str]] = {}

    lines: list[str] = []
    if paths_file and paths_file.is_file():
        lines = [ln.strip() for ln in paths_file.read_text(encoding="utf-8", errors="replace").splitlines() if ln.strip()]
    if stems:
        lines.extend(stems)

    for ln in lines:
        info = classify_path(ln)
        entries.append(info)
        bid = info["base_asset_id"]
        by_base.setdefault(bid, []).append(info["stem"])

    return {
        "count": len(entries),
        "entries": entries,
        "grouped_by_base_asset_id": {k: sorted(set(v)) for k, v in sorted(by_base.items())},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Mercenaries 2 path / stem variant classifier")
    ap.add_argument("--paths", type=Path, help="paths.txt from ffcs extraction")
    ap.add_argument("--stem", action="append", help="Single stem to classify (repeatable)")
    ap.add_argument("--out", type=Path, help="Write variant_registry.json")
    args = ap.parse_args()

    if not args.paths and not args.stem:
        ap.error("provide --paths and/or --stem")

    reg = build_registry(args.paths, args.stem or [])
    text = json.dumps(reg, indent=2)
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(text, encoding="utf-8")
        print(f"Wrote {args.out} ({reg['count']} entries)")
    else:
        print(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
