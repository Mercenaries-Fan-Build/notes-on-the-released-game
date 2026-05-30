#!/usr/bin/env python3
"""Full DLC schema coverage analysis — all 2,197 blocks from Xbox STFS container.

Extracts every block from the Xbox 360 DLC, decompresses BE sges, and pipes
each decompressed block through ucfx_byteswap.exe --report-schema-coverage.
Aggregates results into a comprehensive report.

Usage:
    python tools/_schema_coverage_full.py
"""
from __future__ import annotations

import re
import struct
import subprocess
import sys
import tempfile
import time
from collections import Counter, defaultdict
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from x360_dlc_io import (
    PAGE_SIZE,
    StfsReader,
    decompress_be_sges,
    extract_stfs_from_rar,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)

# ── Config ────────────────────────────────────────────────────────────────────

REPO_ROOT = Path(__file__).resolve().parent.parent
DLC_RAR = REPO_ROOT / "game-files" / "Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar"
BYTESWAP_EXE = REPO_ROOT / "tools" / "wad_simulator" / "target" / "release" / "ucfx_byteswap.exe"
OUTPUT_REPORT = REPO_ROOT / "output" / "schema_coverage_report.txt"


# ── Report parsing ────────────────────────────────────────────────────────────

# Regex patterns for parsing ucfx_byteswap stderr report lines
RE_TOTAL_FIELDS = re.compile(r"Total schema fields scanned:\s+(\d+)")
RE_TYPE_CODE_LINE = re.compile(
    r"\s+([! ])\s+code\s+(\d+)\s+\((\w+)\s*\)\s*:\s+(\d+)\s+field"
)
RE_UNKNOWN_FIELD = re.compile(
    r"\s+component=(\S+)\s+field_hash=(0x[0-9A-Fa-f]+)\s+offset=(\d+)\s+type_code=(\d+)"
)
RE_SCHEMA_FAILURE = re.compile(
    r"\s+component=(\S+)\s+unknown_code\(s\):\s+\[([^\]]*)\]"
)
RE_NO_SCHEMA = re.compile(
    r"\s+(\S+)\s+data_size=(\d+)\s+swap=(.*)"
)
RE_GENERIC_FALLBACK = re.compile(
    r"\s+entry\[(\d+)\]\s+type=(0x[0-9A-Fa-f]+)\s+\((\w+)\)\s+tag=(\S+)\s+body_size=(\d+)"
)
RE_RESULT_LINE = re.compile(r"Result:\s+(\d+)\s+item")


def parse_report_stderr(stderr: str, block_idx: int, agg: dict) -> None:
    """Parse a single block's schema coverage report from stderr."""
    for line in stderr.splitlines():
        m = RE_TOTAL_FIELDS.match(line)
        if m:
            agg["total_schema_fields"] += int(m.group(1))
            continue

        m = RE_TYPE_CODE_LINE.match(line)
        if m:
            marker, code_str, name, count_str = m.groups()
            code = int(code_str)
            count = int(count_str)
            agg["type_code_counts"][code] += count
            if marker == "!":
                agg["unknown_type_code_flags"].add(code)
            continue

        m = RE_UNKNOWN_FIELD.match(line)
        if m:
            comp, field_hash, offset, type_code = m.groups()
            agg["unknown_fields"].append({
                "component": comp, "field_hash": field_hash,
                "offset": int(offset), "type_code": int(type_code),
                "block": block_idx,
            })
            agg["unknown_code_instances"][int(type_code)] += 1
            continue

        m = RE_SCHEMA_FAILURE.match(line)
        if m:
            comp, codes_str = m.groups()
            agg["schema_parse_failures"] += 1
            agg["schema_failure_components"][comp] += 1
            if codes_str.strip():
                for c in codes_str.split(","):
                    c = c.strip()
                    if c:
                        agg["schema_failure_codes"][int(c)] += 1
            continue

        m = RE_NO_SCHEMA.match(line)
        if m:
            comp, data_size, strategy = m.groups()
            agg["no_schema_components"][comp] += 1
            agg["no_schema_strategies"][(comp, strategy.strip())] += 1
            agg["no_schema_total_bytes"][comp] += int(data_size)
            continue

        m = RE_GENERIC_FALLBACK.match(line)
        if m:
            entry_idx, type_hash, type_name, tag, body_size = m.groups()
            agg["generic_fallback_tags"][tag] += 1
            agg["generic_fallback_details"].append({
                "entry_idx": int(entry_idx),
                "type_hash": type_hash,
                "type_name": type_name,
                "tag": tag,
                "body_size": int(body_size),
                "block": block_idx,
            })
            agg["generic_fallback_by_type"][(type_hash, type_name)] += 1
            continue


# ── Entry table parsing (for type_hash statistics) ────────────────────────────

def parse_be_entry_table(block: bytes) -> list[tuple[int, int, int, int]]:
    """Parse BE entry table from decompressed Xbox block."""
    if len(block) < 4:
        return []
    count = struct.unpack_from(">I", block, 0)[0]
    if count > 50000:
        return []
    entries = []
    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(block):
            break
        h, t, c, s = struct.unpack_from(">IIII", block, off)
        entries.append((h, t, c, s))
    return entries


# Type hash registry
TYPE_HASH_NAMES: dict[int, str] = {
    0xF011157A: "texture",
    0xBCFE6314: "path",
    0x5B724250: "model",
    0x18166555: "animation",
    0x600B904E: "shader_scrb",
    0xE6B81A54: "layer",
    0x42498680: "script",
    0x6310807F: "object_registry",
    0x7C569307: "terrainmesh",
    0x1602815C: "lowresterrain",
    0x5608BD5A: "effect",
    0xF753F6D0: "wavebank",
    0x665EF13E: "mission_flow",
    0xE5273C14: "audio_group",
    0x9F8BCA10: "soundbank",
    0xFE0E8320: "cfx_pack",
    0x1CF649BB: "starter",
    0xFA0B8DBC: "resident_misc",
    0x207359C7: "stance",
    0x8F0A54E2: "binary",
    0x99E77ACE: "font",
    0xDE982D61: "resident_info",
    0x39E5E978: "stringdb",
    0x59B9DF6A: "singleton_a",
    0x4D7D30C4: "singleton_b",
    0x34612F86: "singleton_c",
    0xACCE47F2: "sequence",
    0xC122545A: "musicdata2",
    0xE8DF4D87: "musicdata",
    0xECE70371: "state_machine",
    0xEA4829D5: "level",
    0x3B0AABF8: "singleton_d",
    0x5647C35D: "layer_meta",
    0x140E8728: "unknown_10",
    0xFA46D8A8: "unknown_25",
}


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> int:
    if not DLC_RAR.exists():
        print(f"ERROR: DLC RAR not found: {DLC_RAR}", file=sys.stderr)
        return 1
    if not BYTESWAP_EXE.exists():
        print(f"ERROR: ucfx_byteswap.exe not found: {BYTESWAP_EXE}", file=sys.stderr)
        return 1

    OUTPUT_REPORT.parent.mkdir(parents=True, exist_ok=True)

    print("=" * 70)
    print("  FULL DLC SCHEMA COVERAGE ANALYSIS")
    print("=" * 70)
    print(f"  DLC RAR: {DLC_RAR}")
    print(f"  Binary:  {BYTESWAP_EXE}")
    print()

    # Step 1: Extract STFS from RAR
    print("Step 1: Extracting STFS from RAR...")
    t0 = time.time()
    work_dir = Path(tempfile.mkdtemp(prefix="schema_cov_"))
    reader = extract_stfs_from_rar(DLC_RAR, work_dir)
    doh_entry = next(
        (e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh_entry is None:
        print("ERROR: No DOH file in STFS file table", file=sys.stderr)
        return 1
    doh_size = doh_entry["file_size"]
    print(f"  DOH file: {doh_entry['name']} ({doh_size:,} bytes)")
    print(f"  Reading DOH from STFS...")
    doh = reader.read(0, doh_size)
    t_stfs = time.time() - t0
    print(f"  STFS extraction: {t_stfs:.1f}s")

    # Step 2: Parse BE FFCS
    print("\nStep 2: Parsing BE FFCS header...")
    version, rows = parse_be_ffcs(doh)
    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    if indx_row is None:
        print("ERROR: No INDX chunk in DOH", file=sys.stderr)
        return 1

    num_blocks = indx_row.meta
    indx_entries = parse_be_indx(doh, indx_row.offset, num_blocks)
    path_strings = parse_be_pths(doh, pths_row.offset, pths_row.meta) if pths_row else []

    print(f"  FFCS version: {version}")
    print(f"  Total blocks: {num_blocks}")
    print(f"  Path strings: {len(path_strings)}")

    # Step 3: Process each block
    print(f"\nStep 3: Processing all {num_blocks} blocks...")
    print(f"  (decompress BE sges -> pipe to ucfx_byteswap --report-schema-coverage)")
    print()

    agg: dict = {
        "total_schema_fields": 0,
        "type_code_counts": Counter(),
        "unknown_type_code_flags": set(),
        "unknown_fields": [],
        "unknown_code_instances": Counter(),
        "schema_parse_failures": 0,
        "schema_failure_components": Counter(),
        "schema_failure_codes": Counter(),
        "no_schema_components": Counter(),
        "no_schema_strategies": Counter(),
        "no_schema_total_bytes": Counter(),
        "generic_fallback_tags": Counter(),
        "generic_fallback_details": [],
        "generic_fallback_by_type": Counter(),
    }

    type_hash_counts: Counter = Counter()
    blocks_processed = 0
    blocks_skipped = 0
    blocks_decompress_failed = 0
    blocks_byteswap_failed = 0
    total_entries = 0

    t_start = time.time()

    for blk_idx in range(num_blocks):
        indx = indx_entries[blk_idx]
        block_offset = indx.file_offset
        block_size = indx.page_count * PAGE_SIZE
        path = path_strings[blk_idx] if blk_idx < len(path_strings) else f"block_{blk_idx:05d}"

        if block_offset + 4 > len(doh):
            blocks_skipped += 1
            continue

        doh_slice = doh[block_offset:block_offset + block_size]

        # Decompress BE sges
        if doh_slice[:4] == b"segs":
            try:
                decompressed = decompress_be_sges(doh_slice, 0, len(doh_slice))
            except Exception as e:
                blocks_decompress_failed += 1
                continue
        else:
            # Might be uncompressed BE block (XFCU magic after entry table)
            rec_count = struct.unpack_from(">I", doh_slice, 0)[0]
            header_end = 4 + rec_count * 16
            first_tag = doh_slice[header_end:header_end + 4] if header_end + 4 <= len(doh_slice) else b""
            if rec_count > 0 and rec_count < 5000 and first_tag == b"XFCU":
                decompressed = bytes(doh_slice)
            else:
                blocks_skipped += 1
                continue

        # Parse entry table for type_hash stats
        entries = parse_be_entry_table(decompressed)
        total_entries += len(entries)
        for _, th, _, _ in entries:
            type_hash_counts[th] += 1

        # Pipe through ucfx_byteswap.exe (actual conversion needed for report;
        # dry-run skips the schema analysis path). stdout = LE output (discarded).
        try:
            result = subprocess.run(
                [str(BYTESWAP_EXE), "--stdin", "--stdout", "--report-schema-coverage",
                 "--no-validate"],
                input=decompressed,
                capture_output=True,
                timeout=60,
            )
        except subprocess.TimeoutExpired:
            blocks_byteswap_failed += 1
            continue
        except Exception as e:
            blocks_byteswap_failed += 1
            continue

        # Parse the stderr report (report goes to stderr)
        stderr_text = result.stderr.decode("utf-8", errors="replace")
        parse_report_stderr(stderr_text, blk_idx, agg)
        blocks_processed += 1

        # Progress
        if (blk_idx + 1) % 100 == 0 or blk_idx + 1 == num_blocks:
            elapsed = time.time() - t_start
            rate = (blk_idx + 1) / elapsed if elapsed > 0 else 0
            print(f"  [{blk_idx+1}/{num_blocks}] {rate:.0f} blocks/s"
                  f" — processed={blocks_processed}"
                  f" decomp_fail={blocks_decompress_failed}"
                  f" swap_fail={blocks_byteswap_failed}", end="\r")

    print()  # newline after progress
    total_time = time.time() - t0
    print(f"\n  Complete: {total_time:.1f}s total")
    print(f"  Blocks: {blocks_processed} processed, {blocks_skipped} skipped,"
          f" {blocks_decompress_failed} decomp failed, {blocks_byteswap_failed} swap failed")

    # ── Generate report ─────────────────────────────────────────────────────────

    lines: list[str] = []
    w = lines.append

    w("=" * 80)
    w("         FULL DLC SCHEMA COVERAGE REPORT — ALL BLOCKS")
    w("=" * 80)
    w(f"  Generated: {time.strftime('%Y-%m-%d %H:%M:%S')}")
    w(f"  Source:    {DLC_RAR.name}")
    w(f"  Blocks in DOH:     {num_blocks}")
    w(f"  Blocks processed:  {blocks_processed}")
    w(f"  Blocks skipped:    {blocks_skipped}")
    w(f"  Decompress fails:  {blocks_decompress_failed}")
    w(f"  Byteswap fails:    {blocks_byteswap_failed}")
    w(f"  Total UCFX entries:{total_entries}")
    w(f"  Schema fields:     {agg['total_schema_fields']}")
    w("")

    # Section 1: Type hash inventory
    w("-" * 80)
    w("1. TYPE HASH INVENTORY (entry-level, across all blocks)")
    w("-" * 80)
    w(f"  {'Type Hash':<14}{'Name':<22}{'Count':>8}")
    w(f"  {'-'*14}{'-'*22}{'-'*8}")
    for th, count in type_hash_counts.most_common():
        name = TYPE_HASH_NAMES.get(th, "UNKNOWN")
        marker = " " if th in TYPE_HASH_NAMES else "!"
        w(f" {marker}0x{th:08X}  {name:<22}{count:>8}")
    w(f"\n  Unique type hashes: {len(type_hash_counts)}")
    w(f"  Unknown type hashes: {sum(1 for th in type_hash_counts if th not in TYPE_HASH_NAMES)}")
    w("")

    # Section 2: Schema type codes
    w("-" * 80)
    w("2. SCHEMA TYPE CODE BREAKDOWN (field-level)")
    w("-" * 80)
    TYPE_CODE_NAMES = {
        1: "Bit", 2: "U8", 4: "U16", 5: "F32", 6: "U32",
        7: "Ref", 8: "StringRef", 9: "Flags", 10: "Vec3", 11: "Blob32",
    }
    KNOWN_CODES = {1, 2, 4, 5, 6, 7, 8, 9, 10, 11}
    w(f"  {'Code':>6} {'Name':<12} {'Status':<8} {'Count':>8}")
    w(f"  {'-'*6} {'-'*12} {'-'*8} {'-'*8}")
    for code in sorted(agg["type_code_counts"]):
        count = agg["type_code_counts"][code]
        name = TYPE_CODE_NAMES.get(code, "UNKNOWN")
        status = "OK" if code in KNOWN_CODES else "!! UNKNOWN"
        w(f"  {code:>6} {name:<12} {status:<8} {count:>8}")
    w(f"\n  Total schema fields: {agg['total_schema_fields']}")
    w("")

    # Section 3: Unknown type codes
    w("-" * 80)
    w("3. UNKNOWN TYPE CODES (cause schema poisoning)")
    w("-" * 80)
    unknown_codes = {c for c in agg["type_code_counts"] if c not in KNOWN_CODES}
    if unknown_codes:
        w(f"  {'Code':>8} {'Hex':>12} {'Occurrences':>12}")
        w(f"  {'-'*8} {'-'*12} {'-'*12}")
        for code in sorted(unknown_codes, key=lambda c: agg["type_code_counts"][c], reverse=True):
            w(f"  {code:>8} 0x{code:08X} {agg['type_code_counts'][code]:>12}")
        w(f"\n  Total unknown codes: {len(unknown_codes)}")
        w(f"  Total unknown field instances: {sum(agg['type_code_counts'][c] for c in unknown_codes)}")
    else:
        w("  None — all type codes recognized!")
    w("")

    # Section 4: Schema poisoning
    w("-" * 80)
    w("4. SCHEMA POISONING (schm present but parse fails)")
    w("-" * 80)
    w(f"  Total poisoned components: {agg['schema_parse_failures']}")
    if agg["schema_failure_components"]:
        w(f"\n  Top components affected:")
        for comp, count in agg["schema_failure_components"].most_common(30):
            w(f"    {comp:<40} {count:>6}")
        w(f"\n  Poisoning codes:")
        for code, count in agg["schema_failure_codes"].most_common():
            name = TYPE_CODE_NAMES.get(code, "UNKNOWN")
            w(f"    code {code} ({name}): {count} occurrence(s)")
    w("")

    # Section 5: No-schema components (Top 20)
    w("-" * 80)
    w("5. TOP 20 COMPONENTS WITH NO SCHEMA (by fallback count)")
    w("-" * 80)
    w(f"  Total no-schema instances: {sum(agg['no_schema_components'].values())}")
    if agg["no_schema_components"]:
        w(f"\n  {'Component':<40} {'Count':>8} {'Total Bytes':>12} {'Strategy':<20}")
        w(f"  {'-'*40} {'-'*8} {'-'*12} {'-'*20}")
        for comp, count in agg["no_schema_components"].most_common(20):
            total_bytes = agg["no_schema_total_bytes"].get(comp, 0)
            # Find strategy for this component
            strat = "unknown"
            for (c, s), cnt in agg["no_schema_strategies"].items():
                if c == comp:
                    strat = s
                    break
            w(f"  {comp:<40} {count:>8} {total_bytes:>12} {strat:<20}")
    w("")

    # Section 6: Non-ECS generic fallback tags (Top 20)
    w("-" * 80)
    w("6. TOP 20 NON-ECS GENERIC FALLBACK TAGS (u32_array sweep)")
    w("-" * 80)
    w(f"  Total fallback instances: {sum(agg['generic_fallback_tags'].values())}")
    if agg["generic_fallback_tags"]:
        w(f"\n  {'Tag':<8} {'Count':>8} {'Example Type':<22} {'Example Hash':<14}")
        w(f"  {'-'*8} {'-'*8} {'-'*22} {'-'*14}")
        # Find examples
        tag_examples: dict[str, tuple[str, str]] = {}
        for d in agg["generic_fallback_details"]:
            if d["tag"] not in tag_examples:
                tag_examples[d["tag"]] = (d["type_name"], d["type_hash"])
        for tag, count in agg["generic_fallback_tags"].most_common(20):
            ex_name, ex_hash = tag_examples.get(tag, ("?", "?"))
            w(f"  {tag:<8} {count:>8} {ex_name:<22} {ex_hash:<14}")
    w("")

    # Section 7: Fallback by type_hash
    w("-" * 80)
    w("7. GENERIC FALLBACK BY TYPE (which asset types hit fallback most)")
    w("-" * 80)
    if agg["generic_fallback_by_type"]:
        w(f"  {'Type Hash':<14} {'Name':<22} {'Fallback Bodies':>16}")
        w(f"  {'-'*14} {'-'*22} {'-'*16}")
        for (th, tn), count in agg["generic_fallback_by_type"].most_common(20):
            w(f"  {th:<14} {tn:<22} {count:>16}")
    w("")

    # Section 8: Recommendations
    w("-" * 80)
    w("8. RECOMMENDATIONS (what to implement next)")
    w("-" * 80)
    if unknown_codes:
        w("\n  Schema type codes to implement (by frequency/impact):")
        for code in sorted(unknown_codes, key=lambda c: agg["type_code_counts"][c], reverse=True):
            poisonings = agg["schema_failure_codes"].get(code, 0)
            w(f"    - Code {code} (0x{code:08X}): {agg['type_code_counts'][code]} field(s),"
              f" causes {poisonings} component poisoning(s)")

    if agg["generic_fallback_tags"]:
        w("\n  Non-ECS descriptor tags to add typed handlers for:")
        for tag, count in agg["generic_fallback_tags"].most_common(10):
            ex_name, _ = tag_examples.get(tag, ("?", "?"))
            w(f"    - Tag '{tag}': {count} bodies — mostly in '{ex_name}' assets")

    if not unknown_codes and not agg["generic_fallback_tags"]:
        w("\n  ALL data has typed swap coverage — no further work needed!")
    w("")

    w("=" * 80)
    w("         END OF REPORT")
    w("=" * 80)

    report_text = "\n".join(lines)
    OUTPUT_REPORT.write_text(report_text, encoding="utf-8")

    # Print to stdout (safe for Windows console)
    print("\n")
    try:
        print(report_text)
    except UnicodeEncodeError:
        print(report_text.encode("ascii", errors="replace").decode("ascii"))
    print(f"\nReport saved to: {OUTPUT_REPORT}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
