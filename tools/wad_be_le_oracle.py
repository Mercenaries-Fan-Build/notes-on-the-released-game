#!/usr/bin/env python3
"""Base-game BE->LE conversion oracle (the "Rosetta Stone").

Convert every entry of the big-endian Xbox 360 ``xbox-vz.wad`` through the
production BE->LE converter and diff it byte-for-byte against the PC ``vz.wad``
counterpart.

Comparison is keyed by **(block_path, asset_hash, type_hash)** -- NOT a global
``(asset_hash, type_hash)``.  The two WADs share block path strings (PTHS), so
pairing per block is collision-free; a global hash key is unsafe because ~1/3
of ``(asset_hash, type_hash)`` keys recur across multiple blocks with different
content (ECS layer nodes, paths, etc.).  Blocks are matched by path because the
two WADs even differ in block COUNT (PC 11,371 vs Xbox 11,087) and ordering.

Because the comparison is on the DECOMPRESSED per-entry UCFX (with CSUM), the
sges segmentation/padding differences between the WADs are irrelevant.

Artifacts (written under --out-dir, default output/_scratch):
  - rosetta_oracle_report.json   summary + per-type MATCH/MISMATCH/...
  - pc_only_assets.json          assets (any block) present in PC, absent Xbox
  - xbox_only_assets.json        mirror
  - pc_only_blocks.json          block paths in PC but not Xbox (+ mirror)
  - <extract-dir>/{pc,xbox_le,xbox_be}/<block>/<hash>_<type>.bin
                                 mirrored per-entry trees for `diff -r`/hex view

Usage:
    python tools/wad_be_le_oracle.py --converter rust --jobs 8
    python tools/wad_be_le_oracle.py --type 0xF011157A \
        --extract-dir output/_scratch/tex_corpus --jobs 8
"""
from __future__ import annotations

import argparse
import hashlib
import json
import mmap
import struct
import sys
import time
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from audit_dlc_conversion import TYPE_NAMES, _diff_bytes, _entry_payload  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    find_data_chunk,
    get_block_boundaries,
    load_wad_paths,
    parse_block_entries,
)
from x360_dlc_io import (  # noqa: E402
    PAGE_SIZE,
    SCFF_MAGIC,
    decompress_be_sges,
    parse_be_ffcs,
    parse_be_indx,
    parse_be_pths,
)


def _parse_entry_table_be(be: bytes) -> list[tuple[int, int, int, int]]:
    """BE block entry table: [u32 count][N x (hash, type_hash, offset, size)].

    Inlined here so the oracle no longer depends on the retired Python converter.
    """
    count = struct.unpack_from(">I", be, 0)[0]
    entries = []
    for i in range(count):
        off = 4 + i * 16
        if off + 16 > len(be):
            break
        h, t, o, s = struct.unpack_from(">IIII", be, off)
        entries.append((h, t, o, s))
    return entries

DEFAULT_XBOX_WAD = Path("game-files/xbox-vz.wad")
DEFAULT_PC_WAD = Path("game-files/vz.wad")
DEFAULT_OUT_DIR = Path("output/_scratch")

Key = tuple[int, int]  # (asset_hash, type_hash)


def type_name(th: int) -> str:
    return TYPE_NAMES.get(th, f"0x{th:08X}")


def _sha1(data: bytes) -> str:
    return hashlib.sha1(data).hexdigest()


def _norm(path: str) -> str:
    return path.replace("\\", "/").lower()


def _safe_name(path: str) -> str:
    return _norm(path).replace("/", "__")


# -- PC (LE) ground-truth index, keyed by block path -------------------

class PcIndex:
    """Per-block-path index of the PC WAD (metadata only; bytes fetched lazily).

    by_path[path_norm][(hash, type)] = (sha1, payload_len) of null-stripped payload
    loc[path_norm]                   = (s, e) DATA-relative block bounds
    """

    def __init__(self, wad_path: Path) -> None:
        self.wad_path = wad_path
        self.by_path: dict[str, dict[Key, tuple[str, int]]] = {}
        self.loc: dict[str, tuple[int, int]] = {}
        self.all_keys: set[Key] = set()
        self.key_path: dict[Key, str] = {}  # representative path per asset
        self._fh = open(wad_path, "rb")
        self._mm = mmap.mmap(self._fh.fileno(), 0, access=mmap.ACCESS_READ)

    def build(self) -> None:
        dc = find_data_chunk(self.wad_path)
        boundaries = get_block_boundaries(self._mm, dc.offset, dc.size)
        paths = load_wad_paths(self.wad_path)
        for blk_idx, (s, e) in enumerate(boundaries):
            pnorm = _norm(paths[blk_idx]) if blk_idx < len(paths) else f"block_{blk_idx:05d}"
            try:
                data = decompress_sges_block(self._mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            self.loc[pnorm] = (s, e)
            blk = self.by_path.setdefault(pnorm, {})
            for ent in entries:
                eoff, esize = ent["offset"], ent["size"]
                if eoff + esize > len(data):
                    continue
                key = (ent["hash"], ent["type_hash"])
                if key not in blk:
                    payload = _entry_payload(data[eoff:eoff + esize])
                    blk[key] = (_sha1(payload), len(payload))
                self.all_keys.add(key)
                self.key_path.setdefault(key, pnorm)

    def entry_bytes(self, pnorm: str, key: Key) -> bytes | None:
        loc = self.loc.get(pnorm)
        if loc is None:
            return None
        try:
            data = decompress_sges_block(self._mm, *loc)
            for ent in parse_block_entries(data):
                if (ent["hash"], ent["type_hash"]) == key:
                    return data[ent["offset"]:ent["offset"] + ent["size"]]
        except Exception:
            return None
        return None

    def close(self) -> None:
        try:
            self._mm.close()
        finally:
            self._fh.close()


# -- Xbox (BE) walker + converter --------------------------------------

_XBOX_MM: mmap.mmap | None = None
_CONVERTER = "rust"


def _decompress_be_block(mm: mmap.mmap, offset: int, size: int) -> bytes | None:
    """Decompress one Xbox block (segs) or recover an uncompressed XFCU block.

    Mirrors ``dlc_port._process_one_block`` block loading.
    """
    sl = mm[offset:offset + size]
    if len(sl) < 4:
        return None
    if sl[:4] == b"segs":
        try:
            return decompress_be_sges(sl, 0, len(sl))
        except Exception:
            return None
    rec_count = struct.unpack_from(">I", sl, 0)[0]
    header_end = 4 + rec_count * 16
    first_tag = sl[header_end:header_end + 4] if header_end + 4 <= len(sl) else b""
    if 0 < rec_count < 5000 and first_tag == b"XFCU":
        end = len(sl)
        while end > 4 and sl[end - 1] == 0:
            end -= 1
        end = (end + 3) & ~3
        return bytes(sl[:end])
    return None


def _convert(be_block: bytes, converter: str) -> bytes:
    # Rust-only: the Python byte-swap converter has been retired.
    from ucfx_byteswap_wrapper import byteswap_block_rust
    return byteswap_block_rust(be_block, validate=False)


def _split_le_entries(le_block: bytes) -> dict[Key, bytes]:
    out: dict[Key, bytes] = {}
    for ent in parse_block_entries(le_block):
        eoff, esize = ent["offset"], ent["size"]
        if eoff + esize > len(le_block):
            continue
        out[(ent["hash"], ent["type_hash"])] = le_block[eoff:eoff + esize]
    return out


def _split_be_entries(be_block: bytes) -> dict[Key, bytes]:
    out: dict[Key, bytes] = {}
    for h, t, o, s in _parse_entry_table_be(be_block):
        if o + s > len(be_block):
            continue
        out[(h, t)] = be_block[o:o + s]
    return out


class BlockResult:
    __slots__ = ("blk_idx", "path", "skipped", "reason", "converted", "raw_be")

    def __init__(self, blk_idx: int, path: str) -> None:
        self.blk_idx = blk_idx
        self.path = path
        self.skipped = False
        self.reason = ""
        self.converted: dict[Key, bytes] = {}
        self.raw_be: dict[Key, bytes] = {}


def _process_block(task: tuple[int, int, int, str, bool]) -> BlockResult:
    blk_idx, offset, size, path, keep_raw = task
    res = BlockResult(blk_idx, path)
    assert _XBOX_MM is not None
    be_block = _decompress_be_block(_XBOX_MM, offset, size)
    if be_block is None:
        res.skipped = True
        res.reason = "decompress/recover failed"
        return res
    if keep_raw:
        res.raw_be = _split_be_entries(be_block)
    try:
        le_block = _convert(be_block, _CONVERTER)
    except Exception as e:
        res.skipped = True
        res.reason = f"convert failed: {type(e).__name__}: {e}"
        return res
    res.converted = _split_le_entries(le_block)
    return res


# -- Oracle driver -----------------------------------------------------

def run_oracle(args: argparse.Namespace) -> int:
    global _XBOX_MM, _CONVERTER
    _CONVERTER = args.converter

    type_filter = int(args.type, 16) if args.type else None
    extract_dir = Path(args.extract_dir) if args.extract_dir else None
    if extract_dir:
        for sub in ("pc", "xbox_le", "xbox_be"):
            (extract_dir / sub).mkdir(parents=True, exist_ok=True)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    from ucfx_byteswap_wrapper import rust_binary_available
    if not rust_binary_available():
        print("ERROR: rust ucfx_byteswap binary not found "
              "(build: make build-ucfx-byteswap)", file=sys.stderr)
        return 1

    t0 = time.time()
    print(f"[1/3] Indexing PC ground truth: {args.pc_wad}")
    pc = PcIndex(args.pc_wad)
    pc.build()
    print(f"      {len(pc.all_keys):,} unique PC assets across "
          f"{len(pc.by_path):,} blocks ({time.time() - t0:.1f}s)")

    print(f"[2/3] Reading Xbox BE WAD: {args.xbox_wad}")
    xfh = open(args.xbox_wad, "rb")
    _XBOX_MM = mmap.mmap(xfh.fileno(), 0, access=mmap.ACCESS_READ)
    if _XBOX_MM[:4] != SCFF_MAGIC:
        print(f"ERROR: {args.xbox_wad} is not a BE FFCS (SCFF) WAD "
              f"(got {bytes(_XBOX_MM[:4])!r})", file=sys.stderr)
        return 2
    _version, rows = parse_be_ffcs(_XBOX_MM)
    indx_row = next((r for r in rows if r.tag == "INDX"), None)
    pths_row = next((r for r in rows if r.tag == "PTHS"), None)
    if indx_row is None:
        print("ERROR: Xbox WAD missing INDX chunk", file=sys.stderr)
        return 2
    num_blocks = indx_row.meta
    indx_entries = parse_be_indx(_XBOX_MM, indx_row.offset, num_blocks)
    paths = parse_be_pths(_XBOX_MM, pths_row.offset, pths_row.meta) if pths_row else []
    print(f"      {num_blocks:,} Xbox blocks")

    end_block = min(num_blocks, (args.max_blocks or num_blocks))
    keep_raw = extract_dir is not None
    tasks: list[tuple[int, int, int, str, bool]] = []
    for blk_idx in range(end_block):
        indx = indx_entries[blk_idx]
        path = paths[blk_idx] if blk_idx < len(paths) else f"block_{blk_idx:05d}"
        tasks.append((blk_idx, indx.file_offset, indx.page_count * PAGE_SIZE, path, keep_raw))

    by_type: dict[int, dict[str, int]] = defaultdict(lambda: defaultdict(int))
    totals: dict[str, int] = defaultdict(int)
    mismatch_samples: list[dict] = []
    xbox_keys: set[Key] = set()
    xbox_key_path: dict[Key, str] = {}
    xbox_block_paths: set[str] = set()
    unique_status: dict[Key, str] = {}  # match > mismatch
    skipped_blocks: list[dict] = []

    print(f"[3/3] Converting + diffing {len(tasks):,} blocks per block-path "
          f"(converter={_CONVERTER}, jobs={args.jobs})")

    def handle(res: BlockResult) -> None:
        pnorm = _norm(res.path)
        xbox_block_paths.add(pnorm)
        if res.skipped:
            skipped_blocks.append({"block": res.blk_idx, "path": res.path,
                                   "reason": res.reason})
            totals["skipped_blocks"] += 1
            return
        pcblk = pc.by_path.get(pnorm)
        for key, conv in res.converted.items():
            h, th = key
            xbox_keys.add(key)
            xbox_key_path.setdefault(key, pnorm)
            if type_filter is not None and th != type_filter:
                continue
            if pcblk is None or key not in pcblk:
                by_type[th]["unpaired"] += 1
                totals["unpaired"] += 1
                continue
            totals["compared"] += 1
            pc_sha, pc_plen = pcblk[key]
            conv_payload = _entry_payload(conv)
            if _sha1(conv_payload) == pc_sha:
                by_type[th]["match"] += 1
                totals["match"] += 1
                unique_status[key] = "match"
            else:
                by_type[th]["mismatch"] += 1
                totals["mismatch"] += 1
                unique_status.setdefault(key, "mismatch")
                if len(conv_payload) == pc_plen:
                    by_type[th]["mismatch_size_eq"] += 1
                    totals["mismatch_size_eq"] += 1
                else:
                    by_type[th]["mismatch_size_diff"] += 1
                    totals["mismatch_size_diff"] += 1
                if len(mismatch_samples) < 60:
                    pc_bytes = pc.entry_bytes(pnorm, key)
                    diff = _diff_bytes(conv, pc_bytes) if (args.show_diffs and pc_bytes) else []
                    mismatch_samples.append({
                        "asset_hash": f"0x{h:08X}", "type_hash": f"0x{th:08X}",
                        "type": type_name(th), "block": res.path,
                        "converted_len": len(conv),
                        "pc_len": len(pc_bytes) if pc_bytes else None,
                        "diff": diff,
                    })
            if extract_dir is not None:
                _extract_entry(extract_dir, pnorm, key, res.raw_be.get(key),
                               conv, pc)

    if args.jobs > 1 and _CONVERTER == "rust":
        with ThreadPoolExecutor(max_workers=args.jobs) as ex:
            for i, res in enumerate(ex.map(_process_block, tasks)):
                handle(res)
                if (i + 1) % 1000 == 0:
                    print(f"      ... {i + 1:,}/{len(tasks):,} blocks")
    else:
        for i, task in enumerate(tasks):
            handle(_process_block(task))
            if (i + 1) % 1000 == 0:
                print(f"      ... {i + 1:,}/{len(tasks):,} blocks")

    # Global asset-level set differences (any block).
    pc_keys = set(pc.all_keys)
    if type_filter is not None:
        pc_keys = {k for k in pc_keys if k[1] == type_filter}
        xbox_keys = {k for k in xbox_keys if k[1] == type_filter}
    pc_only = pc_keys - xbox_keys
    xbox_only = xbox_keys - pc_keys
    for (_h, th) in pc_only:
        by_type[th]["pc_only"] += 1
    for (_h, th) in xbox_only:
        by_type[th]["xbox_only"] += 1
    totals["pc_only"] = len(pc_only)
    totals["xbox_only"] = len(xbox_only)

    # Unique-asset match rate (an asset that matched in any aligned block).
    totals["unique_match"] = sum(1 for v in unique_status.values() if v == "match")
    totals["unique_mismatch"] = sum(1 for v in unique_status.values() if v == "mismatch")

    pc_block_paths = set(pc.by_path)
    _write_artifacts(out_dir, args, totals, by_type, mismatch_samples,
                     skipped_blocks, pc_only, xbox_only, pc.key_path,
                     xbox_key_path, pc_block_paths, xbox_block_paths,
                     len(pc_keys), len(xbox_keys))
    _print_summary(totals, by_type, len(tasks), time.time() - t0)

    pc.close()
    _XBOX_MM.close()
    xfh.close()
    return 1 if totals["mismatch"] else 0


def _extract_entry(extract_dir: Path, pnorm: str, key: Key,
                   raw_be: bytes | None, conv: bytes, pc: PcIndex) -> None:
    h, th = key
    stem = f"{h:08X}_{th:08X}"
    sub = _safe_name(pnorm)
    le_dir = extract_dir / "xbox_le" / sub
    le_dir.mkdir(parents=True, exist_ok=True)
    (le_dir / f"{stem}.bin").write_bytes(conv)
    if raw_be:
        be_dir = extract_dir / "xbox_be" / sub
        be_dir.mkdir(parents=True, exist_ok=True)
        (be_dir / f"{stem}.bin").write_bytes(raw_be)
    pc_bytes = pc.entry_bytes(pnorm, key)
    if pc_bytes is not None:
        pc_d = extract_dir / "pc" / sub
        pc_d.mkdir(parents=True, exist_ok=True)
        (pc_d / f"{stem}.bin").write_bytes(pc_bytes)


def _write_artifacts(out_dir, args, totals, by_type, mismatch_samples,
                     skipped_blocks, pc_only, xbox_only, pc_key_path,
                     xbox_key_path, pc_block_paths, xbox_block_paths,
                     n_pc_keys, n_xbox_keys) -> None:
    by_type_rows = []
    for th in sorted(by_type, key=lambda t: sum(by_type[t].values()), reverse=True):
        c = by_type[th]
        by_type_rows.append({
            "type_hash": f"0x{th:08X}", "type": type_name(th),
            "match": c["match"], "mismatch": c["mismatch"],
            "mismatch_size_eq": c["mismatch_size_eq"],
            "mismatch_size_diff": c["mismatch_size_diff"],
            "unpaired": c["unpaired"], "pc_only": c["pc_only"],
            "xbox_only": c["xbox_only"],
        })

    report = {
        "xbox_wad": str(args.xbox_wad), "pc_wad": str(args.pc_wad),
        "converter": _CONVERTER, "type_filter": args.type or None,
        "totals": dict(totals),
        "pc_unique_assets": n_pc_keys, "xbox_unique_assets": n_xbox_keys,
        "pc_blocks": len(pc_block_paths), "xbox_blocks": len(xbox_block_paths),
        "common_blocks": len(pc_block_paths & xbox_block_paths),
        "by_type": by_type_rows,
        "mismatch_samples": mismatch_samples,
        "skipped_blocks": skipped_blocks[:100],
        "skipped_block_count": len(skipped_blocks),
    }
    (out_dir / "rosetta_oracle_report.json").write_text(
        json.dumps(report, indent=2), encoding="utf-8")

    def inventory(keys, path_map) -> dict:
        by_t: dict[str, int] = defaultdict(int)
        assets = []
        for (h, th) in sorted(keys):
            by_t[type_name(th)] += 1
            assets.append({"asset_hash": f"0x{h:08X}", "type_hash": f"0x{th:08X}",
                           "type": type_name(th), "block_path": path_map.get((h, th))})
        return {"count": len(keys),
                "by_type": dict(sorted(by_t.items(), key=lambda kv: -kv[1])),
                "assets": assets}

    (out_dir / "pc_only_assets.json").write_text(
        json.dumps(inventory(pc_only, pc_key_path), indent=2), encoding="utf-8")
    (out_dir / "xbox_only_assets.json").write_text(
        json.dumps(inventory(xbox_only, xbox_key_path), indent=2), encoding="utf-8")

    pc_only_blocks = sorted(pc_block_paths - xbox_block_paths)
    xbox_only_blocks = sorted(xbox_block_paths - pc_block_paths)
    (out_dir / "pc_only_blocks.json").write_text(
        json.dumps({"pc_only_block_count": len(pc_only_blocks),
                    "pc_only_blocks": pc_only_blocks,
                    "xbox_only_block_count": len(xbox_only_blocks),
                    "xbox_only_blocks": xbox_only_blocks}, indent=2),
        encoding="utf-8")


def _print_summary(totals, by_type, n_blocks, elapsed) -> None:
    print("\n" + "=" * 78)
    print("ROSETTA ORACLE -- base-game BE->LE conversion vs PC ground truth")
    print("=" * 78)
    print(f"  blocks processed     : {n_blocks:,}  ({elapsed:.1f}s)")
    print(f"  asset instances cmp  : {totals['compared']:,}")
    print(f"    MATCH              : {totals['match']:,}")
    print(f"    MISMATCH           : {totals['mismatch']:,}")
    print(f"  unique assets MATCH  : {totals['unique_match']:,}")
    print(f"  unique assets MISMTCH: {totals['unique_mismatch']:,}")
    print(f"  unpaired (in-block)  : {totals['unpaired']:,}")
    print(f"  PC-ONLY assets       : {totals['pc_only']:,}")
    print(f"  XBOX-ONLY assets     : {totals['xbox_only']:,}")
    if totals.get("skipped_blocks"):
        print(f"  skipped blocks       : {totals['skipped_blocks']:,}")
    print("\n  by type (asset instances)   [mm=size-equal | size-diff]:")
    print(f"    {'type':<18} {'MATCH':>7} {'MM=':>7} {'MM!=':>7} {'UNPAIR':>7} "
          f"{'PC-ONLY':>8} {'XB-ONLY':>8}")
    print(f"    {'-' * 18} {'-' * 7} {'-' * 7} {'-' * 7} {'-' * 7} {'-' * 8} {'-' * 8}")
    for th in sorted(by_type, key=lambda t: sum(by_type[t].values()), reverse=True):
        c = by_type[th]
        # size-equal mismatches => likely small converter bug; size-diff => re-encode
        flag = "  <<< re-encode" if c["mismatch_size_diff"] > c["mismatch_size_eq"] \
            else ("  <- conv-bug?" if c["mismatch"] else "")
        print(f"    {type_name(th):<18} {c['match']:>7} {c['mismatch_size_eq']:>7} "
              f"{c['mismatch_size_diff']:>7} {c['unpaired']:>7} {c['pc_only']:>8} "
              f"{c['xbox_only']:>8}{flag}")
    print("=" * 78)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--xbox-wad", type=Path, default=DEFAULT_XBOX_WAD)
    ap.add_argument("--pc-wad", type=Path, default=DEFAULT_PC_WAD)
    ap.add_argument("--converter", choices=("rust",), default="rust",
                    help="(Python converter retired; rust only)")
    ap.add_argument("--type", default=None,
                    help="restrict comparison/extract to one type_hash (0xF011157A)")
    ap.add_argument("--jobs", type=int, default=1,
                    help="parallel block workers (rust converter only)")
    ap.add_argument("--extract-dir", default=None,
                    help="materialize mirrored per-entry trees pc/ xbox_le/ xbox_be/")
    ap.add_argument("--show-diffs", action="store_true")
    ap.add_argument("--max-blocks", type=int, default=None)
    ap.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    args = ap.parse_args()

    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    if not args.xbox_wad.exists():
        print(f"ERROR: {args.xbox_wad} not found", file=sys.stderr)
        return 2
    if not args.pc_wad.exists():
        print(f"ERROR: {args.pc_wad} not found", file=sys.stderr)
        return 2
    return run_oracle(args)


if __name__ == "__main__":
    sys.exit(main())
