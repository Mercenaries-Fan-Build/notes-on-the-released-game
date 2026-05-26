#!/usr/bin/env python3
"""Compare base game PC soundbank/wavebank format against DLC converter output.

Dumps raw bytes of soundbank/wavebank data bodies from both the base game
and the DLC patch WAD side by side to identify format mismatches.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block

PAGE_SIZE = 0x8000
_TYPE_WAVEBANK = 0xF753F6D0
_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_UNKNOWN_E5 = 0xE5273C14


def parse_ffcs(raw):
    chunks = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off:off+4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off+4)[0]
        meta = struct.unpack_from("<I", raw, off+8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)
    return chunks


def parse_indx(raw, off, n):
    entries = []
    for i in range(n):
        o = off + i * 12
        pi = struct.unpack_from("<I", raw, o)[0]
        pk = struct.unpack_from("<I", raw, o+4)[0]
        fp = struct.unpack_from("<I", raw, o+8)[0]
        entries.append({"page_idx": pi, "packed": pk,
                        "page_count": fp & 0xFFFF, "flags": (fp >> 16) & 0xFFFF})
    return entries


def decompress_block(raw, indx_entry):
    offset = indx_entry["page_idx"] * PAGE_SIZE
    size = indx_entry["page_count"] * PAGE_SIZE
    compressed = raw[offset:offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def find_audio_entries(decomp, target_type):
    """Find entries of a specific type_hash in a decompressed block."""
    entry_count = struct.unpack_from("<I", decomp, 0)[0]
    results = []
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        eoff = 4 + i * 16
        h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th == target_type:
            container = decomp[pos:pos + sz]
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                container = container[:-8]
            if container[:4] == b"UCFX":
                ucfx_data_off = struct.unpack_from("<I", container, 4)[0]
                n_desc = struct.unpack_from("<I", container, 16)[0]
                for d in range(n_desc):
                    doff = 20 + d * 20
                    dtag = container[doff:doff+4].decode("ascii", errors="replace")
                    du0 = struct.unpack_from("<I", container, doff+4)[0]
                    dsz = struct.unpack_from("<I", container, doff+8)[0]
                    if dtag == "data" and du0 != 0xFFFFFFFF:
                        body_start = ucfx_data_off + du0
                        body = container[body_start:body_start+dsz]
                        results.append({
                            "hash": h, "entry_idx": i, "body": body,
                            "body_size": dsz,
                        })
        pos += sz
    return results


def hexdump(data, offset=0, length=None):
    if length:
        data = data[:length]
    lines = []
    for i in range(0, len(data), 16):
        chunk = data[i:i+16]
        hexstr = " ".join(f"{b:02x}" for b in chunk)
        ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
        lines.append(f"  {offset+i:04x}: {hexstr:<48s} {ascii_str}")
    return "\n".join(lines)


def analyze_soundbank(body, label):
    """Analyze a soundbank body at the byte level."""
    print(f"\n{'='*60}")
    print(f"SOUNDBANK: {label}")
    print(f"Body size: {len(body):,} bytes")
    print(f"\nFirst 64 bytes (raw hex):")
    print(hexdump(body, length=64))

    # Try different interpretations of the first 16-20 bytes
    print(f"\nField interpretations:")
    for i in range(0, min(32, len(body)), 4):
        le = struct.unpack_from("<I", body, i)[0]
        be = struct.unpack_from(">I", body, i)[0]
        le_h = struct.unpack_from("<HH", body, i)
        print(f"  [{i:2d}:{i+4:2d}] LE=0x{le:08X} ({le:12d})  "
              f"BE=0x{be:08X} ({be:12d})  "
              f"u16 LE=({le_h[0]:5d}, {le_h[1]:5d})")

    # Try to guess record size by looking at the body
    le_count = struct.unpack_from("<I", body, 0)[0]
    be_count = struct.unpack_from(">I", body, 0)[0]
    print(f"\n  Count as LE: {le_count}")
    print(f"  Count as BE: {be_count}")

    # If count is reasonable, try to determine record size
    count = le_count if le_count < 10000 else (be_count if be_count < 10000 else 0)
    if count > 0 and count < 10000:
        for header_candidates in range(12, 100, 4):
            records_area = len(body) - header_candidates
            if records_area <= 0:
                continue
            if records_area % count == 0:
                rec_size = records_area // count
                if 4 <= rec_size <= 200:
                    print(f"  If header={header_candidates}: record_size = "
                          f"{records_area} / {count} = {rec_size}")


def analyze_wavebank(body, label):
    """Analyze a wavebank body at the byte level."""
    print(f"\n{'='*60}")
    print(f"WAVEBANK: {label}")
    print(f"Body size: {len(body):,} bytes")
    print(f"\nFirst 64 bytes (raw hex):")
    print(hexdump(body, length=64))

    print(f"\nField interpretations:")
    for i in range(0, min(32, len(body)), 4):
        le = struct.unpack_from("<I", body, i)[0]
        be = struct.unpack_from(">I", body, i)[0]
        le_h = struct.unpack_from("<HH", body, i)
        print(f"  [{i:2d}:{i+4:2d}] LE=0x{le:08X} ({le:12d})  "
              f"BE=0x{be:08X} ({be:12d})  "
              f"u16 LE=({le_h[0]:5d}, {le_h[1]:5d})")

    count = struct.unpack_from("<I", body, 0)[0]
    rec_off = struct.unpack_from("<I", body, 16)[0]
    print(f"\n  Count (LE): {count}")
    print(f"  records_offset (LE): {rec_off}")

    if count > 0 and count < 10000 and rec_off < len(body):
        remaining = len(body) - rec_off
        if remaining > 0:
            # Try different record sizes
            for rs in [24, 28, 32, 36, 40, 44, 48]:
                if remaining >= count * rs:
                    print(f"  If record_size={rs}: records use {count*rs} of "
                          f"{remaining} bytes ({remaining - count*rs} trailing)")

            # Dump first few records at offset rec_off
            print(f"\n  First 3 records at offset {rec_off}:")
            for rec_sizes in [36, 40]:
                print(f"    Record size = {rec_sizes}:")
                for r in range(min(3, count)):
                    roff = rec_off + r * rec_sizes
                    if roff + rec_sizes <= len(body):
                        rec_hex = body[roff:roff+rec_sizes].hex()
                        clip_hash = struct.unpack_from("<I", body, roff)[0]
                        fmt = body[roff+4:roff+8]
                        sr = struct.unpack_from("<I", body, roff+8)[0]
                        doff = struct.unpack_from("<I", body, roff+12)[0]
                        dsz = struct.unpack_from("<I", body, roff+16)[0]
                        print(f"      [{r}] hash=0x{clip_hash:08X} fmt={fmt.hex()} "
                              f"rate={sr} doff={doff} dsz={dsz}")


def main():
    base_path = Path("game-files/vz.wad")
    patch_path = Path("output/data/vz-patch.wad")

    if not base_path.exists():
        print(f"Base game WAD not found: {base_path}")
        return 1

    base_raw = base_path.read_bytes()
    base_chunks = parse_ffcs(base_raw)
    base_indx = parse_indx(base_raw, base_chunks["INDX"][0], base_chunks["INDX"][1])
    base_aset_off = base_chunks["ASET"][0]
    base_aset_count = base_chunks["ASET"][1]

    # Find a base game soundbank
    print("Searching for base game soundbank entries...")
    soundbank_found = False
    wavebank_found = False

    for i in range(base_aset_count):
        off = base_aset_off + i * 16
        ah, _, u2, type_id = struct.unpack_from("<IIII", base_raw, off)
        block_idx = (u2 >> 16) & 0xFFFF

        if not soundbank_found and type_id == 21:  # soundbank
            print(f"\nBase game soundbank: ASET entry {i}, "
                  f"hash=0x{ah:08X}, block={block_idx}")
            if block_idx < len(base_indx):
                decomp = decompress_block(base_raw, base_indx[block_idx])
                if decomp:
                    entries = find_audio_entries(decomp, _TYPE_SOUNDBANK)
                    for e in entries[:1]:
                        analyze_soundbank(e["body"],
                                          f"BASE game block {block_idx}")
                        soundbank_found = True

        if not wavebank_found and type_id == 6:  # wavebank
            print(f"\nBase game wavebank: ASET entry {i}, "
                  f"hash=0x{ah:08X}, block={block_idx}")
            if block_idx < len(base_indx):
                decomp = decompress_block(base_raw, base_indx[block_idx])
                if decomp:
                    entries = find_audio_entries(decomp, _TYPE_WAVEBANK)
                    for e in entries[:1]:
                        analyze_wavebank(e["body"],
                                         f"BASE game block {block_idx}")
                        wavebank_found = True

        if soundbank_found and wavebank_found:
            break

    # Now analyze DLC soundbank/wavebank
    if patch_path.exists():
        patch_raw = patch_path.read_bytes()
        patch_chunks = parse_ffcs(patch_raw)
        patch_indx = parse_indx(patch_raw, patch_chunks["INDX"][0],
                                 patch_chunks["INDX"][1])

        # Block 203 has a soundbank entry
        for blk_idx in [203, 343]:
            if blk_idx < len(patch_indx):
                decomp = decompress_block(patch_raw, patch_indx[blk_idx])
                if decomp:
                    sb_entries = find_audio_entries(decomp, _TYPE_SOUNDBANK)
                    for e in sb_entries[:1]:
                        analyze_soundbank(e["body"],
                                          f"DLC block {blk_idx}")

                    wb_entries = find_audio_entries(decomp, _TYPE_WAVEBANK)
                    for e in wb_entries[:1]:
                        analyze_wavebank(e["body"],
                                         f"DLC block {blk_idx}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
