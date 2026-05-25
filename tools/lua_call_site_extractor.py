#!/usr/bin/env python3
"""Extract engine Lua binding call sites from luac -l -l disassembly listings.

Reads per-script ``*.disasm.txt`` files (from ``tools/extract_all_scripts.py``) and
recovers ``Namespace.Function`` calls where Namespace is a known engine table
(Sys, Net, Object, …) via the GETGLOBAL → GETTABLE → CALL pattern.

Outputs:
  - ``output/lua_call_sites.json`` — machine-readable index
  - ``docs/lua_call_sites_from_scripts.md`` — human summary table

Does not invent call sites; only reports patterns visible in disassembly.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from collections import defaultdict
from dataclasses import dataclass, field
from pathlib import Path

# Engine namespaces from docs/lua_engine_bindings_audit.md §2 (+ common aliases)
ENGINE_NAMESPACES = frozenset({
    "_SYS",
    "Sys",
    "Net",
    "NetClient",
    "Object",
    "Player",
    "Gui",
    "Ai",
    "Atmosphere",
    "Graphics",
    "Sound",
    "VO",
    "Weapon",
    "Event",
    "Debug",
    "Boundary",
    "Save",
    "Localization",
    "Lobby",
    "Vehicle",
    "Hud",
    "Pg",
    "Faction",
    "Pursuit",
    "Precache",
    "DLC",
    "Online",
    "Marker",
    "Music",
    "LTI",
})

RE_FUNC_HEADER = re.compile(
    r"^function\s+<([^>]+)>\s*\((\d+)\s+params",
)
RE_INSTR = re.compile(
    r"^\s*(\d+)\s+\[(\d+)\]\s+(\w+)\s+(.+)$"
)
RE_SEMI_NAME = re.compile(r';\s*"?([^";]+)"?\s*$')
RE_GETTABLE_FIELD = re.compile(r';\s*"([^"]+)"\s*$')

# Lua 5.1 CALL A B C: nargs = B-1 when B>0; B==0 means variable args (unknown)
RE_CALL = re.compile(r"^(\d+)\s+(\d+)\s+(\d+)$")


@dataclass
class PendingTable:
    namespace: str
    reg: int


@dataclass
class CallSite:
    namespace: str
    function: str
    script: str
    source_line: int | None
    arity: int | None  # fixed arg count, or None if variable/unknown
    call_b: int
    call_c: int
    arg_hints: list[str] = field(default_factory=list)
    snippet_lines: list[str] = field(default_factory=list)


def _field_name(operand_tail: str) -> str | None:
    m = RE_GETTABLE_FIELD.search(operand_tail)
    if m:
        return m.group(1)
    m = RE_SEMI_NAME.search(operand_tail)
    if m:
        name = m.group(1).strip()
        if name.startswith('"') and name.endswith('"'):
            return name[1:-1]
        return name
    return None


def _parse_operands(tail: str) -> list[str]:
    parts = tail.split("\t")[0].strip().split()
    return parts


def _arg_hint_from_instr(op: str, tail: str) -> str | None:
    op = op.upper()
    if op == "LOADK":
        m = RE_GETTABLE_FIELD.search(tail)
        if m:
            return f"string:{m.group(1)!r}"
        m = RE_SEMI_NAME.search(tail)
        if m:
            return f"string:{m.group(1)!r}"
    if op in ("LOADNIL",):
        return "nil"
    if op in ("LOADBOOL",):
        return "bool"
    if op in ("LOADK",) and ";" not in tail:
        return "const"
    if op in ("GETGLOBAL", "GETTABLE", "SELF", "NEWTABLE"):
        name = _field_name(tail)
        if name:
            return f"{op.lower()}:{name}"
    if op == "MOVE":
        return "reg"
    return None


def extract_from_disasm(path: Path, script_name: str) -> tuple[list[CallSite], list[str]]:
    """Parse one disasm file; return call sites and parse warnings."""
    text = path.read_text(encoding="utf-8", errors="replace")
    lines = text.splitlines()
    warnings: list[str] = []
    sites: list[CallSite] = []

    pending_table: dict[int, PendingTable] = {}
    pending_func: dict[int, tuple[str, str, int | None]] = {}  # reg -> (ns, func, src_line)
    recent_lines: list[str] = []

    def flush_recent() -> None:
        nonlocal recent_lines
        recent_lines = recent_lines[-12:]

    for raw in lines:
        m_hdr = RE_FUNC_HEADER.match(raw.strip())
        if m_hdr:
            pending_table.clear()
            pending_func.clear()
            recent_lines = []
            continue

        m = RE_INSTR.match(raw)
        if not m:
            continue

        _pc, src_line_s, op, tail = m.groups()
        src_line = int(src_line_s)
        op_u = op.upper()
        operands = _parse_operands(tail)
        recent_lines.append(raw.rstrip())
        flush_recent()

        if op_u == "GETGLOBAL" and len(operands) >= 1:
            reg = int(operands[0])
            name = _field_name(tail)
            if name and name in ENGINE_NAMESPACES:
                pending_table[reg] = PendingTable(namespace=name, reg=reg)
                pending_func.pop(reg, None)
            else:
                pending_table.pop(reg, None)
            continue

        if op_u == "GETTABLE" and len(operands) >= 3:
            dest = int(operands[0])
            base = int(operands[1])
            func_name = _field_name(tail)
            if func_name and base in pending_table:
                ns = pending_table[base].namespace
                pending_func[dest] = (ns, func_name, src_line)
            continue

        if op_u == "CALL" and len(operands) >= 3:
            base = int(operands[0])
            b_val = int(operands[1])
            c_val = int(operands[2])
            if base not in pending_func:
                continue
            ns, func_name, fn_line = pending_func[base]
            if b_val == 0:
                arity: int | None = None
            else:
                arity = max(0, b_val - 1)

            # Collect arg hints from instructions since GETTABLE (same function block)
            arg_hints: list[str] = []
            for ln in recent_lines:
                im = RE_INSTR.match(ln)
                if not im:
                    continue
                iop = im.group(3).upper()
                ihint = _arg_hint_from_instr(iop, im.group(4))
                if ihint and iop not in ("GETGLOBAL", "GETTABLE", "CALL"):
                    arg_hints.append(ihint)

            sites.append(
                CallSite(
                    namespace=ns,
                    function=func_name,
                    script=script_name,
                    source_line=fn_line,
                    arity=arity,
                    call_b=b_val,
                    call_c=c_val,
                    arg_hints=arg_hints[-8:],
                    snippet_lines=list(recent_lines[-6:]),
                )
            )
            continue

        # Other ops may clobber registers; drop stale pending func on reassignment
        if op_u in ("SETGLOBAL", "LOADK", "GETGLOBAL") and len(operands) >= 1:
            reg = int(operands[0])
            if op_u != "GETGLOBAL":
                pending_func.pop(reg, None)

    return sites, warnings


def aggregate(sites: list[CallSite]) -> dict:
    by_key: dict[str, dict] = {}
    for s in sites:
        key = f"{s.namespace}.{s.function}"
        if key not in by_key:
            by_key[key] = {
                "namespace": s.namespace,
                "function": s.function,
                "qualified": key,
                "scripts": set(),
                "arity_counts": defaultdict(int),
                "arg_hint_samples": [],
                "snippets": [],
            }
        rec = by_key[key]
        rec["scripts"].add(s.script)
        if s.arity is not None:
            rec["arity_counts"][str(s.arity)] += 1
        else:
            rec["arity_counts"]["var/unknown"] += 1
        if s.arg_hints and len(rec["arg_hint_samples"]) < 5:
            rec["arg_hint_samples"].append(
                {"script": s.script, "line": s.source_line, "hints": s.arg_hints}
            )
        if len(rec["snippets"]) < 3:
            rec["snippets"].append(
                {
                    "script": s.script,
                    "line": s.source_line,
                    "disasm": s.snippet_lines,
                }
            )

    entries = []
    for key in sorted(by_key.keys()):
        rec = by_key[key]
        arities = rec["arity_counts"]
        arity_hint = ", ".join(f"{k}×{v}" for k, v in sorted(arities.items(), key=lambda x: -x[1]))
        entries.append(
            {
                "qualified": key,
                "namespace": rec["namespace"],
                "function": rec["function"],
                "scripts": sorted(rec["scripts"]),
                "script_count": len(rec["scripts"]),
                "arity_hint": arity_hint,
                "arg_hint_samples": rec["arg_hint_samples"],
                "example_snippets": rec["snippets"],
            }
        )
    entries.sort(key=lambda e: (-e["script_count"], e["qualified"]))
    return {"bindings": entries, "total_call_sites": len(sites), "unique_bindings": len(entries)}


def load_audit_bindings(audit_path: Path) -> set[str]:
    """Scrape binding names from ``lua_engine_bindings_audit.md``."""
    if not audit_path.is_file():
        return set()
    found: set[str] = set()
    current_ns: str | None = None
    section_ns = re.compile(
        r"^###\s+[\d.]+\s+.*[`']?(" + "|".join(sorted(ENGINE_NAMESPACES)) + r")[`']?",
        re.I,
    )
    for line in audit_path.read_text(encoding="utf-8", errors="replace").splitlines():
        m_sec = section_ns.search(line)
        if m_sec:
            current_ns = m_sec.group(1)
            continue
        if line.startswith("### "):
            current_ns = None

        # `Sys.LoadLayer` / `UnloadLayer` or `Player.GetCash` / `SetCash`
        for chunk in re.findall(r"`([^`]+)`", line):
            if "." in chunk:
                ns, rest = chunk.split(".", 1)
                if ns in ENGINE_NAMESPACES:
                    for part in re.split(r"\s*/\s*", rest):
                        part = part.strip()
                        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", part):
                            found.add(f"{ns}.{part}")
            elif current_ns and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", chunk):
                found.add(f"{current_ns}.{chunk}")

        # Table rows: | RequestGameState | or | `Event.Create` |
        if line.startswith("|") and not line.startswith("|--"):
            cells = [c.strip() for c in line.split("|")[1:-1]]
            if not cells:
                continue
            cell0 = cells[0].strip("`")
            if "." in cell0:
                ns, fn = cell0.split(".", 1)
                if ns in ENGINE_NAMESPACES:
                    for part in re.split(r"\s*/\s*", fn):
                        part = part.strip()
                        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", part):
                            found.add(f"{ns}.{part}")
            elif current_ns and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", cell0):
                found.add(f"{current_ns}.{cell0}")
    return found


def _top_signature_discoveries(
    bindings: list[dict], audit_known: set[str], limit: int = 10
) -> list[dict]:
    """Rank bindings by script evidence; prefer names absent from audit scrape."""
    core = {
        "Sys", "Net", "Object", "Player", "Atmosphere", "Gui", "Sound", "VO",
        "Ai", "Weapon", "Event", "Debug", "Boundary", "Save", "Vehicle", "Hud",
        "NetClient", "_SYS", "Graphics",
    }
    scored: list[tuple[int, dict]] = []
    for e in bindings:
        if e["namespace"] not in core:
            continue
        bonus = 500 if e["qualified"] not in audit_known else 0
        scored.append((bonus + e["script_count"], e))
    scored.sort(key=lambda x: -x[0])
    return [e for _, e in scored[:limit]]


def write_markdown(
    path: Path,
    agg: dict,
    meta: dict,
    audit_known: set[str],
    failures: list[dict],
    script_names: list[str],
) -> None:
    lines = [
        "# Lua engine call sites from `scripts_vz`",
        "",
        f"> Generated by `tools/lua_call_site_extractor.py`",
        f"> Source block: `{meta['source_block']}`",
        f"> Scripts processed: **{meta['scripts_processed']}** (disasm OK: {meta['disasm_ok']}, failed: {meta['disasm_failed']})",
        f"> Unique engine binding call patterns: **{agg['unique_bindings']}** ({agg['total_call_sites']} total call sites in disasm)",
        "",
        "Evidence: `GETGLOBAL` → `GETTABLE` → `CALL` in `luac -l -l` listings (Mercenaries 2 Lua 5.1 float).",
        "Does not include Mrx*/Wif* framework calls or colon-syntax method calls unless they use engine tables.",
        "",
        "## Failures",
        "",
    ]
    if failures:
        lines.append("| Script | Reason |")
        lines.append("|--------|--------|")
        for f in failures:
            lines.append(f"| {f.get('name', '?')} | {f.get('reason', '?')} |")
    else:
        lines.append("None — all scripts disassembled successfully.")
    lines.extend(
        [
            "",
            "## Source decompile (unluac / luadec)",
            "",
            "**0 / 114** — Java runtime not installed; `tools/unluac.jar` not present. "
            "Use `output/lua_decompile/*.disasm.txt` as evidence. See "
            "`output/lua_decompile/DECOMPILE_STATUS.md`.",
            "",
            "## Top signature discoveries (vs audit)",
            "",
            "Call-site arity/literal hints from bytecode; names may exist in EXE audit without script-level signatures.",
            "",
        ]
    )
    for i, e in enumerate(_top_signature_discoveries(agg["bindings"], audit_known), 1):
        in_audit = "in audit" if e["qualified"] in audit_known else "**new name**"
        samples = e.get("arg_hint_samples", [])
        hint_txt = ""
        if samples:
            hints = samples[0].get("hints", [])
            hint_txt = ", ".join(hints[:5])
        lines.append(
            f"{i}. **`{e['qualified']}`** ({e['script_count']} scripts, {in_audit}) — "
            f"arity: {e['arity_hint']}"
            + (f"; args: {hint_txt}" if hint_txt else "")
        )
    lines.extend(["", "## Script inventory", ""])
    lines.append(f"{len(script_names)} scripts: " + ", ".join(f"`{n}`" for n in script_names))
    lines.extend(["", "## Binding call table", ""])
    lines.append(
        "| Binding | Scripts | Arity (disasm) | Example |"
    )
    lines.append("|---------|---------|----------------|---------|")
    for e in agg["bindings"]:
        scripts = ", ".join(e["scripts"][:6])
        if len(e["scripts"]) > 6:
            scripts += f" (+{len(e['scripts']) - 6} more)"
        snippet = ""
        if e["example_snippets"]:
            sn = e["example_snippets"][0]["disasm"]
            snippet = " → ".join(
                ln.strip().split("\t")[-1] if "\t" in ln else ln.strip()
                for ln in sn[-3:]
            )[:120]
        lines.append(
            f"| `{e['qualified']}` | {e['script_count']}: {scripts} | {e['arity_hint']} | {snippet} |"
        )

    new_bindings = [
        e["qualified"]
        for e in agg["bindings"]
        if e["qualified"] not in audit_known
    ]
    lines.extend(["", "## New vs `lua_engine_bindings_audit.md`", ""])
    if new_bindings:
        lines.append(
            f"**{len(new_bindings)}** call-site bindings not found in audit scrape "
            f"(may still be documented under different naming):"
        )
        for q in new_bindings[:80]:
            lines.append(f"- `{q}`")
        if len(new_bindings) > 80:
            lines.append(f"- … and {len(new_bindings) - 80} more")
    else:
        lines.append("All recovered bindings appear in the audit doc scrape.")

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description="Extract engine Lua call sites from disasm")
    ap.add_argument(
        "--disasm-dir",
        type=Path,
        default=Path("output/lua_decompile"),
        help="Directory with *.disasm.txt from extract_all_scripts.py",
    )
    ap.add_argument(
        "--json-out",
        type=Path,
        default=Path("output/lua_call_sites.json"),
    )
    ap.add_argument(
        "--md-out",
        type=Path,
        default=Path("docs/lua_call_sites_from_scripts.md"),
    )
    ap.add_argument(
        "--audit",
        type=Path,
        default=Path("docs/lua_engine_bindings_audit.md"),
    )
    ap.add_argument(
        "--source-block",
        type=Path,
        default=Path("output_demo/extracted/scripts_vz_demo.block.bin"),
    )
    ap.add_argument(
        "--failures-json",
        type=Path,
        default=None,
        help="full_analysis.json or api_catalog with failed[]",
    )
    args = ap.parse_args()

    disasm_files = sorted(args.disasm_dir.glob("*.disasm.txt"))
    if not disasm_files:
        print(f"error: no *.disasm.txt in {args.disasm_dir}", file=sys.stderr)
        return 1

    script_names = sorted(p.stem.replace(".disasm", "") for p in disasm_files)

    failures: list[dict] = []
    if args.failures_json and args.failures_json.is_file():
        doc = json.loads(args.failures_json.read_text(encoding="utf-8"))
        failures = doc.get("failed", failures)

    all_sites: list[CallSite] = []
    per_script: dict[str, list[dict]] = {}

    for df in disasm_files:
        script = df.stem.replace(".disasm", "")
        sites, _warn = extract_from_disasm(df, script)
        all_sites.extend(sites)
        per_script[script] = [
            {
                "qualified": f"{s.namespace}.{s.function}",
                "namespace": s.namespace,
                "function": s.function,
                "source_line": s.source_line,
                "arity": s.arity,
                "arg_hints": s.arg_hints,
            }
            for s in sites
        ]

    agg = aggregate(all_sites)
    audit_known = load_audit_bindings(args.audit)

    new_vs_audit = [
        e["qualified"]
        for e in agg["bindings"]
        if e["qualified"] not in audit_known
    ]

    out_doc = {
        "meta": {
            "source_block": str(args.source_block),
            "disasm_dir": str(args.disasm_dir),
            "scripts_processed": len(disasm_files),
            "disasm_ok": len(disasm_files) - len(failures),
            "disasm_failed": len(failures),
            "decompile_ok": 0,
            "decompile_failed": len(disasm_files),
            "decompile_failure_reason": "unluac/luadec unavailable (no Java / tools/unluac.jar)",
            "script_names": script_names,
        },
        "failures": failures,
        "per_script": per_script,
        "aggregate": agg,
        "audit_crossref": {
            "audit_bindings_scraped": len(audit_known),
            "call_site_bindings_unique": agg["unique_bindings"],
            "not_in_audit_scrape": sorted(new_vs_audit),
        },
    }

    args.json_out.parent.mkdir(parents=True, exist_ok=True)
    args.json_out.write_text(json.dumps(out_doc, indent=2), encoding="utf-8")

    write_markdown(
        args.md_out,
        agg,
        out_doc["meta"],
        audit_known,
        failures,
        script_names,
    )

    print(f"Processed {len(disasm_files)} scripts")
    print(f"Engine call sites: {agg['total_call_sites']} ({agg['unique_bindings']} unique bindings)")
    print(f"JSON → {args.json_out}")
    print(f"Markdown → {args.md_out}")
    print(f"Not in audit scrape: {len(new_vs_audit)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
