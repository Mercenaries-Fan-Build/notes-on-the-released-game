#!/usr/bin/env python3
"""Harvest DLC name strings from a patch WAD and fold genuinely-new hashes into
the pandemic_hash rainbow table.

build_rainbow_table.py only ingests strings from the retail vz.wad (PTHS +
scripts_vz bytecode), so DLC-only asset names (and their pandemic_hash_m2
hashes) are absent. This tool:

  1. Extracts every ASCII token from the patch WAD's decompressed blocks
     (where NAME / material / texture name strings live) plus its PTHS paths.
  2. Computes pandemic_hash_m2 (+ v1) for each unique token.
  3. Diffs against tools/rainbow_table.json and reports how many hashes are
     GENUINELY NEW vs. already present.
  4. Checks a set of target hashes (e.g. the stuck-texture asset hash).
  5. With --merge, folds the new strings into the table in place.

Usage:
    python tools/harvest_dlc_strings.py                 # dry-run on output/data/vz-patch.wad
    python tools/harvest_dlc_strings.py --merge          # write new hashes into the table
    python tools/harvest_dlc_strings.py --wad <path> --extra-wad game-files/xbox-vz.wad
"""
from __future__ import annotations

import argparse
import json
import mmap
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from pandemic_hash import pandemic_hash, pandemic_hash_m2  # noqa: E402

# ASCII identifier / path token: starts with a letter or _, len >= 3.
TOKEN_RE = re.compile(rb"[A-Za-z_][A-Za-z0-9_.\\/\-]{2,}")

# Hashes worth knowing about (from the live livelock RCA).
DEFAULT_TARGETS = [
    0x244D6624,  # stuck DXT1 texture asset hash (work item 0x2004FFB0 descriptor)
    0x244E6A42,  # sibling registry node hash
    0x5FF5980D,  # ecs_node container ref-hash
    0xE6B81A54,  # ecs_node type_hash
]


_SNAKE_RE = re.compile(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)+")          # lowercase_snake_case
_CAMEL_RE = re.compile(r"(?:[A-Z][a-z0-9]+){2,}")                  # CamelCaseNames
_IDENT_RE = re.compile(r"[A-Za-z0-9_]+")
_PREFIX_RE = re.compile(
    r"(c[0-9]{4,}|dlc[0-9]|dlccon|dlcjob|.*con[0-9]{3}|.*job[0-9]{3}"
    r"|vz_state_|mar_|wif|mrx|starter_)", re.I)


def is_quality_name(s: str) -> bool:
    """Keep real asset/identifier/path names; drop binary-ASCII noise.

    Matches the precision filter validated against the patch-WAD corpus: paths,
    lowercase_snake_case, CamelCase, or known Pandemic name prefixes (c#### cells,
    dlc*, *con###/*job###, vz_state_*, mar_*, Wif*/Mrx*, starter_*). Minimum
    length 5 to drop 3-4 char binary fragments.
    """
    if "\\" in s or "/" in s:
        return True  # paths are real
    base = s.split(".")[0]
    if not (5 <= len(base) <= 64):
        return False
    if _SNAKE_RE.fullmatch(base):
        return True
    if _CAMEL_RE.fullmatch(base):
        return True
    if _PREFIX_RE.match(base) and _IDENT_RE.fullmatch(base):
        return True
    return False


def _add_token(out: set[str], s: str) -> None:
    if len(s) < 3:
        return
    out.add(s)
    # path stems / basenames so e.g. "blocks\VZ\foo_P000_Q3.block" also yields "foo"
    if "\\" in s or "/" in s:
        name = s.replace("\\", "/").split("/")[-1]
        if name:
            out.add(name)
            base = name.split(".")[0]
            base = re.sub(r"_P\d+_Q\d+$", "", base)
            if base:
                out.add(base)


def harvest_wad(wad_path: Path, *, verbose: bool = True) -> set[str]:
    """Decompress every block and PTHS in a WAD; return the set of ASCII tokens."""
    from ffcs_wad import parse_ffcs, extract_slice, dump_paths_from_pths
    from wad_patcher import get_block_boundaries
    from sges_decompress import decompress_sges_block

    tokens: set[str] = set()
    raw = wad_path.read_bytes()
    arch = parse_ffcs(wad_path)

    # PTHS paths
    pths = next((c for c in arch.chunks if c.tag == "PTHS"), None)
    if pths and pths.size:
        for p in dump_paths_from_pths(extract_slice(raw, pths)):
            _add_token(tokens, p)
    if verbose:
        print(f"  PTHS tokens: {len(tokens):,}")

    # Decompressed block ASCII
    data_chunk = next((c for c in arch.chunks if c.tag == "DATA"), None)
    if not data_chunk:
        if verbose:
            print("  (no DATA chunk — skipping block decompression)")
        return tokens

    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    try:
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        if verbose:
            print(f"  blocks: {len(boundaries):,}")
        ok = err = 0
        for i, (start, end) in enumerate(boundaries):
            try:
                decomp = decompress_sges_block(mm, start, end)
                for m in TOKEN_RE.finditer(decomp):
                    try:
                        _add_token(tokens, m.group().decode("ascii"))
                    except UnicodeDecodeError:
                        pass
                ok += 1
            except Exception:
                err += 1
            if verbose and (i + 1) % 250 == 0:
                print(f"    {i + 1}/{len(boundaries)} blocks  (tokens={len(tokens):,})")
    finally:
        mm.close()
    if verbose:
        print(f"  decompressed ok={ok} err={err}; total tokens: {len(tokens):,}")
    return tokens


def main() -> int:
    ap = argparse.ArgumentParser(description="Harvest DLC strings into the rainbow table")
    ap.add_argument("--wad", type=Path, default=Path("output/data/vz-patch.wad"),
                    help="DLC patch WAD to harvest (default: output/data/vz-patch.wad)")
    ap.add_argument("--extra-wad", type=Path, action="append", default=[],
                    help="Additional WAD(s) to harvest (e.g. game-files/xbox-vz.wad)")
    ap.add_argument("--table", type=Path,
                    default=Path(__file__).resolve().parent / "rainbow_table.json")
    ap.add_argument("--merge", action="store_true",
                    help="Write genuinely-new strings into the table in place")
    ap.add_argument("--quality", action="store_true",
                    help="On merge, keep only quality name/path tokens (drop binary noise)")
    ap.add_argument("--cache", type=Path,
                    default=Path(__file__).resolve().parent / ".dlc_tokens_cache.txt",
                    help="Token cache file (written on harvest, reused with --use-cache)")
    ap.add_argument("--use-cache", action="store_true",
                    help="Load tokens from --cache instead of re-decompressing the WAD")
    ap.add_argument("--targets", type=lambda s: int(s, 16), nargs="*",
                    default=DEFAULT_TARGETS, help="Hex hashes to check for cracks")
    args = ap.parse_args()

    wads = [args.wad] + list(args.extra_wad)
    tokens: set[str] = set()
    if args.use_cache and args.cache.is_file():
        print(f"Loading tokens from cache {args.cache} ...")
        tokens = {ln for ln in args.cache.read_text(encoding="utf-8", errors="ignore").splitlines() if ln}
    else:
        for w in wads:
            if not w.is_file():
                print(f"!! WAD not found: {w}")
                continue
            print(f"Harvesting {w} ...")
            tokens |= harvest_wad(w)
        try:
            args.cache.write_text("\n".join(sorted(tokens)), encoding="utf-8")
            print(f"  cached {len(tokens):,} tokens -> {args.cache}")
        except Exception as e:
            print(f"  (cache write failed: {e})")
    print(f"\nTotal unique DLC tokens: {len(tokens):,}")

    # Load existing table
    tbl = json.loads(args.table.read_text())
    m2 = tbl["pandemic_hash_m2"]
    v1 = tbl.get("pandemic_hash", {})
    existing_m2 = set(m2.keys())

    # Hash tokens
    new_hashes: dict[str, list[str]] = {}     # genuinely-new m2 hash -> strings
    new_preimages: dict[str, list[str]] = {}  # existing m2 hash -> new strings
    for s in tokens:
        key = f"0x{pandemic_hash_m2(s):08X}"
        if key in existing_m2:
            if s not in m2[key]:
                new_preimages.setdefault(key, []).append(s)
        else:
            new_hashes.setdefault(key, []).append(s)

    q_tokens = {s for s in tokens if is_quality_name(s)}
    q_new_hashes = {k: v for k, v in new_hashes.items()
                    if any(is_quality_name(s) for s in v)}
    print(f"\nGENUINELY NEW m2 hashes (raw): {len(new_hashes):,}")
    print(f"  ...quality-filtered: {len(q_new_hashes):,}  "
          f"(from {len(q_tokens):,} quality tokens of {len(tokens):,})")
    print(f"New preimages for existing hashes: {len(new_preimages):,} "
          f"({sum(len(v) for v in new_preimages.values()):,} strings)")

    # Target check (against ALL tokens, not just quality)
    print("\nTarget hash check:")
    for h in args.targets:
        key = f"0x{h:08X}"
        hit = m2.get(key) or new_hashes.get(key) or new_preimages.get(key)
        print(f"  {key} -> {sorted(hit) if hit else 'NOT FOUND'}")

    if not args.merge:
        print("\n(dry-run; re-run with --merge [--quality] to fold strings into the table)")
        return 0

    merge_tokens = q_tokens if args.quality else tokens
    print(f"\nMerging {'QUALITY' if args.quality else 'ALL'} tokens: {len(merge_tokens):,}")
    # Merge: add genuinely-new hashes and new preimages (m2 + v1)
    added_m2 = 0
    for s in merge_tokens:
        key = f"0x{pandemic_hash_m2(s):08X}"
        cur = set(m2.get(key, []))
        if s not in cur:
            cur.add(s)
            m2[key] = sorted(cur)
            added_m2 += 1
        vk = f"0x{pandemic_hash(s):08X}"
        curv = set(v1.get(vk, []))
        if s not in curv:
            curv.add(s)
            v1[vk] = sorted(curv)

    meta = tbl.setdefault("_meta", {})
    meta["unique_m2_hashes"] = len(m2)
    meta["unique_v1_hashes"] = len(v1)
    meta["dlc_harvest"] = {
        "wads": [str(w) for w in wads if w.is_file()],
        "tokens_total": len(tokens),
        "tokens_merged": len(merge_tokens),
        "quality_filter": bool(args.quality),
        "new_m2_entries_added": added_m2,
    }
    tbl["pandemic_hash_m2"] = m2
    tbl["pandemic_hash"] = v1
    args.table.write_text(json.dumps(tbl, indent=2, sort_keys=False))
    size_mb = args.table.stat().st_size / 1024 / 1024
    print(f"\nMerged -> {args.table} ({size_mb:.1f} MB); "
          f"m2 entries now {len(m2):,}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
