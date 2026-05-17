#!/usr/bin/env python3
"""
Mercenaries 2: World Placement Data Extractor

Extracts entity placement records (position, rotation, asset reference) from
three types of binary block files extracted from vz.wad:

  1. layers_static  - The always-loaded base world layer (~7.6 MB, 173 UCFX sub-blocks)
  2. vz_state       - Conditional state overlays (746 files, mission/faction variants)
  3. c3XXXX cells   - Geometry/terrain ONLY (no placement data)

Output: JSON array of placement entries with position, rotation, and entity metadata.

Usage:
    python3 placement_extractor.py <block_file.bin> [--output placements.json]
    python3 placement_extractor.py --batch <blocks_dir/> [--output all_placements.json]

Verified from binary inspection — see docs/placement_data_format.md
"""

import argparse
import json
import math
import os
import struct
import sys
from typing import Optional


FORMAT_HASH_VZ_STATE = 0xE6B81A54
FORMAT_HASH_C3_MESH = 0x5B724250
FORMAT_HASH_C3_BODY = 0xF011157A

VZ_STATE_RECORD_STRIDE = 42
LAYERS_STATIC_RECORD_STRIDE = 42

COORD_MIN = -6000.0
COORD_MAX = 6000.0
ELEV_MIN = -500.0
ELEV_MAX = 1000.0


def detect_block_type(data: bytes) -> str:
    """Detect the block type from binary header patterns."""
    if len(data) < 20:
        return "unknown"

    first_uint = struct.unpack_from("<I", data, 0)[0]

    if first_uint >= 2:
        # Potential layers_static or multi-block TOC
        # Check if entries follow the 16-byte pattern: size, hash, format_hash, zero
        # with constant format_hash = 0xe6b81a54
        if len(data) >= first_uint * 16 + 32:
            all_match = True
            for i in range(1, min(first_uint, 10)):
                fmt = struct.unpack_from("<I", data, i * 16 + 8)[0]
                zero = struct.unpack_from("<I", data, i * 16 + 12)[0]
                if fmt != FORMAT_HASH_VZ_STATE or zero != 0:
                    all_match = False
                    break
            if all_match and first_uint > 5:
                return "layers_static"

    if first_uint == 1:
        format_hash = struct.unpack_from("<I", data, 8)[0]
        if format_hash == FORMAT_HASH_VZ_STATE:
            return "vz_state"
        if format_hash == FORMAT_HASH_C3_MESH:
            return "c3_mesh"
        if format_hash == FORMAT_HASH_C3_BODY:
            return "c3_body"

    format_hash = struct.unpack_from("<I", data, 8)[0]
    if format_hash == FORMAT_HASH_C3_BODY:
        return "c3_body"

    if first_uint >= 1 and first_uint <= 20:
        # Multi-sub-block files (c3 mesh with 4+ UCFX, etc.)
        format_hash = struct.unpack_from("<I", data, 8)[0]
        if format_hash == FORMAT_HASH_C3_MESH:
            return "c3_mesh"
        if format_hash == FORMAT_HASH_C3_BODY:
            return "c3_body"

    ucfx_pos = data.find(b"UCFX")
    if ucfx_pos >= 0:
        if data.find(b"COMP") > 0:
            return "vz_state"
        if data.find(b"HIER") > 0 or data.find(b"MTRL") > 0:
            return "c3_mesh"
        return "unknown_ucfx"

    return "unknown"


def is_valid_world_coord(x: float, y: float, z: float) -> bool:
    return (COORD_MIN < x < COORD_MAX and
            ELEV_MIN < y < ELEV_MAX and
            COORD_MIN < z < COORD_MAX)


def parse_vz_state_chunk_table(data: bytes):
    """Parse the UCFX/CHDR chunk table from a vz_state block.

    Returns (chunks, entity_names, flgs_offset, flgs_size).
    Offsets in vz_state child descriptors are ABSOLUTE file offsets.
    """
    chdr_pos = data.find(b"CHDR")
    if chdr_pos < 0:
        return [], {}, None, None

    chdr_entries = struct.unpack_from("<I", data, chdr_pos + 12)[0]

    pos = chdr_pos + 20
    chunks = []
    entity_names = {}
    flgs_offset = None
    flgs_size = None

    for _ in range(chdr_entries):
        if pos + 20 > len(data):
            break
        tag = data[pos:pos + 4]
        if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
            break

        field1 = struct.unpack_from("<I", data, pos + 4)[0]
        field2 = struct.unpack_from("<I", data, pos + 8)[0]
        comp_idx = struct.unpack_from("<I", data, pos + 12)[0]
        num_children = struct.unpack_from("<I", data, pos + 16)[0]

        if tag == b"flgs":
            flgs_offset = field1
            flgs_size = field2
            pos += 20
            continue
        elif tag in (b"flgt", b"enum"):
            pos += 20
            continue

        children = []
        child_pos = pos + 20
        for _ in range(num_children):
            if child_pos + 20 > len(data):
                break
            ctag = data[child_pos:child_pos + 4].decode("ascii", errors="replace")
            coff = struct.unpack_from("<I", data, child_pos + 4)[0]
            csz = struct.unpack_from("<I", data, child_pos + 8)[0]
            children.append({"tag": ctag, "offset": coff, "size": csz})
            child_pos += 20

        info_name = None
        for child in children:
            if child["tag"] == "info":
                off, sz = child["offset"], child["size"]
                if off + sz <= len(data):
                    raw = data[off:off + sz]
                    null_idx = raw.find(b"\x00")
                    if null_idx > 0:
                        info_name = raw[:null_idx].decode("ascii", errors="replace")

            if child["tag"] == "data":
                off, sz = child["offset"], child["size"]
                if off + sz <= len(data):
                    _extract_entity_names(data[off:off + sz], entity_names)

        chunks.append({"idx": comp_idx, "name": info_name, "children": children})
        pos = child_pos

    return chunks, entity_names, flgs_offset, flgs_size


def _extract_entity_names(blob: bytes, entity_names: dict):
    """Extract 'EntityName 0xHEXID' references from a data section."""
    str_start = None
    for bi in range(len(blob)):
        b = blob[bi]
        if 32 <= b < 127:
            if str_start is None:
                str_start = bi
        else:
            if str_start is not None and bi - str_start >= 6:
                s = blob[str_start:bi].decode("ascii", errors="replace")
                if " 0x" in s:
                    parts = s.rsplit(" 0x", 1)
                    if len(parts) == 2:
                        try:
                            eid = int(parts[1], 16)
                            entity_names[eid] = parts[0].strip()
                        except ValueError:
                            pass
            str_start = None


def _extract_entity_names_ordered(blob: bytes) -> list[tuple[int, str]]:
    """Same as _extract_entity_names but preserve discovery order (for Transform zip)."""
    ordered: list[tuple[int, str]] = []
    seen: set[int] = set()
    str_start = None
    for bi in range(len(blob)):
        b = blob[bi]
        if 32 <= b < 127:
            if str_start is None:
                str_start = bi
        else:
            if str_start is not None and bi - str_start >= 6:
                s = blob[str_start:bi].decode("ascii", errors="replace")
                if " 0x" in s:
                    parts = s.rsplit(" 0x", 1)
                    if len(parts) == 2:
                        try:
                            eid = int(parts[1], 16)
                            name = parts[0].strip()
                            if eid not in seen:
                                seen.add(eid)
                                ordered.append((eid, name))
                        except ValueError:
                            pass
            str_start = None
    return ordered


def extract_vz_state_placements(data: bytes, source_file: str = "") -> list[dict]:
    """Extract placement records from a vz_state .bin block."""
    chunks, entity_names, flgs_offset, flgs_size = parse_vz_state_chunk_table(data)

    if flgs_offset is None or flgs_size is None or flgs_size < VZ_STATE_RECORD_STRIDE:
        return []

    if flgs_offset + flgs_size > len(data):
        return []

    flgs_data = data[flgs_offset:flgs_offset + flgs_size]

    one_pos = flgs_data.find(b"\x00\x00\x80\x3f")
    if one_pos >= 4:
        rec_start = one_pos - 4
    elif one_pos >= 0:
        rec_start = 0
    else:
        return []

    placements = []
    roff = rec_start
    while roff + VZ_STATE_RECORD_STRIDE <= len(flgs_data):
        rec = flgs_data[roff:roff + VZ_STATE_RECORD_STRIDE]

        boot_f = struct.unpack_from("<f", rec, 4)[0]
        type_hash = struct.unpack_from("<I", rec, 8)[0]
        entity_id = struct.unpack_from("<I", rec, 14)[0]
        x = struct.unpack_from("<f", rec, 18)[0]
        y = struct.unpack_from("<f", rec, 22)[0]
        z = struct.unpack_from("<f", rec, 26)[0]
        rot_y = struct.unpack_from("<f", rec, 38)[0]

        if is_valid_world_coord(x, y, z) and not (x == 0.0 and y == 0.0 and z == 0.0):
            name = entity_names.get(entity_id)
            boot_u32 = struct.unpack_from("<I", rec, 4)[0]
            entry = {
                "source": source_file,
                "block_type": "vz_state",
                "entity_id": f"0x{entity_id:08x}",
                "entity_name": name,
                "position": {"x": x, "y": y, "z": z},
                "rotation_y_sin": rot_y,
                "boot_float": boot_f,
                "boot_u32": f"0x{boot_u32:08x}",
                "type_hash": f"0x{type_hash:08x}",
            }
            placements.append(entry)

        roff += VZ_STATE_RECORD_STRIDE

    return placements


def extract_layers_static_placements(data: bytes, source_file: str = "") -> list[dict]:
    """Extract placement records from the layers_static composite block.

    The file is structured as:
      - 16-byte TOC entries (entry[0].field0 = sub-block count)
      - Concatenated sub-blocks, each with UCFX/CHDR/COMP structure
      - COMP child offsets are RELATIVE to the end of the chunk descriptor table
      - Transform COMP data sections contain 42-byte placement records
    """
    ucfx_positions = []
    pos = 0
    while True:
        idx = data.find(b"UCFX", pos)
        if idx == -1:
            break
        ucfx_positions.append(idx)
        pos = idx + 1

    if not ucfx_positions:
        return []

    all_placements: list[dict] = []

    for si, ucfx_pos in enumerate(ucfx_positions):
        ucfx_size = struct.unpack_from("<I", data, ucfx_pos + 4)[0]

        if si + 1 < len(ucfx_positions):
            block_end = ucfx_positions[si + 1]
        else:
            block_end = len(data)

        chdr_pos = data.find(b"CHDR", ucfx_pos, ucfx_pos + ucfx_size + 200)
        if chdr_pos < 0:
            continue

        chdr_entries = struct.unpack_from("<I", data, chdr_pos + 12)[0]

        pos = chdr_pos + 20
        chunks = []

        for _ in range(chdr_entries):
            if pos + 20 > block_end:
                break
            tag = data[pos:pos + 4]
            if tag not in (b"COMP", b"enum", b"flgt", b"flgs"):
                break

            num_children = struct.unpack_from("<I", data, pos + 16)[0]

            children = []
            child_pos = pos + 20
            for _ in range(num_children):
                if child_pos + 20 > block_end:
                    break
                ctag = data[child_pos:child_pos + 4].decode("ascii", errors="replace")
                coff = struct.unpack_from("<I", data, child_pos + 4)[0]
                csz = struct.unpack_from("<I", data, child_pos + 8)[0]
                children.append({"tag": ctag, "offset": coff, "size": csz})
                child_pos += 20

            chunks.append({"tag": tag.decode("ascii"), "children": children})
            pos = child_pos

        data_area_start = pos

        # Per sub-block: ordered names from Name COMPs, then transforms (for index zip).
        name_rows_ordered: list[tuple[int, str]] = []
        transform_entries: list[dict] = []

        for chunk in chunks:
            if chunk["tag"] != "COMP":
                continue

            info_name = None
            data_child = None

            for child in chunk["children"]:
                abs_off = data_area_start + child["offset"]
                if child["tag"] == "info" and abs_off + child["size"] <= len(data):
                    raw = data[abs_off:abs_off + child["size"]]
                    null_idx = raw.find(b"\x00")
                    if null_idx > 0:
                        info_name = raw[:null_idx].decode("ascii", errors="replace")
                if child["tag"] == "data":
                    data_child = child

            if data_child:
                abs_data_off = data_area_start + data_child["offset"]
                dsz = data_child["size"]

                if abs_data_off + dsz <= len(data):
                    blob = data[abs_data_off:abs_data_off + dsz]

                    if info_name and info_name.strip() == "Name":
                        name_rows_ordered.extend(_extract_entity_names_ordered(blob))

                    if info_name and "Transform" in info_name and dsz >= LAYERS_STATIC_RECORD_STRIDE:
                        dblob = blob
                        roff = 0
                        while roff + LAYERS_STATIC_RECORD_STRIDE <= len(dblob):
                            rec = dblob[roff:roff + LAYERS_STATIC_RECORD_STRIDE]
                            entity_key = struct.unpack_from("<I", rec, 0)[0]
                            x = struct.unpack_from("<f", rec, 4)[0]
                            y = struct.unpack_from("<f", rec, 8)[0]
                            z = struct.unpack_from("<f", rec, 12)[0]
                            qx = struct.unpack_from("<f", rec, 20)[0]
                            qy = struct.unpack_from("<f", rec, 24)[0]
                            qz = struct.unpack_from("<f", rec, 28)[0]
                            qw = struct.unpack_from("<f", rec, 32)[0]

                            if is_valid_world_coord(x, y, z):
                                # These 4 floats are a unit quaternion (qx, qy, qz, qw).
                                # For Y-axis rotation: qy = sin(yaw/2), qw = cos(yaw/2).
                                # True yaw = 2 * atan2(qy, qw).
                                yaw_rad = 2.0 * math.atan2(qy, qw)
                                entry = {
                                    "source": source_file,
                                    "block_type": "layers_static",
                                    "sub_block": si,
                                    "entity_id": f"0x{entity_key:08x}",
                                    "position": {
                                        "x": x,
                                        "y": y,
                                        "z": z,
                                    },
                                    "rotation_y_rad": yaw_rad,
                                    "rotation_y_deg": math.degrees(yaw_rad),
                                    "rotation_quat_x": qx,
                                    "rotation_quat_y": qy,
                                    "rotation_quat_z": qz,
                                    "rotation_quat_w": qw,
                                }
                                transform_entries.append(entry)

                            roff += LAYERS_STATIC_RECORD_STRIDE

        # Match Name records to Transform records by entity key.
        name_by_key: dict[int, str] = {eid: nm for eid, nm in name_rows_ordered}
        for ent in transform_entries:
            eid_str = ent.get("entity_id", "")
            if eid_str.startswith("0x"):
                try:
                    ek = int(eid_str, 16)
                    if ek in name_by_key:
                        ent["entity_name"] = name_by_key[ek]
                except ValueError:
                    pass

        all_placements.extend(transform_entries)

    return all_placements


def extract_placements(filepath: str) -> dict:
    """Main entry point: detect block type and extract placements."""
    with open(filepath, "rb") as f:
        data = f.read()

    block_type = detect_block_type(data)
    basename = os.path.basename(filepath)

    result = {
        "file": basename,
        "file_size": len(data),
        "block_type": block_type,
        "placements": [],
    }

    if block_type == "vz_state":
        result["placements"] = extract_vz_state_placements(data, basename)
    elif block_type == "layers_static":
        result["placements"] = extract_layers_static_placements(data, basename)
    elif block_type in ("c3_mesh", "c3_body"):
        result["note"] = "c3XXXX blocks contain geometry/terrain data, not placement data"
    else:
        result["note"] = f"Unrecognized block format (format_hash check failed)"

    result["placement_count"] = len(result["placements"])
    return result


def batch_extract(blocks_dir: str, block_filter: Optional[str] = None) -> dict:
    """Extract placements from all matching blocks in a directory."""
    results = {
        "blocks_dir": blocks_dir,
        "total_files": 0,
        "total_placements": 0,
        "by_type": {},
        "placements": [],
    }

    files = sorted(os.listdir(blocks_dir))
    for fname in files:
        if not fname.endswith(".bin"):
            continue
        if block_filter and block_filter not in fname:
            continue

        filepath = os.path.join(blocks_dir, fname)
        if not os.path.isfile(filepath):
            continue

        result = extract_placements(filepath)
        results["total_files"] += 1

        bt = result["block_type"]
        if bt not in results["by_type"]:
            results["by_type"][bt] = {"count": 0, "placements": 0}
        results["by_type"][bt]["count"] += 1
        results["by_type"][bt]["placements"] += result["placement_count"]

        results["total_placements"] += result["placement_count"]
        results["placements"].extend(result["placements"])

        if results["total_files"] % 100 == 0:
            print(
                f"  Processed {results['total_files']} files, "
                f"{results['total_placements']} placements...",
                file=sys.stderr,
            )

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Extract placement data from Mercenaries 2 binary blocks"
    )
    parser.add_argument(
        "input",
        help="Path to a .bin block file or directory (with --batch)",
    )
    parser.add_argument(
        "--output", "-o",
        help="Output JSON file (default: stdout)",
    )
    parser.add_argument(
        "--batch",
        action="store_true",
        help="Process all .bin files in the input directory",
    )
    parser.add_argument(
        "--filter",
        help="Only process files containing this substring (batch mode)",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="Compact JSON output (no indentation)",
    )
    parser.add_argument(
        "--stats-only",
        action="store_true",
        help="Print statistics only, no placement data",
    )

    args = parser.parse_args()
    indent = None if args.compact else 2

    if args.batch:
        result = batch_extract(args.input, args.filter)
        if args.stats_only:
            result.pop("placements", None)
    else:
        result = extract_placements(args.input)
        if args.stats_only:
            result.pop("placements", None)

    json_str = json.dumps(result, indent=indent, ensure_ascii=False)

    if args.output:
        with open(args.output, "w") as f:
            f.write(json_str)
        print(
            f"Wrote {result.get('placement_count', result.get('total_placements', 0))} "
            f"placements to {args.output}",
            file=sys.stderr,
        )
    else:
        print(json_str)


if __name__ == "__main__":
    main()
