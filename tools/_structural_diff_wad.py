#!/usr/bin/env python3
"""Byte-level structural comparison between two FFCS WAD files.

Compares EVERY structural property of a patch WAD against a base game WAD
to find format violations that could cause heap corruption at runtime.

Severity levels:
  CRITICAL  — Definitely would cause a crash (invalid pointers, buffer overflows)
  SUSPECT   — Could cause issues (format deviations from base game patterns)
  INFO      — Differences that are expected (different content, different sizes)

Usage:
  python3 tools/_structural_diff_wad.py \
      --base game-files/vz.wad \
      --patch output/data/vz-patch.wad
"""
from __future__ import annotations

import argparse
import struct
import sys
import zlib
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from sges_decompress import decompress_sges_block, parse_sges_header  # noqa: E402
from wad_patcher import parse_block_entries  # noqa: E402
from aset_type_ids import TYPE_HASH_TO_TYPE_ID  # noqa: E402

PAGE_SIZE = 0x8000  # 32 KB
FFCS_HEADER_SIZE = 256  # 0x100
CERT_BLOB_OFFSET = 0x48
CERT_BLOB_SIZE = 144

VALID_TYPE_IDS = set(range(36))  # 0-35

TYPE_ID_TO_NAME: dict[int, str] = {
    27: "texture", 28: "path", 16: "animation", 19: "model",
    12: "shader", 9: "layer", 35: "script", 30: "registry",
    32: "terrainmesh", 22: "lowresterrain", 29: "effect",
    6: "wavebank", 5: "unk_5", 13: "unk_13", 21: "soundbank",
    23: "unk_23", 34: "unk_34", 18: "unk_18", 11: "unk_11",
    3: "binary", 15: "font", 14: "unk_14", 7: "stringdb",
    20: "level", 0: "singleton", 33: "unk_33", 26: "unk_26",
    4: "unk_4", 31: "unk_31", 1: "unk_1", 8: "unk_8",
    10: "unk_10", 25: "unk_25",
}


@dataclass
class Finding:
    severity: str  # CRITICAL, SUSPECT, INFO
    category: str
    message: str


@dataclass
class Report:
    findings: list[Finding] = field(default_factory=list)

    def add(self, severity: str, category: str, message: str):
        self.findings.append(Finding(severity, category, message))

    def critical(self, cat: str, msg: str): self.add("CRITICAL", cat, msg)
    def suspect(self, cat: str, msg: str): self.add("SUSPECT", cat, msg)
    def info(self, cat: str, msg: str): self.add("INFO", cat, msg)

    def print_report(self):
        by_sev = {"CRITICAL": [], "SUSPECT": [], "INFO": []}
        for f in self.findings:
            by_sev.setdefault(f.severity, []).append(f)

        for sev in ("CRITICAL", "SUSPECT", "INFO"):
            items = by_sev.get(sev, [])
            if not items:
                continue
            print(f"\n{'='*70}")
            print(f" {sev} ({len(items)} findings)")
            print(f"{'='*70}")
            by_cat: dict[str, list[Finding]] = {}
            for f in items:
                by_cat.setdefault(f.category, []).append(f)
            for cat in sorted(by_cat):
                cat_items = by_cat[cat]
                print(f"\n  [{cat}] ({len(cat_items)} items)")
                for f in cat_items[:50]:
                    print(f"    {f.message}")
                if len(cat_items) > 50:
                    print(f"    ... and {len(cat_items) - 50} more")

        total_c = len(by_sev.get("CRITICAL", []))
        total_s = len(by_sev.get("SUSPECT", []))
        total_i = len(by_sev.get("INFO", []))
        print(f"\n{'='*70}")
        print(f" SUMMARY: {total_c} CRITICAL, {total_s} SUSPECT, {total_i} INFO")
        print(f"{'='*70}")


# ── FFCS Header parsing ──────────────────────────────────────────────

def parse_header(raw: bytes) -> dict:
    """Parse full FFCS header returning all fields."""
    result: dict = {}
    result["magic"] = raw[:4]
    result["version"] = struct.unpack_from("<I", raw, 4)[0]
    result["declared_chunk_count"] = struct.unpack_from("<I", raw, 8)[0]

    chunks = []
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off:off+4].decode("ascii", errors="replace")
        val, meta = struct.unpack_from("<II", raw, off + 4)
        chunks.append({"tag": tag, "offset": val, "meta": meta})
    result["chunks"] = chunks

    result["cert_blob"] = raw[CERT_BLOB_OFFSET:CERT_BLOB_OFFSET + CERT_BLOB_SIZE]
    result["post_cert_padding"] = raw[CERT_BLOB_OFFSET + CERT_BLOB_SIZE:0x100]

    return result


def get_chunk(header: dict, tag: str) -> dict | None:
    for c in header["chunks"]:
        if c["tag"] == tag:
            return c
    return None


# ── INDX parsing ─────────────────────────────────────────────────────

def parse_indx_entries(raw: bytes, offset: int, count: int) -> list[dict]:
    entries = []
    for i in range(count):
        off = offset + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, off)
        entries.append({
            "index": i,
            "page_index": page_idx,
            "packed_field": packed,
            "flags_and_page_count": flags_pages,
            "streaming_tier": (packed >> 24) & 0xFF,
            "decompressed_page_count": packed & 0x00FFFFFF,
            "compressed_page_count": flags_pages & 0xFFFF,
            "flags_high16": (flags_pages >> 16) & 0xFFFF,
        })
    return entries


# ── ASET parsing ─────────────────────────────────────────────────────

def parse_aset_entries(raw: bytes, offset: int, count: int) -> list[dict]:
    entries = []
    for i in range(count):
        off = offset + i * 16
        u0, u1, u2, u3 = struct.unpack_from("<IIII", raw, off)
        entries.append({
            "row": i,
            "asset_hash": u0,
            "secondary_ref": u1,
            "packed_block_ref": u2,
            "type_id": u3,
            "block_index": (u2 >> 16) & 0xFFFF,
            "sub_entry": u2 & 0xFFFF,
        })
    return entries


# ── PTHS parsing ─────────────────────────────────────────────────────

def parse_pths_strings(raw: bytes, offset: int, count: int) -> list[str]:
    paths: list[str] = []
    pos = offset
    end = len(raw)
    for _ in range(count):
        if pos >= end:
            break
        nul = raw.find(b"\x00", pos)
        if nul < 0:
            break
        s = raw[pos:nul].decode("utf-8", errors="replace")
        paths.append(s)
        pos = nul + 1
    return paths


# ── Comparison functions ─────────────────────────────────────────────

def compare_headers(base_h: dict, patch_h: dict, report: Report):
    """Compare FFCS header structure."""
    if patch_h["magic"] != b"FFCS":
        report.critical("HEADER", f"Patch magic is {patch_h['magic']!r}, expected b'FFCS'")
    else:
        report.info("HEADER", f"Magic: OK (FFCS)")

    if patch_h["version"] != base_h["version"]:
        report.suspect("HEADER", f"Version differs: base={base_h['version']} patch={patch_h['version']}")
    else:
        report.info("HEADER", f"Version: {patch_h['version']} (matches base)")

    if patch_h["declared_chunk_count"] != base_h["declared_chunk_count"]:
        report.suspect("HEADER",
            f"Declared chunk count differs: base={base_h['declared_chunk_count']} "
            f"patch={patch_h['declared_chunk_count']}")
    else:
        report.info("HEADER", f"Declared chunk count: {patch_h['declared_chunk_count']} (matches base)")

    # Chunk order
    base_order = [c["tag"] for c in base_h["chunks"]]
    patch_order = [c["tag"] for c in patch_h["chunks"]]
    if base_order != patch_order:
        report.suspect("HEADER",
            f"Chunk order differs: base={base_order} patch={patch_order}")
    else:
        report.info("HEADER", f"Chunk order: {patch_order} (matches base)")

    # Cert blob
    if patch_h["cert_blob"] != base_h["cert_blob"]:
        report.critical("HEADER",
            f"Certificate blob at 0x48 differs from base! "
            f"Patch first 16: {patch_h['cert_blob'][:16].hex()} "
            f"Base first 16: {base_h['cert_blob'][:16].hex()}")
    else:
        report.info("HEADER", f"Certificate blob at 0x48: identical to base (144 bytes)")

    # Post-cert padding
    if patch_h["post_cert_padding"] != base_h["post_cert_padding"]:
        non_zero_p = sum(1 for b in patch_h["post_cert_padding"] if b != 0)
        non_zero_b = sum(1 for b in base_h["post_cert_padding"] if b != 0)
        if non_zero_p > 0:
            report.suspect("HEADER",
                f"Post-cert padding (0xD8-0xFF) has {non_zero_p} non-zero bytes "
                f"(base has {non_zero_b})")
        else:
            report.info("HEADER", f"Post-cert padding: all zeros (base has {non_zero_b} non-zero)")
    else:
        report.info("HEADER", f"Post-cert padding: identical to base")

    # Chunk-specific meta values
    for tag in ("INDX", "DATA", "ASET", "PTHS"):
        base_c = get_chunk(base_h, tag)
        patch_c = get_chunk(patch_h, tag)
        if patch_c is None:
            report.critical("HEADER", f"Patch missing {tag} chunk")
            continue
        if base_c is None:
            report.info("HEADER", f"Base missing {tag} chunk (patch has it)")
            continue

    # CSUM chunk comparison
    base_csum = get_chunk(base_h, "CSUM")
    patch_csum = get_chunk(patch_h, "CSUM")
    if base_csum and patch_csum:
        report.info("CSUM",
            f"Base CSUM: offset=0x{base_csum['offset']:08X} meta={base_csum['meta']}")
        report.info("CSUM",
            f"Patch CSUM: offset=0x{patch_csum['offset']:08X} meta={patch_csum['meta']}")
        if patch_csum["offset"] != base_csum["offset"]:
            report.info("CSUM",
                f"CSUM offset differs (expected, not a file offset): "
                f"base=0x{base_csum['offset']:08X} patch=0x{patch_csum['offset']:08X}")
        if patch_csum["meta"] == 0 and base_csum["meta"] > 0:
            report.suspect("CSUM",
                f"Patch CSUM meta=0 while base meta={base_csum['meta']}. "
                f"Meta is reportedly the resident block ASET entry count.")

    # DATA chunk meta
    base_data = get_chunk(base_h, "DATA")
    patch_data = get_chunk(patch_h, "DATA")
    if base_data and patch_data:
        report.info("DATA",
            f"Base DATA: offset=0x{base_data['offset']:X} meta={base_data['meta']}")
        report.info("DATA",
            f"Patch DATA: offset=0x{patch_data['offset']:X} meta={patch_data['meta']}")
        if base_data["meta"] != patch_data["meta"]:
            report.suspect("DATA",
                f"DATA meta differs: base={base_data['meta']} patch={patch_data['meta']}. "
                f"Unknown semantics; base game uses {base_data['meta']}.")


def compare_indx(
    base_raw: bytes, patch_raw: bytes,
    base_h: dict, patch_h: dict,
    report: Report,
) -> tuple[list[dict], list[dict]]:
    """Compare INDX entries between base and patch."""
    base_indx_c = get_chunk(base_h, "INDX")
    patch_indx_c = get_chunk(patch_h, "INDX")

    base_entries = parse_indx_entries(base_raw, base_indx_c["offset"], base_indx_c["meta"])
    patch_entries = parse_indx_entries(patch_raw, patch_indx_c["offset"], patch_indx_c["meta"])

    report.info("INDX", f"Base: {len(base_entries)} entries, Patch: {len(patch_entries)} entries")

    # Analyze base INDX patterns
    base_tiers = Counter(e["streaming_tier"] for e in base_entries)
    patch_tiers = Counter(e["streaming_tier"] for e in patch_entries)
    report.info("INDX",
        f"Base tier distribution: {dict(sorted(base_tiers.items()))}")
    report.info("INDX",
        f"Patch tier distribution: {dict(sorted(patch_tiers.items()))}")

    base_flags = Counter(e["flags_high16"] for e in base_entries)
    patch_flags = Counter(e["flags_high16"] for e in patch_entries)
    report.info("INDX",
        f"Base flags_high16 distribution: {dict(sorted(base_flags.items()))}")
    report.info("INDX",
        f"Patch flags_high16 distribution: {dict(sorted(patch_flags.items()))}")

    # Novel tier values in patch
    novel_tiers = set(patch_tiers.keys()) - set(base_tiers.keys())
    if novel_tiers:
        report.suspect("INDX",
            f"Patch has tier values not seen in base: {novel_tiers}")

    novel_flags = set(patch_flags.keys()) - set(base_flags.keys())
    if novel_flags:
        report.suspect("INDX",
            f"Patch has flags_high16 values not seen in base: "
            f"{[f'0x{f:04X}' for f in novel_flags]}")

    # Validate each patch INDX entry
    patch_file_size = len(patch_raw)
    data_chunk = get_chunk(patch_h, "DATA")
    data_start_page = data_chunk["offset"] // PAGE_SIZE if data_chunk else 0

    for e in patch_entries:
        idx = e["index"]
        page_idx = e["page_index"]
        comp_pages = e["compressed_page_count"]
        alloc_pages = e["decompressed_page_count"]
        tier = e["streaming_tier"]

        block_off = page_idx * PAGE_SIZE
        block_end = block_off + comp_pages * PAGE_SIZE

        # Validate page_index points within DATA
        if block_off >= patch_file_size:
            report.critical("INDX",
                f"block[{idx}]: page_index={page_idx} -> offset 0x{block_off:X} "
                f"beyond file size 0x{patch_file_size:X}")
            continue

        if block_end > patch_file_size:
            report.critical("INDX",
                f"block[{idx}]: extends to 0x{block_end:X} "
                f"beyond file size 0x{patch_file_size:X}")
            continue

        # Validate sges magic at block start
        if patch_raw[block_off:block_off+4] != b"sges":
            report.critical("INDX",
                f"block[{idx}]: no sges magic at offset 0x{block_off:X} "
                f"(got {patch_raw[block_off:block_off+4]!r})")
            continue

        # Parse sges header to get decompressed size
        try:
            _maj, _minor, total_u, _total_c = parse_sges_header(patch_raw, block_off)
        except Exception as ex:
            report.critical("INDX", f"block[{idx}]: sges header parse failed: {ex}")
            continue

        needed_pages = (total_u + PAGE_SIZE - 1) // PAGE_SIZE
        if alloc_pages < needed_pages:
            report.critical("INDX",
                f"block[{idx}]: BUFFER OVERFLOW — packed_field allocates "
                f"{alloc_pages} pages ({alloc_pages * PAGE_SIZE:,} B) "
                f"but sges total_u={total_u:,} B needs {needed_pages} pages")

        # Warn if alloc_pages is wildly over-provisioned
        if alloc_pages > 0 and needed_pages > 0 and alloc_pages > needed_pages * 4:
            report.info("INDX",
                f"block[{idx}]: over-provisioned — alloc {alloc_pages} pages "
                f"for {needed_pages} needed (4x+)")

    # Check for overlaps between patch blocks
    page_ranges = []
    for e in patch_entries:
        start = e["page_index"]
        end = start + e["compressed_page_count"]
        page_ranges.append((start, end, e["index"]))
    page_ranges.sort()

    for i in range(len(page_ranges) - 1):
        s1, e1, idx1 = page_ranges[i]
        s2, e2, idx2 = page_ranges[i+1]
        if e1 > s2:
            report.critical("INDX",
                f"OVERLAP: block[{idx1}] pages {s1}-{e1} overlaps "
                f"block[{idx2}] pages {s2}-{e2}")

    # Check for gaps (pages between blocks)
    if len(page_ranges) > 1:
        total_gap_pages = 0
        for i in range(len(page_ranges) - 1):
            _, e1, _ = page_ranges[i]
            s2, _, _ = page_ranges[i+1]
            gap = s2 - e1
            if gap > 0:
                total_gap_pages += gap
            elif gap < 0:
                pass  # overlap already reported
        if total_gap_pages > 0:
            report.info("INDX",
                f"Total gap between blocks: {total_gap_pages} pages "
                f"({total_gap_pages * PAGE_SIZE:,} bytes)")

    return base_entries, patch_entries


def compare_aset(
    base_raw: bytes, patch_raw: bytes,
    base_h: dict, patch_h: dict,
    patch_indx_count: int,
    report: Report,
) -> tuple[list[dict], list[dict]]:
    """Compare ASET entries between base and patch."""
    base_aset_c = get_chunk(base_h, "ASET")
    patch_aset_c = get_chunk(patch_h, "ASET")

    base_aset = parse_aset_entries(base_raw, base_aset_c["offset"], base_aset_c["meta"])
    patch_aset = parse_aset_entries(patch_raw, patch_aset_c["offset"], patch_aset_c["meta"])

    report.info("ASET", f"Base: {len(base_aset)} entries, Patch: {len(patch_aset)} entries")

    # ── Base game ASET pattern analysis ──
    base_primary = sum(1 for e in base_aset if e["sub_entry"] == 0xFFFF)
    base_streaming = sum(1 for e in base_aset if e["secondary_ref"] != 0xFFFFFFFF)
    base_sub = len(base_aset) - base_primary - base_streaming

    patch_primary = sum(1 for e in patch_aset if e["sub_entry"] == 0xFFFF)
    patch_streaming = sum(1 for e in patch_aset if e["secondary_ref"] != 0xFFFFFFFF)
    patch_sub = len(patch_aset) - patch_primary - patch_streaming

    report.info("ASET",
        f"Base ref types: primary={base_primary} ({100*base_primary/max(1,len(base_aset)):.1f}%) "
        f"streaming={base_streaming} sub_entry={base_sub}")
    report.info("ASET",
        f"Patch ref types: primary={patch_primary} ({100*patch_primary/max(1,len(patch_aset)):.1f}%) "
        f"streaming={patch_streaming} sub_entry={patch_sub}")

    if len(patch_aset) > 0 and patch_primary == 0:
        report.critical("ASET",
            f"Patch has ZERO primary refs (low16=0xFFFF)! "
            f"Base has {base_primary}/{len(base_aset)} ({100*base_primary/len(base_aset):.1f}%). "
            f"This likely means packed_block_ref low16 was not set to 0xFFFF during DLC porting.")

    # ── Validate each patch ASET entry ──
    for e in patch_aset:
        # type_id range check
        if e["type_id"] not in VALID_TYPE_IDS:
            report.critical("ASET",
                f"row {e['row']}: type_id={e['type_id']} is outside valid range 0-35 "
                f"(asset_hash=0x{e['asset_hash']:08X})")

        # block_index range check
        if e["block_index"] >= patch_indx_count:
            report.critical("ASET",
                f"row {e['row']}: block_index={e['block_index']} >= INDX count {patch_indx_count} "
                f"(asset_hash=0x{e['asset_hash']:08X})")

        # asset_hash zero check
        if e["asset_hash"] == 0:
            report.suspect("ASET",
                f"row {e['row']}: asset_hash is 0x00000000 (unusual)")

    # ── sub_entry pattern analysis ──
    sub_entry_vals = [e["sub_entry"] for e in patch_aset if e["sub_entry"] != 0xFFFF]
    if sub_entry_vals:
        # In base game, sub_entry values are typically small offsets into the block
        base_sub_vals = [e["sub_entry"] for e in base_aset if e["sub_entry"] != 0xFFFF]
        if base_sub_vals:
            report.info("ASET",
                f"Base sub_entry range: {min(base_sub_vals)}..{max(base_sub_vals)} "
                f"(mean={sum(base_sub_vals)/len(base_sub_vals):.1f})")
        report.info("ASET",
            f"Patch sub_entry range: {min(sub_entry_vals)}..{max(sub_entry_vals)} "
            f"(mean={sum(sub_entry_vals)/len(sub_entry_vals):.1f})")

        # Check if sub_entry mirrors block_index (Xbox leak pattern)
        mirror_count = sum(
            1 for e in patch_aset
            if e["sub_entry"] != 0xFFFF and e["sub_entry"] == e["block_index"]
        )
        if mirror_count > 0:
            pct = 100 * mirror_count / max(1, len(sub_entry_vals))
            sev = "CRITICAL" if pct > 50 else "SUSPECT"
            report.add(sev, "ASET",
                f"{mirror_count} entries have sub_entry == block_index "
                f"({pct:.1f}% of non-primary) — Xbox block index leak")

    # Type distribution comparison
    base_types = Counter(e["type_id"] for e in base_aset)
    patch_types = Counter(e["type_id"] for e in patch_aset)
    novel_types = set(patch_types.keys()) - set(base_types.keys())
    if novel_types:
        for t in novel_types:
            name = TYPE_ID_TO_NAME.get(t, f"unknown_{t}")
            report.suspect("ASET",
                f"Patch has type_id={t} ({name}) not present in base "
                f"({patch_types[t]} entries)")

    return base_aset, patch_aset


def compare_pths(
    base_raw: bytes, patch_raw: bytes,
    base_h: dict, patch_h: dict,
    report: Report,
) -> tuple[list[str], list[str]]:
    """Compare PTHS sections."""
    base_pths_c = get_chunk(base_h, "PTHS")
    patch_pths_c = get_chunk(patch_h, "PTHS")

    base_paths = parse_pths_strings(base_raw, base_pths_c["offset"], base_pths_c["meta"])
    patch_paths = parse_pths_strings(patch_raw, patch_pths_c["offset"], patch_pths_c["meta"])

    report.info("PTHS",
        f"Base: {len(base_paths)} paths (meta={base_pths_c['meta']}), "
        f"Patch: {len(patch_paths)} paths (meta={patch_pths_c['meta']})")

    # PTHS count should match INDX count
    base_indx_c = get_chunk(base_h, "INDX")
    patch_indx_c = get_chunk(patch_h, "INDX")

    if patch_pths_c["meta"] != patch_indx_c["meta"]:
        report.critical("PTHS",
            f"Patch PTHS meta ({patch_pths_c['meta']}) != INDX meta ({patch_indx_c['meta']}). "
            f"PTHS path count MUST match INDX block count.")
    elif len(patch_paths) != patch_indx_c["meta"]:
        report.critical("PTHS",
            f"Parsed {len(patch_paths)} paths but INDX has {patch_indx_c['meta']} blocks. "
            f"Path parsing may have failed.")
    else:
        report.info("PTHS",
            f"PTHS count matches INDX count: {len(patch_paths)}")

    # Validate path strings
    for i, p in enumerate(patch_paths):
        if not p:
            report.suspect("PTHS", f"Path[{i}] is empty")
            continue
        # Check for valid ASCII
        try:
            p.encode("ascii")
        except UnicodeEncodeError:
            report.suspect("PTHS", f"Path[{i}] contains non-ASCII: {p!r}")
        # Check for expected format (should contain backslash path separators)
        if "\\" not in p and "/" not in p:
            report.suspect("PTHS", f"Path[{i}] has no path separators: {p!r}")

    # PTHS trailer check
    pths_trailer_marker = (
        b"xa37dd45ffe100bfffcc9753aabac325f07cb3fa231144fe2e33ae4783feead2"
        b"b8a73ff021fac326df0ef9753ab9cdf6573ddff0312fab0b0ff39779eaff312"
        b"a4f5de65892ffee33a44569bebf21f66d22e54a22347efd375981188743afd9"
        b"9baacc342d88a99321235798725fedcbf43252669dade32415fee89da543bf23"
        b"d4ex"
    )
    trailer_pos = patch_raw.find(pths_trailer_marker, patch_pths_c["offset"])
    if trailer_pos < 0:
        report.critical("PTHS",
            f"258-byte PTHS trailer marker NOT FOUND in patch WAD! "
            f"Engine will reject the WAD (black-screen hang).")
    else:
        report.info("PTHS",
            f"PTHS trailer found at offset 0x{trailer_pos:X}")

    # Also check base
    base_trailer_pos = base_raw.find(pths_trailer_marker, base_pths_c["offset"])
    if base_trailer_pos >= 0:
        report.info("PTHS", f"Base PTHS trailer at offset 0x{base_trailer_pos:X}")

    return base_paths, patch_paths


def compare_data_blocks(
    patch_raw: bytes,
    patch_h: dict,
    patch_indx: list[dict],
    patch_paths: list[str],
    base_raw: bytes,
    base_h: dict,
    base_indx: list[dict],
    base_paths: list[str],
    report: Report,
    *,
    max_decompress: int = 0,
):
    """Deep inspection of DATA section blocks."""
    patch_file_size = len(patch_raw)
    n_patch = len(patch_indx)

    # Decompress and validate each block
    decomp_ok = 0
    decomp_fail = 0
    block_entry_counts: list[int] = []
    csum_ok = 0
    csum_fail = 0

    limit = n_patch if max_decompress == 0 else min(n_patch, max_decompress)
    print(f"  Decompressing {limit} patch blocks for structural validation...")

    for i in range(limit):
        e = patch_indx[i]
        page_idx = e["page_index"]
        comp_pages = e["compressed_page_count"]
        block_off = page_idx * PAGE_SIZE
        block_sz = comp_pages * PAGE_SIZE
        path = patch_paths[i] if i < len(patch_paths) else f"block_{i}"
        path_label = path.rsplit("\\", 1)[-1].rsplit("/", 1)[-1]

        if block_off + block_sz > patch_file_size:
            report.critical("DATA", f"block[{i}] ({path_label}): beyond EOF")
            decomp_fail += 1
            continue

        try:
            decomp = decompress_sges_block(patch_raw, block_off, block_off + block_sz)
        except Exception as ex:
            report.critical("DATA",
                f"block[{i}] ({path_label}): sges decompression failed: {ex}")
            decomp_fail += 1
            continue

        decomp_ok += 1

        # Validate block entry table
        try:
            entries = parse_block_entries(decomp)
            block_entry_counts.append(len(entries))
        except Exception as ex:
            report.critical("DATA",
                f"block[{i}] ({path_label}): block entry table parse failed: {ex}")
            continue

        # Validate CSUM trailers within the decompressed block
        count = struct.unpack_from("<I", decomp, 0)[0]
        header_end = 4 + count * 16
        pos = header_end
        for ei in range(count):
            entry_off = 4 + ei * 16
            if entry_off + 16 > len(decomp):
                break
            chunk_size = struct.unpack_from("<I", decomp, entry_off + 12)[0]
            if pos + chunk_size > len(decomp):
                report.critical("DATA",
                    f"block[{i}] ({path_label}): chunk[{ei}] extends beyond "
                    f"decompressed data (pos={pos}, chunk_size={chunk_size}, "
                    f"decomp_len={len(decomp)})")
                break

            chunk = decomp[pos:pos + chunk_size]
            if len(chunk) < 8:
                report.critical("DATA",
                    f"block[{i}] ({path_label}): chunk[{ei}] too small for CSUM trailer")
                break

            if chunk[-8:-4] == b"CSUM":
                expected = struct.unpack_from("<I", chunk, len(chunk) - 4)[0]
                computed = (zlib.crc32(chunk[:-8], 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF
                if computed == expected:
                    csum_ok += 1
                else:
                    csum_fail += 1
                    if csum_fail <= 10:
                        report.critical("DATA",
                            f"block[{i}] ({path_label}): chunk[{ei}] CSUM mismatch "
                            f"expected=0x{expected:08X} computed=0x{computed:08X}")
            else:
                report.suspect("DATA",
                    f"block[{i}] ({path_label}): chunk[{ei}] missing CSUM trailer "
                    f"(last 8 bytes: {chunk[-8:].hex()})")

            pos += chunk_size

    report.info("DATA",
        f"Decompression: {decomp_ok} OK, {decomp_fail} failed out of {limit}")
    report.info("DATA",
        f"CSUM validation: {csum_ok} OK, {csum_fail} failed")
    if csum_fail > 10:
        report.critical("DATA",
            f"Total CSUM failures: {csum_fail} (showing first 10 above)")


def compare_alignment(
    patch_raw: bytes,
    patch_h: dict,
    patch_indx: list[dict],
    report: Report,
):
    """Check section alignment and layout."""
    indx_c = get_chunk(patch_h, "INDX")
    aset_c = get_chunk(patch_h, "ASET")
    pths_c = get_chunk(patch_h, "PTHS")
    data_c = get_chunk(patch_h, "DATA")

    # INDX alignment
    if indx_c["offset"] % PAGE_SIZE != 0:
        report.suspect("ALIGNMENT",
            f"INDX offset 0x{indx_c['offset']:X} not page-aligned "
            f"(PAGE_SIZE=0x{PAGE_SIZE:X})")
    else:
        report.info("ALIGNMENT",
            f"INDX at page-aligned offset 0x{indx_c['offset']:X}")

    # DATA alignment
    if data_c["offset"] % PAGE_SIZE != 0:
        report.critical("ALIGNMENT",
            f"DATA offset 0x{data_c['offset']:X} not page-aligned. "
            f"INDX page_index * PAGE_SIZE arithmetic will be wrong.")
    else:
        report.info("ALIGNMENT",
            f"DATA at page-aligned offset 0x{data_c['offset']:X}")

    # Verify INDX/ASET/PTHS all fit before DATA
    indx_end = indx_c["offset"] + indx_c["meta"] * 12
    aset_end = aset_c["offset"] + aset_c["meta"] * 16
    pths_end = pths_c["offset"]  # approximate

    if indx_end > data_c["offset"]:
        report.critical("ALIGNMENT",
            f"INDX data (end=0x{indx_end:X}) overlaps DATA start (0x{data_c['offset']:X})")
    if aset_end > data_c["offset"]:
        report.critical("ALIGNMENT",
            f"ASET data (end=0x{aset_end:X}) overlaps DATA start (0x{data_c['offset']:X})")

    # Check section ordering: INDX before ASET before PTHS before DATA
    sections = [
        ("INDX", indx_c["offset"]),
        ("ASET", aset_c["offset"]),
        ("PTHS", pths_c["offset"]),
        ("DATA", data_c["offset"]),
    ]
    sections.sort(key=lambda x: x[1])
    order = [s[0] for s in sections]
    report.info("ALIGNMENT", f"Section order by offset: {order}")


def compare_aset_block_content(
    patch_raw: bytes,
    patch_indx: list[dict],
    patch_aset: list[dict],
    patch_paths: list[str],
    base_aset: list[dict],
    report: Report,
    *,
    max_blocks: int = 0,
):
    """Verify ASET entries resolve against actual block content."""
    n_indx = len(patch_indx)

    blocks_needed: dict[int, list[dict]] = {}
    for e in patch_aset:
        bi = e["block_index"]
        if bi < n_indx:
            blocks_needed.setdefault(bi, []).append(e)

    blocks_to_check = sorted(blocks_needed.keys())
    if max_blocks and max_blocks < len(blocks_to_check):
        blocks_to_check = blocks_to_check[:max_blocks]

    print(f"  Verifying ASET vs block content for {len(blocks_to_check)} blocks...")

    primary_hit = 0
    primary_miss = 0
    type_mismatch = 0

    for bi in blocks_to_check:
        e_indx = patch_indx[bi]
        page_idx = e_indx["page_index"]
        comp_pages = e_indx["compressed_page_count"]
        block_off = page_idx * PAGE_SIZE
        block_sz = comp_pages * PAGE_SIZE
        path = patch_paths[bi] if bi < len(patch_paths) else f"block_{bi}"
        path_label = path.rsplit("\\", 1)[-1].rsplit("/", 1)[-1]

        if block_off + block_sz > len(patch_raw):
            continue

        try:
            decomp = decompress_sges_block(patch_raw, block_off, block_off + block_sz)
            entries = parse_block_entries(decomp)
        except Exception:
            continue

        block_hashes = {e["hash"] for e in entries}
        block_hash_to_entry = {e["hash"]: e for e in entries}

        for ae in blocks_needed[bi]:
            ah = ae["asset_hash"]
            is_primary = ae["sub_entry"] == 0xFFFF

            if is_primary:
                if ah in block_hashes:
                    primary_hit += 1
                    be = block_hash_to_entry[ah]
                    expected_tid = TYPE_HASH_TO_TYPE_ID.get(be["type_hash"])
                    if expected_tid is not None and expected_tid != ae["type_id"]:
                        type_mismatch += 1
                        if type_mismatch <= 10:
                            report.critical("ASET_CONTENT",
                                f"row {ae['row']}: type_id mismatch "
                                f"ASET={ae['type_id']} block={expected_tid} "
                                f"(type_hash=0x{be['type_hash']:08X}) "
                                f"in block[{bi}] ({path_label})")
                else:
                    primary_miss += 1
                    if primary_miss <= 10:
                        report.critical("ASET_CONTENT",
                            f"row {ae['row']}: PRIMARY asset 0x{ah:08X} "
                            f"NOT FOUND in block[{bi}] ({path_label}, "
                            f"{len(entries)} entries)")

    report.info("ASET_CONTENT",
        f"Primary resolution: {primary_hit} hit, {primary_miss} miss")
    if primary_miss > 10:
        report.critical("ASET_CONTENT",
            f"Total primary misses: {primary_miss} (showing first 10 above)")
    if type_mismatch > 10:
        report.critical("ASET_CONTENT",
            f"Total type mismatches: {type_mismatch} (showing first 10 above)")


def compare_indx_packed_field_deep(
    patch_raw: bytes,
    patch_indx: list[dict],
    patch_paths: list[str],
    base_indx: list[dict],
    report: Report,
    *,
    max_blocks: int = 0,
):
    """Deep verify packed_field by decompressing and comparing declared vs actual size."""
    n = len(patch_indx)
    limit = n if max_blocks == 0 else min(n, max_blocks)

    print(f"  Deep packed_field verification ({limit} blocks)...")

    overflows = 0
    for i in range(limit):
        e = patch_indx[i]
        page_idx = e["page_index"]
        comp_pages = e["compressed_page_count"]
        alloc_pages = e["decompressed_page_count"]
        block_off = page_idx * PAGE_SIZE
        block_sz = comp_pages * PAGE_SIZE
        path = patch_paths[i] if i < len(patch_paths) else f"block_{i}"
        path_label = path.rsplit("\\", 1)[-1].rsplit("/", 1)[-1]

        if block_off + block_sz > len(patch_raw):
            continue

        try:
            decomp = decompress_sges_block(patch_raw, block_off, block_off + block_sz)
        except Exception:
            continue

        actual_pages = (len(decomp) + PAGE_SIZE - 1) // PAGE_SIZE
        if alloc_pages < actual_pages:
            overflows += 1
            report.critical("PACKED_FIELD",
                f"block[{i}] ({path_label}): HEAP OVERFLOW — "
                f"alloc_pages={alloc_pages} ({alloc_pages * PAGE_SIZE:,} B) "
                f"< needed={actual_pages} ({len(decomp):,} B actual). "
                f"Engine will write {len(decomp) - alloc_pages * PAGE_SIZE:,} bytes "
                f"past buffer end!")

    report.info("PACKED_FIELD",
        f"Deep verification complete: {overflows} buffer overflows found out of {limit} blocks")

    # Compare packed_field patterns between base and patch
    if base_indx:
        base_ratios = []
        for e in base_indx[:200]:
            page_idx = e["page_index"]
            comp_pages = e["compressed_page_count"]
            block_off = page_idx * PAGE_SIZE
            block_sz = comp_pages * PAGE_SIZE
            alloc = e["decompressed_page_count"]
            if alloc > 0:
                base_ratios.append(comp_pages / alloc)

        patch_ratios = []
        for e in patch_indx[:200]:
            comp_pages = e["compressed_page_count"]
            alloc = e["decompressed_page_count"]
            if alloc > 0:
                patch_ratios.append(comp_pages / alloc)

        if base_ratios and patch_ratios:
            report.info("PACKED_FIELD",
                f"Base comp/alloc ratio: "
                f"min={min(base_ratios):.3f} max={max(base_ratios):.3f} "
                f"mean={sum(base_ratios)/len(base_ratios):.3f}")
            report.info("PACKED_FIELD",
                f"Patch comp/alloc ratio: "
                f"min={min(patch_ratios):.3f} max={max(patch_ratios):.3f} "
                f"mean={sum(patch_ratios)/len(patch_ratios):.3f}")


def compare_csum_chunk(base_h: dict, patch_h: dict, report: Report):
    """Detailed CSUM chunk analysis."""
    base_csum = get_chunk(base_h, "CSUM")
    patch_csum = get_chunk(patch_h, "CSUM")

    report.info("CSUM_DETAIL",
        f"Base CSUM chunk: offset_field=0x{base_csum['offset']:08X} meta={base_csum['meta']}")
    report.info("CSUM_DETAIL",
        f"Patch CSUM chunk: offset_field=0x{patch_csum['offset']:08X} meta={patch_csum['meta']}")

    # The "offset" field in CSUM is NOT a file offset — it's a hash/identifier
    # The "meta" field is reportedly the resident block's ASET entry count
    report.info("CSUM_DETAIL",
        f"Note: CSUM 'offset' is NOT a file offset (it exceeds file size in base). "
        f"It is a hash/identifier. "
        f"CSUM 'meta' = resident block ASET entry count.")


def compare_raw_header_bytes(base_raw: bytes, patch_raw: bytes, report: Report):
    """Byte-by-byte comparison of the first 256 bytes."""
    diffs = []
    for i in range(min(256, len(base_raw), len(patch_raw))):
        if base_raw[i] != patch_raw[i]:
            diffs.append(i)

    if not diffs:
        report.info("RAW_HEADER", "First 256 bytes are identical between base and patch")
        return

    # Group contiguous ranges
    ranges = []
    start = diffs[0]
    prev = diffs[0]
    for d in diffs[1:]:
        if d == prev + 1:
            prev = d
        else:
            ranges.append((start, prev))
            start = d
            prev = d
    ranges.append((start, prev))

    report.info("RAW_HEADER",
        f"{len(diffs)} byte differences in first 256 bytes across {len(ranges)} ranges")
    for s, e in ranges:
        base_bytes = base_raw[s:e+1].hex()
        patch_bytes = patch_raw[s:e+1].hex()
        region = ""
        if s < 0x0C:
            region = " (magic/version/count)"
        elif s < 0x48:
            chunk_idx = (s - 0x0C) // 12
            region = f" (chunk row {chunk_idx})"
        elif s < 0xD8:
            region = " (cert blob)"
        else:
            region = " (padding)"
        report.info("RAW_HEADER",
            f"  0x{s:02X}-0x{e:02X}{region}: base={base_bytes} patch={patch_bytes}")


# ── Main ─────────────────────────────────────────────────────────────

def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--base", type=Path, required=True, help="Base vz.wad")
    ap.add_argument("--patch", type=Path, required=True, help="Patch vz-patch.wad")
    ap.add_argument("--max-decompress", type=int, default=0,
                     help="Limit number of blocks to decompress (0 = all)")
    ap.add_argument("--skip-deep", action="store_true",
                     help="Skip deep block decompression checks")
    args = ap.parse_args()

    for p in (args.base, args.patch):
        if not p.is_file():
            print(f"ERROR: {p} not found", file=sys.stderr)
            return 1

    print(f"Loading WAD files...")
    print(f"  Base:  {args.base} ({args.base.stat().st_size:,} bytes)")
    print(f"  Patch: {args.patch} ({args.patch.stat().st_size:,} bytes)")

    base_raw = args.base.read_bytes()
    patch_raw = args.patch.read_bytes()

    report = Report()

    # ── 1. Parse headers ──
    print("\n[1/7] Comparing FFCS headers...")
    base_h = parse_header(base_raw)
    patch_h = parse_header(patch_raw)
    compare_headers(base_h, patch_h, report)
    compare_raw_header_bytes(base_raw, patch_raw, report)

    # ── 2. Compare INDX ──
    print("[2/7] Comparing INDX entries...")
    base_indx, patch_indx = compare_indx(base_raw, patch_raw, base_h, patch_h, report)

    # ── 3. Compare ASET ──
    print("[3/7] Comparing ASET entries...")
    patch_indx_count = get_chunk(patch_h, "INDX")["meta"]
    base_aset, patch_aset = compare_aset(
        base_raw, patch_raw, base_h, patch_h, patch_indx_count, report)

    # ── 4. Compare PTHS ──
    print("[4/7] Comparing PTHS section...")
    base_paths, patch_paths = compare_pths(base_raw, patch_raw, base_h, patch_h, report)

    # ── 5. Compare alignment ──
    print("[5/7] Checking alignment...")
    compare_alignment(patch_raw, patch_h, patch_indx, report)

    # ── 6. CSUM chunk detail ──
    print("[6/7] Analyzing CSUM chunk...")
    compare_csum_chunk(base_h, patch_h, report)

    if not args.skip_deep:
        # ── 7a. Deep block validation ──
        print("[7/7] Deep block validation (this may take a while)...")
        compare_data_blocks(
            patch_raw, patch_h, patch_indx, patch_paths,
            base_raw, base_h, base_indx, base_paths,
            report,
            max_decompress=args.max_decompress,
        )

        # ── 7b. packed_field deep verification ──
        compare_indx_packed_field_deep(
            patch_raw, patch_indx, patch_paths,
            base_indx, report,
            max_blocks=args.max_decompress,
        )

        # ── 7c. ASET vs block content ──
        compare_aset_block_content(
            patch_raw, patch_indx, patch_aset, patch_paths,
            base_aset, report,
            max_blocks=args.max_decompress,
        )
    else:
        print("[7/7] Skipping deep block validation (--skip-deep)")

    # ── Print report ──
    report.print_report()
    return 1 if any(f.severity == "CRITICAL" for f in report.findings) else 0


if __name__ == "__main__":
    raise SystemExit(main())
