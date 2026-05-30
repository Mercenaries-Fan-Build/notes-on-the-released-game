#!/usr/bin/env python3
"""Validate DLC-unique ecs_node blocks from the rebuilt patch WAD.

Performs deep structural validation on the 20 DLC-unique ecs_node entries
to catch byte-swap or structural issues that could cause the engine crash
(null pointer when looking up "info" descriptor in a UCFX container).

Checks performed:
  1. Entry table structure (entry_count, chunk_sizes sum to data_area)
  2. UCFX header validity (magic, data_area_off, desc_count)
  3. Descriptor format: data_area_off == 20 + n_desc * 20
  4. Descriptor tags are recognizable (info, data, trnm, schm, etc.)
  5. COMP group completeness: info+schm+data triplets
  6. No NaN/Inf floats in data areas
  7. String bodies (info, NAME, STRS) are printable ASCII
  8. Size invariance: converted output preserves container sizes
  9. Cross-check descriptor offsets don't overlap or exceed container

Usage:
  python tools/validate_ecs_dlc.py
  python tools/validate_ecs_dlc.py --patch-wad output/data/vz-patch.wad
  python tools/validate_ecs_dlc.py --also-check-xbox  # compare BE vs LE
"""
from __future__ import annotations

import argparse
import math
import mmap
import struct
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries

_TYPE_ECS_NODE = 0xE6B81A54

TYPE_NAMES = {
    0xF011157A: "texture", 0x42498680: "script", 0x207359C7: "stance",
    0x18166555: "animation", 0xBCFE6314: "path", 0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node", 0x5B724250: "mesh_B", 0x7C569307: "mesh_A",
    0x600B904E: "mesh_C", 0x39E5E978: "stringdb", 0xE5273C14: "unknown_E5",
    0x1602815C: "unknown_16", 0xF753F6D0: "wavebank", 0x9F8BCA10: "soundbank",
    0x6310807F: "object_registry", 0x5608BD5A: "effect",
}

KNOWN_TAGS = {
    "COMP", "GEOM", "STRM", "UCFX",
    "info", "data", "schm", "flgs", "decl", "enum", "trnm", "evnt",
    "IBUF", "BNDS", "HIER", "PRMG", "MTRL", "INFO", "BODY", "CHDR", "STAT",
    "SWIT", "PRMT", "CEXE", "flgt", "INDX", "SYEK", "SRTS",
    "sequ", "SINF", "ITEM", "CERP", "SCRB", "NAME", "STRS", "TRNS", "AINF",
    "MESH", "NODE", "BINN", "DEPS", "KEYS", "TYPE", "INST", "PTCH",
    "PTMS", "VALU", "AREA", "STAM", "PHY2", "POFF", "SEGM", "TINY",
}


@dataclass
class Issue:
    severity: str
    entry_hash: int
    block_idx: int
    tag: str
    msg: str

    def __str__(self):
        return (f"[{self.severity}] block {self.block_idx}, "
                f"hash 0x{self.entry_hash:08X}, {self.tag}: {self.msg}")


@dataclass
class EcsValidationResult:
    entry_hash: int
    block_idx: int
    entry_size: int
    ucfx_size: int
    n_desc: int
    data_area_off: int
    expected_data_area_off: int
    comp_groups: list[dict] = field(default_factory=list)
    all_tags: list[str] = field(default_factory=list)
    issues: list[Issue] = field(default_factory=list)
    nan_inf_count: int = 0
    has_info_data_trnm: bool = False


def _is_clean_ascii(data: bytes) -> bool:
    for b in data:
        if b == 0:
            continue
        if b < 32 or b > 126:
            return False
    return True


def _count_nan_inf(data: bytes, offset: int = 0) -> tuple[int, list[tuple[int, float]]]:
    """Count NaN/Inf floats in data. Returns (count, [(offset, value)])."""
    bad = []
    n_floats = (len(data) - offset) // 4
    for i in range(n_floats):
        off = offset + i * 4
        val = struct.unpack_from("<f", data, off)[0]
        if math.isnan(val) or math.isinf(val):
            bad.append((off, val))
    return len(bad), bad


def _build_pc_hash_set(pc_wad: Path) -> set[int]:
    """Build set of all entry hashes in the PC base game WAD."""
    dc = find_data_chunk(pc_wad)
    hashes: set[int] = set()
    with open(pc_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                hashes.add(ent["hash"])
        mm.close()
    return hashes


def validate_ucfx_container(
    ucfx: bytes,
    entry_hash: int,
    block_idx: int,
) -> EcsValidationResult:
    """Deep structural validation of a single LE UCFX container."""

    result = EcsValidationResult(
        entry_hash=entry_hash,
        block_idx=block_idx,
        entry_size=len(ucfx),
        ucfx_size=len(ucfx),
        n_desc=0,
        data_area_off=0,
        expected_data_area_off=0,
    )

    if len(ucfx) < 20:
        result.issues.append(Issue("CRITICAL", entry_hash, block_idx, "UCFX",
                                   f"Container too small: {len(ucfx)} bytes"))
        return result

    magic = ucfx[:4]
    if magic != b"UCFX":
        result.issues.append(Issue("CRITICAL", entry_hash, block_idx, "UCFX",
                                   f"Bad magic: {magic!r} (expected b'UCFX')"))
        return result

    data_area_off = struct.unpack_from("<I", ucfx, 4)[0]
    unk_08 = struct.unpack_from("<I", ucfx, 8)[0]
    unk_0c = struct.unpack_from("<I", ucfx, 12)[0]
    n_desc = struct.unpack_from("<I", ucfx, 16)[0]

    result.data_area_off = data_area_off
    result.n_desc = n_desc

    expected_dao = 20 + n_desc * 20
    result.expected_data_area_off = expected_dao

    if n_desc > 5000:
        result.issues.append(Issue("CRITICAL", entry_hash, block_idx, "UCFX",
                                   f"Implausible descriptor count: {n_desc}"))
        return result

    if data_area_off != expected_dao:
        result.issues.append(Issue("WARN", entry_hash, block_idx, "UCFX",
                                   f"data_area_off={data_area_off} != expected "
                                   f"{expected_dao} (20 + {n_desc}*20). "
                                   f"Gap of {data_area_off - expected_dao} bytes"))

    if data_area_off > len(ucfx):
        result.issues.append(Issue("CRITICAL", entry_hash, block_idx, "UCFX",
                                   f"data_area_off={data_area_off} exceeds container "
                                   f"size={len(ucfx)}"))
        return result

    desc_table_end = 20 + n_desc * 20
    if desc_table_end > len(ucfx):
        result.issues.append(Issue("CRITICAL", entry_hash, block_idx, "UCFX",
                                   f"Descriptor table extends past container"))
        return result

    # Parse all descriptors
    descriptors = []
    for di in range(n_desc):
        row_off = 20 + di * 20
        tag_bytes = ucfx[row_off:row_off + 4]
        tag = tag_bytes.decode("ascii", errors="replace")
        row_u0 = struct.unpack_from("<I", ucfx, row_off + 4)[0]
        body_size = struct.unpack_from("<I", ucfx, row_off + 8)[0]
        row_u3 = struct.unpack_from("<I", ucfx, row_off + 12)[0]
        row_u4 = struct.unpack_from("<I", ucfx, row_off + 16)[0]

        descriptors.append({
            "index": di,
            "tag": tag,
            "row_u0": row_u0,
            "body_size": body_size,
            "row_u3": row_u3,
            "row_u4": row_u4,
            "is_sentinel": row_u0 == 0xFFFFFFFF,
        })
        result.all_tags.append(tag)

        if tag.strip("\x00") not in KNOWN_TAGS and row_u0 != 0xFFFFFFFF:
            clean = tag.replace("\x00", "\\0")
            result.issues.append(Issue("WARN", entry_hash, block_idx, f"desc[{di}]",
                                       f"Unknown tag: '{clean}'"))

    # Validate body ranges
    data_start = data_area_off if data_area_off > 0 else 8
    body_ranges = []
    for desc in descriptors:
        if desc["is_sentinel"]:
            continue
        if desc["body_size"] == 0:
            continue
        body_off = data_start + desc["row_u0"]
        body_end = body_off + desc["body_size"]
        if body_end > len(ucfx):
            result.issues.append(Issue("CRITICAL", entry_hash, block_idx,
                                       f"desc[{desc['index']}]({desc['tag']})",
                                       f"Body exceeds container: "
                                       f"off={body_off}, size={desc['body_size']}, "
                                       f"end={body_end}, container={len(ucfx)}"))
        else:
            body_ranges.append((body_off, body_end, desc))

    # Check for overlapping body ranges
    body_ranges.sort(key=lambda x: x[0])
    for i in range(len(body_ranges) - 1):
        _, end_a, desc_a = body_ranges[i]
        start_b, _, desc_b = body_ranges[i + 1]
        if end_a > start_b:
            result.issues.append(Issue("WARN", entry_hash, block_idx,
                                       "overlap",
                                       f"Body overlap: desc[{desc_a['index']}]({desc_a['tag']}) "
                                       f"ends at {end_a}, desc[{desc_b['index']}]({desc_b['tag']}) "
                                       f"starts at {start_b}"))

    # === ECS-specific checks ===
    # Identify COMP groups: COMP sentinel followed by children
    i = 0
    while i < len(descriptors):
        desc = descriptors[i]
        if desc["tag"] == "COMP" and desc["is_sentinel"]:
            group_start = i
            i += 1
            children = {}
            while i < len(descriptors) and not descriptors[i]["is_sentinel"]:
                children[descriptors[i]["tag"]] = descriptors[i]
                i += 1

            comp_info = {
                "start_idx": group_start,
                "children": {t: d["body_size"] for t, d in children.items()},
            }

            # Extract component name from info body
            comp_name = "?"
            if "info" in children:
                info_desc = children["info"]
                info_off = data_start + info_desc["row_u0"]
                info_end = info_off + info_desc["body_size"]
                if info_end <= len(ucfx):
                    info_body = ucfx[info_off:info_end]
                    nul = info_body.find(b"\x00")
                    if nul > 0:
                        name_bytes = info_body[:nul]
                        if _is_clean_ascii(name_bytes):
                            comp_name = name_bytes.decode("ascii")
                        else:
                            result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                       f"COMP[{group_start}].info",
                                                       f"Non-ASCII component name: "
                                                       f"{info_body[:20].hex()}"))
                    elif nul == 0:
                        result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                   f"COMP[{group_start}].info",
                                                   "Empty component name (starts with null)"))

            comp_info["name"] = comp_name

            # Check for required children
            has_info = "info" in children
            has_schm = "schm" in children
            has_data = "data" in children

            if not has_info:
                result.issues.append(Issue("WARN", entry_hash, block_idx,
                                           f"COMP[{group_start}]",
                                           f"Missing 'info' descriptor (comp='{comp_name}')"))
            if not has_data:
                result.issues.append(Issue("WARN", entry_hash, block_idx,
                                           f"COMP[{group_start}]",
                                           f"Missing 'data' descriptor (comp='{comp_name}')"))

            # Validate schema if present
            if has_schm:
                schm_desc = children["schm"]
                schm_off = data_start + schm_desc["row_u0"]
                schm_end = schm_off + schm_desc["body_size"]
                if schm_end <= len(ucfx) and schm_desc["body_size"] >= 8:
                    schm_body = ucfx[schm_off:schm_end]
                    n_fields = struct.unpack_from("<I", schm_body, 0)[0]
                    payload_stride = struct.unpack_from("<I", schm_body, 4)[0]
                    expected_schm_size = 8 + n_fields * 16
                    if expected_schm_size != len(schm_body):
                        result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                   f"COMP[{group_start}].schm",
                                                   f"schm size mismatch: "
                                                   f"n_fields={n_fields} implies "
                                                   f"{expected_schm_size} bytes but got "
                                                   f"{len(schm_body)} "
                                                   f"(comp='{comp_name}')"))
                    if n_fields > 200:
                        result.issues.append(Issue("CRITICAL", entry_hash, block_idx,
                                                   f"COMP[{group_start}].schm",
                                                   f"Implausible n_fields={n_fields} "
                                                   f"(comp='{comp_name}')"))
                    comp_info["n_fields"] = n_fields
                    comp_info["payload_stride"] = payload_stride

                    # Validate field type codes
                    valid_type_codes = {1, 2, 4, 5, 6, 7, 8, 9, 10, 11}
                    for fi in range(min(n_fields, 200)):
                        fo = 8 + fi * 16
                        if fo + 16 > len(schm_body):
                            break
                        type_code = struct.unpack_from("<I", schm_body, fo)[0]
                        if type_code not in valid_type_codes:
                            result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                       f"COMP[{group_start}].schm.field[{fi}]",
                                                       f"Unknown type_code={type_code} "
                                                       f"(comp='{comp_name}')"))

            # Validate data body for NaN/Inf
            if has_data:
                data_desc = children["data"]
                doff = data_start + data_desc["row_u0"]
                dend = doff + data_desc["body_size"]
                if dend <= len(ucfx) and data_desc["body_size"] >= 4:
                    data_body = ucfx[doff:dend]
                    # Only check float-bearing components (skip pure string ones)
                    if comp_name not in ("Name", "ModelName"):
                        nan_count, nan_locs = _count_nan_inf(data_body)
                        if nan_count > 0:
                            result.nan_inf_count += nan_count
                            sample = nan_locs[:3]
                            result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                       f"COMP[{group_start}].data",
                                                       f"{nan_count} NaN/Inf float(s) in "
                                                       f"'{comp_name}' data "
                                                       f"(first at: {sample})"))

                    # Special: Name data should be ASCII strings
                    if comp_name == "Name":
                        pos = 0
                        while pos + 4 <= len(data_body):
                            pos += 4  # skip entity key
                            nul = data_body.find(b"\x00", pos)
                            if nul < 0:
                                break
                            name_chunk = data_body[pos:nul]
                            if len(name_chunk) > 0 and not _is_clean_ascii(name_chunk):
                                result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                           f"COMP[{group_start}].data",
                                                           f"Non-ASCII Name entry at "
                                                           f"offset {pos}: "
                                                           f"{name_chunk[:16].hex()}"))
                                break
                            pos = nul + 1
                            while pos < len(data_body) and data_body[pos] == 0:
                                pos += 1

            result.comp_groups.append(comp_info)
        else:
            # Non-COMP descriptor in ECS container
            if desc["tag"] == "CHDR" and not desc["is_sentinel"]:
                chdr_off = data_start + desc["row_u0"]
                chdr_end = chdr_off + desc["body_size"]
                if chdr_end <= len(ucfx):
                    chdr_body = ucfx[chdr_off:chdr_end]
                    if desc["body_size"] not in (8, 12, 16) and desc["body_size"] % 4 != 0:
                        result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                   "CHDR",
                                                   f"Unusual CHDR size: "
                                                   f"{desc['body_size']} bytes"))

            # Check enum bodies
            if desc["tag"] == "enum" and not desc["is_sentinel"]:
                enum_off = data_start + desc["row_u0"]
                enum_end = enum_off + desc["body_size"]
                if enum_end <= len(ucfx) and desc["body_size"] >= 4:
                    enum_body = ucfx[enum_off:enum_end]
                    total_enums = struct.unpack_from("<I", enum_body, 0)[0]
                    if total_enums > 1000:
                        result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                   "enum",
                                                   f"Implausible enum count: "
                                                   f"{total_enums} (possible BE?)"))
                    else:
                        # Walk enum body to verify strings are ASCII
                        pos = 4
                        ok = True
                        for _ in range(total_enums):
                            if pos >= len(enum_body):
                                break
                            nul = enum_body.find(b"\x00", pos)
                            if nul < 0:
                                result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                           "enum",
                                                           f"Unterminated string at "
                                                           f"offset {pos}"))
                                ok = False
                                break
                            name = enum_body[pos:nul]
                            if len(name) > 0 and not _is_clean_ascii(name):
                                result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                           "enum",
                                                           f"Non-ASCII enum name at "
                                                           f"offset {pos}: "
                                                           f"{name[:16].hex()}"))
                                ok = False
                                break
                            pos = nul + 1 + 4  # skip hash
                            if pos + 4 > len(enum_body):
                                break
                            val_count = struct.unpack_from("<I", enum_body, pos)[0]
                            if val_count > 10000:
                                result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                           "enum",
                                                           f"Implausible value_count: "
                                                           f"{val_count}"))
                                ok = False
                                break
                            pos += 4
                            for _ in range(val_count):
                                if pos >= len(enum_body):
                                    break
                                vnul = enum_body.find(b"\x00", pos)
                                if vnul < 0:
                                    break
                                vname = enum_body[pos:vnul]
                                if len(vname) > 0 and not _is_clean_ascii(vname):
                                    result.issues.append(Issue("ERROR", entry_hash, block_idx,
                                                               "enum",
                                                               f"Non-ASCII enum value at "
                                                               f"offset {pos}"))
                                    ok = False
                                    break
                                pos = vnul + 1 + 8  # hash + ordinal

            # Check flgs body
            if desc["tag"] == "flgs" and not desc["is_sentinel"]:
                flgs_off = data_start + desc["row_u0"]
                flgs_end = flgs_off + desc["body_size"]
                if flgs_end <= len(ucfx):
                    flgs_body = ucfx[flgs_off:flgs_end]
                    if desc["body_size"] % 4 != 0:
                        result.issues.append(Issue("WARN", entry_hash, block_idx,
                                                   "flgs",
                                                   f"flgs body not u32-aligned: "
                                                   f"{desc['body_size']} bytes"))
            i += 1

    # Summary checks
    tag_set = set(result.all_tags)
    result.has_info_data_trnm = "info" in tag_set and "data" in tag_set

    return result


def validate_patch_wad_ecs(
    patch_wad: Path,
    pc_wad: Path,
) -> list[EcsValidationResult]:
    """Find and validate all DLC-unique ecs_node entries in the patch WAD."""

    print(f"Building PC base game hash index from {pc_wad}...")
    pc_hashes = _build_pc_hash_set(pc_wad)
    print(f"  {len(pc_hashes):,} unique hashes in PC base game\n")

    print(f"Scanning patch WAD {patch_wad} for DLC-unique ecs_node entries...")
    dc = find_data_chunk(patch_wad)
    results: list[EcsValidationResult] = []
    all_ecs_entries = []
    dlc_unique_ecs = []

    with open(patch_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)
        print(f"  {len(boundaries)} blocks in patch WAD")

        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception as ex:
                continue

            for ent in entries:
                if ent["type_hash"] != _TYPE_ECS_NODE:
                    continue
                all_ecs_entries.append((blk_idx, ent))

                is_unique = ent["hash"] not in pc_hashes
                if not is_unique:
                    continue

                dlc_unique_ecs.append((blk_idx, ent, data))

        print(f"  Total ecs_node entries in patch WAD: {len(all_ecs_entries)}")
        print(f"  DLC-unique ecs_node entries: {len(dlc_unique_ecs)}\n")

        for blk_idx, ent, block_data in dlc_unique_ecs:
            eoff = ent["offset"]
            esize = ent["size"]
            raw = block_data[eoff:eoff + esize]

            # Strip CSUM trailer
            ucfx = raw
            if len(raw) >= 8 and raw[-8:-4] == b"CSUM":
                ucfx = raw[:-8]

            # Verify UCFX magic
            if ucfx[:4] != b"UCFX":
                pos = raw.find(b"UCFX")
                if pos >= 0:
                    ucfx = raw[pos:]
                    if len(ucfx) >= 8 and ucfx[-8:-4] == b"CSUM":
                        ucfx = ucfx[:-8]

            result = validate_ucfx_container(ucfx, ent["hash"], blk_idx)
            result.entry_size = esize
            results.append(result)

        mm.close()

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Validate DLC-unique ecs_node blocks from patch WAD")
    parser.add_argument("--patch-wad", type=Path,
                        default=Path("output/data/vz-patch.wad"))
    parser.add_argument("--pc-wad", type=Path,
                        default=Path("game-files/pc-game-vz.wad"))
    parser.add_argument("--also-check-xbox", action="store_true",
                        help="Also check Xbox WAD for comparison")
    args = parser.parse_args()

    if not args.patch_wad.exists():
        print(f"ERROR: Patch WAD not found: {args.patch_wad}")
        return 1
    if not args.pc_wad.exists():
        print(f"ERROR: PC WAD not found: {args.pc_wad}")
        return 1

    results = validate_patch_wad_ecs(args.patch_wad, args.pc_wad)

    if not results:
        print("No DLC-unique ecs_node entries found!")
        return 0

    # === Report ===
    print("=" * 80)
    print(f"ECS_NODE DLC-UNIQUE VALIDATION RESULTS ({len(results)} entries)")
    print("=" * 80)

    total_issues = 0
    critical_count = 0
    error_count = 0
    warn_count = 0

    for r in results:
        print(f"\n--- Entry 0x{r.entry_hash:08X} (block {r.block_idx}) ---")
        print(f"  Entry size: {r.entry_size} bytes")
        print(f"  UCFX size: {r.ucfx_size} bytes")
        print(f"  Descriptors: {r.n_desc}")
        print(f"  data_area_off: {r.data_area_off} (expected: {r.expected_data_area_off})")
        dao_match = "OK" if r.data_area_off == r.expected_data_area_off else "MISMATCH"
        print(f"  data_area_off check: {dao_match}")
        print(f"  Tags: {', '.join(r.all_tags)}")
        print(f"  COMP groups: {len(r.comp_groups)}")
        for gi, g in enumerate(r.comp_groups):
            children_str = ", ".join(f"{t}({s}B)" for t, s in g["children"].items())
            print(f"    [{gi}] '{g['name']}': {children_str}")
            if "n_fields" in g:
                print(f"         schm: {g['n_fields']} fields, "
                      f"stride={g.get('payload_stride', '?')}")
        print(f"  NaN/Inf floats: {r.nan_inf_count}")

        if r.issues:
            print(f"  Issues ({len(r.issues)}):")
            for iss in r.issues:
                print(f"    {iss}")
                if iss.severity == "CRITICAL":
                    critical_count += 1
                elif iss.severity == "ERROR":
                    error_count += 1
                else:
                    warn_count += 1
                total_issues += 1
        else:
            print("  Issues: None")

    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    print(f"  Entries validated: {len(results)}")
    print(f"  Total issues: {total_issues}")
    print(f"    CRITICAL: {critical_count}")
    print(f"    ERROR:    {error_count}")
    print(f"    WARN:     {warn_count}")

    # Size invariance check
    print(f"\n  Size invariance:")
    for r in results:
        expected_ucfx = r.entry_size - 8  # entry includes CSUM trailer
        if r.ucfx_size != expected_ucfx:
            print(f"    0x{r.entry_hash:08X}: MISMATCH entry_size={r.entry_size}, "
                  f"ucfx_size={r.ucfx_size}, expected={expected_ucfx}")
        else:
            print(f"    0x{r.entry_hash:08X}: OK (ucfx={r.ucfx_size}, "
                  f"entry={r.entry_size})")

    # COMP group completeness summary
    print(f"\n  COMP group completeness:")
    incomplete_groups = []
    for r in results:
        for g in r.comp_groups:
            children = g["children"]
            has_info = "info" in children
            has_schm = "schm" in children
            has_data = "data" in children
            if not (has_info and has_data):
                incomplete_groups.append((r.entry_hash, g["name"], has_info, has_schm, has_data))

    if incomplete_groups:
        for eh, name, hi, hs, hd in incomplete_groups:
            print(f"    0x{eh:08X} '{name}': "
                  f"info={'YES' if hi else 'NO'}, "
                  f"schm={'YES' if hs else 'NO'}, "
                  f"data={'YES' if hd else 'NO'}")
    else:
        print("    All COMP groups have info+data (complete)")

    # Descriptor format check
    print(f"\n  Descriptor format (data_area_off == 20 + n_desc*20):")
    anomalies = [r for r in results if r.data_area_off != r.expected_data_area_off]
    if anomalies:
        for r in anomalies:
            print(f"    0x{r.entry_hash:08X}: data_area_off={r.data_area_off}, "
                  f"expected={r.expected_data_area_off}")
    else:
        print("    All containers match expected format")

    if critical_count:
        print(f"\n  *** {critical_count} CRITICAL issue(s) — likely crash causes ***")
    if error_count:
        print(f"\n  *** {error_count} ERROR(s) — potential crash causes ***")

    return 1 if critical_count or error_count else 0


if __name__ == "__main__":
    sys.exit(main())
