#!/usr/bin/env python3
"""Check the codec bytes in DLC wavebank entries.

Determines if DLC uses XMA or some other codec that the wavebank
converter doesn't handle, which would pass through unchanged and
crash PalSoundEngine.
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

_CODEC_NAMES = {
    0x00: "PCM/silence",
    0x01: "XMA",
    0x02: "IMA_ADPCM (PC)",
    0x03: "ADPCM",
    0x04: "WMA",
    0x05: "XBOX_ADPCM",
    0x06: "OGG_VORBIS",
    0x69: "XMA2",
}


def parse_ffcs(raw: bytes) -> dict:
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(7):
        off = 0x0C + i * 12
        tag = raw[off:off + 4].decode("ascii", errors="replace")
        offset = struct.unpack_from("<I", raw, off + 4)[0]
        meta = struct.unpack_from("<I", raw, off + 8)[0]
        if tag.strip("\x00"):
            chunks[tag] = (offset, meta)
    return chunks


def parse_indx(raw: bytes, off: int, n: int) -> list[dict]:
    entries = []
    for i in range(n):
        o = off + i * 12
        pi = struct.unpack_from("<I", raw, o)[0]
        pk = struct.unpack_from("<I", raw, o + 4)[0]
        fp = struct.unpack_from("<I", raw, o + 8)[0]
        entries.append({
            "page_idx": pi, "packed": pk,
            "page_count": fp & 0xFFFF, "flags": (fp >> 16) & 0xFFFF,
        })
    return entries


def decompress_block(raw: bytes, entry: dict) -> bytes | None:
    offset = entry["page_idx"] * PAGE_SIZE
    size = entry["page_count"] * PAGE_SIZE
    compressed = raw[offset:offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def analyze_wavebank(decomp: bytes, blk_idx: int, endian: str = "le"):
    """Analyze wavebank entries in a decompressed block."""
    entry_count = struct.unpack_from("<I", decomp, 0)[0]
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        eoff = 4 + i * 16
        h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th == _TYPE_WAVEBANK:
            container = decomp[pos:pos + sz]
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                container = container[:-8]
            if container[:4] == b"UCFX":
                ucfx_data_off = struct.unpack_from("<I", container, 4)[0]
                n_desc = struct.unpack_from("<I", container, 16)[0]
                for d in range(n_desc):
                    doff = 20 + d * 20
                    dtag = container[doff:doff + 4].decode("ascii", errors="replace")
                    du0 = struct.unpack_from("<I", container, doff + 4)[0]
                    dsz = struct.unpack_from("<I", container, doff + 8)[0]
                    if dtag == "data" and du0 != 0xFFFFFFFF:
                        body_start = ucfx_data_off + du0
                        body = container[body_start:body_start + dsz]
                        analyze_wavebank_body(body, h, blk_idx, endian)
        pos += sz


def analyze_wavebank_body(body: bytes, entry_hash: int, blk_idx: int,
                          endian: str):
    """Parse wavebank header and dump record codec info."""
    if len(body) < 24:
        return

    fmt = "<" if endian == "le" else ">"
    count = struct.unpack_from("<I", body, 0)[0]  # count is always LE
    self_hash = struct.unpack_from(f"{fmt}I", body, 4)[0]
    flags = struct.unpack_from(f"{fmt}H", body, 8)[0]
    more_flags = struct.unpack_from(f"{fmt}H", body, 10)[0]
    self_hash2 = struct.unpack_from(f"{fmt}I", body, 12)[0]
    records_off = struct.unpack_from(f"{fmt}I", body, 16)[0]

    print(f"\n  Block {blk_idx} | wavebank 0x{entry_hash:08X} | "
          f"body_size={len(body):,} | endian={endian}")
    print(f"    count={count}, self_hash=0x{self_hash:08X}, "
          f"flags=({flags},{more_flags}), records_off={records_off}")

    if records_off + count * 36 > len(body):
        print(f"    ⚠ Records would extend past body end!")
        print(f"      Expected end: {records_off + count * 36}, body_size: {len(body)}")
        # Try interpreting differently
        if endian == "le":
            alt_count = struct.unpack_from(">I", body, 0)[0]
            alt_records_off = struct.unpack_from(">I", body, 16)[0]
            print(f"    [BE interpretation: count={alt_count}, records_off={alt_records_off}]")
        return

    print(f"    Records ({count} × 36 bytes starting at offset {records_off}):")
    for r in range(min(count, 10)):
        roff = records_off + r * 36
        clip_hash = struct.unpack_from(f"{fmt}I", body, roff)[0]
        fmt_bytes = body[roff + 4:roff + 8]
        sample_rate = struct.unpack_from(f"{fmt}I", body, roff + 8)[0]
        data_offset = struct.unpack_from(f"{fmt}I", body, roff + 12)[0]
        data_size = struct.unpack_from(f"{fmt}I", body, roff + 16)[0]

        codec = fmt_bytes[2]
        channels = fmt_bytes[1]
        codec_name = _CODEC_NAMES.get(codec, f"UNKNOWN(0x{codec:02X})")

        print(f"    [{r:2d}] clip=0x{clip_hash:08X} codec={codec}({codec_name}) "
              f"ch={channels} rate={sample_rate} "
              f"offset={data_offset} size={data_size:,}")
        print(f"         fmt_bytes={fmt_bytes.hex()} "
              f"[{fmt_bytes[0]:02x} {fmt_bytes[1]:02x} "
              f"{fmt_bytes[2]:02x} {fmt_bytes[3]:02x}]")

    if count > 10:
        print(f"    ... ({count - 10} more records)")

    # Collect unique codec values
    codecs = set()
    for r in range(count):
        roff = records_off + r * 36
        if roff + 8 <= len(body):
            codecs.add(body[roff + 6])  # codec is at record+6 (fmt_bytes[2])
    print(f"    Unique codecs in this wavebank: {sorted(codecs)} "
          f"= {[_CODEC_NAMES.get(c, f'0x{c:02X}') for c in sorted(codecs)]}")


def analyze_soundbank_header(decomp: bytes, blk_idx: int, endian: str = "le"):
    """Dump soundbank header info for comparison."""
    entry_count = struct.unpack_from("<I", decomp, 0)[0]
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        eoff = 4 + i * 16
        h, th, o, sz = struct.unpack_from("<IIII", decomp, eoff)
        if th == _TYPE_SOUNDBANK:
            container = decomp[pos:pos + sz]
            if len(container) >= 8 and container[-8:-4] == b"CSUM":
                container = container[:-8]
            if container[:4] == b"UCFX":
                ucfx_data_off = struct.unpack_from("<I", container, 4)[0]
                n_desc = struct.unpack_from("<I", container, 16)[0]
                for d in range(n_desc):
                    doff = 20 + d * 20
                    dtag = container[doff:doff + 4].decode("ascii", errors="replace")
                    du0 = struct.unpack_from("<I", container, doff + 4)[0]
                    dsz = struct.unpack_from("<I", container, doff + 8)[0]
                    if dtag == "data" and du0 != 0xFFFFFFFF:
                        body_start = ucfx_data_off + du0
                        body = container[body_start:body_start + dsz]
                        if len(body) >= 32:
                            fmt = "<" if endian == "le" else ">"
                            ver = struct.unpack_from("<I", body, 0)[0]
                            shash = struct.unpack_from(f"{fmt}I", body, 4)[0]
                            sc1 = struct.unpack_from(f"{fmt}H", body, 8)[0]
                            sc2 = struct.unpack_from(f"{fmt}H", body, 10)[0]
                            print(f"\n  Block {blk_idx} | soundbank 0x{h:08X} | "
                                  f"body_size={len(body):,} | endian={endian}")
                            print(f"    version={ver}, hash=0x{shash:08X}, "
                                  f"sub_count=({sc1},{sc2})")
                            # Hexdump first 32 bytes
                            print(f"    Raw header: {body[:32].hex()}")
        pos += sz


def main():
    patch_path = Path("output/data/vz-patch.wad")
    base_path = Path("game-files/vz.wad")

    if not patch_path.exists():
        print(f"ERROR: {patch_path} not found")
        return 1

    patch_raw = patch_path.read_bytes()
    patch_chunks = parse_ffcs(patch_raw)
    patch_indx = parse_indx(patch_raw, patch_chunks["INDX"][0], patch_chunks["INDX"][1])

    # Blocks containing audio entries
    audio_blocks = {166, 203, 204, 343, 347, 438, 470, 723, 738, 779, 870, 936, 971, 1013}

    print("=" * 70)
    print("DLC WAVEBANK CODEC ANALYSIS (from converted patch WAD)")
    print("=" * 70)

    for blk_idx in sorted(audio_blocks):
        if blk_idx >= len(patch_indx):
            continue
        try:
            decomp = decompress_block(patch_raw, patch_indx[blk_idx])
        except Exception as e:
            print(f"\n  Block {blk_idx}: decompress failed: {e}")
            continue
        if not decomp:
            continue
        analyze_wavebank(decomp, blk_idx, "le")
        analyze_soundbank_header(decomp, blk_idx, "le")

    # Also check a few base game wavebanks for comparison
    if base_path.exists():
        base_raw = base_path.read_bytes()
        base_chunks = parse_ffcs(base_raw)
        base_indx = parse_indx(base_raw, base_chunks["INDX"][0], base_chunks["INDX"][1])

        print(f"\n\n{'=' * 70}")
        print("BASE GAME WAVEBANK CODEC REFERENCE (first 3 audio blocks)")
        print("=" * 70)

        seen = set()
        for i in range(base_chunks["ASET"][1]):
            off = base_chunks["ASET"][0] + i * 16
            _, _, u2, tid = struct.unpack_from("<IIII", base_raw, off)
            if tid == 6:
                blk = (u2 >> 16) & 0xFFFF
                if blk not in seen and len(seen) < 3:
                    seen.add(blk)
                    try:
                        decomp = decompress_block(base_raw, base_indx[blk])
                    except Exception:
                        continue
                    if decomp:
                        analyze_wavebank(decomp, blk, "le")

    return 0


if __name__ == "__main__":
    sys.exit(main())
