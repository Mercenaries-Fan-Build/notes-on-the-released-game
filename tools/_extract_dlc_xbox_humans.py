#!/usr/bin/env python3
"""Extract DLC Xbox-source human blocks from the X360 DLC RAR (STFS -> DOH WAD)."""
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from x360_dlc_io import extract_stfs_from_rar
from _extract_human_blocks import extract

RAR = Path("game-files/Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar")
OUT = Path("output/human_blocks/dlc_xbox")
SUB = sys.argv[1] if len(sys.argv) > 1 else "hum"


def main():
    work = Path(tempfile.mkdtemp(prefix="dlc_src_"))
    print(f"Extracting STFS from {RAR.name} -> {work} ...", flush=True)
    reader = extract_stfs_from_rar(RAR, work)
    doh_entry = next((e for e in reader.file_table if "doh" in e["name"].lower()), None)
    if doh_entry is None:
        print("ERROR: no DOH in STFS"); return 1
    doh_size = doh_entry["file_size"]
    print(f"DOH '{doh_entry['name']}': {doh_size:,} bytes", flush=True)

    doh_file = work / "dlc.doh"
    CH = 64 * 1024 * 1024
    with open(doh_file, "wb") as f:
        for off in range(0, doh_size, CH):
            f.write(reader.read(off, min(CH, doh_size - off)))
    print(f"DOH written to {doh_file} ({doh_file.stat().st_size:,} bytes); magic={doh_file.read_bytes()[:4]!r}", flush=True)

    extract(doh_file, OUT, SUB)


if __name__ == "__main__":
    raise SystemExit(main())
