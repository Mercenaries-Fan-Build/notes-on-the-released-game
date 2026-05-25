#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Split ``scripts_vz`` LuaQ bytecode chunks and harvest PMC / layer strings.

Outputs:
  - ``output/lua_chunks/scripts_vz/*.chunk.bin`` — raw bytecode per ``LuaQ`` header
  - ``output/placements/pmc_lua_string_harvest.json`` — string hits per chunk
  - ``output/placements/pmc_lua_string_harvest.csv`` — flattened table

Optional disassembly: set ``LUADISASS`` to the ``LuaDisAss.py`` (or equivalent) script path;
if the file exists, each chunk is also written as ``.luaasm`` when disassembly succeeds.
"""

from __future__ import annotations

import argparse
import csv
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SIG = b"LuaQ"
PMC_PAT = re.compile(
    r"pmc|pmcoutpost|pmcinterior|interior|RuntimeLayer|Activate|vz_state_pmc|LoadInterior|SpawnPatrols",
    re.I,
)


def _find_luaq_offsets(data: bytes) -> list[int]:
    out: list[int] = []
    pos = 0
    while True:
        i = data.find(SIG, pos)
        if i < 0:
            break
        out.append(i)
        pos = i + 1
    return out


def _ascii_strings(blob: bytes, min_len: int = 5) -> list[str]:
    s: list[str] = []
    i = 0
    while i < len(blob):
        if 32 <= blob[i] < 127:
            j = i
            while j < len(blob) and 32 <= blob[j] < 127:
                j += 1
            if j - i >= min_len:
                s.append(blob[i:j].decode("ascii", errors="replace"))
            i = j
        else:
            i += 1
    return s


def main() -> int:
    ap = argparse.ArgumentParser(description="Split scripts_vz LuaQ chunks + harvest strings")
    ap.add_argument(
        "--scripts-bin",
        type=Path,
        default=Path("output/extracted/batch_vz/blocks/03197_blocks__VZ__scripts_vz_P000_Q3.block.bin"),
    )
    ap.add_argument("--out-dir", type=Path, default=Path("output/lua_chunks/scripts_vz"))
    ap.add_argument(
        "--harvest-json",
        type=Path,
        default=Path("output/placements/pmc_lua_string_harvest.json"),
    )
    ap.add_argument(
        "--harvest-csv",
        type=Path,
        default=Path("output/placements/pmc_lua_string_harvest.csv"),
    )
    args = ap.parse_args()

    if not args.scripts_bin.is_file():
        print(f"error: missing {args.scripts_bin}", file=sys.stderr)
        return 1

    data = args.scripts_bin.read_bytes()
    offs = _find_luaq_offsets(data)
    if not offs:
        print("error: no LuaQ signatures found", file=sys.stderr)
        return 1

    args.out_dir.mkdir(parents=True, exist_ok=True)
    luadisass = os.environ.get("LUADISASS", "").strip()

    rows: list[dict[str, object]] = []
    flat_csv: list[dict[str, str]] = []

    for idx, start in enumerate(offs):
        end = offs[idx + 1] if idx + 1 < len(offs) else len(data)
        chunk = data[start:end]
        stem = f"{args.scripts_bin.stem}_chunk_{idx:04d}"
        bin_path = args.out_dir / f"{stem}.chunk.bin"
        bin_path.write_bytes(chunk)

        strings = _ascii_strings(chunk)
        hits = [t for t in strings if PMC_PAT.search(t)]
        rows.append(
            {
                "chunk_index": idx,
                "byte_offset": start,
                "byte_length": len(chunk),
                "bin_path": str(bin_path),
                "pmc_related_strings": hits,
                "string_count": len(strings),
            }
        )
        for h in hits:
            flat_csv.append({"chunk_index": str(idx), "byte_offset": str(start), "string": h})

        if luadisass and Path(luadisass).is_file():
            asm_path = args.out_dir / f"{stem}.luaasm"
            try:
                subprocess.run(
                    [sys.executable, luadisass, str(bin_path)],
                    check=False,
                    stdout=asm_path.open("w", encoding="utf-8"),
                    stderr=subprocess.DEVNULL,
                    timeout=60,
                )
            except OSError:
                pass

    doc = {
        "source": str(args.scripts_bin),
        "luaq_count": len(offs),
        "chunks": rows,
        "luadisass_env": luadisass or None,
    }
    args.harvest_json.parent.mkdir(parents=True, exist_ok=True)
    args.harvest_json.write_text(json.dumps(doc, indent=2), encoding="utf-8")

    args.harvest_csv.parent.mkdir(parents=True, exist_ok=True)
    with args.harvest_csv.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["chunk_index", "byte_offset", "string"])
        w.writeheader()
        w.writerows(flat_csv)

    print(f"Wrote {len(offs)} chunks under {args.out_dir}")
    print(f"Harvest → {args.harvest_json} and {args.harvest_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
