#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Build ECS + Lua-like symbol list from cdbsizes.ini and Mercenaries2.exe strings."""

from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path


def parse_cdbsizes(path: Path) -> dict[str, list[int]]:
    comp: dict[str, list[int]] = {}
    section = None
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1]
            continue
        if section == "presize" and line and not line.startswith("#"):
            parts = re.split(r"\s+", line)
            name = parts[0]
            nums = [int(x) for x in parts[1:] if x.isdigit()]
            comp[name] = nums
    return comp


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    cdbs = root / "Mercenaries 2 World in Flames/data/cdbsizes.ini"
    exe = root / "Mercenaries 2 World in Flames/Mercenaries2.exe"
    comp = parse_cdbsizes(cdbs)
    blob = subprocess.check_output(["strings", "-n", "8", str(exe)], text=True, errors="ignore")
    symbols = sorted(set(re.findall(r"\b(?:Add|Set|Get|Is|Has|Create|Destroy|Activate|Spawn)[A-Za-z0-9_]{2,}\b", blob)))
    manifest = {
        "components_count": len(comp),
        "symbol_count": len(symbols),
        "symbols_max_output": 8000,
        "components": [{"name": k, "sizes": v} for k, v in sorted(comp.items())],
        "symbols": symbols[:8000],
    }
    out_path = root / "output/ecs_manifest.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(
        f"Wrote {out_path} ({manifest['components_count']} components, "
        f"{manifest['symbol_count']} symbols, symbols_max_output={manifest['symbols_max_output']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
