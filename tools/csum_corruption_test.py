#!/usr/bin/env python3
"""Test whether per-UCFX CSUM trailers are validated at runtime.

Creates two modified copies of a decompressed block file:
  1. ``test_corrupt_csum.block.bin`` — CSUM changed to 0xDEADBEEF (same data)
  2. ``test_corrupt_data.block.bin`` — one byte of LuaQ bytecode changed,
     CSUM correctly recomputed

Each modified block is then sges-compressed and patched into a copy of the
WAD file for manual game testing.

Usage:
  python3 tools/csum_corruption_test.py \
    --scripts-block output_demo/extracted/scripts_vz_demo.block.bin \
    --wad "Mercenaries 2 World in Flames DEMO/data/vz.wad" \
    --block-index 1257 \
    --out-dir output_demo/csum_test
"""

from __future__ import annotations

import argparse
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sges_compress import compress_sges  # noqa: E402
from wad_patcher import patch_inplace  # noqa: E402


CSUM_TAG = b"CSUM"
LUAQ_SIG = b"LuaQ"


def crc32_jamcrc(data: bytes) -> int:
    """CRC-32/JAMCRC: init=0, poly 0xEDB88320, no final XOR."""
    crc = 0
    for b in data:
        crc ^= b
        for _ in range(8):
            crc = (crc >> 1) ^ (0xEDB88320 if crc & 1 else 0)
    return crc


def parse_block_entries(data: bytes) -> list[dict]:
    """Parse the block header: count(4) + count * entry(16).

    Each entry: u32 hash, u32 magic, u32 zero, u32 size.
    Returns list of dicts with hash, size, offset (absolute in block), csum_offset.
    """
    count = struct.unpack_from("<I", data, 0)[0]
    header_end = 4 + count * 16

    entries = []
    pos = header_end
    for i in range(count):
        h, m, z, s = struct.unpack_from("<IIII", data, 4 + i * 16)
        entry_start = pos
        csum_off = pos + s - 8
        entries.append({
            "index": i,
            "hash": h,
            "size": s,
            "offset": entry_start,
            "csum_offset": csum_off,
        })
        pos += s
    return entries


def get_script_name(data: bytes, entry: dict) -> str:
    """Extract the script name from a BINN section within an entry."""
    chunk = data[entry["offset"]:entry["offset"] + entry["size"] - 8]
    binn_off = chunk.find(b"BINN")
    if binn_off < 0:
        return "(unknown)"
    region = chunk[binn_off + 4:binn_off + 200]
    i = 0
    while i < len(region):
        if 32 <= region[i] < 127:
            j = i
            while j < len(region) and 32 <= region[j] < 127:
                j += 1
            s = region[i:j].decode("ascii")
            if len(s) >= 4 and s != "BINN" and s != "LuaQ":
                return s
            i = j
        else:
            i += 1
    return "(unknown)"


def verify_all_csums(data: bytes, entries: list[dict]) -> tuple[int, int]:
    """Verify all CSUM trailers match CRC-32/JAMCRC. Returns (ok, bad)."""
    ok = bad = 0
    for e in entries:
        csum_off = e["csum_offset"]
        if data[csum_off:csum_off + 4] != CSUM_TAG:
            bad += 1
            continue
        stored = struct.unpack_from("<I", data, csum_off + 4)[0]
        ucfx_data = data[e["offset"]:csum_off]
        computed = crc32_jamcrc(ucfx_data)
        if computed == stored:
            ok += 1
        else:
            bad += 1
    return ok, bad


def main() -> int:
    ap = argparse.ArgumentParser(
        description="Prepare CSUM enforcement test files for manual game testing"
    )
    ap.add_argument("--scripts-block", type=Path, required=True,
                    help="Decompressed scripts_vz block file")
    ap.add_argument("--wad", type=Path, default=None,
                    help="Original vz.wad file (optional; for WAD patching)")
    ap.add_argument("--block-index", type=int, default=None,
                    help="Block index of scripts_vz in the WAD (for WAD patching)")
    ap.add_argument("--out-dir", type=Path, default=Path("output_demo/csum_test"),
                    help="Output directory for test files")
    ap.add_argument("--entry-index", type=int, default=0,
                    help="Which UCFX entry to modify (default: 0 = wiftutorialtank)")
    ap.add_argument("--segment-size", type=int, default=65536,
                    help="sges segment size for recompression")
    args = ap.parse_args()

    if not args.scripts_block.is_file():
        print(f"error: block file not found: {args.scripts_block}", file=sys.stderr)
        return 1

    data = args.scripts_block.read_bytes()
    entries = parse_block_entries(data)
    print(f"Block: {args.scripts_block} ({len(data):,} bytes)")
    print(f"UCFX entries: {len(entries)}")

    ok, bad = verify_all_csums(data, entries)
    print(f"CSUM verification: {ok} OK, {bad} bad")
    if bad > 0:
        print("WARNING: some CSUMs don't match — block may already be corrupted",
              file=sys.stderr)

    target = entries[args.entry_index]
    script_name = get_script_name(data, target)
    csum_off = target["csum_offset"]
    stored_csum = struct.unpack_from("<I", data, csum_off + 4)[0]

    print(f"\nTarget entry [{args.entry_index}]: {script_name}")
    print(f"  Hash:     0x{target['hash']:08X}")
    print(f"  Size:     {target['size']} bytes")
    print(f"  Offset:   0x{target['offset']:08x}")
    print(f"  CSUM at:  0x{csum_off:08x}")
    print(f"  CSUM val: 0x{stored_csum:08X}")

    # Find LuaQ bytecode within this entry
    chunk = data[target["offset"]:target["offset"] + target["size"] - 8]
    luaq_rel = chunk.find(LUAQ_SIG)
    if luaq_rel < 0:
        print("error: no LuaQ signature in target entry", file=sys.stderr)
        return 1

    luaq_abs = target["offset"] + luaq_rel
    print(f"  LuaQ at:  0x{luaq_abs:08x} (entry +{luaq_rel})")

    args.out_dir.mkdir(parents=True, exist_ok=True)

    # ── Test 1: Corrupt CSUM (same data, bad checksum) ───────────
    print("\n" + "=" * 60)
    print("TEST 1: Corrupt CSUM — same data, CSUM set to 0xDEADBEEF")
    print("=" * 60)

    data1 = bytearray(data)
    struct.pack_into("<I", data1, csum_off + 4, 0xDEADBEEF)

    verify1_stored = struct.unpack_from("<I", data1, csum_off + 4)[0]
    verify1_computed = crc32_jamcrc(bytes(data1[target["offset"]:csum_off]))
    print(f"  Stored CSUM:   0x{verify1_stored:08X} (should be 0xDEADBEEF)")
    print(f"  Computed CSUM: 0x{verify1_computed:08X} (should still be 0x{stored_csum:08X})")
    print(f"  Mismatch:      {verify1_stored != verify1_computed}")

    out1_block = args.out_dir / "test_corrupt_csum.block.bin"
    out1_block.write_bytes(bytes(data1))
    print(f"  Block: {out1_block}")

    # ── Test 2: Corrupt data + fix CSUM ──────────────────────────
    print("\n" + "=" * 60)
    print("TEST 2: Corrupt data — one LuaQ byte changed, CSUM recomputed")
    print("=" * 60)

    data2 = bytearray(data)

    # Flip one byte 16 bytes into the LuaQ bytecode (past the Lua header)
    flip_offset = luaq_abs + 16
    old_byte = data2[flip_offset]
    new_byte = old_byte ^ 0xFF
    data2[flip_offset] = new_byte
    print(f"  Modified byte at 0x{flip_offset:08x}: 0x{old_byte:02X} -> 0x{new_byte:02X}")

    # Recompute CSUM for this entry
    ucfx_region = bytes(data2[target["offset"]:csum_off])
    new_csum = crc32_jamcrc(ucfx_region)
    struct.pack_into("<I", data2, csum_off + 4, new_csum)

    verify2_stored = struct.unpack_from("<I", data2, csum_off + 4)[0]
    verify2_computed = crc32_jamcrc(bytes(data2[target["offset"]:csum_off]))
    print(f"  New CSUM:      0x{new_csum:08X} (was 0x{stored_csum:08X})")
    print(f"  Verify match:  {verify2_stored == verify2_computed}")

    out2_block = args.out_dir / "test_corrupt_data.block.bin"
    out2_block.write_bytes(bytes(data2))
    print(f"  Block: {out2_block}")

    # ── WAD patching (if requested) ──────────────────────────────
    if args.wad and args.wad.is_file() and args.block_index is not None:
        print("\n" + "=" * 60)
        print("WAD PATCHING")
        print("=" * 60)

        for label, block_path in [
            ("corrupt_csum", out1_block),
            ("corrupt_data", out2_block),
        ]:
            raw = block_path.read_bytes()
            print(f"\nCompressing {label}...")
            compressed = compress_sges(raw, segment_size=args.segment_size)
            ratio = len(compressed) / len(raw) * 100
            print(f"  Compressed: {len(compressed):,} bytes ({ratio:.1f}%)")

            out_wad = args.out_dir / f"vz_{label}.wad"
            print(f"  Patching block {args.block_index} -> {out_wad}...")
            result = patch_inplace(
                args.wad, out_wad, args.block_index, compressed
            )
            print(f"  Strategy: {result['strategy']}")
            print(f"  Output:   {out_wad}")

    # ── Instructions ─────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("TESTING INSTRUCTIONS")
    print("=" * 60)
    print()
    print("Two test WAD files have been created (if --wad was provided):")
    print()
    print(f"  1. vz_corrupt_csum.wad")
    print(f"     CSUM of entry [{args.entry_index}] ({script_name}) set to 0xDEADBEEF.")
    print(f"     Actual script data is UNCHANGED.")
    print(f"     Tests: does the game validate CSUM at load time?")
    print()
    print(f"  2. vz_corrupt_data.wad")
    print(f"     One byte of {script_name}'s LuaQ bytecode flipped.")
    print(f"     CSUM correctly recomputed to match.")
    print(f"     Tests: does the game load modified content when CSUM is valid?")
    print()
    print("To test:")
    print(f"  1. Back up the original vz.wad")
    print(f"  2. Copy the test WAD over vz.wad in the demo's data/ folder")
    print(f"  3. Launch the demo")
    print(f"  4. Start a new game / reach the tutorial tank sequence")
    print()
    print("Expected outcomes:")
    print(f"  Test 1 (corrupt CSUM):")
    print(f"    A) Game loads normally -> CSUM NOT enforced at runtime")
    print(f"    B) Game crashes / corrupt data error -> CSUM IS enforced")
    print(f"    C) Script doesn't execute -> CSUM used as lookup key")
    print()
    print(f"  Test 2 (corrupt data, valid CSUM):")
    print(f"    A) Game crashes at script load (Lua VM error)")
    print(f"       -> Game loads bytecode; our byte flip broke it")
    print(f"    B) Game ignores the script (tutorial doesn't trigger)")
    print(f"       -> Script was silently skipped")
    print(f"    C) Game loads normally but tutorial is glitchy")
    print(f"       -> Bytecode loaded; our flip changed behavior")
    print()
    print("If both tests produce outcome A: modding is straightforward")
    print("  — patch decompressed blocks, recompute CSUMs, repack WAD.")

    # Also create test files without WAD patching for manual use
    if not args.wad or not args.wad.is_file():
        print()
        print("To create patched WADs, re-run with --wad and --block-index:")
        print(f"  python3 tools/csum_corruption_test.py \\")
        print(f"    --scripts-block {args.scripts_block} \\")
        print(f"    --wad \"Mercenaries 2 World in Flames DEMO/data/vz.wad\" \\")
        print(f"    --block-index 1257 \\")
        print(f"    --out-dir {args.out_dir}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
