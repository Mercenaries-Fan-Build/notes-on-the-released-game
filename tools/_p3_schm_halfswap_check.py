#!/usr/bin/env python3
"""Phase 3 verification: test whether converted-block schm field `offset` words
are the u16-half-swap of the retail (PC-native) encoding.

Model:
  retail (correct PC): raw32 = (aux:u16 << 16) | (byte_offset:u16)   [byte_offset in LOW half]
  block18 (our conv) : raw32 = (byte_offset:u16 << 16) | (aux:u16)   [halves swapped -> u32 swap bug]

For a field present in both blocks (matched by name_hash within the same component),
check: block18_raw == ((retail_raw & 0xFFFF) << 16) | (retail_raw >> 16) ?
i.e. block18_raw == rotate16(retail_raw).
"""
from __future__ import annotations
import json
import sys
from pathlib import Path


def load(path: str) -> dict:
    return json.loads(Path(path).read_text())


def rot16(v: int) -> int:
    v &= 0xFFFFFFFF
    return ((v & 0xFFFF) << 16) | (v >> 16)


def index_by_comp(doc: dict) -> dict[str, dict[int, int]]:
    """comp_name -> {name_hash: offset_raw}"""
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
    conv = load(sys.argv[1])   # converted block (block18)
    retail = load(sys.argv[2])  # retail oracle
    c = index_by_comp(conv)
    r = index_by_comp(retail)
    shared = sorted(set(c) & set(r))
    total = 0
    rot_match = 0
    eq_match = 0
    other = 0
    examples: list[str] = []
    for comp in shared:
        for nh, craw in c[comp].items():
            if nh not in r[comp]:
                continue
            rraw = r[comp][nh]
            total += 1
            if craw == rraw:
                eq_match += 1
            elif craw == rot16(rraw):
                rot_match += 1
            else:
                other += 1
                if len(examples) < 20:
                    examples.append(
                        f"  {comp} nh=0x{nh:08x}: conv=0x{craw:08x} retail=0x{rraw:08x} "
                        f"rot16(retail)=0x{rot16(rraw):08x}"
                    )
    print(f"shared components: {shared}")
    print(f"matched fields total={total}  identical={eq_match}  rot16-match={rot_match}  other={other}")
    if examples:
        print("non-matching examples:")
        print("\n".join(examples))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
