#!/usr/bin/env python3
"""Compare mercs2_probe.asi runtime JSON against documented expectations.

Reads probe output from a game run (scripts/probe_results/) and flags
discrepancies vs hardcoded VAs in tools/dlc_enable_asi/dlc_enable.c,
tools/verify_lua_vas.py, and placement_data_format.md.

Usage:
  .venv/bin/python3 tools/validate_probe_results.py --probe-dir ./probe_results
  make validate-probe-results PROBE_DIR=./probe_results
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]

# Documented ground truth (cracked EXE 53,482,288 bytes)
EXPECTED_EXE_SIZE = 53_482_288
DOCUMENTED_LUA_VAS = {
    "luaL_loadbuffer": 0x00860240,
    "lua_pcall": 0x0085DF50,
    "luaL_typerror": 0x0085F050,
    "luaD_pcall": 0x00868AD0,
    "luaB_loadstring": 0x00860FC0,
    "luaB_pcall": 0x008615F0,
    "print_stub": 0x006D5640,
}

DOCUMENTED_LUA_STATE_OFFSETS = {
    "top": 8,
    "base": 12,
    "l_G": 16,
    "ci": 20,
    "stack_last": 28,
    "stack": 32,
}

DOCUMENTED_SECTIONS = {
    ".text": (0x00401000, 0x00703000),
    ".rdata": (0x00B05000, 0x000F1000),
    ".data": (0x00BF6000, 0x00DA4000),
}

DOCUMENTED_PLACEMENT = {
    "record_bytes": 42,
    "x": 0,
    "y": 4,
    "z": 8,
    "qx": 20,
    "qy": 24,
    "qz": 28,
    "qw": 32,
}

TSTRING_DATA_OFFSET = 16
TVALUE_SIZE = 8


@dataclass
class Finding:
    severity: str  # ok, warn, error
    category: str
    message: str
    doc_ref: str = ""


def parse_va(s: str | int | None) -> int | None:
    if s is None:
        return None
    if isinstance(s, int):
        return s
    m = re.match(r"0x([0-9A-Fa-f]+)", str(s).strip())
    if m:
        return int(m.group(1), 16)
    return None


def load_json(path: Path) -> dict | list | None:
    if not path.is_file():
        return None
    try:
        with path.open(encoding="utf-8") as f:
            return json.load(f)
    except json.JSONDecodeError as e:
        print(f"ERROR: {path}: invalid JSON: {e}", file=sys.stderr)
        return None


def validate_lua_api_signatures(data: dict | None) -> list[Finding]:
    findings: list[Finding] = []
    if not data:
        findings.append(
            Finding("error", "lua_api_signatures", "missing lua_api_signatures.json")
        )
        return findings

    funcs = {f.get("name"): f for f in data.get("functions", []) if isinstance(f, dict)}
    for name, expected_va in DOCUMENTED_LUA_VAS.items():
        entry = funcs.get(name)
        if not entry:
            findings.append(
                Finding(
                    "warn",
                    "lua_api_signatures",
                    f"{name} not present in probe output",
                    "tools/verify_lua_vas.py",
                )
            )
            continue
        probe_va = parse_va(entry.get("va"))
        if probe_va != expected_va:
            findings.append(
                Finding(
                    "error",
                    "lua_api_signatures",
                    f"{name}: probe documents 0x{probe_va:08X}, expected 0x{expected_va:08X}",
                    "tools/dlc_enable_asi/dlc_enable.c",
                )
            )
        else:
            prologue = entry.get("prologue_hex", "")
            if not prologue or prologue.startswith("00000000"):
                findings.append(
                    Finding(
                        "warn",
                        "lua_api_signatures",
                        f"{name}: prologue unreadable or all zeros at 0x{expected_va:08X}",
                    )
                )
            else:
                findings.append(
                    Finding(
                        "ok",
                        "lua_api_signatures",
                        f"{name} @ 0x{expected_va:08X} prologue captured",
                    )
                )

        call_sites = entry.get("call_sites", [])
        if not call_sites:
            findings.append(
                Finding(
                    "warn",
                    "lua_api_signatures",
                    f"{name}: no E8 call sites found in .text scan",
                )
            )

    ltcg = data.get("documented_ltcg", {})
    if not ltcg:
        findings.append(
            Finding("warn", "lua_api_signatures", "documented_ltcg block missing from probe")
        )
    return findings


def validate_lua_state_layout(data: dict | None) -> list[Finding]:
    findings: list[Finding] = []
    if not data:
        findings.append(
            Finding("warn", "lua_state_layout", "missing lua_state_layout.json (lua_State not captured?)")
        )
        return findings

    doc_offsets = data.get("documented_offsets", {})
    for key, expected in DOCUMENTED_LUA_STATE_OFFSETS.items():
        probe_off = doc_offsets.get(key)
        if probe_off is not None and probe_off != expected:
            findings.append(
                Finding(
                    "error",
                    "lua_state_layout",
                    f"documented_offsets.{key}: probe says {probe_off}, repo expects {expected}",
                    "tools/dlc_enable_asi/dlc_enable.c",
                )
            )

    stride = data.get("tvalue_stride_bytes", 0)
    if stride and stride != TVALUE_SIZE:
        findings.append(
            Finding(
                "error",
                "lua_state_layout",
                f"TValue stride {stride} != expected {TVALUE_SIZE}",
                "docs/lua_verification_methodology.md",
            )
        )
    elif stride == TVALUE_SIZE:
        findings.append(Finding("ok", "lua_state_layout", f"TValue stride = {TVALUE_SIZE} bytes"))

    tstring_probes = data.get("tstring_probes", [])
    if tstring_probes:
        offsets = {p.get("data_offset") for p in tstring_probes if isinstance(p, dict)}
        if TSTRING_DATA_OFFSET in offsets:
            findings.append(
                Finding(
                    "ok",
                    "lua_state_layout",
                    f"TString data offset {TSTRING_DATA_OFFSET} confirmed at runtime",
                )
            )
        elif offsets:
            findings.append(
                Finding(
                    "warn",
                    "lua_state_layout",
                    f"TString data offsets seen: {sorted(offsets)}; doc says +{TSTRING_DATA_OFFSET}",
                    "tools/dlc_enable_asi/dlc_enable.c",
                )
            )
    else:
        findings.append(
            Finding("warn", "lua_state_layout", "no TString probes (stack had no strings?)")
        )

    fields = data.get("fields", [])
    if fields and data.get("lua_state_va"):
        for name, off in DOCUMENTED_LUA_STATE_OFFSETS.items():
            match = next((f for f in fields if f.get("offset") == off), None)
            if match and match.get("readable"):
                ptr = parse_va(match.get("u32"))
                if ptr and ptr > 0x10000:
                    findings.append(
                        Finding(
                            "ok",
                            "lua_state_layout",
                            f"lua_State+{off:#x} ({name}) readable pointer 0x{ptr:08X}",
                        )
                    )
    return findings


def validate_lua_bindings_deep(data: dict | None) -> list[Finding]:
    findings: list[Finding] = []
    if not data:
        findings.append(Finding("warn", "lua_bindings_deep", "missing lua_bindings_deep.json"))
        return findings

    count = data.get("binding_count", 0)
    bindings = data.get("bindings", [])
    if count < 100:
        findings.append(
            Finding(
                "warn",
                "lua_bindings_deep",
                f"only {count} bindings — expected hundreds+",
                "docs/lua_engine_bindings_audit.md",
            )
        )
    else:
        findings.append(Finding("ok", "lua_bindings_deep", f"{count} bindings inventoried"))

    if not data.get("runtime_walk"):
        findings.append(
            Finding(
                "warn",
                "lua_bindings_deep",
                "runtime_walk=false — only static .rdata scan succeeded",
            )
        )

    # Spot-check known bindings exist
    paths = {b.get("path") for b in bindings if isinstance(b, dict)}
    for expected in ("Sys", "Object", "Player", "Net"):
        if not any(p == expected or (p and p.startswith(expected + ".")) for p in paths):
            findings.append(
                Finding(
                    "warn",
                    "lua_bindings_deep",
                    f"namespace '{expected}' not found in binding inventory",
                )
            )

    obj_gp = [b for b in bindings if isinstance(b, dict) and b.get("path", "").endswith("GetPosition")]
    if obj_gp:
        va = parse_va(obj_gp[0].get("func_va"))
        findings.append(
            Finding("ok", "lua_bindings_deep", f"Object.GetPosition @ 0x{va:08X}" if va else "Object.GetPosition found")
        )
    return findings


def validate_game_objects(data: dict | None) -> list[Finding]:
    findings: list[Finding] = []
    if not data:
        findings.append(Finding("warn", "game_objects", "missing game_objects.json"))
        return findings

    doc = data.get("documented_placement_offsets", {})
    for key, expected in DOCUMENTED_PLACEMENT.items():
        if key == "record_bytes":
            continue
        if doc.get(key) != expected:
            findings.append(
                Finding(
                    "error",
                    "game_objects",
                    f"placement offset {key}: probe doc {doc.get(key)} != expected {expected}",
                    "docs/placement_data_format.md",
                )
            )

    if data.get("record_bytes") == 42 or data.get("placement_record_bytes") == 42:
        findings.append(Finding("ok", "game_objects", "placement record size 42 bytes documented"))

    if not data.get("object_hook_fired"):
        findings.append(
            Finding(
                "warn",
                "game_objects",
                "Object.GetPosition hook never fired — play until in-world for userdata samples",
            )
        )
    elif data.get("sample_count", 0) > 0:
        findings.append(
            Finding(
                "ok",
                "game_objects",
                f"{data['sample_count']} userdata sample(s) captured",
            )
        )
    return findings


def validate_memory_map(data: dict | None) -> list[Finding]:
    findings: list[Finding] = []
    if not data:
        findings.append(Finding("error", "memory_map", "missing memory_map.json"))
        return findings

    if data.get("exe_size_expected") != EXPECTED_EXE_SIZE:
        findings.append(
            Finding(
                "warn",
                "memory_map",
                f"exe_size_expected {data.get('exe_size_expected')} != {EXPECTED_EXE_SIZE}",
            )
        )
    else:
        findings.append(Finding("ok", "memory_map", f"EXE size expectation {EXPECTED_EXE_SIZE}"))

    sections = data.get("sections_documented", {})
    for name, (start, size) in DOCUMENTED_SECTIONS.items():
        sec = sections.get(name, {})
        ps = parse_va(sec.get("start"))
        if ps != start:
            findings.append(
                Finding(
                    "error",
                    "memory_map",
                    f"section {name} start: probe {sec} vs doc 0x{start:08X}",
                    "tools/mercs2_probe/mercs2_probe.c",
                )
            )
        else:
            findings.append(Finding("ok", "memory_map", f"{name} @ 0x{start:08X}"))

    modules = data.get("modules", [])
    if not modules:
        findings.append(Finding("warn", "memory_map", "no loaded modules enumerated"))
    else:
        main = modules[0] if modules else {}
        findings.append(
            Finding("ok", "memory_map", f"{len(modules)} modules loaded (main base {main.get('base')})")
        )
    return findings


def print_report(findings: list[Finding]) -> int:
    by_sev: dict[str, list[Finding]] = {"error": [], "warn": [], "ok": []}
    for f in findings:
        by_sev.setdefault(f.severity, []).append(f)

    print("=== mercs2_probe validation report ===\n")
    for sev in ("error", "warn", "ok"):
        items = by_sev.get(sev, [])
        if not items:
            continue
        print(f"--- {sev.upper()} ({len(items)}) ---")
        for f in items:
            ref = f" [{f.doc_ref}]" if f.doc_ref else ""
            print(f"  [{f.category}] {f.message}{ref}")
        print()

    errors = len(by_sev.get("error", []))
    warns = len(by_sev.get("warn", []))
    print(f"Summary: {errors} error(s), {warns} warning(s), {len(by_sev.get('ok', []))} ok")
    return 1 if errors else 0


def main() -> int:
    ap = argparse.ArgumentParser(description="Validate mercs2_probe JSON against repo docs")
    ap.add_argument(
        "--probe-dir",
        type=Path,
        required=True,
        help="Directory containing probe_results JSON files",
    )
    args = ap.parse_args()
    probe_dir = args.probe_dir.resolve()

    if not probe_dir.is_dir():
        print(f"ERROR: probe directory not found: {probe_dir}", file=sys.stderr)
        return 2

    files = {
        "lua_api_signatures": probe_dir / "lua_api_signatures.json",
        "lua_state_layout": probe_dir / "lua_state_layout.json",
        "lua_bindings_deep": probe_dir / "lua_bindings_deep.json",
        "game_objects": probe_dir / "game_objects.json",
        "memory_map": probe_dir / "memory_map.json",
    }

    findings: list[Finding] = []
    findings.extend(validate_lua_api_signatures(load_json(files["lua_api_signatures"])))  # type: ignore[arg-type]
    findings.extend(validate_lua_state_layout(load_json(files["lua_state_layout"])))  # type: ignore[arg-type]
    findings.extend(validate_lua_bindings_deep(load_json(files["lua_bindings_deep"])))  # type: ignore[arg-type]
    findings.extend(validate_game_objects(load_json(files["game_objects"])))  # type: ignore[arg-type]
    findings.extend(validate_memory_map(load_json(files["memory_map"])))  # type: ignore[arg-type]

    return print_report(findings)


if __name__ == "__main__":
    sys.exit(main())
