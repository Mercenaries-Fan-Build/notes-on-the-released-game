#!/usr/bin/env python3
"""Extract diverse BE blocks from Xbox WAD and probe ucfx_byteswap schema coverage.

Decompresses blocks from the Xbox vz.wad, writes them to temp files, runs
ucfx_byteswap --report-schema-coverage --dry-run on each, and aggregates
the results into a summary report.
"""
from __future__ import annotations

import mmap
import re
import struct
import subprocess
import sys
import zlib
from collections import defaultdict
from pathlib import Path

SEGS_MAGIC = b"segs"
SCFF_MAGIC = b"SCFF"

TYPE_NAMES = {
    0xF011157A: "texture",
    0x42498680: "script",
    0x207359C7: "stance",
    0x18166555: "animation",
    0xE6B81A54: "ecs_node",
    0x5B724250: "mesh_B",
    0x7C569307: "mesh_A",
    0x600B904E: "mesh_C",
    0x39E5E978: "stringdb",
    0xBCFE6314: "path",
    0xECE70371: "state_machine",
    0xE5273C14: "audio_group",
}

PRIORITY_TYPES = {0xE6B81A54, 0xBCFE6314}  # ecs_node, path


def decompress_be_segs(mm: mmap.mmap, start: int, end: int) -> bytes:
    header = mm[start:start + 16]
    if header[:4] != SEGS_MAGIC:
        raise ValueError(f"Expected segs at 0x{start:X}")
    seg_count = struct.unpack_from(">H", header, 6)[0]
    segs: list[tuple[int, int]] = []
    for si in range(seg_count):
        so = start + 16 + si * 8
        csz = struct.unpack_from(">H", mm[so:so + 2], 0)[0]
        dsz = struct.unpack_from(">H", mm[so + 2:so + 4], 0)[0]
        segs.append((csz, dsz))
    hs = 16 + ((seg_count * 8 + 15) & ~15) if seg_count > 0 else 16
    payload = mm[start + hs:end]
    result = bytearray()
    pos = 0
    for csz, dsz in segs:
        if csz > 0 and csz == dsz:
            result.extend(payload[pos:pos + csz])
            pos += csz
        else:
            dc = zlib.decompressobj(-15)
            piece = dc.decompress(bytes(payload[pos:]))
            piece += dc.flush()
            consumed = len(payload[pos:]) - len(dc.unused_data)
            result.extend(piece)
            pos += consumed
        pos = (pos + 15) & ~15
    return bytes(result)


def get_block_type_hashes(block: bytes) -> list[int]:
    count = struct.unpack_from(">I", block, 0)[0]
    if count < 1 or count > 50000:
        return []
    hashes = []
    for i in range(count):
        th = struct.unpack_from(">I", block, 4 + i * 16 + 4)[0]
        hashes.append(th)
    return hashes


def parse_report_stderr(stderr: str) -> dict:
    """Parse the schema coverage report from stderr."""
    result = {
        "total_schema_fields": 0,
        "type_codes": {},        # code -> (name, count, known)
        "unknown_fields": [],    # list of dicts
        "schema_parse_failures": [],
        "no_schema_components": [],
        "generic_fallback_tags": [],
        "total_issues": 0,
    }

    for line in stderr.splitlines():
        line = line.strip()

        m = re.match(r"Total schema fields scanned:\s+(\d+)", line)
        if m:
            result["total_schema_fields"] = int(m.group(1))

        m = re.match(r"([! ]) code\s+(\d+)\s+\((\w+)\s*\)\s*:\s+(\d+)\s+field", line)
        if m:
            marker, code, name, count = m.groups()
            result["type_codes"][int(code)] = {
                "name": name, "count": int(count), "known": marker != "!",
            }

        m = re.match(r"component=(\S+)\s+field_hash=0x([0-9A-Fa-f]+)\s+offset=(\d+)\s+type_code=(\d+)", line)
        if m:
            result["unknown_fields"].append({
                "component": m.group(1),
                "field_hash": int(m.group(2), 16),
                "offset": int(m.group(3)),
                "type_code": int(m.group(4)),
            })

        m = re.match(r"component=(\S+)\s+unknown_code\(s\):\s+\[(.+?)\]", line)
        if m:
            codes = [int(c.strip()) for c in m.group(2).split(",")]
            result["schema_parse_failures"].append({
                "component": m.group(1), "codes": codes,
            })

        m = re.match(r"\s*(\S+)\s+data_size=(\d+)\s+swap=(.+)", line)
        if m and "component" not in line and "entry[" not in line and "desc[" not in line:
            result["no_schema_components"].append({
                "component": m.group(1),
                "data_size": int(m.group(2)),
                "swap": m.group(3).strip(),
            })

        m = re.match(r"entry\[(\d+)\]\s+type=0x([0-9A-Fa-f]+)\s+\((\w+)\)\s+tag=(\S+)\s+body_size=(\d+)", line)
        if m:
            result["generic_fallback_tags"].append({
                "entry_idx": int(m.group(1)),
                "type_hash": int(m.group(2), 16),
                "type_name": m.group(3),
                "tag": m.group(4),
                "body_size": int(m.group(5)),
            })

        m = re.match(r"Result:\s+(\d+)\s+item", line)
        if m:
            result["total_issues"] = int(m.group(1))

    return result


def main() -> int:
    repo = Path(__file__).resolve().parent.parent
    wad_path = repo / "game-files" / "xbox-vz.wad"
    binary = repo / "tools" / "wad_simulator" / "target" / "release" / "ucfx_byteswap.exe"
    temp_dir = repo / "output" / "temp_blocks"

    if not wad_path.exists():
        print(f"ERROR: Xbox WAD not found: {wad_path}", file=sys.stderr)
        return 1
    if not binary.exists():
        print(f"ERROR: binary not found: {binary}", file=sys.stderr)
        return 1

    temp_dir.mkdir(parents=True, exist_ok=True)
    print(f"Xbox WAD: {wad_path} ({wad_path.stat().st_size:,} bytes)")
    print(f"Binary:   {binary}")
    print(f"Temp dir: {temp_dir}")
    print()

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)

    header = bytes(mm[:256])
    if header[:4] != SCFF_MAGIC:
        print(f"ERROR: not an Xbox WAD (magic={header[:4]!r})", file=sys.stderr)
        mm.close()
        return 1

    # Parse FFCS header chunks
    chunk_count = struct.unpack_from(">I", header, 8)[0]
    rows = []
    for i in range(min(chunk_count, 5)):
        off = 0x0C + i * 12
        tag = header[off:off + 4][::-1].decode("ascii", errors="replace")
        val = struct.unpack_from(">I", header, off + 4)[0]
        meta = struct.unpack_from(">I", header, off + 8)[0]
        rows.append({"tag": tag, "offset": val, "meta": meta})

    data_row = next((r for r in rows if r["tag"] == "DATA"), None)
    if not data_row:
        print("ERROR: no DATA chunk", file=sys.stderr)
        mm.close()
        return 1
    data_off = data_row["offset"]

    # Parse PTHS for block names
    pths_row = next((r for r in rows if r["tag"] == "PTHS"), None)
    paths: list[str] = []
    if pths_row:
        blob = bytes(mm[pths_row["offset"]:pths_row["offset"] + 4_000_000])
        p = 0
        while p < len(blob):
            nul = blob.find(b"\x00", p)
            if nul < 0:
                break
            s = blob[p:nul].decode("ascii", errors="replace")
            if len(s) >= 2:
                paths.append(s)
            p = nul + 1
    print(f"PTHS: {len(paths)} paths")

    # Scan for segs blocks
    print("Scanning DATA for segs blocks...")
    file_size = len(mm)
    offsets: list[int] = []
    pos = data_off
    while pos < file_size:
        idx = mm.find(SEGS_MAGIC, pos, file_size)
        if idx < 0:
            break
        offsets.append(idx)
        pos = idx + 4
    print(f"Found {len(offsets)} segs blocks")
    print()

    # Select blocks: prioritize ecs_node and path, then diverse types
    MAX_BLOCKS = 30
    MAX_PER_TYPE = 3

    type_counts: dict[int, int] = defaultdict(int)
    selected: list[tuple[int, str, bytes, list[int]]] = []

    # First pass: priority types (ecs_node, path)
    for idx in range(len(offsets)):
        if len(selected) >= MAX_BLOCKS:
            break
        try:
            start = offsets[idx]
            end = offsets[idx + 1] if idx + 1 < len(offsets) else file_size
            block = decompress_be_segs(mm, start, end)
            type_hashes = get_block_type_hashes(block)
            if not type_hashes:
                continue
            has_priority = any(th in PRIORITY_TYPES for th in type_hashes)
            if has_priority:
                path_name = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
                selected.append((idx, path_name, block, type_hashes))
                for th in set(type_hashes):
                    type_counts[th] += 1
        except Exception:
            continue
        if sum(1 for _, _, _, ths in selected if any(t in PRIORITY_TYPES for t in ths)) >= 10:
            break

    # Second pass: diverse types
    for idx in range(len(offsets)):
        if len(selected) >= MAX_BLOCKS:
            break
        if any(s[0] == idx for s in selected):
            continue
        try:
            start = offsets[idx]
            end = offsets[idx + 1] if idx + 1 < len(offsets) else file_size
            block = decompress_be_segs(mm, start, end)
            type_hashes = get_block_type_hashes(block)
            if not type_hashes:
                continue
            unique_types = set(type_hashes)
            if all(type_counts.get(th, 0) >= MAX_PER_TYPE for th in unique_types):
                continue
            path_name = paths[idx] if idx < len(paths) else f"block_{idx:05d}"
            selected.append((idx, path_name, block, type_hashes))
            for th in unique_types:
                type_counts[th] += 1
        except Exception:
            continue

    mm.close()
    print(f"Selected {len(selected)} blocks for testing")

    # Write blocks to temp files
    block_files: list[tuple[int, str, Path, list[int]]] = []
    for idx, path_name, block, type_hashes in selected:
        safe_name = path_name.replace("/", "_").replace("\\", "_")
        out_file = temp_dir / f"{idx:05d}_{safe_name}.bin"
        out_file.write_bytes(block)
        block_files.append((idx, path_name, out_file, type_hashes))

    print(f"Wrote {len(block_files)} block files to {temp_dir}")
    print()

    # Run each block through the converter
    print("=" * 70)
    print("Running ucfx_byteswap --report-schema-coverage --dry-run")
    print("=" * 70)

    all_reports: list[dict] = []
    agg_type_codes: dict[int, dict] = {}
    agg_unknown_fields: list[dict] = []
    agg_schema_failures: list[dict] = []
    agg_no_schema: list[dict] = []
    agg_generic_fallback: list[dict] = []
    total_schema_fields = 0
    pass_count = 0
    error_count = 0

    for i, (idx, path_name, file_path, type_hashes) in enumerate(block_files):
        entry_types = sorted(set(TYPE_NAMES.get(th, f"0x{th:08X}") for th in type_hashes))
        entry_count = struct.unpack_from(">I", file_path.read_bytes()[:4], 0)[0]
        print(f"\n[{i+1}/{len(block_files)}] Block {idx}: {path_name}")
        print(f"  Entries: {entry_count}, types: {', '.join(entry_types)}")
        print(f"  Size: {file_path.stat().st_size:,} bytes")

        try:
            block_bytes = file_path.read_bytes()
            result = subprocess.run(
                [str(binary), "--stdin", "--stdout", "--report-schema-coverage", "--no-validate"],
                input=block_bytes, capture_output=True, timeout=60,
            )
            stderr = result.stderr.decode("utf-8", errors="replace")
            stdout = result.stdout.decode("utf-8", errors="replace")

            if result.returncode != 0:
                error_count += 1
                err_lines = stderr.strip().split("\n")
                print(f"  ERROR (exit {result.returncode}): {err_lines[-1] if err_lines else '?'}")
                all_reports.append({
                    "block_idx": idx, "path": path_name,
                    "status": "error", "error": err_lines[-1] if err_lines else "?",
                    "types": entry_types, "entry_count": entry_count,
                })
                continue

            report = parse_report_stderr(stderr)
            report["block_idx"] = idx
            report["path"] = path_name
            report["status"] = "ok"
            report["types"] = entry_types
            report["entry_count"] = entry_count
            all_reports.append(report)
            pass_count += 1

            total_schema_fields += report["total_schema_fields"]

            for code, info in report["type_codes"].items():
                if code not in agg_type_codes:
                    agg_type_codes[code] = {"name": info["name"], "count": 0, "known": info["known"]}
                agg_type_codes[code]["count"] += info["count"]

            for uf in report["unknown_fields"]:
                uf["block_idx"] = idx
                uf["path"] = path_name
                agg_unknown_fields.append(uf)

            for sf in report["schema_parse_failures"]:
                sf["block_idx"] = idx
                sf["path"] = path_name
                agg_schema_failures.append(sf)

            for ns in report["no_schema_components"]:
                ns["block_idx"] = idx
                ns["path"] = path_name
                agg_no_schema.append(ns)

            for gf in report["generic_fallback_tags"]:
                gf["block_idx"] = idx
                gf["path"] = path_name
                agg_generic_fallback.append(gf)

            issues = report["total_issues"]
            status = f"OK ({report['total_schema_fields']} fields)" if issues == 0 else \
                     f"{issues} issue(s) ({report['total_schema_fields']} fields)"
            print(f"  Schema coverage: {status}")

        except subprocess.TimeoutExpired:
            error_count += 1
            print(f"  ERROR: timeout (30s)")
            all_reports.append({
                "block_idx": idx, "path": path_name,
                "status": "timeout", "types": entry_types,
                "entry_count": entry_count,
            })

    # ── Aggregate Summary ──
    print()
    print("=" * 70)
    print("AGGREGATE SCHEMA COVERAGE SUMMARY")
    print("=" * 70)
    print()
    print(f"Blocks tested:        {len(block_files)}")
    print(f"  Successful:         {pass_count}")
    print(f"  Errors:             {error_count}")
    print(f"Total schema fields:  {total_schema_fields}")
    print()

    if agg_type_codes:
        print("Type code breakdown (all blocks combined):")
        for code in sorted(agg_type_codes.keys()):
            info = agg_type_codes[code]
            marker = " " if info["known"] else "!"
            print(f"  {marker} code {code:>2} ({info['name']:<10}): {info['count']:>6} field(s)")
        print()

    unknown_codes = {c: info for c, info in agg_type_codes.items() if not info["known"]}
    if unknown_codes:
        print(f"** UNKNOWN type codes: {len(unknown_codes)} distinct code(s) **")
        for code, info in sorted(unknown_codes.items()):
            print(f"  code {code}: {info['count']} field(s) — needs reverse engineering")
        print()

    if agg_unknown_fields:
        print(f"Unknown field instances: {len(agg_unknown_fields)}")
        by_component: dict[str, list] = defaultdict(list)
        for uf in agg_unknown_fields:
            by_component[uf["component"]].append(uf)
        for comp in sorted(by_component.keys()):
            fields = by_component[comp]
            codes = sorted(set(f["type_code"] for f in fields))
            print(f"  {comp}: {len(fields)} field(s), type_code(s): {codes}")
        print()

    if agg_schema_failures:
        print(f"Schema parse failures: {len(agg_schema_failures)}")
        by_comp: dict[str, set] = defaultdict(set)
        for sf in agg_schema_failures:
            for c in sf["codes"]:
                by_comp[sf["component"]].add(c)
        for comp in sorted(by_comp.keys()):
            print(f"  {comp}: unknown_code(s) = {sorted(by_comp[comp])}")
        print()

    u32_sweep_count = sum(1 for ns in agg_no_schema if ns["swap"] == "u32_array sweep")
    if agg_no_schema:
        print(f"Components with NO schema: {len(agg_no_schema)} total")
        print(f"  u32_array sweep (blind): {u32_sweep_count}")
        swap_strategies: dict[str, int] = defaultdict(int)
        for ns in agg_no_schema:
            swap_strategies[ns["swap"]] += 1
        for strategy, cnt in sorted(swap_strategies.items(), key=lambda x: -x[1]):
            print(f"  {strategy}: {cnt}")

        by_comp: dict[str, list] = defaultdict(list)
        for ns in agg_no_schema:
            by_comp[ns["component"]].append(ns)
        print()
        print("  No-schema components by name (top 30):")
        for comp in sorted(by_comp.keys())[:30]:
            entries = by_comp[comp]
            sizes = sorted(set(e["data_size"] for e in entries))
            swaps = sorted(set(e["swap"] for e in entries))
            print(f"    {comp}: {len(entries)}× data_size={sizes} swap={swaps}")
        if len(by_comp) > 30:
            print(f"    ... and {len(by_comp) - 30} more unique components")
        print()

    if agg_generic_fallback:
        print(f"Non-ECS generic fallback tags: {len(agg_generic_fallback)}")
        by_tag: dict[str, int] = defaultdict(int)
        for gf in agg_generic_fallback:
            key = f"{gf['tag']} (type={gf['type_name']})"
            by_tag[key] += 1
        for tag_key, cnt in sorted(by_tag.items(), key=lambda x: -x[1]):
            print(f"  {tag_key}: {cnt}×")
        print()

    # Final tally
    total_issues = (len(agg_unknown_fields) + len(agg_schema_failures) +
                    u32_sweep_count + len(agg_generic_fallback))
    print("=" * 70)
    if total_issues == 0:
        print("RESULT: All data bodies have typed swap coverage.")
    else:
        print(f"RESULT: {total_issues} total item(s) using fallback/unknown swap paths")
        print()
        print("Recommendations for next reverse-engineering steps:")
        if unknown_codes:
            print(f"  1. Reverse-engineer unknown type codes: {sorted(unknown_codes.keys())}")
        if agg_schema_failures:
            poisoned = sorted(set(sf["component"] for sf in agg_schema_failures))
            print(f"  2. Fix schema parsing for components: {poisoned[:10]}")
        if u32_sweep_count > 0:
            blind_comps = sorted(set(ns["component"] for ns in agg_no_schema
                                     if ns["swap"] == "u32_array sweep"))
            print(f"  3. Add schemas for blind-sweep components: {blind_comps[:10]}")
        if agg_generic_fallback:
            fb_tags = sorted(set(gf["tag"] for gf in agg_generic_fallback))
            print(f"  4. Add typed converters for fallback tags: {fb_tags[:10]}")
    print("=" * 70)

    return 0


if __name__ == "__main__":
    sys.exit(main())
