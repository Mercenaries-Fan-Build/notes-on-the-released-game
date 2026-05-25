#!/usr/bin/env python3
"""Validate a built patch WAD for common byte-swap corruption patterns.

Checks each converted UCFX entry for signs of the issues we've encountered:
1. Texture INFO still in Xbox 360 format (no FourCC at bytes 14-17)
2. TYPE tags with implausible u16 type codes (>50)
3. DEPS chunks where count * 4 != remaining bytes
4. Unswapped BE patterns in fields that should be LE
5. NAME tags containing non-ASCII or non-printable bytes
6. Animation data without Havok magic (override failed)

Usage:
    python tools/validate_patch_wad.py output/data/vz-patch.wad [--source-wad path/to/vz.wad]
"""
from __future__ import annotations

import argparse
import struct
import sys
import mmap
from pathlib import Path
from collections import defaultdict

sys.path.insert(0, str(Path(__file__).parent))
from sges_decompress import decompress_sges_block
from wad_patcher import find_data_chunk, get_block_boundaries, parse_block_entries

_TYPE_TEXTURE = 0xF011157A
_TYPE_ANIMATION = 0x18166555
_TYPE_SCRIPT = 0x42498680
_TYPE_PATH = 0xBCFE6314

_HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"

TYPE_NAMES = {
    0xF011157A: "texture",
    0x42498680: "script",
    0x207359C7: "stance",
    0x18166555: "animation",
    0xBCFE6314: "path",
    0xECE70371: "state_machine",
    0xE6B81A54: "ecs_node",
    0x5B724250: "mesh_B",
    0x7C569307: "mesh_A",
    0x600B904E: "mesh_C",
    0x39E5E978: "stringdb",
}


class Issue:
    def __init__(self, severity: str, block: int, hash: int, type_hash: int, tag: str, msg: str):
        self.severity = severity
        self.block = block
        self.hash = hash
        self.type_hash = type_hash
        self.tag = tag
        self.msg = msg

    def __str__(self):
        tname = TYPE_NAMES.get(self.type_hash, f"0x{self.type_hash:08X}")
        return f"[{self.severity}] block {self.block}, hash 0x{self.hash:08X} ({tname}), {self.tag}: {self.msg}"


def validate_patch_wad(patch_path: Path, source_wad: Path | None = None) -> list[Issue]:
    issues: list[Issue] = []
    dc = find_data_chunk(patch_path)

    with open(patch_path, "rb") as f:
        mm = mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
        boundaries = get_block_boundaries(mm, dc.offset, dc.size)

        for blk_idx in range(len(boundaries)):
            s, e = boundaries[blk_idx]
            try:
                data = decompress_sges_block(mm, s, e)
            except Exception as ex:
                issues.append(Issue("ERROR", blk_idx, 0, 0, "block", f"Decompression failed: {ex}"))
                continue

            for ent in parse_block_entries(data):
                th = ent["type_hash"]
                eh = ent["hash"]
                chunk = data[ent["offset"]:ent["offset"] + ent["size"] - 8]
                pos = chunk.find(b"UCFX")
                if pos < 0:
                    continue
                c = chunk[pos:]
                if len(c) < 20:
                    continue

                dao = struct.unpack_from("<I", c, 4)[0]
                n = struct.unpack_from("<I", c, 16)[0]
                if n > 5000:
                    issues.append(Issue("ERROR", blk_idx, eh, th, "UCFX",
                                        f"Implausible descriptor count: {n}"))
                    continue

                for i in range(n):
                    doff = 20 + i * 20
                    if doff + 20 > len(c):
                        break
                    tag = c[doff:doff+4].decode("ascii", "replace")
                    u0, bs = struct.unpack_from("<II", c, doff + 4)
                    if u0 == 0xFFFFFFFF or bs == 0:
                        continue
                    bstart = (dao if dao else 8) + u0
                    if bstart + bs > len(c):
                        continue
                    body = c[bstart:bstart + bs]

                    # ── Check 1: Texture INFO format ──
                    if tag == "INFO" and th == _TYPE_TEXTURE:
                        if bs >= 22:
                            fmt = body[14:18]
                            if not _is_valid_fourcc(fmt):
                                issues.append(Issue("CRITICAL", blk_idx, eh, th, "INFO",
                                    f"Invalid FourCC at [14:18]: {fmt.hex()} (Xbox 360 format not overridden?)"))

                    # ── Check 2: TYPE tag codes ──
                    if tag == "TYPE":
                        bad_codes = _check_type_codes(body)
                        if bad_codes:
                            issues.append(Issue("WARN", blk_idx, eh, th, "TYPE",
                                f"Suspicious type codes: {bad_codes[:5]}"))

                    # ── Check 3: DEPS count consistency ──
                    if tag == "DEPS" and bs >= 1:
                        count_byte = body[0]
                        expected_size = 1 + count_byte * 4
                        if expected_size != bs:
                            issues.append(Issue("ERROR", blk_idx, eh, th, "DEPS",
                                f"Count={count_byte} but size={bs} (expected {expected_size})"))

                    # ── Check 4: NAME should be printable ASCII ──
                    if tag == "NAME":
                        if not _is_clean_ascii(body):
                            issues.append(Issue("WARN", blk_idx, eh, th, "NAME",
                                f"Non-ASCII content: {body[:20].hex()}"))

                    # ── Check 5: Animation data should have Havok magic ──
                    if tag == "data" and th == _TYPE_ANIMATION and bs >= 8:
                        if body[:8] != _HAVOK_MAGIC:
                            # Check if it's LE havok magic
                            if body[:8] != b"\x10\xc0\xc0\x10\x57\xe0\xe0\x57":
                                issues.append(Issue("WARN", blk_idx, eh, th, "data",
                                    f"No Havok magic (override failed?): {body[:8].hex()}"))

                    # ── Check 6: info for ecs_node should start with ASCII ──
                    if tag == "info" and th == 0xE6B81A54 and bs >= 4:
                        nul = body.find(b"\x00")
                        if nul <= 0 or not _is_clean_ascii(body[:nul]):
                            issues.append(Issue("WARN", blk_idx, eh, th, "info",
                                f"Expected ASCII name prefix: {body[:16].hex()}"))

                    # ── Check 7: Potential unswapped BE u32 in LE context ──
                    if tag == "INFO" and th in (0x7C569307, 0x5B724250, 0x600B904E):
                        _check_mesh_info_be_patterns(body, blk_idx, eh, th, issues)

        mm.close()
    return issues


def _is_valid_fourcc(b: bytes) -> bool:
    """Check if 4 bytes look like a PC texture FourCC (DXT1, DXT3, DXT5, etc.)."""
    known = {b"DXT1", b"DXT3", b"DXT5", b"ATI1", b"ATI2", b"A8R8", b"X8R8", b"R5G6"}
    stripped = b.rstrip(b"\x00")
    if stripped in known:
        return True
    # At minimum, FourCC should be printable ASCII
    return all(32 <= byte < 127 for byte in stripped) and len(stripped) >= 3


def _check_type_codes(body: bytes) -> list[tuple[str, int]]:
    """Walk TYPE body looking for suspiciously large u16 type codes."""
    bad = []
    pos = 0
    while pos < len(body):
        nul = body.find(b"\x00", pos)
        if nul < 0:
            break
        name = body[pos:nul].decode("ascii", "replace")
        pos = nul + 1
        if pos + 2 <= len(body):
            code = struct.unpack_from("<H", body, pos)[0]
            pos += 2
            if code > 50:
                bad.append((name, code))
        else:
            break
    return bad


def _is_clean_ascii(data: bytes) -> bool:
    """Check if bytes are printable ASCII (allowing null terminator)."""
    for b in data:
        if b == 0:
            continue
        if b < 32 or b > 126:
            return False
    return True


def _check_mesh_info_be_patterns(body: bytes, blk: int, eh: int, th: int, issues: list):
    """Check mesh INFO for patterns suggesting unswapped BE data."""
    if len(body) < 8:
        return
    # Mesh INFO contains floats (bounding box). If we see values like 0x43XX00XX
    # that suggests partial swap. Check first few u32 values for NaN patterns.
    for off in range(0, min(len(body), 32), 4):
        v = struct.unpack_from("<I", body, off)[0]
        # Check for common BE float pattern leaked into LE: exponent in wrong byte
        # A properly swapped float will have exponent in byte 2-3 (bits 23-30)
        # If we see 0x00XX43XX pattern, it might be an unswapped 0xXX43XX00
        if v != 0 and (v & 0xFF000000) == 0 and ((v >> 8) & 0xFF) > 0x3E:
            issues.append(Issue("WARN", blk, eh, th, "INFO",
                f"Possible BE float at offset {off}: 0x{v:08X}"))
            break


def main():
    parser = argparse.ArgumentParser(description="Validate patch WAD for byte-swap issues")
    parser.add_argument("patch_wad", type=Path)
    parser.add_argument("--source-wad", type=Path, default=None)
    args = parser.parse_args()

    if not args.patch_wad.exists():
        print(f"ERROR: {args.patch_wad} not found")
        return 1

    print(f"Validating {args.patch_wad}...")
    issues = validate_patch_wad(args.patch_wad, args.source_wad)

    if not issues:
        print("\n  ✓ No issues detected!")
        return 0

    # Group by severity
    by_severity = defaultdict(list)
    for iss in issues:
        by_severity[iss.severity].append(iss)

    print(f"\n  Found {len(issues)} issue(s):\n")
    for sev in ("CRITICAL", "ERROR", "WARN"):
        group = by_severity.get(sev, [])
        if group:
            print(f"  [{sev}] ({len(group)}):")
            for iss in group[:20]:
                print(f"    {iss}")
            if len(group) > 20:
                print(f"    ... and {len(group) - 20} more")
            print()

    critical = len(by_severity.get("CRITICAL", []))
    errors = len(by_severity.get("ERROR", []))
    if critical:
        print(f"  ⚠ {critical} CRITICAL issue(s) — these WILL cause crashes")
    if errors:
        print(f"  ⚠ {errors} ERROR(s) — these likely cause crashes")

    return 1 if critical or errors else 0


if __name__ == "__main__":
    sys.exit(main())
