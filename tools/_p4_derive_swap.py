#!/usr/bin/env python3
"""Phase 4: derive the correct schm field-`offset` conversion from BE source.

probe_schm_fields.py --be reports V_be = the offset word read as a big-endian u32,
i.e. V_be's 4 bytes in file order are [b0,b1,b2,b3] = BE bytes on disk.

Candidate conversions (file-byte transforms), expressed on V_be:
  full_u32_swap (CURRENT/BUGGY): bytes -> [b3,b2,b1,b0]
  swap_first_u16 (HYPOTHESIS) : bytes -> [b1,b0,b2,b3]  (swap byte_offset u16, keep aux)
  swap_both_u16               : bytes -> [b1,b0,b3,b2]  (swap each u16 half in place)

We compare each candidate's resulting LE u32 to retail's LE offset for the same
(component, name_hash), to find which conversion reproduces retail.
"""
from __future__ import annotations
import json
import sys
from pathlib import Path


def le_from_be_bytes(v_be: int, perm: tuple[int, int, int, int]) -> int:
    b = [(v_be >> 24) & 0xFF, (v_be >> 16) & 0xFF, (v_be >> 8) & 0xFF, v_be & 0xFF]
    out = [b[perm[0]], b[perm[1]], b[perm[2]], b[perm[3]]]
    # interpret resulting file bytes as little-endian u32
    return out[0] | (out[1] << 8) | (out[2] << 16) | (out[3] << 24)


CANDS = {
    "full_u32_swap": (3, 2, 1, 0),
    "swap_first_u16": (1, 0, 2, 3),
    "swap_both_u16": (1, 0, 3, 2),
    "identity": (0, 1, 2, 3),
}


def index_by_comp(doc: dict) -> dict[str, dict[int, int]]:
    out: dict[str, dict[int, int]] = {}
    for g in doc.get("comp_groups", []):
        name = g.get("component_name") or "?"
        schm = g.get("schm") or {}
        fields = {}
        for f in schm.get("fields", []):
            nh = f["name_hash"]
            if isinstance(nh, str):
                nh = int(nh, 16)
            fields[nh] = f["field_offset"]
        out[name] = fields
    return out


def main() -> int:
    be = index_by_comp(json.loads(Path(sys.argv[1]).read_text()))   # probe --be on BE dump
    retail = index_by_comp(json.loads(Path(sys.argv[2]).read_text()))
    shared = sorted(set(be) & set(retail))
    results = {k: [0, 0] for k in CANDS}  # name -> [match, total]
    mism: dict[str, list[str]] = {k: [] for k in CANDS}
    for comp in shared:
        for nh, vbe in be[comp].items():
            if nh not in retail[comp]:
                continue
            tgt = retail[comp][nh]
            for name, perm in CANDS.items():
                got = le_from_be_bytes(vbe, perm)
                results[name][1] += 1
                if got == tgt:
                    results[name][0] += 1
                elif len(mism[name]) < 6:
                    mism[name].append(
                        f"    {comp} nh=0x{nh:08x}: V_be=0x{vbe:08x} got=0x{got:08x} retail=0x{tgt:08x}")
    print(f"shared components: {shared}")
    for name in CANDS:
        m, t = results[name]
        print(f"  {name:16s}: {m}/{t} match")
        if m != t and name in ("swap_first_u16", "swap_both_u16"):
            print("\n".join(mism[name]))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
