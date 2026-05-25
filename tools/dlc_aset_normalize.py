#!/usr/bin/env python3
"""Normalize and dedupe ASET rows on patch WAD blocks before FFCS assembly."""
from __future__ import annotations

from aset_type_ids import SCRIPT_ASET_TYPE_ID, type_id_for_type_hash
from ffcs_patch_wad import PatchBlock
from pandemic_hash import pandemic_hash_m2
from sges_decompress import decompress_sges_block
from wad_patcher import get_script_name, parse_block_entries, script_aset_entry

# Contracts required for import()/dynamic_import() (verify_dlc_import_chain).
DLC_IMPORT_CONTRACTS = (
    "dlccon001",
    "dlccon002",
    "dlccon003",
    "dlccon004a",
)


def _resident_path_score(path: str) -> int:
    """Rank PTHS paths; higher = preferred DLC script resident block."""
    p = path.replace("/", "\\").lower()
    if "vo_resident" in p or "resident" not in p:
        return -1
    if not p.endswith("p000_q3.block"):
        return -1
    score = 1
    if "\\dlc01\\" in p or p.startswith("blocks\\dlc01\\"):
        score += 10
    if "dlctest" in p:
        score -= 5
    if p.endswith("resident_p000_q3.block") or "\\resident_p000_q3.block" in p:
        score += 100
    return score


def find_dlc_script_resident_block_index(blocks: list[PatchBlock]) -> int | None:
    """Patch WAD index of dlc01 script resident (not vo_resident / dlctest)."""
    best_idx: int | None = None
    best_score = -1
    for idx, blk in enumerate(blocks):
        score = _resident_path_score(blk.path_string)
        if score > best_score:
            best_score = score
            best_idx = idx
    return best_idx if best_score > 0 else None


def find_resident_block_index_from_paths(paths: list[str]) -> int | None:
    """Same as find_dlc_script_resident_block_index but for raw PTHS path strings."""
    best_idx: int | None = None
    best_score = -1
    for idx, path in enumerate(paths):
        score = _resident_path_score(path)
        if score > best_score:
            best_score = score
            best_idx = idx
    return best_idx if best_score > 0 else None


def find_block_for_script_module(
    blocks: list[PatchBlock],
    module_name: str,
) -> int | None:
    """Block index containing a UCFX entry for *module_name* (hash or BINN name)."""
    target_hash = pandemic_hash_m2(module_name)
    for blk_idx, blk in enumerate(blocks):
        try:
            decomp = decompress_sges_block(
                blk.compressed_data, 0, len(blk.compressed_data))
            entries = parse_block_entries(decomp)
        except Exception:
            continue
        for entry in entries:
            if entry.get("hash") == target_hash:
                return blk_idx
            try:
                binn_name = get_script_name(decomp, entry)
            except Exception:
                continue
            if binn_name.lower() == module_name.lower():
                return blk_idx
    return None


def ensure_import_chain_script_aset(
    blocks: list[PatchBlock],
    module_names: list[str] | tuple[str, ...] = DLC_IMPORT_CONTRACTS,
) -> tuple[int, list[str]]:
    """Register script ASET rows for modules present in blocks but not yet in ASET."""
    global_hashes: set[int] = set()
    for blk in blocks:
        for row in blk.aset_entries:
            global_hashes.add(row["asset_hash"])

    added = 0
    not_in_blocks: list[str] = []
    for name in module_names:
        module_hash = pandemic_hash_m2(name)
        blk_idx = find_block_for_script_module(blocks, name)
        if blk_idx is None:
            not_in_blocks.append(name)
            continue
        if module_hash in global_hashes:
            continue
        blocks[blk_idx].aset_entries.append(script_aset_entry(module_hash))
        global_hashes.add(module_hash)
        added += 1
    return added, not_in_blocks


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
