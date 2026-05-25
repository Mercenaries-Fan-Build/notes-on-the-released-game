#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Havok 5.5.0-r1 binary packfile reader (Mercenaries 2 animation .hkx slices).

Parses the text-version header used by M2 (``Havok-5.5.0-r1`` + padding), three
48-byte section headers (``__classnames__``, ``__types__``, ``__data__``),
the class-name table, and the four chained fixup streams inside ``__data__``
(local → global → virtual → finish). Local fixups are applied to produce
``data_patched.bin``; global fixups are optional (``--apply-global``) while the
semantics are validated against hkxcmd dumps.

This is intentionally self-contained (no external Havok SDK). Full hkClass
reflection from ``__types__`` is only lightly parsed (hex preview + bounds).
"""

from __future__ import annotations

import argparse
import json
import struct
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

HAVOK_VER = b"Havok-5.5.0-r1"
SECTION_HDR_SIZE = 48  # 20-byte name + 7×u32


@dataclass
class HkSection:
    name: str
    abs_start: int
    local_fixup: int
    global_fixup: int
    virtual_fixup: int
    exports: int
    imports: int
    end: int


@dataclass
class HkPackfile:
    raw: bytes
    version_off: int
    classnames: HkSection
    types: HkSection
    data: HkSection
    classname_entries: list[tuple[int, str, int]] = field(default_factory=list)
    local_fixups: list[tuple[int, int]] = field(default_factory=list)
    global_fixups: list[tuple[int, int]] = field(default_factory=list)
    virtual_fixups: list[tuple[int, int, int]] = field(default_factory=list)
    finish_fixups: list[tuple[int, int]] = field(default_factory=list)
    patched_data: bytes = b""


def _read_cstring(data: bytes, off: int, max_len: int = 4096) -> tuple[str, int]:
    end = off
    while end < len(data) and end - off < max_len and data[end] != 0:
        end += 1
    return data[off:end].decode("ascii", errors="replace"), end + 1


def _align16(x: int) -> int:
    return (x + 15) & ~15


def find_version(data: bytes) -> int:
    i = data.find(HAVOK_VER)
    if i < 0:
        raise ValueError("not a Havok-5.5.0-r1 packfile")
    return i


def find_first_section_off(data: bytes, version_off: int) -> int:
    """Locate ``__classnames__`` section header (20-byte NUL-padded name + u32 fields)."""
    needle = b"__classnames__\x00"
    p = data.find(needle, version_off, min(len(data), version_off + 0x200))
    if p < 0:
        raise ValueError("__classnames__ section header not found")
    return p


def parse_section_headers(data: bytes, first_section_off: int) -> tuple[HkSection, HkSection, HkSection]:
    o = first_section_off
    sections: list[HkSection] = []
    for _ in range(3):
        name_raw = data[o : o + 20]
        nz = name_raw.split(b"\xff")[0]
        name = nz.split(b"\x00", 1)[0].decode("ascii", errors="replace")
        u = struct.unpack_from("<7I", data, o + 20)
        sections.append(
            HkSection(
                name=name,
                abs_start=int(u[0]),
                local_fixup=int(u[1]),
                global_fixup=int(u[2]),
                virtual_fixup=int(u[3]),
                exports=int(u[4]),
                imports=int(u[5]),
                end=int(u[6]),
            )
        )
        o += SECTION_HDR_SIZE
    return sections[0], sections[1], sections[2]


def parse_classnames_body(data: bytes, sec: HkSection) -> list[tuple[int, str]]:
    """Parse classname table.  Each entry is: signature (u32 LE) + 0x09 byte + NUL-terminated name, packed tightly."""
    start = sec.abs_start
    end = start + sec.local_fixup
    out: list[tuple[int, str]] = []
    p = start
    while p + 5 < end and p + 5 < len(data):
        sig = struct.unpack_from("<I", data, p)[0]
        if sig == 0xFFFFFFFF:
            break
        _flag = data[p + 4]
        q = p + 5
        while q < end and q < len(data) and data[q] != 0:
            q += 1
        name = data[p + 5 : q].decode("ascii", errors="replace")
        if not name:
            break
        rel_off = p - start
        out.append((sig, name, rel_off))
        q += 1
        p = q
    return out


def _read_fixup_pairs(data: bytes, start: int, end: int) -> list[tuple[int, int]]:
    """Read 8-byte (u32, u32) pairs in [start, end), stopping at sentinel or boundary."""
    out: list[tuple[int, int]] = []
    p = start
    while p + 8 <= end and p + 8 <= len(data):
        a, b = struct.unpack_from("<II", data, p)
        p += 8
        if a == 0xFFFFFFFF and b == 0xFFFFFFFF:
            break
        out.append((a, b))
    return out


def _read_virtual_fixup_triples(data: bytes, start: int, end: int) -> list[tuple[int, int, int]]:
    """Read 12-byte (src u32, section_index u32, classname_offset u32) virtual fixup entries."""
    out: list[tuple[int, int, int]] = []
    p = start
    while p + 12 <= end and p + 12 <= len(data):
        a, b, c = struct.unpack_from("<III", data, p)
        p += 12
        if a == 0xFFFFFFFF:
            break
        out.append((a, b, c))
    return out


def read_fixup_streams(
    data: bytes, data_sec: HkSection
) -> tuple[list[tuple[int, int]], list[tuple[int, int]], list[tuple[int, int, int]], list[tuple[int, int]]]:
    """
    Havok 5.5 ``__data__`` stores four fixup streams bounded by the section header offsets:
    local [local_fixup..global_fixup), global [global_fixup..virtual_fixup),
    virtual [virtual_fixup..exports), finish [exports..imports).
    Virtual fixups are 12-byte triples; the rest are 8-byte pairs.
    """
    base = data_sec.abs_start
    local = _read_fixup_pairs(data, base + data_sec.local_fixup, base + data_sec.global_fixup)
    global_ = _read_fixup_pairs(data, base + data_sec.global_fixup, base + data_sec.virtual_fixup)
    virtual = _read_virtual_fixup_triples(data, base + data_sec.virtual_fixup, base + data_sec.exports)
    finish = _read_fixup_pairs(data, base + data_sec.exports, base + data_sec.end)
    return local, global_, virtual, finish


def read_local_fixups(data: bytes, data_sec: HkSection) -> list[tuple[int, int]]:
    local, _g, _v, _f = read_fixup_streams(data, data_sec)
    return local


def apply_local_fixups(data_sec_bytes: bytes, abs0: int, pairs: list[tuple[int, int]]) -> bytearray:
    buf = bytearray(data_sec_bytes)
    for src, dst in pairs:
        if src + 4 > len(buf):
            continue
        struct.pack_into("<I", buf, src, abs0 + dst)
    return buf


def apply_global_fixups(data_sec_bytes: bytes, pairs: list[tuple[int, int]]) -> None:
    """Patch absolute file pointers (``dst``) into ``__data__`` object bytes at ``src`` offsets."""
    buf = data_sec_bytes
    for src, dst_abs in pairs:
        if src + 4 > len(buf):
            continue
        struct.pack_into("<I", buf, src, int(dst_abs) & 0xFFFFFFFF)


def types_section_preview(raw: bytes, ty: HkSection, max_bytes: int = 2048) -> dict[str, Any]:
    """Lightweight ``__types__`` slice for debugging (full hkClass graph parse is future work)."""
    if ty.abs_start >= len(raw) or ty.end <= ty.abs_start:
        return {"error": "bad_types_bounds", "abs_start": ty.abs_start, "end": ty.end}
    span = min(max_bytes, ty.end - ty.abs_start)
    chunk = raw[ty.abs_start : ty.abs_start + span]
    return {
        "abs_start": ty.abs_start,
        "end": ty.end,
        "declared_length": ty.end - ty.abs_start,
        "preview_bytes": min(span, max_bytes),
        "head_hex": chunk[:256].hex(),
    }


def scan_data_for_classname_hashes(
    patched: bytes,
    hash_to_name: dict[int, str],
    *,
    stride: int = 8,
    max_hits: int = 120,
    scan_limit: int = 262_144,
) -> list[dict[str, Any]]:
    """Heuristic u32 hash hits against ``__classnames__`` (coarse class-graph hint)."""
    hits: list[dict[str, Any]] = []
    seen_off: set[int] = set()
    limit = min(len(patched) - 4, scan_limit)
    for off in range(0, limit, stride):
        h = struct.unpack_from("<I", patched, off)[0]
        name = hash_to_name.get(h)
        if not name:
            continue
        if not (name.startswith("hka") or name.startswith("hkx")):
            continue
        if off in seen_off:
            continue
        seen_off.add(off)
        hits.append({"offset": off, "offset_hex": hex(off), "hash": f"0x{h:08X}", "class": name})
        if len(hits) >= max_hits:
            break
    return hits


def load_packfile(path: Path, *, apply_global: bool = False) -> HkPackfile:
    raw = path.read_bytes()
    voff = find_version(raw)
    first_sec = find_first_section_off(raw, voff)
    cn, ty, da = parse_section_headers(raw, first_sec)
    entries = parse_classnames_body(raw, cn)
    loc, glo, vir, fin = read_fixup_streams(raw, da)
    d0 = da.abs_start
    body = raw[d0 : d0 + da.local_fixup]
    patched_buf = apply_local_fixups(body, d0, loc)
    if apply_global and glo:
        apply_global_fixups(patched_buf, glo)
    patched = bytes(patched_buf)
    return HkPackfile(
        raw=raw,
        version_off=voff,
        classnames=cn,
        types=ty,
        data=da,
        classname_entries=entries,
        local_fixups=loc,
        global_fixups=glo,
        virtual_fixups=vir,
        finish_fixups=fin,
        patched_data=patched,
    )


def locate_objects_by_class(pf: HkPackfile) -> dict[str, list[int]]:
    """Map class names to data-section offsets using virtual fixups + classname table.

    Returns ``{class_name: [offset_in_data, ...]}`` for every object in ``__data__``.
    """
    cn_by_rel_off: dict[int, str] = {rel: name for _sig, name, rel in pf.classname_entries}
    out: dict[str, list[int]] = {}
    for src, _sec_idx, cn_off in pf.virtual_fixups:
        name = cn_by_rel_off.get(cn_off)
        if name:
            out.setdefault(name, []).append(src)
    return out


def packfile_summary(pf: HkPackfile) -> dict[str, Any]:
    sig_to_name = {sig: n for sig, n, _rel in pf.classname_entries}
    class_hits = scan_data_for_classname_hashes(pf.patched_data, sig_to_name)
    types_pv = types_section_preview(pf.raw, pf.types)
    obj_map = locate_objects_by_class(pf)
    return {
        "havok_version_offset": pf.version_off,
        "sections": {
            "__classnames__": pf.classnames.__dict__,
            "__types__": pf.types.__dict__,
            "__data__": pf.data.__dict__,
        },
        "types_preview": types_pv,
        "classname_count": len(pf.classname_entries),
        "classnames_sample": [{"sig": f"0x{sig:08X}", "name": n, "rel_off": rel} for sig, n, rel in pf.classname_entries[:40]],
        "local_fixup_count": len(pf.local_fixups),
        "global_fixup_count": len(pf.global_fixups),
        "virtual_fixup_count": len(pf.virtual_fixups),
        "finish_fixup_count": len(pf.finish_fixups),
        "local_fixups": [{"src": hex(a), "dst": hex(b)} for a, b in pf.local_fixups[:400]],
        "global_fixups_sample": [{"src": hex(a), "dst_abs": hex(b)} for a, b in pf.global_fixups[:80]],
        "virtual_fixups_sample": [{"src": hex(a), "section": b, "cn_off": c} for a, b, c in pf.virtual_fixups[:80]],
        "object_map": {k: [hex(o) for o in v] for k, v in obj_map.items()},
        "data_object_size": pf.data.local_fixup,
        "data_section_total": pf.data.end,
        "data_class_hits_sample": class_hits,
    }


def write_outputs(pf: HkPackfile, out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "packfile.json").write_text(json.dumps(packfile_summary(pf), indent=2), encoding="utf-8")
    (out_dir / "data_patched.bin").write_bytes(pf.patched_data)
    (out_dir / "classnames.json").write_text(
        json.dumps([{"sig": f"0x{sig:08X}", "name": n, "rel_off": rel} for sig, n, rel in pf.classname_entries], indent=2),
        encoding="utf-8",
    )


def main() -> int:
    ap = argparse.ArgumentParser(description="Parse Havok 5.5.0-r1 packfile (.hkx)")
    ap.add_argument("hkx", type=Path)
    ap.add_argument("--out-dir", type=Path, required=True)
    ap.add_argument(
        "--apply-global",
        action="store_true",
        help="After local fixups, apply global fixup absolute pointers (experimental).",
    )
    args = ap.parse_args()
    pf = load_packfile(args.hkx, apply_global=args.apply_global)
    write_outputs(pf, args.out_dir)
    print(f"Wrote {args.out_dir}/packfile.json (+ data_patched.bin, classnames.json)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
