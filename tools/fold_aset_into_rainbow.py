#!/usr/bin/env python3
"""fold_aset_into_rainbow.py -- publish the ASET-cracked names into the rainbow table.

The bone census + workshop bone resolver read `tools/rainbow_table.json` (via
`worldutil::rainbow_names`), NOT the ASET export. So a name cracked by the ASET pipeline
(`aset_export` / `aset_external_mine --roster` / convention derivation) lives in
`docs/data/aset_names.csv` but stays invisible to the census until it is folded here.

This folds every VERIFIED preimage from `aset_names.csv` (a name whose `pandemic_hash_m2`
equals its `asset_hash`) into the rainbow table. Idempotent; only verified names are added,
so it can never introduce a fabricated name. Run after any ASET-naming pass.
"""
import csv
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from fnv import m2  # noqa: E402

ASET = Path("docs/data/aset_names.csv")
RAINBOW = Path("tools/rainbow_table.json")


def main() -> int:
    rb = json.loads(RAINBOW.read_text())
    m = rb["pandemic_hash_m2"]
    before = len(m)
    added = rejected = 0
    for r in csv.DictReader(open(ASET)):
        name = (r.get("name") or "").strip()
        if not name:
            continue
        h = int(r["asset_hash"], 16)
        if m2(name) != h:  # only publish real preimages — never a fabrication
            rejected += 1
            continue
        key = f"0x{h:08X}"
        m.setdefault(key, [])
        if name not in m[key]:
            m[key].append(name)
            added += 1
    RAINBOW.write_text(json.dumps(rb, indent=1))
    print(f"folded aset_names.csv -> rainbow: +{added} verified names "
          f"({rejected} rejected as non-preimages); {before} -> {len(m)} hashes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
