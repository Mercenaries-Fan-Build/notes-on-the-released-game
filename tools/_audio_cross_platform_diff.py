#!/usr/bin/env python3
r"""Cross-platform byte-level diff of soundbank/wavebank entries.

Compares Xbox 360 (BE) and PC (LE) base game audio entries to produce
a definitive field-type map for the soundbank/wavebank converters.

For each matching hash found in both WADs:
  - Extracts the data body from both platforms
  - Compares every 4-byte group to classify as:
      u32/f32 (all 4 bytes reversed)
      u16x2   (each 2-byte pair reversed, but pair order preserved)
      u8x4    (identical bytes on both platforms)
      mixed   (partial reversal — indicates misaligned fields)
  - Outputs the definitive field-type map

Usage:
  python tools/_audio_cross_platform_diff.py \
    --pc-wad game-files/vz.wad \
    --xbox-wad <path-to-xbox-vz.wad> \
    [--output analysis/audio_format]
"""
from __future__ import annotations

import argparse
import struct
import sys
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

PAGE_SIZE = 0x8000
FFCS_MAGIC = b"FFCS"
SCFF_MAGIC = b"SCFF"
SGES_MAGIC = b"sges"
SEGS_MAGIC = b"segs"

_TYPE_SOUNDBANK = 0x9F8BCA10
_TYPE_WAVEBANK = 0xF753F6D0

_AUDIO_TYPES = {_TYPE_SOUNDBANK, _TYPE_WAVEBANK}
_TYPE_NAMES = {_TYPE_SOUNDBANK: "soundbank", _TYPE_WAVEBANK: "wavebank"}


# ── WAD parsing (both endiannesses) ──────────────────────────────────

@dataclass
class WADContext:
    data: bytes
    endian: str  # "le" or "be"
    indx: list[dict]
    aset_entries: list[dict]

    def fmt(self, spec: str) -> str:
        return f"<{spec}" if self.endian == "le" else f">{spec}"


def _parse_ffcs_header(raw: bytes) -> tuple[str, int, list[dict]]:
    """Parse FFCS/SCFF header, return (endian, version, chunk_rows)."""
    if raw[:4] == FFCS_MAGIC:
        endian = "le"
    elif raw[:4] == SCFF_MAGIC:
        endian = "be"
    else:
        raise ValueError(f"Unknown magic: {raw[:4]!r}")

    fmt = "<" if endian == "le" else ">"
    version = struct.unpack_from(f"{fmt}I", raw, 4)[0]
    chunk_count = struct.unpack_from(f"{fmt}I", raw, 8)[0]

    chunks = []
    for i in range(min(chunk_count, 7)):
        off = 0x0C + i * 12
        tag_raw = raw[off:off + 4]
        tag = tag_raw[::-1].decode("ascii", errors="replace") if endian == "be" else tag_raw.decode("ascii", errors="replace")
        val = struct.unpack_from(f"{fmt}I", raw, off + 4)[0]
        meta = struct.unpack_from(f"{fmt}I", raw, off + 8)[0]
        if tag.strip("\x00"):
            chunks.append({"tag": tag, "offset": val, "meta": meta})
    return endian, version, chunks


def _parse_indx(raw: bytes, off: int, n: int, endian: str) -> list[dict]:
    fmt = "<" if endian == "le" else ">"
    entries = []
    for i in range(n):
        o = off + i * 12
        pi, pk, fp = struct.unpack_from(f"{fmt}III", raw, o)
        entries.append({
            "page_idx": pi, "packed": pk,
            "page_count": fp & 0xFFFF, "flags": (fp >> 16) & 0xFFFF,
        })
    return entries


def _parse_aset(raw: bytes, off: int, n: int, endian: str) -> list[dict]:
    fmt = "<" if endian == "le" else ">"
    entries = []
    for i in range(n):
        o = off + i * 16
        if endian == "be":
            u0, u1, u2 = struct.unpack_from(">III", raw, o)
            u3 = struct.unpack_from("<I", raw, o + 12)[0]  # type_id is always LE
        else:
            u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, o)
        entries.append({
            "hash": u0, "u1": u1, "u2": u2, "type_id": u3,
            "block_idx": (u2 >> 16) & 0xFFFF,
        })
    return entries


def _decompress_block(raw: bytes, entry: dict, endian: str) -> bytes | None:
    """Decompress a block from a WAD."""
    offset = entry["page_idx"] * PAGE_SIZE
    page_count = entry["page_count"]
    size = page_count * PAGE_SIZE
    if offset + size > len(raw):
        return None
    block_data = raw[offset:offset + size]

    if endian == "le":
        if block_data[:4] != SGES_MAGIC:
            return None
        from sges_decompress import decompress_sges_block
        return decompress_sges_block(block_data, 0, len(block_data))
    else:
        if block_data[:4] != SEGS_MAGIC:
            return None
        from x360_dlc_io import decompress_be_sges
        return decompress_be_sges(raw, offset, size)


def _extract_audio_bodies(decomp: bytes, endian: str) -> list[dict]:
    """Extract soundbank/wavebank data bodies from a decompressed block."""
    fmt = "<" if endian == "le" else ">"
    entry_count = struct.unpack_from(f"{fmt}I", decomp, 0)[0]

    # Sanity check
    if entry_count > 1000 or entry_count * 16 + 4 > len(decomp):
        return []

    results = []
    pos = 4 + entry_count * 16
    for i in range(entry_count):
        eoff = 4 + i * 16
        h, th, o, sz = struct.unpack_from(f"{fmt}IIII", decomp, eoff)
        if th in _AUDIO_TYPES:
            container = decomp[pos:pos + sz]
            # Strip CSUM trailer
            csum_tag = b"CSUM" if endian == "le" else b"MUSC"
            if len(container) >= 8 and container[-8:-4] == csum_tag:
                container = container[:-8]
            # Parse UCFX
            ucfx_magic = b"UCFX" if endian == "le" else b"XFCU"
            if len(container) >= 4 and container[:4] == ucfx_magic:
                ucfx_data_off = struct.unpack_from(f"{fmt}I", container, 4)[0]
                n_desc = struct.unpack_from(f"{fmt}I", container, 16)[0]
                for d in range(n_desc):
                    doff = 20 + d * 20
                    dtag_raw = container[doff:doff + 4]
                    dtag = dtag_raw[::-1].decode("ascii", "replace") if endian == "be" else dtag_raw.decode("ascii", "replace")
                    du0 = struct.unpack_from(f"{fmt}I", container, doff + 4)[0]
                    dsz = struct.unpack_from(f"{fmt}I", container, doff + 8)[0]
                    if dtag == "data" and du0 != 0xFFFFFFFF:
                        body_start = ucfx_data_off + du0
                        body = container[body_start:body_start + dsz]
                        results.append({
                            "hash": h,
                            "type_hash": th,
                            "type_name": _TYPE_NAMES.get(th, f"0x{th:08X}"),
                            "body": body,
                            "body_size": dsz,
                        })
        pos += sz
    return results


def load_wad(path: Path) -> WADContext:
    """Load and parse a WAD file (auto-detects endianness)."""
    raw = path.read_bytes()
    endian, version, chunks = _parse_ffcs_header(raw)

    chunk_map = {c["tag"]: c for c in chunks}

    indx_chunk = chunk_map.get("INDX")
    aset_chunk = chunk_map.get("ASET")

    if not indx_chunk or not aset_chunk:
        raise ValueError(f"WAD missing INDX or ASET chunk: {path}")

    indx = _parse_indx(raw, indx_chunk["offset"], indx_chunk["meta"], endian)
    aset = _parse_aset(raw, aset_chunk["offset"], aset_chunk["meta"], endian)

    print(f"  Loaded: {path.name} ({endian.upper()}, {len(raw):,} bytes, "
          f"{len(indx)} blocks, {len(aset)} ASET entries)")

    return WADContext(data=raw, endian=endian, indx=indx, aset_entries=aset)


def collect_audio_bodies(ctx: WADContext) -> dict[tuple[int, int], bytes]:
    """Collect all audio data bodies keyed by (hash, type_hash)."""
    # Find blocks containing audio via ASET
    audio_blocks: set[int] = set()
    for e in ctx.aset_entries:
        if e["type_id"] in (6, 21):  # wavebank=6, soundbank=21
            audio_blocks.add(e["block_idx"])

    bodies: dict[tuple[int, int], bytes] = {}
    for blk_idx in sorted(audio_blocks):
        if blk_idx >= len(ctx.indx):
            continue
        try:
            decomp = _decompress_block(ctx.data, ctx.indx[blk_idx], ctx.endian)
        except Exception:
            continue
        if not decomp:
            continue
        entries = _extract_audio_bodies(decomp, ctx.endian)
        for e in entries:
            key = (e["hash"], e["type_hash"])
            if key not in bodies:
                bodies[key] = e["body"]
    return bodies


# ── Byte-level comparison ────────────────────────────────────────────

def classify_4byte_diff(xbox_bytes: bytes, pc_bytes: bytes) -> str:
    """Classify a 4-byte field based on how Xbox (BE) maps to PC (LE).

    Returns: 'u32' (full reversal), 'u16x2' (two pairs reversed),
             'u8x4' (identical), 'zero' (both zero), or 'mixed'.
    """
    if xbox_bytes == pc_bytes == b'\x00\x00\x00\x00':
        return "zero"
    if xbox_bytes == pc_bytes:
        return "u8x4"
    if xbox_bytes == pc_bytes[::-1]:
        return "u32"
    # Check u16x2: Xbox [A,B,C,D] → PC [B,A,D,C]
    if (xbox_bytes[0] == pc_bytes[1] and xbox_bytes[1] == pc_bytes[0] and
            xbox_bytes[2] == pc_bytes[3] and xbox_bytes[3] == pc_bytes[2]):
        return "u16x2"
    return "mixed"


@dataclass
class FieldClassification:
    offset: int
    classifications: dict[str, int]  # type → count

    @property
    def dominant_type(self) -> str:
        if not self.classifications:
            return "unknown"
        return max(self.classifications, key=self.classifications.get)

    @property
    def is_ambiguous(self) -> bool:
        non_zero = {k: v for k, v in self.classifications.items() if k != "zero"}
        return len(non_zero) > 1


def diff_audio_bodies(
    xbox_bodies: dict[tuple[int, int], bytes],
    pc_bodies: dict[tuple[int, int], bytes],
) -> dict[str, list[FieldClassification]]:
    """Compare matched audio bodies and classify each field position."""

    matched = set(xbox_bodies.keys()) & set(pc_bodies.keys())
    sb_matches = [(k, xbox_bodies[k], pc_bodies[k])
                  for k in sorted(matched) if k[1] == _TYPE_SOUNDBANK]
    wb_matches = [(k, xbox_bodies[k], pc_bodies[k])
                  for k in sorted(matched) if k[1] == _TYPE_WAVEBANK]

    results: dict[str, list[FieldClassification]] = {}

    for type_name, matches in [("soundbank", sb_matches), ("wavebank", wb_matches)]:
        if not matches:
            continue

        max_size = max(min(len(xb), len(pb)) for _, xb, pb in matches)
        field_classes: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))

        for (key, xbox_body, pc_body), _ in zip(matches, range(len(matches))):
            common_len = min(len(xbox_body), len(pc_body))
            for off in range(0, common_len - 3, 4):
                xb = xbox_body[off:off + 4]
                pb = pc_body[off:off + 4]
                cls = classify_4byte_diff(xb, pb)
                field_classes[off][cls] += 1

        fields = []
        for off in sorted(field_classes.keys()):
            fields.append(FieldClassification(
                offset=off,
                classifications=dict(field_classes[off]),
            ))
        results[type_name] = fields

    return results


# ── Output formatting ────────────────────────────────────────────────

def print_field_map(results: dict[str, list[FieldClassification]],
                    xbox_bodies: dict, pc_bodies: dict):
    """Print the definitive field-type map."""
    matched = set(xbox_bodies.keys()) & set(pc_bodies.keys())
    sb_matched = sum(1 for k in matched if k[1] == _TYPE_SOUNDBANK)
    wb_matched = sum(1 for k in matched if k[1] == _TYPE_WAVEBANK)

    print(f"\n{'=' * 80}")
    print("CROSS-PLATFORM AUDIO FORMAT COMPARISON RESULTS")
    print(f"{'=' * 80}")
    print(f"\n  Matched soundbanks: {sb_matched}")
    print(f"  Matched wavebanks:  {wb_matched}")

    for type_name, fields in results.items():
        print(f"\n{'─' * 80}")
        print(f"  {type_name.upper()} FIELD MAP ({len(fields)} 4-byte fields analyzed)")
        print(f"{'─' * 80}")

        # Header fields (first 32 bytes)
        print(f"\n  HEADER (first 32 bytes):")
        for f in fields:
            if f.offset >= 32:
                break
            dom = f.dominant_type
            amb = " ⚠ AMBIGUOUS" if f.is_ambiguous else ""
            counts = ", ".join(f"{k}:{v}" for k, v in sorted(f.classifications.items()))
            print(f"    [{f.offset:4d}:{f.offset+4:4d}] {dom:6s}  ({counts}){amb}")

        # Record area — group by dominant type and look for patterns
        print(f"\n  RECORD AREA (offset 32+):")
        u8_offsets = []
        u16_offsets = []
        u32_offsets = []
        mixed_offsets = []

        for f in fields:
            if f.offset < 32:
                continue
            dom = f.dominant_type
            if dom == "u8x4":
                u8_offsets.append(f.offset)
            elif dom == "u16x2":
                u16_offsets.append(f.offset)
            elif dom in ("u32", "zero"):
                u32_offsets.append(f.offset)
            elif dom == "mixed":
                mixed_offsets.append(f.offset)

        total_record = len([f for f in fields if f.offset >= 32])
        print(f"    u32/f32 fields: {len(u32_offsets)} "
              f"({100 * len(u32_offsets) / max(total_record, 1):.1f}%)")
        print(f"    u8x4 fields:    {len(u8_offsets)} "
              f"({100 * len(u8_offsets) / max(total_record, 1):.1f}%)")
        print(f"    u16x2 fields:   {len(u16_offsets)} "
              f"({100 * len(u16_offsets) / max(total_record, 1):.1f}%)")
        print(f"    mixed fields:   {len(mixed_offsets)} "
              f"({100 * len(mixed_offsets) / max(total_record, 1):.1f}%)")

        if u8_offsets:
            print(f"\n    u8x4 field offsets (MUST NOT be u32-swapped):")
            for off in u8_offsets[:50]:
                f = next(x for x in fields if x.offset == off)
                counts = ", ".join(f"{k}:{v}" for k, v in sorted(f.classifications.items()))
                print(f"      [{off:4d}:{off+4:4d}]  ({counts})")

        if u16_offsets:
            print(f"\n    u16x2 field offsets (need u16 pair swap, not u32):")
            for off in u16_offsets[:50]:
                f = next(x for x in fields if x.offset == off)
                counts = ", ".join(f"{k}:{v}" for k, v in sorted(f.classifications.items()))
                print(f"      [{off:4d}:{off+4:4d}]  ({counts})")

        if mixed_offsets:
            print(f"\n    mixed field offsets (irregular pattern — needs manual review):")
            for off in mixed_offsets[:30]:
                f = next(x for x in fields if x.offset == off)
                counts = ", ".join(f"{k}:{v}" for k, v in sorted(f.classifications.items()))
                print(f"      [{off:4d}:{off+4:4d}]  ({counts})")

        # Detailed dump of first 128 bytes for all fields
        print(f"\n  DETAILED FIELD DUMP (first 128 bytes of record area):")
        for f in fields:
            if f.offset < 32 or f.offset >= 160:
                continue
            dom = f.dominant_type
            amb = " ⚠" if f.is_ambiguous else ""
            counts = ", ".join(f"{k}:{v}" for k, v in sorted(f.classifications.items()))
            print(f"    [{f.offset:4d}:{f.offset+4:4d}] {dom:6s}  ({counts}){amb}")

    # Generate converter field map as Python code
    print(f"\n{'=' * 80}")
    print("CONVERTER FIELD MAP (copy-paste into ucfx_be_to_le.py)")
    print(f"{'=' * 80}")

    for type_name, fields in results.items():
        u8_set = set()
        u16_set = set()
        for f in fields:
            dom = f.dominant_type
            if dom == "u8x4":
                u8_set.add(f.offset)
            elif dom == "u16x2":
                u16_set.add(f.offset)

        if u8_set or u16_set:
            print(f"\n# {type_name} record area: fields that are NOT u32")
            if u8_set:
                print(f"_{type_name.upper()}_U8X4_OFFSETS = frozenset({{")
                for off in sorted(u8_set):
                    print(f"    {off},")
                print(f"}})")
            if u16_set:
                print(f"_{type_name.upper()}_U16X2_OFFSETS = frozenset({{")
                for off in sorted(u16_set):
                    print(f"    {off},")
                print(f"}})")


def print_per_entry_diff(xbox_bodies: dict, pc_bodies: dict,
                         max_entries: int = 5):
    """Print detailed byte diffs for a few sample entries."""
    matched = set(xbox_bodies.keys()) & set(pc_bodies.keys())

    for type_hash, type_name in [(_TYPE_SOUNDBANK, "SOUNDBANK"),
                                  (_TYPE_WAVEBANK, "WAVEBANK")]:
        type_matches = sorted(k for k in matched if k[1] == type_hash)
        if not type_matches:
            continue

        print(f"\n{'═' * 80}")
        print(f"SAMPLE {type_name} BYTE DIFFS ({min(len(type_matches), max_entries)} entries)")
        print(f"{'═' * 80}")

        for key in type_matches[:max_entries]:
            xbox_body = xbox_bodies[key]
            pc_body = pc_bodies[key]
            common_len = min(len(xbox_body), len(pc_body))

            print(f"\n  Hash: 0x{key[0]:08X}")
            print(f"  Xbox size: {len(xbox_body):,}  PC size: {len(pc_body):,}")
            print(f"  Comparing first {min(common_len, 128)} bytes:")

            for off in range(0, min(common_len, 128), 4):
                xb = xbox_body[off:off + 4]
                pb = pc_body[off:off + 4]
                cls = classify_4byte_diff(xb, pb)
                match = "=" if xb == pb else "≠"
                print(f"    [{off:4d}:{off+4:4d}] Xbox={xb.hex()} PC={pb.hex()} "
                      f"{match} {cls}")


# ── Entrypoint ───────────────────────────────────────────────────────

def find_xbox_wad(search_dir: Path) -> Path | None:
    """Search for vz.wad in a directory tree, including inside zip files."""
    # Direct file
    for p in search_dir.rglob("vz.wad"):
        raw = p.read_bytes()
        if raw[:4] == SCFF_MAGIC:
            return p

    # Inside zip files
    for zp in search_dir.glob("*.zip"):
        try:
            with zipfile.ZipFile(zp, "r") as zf:
                for name in zf.namelist():
                    if name.lower().endswith("vz.wad"):
                        # Check magic
                        with zf.open(name) as f:
                            magic = f.read(4)
                            if magic == SCFF_MAGIC:
                                print(f"  Found Xbox vz.wad inside {zp.name}/{name}")
                                return (zp, name)  # type: ignore
        except Exception:
            continue
    return None


def load_wad_or_from_zip(path_or_tuple) -> WADContext:
    """Load a WAD from disk or from inside a zip."""
    if isinstance(path_or_tuple, tuple):
        zip_path, inner_name = path_or_tuple
        with zipfile.ZipFile(zip_path, "r") as zf:
            raw = zf.read(inner_name)
        print(f"  Extracted from zip: {zip_path.name}/{inner_name} ({len(raw):,} bytes)")
        endian, version, chunks = _parse_ffcs_header(raw)
        chunk_map = {c["tag"]: c for c in chunks}
        indx_chunk = chunk_map.get("INDX")
        aset_chunk = chunk_map.get("ASET")
        if not indx_chunk or not aset_chunk:
            raise ValueError(f"WAD missing INDX or ASET chunk")
        indx = _parse_indx(raw, indx_chunk["offset"], indx_chunk["meta"], endian)
        aset = _parse_aset(raw, aset_chunk["offset"], aset_chunk["meta"], endian)
        print(f"  Parsed: {endian.upper()}, {len(indx)} blocks, {len(aset)} ASET entries")
        return WADContext(data=raw, endian=endian, indx=indx, aset_entries=aset)
    else:
        return load_wad(Path(path_or_tuple))


def main():
    ap = argparse.ArgumentParser(
        description="Cross-platform audio format diff: Xbox BE vs PC LE")
    ap.add_argument("--pc-wad", type=Path, default=Path("game-files/vz.wad"),
                    help="Path to PC vz.wad (default: game-files/vz.wad)")
    ap.add_argument("--xbox-wad", type=Path, default=None,
                    help="Path to Xbox 360 vz.wad (auto-detected from game-files/ if omitted)")
    ap.add_argument("--output", type=Path, default=None,
                    help="Output directory for reports")
    ap.add_argument("--max-sample-diffs", type=int, default=3,
                    help="Number of per-entry byte diffs to print")
    args = ap.parse_args()

    print("=" * 80)
    print("CROSS-PLATFORM AUDIO FORMAT DIFF")
    print("Xbox 360 (BE) vs PC (LE)")
    print("=" * 80)

    # Load PC WAD
    print("\nLoading PC WAD...")
    if not args.pc_wad.exists():
        print(f"ERROR: PC WAD not found: {args.pc_wad}")
        return 1
    pc_ctx = load_wad(args.pc_wad)

    # Load Xbox WAD
    print("\nLoading Xbox WAD...")
    xbox_source = args.xbox_wad
    if xbox_source is None:
        # Auto-detect from game-files/
        xbox_source = find_xbox_wad(Path("game-files"))
        if xbox_source is None:
            print("ERROR: No Xbox vz.wad found in game-files/")
            print("  Place the Xbox 360 game files in game-files/ or use --xbox-wad")
            return 1

    if isinstance(xbox_source, tuple):
        xbox_ctx = load_wad_or_from_zip(xbox_source)
    elif isinstance(xbox_source, Path) and xbox_source.suffix == ".zip":
        # It's a zip file — look for vz.wad inside
        result = find_xbox_wad(xbox_source.parent)
        if result is None:
            print(f"ERROR: No Xbox vz.wad found in {xbox_source}")
            return 1
        xbox_ctx = load_wad_or_from_zip(result)
    else:
        xbox_ctx = load_wad(xbox_source)

    if xbox_ctx.endian != "be":
        print(f"WARNING: Xbox WAD is {xbox_ctx.endian.upper()}, expected BE")
        print("  This might be the PC WAD by mistake")

    # Collect audio bodies
    print("\nCollecting PC audio bodies...")
    pc_bodies = collect_audio_bodies(pc_ctx)
    pc_sb = sum(1 for k in pc_bodies if k[1] == _TYPE_SOUNDBANK)
    pc_wb = sum(1 for k in pc_bodies if k[1] == _TYPE_WAVEBANK)
    print(f"  Found {pc_sb} soundbanks + {pc_wb} wavebanks")

    print("\nCollecting Xbox audio bodies...")
    xbox_bodies = collect_audio_bodies(xbox_ctx)
    xbox_sb = sum(1 for k in xbox_bodies if k[1] == _TYPE_SOUNDBANK)
    xbox_wb = sum(1 for k in xbox_bodies if k[1] == _TYPE_WAVEBANK)
    print(f"  Found {xbox_sb} soundbanks + {xbox_wb} wavebanks")

    # Match and diff
    matched = set(xbox_bodies.keys()) & set(pc_bodies.keys())
    xbox_only = set(xbox_bodies.keys()) - set(pc_bodies.keys())
    pc_only = set(pc_bodies.keys()) - set(xbox_bodies.keys())

    print(f"\n  Matched: {len(matched)} entries")
    print(f"  Xbox only: {len(xbox_only)} entries")
    print(f"  PC only: {len(pc_only)} entries")

    if not matched:
        print("\nERROR: No matching audio entries between platforms!")
        print("  Check that both WADs are from the same game version.")
        return 1

    # Size comparison
    print(f"\n  Size comparison for matched entries:")
    size_mismatches = 0
    for key in sorted(matched):
        xsz = len(xbox_bodies[key])
        psz = len(pc_bodies[key])
        if xsz != psz:
            size_mismatches += 1
            print(f"    0x{key[0]:08X} ({_TYPE_NAMES.get(key[1], '?')}): "
                  f"Xbox={xsz:,} vs PC={psz:,} (diff={xsz-psz:+,})")
    if size_mismatches == 0:
        print(f"    All {len(matched)} entries have identical sizes!")
    else:
        print(f"    {size_mismatches} entries have different sizes "
              f"(out of {len(matched)} matched)")

    # Run the diff
    results = diff_audio_bodies(xbox_bodies, pc_bodies)
    print_field_map(results, xbox_bodies, pc_bodies)
    print_per_entry_diff(xbox_bodies, pc_bodies, args.max_sample_diffs)

    # Save results
    if args.output:
        args.output.mkdir(parents=True, exist_ok=True)
        report_path = args.output / "audio_field_map.txt"
        import io
        buf = io.StringIO()
        # Re-run with output capture... actually just tell user to redirect
        print(f"\n  To save report: redirect stdout to {report_path}")

    print(f"\n{'=' * 80}")
    print("DONE")
    print(f"{'=' * 80}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
