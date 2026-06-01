#!/usr/bin/env python3
"""Phase 3: Transform entity-key overlap between DLC blocks and retail VZ blocks.

If DLC block keys collide with retail keys that are registered first, the engine's
keyed entity registry could merge/overwrite -> corrupt runtime entity -> bad position.
"""
from __future__ import annotations
import sys
from pathlib import Path

_TOOLS = Path(__file__).resolve().parent
if str(_TOOLS) not in sys.path:
    sys.path.insert(0, str(_TOOLS))

from correlate_entity_ptr import _iter_transform_records  # type: ignore


def keys_of(path: str) -> set[int]:
    data = Path(path).read_bytes()
    return {r["entity_key"] for r in _iter_transform_records(data)}


def main() -> int:
    # args: label=path pairs
    blocks: dict[str, set[int]] = {}
    for arg in sys.argv[1:]:
        label, _, path = arg.partition("=")
        ks = keys_of(path)
        blocks[label] = ks
        lo = min(ks) if ks else 0
        hi = max(ks) if ks else 0
        print(f"{label:14s} keys={len(ks):5d}  range=0x{lo:08x}..0x{hi:08x}")
    print()
    labels = list(blocks)
    retail = [l for l in labels if l.startswith("retail")]
    dlc = [l for l in labels if not l.startswith("retail")]
    for d in dlc:
        for r in retail:
            ov = blocks[d] & blocks[r]
            print(f"{d:14s} X {r:18s} = {len(ov):5d} colliding keys")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
