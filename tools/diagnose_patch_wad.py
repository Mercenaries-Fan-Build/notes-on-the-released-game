#!/usr/bin/env python3
"""Diagnose structural issues in a custom patch WAD for Mercenaries 2.

Parses the FFCS header, decompresses the sges block, validates the
block entry table, each UCFX container header, DEPS chunks, CSUM
trailers, and ASET sub-entry consistency.
"""
from __future__ import annotations

import struct
import sys
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sges_decompress import decompress_sges_block, parse_sges_header

PAGE_SIZE = 0x8000
UCFX_MAGIC = b"UCFX"
CSUM_TAG = b"CSUM"


def crc32_mercs2(data: bytes) -> int:
    return (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF


def diagnose(wad_path: Path, *, retail_block_path: Path | None = None) -> int:
    raw = wad_path.read_bytes()
    size = len(raw)
    errors: list[str] = []
    warnings: list[str] = []

    print(f"{'='*70}")
    print(f"  PATCH WAD DIAGNOSTIC: {wad_path}")
    print(f"  File size: {size:,} bytes")
    print(f"{'='*70}")

    print(f"\n{'-'*70}")
    print("1. FFCS HEADER")
    print(f"{'-'*70}")

    if raw[:4] != b"FFCS":
        errors.append(f"Missing FFCS magic (got {raw[:4]!r})")
        print(f"  FAIL: {errors[-1]}")
        return _report(errors, warnings)

    version = struct.unpack_from("<I", raw, 4)[0]
    chunk_count = struct.unpack_from("<I", raw, 8)[0]
    print(f"  Magic: FFCS OK")
    print(f"  Version: {version}")
    print(f"  Declared chunk count: {chunk_count}")

    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        chunks[tag] = (val, meta)
        print(f"  Chunk [{i}] {tag}: offset/value=0x{val:08X}, meta={meta}")

    for required in ("INDX", "DATA", "ASET", "PTHS"):
        if required not in chunks:
            errors.append(f"Missing required chunk: {required}")

    if errors:
        return _report(errors, warnings)

    print(f"\n{'-'*70}")
    print("2. INDX ENTRIES")
    print(f"{'-'*70}")

    indx_off, indx_count = chunks["INDX"]
    print(f"  Offset: 0x{indx_off:X}, Count: {indx_count}")

    indx_entries = []
    for i in range(indx_count):
        off = indx_off + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, off)
        pages = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        file_offset = page_idx * PAGE_SIZE
        indx_entries.append({
            "page_idx": page_idx, "packed": packed,
            "flags": flags, "pages": pages,
            "file_offset": file_offset,
        })
        print(f"  Block [{i}]: page_idx={page_idx} (offset=0x{file_offset:X}), "
              f"packed={packed}, flags=0x{flags:04X}, pages={pages}")

        if file_offset + pages * PAGE_SIZE > size:
            errors.append(f"Block {i} extends beyond file: offset 0x{file_offset:X} + "
                          f"{pages} pages = 0x{file_offset + pages*PAGE_SIZE:X} > file size 0x{size:X}")

    print(f"\n{'-'*70}")
    print("3. ASET ENTRIES")
    print(f"{'-'*70}")

    aset_off, aset_count = chunks["ASET"]
    print(f"  Offset: 0x{aset_off:X}, Count: {aset_count}")

    aset_entries = []
    for i in range(aset_count):
        off = aset_off + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        sub_entry = u2 & 0xFFFF
        aset_entries.append({
            "asset_hash": u0, "u1": u1, "u2": u2, "u3": u3,
            "block_idx": block_idx, "sub_entry": sub_entry,
        })

    print(f"  Total ASET entries: {aset_count}")
    block_idx_set = set(e["block_idx"] for e in aset_entries)
    print(f"  Distinct block indices referenced: {sorted(block_idx_set)}")

    for e in aset_entries:
        if e["block_idx"] >= indx_count:
            errors.append(f"ASET entry hash=0x{e['asset_hash']:08X} references "
                          f"block_idx={e['block_idx']} but only {indx_count} blocks exist")

    # Show first 10 and last 5
    show_n = min(10, aset_count)
    for i in range(show_n):
        e = aset_entries[i]
        print(f"    [{i:3d}] hash=0x{e['asset_hash']:08X} u1=0x{e['u1']:08X} "
              f"u2=0x{e['u2']:08X} (blk={e['block_idx']}, sub=0x{e['sub_entry']:04X}) "
              f"u3={e['u3']}")
    if aset_count > show_n:
        print(f"    ... ({aset_count - show_n} more)")
        for i in range(max(show_n, aset_count - 5), aset_count):
            e = aset_entries[i]
            print(f"    [{i:3d}] hash=0x{e['asset_hash']:08X} u1=0x{e['u1']:08X} "
                  f"u2=0x{e['u2']:08X} (blk={e['block_idx']}, sub=0x{e['sub_entry']:04X}) "
                  f"u3={e['u3']}")

    print(f"\n{'-'*70}")
    print("4. DATA BLOCK DECOMPRESSION")
    print(f"{'-'*70}")

    data_off, _data_meta = chunks["DATA"]
    print(f"  DATA offset: 0x{data_off:X}")

    if data_off >= size:
        errors.append(f"DATA offset 0x{data_off:X} beyond file size")
        return _report(errors, warnings)

    sges_data = raw[data_off:]
    if sges_data[:4] != b"sges":
        errors.append(f"DATA does not start with sges magic (got {sges_data[:4]!r})")
        return _report(errors, warnings)

    try:
        maj, minor, total_u, total_c = parse_sges_header(sges_data[:16])
        print(f"  sges v{maj}.{minor}: uncompressed={total_u:,}, "
              f"compressed_hint={total_c:,}, segments={minor}")
    except Exception as exc:
        errors.append(f"Failed to parse sges header: {exc}")
        return _report(errors, warnings)

    try:
        decompressed = decompress_sges_block(sges_data, 0, len(sges_data))
        print(f"  Decompressed: {len(decompressed):,} bytes")
    except Exception as exc:
        errors.append(f"Failed to decompress sges: {exc}")
        return _report(errors, warnings)

    if len(decompressed) != total_u:
        warnings.append(f"Decompressed size {len(decompressed)} != sges declared {total_u}")

    print(f"\n{'-'*70}")
    print("5. BLOCK ENTRY TABLE")
    print(f"{'-'*70}")

    if len(decompressed) < 4:
        errors.append("Decompressed block too short for entry count")
        return _report(errors, warnings)

    entry_count = struct.unpack_from("<I", decompressed, 0)[0]
    header_end = 4 + entry_count * 16
    print(f"  entry_count: {entry_count}")
    print(f"  Header size: {header_end} bytes (4 + {entry_count} * 16)")
    print(f"  Data area starts at offset: 0x{header_end:X}")

    if header_end > len(decompressed):
        errors.append(f"Header extends beyond decompressed data: "
                      f"{header_end} > {len(decompressed)}")
        return _report(errors, warnings)

    if entry_count != aset_count:
        msg = (f"Entry count ({entry_count}) != ASET count ({aset_count})")
        if abs(entry_count - aset_count) <= 2:
            warnings.append(msg + " (close, might be OK for injected scripts)")
        else:
            warnings.append(msg)
        print(f"  WARNING: {msg}")

    block_entries = []
    running_offset = header_end
    total_chunk_bytes = 0
    data_remaining = len(decompressed) - header_end

    for i in range(entry_count):
        eoff = 4 + i * 16
        name_hash, type_hash, field_c, chunk_size = struct.unpack_from(
            "<IIII", decompressed, eoff
        )
        block_entries.append({
            "index": i,
            "name_hash": name_hash,
            "type_hash": type_hash,
            "field_c": field_c,
            "chunk_size": chunk_size,
            "data_offset": running_offset,
        })
        total_chunk_bytes += chunk_size
        running_offset += chunk_size

    print(f"\n  Entry table summary:")
    print(f"    Total entries: {entry_count}")
    print(f"    Sum of all chunk_size: {total_chunk_bytes:,}")
    print(f"    Data area available: {data_remaining:,}")
    print(f"    Difference: {data_remaining - total_chunk_bytes:+,}")

    if total_chunk_bytes != data_remaining:
        errors.append(f"Chunk sizes don't add up: sum={total_chunk_bytes:,} but "
                      f"data area is {data_remaining:,} bytes "
                      f"(diff={data_remaining - total_chunk_bytes:+,})")

    # Check field_c values
    nonzero_field_c = [(e["index"], e["field_c"]) for e in block_entries if e["field_c"] != 0]
    if nonzero_field_c:
        warnings.append(f"{len(nonzero_field_c)} entries have non-zero field_c")
        for idx, fc in nonzero_field_c[:5]:
            print(f"    Entry [{idx}]: field_c = 0x{fc:08X}")
    else:
        print(f"    All field_c values are 0: OK")

    # Check type_hash distribution
    type_hash_counts: dict[int, int] = {}
    for e in block_entries:
        th = e["type_hash"]
        type_hash_counts[th] = type_hash_counts.get(th, 0) + 1
    print(f"    Type hash distribution:")
    for th, cnt in sorted(type_hash_counts.items()):
        print(f"      0x{th:08X}: {cnt} entries")

    # Print all entries
    print(f"\n  All entries:")
    print(f"  {'Idx':>4} {'NameHash':>10} {'TypeHash':>10} {'FieldC':>6} "
          f"{'ChunkSize':>10} {'DataOff':>10}")
    print(f"  {'-'*60}")
    for e in block_entries:
        flag = ""
        if e["chunk_size"] < 8:
            flag = " *** TOO SMALL (< 8 for CSUM)"
            errors.append(f"Entry [{e['index']}] chunk_size={e['chunk_size']} < 8 bytes")
        if e["chunk_size"] < 28:
            flag = flag or " * small"
        print(f"  {e['index']:4d} 0x{e['name_hash']:08X} 0x{e['type_hash']:08X} "
              f"{e['field_c']:6d} {e['chunk_size']:10,} 0x{e['data_offset']:08X}{flag}")

    print(f"\n{'-'*70}")
    print("6. UCFX CONTAINER VALIDATION")
    print(f"{'-'*70}")

    for e in block_entries:
        idx = e["index"]
        doff = e["data_offset"]
        csz = e["chunk_size"]
        end = doff + csz

        if end > len(decompressed):
            errors.append(f"Entry [{idx}] extends beyond decompressed data: "
                          f"offset 0x{doff:X} + size {csz:,} = 0x{end:X} > 0x{len(decompressed):X}")
            continue

        chunk_data = decompressed[doff:end]

        # Check UCFX magic
        if chunk_data[:4] != UCFX_MAGIC:
            errors.append(f"Entry [{idx}] at offset 0x{doff:X}: missing UCFX magic "
                          f"(got {chunk_data[:4]!r})")
            continue

        # Parse UCFX header (20 bytes)
        if len(chunk_data) < 20:
            errors.append(f"Entry [{idx}]: chunk too short for UCFX header ({len(chunk_data)} bytes)")
            continue

        u0 = struct.unpack_from("<I", chunk_data, 4)[0]
        u1 = struct.unpack_from("<I", chunk_data, 8)[0]
        u2 = struct.unpack_from("<I", chunk_data, 12)[0]
        u3 = struct.unpack_from("<I", chunk_data, 16)[0]

        # Check CSUM trailer
        csum_body_end = csz - 8
        csum_tag = chunk_data[csum_body_end:csum_body_end + 4]
        if csum_tag != CSUM_TAG:
            errors.append(f"Entry [{idx}]: CSUM tag not at expected position "
                          f"(offset 0x{doff + csum_body_end:X}, got {csum_tag!r})")
            stored_csum = 0
            csum_ok = False
        else:
            stored_csum = struct.unpack_from("<I", chunk_data, csum_body_end + 4)[0]
            ucfx_body = chunk_data[:csum_body_end]
            computed_csum = crc32_mercs2(ucfx_body)
            csum_ok = stored_csum == computed_csum
            if not csum_ok:
                errors.append(f"Entry [{idx}]: CSUM mismatch: stored=0x{stored_csum:08X} "
                              f"computed=0x{computed_csum:08X}")

        # Parse descriptors
        n_desc = u2  # based on _build_ucfx_script_chunk convention: u2 = n_desc
        desc_area_start = 20
        desc_area_end = desc_area_start + n_desc * 20

        if desc_area_end > csum_body_end:
            errors.append(f"Entry [{idx}]: descriptor area extends beyond UCFX body: "
                          f"{desc_area_end} > {csum_body_end}")
            n_desc = 0

        tags = []
        desc_issues = []
        data_base_offset = 20 + n_desc * 20  # data area starts after UCFX header + descriptors

        for d in range(n_desc):
            doff_d = desc_area_start + d * 20
            dtag = chunk_data[doff_d:doff_d + 4].decode("ascii", errors="replace")
            d_u0, d_u1, d_u2, d_u3 = struct.unpack_from(
                "<IIII", chunk_data, doff_d + 4
            )
            tags.append(dtag)

            # d_u0 = offset within data area, d_u1 = body size
            body_start = data_base_offset + d_u0
            body_end_d = body_start + d_u1
            if body_end_d > csum_body_end:
                desc_issues.append(
                    f"desc [{d}] {dtag}: body extends beyond chunk "
                    f"(data_base+{d_u0}+{d_u1}={body_end_d} > {csum_body_end})"
                )

        for issue in desc_issues:
            errors.append(f"Entry [{idx}]: {issue}")

        # Show entry details for first 5 + last 3
        show = idx < 5 or idx >= entry_count - 3
        if show:
            status = "OK" if csum_ok else "BAD"
            print(f"\n  Entry [{idx}]: hash=0x{e['name_hash']:08X} type=0x{e['type_hash']:08X} "
                  f"size={csz:,}")
            print(f"    UCFX header: u0={u0} u1={u1} u2={u2} u3={u3}")
            print(f"    Descriptors ({n_desc}): {', '.join(tags)}")
            print(f"    CSUM: 0x{stored_csum:08X} [{status}]")

            # Check for DEPS
            if "DEPS" in tags:
                deps_idx = tags.index("DEPS")
                deps_doff = desc_area_start + deps_idx * 20
                deps_offset_val = struct.unpack_from("<I", chunk_data, deps_doff + 4)[0]
                deps_size_val = struct.unpack_from("<I", chunk_data, deps_doff + 8)[0]
                deps_body_start = data_base_offset + deps_offset_val
                deps_body = chunk_data[deps_body_start:deps_body_start + deps_size_val]
                print(f"    DEPS body ({deps_size_val} bytes): {deps_body.hex()}")

            # Check for BINN and try to get script name
            if "BINN" in tags:
                binn_idx = tags.index("BINN")
                binn_doff = desc_area_start + binn_idx * 20
                binn_offset_val = struct.unpack_from("<I", chunk_data, binn_doff + 4)[0]
                binn_size_val = struct.unpack_from("<I", chunk_data, binn_doff + 8)[0]
                binn_body_start = data_base_offset + binn_offset_val
                binn_body = chunk_data[binn_body_start:binn_body_start + min(binn_size_val, 64)]

                # Try to extract name from BINN
                if len(binn_body) >= 16 and binn_body[12] == 0x05:
                    name_len = struct.unpack_from("<H", binn_body, 13)[0]
                    name_start = 15
                    name_bytes = binn_body[name_start:name_start + name_len]
                    try:
                        script_name = name_bytes.decode("ascii")
                        print(f"    Script name: {script_name}")
                    except Exception:
                        print(f"    Script name bytes: {name_bytes.hex()}")

        # Check for DEPS corruption across ALL entries
        if "DEPS" in tags:
            deps_idx = tags.index("DEPS")
            deps_doff = desc_area_start + deps_idx * 20
            deps_offset_val = struct.unpack_from("<I", chunk_data, deps_doff + 4)[0]
            deps_size_val = struct.unpack_from("<I", chunk_data, deps_doff + 8)[0]
            deps_body_start = data_base_offset + deps_offset_val
            if deps_body_start + deps_size_val <= csum_body_end:
                deps_body = chunk_data[deps_body_start:deps_body_start + deps_size_val]
                if deps_size_val == 4:
                    deps_count = struct.unpack_from("<I", deps_body, 0)[0]
                    if deps_count != 0:
                        warnings.append(f"Entry [{idx}]: DEPS count={deps_count} (4-byte body, "
                                        f"expected 0 deps with no dep data)")
                elif deps_size_val > 4:
                    deps_count = struct.unpack_from("<I", deps_body, 0)[0]
                    expected_body = 4 + deps_count * 4
                    if expected_body != deps_size_val:
                        warnings.append(f"Entry [{idx}]: DEPS count={deps_count} but body size "
                                        f"{deps_size_val} != expected {expected_body}")
                elif deps_size_val < 4:
                    errors.append(f"Entry [{idx}]: DEPS body too small ({deps_size_val} < 4)")

    print(f"\n{'-'*70}")
    print("7. ASET vs BLOCK ENTRY CROSS-REFERENCE")
    print(f"{'-'*70}")

    block0_aset = [e for e in aset_entries if e["block_idx"] == 0]
    print(f"  ASET entries referencing block 0: {len(block0_aset)}")
    print(f"  Block entry count: {entry_count}")

    # Check sub_entry values
    sub_entries_used = set()
    for ae in block0_aset:
        sub = ae["sub_entry"]
        sub_entries_used.add(sub)

    # sub_entry = 0xFFFF is a special "primary" marker
    primary_refs = [e for e in block0_aset if e["sub_entry"] == 0xFFFF]
    indexed_refs = [e for e in block0_aset if e["sub_entry"] != 0xFFFF]
    print(f"  Primary references (sub=0xFFFF): {len(primary_refs)}")
    print(f"  Indexed references (sub!=0xFFFF): {len(indexed_refs)}")

    if indexed_refs:
        max_sub = max(e["sub_entry"] for e in indexed_refs)
        print(f"  Max sub_entry index: {max_sub}")
        if max_sub >= entry_count:
            errors.append(f"ASET sub_entry {max_sub} >= block entry_count {entry_count}")

    # Check ASET asset_hash matches block entry name_hash
    block_hashes = {e["name_hash"] for e in block_entries}
    aset_hashes = {e["asset_hash"] for e in block0_aset}
    in_aset_not_block = aset_hashes - block_hashes
    in_block_not_aset = block_hashes - aset_hashes

    if in_aset_not_block:
        print(f"\n  ASET hashes NOT in block entries ({len(in_aset_not_block)}):")
        for h in sorted(in_aset_not_block):
            print(f"    0x{h:08X}")
        # This might be OK for xref entries
    if in_block_not_aset:
        print(f"\n  Block hashes NOT in ASET ({len(in_block_not_aset)}):")
        for h in sorted(in_block_not_aset):
            print(f"    0x{h:08X}")
        warnings.append(f"{len(in_block_not_aset)} block entry hashes have no ASET row")

    if retail_block_path and retail_block_path.is_file():
        print(f"\n{'-'*70}")
        print("8. COMPARISON WITH RETAIL BLOCK")
        print(f"{'-'*70}")

        retail_data = retail_block_path.read_bytes()
        if retail_data[:4] == b"sges":
            retail_decomp = decompress_sges_block(retail_data, 0, len(retail_data))
        else:
            retail_decomp = retail_data

        if len(retail_decomp) >= 4:
            retail_count = struct.unpack_from("<I", retail_decomp, 0)[0]
            print(f"  Retail entry count: {retail_count}")
            print(f"  Patch entry count:  {entry_count}")

            # Compare first few entries
            compare_n = min(5, retail_count, entry_count)
            print(f"\n  First {compare_n} entries comparison:")
            print(f"  {'Idx':>4} {'Retail Hash':>12} {'Patch Hash':>12} {'R-Type':>12} "
                  f"{'P-Type':>12} {'R-Size':>8} {'P-Size':>8} {'R-FC':>6} {'P-FC':>6}")
            for i in range(compare_n):
                r_off = 4 + i * 16
                rh, rt, rfc, rs = struct.unpack_from("<IIII", retail_decomp, r_off)
                pe = block_entries[i]
                hash_match = "==" if rh == pe["name_hash"] else "!="
                print(f"  {i:4d} 0x{rh:08X} 0x{pe['name_hash']:08X} "
                      f"0x{rt:08X} 0x{pe['type_hash']:08X} "
                      f"{rs:8,} {pe['chunk_size']:8,} {rfc:6d} {pe['field_c']:6d} {hash_match}")

            # Compare UCFX structure of first retail entry
            r_header_end = 4 + retail_count * 16
            r_chunk0_data = retail_decomp[r_header_end:]
            if r_chunk0_data[:4] == UCFX_MAGIC and len(r_chunk0_data) >= 20:
                r_u0 = struct.unpack_from("<I", r_chunk0_data, 4)[0]
                r_u1 = struct.unpack_from("<I", r_chunk0_data, 8)[0]
                r_u2 = struct.unpack_from("<I", r_chunk0_data, 12)[0]
                r_u3 = struct.unpack_from("<I", r_chunk0_data, 16)[0]
                print(f"\n  Retail entry[0] UCFX header: u0={r_u0} u1={r_u1} u2={r_u2} u3={r_u3}")

                p_chunk0 = decompressed[header_end:]
                if p_chunk0[:4] == UCFX_MAGIC and len(p_chunk0) >= 20:
                    p_u0 = struct.unpack_from("<I", p_chunk0, 4)[0]
                    p_u1 = struct.unpack_from("<I", p_chunk0, 8)[0]
                    p_u2 = struct.unpack_from("<I", p_chunk0, 12)[0]
                    p_u3 = struct.unpack_from("<I", p_chunk0, 16)[0]
                    print(f"  Patch  entry[0] UCFX header: u0={p_u0} u1={p_u1} u2={p_u2} u3={p_u3}")

                    if r_u0 != p_u0:
                        warnings.append(f"Entry[0] UCFX u0 differs: retail={r_u0} patch={p_u0}")
                    if r_u3 != p_u3:
                        warnings.append(f"Entry[0] UCFX u3 differs: retail={r_u3} patch={p_u3}")

                # Show retail descriptors
                r_n_desc = r_u2
                print(f"\n  Retail entry[0] descriptors ({r_n_desc}):")
                for d in range(r_n_desc):
                    doff = 20 + d * 20
                    dtag = r_chunk0_data[doff:doff+4].decode("ascii", errors="replace")
                    d0, d1, d2, d3 = struct.unpack_from("<IIII", r_chunk0_data, doff + 4)
                    print(f"    [{d}] {dtag}: offset={d0} size={d1} u2={d2} u3={d3}")

    print(f"\n{'-'*70}")
    print("9. PTHS")
    print(f"{'-'*70}")

    pths_off, pths_count = chunks["PTHS"]
    print(f"  Offset: 0x{pths_off:X}, Count: {pths_count}")

    pths_region = raw[pths_off:]
    pos = 0
    path_strings = []
    for _ in range(pths_count):
        nul = pths_region.find(b"\x00", pos)
        if nul < 0:
            break
        s = pths_region[pos:nul].decode("utf-8", errors="replace")
        path_strings.append(s)
        pos = nul + 1

    for i, s in enumerate(path_strings):
        print(f"    [{i}] \"{s}\"")

    # Check for PTHS trailer
    trailer = (b"xa37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2"
               b"b8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312"
               b"a4f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd9"
               b"9baacc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23"
               b"d4ex")
    trailer_pos = raw.find(trailer, pths_off)
    if trailer_pos >= 0:
        print(f"  PTHS trailer: PRESENT at offset 0x{trailer_pos:X}")
    else:
        errors.append("PTHS trailer marker MISSING")

    print(f"\n{'-'*70}")
    print("10. HEX DUMP OF FIRST ENTRY'S UCFX (first 256 bytes)")
    print(f"{'-'*70}")

    if block_entries:
        e0 = block_entries[0]
        chunk0 = decompressed[e0["data_offset"]:e0["data_offset"] + min(e0["chunk_size"], 256)]
        for row in range(0, len(chunk0), 16):
            hex_part = " ".join(f"{chunk0[row+i]:02X}" if row+i < len(chunk0) else "  "
                                for i in range(16))
            ascii_part = "".join(chr(chunk0[row+i]) if 32 <= chunk0[row+i] < 127 else "."
                                 for i in range(16) if row+i < len(chunk0))
            print(f"  {row:04X}: {hex_part}  {ascii_part}")

    return _report(errors, warnings)


def _report(errors: list[str], warnings: list[str]) -> int:
    print(f"\n{'='*70}")
    print("DIAGNOSTIC SUMMARY")
    print(f"{'='*70}")

    if warnings:
        print(f"\nWARNINGS ({len(warnings)}):")
        for i, w in enumerate(warnings, 1):
            print(f"  {i}. {w}")

    if errors:
        print(f"\nERRORS ({len(errors)}):")
        for i, e in enumerate(errors, 1):
            print(f"  {i}. {e}")
        print(f"\nRESULT: FAIL ({len(errors)} error(s), {len(warnings)} warning(s))")
        return 1

    print(f"\nRESULT: PASS ({len(warnings)} warning(s))")
    return 0


if __name__ == "__main__":
    import argparse
    ap = argparse.ArgumentParser(description="Diagnose patch WAD structural issues")
    ap.add_argument("wad", type=Path, help="Path to vz-patch.wad")
    ap.add_argument("--retail-block", type=Path, default=None,
                    help="Path to retail scripts_vz block for comparison")
    args = ap.parse_args()
    sys.exit(diagnose(args.wad, retail_block_path=args.retail_block))
