#!/usr/bin/env python3
"""Dump all string/number constants, local variable names, and upvalue names
from a Lua 5.1 compiled chunk (.luac).

Handles both stock Lua 5.1 headers (\\x1bLua\\x51) and the Mercenaries 2
variant (\\x1bLuaQ\\x51) with 4-byte float lua_Number.

Usage:
  .venv/bin/python3 tools/lua_const_dump.py <file.luac> [--json]
"""
from __future__ import annotations

import argparse
import json
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Proto:
    source: str | None
    line_defined: int
    last_line_defined: int
    num_upvalues: int
    num_params: int
    is_vararg: int
    max_stack: int
    num_instructions: int
    constants: list[tuple[str, object]]  # (type_tag, value)
    children: list[Proto]
    locals: list[tuple[str, int, int]]   # (name, startpc, endpc)
    upvalue_names: list[str]
    depth: int = 0


class Parser:
    def __init__(self, data: bytes):
        self.data = data
        self.pos = 0

    def _byte(self) -> int:
        v = self.data[self.pos]
        self.pos += 1
        return v

    def _int(self) -> int:
        v = struct.unpack_from("<i", self.data, self.pos)[0]
        self.pos += 4
        return v

    def _uint32(self) -> int:
        v = struct.unpack_from("<I", self.data, self.pos)[0]
        self.pos += 4
        return v

    def _float(self) -> float:
        v = struct.unpack_from("<f", self.data, self.pos)[0]
        self.pos += 4
        return v

    def _string(self) -> str | None:
        size = self._uint32()
        if size == 0:
            return None
        raw = self.data[self.pos : self.pos + size]
        self.pos += size
        return raw[:-1].decode("latin-1", errors="replace") if size > 1 else ""

    def parse_header(self) -> None:
        # Lua 5.1 header: \x1bLua (4 bytes) + version(1) + format(1) + ...
        # The 'Q' (0x51) IS the version byte, not part of the signature.
        if self.data[self.pos : self.pos + 4] != b"\x1bLua":
            raise ValueError("Not a Lua chunk (missing \\x1bLua signature)")
        self.pos += 4
        ver = self._byte()
        if ver != 0x51:
            raise ValueError(f"Version 0x{ver:02X}, expected 0x51")
        self._byte()  # format (0 = official)
        self._byte()  # endianness (1 = little)
        int_size = self._byte()      # sizeof(int)
        size_t_size = self._byte()   # sizeof(size_t)
        instr_size = self._byte()    # sizeof(Instruction)
        number_size = self._byte()   # sizeof(lua_Number)
        integral_flag = self._byte() # 0 = floating point, 1 = integral
        self._int_size = int_size
        self._size_t_size = size_t_size
        self._instr_size = instr_size
        self._number_size_val = number_size
        self._integral = integral_flag

    def _read_number(self) -> float:
        if self._number_size_val == 8:
            v = struct.unpack_from("<d", self.data, self.pos)[0]
            self.pos += 8
            return v
        return self._float()

    def parse_function(self, depth: int = 0) -> Proto:
        source = self._string()
        line_def = self._int()
        last_line = self._int()
        nups = self._byte()
        nparams = self._byte()
        is_vararg = self._byte()
        max_stack = self._byte()

        # code
        code_size = self._int()
        self.pos += code_size * 4  # skip instruction words

        # constants
        nk = self._int()
        constants: list[tuple[str, object]] = []
        for _ in range(nk):
            t = self._byte()
            if t == 0:
                constants.append(("nil", None))
            elif t == 1:
                constants.append(("bool", bool(self._byte())))
            elif t == 3:
                constants.append(("number", self._read_number()))
            elif t == 4:
                constants.append(("string", self._string()))
            else:
                raise ValueError(f"Unknown const tag {t}")

        # protos (child functions)
        np = self._int()
        children = []
        for _ in range(np):
            children.append(self.parse_function(depth + 1))

        # line info (debug)
        nlines = self._int()
        self.pos += nlines * 4

        # locals (debug)
        nlocals = self._int()
        locals_list = []
        for _ in range(nlocals):
            name = self._string()
            startpc = self._int()
            endpc = self._int()
            locals_list.append((name or "", startpc, endpc))

        # upvalue names (debug)
        nupval_names = self._int()
        upval_names = []
        for _ in range(nupval_names):
            upval_names.append(self._string() or "")

        return Proto(
            source=source,
            line_defined=line_def,
            last_line_defined=last_line,
            num_upvalues=nups,
            num_params=nparams,
            is_vararg=is_vararg,
            max_stack=max_stack,
            num_instructions=code_size,
            constants=constants,
            children=children,
            locals=locals_list,
            upvalue_names=upval_names,
            depth=depth,
        )


def collect_strings(proto: Proto, prefix: str = "") -> list[dict]:
    """Recursively collect all string constants with context."""
    results = []
    label = prefix or proto.source or "(top)"

    for tag, val in proto.constants:
        if tag == "string" and val:
            results.append({"function": label, "depth": proto.depth, "value": val})

    for name, _, _ in proto.locals:
        if name and not name.startswith("("):
            results.append({"function": label, "depth": proto.depth,
                            "value": name, "kind": "local"})

    for name in proto.upvalue_names:
        if name:
            results.append({"function": label, "depth": proto.depth,
                            "value": name, "kind": "upvalue"})

    for i, child in enumerate(proto.children):
        child_label = f"{label}::child[{i}]@L{child.line_defined}"
        results.extend(collect_strings(child, child_label))

    return results


def print_proto_tree(proto: Proto, indent: int = 0) -> None:
    """Print a human-readable tree of the prototype hierarchy."""
    pad = "  " * indent
    label = proto.source or f"(anonymous@L{proto.line_defined})"
    print(f"{pad}Proto {label}  "
          f"[{proto.num_instructions} instr, {len(proto.constants)} const, "
          f"{len(proto.children)} children, {len(proto.locals)} locals, "
          f"{len(proto.upvalue_names)} upvals]")

    strings = [v for t, v in proto.constants if t == "string" and v]
    numbers = [v for t, v in proto.constants if t == "number"]

    if strings:
        print(f"{pad}  String constants ({len(strings)}):")
        for s in strings:
            display = s if len(s) <= 120 else s[:117] + "..."
            print(f"{pad}    \"{display}\"")
    if numbers:
        print(f"{pad}  Number constants ({len(numbers)}): {numbers[:20]}"
              + ("..." if len(numbers) > 20 else ""))
    if proto.locals:
        local_names = [n for n, _, _ in proto.locals if not n.startswith("(")]
        if local_names:
            print(f"{pad}  Locals: {', '.join(local_names)}")
    if proto.upvalue_names:
        print(f"{pad}  Upvalues: {', '.join(proto.upvalue_names)}")

    for child in proto.children:
        print_proto_tree(child, indent + 1)


def main() -> int:
    ap = argparse.ArgumentParser(description="Dump Lua 5.1 bytecode constants")
    ap.add_argument("file", type=Path, help=".luac file to analyze")
    ap.add_argument("--json", action="store_true", help="Output JSON instead")
    ap.add_argument("--strings-only", action="store_true",
                    help="Just list unique string constants")
    args = ap.parse_args()

    data = args.file.read_bytes()
    p = Parser(data)
    p.parse_header()
    top = p.parse_function()

    if args.strings_only:
        all_strs = collect_strings(top)
        seen: set[str] = set()
        for entry in all_strs:
            v = entry["value"]
            if v not in seen:
                print(v)
                seen.add(v)
        return 0

    if args.json:
        all_strs = collect_strings(top)
        print(json.dumps(all_strs, indent=2))
        return 0

    print(f"=== {args.file.name} ===\n")
    print_proto_tree(top)
    return 0


if __name__ == "__main__":
    sys.exit(main())
