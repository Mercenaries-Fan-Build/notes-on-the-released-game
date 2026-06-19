#!/usr/bin/env python3
"""Build all standard patch-WAD bisect trim variants into one output directory."""
from __future__ import annotations

import hashlib
import json
import subprocess
import sys
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
REPO = THIS_DIR.parent
PY = REPO / ".venv" / "Scripts" / "python.exe"
TRIM = THIS_DIR / "trim_patch_wad.py"
WAD = REPO / "output" / "data" / "vz-patch.wad"
OUT_DIR = REPO / "output" / "data" / "bisect"

RULED = "0,4,12,15,16,17"
BOOTSTRAP = 2196
DEFAULT_TOP5 = "3,8,2,5,13"

VARIANTS: list[tuple[str, str, list[str]]] = [
    (
        "step2-retest",
        "Ruled-out state overlays only (0,4,12,15,16,17)",
        ["--exclude-indices", RULED],
    ),
    (
        "no-bootstrap",
        "Step2 + drop scripts_vz bootstrap @2196",
        ["--exclude-indices", f"{RULED},{BOOTSTRAP}"],
    ),
    (
        "no-base",
        "Step2 + drop dlc01_base + commonlocations (3,5)",
        ["--exclude-indices", f"{RULED},3,5"],
    ),
    (
        "no-top5-scan",
        f"Step2 + drop default scan suspects ({DEFAULT_TOP5})",
        ["--exclude-indices", f"{RULED},{DEFAULT_TOP5}"],
    ),
    (
        "lo-half",
        "Keep blocks 1-1099 only (excl bootstrap + ruled-out)",
        [
            "--exclude-indices",
            f"{RULED},{BOOTSTRAP}",
            "--keep-only-indices",
            "1-1099",
        ],
    ),
    (
        "hi-half",
        "Keep blocks 1100-2195 only (excl bootstrap + ruled-out)",
        [
            "--exclude-indices",
            f"{RULED},{BOOTSTRAP}",
            "--keep-only-indices",
            "1100-2195",
        ],
    ),
    (
        "q1",
        "Quarter 1: blocks 1-549",
        ["--exclude-indices", f"{RULED},{BOOTSTRAP}", "--keep-only-indices", "1-549"],
    ),
    (
        "q2",
        "Quarter 2: blocks 550-1099",
        [
            "--exclude-indices",
            f"{RULED},{BOOTSTRAP}",
            "--keep-only-indices",
            "550-1099",
        ],
    ),
    (
        "q3",
        "Quarter 3: blocks 1100-1649",
        [
            "--exclude-indices",
            f"{RULED},{BOOTSTRAP}",
            "--keep-only-indices",
            "1100-1649",
        ],
    ),
    (
        "q4",
        "Quarter 4: blocks 1650-2195",
        [
            "--exclude-indices",
            f"{RULED},{BOOTSTRAP}",
            "--keep-only-indices",
            "1650-2195",
        ],
    ),
    (
        "no-c3",
        "Step2 + drop all blocks\\dlc01\\c3 cells",
        ["--exclude-indices", RULED, "--exclude-path-substr", "dlc01/c3"],
    ),
    (
        "no-state",
        "Step2 + drop all dlc01_state* overlay blocks",
        ["--exclude-indices", RULED, "--exclude-path-substr", "dlc01_state"],
    ),
    (
        "no-scripts-vz",
        "Step2 + drop scripts_vz path blocks",
        ["--exclude-indices", RULED, "--exclude-path-substr", "scripts_vz"],
    ),
    (
        "no-dlc01-meshes",
        "Step2 + drop dlc01 mesh contract blocks (dlccon)",
        ["--exclude-indices", RULED, "--exclude-path-substr", "dlccon"],
    ),
]

# Additive bisect: known-good hi-half (1100-2195) + suspect lo-half subset.
_HI = "1100-2195"
_ADDITIVE_EXCL = ["--exclude-indices", f"{RULED},{BOOTSTRAP}"]

ADDITIVE_VARIANTS: list[tuple[str, str, list[str]]] = [
    (
        "arena-hi",
        "hi-half + arena bootstrap layer (blocks 1-19): caicara, dlccon, base, speedcity",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"1-19,{_HI}"],
    ),
    (
        "blk18-hi",
        "hi-half + block 18 only (dlc01_dlccon004_roads — spatial-hash suspect)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"18,{_HI}"],
    ),
    (
        "blk464-hi",
        "hi-half + block 464 only (resident_P000_Q3 — script/singleton suspect)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"464,{_HI}"],
    ),
    (
        "q1-c3-hi",
        "hi-half + q1 c3 slice (blocks 20-549, no arena bootstrap)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"20-549,{_HI}"],
    ),
    (
        "q2-lo-hi",
        "hi-half + q2 lower half (blocks 550-824)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"550-824,{_HI}"],
    ),
    (
        "q2-hi-hi",
        "hi-half + q2 upper half (blocks 825-1099)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"825-1099,{_HI}"],
    ),
    (
        "dlccon-core-hi",
        "hi-half + core contract blocks (2,3,6,8,10,13,18)",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"2,3,6,8,10,13,18,{_HI}"],
    ),
    (
        "arena-resident-hi",
        "hi-half + arena (1-19) + resident 464",
        [*_ADDITIVE_EXCL, "--keep-only-indices", f"1-19,464,{_HI}"],
    ),
    # Arena split to isolate the render-view 0xFFFF trigger WITHOUT block 18.
    # Block 18 is in neither WAD: if both pass, 18 is confirmed the sole trigger.
    # Literal index ranges per request (state overlays 4 / 12,15,16,17 retained,
    # unlike arena-hi which excluded them); bootstrap 2196 excluded (out of range).
    (
        "arena-1-10-hi",
        "hi-half + arena blocks 1-10 (block 18 absent)",
        ["--exclude-indices", str(BOOTSTRAP), "--keep-only-indices", f"1-10,{_HI}"],
    ),
    (
        "arena-11-20-no18-hi",
        "hi-half + arena blocks 11-17,19,20 (block 18 absent)",
        [
            "--exclude-indices",
            str(BOOTSTRAP),
            "--keep-only-indices",
            f"11-17,19,20,{_HI}",
        ],
    ),
    # "Clean" arena splits: same ranges but with all known-bad road/race blocks
    # removed (6 dlccon002_roads, 13 dlccon002_race, 18 dlccon004_roads).
    # If these still fault, an UNKNOWN arena trigger remains.
    (
        "arena-1-10-clean-hi",
        "hi-half + arena 1-10 minus known-bad {6,13,18}",
        [
            "--exclude-indices",
            f"{BOOTSTRAP},6,13,18",
            "--keep-only-indices",
            f"1-10,{_HI}",
        ],
    ),
    (
        "arena-11-20-clean-hi",
        "hi-half + arena 11-17,19,20 minus known-bad {6,13,18}",
        [
            "--exclude-indices",
            f"{BOOTSTRAP},6,13,18",
            "--keep-only-indices",
            f"11-17,19,20,{_HI}",
        ],
    ),
    # Compact-ECS byte-order bug controls (blocks 0,4,15,16,17 carry BE-unswapped
    # ecs_node compact 'info' records — proven byte-exact vs retail vz.wad).
    # Sufficiency: do the corrupt blocks alone reproduce the livelock?
    (
        "ecs-corrupt-hi",
        "hi-half + ONLY corrupt-ECS blocks {0,4,15,16,17}",
        [
            "--keep-only-indices",
            f"0,4,15,16,17,{_HI}",
        ],
    ),
    # Necessity: arena 1-20 with corrupt-ECS {0,4,15,16,17} AND known-bad {6,13,18}
    # removed. If this loads, the corrupt blocks were required for the arena hang.
    (
        "arena-noecs-hi",
        "hi-half + arena 1-20 minus corrupt-ECS {0,4,15,16,17} and known-bad {6,13,18}",
        [
            "--exclude-indices",
            f"{BOOTSTRAP},0,4,6,13,15,16,17,18",
            "--keep-only-indices",
            f"1-20,{_HI}",
        ],
    ),
]


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def _build_variants(
    variants: list[tuple[str, str, list[str]]],
    manifest: list[dict],
) -> int:
    for name, description, extra_args in variants:
        out = OUT_DIR / f"vz-patch-{name}.wad"
        print(f"\n=== Building {name} ===")
        cmd = [
            str(PY),
            str(TRIM),
            "-i",
            str(WAD),
            "-o",
            str(out),
            *extra_args,
        ]
        rc = subprocess.run(cmd, cwd=REPO)
        if rc.returncode != 0:
            print(f"FAILED: {name}", file=sys.stderr)
            return rc.returncode
        entry = {
            "id": name,
            "description": description,
            "file": str(out.relative_to(REPO)).replace("\\", "/"),
            "bytes": out.stat().st_size,
            "sha256": sha256(out),
            "deploy": f'copy "{out}" "…\\Mercenaries 2 World in Flames\\data\\vz-patch.wad"',
        }
        manifest.append(entry)
        print(f"OK {out.name}  {entry['bytes']:,} bytes")
    return 0


def main() -> int:
    import argparse

    ap = argparse.ArgumentParser(description="Build patch-WAD bisect trim variants")
    ap.add_argument(
        "--additive-only",
        action="store_true",
        help="Build only hi-half + lo-subset additive variants",
    )
    ap.add_argument(
        "--merge-manifest",
        action="store_true",
        default=True,
        help="Merge into existing manifest.json (default: on)",
    )
    args = ap.parse_args()

    if not PY.is_file():
        print("ERROR: .venv missing — run make venv", file=sys.stderr)
        return 2
    if not WAD.is_file():
        print(f"ERROR: missing {WAD}", file=sys.stderr)
        return 2

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    manifest_path = OUT_DIR / "manifest.json"
    manifest: list[dict] = []
    if args.merge_manifest and manifest_path.is_file():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))

    to_build = ADDITIVE_VARIANTS if args.additive_only else VARIANTS
    if args.additive_only:
        manifest = [e for e in manifest if e["id"] not in {v[0] for v in to_build}]

    rc = _build_variants(to_build, manifest)
    if rc != 0:
        return rc

    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"\nWrote {manifest_path} ({len(manifest)} variants)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
