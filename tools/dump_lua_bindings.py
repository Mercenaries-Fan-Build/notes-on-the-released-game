#!/usr/bin/env python3
"""Dump luaL_Reg registration tables from Mercenaries 2 PC EXE.

Walks the engine registration cluster in ``.rdata`` (file offsets ~0x00798770–0x0079AA38).
**By default only tables with a verified namespace label are named** — see
``VERIFIED_TABLE_LABELS`` (from ``docs/lua_engine_bindings_audit_deep_dive.md``,
CONFIRMED/CERTAIN only). Unlabeled tables are emitted as ``table@0x<file_offset>``.

Optional ``--scan-rdata`` runs a pair scan over all of ``.rdata``; that mode produces
many false tables (Lua stdlib, Flash, misaligned runs) and is **off by default**.

Table storage uses **file offsets** in ``.rdata``; each entry's ``name_va`` / ``func_va``
are image VAs (image base 0x00400000).

Usage:
  .venv/bin/python3 tools/dump_lua_bindings.py --exe path/to/Mercenaries2.exe
  .venv/bin/python3 tools/dump_lua_bindings.py --exe ... --json out.json --csv out.csv
  .venv/bin/python3 tools/dump_lua_bindings.py --exe ... --scan-rdata   # not recommended
  .venv/bin/python3 tools/dump_lua_bindings.py --self-test
"""
from __future__ import annotations

import argparse
import csv
import json
import struct
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Iterator

IMAGE_BASE_DEFAULT = 0x00400000

# Engine luaL_Reg cluster (file offsets within .rdata for cracked 53,482,288-byte EXE)
PRIMARY_FILE_START = 0x00798770
PRIMARY_FILE_END = 0x00799200
PRIMARY_FILE_SCAN_END = 0x0079AA38

# CONFIRMED/CERTAIN table bases only (docs/lua_engine_bindings_audit_deep_dive.md §1.4).
# Do not add labels without cross-verified evidence (bytecode, luaopen string, or RE consensus).
VERIFIED_TABLE_LABELS: dict[int, str] = {
    0x007987F8: "Event",
    0x00798828: "Debug",
    0x00798860: "Weapon",
    0x007988B0: "VO",
    0x00798918: "Vehicle",
    0x00798A78: "Sys",
    0x00798C98: "Sound",
    0x00798F64: "Faction",
    0x00798FC0: "Player",
    0x00799328: "Pg",
    0x00799608: "Object",
    0x007998D0: "Net",
    0x00799C78: "LTI",
    0x00799FF8: "Gui",
    0x0079A7D8: "Camera",
    0x0079A854: "_SYS",
    0x0079A938: "Ai",
}

MAX_NAME_LEN = 128
MIN_TABLE_ENTRIES = 2
MIN_HEURISTIC_ENTRIES = 2
MAX_TABLE_ENTRIES = 512
STRING_SECTIONS = (".rdata", ".data")
CODE_SECTIONS = (".text",)


@dataclass(frozen=True)
class PeSection:
    name: str
    virtual_address: int
    virtual_size: int
    raw_ptr: int
    raw_size: int

    def contains_rva(self, rva: int) -> bool:
        span = max(self.virtual_size, self.raw_size)
        return self.virtual_address <= rva < self.virtual_address + span

    def contains_file_offset(self, offset: int) -> bool:
        return self.raw_ptr <= offset < self.raw_ptr + self.raw_size


@dataclass
class ParsedPe:
    path: Path
    data: bytes
    image_base: int
    sections: list[PeSection]

    def section(self, name: str) -> PeSection | None:
        for sec in self.sections:
            if sec.name.lower() == name.lower():
                return sec
        return None

    def rva_to_offset(self, rva: int) -> int | None:
        for sec in self.sections:
            if sec.contains_rva(rva):
                off = sec.raw_ptr + (rva - sec.virtual_address)
                if 0 <= off < len(self.data):
                    return off
        return None

    def va_to_offset(self, va: int) -> int | None:
        rva = va - self.image_base
        if rva < 0:
            return None
        return self.rva_to_offset(rva)

    def offset_to_va(self, offset: int) -> int | None:
        for sec in self.sections:
            if sec.contains_file_offset(offset):
                rva = sec.virtual_address + (offset - sec.raw_ptr)
                return self.image_base + rva
        return None

    def va_in_sections(self, va: int, names: tuple[str, ...]) -> bool:
        rva = va - self.image_base
        if rva < 0:
            return False
        for sec in self.sections:
            if sec.name.lower() in {n.lower() for n in names} and sec.contains_rva(rva):
                return True
        return False

    def resolve_primary_offset(self, documented: int) -> int:
        """Map audit address to a file offset.

        Mercenaries RE docs use **file offsets** in ``.rdata`` for the table cluster
        (e.g. ``0x00798770``). The same numeric value is also a valid in-image VA
        inside ``.text``, so prefer the ``.rdata`` file-offset interpretation first.
        """
        rdata = self.section(".rdata")
        if rdata and rdata.contains_file_offset(documented):
            return documented
        off = self.va_to_offset(documented)
        if off is not None:
            return off
        return documented


@dataclass
class BindingEntry:
    name: str
    name_va: int
    func_va: int


@dataclass
class BindingTable:
    namespace: str | None
    start_va: int
    start_foff: int
    end_foff: int
    entries: list[BindingEntry] = field(default_factory=list)
    source: str = "primary"

    @property
    def end_va(self) -> int:
        return self.start_va + (self.end_foff - self.start_foff)

    @property
    def label(self) -> str:
        if self.namespace:
            return self.namespace
        return f"table@0x{self.start_foff:08X}"

    def to_dict(self) -> dict[str, Any]:
        return {
            "namespace": self.namespace,
            "label": self.label,
            "start_va": f"0x{self.start_va:08X}",
            "start_foff": f"0x{self.start_foff:08X}",
            "end_va": f"0x{self.end_va:08X}",
            "end_foff": f"0x{self.end_foff:08X}",
            "entry_count": len(self.entries),
            "source": self.source,
            "entries": [
                {
                    "name": e.name,
                    "name_va": f"0x{e.name_va:08X}",
                    "func_va": f"0x{e.func_va:08X}",
                }
                for e in self.entries
            ],
        }


def parse_pe(exe_path: Path) -> ParsedPe:
    data = exe_path.read_bytes()
    if data[:2] != b"MZ":
        raise ValueError(f"Not a PE file (missing MZ): {exe_path}")

    pe_off = struct.unpack_from("<I", data, 0x3C)[0]
    if data[pe_off : pe_off + 4] != b"PE\x00\x00":
        raise ValueError(f"Not a PE file (missing PE signature): {exe_path}")

    coff_off = pe_off + 4
    num_sections = struct.unpack_from("<H", data, coff_off + 2)[0]
    opt_hdr_size = struct.unpack_from("<H", data, coff_off + 16)[0]
    opt_off = coff_off + 20
    magic = struct.unpack_from("<H", data, opt_off)[0]

    if magic == 0x10B:
        image_base = struct.unpack_from("<I", data, opt_off + 28)[0]
    elif magic == 0x20B:
        image_base = struct.unpack_from("<Q", data, opt_off + 24)[0]
    else:
        raise ValueError(f"Unknown PE optional header magic: 0x{magic:X}")

    sec_table_off = coff_off + 20 + opt_hdr_size
    sections: list[PeSection] = []
    for i in range(num_sections):
        s_off = sec_table_off + i * 40
        name = data[s_off : s_off + 8].rstrip(b"\x00").decode("ascii", errors="replace")
        virtual_size, virtual_address, raw_size, raw_ptr = struct.unpack_from(
            "<IIII", data, s_off + 8
        )
        sections.append(
            PeSection(
                name=name,
                virtual_address=virtual_address,
                virtual_size=virtual_size,
                raw_ptr=raw_ptr,
                raw_size=raw_size,
            )
        )

    return ParsedPe(path=exe_path, data=data, image_base=image_base, sections=sections)


def read_cstring(pe: ParsedPe, va: int, max_len: int = MAX_NAME_LEN) -> str | None:
    off = pe.va_to_offset(va)
    if off is None:
        return None
    end = off
    limit = min(len(pe.data), off + max_len)
    while end < limit and pe.data[end] != 0:
        end += 1
    if end >= limit:
        return None
    raw = pe.data[off:end]
    if not raw:
        return None
    try:
        return raw.decode("ascii")
    except UnicodeDecodeError:
        return None


def is_plausible_binding_name(name: str) -> bool:
    if not name or len(name) > MAX_NAME_LEN:
        return False
    if not (name[0].isalpha() or name[0] == "_"):
        return False
    return all(ch.isalnum() or ch in "._" for ch in name)


def is_valid_reg_pair(pe: ParsedPe, name_va: int, func_va: int) -> bool:
    if name_va == 0 and func_va == 0:
        return True
    if name_va == 0 or func_va == 0:
        return False
    if not pe.va_in_sections(name_va, STRING_SECTIONS):
        return False
    if not pe.va_in_sections(func_va, CODE_SECTIONS):
        return False
    name = read_cstring(pe, name_va)
    return name is not None and is_plausible_binding_name(name)


def read_pair_at_offset(pe: ParsedPe, foff: int) -> tuple[int, int] | None:
    if foff + 8 > len(pe.data):
        return None
    return struct.unpack_from("<II", pe.data, foff)


def pair_to_entry(pe: ParsedPe, name_va: int, func_va: int) -> BindingEntry | None:
    name = read_cstring(pe, name_va)
    if name is None or not is_plausible_binding_name(name):
        return None
    return BindingEntry(name=name, name_va=name_va, func_va=func_va)


def verified_namespace(start_foff: int) -> str | None:
    """Return namespace only when file offset is in the verified map."""
    return VERIFIED_TABLE_LABELS.get(start_foff)


def parse_table_at_offset(pe: ParsedPe, start_foff: int) -> BindingTable | None:
    entries: list[BindingEntry] = []
    foff = start_foff
    while len(entries) <= MAX_TABLE_ENTRIES:
        pair = read_pair_at_offset(pe, foff)
        if pair is None:
            break
        name_va, func_va = pair
        if name_va == 0 and func_va == 0:
            end_foff = foff + 8
            if len(entries) < MIN_TABLE_ENTRIES:
                return None
            start_va = pe.offset_to_va(start_foff) or start_foff
            return BindingTable(
                namespace=verified_namespace(start_foff),
                start_va=start_va,
                start_foff=start_foff,
                end_foff=end_foff,
                entries=entries,
            )
        if not is_valid_reg_pair(pe, name_va, func_va):
            break
        entry = pair_to_entry(pe, name_va, func_va)
        if entry is None:
            break
        entries.append(entry)
        foff += 8
    return None


def skip_gap(pe: ParsedPe, foff: int, limit: int) -> int:
    while foff < limit:
        pair = read_pair_at_offset(pe, foff)
        if pair is None:
            return foff
        if pair == (0, 0):
            foff += 4
            continue
        if is_valid_reg_pair(pe, pair[0], pair[1]):
            return foff
        foff += 4
    return foff


def dump_primary_cluster(pe: ParsedPe) -> list[BindingTable]:
    start = pe.resolve_primary_offset(PRIMARY_FILE_START)
    end = pe.resolve_primary_offset(PRIMARY_FILE_SCAN_END)
    tables: list[BindingTable] = []
    foff = start
    while foff < end:
        table = parse_table_at_offset(pe, foff)
        if table is None:
            foff += 4
            continue
        table.source = "primary"
        tables.append(table)
        foff = table.end_foff
        foff = skip_gap(pe, foff, end)
    return tables


def file_ranges_overlap(a0: int, a1: int, b0: int, b1: int) -> bool:
    return a0 < b1 and b0 < a1


def iter_rdata_offsets(pe: ParsedPe, step: int = 4) -> Iterator[int]:
    rdata = pe.section(".rdata")
    if rdata is None:
        return
    end = rdata.raw_ptr + rdata.raw_size
    foff = rdata.raw_ptr
    while foff + 8 <= end:
        yield foff
        foff += step


def dump_rdata_scan_tables(
    pe: ParsedPe,
    *,
    exclude: list[BindingTable],
) -> list[BindingTable]:
    claimed = [(t.start_foff, t.end_foff) for t in exclude]
    primary_lo = pe.resolve_primary_offset(PRIMARY_FILE_START)
    primary_hi = pe.resolve_primary_offset(PRIMARY_FILE_SCAN_END)
    found: list[BindingTable] = []

    for start_foff in iter_rdata_offsets(pe):
        if primary_lo <= start_foff < primary_hi:
            continue
        if any(file_ranges_overlap(start_foff, start_foff + 8, lo, hi) for lo, hi in claimed):
            continue

        table = parse_table_at_offset(pe, start_foff)
        if table is None or len(table.entries) < MIN_HEURISTIC_ENTRIES:
            continue
        if any(
            file_ranges_overlap(table.start_foff, table.end_foff, lo, hi) for lo, hi in claimed
        ):
            continue

        table.source = "rdata_scan"
        found.append(table)
        claimed.append((table.start_foff, table.end_foff))

    return found


def write_csv(path: Path, tables: list[BindingTable]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(
            [
                "table_start_va",
                "table_start_foff",
                "namespace",
                "table_label",
                "source",
                "name",
                "name_va",
                "func_va",
            ]
        )
        for table in tables:
            for e in table.entries:
                w.writerow(
                    [
                        f"0x{table.start_va:08X}",
                        f"0x{table.start_foff:08X}",
                        table.namespace or "",
                        table.label,
                        table.source,
                        e.name,
                        f"0x{e.name_va:08X}",
                        f"0x{e.func_va:08X}",
                    ]
                )


def print_summary(tables: list[BindingTable], pe: ParsedPe) -> None:
    rdata = pe.section(".rdata")
    text = pe.section(".text")
    print(f"EXE: {pe.path} ({len(pe.data):,} bytes)")
    print(f"Image base: 0x{pe.image_base:08X}")
    if rdata:
        print(
            f".rdata file 0x{rdata.raw_ptr:08X}–0x{rdata.raw_ptr + rdata.raw_size:08X}"
            f"  (VA 0x{pe.image_base + rdata.virtual_address:08X})"
        )
    if text:
        print(
            f".text  file 0x{text.raw_ptr:08X}–0x{text.raw_ptr + text.raw_size:08X}"
            f"  (VA 0x{pe.image_base + text.virtual_address:08X})"
        )
    print()
    print(
        f"Primary cluster (doc file offsets 0x{PRIMARY_FILE_START:08X}–"
        f"0x{PRIMARY_FILE_END:08X}, scan to 0x{PRIMARY_FILE_SCAN_END:08X})"
    )
    primary = [t for t in tables if t.source == "primary"]
    scanned = [t for t in tables if t.source == "rdata_scan"]
    labeled = sum(1 for t in tables if t.namespace)
    print(
        f"Tables: {len(tables)} total ({len(primary)} cluster, {len(scanned)} rdata_scan); "
        f"{labeled} with verified namespace"
    )
    total = 0
    for i, table in enumerate(tables):
        total += len(table.entries)
        print(
            f"  [{i + 1:2d}] {table.label:20s} "
            f"foff 0x{table.start_foff:08X}  "
            f"({len(table.entries):4d} entries, {table.source})"
        )
    print(f"Total bindings: {total}")
    unlabeled = [t for t in tables if not t.namespace]
    if unlabeled:
        print(f"Unlabeled tables (offset only, do not treat as namespace): {len(unlabeled)}")


def build_self_test_pe(path: Path) -> None:
    image_base = IMAGE_BASE_DEFAULT
    file_align = 0x200
    sect_align = 0x1000
    text_raw, text_va, text_size = 0x200, 0x1000, 0x200
    rdata_raw, rdata_va, rdata_size = 0x400, 0x2000, 0x400

    func1 = image_base + text_va + 0x10
    func2 = image_base + text_va + 0x20
    func3 = image_base + text_va + 0x30

    rdata_blob = bytearray(rdata_size)
    rdata_blob[0:4] = b"Foo\x00"
    rdata_blob[4:8] = b"Bar\x00"
    rdata_blob[8:12] = b"Baz\x00"

    def sva(off: int) -> int:
        return image_base + rdata_va + off

    t1, t2 = 0x40, 0x60
    for i, (nva, fva) in enumerate(
        [(sva(0), func1), (sva(4), func2), (0, 0)]
    ):
        struct.pack_into("<II", rdata_blob, t1 + i * 8, nva, fva)
    for i, (nva, fva) in enumerate(
        [(sva(8), func3), (sva(0), func1), (0, 0)]
    ):
        struct.pack_into("<II", rdata_blob, t2 + i * 8, nva, fva)

    text_blob = bytes([0xC3]) * text_size

    dos = bytearray(0x80)
    dos[0:2] = b"MZ"
    struct.pack_into("<I", dos, 0x3C, 0x80)
    coff = struct.pack("<HHIIIHH", 0x14C, 2, 0, 0, 0, 224, 2)
    opt = bytearray(224)
    struct.pack_into("<H", opt, 0, 0x10B)
    struct.pack_into("<I", opt, 16, text_size)
    struct.pack_into("<I", opt, 28, image_base)
    struct.pack_into("<I", opt, 32, sect_align)
    struct.pack_into("<I", opt, 36, file_align)
    struct.pack_into("<H", opt, 68, 3)

    sections = []
    for name, vsize, vaddr, rsize, rptr in [
        (b".text\x00\x00\x00", text_size, text_va, text_size, text_raw),
        (b".rdata\x00\x00\x00", rdata_size, rdata_va, rdata_size, rdata_raw),
    ]:
        sec = bytearray(40)
        sec[0:8] = name[:8]
        struct.pack_into("<IIII", sec, 8, vsize, vaddr, rsize, rptr)
        sections.append(bytes(sec))

    headers_size = (0x80 + 4 + len(coff) + len(opt) + 80 + file_align - 1) // file_align * file_align
    out = bytearray(headers_size + text_size + rdata_size)
    out[0:0x80] = dos
    pe_start = 0x80
    out[pe_start : pe_start + 4] = b"PE\x00\x00"
    o = pe_start + 4
    out[o : o + len(coff)] = coff
    o += len(coff)
    out[o : o + len(opt)] = opt
    o += len(opt)
    for sec in sections:
        out[o : o + 40] = sec
        o += 40
    out[text_raw : text_raw + text_size] = text_blob
    out[rdata_raw : rdata_raw + rdata_size] = rdata_blob
    path.write_bytes(out)


def run_self_test() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        exe = Path(tmp) / "minimal.exe"
        build_self_test_pe(exe)
        pe = parse_pe(exe)
        assert pe.image_base == IMAGE_BASE_DEFAULT
        rdata = pe.section(".rdata")
        assert rdata is not None
        table = parse_table_at_offset(pe, rdata.raw_ptr + 0x60)
        assert table is not None and len(table.entries) == 2
        secondary = dump_rdata_scan_tables(pe, exclude=[])
        assert len(secondary) >= 1
    print("Self-test OK")
    return 0


def find_default_exe() -> Path | None:
    for rel in (
        "game-files/cracked-parts/Crack/Mercenaries2.exe",
        "output/patched/Mercenaries2.exe",
        "output/patched/MERCENAR.EXE",
    ):
        p = Path(rel)
        if p.is_file():
            return p
    return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--exe", type=Path, help="Path to cracked Mercenaries2.exe")
    parser.add_argument("--json", type=Path, help="Write JSON output")
    parser.add_argument("--csv", type=Path, help="Write CSV output")
    parser.add_argument(
        "--scan-rdata",
        action="store_true",
        help="Also scan all of .rdata for reg-like tables (many false positives; not for docs)",
    )
    parser.add_argument("--self-test", action="store_true", help="Run minimal PE fixture test")
    args = parser.parse_args()

    if args.self_test:
        return run_self_test()

    exe_path = args.exe or find_default_exe()
    if exe_path is None:
        print(
            "ERROR: No EXE found. Pass --exe or place Mercenaries2.exe at\n"
            "  game-files/cracked-parts/Crack/Mercenaries2.exe",
            file=sys.stderr,
        )
        return 1
    if not exe_path.is_file():
        print(f"ERROR: File not found: {exe_path}", file=sys.stderr)
        return 1

    pe = parse_pe(exe_path)
    primary = dump_primary_cluster(pe)
    scanned: list[BindingTable] = []
    if args.scan_rdata:
        scanned = dump_rdata_scan_tables(pe, exclude=primary)
    tables = sorted(primary + scanned, key=lambda t: t.start_foff)

    payload = {
        "exe": str(exe_path.resolve()),
        "exe_size": len(pe.data),
        "image_base": f"0x{pe.image_base:08X}",
        "primary_cluster": {
            "doc_file_start": f"0x{PRIMARY_FILE_START:08X}",
            "doc_file_end": f"0x{PRIMARY_FILE_END:08X}",
            "scan_file_end": f"0x{PRIMARY_FILE_SCAN_END:08X}",
        },
        "table_count": len(tables),
        "binding_count": sum(len(t.entries) for t in tables),
        "verified_namespace_table_count": sum(1 for t in tables if t.namespace),
        "cluster_table_count": len(primary),
        "cluster_binding_count": sum(len(t.entries) for t in primary),
        "rdata_scan_table_count": len(scanned),
        "rdata_scan_binding_count": sum(len(t.entries) for t in scanned),
        "tables": [t.to_dict() for t in tables],
        "rdata_scan_ranges": [
            {
                "start_foff": f"0x{t.start_foff:08X}",
                "start_va": f"0x{t.start_va:08X}",
                "end_foff": f"0x{t.end_foff:08X}",
                "namespace": t.namespace,
                "label": t.label,
                "entry_count": len(t.entries),
            }
            for t in scanned
        ],
    }

    print_summary(tables, pe)

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(payload, indent=2), encoding="utf-8")
        print(f"\nWrote JSON: {args.json}")
    if args.csv:
        write_csv(args.csv, tables)
        print(f"Wrote CSV: {args.csv}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
