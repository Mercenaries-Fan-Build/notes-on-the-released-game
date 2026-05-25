# Ghidra Annotation Guide — Mercenaries 2 PC Binary

Automated annotation of the Mercenaries 2 PC executable by cross-referencing
with the Mercenaries 1 engine source code.

## Overview

The annotation workflow has two phases:

1. **Pre-analysis** (runs standalone with Python 3.12+): Scans Mercs 1 source
   code and builds a JSON database of strings, class names, Lua registrations,
   and known VAs.

2. **Ghidra annotation** (runs inside Ghidra's Jython): Reads the JSON database
   and applies labels, comments, and namespace annotations to the loaded binary.

This separation means you can regenerate the annotation data without re-running
Ghidra, and the Ghidra script itself stays simple.

---

## Prerequisites

- **Ghidra** 10.x+ installed
- **Mercenaries 2 cracked EXE** (53,482,288 bytes) loaded as a Ghidra project
- **Mercs 1 source code** at `game-files/first-game-source-code-with-engine/`
- **Python virtualenv** (run `make venv` to set up)

---

## Step 1: Generate the Annotation Database

```bash
make ghidra-annotate-preanalysis
```

Or manually:

```bash
.venv/bin/python3 scripts/ghidra_mercs2_preanalysis.py --output scripts/mercs2_annotations.json
```

This scans ~600 source files from the Mercs 1 engine and produces
`scripts/mercs2_annotations.json` containing:

| Section | Contents |
|---------|----------|
| `known_vas` | All VAs identified by the ASI plugin research |
| `lua_registrations` | 350+ Lua C function registration entries from `kLuaBaseFns[]` and `kLuaUserDataRsActorFns[]` |
| `rtti_patterns` | MSVC RTTI `.?AV` patterns for every class in Mercs 1 |
| `string_database` | Debug strings, error messages, format strings |
| `class_hierarchy` | Class inheritance relationships |

### Output statistics (typical)

```
Source files scanned: ~600
Debug strings:       ~200+
Class names:         ~300+
Lua registrations:   ~350+
RTTI patterns:       ~300+
High-value strings:  ~800+
```

---

## Step 2: Run the Ghidra Annotation Script

### GUI mode

1. Open the Mercs 2 EXE in Ghidra and let auto-analysis complete
2. Go to **Window → Script Manager**
3. Click the **Manage Script Directories** icon (folder with +)
4. Add the repo's `scripts/` directory
5. Find `ghidra_mercs2_annotate.py` in the script list
6. Run it — it will auto-detect `mercs2_annotations.json` in the same directory,
   or prompt you to select it

### Headless mode

```bash
analyzeHeadless /path/to/ghidra_project Mercs2 \
  -process Mercenaries2.exe \
  -postScript /path/to/scripts/ghidra_mercs2_annotate.py
```

Make sure `mercs2_annotations.json` is in the same directory as the script,
or the script will prompt for a file (which won't work headless — copy it
alongside the script).

---

## What the Script Annotates

### Phase 1: Known VA Labels

Labels all addresses discovered through ASI plugin research:

| VA | Label | Type |
|----|-------|------|
| `0x005AE2D0` | `_SYS._IMPORT` | lua_CFunction (import() implementation) |
| `0x00860240` | `luaL_loadbuffer` | LTCG Lua API |
| `0x0085DF50` | `lua_pcall` | LTCG Lua API |
| `0x00860FC0` | `luaB_loadstring` | cdecl wrapper |
| `0x008615F0` | `luaB_pcall` | cdecl wrapper |
| `0x006D5640` | `shared_print_stub` | xor eax,eax; ret |
| `0x00B98828` | `Debug_luaL_Reg_table` | .rdata table start |
| ... | (15+ total) | |

### Phase 2: String Cross-Reference

Searches the .rdata section for strings that also appear in the Mercs 1 source
code. When found, annotates the referencing functions with:

- Pre-comment: `[Mercs1-XRef] String "..." from RsLuaState.cpp:104`
- Source file hint: `[Mercs1-Hint] Possibly from RsLuaState.cpp`

This helps identify functions that handle similar logic in both games.

### Phase 3: luaL_Reg Table Scanner

Scans .rdata for patterns matching luaL_Reg struct arrays:

```
{ ptr_to_string, ptr_to_code }  ← string in .rdata, code in .text
{ ptr_to_string, ptr_to_code }
...
{ 0, 0 }                        ← terminator
```

For each table discovered:
- Labels the table: `luaL_Reg_Debug`, `luaL_Reg_Sys`, etc.
- Labels each function: `lua_Printf`, `lua_IsOnlineConnected`, etc.
- Cross-references against Mercs 1 registrations
- Identifies the Lua module (Debug, Sys, Actor, Mission, etc.)

### Phase 4: RTTI / VTable Scanner

Finds MSVC RTTI type descriptors (`.?AV` prefix strings) and:
- Labels each type descriptor with the class name
- Cross-references with Mercs 1 class hierarchy
- Annotates vtable references

### Phase 5: Label Propagation

For key known functions (luaL_loadbuffer, lua_pcall, _SYS._IMPORT, etc.),
finds all callers and annotates them with context about what they call.

---

## Namespaces

All labels are organized into Ghidra namespaces:

| Namespace | Contents |
|-----------|----------|
| `Mercs2` | Known VAs, general annotations |
| `Mercs2_Lua` | luaL_Reg tables and Lua-registered functions |
| `Mercs2_LuaStrings` | String literals from luaL_Reg entries |
| `Mercs2_RTTI` | RTTI type descriptors and vtable references |

---

## Idempotency

The script is safe to run multiple times. It checks for existing labels before
creating new ones, and appends comments rather than replacing them.

---

## Customization

### Adding new known VAs

Edit the `KNOWN_VAS` list in `scripts/ghidra_mercs2_preanalysis.py`:

```python
{"va": 0x00XXXXXX, "name": "function_name", "type": "category",
 "comment": "Description of what this address is"},
```

Then re-run `make ghidra-annotate-preanalysis` and the Ghidra script.

### Adding source directories

Pass `--source-dirs` to the pre-analysis script:

```bash
.venv/bin/python3 scripts/ghidra_mercs2_preanalysis.py \
  --source-dirs /path/to/more/source \
  --output scripts/mercs2_annotations.json
```

---

## Troubleshooting

**"No annotation file selected"**: Run the pre-analysis step first, or copy
`mercs2_annotations.json` to the same directory as the Ghidra script.

**Slow Phase 2 (string scan)**: The string scan searches ~800+ patterns across
~1MB of .rdata. It takes a few minutes. You can cancel with Ghidra's cancel
button — partial results are kept.

**Phase 3 finds too many/few tables**: The luaL_Reg scanner requires at least
2 consecutive (string, code) pairs followed by a (0, 0) terminator. Adjust the
minimum entry count in the script if needed.

**Binary size mismatch**: The known VAs are specific to the cracked retail EXE
(53,482,288 bytes). If your binary differs, Phase 1 labels may point to wrong
locations — skip it by commenting out the `phase1_known_vas()` call.
