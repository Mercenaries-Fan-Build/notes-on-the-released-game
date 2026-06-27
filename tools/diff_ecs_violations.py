#!/usr/bin/env python3
"""Differential ECS-violation diff for two wad_simulator JSON reports.

The simulator's schema-driven ECS float/position scan over-flags some retail-valid
non-Transform Vec3/Blob32 fields (e.g. Road@0x0 is ref data, not a world position),
so the raw counts are NOT a reliable corruption signal on their own. This tool
subtracts a retail-oracle report from a patch report and prints only the
DLC-specific deltas — the violations the conversion actually introduced.

Signatures ignore block index (which differs between overlay and base-only runs)
and key on (component, field_type, field_offset, kind, value_string).

Usage:
    python tools/diff_ecs_violations.py --patch patch.json --base base.json
Produce the inputs with:
    wad_simulator --wad <patch.wad> --base-wad <retail.wad> --json-output patch.json
    wad_simulator --wad <retail.wad>                         --json-output base.json
"""
from __future__ import annotations

import argparse
import collections
import json
import re
from pathlib import Path

_RX = re.compile(
    r'ECS "([^"]+)" (\w+)\+0x([0-9A-Fa-f]+) record\[(\d+)\] ([^:]+): (.+?)(?: \u2014|$)'
)


def signatures(path: Path) -> collections.Counter:
    data = json.loads(path.read_text(encoding="utf-8"))
    out: collections.Counter = collections.Counter()
    # ECS component NaN/Inf strings now live in their own differential channel
    # (ecs_diff_issues); fall back to ucfx_issues for reports from older builds.
    sources = data.get("ecs_diff_issues") or data.get("ucfx_issues", [])
    for s in sources:
        if 'ECS "' not in s:
            continue
        m = _RX.search(s)
        if not m:
            continue
        name, ftype, off, _rec, kind, vals = m.groups()
        out[(name, ftype, "0x" + off.upper(), kind.strip(), vals.strip())] += 1
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--patch", required=True, type=Path, help="patch (DLC) JSON report")
    ap.add_argument("--base", required=True, type=Path, help="retail oracle JSON report")
    ap.add_argument("--max", type=int, default=40, help="max delta lines to print")
    args = ap.parse_args()

    patch = signatures(args.patch)
    base = signatures(args.base)
    patch_only = patch - base
    base_only = base - patch

    print(f"patch ECS pos/quat signatures: {sum(patch.values())}")
    print(f"base  ECS pos/quat signatures: {sum(base.values())}")
    print()
    print(f"DLC-SPECIFIC violations (patch − base): {sum(patch_only.values())}")
    by_comp: collections.Counter = collections.Counter()
    for (name, *_), c in patch_only.items():
        by_comp[name] += c
    for name, c in by_comp.most_common():
        print(f"  {c:6}  {name}")
    for sig, c in patch_only.most_common(args.max):
        print(f"    +{c}  {sig}")
    print()
    print(f"retail-only (base − patch): {sum(base_only.values())}")

    if sum(patch_only.values()) == 0:
        print("\nNo DLC-specific ECS position/float deltas: stored data matches retail.")
        return 0
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
