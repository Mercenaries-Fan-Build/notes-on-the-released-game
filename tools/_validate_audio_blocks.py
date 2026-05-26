#!/usr/bin/env python3
"""Validate audio UCFX entries in the output patch WAD.

Decompresses each block, finds wavebank/soundbank entries, and checks:
1. Entry-table sizes match actual UCFX container sizes
2. UCFX descriptor offsets don't overlap after body conversion
3. Wavebank/soundbank header fields are structurally sane
4. Compare PC-converted wavebank format against base game wavebank format
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block

_TYPE_WAVEBANK = 0xF753F6D0
_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_UNKNOWN_E5 = 0xE5273C14
_AUDIO_HASHES = {_TYPE_WAVEBANK, _TYPE_SOUNDBANK, _TYPE_UNKNOWN_E5}
_TYPE_NAMES = {
    _TYPE_WAVEBANK: "wavebank",
    _TYPE_SOUNDBANK: "soundbank",
    _TYPE_UNKNOWN_E5: "audio_group",
}


def parse_ffcs_header(raw):
    magic = raw[:4]
    assert magic == b"FFCS", f"Bad magic: {magic!r}"
    chunks = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off:off+4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off+4)[0]
        meta = struct.unpack_from("<I", raw, off+8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)
    return chunks


def parse_indx_entries(raw, indx_off, num_blocks):
    """Parse INDX entries: (page_index, packed_field, flags_pages) per block."""
    entries = []
    for i in range(num_blocks):
        off = indx_off + i * 12
        page_idx = struct.unpack_from("<I", raw, off)[0]
        packed = struct.unpack_from("<I", raw, off+4)[0]
        flags_pages = struct.unpack_from("<I", raw, off+8)[0]
        page_count = flags_pages & 0xFFFF
        flags = (flags_pages >> 16) & 0xFFFF
        entries.append({
            "page_idx": page_idx,
            "packed": packed,
            "page_count": page_count,
            "flags": flags,
        })
    return entries


PAGE_SIZE = 0x8000  # 32 KB (FFCS page)


def validate_ucfx_container(ucfx_data, label):
    """Check UCFX container internal consistency. Returns list of issues."""
    issues = []
    if len(ucfx_data) < 20:
        issues.append(f"  {label}: UCFX too short ({len(ucfx_data)} bytes)")
        return issues

    magic = ucfx_data[:4]
    if magic != b"UCFX":
        issues.append(f"  {label}: Bad magic {magic!r}")
        return issues

    data_area_off = struct.unpack_from("<I", ucfx_data, 4)[0]
    n_desc = struct.unpack_from("<I", ucfx_data, 16)[0]

    if n_desc > 50000:
        issues.append(f"  {label}: Implausible descriptor count {n_desc}")
        return issues

    descriptors = []
    for i in range(n_desc):
        row_off = 20 + i * 20
        if row_off + 20 > len(ucfx_data):
            issues.append(f"  {label}: Descriptor {i} extends past UCFX")
            break
        tag = ucfx_data[row_off:row_off+4].decode("ascii", errors="replace")
        u0, body_size, f3, f4 = struct.unpack_from("<IIII", ucfx_data, row_off+4)
        descriptors.append((tag, u0, body_size, f3, f4))

    for i, (tag, u0, body_size, f3, f4) in enumerate(descriptors):
        if u0 == 0xFFFFFFFF:
            continue
        body_start = (data_area_off + u0) if data_area_off > 0 else (8 + u0)
        body_end = body_start + body_size
        if body_end > len(ucfx_data):
            issues.append(
                f"  {label}: Descriptor {i} ({tag}) body "
                f"[{body_start}:{body_end}] exceeds container ({len(ucfx_data)} bytes)")

    # Check for body overlaps
    bodies = []
    for i, (tag, u0, body_size, f3, f4) in enumerate(descriptors):
        if u0 == 0xFFFFFFFF:
            continue
        bodies.append((u0, body_size, i, tag))
    bodies.sort()
    for j in range(len(bodies) - 1):
        u0_a, sz_a, idx_a, tag_a = bodies[j]
        u0_b, sz_b, idx_b, tag_b = bodies[j+1]
        if u0_a + sz_a > u0_b:
            overlap = u0_a + sz_a - u0_b
            issues.append(
                f"  {label}: OVERLAP desc {idx_a} ({tag_a}, off={u0_a}, sz={sz_a}) "
                f"overlaps desc {idx_b} ({tag_b}, off={u0_b}) by {overlap} bytes!")

    return issues


def validate_wavebank_body(body, label):
    """Validate a PC wavebank data body. Returns list of issues."""
    issues = []
    if len(body) < 24:
        issues.append(f"  {label}: wavebank body too short ({len(body)} bytes)")
        return issues

    count = struct.unpack_from("<I", body, 0)[0]
    self_hash = struct.unpack_from("<I", body, 4)[0]
    flags = struct.unpack_from("<H", body, 8)[0]
    more_flags = struct.unpack_from("<H", body, 10)[0]
    self_hash2 = struct.unpack_from("<I", body, 12)[0]
    records_offset = struct.unpack_from("<I", body, 16)[0]

    print(f"  {label}: count={count} self_hash=0x{self_hash:08X} "
          f"flags=0x{flags:04X} more_flags=0x{more_flags:04X} "
          f"self_hash2=0x{self_hash2:08X} records_offset={records_offset}")

    if count > 100000:
        issues.append(f"  {label}: IMPLAUSIBLE COUNT {count} (possibly wrong endianness!)")
        be_count = struct.unpack_from(">I", body, 0)[0]
        issues.append(f"    Count as BE would be: {be_count}")
        return issues

    if records_offset > len(body):
        issues.append(f"  {label}: records_offset {records_offset} > body size {len(body)}")
        return issues

    expected_end = records_offset + count * 36
    if expected_end > len(body):
        issues.append(
            f"  {label}: Records extend past body "
            f"(records_offset={records_offset} + count={count} * 36 = {expected_end} > {len(body)})")
        return issues

    for i in range(min(count, 10)):
        roff = records_offset + i * 36
        if roff + 36 > len(body):
            break
        clip_hash = struct.unpack_from("<I", body, roff)[0]
        fmt_bytes = body[roff+4:roff+8]
        sample_rate = struct.unpack_from("<I", body, roff+8)[0]
        data_offset = struct.unpack_from("<I", body, roff+12)[0]
        data_size = struct.unpack_from("<I", body, roff+16)[0]
        extra = struct.unpack_from("<4I", body, roff+20)

        codec = fmt_bytes[2]
        channels = fmt_bytes[1]

        # Empty preallocated slots (all zeros) are normal
        is_empty = (clip_hash == 0 and sample_rate == 0 and data_size == 0)

        if not is_empty:
            if sample_rate == 0 or sample_rate > 192000:
                issues.append(
                    f"  {label}: Record {i}: implausible sample_rate {sample_rate}")
            if codec not in (0x01, 0x02, 0x03, 0x05, 0x11, 0x69):
                issues.append(
                    f"  {label}: Record {i}: unusual codec 0x{codec:02X}")
            if channels == 0 or channels > 8:
                issues.append(
                    f"  {label}: Record {i}: implausible channels {channels}")

        print(f"    Record {i}: hash=0x{clip_hash:08X} ch={channels} "
              f"codec=0x{codec:02X} rate={sample_rate} "
              f"data_off={data_offset} data_sz={data_size} extra={extra}")

    return issues


def validate_soundbank_body(body, label):
    """Validate a PC soundbank data body. Returns list of issues."""
    issues = []
    if len(body) < 16:
        issues.append(f"  {label}: soundbank body too short ({len(body)} bytes)")
        return issues

    count = struct.unpack_from("<I", body, 0)[0]
    self_hash = struct.unpack_from("<I", body, 4)[0]
    flags = struct.unpack_from("<I", body, 8)[0]
    self_hash2 = struct.unpack_from("<I", body, 12)[0]

    print(f"  {label}: count={count} self_hash=0x{self_hash:08X} "
          f"flags=0x{flags:08X} self_hash2=0x{self_hash2:08X}")

    if count > 100000:
        issues.append(f"  {label}: IMPLAUSIBLE COUNT {count} (possibly wrong endianness!)")
        be_count = struct.unpack_from(">I", body, 0)[0]
        issues.append(f"    Count as BE would be: {be_count}")
        return issues

    if len(body) >= 20:
        data_start = struct.unpack_from("<I", body, 16)[0]
        print(f"    data_start={data_start} body_size={len(body)}")
        if data_start > len(body):
            issues.append(f"  {label}: data_start {data_start} > body size {len(body)}")

    return issues


def decompress_block(raw, indx_entry, data_offset):
    """Decompress a single block from the WAD."""
    block_offset = indx_entry["page_idx"] * PAGE_SIZE
    block_size = indx_entry["page_count"] * PAGE_SIZE
    if block_offset + block_size > len(raw):
        block_size = len(raw) - block_offset
    compressed = raw[block_offset:block_offset + block_size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def main():
    wad_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("output/data/vz-patch.wad")
    raw = wad_path.read_bytes()

    chunks = parse_ffcs_header(raw)
    indx_off, num_blocks = chunks["INDX"]
    aset_off, aset_count = chunks["ASET"]
    pths_off, pths_count = chunks["PTHS"]
    data_off = chunks["DATA"][0]

    indx_entries = parse_indx_entries(raw, indx_off, num_blocks)

    # Parse paths
    paths = []
    pos = pths_off
    for _ in range(pths_count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1

    # Parse ASET to find audio entries
    AUDIO_TYPE_IDS = {6: "wavebank", 21: "soundbank", 5: "audio_group"}
    audio_block_indices = set()
    audio_aset_by_block: dict[int, list] = {}

    for i in range(aset_count):
        off = aset_off + i * 16
        asset_hash, u1, u2, type_id = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if type_id in AUDIO_TYPE_IDS:
            audio_block_indices.add(block_idx)
            audio_aset_by_block.setdefault(block_idx, []).append({
                "hash": asset_hash, "u1": u1, "type_id": type_id,
                "type_name": AUDIO_TYPE_IDS[type_id],
            })

    print(f"WAD: {num_blocks} blocks, {aset_count} ASET entries")
    print(f"Audio ASET entries span {len(audio_block_indices)} blocks: "
          f"{sorted(audio_block_indices)}")

    all_issues = []

    for blk_idx in sorted(audio_block_indices):
        if blk_idx >= num_blocks:
            all_issues.append(f"Block {blk_idx}: index out of range ({num_blocks} blocks)")
            continue

        blk_name = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx}"
        print(f"\n{'='*60}")
        print(f"Block {blk_idx}: {blk_name}")

        try:
            decompressed = decompress_block(raw, indx_entries[blk_idx], data_off)
        except Exception as e:
            all_issues.append(f"Block {blk_idx}: decompression failed: {e}")
            continue

        if decompressed is None:
            all_issues.append(f"Block {blk_idx}: not sges or empty")
            continue

        print(f"  Decompressed: {len(decompressed):,} bytes")

        entry_count = struct.unpack_from("<I", decompressed, 0)[0]
        print(f"  Entries: {entry_count}")
        header_end = 4 + entry_count * 16

        pos = header_end
        for i in range(entry_count):
            eoff = 4 + i * 16
            h, th, _o, sz = struct.unpack_from("<IIII", decompressed, eoff)

            type_name = _TYPE_NAMES.get(th, f"0x{th:08X}")
            is_audio = th in _AUDIO_HASHES

            if is_audio:
                entry_end = pos + sz
                print(f"\n  Entry {i}: hash=0x{h:08X} type={type_name} "
                      f"size={sz:,} offset={pos}")

                if entry_end > len(decompressed):
                    all_issues.append(
                        f"Block {blk_idx} entry {i}: "
                        f"extends past block ({entry_end} > {len(decompressed)})")
                    pos = entry_end
                    continue

                container = decompressed[pos:entry_end]

                # Strip CSUM trailer
                if len(container) >= 8 and container[-8:-4] == b"CSUM":
                    container_no_csum = container[:-8]
                else:
                    container_no_csum = container

                label = f"Block {blk_idx} entry {i} ({type_name})"
                issues = validate_ucfx_container(container_no_csum, label)
                all_issues.extend(issues)

                # Find and validate the data chunk body
                if container_no_csum[:4] == b"UCFX":
                    ucfx_data_off = struct.unpack_from("<I", container_no_csum, 4)[0]
                    n_desc = struct.unpack_from("<I", container_no_csum, 16)[0]

                    print(f"    UCFX: data_area_off={ucfx_data_off} n_desc={n_desc}")
                    for d in range(n_desc):
                        doff = 20 + d * 20
                        if doff + 20 > len(container_no_csum):
                            break
                        dtag = container_no_csum[doff:doff+4].decode(
                            "ascii", errors="replace")
                        du0 = struct.unpack_from("<I", container_no_csum, doff+4)[0]
                        dsz = struct.unpack_from("<I", container_no_csum, doff+8)[0]
                        df3 = struct.unpack_from("<I", container_no_csum, doff+12)[0]
                        df4 = struct.unpack_from("<I", container_no_csum, doff+16)[0]

                        if du0 == 0xFFFFFFFF:
                            print(f"    desc {d}: {dtag} SENTINEL sz={dsz}")
                        else:
                            print(f"    desc {d}: {dtag} off={du0} sz={dsz} "
                                  f"f3=0x{df3:08X} f4=0x{df4:08X}")

                        if dtag == "data" and du0 != 0xFFFFFFFF:
                            body_start = ucfx_data_off + du0
                            body_end_d = body_start + dsz
                            if body_end_d > len(container_no_csum):
                                all_issues.append(
                                    f"  {label}: data body [{body_start}:{body_end_d}] "
                                    f"exceeds UCFX ({len(container_no_csum)})")
                                continue
                            body_data = container_no_csum[body_start:body_end_d]
                            if th == _TYPE_WAVEBANK:
                                issues2 = validate_wavebank_body(body_data, label)
                                all_issues.extend(issues2)
                            elif th == _TYPE_SOUNDBANK:
                                issues2 = validate_soundbank_body(body_data, label)
                                all_issues.extend(issues2)

            pos += sz

    # Also validate one base game wavebank for format comparison
    print(f"\n{'='*60}")
    print("COMPARING WITH BASE GAME WAVEBANK FORMAT")
    print("="*60)

    base_path = Path("game-files/vz.wad")
    if base_path.exists():
        base_raw = base_path.read_bytes()
        base_chunks = parse_ffcs_header(base_raw)
        base_indx = parse_indx_entries(
            base_raw, base_chunks["INDX"][0], base_chunks["INDX"][1])
        base_aset_off = base_chunks["ASET"][0]
        base_aset_count = base_chunks["ASET"][1]
        base_data_off = base_chunks["DATA"][0]

        for i in range(base_aset_count):
            off = base_aset_off + i * 16
            _, _, u2, type_id = struct.unpack_from("<IIII", base_raw, off)
            if type_id == 6:
                block_idx = (u2 >> 16) & 0xFFFF
                if block_idx >= len(base_indx):
                    continue
                print(f"\nBase wavebank: block {block_idx}")
                try:
                    base_decomp = decompress_block(
                        base_raw, base_indx[block_idx], base_data_off)
                except Exception as e:
                    print(f"  Decompress failed: {e}")
                    break
                if base_decomp is None:
                    print("  Not sges")
                    break

                ec = struct.unpack_from("<I", base_decomp, 0)[0]
                bpos = 4 + ec * 16
                for j in range(ec):
                    beoff = 4 + j * 16
                    bh, bth, _, bsz = struct.unpack_from("<IIII", base_decomp, beoff)
                    if bth == _TYPE_WAVEBANK:
                        container = base_decomp[bpos:bpos+bsz]
                        if len(container) >= 8 and container[-8:-4] == b"CSUM":
                            container = container[:-8]
                        if container[:4] == b"UCFX":
                            ucfx_d = struct.unpack_from("<I", container, 4)[0]
                            n = struct.unpack_from("<I", container, 16)[0]
                            for dd in range(n):
                                ddoff = 20 + dd * 20
                                dtag = container[ddoff:ddoff+4].decode(
                                    "ascii", errors="replace")
                                du0 = struct.unpack_from("<I", container, ddoff+4)[0]
                                dsz = struct.unpack_from("<I", container, ddoff+8)[0]
                                print(f"  desc {dd}: {dtag} off={du0} sz={dsz}")
                                if dtag == "data" and du0 != 0xFFFFFFFF:
                                    bd_start = ucfx_d + du0
                                    bd = container[bd_start:bd_start+dsz]
                                    validate_wavebank_body(
                                        bd, f"BASE block {block_idx}")
                        break
                    bpos += bsz
                break

    print(f"\n{'='*60}")
    print("VALIDATION SUMMARY")
    print("="*60)
    if all_issues:
        print(f"\n*** {len(all_issues)} ISSUE(S) FOUND ***\n")
        for issue in all_issues:
            print(issue)
    else:
        print("\n  All audio blocks validated OK")

    return 1 if all_issues else 0


if __name__ == "__main__":
    sys.exit(main())
