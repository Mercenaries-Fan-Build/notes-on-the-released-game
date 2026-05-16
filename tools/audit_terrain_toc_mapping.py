#!/usr/bin/env python3
"""Fresh audit of low_res_terrain TOC -> LowResTerrainObject COMP mapping.

Verifies (or refutes) the claim that record.mesh_hash == TOC[i].hash1 with
~399/400 coverage, and brute-forces alternate mappings if the claim is wrong.
"""
from __future__ import annotations

import json
import struct
import sys
import zlib
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))

LOW_RES_BLOB = REPO / "output/extracted/batch_vz/blocks/03121_blocks__VZ__low_res_terrain_P000_Q3.block.bin"
LAYERS_STATIC_BLOB = REPO / "output/extracted/batch_vz/blocks/00029_blocks__VZ__layers_static_P000_Q3.block.bin"
LAYERS_STATIC_JSON = REPO / "output/placements/layers_static.json"
OUT_AUDIT = REPO / "output/terrain_toc_mapping_audit.json"

LRTERRAIN_SUB_BLOCK = 13


def parse_toc(data: bytes) -> tuple[int, list[tuple[int, int, int, int]]]:
    """Parse leading 16-byte TOC. Returns (header_first_uint, entries).

    Entries are tuples of (u0, u1, u2, u3) - all 4 uint32s per 16-byte row.
    Entry 0 is the count header per known format; entries[1..count-1] are tiles.
    """
    n = struct.unpack_from("<I", data, 0)[0]
    entries: list[tuple[int, int, int, int]] = []
    for i in range(n):
        a, b, c, d = struct.unpack_from("<IIII", data, i * 16)
        entries.append((a, b, c, d))
    return n, entries


def parse_lrterrain_records(layers_static: bytes) -> list[tuple[int, int, int]]:
    """Extract LowResTerrainObject records from layers_static sub-block 13."""
    ucfx_positions: list[int] = []
    pos = 0
    while True:
        idx = layers_static.find(b"UCFX", pos)
        if idx < 0:
            break
        ucfx_positions.append(idx)
        pos = idx + 1

    ucfx_pos = ucfx_positions[LRTERRAIN_SUB_BLOCK]
    ucfx_size = struct.unpack_from("<I", layers_static, ucfx_pos + 4)[0]
    block_end = (
        ucfx_positions[LRTERRAIN_SUB_BLOCK + 1]
        if LRTERRAIN_SUB_BLOCK + 1 < len(ucfx_positions)
        else len(layers_static)
    )
    chdr_pos = layers_static.find(b"CHDR", ucfx_pos, ucfx_pos + ucfx_size + 200)
    chdr_entries = struct.unpack_from("<I", layers_static, chdr_pos + 12)[0]

    pos = chdr_pos + 20
    chunks: list[tuple[bytes, list[tuple[bytes, int, int]]]] = []
    for _ in range(chdr_entries):
        if pos + 20 > block_end:
            break
        tag = layers_static[pos : pos + 4]
        if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
            break
        num_children = struct.unpack_from("<I", layers_static, pos + 16)[0]
        children: list[tuple[bytes, int, int]] = []
        cpos = pos + 20
        for _ in range(num_children):
            if cpos + 20 > block_end:
                break
            ctag = layers_static[cpos : cpos + 4]
            coff = struct.unpack_from("<I", layers_static, cpos + 4)[0]
            csz = struct.unpack_from("<I", layers_static, cpos + 8)[0]
            children.append((ctag, coff, csz))
            cpos += 20
        chunks.append((tag, children))
        pos = cpos
    data_area_start = pos

    for tag, children in chunks:
        if tag != b"COMP":
            continue
        info_name: str | None = None
        data_child: tuple[int, int] | None = None
        for ctag, coff, csz in children:
            abs_off = data_area_start + coff
            if ctag == b"info" and abs_off + csz <= len(layers_static):
                raw = layers_static[abs_off : abs_off + csz]
                null_idx = raw.find(b"\x00")
                if null_idx > 0:
                    info_name = raw[:null_idx].decode("ascii", errors="replace")
            elif ctag == b"data":
                data_child = (abs_off, csz)
        if info_name == "LowResTerrainObject" and data_child is not None:
            off, size = data_child
            n_records = size // 12
            out: list[tuple[int, int, int]] = []
            for i in range(n_records):
                rec_off = off + i * 12
                ek, mh, so = struct.unpack_from("<III", layers_static, rec_off)
                out.append((ek, mh, so))
            return out
    return []


def byteswap32(x: int) -> int:
    return int.from_bytes(x.to_bytes(4, "little"), "big") & 0xFFFFFFFF


def bitreverse32(x: int) -> int:
    x = ((x & 0x55555555) << 1) | ((x >> 1) & 0x55555555)
    x = ((x & 0x33333333) << 2) | ((x >> 2) & 0x33333333)
    x = ((x & 0x0F0F0F0F) << 4) | ((x >> 4) & 0x0F0F0F0F)
    x = ((x & 0x00FF00FF) << 8) | ((x >> 8) & 0x00FF00FF)
    x = ((x & 0x0000FFFF) << 16) | ((x >> 16) & 0x0000FFFF)
    return x & 0xFFFFFFFF


def fnv1a32(s: bytes) -> int:
    h = 0x811C9DC5
    for b in s:
        h ^= b
        h = (h * 0x01000193) & 0xFFFFFFFF
    return h


def fnv1_32(s: bytes) -> int:
    h = 0x811C9DC5
    for b in s:
        h = (h * 0x01000193) & 0xFFFFFFFF
        h ^= b
    return h


def crc32(s: bytes) -> int:
    return zlib.crc32(s) & 0xFFFFFFFF


def main() -> None:
    print(f"Reading low_res_terrain: {LOW_RES_BLOB}")
    low_res = LOW_RES_BLOB.read_bytes()
    n, toc = parse_toc(low_res)
    print(f"  TOC count header: {n}  (total entries parsed: {len(toc)})")
    print(f"  First 6 entries:")
    for i in range(min(6, len(toc))):
        a, b, c, d = toc[i]
        print(f"    [{i:3d}] u0={a:#010x}({a}) u1={b:#010x} u2={c:#010x} u3={d:#010x}")
    print(f"  Last 4 entries:")
    for i in range(max(0, len(toc) - 4), len(toc)):
        a, b, c, d = toc[i]
        print(f"    [{i:3d}] u0={a:#010x}({a}) u1={b:#010x} u2={c:#010x} u3={d:#010x}")

    print(f"\nReading layers_static: {LAYERS_STATIC_BLOB}")
    layers_static = LAYERS_STATIC_BLOB.read_bytes()
    records = parse_lrterrain_records(layers_static)
    print(f"  LowResTerrainObject records: {len(records)}")
    print(f"  First 5 records:")
    for i in range(min(5, len(records))):
        ek, mh, so = records[i]
        print(f"    [{i:3d}] entity_key={ek:#010x} mesh_hash={mh:#010x} scene_obj={so:#010x}")

    # The sample data confirms entry 0 is a header (first uint == 401 == total entry count)
    header_count = toc[0][0]
    tile_entries = toc[1:]  # the 400 tile rows
    print(f"\nAssuming entry 0 is header (count={header_count}): {len(tile_entries)} tile entries")

    # ----- Hypothesis tests -----
    record_hashes = [mh for _ek, mh, _so in records]
    record_set = set(record_hashes)

    toc_u0 = [e[0] for e in tile_entries]
    toc_u1 = [e[1] for e in tile_entries]  # claimed hash1
    toc_u2 = [e[2] for e in tile_entries]
    toc_u3 = [e[3] for e in tile_entries]

    tests: list[tuple[str, int, int]] = []  # (name, hits, total)

    def hits_in_set(values: list[int], target: set[int]) -> int:
        return sum(1 for v in values if v in target)

    # H1: record.mesh_hash matches TOC u1 (previous claim)
    tests.append(("record.mesh_hash in TOC.u1 (prev claim)", hits_in_set(list(record_set), set(toc_u1)), len(record_set)))

    # H2: in TOC u0
    tests.append(("record.mesh_hash in TOC.u0", hits_in_set(list(record_set), set(toc_u0)), len(record_set)))

    # H3: in TOC u2
    tests.append(("record.mesh_hash in TOC.u2", hits_in_set(list(record_set), set(toc_u2)), len(record_set)))

    # H4: in TOC u3
    tests.append(("record.mesh_hash in TOC.u3", hits_in_set(list(record_set), set(toc_u3)), len(record_set)))

    # H5: byteswap of u1
    swapped_u1 = {byteswap32(v) for v in toc_u1}
    tests.append(("record.mesh_hash in byteswap(TOC.u1)", hits_in_set(list(record_set), swapped_u1), len(record_set)))

    # H6: bitreverse u1
    rev_u1 = {bitreverse32(v) for v in toc_u1}
    tests.append(("record.mesh_hash in bitreverse(TOC.u1)", hits_in_set(list(record_set), rev_u1), len(record_set)))

    # H7: TOC u1 XOR constant 0x1602815c
    xor_c = 0x1602815C
    tests.append((f"record.mesh_hash in (TOC.u1 XOR {xor_c:#010x})",
                  hits_in_set(list(record_set), {v ^ xor_c for v in toc_u1}), len(record_set)))

    # H8: record.scene_obj as key
    record_so = {so for _ek, _mh, so in records}
    tests.append(("record.scene_obj in TOC.u1", hits_in_set(list(record_so), set(toc_u1)), len(record_so)))
    tests.append(("record.scene_obj in TOC.u0", hits_in_set(list(record_so), set(toc_u0)), len(record_so)))

    # H9: record.entity_key as key
    record_ek = {ek for ek, _mh, _so in records}
    tests.append(("record.entity_key in TOC.u1", hits_in_set(list(record_ek), set(toc_u1)), len(record_ek)))

    # H10: same-index alignment (TOC tile entry i corresponds to record i)
    # Just check positional pairwise consistency rather than set intersection
    pairwise_u1 = sum(1 for i in range(min(len(records), len(tile_entries))) if records[i][1] == tile_entries[i][1])
    pairwise_u0 = sum(1 for i in range(min(len(records), len(tile_entries))) if records[i][1] == tile_entries[i][0])
    print(f"\nPairwise (positional) checks:")
    print(f"  record[i].mesh_hash == toc_tile[i].u1: {pairwise_u1}/{min(len(records), len(tile_entries))}")
    print(f"  record[i].mesh_hash == toc_tile[i].u0: {pairwise_u0}/{min(len(records), len(tile_entries))}")

    # H11: maybe the previous agent used full TOC including entry 0 (raw, no offset)
    tests.append(("record.mesh_hash in full TOC u1 (incl entry 0)", hits_in_set(list(record_set), set(e[1] for e in toc)), len(record_set)))

    # H12: hash of name strings
    name_hashes_fnv1a: set[int] = set()
    name_hashes_fnv1: set[int] = set()
    name_hashes_crc32: set[int] = set()
    for r in range(20):
        for c in range(20):
            name = f"lrterrain_r{r:02d}_c{c:02d}".encode("ascii")
            name_hashes_fnv1a.add(fnv1a32(name))
            name_hashes_fnv1.add(fnv1_32(name))
            name_hashes_crc32.add(crc32(name))
    tests.append(("FNV-1a of lrterrain names matches record.mesh_hash", len(name_hashes_fnv1a & record_set), 400))
    tests.append(("FNV-1   of lrterrain names matches record.mesh_hash", len(name_hashes_fnv1 & record_set), 400))
    tests.append(("CRC32   of lrterrain names matches record.mesh_hash", len(name_hashes_crc32 & record_set), 400))
    tests.append(("FNV-1a of lrterrain names matches TOC.u1", len(name_hashes_fnv1a & set(toc_u1)), 400))
    tests.append(("FNV-1   of lrterrain names matches TOC.u1", len(name_hashes_fnv1 & set(toc_u1)), 400))
    tests.append(("CRC32   of lrterrain names matches TOC.u1", len(name_hashes_crc32 & set(toc_u1)), 400))

    print(f"\n=== Hypothesis hit counts ===")
    for name, hits, total in tests:
        print(f"  {hits:4d}/{total:<4d}  {name}")

    # Find winning hypothesis
    winning_name = max(tests, key=lambda t: t[1])[0]
    winning_hits = max(t[1] for t in tests)

    prev_claim_intersection = next(h for (n_, h, _t) in tests if n_.startswith("record.mesh_hash in TOC.u1"))
    prev_claim_verified = prev_claim_intersection >= 395  # ~399/400 claim threshold

    print(f"\nPrevious agent claim verified: {prev_claim_verified}")
    print(f"Intersection record.mesh_hash ↔ TOC.u1 (tile entries 1..400): {prev_claim_intersection}")
    print(f"Winning hypothesis: {winning_name!r} (hits={winning_hits})")

    # ---- Anchor checks: 5 known grid cells ----
    # Read placement coords from layers_static.json
    with LAYERS_STATIC_JSON.open() as f:
        ls = json.load(f)
    placements_iter = ls if isinstance(ls, list) else ls.get("placements", ls.get("records", []))
    name_to_pos: dict[str, tuple[float, float, float]] = {}
    for rec in placements_iter:
        nm = rec.get("entity_name")
        if isinstance(nm, str) and nm.startswith("lrterrain_r"):
            pos = rec.get("position")
            if isinstance(pos, dict):
                name_to_pos[nm] = (pos["x"], pos["y"], pos["z"])
            elif isinstance(pos, list) and len(pos) >= 3:
                name_to_pos[nm] = (pos[0], pos[1], pos[2])
            elif "position_x" in rec:
                name_to_pos[nm] = (rec["position_x"], rec["position_y"], rec["position_z"])

    targets = [(0, 0), (0, 19), (19, 0), (19, 19), (10, 10)]
    anchor_checks = []
    for r, c in targets:
        rec_idx = r * 20 + c
        if rec_idx >= len(records):
            anchor_checks.append({"rc": [r, c], "error": "out_of_range"})
            continue
        ek, mh, so = records[rec_idx]
        # Search TOC u1 for this mesh_hash
        toc_idx = next((i for i, v in enumerate(toc_u1) if v == mh), None)
        nm = f"lrterrain_r{r:02d}_c{c:02d}"
        pos = name_to_pos.get(nm)
        anchor_checks.append({
            "record_index": rec_idx,
            "record_mesh_hash": f"{mh:#010x}",
            "toc_entry_index_in_tile_entries": toc_idx,  # in [0..399]
            "toc_entry_index_overall": (toc_idx + 1) if toc_idx is not None else None,
            "expected_rc": [r, c],
            "expected_name": nm,
            "world_xyz_from_placement": list(pos) if pos else None,
            "matches_toc_u1": toc_idx is not None,
        })

    print(f"\nAnchor checks (5 cells):")
    for ck in anchor_checks:
        print(f"  rc={ck.get('expected_rc')} mesh={ck.get('record_mesh_hash')} -> toc_idx={ck.get('toc_entry_index_in_tile_entries')} pos={ck.get('world_xyz_from_placement')}")

    # tile_index_to_toc_entry: map each record to a TOC entry (using full TOC u1).
    # Index space: overall TOC index in [0..400]. Entry 0 acts as both header AND
    # a backup tile slot whose hash is referenced by the one record not present
    # in entries 1..400.
    u1_full_to_idx: dict[int, int] = {}
    for i, e in enumerate(toc):
        u1_full_to_idx.setdefault(e[1], i)
    tile_index_to_toc_entry = [u1_full_to_idx.get(records[i][1], -1) for i in range(len(records))]
    matched_full = sum(1 for v in tile_index_to_toc_entry if v >= 0)
    matched_tile_range = sum(1 for v in tile_index_to_toc_entry if v >= 1)
    print(f"\nRecords mapping to any TOC entry (incl entry 0): {matched_full}/{len(records)}")
    print(f"Records mapping to a TILE entry (1..400):         {matched_tile_range}/{len(records)}")

    # Identify the odd record that maps to entry 0 (or to nothing)
    odd_records = [
        {"record_index": i, "rc": [i // 20, i % 20], "mesh_hash": f"{records[i][1]:#010x}",
         "toc_entry_index_full": tile_index_to_toc_entry[i]}
        for i in range(len(records))
        if tile_index_to_toc_entry[i] == 0 or tile_index_to_toc_entry[i] < 0
    ]
    print(f"Anomalous records (mesh_hash matches entry 0 or no entry):")
    for o in odd_records:
        print(f"  record[{o['record_index']:3d}] rc={o['rc']} mesh={o['mesh_hash']} -> toc_idx={o['toc_entry_index_full']}")

    # Which tile entries (1..400) are NOT referenced by any record's mesh_hash?
    referenced_tile_entries = {v for v in tile_index_to_toc_entry if v >= 1}
    unused_tile_entries = [i for i in range(1, len(toc)) if i not in referenced_tile_entries]
    print(f"Unused TOC tile entries (1..400) not referenced by any record: {unused_tile_entries}")
    for u in unused_tile_entries[:5]:
        e = toc[u]
        print(f"  [{u}] u0={e[0]} u1={e[1]:#010x}")

    out = {
        "previous_agent_claim_verified": prev_claim_verified,
        "intersection_count_record_mesh_hash_to_toc_hash1": prev_claim_intersection,
        "winning_mapping_hypothesis": winning_name,
        "winning_mapping_hit_count": winning_hits,
        "anomalous_records": odd_records,
        "unused_tile_entries_1_to_400": unused_tile_entries,
        "all_hypotheses_tested": [
            {"name": n_, "hits": h, "total": t_} for (n_, h, t_) in tests
        ],
        "pairwise_record_mesh_hash_eq_toc_u1_same_index": pairwise_u1,
        "tile_index_to_toc_entry": tile_index_to_toc_entry,
        "tile_index_to_grid_rc_anchor_check": anchor_checks,
        "toc_header": {
            "count_field": header_count,
            "entry0": {
                "u0": toc[0][0], "u1": toc[0][1], "u2": toc[0][2], "u3": toc[0][3],
            },
        },
        "sample_records": [
            {"index": i, "entity_key": f"{records[i][0]:#010x}",
             "mesh_hash": f"{records[i][1]:#010x}", "scene_obj": f"{records[i][2]:#010x}"}
            for i in range(min(5, len(records)))
        ],
        "sample_toc_entries": [
            {"index": i, "u0": toc[i][0], "u1": f"{toc[i][1]:#010x}",
             "u2": f"{toc[i][2]:#010x}", "u3": f"{toc[i][3]:#010x}"}
            for i in list(range(min(6, len(toc)))) + list(range(max(0, len(toc) - 4), len(toc)))
        ],
    }
    OUT_AUDIT.write_text(json.dumps(out, indent=2))
    print(f"\nWrote {OUT_AUDIT}")


if __name__ == "__main__":
    main()
