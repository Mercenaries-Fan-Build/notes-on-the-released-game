#!/usr/bin/env python3
"""Comprehensive Lua 5.1.2 C API audit v2 - Mercenaries 2 EXE.

Extended scan: searches ALL sections, handles alternate instruction encodings,
and does a broader registration table sweep.
"""
from __future__ import annotations
import struct
import sys
from pathlib import Path
from collections import defaultdict

EXE_PATH = Path("/Users/austinkregel/src/mercenaries-game/output/patched/Mercenaries2.exe")
IMAGE_BASE = 0x00400000

def parse_pe(data: bytes):
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


def find_all(data: bytes, pattern: bytes, start: int = 0, end: int | None = None) -> list[int]:
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
    for sec in sections.values():
        if sec['raw_offset'] <= offset < sec['raw_offset'] + sec['raw_size']:
            return IMAGE_BASE + sec['rva'] + (offset - sec['raw_offset'])
    return None


def va_to_offset(va: int, sections: dict) -> int | None:
    rva = va - IMAGE_BASE
    for sec in sections.values():
        if sec['rva'] <= rva < sec['rva'] + sec['virt_size']:
            off = sec['raw_offset'] + (rva - sec['rva'])
            if off < sec['raw_offset'] + sec['raw_size']:
                return off
    return None


print(f"Loading: {EXE_PATH} ({EXE_PATH.stat().st_size:,} bytes)")
data = EXE_PATH.read_bytes()
sections = parse_pe(data)

print("\n=== PE SECTIONS ===")
for name, info in sections.items():
    print(f"  {name:10s} VA 0x{info['va']:08X}-0x{info['va']+info['virt_size']:08X}  "
          f"Raw 0x{info['raw_offset']:08X} Size 0x{info['raw_size']:08X}")

rdata = sections['.rdata']
text = sections['.text']
rdata_start = rdata['raw_offset']
rdata_end = rdata_start + rdata['raw_size']
text_start = text['raw_offset']
text_end = text_start + text['raw_size']

# ====================================================================
# PART A: Find ALL Lua-specific diagnostic strings (unique fingerprints)
# ====================================================================
print("\n" + "="*100)
print("PART A: ALL LUA 5.1.2 DIAGNOSTIC STRINGS")
print("="*100)

# These are strings UNIQUE to specific Lua source files - they fingerprint functions
UNIQUE_STRINGS = [
    # lapi.c
    (b"index out of range", "lapi.c: index_check (lua_gettop context)"),
    (b"table index is nil", "lapi.c: lua_settable / luaH_newkey"),
    (b"table index is NaN", "lapi.c: lua_settable / luaH_newkey"),
    (b"nil or table expected", "lapi.c: lua_setmetatable"),
    (b"invalid index", "lapi.c: various index validation"),
    # lbaselib.c
    (b"'tostring' must return a string to 'print'", "lbaselib.c: luaB_print"),
    (b"'tostring' must return a string", "lbaselib.c: luaB_tostring"),
    (b"too many results to unpack", "lbaselib.c: luaB_unpack"),
    (b"cannot resume dead coroutine", "lbaselib.c: (or ldo.c) lua_resume"),
    (b"'__tostring' must return a string", "lbaselib.c: luaB_tostring alternate"),
    # ldblib.c
    (b"level out of range", "ldblib.c: debug.getinfo"),
    # ldo.c  
    (b"C stack overflow", "ldo.c: luaD_call"),
    (b"error in error handling", "ldo.c: luaG_errormsg / luaD_rawrunprotected"),
    (b"attempt to yield across metamethod/C-call boundary", "ldo.c: lua_yield"),
    (b"cannot resume non-suspended coroutine", "ldo.c: lua_resume"),
    # lgc.c
    (b"__gc", "lgc.c / lbaselib.c: GC metamethod"),
    # liolib.c
    (b"standard %s file is closed", "liolib.c: io library"),
    (b"cannot close standard file", "liolib.c: io.close"),
    # llex.c
    (b"unfinished string", "llex.c: luaX_lexerror"),
    (b"unfinished long string", "llex.c: luaX_lexerror (long)"),
    (b"unfinished long comment", "llex.c: luaX_lexerror (comment)"),
    (b"malformed number", "llex.c: luaX_lexerror (number)"),
    (b"invalid long string delimiter", "llex.c: luaX_lexerror"),
    (b"lexical element too long", "llex.c: luaX_lexerror (token)"),
    # loadlib.c
    (b"module '%s' not found", "loadlib.c: require"),
    (b"error loading module '%s'", "loadlib.c: loader errors"),
    (b"'package.%s' must be a string", "loadlib.c: package"),
    # lparser.c
    (b"function or expression too complex", "lparser.c: luaY_parser"),
    (b"chunk has too many syntax levels", "lparser.c: nesting"),
    (b"ambiguous syntax", "lparser.c: ambiguity"),
    (b"cannot use '...' outside a vararg function", "lparser.c: vararg"),
    (b"main function has more than %d %s", "lparser.c: limits"),
    (b"too many %s (limit is %d)", "lparser.c: limits"),
    # lstrlib.c
    (b"string slice too long", "lstrlib.c: string.rep"),
    (b"invalid pattern capture index", "lstrlib.c: pattern"),
    (b"malformed pattern", "lstrlib.c: pattern"),
    (b"pattern too complex", "lstrlib.c: pattern"),
    (b"invalid capture index", "lstrlib.c: gsub"),
    # ltablib.c
    (b"invalid order function for sorting", "ltablib.c: table.sort"),
    # lvm.c
    (b"loop in gettable", "lvm.c: luaV_gettable"),
    (b"loop in settable", "lvm.c: luaV_settable"),
    (b"'for' initial value must be a number", "lvm.c: luaV_execute"),
    (b"'for' limit must be a number", "lvm.c: luaV_execute"),
    (b"'for' step must be a number", "lvm.c: luaV_execute"),
    (b"attempt to perform arithmetic on a %s value", "lvm.c: luaG_aritherror"),
    (b"attempt to compare two %s values", "lvm.c: luaG_ordererror"),
    (b"attempt to compare %s with %s", "lvm.c: luaG_ordererror alt"),
    (b"attempt to concatenate a %s value", "lvm.c: luaG_concaterror"),
    (b"attempt to call a %s value", "lvm.c: luaD_precall"),
    (b"attempt to %s a %s value", "lvm.c: luaG_typeerror"),
    (b"get length of", "lvm.c: luaG_typeerror (len)"),
    # lauxlib.c
    (b"bad argument #%d", "lauxlib.c: luaL_argerror"),
    (b"value expected", "lauxlib.c: luaL_checkany"),
    (b"string length overflow", "lauxlib.c: luaL_addlstring"),
    (b"stack overflow", "lauxlib.c: luaL_checkstack / luaD_growstack"),
    (b"invalid option '%s'", "lauxlib.c: luaL_checkoption"),
    (b"invalid option", "lauxlib.c: lua_getinfo / luaL_checkoption"),
    (b"=[string \"", "lauxlib.c: luaO_chunkid / luaL_loadbuffer"),
    (b"(error object is a %s value)", "lauxlib.c: luaL_tolstring"),
    # lmem.c
    (b"not enough memory", "lmem.c: luaM_realloc / luaL_newstate"),
    # Metamethods (all from ltm.c / ltm.h)
    (b"__index\x00", "ltm.c: TM_INDEX"),
    (b"__newindex\x00", "ltm.c: TM_NEWINDEX"),
    (b"__gc\x00", "ltm.c: TM_GC"),
    (b"__mode\x00", "ltm.c: TM_MODE"),
    (b"__eq\x00", "ltm.c: TM_EQ"),
    (b"__add\x00", "ltm.c: TM_ADD"),
    (b"__sub\x00", "ltm.c: TM_SUB"),
    (b"__mul\x00", "ltm.c: TM_MUL"),
    (b"__div\x00", "ltm.c: TM_DIV"),
    (b"__mod\x00", "ltm.c: TM_MOD"),
    (b"__pow\x00", "ltm.c: TM_POW"),
    (b"__unm\x00", "ltm.c: TM_UNM"),
    (b"__len\x00", "ltm.c: TM_LEN"),
    (b"__lt\x00", "ltm.c: TM_LT"),
    (b"__le\x00", "ltm.c: TM_LE"),
    (b"__concat\x00", "ltm.c: TM_CONCAT"),
    (b"__call\x00", "ltm.c: TM_CALL"),
    (b"__tostring\x00", "ltm.c: (not standard TM but used)"),
    (b"__metatable\x00", "ltm.c: metatable protection"),
    # Version
    (b"Lua 5.1", "version string"),
    # Type names (ltm.c / lobject.c)
    (b"nil\x00", "type name: nil"),
    (b"boolean\x00", "type name: boolean"),
    (b"userdata\x00", "type name: userdata"),
    (b"number\x00", "type name: number"),
    (b"string\x00", "type name: string"),
    (b"table\x00", "type name: table"),
    (b"function\x00", "type name: function"),
    (b"thread\x00", "type name: thread"),
    (b"proto\x00", "type name: proto (internal)"),
    (b"upval\x00", "type name: upval (internal)"),
    # lundump.c
    (b"%s: bad header in precompiled chunk", "lundump.c: header check"),
    (b"truncated precompiled chunk", "lundump.c: LoadBlock"),
    (b"bad constant", "lundump.c: LoadConstants"),
    # Coroutine lib
    (b"coroutine expected", "lcorolib / lbaselib coroutine"),
    (b"too many arguments to resume", "lbaselib: coroutine.resume"),
]

print(f"\nSearching for {len(UNIQUE_STRINGS)} unique fingerprint strings...\n")

all_found = []
for pattern, source in UNIQUE_STRINGS:
    # Search across all readable sections  
    occurrences = find_all(data, pattern, rdata_start, rdata_end)
    # Also check Srdata if it exists
    if 'Srdata' in sections:
        sr = sections['Srdata']
        occurrences += find_all(data, pattern, sr['raw_offset'], sr['raw_offset'] + sr['raw_size'])
    
    for off in occurrences:
        va = offset_to_va(off, sections)
        # Verify it's a plausible standalone string (preceded by NUL or at boundary)
        if off > 0 and data[off-1] not in (0x00, 0x0A, 0x0D, 0x22):
            # Check if the pattern has a NUL terminator indicating exact match
            if not pattern.endswith(b'\x00'):
                # For non-exact patterns, allow if followed by reasonable char
                pass
        all_found.append((va, off, pattern, source))

all_found.sort()
# Deduplicate by VA
seen_vas = set()
unique_found = []
for item in all_found:
    if item[0] not in seen_vas:
        seen_vas.add(item[0])
        unique_found.append(item)

print(f"Found {len(unique_found)} unique string locations\n")
print(f"{'VA':>12s} {'FileOff':>10s} Source/Function")
print("-"*100)
for va, off, pattern, source in unique_found:
    pat_display = pattern.decode('ascii', errors='replace').rstrip('\x00')[:55]
    print(f"  0x{va:08X}  0x{off:08X}  {source:50s} \"{pat_display}\"")

# ====================================================================
# PART B: Full registration table sweep - scan ALL of .rdata for
# consecutive (string_ptr, code_ptr) pairs
# ====================================================================
print("\n" + "="*100)
print("PART B: COMPREHENSIVE REGISTRATION TABLE SWEEP")
print("="*100)

text_va_start = text['va']
text_va_end = text['va'] + text['virt_size']
rdata_va_start = rdata['va']
rdata_va_end = rdata['va'] + rdata['virt_size']

def is_valid_string_ptr(va):
    off = va_to_offset(va, sections)
    if off is None:
        return False
    if not (rdata_start <= off < rdata_end):
        return False
    # Check for printable ASCII string
    end = data.find(b'\x00', off, off + 128)
    if end == -1 or end == off:
        return False
    s = data[off:end]
    try:
        decoded = s.decode('ascii')
        return all(c.isprintable() or c in '\t\n\r' for c in decoded)
    except:
        return False

def read_string_at_va(va):
    off = va_to_offset(va, sections)
    if off is None:
        return None
    end = data.find(b'\x00', off, off + 128)
    if end == -1:
        return None
    return data[off:end].decode('ascii', errors='replace')

# Scan .rdata for registration tables (consecutive valid entries)
print("\nScanning .rdata for luaL_Reg tables (name_ptr + func_ptr pairs)...\n")

all_reg_tables = []  # [(table_va, [(name, func_va)])]
pos = rdata_start

# Align to 4 bytes
pos = (pos + 3) & ~3

visited = set()
while pos < rdata_end - 16:
    # Read potential entry
    name_ptr = struct.unpack_from("<I", data, pos)[0]
    func_ptr = struct.unpack_from("<I", data, pos + 4)[0]
    
    if pos in visited:
        pos += 4
        continue
    
    # Check if this looks like a valid entry
    if not (is_valid_string_ptr(name_ptr) and text_va_start <= func_ptr < text_va_end):
        pos += 4
        continue
    
    # Found a potential table start - read consecutive entries
    table_entries = []
    scan_pos = pos
    while scan_pos < rdata_end - 8:
        np = struct.unpack_from("<I", data, scan_pos)[0]
        fp = struct.unpack_from("<I", data, scan_pos + 4)[0]
        
        if np == 0 and fp == 0:
            # NULL terminator
            table_entries.append(("--- END ---", 0))
            visited.add(scan_pos)
            break
        
        if not (is_valid_string_ptr(np) and text_va_start <= fp < text_va_end):
            break
        
        name = read_string_at_va(np)
        if name and len(name) <= 64:
            table_entries.append((name, fp))
            visited.add(scan_pos)
        else:
            break
        
        scan_pos += 8
    
    # Only keep tables with 3+ real entries
    real_entries = [e for e in table_entries if e[0] != "--- END ---"]
    if len(real_entries) >= 3:
        table_va = offset_to_va(pos, sections)
        all_reg_tables.append((table_va, table_entries))
    
    pos += 4

print(f"Found {len(all_reg_tables)} registration tables with 3+ entries\n")

# Classify tables by content
all_functions = {}  # name -> func_va (deduplicated)

for table_va, entries in sorted(all_reg_tables):
    real = [e for e in entries if e[0] != "--- END ---"]
    # Try to identify the library
    names = set(n for n, _ in real)
    
    if "assert" in names and "pcall" in names:
        lib = "BASE LIBRARY (luaopen_base)"
    elif "find" in names and "gsub" in names and "format" in names:
        lib = "STRING LIBRARY (luaopen_string)"
    elif "sort" in names and "insert" in names and "concat" in names:
        lib = "TABLE LIBRARY (luaopen_table)"
    elif "sin" in names and "cos" in names and "sqrt" in names:
        lib = "MATH LIBRARY (luaopen_math)"
    elif "open" in names and "close" in names and "read" in names and "write" in names:
        lib = "IO LIBRARY (luaopen_io)"
    elif "clock" in names and "date" in names and "execute" in names:
        lib = "OS LIBRARY (luaopen_os)"
    elif "getinfo" in names and "traceback" in names:
        lib = "DEBUG LIBRARY (luaopen_debug)"
    elif "create" in names and "resume" in names and "yield" in names:
        lib = "COROUTINE LIBRARY (luaopen_coroutine)"
    elif "loadlib" in names and "seeall" in names:
        lib = "PACKAGE LIBRARY (luaopen_package)"
    elif "send" in names and "decode" in names:
        lib = "GAME/NETWORK LIBRARY (custom)"
    elif "addRequestHeader" in names:
        lib = "HTTP LIBRARY (custom)"
    else:
        lib = f"UNKNOWN ({', '.join(list(names)[:4])}...)"
    
    print(f"\n{'='*80}")
    print(f"  TABLE at VA 0x{table_va:08X} — {lib}")
    print(f"  {len(real)} functions registered")
    print(f"{'='*80}")
    print(f"  {'Name':30s} {'FuncVA':>12s} {'First 8 bytes':24s}")
    print(f"  {'-'*70}")
    
    for name, func_va in entries:
        if name == "--- END ---":
            print(f"  {'[NULL terminator]':30s}")
            continue
        
        func_off = va_to_offset(func_va, sections)
        hex_bytes = ""
        if func_off and func_off + 8 <= len(data):
            hex_bytes = ' '.join(f'{b:02X}' for b in data[func_off:func_off+8])
        
        print(f"  {name:30s} 0x{func_va:08X}  {hex_bytes}")
        all_functions[name] = func_va

# ====================================================================
# PART C: Core Lua C API functions via call pattern analysis
# ====================================================================
print("\n" + "="*100)
print("PART C: CORE LUA C API FUNCTION IDENTIFICATION")
print("="*100)

# The most-called functions from the base library implementations
# are the core C API (lua_pushstring, lua_gettop, lua_settop, etc.)

print("\nTracing CALL targets from all identified base library functions...")

call_freq = defaultdict(int)
call_callers = defaultdict(set)

for name, func_va in all_functions.items():
    func_off = va_to_offset(func_va, sections)
    if func_off is None:
        continue
    
    scan_len = min(512, text_end - func_off - 5)
    for i in range(scan_len):
        if data[func_off + i] == 0xE8:
            rel = struct.unpack_from("<i", data, func_off + i + 1)[0]
            target = func_va + i + 5 + rel
            if text_va_start <= target < text_va_end:
                call_freq[target] += 1
                call_callers[target].add(name)

# Sort by frequency
sorted_targets = sorted(call_freq.items(), key=lambda x: -x[1])

print(f"\nTop 60 most-called functions from Lua library implementations:")
print(f"{'VA':>12s} {'Count':>6s} {'Callers sample':60s} Notes")
print("-" * 120)

identified_api = {}

for target_va, count in sorted_targets[:60]:
    target_off = va_to_offset(target_va, sections)
    callers_sample = ', '.join(sorted(call_callers[target_va])[:5])
    
    notes = ""
    # Check if this is already one of our named functions
    for fname, fva in all_functions.items():
        if fva == target_va:
            notes = f"= {fname}"
            break
    
    # Check what strings this function references (first 128 bytes)
    if not notes and target_off:
        for j in range(min(120, text_end - target_off - 5)):
            if data[target_off + j] == 0x68:  # PUSH imm32
                pushed = struct.unpack_from("<I", data, target_off + j + 1)[0]
                pushed_off = va_to_offset(pushed, sections)
                if pushed_off and rdata_start <= pushed_off < rdata_end:
                    end_pos = data.find(b'\x00', pushed_off, pushed_off + 80)
                    if end_pos != -1:
                        s = data[pushed_off:end_pos].decode('ascii', errors='replace')
                        if s.isprintable() and 2 < len(s) < 60:
                            notes += f" refs \"{s[:40]}\""
                            break
    
    # Heuristic identification based on prologue + frequency
    if not notes and target_off:
        prologue = data[target_off:target_off+16]
        # lua_gettop is typically very short: return L->top - L->base (offset arithmetic)
        # lua_settop involves setting L->top
        # lua_pushnil pushes a nil value (sets tag)
        # lua_pushnumber pushes a float (sets tag + value)
        hex_pre = ' '.join(f'{b:02X}' for b in prologue[:8])
        notes = f"prologue: {hex_pre}"
    
    # Attempt smarter identification
    api_name = ""
    if target_off:
        func_bytes = data[target_off:target_off+32]
        # lua_gettop: very short, returns (L->top - L->base) / sizeof(TValue)
        # Typically: mov eax, [ecx+8]; sub eax, [ecx+14h]; sar eax, 3; ret
        # or with stdcall: mov ecx, [esp+4]; mov eax, [ecx+X] ...
        
        # Count: if this function is called 100+ times, it's likely lua_gettop/settop/type/push
        if count >= 30:
            api_name = f"[HIGH-FREQ C API, {count} calls]"
    
    print(f"  0x{target_va:08X}  {count:>5d}  {callers_sample:60s} {notes}")
    if api_name:
        identified_api[target_va] = api_name

# ====================================================================
# PART D: LUA_GLOBALSINDEX / REGISTRYINDEX usage
# ====================================================================
print("\n" + "="*100)
print("PART D: PSEUDO-INDEX USAGE (LUA_GLOBALSINDEX, REGISTRYINDEX)")
print("="*100)

# In 32-bit x86, PUSH -10002 can be encoded as:
# 68 EE D8 FF FF  (PUSH imm32)
# But compiler may optimize to: 6A XX (PUSH imm8) - won't work for -10002
# Or: MOV [esp+X], imm32; which is C7 44 24 XX EE D8 FF FF
# Or: MOV reg, imm32; PUSH reg

GLOBALS_INDEX = 0xFFFFD8EE  # -10002 as unsigned
REGISTRY_INDEX = 0xFFFFD8F0  # -10000 as unsigned
ENVIRON_INDEX = 0xFFFFD8EF  # -10001 as unsigned

print(f"\n  LUA_GLOBALSINDEX = -10002 (0x{GLOBALS_INDEX:08X})")
print(f"  LUA_REGISTRYINDEX = -10000 (0x{REGISTRY_INDEX:08X})")
print(f"  LUA_ENVIRONINDEX = -10001 (0x{ENVIRON_INDEX:08X})")

# Search for the 4-byte value anywhere in .text
for name, val in [("GLOBALSINDEX", GLOBALS_INDEX), ("REGISTRYINDEX", REGISTRY_INDEX), 
                   ("ENVIRONINDEX", ENVIRON_INDEX)]:
    val_bytes = struct.pack("<I", val)
    refs = find_all(data, val_bytes, text_start, text_end)
    print(f"\n  LUA_{name} (0x{val:08X}): {len(refs)} occurrences in .text")
    
    for ref in refs[:15]:
        ref_va = offset_to_va(ref, sections)
        # Show context: 2 bytes before + the match + 4 bytes after
        ctx_start = max(text_start, ref - 2)
        ctx = data[ctx_start:ref+8]
        ctx_hex = ' '.join(f'{b:02X}' for b in ctx)
        
        # Decode instruction
        opcode_before = data[ref-1] if ref > text_start else 0
        instr = ""
        if opcode_before == 0x68:
            instr = "PUSH imm32"
        elif data[ref-3:ref-1] == b'\xC7\x04' and data[ref-1] == 0x24:
            instr = "MOV [esp], imm32"
        elif opcode_before in (0xB8, 0xB9, 0xBA, 0xBB, 0xBC, 0xBD, 0xBE, 0xBF):
            reg_names = ["EAX","ECX","EDX","EBX","ESP","EBP","ESI","EDI"]
            instr = f"MOV {reg_names[opcode_before - 0xB8]}, imm32"
        elif ref >= text_start + 2 and data[ref-2] == 0xC7:
            instr = "MOV [mem], imm32"
        
        print(f"    VA 0x{ref_va:08X}: {ctx_hex}  [{instr}]")

# ====================================================================
# PART E: Lua source file paths (confirms all linked modules)
# ====================================================================
print("\n" + "="*100)
print("PART E: LINKED LUA SOURCE FILES (BUILD ARTIFACTS)")
print("="*100)

lua_path_prefix = b"D:\\Projects\\Mercs2_PC\\mercs2\\Lua-5.1.2\\src\\"
all_paths = find_all(data, lua_path_prefix)

source_files = {}
for off in all_paths:
    end = data.find(b'\x00', off, off + 200)
    if end != -1:
        path = data[off:end].decode('ascii', errors='replace')
        va = offset_to_va(off, sections)
        if path not in source_files:
            source_files[path] = va

# Group by .c file
by_file = defaultdict(list)
for path, va in sorted(source_files.items()):
    # Extract just the filename
    parts = path.split('\\')
    fname = parts[-1] if parts else path
    # Strip line number if present
    base = fname.split(' [')[0] if ' [' in fname else fname
    by_file[base].append((va, path))

print(f"\nFound {len(source_files)} unique source path strings from {len(by_file)} Lua C files:\n")
for fname in sorted(by_file.keys()):
    entries = by_file[fname]
    print(f"  {fname}:")
    for va, path in sorted(entries):
        print(f"    0x{va:08X}  {path}")

# ====================================================================  
# PART F: Key string → function VA resolution
# ====================================================================
print("\n" + "="*100)
print("PART F: STRING → FUNCTION VA RESOLUTION (KEY FUNCTIONS)")
print("="*100)

# Find specific important strings and trace to the function that references them
KEY_TRACE = [
    (b"error in error handling\x00", "luaG_errormsg"),
    (b"attempt to call a %s value\x00", "luaD_precall"),
    (b"cannot resume dead coroutine\x00", "lua_resume"),
    (b"attempt to yield across metamethod/C-call boundary\x00", "lua_yield"),
    (b"C stack overflow\x00", "luaD_call"),
    (b"'tostring' must return a string\x00", "luaB_tostring"),
    (b"table index is nil\x00", "luaH_newkey"),
    (b"loop in gettable\x00", "luaV_gettable"),
    (b"loop in settable\x00", "luaV_settable"),
    (b"bad argument #%d", "luaL_argerror"),
    (b"value expected\x00", "luaL_checkany"),
    (b"not enough memory\x00", "luaM_realloc / lua_newstate"),
    (b"too many results to unpack\x00", "luaB_unpack"),
    (b"stack overflow\x00", "luaD_growstack / lua_checkstack"),
    (b"invalid order function for sorting\x00", "table.sort"),
    (b"module '%s' not found", "require (package.loaders)"),
    (b"%.14g", "luaO_str2d / lua_number2str (number format)"),
    (b"=[string \"", "luaL_loadbuffer (chunk naming)"),
]

print(f"\n{'String':55s} {'StringVA':>12s} {'RefVA (PUSH)':>14s} {'FuncVA':>12s} Function")
print("-" * 140)

resolved_functions = {}

for pattern, func_name in KEY_TRACE:
    # Find string in .rdata
    occs = find_all(data, pattern, rdata_start, rdata_end)
    for str_off in occs:
        str_va = offset_to_va(str_off, sections)
        if not str_va:
            continue
        
        # Find PUSH refs in .text
        push_pattern = b'\x68' + struct.pack("<I", str_va)
        push_refs = find_all(data, push_pattern, text_start, text_end)
        
        for push_off in push_refs[:3]:
            push_va = offset_to_va(push_off, sections)
            
            # Find function start by scanning backwards
            func_start_va = None
            for back in range(1, 1024):
                candidate = push_off - back
                if candidate <= text_start:
                    break
                # Function prologue: preceded by padding (CC/90/C3) then PUSH EBP or SUB ESP
                if data[candidate] == 0x55 and data[candidate-1] in (0xCC, 0x90, 0xC3, 0xC2):
                    func_start_va = offset_to_va(candidate, sections)
                    break
                if data[candidate:candidate+2] in (b'\x83\xEC', b'\x81\xEC') and \
                   data[candidate-1] in (0xCC, 0x90, 0xC3, 0xC2):
                    func_start_va = offset_to_va(candidate, sections)
                    break
                # Also check for common prologue: PUSH reg (51-57)
                if data[candidate] in range(0x50, 0x58) and \
                   data[candidate-1] in (0xCC, 0x90, 0xC3, 0xC2):
                    func_start_va = offset_to_va(candidate, sections)
                    break
            
            pat_display = pattern.decode('ascii', errors='replace').rstrip('\x00')[:50]
            fva_str = f"0x{func_start_va:08X}" if func_start_va else "???"
            print(f"  \"{pat_display:52s}\" 0x{str_va:08X}  0x{push_va:08X}  {fva_str:>12s}  {func_name}")
            
            if func_start_va and func_name not in resolved_functions:
                resolved_functions[func_name] = func_start_va
            break  # Only need first reference
        break  # Only need first occurrence

# ====================================================================
# PART G: Final comprehensive function table
# ====================================================================
print("\n" + "="*100)
print("PART G: FINAL COMPREHENSIVE FUNCTION TABLE")
print("="*100)

# Merge all findings
all_identified = {}
all_identified.update(all_functions)
all_identified.update(resolved_functions)

# Categorize
categories = defaultdict(list)
for name, va in sorted(all_identified.items()):
    if name.startswith("lua") and name[3].isupper():
        categories["Lua C API (internal)"].append((name, va))
    elif name.startswith("luaL_") or name.startswith("luaB_") or name.startswith("luaD_") or \
         name.startswith("luaG_") or name.startswith("luaV_") or name.startswith("luaH_") or \
         name.startswith("luaM_") or name.startswith("luaO_") or name.startswith("luaX_") or \
         name.startswith("luaY_"):
        categories["Lua Internal API"].append((name, va))
    elif name in ("assert", "collectgarbage", "dofile", "error", "gcinfo",
                  "getfenv", "getmetatable", "ipairs", "load", "loadfile",
                  "loadstring", "module", "newproxy", "next", "pairs",
                  "pcall", "print", "rawequal", "rawget", "rawset",
                  "require", "select", "setfenv", "setmetatable", "tonumber",
                  "tostring", "type", "unpack", "xpcall"):
        categories["Base Library"].append((name, va))
    elif name in ("byte", "char", "dump", "find", "format", "gfind",
                  "gmatch", "gsub", "len", "lower", "match", "rep",
                  "reverse", "sub", "upper"):
        categories["String Library"].append((name, va))
    elif name in ("concat", "foreach", "foreachi", "getn", "insert",
                  "maxn", "remove", "setn", "sort"):
        categories["Table Library"].append((name, va))
    elif name in ("abs", "acos", "asin", "atan", "atan2", "ceil",
                  "cos", "cosh", "deg", "exp", "floor", "fmod",
                  "frexp", "huge", "ldexp", "log", "log10", "max",
                  "min", "modf", "pi", "pow", "rad", "random",
                  "randomseed", "sin", "sinh", "sqrt", "tan", "tanh"):
        categories["Math Library"].append((name, va))
    elif name in ("close", "flush", "input", "lines", "open", "output",
                  "popen", "read", "stderr", "stdin", "stdout",
                  "tmpfile", "write"):
        categories["IO Library"].append((name, va))
    elif name in ("clock", "date", "difftime", "execute", "exit",
                  "getenv", "remove", "rename", "setlocale", "time",
                  "tmpname"):
        categories["OS Library"].append((name, va))
    elif name in ("getinfo", "traceback", "sethook", "gethook", 
                  "getlocal", "setlocal", "getupvalue", "setupvalue",
                  "debug"):
        categories["Debug Library"].append((name, va))
    elif name in ("create", "resume", "running", "status", "wrap", "yield"):
        categories["Coroutine Library"].append((name, va))
    elif name in ("config", "cpath", "loaded", "loaders", "loadlib",
                  "path", "preload", "seeall"):
        categories["Package Library"].append((name, va))
    else:
        categories["Game/Custom"].append((name, va))

print(f"\nTotal identified functions: {len(all_identified)}\n")

for cat in ["Base Library", "String Library", "Table Library", "Math Library",
            "IO Library", "OS Library", "Debug Library", "Coroutine Library",
            "Package Library", "Lua Internal API", "Lua C API (internal)", "Game/Custom"]:
    if cat not in categories:
        continue
    funcs = categories[cat]
    print(f"\n  --- {cat} ({len(funcs)} functions) ---")
    for name, va in sorted(funcs):
        func_off = va_to_offset(va, sections)
        hex_str = ""
        if func_off and func_off + 16 <= len(data):
            hex_str = ' '.join(f'{b:02X}' for b in data[func_off:func_off+16])
        print(f"    {name:32s} 0x{va:08X}  {hex_str}")

# ====================================================================
# PART H: Summary statistics
# ====================================================================
print("\n" + "="*100)
print("SUMMARY")
print("="*100)
print(f"""
Lua 5.1.2 Static Link Confirmation:
  Build path: D:\\Projects\\Mercs2_PC\\mercs2\\Lua-5.1.2\\src\\
  Source files linked: {len(by_file)} .c files
  Diagnostic strings found: {len(unique_found)}
  Registration tables: {len(all_reg_tables)}
  Named functions from tables: {len(all_functions)}
  Functions resolved from string xrefs: {len(resolved_functions)}
  Total identified: {len(all_identified)}

Lua Source Files Confirmed Linked:
  {', '.join(sorted(by_file.keys()))}

Categories:""")
for cat in sorted(categories.keys()):
    print(f"  {cat}: {len(categories[cat])} functions")
