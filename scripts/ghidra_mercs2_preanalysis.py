#!/usr/bin/env python3
"""
ghidra_mercs2_preanalysis.py — Standalone pre-analysis for Mercs 2 binary annotation.

Scans Mercenaries 1 source code to build a JSON database of:
  - Debug/log strings, class names, function registration tables
  - Known luaL_Reg patterns to search for in Mercs 2
  - RTTI class name patterns
  - Known VAs from the ASI plugin research

Output: JSON file consumed by ghidra_mercs2_annotate.py (the Ghidra script).

Usage:
    .venv/bin/python3 scripts/ghidra_mercs2_preanalysis.py --output scripts/mercs2_annotations.json
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

REPO_ROOT = Path(__file__).resolve().parent.parent

MERCS1_SOURCE_DIRS = [
    REPO_ROOT / "game-files" / "first-game-source-code-with-engine"
    / "Final_Editor_And_Projects_Folders" / "Projects" / "RedEngine" / "Source",
    REPO_ROOT / "game-files" / "first-game-source-code-with-engine"
    / "Final_Editor_And_Projects_Folders" / "Projects" / "RetroStrike" / "Source",
    REPO_ROOT / "game-files" / "first-game-source-code-with-engine"
    / "Final_Editor_And_Projects_Folders" / "Projects" / "Pebble" / "Source",
    REPO_ROOT / "game-files" / "first-game-source-code-with-engine"
    / "Final_Editor_And_Projects_Folders" / "Projects" / "Lua",
]

SOURCE_EXTENSIONS = {".cpp", ".c", ".h", ".inl"}

# ---------------------------------------------------------------------------
# Known VAs from dlc_enable.c and binary analysis
# ---------------------------------------------------------------------------

KNOWN_VAS: list[dict[str, Any]] = [
    {"va": 0x005AE2D0, "name": "_SYS._IMPORT", "type": "lua_CFunction",
     "comment": "Mercs 2 import() implementation — loads script modules"},
    {"va": 0x00860240, "name": "luaL_loadbuffer", "type": "lua_api",
     "comment": "LTCG: EAX=name, EDX=L, stack=(buff,sz); returns status in EAX"},
    {"va": 0x0085DF50, "name": "lua_pcall", "type": "lua_api",
     "comment": "LTCG: EAX=L, ECX=errfunc, EDI=nresults, stack=(nargs)"},
    {"va": 0x00860FC0, "name": "luaB_loadstring", "type": "lua_wrapper",
     "comment": "Standard cdecl lua_CFunction wrapper for luaL_loadbuffer"},
    {"va": 0x008615F0, "name": "luaB_pcall", "type": "lua_wrapper",
     "comment": "Standard cdecl lua_CFunction wrapper"},
    {"va": 0x008607E0, "name": "luaB_setfenv", "type": "lua_wrapper",
     "comment": "db_setfenv — cdecl lua_CFunction"},
    {"va": 0x0085F050, "name": "luaL_typerror", "type": "lua_api",
     "comment": "Previously misidentified as luaL_loadbuffer"},
    {"va": 0x00868AD0, "name": "luaD_pcall", "type": "lua_internal",
     "comment": "Internal pcall dispatcher (called by luaB_pcall, not lua_pcall)"},
    {"va": 0x006D5640, "name": "shared_print_stub", "type": "stub",
     "comment": "xor eax,eax; ret — shared by print, Debug.Printf, ~60+ registrations"},
    {"va": 0x005AE372, "name": "script_cmd_crash_point", "type": "bug",
     "comment": "NULL dereference in script command dispatcher when table uninitialized"},
    {"va": 0x00B98828, "name": "Debug_luaL_Reg_table", "type": "rdata_table",
     "comment": "Start of Debug.* luaL_Reg array in .rdata"},
    {"va": 0x00B9882C, "name": "Debug.Printf_func_ptr", "type": "rdata_ptr",
     "comment": "Function pointer slot for Debug.Printf in luaL_Reg"},
    {"va": 0x00B9251C, "name": "print_func_ptr", "type": "rdata_ptr",
     "comment": "Function pointer slot for base print() in luaL_Reg"},
    {"va": 0x00B98A7C, "name": "Sys.WriteToConsole_func_ptr", "type": "rdata_ptr",
     "comment": "First Sys.* luaL_Reg entry func ptr"},
    {"va": 0x01176630, "name": "g_scriptCommandTable", "type": "global_ptr",
     "comment": "Global pointer to script command dispatch table (can be NULL early)"},

    # Section layout
    {"va": 0x00B05000, "name": ".rdata_start", "type": "section",
     "comment": "Start of .rdata section (size 0xF1000)"},
    {"va": 0x00401000, "name": ".text_start", "type": "section",
     "comment": "Start of .text section (size 0x703000)"},

    # --- Spatial-hash crash investigation (docs/spatial_hash_crash_analysis.md) ---
    # In-.text decomp targets (resolve cell-index formula + entity field extraction).
    {"va": 0x00516B10, "name": "spatial_cell_index_calc", "type": "decomp_target",
     "comment": "Spatial-hash cell-index computation (reads entity XYZ). Decompile to "
                "recover the float->cell-index formula and confirm whether it reads "
                "position via schm field offsets."},
    {"va": 0x00516C00, "name": "spatial_hash_insert", "type": "decomp_target",
     "comment": "Spatial-hash insert/register path (near cell-index calc)."},
    {"va": 0x0051812F, "name": "spatial_loader_entry", "type": "decomp_target",
     "comment": "Loader/registration caller feeding the spatial hash."},
    {"va": 0x00516EF6, "name": "spatial_hash_benign_site", "type": "decomp_target",
     "comment": "Secondary spatial-hash read site seen in x32dbg captures."},
    {"va": 0x0063DA1F, "name": "entity_construct_stride", "type": "decomp_target",
     "comment": "Candidate entity-construction site — recover record stride/offset "
                "and whether non-Transform components extract position via schm offsets."},
    # Runtime fault VAs (NOT in static .text; base must be resolved from a live
    # x32dbg session before mapping to file offsets — see Phase 2 capture recipe).
    {"va": 0x0248BB60, "name": "RUNTIME_spatial_fn", "type": "runtime_va",
     "comment": "Crash function (read 0x248BB7C / write 0x248BBE2; cond bp 0x248BB6D). "
                "Above static .text — resolve module base at runtime."},
]

# Section boundaries for luaL_Reg scanning heuristics
RDATA_START = 0x00B05000
RDATA_END = RDATA_START + 0x000F1000
TEXT_START = 0x00401000
TEXT_END = TEXT_START + 0x00703000


def find_source_files(dirs: list[Path]) -> list[Path]:
    """Recursively find C/C++ source files."""
    files = []
    for d in dirs:
        if not d.exists():
            continue
        for root, _dirnames, filenames in os.walk(d):
            for fn in filenames:
                if Path(fn).suffix.lower() in SOURCE_EXTENSIONS:
                    files.append(Path(root) / fn)
    return sorted(files)


def read_file_text(path: Path) -> str:
    """Read a source file, handling CRLF and common encodings."""
    for enc in ("utf-8", "latin-1", "cp1252"):
        try:
            return path.read_text(encoding=enc)
        except (UnicodeDecodeError, ValueError):
            continue
    return ""


# ---------------------------------------------------------------------------
# Phase 1: String extraction from Mercs 1 source
# ---------------------------------------------------------------------------

# Patterns for debug/log/assert strings
_RE_STRING_LITERAL = re.compile(r'"([^"\\]*(?:\\.[^"\\]*)*)"')
_RE_PRINTF_CALL = re.compile(
    r'\b(printf|OutputDebugString|Debug_Printf|ASSERT|assert|RED_ASSERT'
    r'|RED_TRACE|PBL_TRACE|PBL_ASSERT|RED_WARNING|RED_ERROR'
    r'|LOG|TRACE|WARN|ERROR)\s*\(',
    re.IGNORECASE,
)
_RE_CLASS_DECL = re.compile(
    r'\bclass\s+(__declspec\s*\([^)]*\)\s+)?(\w+)\s*(?::\s*(?:public|protected|private)\s+(\w+))?',
)
_RE_LUALREG_ENTRY = re.compile(
    r'\{\s*"([^"]+)"\s*,\s*(\w+)\s*\}',
)


def extract_strings_from_source(files: list[Path]) -> dict[str, Any]:
    """Extract debug strings, class names, and Lua registrations from Mercs 1 source."""

    debug_strings: dict[str, list[dict]] = {}
    class_names: dict[str, dict] = {}
    lua_reg_entries: list[dict] = []
    all_string_literals: set[str] = set()
    error_messages: set[str] = set()

    for fpath in files:
        text = read_file_text(fpath)
        if not text:
            continue

        relpath = str(fpath.relative_to(REPO_ROOT)) if fpath.is_relative_to(REPO_ROOT) else str(fpath)
        lines = text.split("\n")

        # Extract all string literals
        for s in _RE_STRING_LITERAL.findall(text):
            cleaned = s.replace("\\n", "\n").replace("\\t", "\t").replace('\\"', '"')
            if len(cleaned) >= 4:
                all_string_literals.add(cleaned)

        # Extract debug/log call strings
        for i, line in enumerate(lines):
            if _RE_PRINTF_CALL.search(line):
                for s in _RE_STRING_LITERAL.findall(line):
                    cleaned = s.replace("\\n", "").replace("\\t", " ").replace('\\"', '"').strip()
                    if len(cleaned) >= 4:
                        if cleaned not in debug_strings:
                            debug_strings[cleaned] = []
                        debug_strings[cleaned].append({
                            "file": relpath,
                            "line": i + 1,
                        })

            # Extract error-like messages (longer strings with specific patterns)
            for s in _RE_STRING_LITERAL.findall(line):
                cleaned = s.strip()
                if any(kw in cleaned.lower() for kw in
                       ("error", "fail", "invalid", "cannot", "unable", "assert",
                        "warning", "missing", "unexpected", "corrupt")):
                    if len(cleaned) >= 6:
                        error_messages.add(cleaned)

        # Extract class declarations
        for m in _RE_CLASS_DECL.finditer(text):
            cname = m.group(2)
            parent = m.group(3) or ""
            if cname not in class_names:
                class_names[cname] = {
                    "name": cname,
                    "parent": parent,
                    "file": relpath,
                    "rtti_pattern": ".?AV%s@@" % cname,
                }

        # Extract luaL_reg entries
        for m in _RE_LUALREG_ENTRY.finditer(text):
            lua_name = m.group(1)
            c_func = m.group(2)
            if lua_name != "0" and c_func != "0":
                lua_reg_entries.append({
                    "lua_name": lua_name,
                    "c_function": c_func,
                    "source_file": relpath,
                })

    return {
        "debug_strings": debug_strings,
        "class_names": class_names,
        "lua_reg_entries": lua_reg_entries,
        "all_string_literals": sorted(all_string_literals),
        "error_messages": sorted(error_messages),
    }


# ---------------------------------------------------------------------------
# Phase 2: Build luaL_Reg search patterns for Mercs 2
# ---------------------------------------------------------------------------

def build_lua_search_patterns(lua_entries: list[dict]) -> dict[str, Any]:
    """
    Build patterns for finding luaL_Reg tables in the Mercs 2 binary.

    In Mercs 2, the API evolved from flat Subsystem_Function names to
    table-based registration (Debug.Printf, Sys.WriteToConsole, etc.).
    We provide both Mercs 1 names and likely Mercs 2 equivalents.
    """

    # Group by subsystem prefix
    subsystems: dict[str, list[str]] = {}
    for entry in lua_entries:
        name = entry["lua_name"]
        parts = name.split("_", 1)
        prefix = parts[0] if len(parts) > 1 else "Base"
        subsystems.setdefault(prefix, []).append(name)

    # Known Mercs 2 Lua table modules (from binary analysis)
    mercs2_modules = [
        "Debug", "Sys", "System", "Actor", "Ai", "Mission", "Event",
        "Camera", "Audio", "Player", "Faction", "Vehicle", "Squad",
        "Objective", "Ui", "HUD", "Effect", "Traffic", "Shop",
        "Boundary", "Region", "Briefing", "Cinematic", "Weather",
        "Renderer", "Utility", "Global", "Challenge", "Desktop",
        "Network", "Net", "Online", "Save", "Load", "Mail",
        "Support", "Building", "Location", "Encounter", "Terrain",
        "Water", "Physics", "Path",
    ]

    # Likely string patterns that would appear in luaL_Reg tables
    search_strings = set()
    for entry in lua_entries:
        search_strings.add(entry["lua_name"])
        parts = entry["lua_name"].split("_", 1)
        if len(parts) > 1:
            search_strings.add(parts[1])

    return {
        "subsystem_groups": subsystems,
        "mercs2_module_names": mercs2_modules,
        "lua_function_strings": sorted(search_strings),
    }


# ---------------------------------------------------------------------------
# Phase 3: RTTI patterns from Mercs 1 class names
# ---------------------------------------------------------------------------

def build_rtti_patterns(class_names: dict[str, dict]) -> list[dict]:
    """Build MSVC RTTI search patterns from Mercs 1 class declarations."""
    patterns = []

    for cname, info in sorted(class_names.items()):
        # MSVC RTTI type descriptor format: .?AVClassName@@
        rtti_str = ".?AV%s@@" % cname
        patterns.append({
            "class_name": cname,
            "rtti_string": rtti_str,
            "parent_class": info.get("parent", ""),
            "source_file": info.get("file", ""),
            "mercs2_likely": cname.startswith(("Red", "Rs", "Pbl")),
        })

    # Common Pandemic engine class prefixes to look for in Mercs 2
    pandemic_prefixes = [
        "Red", "Rs", "Pbl", "Pmc",
        "Lua", "Havok", "Hk",
        "UCFX", "FFCS", "SGES",
    ]

    return patterns


# ---------------------------------------------------------------------------
# Phase 4: Compile everything
# ---------------------------------------------------------------------------

def build_annotation_database(source_files: list[Path]) -> dict[str, Any]:
    """Build the complete annotation database."""
    print(f"Scanning {len(source_files)} source files...")

    extracted = extract_strings_from_source(source_files)
    lua_patterns = build_lua_search_patterns(extracted["lua_reg_entries"])
    rtti_patterns = build_rtti_patterns(extracted["class_names"])

    # High-value strings: strings likely to survive into Mercs 2 binary
    # (class names, subsystem names, format strings, error messages)
    high_value_strings = set()

    # Lua function names are very likely to be in .rdata
    for entry in extracted["lua_reg_entries"]:
        high_value_strings.add(entry["lua_name"])

    # Class names (for RTTI matching)
    for cname in extracted["class_names"]:
        high_value_strings.add(cname)
        high_value_strings.add(".?AV%s@@" % cname)

    # Error/debug strings with engine-specific content
    for s in extracted["error_messages"]:
        if len(s) >= 8:
            high_value_strings.add(s)

    # Format strings from debug output
    for s in extracted["debug_strings"]:
        if "%" in s and len(s) >= 6:
            high_value_strings.add(s)

    stats = {
        "source_files_scanned": len(source_files),
        "debug_strings_found": len(extracted["debug_strings"]),
        "class_names_found": len(extracted["class_names"]),
        "lua_reg_entries_found": len(extracted["lua_reg_entries"]),
        "total_string_literals": len(extracted["all_string_literals"]),
        "error_messages_found": len(extracted["error_messages"]),
        "high_value_strings": len(high_value_strings),
        "rtti_patterns": len(rtti_patterns),
    }

    return {
        "metadata": {
            "generator": "ghidra_mercs2_preanalysis.py",
            "target": "Mercenaries 2: World in Flames (PC, 53482288 bytes)",
            "source": "Mercenaries 1 engine source code",
            "sections": {
                "rdata": {"start": RDATA_START, "end": RDATA_END,
                          "start_hex": hex(RDATA_START), "end_hex": hex(RDATA_END)},
                "text": {"start": TEXT_START, "end": TEXT_END,
                         "start_hex": hex(TEXT_START), "end_hex": hex(TEXT_END)},
            },
        },
        "stats": stats,
        "known_vas": KNOWN_VAS,
        "lua_registrations": {
            "mercs1_entries": extracted["lua_reg_entries"],
            "search_patterns": lua_patterns,
        },
        "rtti_patterns": rtti_patterns,
        "string_database": {
            "debug_strings": extracted["debug_strings"],
            "error_messages": list(extracted["error_messages"]),
            "high_value_strings": sorted(high_value_strings),
        },
        "class_hierarchy": extracted["class_names"],
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Pre-analyze Mercs 1 source code for Ghidra annotation of Mercs 2 binary",
    )
    parser.add_argument(
        "--output", "-o",
        default=str(REPO_ROOT / "scripts" / "mercs2_annotations.json"),
        help="Output JSON path (default: scripts/mercs2_annotations.json)",
    )
    parser.add_argument(
        "--source-dirs",
        nargs="*",
        help="Override source directories to scan (default: RedEngine + RetroStrike + Pebble + Lua)",
    )
    parser.add_argument(
        "--pretty", action="store_true", default=True,
        help="Pretty-print JSON output (default: true)",
    )
    args = parser.parse_args()

    src_dirs = [Path(d) for d in args.source_dirs] if args.source_dirs else MERCS1_SOURCE_DIRS

    existing = [d for d in src_dirs if d.exists()]
    if not existing:
        print("ERROR: No source directories found. Expected paths:")
        for d in src_dirs:
            print(f"  {d}")
        print("\nEnsure game-files/first-game-source-code-with-engine/ is populated.")
        sys.exit(1)

    missing = [d for d in src_dirs if not d.exists()]
    if missing:
        print("WARNING: Some source directories not found:")
        for d in missing:
            print(f"  {d}")

    source_files = find_source_files(existing)
    if not source_files:
        print("ERROR: No source files found in the specified directories.")
        sys.exit(1)

    db = build_annotation_database(source_files)

    out_path = Path(args.output)
    out_path.parent.mkdir(parents=True, exist_ok=True)

    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(db, f, indent=2 if args.pretty else None, ensure_ascii=False)

    print(f"\nAnnotation database written to: {out_path}")
    print(f"  Source files scanned: {db['stats']['source_files_scanned']}")
    print(f"  Debug strings:       {db['stats']['debug_strings_found']}")
    print(f"  Class names:         {db['stats']['class_names_found']}")
    print(f"  Lua registrations:   {db['stats']['lua_reg_entries_found']}")
    print(f"  RTTI patterns:       {db['stats']['rtti_patterns']}")
    print(f"  High-value strings:  {db['stats']['high_value_strings']}")


if __name__ == "__main__":
    main()
