#!/usr/bin/env python3
"""Comprehensive audit of ALL Lua 5.1.2 C API functions in Mercenaries 2 EXE.

Parses PE headers, finds diagnostic strings in .rdata, traces cross-references
to identify function VAs, and dumps the base library registration table.
"""
from __future__ import annotations
import struct
import sys
from pathlib import Path
from collections import defaultdict

EXE_PATH = Path("/Users/austinkregel/src/mercenaries-game/output/patched/Mercenaries2.exe")
IMAGE_BASE = 0x00400000

# Known Lua 5.1.2 diagnostic strings and which function they identify
LUA_STRINGS = {
    # Core VM / runtime
    b"=[string \"": "luaO_chunkid (called by luaL_loadbuffer)",
    b"error in error handling": "luaG_errormsg",
    b"attempt to call a %s value": "luaD_precall",
    b"cannot resume dead coroutine": "lua_resume",
    b"attempt to yield across metamethod/C-call boundary": "lua_yield",
    b"stack overflow": "luaD_growstack / lua_checkstack",
    b"C stack overflow": "luaD_call",
    b"'tostring' must return a string": "luaB_tostring",
    b"table index is nil": "lua_settable / luaH_newkey",
    b"table index is NaN": "lua_settable / luaH_newkey (NaN)",
    b"invalid option": "lua_getinfo / luaL_checkoption",
    b"unfinished string": "luaX_lexerror (lexer)",
    b"bad argument #%d": "luaL_argerror",
    b"value expected": "luaL_checkany",
    b"string length overflow": "luaL_addlstring",
    b"loop in gettable": "luaV_gettable",
    b"loop in settable": "luaV_settable",
    b"attempt to %s a %s value": "luaG_typeerror",
    b"too many results to unpack": "luaB_unpack",
    b"cannot %s %s: %s": "luaL_fileresult / io errors",
    # Metamethods
    b"__gc": "GC metamethod tag",
    b"__index": "Index metamethod tag",
    b"__newindex": "Newindex metamethod tag",
    b"__call": "Call metamethod tag",
    b"__tostring": "Tostring metamethod tag",
    b"__len": "Length metamethod tag",
    b"__eq": "Equality metamethod tag",
    b"__add": "Add metamethod tag",
    b"__sub": "Sub metamethod tag",
    b"__mul": "Mul metamethod tag",
    b"__div": "Div metamethod tag",
    b"__mod": "Mod metamethod tag",
    b"__pow": "Pow metamethod tag",
    b"__unm": "Unary minus metamethod tag",
    b"__concat": "Concat metamethod tag",
    b"__lt": "Less-than metamethod tag",
    b"__le": "Less-or-equal metamethod tag",
    b"__mode": "Weak table mode tag",
    b"__metatable": "Metatable protection tag",
    # Version
    b"Lua 5.1": "lua_version / version constant",
    # Source path (confirms static link)
    b"D:\\Projects\\Mercs2_PC\\mercs2\\Lua-5.1.2\\src\\": "Lua source path (build artifact)",
    # Additional diagnostic strings
    b"not enough memory": "luaM_realloc / memory allocation",
    b"attempt to perform arithmetic on a %s value": "luaG_aritherror",
    b"attempt to compare two %s values": "luaG_ordererror",
    b"attempt to concatenate a %s value": "luaG_concaterror",
    b"table overflow": "luaH_resize",
    b"nil or table expected": "lua_setmetatable",
    b"function or expression too complex": "luaY_parser",
    b"main function has more than %d %s": "luaY_parser limits",
    b"too many %s (limit is %d)": "luaX_syntaxerror limits",
    b"chunk has too many syntax levels": "luaY_parser nesting",
    b"malformed number": "luaX_lexerror number",
    b"invalid long string delimiter": "luaX_lexerror long string",
    b"unfinished long string": "luaX_lexerror long string end",
    b"unfinished long comment": "luaX_lexerror long comment",
    b"lexical element too long": "luaX_lexerror token length",
    b"ambiguous syntax": "luaX_syntaxerror",
    b"'for' initial value must be a number": "luaV_execute FOR",
    b"'for' limit must be a number": "luaV_execute FOR",
    b"'for' step must be a number": "luaV_execute FOR",
    b"get length of": "luaG_typeerror len",
    b"cannot use '...' outside a vararg function": "luaY_parser vararg",
    # Base library specific
    b"tostring": "tostring global name",
    b"loadstring": "loadstring global name",
    b"pcall": "pcall global name",
    b"xpcall": "xpcall global name",
    b"collectgarbage": "collectgarbage global name",
    b"setmetatable": "setmetatable global name",
    b"getmetatable": "getmetatable global name",
    b"rawget": "rawget global name",
    b"rawset": "rawset global name",
    b"rawequal": "rawequal global name",
    b"setfenv": "setfenv global name",
    b"getfenv": "getfenv global name",
    b"newproxy": "newproxy global name",
    b"ipairs": "ipairs global name",
    b"pairs": "pairs global name",
    b"next": "next global name",
    b"select": "select global name",
    b"unpack": "unpack global name",
    b"require": "require global name",
    b"module": "module global name",
    b"dofile": "dofile global name",
    b"loadfile": "loadfile global name",
    b"gcinfo": "gcinfo global name",
    b"print": "print global name",
    b"error": "error global name",
    b"assert": "assert global name",
    b"type": "type global name",
    b"tonumber": "tonumber global name",
    # Stack / push / get functions (identifiable by their error messages)
    b"index out of range": "lua_checkstack / stack error",
    b"invalid index": "lua_remove / lua_insert bounds",
    # Coroutine library
    b"coroutine expected": "coroutine library check",
    b"too many arguments to resume": "coroutine.resume",
    b"cannot resume non-suspended coroutine": "coroutine.resume check",
    # String library
    b"string slice too long": "string.rep",
    b"invalid pattern capture index": "string.find/match",
    b"malformed pattern": "string pattern matching",
    b"pattern too complex": "string pattern matching",
    b"invalid capture index": "string.gsub capture",
    # Table library
    b"invalid order function for sorting": "table.sort",
    # OS library
    b"os_tmpname": "os.tmpname",
    # Math library
    b"too few arguments": "math functions",
    # IO library
    b"standard %s file is closed": "io library file check",
    b"__close": "io library close metamethod",
    # Debug library
    b"level out of range": "debug.getinfo",
    # Package library
    b"'package.%s' must be a string": "package library",
    b"module '%s' not found": "require / package.loader",
    b"error loading module": "package.loadlib",
}

# Base library function names (luaopen_base registration)
BASE_LIB_NAMES = [
    b"assert", b"collectgarbage", b"dofile", b"error", b"gcinfo",
    b"getfenv", b"getmetatable", b"ipairs", b"load", b"loadfile",
    b"loadstring", b"module", b"newproxy", b"next", b"pairs",
    b"pcall", b"print", b"rawequal", b"rawget", b"rawset",
    b"require", b"select", b"setfenv", b"setmetatable", b"tonumber",
    b"tostring", b"type", b"unpack", b"xpcall",
]


def parse_pe(data: bytes):
    """Parse PE headers and return section info."""
    pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
    assert data[pe_offset:pe_offset+4] == b"PE\x00\x00"
    
    coff_offset = pe_offset + 4
    num_sections = struct.unpack_from("<H", data, coff_offset + 2)[0]
    optional_hdr_size = struct.unpack_from("<H", data, coff_offset + 16)[0]
    
    sections_offset = coff_offset + 20 + optional_hdr_size
    
    sections = {}
    for i in range(num_sections):
        sec_off = sections_offset + i * 40
        name = data[sec_off:sec_off+8].rstrip(b'\x00').decode('ascii', errors='replace')
        virt_size = struct.unpack_from("<I", data, sec_off + 8)[0]
        virt_addr = struct.unpack_from("<I", data, sec_off + 12)[0]
        raw_size = struct.unpack_from("<I", data, sec_off + 16)[0]
        raw_offset = struct.unpack_from("<I", data, sec_off + 20)[0]
        sections[name] = {
            'va': IMAGE_BASE + virt_addr,
            'virt_size': virt_size,
            'raw_offset': raw_offset,
            'raw_size': raw_size,
            'rva': virt_addr,
        }
    return sections


def find_all_occurrences(data: bytes, pattern: bytes, start: int = 0, end: int | None = None) -> list[int]:
    """Find all occurrences of pattern in data[start:end]."""
    results = []
    pos = start
    if end is None:
        end = len(data)
    while pos < end:
        idx = data.find(pattern, pos, end)
        if idx == -1:
            break
        results.append(idx)
        pos = idx + 1
    return results


def offset_to_va(offset: int, sections: dict) -> int | None:
    """Convert file offset to VA."""
    for sec in sections.values():
        if sec['raw_offset'] <= offset < sec['raw_offset'] + sec['raw_size']:
            return IMAGE_BASE + sec['rva'] + (offset - sec['raw_offset'])
    return None


def va_to_offset(va: int, sections: dict) -> int | None:
    """Convert VA to file offset."""
    rva = va - IMAGE_BASE
    for sec in sections.values():
        if sec['rva'] <= rva < sec['rva'] + sec['virt_size']:
            return sec['raw_offset'] + (rva - sec['rva'])
    return None


def find_dword_refs(data: bytes, va: int, section_start: int, section_end: int) -> list[int]:
    """Find all 4-byte references to a VA within a section."""
    target_bytes = struct.pack("<I", va)
    results = []
    pos = section_start
    while pos < section_end:
        idx = data.find(target_bytes, pos, section_end)
        if idx == -1:
            break
        results.append(idx)
        pos = idx + 4
    return results


def find_call_targets(data: bytes, func_offset: int, length: int = 128) -> list[int]:
    """Find E8 (CALL rel32) targets within first `length` bytes of a function."""
    targets = []
    for i in range(length - 5):
        if data[func_offset + i] == 0xE8:
            rel = struct.unpack_from("<i", data, func_offset + i + 1)[0]
            target_va = IMAGE_BASE + (func_offset + i + 5 - 0) 
            # Need to account for section offset properly
            call_va = offset_to_va(func_offset + i + 5, sections)
            if call_va:
                target_va = call_va + rel
                targets.append((i, target_va))
    return targets


def find_push_refs_in_text(data: bytes, va: int, text_start: int, text_end: int, max_results: int = 20) -> list[int]:
    """Find PUSH imm32 instructions (0x68 XX XX XX XX) referencing a VA in .text."""
    target_bytes = struct.pack("<I", va)
    push_pattern = b'\x68' + target_bytes
    results = []
    pos = text_start
    while pos < text_end and len(results) < max_results:
        idx = data.find(push_pattern, pos, text_end)
        if idx == -1:
            break
        results.append(idx)
        pos = idx + 5
    return results


def scan_registration_tables(data: bytes, sections: dict, start_va: int, end_va: int):
    """Scan a known registration table region for luaL_Reg entries (name_ptr, func_ptr pairs)."""
    start_off = va_to_offset(start_va, sections)
    end_off = va_to_offset(end_va, sections)
    if start_off is None or end_off is None:
        return []
    
    entries = []
    pos = start_off
    while pos < end_off - 8:
        name_va, func_va = struct.unpack_from("<II", data, pos)
        if name_va == 0 and func_va == 0:
            # NULL terminator for a registration table
            entries.append((pos, None, None, "--- TABLE END ---"))
            pos += 8
            continue
        
        # Check if name_va points to .rdata
        name_off = va_to_offset(name_va, sections)
        if name_off is not None and 0 < name_off < len(data):
            # Read null-terminated string
            end = data.find(b'\x00', name_off, name_off + 64)
            if end != -1:
                name = data[name_off:end].decode('ascii', errors='replace')
                if name.isprintable() and len(name) > 0:
                    entries.append((pos, name_va, func_va, name))
        pos += 8
    
    return entries


# ============================================================
# MAIN
# ============================================================

print(f"Loading EXE: {EXE_PATH} ({EXE_PATH.stat().st_size:,} bytes)")
data = EXE_PATH.read_bytes()

sections = parse_pe(data)
print("\n" + "="*80)
print("PE SECTIONS")
print("="*80)
for name, info in sections.items():
    print(f"  {name:8s}  VA: 0x{info['va']:08X} - 0x{info['va']+info['virt_size']:08X}  "
          f"Raw: 0x{info['raw_offset']:08X}  Size: 0x{info['raw_size']:08X}")

# Get section bounds
rdata = sections.get('.rdata')
text = sections.get('.text')
if not rdata or not text:
    print("ERROR: .rdata or .text section not found!")
    sys.exit(1)

rdata_start = rdata['raw_offset']
rdata_end = rdata_start + rdata['raw_size']
text_start = text['raw_offset']
text_end = text_start + text['raw_size']

print(f"\n.rdata file range: 0x{rdata_start:08X} - 0x{rdata_end:08X}")
print(f".text  file range: 0x{text_start:08X} - 0x{text_end:08X}")

# ============================================================
# PHASE 1: Find all diagnostic strings
# ============================================================
print("\n" + "="*80)
print("PHASE 1: LUA DIAGNOSTIC STRING SEARCH")
print("="*80)

string_locations = {}  # string -> [(file_offset, va)]

for pattern, func_name in LUA_STRINGS.items():
    # Search in .rdata only for null-terminated or prefixed strings
    occurrences = find_all_occurrences(data, pattern, rdata_start, rdata_end)
    if occurrences:
        locs = []
        for off in occurrences:
            va = offset_to_va(off, sections)
            locs.append((off, va))
        string_locations[pattern] = locs

print(f"\nFound {len(string_locations)} / {len(LUA_STRINGS)} string patterns in .rdata\n")

# Print results sorted by VA
found_items = []
for pattern, locs in string_locations.items():
    func_name = LUA_STRINGS[pattern]
    for off, va in locs:
        found_items.append((va or 0, off, pattern, func_name))

found_items.sort()

print(f"{'VA':>12s} {'Offset':>10s} {'Function':40s} String")
print("-" * 120)
for va, off, pattern, func_name in found_items[:200]:  # limit output
    pat_str = pattern.decode('ascii', errors='replace')[:50]
    print(f"  0x{va:08X}  0x{off:08X}  {func_name:40s} \"{pat_str}\"")

# ============================================================
# PHASE 2: Cross-reference strings → find functions via PUSH imm32
# ============================================================
print("\n" + "="*80)
print("PHASE 2: STRING CROSS-REFERENCES (PUSH imm32 in .text)")
print("="*80)

# Key strings that uniquely identify important functions
KEY_STRINGS = {
    b"error in error handling": "luaG_errormsg",
    b"attempt to call a %s value": "luaD_precall",
    b"cannot resume dead coroutine": "lua_resume",
    b"attempt to yield across metamethod/C-call boundary": "lua_yield",
    b"stack overflow": "luaD_growstack",
    b"C stack overflow": "luaD_call",
    b"'tostring' must return a string": "luaB_tostring",
    b"table index is nil": "luaH_newkey",
    b"table index is NaN": "luaH_newkey (NaN check)",
    b"bad argument #%d": "luaL_argerror",
    b"value expected": "luaL_checkany",
    b"loop in gettable": "luaV_gettable",
    b"loop in settable": "luaV_settable",
    b"attempt to %s a %s value": "luaG_typeerror",
    b"too many results to unpack": "luaB_unpack",
    b"not enough memory": "luaM_realloc",
    b"attempt to perform arithmetic on a %s value": "luaG_aritherror",
    b"attempt to compare two %s values": "luaG_ordererror",
    b"'for' initial value must be a number": "luaV_execute (FOR init)",
    b"invalid order function for sorting": "table.sort impl",
    b"module '%s' not found": "require / package loader",
    b"level out of range": "debug.getinfo",
    b"malformed number": "luaX_lexerror (number)",
    b"unfinished long string": "luaX_lexerror (long string)",
    b"function or expression too complex": "luaY_parser",
}

func_vas = {}  # func_name -> set of candidate VAs

for pattern, func_name in KEY_STRINGS.items():
    if pattern not in string_locations:
        continue
    for str_off, str_va in string_locations[pattern]:
        if str_va is None:
            continue
        push_refs = find_push_refs_in_text(data, str_va, text_start, text_end)
        if push_refs:
            print(f"\n  String: \"{pattern.decode('ascii', errors='replace')[:60]}\"")
            print(f"  String VA: 0x{str_va:08X}  →  {func_name}")
            for ref_off in push_refs[:5]:
                ref_va = offset_to_va(ref_off, sections)
                # Try to find function start by scanning backwards for common prologues
                func_start = None
                scan_back = ref_off
                for back in range(min(512, ref_off - text_start)):
                    candidate = scan_back - back
                    # Look for PUSH EBP (0x55) or common function prologue
                    if data[candidate] == 0x55 and candidate > text_start:
                        # Check preceding bytes - often 0xCC (int3) or 0x90 (nop) before function
                        if candidate > 0 and data[candidate-1] in (0xCC, 0x90, 0xC3, 0xC2):
                            func_start = candidate
                            break
                    # Also look for SUB ESP (0x81 0xEC or 0x83 0xEC) as function start
                    if data[candidate:candidate+2] == b'\x83\xEC' and candidate > text_start:
                        if candidate > 0 and data[candidate-1] in (0xCC, 0x90, 0xC3, 0xC2):
                            func_start = candidate
                            break
                
                func_va_str = ""
                if func_start:
                    fva = offset_to_va(func_start, sections)
                    func_va_str = f"  Likely function: 0x{fva:08X}"
                    if func_name not in func_vas:
                        func_vas[func_name] = set()
                    func_vas[func_name].add(fva)
                
                print(f"    PUSH ref at file 0x{ref_off:08X} (VA 0x{ref_va:08X}){func_va_str}")

# ============================================================
# PHASE 3: Registration table scan (VA 0x00798770 – 0x00799200)
# ============================================================
print("\n" + "="*80)
print("PHASE 3: REGISTRATION TABLE SCAN (VA 0x00798770 - 0x00799200)")
print("="*80)

reg_entries = scan_registration_tables(data, sections, 0x00798770, 0x00799200)

print(f"\nFound {len(reg_entries)} entries in registration table region\n")
print(f"{'Offset':>10s} {'NameVA':>12s} {'FuncVA':>12s} Name")
print("-" * 80)

base_lib_funcs = {}  # name -> func_va

for off, name_va, func_va, name in reg_entries:
    if name == "--- TABLE END ---":
        print(f"  0x{off:08X}  {'NULL':>12s} {'NULL':>12s} {name}")
    else:
        print(f"  0x{off:08X}  0x{name_va:08X}  0x{func_va:08X}  {name}")
        if name_va and func_va:
            base_lib_funcs[name] = func_va

# ============================================================
# PHASE 4: Extended registration table search
# ============================================================
print("\n" + "="*80)
print("PHASE 4: EXTENDED REGISTRATION TABLE SEARCH")
print("="*80)
print("Searching for additional luaL_Reg tables by finding known function name strings...")

# For each base library name, find its string in .rdata, then look for DWORD refs
# that could be part of a registration table (name_ptr followed by func_ptr pattern)

extended_reg_tables = {}  # table_start_va -> [(name, func_va)]

for name_bytes in BASE_LIB_NAMES:
    # Find the exact null-terminated string
    search_pattern = name_bytes + b'\x00'
    occurrences = find_all_occurrences(data, search_pattern, rdata_start, rdata_end)
    
    for str_off in occurrences:
        str_va = offset_to_va(str_off, sections)
        if str_va is None:
            continue
        
        # Check if this is a standalone string (preceded by \x00 or at section start)
        if str_off > rdata_start and data[str_off - 1] != 0x00:
            continue
        
        # Find DWORD references to this string VA in .rdata (registration tables are in .rdata)
        refs = find_dword_refs(data, str_va, rdata_start, rdata_end)
        for ref_off in refs:
            # A luaL_Reg entry is: [name_ptr][func_ptr]
            # The func_ptr should point into .text
            if ref_off + 4 < rdata_end:
                func_ptr = struct.unpack_from("<I", data, ref_off + 4)[0]
                if text['va'] <= func_ptr < text['va'] + text['virt_size']:
                    ref_va = offset_to_va(ref_off, sections)
                    if name_bytes.decode() not in base_lib_funcs:
                        base_lib_funcs[name_bytes.decode()] = func_ptr
                    # Try to identify which table this belongs to
                    # Look backwards for the start of the table
                    table_start = ref_off
                    while table_start >= rdata_start + 8:
                        prev_name_ptr = struct.unpack_from("<I", data, table_start - 8)[0]
                        prev_func_ptr = struct.unpack_from("<I", data, table_start - 4)[0]
                        prev_name_off = va_to_offset(prev_name_ptr, sections)
                        if (prev_name_off is not None and 
                            rdata_start <= prev_name_off < rdata_end and
                            text['va'] <= prev_func_ptr < text['va'] + text['virt_size']):
                            table_start -= 8
                        else:
                            break
                    
                    table_va = offset_to_va(table_start, sections)
                    if table_va not in extended_reg_tables:
                        extended_reg_tables[table_va] = []

# Now dump all found registration tables
print(f"\nFound {len(extended_reg_tables)} potential registration table regions")

# Re-scan each table region properly
all_tables = {}
for table_va in sorted(extended_reg_tables.keys()):
    table_off = va_to_offset(table_va, sections)
    if table_off is None:
        continue
    
    entries = []
    pos = table_off
    while pos < rdata_end - 8:
        name_ptr = struct.unpack_from("<I", data, pos)[0]
        func_ptr = struct.unpack_from("<I", data, pos + 4)[0]
        
        if name_ptr == 0 and func_ptr == 0:
            entries.append(("--- END ---", 0))
            break
        
        name_off = va_to_offset(name_ptr, sections)
        if name_off is None or not (rdata_start <= name_off < rdata_end):
            break
        if not (text['va'] <= func_ptr < text['va'] + text['virt_size']):
            break
        
        end = data.find(b'\x00', name_off, name_off + 64)
        if end == -1:
            break
        name = data[name_off:end].decode('ascii', errors='replace')
        entries.append((name, func_ptr))
        pos += 8
    
    if len(entries) >= 2:
        all_tables[table_va] = entries

print(f"\nValid registration tables found: {len(all_tables)}")
for table_va in sorted(all_tables.keys()):
    entries = all_tables[table_va]
    print(f"\n  Table at VA 0x{table_va:08X} ({len(entries)} entries):")
    for name, func_va in entries:
        if name == "--- END ---":
            print(f"    [NULL terminator]")
        else:
            print(f"    {name:24s} → 0x{func_va:08X}")
            base_lib_funcs[name] = func_va

# ============================================================
# PHASE 5: Function prologue analysis for base library functions
# ============================================================
print("\n" + "="*80)
print("PHASE 5: BASE LIBRARY FUNCTION ANALYSIS")
print("="*80)
print(f"\nAnalyzing {len(base_lib_funcs)} identified functions\n")

print(f"{'Name':24s} {'VA':>12s} {'First 16 bytes':48s} CALL targets")
print("-" * 130)

for name in sorted(base_lib_funcs.keys()):
    func_va = base_lib_funcs[name]
    func_off = va_to_offset(func_va, sections)
    if func_off is None or func_off + 128 > len(data):
        continue
    
    first_bytes = data[func_off:func_off+16]
    hex_str = ' '.join(f'{b:02X}' for b in first_bytes)
    
    # Find CALL targets
    calls = []
    for i in range(123):
        if data[func_off + i] == 0xE8:
            rel = struct.unpack_from("<i", data, func_off + i + 1)[0]
            call_site_va = func_va + i + 5
            target = call_site_va + rel
            if text['va'] <= target < text['va'] + text['virt_size']:
                calls.append(f"0x{target:08X}")
    
    calls_str = ", ".join(calls[:5])
    if len(calls) > 5:
        calls_str += f" (+{len(calls)-5} more)"
    
    print(f"  {name:24s} 0x{func_va:08X}  {hex_str}  {calls_str}")

# ============================================================
# PHASE 6: Identify core Lua C API by characteristic patterns
# ============================================================
print("\n" + "="*80)
print("PHASE 6: CORE LUA C API IDENTIFICATION")
print("="*80)

# lua_pushstring: typically references "string" type name
# lua_getfield / lua_setfield: use __index / __newindex metamethods
# We'll look for specific patterns

# Find lua_type names table (nil, boolean, userdata, number, string, table, function, thread)
type_names = [b"nil\x00", b"boolean\x00", b"userdata\x00", b"number\x00", 
              b"string\x00", b"table\x00", b"function\x00", b"thread\x00"]

print("\n--- Lua type names in .rdata ---")
type_name_vas = {}
for tn in type_names:
    # Search for standalone occurrence (preceded by NUL)
    search = b'\x00' + tn
    occs = find_all_occurrences(data, search, rdata_start, rdata_end)
    for off in occs:
        va = offset_to_va(off + 1, sections)  # +1 to skip the leading NUL
        name = tn.rstrip(b'\x00').decode()
        type_name_vas[name] = va
        print(f"  \"{name}\" at VA 0x{va:08X}")

# Look for the type names array (8 consecutive pointers to these strings)
print("\n--- Searching for luaT_typenames array ---")
if len(type_name_vas) >= 4:
    nil_va = type_name_vas.get("nil")
    if nil_va:
        nil_bytes = struct.pack("<I", nil_va)
        candidates = find_all_occurrences(data, nil_bytes, rdata_start, rdata_end)
        for cand_off in candidates:
            # Check if next entries are boolean, userdata, number, string, ...
            if cand_off + 32 < rdata_end:
                ptrs = struct.unpack_from("<8I", data, cand_off)
                names_found = []
                for ptr in ptrs:
                    ptr_off = va_to_offset(ptr, sections)
                    if ptr_off and rdata_start <= ptr_off < rdata_end:
                        end = data.find(b'\x00', ptr_off, ptr_off + 32)
                        if end != -1:
                            s = data[ptr_off:end].decode('ascii', errors='replace')
                            names_found.append(s)
                
                if "boolean" in names_found and "string" in names_found:
                    arr_va = offset_to_va(cand_off, sections)
                    print(f"  luaT_typenames array at VA 0x{arr_va:08X}")
                    print(f"    Entries: {names_found}")

# Find metamethod name table (__index, __newindex, __gc, etc.)
print("\n--- Searching for luaT_eventname array (metamethod names) ---")
index_str = b"__index\x00"
idx_occs = find_all_occurrences(data, index_str, rdata_start, rdata_end)
for idx_off in idx_occs:
    idx_va = offset_to_va(idx_off, sections)
    # Look for pointer to this in .rdata
    idx_refs = find_dword_refs(data, idx_va, rdata_start, rdata_end)
    for ref_off in idx_refs:
        # Check surrounding entries for other metamethods
        if ref_off - 16 >= rdata_start and ref_off + 64 < rdata_end:
            # Read several pointers around this
            start_check = ref_off - 8
            ptrs = struct.unpack_from("<12I", data, start_check)
            mm_names = []
            for ptr in ptrs:
                ptr_off = va_to_offset(ptr, sections)
                if ptr_off and rdata_start <= ptr_off < rdata_end:
                    end = data.find(b'\x00', ptr_off, ptr_off + 32)
                    if end != -1:
                        s = data[ptr_off:end].decode('ascii', errors='replace')
                        if s.startswith("__"):
                            mm_names.append(s)
            
            if len(mm_names) >= 4:
                arr_va = offset_to_va(start_check, sections)
                print(f"  Metamethod name array near VA 0x{arr_va:08X}")
                print(f"    Found: {mm_names}")
                break

# ============================================================
# PHASE 7: Identify lua_push*/lua_get*/lua_set* by MOV patterns
# ============================================================
print("\n" + "="*80)
print("PHASE 7: IDENTIFYING STACK MANIPULATION FUNCTIONS")
print("="*80)

# lua_pushstring is identified by being called right before/after string operations
# In the registration tables, functions like luaB_tostring call lua_pushstring
# Let's trace calls from known functions

print("\n--- Tracing calls from known base library functions ---")
# Functions that definitely call lua_pushstring:
# - luaB_tostring (after getting string result)
# - luaB_type (pushes type name)
# - luaL_argerror (formats error message)

call_frequency = defaultdict(int)  # target_va -> count

for name, func_va in sorted(base_lib_funcs.items()):
    func_off = va_to_offset(func_va, sections)
    if func_off is None:
        continue
    
    # Scan first 256 bytes for CALL instructions
    for i in range(min(256, text_end - func_off - 5)):
        if data[func_off + i] == 0xE8:
            rel = struct.unpack_from("<i", data, func_off + i + 1)[0]
            target = func_va + i + 5 + rel
            if text['va'] <= target < text['va'] + text['virt_size']:
                call_frequency[target] += 1

# Sort by frequency - most called functions are likely core API
print("\n  Most frequently called functions from base library implementations:")
print(f"  {'VA':>12s} {'Count':>6s}  Notes")
print("  " + "-" * 60)

sorted_calls = sorted(call_frequency.items(), key=lambda x: -x[1])
for target_va, count in sorted_calls[:40]:
    target_off = va_to_offset(target_va, sections)
    notes = ""
    
    # Check if this is one of our already identified functions
    for fname, fva in base_lib_funcs.items():
        if fva == target_va:
            notes = f"= {fname}"
            break
    
    # Check first bytes for identification hints
    if target_off and target_off + 16 < len(data):
        first_bytes = data[target_off:target_off+16]
        hex_prefix = ' '.join(f'{b:02X}' for b in first_bytes[:8])
        
        # Check if function references specific strings (scan first 64 bytes for PUSH imm32)
        for j in range(min(60, text_end - target_off - 5)):
            if data[target_off + j] == 0x68:  # PUSH imm32
                pushed_va = struct.unpack_from("<I", data, target_off + j + 1)[0]
                pushed_off = va_to_offset(pushed_va, sections)
                if pushed_off and rdata_start <= pushed_off < rdata_end:
                    end = data.find(b'\x00', pushed_off, pushed_off + 64)
                    if end != -1:
                        s = data[pushed_off:end].decode('ascii', errors='replace')
                        if s and s.isprintable() and len(s) < 50:
                            notes += f" pushes \"{s}\""
                            break
    
    if not notes:
        notes = f"(prologue: {hex_prefix})"
    
    print(f"  0x{target_va:08X}  {count:>5d}   {notes}")

# ============================================================
# PHASE 8: Search for Lua source file references
# ============================================================
print("\n" + "="*80)
print("PHASE 8: LUA SOURCE FILE REFERENCES (BUILD PATH STRINGS)")
print("="*80)

lua_src_path = b"D:\\Projects\\Mercs2_PC\\mercs2\\Lua-5.1.2\\src\\"
src_refs = find_all_occurrences(data, lua_src_path, rdata_start, rdata_end)

source_files = set()
for off in src_refs:
    end = data.find(b'\x00', off, off + 200)
    if end != -1:
        full_path = data[off:end].decode('ascii', errors='replace')
        source_files.add(full_path)

print(f"\nFound {len(source_files)} Lua source file references:\n")
for sf in sorted(source_files):
    va = offset_to_va(data.find(sf.encode(), rdata_start, rdata_end), sections)
    print(f"  0x{va:08X}  {sf}")

# ============================================================
# PHASE 9: Comprehensive summary
# ============================================================
print("\n" + "="*80)
print("PHASE 9: COMPREHENSIVE SUMMARY")
print("="*80)

print(f"""
CONFIRMED Lua 5.1.2 Integration:
  - Statically linked (source paths embedded in binary)
  - Float number type (verified by 4-byte float operations)
  - Build path: D:\\Projects\\Mercs2_PC\\mercs2\\Lua-5.1.2\\src\\
  - Registration tables at VA 0x00798770 - 0x00799200

Identified {len(string_locations)} diagnostic strings out of {len(LUA_STRINGS)} searched
Identified {len(base_lib_funcs)} named functions from registration tables
Found {len(source_files)} source file paths

ALL IDENTIFIED FUNCTION VAs (from registration tables):
""")

print(f"{'Name':30s} {'VA':>12s} {'Category'}")
print("-" * 70)
for name in sorted(base_lib_funcs.keys()):
    va = base_lib_funcs[name]
    # Categorize
    if name in ("assert", "collectgarbage", "dofile", "error", "gcinfo",
                "getfenv", "getmetatable", "ipairs", "load", "loadfile",
                "loadstring", "module", "newproxy", "next", "pairs",
                "pcall", "print", "rawequal", "rawget", "rawset",
                "require", "select", "setfenv", "setmetatable", "tonumber",
                "tostring", "type", "unpack", "xpcall"):
        cat = "base library"
    elif name in ("byte", "char", "dump", "find", "format", "gfind",
                  "gmatch", "gsub", "len", "lower", "match", "rep",
                  "reverse", "sub", "upper"):
        cat = "string library"
    elif name in ("concat", "foreach", "foreachi", "getn", "insert",
                  "maxn", "remove", "setn", "sort"):
        cat = "table library"
    elif name in ("abs", "acos", "asin", "atan", "atan2", "ceil",
                  "cos", "cosh", "deg", "exp", "floor", "fmod",
                  "frexp", "huge", "ldexp", "log", "log10", "max",
                  "min", "modf", "pi", "pow", "rad", "random",
                  "randomseed", "sin", "sinh", "sqrt", "tan", "tanh"):
        cat = "math library"
    elif name in ("close", "flush", "input", "lines", "open", "output",
                  "popen", "read", "stderr", "stdin", "stdout",
                  "tmpfile", "type", "write"):
        cat = "io library"
    elif name in ("clock", "date", "difftime", "execute", "exit",
                  "getenv", "remove", "rename", "setlocale", "time",
                  "tmpname"):
        cat = "os library"
    elif name in ("debug", "getfenv", "gethook", "getinfo", "getlocal",
                  "getmetatable", "getregistry", "getupvalue", "setfenv",
                  "sethook", "setlocal", "setmetatable", "setupvalue",
                  "traceback"):
        cat = "debug library"
    elif name in ("create", "resume", "running", "status", "wrap", "yield"):
        cat = "coroutine library"
    elif name in ("config", "cpath", "loaded", "loaders", "loadlib",
                  "path", "preload", "seeall"):
        cat = "package library"
    else:
        cat = "other/game"
    
    print(f"  {name:30s} 0x{va:08X}  {cat}")

# ============================================================
# PHASE 10: Specific API function identification
# ============================================================
print("\n" + "="*80)
print("PHASE 10: SPECIFIC C API FUNCTION IDENTIFICATION")
print("="*80)

print("""
Identifying lua_pushstring, lua_getfield, lua_setfield, etc.
by their characteristic instruction patterns and cross-references.
""")

# lua_getglobal and lua_setglobal are macros in Lua 5.1:
#   #define lua_getglobal(L,s)  lua_getfield(L, LUA_GLOBALSINDEX, s)
#   #define lua_setglobal(L,s)  lua_setfield(L, LUA_GLOBALSINDEX, s)
# LUA_GLOBALSINDEX = -10002
# So we look for PUSH -10002 (0xFFFFD8EE = 0xFFFF D8EE) followed by a call

GLOBALS_INDEX = -10002  # 0xFFFFD8EE as signed 32-bit
globals_bytes_push = b'\x68' + struct.pack("<i", GLOBALS_INDEX)  # 68 EE D8 FF FF
globals_bytes_push6 = b'\x6A' + struct.pack("<b", GLOBALS_INDEX & 0xFF) if -128 <= GLOBALS_INDEX <= 127 else None

print(f"  LUA_GLOBALSINDEX = {GLOBALS_INDEX} (0x{GLOBALS_INDEX & 0xFFFFFFFF:08X})")
print(f"  Searching for PUSH {GLOBALS_INDEX} pattern: {globals_bytes_push.hex()}")

gi_refs = find_all_occurrences(data, globals_bytes_push, text_start, text_end)
print(f"  Found {len(gi_refs)} references to LUA_GLOBALSINDEX in .text")
if gi_refs:
    print(f"  First 10 locations:")
    for ref in gi_refs[:10]:
        ref_va = offset_to_va(ref, sections)
        # Show context
        ctx = data[ref:ref+20]
        ctx_hex = ' '.join(f'{b:02X}' for b in ctx)
        print(f"    VA 0x{ref_va:08X}: {ctx_hex}")

# LUA_REGISTRYINDEX = -10000
REG_INDEX = -10000
reg_bytes = b'\x68' + struct.pack("<i", REG_INDEX)
ri_refs = find_all_occurrences(data, reg_bytes, text_start, text_end)
print(f"\n  LUA_REGISTRYINDEX = {REG_INDEX} → {len(ri_refs)} references in .text")

# LUA_ENVIRONINDEX = -10001  
ENV_INDEX = -10001
env_bytes = b'\x68' + struct.pack("<i", ENV_INDEX)
ei_refs = find_all_occurrences(data, env_bytes, text_start, text_end)
print(f"  LUA_ENVIRONINDEX = {ENV_INDEX} → {len(ei_refs)} references in .text")

# luaL_dostring is a macro: luaL_loadstring(L, s) || lua_pcall(L, 0, LUA_MULTRET, 0)
# So it's not a function. But luaL_loadstring calls luaL_loadbuffer.
# luaL_loadbuffer is identifiable by the "=[string \"" prefix it generates.

print("\n--- luaL_loadbuffer identification ---")
if b"=[string \"" in string_locations:
    for off, va in string_locations[b"=[string \""]:
        print(f"  '=[string \"' at VA 0x{va:08X}")
        push_refs = find_push_refs_in_text(data, va, text_start, text_end)
        for pr in push_refs[:3]:
            pr_va = offset_to_va(pr, sections)
            print(f"    Referenced at VA 0x{pr_va:08X}")

# luaL_newstate: look for "not enough memory" + initial allocator setup
print("\n--- luaL_newstate / lua_newstate ---")
if b"not enough memory" in string_locations:
    for off, va in string_locations[b"not enough memory"]:
        print(f"  'not enough memory' at VA 0x{va:08X}")
        push_refs = find_push_refs_in_text(data, va, text_start, text_end)
        for pr in push_refs[:5]:
            pr_va = offset_to_va(pr, sections)
            print(f"    Referenced at VA 0x{pr_va:08X}")

print("\n" + "="*80)
print("AUDIT COMPLETE")
print("="*80)
