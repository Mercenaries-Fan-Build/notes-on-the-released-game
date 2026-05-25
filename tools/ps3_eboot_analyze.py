#!/usr/bin/env python3
"""Analyze decrypted PS3 EBOOT.elf for VZ.WAD / WAD loader strings and constants.

Requires decrypted ELF from scripts/decrypt_ps3_eboot.sh (oscetool + appldr key revision 1).

Usage:
  .venv/bin/python3 tools/ps3_eboot_analyze.py \\
    --elf analysis/cross_platform/ps3_eboot/EBOOT.elf \\
    --output analysis/cross_platform/ps3_eboot
"""
from __future__ import annotations

import argparse
import json
import struct
import subprocess
import sys
from pathlib import Path

HDR_SIZE = 0x80800
PAGE_SIZE = 0x8000


def parse_elf_load_segments(data: bytes) -> list[tuple[int, int, int]]:
    if data[:4] != b"\x7fELF":
        raise ValueError("not ELF")
    e_phoff = struct.unpack_from(">Q", data, 32)[0]
    e_phnum = struct.unpack_from(">H", data, 56)[0]
    e_phentsize = struct.unpack_from(">H", data, 58)[0]
    segs: list[tuple[int, int, int]] = []
    for i in range(e_phnum):
        ph = data[e_phoff + i * e_phentsize : e_phoff + (i + 1) * e_phentsize]
        p_type, _flags, p_offset, p_vaddr, _paddr, p_filesz, _memsz, _align = struct.unpack_from(
            ">IIQQQQQQ", ph
        )
        if p_type == 1:
            segs.append((p_offset, p_vaddr, p_filesz))
    return segs


def file_to_va(segs: list[tuple[int, int, int]], file_off: int) -> int | None:
    for p_offset, p_vaddr, p_filesz in segs:
        if p_offset <= file_off < p_offset + p_filesz:
            return p_vaddr + (file_off - p_offset)
    return None


def find_u32_constants(data: bytes, values: list[int], max_hits: int = 20) -> dict:
    out: dict[str, list[int]] = {}
    for v in values:
        hits: list[int] = []
        for endian, tag in [(">I", "be"), ("<I", "le")]:
            pat = struct.pack(endian, v)
            start = 0
            while len(hits) < max_hits:
                i = data.find(pat, start)
                if i < 0:
                    break
                hits.append(i)
                start = i + 4
        out[f"{v:#x}"] = hits[:max_hits]
    return out


def extract_strings(data: bytes, min_len: int = 6) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    cur: list[str] = []
    start = 0
    for i, b in enumerate(data):
        if 32 <= b < 127:
            if not cur:
                start = i
            cur.append(chr(b))
        else:
            if len(cur) >= min_len:
                out.append((start, "".join(cur)))
            cur = []
    return out


def main() -> int:
    ap = argparse.ArgumentParser(description="PS3 decrypted EBOOT string/constant analysis")
    ap.add_argument("--elf", type=Path, required=True)
    ap.add_argument("--output", type=Path, required=True)
    ap.add_argument("--self-info", type=Path, help="Optional EBOOT.BIN for oscetool -i metadata")
    args = ap.parse_args()

    if not args.elf.is_file():
        print(f"error: ELF not found: {args.elf}", file=sys.stderr)
        return 1

    args.output.mkdir(parents=True, exist_ok=True)
    data = args.elf.read_bytes()
    segs = parse_elf_load_segments(data)

    keywords = (
        "wad", "WAD", "VZ", "segs", "sges", "FFCS", "SCFF", "decrypt", "encrypt",
        "crypt", "INDX", "80800", "IsDLC", "DlcMap", "MasterScript", "cellFs",
        "USRDIR", "BLUS", "scripts_vz", "Pandemic",
    )
    all_strings = extract_strings(data)
    hits = [(off, s) for off, s in all_strings if any(k in s for k in keywords)]

    vz_off = data.find(b"VZ.WAD")
    vz_va = file_to_va(segs, vz_off) if vz_off >= 0 else None

    constants = find_u32_constants(
        data, [HDR_SIZE, PAGE_SIZE, 0x9FED8BC6, 0x524288, 0x80000]
    )

    self_info: str | None = None
    if args.self_info and args.self_info.is_file():
        try:
            r = subprocess.run(
                ["oscetool", "-i", str(args.self_info)],
                capture_output=True,
                text=True,
                timeout=30,
            )
            self_info = r.stdout + r.stderr
        except FileNotFoundError:
            self_info = "oscetool not in PATH"

    report = {
        "elf": str(args.elf),
        "elf_size": len(data),
        "load_segments": [
            {"file_offset": o, "vaddr": v, "size": s} for o, v, s in segs
        ],
        "vz_wad_string": {
            "file_offset": f"0x{vz_off:X}" if vz_off >= 0 else None,
            "vaddr": f"0x{vz_va:X}" if vz_va else None,
        },
        "keyword_strings_count": len(hits),
        "keyword_strings": [
            {"offset": f"0x{off:X}", "text": s[:200]} for off, s in hits[:200]
        ],
        "u32_constant_hits": {
            k: [f"0x{x:X}" for x in v] for k, v in constants.items()
        },
        "notes": [
            "bit_xor in ELF is Flash/ActionScript VM opcode, not WAD crypto.",
            "0x80800 appears in allocator/page tables (near 0x8000), not only WAD.",
            "PS3 build paths include /dev_bdvd/PS3_GAME/USRDIR and BLUS30056.",
            "IsDLC / SetMasterScriptName present — prior encrypted-EBOOT string scan was wrong.",
        ],
    }

    out_json = args.output / "eboot_analysis.json"
    out_json.write_text(json.dumps(report, indent=2), encoding="utf-8")

    md = [
        "# PS3 EBOOT.elf Analysis (BLUS30056)",
        "",
        f"**ELF:** `{args.elf}` ({len(data):,} bytes)",
        "",
        "## VZ.WAD string",
        "",
        f"- File offset: `{report['vz_wad_string']['file_offset']}`",
        f"- Virtual address: `{report['vz_wad_string']['vaddr']}`",
        "",
        "## Key strings (sample)",
        "",
    ]
    for item in report["keyword_strings"][:40]:
        md.append(f"- `{item['offset']}`: `{item['text']}`")
    md.extend([
        "",
        "## Constants",
        "",
    ])
    for k, v in report["u32_constant_hits"].items():
        md.append(f"- **{k}**: {len(v)} hits — {', '.join(v[:8])}{'...' if len(v) > 8 else ''}")
    md.extend(["", "## Notes", ""])
    for n in report["notes"]:
        md.append(f"- {n}")

    out_md = args.output / "eboot_analysis.md"
    out_md.write_text("\n".join(md) + "\n", encoding="utf-8")

    print(f"Wrote {out_json}")
    print(f"Wrote {out_md}")
    print(f"Keyword string hits: {len(hits)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
