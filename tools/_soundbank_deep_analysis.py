#!/usr/bin/env python3
"""Deep byte-level analysis of soundbank format: base game vs DLC.

Dumps every field with LE/BE/u16-pair/u8-quad interpretations,
identifies non-u32 fields by comparing against base game ground truth,
and produces a structural format specification.
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


def find_all_audio_blocks(raw: bytes, indx: list[dict], aset_off: int, aset_count: int,
                          target_type: int, type_id_filter: int) -> list[dict]:
    """Find all blocks containing a given audio type via ASET scan."""
    seen_blocks: set[int] = set()
    results = []
    for i in range(aset_count):
        off = aset_off + i * 16
        ah, _, u2, tid = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if tid == type_id_filter and block_idx not in seen_blocks:
            seen_blocks.add(block_idx)
            if block_idx < len(indx):
                try:
                    decomp = decompress_block(raw, indx[block_idx])
                except Exception:
                    continue
                if decomp:
                    entries = find_audio_entries(decomp, target_type)
                    for e in entries:
                        e["block_idx"] = block_idx
                        results.append(e)
    return results


def hexdump_line(data: bytes, offset: int = 0) -> str:
    hexstr = " ".join(f"{b:02x}" for b in data)
    ascii_str = "".join(chr(b) if 32 <= b < 127 else "." for b in data)
    return f"  {offset:04x}: {hexstr:<48s} {ascii_str}"


def analyze_field(body: bytes, offset: int, label: str = "") -> str:
    """Analyze a 4-byte field with all possible interpretations."""
    if offset + 4 > len(body):
        return f"  [{offset:3d}:{offset+4:3d}] (past end of body)"
    raw = body[offset:offset + 4]
    le_u32 = struct.unpack_from("<I", body, offset)[0]
    be_u32 = struct.unpack_from(">I", body, offset)[0]
    le_u16 = struct.unpack_from("<HH", body, offset)
    be_u16 = struct.unpack_from(">HH", body, offset)
    u8s = struct.unpack_from("BBBB", body, offset)
    le_f32 = struct.unpack_from("<f", body, offset)[0]
    be_f32 = struct.unpack_from(">f", body, offset)[0]

    parts = [
        f"[{offset:3d}:{offset+4:3d}]",
        f"raw={raw.hex()}",
        f"LE_u32=0x{le_u32:08X}({le_u32:>10d})",
        f"BE_u32=0x{be_u32:08X}({be_u32:>10d})",
        f"LE_u16=({le_u16[0]:5d},{le_u16[1]:5d})",
        f"BE_u16=({be_u16[0]:5d},{be_u16[1]:5d})",
        f"u8=({u8s[0]:3d},{u8s[1]:3d},{u8s[2]:3d},{u8s[3]:3d})",
    ]

    le_f_str = f"{le_f32:.6g}" if 1e-10 < abs(le_f32) < 1e10 else f"{le_f32:.4e}"
    be_f_str = f"{be_f32:.6g}" if 1e-10 < abs(be_f32) < 1e10 else f"{be_f32:.4e}"

    float_valid_le = 1e-10 < abs(le_f32) < 1e10 or le_f32 == 0.0
    float_valid_be = 1e-10 < abs(be_f32) < 1e10 or be_f32 == 0.0

    if float_valid_le:
        parts.append(f"LE_f32={le_f_str}")
    if float_valid_be:
        parts.append(f"BE_f32={be_f_str}")

    if label:
        parts.append(f"  # {label}")

    return "  " + "  ".join(parts)


def deep_soundbank_analysis(bodies: list[tuple[str, bytes]]):
    """Side-by-side deep analysis of multiple soundbank bodies."""
    print("\n" + "=" * 100)
    print("SOUNDBANK DEEP BYTE-LEVEL ANALYSIS")
    print("=" * 100)

    for label, body in bodies:
        print(f"\n{'─' * 80}")
        print(f"SOURCE: {label}")
        print(f"Body size: {len(body):,} bytes ({len(body)} = 0x{len(body):X})")

        # Raw hex of first 128 bytes
        print(f"\nRaw hexdump (first 128 bytes):")
        for i in range(0, min(128, len(body)), 16):
            print(hexdump_line(body[i:i + 16], i))

        # Field-by-field analysis of header
        print(f"\nField-by-field analysis (header, first 64 bytes):")
        for i in range(0, min(64, len(body)), 4):
            print(analyze_field(body, i))

        # Structural interpretation
        count_le = struct.unpack_from("<I", body, 0)[0] if len(body) >= 4 else 0
        count_be = struct.unpack_from(">I", body, 0)[0] if len(body) >= 4 else 0
        print(f"\n  Count interpretations: LE={count_le}, BE={count_be}")

        if len(body) >= 20:
            # Try to identify sections using offset fields
            for off in [16, 20, 24, 28]:
                if off + 4 <= len(body):
                    val_le = struct.unpack_from("<I", body, off)[0]
                    val_be = struct.unpack_from(">I", body, off)[0]
                    if 0 < val_le < len(body):
                        print(f"  Offset [{off}:{off+4}] LE=0x{val_le:X} ({val_le}) "
                              f"→ plausible file offset (body_size={len(body)})")
                    if 0 < val_be < len(body):
                        print(f"  Offset [{off}:{off+4}] BE=0x{val_be:X} ({val_be}) "
                              f"→ plausible file offset (body_size={len(body)})")

        # Record size inference
        count = count_le if count_le < 10000 else (count_be if count_be < 10000 else 0)
        if count > 0:
            print(f"\n  Record size inference (count={count}):")
            for hdr_size in range(20, 120, 4):
                remaining = len(body) - hdr_size
                if remaining <= 0:
                    continue
                if remaining % count == 0:
                    rec_size = remaining // count
                    if 4 <= rec_size <= 200:
                        print(f"    header={hdr_size} → record_size={rec_size} "
                              f"({count} × {rec_size} = {count * rec_size}, "
                              f"remaining={remaining})")

    # Side-by-side comparison if multiple bodies
    if len(bodies) >= 2:
        print(f"\n{'═' * 100}")
        print("SIDE-BY-SIDE COMPARISON")
        print("═" * 100)

        ref_label, ref_body = bodies[0]  # Base game = ground truth
        for comp_label, comp_body in bodies[1:]:
            print(f"\n  Comparing: {ref_label} (reference) vs {comp_label}")
            print(f"  Sizes: {len(ref_body):,} vs {len(comp_body):,}")

            max_off = min(len(ref_body), len(comp_body), 256)
            print(f"\n  Field comparison (first {max_off} bytes):")
            for i in range(0, max_off, 4):
                r = ref_body[i:i + 4]
                c = comp_body[i:i + 4]
                match = "✓ MATCH" if r == c else "✗ DIFFER"
                r_le = struct.unpack_from("<I", ref_body, i)[0]
                c_le = struct.unpack_from("<I", comp_body, i)[0]
                r_u16 = struct.unpack_from("<HH", ref_body, i)
                c_u16 = struct.unpack_from("<HH", comp_body, i)
                r_u8 = struct.unpack_from("BBBB", ref_body, i)
                c_u8 = struct.unpack_from("BBBB", comp_body, i)

                print(f"  [{i:3d}:{i+4:3d}] ref={r.hex()} comp={c.hex()} {match}")
                if r != c:
                    print(f"           ref  LE_u32=0x{r_le:08X}  u16=({r_u16[0]:5d},{r_u16[1]:5d})  "
                          f"u8=({r_u8[0]:3d},{r_u8[1]:3d},{r_u8[2]:3d},{r_u8[3]:3d})")
                    print(f"           comp LE_u32=0x{c_le:08X}  u16=({c_u16[0]:5d},{c_u16[1]:5d})  "
                          f"u8=({c_u8[0]:3d},{c_u8[1]:3d},{c_u8[2]:3d},{c_u8[3]:3d})")


def analyze_flags_field(bodies: list[tuple[str, bytes]]):
    """Specifically analyze the [8:12] flags field across all samples."""
    print(f"\n{'═' * 100}")
    print("SPECIFIC ANALYSIS: [8:12] FLAGS FIELD")
    print("═" * 100)

    for label, body in bodies:
        if len(body) < 12:
            continue
        raw = body[8:12]
        le_u32 = struct.unpack_from("<I", body, 8)[0]
        be_u32 = struct.unpack_from(">I", body, 8)[0]
        le_u16 = struct.unpack_from("<HH", body, 8)
        be_u16 = struct.unpack_from(">HH", body, 8)
        u8s = struct.unpack_from("BBBB", body, 8)

        print(f"\n  {label}:")
        print(f"    Raw bytes:     {raw.hex()} → [{raw[0]:02x} {raw[1]:02x} {raw[2]:02x} {raw[3]:02x}]")
        print(f"    As u32 LE:     0x{le_u32:08X} ({le_u32})")
        print(f"    As u32 BE:     0x{be_u32:08X} ({be_u32})")
        print(f"    As u16 LE pair: ({le_u16[0]}, {le_u16[1]}) = (0x{le_u16[0]:04X}, 0x{le_u16[1]:04X})")
        print(f"    As u16 BE pair: ({be_u16[0]}, {be_u16[1]}) = (0x{be_u16[0]:04X}, 0x{be_u16[1]:04X})")
        print(f"    As 4 × u8:     ({u8s[0]}, {u8s[1]}, {u8s[2]}, {u8s[3]})")

        # Check symmetry — if bytes[0]==bytes[2] and bytes[1]==bytes[3],
        # it's likely a u32 swap of two u16 values that were identical
        if raw[0] == raw[2] and raw[1] == raw[3]:
            print(f"    ⚠ SYMMETRIC: bytes [0:2] == bytes [2:4] "
                  f"→ likely u16 pair ({le_u16[0]}, {le_u16[1]}) with u16[0]==u16[1]")
            print(f"      OR a u32 that happens to be symmetric")
        elif raw[0] == raw[1] and raw[2] == raw[3]:
            print(f"    ⚠ PATTERN: bytes 0==1 and 2==3")


def find_float_regions(body: bytes, label: str):
    """Scan for regions that contain IEEE 754 floats."""
    print(f"\n{'─' * 60}")
    print(f"FLOAT SCAN: {label}")

    float_fields = []
    for i in range(0, len(body) - 3, 4):
        f_le = struct.unpack_from("<f", body, i)[0]
        if f_le != 0.0 and 1e-10 < abs(f_le) < 1e10:
            float_fields.append((i, f_le, "LE"))
        else:
            f_be = struct.unpack_from(">f", body, i)[0]
            if f_be != 0.0 and 1e-10 < abs(f_be) < 1e10:
                float_fields.append((i, f_be, "BE"))

    if float_fields:
        print(f"  Found {len(float_fields)} plausible float fields:")
        for off, val, endian in float_fields[:50]:
            print(f"    [{off:4d}:{off+4:4d}] {endian} f32 = {val:.6g}")
    else:
        print("  No plausible float fields found")


def scan_base_game_audio_counts(raw: bytes, chunks: dict, indx: list[dict]):
    """Count total soundbank/wavebank entries in the base game WAD."""
    aset_off, aset_count = chunks["ASET"]

    sb_count = 0
    wb_count = 0
    sb_blocks: set[int] = set()
    wb_blocks: set[int] = set()

    for i in range(aset_count):
        off = aset_off + i * 16
        _, _, u2, tid = struct.unpack_from("<IIII", raw, off)
        block_idx = (u2 >> 16) & 0xFFFF
        if tid == 21:  # soundbank
            sb_count += 1
            sb_blocks.add(block_idx)
        elif tid == 6:  # wavebank
            wb_count += 1
            wb_blocks.add(block_idx)

    return sb_count, sb_blocks, wb_count, wb_blocks


def main():
    base_path = Path("game-files/vz.wad")
    patch_path = Path("output/data/vz-patch.wad")

    if not base_path.exists():
        print(f"ERROR: Base game WAD not found: {base_path}")
        return 1

    base_raw = base_path.read_bytes()
    base_chunks = parse_ffcs(base_raw)
    base_indx = parse_indx(base_raw, base_chunks["INDX"][0], base_chunks["INDX"][1])

    # ── Part 1: Count base game audio entries ──
    print("=" * 100)
    print("PART 1: BASE GAME AUDIO INVENTORY")
    print("=" * 100)

    sb_count, sb_blocks, wb_count, wb_blocks = scan_base_game_audio_counts(
        base_raw, base_chunks, base_indx)

    print(f"\n  Soundbanks: {sb_count} ASET entries across {len(sb_blocks)} blocks")
    print(f"  Wavebanks:  {wb_count} ASET entries across {len(wb_blocks)} blocks")
    print(f"  Soundbank blocks: {sorted(sb_blocks)[:20]}{'...' if len(sb_blocks) > 20 else ''}")
    print(f"  Wavebank blocks:  {sorted(wb_blocks)[:20]}{'...' if len(wb_blocks) > 20 else ''}")

    # Get base game block paths for context
    if "PTHS" in base_chunks:
        base_paths = parse_pths(base_raw, base_chunks["PTHS"][0], base_chunks["PTHS"][1])
    else:
        base_paths = []

    # ── Part 2: Collect soundbank samples from base game ──
    print(f"\n{'=' * 100}")
    print("PART 2: COLLECTING SOUNDBANK SAMPLES")
    print("=" * 100)

    base_soundbanks = find_all_audio_blocks(
        base_raw, base_indx, base_chunks["ASET"][0], base_chunks["ASET"][1],
        _TYPE_SOUNDBANK, 21)

    print(f"\n  Found {len(base_soundbanks)} base game soundbank data bodies")
    for i, e in enumerate(base_soundbanks[:5]):
        blk = e.get("block_idx", "?")
        name = base_paths[blk] if blk < len(base_paths) else f"block_{blk}"
        print(f"    [{i}] block {blk} ({name}): hash=0x{e['hash']:08X}, "
              f"body_size={e['body_size']:,}")

    # Collect aggregate stats on [8:12] across ALL base game soundbanks
    print(f"\n{'─' * 60}")
    print("BASE GAME [8:12] FLAGS — ALL SOUNDBANKS:")
    flags_set: dict[bytes, int] = {}
    for e in base_soundbanks:
        if len(e["body"]) >= 12:
            raw_flags = e["body"][8:12]
            flags_set[raw_flags] = flags_set.get(raw_flags, 0) + 1
    for raw_flags, cnt in sorted(flags_set.items(), key=lambda x: -x[1]):
        le_u32 = struct.unpack_from("<I", raw_flags, 0)[0]
        le_u16 = struct.unpack_from("<HH", raw_flags, 0)
        u8s = struct.unpack_from("BBBB", raw_flags, 0)
        print(f"  {raw_flags.hex()} (LE_u32=0x{le_u32:08X}, "
              f"u16=({le_u16[0]:5d},{le_u16[1]:5d}), "
              f"u8=({u8s[0]:3d},{u8s[1]:3d},{u8s[2]:3d},{u8s[3]:3d})): "
              f"{cnt} occurrence(s)")

    # ── Part 3: Collect DLC soundbank samples ──
    dlc_soundbanks: list[dict] = []
    if patch_path.exists():
        patch_raw = patch_path.read_bytes()
        patch_chunks = parse_ffcs(patch_raw)
        patch_indx = parse_indx(patch_raw, patch_chunks["INDX"][0], patch_chunks["INDX"][1])

        dlc_soundbanks = find_all_audio_blocks(
            patch_raw, patch_indx, patch_chunks["ASET"][0], patch_chunks["ASET"][1],
            _TYPE_SOUNDBANK, 21)

        print(f"\n  Found {len(dlc_soundbanks)} DLC soundbank data bodies")
        for i, e in enumerate(dlc_soundbanks[:10]):
            blk = e.get("block_idx", "?")
            print(f"    [{i}] block {blk}: hash=0x{e['hash']:08X}, "
                  f"body_size={e['body_size']:,}")

        print(f"\nDLC [8:12] FLAGS — ALL SOUNDBANKS:")
        flags_set2: dict[bytes, int] = {}
        for e in dlc_soundbanks:
            if len(e["body"]) >= 12:
                raw_flags = e["body"][8:12]
                flags_set2[raw_flags] = flags_set2.get(raw_flags, 0) + 1
        for raw_flags, cnt in sorted(flags_set2.items(), key=lambda x: -x[1]):
            le_u32 = struct.unpack_from("<I", raw_flags, 0)[0]
            le_u16 = struct.unpack_from("<HH", raw_flags, 0)
            u8s = struct.unpack_from("BBBB", raw_flags, 0)
            print(f"  {raw_flags.hex()} (LE_u32=0x{le_u32:08X}, "
                  f"u16=({le_u16[0]:5d},{le_u16[1]:5d}), "
                  f"u8=({u8s[0]:3d},{u8s[1]:3d},{u8s[2]:3d},{u8s[3]:3d})): "
                  f"{cnt} occurrence(s)")

    # ── Part 4: Deep analysis ──
    samples: list[tuple[str, bytes]] = []
    if base_soundbanks:
        blk = base_soundbanks[0].get("block_idx", "?")
        name = base_paths[blk] if isinstance(blk, int) and blk < len(base_paths) else str(blk)
        samples.append((f"BASE block {blk} ({name})", base_soundbanks[0]["body"]))
    if len(base_soundbanks) > 1:
        blk = base_soundbanks[1].get("block_idx", "?")
        name = base_paths[blk] if isinstance(blk, int) and blk < len(base_paths) else str(blk)
        samples.append((f"BASE block {blk} ({name})", base_soundbanks[1]["body"]))
    for e in dlc_soundbanks[:3]:
        blk = e.get("block_idx", "?")
        samples.append((f"DLC block {blk}", e["body"]))

    deep_soundbank_analysis(samples)
    analyze_flags_field(samples)

    # Float scan on first base game soundbank
    if base_soundbanks:
        find_float_regions(base_soundbanks[0]["body"],
                           f"BASE block {base_soundbanks[0].get('block_idx', '?')}")

    # ── Part 5: Section offset analysis ──
    print(f"\n{'═' * 100}")
    print("PART 5: SECTION OFFSET / RECORD STRUCTURE ANALYSIS")
    print("═" * 100)

    for label, body in samples[:3]:
        print(f"\n{'─' * 60}")
        print(f"  {label} (size={len(body)})")

        if len(body) < 32:
            print("    Too short for section analysis")
            continue

        count = struct.unpack_from("<I", body, 0)[0]
        if count > 10000:
            print(f"    Count {count} too large, skipping")
            continue

        # Read potential offset fields at [16:32]
        for off in [16, 20, 24, 28]:
            if off + 4 <= len(body):
                val = struct.unpack_from("<I", body, off)[0]
                if 0 < val < len(body):
                    print(f"    Offset at [{off}:{off+4}] = {val} (0x{val:X})")
                    # Dump 32 bytes at that offset
                    end = min(val + 64, len(body))
                    print(f"    Data at offset {val}:")
                    for i in range(val, end, 16):
                        chunk = body[i:min(i + 16, end)]
                        if chunk:
                            print(hexdump_line(chunk, i))

        # Try to identify the record structure starting from offset 32
        print(f"\n    Scanning from offset 32 for repeating patterns:")
        if len(body) > 32:
            # Look for hashes (u32 values that look like pandemic_hash output)
            hash_candidates = []
            for i in range(32, min(len(body) - 3, 256), 4):
                val = struct.unpack_from("<I", body, i)[0]
                if val > 0x10000000 and val != 0xFFFFFFFF:
                    hash_candidates.append((i, val))
            if hash_candidates:
                print(f"    Potential hash values (large u32s):")
                for off, val in hash_candidates[:15]:
                    print(f"      [{off:4d}] 0x{val:08X}")

                # Check spacing between hash candidates
                if len(hash_candidates) >= 3:
                    spacings = [hash_candidates[i+1][0] - hash_candidates[i][0]
                                for i in range(min(10, len(hash_candidates) - 1))]
                    print(f"    Spacings between hashes: {spacings}")

    # ── Part 6: Determine field types for soundbank format ──
    print(f"\n{'═' * 100}")
    print("PART 6: FORMAT VERDICT — IS [8:12] u32 OR u16×2 OR u8×4?")
    print("═" * 100)

    all_base_flags: list[bytes] = [e["body"][8:12] for e in base_soundbanks if len(e["body"]) >= 12]
    all_dlc_flags: list[bytes] = [e["body"][8:12] for e in dlc_soundbanks if len(e["body"]) >= 12]

    # Test 1: Are the base game values consistent with u32?
    base_u32_vals = set(struct.unpack_from("<I", f, 0)[0] for f in all_base_flags)
    print(f"\n  Base game [8:12] unique u32 LE values: {len(base_u32_vals)}")
    for v in sorted(base_u32_vals):
        hi = (v >> 16) & 0xFFFF
        lo = v & 0xFFFF
        print(f"    0x{v:08X} → hi_u16={hi} lo_u16={lo}")

    # Test 2: Do the u16 sub-fields have independent distributions?
    base_lo: set[int] = set()
    base_hi: set[int] = set()
    for f in all_base_flags:
        lo, hi = struct.unpack_from("<HH", f, 0)
        base_lo.add(lo)
        base_hi.add(hi)
    print(f"\n  Base game u16 LE[0] unique values: {sorted(base_lo)}")
    print(f"  Base game u16 LE[1] unique values: {sorted(base_hi)}")

    if len(base_lo) > 1 or len(base_hi) > 1:
        print("\n  → u16 sub-fields vary independently → LIKELY u16×2 (not u32)")
    elif base_lo == base_hi:
        print("\n  → u16 sub-fields identical → COULD BE u32 or u16×2 where both happen to match")
    else:
        print("\n  → Insufficient variation to determine — testing cross-correlation")

    # Test 3: Does ANY DLC value match ANY base game value?
    dlc_u32_vals = set(struct.unpack_from("<I", f, 0)[0] for f in all_dlc_flags)
    overlap = base_u32_vals & dlc_u32_vals
    print(f"\n  DLC [8:12] unique u32 LE values: {len(dlc_u32_vals)}")
    for v in sorted(dlc_u32_vals):
        hi = (v >> 16) & 0xFFFF
        lo = v & 0xFFFF
        in_base = "✓ MATCHES BASE" if v in base_u32_vals else "✗ NOT IN BASE"
        print(f"    0x{v:08X} → hi_u16={hi} lo_u16={lo}  {in_base}")

    print(f"\n  Overlap with base game: {len(overlap)} values")

    # Test 4: Check if DLC u16 sub-fields fall within base game ranges
    dlc_lo: set[int] = set()
    dlc_hi: set[int] = set()
    for f in all_dlc_flags:
        lo, hi = struct.unpack_from("<HH", f, 0)
        dlc_lo.add(lo)
        dlc_hi.add(hi)
    print(f"\n  DLC u16 LE[0] values: {sorted(dlc_lo)}")
    print(f"  DLC u16 LE[1] values: {sorted(dlc_hi)}")

    # Final verdict
    print(f"\n{'─' * 60}")
    print("VERDICT:")
    if len(base_u32_vals) == 1 and list(base_u32_vals)[0] == 0x00010001:
        base_val = list(base_u32_vals)[0]
        print(f"  Base game always has [8:12] = 0x{base_val:08X}")
        print(f"  This is u16 pair (1, 1) if read as two u16 LE values")
        print(f"  The DLC values differ significantly — the blind u32 BE→LE swap")
        print(f"  is ONLY correct if the original Xbox bytes form a coherent u32.")
        print(f"  If the Xbox source has two u16 BE fields, the u32 swap corrupts them.")

        # Reverse-engineer what the Xbox source bytes would have been
        print(f"\n  Reverse-engineering Xbox source bytes:")
        for f in all_dlc_flags:
            le_u32 = struct.unpack_from("<I", f, 0)[0]
            # Current DLC value was produced by BE→LE u32 swap
            # So the Xbox bytes were the BE representation of le_u32
            xbox_raw = struct.pack(">I", le_u32)
            # If field is actually u16×2 BE, the Xbox values would be:
            xbox_u16 = struct.unpack_from(">HH", xbox_raw, 0)
            # If we had done u16×2 BE→LE swap instead:
            correct_le = struct.pack("<HH", xbox_u16[0], xbox_u16[1])
            correct_le_u16 = struct.unpack_from("<HH", correct_le, 0)
            print(f"    DLC output: {f.hex()} (LE u32 = 0x{le_u32:08X})")
            print(f"    Xbox source (as u32 BE): {xbox_raw.hex()}")
            print(f"    Xbox source (as u16 BE pair): ({xbox_u16[0]}, {xbox_u16[1]})")
            print(f"    If u16×2 swap: would produce ({correct_le_u16[0]}, {correct_le_u16[1]}) "
                  f"= {correct_le.hex()}")
            # Check if u16 values make sense (small counts, like the base game's (1,1))
            if all(v < 1000 for v in xbox_u16):
                print(f"    ⚠ Xbox u16 values are small → u16×2 interpretation is PLAUSIBLE")
            else:
                print(f"    Xbox u16 values are large → u32 interpretation may be correct")

    return 0


if __name__ == "__main__":
    sys.exit(main())
