#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Read-only audit of skeleton-related data across all extracted blocks.

Walks every ``output/extracted/batch_*/blocks/*.block.bin`` and records:

* For each asset entry with type ``0x5B724250`` (mesh): HIER size, SKIN count/sizes,
  BSHP count, and any string tokens found.
* For each ``*animgroup*`` block: per-record ``numTransformTracks`` from the wavelet
  header sniff.

Outputs ``output/animations/_skeleton_audit.json``.

Usage::

    ./.venv/bin/python tools/mesh_ucfx_skeleton_audit.py --pipeline-root ./output

This script makes no modifications to any files — purely read-only.
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from collections import Counter
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from texture_streaming_index import MESH_TYPE_HASH, iter_block_entries
from ucfx_mesh_codec import CHUNK_HDR, CONTAINER_SENTINEL, _HIER_NODE_STRIDE

ANIMGROUP_RECORD_MAGIC = 0x18166555
HAVOK_VER = b"Havok-5.5.0-r1"


def _sniff_track_count_from_blob(blob: bytes) -> int:
    """Read numTransformTracks from the wavelet struct header in a Havok blob."""
    for off in range(0, min(len(blob) - 96, 4096), 4):
        t = struct.unpack_from("<I", blob, off + 8)[0]
        if t != 3:
            continue
        d = struct.unpack_from("<f", blob, off + 12)[0]
        if not (0.001 <= d <= 600.0 and math.isfinite(d)):
            continue
        ntt = struct.unpack_from("<I", blob, off + 16)[0]
        if 1 <= ntt <= 500:
            return ntt
    return 0


def _character_slug(stem: str) -> str:
    import re
    m = re.search(r"animgroup_([A-Za-z0-9_]+)", stem, re.I)
    if m:
        return m.group(1).lower()
    return ""


def _iter_ucfx_chunks(data: bytes, entry_offset: int, entry_size: int):
    """Yield (tag_bytes, u0, u1, u2, u3) for UCFX chunk rows inside a block entry."""
    end = entry_offset + entry_size
    if entry_offset + 20 > end:
        return
    if data[entry_offset : entry_offset + 4] != b"UCFX":
        return
    u0, _u1, _u2, u3 = struct.unpack_from("<IIII", data, entry_offset + 4)
    n_chunks = int(u3)
    if n_chunks < 1 or n_chunks > 50_000:
        return
    if entry_offset + 20 + n_chunks * CHUNK_HDR > end:
        return
    for i in range(n_chunks):
        cpos = entry_offset + 20 + i * CHUNK_HDR
        tag = data[cpos : cpos + 4]
        cu = struct.unpack_from("<IIII", data, cpos + 4)
        yield tag, cu[0], cu[1], cu[2], cu[3]


def audit_mesh_entry(
    data: bytes, entry_offset: int, entry_size: int
) -> dict[str, Any] | None:
    """Extract skeleton-related chunk stats from a mesh UCFX entry."""
    hier_bytes = 0
    skin_count = 0
    skin_sizes: list[int] = []
    bshp_count = 0
    for tag, u0, u1, _u2, _u3 in _iter_ucfx_chunks(data, entry_offset, entry_size):
        if tag == b"HIER" and u0 != CONTAINER_SENTINEL and u1 >= _HIER_NODE_STRIDE:
            hier_bytes = int(u1)
        elif tag == b"SKIN" and u0 != CONTAINER_SENTINEL and u1 > 0:
            skin_count += 1
            skin_sizes.append(int(u1))
        elif tag == b"BSHP" and u0 != CONTAINER_SENTINEL and u1 > 0:
            bshp_count += 1

    if hier_bytes == 0 and skin_count == 0 and bshp_count == 0:
        return None

    implied_bones = hier_bytes // _HIER_NODE_STRIDE if hier_bytes >= _HIER_NODE_STRIDE else 0

    return {
        "hier_bytes": hier_bytes,
        "implied_bone_count": implied_bones,
        "skin_count": skin_count,
        "skin_sizes": skin_sizes,
        "bshp_count": bshp_count,
    }


def audit_animgroup_block(data: bytes) -> list[int]:
    """Return per-record numTransformTracks from an animgroup block."""
    if len(data) < 4:
        return []
    count = struct.unpack_from("<I", data, 0)[0]
    if count < 1 or count > 10_000:
        return []
    header_end = 4 + count * 16
    if header_end > len(data):
        return []
    cursor = header_end
    tracks: list[int] = []
    for i in range(count):
        off = 4 + i * 16
        _chk, mag, _res, sz = struct.unpack_from("<IIII", data, off)
        if mag != ANIMGROUP_RECORD_MAGIC:
            return []
        if cursor + sz > len(data):
            break
        rec = data[cursor : cursor + sz]
        hk_idx = rec.find(HAVOK_VER)
        if hk_idx >= 0:
            hk_blob = rec[hk_idx:]
            ntt = _sniff_track_count_from_blob(hk_blob)
            tracks.append(ntt)
        cursor += sz
    return tracks


def run_audit(pipeline_root: Path, *, verbose: bool = False) -> dict[str, Any]:
    extracted = pipeline_root / "extracted"
    meshes_with_hier: list[dict[str, Any]] = []
    animgroup_tracks: dict[str, list[int]] = {}
    hier_size_counter: Counter[int] = Counter()
    animated_slugs: set[str] = set()
    mesh_slugs: set[str] = set()

    block_dirs = sorted(extracted.glob("batch_*/blocks"))
    total_blocks = 0

    for blocks_dir in block_dirs:
        if not blocks_dir.is_dir():
            continue
        for fn in sorted(blocks_dir.iterdir()):
            if not fn.name.endswith(".block.bin"):
                continue
            total_blocks += 1
            stem = fn.stem.replace(".block", "")

            try:
                file_data = fn.read_bytes()
            except OSError:
                continue

            if "animgroup" in stem.lower():
                slug = _character_slug(stem)
                if slug:
                    animated_slugs.add(slug)
                tt = audit_animgroup_block(file_data)
                if tt:
                    animgroup_tracks[slug or stem] = tt

            entries = iter_block_entries(file_data)
            for asset_hash, type_hash, body_offset, size in entries:
                if type_hash != MESH_TYPE_HASH:
                    continue
                if body_offset + size > len(file_data):
                    continue
                info = audit_mesh_entry(file_data, body_offset, size)
                if info is None:
                    continue
                slug_guess = stem.lower()
                mesh_slugs.add(slug_guess)
                rec: dict[str, Any] = {
                    "block": fn.name,
                    "slug": slug_guess,
                    "asset_hash": f"0x{asset_hash:08X}",
                }
                rec.update(info)
                meshes_with_hier.append(rec)
                if info["hier_bytes"] > 0:
                    hier_size_counter[info["hier_bytes"]] += 1

            if verbose and total_blocks % 500 == 0:
                print(f"  ... scanned {total_blocks} blocks", file=sys.stderr)

    slugs_animated_without_mesh = sorted(animated_slugs - mesh_slugs)

    hier_distribution = [
        {"hier_bytes": k, "count": v}
        for k, v in sorted(hier_size_counter.items())
    ]

    doc: dict[str, Any] = {
        "version": 1,
        "total_blocks_scanned": total_blocks,
        "meshes_with_hier": meshes_with_hier,
        "animgroup_tracks": animgroup_tracks,
        "hier_size_distribution": hier_distribution,
        "slugs_animated_without_mesh": slugs_animated_without_mesh,
    }
    return doc


def main() -> int:
    ap = argparse.ArgumentParser(description="Skeleton audit across all extracted blocks")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=None)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    root = args.pipeline_root.resolve()
    out = (args.out or (root / "animations" / "_skeleton_audit.json")).resolve()

    print(f"Auditing {root / 'extracted'} ...", file=sys.stderr)
    doc = run_audit(root, verbose=args.verbose)

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(
        f"Wrote {out}  "
        f"(meshes_with_hier={len(doc['meshes_with_hier'])}, "
        f"animgroup_slugs={len(doc['animgroup_tracks'])}, "
        f"hier_sizes={len(doc['hier_size_distribution'])})",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
