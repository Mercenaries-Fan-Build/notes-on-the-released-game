#!/usr/bin/env python3
"""Verify patch WAD integrity: sges round-trip, chunk_size table, INDX packed_field, FFCS readback.

Consolidates verification gaps for DLC port / vz-patch.wad:

  1. sges compress → decompress round-trip on LE block data (dlc_port path)
  2. Per-entry chunk_size vs measured UCFX+CSUM container length
  3. INDX packed_field semantics (retail PC vs patch; correlation with sizes)
  4. End-to-end FFCS readback (INDX page offsets, UCFX magic, CSUM trailers)
  5. Documents single-block patch workflow (ffcs_patch_wad / build_patch_wad)

Usage:
  .venv/bin/python3 tools/verify_patch_wad_integrity.py
  .venv/bin/python3 tools/verify_patch_wad_integrity.py --patch-wad output/data/vz-patch.wad
  .venv/bin/python3 tools/verify_patch_wad_integrity.py --retail-wad game-files/vz.wad --retail-sample 200
"""
from __future__ import annotations

import argparse
import mmap
import random
import struct
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

PAGE_SIZE = 0x8000

THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent
sys.path.insert(0, str(THIS_DIR))

from ffcs_patch_wad import PTHS_TRAILER, read_patch_wad  # noqa: E402
from ffcs_wad import parse_ffcs  # noqa: E402
from sges_compress import compress_sges  # noqa: E402
from sges_decompress import decompress_sges_block, parse_sges_header  # noqa: E402
from ucfx_be_to_le import crc32_mercs2  # noqa: E402
from wad_patcher import get_block_boundaries, parse_block_entries  # noqa: E402

DEFAULT_PATCH_CANDIDATES = [
    REPO_ROOT / "output" / "data" / "vz-patch.wad",
    REPO_ROOT / "output" / "vz-patch.wad",
    REPO_ROOT / "game-files" / "vz-patch.wad",
    Path(r"c:\Users\Shadow\Desktop\Mercenaries 2 World in Flames\data\vz-patch.wad"),
]

DEFAULT_RETAIL = REPO_ROOT / "game-files" / "vz.wad"


@dataclass
class CheckResult:
    name: str
    passed: int = 0
    failed: int = 0
    skipped: int = 0
    failures: list[str] = field(default_factory=list)

    def fail(self, msg: str, limit: int = 25) -> None:
        self.failed += 1
        if len(self.failures) < limit:
            self.failures.append(msg)

    def ok(self, n: int = 1) -> None:
        self.passed += n

    def skip(self, n: int = 1) -> None:
        self.skipped += n


def find_patch_wad(explicit: Path | None) -> Path | None:
    if explicit is not None:
        return explicit if explicit.is_file() else None
    for p in DEFAULT_PATCH_CANDIDATES:
        if p.is_file():
            return p
    return None


def parse_ffcs_chunks(raw: bytes) -> dict[str, tuple[int, int]]:
    if raw[:4] != b"FFCS":
        raise ValueError("Not FFCS")
    chunks: dict[str, tuple[int, int]] = {}
    for i in range(5):
        off = 0x0C + i * 12
        tag = raw[off : off + 4].decode("ascii", errors="replace").strip("\x00")
        offset, meta = struct.unpack_from("<II", raw, off + 4)
        if tag:
            chunks[tag] = (offset, meta)
    return chunks


def parse_indx_list(raw: bytes, indx_off: int, count: int) -> list[tuple[int, int, int, int, int]]:
    """Return (page_idx, packed, flags, pages, file_offset) per block."""
    out: list[tuple[int, int, int, int, int]] = []
    for i in range(count):
        off = indx_off + i * 12
        page_idx, packed, flags_pages = struct.unpack_from("<III", raw, off)
        flags = (flags_pages >> 16) & 0xFFFF
        pages = flags_pages & 0xFFFF
        out.append((page_idx, packed, flags, pages, page_idx * PAGE_SIZE))
    return out


def trim_sges_blob(raw: bytes, file_offset: int, max_bytes: int) -> tuple[bytes, int]:
    """Return compressed blob bounded by sges total_c (within page allocation)."""
    region = raw[file_offset : file_offset + max_bytes]
    if len(region) < 16 or region[:4] != b"sges":
        return region, len(region)
    _maj, seg_count = struct.unpack_from("<HH", region, 4)
    _tu, total_c = struct.unpack_from("<II", region, 8)
    use = min(len(region), max(16, total_c))
    return region[:use], use


def decompress_block_at(raw: bytes, file_offset: int, max_bytes: int) -> tuple[bytes, dict]:
    blob, used = trim_sges_blob(raw, file_offset, max_bytes)
    if blob[:4] != b"sges":
        raise ValueError(f"no sges at 0x{file_offset:X}: magic={blob[:4]!r}")
    decomp = decompress_sges_block(blob, 0, len(blob))
    _maj, seg_count = struct.unpack_from("<HH", blob, 4)
    total_u, total_c = struct.unpack_from("<II", blob, 8)
    return decomp, {
        "compressed_bytes": used,
        "total_u": total_u,
        "total_c": total_c,
        "segments": seg_count,
    }


def verify_chunk_sizes_for_block(
    decompressed: bytes,
    *,
    block_label: str,
    result: CheckResult,
) -> None:
    """Each header chunk_size must equal the contiguous UCFX+CSUM span."""
    if len(decompressed) < 4:
        result.fail(f"{block_label}: decompressed block too short")
        return

    try:
        entries = parse_block_entries(decompressed)
    except ValueError as e:
        result.fail(f"{block_label}: entry table parse error: {e}")
        return

    pos = 4 + len(entries) * 16
    for ent in entries:
        declared = ent["size"]
        start = ent["offset"]
        if start != pos:
            result.fail(
                f"{block_label} entry[{ent['index']}]: gap/overlap "
                f"(cursor=0x{pos:X} entry_offset=0x{start:X})"
            )
            pos = start

        if pos + declared > len(decompressed):
            result.fail(
                f"{block_label} entry[{ent['index']}]: chunk_size={declared} "
                f"extends past block end (pos=0x{pos:X}, len={len(decompressed)})"
            )
            break

        chunk = decompressed[pos : pos + declared]
        measured = len(chunk)
        if measured != declared:
            result.fail(
                f"{block_label} entry[{ent['index']}]: "
                f"declared chunk_size={declared} measured={measured}"
            )
        else:
            result.ok()

        if chunk[:4] != b"UCFX":
            result.fail(
                f"{block_label} entry[{ent['index']}]: missing UCFX "
                f"(magic={chunk[:4]!r})"
            )
        elif declared >= 16 and chunk[-8:-4] != b"CSUM":
            result.fail(
                f"{block_label} entry[{ent['index']}]: missing CSUM trailer "
                f"(tag={chunk[-8:-4]!r})"
            )
        elif declared >= 16 and chunk[-8:-4] == b"CSUM":
            stored = struct.unpack_from("<I", chunk, declared - 4)[0]
            expect = crc32_mercs2(chunk[:-8])
            if stored != expect:
                result.fail(
                    f"{block_label} entry[{ent['index']}]: CSUM mismatch "
                    f"stored=0x{stored:08X} expect=0x{expect:08X}"
                )
            else:
                result.ok()

        pos += declared

    trailing = len(decompressed) - pos
    if trailing > 16:
        result.fail(
            f"{block_label}: {trailing} unexpected trailing bytes after chunks"
        )


def check_sges_roundtrip(
    decompressed: bytes,
    *,
    block_label: str,
    result: CheckResult,
) -> None:
    try:
        compressed = compress_sges(decompressed, segment_size=65536, level=6, major=4)
    except Exception as e:
        result.fail(f"{block_label}: compress_sges failed: {e}")
        return

    roundtrip = decompress_sges_block(compressed, 0, len(compressed))
    if roundtrip == decompressed:
        result.ok()
    else:
        if len(roundtrip) != len(decompressed):
            result.fail(
                f"{block_label}: round-trip size {len(roundtrip)} != {len(decompressed)}"
            )
        else:
            diffs = sum(1 for a, b in zip(roundtrip, decompressed) if a != b)
            result.fail(f"{block_label}: round-trip {diffs} differing bytes")


def analyze_packed_field_retail(
    wad_path: Path,
    *,
    sample_count: int,
    seed: int,
    result: CheckResult,
) -> dict:
    """Sample retail PC blocks via DATA sges scan."""
    with open(wad_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
    try:
        arch = parse_ffcs(wad_path)
        data_chunk = next(c for c in arch.chunks if c.tag == "DATA")
        boundaries = get_block_boundaries(mm, data_chunk.offset, data_chunk.size)
        indx_raw = wad_path.read_bytes()  # only need INDX — read via mmap slice
        chunks = parse_ffcs_chunks(indx_raw[:0x10000])
        indx_off, indx_count = chunks["INDX"]
        indx = parse_indx_list(indx_raw, indx_off, min(indx_count, len(boundaries)))

        rng = random.Random(seed)
        indices = sorted(
            rng.sample(range(min(len(boundaries), len(indx))), min(sample_count, len(boundaries)))
        )

        tier_counter: Counter[int] = Counter()
        formula_match = 0
        low24_match = 0
        low24_eq_compressed_pages = 0
        mismatch_samples: list[str] = []

        for i in indices:
            page_idx, packed, _flags, pages, _file_off = indx[i]
            s, e = boundaries[i]
            try:
                decomp = decompress_sges_block(mm, s, e)
            except Exception as ex:
                result.fail(f"retail block[{i}]: decompress: {ex}")
                continue

            blob = mm[s:e]
            compr_len = len(blob)
            if blob[:4] == b"sges":
                _maj, _sc = struct.unpack_from("<HH", blob, 4)
                _tu, total_c = struct.unpack_from("<II", blob, 8)
                compr_len = total_c

            tier = (packed >> 24) & 0xFF
            low24 = packed & 0xFFFFFF
            decomp_pages = (len(decomp) + PAGE_SIZE - 1) // PAGE_SIZE
            compr_pages = (compr_len + PAGE_SIZE - 1) // PAGE_SIZE
            tier_counter[tier] += 1

            if packed == ((tier << 24) | decomp_pages):
                formula_match += 1
            elif low24 == decomp_pages:
                low24_match += 1
            elif low24 == compr_pages:
                low24_eq_compressed_pages += 1
                if len(mismatch_samples) < 5:
                    mismatch_samples.append(
                        f"retail[{i}] low24=compr_pages ({compr_pages}) not decomp ({decomp_pages}) "
                        f"packed=0x{packed:08X}"
                    )
            else:
                if len(mismatch_samples) < 8:
                    mismatch_samples.append(
                        f"retail[{i}] packed=0x{packed:08X} tier={tier} low24={low24} "
                        f"decomp_pages={decomp_pages} compr_pages={compr_pages} "
                        f"indx_pages={pages} len_decomp={len(decomp)}"
                    )

        if mismatch_samples and formula_match + low24_match < len(indices) // 2:
            for msg in mismatch_samples[:5]:
                result.fail(f"retail packed_field: {msg}")

        return {
            "label": "retail_pc",
            "blocks_analyzed": len(indices),
            "tier_distribution": dict(tier_counter),
            "match_tier_decomp_pages": formula_match,
            "match_low24_decomp_pages": low24_match,
            "match_low24_compr_pages": low24_eq_compressed_pages,
            "samples": mismatch_samples,
        }
    finally:
        mm.close()


def verify_patch_wad_e2e(
    wad_path: Path,
    *,
    sample_count: int,
    seed: int,
    check_all_chunk_sizes: bool,
    sges_sample: int,
) -> tuple[CheckResult, CheckResult, CheckResult, dict]:
    """FFCS readback + chunk_size + sges round-trip on patch WAD."""
    e2e = CheckResult("e2e_readback")
    chunk_res = CheckResult("chunk_size")
    sges_res = CheckResult("sges_roundtrip")

    raw = wad_path.read_bytes()
    if raw[:4] != b"FFCS":
        e2e.fail("bad FFCS magic")
        return e2e, chunk_res, sges_res, {}

    chunks = parse_ffcs_chunks(raw)
    for tag in ("INDX", "DATA", "CSUM", "ASET", "PTHS"):
        if tag not in chunks:
            e2e.fail(f"missing chunk {tag}")

    indx_off, indx_count = chunks["INDX"]
    indx = parse_indx_list(raw, indx_off, indx_count)

    # PTHS count vs INDX
    pths_off, pths_count = chunks["PTHS"]
    if pths_count != indx_count:
        e2e.fail(f"PTHS count {pths_count} != INDX count {indx_count}")

    # PTHS trailer
    pos = pths_off
    for _ in range(pths_count):
        nul = raw.find(b"\x00", pos)
        if nul < 0:
            break
        pos = nul + 1
    if raw[pos : pos + len(PTHS_TRAILER)] != PTHS_TRAILER:
        e2e.fail("PTHS trailer missing or wrong")
    else:
        e2e.ok()

    # ASET block refs
    aset_off, aset_count = chunks["ASET"]
    bad_aset = 0
    for i in range(aset_count):
        off = aset_off + i * 16
        _u0, _u1, u2, _u3 = struct.unpack_from("<IIII", raw, off)
        blk = (u2 >> 16) & 0xFFFF
        if blk >= indx_count:
            bad_aset += 1
            if bad_aset <= 3:
                e2e.fail(f"ASET[{i}] block_ref={blk} >= {indx_count}")
    if bad_aset == 0:
        e2e.ok()

    # INDX extents + sges total_u vs decompressed length
    for i, (page_idx, packed, flags, pages, file_off) in enumerate(indx):
        if pages == 0:
            continue
        end = file_off + pages * PAGE_SIZE
        if end > len(raw):
            e2e.fail(f"INDX[{i}] extends past EOF (page_idx={page_idx} pages={pages})")
            continue
        if raw[file_off : file_off + 4] != b"sges":
            e2e.fail(f"INDX[{i}] offset 0x{file_off:X} magic={raw[file_off:file_off+4]!r}")
            continue
        e2e.ok()
        try:
            decomp, info = decompress_block_at(raw, file_off, pages * PAGE_SIZE)
        except Exception as e:
            e2e.fail(f"INDX[{i}]: decompress failed: {e}")
            continue
        if len(decomp) != info["total_u"]:
            e2e.fail(
                f"block[{i}]: decompressed {len(decomp):,} != sges total_u {info['total_u']:,} "
                f"({info['segments']} segments)"
            )

    rng = random.Random(seed)
    all_indices = list(range(indx_count))
    sample_indices = (
        all_indices
        if sample_count >= indx_count
        else sorted(rng.sample(all_indices, min(sample_count, indx_count)))
    )

    chunk_indices = all_indices if check_all_chunk_sizes else sample_indices
    sges_indices = (
        all_indices
        if sges_sample >= indx_count
        else sorted(rng.sample(all_indices, min(sges_sample, indx_count)))
    )

    packed_summary: dict = {}

    for i in chunk_indices:
        page_idx, packed, flags, pages, file_off = indx[i]
        label = f"block[{i}]"
        if pages == 0:
            chunk_res.skip()
            continue
        try:
            decomp, _info = decompress_block_at(raw, file_off, pages * PAGE_SIZE)
        except Exception as e:
            chunk_res.fail(f"{label}: {e}")
            continue
        if len(decomp) != _info["total_u"]:
            chunk_res.skip()
            continue
        verify_chunk_sizes_for_block(decomp, block_label=label, result=chunk_res)

    for i in sges_indices:
        page_idx, packed, flags, pages, file_off = indx[i]
        label = f"block[{i}]"
        if pages == 0:
            sges_res.skip()
            continue
        try:
            decomp, _info = decompress_block_at(raw, file_off, pages * PAGE_SIZE)
        except Exception as e:
            sges_res.fail(f"{label}: {e}")
            continue
        check_sges_roundtrip(decomp, block_label=label, result=sges_res)

    # packed_field on patch (all blocks with DATA pages)
    tier_counter: Counter[int] = Counter()
    formula_ok = 0
    mismatch_n = 0
    small_packed = 0  # packed < 0x100 — retail-style scalar, not tier<<24
    mismatch_samples: list[str] = []
    for i, (_pi, packed, _f, pages, file_off) in enumerate(indx):
        if pages == 0:
            continue
        try:
            decomp, info = decompress_block_at(raw, file_off, pages * PAGE_SIZE)
        except Exception:
            continue
        tier = (packed >> 24) & 0xFF
        decomp_pages = (len(decomp) + PAGE_SIZE - 1) // PAGE_SIZE
        tier_counter[tier] += 1
        if packed < 0x100:
            small_packed += 1
        expected = (tier << 24) | decomp_pages
        if packed == expected:
            formula_ok += 1
        else:
            mismatch_n += 1
            if len(mismatch_samples) < 6:
                mismatch_samples.append(
                    f"block[{i}] packed=0x{packed:08X} expect=0x{expected:08X} "
                    f"decomp_pages={decomp_pages} indx_pages={pages} len={len(decomp)}"
                )

    packed_summary = {
        "blocks_with_pages": sum(1 for x in indx if x[3] > 0),
        "formula_match": formula_ok,
        "formula_mismatch": mismatch_n,
        "small_packed_scalar": small_packed,
        "tier_distribution": dict(tier_counter),
        "mismatch_samples": mismatch_samples,
    }

    return e2e, chunk_res, sges_res, packed_summary


def print_single_block_instructions() -> None:
    print(
        """
Single-block patch WAD (manual in-game test)
------------------------------------------
The engine loads ``<disk>-patch.wad`` beside the base WAD (e.g. ``vz-patch.wad`` next to ``vz.wad``).

1. Build one modified block (sges or raw LE block) with metadata from retail::

     python3 tools/build_patch_wad.py \\
       --source-wad game-files/vz.wad \\
       --block-index <N> \\
       --modified-block /path/to/modified.sges \\
       --output game-files/vz-patch.wad

   Use ``--raw`` if ``modified-block`` is decompressed ``*.block.bin`` (auto-compresses via sges_compress).

2. Low-level API (same layout as dlc_port multi-block builder)::

     from pathlib import Path
     from ffcs_patch_wad import PatchBlock, build_patch_wad_single

     wad_bytes = build_patch_wad_single(
         indx_entry={"packed_field": <from analyze-block>, "flags": 0x8000},
         aset_entries=[...],  # from --analyze-block JSON
         pths_string=r"data\\\\blocksets\\\\vz\\\\...\\\\foo.block",
         compressed_block=open("modified.sges","rb").read(),
     )
     Path("vz-patch.wad").write_bytes(wad_bytes)

3. Deploy: copy ``vz-patch.wad`` to the game ``data`` folder beside ``vz.wad``.

4. Verify before launch::

     python3 tools/verify_patch_wad_integrity.py --patch-wad game-files/vz-patch.wad

``build_patch_wad.py --analyze-block`` writes INDX/ASET/PTHS fields needed for step 2.
"""
    )


def print_result(res: CheckResult) -> None:
    status = "PASS" if res.failed == 0 else "FAIL"
    print(
        f"  [{status}] {res.name}: passed={res.passed} failed={res.failed} skipped={res.skipped}"
    )
    for msg in res.failures[:12]:
        print(f"      - {msg}")
    if len(res.failures) > 12:
        print(f"      ... and {len(res.failures) - 12} more")


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify vz-patch.wad integrity (sges, chunk_size, INDX, FFCS)")
    ap.add_argument("--patch-wad", type=Path, default=None, help="Path to vz-patch.wad")
    ap.add_argument("--retail-wad", type=Path, default=DEFAULT_RETAIL, help="Retail PC vz.wad for INDX comparison")
    ap.add_argument("--retail-sample", type=int, default=150, help="Retail blocks to sample for packed_field")
    ap.add_argument("--sample-blocks", type=int, default=40, help="Random patch blocks for deep UCFX/CSUM checks")
    ap.add_argument("--sges-sample", type=int, default=80, help="Patch blocks for sges round-trip")
    ap.add_argument("--all-chunk-sizes", action="store_true", help="Verify chunk_size on every patch block")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--no-retail", action="store_true", help="Skip retail vz.wad comparison")
    args = ap.parse_args()

    patch_path = find_patch_wad(args.patch_wad)
    if patch_path is None:
        print("ERROR: vz-patch.wad not found. Tried:")
        for p in ([args.patch_wad] if args.patch_wad else []) + DEFAULT_PATCH_CANDIDATES:
            if p is not None:
                print(f"  {p}")
        return 1

    print(f"Patch WAD: {patch_path} ({patch_path.stat().st_size:,} bytes)")
    print(f"Retail WAD: {args.retail_wad} ({'present' if args.retail_wad.is_file() else 'missing'})")
    print()

    e2e, chunk_res, sges_res, packed_patch = verify_patch_wad_e2e(
        patch_path,
        sample_count=args.sample_blocks,
        seed=args.seed,
        check_all_chunk_sizes=args.all_chunk_sizes,
        sges_sample=args.sges_sample,
    )

    retail_packed: dict = {}
    retail_res = CheckResult("retail_packed_field")
    if not args.no_retail and args.retail_wad.is_file():
        print(f"Analyzing retail INDX packed_field ({args.retail_sample} samples)...")
        retail_packed = analyze_packed_field_retail(
            args.retail_wad,
            sample_count=args.retail_sample,
            seed=args.seed,
            result=retail_res,
        )

    print()
    print("=" * 70)
    print(" RESULTS")
    print("=" * 70)
    print_result(e2e)
    print_result(chunk_res)
    print_result(sges_res)
    if retail_packed:
        print_result(retail_res)
        print()
        print("  INDX packed_field analysis:")
        print(f"    Patch WAD: formula (tier<<24)|decomp_pages match "
              f"{packed_patch.get('formula_match', 0)}/"
              f"{packed_patch.get('blocks_with_pages', 0)} blocks")
        if packed_patch.get("formula_mismatch"):
            print(f"    Patch mismatches vs dlc_port formula: {packed_patch['formula_mismatch']}")
        print(f"    Patch packed<0x100 (scalar style): {packed_patch.get('small_packed_scalar', 0)}")
        print(f"    Patch tier distribution: {packed_patch.get('tier_distribution', {})}")
        if packed_patch.get("mismatch_samples"):
            print("    Patch mismatch examples:")
            for s in packed_patch["mismatch_samples"]:
                print(f"      - {s}")
        print(f"    Retail sample ({retail_packed.get('blocks_analyzed', 0)} blocks):")
        print(f"      tier<<24|decomp_pages: {retail_packed.get('match_tier_decomp_pages', 0)}")
        print(f"      low24==decomp_pages only: {retail_packed.get('match_low24_decomp_pages', 0)}")
        print(f"      low24==compressed_pages: {retail_packed.get('match_low24_compr_pages', 0)}")
        if retail_packed.get("samples"):
            print("    Retail sample notes (first few):")
            for s in retail_packed["samples"][:5]:
                print(f"      - {s}")

    print()
    print("  packed_field encoding (verified from dlc_port.py + patch readback):")
    print("    packed_field = (tier << 24) | ceil(decompressed_size / 0x8000)")
    print("    tier = byte at bits 24-31 (often 0 or 1 on patch blocks)")
    print("    INDX flags<<16 | page_count = compressed allocation in 32KB pages")
    print("    Retail PC may use low 24 bits differently on some blocks — see retail sample.")

    print_single_block_instructions()

    total_fail = e2e.failed + chunk_res.failed + sges_res.failed + retail_res.failed
    print()
    if total_fail:
        print(f"OVERALL: FAIL ({total_fail} failed checks)")
        return 1
    print("OVERALL: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
