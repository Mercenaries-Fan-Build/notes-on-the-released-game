#!/usr/bin/env python3
"""Solve the Xbox 360 -> PC texture transform against the Rosetta corpus.

Uses the base-game ground truth: every PC texture in ``vz.wad`` has an Xbox
counterpart in ``xbox-vz.wad`` keyed by ``asset_hash``.  Textures are
content-addressed (same hash => same image), so we pair **globally** by hash
(block reorganisation between platforms is irrelevant here).

The production converter passes texture INFO format bytes [14:22] and the DXT
BODY through unchanged (only re-framing the container as LE), so the
*converted* LE entry still carries the raw Xbox GPU format word + GPU-tiled
DXT body.  We therefore analyse everything with the LE chunk parser:

  phase `info`  derive the Xbox GPU format word -> PC FourCC mapping and verify
                the INFO field layout (width/height/mips/total_size) against PC.
  phase `body`  dump a size-stratified sample of (xbox BODY, pc BODY) pairs for
                the untile solver, and report the per-format body-size relation.

Usage:
    python tools/xbox_texture_solver.py info  --jobs 8
    python tools/xbox_texture_solver.py body  --jobs 8 --sample 40 \
        --dump output/_scratch/tex_body_pairs
"""
from __future__ import annotations

import argparse
import json
import mmap
import struct
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import wad_be_le_oracle as ora  # noqa: E402
from sges_decompress import decompress_sges_block  # noqa: E402
from wad_patcher import (  # noqa: E402
    find_data_chunk,
    get_block_boundaries,
    parse_block_entries,
)
from x360_dlc_io import (  # noqa: E402
    PAGE_SIZE,
    SCFF_MAGIC,
    parse_be_ffcs,
    parse_be_indx,
)

TEXTURE_TYPE = 0xF011157A
DEFAULT_XBOX = Path("game-files/xbox-vz.wad")
DEFAULT_PC = Path("game-files/vz.wad")
DEFAULT_OUT = Path("output/_scratch")


def le_u32(b: bytes, off: int) -> int:
    return struct.unpack_from("<I", b, off)[0]


def le_chunks(entry: bytes) -> dict[bytes, tuple[int, int]]:
    """Return {tag: (payload_start, payload_len)} for an LE UCFX entry."""
    if len(entry) < 20 or entry[:4] != b"UCFX":
        return {}
    data_base = le_u32(entry, 4)
    n = le_u32(entry, 16)
    out: dict[bytes, tuple[int, int]] = {}
    for ci in range(min(n, 32)):
        cpos = 20 + ci * 20
        if cpos + 20 > len(entry):
            break
        tag = entry[cpos:cpos + 4]
        cu0 = le_u32(entry, cpos + 4)
        cu1 = le_u32(entry, cpos + 8)
        start = data_base + cu0
        if 0 <= start <= len(entry):
            out[tag] = (start, cu1)
    return out


def chunk_payload(entry: bytes, tag: bytes) -> bytes | None:
    loc = le_chunks(entry).get(tag)
    if loc is None:
        return None
    start, ln = loc
    return entry[start:start + ln]


# -- corpus walkers ----------------------------------------------------

def walk_pc_textures(pc_wad: Path):
    """Yield (asset_hash, pc_entry_bytes) for every PC texture (first wins)."""
    dc = find_data_chunk(pc_wad)
    seen: set[int] = set()
    with open(pc_wad, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        for s, e in get_block_boundaries(mm, dc.offset, dc.size):
            try:
                data = decompress_sges_block(mm, s, e)
                entries = parse_block_entries(data)
            except Exception:
                continue
            for ent in entries:
                if ent["type_hash"] != TEXTURE_TYPE:
                    continue
                h = ent["hash"]
                if h in seen:
                    continue
                seen.add(h)
                yield h, data[ent["offset"]:ent["offset"] + ent["size"]]
        mm.close()


def walk_xbox_textures(xbox_wad: Path, jobs: int):
    """Yield (asset_hash, converted_le_entry_bytes) for every Xbox texture."""
    xfh = open(xbox_wad, "rb")
    ora._XBOX_MM = mmap.mmap(xfh.fileno(), 0, access=mmap.ACCESS_READ)
    ora._CONVERTER = "rust"
    if ora._XBOX_MM[:4] != SCFF_MAGIC:
        raise SystemExit("xbox wad is not SCFF")
    _v, rows = parse_be_ffcs(ora._XBOX_MM)
    indx_row = next(r for r in rows if r.tag == "INDX")
    indx = parse_be_indx(ora._XBOX_MM, indx_row.offset, indx_row.meta)
    tasks = [(i, e.file_offset, e.page_count * PAGE_SIZE, "", False)
             for i, e in enumerate(indx)]
    seen: set[int] = set()
    from concurrent.futures import ThreadPoolExecutor
    with ThreadPoolExecutor(max_workers=jobs) as ex:
        for res in ex.map(ora._process_block, tasks):
            for (h, th), conv in res.converted.items():
                if th != TEXTURE_TYPE or h in seen:
                    continue
                seen.add(h)
                yield h, conv
    ora._XBOX_MM.close()
    xfh.close()


# -- phase: INFO -------------------------------------------------------

def phase_info(args) -> int:
    print("[info] indexing PC texture INFO ...")
    pc_info: dict[int, bytes] = {}
    for h, entry in walk_pc_textures(args.pc_wad):
        info = chunk_payload(entry, b"INFO")
        if info:
            pc_info[h] = info
    print(f"       {len(pc_info):,} PC textures")

    print("[info] converting + indexing Xbox texture INFO ...")
    xb_info: dict[int, bytes] = {}
    for h, conv in walk_xbox_textures(args.xbox_wad, args.jobs):
        info = chunk_payload(conv, b"INFO")
        if info:
            xb_info[h] = info
    print(f"       {len(xb_info):,} Xbox textures")

    common = sorted(set(pc_info) & set(xb_info))
    print(f"[info] paired textures: {len(common):,}")

    fmt_map: Counter = Counter()        # (xbox fmt region hex) -> count
    fmt_to_fourcc: dict[str, Counter] = defaultdict(Counter)
    field_mismatch: Counter = Counter()
    samples: list[dict] = []
    for h in common:
        xi, pi = xb_info[h], pc_info[h]
        if len(xi) < 22 or len(pi) < 18:
            continue
        pc_fourcc = bytes(pi[14:18])
        xb_fmt = bytes(xi[14:22])
        fmt_map[xb_fmt.hex()] += 1
        fmt_to_fourcc[xb_fmt.hex()][pc_fourcc.decode("latin1")] += 1
        # Verify field layout: width/height/mips against PC.
        xw, xh = struct.unpack_from("<HH", xi, 0)
        pw, ph = struct.unpack_from("<HH", pi, 0)
        if (xw, xh) != (pw, ph):
            field_mismatch["wh"] += 1
        if len(samples) < 12:
            samples.append({
                "hash": f"0x{h:08X}",
                "xbox_info": xi.hex(), "pc_info": pi.hex(),
                "pc_fourcc": pc_fourcc.decode("latin1"),
                "xbox_wh": [xw, xh], "pc_wh": [pw, ph],
            })

    print("\n  Xbox INFO[14:22] format region  ->  PC FourCC")
    print("  " + "-" * 60)
    for fmt_hex, n in fmt_map.most_common():
        fcc = dict(fmt_to_fourcc[fmt_hex])
        print(f"  {fmt_hex:<20} x{n:<6} -> {fcc}")
    print(f"\n  width/height field mismatches: {field_mismatch['wh']:,} "
          f"/ {len(common):,}")

    out = {
        "paired": len(common),
        "format_region_map": {k: dict(fmt_to_fourcc[k]) for k in fmt_map},
        "format_region_counts": dict(fmt_map),
        "wh_field_mismatches": field_mismatch["wh"],
        "samples": samples,
    }
    args.out_dir.mkdir(parents=True, exist_ok=True)
    (args.out_dir / "texture_info_map.json").write_text(
        json.dumps(out, indent=2), encoding="utf-8")
    print(f"\n  wrote {args.out_dir / 'texture_info_map.json'}")
    return 0


# -- phase: BODY -------------------------------------------------------

def phase_body(args) -> int:
    # 1) Sample Xbox textures first (bounded), classed by format byte + size.
    print("[body] converting + sampling Xbox textures ...")
    sample: dict[int, tuple[bytes, bytes]] = {}  # h -> (xbox_info, xbox_body)
    seen_class: Counter = Counter()
    for h, conv in walk_xbox_textures(args.xbox_wad, args.jobs):
        xi = chunk_payload(conv, b"INFO")
        xb = chunk_payload(conv, b"BODY")
        if not xi or not xb or len(xi) < 18:
            continue
        fmt_byte = xi[17]
        w, hh = struct.unpack_from("<HH", xi, 0)
        cls = (fmt_byte, 1 << max(0, max(w, hh).bit_length() - 1))
        if seen_class[cls] >= args.per_class:
            continue
        seen_class[cls] += 1
        sample[h] = (xi, xb)
        if len(sample) >= args.sample:
            break
    print(f"       sampled {len(sample)} Xbox textures")

    # 2) Fetch only the sampled hashes from PC (bounded memory).
    print("[body] fetching matching PC bodies ...")
    pairs: list[tuple[int, bytes, bytes, bytes, bytes]] = []
    want = set(sample)
    for h, entry in walk_pc_textures(args.pc_wad):
        if h not in want:
            continue
        pi = chunk_payload(entry, b"INFO")
        pb = chunk_payload(entry, b"BODY")
        if pi and pb:
            xi, xb = sample[h]
            pairs.append((h, xi, xb, pb, pi))
    print(f"       matched {len(pairs)} paired bodies")

    rel: Counter = Counter()
    dump = Path(args.dump) if args.dump else None
    if dump:
        dump.mkdir(parents=True, exist_ok=True)
    manifest: list[dict] = []
    print("\n  hash        fourcc  wxh        mips  xbox_body   pc_body   ratio  full?")
    print("  " + "-" * 72)
    for h, xi, xb, pb, pi in pairs:
        fourcc = bytes(pi[14:18]).decode("latin1")
        w, hh = struct.unpack_from("<HH", pi, 0)
        mips = struct.unpack_from("<H", pi, 6)[0]
        ratio = len(xb) / len(pb) if pb else 0.0
        # A "full" (non-streamed) texture: Xbox body >= PC body and close in
        # size (Xbox only adds tile padding). Streamed stubs have huge ratios.
        full = len(xb) >= len(pb) and ratio <= 1.40
        rel[(fourcc, round(ratio, 3))] += 1
        print(f"  0x{h:08X}  {fourcc:<6} {w:>5}x{hh:<5} {mips:>3}  "
              f"{len(xb):>9} {len(pb):>9}   {ratio:>5.3f}  {'YES' if full else ''}")
        if dump:
            stem = f"{h:08X}_{fourcc}_{w}x{hh}_m{mips}"
            (dump / f"{stem}.xbox_body.bin").write_bytes(xb)
            (dump / f"{stem}.pc_body.bin").write_bytes(pb)
            (dump / f"{stem}.pc_info.bin").write_bytes(pi)
            manifest.append({"hash": f"0x{h:08X}", "fourcc": fourcc,
                             "w": w, "h": hh, "mips": mips,
                             "xbox_len": len(xb), "pc_len": len(pb),
                             "ratio": round(ratio, 4), "full": full,
                             "stem": stem})
    if dump:
        (dump / "manifest.json").write_text(json.dumps(manifest, indent=2),
                                            encoding="utf-8")
    print("\n  body-size ratios (fourcc, xbox/pc):", dict(rel))
    print(f"  full (non-streamed) pairs: {sum(1 for m in manifest if m['full'])}")
    return 0


def phase_validate(args) -> int:
    """Validate the untile codec against the dumped corpus (top mip).

    Metadata is read from the dumped ``*.pc_info.bin`` (ground truth), so no
    manifest is required.
    """
    import xbox_texture_codec as codec
    dump = Path(args.dump)
    fmt = {b"DXT1": (8, 3), b"DXT5": (16, 4), b"DXT3": (16, 4)}
    print(f"  {'hash':<12}{'fourcc':<7}{'wxh':<12}{'swap':<6}"
          f"{'top_match%':<11}{'first_diff'}")
    print("  " + "-" * 64)
    ok = tested = 0
    for info_path in sorted(dump.glob("*.pc_info.bin")):
        stem = info_path.name[:-len(".pc_info.bin")]
        pi = info_path.read_bytes()
        if len(pi) < 18:
            continue
        fourcc = bytes(pi[14:18])
        if fourcc not in fmt:
            continue
        w, h = struct.unpack_from("<HH", pi, 0)
        xb = (dump / f"{stem}.xbox_body.bin").read_bytes()
        pb = (dump / f"{stem}.pc_body.bin").read_bytes()
        texel_pitch, log_bpb = fmt[fourcc]
        wb, hb = max(1, (w + 3) // 4), max(1, (h + 3) // 4)
        if len(xb) < len(pb) or (len(xb) / max(1, len(pb))) > 1.40:
            continue  # streamed stub, not a full surface
        awb, ahb = (wb + 31) & ~31, (hb + 31) & ~31
        top_tiled = awb * ahb * texel_pitch
        pc_top = pb[:wb * hb * texel_pitch]
        for swap in (True, False):
            linear, awb2, _ahb2, wb2, hb2, tp = codec.convert_dxt_mip(
                xb[:top_tiled], w, h, fourcc, swap=swap)
            cand = codec.crop_blocks(linear, awb2, wb2, hb2, tp)
            n = min(len(cand), len(pc_top))
            same = sum(1 for k in range(n) if cand[k] == pc_top[k])
            pct = 100.0 * same / n if n else 0.0
            first = next((k for k in range(n) if cand[k] != pc_top[k]), -1)
            if swap:
                tested += 1
                ok += 1 if pct > 99.9 else 0
            print(f"  0x{stem[:8]:<10}{fourcc.decode():<7}{w}x{h:<8}"
                  f"{str(swap):<6}{pct:<11.2f}{first}")
    print(f"\n  top-mip exact (swap=True): {ok}/{tested}")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="phase", required=True)
    for name in ("info", "body"):
        p = sub.add_parser(name)
        p.add_argument("--xbox-wad", type=Path, default=DEFAULT_XBOX)
        p.add_argument("--pc-wad", type=Path, default=DEFAULT_PC)
        p.add_argument("--jobs", type=int, default=8)
        p.add_argument("--out-dir", type=Path, default=DEFAULT_OUT)
        if name == "body":
            p.add_argument("--sample", type=int, default=40)
            p.add_argument("--per-class", type=int, default=3)
            p.add_argument("--dump", default=None)
    pv = sub.add_parser("validate")
    pv.add_argument("--dump", required=True,
                    help="corpus dir produced by `body --dump`")
    args = ap.parse_args()
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    if args.phase == "info":
        return phase_info(args)
    if args.phase == "validate":
        return phase_validate(args)
    return phase_body(args)


if __name__ == "__main__":
    sys.exit(main())
