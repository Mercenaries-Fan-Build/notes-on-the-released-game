#!/usr/bin/env python3
"""Fast JSON quality scanner — optimized for large extraction output.

Runs in phases to minimize I/O:
  Phase 1: File inventory + size scan (os.scandir, no reads)
  Phase 2: NaN/Infinity scan via raw regex on text
  Phase 3: Parse check + schema on a sample
  Phase 4: Deep walk on NaN-affected files
"""
from __future__ import annotations

import json
import math
import os
import re
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

REVIEW_ROOT = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
SIZE_THRESHOLD_MB = 5
SPECIAL_RE = re.compile(rb'(?<!["\w])(NaN|-?Infinity)(?!["\w])')
KEY_RE = re.compile(rb'"([^"]+)"\s*:\s*(?:\[?\s*)?$')

# ── Phase 1: Inventory ──────────────────────────────────────────────────────
print("Phase 1: Inventory...", flush=True)
t0 = time.time()

json_files: list[tuple[Path, int]] = []
for dirpath, _dirs, fnames in os.walk(REVIEW_ROOT):
    dp = Path(dirpath)
    for fn in fnames:
        if fn.endswith(".json"):
            fp = dp / fn
            try:
                sz = fp.stat().st_size
            except OSError:
                continue
            json_files.append((fp, sz))

total_files = len(json_files)
total_bytes = sum(sz for _, sz in json_files)
file_type_counts: Counter = Counter()
oversized: list[tuple[str, float]] = []
max_size = 0
max_path = ""

for fp, sz in json_files:
    file_type_counts[fp.name] += 1
    if sz > max_size:
        max_size = sz
        max_path = str(fp.relative_to(REVIEW_ROOT))
    if sz > SIZE_THRESHOLD_MB * 1024 * 1024:
        oversized.append((str(fp.relative_to(REVIEW_ROOT)), sz / (1024 * 1024)))

print(f"  {total_files:,} JSON files, {total_bytes / (1024**3):.2f} GB total  ({time.time()-t0:.1f}s)", flush=True)

# Size distribution
size_buckets = Counter()
for _, sz in json_files:
    if sz < 1024:
        size_buckets["<1KB"] += 1
    elif sz < 100 * 1024:
        size_buckets["1KB-100KB"] += 1
    elif sz < 1024 * 1024:
        size_buckets["100KB-1MB"] += 1
    elif sz < 10 * 1024 * 1024:
        size_buckets["1MB-10MB"] += 1
    else:
        size_buckets[">10MB"] += 1

# ── Phase 2: NaN / Infinity scan ────────────────────────────────────────────
print("Phase 2: NaN/Infinity scan...", flush=True)
t1 = time.time()

nan_inf_results: dict[str, dict] = {}
nan_total_files = 0
nan_total_occurrences = 0
token_counts: Counter = Counter()
field_counts: Counter = Counter()
file_type_nan_counts: Counter = Counter()

for idx, (fp, sz) in enumerate(json_files):
    if idx % 10000 == 0 and idx > 0:
        print(f"  ...{idx}/{total_files} ({time.time()-t1:.0f}s)", flush=True)

    try:
        raw = fp.read_bytes()
    except OSError:
        continue

    hits = list(SPECIAL_RE.finditer(raw))
    if not hits:
        continue

    nan_total_files += 1
    nan_total_occurrences += len(hits)
    file_type_nan_counts[fp.name] += 1
    rel = str(fp.relative_to(REVIEW_ROOT))

    local_tokens: Counter = Counter()
    local_fields: Counter = Counter()
    sample_contexts: list[str] = []

    for m in hits:
        tok = m.group(1).decode()
        local_tokens[tok] += 1
        token_counts[tok] += 1

        prefix = raw[max(0, m.start() - 80):m.start()]
        km = KEY_RE.search(prefix)
        if km:
            field = km.group(1).decode(errors="replace")
            local_fields[field] += 1
            field_counts[field] += 1

        if len(sample_contexts) < 3:
            ctx = raw[max(0, m.start() - 40):m.end() + 40].decode(errors="replace").strip()
            sample_contexts.append(ctx)

    nan_inf_results[rel] = {
        "count": len(hits),
        "tokens": dict(local_tokens),
        "fields": dict(local_fields),
        "samples": sample_contexts,
    }

print(f"  NaN/Inf found in {nan_total_files:,} files, {nan_total_occurrences:,} occurrences  ({time.time()-t1:.1f}s)", flush=True)

# ── Phase 3: Parse check on all files ────────────────────────────────────────
print("Phase 3: JSON parse validity check...", flush=True)
t2 = time.time()

parse_failures_non_nan: list[tuple[str, str]] = []
parse_failures_with_nan: list[tuple[str, str]] = []
additional_parse_errors: list[tuple[str, str]] = []

for idx, (fp, sz) in enumerate(json_files):
    if idx % 10000 == 0 and idx > 0:
        print(f"  ...{idx}/{total_files} ({time.time()-t2:.0f}s)", flush=True)

    try:
        raw = fp.read_bytes()
    except OSError:
        continue

    try:
        json.loads(raw)
        continue  # parses fine
    except json.JSONDecodeError as e:
        rel = str(fp.relative_to(REVIEW_ROOT))
        err = str(e)[:150]

    has_nan = bool(SPECIAL_RE.search(raw))
    if has_nan:
        # Try cleaning NaN/Inf and re-parsing
        cleaned = SPECIAL_RE.sub(b'"__PLACEHOLDER__"', raw)
        try:
            json.loads(cleaned)
            parse_failures_with_nan.append((rel, err))
        except json.JSONDecodeError as e2:
            additional_parse_errors.append((rel, f"NaN+other: {str(e2)[:120]}"))
    else:
        parse_failures_non_nan.append((rel, err))

print(f"  Parse failures: {len(parse_failures_non_nan)} non-NaN, {len(parse_failures_with_nan)} NaN-only, {len(additional_parse_errors)} NaN+other  ({time.time()-t2:.1f}s)", flush=True)

# ── Phase 4: Schema check on sample ─────────────────────────────────────────
print("Phase 4: Schema spot-check on sample...", flush=True)
t3 = time.time()

EXPECTED_SCHEMAS = {
    "mesh.meta.json": {"required": {"vertices", "faces", "stem"}, "types": {"vertices": int, "faces": int, "stem": str}},
    "ucfx.json": {"required": {"file", "size"}, "types": {"file": str, "size": int}},
    "dialog_fragments.json": {"required": {"file", "size"}, "types": {"file": str, "size": int}},
    "texture_manifest.json": {"required": {"source_blob", "stem", "textures"}, "types": {"source_blob": str, "stem": str, "textures": list}},
}

schema_issues: list[tuple[str, str]] = []
null_byte_files: list[str] = []
huge_arrays: list[tuple[str, str, int]] = []

checked = 0
for fp, sz in json_files:
    basename = fp.name
    schema = EXPECTED_SCHEMAS.get(basename)
    if not schema:
        continue

    rel = str(fp.relative_to(REVIEW_ROOT))
    has_nan = rel in nan_inf_results

    try:
        raw = fp.read_bytes()
    except OSError:
        continue

    if b"\x00" in raw:
        null_byte_files.append(rel)

    if has_nan:
        raw = SPECIAL_RE.sub(b"0", raw)

    try:
        data = json.loads(raw)
    except json.JSONDecodeError:
        continue

    checked += 1

    if isinstance(data, dict):
        missing = schema["required"] - set(data.keys())
        for k in missing:
            schema_issues.append((rel, f"missing key: {k}"))
        for k, expected_type in schema["types"].items():
            if k in data and not isinstance(data[k], expected_type):
                schema_issues.append((rel, f"wrong type for '{k}': expected {expected_type.__name__}, got {type(data[k]).__name__}"))

    # Check for huge arrays
    def _check_arrays(obj, path="$"):
        if isinstance(obj, list):
            if len(obj) > 100_000:
                huge_arrays.append((rel, path, len(obj)))
            for i, v in enumerate(obj[:5]):
                _check_arrays(v, f"{path}[{i}]")
        elif isinstance(obj, dict):
            for k, v in obj.items():
                _check_arrays(v, f"{path}.{k}")
    _check_arrays(data)

print(f"  Checked {checked:,} schema-eligible files  ({time.time()-t3:.1f}s)", flush=True)

# ── Phase 5: NaN field path analysis ─────────────────────────────────────────
print("Phase 5: Deep NaN field path analysis on affected files...", flush=True)
t4 = time.time()

nan_json_paths: Counter = Counter()
nan_nesting_patterns: Counter = Counter()
sample_count = 0

for rel, info in nan_inf_results.items():
    if sample_count >= 200:
        break
    fp = REVIEW_ROOT / rel
    try:
        raw = fp.read_bytes()
    except OSError:
        continue

    cleaned = SPECIAL_RE.sub(b"99999.99", raw)
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError:
        continue

    sample_count += 1

    # Walk to find 99999.99 sentinels
    def _find_sentinels(obj, path="$"):
        if isinstance(obj, float) and abs(obj - 99999.99) < 0.01:
            nan_json_paths[path] += 1
            # Extract structural pattern (replace indices with [*])
            pattern = re.sub(r'\[\d+\]', '[*]', path)
            nan_nesting_patterns[pattern] += 1
        elif isinstance(obj, dict):
            for k, v in obj.items():
                _find_sentinels(v, f"{path}.{k}")
        elif isinstance(obj, list):
            for i, v in enumerate(obj):
                _find_sentinels(v, f"{path}[{i}]")

    _find_sentinels(data)

print(f"  Analyzed {sample_count} files for NaN paths  ({time.time()-t4:.1f}s)", flush=True)

# ══════════════════════════════════════════════════════════════════════════════
# REPORT
# ══════════════════════════════════════════════════════════════════════════════
print("\n" + "=" * 80)
print("JSON DATA QUALITY REPORT — PostgreSQL Ingest Readiness")
print("=" * 80)

print(f"\nTotal JSON files scanned: {total_files:,}")
print(f"Total data volume: {total_bytes / (1024**3):.2f} GB")
print(f"\nFile type distribution:")
for ft, count in file_type_counts.most_common():
    print(f"  {ft:>30}: {count:,}")
print(f"\nSize distribution:")
for bucket in ["<1KB", "1KB-100KB", "100KB-1MB", "1MB-10MB", ">10MB"]:
    print(f"  {bucket:>12}: {size_buckets.get(bucket, 0):,}")

# 1. NaN/Inf
print(f"\n{'─' * 80}")
print("1. NaN / Infinity VALUES  [CRITICAL — PostgreSQL rejects these]")
print(f"{'─' * 80}")
print(f"  Files affected:        {nan_total_files:,} / {total_files:,} ({100*nan_total_files/total_files:.1f}%)")
print(f"  Total occurrences:     {nan_total_occurrences:,}")
print(f"\n  By token:")
for tok, cnt in token_counts.most_common():
    print(f"    {tok:>12}: {cnt:,}")
print(f"\n  By file type:")
for ft, cnt in file_type_nan_counts.most_common():
    print(f"    {ft:>30}: {cnt:,}")
print(f"\n  By field name (JSON key preceding the value):")
for field, cnt in field_counts.most_common(40):
    print(f"    {field:>35}: {cnt:,}")
print(f"\n  NaN nesting patterns (structural JSON paths):")
for pattern, cnt in nan_nesting_patterns.most_common(30):
    print(f"    {pattern}: {cnt:,}")

print(f"\n  Sample contexts (first 15 affected files):")
shown = 0
for rel, info in nan_inf_results.items():
    if shown >= 15:
        break
    print(f"\n    {rel}")
    print(f"      occurrences: {info['count']}, tokens: {info['tokens']}")
    for ctx in info["samples"][:2]:
        print(f"      ...{ctx}...")
    shown += 1

# 2. Parse failures
print(f"\n{'─' * 80}")
print("2. JSON PARSE FAILURES")
print(f"{'─' * 80}")
print(f"  NaN/Inf-only failures:     {len(parse_failures_with_nan):,}")
print(f"  Non-NaN failures:          {len(parse_failures_non_nan):,}")
print(f"  NaN + other failures:      {len(additional_parse_errors):,}")
if parse_failures_non_nan:
    print(f"\n  Non-NaN parse failures:")
    for rel, err in parse_failures_non_nan[:20]:
        print(f"    {rel}")
        print(f"      {err}")
if additional_parse_errors:
    print(f"\n  NaN + additional parse errors:")
    for rel, err in additional_parse_errors[:10]:
        print(f"    {rel}")
        print(f"      {err}")

# 3. Oversized
print(f"\n{'─' * 80}")
print(f"3. OVERSIZED FILES  (>{SIZE_THRESHOLD_MB}MB)")
print(f"{'─' * 80}")
print(f"  Largest: {max_size/(1024*1024):.2f} MB  ({max_path})")
print(f"  Files > {SIZE_THRESHOLD_MB}MB: {len(oversized):,}")
for rel, mb in sorted(oversized, key=lambda x: -x[1])[:25]:
    print(f"    {mb:>8.2f} MB  {rel}")

# 4. Schema
print(f"\n{'─' * 80}")
print("4. SCHEMA ISSUES")
print(f"{'─' * 80}")
issue_types = Counter(iss for _, iss in schema_issues)
print(f"  Total issues: {len(schema_issues):,}")
for iss, cnt in issue_types.most_common():
    print(f"    {iss}: {cnt:,}")

# 5. Other
print(f"\n{'─' * 80}")
print("5. OTHER ISSUES")
print(f"{'─' * 80}")
print(f"  Null byte files: {len(null_byte_files):,}")
for f in null_byte_files[:10]:
    print(f"    {f}")
print(f"  Huge arrays (>100k): {len(huge_arrays):,}")
for rel, path, length in huge_arrays[:10]:
    print(f"    {rel}  {path}  length={length:,}")

# Summary
print(f"\n{'=' * 80}")
print("SEVERITY SUMMARY")
print(f"{'=' * 80}")
print(f"\n  CRITICAL (will cause PostgreSQL INSERT failures):")
if nan_total_files:
    print(f"    - NaN/Infinity: {nan_total_files:,} files, {nan_total_occurrences:,} occurrences")
if parse_failures_non_nan:
    print(f"    - Invalid JSON (non-NaN): {len(parse_failures_non_nan):,} files")
if additional_parse_errors:
    print(f"    - Invalid JSON (NaN + other): {len(additional_parse_errors):,} files")
if null_byte_files:
    print(f"    - Null bytes: {len(null_byte_files):,} files")
if not (nan_total_files or parse_failures_non_nan or additional_parse_errors or null_byte_files):
    print(f"    (none)")

print(f"\n  WARNING (may cause performance issues):")
if oversized:
    print(f"    - Oversized files (>{SIZE_THRESHOLD_MB}MB): {len(oversized):,}")
if huge_arrays:
    print(f"    - Huge arrays (>100k elements): {len(huge_arrays):,}")
if schema_issues:
    print(f"    - Schema issues: {len(schema_issues):,}")
if not (oversized or huge_arrays or schema_issues):
    print(f"    (none)")

print(f"\nTotal scan time: {time.time()-t0:.1f}s")

# Write machine-readable summary
summary = {
    "total_json_files": total_files,
    "total_bytes": total_bytes,
    "nan_inf": {
        "total_files": nan_total_files,
        "total_occurrences": nan_total_occurrences,
        "by_token": dict(token_counts),
        "by_file_type": dict(file_type_nan_counts),
        "by_field": dict(field_counts),
        "nesting_patterns": dict(nan_nesting_patterns.most_common(50)),
        "affected_file_list": list(nan_inf_results.keys()),
    },
    "parse_failures": {
        "non_nan": len(parse_failures_non_nan),
        "nan_only": len(parse_failures_with_nan),
        "nan_plus_other": len(additional_parse_errors),
        "non_nan_details": parse_failures_non_nan[:50],
        "nan_plus_other_details": additional_parse_errors[:50],
    },
    "oversized": {"count": len(oversized), "files": sorted(oversized, key=lambda x: -x[1])[:50]},
    "schema_issues": {"count": len(schema_issues), "details": schema_issues[:100]},
    "null_bytes": {"count": len(null_byte_files), "files": null_byte_files[:50]},
    "huge_arrays": {"count": len(huge_arrays), "details": [(r, p, l) for r, p, l in huge_arrays[:50]]},
    "file_type_counts": dict(file_type_counts),
    "size_distribution": dict(size_buckets),
}
out_path = REVIEW_ROOT.parent / "json_quality_report.json"
with open(out_path, "w") as f:
    json.dump(summary, f, indent=2)
print(f"\nMachine-readable summary: {out_path}")
