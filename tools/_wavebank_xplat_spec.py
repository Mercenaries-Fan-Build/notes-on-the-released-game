#!/usr/bin/env python3
"""Cross-platform wavebank byte-level spec builder.

Extracts identical wavebank entries (same asset_hash) from both Xbox BE
and PC LE base-game vz.wad files, then does a structural byte-for-byte
comparison to produce a definitive field map.

No heuristics — every byte position is classified by direct observation.

Usage:
    python tools/_wavebank_xplat_spec.py
"""
from __future__ import annotations

import struct
import sys
from collections import defaultdict
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from _audio_cross_platform_diff import (
    load_wad,
    classify_4byte_diff,
    _TYPE_WAVEBANK,
    _AUDIO_TYPES,
    _TYPE_NAMES,
    _decompress_block,
    PAGE_SIZE,
)

REPO_ROOT = THIS_DIR.parent
PC_WAD = REPO_ROOT / "game-files" / "pc-game-vz.wad"
XBOX_WAD = REPO_ROOT / "game-files" / "xbox-vz.wad"


def _extract_audio_bodies_from_wad(ctx) -> dict[tuple[int, int], bytes]:
    """Collect all audio data bodies, with corrected Xbox block_idx."""
    audio_blocks: dict[int, set[int]] = defaultdict(set)
    for e in ctx.aset_entries:
        if e["type_id"] in (6, 21):
            if ctx.endian == "be":
                bi = e["u2"] & 0xFFFF
            else:
                bi = (e["u2"] >> 16) & 0xFFFF
            audio_blocks[bi].add(e["hash"])

    bodies: dict[tuple[int, int], bytes] = {}
    for blk_idx in sorted(audio_blocks.keys()):
        if blk_idx >= len(ctx.indx):
            continue
        try:
            decomp = _decompress_block(ctx.data, ctx.indx[blk_idx], ctx.endian)
        except Exception:
            continue
        if not decomp:
            continue
        fmt = "<" if ctx.endian == "le" else ">"
        entry_count = struct.unpack_from(f"{fmt}I", decomp, 0)[0]
        if entry_count > 1000 or entry_count * 16 + 4 > len(decomp):
            continue

        pos = 4 + entry_count * 16
        for i in range(entry_count):
            eoff = 4 + i * 16
            h, th, o, sz = struct.unpack_from(f"{fmt}IIII", decomp, eoff)
            if th in _AUDIO_TYPES:
                container = decomp[pos:pos + sz]
                csum_tag = b"CSUM" if ctx.endian == "le" else b"MUSC"
                if len(container) >= 8 and container[-8:-4] == csum_tag:
                    container = container[:-8]
                ucfx_magic = b"UCFX" if ctx.endian == "le" else b"XFCU"
                if len(container) >= 4 and container[:4] == ucfx_magic:
                    ucfx_data_off = struct.unpack_from(f"{fmt}I", container, 4)[0]
                    n_desc = struct.unpack_from(f"{fmt}I", container, 16)[0]
                    for d in range(n_desc):
                        doff = 20 + d * 20
                        dtag_raw = container[doff:doff + 4]
                        dtag = dtag_raw[::-1].decode("ascii", "replace") if ctx.endian == "be" else dtag_raw.decode("ascii", "replace")
                        du0 = struct.unpack_from(f"{fmt}I", container, doff + 4)[0]
                        dsz = struct.unpack_from(f"{fmt}I", container, doff + 8)[0]
                        if dtag == "data" and du0 != 0xFFFFFFFF:
                            body_start = ucfx_data_off + du0
                            body = container[body_start:body_start + dsz]
                            if body:
                                bodies[(h, th)] = body
            pos += sz
    return bodies


def extract_matched_wavebanks() -> list[tuple[int, bytes, bytes]]:
    """Return [(asset_hash, xbox_body_be, pc_body_le), ...] for all matched wavebanks."""
    print("Loading PC WAD...")
    pc_ctx = load_wad(PC_WAD)
    print("Loading Xbox WAD...")
    xbox_ctx = load_wad(XBOX_WAD)

    print("Collecting PC audio bodies (corrected block_idx)...")
    pc_bodies = _extract_audio_bodies_from_wad(pc_ctx)
    print("Collecting Xbox audio bodies (corrected block_idx)...")
    xbox_bodies = _extract_audio_bodies_from_wad(xbox_ctx)

    pc_wb = {k: v for k, v in pc_bodies.items() if k[1] == _TYPE_WAVEBANK}
    xbox_wb = {k: v for k, v in xbox_bodies.items() if k[1] == _TYPE_WAVEBANK}

    matched_keys = sorted(set(pc_wb.keys()) & set(xbox_wb.keys()))
    print(f"\nPC wavebanks: {len(pc_wb)}")
    print(f"Xbox wavebanks: {len(xbox_wb)}")
    print(f"Matched (same hash): {len(matched_keys)}")

    pairs = []
    for k in matched_keys:
        pairs.append((k[0], xbox_wb[k], pc_wb[k]))
    return pairs


def analyze_header(pairs: list[tuple[int, bytes, bytes]]):
    """Byte-for-byte comparison of the 24-byte wavebank header."""
    print("\n" + "=" * 100)
    print("WAVEBANK HEADER ANALYSIS (first 24 bytes)")
    print("=" * 100)

    for off in range(0, 24, 4):
        field_types = defaultdict(int)
        examples = []
        for asset_hash, xb, pb in pairs:
            if len(xb) < off + 4 or len(pb) < off + 4:
                continue
            x4 = xb[off:off + 4]
            p4 = pb[off:off + 4]
            cls = classify_4byte_diff(x4, p4)
            field_types[cls] += 1
            if len(examples) < 3:
                examples.append((asset_hash, x4, p4, cls))

        dom = max(field_types, key=field_types.get) if field_types else "unknown"
        counts = ", ".join(f"{k}:{v}" for k, v in sorted(field_types.items()))
        print(f"\n  [{off:3d}:{off+4:3d}]  {dom:6s}  ({counts})")
        for ah, x4, p4, cls in examples:
            xu32 = struct.unpack(">I", x4)[0]
            pu32 = struct.unpack("<I", p4)[0]
            print(f"    0x{ah:08X}: Xbox={x4.hex()} ({xu32:>10d})  "
                  f"PC={p4.hex()} ({pu32:>10d})  [{cls}]")

    # Also check if offset [0:4] is LE on Xbox (count field known to be LE on both)
    print("\n  --- Special check: is [0:4] (count) LE on both? ---")
    for asset_hash, xb, pb in pairs[:5]:
        xle = struct.unpack_from("<I", xb, 0)[0]
        xbe = struct.unpack_from(">I", xb, 0)[0]
        ple = struct.unpack_from("<I", pb, 0)[0]
        print(f"    0x{asset_hash:08X}: Xbox LE={xle} BE={xbe}  PC LE={ple}")


def analyze_records(pairs: list[tuple[int, bytes, bytes]]):
    """Compare per-record fields across platforms."""
    print("\n" + "=" * 100)
    print("WAVEBANK RECORD ANALYSIS (36 bytes each)")
    print("=" * 100)

    # Accumulate classifications per record-field offset
    RECSIZE = 36
    field_types: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    record_examples: dict[int, list] = defaultdict(list)

    for asset_hash, xb, pb in pairs:
        # Parse headers to find record start
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        x_count_be = struct.unpack_from(">I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]

        # Determine Xbox count — try both endians, match with PC
        x_count = x_count_le if x_count_le == p_count else x_count_be

        if x_count != p_count or x_count == 0:
            continue

        x_roff_be = struct.unpack_from(">I", xb, 16)[0]
        x_roff_le = struct.unpack_from("<I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]

        # Use whatever roff matches PC
        x_roff = x_roff_be if x_roff_be == p_roff else x_roff_le

        # Compare each record
        for r in range(x_count):
            x_off = x_roff + r * RECSIZE
            p_off = p_roff + r * RECSIZE

            if x_off + RECSIZE > len(xb) or p_off + RECSIZE > len(pb):
                break

            for foff in range(0, RECSIZE, 4):
                x4 = xb[x_off + foff:x_off + foff + 4]
                p4 = pb[p_off + foff:p_off + foff + 4]
                cls = classify_4byte_diff(x4, p4)
                field_types[foff][cls] += 1
                if len(record_examples[foff]) < 3:
                    record_examples[foff].append((asset_hash, r, x4, p4, cls))

    print(f"\n  Record fields (36 bytes, 9 u32 slots):\n")
    for foff in sorted(field_types.keys()):
        dom = max(field_types[foff], key=field_types[foff].get)
        counts = ", ".join(f"{k}:{v}" for k, v in sorted(field_types[foff].items()))
        print(f"  [{foff:3d}:{foff+4:3d}]  {dom:6s}  ({counts})")
        for ah, r, x4, p4, cls in record_examples[foff]:
            print(f"    0x{ah:08X} rec[{r}]: Xbox={x4.hex()}  PC={p4.hex()}  [{cls}]")


def analyze_audio_blob(pairs: list[tuple[int, bytes, bytes]]):
    """Compare trailing audio data layout."""
    print("\n" + "=" * 100)
    print("WAVEBANK AUDIO BLOB ANALYSIS")
    print("=" * 100)

    RECSIZE = 36

    for asset_hash, xb, pb in pairs[:10]:
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        x_count_be = struct.unpack_from(">I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]
        x_count = x_count_le if x_count_le == p_count else x_count_be
        if x_count != p_count or x_count == 0:
            continue

        x_roff_be = struct.unpack_from(">I", xb, 16)[0]
        x_roff_le = struct.unpack_from("<I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]
        x_roff = x_roff_be if x_roff_be == p_roff else x_roff_le

        # Audio blob starts
        x_audio = x_roff + x_count * RECSIZE
        p_audio = p_roff + p_count * RECSIZE

        print(f"\n  0x{asset_hash:08X}: count={x_count}  "
              f"Xbox(roff={x_roff}, audio@0x{x_audio:X}, body={len(xb)}, tail={len(xb)-x_audio})  "
              f"PC(roff={p_roff}, audio@0x{p_audio:X}, body={len(pb)}, tail={len(pb)-p_audio})")

        # Check first 3 records' data_offset and data_size on both platforms
        for r in range(min(3, x_count)):
            xr = x_roff + r * RECSIZE
            pr = p_roff + r * RECSIZE
            if xr + RECSIZE > len(xb) or pr + RECSIZE > len(pb):
                break

            x_hash = struct.unpack_from(">I", xb, xr)[0]
            p_hash = struct.unpack_from("<I", pb, pr)[0]
            x_codec = xb[xr + 6]
            p_codec = pb[pr + 6]
            x_doff = struct.unpack_from(">I", xb, xr + 12)[0]
            x_dsz = struct.unpack_from(">I", xb, xr + 16)[0]
            p_doff = struct.unpack_from("<I", pb, pr + 12)[0]
            p_dsz = struct.unpack_from("<I", pb, pr + 16)[0]

            # Check if offsets are relative to audio_start
            x_rel = x_doff - x_audio if x_doff >= x_audio else x_doff
            p_rel = p_doff - p_audio if p_doff >= p_audio else p_doff

            x_ok = x_doff + x_dsz <= len(xb) if x_dsz else True
            p_ok = p_doff + p_dsz <= len(pb) if p_dsz else True

            print(f"    rec[{r}] hash X=0x{x_hash:08X} P=0x{p_hash:08X}  "
                  f"codec X=0x{x_codec:02X} P=0x{p_codec:02X}  "
                  f"off X=0x{x_doff:X}(rel=0x{x_rel:X}) P=0x{p_doff:X}(rel=0x{p_rel:X})  "
                  f"sz X={x_dsz} P={p_dsz}  "
                  f"valid X={x_ok} P={p_ok}")


def analyze_offset_origin(pairs: list[tuple[int, bytes, bytes]]):
    """Determine whether data_offset is body-absolute or audio-relative."""
    print("\n" + "=" * 100)
    print("OFFSET ORIGIN ANALYSIS: body-absolute vs audio-relative")
    print("=" * 100)

    RECSIZE = 36
    body_abs_count = 0
    audio_rel_count = 0
    neither_count = 0
    total = 0

    for asset_hash, xb, pb in pairs:
        for plat_name, body, endian in [("Xbox", xb, ">"), ("PC", pb, "<")]:
            count_le = struct.unpack_from("<I", body, 0)[0]
            count_be = struct.unpack_from(">I", body, 0)[0]
            count = count_le if count_le < 10000 else count_be

            roff = struct.unpack_from(f"{endian}I", body, 16)[0]
            audio_start = roff + count * RECSIZE

            for r in range(count):
                rbase = roff + r * RECSIZE
                if rbase + RECSIZE > len(body):
                    break
                doff = struct.unpack_from(f"{endian}I", body, rbase + 12)[0]
                dsz = struct.unpack_from(f"{endian}I", body, rbase + 16)[0]
                if dsz == 0:
                    continue
                total += 1

                # Test body-absolute: does doff+dsz fit body?
                if doff + dsz <= len(body) and doff >= audio_start:
                    body_abs_count += 1
                # Test audio-relative: does (audio_start + doff + dsz) fit body?
                elif audio_start + doff + dsz <= len(body):
                    audio_rel_count += 1
                else:
                    neither_count += 1

    print(f"\n  Total non-zero records checked: {total}")
    print(f"  Body-absolute (doff from body[0]): {body_abs_count} ({100*body_abs_count/max(total,1):.1f}%)")
    print(f"  Audio-relative (doff from audio_start): {audio_rel_count} ({100*audio_rel_count/max(total,1):.1f}%)")
    print(f"  Neither fits: {neither_count} ({100*neither_count/max(total,1):.1f}%)")


def analyze_full_record_detailed(pairs: list[tuple[int, bytes, bytes]]):
    """Detailed per-byte analysis of record fields 4-7 (format_bytes area)."""
    print("\n" + "=" * 100)
    print("RECORD FORMAT_BYTES DETAILED (bytes [4:8] of each record)")
    print("=" * 100)

    RECSIZE = 36
    byte_match = [defaultdict(int) for _ in range(4)]

    for asset_hash, xb, pb in pairs:
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]
        if x_count_le != p_count or x_count_le == 0:
            continue

        x_roff = struct.unpack_from(">I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]

        for r in range(x_count_le):
            xr = x_roff + r * RECSIZE
            pr = p_roff + r * RECSIZE
            if xr + 8 > len(xb) or pr + 8 > len(pb):
                break

            for i in range(4):
                xval = xb[xr + 4 + i]
                pval = pb[pr + 4 + i]
                byte_match[i][(xval, pval)] += 1

    for i in range(4):
        print(f"\n  Byte [{4+i}] (record offset +{4+i}):")
        for (xv, pv), cnt in sorted(byte_match[i].items(), key=lambda x: -x[1])[:10]:
            eq = "==" if xv == pv else "!="
            print(f"    Xbox=0x{xv:02X}  PC=0x{pv:02X}  {eq}  count={cnt}")


def analyze_extra_fields(pairs: list[tuple[int, bytes, bytes]]):
    """Analyze record bytes [20:36] — the extra/metadata fields."""
    print("\n" + "=" * 100)
    print("RECORD EXTRA FIELDS (bytes [20:36] — 4 u32 slots)")
    print("=" * 100)

    RECSIZE = 36
    field_types: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    examples: dict[int, list] = defaultdict(list)

    for asset_hash, xb, pb in pairs:
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]
        if x_count_le != p_count or x_count_le == 0:
            continue

        x_roff = struct.unpack_from(">I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]

        for r in range(x_count_le):
            xr = x_roff + r * RECSIZE
            pr = p_roff + r * RECSIZE
            if xr + RECSIZE > len(xb) or pr + RECSIZE > len(pb):
                break

            for foff in range(20, 36, 4):
                x4 = xb[xr + foff:xr + foff + 4]
                p4 = pb[pr + foff:pr + foff + 4]
                cls = classify_4byte_diff(x4, p4)
                field_types[foff][cls] += 1
                if len(examples[foff]) < 3:
                    examples[foff].append((asset_hash, r, x4, p4, cls))

    for foff in sorted(field_types.keys()):
        dom = max(field_types[foff], key=field_types[foff].get)
        counts = ", ".join(f"{k}:{v}" for k, v in sorted(field_types[foff].items()))
        print(f"\n  [{foff:3d}:{foff+4:3d}]  {dom:6s}  ({counts})")
        for ah, r, x4, p4, cls in examples[foff]:
            print(f"    0x{ah:08X} rec[{r}]: Xbox={x4.hex()}  PC={p4.hex()}  [{cls}]")


def analyze_codec_mapping(pairs: list[tuple[int, bytes, bytes]]):
    """Confirm codec byte mapping Xbox→PC."""
    print("\n" + "=" * 100)
    print("CODEC BYTE MAPPING")
    print("=" * 100)

    RECSIZE = 36
    codec_map = defaultdict(int)

    for asset_hash, xb, pb in pairs:
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]
        if x_count_le != p_count or x_count_le == 0:
            continue

        x_roff = struct.unpack_from(">I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]

        for r in range(x_count_le):
            xr = x_roff + r * RECSIZE
            pr = p_roff + r * RECSIZE
            if xr + 8 > len(xb) or pr + 8 > len(pb):
                break
            xcodec = xb[xr + 6]
            pcodec = pb[pr + 6]
            codec_map[(xcodec, pcodec)] += 1

    for (xc, pc), cnt in sorted(codec_map.items(), key=lambda x: -x[1]):
        print(f"  Xbox 0x{xc:02X} → PC 0x{pc:02X}  ({cnt} clips)")


def analyze_size_relationship(pairs: list[tuple[int, bytes, bytes]]):
    """Compare data_size values to understand Xbox→PC size mapping."""
    print("\n" + "=" * 100)
    print("DATA_SIZE RELATIONSHIP (Xbox vs PC per matched clip)")
    print("=" * 100)

    RECSIZE = 36

    ratios = []
    exact = 0
    total = 0

    for asset_hash, xb, pb in pairs:
        x_count_le = struct.unpack_from("<I", xb, 0)[0]
        p_count = struct.unpack_from("<I", pb, 0)[0]
        if x_count_le != p_count or x_count_le == 0:
            continue

        x_roff = struct.unpack_from(">I", xb, 16)[0]
        p_roff = struct.unpack_from("<I", pb, 16)[0]

        for r in range(x_count_le):
            xr = x_roff + r * RECSIZE
            pr = p_roff + r * RECSIZE
            if xr + 20 > len(xb) or pr + 20 > len(pb):
                break

            x_hash = struct.unpack_from(">I", xb, xr)[0]
            p_hash = struct.unpack_from("<I", pb, pr)[0]
            if x_hash != p_hash:
                continue

            x_dsz = struct.unpack_from(">I", xb, xr + 16)[0]
            p_dsz = struct.unpack_from("<I", pb, pr + 16)[0]
            if x_dsz == 0 and p_dsz == 0:
                continue

            total += 1
            if x_dsz == p_dsz:
                exact += 1
            if x_dsz > 0 and p_dsz > 0:
                ratios.append((p_dsz / x_dsz, x_dsz, p_dsz, asset_hash, r))

    print(f"\n  Matched clips with non-zero sizes: {total}")
    print(f"  Exact same size: {exact} ({100*exact/max(total,1):.1f}%)")

    if ratios:
        ratios.sort()
        print(f"  Ratio PC/Xbox: min={ratios[0][0]:.4f}  max={ratios[-1][0]:.4f}  "
              f"median={ratios[len(ratios)//2][0]:.4f}")
        print(f"\n  Sample ratios:")
        for ratio, xsz, psz, ah, r in ratios[:5]:
            print(f"    0x{ah:08X}[{r}]: Xbox={xsz:>8d}  PC={psz:>8d}  ratio={ratio:.4f}")
        print(f"    ...")
        for ratio, xsz, psz, ah, r in ratios[-5:]:
            print(f"    0x{ah:08X}[{r}]: Xbox={xsz:>8d}  PC={psz:>8d}  ratio={ratio:.4f}")


def main():
    print("=" * 100)
    print("WAVEBANK CROSS-PLATFORM BYTE-LEVEL SPEC BUILDER")
    print("=" * 100)
    print(f"PC WAD:   {PC_WAD}")
    print(f"Xbox WAD: {XBOX_WAD}")

    pairs = extract_matched_wavebanks()
    if not pairs:
        print("ERROR: No matched wavebanks found!")
        return

    analyze_header(pairs)
    analyze_records(pairs)
    analyze_full_record_detailed(pairs)
    analyze_extra_fields(pairs)
    analyze_codec_mapping(pairs)
    analyze_offset_origin(pairs)
    analyze_size_relationship(pairs)
    analyze_audio_blob(pairs)


if __name__ == "__main__":
    main()
