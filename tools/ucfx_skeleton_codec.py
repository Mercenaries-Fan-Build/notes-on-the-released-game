#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Probe HIER chunk data to extract skeleton bind-pose from mesh UCFX blocks.

The HIER chunk has a known 176-byte per-node layout (already decoded in
``ucfx_mesh_codec.py``). This module validates the layout across a cross-category
test set and writes ``tools/_skeleton_probe.json`` with results.

Each HIER node (176 bytes):
  +0..+3:   u32 name hash
  +4..+5:   u16 (index field a — always 1 in practice)
  +6..+7:   u16 first-child index (0xFFFF = leaf)
  +8..+9:   u16 parent index (0xFFFF = root)
  +10..+11:  u16 sibling / next-sibling index (0xFFFF = none)
  +12..+15:  u32 flags (always 0 in probed data)
  +16..+79:  4×4 float local transform (row-major, affine)
  +80..+143: 4×4 float inverse-bind matrix (row-major, affine)
  +144..+159: float[3] tail_bbox_min + padding float (1.0)
  +160..+175: float[3] tail_bbox_max + padding float (1.0)

Usage::

    ./.venv/bin/python tools/ucfx_skeleton_codec.py --pipeline-root ./output
"""

from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path
from typing import Any

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from texture_streaming_index import MESH_TYPE_HASH, iter_block_entries
from ucfx_mesh_codec import CHUNK_HDR, CONTAINER_SENTINEL, _HIER_NODE_STRIDE


def _read_mat4_row_major(data: bytes, off: int) -> list[list[float]]:
    m: list[list[float]] = []
    for r in range(4):
        row = list(struct.unpack_from("<4f", data, off + r * 16))
        for c in range(4):
            if not math.isfinite(row[c]):
                row[c] = 0.0
        m.append(row)
    return m


def _mat4_is_identity(m: list[list[float]], eps: float = 1e-4) -> bool:
    for r in range(4):
        for c in range(4):
            expected = 1.0 if r == c else 0.0
            if abs(m[r][c] - expected) > eps:
                return False
    return True


def _mat4_mul(a: list[list[float]], b: list[list[float]]) -> list[list[float]]:
    r: list[list[float]] = [[0.0] * 4 for _ in range(4)]
    for i in range(4):
        for j in range(4):
            s = 0.0
            for k in range(4):
                s += a[i][k] * b[k][j]
            r[i][j] = s
    return r


def _decompose_trs(m: list[list[float]]) -> dict[str, list[float]]:
    """Extract T/R(quat)/S from row-major affine mat4. Rotation via Shepperd's method."""
    tx, ty, tz = m[3][0], m[3][1], m[3][2]

    sx = math.sqrt(m[0][0] ** 2 + m[0][1] ** 2 + m[0][2] ** 2) or 1.0
    sy = math.sqrt(m[1][0] ** 2 + m[1][1] ** 2 + m[1][2] ** 2) or 1.0
    sz = math.sqrt(m[2][0] ** 2 + m[2][1] ** 2 + m[2][2] ** 2) or 1.0

    r00, r01, r02 = m[0][0] / sx, m[0][1] / sx, m[0][2] / sx
    r10, r11, r12 = m[1][0] / sy, m[1][1] / sy, m[1][2] / sy
    r20, r21, r22 = m[2][0] / sz, m[2][1] / sz, m[2][2] / sz

    trace = r00 + r11 + r22
    if trace > 0:
        s = 0.5 / math.sqrt(trace + 1.0)
        qw = 0.25 / s
        qx = (r12 - r21) * s
        qy = (r20 - r02) * s
        qz = (r01 - r10) * s
    elif r00 > r11 and r00 > r22:
        s = 2.0 * math.sqrt(1.0 + r00 - r11 - r22)
        qw = (r12 - r21) / s
        qx = 0.25 * s
        qy = (r01 + r10) / s
        qz = (r20 + r02) / s
    elif r11 > r22:
        s = 2.0 * math.sqrt(1.0 + r11 - r00 - r22)
        qw = (r20 - r02) / s
        qx = (r01 + r10) / s
        qy = 0.25 * s
        qz = (r02 + r12) / s
    else:
        s = 2.0 * math.sqrt(1.0 + r22 - r00 - r11)
        qw = (r01 - r10) / s
        qx = (r20 + r02) / s
        qy = (r02 + r12) / s
        qz = 0.25 * s

    ql = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw) or 1.0
    qx, qy, qz, qw = qx / ql, qy / ql, qz / ql, qw / ql

    return {
        "t": [tx, ty, tz],
        "q": [qx, qy, qz, qw],
        "s": [sx, sy, sz],
    }


def probe_hier_chunk(
    data: bytes, abs_base: int, hier_len: int
) -> dict[str, Any]:
    """Probe a single HIER chunk and return validation results."""
    n_nodes = hier_len // _HIER_NODE_STRIDE
    if n_nodes == 0:
        return {"error": "zero nodes", "n_nodes": 0}

    parents: list[int] = []
    name_hashes: list[str] = []
    local_is_identity: list[bool] = []
    ibm_is_identity: list[bool] = []
    local_translations: list[list[float]] = []
    reference_pose: list[list[float]] = []

    for rec in range(n_nodes):
        off = abs_base + rec * _HIER_NODE_STRIDE
        nhash = struct.unpack_from("<I", data, off)[0]
        parent = struct.unpack_from("<H", data, off + 8)[0]
        parent = parent if parent != 0xFFFF else -1

        mat_local = _read_mat4_row_major(data, off + 16)
        mat_ibm = _read_mat4_row_major(data, off + 80)

        parents.append(parent)
        name_hashes.append(f"0x{nhash:08X}")
        local_is_identity.append(_mat4_is_identity(mat_local))
        ibm_is_identity.append(_mat4_is_identity(mat_ibm))

        lt = mat_local[3]
        local_translations.append([lt[0], lt[1], lt[2]])

        trs = _decompose_trs(mat_local)
        row = [
            trs["t"][0], trs["t"][1], trs["t"][2],
            trs["q"][0], trs["q"][1], trs["q"][2], trs["q"][3],
            trs["s"][0], trs["s"][1], trs["s"][2],
        ]
        reference_pose.append([round(v, 6) for v in row])

    root_count = sum(1 for p in parents if p == -1)
    valid_chain = all(p < i or p == -1 for i, p in enumerate(parents))
    n_identity_local = sum(local_is_identity)
    n_identity_ibm = sum(ibm_is_identity)

    # Verify world_transform * IBM = identity for all nodes
    # Build world matrices via BFS/topological order
    world_ibm_identity_count = 0
    local_mats: list[list[list[float]]] = []
    ibm_mats: list[list[list[float]]] = []
    for rec in range(n_nodes):
        off = abs_base + rec * _HIER_NODE_STRIDE
        local_mats.append(_read_mat4_row_major(data, off + 16))
        ibm_mats.append(_read_mat4_row_major(data, off + 80))

    worlds: list[list[list[float]] | None] = [None] * n_nodes
    # Process in index order since parent[i] < i is guaranteed
    for rec in range(n_nodes):
        p = parents[rec]
        if p < 0 or p >= n_nodes:
            worlds[rec] = local_mats[rec]
        else:
            worlds[rec] = _mat4_mul(local_mats[rec], worlds[p])

    for rec in range(n_nodes):
        if worlds[rec] is not None:
            product = _mat4_mul(worlds[rec], ibm_mats[rec])
            if _mat4_is_identity(product, eps=0.02):
                world_ibm_identity_count += 1

    return {
        "n_nodes": n_nodes,
        "hier_bytes": hier_len,
        "stride": _HIER_NODE_STRIDE,
        "root_count": root_count,
        "valid_parent_chain": valid_chain,
        "n_identity_local": n_identity_local,
        "n_identity_ibm": n_identity_ibm,
        "world_ibm_identity_pairs": world_ibm_identity_count,
        "parents": parents,
        "name_hashes": name_hashes[:20],
        "reference_pose": reference_pose,
    }


def find_hier_in_block(
    data: bytes, block_path: Path
) -> list[dict[str, Any]]:
    """Find all mesh entries with HIER chunks in a block file."""
    results: list[dict[str, Any]] = []
    entries = iter_block_entries(data)

    for asset_hash, type_hash, body_offset, size in entries:
        if type_hash != MESH_TYPE_HASH:
            continue
        if body_offset + 20 > len(data):
            continue
        if data[body_offset : body_offset + 4] != b"UCFX":
            continue

        u0, _u1, _u2, u3 = struct.unpack_from("<IIII", data, body_offset + 4)
        data_base = body_offset + int(u0)
        n_chunks = int(u3)
        if n_chunks < 1 or n_chunks > 50_000:
            continue
        if body_offset + 20 + n_chunks * CHUNK_HDR > len(data):
            continue

        for i in range(n_chunks):
            cpos = body_offset + 20 + i * CHUNK_HDR
            tag = data[cpos : cpos + 4]
            cu = struct.unpack_from("<IIII", data, cpos + 4)
            if tag == b"HIER" and cu[0] != CONTAINER_SENTINEL and cu[1] >= _HIER_NODE_STRIDE:
                abs_base = data_base + cu[0]
                hier_len = cu[1]
                if abs_base + hier_len <= len(data):
                    probe = probe_hier_chunk(data, abs_base, hier_len)
                    probe["block"] = block_path.name
                    probe["asset_hash"] = f"0x{asset_hash:08X}"
                    results.append(probe)
                break

    return results


def run_probe(pipeline_root: Path, *, verbose: bool = False) -> dict[str, Any]:
    """Probe a cross-category test set of known blocks."""
    extracted = pipeline_root / "extracted"
    blocks_dir = extracted / "batch_vz" / "blocks"

    test_blocks: dict[str, str] = {
        "mattias_v2": "03047_blocks__VZ__pmc_hum_mattias_v2_P000_Q3.block.bin",
        "mattias_v3": "03359_blocks__VZ__pmc_hum_mattias_v3_P000_Q3.block.bin",
        "mattias_v4": "03060_blocks__VZ__pmc_hum_mattias_v4_P000_Q3.block.bin",
        "jen": "03029_blocks__VZ__pmc_hum_jen_P000_Q3.block.bin",
        "amx30_tank": "03420_blocks__VZ__vz_veh_tank_amx30_aa_P000_Q3.block.bin",
        "helicopter_alouette": "03054_blocks__VZ__vz_veh_helicopter_alouetteiii_P000_Q3.block.bin",
    }

    results: dict[str, Any] = {}
    for label, fn in test_blocks.items():
        path = blocks_dir / fn
        if not path.is_file():
            results[label] = {"error": f"file not found: {path}"}
            if verbose:
                print(f"  SKIP {label}: not found", file=sys.stderr)
            continue

        data = path.read_bytes()
        probes = find_hier_in_block(data, path)
        if not probes:
            results[label] = {"error": "no HIER chunk found"}
            if verbose:
                print(f"  SKIP {label}: no HIER", file=sys.stderr)
            continue

        probe = probes[0]
        results[label] = probe
        if verbose:
            print(
                f"  {label}: {probe['n_nodes']} nodes, "
                f"root_count={probe['root_count']}, "
                f"valid_chain={probe['valid_parent_chain']}, "
                f"world_ibm_identity={probe['world_ibm_identity_pairs']}/{probe['n_nodes']}",
                file=sys.stderr,
            )

    summary: dict[str, Any] = {
        "version": 1,
        "layout": {
            "stride": _HIER_NODE_STRIDE,
            "format": "known_176byte_ucfx_hier",
            "fields": {
                "+0": "u32 name_hash",
                "+4": "u16 index_a (always 1)",
                "+6": "u16 first_child (0xFFFF=leaf)",
                "+8": "u16 parent_index (0xFFFF=root)",
                "+10": "u16 sibling_index (0xFFFF=none)",
                "+12": "u32 flags (always 0)",
                "+16": "mat4x4 local_transform (row-major, affine, translation in row 3)",
                "+80": "mat4x4 inverse_bind_matrix (row-major, affine)",
                "+144": "vec3 tail_bbox_min + 1.0 pad",
                "+160": "vec3 tail_bbox_max + 1.0 pad",
            },
        },
        "probes": results,
    }
    return summary


_HAVOK_VER = b"Havok-5.5.0-r1"
_HKX_DATA_SECTION_HEADER_OFFSET = 120  # 3rd section header in the file


def extract_bone_hash_table(hkx: bytes, num_transform_tracks: int) -> list[int] | None:
    """Read the bone-hash table appended to the Havok data section.

    The Mercs2 exporter stores ``num_transform_tracks`` u32 HIER-node hashes
    at the position the Havok packfile header calls ``virtual_fixup_offset``
    inside the ``__data__`` section.  Each hash at index *i* identifies which
    HIER node animation track *i* drives.

    Returns a list of *num_transform_tracks* u32 hashes, or ``None`` if the
    file layout doesn't match expectations.
    """
    if len(hkx) < _HKX_DATA_SECTION_HEADER_OFFSET + 48:
        return None
    if not hkx.startswith(_HAVOK_VER):
        return None

    data_abs = struct.unpack_from("<I", hkx, _HKX_DATA_SECTION_HEADER_OFFSET + 20)[0]
    vf_off = struct.unpack_from("<I", hkx, _HKX_DATA_SECTION_HEADER_OFFSET + 20 + 12)[0]

    table_start = data_abs + vf_off
    table_end = table_start + num_transform_tracks * 4
    if table_end > len(hkx):
        return None

    return [struct.unpack_from("<I", hkx, table_start + i * 4)[0] for i in range(num_transform_tracks)]


def _read_hier_nodes(data: bytes, body_offset: int) -> tuple[list[dict[str, Any]], dict[int, int]] | None:
    """Parse all HIER nodes from a mesh UCFX entry.

    Returns ``(nodes, hash_to_idx)`` where each node dict has ``hash``,
    ``parent``, ``trs``, and ``name``, or ``None`` if no HIER chunk found.
    """
    if data[body_offset : body_offset + 4] != b"UCFX":
        return None

    u0, _u1, _u2, u3 = struct.unpack_from("<IIII", data, body_offset + 4)
    data_base = body_offset + int(u0)
    n_chunks = int(u3)
    if n_chunks < 1 or n_chunks > 50_000:
        return None
    if body_offset + 20 + n_chunks * CHUNK_HDR > len(data):
        return None

    for i in range(n_chunks):
        cpos = body_offset + 20 + i * CHUNK_HDR
        tag = data[cpos : cpos + 4]
        cu = struct.unpack_from("<IIII", data, cpos + 4)
        if tag != b"HIER" or cu[0] == CONTAINER_SENTINEL or cu[1] < _HIER_NODE_STRIDE:
            continue

        abs_base = data_base + cu[0]
        hier_len = cu[1]
        if abs_base + hier_len > len(data):
            continue

        n_nodes = hier_len // _HIER_NODE_STRIDE
        if n_nodes == 0:
            continue

        nodes: list[dict[str, Any]] = []
        hash_to_idx: dict[int, int] = {}

        for rec in range(n_nodes):
            off = abs_base + rec * _HIER_NODE_STRIDE
            nhash = struct.unpack_from("<I", data, off)[0]
            parent = struct.unpack_from("<H", data, off + 8)[0]

            mat_local = _read_mat4_row_major(data, off + 16)
            trs = _decompose_trs(mat_local)

            nodes.append({
                "hash": nhash,
                "parent": parent if parent != 0xFFFF else -1,
                "trs": trs,
                "name": f"node_{rec}_{nhash:08x}",
            })
            hash_to_idx[nhash] = rec

        return nodes, hash_to_idx

    return None


def extract_hier_skeleton(
    block_path: Path,
    bone_hashes: list[int] | None = None,
) -> dict[str, Any] | None:
    """Extract a skeleton document from the HIER chunk of a mesh block.

    If *bone_hashes* is provided (from :func:`extract_bone_hash_table`), only
    the referenced HIER nodes (plus necessary ancestors) are emitted, in
    track order.  The resulting skeleton has ``source: "ucfx_hier"`` and is
    treated as ``skeleton_status = "decoded"``.

    Without *bone_hashes* the full HIER tree is emitted with
    ``source: "ucfx_hier_unverified"`` (treated as ``skeleton_status = "unknown"``).
    """
    try:
        data = block_path.read_bytes()
    except OSError:
        return None

    entries = iter_block_entries(data)
    for asset_hash, type_hash, body_offset, size in entries:
        if type_hash != MESH_TYPE_HASH:
            continue
        if body_offset + 20 > len(data):
            continue

        parsed = _read_hier_nodes(data, body_offset)
        if parsed is None:
            continue
        nodes, hash_to_idx = parsed

        if bone_hashes is not None:
            return _build_mapped_skeleton(nodes, hash_to_idx, bone_hashes, block_path)

        # Unverified fallback — emit full tree
        parents: list[int] = []
        bone_names: list[str] = []
        reference_pose: list[list[float]] = []

        for nd in nodes:
            parents.append(nd["parent"])
            bone_names.append(nd["name"])
            trs = nd["trs"]
            row = [
                trs["t"][0], trs["t"][1], trs["t"][2],
                trs["q"][0], trs["q"][1], trs["q"][2], trs["q"][3],
                trs["s"][0], trs["s"][1], trs["s"][2],
            ]
            reference_pose.append([round(v, 6) for v in row])

        return {
            "bone_count": len(nodes),
            "bone_names": bone_names,
            "parent_indices": parents,
            "reference_pose": reference_pose,
            "source": "ucfx_hier_unverified",
            "meta": {
                "block": block_path.name,
                "hier_bytes": len(nodes) * _HIER_NODE_STRIDE,
                "stride": _HIER_NODE_STRIDE,
            },
        }

    return None


def _build_mapped_skeleton(
    hier_nodes: list[dict[str, Any]],
    hash_to_idx: dict[int, int],
    bone_hashes: list[int],
    block_path: Path,
) -> dict[str, Any] | None:
    """Build a skeleton doc using the verified track→HIER-node hash mapping.

    The output skeleton has one bone per animation track (in track order),
    plus any ancestor HIER nodes needed to preserve the parent chain.
    Non-animated ancestors are appended after the track bones.
    """
    n_tracks = len(bone_hashes)
    mapped_hier_indices: list[int] = []
    unresolved = 0
    for h in bone_hashes:
        idx = hash_to_idx.get(h, -1)
        mapped_hier_indices.append(idx)
        if idx < 0:
            unresolved += 1

    if unresolved > n_tracks * 0.2:
        return None

    needed: set[int] = set()
    for idx in mapped_hier_indices:
        if idx < 0:
            continue
        cur = idx
        while cur >= 0 and cur not in needed:
            needed.add(cur)
            cur = hier_nodes[cur]["parent"]

    # Track bones come first (in track order), then ancestor-only nodes
    track_set = set(mapped_hier_indices)
    ancestor_only = sorted(needed - track_set)
    emit_order = list(mapped_hier_indices) + ancestor_only

    hier_idx_to_bone_idx: dict[int, int] = {}
    for bone_i, hier_i in enumerate(emit_order):
        if hier_i >= 0:
            hier_idx_to_bone_idx[hier_i] = bone_i

    parents: list[int] = []
    bone_names: list[str] = []
    reference_pose: list[list[float]] = []

    for bone_i, hier_i in enumerate(emit_order):
        if hier_i < 0:
            parents.append(-1)
            bone_names.append(f"unmapped_track_{bone_i}")
            reference_pose.append([0, 0, 0, 0, 0, 0, 1, 1, 1, 1])
            continue

        nd = hier_nodes[hier_i]
        p_hier = nd["parent"]
        p_bone = hier_idx_to_bone_idx.get(p_hier, -1) if p_hier >= 0 else -1
        parents.append(p_bone)
        bone_names.append(nd["name"])

        trs = nd["trs"]
        row = [
            trs["t"][0], trs["t"][1], trs["t"][2],
            trs["q"][0], trs["q"][1], trs["q"][2], trs["q"][3],
            trs["s"][0], trs["s"][1], trs["s"][2],
        ]
        reference_pose.append([round(v, 6) for v in row])

    return {
        "bone_count": len(emit_order),
        "bone_names": bone_names,
        "parent_indices": parents,
        "reference_pose": reference_pose,
        "source": "ucfx_hier",
        "track_count": n_tracks,
        "ancestor_count": len(ancestor_only),
        "meta": {
            "block": block_path.name,
            "hier_node_count": len(hier_nodes),
            "track_to_hier_idx": mapped_hier_indices,
            "unresolved_hashes": unresolved,
        },
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Probe HIER chunk layout across test set")
    ap.add_argument("--pipeline-root", type=Path, required=True)
    ap.add_argument("--out", type=Path, default=None)
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    root = args.pipeline_root.resolve()
    out = (args.out or (_TOOLS / "_skeleton_probe.json")).resolve()

    print("Probing HIER chunks ...", file=sys.stderr)
    doc = run_probe(root, verbose=args.verbose)

    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(doc, indent=2), encoding="utf-8")
    print(f"Wrote {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
