# Ghidra script: Annotate Mercenaries 2 PC binary using cross-reference data
# from Mercenaries 1 engine source code.
#
# Runs inside Ghidra's Jython interpreter (Python 2.7 compatible).
#
# Prerequisites:
#   1. Run the pre-analysis script to generate the JSON database:
#      .venv/bin/python3 scripts/ghidra_mercs2_preanalysis.py --output scripts/mercs2_annotations.json
#   2. Open the Mercenaries 2 cracked EXE in Ghidra and auto-analyze.
#   3. Run this script via Script Manager (Window > Script Manager > Run).
#      When prompted, select the mercs2_annotations.json file.
#
# The script is idempotent: re-running will skip already-labeled addresses.
#
# @author  Mercs2 Recreation Project
# @category Mercs2
# @keybinding
# @menupath Tools.Mercs2 Annotate
# @toolbar

import json
import os
import struct

from ghidra.program.model.symbol import SourceType
from ghidra.program.model.listing import CodeUnit
from ghidra.program.model.address import AddressSet
from ghidra.program.model.data import StringDataType
from ghidra.app.cmd.label import AddLabelCmd
from java.io import File

# ── Globals set by Ghidra's scripting environment ─────────────────────────
# currentProgram, currentAddress, monitor, state, askFile, println, etc.
# are injected by the Ghidra script framework.


def get_flat_api():
    """Return the FlatProgramAPI-like methods available in Ghidra scripts."""
    from ghidra.program.flatapi import FlatProgramAPI
    return FlatProgramAPI(currentProgram, monitor)


def addr(va):
    """Convert an integer VA to a Ghidra Address."""
    return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(va)


def read_bytes(address, length):
    """Read raw bytes from the program at the given address."""
    mem = currentProgram.getMemory()
    buf = bytearray(length)
    # Use jarray for Ghidra/Jython
    import jarray
    jbuf = jarray.zeros(length, 'b')
    mem.getBytes(address, jbuf)
    return bytes(bytearray([b & 0xFF for b in jbuf]))


def read_dword(address):
    """Read a little-endian 32-bit value."""
    data = read_bytes(address, 4)
    return struct.unpack('<I', data)[0]


def read_cstring(address, max_len=256):
    """Read a null-terminated C string from the program."""
    mem = currentProgram.getMemory()
    result = []
    for i in range(max_len):
        try:
            a = address.add(i)
            import jarray
            jb = jarray.zeros(1, 'b')
            mem.getBytes(a, jb)
            b = jb[0] & 0xFF
            if b == 0:
                break
            if b < 0x20 or b > 0x7E:
                break
            result.append(chr(b))
        except Exception:
            break
    return ''.join(result)


def is_in_section(va, section_name):
    """Check if a VA falls within a named memory block."""
    mem = currentProgram.getMemory()
    block = mem.getBlock(addr(va))
    if block is None:
        return False
    return block.getName() == section_name


def is_readable_ascii(va):
    """Check if a VA points to a readable ASCII string (at least 2 chars)."""
    try:
        s = read_cstring(addr(va), 4)
        return len(s) >= 2
    except Exception:
        return False


def is_executable_va(va):
    """Check if a VA falls in an executable section."""
    mem = currentProgram.getMemory()
    block = mem.getBlock(addr(va))
    if block is None:
        return False
    return block.isExecute()


def has_label(address, name):
    """Check if an address already has a specific label."""
    sym_table = currentProgram.getSymbolTable()
    syms = sym_table.getSymbols(address)
    for s in syms:
        if s.getName() == name:
            return True
    return False


def create_label_safe(va, name, comment=None, namespace=None):
    """Create a label at VA if it doesn't already exist. Returns True if created."""
    address = addr(va)
    sanitized = name.replace(" ", "_").replace(".", "_").replace("(", "").replace(")", "")

    if has_label(address, sanitized):
        return False

    sym_table = currentProgram.getSymbolTable()

    ns = None
    if namespace:
        ns = sym_table.getNamespace(namespace, None)
        if ns is None:
            ns = sym_table.createNameSpace(None, namespace, SourceType.USER_DEFINED)

    sym_table.createLabel(address, sanitized, ns, SourceType.USER_DEFINED)

    if comment:
        listing = currentProgram.getListing()
        cu = listing.getCodeUnitAt(address)
        if cu is not None:
            existing = cu.getComment(CodeUnit.PRE_COMMENT)
            if existing is None or comment not in existing:
                new_comment = comment if existing is None else existing + "\n" + comment
                cu.setComment(CodeUnit.PRE_COMMENT, new_comment)

    return True


def set_pre_comment(va, comment):
    """Set or append a pre-comment at a VA."""
    address = addr(va)
    listing = currentProgram.getListing()
    cu = listing.getCodeUnitAt(address)
    if cu is not None:
        existing = cu.getComment(CodeUnit.PRE_COMMENT)
        if existing is None:
            cu.setComment(CodeUnit.PRE_COMMENT, comment)
        elif comment not in existing:
            cu.setComment(CodeUnit.PRE_COMMENT, existing + "\n" + comment)


def find_string_in_memory(target_str, start_va, end_va):
    """Search for a null-terminated string in a VA range. Returns list of VAs."""
    mem = currentProgram.getMemory()
    results = []
    target_bytes = bytearray(target_str.encode('ascii')) + bytearray([0])
    search_len = len(target_bytes)

    start_addr = addr(start_va)
    end_addr = addr(end_va)

    found = mem.findBytes(start_addr, end_addr, target_bytes, None, True, monitor)
    while found is not None:
        results.append(found.getOffset())
        next_start = found.add(1)
        if next_start.compareTo(end_addr) >= 0:
            break
        found = mem.findBytes(next_start, end_addr, target_bytes, None, True, monitor)

    return results


def get_references_to(va):
    """Get all addresses that reference a given VA."""
    ref_mgr = currentProgram.getReferenceManager()
    refs = ref_mgr.getReferencesTo(addr(va))
    result = []
    while refs.hasNext():
        ref = refs.next()
        result.append(ref.getFromAddress().getOffset())
    return result


def get_function_at(va):
    """Get the function containing a VA."""
    fm = currentProgram.getFunctionManager()
    return fm.getFunctionContaining(addr(va))


# ══════════════════════════════════════════════════════════════════════════
# Phase 1: Apply known VA annotations
# ══════════════════════════════════════════════════════════════════════════

def phase1_known_vas(known_vas):
    """Label all known VAs from ASI plugin research."""
    println("=== Phase 1: Known VA Annotations ===")
    count = 0
    for entry in known_vas:
        va = entry["va"]
        name = entry["name"]
        etype = entry.get("type", "")
        comment = entry.get("comment", "")

        full_comment = "[Mercs2-RE] %s" % comment if comment else "[Mercs2-RE] %s" % etype

        if create_label_safe(va, name, full_comment, namespace="Mercs2"):
            count += 1
            println("  Labeled 0x%08X as %s" % (va, name))

    println("  Phase 1 complete: %d labels applied" % count)
    return count


# ══════════════════════════════════════════════════════════════════════════
# Phase 2: String cross-reference (Mercs 1 strings → Mercs 2 binary)
# ══════════════════════════════════════════════════════════════════════════

def phase2_string_xref(annotation_db):
    """Find Mercs 1 debug strings in the Mercs 2 binary and label referencing functions."""
    println("=== Phase 2: String Cross-Reference ===")

    sections = annotation_db.get("metadata", {}).get("sections", {})
    rdata = sections.get("rdata", {})
    rdata_start = rdata.get("start", 0x00B05000)
    rdata_end = rdata.get("end", 0x00BF6000)

    high_value = annotation_db.get("string_database", {}).get("high_value_strings", [])
    debug_strings = annotation_db.get("string_database", {}).get("debug_strings", {})

    total_strings = len(high_value)
    matches_found = 0
    functions_labeled = 0

    println("  Searching %d high-value strings in .rdata [0x%08X - 0x%08X]..." %
            (total_strings, rdata_start, rdata_end))

    # Process in batches with progress
    for idx, target in enumerate(high_value):
        if idx % 100 == 0:
            monitor.setMessage("String scan: %d/%d" % (idx, total_strings))
            if monitor.isCancelled():
                println("  Cancelled by user")
                break

        # Skip very short or overly generic strings
        if len(target) < 5:
            continue
        # Skip strings with non-ASCII
        try:
            target.encode('ascii')
        except (UnicodeEncodeError, UnicodeDecodeError):
            continue

        locations = find_string_in_memory(target, rdata_start, rdata_end)
        if not locations:
            continue

        matches_found += 1

        for string_va in locations:
            # Find references to this string
            refs = get_references_to(string_va)
            for ref_va in refs:
                func = get_function_at(ref_va)
                if func is not None:
                    func_va = func.getEntryPoint().getOffset()
                    func_name = func.getName()

                    # Build context from Mercs 1 source
                    context_parts = []
                    if target in debug_strings:
                        for loc in debug_strings[target][:3]:
                            context_parts.append("%s:%d" % (
                                os.path.basename(loc.get("file", "?")),
                                loc.get("line", 0)))

                    context = ", ".join(context_parts) if context_parts else "Mercs1 match"
                    comment = "[Mercs1-XRef] String \"%s\" from %s" % (
                        target[:60] + "..." if len(target) > 60 else target,
                        context)

                    set_pre_comment(func_va, comment)

                    # If the function has a default name, try to derive a better one
                    if func_name.startswith("FUN_") or func_name.startswith("sub_"):
                        # Try to use the string as a hint for the function name
                        if target in debug_strings:
                            # Use the first Mercs 1 source location
                            for loc in debug_strings[target]:
                                src_file = os.path.basename(loc.get("file", ""))
                                if src_file:
                                    base = os.path.splitext(src_file)[0]
                                    hint = "maybe_%s_L%d" % (base, loc.get("line", 0))
                                    set_pre_comment(func_va,
                                                    "[Mercs1-Hint] Possibly from %s" % src_file)
                                    break

                    functions_labeled += 1

    println("  Phase 2 complete: %d string matches, %d function annotations" %
            (matches_found, functions_labeled))
    return matches_found


# ══════════════════════════════════════════════════════════════════════════
# Phase 3: luaL_Reg table scanner
# ══════════════════════════════════════════════════════════════════════════

def phase3_lua_reg_scanner(annotation_db):
    """
    Scan .rdata for luaL_Reg arrays: consecutive (string_ptr, func_ptr) pairs
    where string_ptr → readable ASCII in .rdata and func_ptr → .text,
    terminated by (0, 0).
    """
    println("=== Phase 3: luaL_Reg Table Scanner ===")

    sections = annotation_db.get("metadata", {}).get("sections", {})
    rdata = sections.get("rdata", {})
    text = sections.get("text", {})
    rdata_start = rdata.get("start", 0x00B05000)
    rdata_end = rdata.get("end", 0x00BF6000)
    text_start = text.get("start", 0x00401000)
    text_end = text.get("end", 0x00B04000)

    # Known Mercs 1 lua function names for cross-referencing
    mercs1_lua_names = set()
    for entry in annotation_db.get("lua_registrations", {}).get("mercs1_entries", []):
        mercs1_lua_names.add(entry["lua_name"])

    tables_found = 0
    functions_labeled = 0

    # Scan .rdata at 4-byte alignment looking for luaL_Reg arrays
    scan_start = rdata_start
    scan_end = rdata_end - 16  # need room for at least one entry + terminator

    println("  Scanning .rdata [0x%08X - 0x%08X] for luaL_Reg tables..." %
            (scan_start, scan_end))

    current = scan_start
    while current < scan_end:
        if (current - scan_start) % 0x10000 == 0:
            monitor.setMessage("luaL_Reg scan: 0x%08X" % current)
            if monitor.isCancelled():
                println("  Cancelled by user")
                break

        try:
            ptr1 = read_dword(addr(current))
            ptr2 = read_dword(addr(current + 4))
        except Exception:
            current += 4
            continue

        # Check if this looks like a luaL_Reg entry:
        # ptr1 should be a string pointer in .rdata
        # ptr2 should be a function pointer in .text
        if not (rdata_start <= ptr1 < rdata_end and text_start <= ptr2 < text_end):
            current += 4
            continue

        if not is_readable_ascii(ptr1):
            current += 4
            continue

        # Potential table start. Walk forward to collect entries.
        entries = []
        scan_pos = current
        while scan_pos < scan_end:
            try:
                sp = read_dword(addr(scan_pos))
                fp = read_dword(addr(scan_pos + 4))
            except Exception:
                break

            # Terminator: (0, 0)
            if sp == 0 and fp == 0:
                entries.append({"string_va": 0, "func_va": 0, "name": None})
                break

            # Validate entry
            if not (rdata_start <= sp < rdata_end):
                break
            if not (text_start <= fp < text_end):
                break

            name = read_cstring(addr(sp))
            if len(name) < 1:
                break

            entries.append({
                "string_va": sp,
                "func_va": fp,
                "name": name,
            })
            scan_pos += 8

        # Valid table has at least 2 real entries + terminator
        real_entries = [e for e in entries if e["name"] is not None]
        if len(real_entries) >= 2 and entries[-1]["string_va"] == 0:
            tables_found += 1

            # Try to identify the module name from the entries
            module_name = identify_lua_module(real_entries)
            table_label = "luaL_Reg_%s" % module_name if module_name else "luaL_Reg_table_%d" % tables_found

            create_label_safe(current, table_label,
                              "[Mercs2-Lua] luaL_Reg table with %d entries" % len(real_entries),
                              namespace="Mercs2_Lua")

            println("  Table at 0x%08X: %s (%d entries)" %
                    (current, table_label, len(real_entries)))

            for entry in real_entries:
                fname = entry["name"]
                fva = entry["func_va"]

                # Label the function
                lua_label = "lua_%s" % fname
                mercs1_match = fname in mercs1_lua_names
                comment = "[Mercs2-Lua] Registered as \"%s\"" % fname
                if mercs1_match:
                    comment += " (MATCH: Mercs 1 has same name)"
                if module_name:
                    comment += " [module: %s]" % module_name

                if create_label_safe(fva, lua_label, comment, namespace="Mercs2_Lua"):
                    functions_labeled += 1

                # Also label the string
                create_label_safe(entry["string_va"], "str_%s" % fname,
                                  namespace="Mercs2_LuaStrings")

            # Skip past this table for the next scan
            current = scan_pos + 8
            continue

        current += 4

    println("  Phase 3 complete: %d tables found, %d functions labeled" %
            (tables_found, functions_labeled))
    return tables_found


def identify_lua_module(entries):
    """Try to identify the Lua module name from luaL_Reg entry names."""
    names = [e["name"] for e in entries if e.get("name")]
    if not names:
        return None

    # Check for dot-notation (e.g., "Printf" in Debug table)
    # or underscore-separated prefixes
    prefix_counts = {}
    for name in names:
        # Split on underscore or CamelCase boundary
        parts = name.split("_", 1)
        if len(parts) > 1:
            prefix = parts[0]
            prefix_counts[prefix] = prefix_counts.get(prefix, 0) + 1

    if prefix_counts:
        best = max(prefix_counts, key=prefix_counts.get)
        if prefix_counts[best] >= len(names) * 0.4:
            return best

    # Check for known module patterns
    known_modules = {
        "Printf": "Debug", "Assert": "Debug", "Break": "Debug",
        "WriteToConsole": "Sys", "IsOnlineConnected": "Net",
        "Spawn": "Mission", "GetTime": "Mission",
        "PlayVoiceover": "Audio", "PlayMusic": "Audio",
        "SetMode": "Camera", "SetPosition": "Camera",
        "GetAttitude": "Faction", "SetRelation": "Faction",
    }
    for name in names:
        if name in known_modules:
            return known_modules[name]

    return None


# ══════════════════════════════════════════════════════════════════════════
# Phase 4: RTTI / VTable scanner
# ══════════════════════════════════════════════════════════════════════════

def phase4_rtti_scanner(annotation_db):
    """
    Scan for MSVC RTTI type descriptors (.?AV prefix) and map to class names.
    Cross-reference with Mercs 1 class names.
    """
    println("=== Phase 4: RTTI / VTable Scanner ===")

    sections = annotation_db.get("metadata", {}).get("sections", {})
    rdata = sections.get("rdata", {})
    rdata_start = rdata.get("start", 0x00B05000)
    rdata_end = rdata.get("end", 0x00BF6000)

    rtti_patterns = annotation_db.get("rtti_patterns", [])
    mercs1_classes = set()
    for p in rtti_patterns:
        mercs1_classes.add(p["class_name"])

    println("  Searching for MSVC RTTI type descriptors (.?AV prefix)...")

    # Search for the RTTI signature
    rtti_locations = find_string_in_memory(".?AV", rdata_start, rdata_end)
    println("  Found %d potential RTTI type descriptor strings" % len(rtti_locations))

    classes_found = 0
    mercs1_matches = 0

    for rtti_va in rtti_locations:
        if monitor.isCancelled():
            break

        # Read the full class name
        full_name = read_cstring(addr(rtti_va), 256)
        if not full_name or not full_name.startswith(".?AV"):
            continue

        # Extract class name: .?AVClassName@@ or .?AVClassName@Namespace@@
        # Strip .?AV prefix and @@ suffix
        class_part = full_name[4:]  # remove .?AV
        if class_part.endswith("@@"):
            class_part = class_part[:-2]

        # Handle namespaced names
        parts = class_part.split("@")
        class_name = parts[0]
        namespace_name = parts[1] if len(parts) > 1 else ""

        if not class_name:
            continue

        classes_found += 1

        # Check Mercs 1 cross-reference
        is_mercs1 = class_name in mercs1_classes
        if is_mercs1:
            mercs1_matches += 1

        # The RTTI type descriptor is usually at offset +8 from the
        # _TypeDescriptor struct start (after the vtable ptr and spare ptr).
        # The actual _TypeDescriptor starts 8 bytes before the name string.
        type_desc_va = rtti_va - 8

        label = "RTTI_%s" % class_name
        if namespace_name:
            label = "RTTI_%s_%s" % (namespace_name, class_name)

        comment = "[Mercs2-RTTI] Class: %s" % class_name
        if namespace_name:
            comment += " (namespace: %s)" % namespace_name
        if is_mercs1:
            comment += " [MERCS1 MATCH]"
            # Find source file from Mercs 1
            for p in rtti_patterns:
                if p["class_name"] == class_name:
                    if p.get("source_file"):
                        comment += " — see %s" % os.path.basename(p["source_file"])
                    if p.get("parent_class"):
                        comment += " (parent: %s)" % p["parent_class"]
                    break

        create_label_safe(type_desc_va, label, comment, namespace="Mercs2_RTTI")

        # Find references to this type descriptor to locate vtables
        refs = get_references_to(type_desc_va)
        for ref_va in refs:
            # A reference to the type descriptor from .rdata is likely a
            # Complete Object Locator → vtable
            try:
                mem_block = currentProgram.getMemory().getBlock(addr(ref_va))
                if mem_block and mem_block.getName() in (".rdata", ".data"):
                    vtable_comment = "[Mercs2-VTable] Likely vtable ref for %s" % class_name
                    set_pre_comment(ref_va, vtable_comment)
            except Exception:
                pass

    println("  Phase 4 complete: %d RTTI classes found, %d match Mercs 1 source" %
            (classes_found, mercs1_matches))
    return classes_found


# ══════════════════════════════════════════════════════════════════════════
# Phase 5: Propagate known VA labels (callers/callees)
# ══════════════════════════════════════════════════════════════════════════

def phase5_propagate(known_vas):
    """For key known functions, label their callers with context."""
    println("=== Phase 5: Label Propagation ===")

    propagation_targets = [
        ("luaL_loadbuffer", 0x00860240, "calls_luaL_loadbuffer"),
        ("lua_pcall", 0x0085DF50, "calls_lua_pcall"),
        ("luaB_loadstring", 0x00860FC0, "calls_luaB_loadstring"),
        ("luaB_pcall", 0x008615F0, "calls_luaB_pcall"),
        ("_SYS._IMPORT", 0x005AE2D0, "calls_SYS_IMPORT"),
        ("shared_print_stub", 0x006D5640, "calls_print_stub"),
    ]

    total_callers = 0
    for func_name, va, caller_prefix in propagation_targets:
        if monitor.isCancelled():
            break

        refs = get_references_to(va)
        caller_count = 0
        for ref_va in refs:
            func = get_function_at(ref_va)
            if func is not None:
                func_va = func.getEntryPoint().getOffset()
                comment = "[Mercs2-Propagate] Calls %s (0x%08X)" % (func_name, va)
                set_pre_comment(func_va, comment)
                caller_count += 1

        if caller_count > 0:
            println("  %s (0x%08X): %d callers annotated" % (func_name, va, caller_count))
            total_callers += caller_count

    println("  Phase 5 complete: %d total caller annotations" % total_callers)
    return total_callers


# ══════════════════════════════════════════════════════════════════════════
# Main entry point
# ══════════════════════════════════════════════════════════════════════════

def main():
    println("=" * 70)
    println("  Mercenaries 2 Binary Annotation Script")
    println("  Cross-referencing with Mercenaries 1 engine source")
    println("=" * 70)
    println("")

    # Ask user for the annotation JSON file
    json_file = None

    # Try default location first
    default_path = os.path.join(
        os.path.dirname(os.path.abspath(__file__)),
        "mercs2_annotations.json"
    )
    if os.path.exists(default_path):
        json_file = default_path
        println("Using default annotation file: %s" % json_file)
    else:
        # Prompt user
        try:
            f = askFile("Select mercs2_annotations.json", "Open")
            json_file = f.getAbsolutePath()
        except Exception:
            println("ERROR: No annotation file selected. Run ghidra_mercs2_preanalysis.py first.")
            return

    if not os.path.exists(json_file):
        println("ERROR: File not found: %s" % json_file)
        return

    println("Loading annotation database: %s" % json_file)
    with open(json_file, 'r') as f:
        annotation_db = json.load(f)

    stats = annotation_db.get("stats", {})
    println("  Source files:      %d" % stats.get("source_files_scanned", 0))
    println("  Debug strings:     %d" % stats.get("debug_strings_found", 0))
    println("  Lua registrations: %d" % stats.get("lua_reg_entries_found", 0))
    println("  RTTI patterns:     %d" % stats.get("rtti_patterns", 0))
    println("")

    # Start a transaction for all modifications
    txn = currentProgram.startTransaction("Mercs2 Annotation")
    try:
        # Phase 1: Known VAs
        phase1_known_vas(annotation_db.get("known_vas", []))
        println("")

        # Phase 2: String cross-reference
        phase2_string_xref(annotation_db)
        println("")

        # Phase 3: luaL_Reg table scanner
        phase3_lua_reg_scanner(annotation_db)
        println("")

        # Phase 4: RTTI / VTable scanner
        phase4_rtti_scanner(annotation_db)
        println("")

        # Phase 5: Propagation
        phase5_propagate(annotation_db.get("known_vas", []))
        println("")

        println("=" * 70)
        println("  Annotation complete!")
        println("  All labels are in the Mercs2 / Mercs2_Lua / Mercs2_RTTI namespaces.")
        println("  Re-running this script is safe (idempotent).")
        println("=" * 70)

    finally:
        currentProgram.endTransaction(txn, True)


# Run
main()
