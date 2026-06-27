#!/usr/bin/env python3
"""Pair the recovered Xbox-binary symbol evidence with the PC-retail Ghidra decomp.

Two bridges between the (symbol-rich) Xbox Profile build and the (logic-rich, mostly
anonymous) PC retail decompilation:

  1. VTABLE bridge — Ghidra labels recovered RTTI vtables as ``Class::vftable``. A
     function that assigns ``Class::vftable`` to a pointer is Class's constructor /
     vtable-setter. This directly names ~hundreds of PC functions (Havok keeps RTTI
     even in release, so Ghidra already recovered the names).
  2. STRING bridge — both builds embed the same debug/format/state strings. Ghidra
     inlines them as ``s_<sanitized>_<addr>``. A PC function referencing the same
     string that names a system in the Xbox build can be attributed.

Outputs (output/jul08_prototype/pairing/):
  - vtable_map.json     : Class -> [FUN_ addrs that set its vftable]
  - string_func_map.json: ghidra s_ token -> [FUN_ addrs that reference it]
  - functions.json      : FUN_addr -> {line, signature}
  - resolved_<system>.txt per inventory system (classes+strings -> FUN_ addrs)
"""
from __future__ import annotations
import json, re
from pathlib import Path
from collections import defaultdict

ROOT = Path(__file__).resolve().parent.parent
DECOMP = ROOT / "output/_ghidra/all_functions_decomp.txt"
INV = ROOT / "output/jul08_prototype/inventory"
RTTI = ROOT / "output/jul08_prototype/mercs2_xenon_p.rtti_classes.txt"
OUT = ROOT / "output/jul08_prototype/pairing"

FUN_HDR = re.compile(r'\b((?:thunk_)?FUN_[0-9a-f]{8}|[A-Za-z_][\w]*(?:::~?[\w]+)+)\s*\(')
VFT = re.compile(r'([A-Za-z_][\w:]*?)::vftable')
STR = re.compile(r's_([A-Za-z0-9_]+)_[0-9a-f]{6,8}')


def parse():
    funcs = {}                       # addr/name -> {line}
    vtable_map = defaultdict(set)    # class -> {func}
    str_map = defaultdict(set)       # token -> {func}
    cur = None
    for ln, line in enumerate(DECOMP.open(encoding="utf-8", errors="replace"), 1):
        # detect a function header at line start (return-type ... NAME( )
        if line and not line[0].isspace():
            m = FUN_HDR.search(line)
            if m and ('FUN_' in m.group(1) or '::' in m.group(1)):
                cur = m.group(1)
                funcs.setdefault(cur, {"line": ln, "sig": line.strip()[:160]})
        if cur is None:
            continue
        for vm in VFT.finditer(line):
            vtable_map[vm.group(1)].add(cur)
        for sm in STR.finditer(line):
            str_map[sm.group(1)].add(cur)
    return funcs, vtable_map, str_map


def demangle(r):
    m = re.match(r'\.\?A[UV](?:\?\$)?([A-Za-z_]\w+)@', r)
    return m.group(1) if m else None


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print("parsing decomp (37 MB)...", flush=True)
    funcs, vtable_map, str_map = parse()
    print(f"  functions={len(funcs)}  vtable-classes={len(vtable_map)}  string-tokens={len(str_map)}")
    (OUT/"vtable_map.json").write_text(json.dumps({k: sorted(v) for k, v in vtable_map.items()}, indent=0))
    (OUT/"string_func_map.json").write_text(json.dumps({k: sorted(v) for k, v in str_map.items()}, indent=0))
    (OUT/"functions.json").write_text(json.dumps(funcs, indent=0))

    # Xbox RTTI classes -> PC vtable constructors
    rtti = set(filter(None, (demangle(l.strip()) for l in RTTI.read_text(errors="replace").splitlines() if l.strip())))
    rtti_hits = {c: sorted(vtable_map[c]) for c in rtti if c in vtable_map}
    print(f"\nXbox RTTI classes resolved to PC vtable-setters: {len(rtti_hits)}/{len(rtti)}")

    # per-system resolution
    summary = {}
    for invf in sorted(INV.glob("*.txt")):
        sysname = invf.stem
        if sysname.startswith("_"):
            continue
        syms = []
        for line in invf.read_text(errors="replace").splitlines():
            parts = line.split(None, 2)
            if len(parts) == 3:
                syms.append(parts[2])
        resolved_vt = {}
        resolved_str = {}
        for s in syms:
            # vtable match (symbol is a class name)
            base = s.split('::')[0]
            if base in vtable_map:
                resolved_vt[s] = sorted(vtable_map[base])
            # string match: sanitize like ghidra (keep alnum/underscore prefix)
            tok = re.sub(r'[^A-Za-z0-9_]', '_', s)
            if tok in str_map:
                resolved_str[s] = sorted(str_map[tok])
        lines = ["# vtable-resolved (symbol -> PC constructor/vtable-setter funcs)"]
        for s, fs in sorted(resolved_vt.items()):
            lines.append(f"{s}\t{', '.join(fs[:6])}")
        lines.append("\n# string-anchored (symbol -> PC funcs referencing the same string)")
        for s, fs in sorted(resolved_str.items()):
            lines.append(f"{s}\t{', '.join(fs[:6])}")
        (OUT/f"resolved_{sysname}.txt").write_text("\n".join(lines), encoding="utf-8")
        summary[sysname] = {"symbols": len(syms), "vtable_resolved": len(resolved_vt), "string_resolved": len(resolved_str)}

    (OUT/"summary.json").write_text(json.dumps(summary, indent=2))
    print(f"\n{'system':22} syms  vtable  string")
    for s, d in sorted(summary.items(), key=lambda x: -(x[1]['vtable_resolved']+x[1]['string_resolved'])):
        print(f"  {s:22} {d['symbols']:4}  {d['vtable_resolved']:5}  {d['string_resolved']:5}")


if __name__ == "__main__":
    main()
