#!/usr/bin/env python3
"""Instruction-boundary-aware Lua 5.1 bytecode scanner.

Finds precompiled chunks by signature, validates the luac header, walks Proto
trees, and only decodes ``code[]`` as aligned 32-bit VM instructions. Does NOT
treat arbitrary bytes inside string constants as opcodes.

Usage:
  .venv/bin/python3 tools/lua_bytecode_scan.py --exe output/patched/Mercenaries2.exe
  .venv/bin/python3 tools/lua_bytecode_scan.py --file fresh-rebuilt/data/vz-patch.wad
  .venv/bin/python3 tools/lua_bytecode_scan.py --file output/extracted/.../scripts_vz.block.bin
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path

# Lua 5.1 precompiled chunk (Mercenaries uses \x1bLuaQ — 'Q' after signature)
LUA_SIGNATURE = b"\x1bLua"
LUA_SIG_MERC = b"\x1bLuaQ"  # game / pipeline format per docs/dlc_bootstrap_implementation.md
LUAC_VERSION = 0x51
LUAC_FORMAT = 0
LUAC_HEADERSIZE = 12  # sig(4) + ver + fmt + endian + int + size_t + instr + number
SIZE_T_FLOAT = 4
NUMBER_FLOAT = 4

# VM: 6-bit opcode in low bits of 32-bit instruction
NUM_OPCODES = 40  # Lua 5.1 has opcodes 0..37; allow slack for sanity


class ParseError(Exception):
    pass


@dataclass
class ProtoInfo:
    code_size: int
    const_count: int
    upvalue_count: int
    proto_children: int
    lineinfo_size: int
    locvars: int
    upvalue_names: int
    valid_opcodes: int
    invalid_opcodes: int


@dataclass
class ChunkReport:
    offset: int
    source_label: str
    header_ok: bool
    error: str | None = None
    protos: list[ProtoInfo] = field(default_factory=list)
    total_instructions: int = 0


def get_opcode(instr: int) -> int:
    return instr & 0x3F


def is_sane_opcode(op: int) -> bool:
    return op < NUM_OPCODES


def read_byte(data: bytes, pos: int) -> tuple[int, int]:
    if pos >= len(data):
        raise ParseError("unexpected EOF (byte)")
    return data[pos], pos + 1


def read_int(data: bytes, pos: int) -> tuple[int, int]:
    if pos + 4 > len(data):
        raise ParseError("unexpected EOF (int)")
    return struct.unpack_from("<i", data, pos)[0], pos + 4


def read_uint32(data: bytes, pos: int) -> tuple[int, int]:
    if pos + 4 > len(data):
        raise ParseError("unexpected EOF (uint32)")
    return struct.unpack_from("<I", data, pos)[0], pos + 4


def read_number_float(data: bytes, pos: int) -> tuple[float, int]:
    if pos + 4 > len(data):
        raise ParseError("unexpected EOF (number)")
    return struct.unpack_from("<f", data, pos)[0], pos + 4


def read_size_t(data: bytes, pos: int) -> tuple[int, int]:
    return read_uint32(data, pos)


def read_string(data: bytes, pos: int) -> tuple[str | None, int]:
    size, pos = read_size_t(data, pos)
    if size == 0:
        return None, pos
    if pos + size > len(data):
        raise ParseError("string overruns buffer")
    raw = data[pos : pos + size]
    pos += size
    # includes trailing NUL
    return raw[:-1].decode("latin-1", errors="replace") if size > 1 else "", pos


def load_code(data: bytes, pos: int) -> tuple[tuple[int, ...], int, ProtoInfo]:
    n, pos = read_int(data, pos)
    if n < 0 or n > 1_000_000:
        raise ParseError(f"bad code size {n}")
    need = pos + n * 4
    if need > len(data):
        raise ParseError("code overruns buffer")
    if n > 0 and (pos % 4) != 0:
        raise ParseError("code array not 4-byte aligned")
    codes: list[int] = []
    valid = invalid = 0
    for _ in range(n):
        instr, pos = read_uint32(data, pos)
        codes.append(instr)
        op = get_opcode(instr)
        if is_sane_opcode(op):
            valid += 1
        else:
            invalid += 1
    meta = ProtoInfo(
        code_size=n,
        const_count=0,
        upvalue_count=0,
        proto_children=0,
        lineinfo_size=0,
        locvars=0,
        upvalue_names=0,
        valid_opcodes=valid,
        invalid_opcodes=invalid,
    )
    return tuple(codes), pos, meta


def load_constants(data: bytes, pos: int) -> tuple[int, int]:
    n, pos = read_int(data, pos)
    if n < 0 or n > 100_000:
        raise ParseError(f"bad constant count {n}")
    for _ in range(n):
        t, pos = read_byte(data, pos)
        if t == 0:  # LUA_TNIL
            continue
        if t == 1:  # LUA_TBOOLEAN
            _, pos = read_byte(data, pos)
        elif t == 3:  # LUA_TNUMBER (float build)
            _, pos = read_number_float(data, pos)
        elif t == 4:  # LUA_TSTRING
            _, pos = read_string(data, pos)
        else:
            raise ParseError(f"unknown constant tag {t}")
    return n, pos


def load_function(data: bytes, pos: int, depth: int = 0) -> tuple[list[ProtoInfo], int]:
    if depth > 64:
        raise ParseError("proto nesting too deep")
    source, pos = read_string(data, pos)
    _, pos = read_int(data, pos)  # linedefined
    _, pos = read_int(data, pos)  # lastlinedefined
    _, pos = read_byte(data, pos)  # nups
    _, pos = read_byte(data, pos)  # numparams
    _, pos = read_byte(data, pos)  # is_vararg
    _, pos = read_byte(data, pos)  # maxstacksize
    _, pos, meta = load_code(data, pos)
    const_n, pos = load_constants(data, pos)
    meta.const_count = const_n
    proto_n, pos = read_int(data, pos)
    if proto_n < 0 or proto_n > 10_000:
        raise ParseError(f"bad proto count {proto_n}")
    meta.proto_children = proto_n
    protos = [meta]
    for _ in range(proto_n):
        children, pos = load_function(data, pos, depth + 1)
        protos.extend(children)
    # line info
    line_n, pos = read_int(data, pos)
    meta.lineinfo_size = line_n
    if line_n < 0 or pos + line_n * 4 > len(data):
        raise ParseError("bad lineinfo")
    pos += line_n * 4
    loc_n, pos = read_int(data, pos)
    meta.locvars = loc_n
    for _ in range(loc_n):
        _, pos = read_string(data, pos)
        _, pos = read_int(data, pos)
        _, pos = read_int(data, pos)
    upn, pos = read_int(data, pos)
    meta.upvalue_names = upn
    for _ in range(upn):
        _, pos = read_string(data, pos)
    return protos, pos


def validate_header(data: bytes, pos: int) -> tuple[bool, int, str | None]:
    # header fields (7) + test lua_Number (4) after 4- or 5-byte signature
    if pos + 16 > len(data):
        return False, pos, "truncated header"
    if data[pos : pos + 5] == LUA_SIG_MERC:
        pos += 5  # \x1bLua + 'Q'
    elif data[pos : pos + 4] == LUA_SIGNATURE:
        pos += 4
    else:
        return False, pos, "bad signature (expected \\x1bLua or \\x1bLuaQ)"
    ver = data[pos]
    pos += 1
    if ver != LUAC_VERSION:
        return False, pos, f"version 0x{ver:02X} != 0x{LUAC_VERSION:02X}"
    fmt = data[pos]
    pos += 1
    if fmt != LUAC_FORMAT:
        return False, pos, f"format {fmt}"
    endian = data[pos]
    pos += 1
    if endian != 1:
        return False, pos, f"endian {endian} (expected 1=little)"
    int_size = data[pos]
    pos += 1
    if int_size != 4:
        return False, pos, f"int size {int_size}"
    size_t_size = data[pos]
    pos += 1
    if size_t_size != SIZE_T_FLOAT:
        return False, pos, f"size_t {size_t_size} (game uses 4)"
    instr_size = data[pos]
    pos += 1
    if instr_size != 4:
        return False, pos, f"instruction size {instr_size}"
    number_size = data[pos]
    pos += 1
    if number_size != NUMBER_FLOAT:
        return False, pos, f"number size {number_size}"
    _, pos = read_number_float(data, pos)  # LUAC_HEADERSIZE test number (5.0)
    return True, pos, None


def parse_chunk_at(data: bytes, offset: int, source_label: str) -> ChunkReport:
    rep = ChunkReport(offset=offset, source_label=source_label, header_ok=False)
    try:
        ok, pos, err = validate_header(data, offset)
        if not ok:
            rep.error = err
            return rep
        rep.header_ok = True
        protos, _ = load_function(data, pos)
        rep.protos = protos
        rep.total_instructions = sum(p.code_size for p in protos)
    except ParseError as e:
        rep.error = str(e)
    return rep


def find_chunk_offsets(data: bytes) -> list[int]:
    """Return offsets of Merc (\x1bLuaQ) and stock (\x1bLua) chunk starts."""
    seen: set[int] = set()
    for sig in (LUA_SIG_MERC, LUA_SIGNATURE):
        pos = 0
        while True:
            i = data.find(sig, pos)
            if i < 0:
                break
            if i not in seen:
                seen.add(i)
            pos = i + 1
    return sorted(seen)


def find_signatures(data: bytes, sig: bytes = LUA_SIGNATURE) -> list[int]:
    out: list[int] = []
    pos = 0
    while True:
        i = data.find(sig, pos)
        if i < 0:
            break
        out.append(i)
        pos = i + 1
    return out


def scan_blob(data: bytes, source_label: str, max_chunks: int = 500) -> list[ChunkReport]:
    reports: list[ChunkReport] = []
    for off in find_chunk_offsets(data):
        rep = parse_chunk_at(data, off, source_label)
        if rep.header_ok:
            reports.append(rep)
        if len(reports) >= max_chunks:
            break
    return reports


def main() -> int:
    ap = argparse.ArgumentParser(description="Boundary-aware Lua 5.1 bytecode scan")
    ap.add_argument("--exe", type=Path, help="Scan PE image for embedded chunks")
    ap.add_argument("--file", type=Path, help="Scan arbitrary file (WAD, block.bin, etc.)")
    ap.add_argument("--json", type=Path, help="Write JSON report")
    ap.add_argument("--max-chunks", type=int, default=200)
    args = ap.parse_args()
    if not args.exe and not args.file:
        ap.error("provide --exe and/or --file")

    all_reports: dict[str, list[dict[str, object]]] = {}

    if args.exe and args.exe.is_file():
        data = args.exe.read_bytes()
        reps = scan_blob(data, str(args.exe), args.max_chunks)
        all_reports[str(args.exe)] = [
            {
                "offset": r.offset,
                "header_ok": r.header_ok,
                "error": r.error,
                "proto_count": len(r.protos),
                "total_instructions": r.total_instructions,
                "invalid_opcode_ratio": (
                    sum(p.invalid_opcodes for p in r.protos)
                    / max(1, sum(p.valid_opcodes + p.invalid_opcodes for p in r.protos))
                ),
            }
            for r in reps
        ]
        offs = find_chunk_offsets(data)
        print(f"{args.exe}: {len(offs)} chunk offset(s), {len(reps)} header-valid")

    if args.file and args.file.is_file():
        data = args.file.read_bytes()
        reps = scan_blob(data, str(args.file), args.max_chunks)
        all_reports[str(args.file)] = [
            {
                "offset": r.offset,
                "header_ok": r.header_ok,
                "error": r.error,
                "proto_count": len(r.protos),
                "total_instructions": r.total_instructions,
            }
            for r in reps
        ]
        offs = find_chunk_offsets(data)
        print(f"{args.file}: {len(offs)} chunk offset(s), {len(reps)} header-valid")
        # Warn on bare 'LuaQ' substring without ESC (common false positive in compressed WAD)
        bare = []
        pos = 0
        while True:
            i = data.find(b"LuaQ", pos)
            if i < 0:
                break
            if (i == 0 or data[i - 1] != 0x1B) and (i < 4 or data[i - 4 : i] != LUA_SIGNATURE):
                bare.append(i)
            pos = i + 1
        if bare and not offs:
            print(f"  warning: {len(bare)} bare 'LuaQ' substring(s) — not valid chunks without \\x1bLuaQ header")

    if args.json:
        args.json.parent.mkdir(parents=True, exist_ok=True)
        args.json.write_text(json.dumps(all_reports, indent=2), encoding="utf-8")
        print(f"Wrote {args.json}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
