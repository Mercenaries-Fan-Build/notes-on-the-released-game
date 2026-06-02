#!/usr/bin/env python3
"""READ-ONLY render-object audit for Mercenaries 2 WADs.

Tests the hypothesis (docs/render_view_handle_crash_analysis.md) that the DLC
``vz-patch.wad`` registers an extra render-view / camera / scene render object
versus the base ``vz.wad``. This tool does NOT modify any WAD or conversion
code. It only reads.

Three levels of inventory per WAD:
  1. ASET type_id distribution (counts per resolved type name).
  2. PTHS path inventory (so base-vs-patch path diffs are possible).
  3. COMP ``info`` component-name scan inside ``layer`` (0xE6B81A54) and
     ``worldentity`` (0x5647C35D) blocks — these host the ECS components that
     could register a render/scene/camera/view object at load time. Plus a
     tolerant ASCII token scan for render/camera/scene/view/viewport tokens.

Usage:
    .venv/Scripts/python.exe tools/render_object_audit.py <wad> --out <json>
"""
from __future__ import annotations

import argparse
import json
import mmap as mmap_mod
import re
import struct
import sys
import time
from collections import Counter
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_wad import parse_ffcs, dump_paths_from_pths  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from ucfx_ecs_codec import _parse_chdr_sub_block  # noqa: E402

PAGE_SIZE = 0x8000

LAYER_TH = 0xE6B81A54
WORLDENTITY_TH = 0x5647C35D

# ASET type_id -> resolved name (from docs/type_hash_registry.md).
TYPE_ID_NAME = {
    0: "fxdict", 1: "decaltable", 3: "binary", 4: "musiccue",
    5: "facefxanimationset", 6: "wavebank", 7: "stringdb", 8: "worldentity",
    9: "layer", 10: "guidmap", 11: "animationtable", 12: "scrub",
    13: "sounddb", 14: "materialparam", 15: "font", 16: "animation",
    17: "animstatemachine", 18: "chatter", 19: "model", 20: "level",
    21: "soundbank", 22: "lowresterrain", 23: "scaleformgfx",
    24: "musicstatemap", 25: "fxdict", 26: "musicstatemap", 27: "texture",
    28: "path", 29: "effect", 30: "lineregion", 31: "animstatemachine",
    32: "terrainmesh", 33: "sequencetable", 34: "facefxactor", 35: "script",
}

TYPE_HASH_NAME = {
    0xF011157A: "texture", 0xBCFE6314: "path", 0x5B724250: "model",
    0x18166555: "animation", 0x600B904E: "scrub", 0xE6B81A54: "layer",
    0x42498680: "script", 0x6310807F: "lineregion", 0x7C569307: "terrainmesh",
    0x1602815C: "lowresterrain", 0x5608BD5A: "effect", 0xF753F6D0: "wavebank",
    0x665EF13E: "facefxanimationset", 0xE5273C14: "sounddb",
    0x9F8BCA10: "soundbank", 0xFE0E8320: "scaleformgfx",
    0x1CF649BB: "facefxactor", 0xFA0B8DBC: "chatter",
    0x207359C7: "animationtable", 0x8F0A54E2: "binary", 0x99E77ACE: "font",
    0xDE982D61: "materialparam", 0x39E5E978: "stringdb",
    0x59B9DF6A: "materialtable", 0x4D7D30C4: "watermap", 0x34612F86: "foliage",
    0xACCE47F2: "sequencetable", 0xC122545A: "musicstatemap",
    0xE8DF4D87: "musiccue", 0xECE70371: "animstatemachine",
    0xEA4829D5: "level", 0x3B0AABF8: "decaltable", 0x5647C35D: "worldentity",
    0x140E8728: "guidmap", 0xFA46D8A8: "fxdict",
}

# Tokens that would indicate a render/scene/camera/view render object.
RENDER_TOKEN_RE = re.compile(
    rb"(RenderView|RenderObject|RenderScene|RenderTarget|RenderNode|RenderCamera"
    rb"|SceneObject|SceneNode|SceneCapture|ReflectionProbe|Cubemap|PostProcess"
    rb"|Viewport|CameraComponent|\bCamera\b|\bView\b)",
    re.IGNORECASE,
)

# Component-name detector: COMP info names are short C identifiers.
IDENT_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_]{2,40}")


def parse_indx_entries(data: bytes) -> list[dict]:
    entries = []
    for i in range(len(data) // 12):
        o = i * 12
        page_index, _packed, flags_pages = struct.unpack_from("<III", data, o)
        entries.append({
            "block_index": i,
            "offset": page_index * PAGE_SIZE,
            "size_bytes": (flags_pages & 0xFFFF) * PAGE_SIZE,
        })
    return entries


def read_chunk(mm, off: int, size: int) -> bytes:
    return mm[off:off + size]


def scan_comp_info_names(raw: bytes) -> Counter:
    """Return Counter of COMP ``info`` component names in a decompressed block.

    Handles both layers_static (relative child offsets) and vz_state (absolute
    child offsets) by trying both interpretations and accepting whichever yields
    a valid leading C-identifier.
    """
    names: Counter = Counter()
    ucfx_positions: list[int] = []
    pos = 0
    while True:
        idx = raw.find(b"UCFX", pos)
        if idx == -1:
            break
        ucfx_positions.append(idx)
        pos = idx + 1

    for si, ucfx_pos in enumerate(ucfx_positions):
        block_end = (ucfx_positions[si + 1]
                     if si + 1 < len(ucfx_positions) else len(raw))
        try:
            chunks, data_area_start = _parse_chdr_sub_block(raw, ucfx_pos, block_end)
        except Exception:
            continue
        for ch in chunks:
            if ch["tag"] != "COMP":
                continue
            for c in ch["children"]:
                if c["tag"] != "info":
                    continue
                for base in (data_area_start + c["offset"], c["offset"]):
                    if base < 0 or base + 1 > len(raw):
                        continue
                    end = min(base + max(c["size"], 1), len(raw))
                    seg = raw[base:end]
                    ni = seg.find(b"\x00")
                    cand = seg[:ni] if ni >= 0 else seg
                    m = IDENT_RE.match(cand)
                    if m and m.start() == 0 and len(m.group(0)) == len(cand.rstrip(b"\x00")):
                        names[m.group(0).decode("ascii")] += 1
                        break
    return names


def audit_wad(wad_path: Path, deep: bool = True) -> dict:
    arch = parse_ffcs(wad_path)
    chunks = {c.tag: c for c in arch.chunks}
    out: dict = {
        "wad": str(wad_path),
        "file_size": arch.file_size,
        "block_count": None,
        "aset_rows": None,
    }

    with open(wad_path, "rb") as fh:
        mm = mmap_mod.mmap(fh.fileno(), 0, access=mmap_mod.ACCESS_READ)
        try:
            indx = chunks["INDX"]
            pths = chunks["PTHS"]
            aset = chunks["ASET"]
            indx_data = read_chunk(mm, indx.offset, indx.size)
            pths_data = read_chunk(mm, pths.offset, pths.size)
            aset_data = read_chunk(mm, aset.offset, aset.size)

            indx_entries = parse_indx_entries(indx_data)
            paths = dump_paths_from_pths(pths_data)
            out["block_count"] = len(indx_entries)

            # --- ASET type_id distribution ---
            aset_type_counts: Counter = Counter()
            n_rows = len(aset_data) // 16
            for i in range(n_rows):
                _h, _ref, _blk, tid = struct.unpack_from("<IIII", aset_data, i * 16)
                aset_type_counts[tid] += 1
            out["aset_rows"] = n_rows
            out["aset_type_id_counts"] = {
                f"{tid}:{TYPE_ID_NAME.get(tid, '?')}": cnt
                for tid, cnt in sorted(aset_type_counts.items())
            }

            # --- Path inventory ---
            out["paths"] = paths

            # --- Per-block header decompress: type_hash multiset ---
            block_type_hash = Counter()
            layer_world_blocks: list[tuple[int, str]] = []
            hdr_ok = hdr_fail = 0
            for entry in indx_entries:
                bo, bs = entry["offset"], entry["size_bytes"]
                bi = entry["block_index"]
                if bs == 0:
                    continue
                be = bo + bs
                if be > len(mm) or mm[bo:bo + 4] != b"sges":
                    hdr_fail += 1
                    continue
                try:
                    raw = decompress_sges_block(mm, bo, be, max_out=4 + 600 * 16 + 64)
                    if len(raw) < 4:
                        hdr_fail += 1
                        continue
                    count = struct.unpack_from("<I", raw, 0)[0]
                    if count == 0 or count > 200000:
                        hdr_fail += 1
                        continue
                    needed = 4 + count * 16
                    if len(raw) < needed:
                        raw = decompress_sges_block(mm, bo, be, max_out=needed + 64)
                        if len(raw) < needed:
                            hdr_fail += 1
                            continue
                    ths = set()
                    for j in range(count):
                        _nh, th, _fc, _cs = struct.unpack_from(
                            "<IIII", raw, 4 + j * 16)
                        block_type_hash[th] += 1
                        ths.add(th)
                    hdr_ok += 1
                    if LAYER_TH in ths or WORLDENTITY_TH in ths:
                        path = paths[bi] if bi < len(paths) else f"block_{bi:05d}"
                        layer_world_blocks.append((bi, path))
                except Exception:
                    hdr_fail += 1

            out["header_blocks_ok"] = hdr_ok
            out["header_blocks_fail"] = hdr_fail
            out["block_type_hash_counts"] = {
                f"0x{th:08X}:{TYPE_HASH_NAME.get(th, '?')}": cnt
                for th, cnt in block_type_hash.most_common()
            }
            out["layer_world_block_count"] = len(layer_world_blocks)
            out["layer_world_block_paths"] = [p for _, p in layer_world_blocks]

            # --- Deep COMP info-name scan on layer/worldentity blocks ---
            if deep:
                comp_names: Counter = Counter()
                render_token_hits: Counter = Counter()
                render_token_blocks: dict[str, list[str]] = {}
                for bi, path in layer_world_blocks:
                    entry = indx_entries[bi]
                    bo, bs = entry["offset"], entry["size_bytes"]
                    be = bo + bs
                    try:
                        raw = decompress_sges_block(mm, bo, be)
                    except Exception:
                        continue
                    comp_names.update(scan_comp_info_names(raw))
                    for m in RENDER_TOKEN_RE.finditer(raw):
                        tok = m.group(0).decode("ascii", "replace")
                        render_token_hits[tok] += 1
                        render_token_blocks.setdefault(tok, [])
                        if path not in render_token_blocks[tok]:
                            render_token_blocks[tok].append(path)
                out["comp_info_names"] = dict(comp_names.most_common())
                out["render_token_hits"] = dict(render_token_hits.most_common())
                out["render_token_blocks"] = {
                    k: v[:25] for k, v in render_token_blocks.items()
                }
        finally:
            mm.close()
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="Read-only render-object audit")
    ap.add_argument("wad", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--no-deep", action="store_true",
                    help="skip the deep COMP scan (header + ASET only)")
    args = ap.parse_args()
    t0 = time.time()
    result = audit_wad(args.wad, deep=not args.no_deep)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} in {time.time() - t0:.1f}s")
    print(f"  blocks={result['block_count']} aset_rows={result['aset_rows']} "
          f"layer/world blocks={result['layer_world_block_count']}")
    if "render_token_hits" in result:
        print(f"  render token hits: {result['render_token_hits']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
