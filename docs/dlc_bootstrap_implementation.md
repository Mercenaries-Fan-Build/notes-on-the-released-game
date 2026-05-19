# DLC Bootstrap Implementation

> **Date:** 2026-05-19
> **Status:** Implemented. Tooling complete; runtime validation pending (requires game installation with DLC patch WAD).

---

## Overview

The DLC bootstrap injection solves the critical gap identified in
`docs/dlc_loader_cross_reference.md` §5: the Xbox 360 DLC assets load into the
PC engine via `vz-patch.wad`, but no Lua script triggers `import("dlccon001")`
etc. to register the DLC contracts with the game.

This implementation adds:
1. A **`dlc01` master script** that imports all DLC contracts
2. A **modified `vz` master script** that chain-loads `dlc01` at world startup
3. CLI tooling to build or merge the bootstrap into a patch WAD

---

## Architecture

### How It Works

```
Engine boot → opens vz.wad → opens vz-patch.wad (overlay)
           → loads scripts_vz block from patch WAD (overrides base)
           → executes vz master script
              → import("dlc01")     ← NEW: chain-loads DLC master
                 → import("dlccon001")  ← Merc Blitz contract
                 → import("dlccon002")  ← Arms Race contract
                 → import("dlccon003")  ← Urban Rampage contract
                 → import("dlccon004")  ← Death Race contract
```

### What Gets Modified

| Component | Change | Size Impact |
|-----------|--------|-------------|
| `vz` UCFX chunk | Bytecode replaced with minimal `import("dlc01")` wrapper | -37 KB (original is ~38 KB) |
| New `dlc01` UCFX chunk | Added to block with DLC master script bytecode | +~500 bytes |
| Block header table | Entry count incremented, new 16-byte entry appended | +16 bytes |
| ASET entries | New entry for `dlc01` asset hash | +16 bytes |

### Why Replace the `vz` Script?

The `vz` master script (38 KB, largest in scripts_vz) is the core world script
entry point. The engine loads it first, and its `ScriptInit()` initializes the
game world. We cannot easily *prepend* an `import()` call to existing bytecode
without a full decompile/recompile cycle.

Instead, we replace the `vz` bytecode in the **patch WAD's copy** with a
minimal wrapper that does `import("dlc01")`. This works because:

- The **base `vz.wad`** still contains the original `vz` script
- The engine's module system (`import()`) resolves scripts from both WADs
- The patch WAD's `vz` runs first (overlay), triggers DLC loading
- The base WAD's `vz` is not affected (it loads independently via its own
  `scripts_vz` block, which the patch WAD only partially overrides)

**Important nuance:** The patch WAD replaces the *entire* `scripts_vz` block,
not individual scripts within it. So the 113 other scripts in the block
(oilcon001, chicon001, etc.) come from the patch WAD's copy. They are
byte-identical to the original except for oilcon001 string mods and demo timer
disable (applied as existing mods).

---

## Usage

### Integrated Mode (preferred — single command)

```bash
# Full DLC pipeline: port Xbox 360 assets + inject bootstrap in one step
make dlc-port DLC_RAR=path/to/DLC.rar SOURCE_WAD=path/to/vz.wad OUTPUT=./output

# Or directly:
python3 tools/dlc_port.py \
  --x360-rar path/to/DLC.rar \
  --source-wad path/to/vz.wad \
  --output output/data/vz-patch.wad \
  --extract-audio output/data/Audios
```

This produces a single `vz-patch.wad` containing:
- 2,196 DLC asset blocks (Xbox 360 → PC byte-swapped)
- 1 modified `scripts_vz` block with DLC bootstrap

### DLC Port Without Bootstrap

```bash
# Port DLC blocks only (no bootstrap injection):
make dlc-port DLC_RAR=path/to/DLC.rar OUTPUT=./output

# Or explicitly disable with --no-bootstrap:
python3 tools/dlc_port.py \
  --x360-rar path/to/DLC.rar \
  --source-wad path/to/vz.wad \
  --no-bootstrap \
  --output output/data/vz-patch.wad
```

### Standalone Mode (bootstrap-only patch WAD)

```bash
# Build a standalone vz-patch.wad with DLC bootstrap only (no DLC assets)
make dlc-bootstrap SOURCE_WAD=path/to/vz.wad OUTPUT=./output

# Or directly:
python3 tools/build_patch_wad.py \
  --inject-dlc-bootstrap \
  --source-wad path/to/vz.wad \
  --output output/data/vz-patch.wad
```

### Legacy Merge Mode (into existing DLC patch WAD)

```bash
# If you already have a vz-patch.wad from a previous dlc-port run without
# SOURCE_WAD, you can merge the bootstrap into it after the fact:
make dlc-bootstrap-merge SOURCE_WAD=path/to/vz.wad OUTPUT=./output

# Or directly:
python3 tools/build_patch_wad.py \
  --inject-dlc-bootstrap-merge \
  --source-wad path/to/vz.wad \
  --merge-from output/data/vz-patch.wad \
  --output output/data/vz-patch.wad
```

### Custom DLC Contract List

```bash
# Only import specific contracts:
python3 tools/build_patch_wad.py \
  --inject-dlc-bootstrap \
  --source-wad path/to/vz.wad \
  --output output/data/vz-patch.wad \
  --dlc-contracts dlccon001,dlccon002
```

### Without Modifying `vz` (advanced)

```bash
# Add dlc01 UCFX entry but don't replace vz bytecode.
# Use this if you plan to trigger DLC via another mechanism
# (e.g., ASI plugin calling SetMasterScriptName).
python3 tools/build_patch_wad.py \
  --inject-dlc-bootstrap \
  --source-wad path/to/vz.wad \
  --output output/data/vz-patch.wad \
  --no-vz-inject
```

---

## Technical Details

### UCFX Container Structure

Each script in the `scripts_vz` block is wrapped in a UCFX container:

```
UCFX header (20 bytes):
  tag:     "UCFX" (4 bytes)
  u0:      offset to data area (relative to end of chunk headers)
  u1:      data area size
  u2:      number of sub-chunks (always 3: INFO, DEPS, BINN)
  u3:      reserved (0)

INFO chunk header (20 bytes):
  tag:     "INFO" + offset, size, u2, u3

DEPS chunk header (20 bytes):
  tag:     "DEPS" + offset, size, u2, u3

BINN chunk header (20 bytes):
  tag:     "BINN" + offset, size, u2, u3

Data area:
  INFO data:  8 bytes (zeros)
  DEPS data:  4 bytes (zero dependency count)
  BINN data:
    bytecode_size:  u32 (size of LuaQ that follows)
    reserved:       8 bytes (zeros)
    type_code:      u8 = 0x05 (Lua script)
    name_length:    u16
    name:           ASCII + null terminator
    dep_count:      u8 = 0
    padding:        3 bytes
    LuaQ bytecode:  (the compiled Lua)

CSUM trailer (8 bytes):
  tag:     "CSUM" (4 bytes)
  value:   u32 CRC-32/JAMCRC of UCFX body (everything before CSUM)
```

### Block Header Table

The decompressed block starts with a header table:

```
count:   u32 (number of UCFX entries)
entries: count × 16 bytes each:
  asset_hash:  u32 (ASET lookup key)
  type_hash:   u32 (always 0x42498680 for scripts)
  field_c:     u32 (reserved, 0)
  chunk_size:  u32 (total UCFX + CSUM bytes)
```

When adding a new entry, the count is incremented, a new 16-byte entry is
appended to the header, and the existing UCFX data shifts by 16 bytes. All
subsequent chunk offsets in `parse_block_entries()` are recomputed automatically
since they're derived from cumulative sizes.

### Asset Hash

The `dlc01` asset hash is computed as `pandemic_hash_m2("dlc01")` — the same
FNV-1a + post-processing hash used for all asset name lookups. This hash must
appear in both the block header table and the FFCS ASET chunk for the engine's
streaming system to locate the script.

### Lua Compiler

The implementation uses the Mercs 2-compatible Lua 5.1 compiler at
`lua-backup-dont-delete/src/luac` (or `lua-5.1.5/src/luac` as fallback).
This compiler produces bytecode with the required header:

```
\x1bLuaQ\x00\x01\x04\x04\x04\x04\x00
         ^    ^    ^    ^    ^    ^
         |    |    |    |    |    integral=0 (float)
         |    |    |    |    sizeof(lua_Number)=4
         |    |    |    sizeof(Instruction)=4
         |    |    sizeof(size_t)=4
         |    sizeof(int)=4
         endian=LE
```

The critical difference from stock Lua 5.1 is `sizeof(lua_Number) = 4` (float)
instead of the default 8 (double).

---

## Known Limitations

### 1. DLC Contract Bytecode Endianness

The DLC contract scripts (`dlccon001`–`dlccon004`) from the Xbox 360 port are
**big-endian** Lua bytecode. They need endian-swapping or decompile+recompile
before the PC engine can execute them. Options:

- **Bytecode endian-swapper**: Flip the endianness flag in the header, swap all
  u32 instructions and float constants. Not yet implemented.
- **Decompile + recompile**: Use unluac/luadec to decompile the BE bytecode,
  then recompile with the PC-format Lua compiler. More reliable but requires
  the decompiler to handle 4-byte floats correctly.

### 2. DLC Mesh Rendering

Even with scripts activated, DLC meshes won't render correctly until the STRM
vertex data byte-swap is implemented (tracked in `dlc_pc_port_status.md`).
DLC contract logic (objectives, timers, events) should still function.

### 3. `vz` Script Replacement

The `vz` master script in the patch WAD is replaced with a minimal
`import("dlc01")` wrapper. The original 38 KB of world initialization logic
comes from the base `vz.wad`. If the engine's module system doesn't load both
copies (patch + base), the world initialization might not run correctly.

**Mitigation:** Test with `--no-vz-inject` flag first to verify DLC loading
works when triggered via an alternative mechanism (e.g., modifying
`wifpmcinterior` instead, which is always loaded at PMC base entry).

### 4. ASET Hash Registration

The `dlc01` script's asset hash is added to the patch WAD's ASET chunk. The
DLC contract scripts' asset hashes must also be present in the ASET for
`import()` to find them. The `dlc_port.py` pipeline already handles this for
the Xbox 360 DLC blocks, but verify that the merged WAD's ASET contains entries
for all `dlccon*` scripts.

---

## Future Improvements

1. **Full `vz` script augmentation**: Instead of replacing the `vz` bytecode,
   decompile the original 38 KB script, add the `import("dlc01")` call to its
   `ScriptInit()`, and recompile. This preserves all original world logic in a
   single WAD.

2. **Bytecode endian-swapper**: Implement `tools/lua_bytecode_swap.py` to
   convert BE→LE Lua 5.1 bytecode in-place, avoiding the decompile/recompile
   dependency.

3. **Self-registering contracts**: Use `dynamic_import()` instead of static
   `import()` calls, allowing contracts to load asynchronously and gracefully
   handle missing scripts.

4. **Extras menu fix**: Patch `IsOnlineConnected()` in the EXE to return true,
   enabling the Scaleform Extras menu UI alongside the auto-loading approach.

---

## Related Documentation

- [`docs/dlc_loader_cross_reference.md`](dlc_loader_cross_reference.md) — DLC loading mechanism analysis
- [`docs/dlc_extras_activation_research.md`](dlc_extras_activation_research.md) — Research report
- [`docs/modding_deep_dive.md`](modding_deep_dive.md) — Lua bytecode format, CSUM algorithm
- [`docs/dlc_pc_port_status.md`](dlc_pc_port_status.md) — DLC porting gaps
- [`tools/build_patch_wad.py`](../tools/build_patch_wad.py) — Implementation (see `--inject-dlc-bootstrap`)
- [`tools/dlc_port.py`](../tools/dlc_port.py) — Xbox 360 → PC DLC porting
