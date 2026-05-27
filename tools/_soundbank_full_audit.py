#!/usr/bin/env python3
"""Exhaustive soundbank field analysis: extract ALL bodies from base game vz.wad.

Outputs:
  1. Header field distributions across all 76 soundbanks
  2. Per-field byte analysis with LE/BE/u16/u8/f32 interpretations
  3. Record area structure inference — auto-detects record size and field types
  4. DLC comparison when available
"""
from __future__ import annotations

import struct
import sys
import json
from pathlib import Path
from collections import Counter

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sges_decompress import decompress_sges_block

PAGE_SIZE = 0x8000
_TYPE_SOUNDBANK = 0x9F8BCA10


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


def parse_pths(raw: bytes, off: int, count: int) -> list[str]:
    paths = []
    pos = off
    for _ in range(count):
        nul = raw.index(b"\x00", pos)
        paths.append(raw[pos:nul].decode("utf-8", errors="replace"))
        pos = nul + 1
    return paths


def decompress_block(raw: bytes, entry: dict) -> bytes | None:
    offset = entry["page_idx"] * PAGE_SIZE
    size = entry["page_count"] * PAGE_SIZE
    compressed = raw[offset:offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def find_audio_entries(decomp: bytes, target_type: int) -> list[dict]:
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
                    dtag = container[doff:doff + 4].decode("ascii", errors="replace")
                    du0 = struct.unpack_from("<I", container, doff + 4)[0]
                    dsz = struct.unpack_from("<I", container, doff + 8)[0]
                    if dtag == "data" and du0 != 0xFFFFFFFF:
                        body_start = ucfx_data_off + du0
                        body = container[body_start:body_start + dsz]
                        results.append({
                            "hash": h, "entry_idx": i, "body": body,
                            "body_size": dsz,
                        })
        pos += sz
    return results


def find_all_soundbanks(raw: bytes, indx: list[dict],
                        aset_off: int, aset_count: int) -> list[dict]:
    seen_blocks: set[int] = set()
    results = []
    for i in range(aset_count):
        off = aset_off + i * 16
        ah, _, u2, tid = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if tid == 21 and block_idx not in seen_blocks:
            seen_blocks.add(block_idx)
            if block_idx < len(indx):
                try:
                    decomp = decompress_block(raw, indx[block_idx])
                except Exception:
                    continue
                if decomp:
                    entries = find_audio_entries(decomp, _TYPE_SOUNDBANK)
                    for e in entries:
                        e["block_idx"] = block_idx
                        e["aset_hash"] = ah
                        results.append(e)
    return results


def is_plausible_float(raw_bytes: bytes) -> tuple[bool, float]:
    val = struct.unpack_from("<f", raw_bytes, 0)[0]
    if val == 0.0:
        return True, 0.0
    if 1e-10 < abs(val) < 1e10:
        return True, val
    return False, val


def main():
    base_path = Path("game-files/vz.wad")
    patch_path = Path("output/data/vz-patch.wad")

    if not base_path.exists():
        print(f"ERROR: Base game WAD not found: {base_path}")
        return 1

    base_raw = base_path.read_bytes()
    base_chunks = parse_ffcs(base_raw)
    base_indx = parse_indx(base_raw, base_chunks["INDX"][0], base_chunks["INDX"][1])

    base_paths = []
    if "PTHS" in base_chunks:
        base_paths = parse_pths(base_raw, base_chunks["PTHS"][0], base_chunks["PTHS"][1])

    # ════════════════════════════════════════════════════════════════
    # PART 1: Extract ALL base game soundbanks
    # ════════════════════════════════════════════════════════════════
    print("=" * 110)
    print("PART 1: EXTRACTING ALL BASE GAME SOUNDBANKS")
    print("=" * 110)

    all_sb = find_all_soundbanks(base_raw, base_indx,
                                  base_chunks["ASET"][0], base_chunks["ASET"][1])
    print(f"\nTotal soundbank bodies extracted: {len(all_sb)}")

    for i, e in enumerate(all_sb):
        blk = e["block_idx"]
        name = base_paths[blk] if blk < len(base_paths) else f"block_{blk}"
        print(f"  [{i:3d}] block={blk:5d}  hash=0x{e['hash']:08X}  "
              f"body_size={e['body_size']:>8,d}  {name}")

    # ════════════════════════════════════════════════════════════════
    # PART 2: Header field distributions (first 32 bytes)
    # ════════════════════════════════════════════════════════════════
    print(f"\n{'=' * 110}")
    print("PART 2: HEADER FIELD DISTRIBUTIONS (bytes 0..31)")
    print("=" * 110)

    field_names = [
        (0, "count"), (4, "self_hash"), (8, "flags_or_u16pair"),
        (12, "self_hash2"), (16, "data_start"), (20, "section_off1"),
        (24, "section_off2"), (28, "section_off3"),
    ]

    for foff, fname in field_names:
        print(f"\n  ── Field [{foff}:{foff+4}] '{fname}' ──")
        u32_vals = Counter()
        u16_lo_vals = Counter()
        u16_hi_vals = Counter()
        u8_patterns = Counter()
        raw_bytes_set = Counter()

        for e in all_sb:
            body = e["body"]
            if len(body) < foff + 4:
                continue
            raw = body[foff:foff + 4]
            raw_bytes_set[raw] += 1
            u32_le = struct.unpack_from("<I", body, foff)[0]
            u32_vals[u32_le] += 1
            lo, hi = struct.unpack_from("<HH", body, foff)
            u16_lo_vals[lo] += 1
            u16_hi_vals[hi] += 1
            u8_patterns[struct.unpack_from("BBBB", body, foff)] += 1

        # Show u32 distribution
        print(f"    Unique u32 LE values: {len(u32_vals)}")
        for val, cnt in u32_vals.most_common(20):
            hi16 = (val >> 16) & 0xFFFF
            lo16 = val & 0xFFFF
            print(f"      0x{val:08X} ({val:>12,d})  hi16={hi16:5d} lo16={lo16:5d}  — {cnt}x")

        # Show u16 pair distributions
        print(f"    u16 LE[0] (lo) unique values ({len(u16_lo_vals)}): "
              f"{sorted(u16_lo_vals.keys())[:30]}")
        print(f"    u16 LE[1] (hi) unique values ({len(u16_hi_vals)}): "
              f"{sorted(u16_hi_vals.keys())[:30]}")

        # Check independence: do lo and hi vary independently?
        lo_set = set(u16_lo_vals.keys())
        hi_set = set(u16_hi_vals.keys())
        if len(lo_set) > 1 and len(hi_set) > 1:
            if lo_set != hi_set:
                print(f"    ⚠ u16 halves have DIFFERENT value sets → likely u16×2")
            else:
                print(f"    u16 halves have SAME value sets → could be u32 or u16×2")

        # Show u8 distribution if interesting
        if len(u8_patterns) > 1:
            print(f"    u8 patterns ({len(u8_patterns)} unique):")
            for pat, cnt in u8_patterns.most_common(10):
                print(f"      ({pat[0]:3d},{pat[1]:3d},{pat[2]:3d},{pat[3]:3d})  — {cnt}x")

        # Float interpretation
        float_count = 0
        for e in all_sb:
            body = e["body"]
            if len(body) < foff + 4:
                continue
            ok, _ = is_plausible_float(body[foff:foff + 4])
            if ok:
                float_count += 1
        if float_count == len(all_sb):
            print(f"    All values are plausible LE floats")
        elif float_count > 0:
            print(f"    {float_count}/{len(all_sb)} values are plausible LE floats")

        # Check if self_hash == self_hash2
        if fname == "self_hash2":
            match_count = 0
            for e in all_sb:
                body = e["body"]
                if len(body) >= 16:
                    h1 = struct.unpack_from("<I", body, 4)[0]
                    h2 = struct.unpack_from("<I", body, 12)[0]
                    if h1 == h2:
                        match_count += 1
            print(f"    self_hash[4:8] == self_hash2[12:16]: {match_count}/{len(all_sb)}")

    # ════════════════════════════════════════════════════════════════
    # PART 3: Section offset analysis
    # ════════════════════════════════════════════════════════════════
    print(f"\n{'=' * 110}")
    print("PART 3: SECTION OFFSETS & RECORD SIZE INFERENCE")
    print("=" * 110)

    record_sizes = Counter()
    for e in all_sb:
        body = e["body"]
        if len(body) < 32:
            continue
        count = struct.unpack_from("<I", body, 0)[0]
        data_start = struct.unpack_from("<I", body, 16)[0]
        off1 = struct.unpack_from("<I", body, 20)[0]
        off2 = struct.unpack_from("<I", body, 24)[0]
        off3 = struct.unpack_from("<I", body, 28)[0]

        blk = e["block_idx"]
        name = base_paths[blk] if blk < len(base_paths) else f"block_{blk}"

        # Check if count field matches LE u16 pair interpretation of [8:12]
        lo16, hi16 = struct.unpack_from("<HH", body, 8)

        # Section structure: header(data_start) + records... then sections at off1,off2,off3
        if data_start > 0 and data_start < len(body) and off1 > 0 and off1 < len(body):
            records_area = off1 - data_start
            if count > 0 and records_area > 0 and records_area % count == 0:
                rec_size = records_area // count
                record_sizes[rec_size] += 1

    print(f"\n  Record size distribution (data_start..section_off1 / count):")
    for rs, cnt in record_sizes.most_common():
        print(f"    record_size={rs} bytes  — {cnt} soundbanks")

    # ════════════════════════════════════════════════════════════════
    # PART 4: Detailed record structure for the most common size
    # ════════════════════════════════════════════════════════════════
    if not record_sizes:
        print("  No record sizes found, skipping record analysis")
        return 0

    dominant_rec_size = record_sizes.most_common(1)[0][0]
    print(f"\n{'=' * 110}")
    print(f"PART 4: RECORD FIELD ANALYSIS (record_size={dominant_rec_size})")
    print("=" * 110)

    # Collect all records with the dominant size
    all_records: list[bytes] = []
    for e in all_sb:
        body = e["body"]
        if len(body) < 32:
            continue
        count = struct.unpack_from("<I", body, 0)[0]
        data_start = struct.unpack_from("<I", body, 16)[0]
        off1 = struct.unpack_from("<I", body, 20)[0]
        if data_start <= 0 or off1 <= 0 or data_start >= len(body):
            continue
        records_area = off1 - data_start
        if count <= 0 or records_area <= 0 or records_area % count != 0:
            continue
        rec_size = records_area // count
        if rec_size != dominant_rec_size:
            continue
        for r in range(count):
            roff = data_start + r * rec_size
            if roff + rec_size <= len(body):
                all_records.append(body[roff:roff + rec_size])

    print(f"\n  Total records collected: {len(all_records)}")

    # For each 4-byte field in the record, determine its likely type
    print(f"\n  Per-field type analysis:")
    for foff in range(0, dominant_rec_size, 4):
        if foff + 4 > dominant_rec_size:
            break

        u32_vals = []
        f32_vals = []
        u16_pairs = []
        u8_quads = []
        zero_count = 0
        hash_like = 0
        small_int = 0
        plausible_float = 0

        for rec in all_records:
            raw = rec[foff:foff + 4]
            u32 = struct.unpack_from("<I", raw, 0)[0]
            f32 = struct.unpack_from("<f", raw, 0)[0]
            lo, hi = struct.unpack_from("<HH", raw, 0)
            b0, b1, b2, b3 = struct.unpack_from("BBBB", raw, 0)

            u32_vals.append(u32)
            f32_vals.append(f32)
            u16_pairs.append((lo, hi))
            u8_quads.append((b0, b1, b2, b3))

            if u32 == 0:
                zero_count += 1
            elif u32 > 0x10000000:
                hash_like += 1
            elif u32 < 65536:
                small_int += 1

            ok, _ = is_plausible_float(raw)
            if ok:
                plausible_float += 1

        n = len(all_records)
        unique_u32 = len(set(u32_vals))
        unique_lo = len(set(p[0] for p in u16_pairs))
        unique_hi = len(set(p[1] for p in u16_pairs))

        # Determine likely type
        if zero_count == n:
            field_type = "ZERO (always 0x00000000)"
        elif hash_like > n * 0.8:
            field_type = "u32 HASH"
        elif plausible_float > n * 0.7 and hash_like < n * 0.1:
            non_zero_floats = [f for f in f32_vals if f != 0.0]
            if non_zero_floats:
                fmin = min(non_zero_floats)
                fmax = max(non_zero_floats)
                field_type = f"f32 (range {fmin:.4g}..{fmax:.4g})"
            else:
                field_type = "f32 (all zero)"
        elif small_int > n * 0.8:
            field_type = "u32 small int"
        else:
            field_type = "u32 (mixed/unclear)"

        # Check for u16 pair vs u32
        lo_range = max(p[0] for p in u16_pairs) - min(p[0] for p in u16_pairs) if u16_pairs else 0
        hi_range = max(p[1] for p in u16_pairs) - min(p[1] for p in u16_pairs) if u16_pairs else 0
        hi_always_zero = all(p[1] == 0 for p in u16_pairs)

        # Check for u8 quad
        b0_range = max(q[0] for q in u8_quads) if u8_quads else 0
        b1_range = max(q[1] for q in u8_quads) if u8_quads else 0
        b2_range = max(q[2] for q in u8_quads) if u8_quads else 0
        b3_range = max(q[3] for q in u8_quads) if u8_quads else 0

        # Sample values
        samples = sorted(set(u32_vals))[:8]
        samples_hex = [f"0x{v:08X}" for v in samples]

        print(f"\n  rec[{foff:2d}:{foff+4:2d}]  TYPE: {field_type}")
        print(f"    unique_u32={unique_u32}  zeros={zero_count}/{n}  "
              f"hash_like={hash_like}/{n}  float_like={plausible_float}/{n}")
        print(f"    u16 lo unique={unique_lo} hi unique={unique_hi} "
              f"hi_always_zero={hi_always_zero}")
        print(f"    u8 max values: ({b0_range},{b1_range},{b2_range},{b3_range})")
        print(f"    sample values: {samples_hex[:8]}")

        # For floats, show actual float samples
        if "f32" in field_type:
            float_samples = sorted(set(round(f, 4) for f in f32_vals if f != 0.0))[:10]
            print(f"    float samples: {float_samples}")

    # ════════════════════════════════════════════════════════════════
    # PART 5: Section tables at off1, off2, off3
    # ════════════════════════════════════════════════════════════════
    print(f"\n{'=' * 110}")
    print("PART 5: SECTION TABLE ANALYSIS (off1, off2, off3 regions)")
    print("=" * 110)

    for sb_idx, e in enumerate(all_sb[:5]):
        body = e["body"]
        if len(body) < 32:
            continue
        count = struct.unpack_from("<I", body, 0)[0]
        data_start = struct.unpack_from("<I", body, 16)[0]
        off1 = struct.unpack_from("<I", body, 20)[0]
        off2 = struct.unpack_from("<I", body, 24)[0]
        off3 = struct.unpack_from("<I", body, 28)[0]
        lo16, hi16 = struct.unpack_from("<HH", body, 8)

        blk = e["block_idx"]
        name = base_paths[blk] if blk < len(base_paths) else f"block_{blk}"

        print(f"\n  ── Soundbank [{sb_idx}] block {blk} ({name}) ──")
        print(f"    count={count}  data_start=0x{data_start:X}  "
              f"off1=0x{off1:X}  off2=0x{off2:X}  off3=0x{off3:X}")
        print(f"    u16_pair[8:12]=({lo16}, {hi16})  body_size={len(body)}")

        sections = [
            ("section1 (off1..off2)", off1, off2),
            ("section2 (off2..off3)", off2, off3),
            ("section3 (off3..end)", off3, len(body)),
        ]

        for sec_name, sec_start, sec_end in sections:
            if sec_start <= 0 or sec_start >= len(body):
                continue
            if sec_end <= sec_start:
                sec_end = len(body)
            sec_size = sec_end - sec_start
            print(f"\n    {sec_name}: offset=0x{sec_start:X}, size={sec_size}")

            # Determine entry count / entry size for this section
            # Try lo16 and hi16 as possible counts
            for trial_count_name, trial_count in [("lo16", lo16), ("hi16", hi16), ("count", count)]:
                if trial_count > 0 and sec_size % trial_count == 0:
                    entry_size = sec_size // trial_count
                    if 2 <= entry_size <= 200:
                        print(f"      If count={trial_count_name}({trial_count}): "
                              f"entry_size={entry_size}")

            # Dump first 96 bytes of section
            dump_len = min(96, sec_size)
            for i in range(0, dump_len, 16):
                chunk = body[sec_start + i:sec_start + i + 16]
                hexstr = " ".join(f"{b:02x}" for b in chunk)
                ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
                print(f"      {sec_start + i:04x}: {hexstr:<48s} {ascii_str}")

    # ════════════════════════════════════════════════════════════════
    # PART 6: DLC soundbank comparison
    # ════════════════════════════════════════════════════════════════
    if patch_path.exists():
        print(f"\n{'=' * 110}")
        print("PART 6: DLC SOUNDBANK COMPARISON")
        print("=" * 110)

        patch_raw = patch_path.read_bytes()
        patch_chunks = parse_ffcs(patch_raw)
        patch_indx = parse_indx(patch_raw, patch_chunks["INDX"][0],
                                 patch_chunks["INDX"][1])

        dlc_sb = find_all_soundbanks(patch_raw, patch_indx,
                                      patch_chunks["ASET"][0],
                                      patch_chunks["ASET"][1])
        print(f"\n  DLC soundbanks found: {len(dlc_sb)}")

        for i, e in enumerate(dlc_sb):
            body = e["body"]
            blk = e["block_idx"]
            print(f"\n  ── DLC soundbank [{i}] block {blk} ──")
            print(f"    hash=0x{e['hash']:08X}  body_size={len(body)}")

            if len(body) < 32:
                print("    Too short")
                continue

            print(f"    Header (first 32 bytes):")
            for foff in range(0, 32, 4):
                raw = body[foff:foff + 4]
                le_u32 = struct.unpack_from("<I", body, foff)[0]
                lo, hi = struct.unpack_from("<HH", body, foff)
                b0, b1, b2, b3 = struct.unpack_from("BBBB", body, foff)
                print(f"      [{foff:2d}:{foff+4:2d}] {raw.hex()}  "
                      f"LE_u32=0x{le_u32:08X}  u16=({lo:5d},{hi:5d})  "
                      f"u8=({b0:3d},{b1:3d},{b2:3d},{b3:3d})")

            # Check count and record structure
            count = struct.unpack_from("<I", body, 0)[0]
            data_start = struct.unpack_from("<I", body, 16)[0]
            off1 = struct.unpack_from("<I", body, 20)[0]

            print(f"    count={count}  data_start=0x{data_start:X}  off1=0x{off1:X}")

            if data_start > 0 and off1 > data_start and count > 0:
                rec_area = off1 - data_start
                if rec_area % count == 0:
                    rec_size = rec_area // count
                    print(f"    record_size={rec_size}")

                    # Dump first 3 records
                    for r in range(min(3, count)):
                        roff = data_start + r * rec_size
                        if roff + rec_size <= len(body):
                            rec = body[roff:roff + rec_size]
                            print(f"    Record [{r}]:")
                            for foff2 in range(0, rec_size, 4):
                                if foff2 + 4 > rec_size:
                                    break
                                raw = rec[foff2:foff2 + 4]
                                le_u32 = struct.unpack_from("<I", raw, 0)[0]
                                le_f32 = struct.unpack_from("<f", raw, 0)[0]
                                ok, _ = is_plausible_float(raw)
                                fstr = f"  f32={le_f32:.4g}" if ok and le_u32 != 0 else ""
                                print(f"      [{foff2:2d}:{foff2+4:2d}] {raw.hex()} "
                                      f"LE=0x{le_u32:08X}{fstr}")

        # Compare base game field patterns vs DLC
        if all_sb and dlc_sb:
            print(f"\n  ── BASE vs DLC pattern comparison ──")
            ref = all_sb[0]["body"]
            comp = dlc_sb[0]["body"]
            ref_count = struct.unpack_from("<I", ref, 0)[0]
            comp_count = struct.unpack_from("<I", comp, 0)[0]
            ref_ds = struct.unpack_from("<I", ref, 16)[0]
            ref_off1 = struct.unpack_from("<I", ref, 20)[0]
            comp_ds = struct.unpack_from("<I", comp, 16)[0]
            comp_off1 = struct.unpack_from("<I", comp, 20)[0]

            if ref_count > 0 and (ref_off1 - ref_ds) % ref_count == 0:
                ref_rec_size = (ref_off1 - ref_ds) // ref_count
            else:
                ref_rec_size = 0

            if comp_count > 0 and comp_off1 > comp_ds and (comp_off1 - comp_ds) % comp_count == 0:
                comp_rec_size = (comp_off1 - comp_ds) // comp_count
            else:
                comp_rec_size = 0

            print(f"    Base: count={ref_count}, rec_size={ref_rec_size}")
            print(f"    DLC:  count={comp_count}, rec_size={comp_rec_size}")

    # ════════════════════════════════════════════════════════════════
    # PART 7: ALL-FIELD DISTRIBUTION HEATMAP for [8:12]
    # ════════════════════════════════════════════════════════════════
    print(f"\n{'=' * 110}")
    print("PART 7: DEFINITIVE [8:12] FIELD VERDICT")
    print("=" * 110)

    base_lo_vals = []
    base_hi_vals = []
    base_u32_vals_list = []
    for e in all_sb:
        body = e["body"]
        if len(body) >= 12:
            lo, hi = struct.unpack_from("<HH", body, 8)
            u32 = struct.unpack_from("<I", body, 8)[0]
            base_lo_vals.append(lo)
            base_hi_vals.append(hi)
            base_u32_vals_list.append(u32)

    lo_counter = Counter(base_lo_vals)
    hi_counter = Counter(base_hi_vals)
    u32_counter = Counter(base_u32_vals_list)

    print(f"\n  u32 LE values ({len(u32_counter)} unique):")
    for val, cnt in u32_counter.most_common():
        print(f"    0x{val:08X}  — {cnt}x")

    print(f"\n  u16 LE[0] (lo byte pair) values ({len(lo_counter)} unique):")
    for val, cnt in lo_counter.most_common():
        print(f"    {val:5d} (0x{val:04X})  — {cnt}x")

    print(f"\n  u16 LE[1] (hi byte pair) values ({len(hi_counter)} unique):")
    for val, cnt in hi_counter.most_common():
        print(f"    {val:5d} (0x{val:04X})  — {cnt}x")

    # Cross-tabulation
    print(f"\n  Cross-tabulation (lo, hi) pairs:")
    pair_counter = Counter(zip(base_lo_vals, base_hi_vals))
    for (lo, hi), cnt in pair_counter.most_common():
        print(f"    ({lo:3d}, {hi:3d})  — {cnt}x")

    # Final verdict
    lo_varies = len(lo_counter) > 1
    hi_varies = len(hi_counter) > 1
    independent = lo_varies and hi_varies
    correlated = all(lo == hi for lo, hi in zip(base_lo_vals, base_hi_vals))

    print(f"\n  lo varies: {lo_varies}  hi varies: {hi_varies}")
    print(f"  always lo==hi: {correlated}")

    if independent and not correlated:
        print(f"\n  VERDICT: [8:12] is TWO INDEPENDENT u16 fields")
    elif correlated and lo_varies:
        print(f"\n  VERDICT: [8:12] COULD be u32 OR u16×2 (lo always == hi)")
    elif not lo_varies and not hi_varies:
        print(f"\n  VERDICT: [8:12] is CONSTANT — type ambiguous but doesn't matter")
    else:
        print(f"\n  VERDICT: Needs more analysis")

    # ════════════════════════════════════════════════════════════════
    # PART 8: Section table field types  
    # ════════════════════════════════════════════════════════════════
    print(f"\n{'=' * 110}")
    print("PART 8: SECTION TABLE FIELD TYPE ANALYSIS")
    print("=" * 110)

    for sec_idx, (sec_label, offset_field) in enumerate([
        ("section1 (off1..off2)", (20, 24)),
        ("section2 (off2..off3)", (24, 28)),
        ("section3 (off3..end)", (28, None)),
    ]):
        start_field, end_field = offset_field
        print(f"\n  ── {sec_label} ──")

        all_entries: list[bytes] = []
        entry_size_counter = Counter()

        for e in all_sb:
            body = e["body"]
            if len(body) < 32:
                continue
            lo16, hi16 = struct.unpack_from("<HH", body, 8)
            sec_start = struct.unpack_from("<I", body, start_field)[0]
            sec_end = struct.unpack_from("<I", body, end_field)[0] if end_field else len(body)
            if sec_start <= 0 or sec_start >= len(body):
                continue
            if sec_end <= sec_start:
                sec_end = len(body)
            sec_size = sec_end - sec_start

            # Try different counts
            for trial_name, trial_count in [("lo16", lo16), ("hi16", hi16)]:
                if trial_count > 0 and sec_size % trial_count == 0:
                    es = sec_size // trial_count
                    if 2 <= es <= 200:
                        entry_size_counter[(trial_name, es)] += 1

            # Collect raw section data
            if sec_size > 0:
                all_entries.append(body[sec_start:sec_start + min(sec_size, 512)])

        print(f"    Entry size candidates:")
        for (cnt_name, es), cnt in entry_size_counter.most_common(10):
            print(f"      count={cnt_name}, entry_size={es}  — {cnt} soundbanks")

        # Dump first section from first soundbank for visual inspection
        if all_entries:
            print(f"\n    First section data (first 128 bytes):")
            data = all_entries[0]
            for i in range(0, min(128, len(data)), 16):
                chunk = data[i:i + 16]
                hexstr = " ".join(f"{b:02x}" for b in chunk)
                ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in chunk)
                print(f"      {i:04x}: {hexstr:<48s} {ascii_str}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
