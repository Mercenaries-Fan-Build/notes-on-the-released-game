# Mercenaries 2 EXE Cross-Validation Report

> Cross-validated findings from two independent reverse-engineering analyses of the
> cracked `MERCENAR.EXE` (53,482,288 bytes, SecuROM removed).
>
> **Source analyses:** `docs/exe_analysis_agent_a.md` and `docs/exe_analysis_agent_b.md`
>
> **Date:** 2026-05-18
> **Status:** Cross-validated. Code fixes applied and tested.

---

## Table of Contents

1. [sges Format (Engine Validation)](#1-sges-format-engine-validation)
2. [Pandemic FNV-1a Hash (Mercs 2 Variant)](#2-pandemic-fnv-1a-hash-mercs-2-variant)
3. [Lua Integration](#3-lua-integration)
4. [Demo Timer](#4-demo-timer)
5. [Patch WAD Mechanism](#5-patch-wad-mechanism)
6. [Event System](#6-event-system)
7. [Auto-Complete Mod Failure Explanation](#7-auto-complete-mod-failure-explanation)
8. [Points of Divergence](#8-points-of-divergence)
9. [Verification Results](#9-verification-results)

---

## 1. sges Format (Engine Validation)

**Confidence:** CERTAIN (both agents agree, binary-verified against demo `vz.wad`)

### Header Layout (16 bytes)

| Offset | Size | Field | Validation |
|--------|------|-------|------------|
| +0x00 | 4 | Magic `sges` | Engine checks `cmp dword [ptr], 0x73676573` |
| +0x04 | 2 | Major version (u16) | Must be `4` |
| +0x06 | 2 | Segment count (u16) | Used as loop counter |
| +0x08 | 4 | Total uncompressed size (u32) | Validated ≤ expected size from block table |
| +0x0C | 4 | Total compressed/block size (u32) | Block extent hint |

### Segment Table (starts at offset 0x10)

Each entry is 8 bytes:

| Offset | Size | Field |
|--------|------|-------|
| +0x00 | 2 | Compressed size (u16) |
| +0x02 | 2 | Uncompressed size (u16); **0 means 65536 (0x10000) default** |
| +0x04 | 4 | Offset with compression flag (u32) |

The offset field's **bit 0** is the compression flag:
- Bit 0 = 1: segment is deflate-compressed
- Bit 0 = 0: segment is stored raw (uncompressed)
- Engine reads actual offset via `value & 0xFFFFFFFE`

Since all segment offsets are 16-byte aligned (always even), bit 0 is always available for the flag.

### Data Payload

Starts at `ceil((16 + segment_count × 8) / 16) × 16` bytes from block start (16-byte aligned). Segments are raw deflate (`zlib` windowBits `-15`), separated by zero-padding for alignment.

### Agent Report Discrepancy: Offset 0x10 vs 0x12

Both agent reports state the segment table starts at **offset 0x12** (18 bytes). However, **binary verification proves the table starts at offset 0x10** (16 bytes):

- Reading block 0 of demo `vz.wad` at DATA+0x00:
  - At +0x10: `u16=22679` (comp_size), `u16=0` (decomp=64KB), `u32=33` (offset 32 | flag 1)
  - At +0x12: would give `u16=0`, `u16=33`, `u32=0x43AD0000` — nonsensical

- Deflate decompression succeeds at offset 32 (= 33 & 0xFFFFFFFE), producing exactly 65536 bytes
- Second segment at offset 22720 (= 22721 & 0xFFFFFFFE) decompresses to exactly 52937 bytes
- 65536 + 52937 = 118473 = total_u from header — perfect match

**Explanation of the agent error:** The assembly shows `ptr+0x12` where `ptr` is the segment table start, not the sges block start. The agents likely confused a field-relative offset within an entry (`entry+2` for the offset field) with the table's absolute position. The table starts at byte 16 (0x10) of the sges block.

**Our code is correct.** `sges_data_offset(N) = ceil((16 + N*8)/16) * 16` works perfectly.

---

## 2. Pandemic FNV-1a Hash (Mercs 2 Variant)

**Confidence:** CERTAIN — independently confirmed by both agents, validated against known type constants

### Algorithm

```c
uint32_t pandemic_hash_m2(const char* str) {
    if (*str == '\0') return 0;
    uint32_t hash = 0x811C9DC5;      // FNV-1a offset basis
    while (*str) {
        hash ^= (uint32_t)(*str | 0x20);  // case suppression
        hash *= 0x01000193;           // FNV-1a prime
        str++;
    }
    // Mercs 2 post-processing (NOT present in Mercs 1)
    hash ^= 0x2A;
    hash *= 0x01000193;
    return hash;
}
```

### Key Properties

- **Case-insensitive**: each byte OR'd with `0x20` before XOR (forces uppercase to lowercase)
- **Post-processing**: after the main loop: `hash ^= 0x2A; hash *= 0x01000193`
- **Empty string**: returns 0 (early exit before loop)
- **Call sites**: 166+ locations in the binary (pervasive)
- **NOT present in Mercs 1**: the Mercenaries 1 source code (`Hash.c`, `PblHashTable.cpp`) uses the same FNV-1a + case suppression but WITHOUT the post-processing step

### Verified Matches

| Input | Hash (Mercs 2) | Where Used |
|-------|----------------|------------|
| `"texture"` | `0xF011157A` | ASET type discriminator (BODY/texture streaming) |
| `"model"` | `0x5B724250` | ASET type discriminator (mesh type) |
| `"registry"` | `0x3884598e` | Mercs 1 only (WITHOUT post-processing) |

### Two Variants in Our Tooling

| Function | Post-processing | Use Case |
|----------|----------------|----------|
| `pandemic_hash()` | No | Mercs 1 compatibility, path lookups where Mercs 1 source confirms behavior |
| `pandemic_hash_m2()` | Yes | Mercs 2 ASET type lookups, runtime asset resolution |

**Implementation:** `tools/pandemic_hash.py` — use `--m2` flag for Mercs 2 variant.

### Remaining Unknown

The ASET **name_hash** values (per-asset identity, e.g., `0x35383CCD` for `vz_mar_roads`) do NOT match either variant when tested against any obvious name format. The input to the hash for per-asset keys may include additional path/prefix transformations, or may use a completely different algorithm. This remains an open question.

---

## 3. Lua Integration

**Confidence:** CERTAIN (both agents find identical strings and offsets)

### Core Facts

| Property | Value | Evidence |
|----------|-------|----------|
| Version | Lua 5.1.2 | String at offset `0x007925B8` |
| Source path | `D:\Projects\Mercs2_PC\mercs2\Lua-5.1.2\src\` | Debug paths |
| Number type | `float` (4 bytes) | Bytecode headers: `sizeof(lua_Number)=4` |
| Registered functions | 800–1300+ | `luaL_Reg` tables at `0x00798770–0x00799200` |

### Bootstrap Code (at offset 0x007B4EE2)

```lua
_G._MODULES = {};
_MODULESMETATABLE = { __index = _SYS._MODULEINDEX };

function _G.import(module)
    return _SYS._IMPORT(getfenv(2), module);
end

function _G.dynamic_import(module, callbackfunc, callbackdata)
    return _SYS._DYNAMIC_IMPORT(_SYS._GETFENV(2) or _G, module, callbackfunc, callbackdata);
end

function _G.inherit(module)
    return _SYS._INHERIT(getfenv(2), module);
end

function _G.dynamic_remove(module)
    return _SYS._DYNAMIC_REMOVE(_SYS._GETFENV(2), module);
end
```

### How Module Loading Works

1. `import("foo")` → `_SYS._IMPORT(getfenv(2), "foo")`
2. C++ resolves `"foo"` to a WAD block asset hash
3. Loads the Lua bytecode from the WAD's BINN chunk
4. Executes it in the caller's environment (scoped isolation)
5. Modules tracked in `_G._MODULES` with metatable `_MODULESMETATABLE`

### How `inherit()` Works

- `inherit("base_module")` → `_SYS._INHERIT(getfenv(2), "base_module")`
- Copies all functions/values from the base module's environment into the caller's environment (prototype-based inheritance pattern)

---

## 4. Demo Timer

**Confidence:** CERTAIN (flag address) / LIKELY (timer constants)

| Property | Value | Location |
|----------|-------|----------|
| Demo flag | Single byte at address `0x01175F59` | `.data` section, file offset `0x00D75F59` |
| `IsDemoMode` function | VA `0x005E5670` | Reads flag byte, pushes boolean to Lua stack |
| Timer value | `900.0` float (15 minutes) | `.rdata` at file offset `0x007EAACC` |
| Warning threshold | `480.0` float (8 minutes) | Adjacent float at `0x007EAAC4` |

The demo timer is **managed in Lua**, not hardcoded as a C++ loop. `IsDemoMode` simply returns the flag value; Lua scripts handle the countdown, warnings, and boundary restrictions using the Event system.

In the cracked retail exe, the flag byte = `0x00` (not demo mode).

---

## 5. Patch WAD Mechanism

**Confidence:** CERTAIN (format strings at known offsets)

| String | Offset | Purpose |
|--------|--------|---------|
| `%s\%s.wad` | `0x007AFED0` | Primary WAD load pattern |
| `%s\%s-patch.wad` | `0x007AFF5C` | Patch overlay WAD |

### Loading Sequence

1. Engine formats path: `sprintf(buf, "%s\\%s.wad", data_dir, wad_name)`
2. Opens and parses the primary WAD (FFCS format)
3. Immediately tries `sprintf(buf, "%s\\%s-patch.wad", data_dir, wad_name)`
4. Patch WAD is optional — if it exists, it overlays blocks using same FFCS format
5. **Last-loaded-wins** for asset hash collisions (patch overrides base)

### Modding Implication

This is the intended modding entry point: create a `vz-patch.wad` containing only modified blocks. The engine's design supports it natively.

---

## 6. Event System

**Confidence:** CERTAIN (registration table disassembly)

### Event Module (at registration table 0x007987F8)

| Function | C++ VA | Behavior |
|----------|--------|----------|
| `Event.Create` | `0x005F69F0` | `push 0; call 0x005F6660` (persistent=false) |
| `Event.CreatePersistent` | `0x005F6A00` | `push 1; call 0x005F6660` (persistent=true) |
| `Event.Delete` | `0x005F6A10` | Delete an event handle |
| `Event.Post` | `0x005F6A90` | Dispatch/fire an event |

Both `Create` and `CreatePersistent` call the same internal function at `0x005F6660` with a boolean persistence flag.

### Contract Lifecycle

Registered at offsets `0x7B8A88–0x7B8AC4`:

```
ContractActivated  → script begins (state machine enters active)
ContractCompleted  → fired when contract is done
ContractCancelled  → fired when contract is cancelled
```

The `Completed`/`Failed` strings are registered in the **Faction/Pursuit** Lua table, suggesting contract completion goes through the faction state machine rather than being a simple direct event post.

### Event Listener Types (from registration tables)

```
Event, WeaponEvent, ScriptEvent, HumanAnimationNearlyCompleted,
HumanActionComplete, AirstrikeDeliveryReady, GameStateChange,
TimerRelative, GuiGameTimer, ObjectIsVisible, ObjectPhysicsEvent,
ObjectIsGrounded, ObjectIsReady, ObjectHibernation, Boundary,
ObjectProximity, ObjectHealthLessThan, ObjectHealth
```

---

## 7. Auto-Complete Mod Failure Explanation

**Confidence:** LIKELY (inferred from combined evidence)

Both agents converge on the same explanation for why a Lua auto-complete mod doesn't fire:

1. **State machine gating**: Contracts use `StateMachine` components (768 pool slots). `self:Complete()` triggers C++ `ContractCompleted` which requires the contract to be in the correct state machine phase. Calling it from an invalid state is rejected.

2. **Faction system validation**: The `Completed` string lives in the Faction/Pursuit table, not a standalone event. Contract completion must flow through faction reputation logic.

3. **Module environment isolation**: `import()` scopes modules via `getfenv(2)`. A mod injected at the wrong scope won't have access to the contract's environment variables or state.

4. **Event typing**: The event system has typed dispatchers (`ProcessEventImmediate`, `GetEventListTable`). Using the wrong event type (e.g., `Event.TimerRelative` vs `Event.Timer`) would silently fail.

5. **Network sync architecture**: `NetSynchImportModule` / `SynchNetImportModule` suggest the game uses client-server architecture internally, even in single-player. Module imports may require synchronization.

---

## 8. Points of Divergence

These are areas where the two agent analyses disagree or provide different data. Further investigation may be needed.

| Topic | Agent A | Agent B | Assessment |
|-------|---------|---------|------------|
| sges validation function offset | File offset `0x00114870` | File offset `0x001148B0` | 0x40 (64 byte) difference — likely different entry points or inlined copies of the same logic |
| Lua function count | 1300+ | 800+ | Different counting methodology; Agent A may count all string references, Agent B may count only verified `luaL_Reg` entries |
| Event dispatch | 44 `SendEvent_*` functions | `Event.Post` at `0x005F6A90` | Complementary: SendEvent functions are C++→Lua bridges; Event.Post is the Lua API |
| Segment table offset | States "+0x12" | States "+0x12" | **BOTH WRONG** — binary verification proves table is at +0x10 (see §1) |

---

## 9. Verification Results

### Code Changes Applied

| File | Change | Result |
|------|--------|--------|
| `tools/pandemic_hash.py` | Added `pandemic_hash_m2()` with `^0x2A; *prime` post-processing | ✓ PASS: `pandemic_hash_m2("texture") == 0xF011157A`, `pandemic_hash_m2("model") == 0x5B724250` |
| `tools/pandemic_hash.py` | Added `--m2` CLI flag | ✓ Working |
| `tools/sges_compress.py` | Updated comment: offset field bit 0 = compression flag | ✓ Round-trip still passes |
| `tools/sges_compress.py` | Changed `+ 1` to `\| 1` (semantically correct, same output) | ✓ Round-trip still passes |

### Tests Performed

1. **Hash v1 (Mercs 1)**: `pandemic_hash("registry") == 0x3884598E` — PASS
2. **Hash v2 (Mercs 2)**: `pandemic_hash_m2("texture") == 0xF011157A` — PASS
3. **Hash v2 (Mercs 2)**: `pandemic_hash_m2("model") == 0x5B724250` — PASS
4. **sges decompression**: Block 0 of demo vz.wad → 118,473 bytes (matches header) — PASS
5. **sges round-trip**: decompress → compress → decompress = byte-identical — PASS
6. **Segment table at 0x10**: Deflate data found at offsets 32 and 22720 (matching entry values) — CONFIRMED

### What Was Already Correct

- `sges_decompress.py`: Segment table parsing at offset 0x10 ✓
- `sges_decompress.py`: Handles zero-uncompressed = 64KB implicitly (via sequential deflate) ✓
- `sges_compress.py`: Segment table layout and data alignment ✓
- `sges_compress.py`: Compression flag handling (was labeled "1-indexed" but produced correct bit pattern) ✓

### What Needed Fixing

- `pandemic_hash.py`: Missing the Mercs 2 post-processing variant. The file only had the Mercs 1 algorithm. **Fixed** by adding `pandemic_hash_m2()` and the `--m2` CLI flag. The original `pandemic_hash()` is preserved for backward compatibility with existing pipeline code that uses Mercs 1 hashing.

---

## Related Documentation

- [`docs/exe_analysis_agent_a.md`](exe_analysis_agent_a.md) — Full Agent A analysis
- [`docs/exe_analysis_agent_b.md`](exe_analysis_agent_b.md) — Full Agent B analysis
- [`docs/modding_deep_dive.md`](modding_deep_dive.md) — Comprehensive modding feasibility analysis
- [`docs/format_reference.md`](format_reference.md) — Binary format specifications
- [`tools/pandemic_hash.py`](../tools/pandemic_hash.py) — Hash implementation (both variants)
- [`tools/sges_compress.py`](../tools/sges_compress.py) — sges block compressor
- [`tools/sges_decompress.py`](../tools/sges_decompress.py) — sges block decompressor
