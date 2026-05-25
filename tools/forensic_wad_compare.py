#!/usr/bin/env python3
"""Forensic binary comparison of FFCS WAD files.

Dumps every structural element of multiple WADs side-by-side and flags differences.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

PAGE_SIZE = 0x8000  # 32 KB


def hexdump(data: bytes, offset: int = 0, length: int = 0x100) -> str:
    lines = []
    for i in range(0, min(length, len(data)), 16):
        hex_part = " ".join(f"{b:02x}" for b in data[i:i+16])
        ascii_part = "".join(
            chr(b) if 0x20 <= b < 0x7f else "." for b in data[i:i+16]
        )
        lines.append(f"  {offset + i:08x}: {hex_part:<48s} {ascii_part}")
    return "\n".join(lines)


def analyze_wad(path: Path) -> dict:
    raw = path.read_bytes()
    info: dict = {"path": str(path), "size": len(raw), "size_hex": f"0x{len(raw):X}"}

    # Magic + version + chunk_count
    magic = raw[0:4]
    info["magic"] = magic.decode("ascii", errors="replace")
    info["version"] = struct.unpack_from("<I", raw, 4)[0]
    info["chunk_count"] = struct.unpack_from("<I", raw, 8)[0]

    # Parse all 7 chunk rows (even if some are padding)
    info["chunk_rows"] = []
    for i in range(7):
        off = 0x0C + i * 12
        if off + 12 > len(raw):
            break
        tag_bytes = raw[off:off+4]
        val, meta = struct.unpack_from("<II", raw, off + 4)
        tag = tag_bytes.decode("ascii", errors="replace")
        info["chunk_rows"].append({
            "index": i,
            "offset_in_header": f"0x{off:02X}",
            "tag": tag,
            "tag_hex": tag_bytes.hex(),
            "value": val,
            "value_hex": f"0x{val:08X}",
            "meta": meta,
            "meta_hex": f"0x{meta:08X}",
        })

    # 144-byte cert blob at 0x48
    cert_start = 0x48
    cert_end = cert_start + 144
    info["cert_blob_hex"] = raw[cert_start:cert_end].hex()

    # Remaining header bytes (0xD8..0xFF)
    info["header_tail_hex"] = raw[0xD8:0x100].hex()
    info["header_tail_nonzero"] = any(b != 0 for b in raw[0xD8:0x100])

    # Full header hex dump (first 0x100 bytes)
    info["header_hexdump"] = hexdump(raw, 0, 0x100)

    # Check page alignment of file size
    info["file_page_aligned"] = (len(raw) % PAGE_SIZE) == 0
    info["file_pages"] = len(raw) // PAGE_SIZE
    info["file_remainder"] = len(raw) % PAGE_SIZE

    # Find INDX, DATA, ASET, PTHS, CSUM from chunk rows
    chunks_by_tag = {}
    for row in info["chunk_rows"]:
        tag = row["tag"].strip("\x00")
        if tag and tag not in chunks_by_tag:
            chunks_by_tag[tag] = row

    # INDX analysis
    if "INDX" in chunks_by_tag:
        indx = chunks_by_tag["INDX"]
        indx_off = indx["value"]
        num_entries = indx["meta"]
        info["indx_offset"] = f"0x{indx_off:X}"
        info["indx_num_entries"] = num_entries
        info["indx_entries"] = []
        for i in range(min(num_entries, 50)):
            eoff = indx_off + i * 12
            if eoff + 12 > len(raw):
                break
            page_idx, packed, flags_pages = struct.unpack_from("<III", raw, eoff)
            pages = flags_pages & 0xFFFF
            flags = (flags_pages >> 16) & 0xFFFF
            info["indx_entries"].append({
                "block": i,
                "page_index": page_idx,
                "page_index_hex": f"0x{page_idx:X}",
                "file_offset": f"0x{page_idx * PAGE_SIZE:X}",
                "packed_field": packed,
                "flags": f"0x{flags:04X}",
                "page_count": pages,
            })
        # Raw hex of first few INDX entries
        indx_raw_len = min(num_entries * 12, 120)
        info["indx_raw_hex"] = raw[indx_off:indx_off + indx_raw_len].hex()

    # ASET analysis
    if "ASET" in chunks_by_tag:
        aset = chunks_by_tag["ASET"]
        aset_off = aset["value"]
        num_aset = aset["meta"]
        info["aset_offset"] = f"0x{aset_off:X}"
        info["aset_num_entries"] = num_aset
        info["aset_entries"] = []
        for i in range(min(num_aset, 20)):
            eoff = aset_off + i * 16
            if eoff + 16 > len(raw):
                break
            u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, eoff)
            block_idx = (u2 >> 16) & 0xFFFF
            info["aset_entries"].append({
                "index": i,
                "u0_hash": f"0x{u0:08X}",
                "u1": f"0x{u1:08X}",
                "u2": f"0x{u2:08X}",
                "block_idx_from_u2": block_idx,
                "u3": u3,
            })
        # Raw hex of first few ASET entries
        aset_raw_len = min(num_aset * 16, 256)
        info["aset_raw_hex"] = raw[aset_off:aset_off + aset_raw_len].hex()

    # PTHS analysis
    if "PTHS" in chunks_by_tag:
        pths = chunks_by_tag["PTHS"]
        pths_off = pths["value"]
        pths_meta = pths["meta"]
        info["pths_offset"] = f"0x{pths_off:X}"
        info["pths_meta"] = pths_meta

        # Read null-terminated strings
        info["pths_strings"] = []
        pos = pths_off
        for _ in range(min(pths_meta + 5, 100)):
            end = raw.find(b"\x00", pos)
            if end < 0 or end > pths_off + 0x10000:
                break
            s = raw[pos:end].decode("utf-8", errors="replace")
            if s:
                info["pths_strings"].append(s)
            pos = end + 1
            if pos >= len(raw):
                break
        # Raw hex around PTHS
        pths_raw_len = min(256, len(raw) - pths_off)
        info["pths_raw_hex"] = raw[pths_off:pths_off + pths_raw_len].hex()

    # CSUM analysis
    if "CSUM" in chunks_by_tag:
        csum = chunks_by_tag["CSUM"]
        info["csum_value"] = f"0x{csum['value']:08X}"
        info["csum_meta"] = csum["meta"]

    # DATA analysis
    if "DATA" in chunks_by_tag:
        data_chunk = chunks_by_tag["DATA"]
        data_off = data_chunk["value"]
        info["data_offset"] = f"0x{data_off:X}"
        info["data_meta"] = data_chunk["meta"]
        info["data_page"] = data_off // PAGE_SIZE

        # Check what's at the DATA offset
        if data_off < len(raw):
            data_first_16 = raw[data_off:data_off + 16]
            info["data_first_16_hex"] = data_first_16.hex()
            info["data_starts_with_sges"] = data_first_16[:4] == b"sges"
        else:
            info["data_first_16_hex"] = "(beyond file)"
            info["data_starts_with_sges"] = False

    # Check what's between header end (0x100) and INDX start
    if "INDX" in chunks_by_tag:
        indx_off = chunks_by_tag["INDX"]["value"]
        gap = raw[0x100:indx_off]
        info["header_to_indx_gap_size"] = len(gap)
        info["header_to_indx_gap_all_zero"] = all(b == 0 for b in gap)

    # Check what's between INDX end and next chunk (ASET/PTHS/DATA)
    # -- find the region between the metadata chunks and DATA
    metadata_offsets = []
    for tag in ("INDX", "ASET", "PTHS"):
        if tag in chunks_by_tag:
            off = chunks_by_tag[tag]["value"]
            metadata_offsets.append(off)

    if metadata_offsets and "DATA" in chunks_by_tag:
        meta_min = min(metadata_offsets)
        meta_max = max(metadata_offsets)
        data_off = chunks_by_tag["DATA"]["value"]
        # Find actual end of metadata region
        if "PTHS" in chunks_by_tag:
            pths_off = chunks_by_tag["PTHS"]["value"]
            # Find end of last null-terminated string
            scan = pths_off
            while scan < len(raw) and scan < pths_off + 0x10000:
                if raw[scan] == 0:
                    # Check if rest until data is all zeros
                    break
                scan += 1
            meta_end = scan + 1  # past the null
        else:
            meta_end = meta_max + 256

        info["metadata_region_start"] = f"0x{meta_min:X}"
        info["metadata_region_approx_end"] = f"0x{meta_end:X}"
        info["metadata_to_data_gap"] = data_off - meta_end
        gap_data = raw[meta_end:data_off]
        info["metadata_to_data_gap_all_zero"] = all(b == 0 for b in gap_data) if gap_data else True

    return info


def print_wad_info(info: dict, label: str):
    print(f"\n{'=' * 80}")
    print(f"  {label}: {info['path']}")
    print(f"  Size: {info['size']:,} bytes ({info['size_hex']})")
    print(f"  Page aligned: {info['file_page_aligned']} "
          f"(pages={info['file_pages']}, remainder={info['file_remainder']})")
    print(f"{'=' * 80}")

    print(f"\n  Magic: {info['magic']}")
    print(f"  Version: {info['version']}")
    print(f"  Declared chunk count: {info['chunk_count']}")

    print(f"\n  Chunk rows (all 7):")
    for row in info["chunk_rows"]:
        print(f"    [{row['index']}] @{row['offset_in_header']}: "
              f"tag={row['tag']!r} ({row['tag_hex']}) "
              f"value={row['value_hex']} meta={row['meta_hex']}")

    print(f"\n  Certificate blob (0x48, 144 bytes): "
          f"{'MATCH' if info['cert_blob_hex'] == KNOWN_CERT_HEX else 'MISMATCH!'}")
    print(f"  Header tail (0xD8-0xFF) nonzero: {info['header_tail_nonzero']}")

    if "indx_num_entries" in info:
        print(f"\n  INDX: {info['indx_num_entries']} entries at {info['indx_offset']}")
        for e in info.get("indx_entries", []):
            print(f"    block[{e['block']}]: page={e['page_index']} ({e['page_index_hex']}) "
                  f"→ file {e['file_offset']}, packed={e['packed_field']}, "
                  f"flags={e['flags']}, pages={e['page_count']}")

    if "aset_num_entries" in info:
        print(f"\n  ASET: {info['aset_num_entries']} entries at {info['aset_offset']}")
        for e in info.get("aset_entries", []):
            print(f"    [{e['index']}] hash={e['u0_hash']} u1={e['u1']} "
                  f"u2={e['u2']} (block={e['block_idx_from_u2']}) u3={e['u3']}")

    if "pths_offset" in info:
        print(f"\n  PTHS: meta={info['pths_meta']} at {info['pths_offset']}")
        for s in info.get("pths_strings", []):
            print(f"    {s!r}")

    if "csum_value" in info:
        print(f"\n  CSUM: value={info['csum_value']} meta={info['csum_meta']}")

    if "data_offset" in info:
        print(f"\n  DATA: offset={info['data_offset']} meta={info['data_meta']} "
              f"page={info.get('data_page', '?')}")
        print(f"    First 16 bytes: {info.get('data_first_16_hex', '?')}")
        print(f"    Starts with sges: {info.get('data_starts_with_sges', '?')}")

    if "header_to_indx_gap_size" in info:
        print(f"\n  Gap header(0x100)→INDX: {info['header_to_indx_gap_size']} bytes, "
              f"all zero: {info['header_to_indx_gap_all_zero']}")

    if "metadata_to_data_gap" in info:
        print(f"  Gap metadata→DATA: {info['metadata_to_data_gap']} bytes, "
              f"all zero: {info['metadata_to_data_gap_all_zero']}")

    print(f"\n  Full header hex dump (0x000-0x0FF):")
    print(info["header_hexdump"])


# Known cert blob for comparison
KNOWN_CERT_HEX = (
    "a8d846fa28870e149ad33171e2540a8ff8ab0a3b3ef15e66d0f653f778e9e539"
    "5a5422c1541ab8e6874ddfe8c7597320"
    "4e900b60143c27e5612d98dece7ae799"
    "5565161854c34756bc8d0bfa5042725b"
    "862f613410ca8b9f5c81021620830efe"
    "f247ceacc4307d4dd52948ea7a1511f0"
    "1463febc5abd08567f8010636adfb959"
    "079356746703e7ecbb49f61c80864942"  # Note: this was "7c" originally
)


def compare_wads(infos: list[dict]):
    print("\n\n" + "=" * 80)
    print("  COMPARISON SUMMARY")
    print("=" * 80)

    ref = infos[0]
    labels = [Path(i["path"]).name for i in infos]

    # Compare chunk row order
    print("\n  Chunk row tags (order matters):")
    for i, info in enumerate(infos):
        tags = [r["tag"] for r in info["chunk_rows"]]
        print(f"    {labels[i]:30s}: {tags}")

    # Compare chunk row values
    print("\n  Chunk row values:")
    for row_idx in range(max(len(info["chunk_rows"]) for info in infos)):
        vals = []
        for info in infos:
            if row_idx < len(info["chunk_rows"]):
                r = info["chunk_rows"][row_idx]
                vals.append(f"{r['tag']}:{r['value_hex']}:{r['meta_hex']}")
            else:
                vals.append("(missing)")
        match = "OK" if len(set(vals)) == 1 else "DIFF"
        if match == "DIFF":
            print(f"    Row [{row_idx}] *** {match} ***")
            for j, v in enumerate(vals):
                print(f"      {labels[j]:30s}: {v}")
        else:
            print(f"    Row [{row_idx}] {match}: {vals[0]}")

    # DATA offset
    print(f"\n  DATA offsets:")
    for i, info in enumerate(infos):
        print(f"    {labels[i]:30s}: {info.get('data_offset', '?')} "
              f"(meta={info.get('data_meta', '?')}, page={info.get('data_page', '?')})")

    # INDX first entry page_index
    print(f"\n  INDX first entry page_index:")
    for i, info in enumerate(infos):
        entries = info.get("indx_entries", [])
        if entries:
            e = entries[0]
            print(f"    {labels[i]:30s}: page={e['page_index']} ({e['page_index_hex']}) "
                  f"→ file offset {e['file_offset']}")

    # CSUM
    print(f"\n  CSUM:")
    for i, info in enumerate(infos):
        print(f"    {labels[i]:30s}: value={info.get('csum_value', '?')} "
              f"meta={info.get('csum_meta', '?')}")

    # File alignment
    print(f"\n  File size / page alignment:")
    for i, info in enumerate(infos):
        print(f"    {labels[i]:30s}: {info['size']:,} bytes, "
              f"page_aligned={info['file_page_aligned']}, "
              f"pages={info['file_pages']}, remainder={info['file_remainder']}")

    # Cert blob
    print(f"\n  Certificate blob match:")
    for i, info in enumerate(infos):
        match = info["cert_blob_hex"] == KNOWN_CERT_HEX
        # Also cross-compare
        match_ref = info["cert_blob_hex"] == ref["cert_blob_hex"]
        print(f"    {labels[i]:30s}: vs_known={'OK' if match else 'MISMATCH'} "
              f"vs_ref={'OK' if match_ref else 'MISMATCH'}")

    # Header tail
    print(f"\n  Header tail (0xD8-0xFF):")
    for i, info in enumerate(infos):
        print(f"    {labels[i]:30s}: nonzero={info['header_tail_nonzero']}")
        if info["header_tail_nonzero"]:
            print(f"      hex: {info['header_tail_hex']}")


def main():
    demo_dir = Path("Mercenaries 2 World in Flames DEMO/data")
    wads = [
        demo_dir / "English.wad",
        demo_dir / "Loading.wad",
        demo_dir / "shell.wad",
        demo_dir / "vz.wad",
    ]

    # Add patch WAD if it exists
    patch = demo_dir / "vz-patch.wad"
    if patch.exists():
        wads.append(patch)

    # Also check for patch in current dir
    if not patch.exists():
        alt = Path("vz-patch.wad")
        if alt.exists():
            wads.append(alt)

    infos = []
    for wad in wads:
        if not wad.exists():
            print(f"SKIP: {wad} not found")
            continue
        try:
            info = analyze_wad(wad)
            infos.append(info)
        except Exception as e:
            print(f"ERROR analyzing {wad}: {e}")

    for info in infos:
        print_wad_info(info, Path(info["path"]).name)

    if len(infos) >= 2:
        compare_wads(infos)


if __name__ == "__main__":
    main()
