#!/usr/bin/env python3
"""Decompile a Mercenaries 2 LuaQ chunk and verify round-trip compilation.

Workflow:
  1. Read a .chunk.bin (raw LuaQ bytecode)
  2. Attempt decompilation via unluac (Java) or luadec (C)
  3. Recompile the decompiled source with the custom Lua 5.1 float compiler
  4. Compare original and recompiled bytecode
  5. Report differences (header, constants, instructions, debug info)

Usage:
  python3 tools/lua_roundtrip_test.py --chunk output/lua_chunks/scripts_vz/wiftutorialtank.chunk.bin
  python3 tools/lua_roundtrip_test.py --chunk-dir output/lua_chunks/scripts_vz/ --max 5
"""

from __future__ import annotations

import argparse
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LUAC = REPO_ROOT / "tools" / "lua51-mercs2" / "luac"
EXPECTED_HEADER = bytes.fromhex("1b4c75615100010404040400")


def parse_header(data: bytes) -> dict:
    if len(data) < 12:
        return {"error": "too short"}
    return {
        "magic": data[0:4],
        "version": data[4],
        "format": data[5],
        "endian": data[6],
        "int_size": data[7],
        "size_t_size": data[8],
        "instruction_size": data[9],
        "number_size": data[10],
        "integral": data[11],
    }


def validate_header(data: bytes) -> str | None:
    if len(data) < 12:
        return "File too short for LuaQ header"
    if data[:12] != EXPECTED_HEADER:
        return f"Header mismatch: got {data[:12].hex()}, expected {EXPECTED_HEADER.hex()}"
    return None


def try_decompile_unluac(chunk_path: Path, out_path: Path) -> bool:
    """Attempt decompilation via unluac (must be on PATH or in tools/)."""
    unluac_jar = REPO_ROOT / "tools" / "unluac.jar"
    if not unluac_jar.exists():
        for p in [Path("/usr/local/share/unluac.jar"), Path.home() / "unluac.jar"]:
            if p.exists():
                unluac_jar = p
                break

    if unluac_jar.exists():
        try:
            result = subprocess.run(
                ["java", "-jar", str(unluac_jar), str(chunk_path)],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode == 0 and result.stdout.strip():
                out_path.write_text(result.stdout)
                return True
            print(f"  unluac failed: {result.stderr[:200]}", file=sys.stderr)
        except (subprocess.TimeoutExpired, FileNotFoundError) as e:
            print(f"  unluac error: {e}", file=sys.stderr)
    return False


def try_decompile_luadec(chunk_path: Path, out_path: Path) -> bool:
    """Attempt decompilation via luadec51 (must be on PATH)."""
    for name in ["luadec51", "luadec5.1", "luadec"]:
        try:
            result = subprocess.run(
                [name, str(chunk_path)],
                capture_output=True, text=True, timeout=30,
            )
            if result.returncode == 0 and result.stdout.strip():
                out_path.write_text(result.stdout)
                return True
        except FileNotFoundError:
            continue
        except subprocess.TimeoutExpired:
            print(f"  {name} timed out", file=sys.stderr)
    return False


def recompile(source_path: Path, output_path: Path) -> bool:
    """Recompile Lua source with the custom Mercs2 compiler."""
    if not LUAC.exists():
        print(f"  ERROR: Custom luac not found at {LUAC}", file=sys.stderr)
        print(f"  Build it: cd lua-5.1.5 && make macosx", file=sys.stderr)
        return False
    try:
        result = subprocess.run(
            [str(LUAC), "-o", str(output_path), str(source_path)],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(f"  luac failed: {result.stderr[:200]}", file=sys.stderr)
            return False
        return True
    except (subprocess.TimeoutExpired, FileNotFoundError) as e:
        print(f"  luac error: {e}", file=sys.stderr)
        return False


def compare_bytecode(original: bytes, recompiled: bytes) -> dict:
    """Compare two LuaQ bytecodes and report differences."""
    report = {
        "original_size": len(original),
        "recompiled_size": len(recompiled),
        "size_match": len(original) == len(recompiled),
        "byte_identical": original == recompiled,
    }

    if original == recompiled:
        report["diff_count"] = 0
        return report

    min_len = min(len(original), len(recompiled))
    diffs = []
    for i in range(min_len):
        if original[i] != recompiled[i]:
            diffs.append(i)
    report["diff_count"] = len(diffs) + abs(len(original) - len(recompiled))
    report["first_diff_offset"] = diffs[0] if diffs else min_len
    report["diff_offsets_sample"] = diffs[:20]

    if len(diffs) > 0 and diffs[0] < 12:
        report["header_differs"] = True
    else:
        report["header_differs"] = False

    return report


def test_chunk(chunk_path: Path, work_dir: Path) -> dict:
    """Run full round-trip test on one chunk."""
    result = {"chunk": chunk_path.name, "status": "unknown"}

    data = chunk_path.read_bytes()
    header_err = validate_header(data)
    if header_err:
        result["status"] = "bad_header"
        result["error"] = header_err
        return result

    result["original_size"] = len(data)
    result["header"] = parse_header(data)

    source_name = "unknown"
    if len(data) > 16:
        name_len = struct.unpack_from("<I", data, 12)[0]
        if 0 < name_len < 256 and 12 + 4 + name_len <= len(data):
            raw = data[16:16 + name_len]
            source_name = raw.rstrip(b"\x00").decode("ascii", errors="replace")
    result["source_name"] = source_name

    decompiled_path = work_dir / f"{chunk_path.stem}.lua"
    decompiled = try_decompile_unluac(chunk_path, decompiled_path)
    if not decompiled:
        decompiled = try_decompile_luadec(chunk_path, decompiled_path)

    if not decompiled:
        result["status"] = "no_decompiler"
        result["error"] = "Neither unluac nor luadec available; install one to test round-trip"
        return result

    result["decompiled_size"] = decompiled_path.stat().st_size

    recompiled_path = work_dir / f"{chunk_path.stem}.recompiled.luac"
    if not recompile(decompiled_path, recompiled_path):
        result["status"] = "recompile_failed"
        return result

    recompiled_data = recompiled_path.read_bytes()
    comparison = compare_bytecode(data, recompiled_data)
    result.update(comparison)

    if comparison["byte_identical"]:
        result["status"] = "perfect_match"
    elif comparison["diff_count"] < 20:
        result["status"] = "minor_differences"
    else:
        result["status"] = "significant_differences"

    return result


def main() -> int:
    ap = argparse.ArgumentParser(description="Lua round-trip decompile/recompile test")
    ap.add_argument("--chunk", type=Path, help="Single .chunk.bin to test")
    ap.add_argument("--chunk-dir", type=Path, help="Directory of .chunk.bin files")
    ap.add_argument("--max", type=int, default=0, help="Max chunks to test (0 = all)")
    ap.add_argument("--work-dir", type=Path, help="Working directory for intermediates")
    args = ap.parse_args()

    if not args.chunk and not args.chunk_dir:
        default = Path("output/lua_chunks/scripts_vz")
        if default.is_dir():
            args.chunk_dir = default
        else:
            ap.error("Provide --chunk or --chunk-dir, or run lua_script_chunks.py first")

    if not LUAC.exists():
        print(f"ERROR: Custom Lua compiler not found at {LUAC}", file=sys.stderr)
        print("Build it: cd lua-5.1.5 && make macosx", file=sys.stderr)
        return 1

    chunks: list[Path] = []
    if args.chunk:
        chunks = [args.chunk]
    elif args.chunk_dir:
        chunks = sorted(args.chunk_dir.glob("*.chunk.bin"))

    if args.max > 0:
        chunks = chunks[:args.max]

    if not chunks:
        print("No .chunk.bin files found", file=sys.stderr)
        return 1

    print(f"Testing {len(chunks)} chunk(s)...")
    print(f"Compiler: {LUAC}")
    print()

    results = []
    with tempfile.TemporaryDirectory(prefix="lua_roundtrip_") as tmpdir:
        work = Path(args.work_dir) if args.work_dir else Path(tmpdir)
        work.mkdir(parents=True, exist_ok=True)

        for chunk_path in chunks:
            print(f"--- {chunk_path.name} ---")
            r = test_chunk(chunk_path, work)
            results.append(r)

            print(f"  Source name: {r.get('source_name', '?')}")
            print(f"  Status: {r['status']}")
            if "error" in r:
                print(f"  Error: {r['error']}")
            if "diff_count" in r:
                print(f"  Original: {r['original_size']} bytes")
                print(f"  Recompiled: {r.get('recompiled_size', '?')} bytes")
                print(f"  Differences: {r['diff_count']} bytes")
                if r.get("diff_offsets_sample"):
                    print(f"  First diffs at: {r['diff_offsets_sample']}")
            print()

    perfect = sum(1 for r in results if r["status"] == "perfect_match")
    minor = sum(1 for r in results if r["status"] == "minor_differences")
    failed = sum(1 for r in results if r["status"] in ("recompile_failed", "bad_header"))
    no_tool = sum(1 for r in results if r["status"] == "no_decompiler")

    print("=" * 50)
    print(f"Results: {len(results)} tested")
    print(f"  Perfect match:  {perfect}")
    print(f"  Minor diffs:    {minor}")
    print(f"  Failed:         {failed}")
    print(f"  No decompiler:  {no_tool}")

    if no_tool > 0:
        print()
        print("To enable decompilation, install one of:")
        print("  - unluac: download unluac.jar to tools/unluac.jar")
        print("  - luadec: build luadec51 from source with LUA_NUMBER=float")

    return 0


if __name__ == "__main__":
    sys.exit(main())
