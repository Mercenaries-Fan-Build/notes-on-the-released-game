#!/usr/bin/env python3
"""PS3 VZ.WAD header cryptanalysis — brute-force and known-plaintext attacks.

The PS3 retail VZ.WAD wraps big-endian ``segs`` DATA at file offset 0x80800.
The preceding 0x80800 bytes (16 × 32 KiB FFCS pages + 0x800 byte gap) are an
encrypted/obfuscated metadata envelope — no FFCS/SCFF magic, ~7.9 bits/byte entropy.

This tool applies late-2000s reverse-engineering tactics:
  1. Structural alignment (16-page metadata + DATA bias)
  2. Transform battery (XOR / zlib / AES-with-title-keys / segs-at-zero)
  3. Known-plaintext from SCFF header template
  4. INDX reconstruction from cleartext ``segs`` block walk (stream-cipher probe)
  5. Full-file segs catalog + content fingerprinting (bypass path)

Usage:
  .venv/bin/python3 tools/ps3_wad_header_crack.py \\
    --ps3-wad analysis/cross_platform/wads/ps3/VZ.WAD \\
    --output analysis/cross_platform/ps3_header_crack
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import sys
import zlib
import zlib as _zlib
from collections import Counter
from dataclasses import dataclass, asdict
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(THIS_DIR))

from dlc_port_x360_to_pc import decompress_be_sges  # noqa: E402

PAGE_SIZE = 0x8000
HDR_SIZE = 0x80800
DATA_OFFSET = 0x80800
SCFF_TEMPLATE = b"SCFF" + struct.pack(">II", 2, 7)
VZ_NAME_HASH = 0xB4420059  # pandemic_hash("vz")


@dataclass
class SegsBlock:
    file_offset: int
    rel_offset: int
    page_index_rel: int
    page_index_abs: int
    page_count: int
    seg_count: int
    decomp_total: int
    comp_total: int


def _entropy(data: bytes) -> float:
    if not data:
        return 0.0
    c = Counter(data)
    n = len(data)
    return -sum((v / n) * math.log2(v / n) for v in c.values())


def _score_scff_header(hdr: bytes) -> int:
    score = 0
    if hdr[:4] in (b"SCFF", b"FFCS"):
        score += 100
    if hdr[4:8] in (struct.pack(">I", 2), struct.pack("<I", 2)):
        score += 40
    if hdr[8:12] in (struct.pack(">I", 7), struct.pack("<I", 7)):
        score += 40
    for i in range(7):
        off = 0x0C + i * 12
        if off + 4 > len(hdr):
            break
        tag = hdr[off : off + 4]
        rev = tag[::-1]
        known = {
            b"INDX", b"DATA", b"ASET", b"PTHS", b"CSUM", b"MUSC",
            b"XDNI", b"ATAD", b"TESA", b"SHTP",
        }
        if tag in known or rev in known:
            score += 20
    if len(hdr) > 0x8004 and hdr[0x8000:0x8004] in (b"INDX", b"XDNI"):
        score += 60
    return score


def _title_aes_keys() -> list[bytes]:
    seeds = [
        b"BLUS30056", b"BCUS30056", b"BLES30110", b"NPUB30057",
        b"MERCENARIES2", b"Mercenaries2", b"WorldInFlames", b"M2WIF",
        b"VZ.WAD", b"vz.wad", b"Pandemic", b"EA", b"SCEA",
        b"UP0006-BLUS30056_00-MERCENARIES200000",
    ]
    keys: list[bytes] = []
    for s in seeds:
        keys.append(s.ljust(16, b"\0")[:16])
        keys.append(hashlib.md5(s).digest())
        keys.append(hashlib.sha1(s).digest()[:16])
        keys.append(hashlib.sha256(s).digest()[:16])
    return keys


def _try_aes_decrypt(sample: bytes, keys: list[bytes]) -> list[dict]:
    try:
        from Crypto.Cipher import AES
    except ImportError:
        return [{"error": "pycryptodome not installed; pip install pycryptodome"}]

    hits: list[dict] = []
    n = len(sample) // 16 * 16
    if n < 16:
        return hits
    block = sample[:n]
    for key in keys:
        for mode_name, pt in (
            ("ECB", AES.new(key, AES.MODE_ECB).decrypt(block)),
            ("CBC_zero", AES.new(key, AES.MODE_CBC, iv=b"\0" * 16).decrypt(block)),
            ("CBC_iv0", AES.new(key, AES.MODE_CBC, iv=sample[:16]).decrypt(sample[16:n])),
        ):
            sc = _score_scff_header(pt)
            if sc >= 100:
                hits.append({
                    "score": sc,
                    "key_hex": key.hex(),
                    "mode": mode_name,
                    "head_hex": pt[:32].hex(),
                    "magic": pt[:4].decode("ascii", errors="replace"),
                })
    return hits


def _transform_battery(hdr: bytes) -> list[dict]:
    """Fast transforms a 2008-era RE would try before reaching for IDA."""
    results: list[dict] = []

    # Single-byte XOR → SCFF
    for k in range(256):
        dec = bytes(b ^ k for b in hdr[:64])
        if dec[:4] == b"SCFF":
            results.append({"transform": "xor1", "key": k, "score": _score_scff_header(dec)})

    # Repeating XOR only counts if key is NOT derived from ciphertext (avoid false +)
    for klen in (4, 8, 16):
        for seed in (b"BLUS30056", b"VZ.WAD", b"Pandemic", b"\x00" * klen):
            key = (seed * ((klen // len(seed)) + 1))[:klen]
            dec = bytes(hdr[i] ^ key[i % klen] for i in range(min(256, len(hdr))))
            sc = _score_scff_header(dec)
            if sc >= 100:
                results.append({
                    "transform": f"xor_repeat_{klen}",
                    "key_hex": key.hex(),
                    "score": sc,
                })

    # zlib (stored/deflate) at common offsets
    for off in (0, 0x10, 0x20, 0x100, 0x800, 0x1000):
        for wbits in (-15, 15, -_zlib.MAX_WBITS):
            try:
                out = zlib.decompress(hdr[off:], wbits)
                if len(out) > 64:
                    sc = _score_scff_header(out)
                    if sc >= 80 or out[:4] in (b"SCFF", b"FFCS"):
                        results.append({
                            "transform": "zlib",
                            "offset": off,
                            "wbits": wbits,
                            "out_len": len(out),
                            "score": sc,
                            "magic": out[:4].decode("ascii", errors="replace"),
                        })
            except Exception:
                pass

    # segs-at-zero (header is one compressed blob)
    try:
        out = decompress_be_sges(hdr, 0, len(hdr))
        sc = _score_scff_header(out)
        results.append({
            "transform": "segs_at_0",
            "out_len": len(out),
            "score": sc,
            "magic": out[:4].decode("ascii", errors="replace"),
        })
    except Exception as e:
        results.append({"transform": "segs_at_0", "error": str(e)})

    # bswap32 first 256 bytes
    sw = bytearray(hdr[:256])
    for i in range(0, len(sw) - 3, 4):
        sw[i : i + 4] = sw[i : i + 4][::-1]
    sc = _score_scff_header(bytes(sw))
    if sc >= 80:
        results.append({"transform": "bswap32_256", "score": sc})

    return sorted(results, key=lambda r: r.get("score", 0), reverse=True)


def walk_segs_blocks(tail: bytes, base: int = DATA_OFFSET) -> list[SegsBlock]:
    blocks: list[SegsBlock] = []
    pos = 0
    while pos < len(tail) - 16:
        if tail[pos : pos + 4] != b"segs":
            pos += 1
            continue
        seg_count = struct.unpack_from(">H", tail, pos + 6)[0]
        decomp_total = struct.unpack_from(">I", tail, pos + 8)[0]
        comp_total = struct.unpack_from(">I", tail, pos + 12)[0]
        if not (
            1 <= seg_count <= 64
            and 100 < decomp_total < 20_000_000
            and 100 < comp_total < 20_000_000
        ):
            pos += 4
            continue
        file_off = base + pos
        rel = pos
        hdr_size = 16 + ((seg_count * 8 + 15) & ~15)
        page_count = (hdr_size + comp_total + PAGE_SIZE - 1) // PAGE_SIZE
        blocks.append(
            SegsBlock(
                file_offset=file_off,
                rel_offset=rel,
                page_index_rel=rel // PAGE_SIZE,
                page_index_abs=file_off // PAGE_SIZE,
                page_count=page_count,
                seg_count=seg_count,
                decomp_total=decomp_total,
                comp_total=comp_total,
            )
        )
        nxt = tail.find(b"segs", pos + 4)
        pos = nxt if 0 < nxt - pos < 0x500000 else pos + hdr_size + comp_total
    return blocks


def indx_known_plaintext_probe(enc: bytes, blocks: list[SegsBlock]) -> dict:
    """Assume INDX at 0x8000 (PC layout). Derive XOR keystream per entry."""
    indx_off = 0x8000
    probes: list[dict] = []
    for use_rel in (True, False):
        for flags in (0, 1, 2, 4, 0x10):
            matches = 0
            ks_samples: list[str] = []
            for i in range(min(50, len(blocks))):
                b = blocks[i]
                pidx = b.page_index_rel if use_rel else b.page_index_abs
                w3 = (flags << 16) | b.page_count
                plain = struct.pack(">III", pidx, 0, w3)
                eoff = indx_off + i * 12
                if eoff + 12 > len(enc):
                    break
                enc_entry = enc[eoff : eoff + 12]
                if enc_entry == plain:
                    matches += 1
                if i < 3:
                    ks = bytes(a ^ b for a, b in zip(enc_entry, plain))
                    ks_samples.append(ks.hex())
            probes.append({
                "page_index": "rel" if use_rel else "abs",
                "flags_high": flags,
                "exact_matches_50": matches,
                "keystream_first3": ks_samples,
            })

    # Header SCFF keystream vs INDX entry0 keystream (stream cipher offset check)
    ks_hdr = bytes(a ^ b for a, b in zip(enc[:12], SCFF_TEMPLATE))
    b0 = blocks[0]
    plain0 = struct.pack(">III", b0.page_index_rel, 0, b0.page_count)
    ks_indx0 = bytes(enc[0x8000 + i] ^ plain0[i] for i in range(12))

    return {
        "indx_offset": indx_off,
        "block_count": len(blocks),
        "first_block": asdict(b0),
        "header_keystream_12": ks_hdr.hex(),
        "indx0_keystream_12_assumed": ks_indx0.hex(),
        "same_keystream": ks_hdr == ks_indx0,
        "probes": probes,
        "note": (
            "Per-entry keystream differs → not static XOR; likely RC4/AES-CTR/custom "
            "stream. Exact INDX plaintext format still unknown (packed_field/flags)."
        ),
    }


def fingerprint_blocks(
    ps3: Path, blocks: list[SegsBlock], *, max_decompress: int = 200
) -> dict:
    """Decompress blocks looking for scripts_vz / vz hash / LuaQ (bypass path)."""
    targets_dec = {1_055_365, 1_579_504, 1_541_939}  # xbox/pc/demo scripts_vz
    size_hits = [
        b for b in blocks
        if any(abs(b.decomp_total - t) < 10_000 for t in targets_dec)
    ][:20]

    vz_hits: list[dict] = []
    lua_hits: list[dict] = []
    entry114: list[dict] = []

    with ps3.open("rb") as f:
        for i, b in enumerate(blocks[:max_decompress]):
            f.seek(b.file_offset)
            chunk = f.read(min(b.comp_total + 65536, 4 * 1024 * 1024))
            if chunk[:4] != b"segs":
                continue
            try:
                dec = decompress_be_sges(chunk, 0, len(chunk))
            except Exception:
                continue
            if len(dec) < 4:
                continue
            nrec = struct.unpack_from(">I", dec, 0)[0]
            if nrec in (111, 113, 114, 115, 116):
                entry114.append({
                    "offset": f"0x{b.file_offset:X}",
                    "nrec": nrec,
                    "decomp": len(dec),
                })
            for ri in range(min(nrec, 400)):
                ro = 4 + ri * 16
                if ro + 16 > len(dec):
                    break
                ah = struct.unpack_from(">I", dec, ro)[0]
                if ah == VZ_NAME_HASH:
                    vz_hits.append({
                        "offset": f"0x{b.file_offset:X}",
                        "record": ri,
                        "nrec": nrec,
                    })
            if b"\x1bLua" in dec[: min(len(dec), 500_000)]:
                lua_hits.append({"offset": f"0x{b.file_offset:X}", "nrec": nrec})

    return {
        "decompressed_sampled": min(max_decompress, len(blocks)),
        "scripts_vz_size_candidates": [asdict(b) for b in size_hits],
        "blocks_with_111_116_records": entry114[:20],
        "vz_hash_hits": vz_hits,
        "luaq_hits": lua_hits,
    }


def analyze_header_structure(hdr: bytes) -> dict:
    return {
        "size": len(hdr),
        "size_hex": hex(len(hdr)),
        "page_count": len(hdr) / PAGE_SIZE,
        "gap_after_16_pages": hex(len(hdr) - 16 * PAGE_SIZE),
        "magic_hex": hdr[:4].hex(),
        "magic_be_u32": hex(struct.unpack(">I", hdr[:4])[0]),
        "entropy_first_4k": round(_entropy(hdr[:4096]), 3),
        "printable_ratio_first_4k": round(
            sum(32 <= b < 127 for b in hdr[:4096]) / 4096, 3
        ),
        "header_xor_scff_keystream_12": bytes(
            a ^ b for a, b in zip(hdr[:12], SCFF_TEMPLATE)
        ).hex(),
        "bytes_at_0x8000": hdr[0x8000:0x8010].hex(),
        "interpretation": (
            "0x80800 = 16×32KiB metadata pages + 0x800 gap; DATA/segs at 0x80800. "
            "Likely encrypted SCFF-equivalent (INDX/ASET/PTHS/CSUM), not cleartext."
        ),
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="PS3 VZ.WAD header cryptanalysis")
    ap.add_argument("--ps3-wad", type=Path, required=True)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument(
        "--decompress-sample",
        type=int,
        default=300,
        help="Number of segs blocks to decompress for fingerprinting",
    )
    args = ap.parse_args()

    if not args.ps3_wad.is_file():
        print(f"ERROR: not found: {args.ps3_wad}", file=sys.stderr)
        return 1

    args.output.mkdir(parents=True, exist_ok=True)
    file_size = args.ps3_wad.stat().st_size

    with args.ps3_wad.open("rb") as f:
        hdr = f.read(HDR_SIZE)
        f.seek(DATA_OFFSET)
        tail = f.read()

    blocks = walk_segs_blocks(tail)
    report = {
        "file": str(args.ps3_wad),
        "file_size": file_size,
        "header_structure": analyze_header_structure(hdr),
        "transform_battery_top": _transform_battery(hdr)[:15],
        "aes_hits": _try_aes_decrypt(hdr[:0x2000], _title_aes_keys()),
        "indx_probe": indx_known_plaintext_probe(hdr, blocks),
        "segs_catalog": {
            "block_count": len(blocks),
            "first": asdict(blocks[0]) if blocks else None,
            "last": asdict(blocks[-1]) if blocks else None,
        },
        "fingerprint": fingerprint_blocks(
            args.ps3_wad, blocks, max_decompress=args.decompress_sample
        ),
        "recommended_next_steps": [
            "EBOOT.BIN: locate VZ.WAD read/decrypt routine (keys almost certainly in executable).",
            "PS3 ISO / EBOOT dump: strings for 'VZ.WAD', 'segs', decrypt, XOR, AES, SCE.",
            "Compare 5462 segs offsets vs Xbox 11087 INDX once Xbox vz.wad available — partial overlap expected.",
            "If stream cipher: recover ~64KB keystream via INDX+ASET+PTHS layout, then RC4/AES-CTR solver.",
            "Bypass: brute-decompress all segs + scan decompressed for 0xB4420059 / 114 BINN records (CPU-heavy).",
        ],
    }

    out_json = args.output / "ps3_header_crack_report.json"
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")

    md_lines = [
        "# PS3 VZ.WAD Header Crack Report",
        "",
        f"**File:** `{args.ps3_wad}` ({file_size:,} bytes)",
        "",
        "## Structure",
        "",
        f"- Header envelope: **{HDR_SIZE:#x}** bytes ({report['header_structure']['page_count']:.3f} × 32KiB pages)",
        f"- DATA `segs` region: **{DATA_OFFSET:#x}** → EOF",
        f"- `segs` blocks catalogued: **{len(blocks)}**",
        "",
        "## Entropy / magic",
        "",
        f"- First 4 bytes: `{report['header_structure']['magic_hex']}` (not SCFF/FFCS)",
        f"- Entropy (first 4KiB): **{report['header_structure']['entropy_first_4k']}** bits/byte",
        f"- XOR keystream vs SCFF template (first 12B): `{report['header_structure']['header_xor_scff_keystream_12']}`",
        "",
        "## Transform battery (top hits)",
        "",
    ]
    for hit in report["transform_battery_top"][:8]:
        md_lines.append(f"- `{hit}`")
    if report["aes_hits"]:
        md_lines.extend(["", "## AES (title-derived keys)", ""])
        for hit in report["aes_hits"][:5]:
            md_lines.append(f"- `{hit}`")
    md_lines.extend([
        "",
        "## INDX known-plaintext probe",
        "",
        f"- Header keystream ≠ INDX@0x8000 keystream → **stream cipher**, not single XOR.",
        f"- Best probe: `{report['indx_probe']['probes'][0]}`",
        "",
        "## Fingerprint (decompress sample)",
        "",
        f"- vz hash `0x{VZ_NAME_HASH:08X}` hits: **{len(report['fingerprint']['vz_hash_hits'])}**",
        f"- LuaQ hits: **{len(report['fingerprint']['luaq_hits'])}**",
        f"- Blocks with ~114 records: **{len(report['fingerprint']['blocks_with_111_116_records'])}**",
        "",
        "## Next steps",
        "",
    ])
    for step in report["recommended_next_steps"]:
        md_lines.append(f"1. {step}")

    out_md = args.output / "ps3_header_crack_report.md"
    out_md.write_text("\n".join(md_lines) + "\n", encoding="utf-8")

    print(f"Wrote {out_json}")
    print(f"Wrote {out_md}")
    print(f"segs blocks: {len(blocks)}")
    print(f"AES/SCFF hits: {len(report['aes_hits'])}")
    print(f"vz fingerprint hits: {len(report['fingerprint']['vz_hash_hits'])}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
