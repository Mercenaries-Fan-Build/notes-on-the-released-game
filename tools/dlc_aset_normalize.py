#!/usr/bin/env python3
"""Normalize and dedupe ASET rows on patch WAD blocks before FFCS assembly."""
from __future__ import annotations

from aset_type_ids import SCRIPT_ASET_TYPE_ID, type_id_for_type_hash
from ffcs_patch_wad import PatchBlock
from sges_decompress import decompress_sges_block
from wad_patcher import parse_block_entries


def _hash_to_type_hash_map(block_data: bytes) -> dict[int, int]:
    out: dict[int, int] = {}
    try:
        entries = parse_block_entries(block_data)
    except Exception:
        return out
    for entry in entries:
        h = entry.get("hash")
        th = entry.get("type_hash", 0)
        if h and th:
            out[h] = th
    return out


def normalize_block_aset_type_ids(blk: PatchBlock, hash_to_th: dict[int, int]) -> int:
    """Fix u32_3 on block ASET rows using UCFX type_hash. Returns change count."""
    changed = 0
    for entry in blk.aset_entries:
        th = hash_to_th.get(entry["asset_hash"])
        if not th:
            continue
        tid = type_id_for_type_hash(th)
        if tid is None:
            continue
        if entry.get("u32_3") != tid:
            entry["u32_3"] = tid
            changed += 1
    return changed


def build_hash_type_maps(blocks: list[PatchBlock]) -> list[dict[int, int]]:
    maps: list[dict[int, int]] = []
    for blk in blocks:
        try:
            raw = decompress_sges_block(
                blk.compressed_data, 0, len(blk.compressed_data))
        except Exception:
            maps.append({})
            continue
        maps.append(_hash_to_type_hash_map(raw))
    return maps


def normalize_all_block_asets(blocks: list[PatchBlock]) -> int:
    """Normalize type_id on every block's ASET entries from UCFX headers."""
    maps = build_hash_type_maps(blocks)
    total = 0
    for blk, hmap in zip(blocks, maps):
        total += normalize_block_aset_type_ids(blk, hmap)
    return total


def dedupe_asset_hash_across_blocks(
    blocks: list[PatchBlock],
    asset_hash: int,
    *,
    prefer_type_id: int | None = None,
    prefer_min_block_index: int | None = None,
) -> int:
    """Keep one ASET row per asset_hash across all blocks. Returns rows removed."""
    candidates: list[tuple[int, int, dict]] = []
    for bi, blk in enumerate(blocks):
        for ei, entry in enumerate(blk.aset_entries):
            if entry["asset_hash"] == asset_hash:
                candidates.append((bi, ei, entry))

    if len(candidates) <= 1:
        return 0

    def score(item: tuple[int, int, dict]) -> tuple:
        bi, _ei, e = item
        tid = e.get("u32_3", 0)
        prefer_bi = (
            2 if prefer_min_block_index is not None and bi == prefer_min_block_index
            else 0
        )
        prefer_tid = 1 if prefer_type_id is not None and tid == prefer_type_id else 0
        bad_tid = 0 if tid == 26 and prefer_type_id == SCRIPT_ASET_TYPE_ID else 1
        return (prefer_bi, prefer_tid, bad_tid, bi, tid == SCRIPT_ASET_TYPE_ID)

    keep_bi, keep_ei, _ = max(candidates, key=score)
    to_remove = [
        (bi, ei) for bi, ei, _ in candidates
        if not (bi == keep_bi and ei == keep_ei)
    ]
    for bi, ei in sorted(to_remove, key=lambda t: (t[0], -t[1])):
        blocks[bi].aset_entries.pop(ei)
    return len(to_remove)


def dedupe_all_duplicate_hashes(blocks: list[PatchBlock]) -> int:
    """For each asset_hash appearing in multiple blocks, keep the best row."""
    by_hash: dict[int, list[tuple[int, int]]] = {}
    for bi, blk in enumerate(blocks):
        for ei, entry in enumerate(blk.aset_entries):
            by_hash.setdefault(entry["asset_hash"], []).append((bi, ei))

    removed = 0
    for asset_hash, locs in by_hash.items():
        if len(locs) <= 1:
            continue
        removed += dedupe_asset_hash_across_blocks(
            blocks,
            asset_hash,
            prefer_type_id=SCRIPT_ASET_TYPE_ID,
        )
    return removed
