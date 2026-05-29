#!/usr/bin/env python3
"""Phase 0 probe: Extract schm field entries from ECS_NODE blocks.

Walks a decompressed UCFX block, finds COMP triplets (info/schm/data),
and dumps the raw schm field entries for reverse-engineering the type-code
to field-width mapping.

Usage:
    python probe_schm_fields.py <block.bin> [--le|--be]
    python probe_schm_fields.py --from-wad <vz.wad> --block-index <N>
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))


def read_u32(data: bytes, offset: int, big_endian: bool = False) -> int:
    fmt = ">I" if big_endian else "<I"
    return struct.unpack_from(fmt, data, offset)[0]


def read_u16(data: bytes, offset: int, big_endian: bool = False) -> int:
    fmt = ">H" if big_endian else "<H"
    return struct.unpack_from(fmt, data, offset)[0]


def walk_ucfx_descriptors(container: bytes, big_endian: bool = False):
    """Parse UCFX container descriptors. Yields (index, tag, row_u0, body_offset, body_size)."""
    magic = container[0:4]
    expected = b"XFCU" if big_endian else b"UCFX"
    if magic != expected:
        return

    data_area_off = read_u32(container, 4, big_endian)
    n_desc = read_u32(container, 16, big_endian)

    for i in range(n_desc):
        row_start = 20 + i * 20
        if row_start + 20 > len(container):
            break
        tag_bytes = container[row_start:row_start + 4]
        if big_endian:
            tag_bytes = tag_bytes[::-1]
        tag = tag_bytes.decode("ascii", errors="replace")
        row_u0 = read_u32(container, row_start + 4, big_endian)
        body_size = read_u32(container, row_start + 8, big_endian)

        if row_u0 == 0xFFFFFFFF:
            body_offset = None
        else:
            body_offset = (data_area_off + row_u0) if data_area_off > 0 else (8 + row_u0)

        yield (i, tag, row_u0, body_offset, body_size)


def extract_comp_groups(container: bytes, big_endian: bool = False):
    """Find COMP triplets and extract info/schm/data bodies."""
    descriptors = list(walk_ucfx_descriptors(container, big_endian))
    groups = []

    i = 0
    while i < len(descriptors):
        idx, tag, row_u0, body_off, body_size = descriptors[i]
        if tag == "COMP" and row_u0 == 0xFFFFFFFF:
            group = {"info": None, "schm": None, "data": None, "info_raw": None}
            j = i + 1
            while j < len(descriptors):
                jidx, jtag, jrow_u0, jbody_off, jbody_size = descriptors[j]
                if jtag == "COMP" and jrow_u0 == 0xFFFFFFFF:
                    break
                if jrow_u0 == 0xFFFFFFFF:
                    j += 1
                    continue
                if jbody_off is not None and jbody_size > 0:
                    body = container[jbody_off:jbody_off + jbody_size]
                    if jtag == "info":
                        group["info"] = body
                        group["info_raw"] = body
                    elif jtag == "schm":
                        group["schm"] = body
                    elif jtag == "data":
                        group["data"] = body
                j += 1
            groups.append(group)
            i = j
        else:
            i += 1

    return groups


def parse_component_name(info_body: bytes) -> str:
    """Extract component name from info body (null-terminated ASCII or compact hash)."""
    if not info_body:
        return "<empty>"
    null_idx = info_body.find(b"\x00")
    if null_idx > 0 and all(32 <= b < 127 for b in info_body[:null_idx]):
        return info_body[:null_idx].decode("ascii")
    return f"__hash_0x{struct.unpack_from('<I', info_body, 0)[0]:08x}"


def parse_schm_fields(schm_body: bytes, big_endian: bool = False):
    """Parse schm field entries.

    Layout:
        +0: u32 n_fields
        +4: u32 payload_stride
        +8: 16 * n_fields field entries
            Each entry: (u32 type_code, u32 name_hash, u32 unk, u32 field_offset)
    """
    if not schm_body or len(schm_body) < 8:
        return None

    n_fields = read_u32(schm_body, 0, big_endian)
    payload_stride = read_u32(schm_body, 4, big_endian)

    if n_fields > 200 or n_fields * 16 + 8 > len(schm_body):
        return {"n_fields": n_fields, "payload_stride": payload_stride,
                "error": f"implausible n_fields={n_fields} or schm too small"}

    fields = []
    for fi in range(n_fields):
        entry_off = 8 + fi * 16
        type_code = read_u32(schm_body, entry_off, big_endian)
        name_hash = read_u32(schm_body, entry_off + 4, big_endian)
        unk = read_u32(schm_body, entry_off + 8, big_endian)
        field_offset = read_u32(schm_body, entry_off + 12, big_endian)
        fields.append({
            "type_code": f"0x{type_code:08x}",
            "type_code_dec": type_code,
            "name_hash": f"0x{name_hash:08x}",
            "unk": f"0x{unk:08x}",
            "field_offset": field_offset,
        })

    return {
        "n_fields": n_fields,
        "payload_stride": payload_stride,
        "fields": fields,
        "schm_size": len(schm_body),
    }


def probe_block(block_data: bytes, big_endian: bool = False, label: str = ""):
    """Walk a decompressed block's entry table and probe each UCFX container."""
    entry_count = read_u32(block_data, 0, big_endian)
    if entry_count > 50000:
        print(f"  [!] Implausible entry_count={entry_count}, skipping")
        return []

    results = []
    entries = []
    for ei in range(entry_count):
        eo = 4 + ei * 16
        name_hash = read_u32(block_data, eo, big_endian)
        type_hash = read_u32(block_data, eo + 4, big_endian)
        field_c = read_u32(block_data, eo + 8, big_endian)
        chunk_size = read_u32(block_data, eo + 12, big_endian)
        entries.append((name_hash, type_hash, field_c, chunk_size))

    header_size = 4 + entry_count * 16
    offset = header_size

    TYPE_ECS_NODE = 0xE6B81A54

    for ei, (name_hash, type_hash, field_c, chunk_size) in enumerate(entries):
        container_end = offset + chunk_size
        if container_end > len(block_data):
            break

        container = block_data[offset:container_end]

        if type_hash == TYPE_ECS_NODE:
            groups = extract_comp_groups(container, big_endian)
            for gi, group in enumerate(groups):
                comp_name = parse_component_name(group["info"])
                schm_result = parse_schm_fields(group["schm"], big_endian) if group["schm"] else None
                data_size = len(group["data"]) if group["data"] else 0

                result = {
                    "block_label": label,
                    "entry_index": ei,
                    "comp_index": gi,
                    "component_name": comp_name,
                    "has_schm": group["schm"] is not None,
                    "schm": schm_result,
                    "data_size": data_size,
                }
                results.append(result)

        offset = container_end
        csum_size = 8
        if offset + csum_size <= len(block_data):
            offset += csum_size

    return results


def decompress_block_from_wad(wad_path: Path, block_index: int) -> bytes:
    """Decompress a single block from a WAD file."""
    from sges_decompress import decompress_sges_block

    wad_data = wad_path.read_bytes()

    if wad_data[0:4] != b"FFCS":
        raise ValueError(f"Not an FFCS WAD: {wad_path}")

    indx_off = None
    pos = 8
    while pos < min(len(wad_data), 0x100):
        chunk_tag = wad_data[pos:pos + 4]
        chunk_size = struct.unpack_from("<I", wad_data, pos + 4)[0]
        if chunk_tag == b"INDX":
            indx_off = pos + 8
            break
        pos += 8 + chunk_size

    if indx_off is None:
        raise ValueError("No INDX chunk found in FFCS header")

    entry_size = 16
    entry_off = indx_off + block_index * entry_size
    packed_field = struct.unpack_from("<I", wad_data, entry_off)[0]
    page_count = packed_field & 0x3FFF
    page_index = struct.unpack_from("<I", wad_data, entry_off + 4)[0]

    block_start = page_index * 0x8000
    block_end = block_start + page_count * 0x8000

    return decompress_sges_block(wad_data, block_start, block_end)


def probe_xbox_sges_header(wad_path: Path):
    """Inspect the first sges block header from an Xbox WAD to determine format."""
    wad_data = wad_path.read_bytes()

    if wad_data[0:4] != b"FFCS":
        print(f"  [!] Not an FFCS WAD: {wad_path}")
        return None

    pos = 8
    indx_off = None
    while pos < min(len(wad_data), 0x200):
        chunk_tag = wad_data[pos:pos + 4]
        chunk_size = struct.unpack_from(">I", wad_data, pos + 4)[0]
        if chunk_tag == b"XDNI":  # reversed "INDX" for BE
            indx_off = pos + 8
            break
        elif chunk_tag == b"INDX":
            indx_off = pos + 8
            break
        pos += 8 + chunk_size

    if indx_off is None:
        first_64 = wad_data[:64].hex()
        print(f"  [!] Could not find INDX in Xbox WAD header")
        print(f"      First 64 bytes: {first_64}")
        return None

    entry_off = indx_off
    packed_field_be = struct.unpack_from(">I", wad_data, entry_off)[0]
    page_index_be = struct.unpack_from(">I", wad_data, entry_off + 4)[0]
    page_count = packed_field_be & 0x3FFF

    block_start = page_index_be * 0x8000
    if block_start + 64 > len(wad_data):
        print(f"  [!] Block start 0x{block_start:x} beyond WAD size")
        return None

    header = wad_data[block_start:block_start + 64]
    print(f"\n  Xbox sges block 0 header (first 64 bytes at offset 0x{block_start:x}):")
    print(f"    Magic: {header[0:4]}")
    for row in range(4):
        row_bytes = header[row * 16:(row + 1) * 16]
        hex_str = " ".join(f"{b:02x}" for b in row_bytes)
        print(f"    +{row * 16:02x}: {hex_str}")

    if header[0:4] == b"sges":
        decompressed_size_be = struct.unpack_from(">I", header, 4)[0]
        print(f"\n    Decompressed size (BE u32 @+4): {decompressed_size_be} (0x{decompressed_size_be:x})")
        print(f"    Bytes @+8..+16: {header[8:16].hex()}")
        print(f"    Bytes @+16..+32: {header[16:32].hex()}")
    return header


def probe_lua_blocks(wad_path: Path, big_endian: bool = True, max_blocks: int = 50):
    """Scan WAD for Lua script blocks and inspect bytecode headers."""
    wad_data = wad_path.read_bytes()

    if wad_data[0:4] != b"FFCS":
        print(f"  [!] Not an FFCS WAD")
        return

    endian_char = ">" if big_endian else "<"

    pos = 8
    indx_off = None
    indx_size = 0
    while pos < min(len(wad_data), 0x400):
        chunk_tag = wad_data[pos:pos + 4]
        chunk_size = struct.unpack_from(f"{endian_char}I", wad_data, pos + 4)[0]
        tag_str = chunk_tag.decode("ascii", errors="replace")
        reversed_tag = chunk_tag[::-1].decode("ascii", errors="replace")
        if tag_str == "INDX" or reversed_tag == "INDX":
            indx_off = pos + 8
            indx_size = chunk_size
            break
        pos += 8 + chunk_size

    if indx_off is None:
        print("  [!] No INDX found")
        return

    n_entries = indx_size // 16
    TYPE_SCRIPT = 0x8C121E89

    lua_findings = []
    for bi in range(min(n_entries, max_blocks * 10)):
        eo = indx_off + bi * 16
        if eo + 16 > len(wad_data):
            break
        packed = struct.unpack_from(f"{endian_char}I", wad_data, eo)[0]
        page_idx = struct.unpack_from(f"{endian_char}I", wad_data, eo + 4)[0]
        page_count = packed & 0x3FFF

        if page_count == 0:
            continue

        block_start = page_idx * 0x8000
        if block_start + 32 > len(wad_data):
            continue

        sges_magic = wad_data[block_start:block_start + 4]
        if sges_magic != b"sges":
            continue

        decomp_size = struct.unpack_from(f"{endian_char}I", wad_data, block_start + 4)[0]
        if decomp_size < 100 or decomp_size > 0x1000000:
            continue

        try:
            import zlib
            seg_start = block_start + 16 if not big_endian else block_start + 32
            if big_endian:
                seg_start = block_start + 16
            compressed = wad_data[seg_start:block_start + page_count * 0x8000]

            for scan_off in range(0, min(len(compressed), 0x8000)):
                if compressed[scan_off:scan_off + 4] == b"\x1bLua":
                    lua_hdr = compressed[scan_off:scan_off + 20]
                    lua_findings.append({
                        "block_index": bi,
                        "lua_header_hex": lua_hdr.hex(),
                        "version": lua_hdr[4] if len(lua_hdr) > 4 else None,
                        "format": lua_hdr[5] if len(lua_hdr) > 5 else None,
                        "endian_flag": lua_hdr[6] if len(lua_hdr) > 6 else None,
                        "sizeof_int": lua_hdr[7] if len(lua_hdr) > 7 else None,
                        "sizeof_size_t": lua_hdr[8] if len(lua_hdr) > 8 else None,
                        "sizeof_instruction": lua_hdr[9] if len(lua_hdr) > 9 else None,
                        "sizeof_number": lua_hdr[10] if len(lua_hdr) > 10 else None,
                        "integral_flag": lua_hdr[11] if len(lua_hdr) > 11 else None,
                    })
                    if len(lua_findings) >= 5:
                        return lua_findings
                    break
        except Exception:
            continue

    return lua_findings


def main():
    ap = argparse.ArgumentParser(description="Probe schm field entries from UCFX ECS_NODE blocks")
    ap.add_argument("block", nargs="?", type=Path, help="Decompressed block .bin file")
    ap.add_argument("--be", action="store_true", help="Block data is big-endian")
    ap.add_argument("--from-wad", type=Path, help="Extract block from WAD file")
    ap.add_argument("--block-index", type=int, default=0, help="Block index within WAD")
    ap.add_argument("--xbox-sges", type=Path, help="Inspect Xbox sges header format")
    ap.add_argument("--lua-scan", type=Path, help="Scan WAD for Lua bytecode headers")
    ap.add_argument("--lua-be", action="store_true", help="Lua scan WAD is big-endian")
    ap.add_argument("--output", type=Path, help="Write JSON output")
    args = ap.parse_args()

    results = {}

    if args.xbox_sges:
        print(f"=== Xbox sges header probe: {args.xbox_sges} ===")
        header = probe_xbox_sges_header(args.xbox_sges)
        if header:
            results["xbox_sges_header"] = header[:64].hex()

    if args.lua_scan:
        print(f"\n=== Lua bytecode header scan: {args.lua_scan} ===")
        findings = probe_lua_blocks(args.lua_scan, big_endian=args.lua_be)
        if findings:
            for f in findings:
                print(f"  Block {f['block_index']}: version={f['version']}, "
                      f"endian_flag=0x{f['endian_flag']:02x} ({f['endian_flag']}), "
                      f"sizeof_int={f['sizeof_int']}, sizeof_number={f['sizeof_number']}")
                print(f"    Raw header: {f['lua_header_hex']}")
            results["lua_findings"] = findings
        else:
            print("  No Lua bytecode found in scanned blocks")

    if args.block:
        print(f"\n=== schm field probe: {args.block} ===")
        block_data = args.block.read_bytes()
        comp_results = probe_block(block_data, big_endian=args.be, label=str(args.block))

        if not comp_results:
            print("  No ECS_NODE / COMP groups found in block")
        else:
            has_schm_count = sum(1 for r in comp_results if r["has_schm"])
            no_schm_count = sum(1 for r in comp_results if not r["has_schm"])
            print(f"  Found {len(comp_results)} COMP groups: "
                  f"{has_schm_count} with schm, {no_schm_count} without")
            print()
            for r in comp_results:
                name = r["component_name"]
                schm = r["schm"]
                if schm and "fields" in schm:
                    print(f"  [{name}] payload_stride={schm['payload_stride']}, "
                          f"n_fields={schm['n_fields']}, data_size={r['data_size']}")
                    for fi, f in enumerate(schm["fields"]):
                        print(f"    field[{fi}]: type={f['type_code']} ({f['type_code_dec']}), "
                              f"name_hash={f['name_hash']}, unk={f['unk']}, "
                              f"offset={f['field_offset']}")
                elif schm and "error" in schm:
                    print(f"  [{name}] schm ERROR: {schm['error']}")
                else:
                    print(f"  [{name}] NO SCHM, data_size={r['data_size']}")
                print()

        results["comp_groups"] = comp_results

    elif args.from_wad:
        print(f"\n=== Decompress block {args.block_index} from {args.from_wad} ===")
        try:
            block_data = decompress_block_from_wad(args.from_wad, args.block_index)
            comp_results = probe_block(block_data, big_endian=False,
                                       label=f"{args.from_wad.name}[{args.block_index}]")
            if comp_results:
                for r in comp_results:
                    name = r["component_name"]
                    schm = r["schm"]
                    if schm and "fields" in schm:
                        print(f"  [{name}] payload_stride={schm['payload_stride']}, "
                              f"n_fields={schm['n_fields']}")
                        for fi, f in enumerate(schm["fields"]):
                            print(f"    field[{fi}]: type={f['type_code']} ({f['type_code_dec']}), "
                                  f"offset={f['field_offset']}")
                    else:
                        print(f"  [{name}] NO SCHM")
                    print()
            results["comp_groups"] = comp_results
        except Exception as e:
            print(f"  ERROR: {e}")

    if args.output and results:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(results, indent=2))
        print(f"\nJSON output written to: {args.output}")


if __name__ == "__main__":
    main()
