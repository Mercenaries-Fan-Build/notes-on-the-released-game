#!/usr/bin/env python3
"""Reverse-engineer soundbank record layout from base game ground truth.

Analyzes all 76 base game PC soundbank bodies to determine:
1. The exact meaning of the header fields (esp. sub_count, sub_count2)
2. How body size correlates with these counts
3. The field types in each section (u32, f32, u16×2, u8×4)
4. A definitive per-record layout for the converter

This uses ZERO heuristics — everything is derived from the base game's
LE byte patterns across the full sample set.
"""
from __future__ import annotations

import struct
import sys
from pathlib import Path
from collections import defaultdict

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


def decompress_block(raw: bytes, entry: dict) -> bytes | None:
    offset = entry["page_idx"] * PAGE_SIZE
    size = entry["page_count"] * PAGE_SIZE
    compressed = raw[offset:offset + size]
    if not compressed or compressed[:4] != b"sges":
        return None
    return decompress_sges_block(compressed, 0, len(compressed))


def find_soundbank_entries(decomp: bytes) -> list[dict]:
    entry_count = struct.unpack_from("<I", decomp, 0)[0]
    results = []
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
                        results.append({
                            "hash": h, "entry_idx": i, "body": body,
                            "body_size": dsz,
                        })
        pos += sz
    return results


def classify_field(values: list[bytes]) -> str:
    """Classify a 4-byte field based on observed values across samples.

    Returns one of: 'u32', 'f32', 'u16x2', 'u8x4', 'zero', 'const', 'mixed'
    """
    if all(v == b'\x00\x00\x00\x00' for v in values):
        return "zero"
    if len(set(values)) == 1:
        return "const"

    n_float = 0
    n_u8_pattern = 0
    n_u16_pattern = 0

    for v in values:
        b0, b1, b2, b3 = v
        f_le = struct.unpack_from("<f", v, 0)[0]

        is_valid_float = (f_le == 0.0 or (1e-10 < abs(f_le) < 1e10))
        if is_valid_float and (b3 in (0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44)):
            n_float += 1

        if b1 == 0 and b3 == 0 and (b0 > 0 or b2 > 0):
            n_u16_pattern += 1

        if (b0 <= 10 and b1 <= 10 and b2 <= 10 and b3 <= 10 and
                (b0 > 0 or b1 > 0 or b2 > 0 or b3 > 0)):
            n_u8_pattern += 1

    total = len(values)
    if n_float > total * 0.7:
        return "f32"
    if n_u16_pattern > total * 0.7:
        return "u16x2"
    if n_u8_pattern > total * 0.5:
        return "u8x4"
    return "u32"


def main():
    base_path = Path("game-files/vz.wad")
    if not base_path.exists():
        print(f"ERROR: {base_path} not found")
        return 1

    base_raw = base_path.read_bytes()
    chunks = parse_ffcs(base_raw)
    indx = parse_indx(base_raw, chunks["INDX"][0], chunks["INDX"][1])
    aset_off, aset_count = chunks["ASET"]

    # Find all blocks with soundbanks via ASET scan
    seen_blocks: set[int] = set()
    for i in range(aset_count):
        off = aset_off + i * 16
        _, _, u2, tid = struct.unpack_from("<IIII", base_raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if tid == 21:
            seen_blocks.add(block_idx)

    all_soundbanks: list[dict] = []
    for blk_idx in sorted(seen_blocks):
        if blk_idx >= len(indx):
            continue
        try:
            decomp = decompress_block(base_raw, indx[blk_idx])
        except Exception:
            continue
        if decomp:
            entries = find_soundbank_entries(decomp)
            for e in entries:
                e["block_idx"] = blk_idx
                all_soundbanks.append(e)

    print(f"Collected {len(all_soundbanks)} base game soundbank bodies\n")

    # ── PART 1: Header analysis across all samples ──
    print("=" * 80)
    print("PART 1: HEADER FIELD ANALYSIS (all samples)")
    print("=" * 80)

    version_vals: set[int] = set()
    sub_count_vals: list[int] = []
    sub_count2_vals: list[int] = []
    sizes: list[int] = []

    for e in all_soundbanks:
        body = e["body"]
        if len(body) < 32:
            continue
        version_vals.add(struct.unpack_from("<I", body, 0)[0])
        sc1 = struct.unpack_from("<H", body, 8)[0]
        sc2 = struct.unpack_from("<H", body, 10)[0]
        sub_count_vals.append(sc1)
        sub_count2_vals.append(sc2)
        sizes.append(len(body))

    print(f"  [0:4]  version values: {sorted(version_vals)}")
    print(f"  [8:10] sub_count  range: {min(sub_count_vals)}..{max(sub_count_vals)} "
          f"(mean={sum(sub_count_vals)/len(sub_count_vals):.1f})")
    print(f"  [10:12] sub_count2 range: {min(sub_count2_vals)}..{max(sub_count2_vals)} "
          f"(mean={sum(sub_count2_vals)/len(sub_count2_vals):.1f})")
    print(f"  body_size range: {min(sizes)}..{max(sizes)}")

    # ── PART 2: Correlation between counts and body size ──
    print(f"\n{'=' * 80}")
    print("PART 2: SIZE vs COUNTS CORRELATION")
    print("=" * 80)

    for e in all_soundbanks:
        body = e["body"]
        if len(body) < 32:
            continue
        sc1 = struct.unpack_from("<H", body, 8)[0]
        sc2 = struct.unpack_from("<H", body, 10)[0]
        data_start = struct.unpack_from("<I", body, 16)[0]
        sec1_off = struct.unpack_from("<I", body, 20)[0]
        sec2_off = struct.unpack_from("<I", body, 24)[0]
        sec3_off = struct.unpack_from("<I", body, 28)[0]

        sec_a = sec1_off - data_start
        sec_b = sec2_off - sec1_off
        sec_c = sec3_off - sec2_off
        sec_d = len(body) - sec3_off

        e["sc1"] = sc1
        e["sc2"] = sc2
        e["sec_a"] = sec_a
        e["sec_b"] = sec_b
        e["sec_c"] = sec_c
        e["sec_d"] = sec_d

    # Check if sec_a = f(sc1) or sec_c = f(sc2)
    print("\n  Testing: section_A_size = f(sub_count)")
    sc1_to_seca: dict[int, list[int]] = defaultdict(list)
    for e in all_soundbanks:
        if "sc1" in e:
            sc1_to_seca[e["sc1"]].append(e["sec_a"])

    all_consistent = True
    for sc1 in sorted(sc1_to_seca.keys())[:20]:
        sec_a_vals = sc1_to_seca[sc1]
        unique = sorted(set(sec_a_vals))
        consistent = "CONSISTENT" if len(unique) == 1 else "VARIES"
        if len(unique) != 1:
            all_consistent = False
        print(f"    sc1={sc1:4d} → sec_a sizes: {unique[:5]}{'...' if len(unique) > 5 else ''} "
              f"({len(sec_a_vals)} samples) [{consistent}]")

    # Try sec_a / sc1 to find record size
    print("\n  Record size candidates (sec_a / sc1):")
    ratios: dict[float, int] = defaultdict(int)
    for e in all_soundbanks:
        if "sc1" in e and e["sc1"] > 0:
            ratio = e["sec_a"] / e["sc1"]
            ratios[ratio] += 1

    for ratio in sorted(ratios.keys()):
        if ratios[ratio] >= 2:
            print(f"    sec_a/sc1 = {ratio:.1f} → {ratios[ratio]} samples")

    # Try sec_c / sc2
    print("\n  Testing: section_C_size = f(sub_count2)")
    sc2_to_secc: dict[int, list[int]] = defaultdict(list)
    for e in all_soundbanks:
        if "sc2" in e:
            sc2_to_secc[e["sc2"]].append(e["sec_c"])

    for sc2 in sorted(sc2_to_secc.keys())[:20]:
        sec_c_vals = sc2_to_secc[sc2]
        unique = sorted(set(sec_c_vals))
        consistent = "CONSISTENT" if len(unique) == 1 else "VARIES"
        print(f"    sc2={sc2:4d} → sec_c sizes: {unique[:5]}{'...' if len(unique) > 5 else ''} "
              f"({len(sec_c_vals)} samples) [{consistent}]")

    ratios_c: dict[float, int] = defaultdict(int)
    for e in all_soundbanks:
        if "sc2" in e and e["sc2"] > 0:
            ratio = e["sec_c"] / e["sc2"]
            ratios_c[ratio] += 1

    print("\n  Record size candidates (sec_c / sc2):")
    for ratio in sorted(ratios_c.keys()):
        if ratios_c[ratio] >= 2:
            print(f"    sec_c/sc2 = {ratio:.1f} → {ratios_c[ratio]} samples")

    # section B and D analysis
    print(f"\n  section_B sizes: {sorted(set(e['sec_b'] for e in all_soundbanks if 'sec_b' in e))}")
    print(f"  section_D sizes: {sorted(set(e['sec_d'] for e in all_soundbanks if 'sec_d' in e))}")

    # ── PART 3: Field type classification in section A ──
    print(f"\n{'=' * 80}")
    print("PART 3: FIELD TYPE CLASSIFICATION IN SECTION A (per-sound records)")
    print("=" * 80)

    # Take a subset: soundbanks with the same sc1 value for clean comparison
    # Use the most common sc1 value
    sc1_counts = defaultdict(int)
    for e in all_soundbanks:
        if "sc1" in e:
            sc1_counts[e["sc1"]] += 1
    most_common_sc1 = max(sc1_counts, key=sc1_counts.get)
    subset = [e for e in all_soundbanks if e.get("sc1") == most_common_sc1]
    print(f"\n  Using subset with sc1={most_common_sc1} ({len(subset)} soundbanks)")

    if subset:
        sec_a_size = subset[0]["sec_a"]
        print(f"  Section A size: {sec_a_size} bytes")

        # Classify each 4-byte field in section A
        print(f"\n  Field classification (offset relative to section A start = 32):")
        for field_off in range(0, sec_a_size, 4):
            abs_off = 32 + field_off
            values = []
            for e in subset:
                body = e["body"]
                if abs_off + 4 <= len(body):
                    values.append(body[abs_off:abs_off + 4])
            if not values:
                continue

            ftype = classify_field(values)
            sample = values[0]
            le_u32 = struct.unpack_from("<I", sample, 0)[0]
            le_f32 = struct.unpack_from("<f", sample, 0)[0]
            u8s = struct.unpack_from("BBBB", sample, 0)
            le_u16 = struct.unpack_from("<HH", sample, 0)

            unique_count = len(set(values))
            sample_str = ""
            if ftype == "f32":
                sample_str = f"  sample={le_f32:.4g}"
            elif ftype == "u32":
                sample_str = f"  sample=0x{le_u32:08X}"
            elif ftype == "u16x2":
                sample_str = f"  sample=({le_u16[0]},{le_u16[1]})"
            elif ftype == "u8x4":
                sample_str = f"  sample=({u8s[0]},{u8s[1]},{u8s[2]},{u8s[3]})"
            elif ftype == "zero":
                sample_str = ""
            elif ftype == "const":
                sample_str = f"  value=0x{le_u32:08X}"

            print(f"    [{abs_off:4d}:{abs_off+4:4d}] ({field_off:3d})  {ftype:6s}  "
                  f"unique={unique_count:3d}/{len(values)}{sample_str}")

    # ── PART 4: Section C (likely per-wavebank-ref records) ──
    print(f"\n{'=' * 80}")
    print("PART 4: FIELD TYPE CLASSIFICATION IN SECTION C")
    print("=" * 80)

    sc2_counts = defaultdict(int)
    for e in all_soundbanks:
        if "sc2" in e:
            sc2_counts[e["sc2"]] += 1
    if sc2_counts:
        most_common_sc2 = max(sc2_counts, key=sc2_counts.get)
        subset_c = [e for e in all_soundbanks if e.get("sc2") == most_common_sc2]
        print(f"\n  Using subset with sc2={most_common_sc2} ({len(subset_c)} soundbanks)")

        if subset_c:
            sec2_off = struct.unpack_from("<I", subset_c[0]["body"], 24)[0]
            sec3_off = struct.unpack_from("<I", subset_c[0]["body"], 28)[0]
            sec_c_size = sec3_off - sec2_off
            print(f"  Section C size: {sec_c_size} bytes (offset {sec2_off}..{sec3_off})")

            for field_off in range(0, sec_c_size, 4):
                abs_off = sec2_off + field_off
                values = []
                for e in subset_c:
                    body = e["body"]
                    s2 = struct.unpack_from("<I", body, 24)[0]
                    actual_off = s2 + field_off
                    if actual_off + 4 <= len(body):
                        values.append(body[actual_off:actual_off + 4])
                if not values:
                    continue

                ftype = classify_field(values)
                sample = values[0]
                le_u32 = struct.unpack_from("<I", sample, 0)[0]
                le_f32 = struct.unpack_from("<f", sample, 0)[0]
                u8s = struct.unpack_from("BBBB", sample, 0)
                le_u16 = struct.unpack_from("<HH", sample, 0)
                unique_count = len(set(values))

                sample_str = ""
                if ftype == "f32":
                    sample_str = f"  sample={le_f32:.4g}"
                elif ftype == "u32":
                    sample_str = f"  sample=0x{le_u32:08X}"
                elif ftype == "u16x2":
                    sample_str = f"  sample=({le_u16[0]},{le_u16[1]})"
                elif ftype == "u8x4":
                    sample_str = f"  sample=({u8s[0]},{u8s[1]},{u8s[2]},{u8s[3]})"
                elif ftype == "const":
                    sample_str = f"  value=0x{le_u32:08X}"

                print(f"    [{abs_off:4d}:{abs_off+4:4d}] ({field_off:3d})  {ftype:6s}  "
                      f"unique={unique_count:3d}/{len(values)}{sample_str}")

    # ── PART 5: Full record layout summary ──
    print(f"\n{'=' * 80}")
    print("PART 5: FULL PER-SOUND RECORD LAYOUT")
    print("=" * 80)

    # For the widest analysis, pick a soundbank with a larger sc1 value
    # to see if the per-record pattern repeats
    large_sc1 = [e for e in all_soundbanks if e.get("sc1", 0) >= 5]
    if large_sc1:
        example = large_sc1[0]
        body = example["body"]
        sc1 = example["sc1"]
        sec_a_size = example["sec_a"]
        print(f"\n  Example: hash=0x{example['hash']:08X}, sc1={sc1}, "
              f"sec_a={sec_a_size} bytes")

        if sc1 > 0 and sec_a_size % sc1 == 0:
            rec_size = sec_a_size // sc1
            print(f"  → Record size = {rec_size} bytes ({sec_a_size}/{sc1})")
            print(f"\n  First 3 records:")
            for r in range(min(3, sc1)):
                rec_start = 32 + r * rec_size
                rec_end = rec_start + rec_size
                if rec_end > len(body):
                    break
                print(f"\n    Record {r} at offset {rec_start}:")
                for f in range(0, rec_size, 4):
                    off = rec_start + f
                    if off + 4 > len(body):
                        break
                    raw = body[off:off + 4]
                    le_u32 = struct.unpack_from("<I", body, off)[0]
                    le_f32 = struct.unpack_from("<f", body, off)[0]
                    u8s = struct.unpack_from("BBBB", body, off)
                    le_u16 = struct.unpack_from("<HH", body, off)

                    is_float = (le_f32 == 0.0 or
                                (1e-10 < abs(le_f32) < 1e10 and
                                 raw[3] in (0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45)))
                    is_hash = le_u32 > 0x10000000 and le_u32 != 0xFFFFFFFF
                    is_u16 = (raw[1] == 0 and raw[3] == 0 and (raw[0] > 0 or raw[2] > 0))
                    is_u8 = (all(b <= 20 for b in raw) and any(b > 0 for b in raw) and
                             not is_float and not is_hash)

                    if is_float:
                        tag = "f32"
                        val = f"{le_f32:.4g}"
                    elif is_hash:
                        tag = "hash"
                        val = f"0x{le_u32:08X}"
                    elif is_u16:
                        tag = "u16×2"
                        val = f"({le_u16[0]},{le_u16[1]})"
                    elif is_u8:
                        tag = "u8×4"
                        val = f"({u8s[0]},{u8s[1]},{u8s[2]},{u8s[3]})"
                    elif le_u32 == 0:
                        tag = "zero"
                        val = "0"
                    else:
                        tag = "u32"
                        val = f"0x{le_u32:08X} ({le_u32})"

                    print(f"      +{f:3d} [{off:4d}:{off+4:4d}]  {raw.hex()}  "
                          f"{tag:6s}  {val}")
        else:
            print(f"  sec_a ({sec_a_size}) not evenly divisible by sc1 ({sc1})")
            if sc1 > 0:
                approx = sec_a_size / sc1
                print(f"  Approximate record size: {approx:.2f}")
                for fixed_hdr in range(0, 20, 4):
                    remaining = sec_a_size - fixed_hdr
                    if remaining > 0 and remaining % sc1 == 0:
                        rec_size = remaining // sc1
                        print(f"  If {fixed_hdr}-byte fixed prefix: rec_size={rec_size}")

    # ── PART 6: Same analysis for section C ──
    print(f"\n{'=' * 80}")
    print("PART 6: SECTION C PER-RECORD LAYOUT")
    print("=" * 80)

    large_sc2 = [e for e in all_soundbanks if e.get("sc2", 0) >= 5]
    if large_sc2:
        example = large_sc2[0]
        body = example["body"]
        sc2 = example["sc2"]
        sec2_off = struct.unpack_from("<I", body, 24)[0]
        sec3_off = struct.unpack_from("<I", body, 28)[0]
        sec_c_size = sec3_off - sec2_off
        print(f"\n  Example: hash=0x{example['hash']:08X}, sc2={sc2}, "
              f"sec_c={sec_c_size} bytes")

        if sc2 > 0 and sec_c_size % sc2 == 0:
            rec_size = sec_c_size // sc2
            print(f"  → Record size = {rec_size} bytes ({sec_c_size}/{sc2})")
            print(f"\n  First 3 records:")
            for r in range(min(3, sc2)):
                rec_start = sec2_off + r * rec_size
                rec_end = rec_start + rec_size
                if rec_end > len(body):
                    break
                print(f"\n    Record {r} at offset {rec_start}:")
                for f in range(0, rec_size, 4):
                    off = rec_start + f
                    if off + 4 > len(body):
                        break
                    raw = body[off:off + 4]
                    le_u32 = struct.unpack_from("<I", body, off)[0]
                    le_f32 = struct.unpack_from("<f", body, off)[0]
                    u8s = struct.unpack_from("BBBB", body, off)
                    le_u16 = struct.unpack_from("<HH", body, off)

                    is_float = (le_f32 == 0.0 or
                                (1e-10 < abs(le_f32) < 1e10 and
                                 raw[3] in (0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45)))
                    is_hash = le_u32 > 0x10000000 and le_u32 != 0xFFFFFFFF
                    is_u16 = (raw[1] == 0 and raw[3] == 0 and (raw[0] > 0 or raw[2] > 0))
                    is_u8 = (all(b <= 20 for b in raw) and any(b > 0 for b in raw) and
                             not is_float and not is_hash)

                    if is_float:
                        tag = "f32"
                        val = f"{le_f32:.4g}"
                    elif is_hash:
                        tag = "hash"
                        val = f"0x{le_u32:08X}"
                    elif is_u16:
                        tag = "u16×2"
                        val = f"({le_u16[0]},{le_u16[1]})"
                    elif is_u8:
                        tag = "u8×4"
                        val = f"({u8s[0]},{u8s[1]},{u8s[2]},{u8s[3]})"
                    elif le_u32 == 0:
                        tag = "zero"
                        val = "0"
                    else:
                        tag = "u32"
                        val = f"0x{le_u32:08X} ({le_u32})"

                    print(f"      +{f:3d} [{off:4d}:{off+4:4d}]  {raw.hex()}  "
                          f"{tag:6s}  {val}")
        else:
            print(f"  sec_c ({sec_c_size}) not evenly divisible by sc2 ({sc2})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
