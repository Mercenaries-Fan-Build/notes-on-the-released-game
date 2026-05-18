#!/usr/bin/env python3
"""Extract and disassemble all Lua scripts from the Mercenaries 2 scripts block.

Reads the decompressed scripts_vz block, extracts each UCFX chunk's Lua bytecode,
runs `luac -l -l` to produce disassembly listings, and generates API analysis.

Usage:
  python3 tools/extract_all_scripts.py \
    --block output_demo/extracted/scripts_vz_demo.block.bin \
    --output output_demo/scripts_disasm \
    --luac lua-5.1.5/src/luac
"""
from __future__ import annotations

import argparse
import json
import os
import re
import struct
import subprocess
import sys
from pathlib import Path

UCFX_MAGIC = b"UCFX"
BINN_TAG = b"BINN"
CSUM_TAG = b"CSUM"
LUAQ_SIG = b"\x1bLua"


def parse_block_entries(data: bytes) -> list[dict]:
    """Parse block header: count(4) + count * entry(16)."""
    if len(data) < 4:
        raise ValueError("Block data too short")
    count = struct.unpack_from("<I", data, 0)[0]
    header_end = 4 + count * 16

    entries: list[dict] = []
    pos = header_end
    for i in range(count):
        h, th, fc, s = struct.unpack_from("<IIII", data, 4 + i * 16)
        entries.append({
            "index": i,
            "hash": h,
            "type_hash": th,
            "field_c": fc,
            "size": s,
            "offset": pos,
        })
        pos += s
    return entries


def get_script_name(data: bytes, entry: dict) -> str:
    """Extract the script name from BINN section."""
    chunk = data[entry["offset"]:entry["offset"] + entry["size"] - 8]
    binn_off = chunk.find(BINN_TAG)
    if binn_off < 0:
        return f"unknown_{entry['index']:03d}"
    region = chunk[binn_off + 4:binn_off + 300]
    i = 0
    while i < len(region):
        if 32 <= region[i] < 127:
            j = i
            while j < len(region) and 32 <= region[j] < 127:
                j += 1
            s = region[i:j].decode("ascii")
            if len(s) >= 4 and s not in ("BINN", "LuaQ", "UCFX"):
                return s
            i = j
        else:
            i += 1
    return f"unknown_{entry['index']:03d}"


def extract_lua_bytecode(data: bytes, entry: dict) -> bytes | None:
    """Extract the LuaQ bytecode from a UCFX chunk entry."""
    entry_start = entry["offset"]
    entry_end = entry["offset"] + entry["size"] - 8
    chunk = data[entry_start:entry_end]
    luaq_off = chunk.find(LUAQ_SIG)
    if luaq_off < 0:
        return None
    return chunk[luaq_off:]


def extract_strings_from_bytecode(bytecode: bytes) -> list[str]:
    """Extract readable string constants from Lua 5.1 bytecode."""
    strings = []
    pos = 0
    while pos < len(bytecode) - 4:
        # Lua 5.1 strings are preceded by a size_t length
        # Try to find printable string sequences
        if 32 <= bytecode[pos] < 127:
            end = pos
            while end < len(bytecode) and 32 <= bytecode[end] < 127:
                end += 1
            if bytecode[end:end+1] == b'\x00' and end - pos >= 3:
                s = bytecode[pos:end].decode("ascii", errors="replace")
                strings.append(s)
                pos = end + 1
            else:
                pos += 1
        else:
            pos += 1
    return strings


def analyze_disassembly(disasm_text: str) -> dict:
    """Parse luac disassembly output for API patterns."""
    result = {
        "globals_get": [],
        "globals_set": [],
        "self_calls": [],
        "functions": [],
        "constants": [],
    }

    for line in disasm_text.split("\n"):
        line = line.strip()
        # GETGLOBAL pattern: identifies global variable access
        m = re.search(r'GETGLOBAL\s+\d+\s+-\d+\s*;\s*(\S+)', line)
        if m:
            result["globals_get"].append(m.group(1))
            continue

        m = re.search(r'SETGLOBAL\s+\d+\s+-\d+\s*;\s*(\S+)', line)
        if m:
            result["globals_set"].append(m.group(1))
            continue

        # SELF pattern: method calls
        m = re.search(r'SELF\s+\d+\s+\d+\s+-\d+\s*;\s*"([^"]+)"', line)
        if m:
            result["self_calls"].append(m.group(1))
            continue

        # Function names from "function <name>" lines
        m = re.match(r'function\s+<[^>]+>\s*\(', line)
        if m:
            result["functions"].append(line)
            continue

        # String constants
        m = re.search(r';\s*"([^"]*)"', line)
        if m and len(m.group(1)) >= 2:
            result["constants"].append(m.group(1))

    return result


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract and disassemble all Lua scripts")
    ap.add_argument("--block", type=Path, required=True,
                    help="Decompressed scripts block .bin file")
    ap.add_argument("--output", type=Path, required=True,
                    help="Output directory for disassemblies")
    ap.add_argument("--luac", type=Path, default=Path("lua-5.1.5/src/luac"),
                    help="Path to luac binary")
    args = ap.parse_args()

    if not args.block.is_file():
        print(f"ERROR: Block file not found: {args.block}", file=sys.stderr)
        return 1
    if not args.luac.is_file():
        print(f"ERROR: luac not found: {args.luac}", file=sys.stderr)
        return 1

    args.output.mkdir(parents=True, exist_ok=True)
    bytecode_dir = args.output / "bytecode"
    bytecode_dir.mkdir(parents=True, exist_ok=True)

    print(f"Reading block: {args.block} ({args.block.stat().st_size:,} bytes)")
    data = args.block.read_bytes()
    entries = parse_block_entries(data)
    print(f"Found {len(entries)} UCFX entries")

    all_analysis: list[dict] = []
    failed = []

    for entry in entries:
        name = get_script_name(data, entry)
        bytecode = extract_lua_bytecode(data, entry)

        if bytecode is None:
            print(f"  [{entry['index']:3d}] {name:30s} — NO BYTECODE")
            failed.append({"index": entry["index"], "name": name, "reason": "no LuaQ"})
            continue

        # Save raw bytecode
        bc_path = bytecode_dir / f"{name}.luac"
        bc_path.write_bytes(bytecode)

        # Run luac -l -l for disassembly
        disasm_path = args.output / f"{name}.disasm.txt"
        result = subprocess.run(
            [str(args.luac), "-l", "-l", str(bc_path)],
            capture_output=True, text=True, timeout=30,
        )

        if result.returncode != 0:
            # luac -l -l failed, try just -l
            result = subprocess.run(
                [str(args.luac), "-l", str(bc_path)],
                capture_output=True, text=True, timeout=30,
            )

        if result.returncode != 0:
            print(f"  [{entry['index']:3d}] {name:30s} — DISASM FAILED: {result.stderr.strip()}")
            failed.append({"index": entry["index"], "name": name, "reason": result.stderr.strip()})
            # Still save what we have
            disasm_path.write_text(f"DISASSEMBLY FAILED\n{result.stderr}\n")
            # Fall back to string extraction
            strings = extract_strings_from_bytecode(bytecode)
            strings_path = args.output / f"{name}.strings.txt"
            strings_path.write_text("\n".join(strings))
            all_analysis.append({
                "index": entry["index"],
                "name": name,
                "hash": f"0x{entry['hash']:08X}",
                "size": entry["size"],
                "bytecode_size": len(bytecode),
                "disasm_failed": True,
                "strings": strings[:100],
            })
            continue

        disasm_text = result.stdout
        disasm_path.write_text(disasm_text)

        # Analyze the disassembly
        analysis = analyze_disassembly(disasm_text)

        # Also extract raw strings for deeper analysis
        strings = extract_strings_from_bytecode(bytecode)

        entry_info = {
            "index": entry["index"],
            "name": name,
            "hash": f"0x{entry['hash']:08X}",
            "size": entry["size"],
            "bytecode_size": len(bytecode),
            "globals_get": sorted(set(analysis["globals_get"])),
            "globals_set": sorted(set(analysis["globals_set"])),
            "self_calls": sorted(set(analysis["self_calls"])),
            "function_count": len(analysis["functions"]),
            "key_strings": [s for s in strings if any(kw in s for kw in [
                "inherit", "import", "Event", "Timer", "Complete", "Cancel",
                "Activated", "Mrx", "Contract", "Mission", "Objective",
                "self", "Create", "Vehicle", "Player", "Spawn", "AI",
            ])],
        }
        all_analysis.append(entry_info)

        print(f"  [{entry['index']:3d}] {name:30s} "
              f"({len(bytecode):6,} bytes, "
              f"{len(analysis['globals_get'])} globals, "
              f"{len(analysis['self_calls'])} methods)")

    # Save full analysis JSON
    analysis_path = args.output / "full_analysis.json"
    analysis_path.write_text(json.dumps(all_analysis, indent=2))

    # Generate API catalog
    print("\n" + "=" * 70)
    print("API CATALOG")
    print("=" * 70)

    all_globals = {}
    all_methods = {}
    all_inherits = []
    all_imports = []
    all_events = []

    for entry_info in all_analysis:
        name = entry_info["name"]
        for g in entry_info.get("globals_get", []):
            all_globals.setdefault(g, []).append(name)
        for m in entry_info.get("self_calls", []):
            all_methods.setdefault(m, []).append(name)

        for s in entry_info.get("key_strings", []):
            if "inherit" in s.lower() and "(" not in s:
                pass
            if s.startswith("Mrx") or s.startswith("Wif"):
                pass

    # Find inherit/import patterns from strings
    for entry_info in all_analysis:
        for s in entry_info.get("key_strings", []):
            if "inherit" in s.lower():
                all_inherits.append({"script": entry_info["name"], "inherits": s})
            if "import" in s.lower() and "import" in s:
                all_imports.append({"script": entry_info["name"], "imports": s})

    catalog = {
        "total_scripts": len(entries),
        "successful_disasm": len(entries) - len(failed),
        "failed": failed,
        "unique_globals": sorted(all_globals.keys()),
        "unique_methods": sorted(all_methods.keys()),
        "globals_by_usage": {k: v for k, v in sorted(all_globals.items(), key=lambda x: -len(x[1]))[:50]},
        "methods_by_usage": {k: v for k, v in sorted(all_methods.items(), key=lambda x: -len(x[1]))[:50]},
    }

    catalog_path = args.output / "api_catalog.json"
    catalog_path.write_text(json.dumps(catalog, indent=2))

    # Print summary
    print(f"\nTotal scripts: {len(entries)}")
    print(f"Successfully disassembled: {len(entries) - len(failed)}")
    print(f"Failed: {len(failed)}")
    print(f"\nUnique global accesses: {len(all_globals)}")
    print(f"Unique method calls: {len(all_methods)}")
    print(f"\nTop 20 globals by usage count:")
    for g, scripts in sorted(all_globals.items(), key=lambda x: -len(x[1]))[:20]:
        print(f"  {g:30s} ({len(scripts)} scripts)")
    print(f"\nTop 20 methods by usage count:")
    for m, scripts in sorted(all_methods.items(), key=lambda x: -len(x[1]))[:20]:
        print(f"  {m:30s} ({len(scripts)} scripts)")

    print(f"\nOutput saved to: {args.output}/")
    print(f"  - bytecode/         (raw .luac files)")
    print(f"  - *.disasm.txt      (luac disassembly listings)")
    print(f"  - full_analysis.json")
    print(f"  - api_catalog.json")

    return 0


if __name__ == "__main__":
    sys.exit(main())
