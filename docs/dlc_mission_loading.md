# DLC Mission Loading — Streaming State Machine & Hang Analysis

> **Date:** 2026-05-23
> **Status:** Active research — streaming hang not yet resolved
> **Context:** PC DLC port via `dlc_enable.asi` + `vz-patch.wad`; cracked retail EXE (53,482,288 bytes)

---

## Table of Contents

1. [Mission Loading State Machine](#1-mission-loading-state-machine)
2. [Key Lua Tables](#2-key-lua-tables)
3. [Base Game Mission Example (PmcCon033)](#3-base-game-mission-example-pmccon033)
4. [The Streaming Refcount Problem](#4-the-streaming-refcount-problem)
5. [Key Addresses](#5-key-addresses-cracked-exe-53482288-bytes)
6. [DLC Bootstrap](#6-dlc-bootstrap)
7. [What Needs to Be Fixed](#7-what-needs-to-be-fixed)
8. [Forensic Tracing Notes](#8-forensic-tracing-notes)
9. [Havok Animation Byte-Swap Fix](#9-havok-animation-byte-swap-fix-vz-patchwad)
10. [DEPS Chunk Byte-Swap Fix](#10-deps-chunk-byte-swap-fix-script-dependencies)
11. [BINN Script-Reference Byte-Swap Fix](#11-binn-script-reference-byte-swap-fix-registry-crash)

---

## 1. Mission Loading State Machine

When a player accepts a contract, the engine runs a multi-phase state machine
that interleaves Lua script execution with native C++ streaming operations.
The following sequence was reconstructed from `Debug.Printf` log captures
of a base-game mission acceptance and a DLC mission acceptance that hangs.

### Phase 1: Mission Selection → Briefing

```
1. Player selects mission at starter NPC
   → Lua sets _sSelectedMission = "<MissionName>"

2. STATE_WAITFORGAME enters (refcount=1)

3. Briefing plays:
   - Cinematic camera
   - Voiceover audio
   - FaceFX lip-sync animation
```

### Phase 2: PMC Interior Teardown

```
4. Fade to black
   → PMC interior layers unloaded (4 layers):
     - vz_state_pmcinterior
     - vz_state_pmcinterior_hel
     - vz_state_pmcinterior_jet
     - vz_state_pmcinterior_mec

5. Reward/wager lookup:
   =-= <MissionName> <value>
   → looks up MrxRewardData._tRewards[MissionName]
   Base game: returns table with .nWagerMin, .nWagerMax, .sFactionId, .nWager, .sMissionId
   DLC:       returns nil → "NOT A WAGER!"
```

### Phase 3: First Streaming Wait (PMC unload)

```
6.  STATE_WAITFORSTREAMING enters (refcount=1) — FIRST streaming state

7.  Briefing assets unloaded (animations, sounds, FaceFX data)

8.  Layer removal requests complete:
    nPendingOps: 4 → 3 → 2 → 1 → 0

9.  WifPmcInterior._ExitEnd: _bLayersRemoved

10. MrxUtil._TeleportHero — player teleported to mission start location

11. _TeleportComplete: bStreamingComplete=nil
    → engine polls until bStreamingComplete=true

12. STATE_WAITFORSTREAMING exits (refcount=0) — FIRST streaming SUCCEEDS
```

### Phase 4: Briefing Cleanup → Mission Module Load

```
13. Briefing task completes
    → missions saved
    → equipment saved

14. "Starter PmcBoss removing briefing <MissionName>"

15. STATE_WAITFORSTREAMING enters (refcount=1) — SECOND streaming state

16. "Dynamically imported module <missionmodule>"
    → engine calls dynamic_import() for the mission's Lua module
```

### Phase 5: Mission Layer Loading (divergence point)

**Base game (e.g. PmcCon033):**

```
17. Mission module's Activated() requests layer loads:
    refcount: 1 → 2 → 3 → 4 → 5
    (each Sys.LoadLayer() call increments native refcount)

    Layer load completions decrement refcount:
    refcount: 5 → 4 → 3 → 2 → 1 → 0

18. STATE_WAITFORSTREAMING exits (refcount=0) — SECOND streaming SUCCEEDS
    → mission gameplay begins
```

**DLC (e.g. DlcCon001):**

```
17. Mission module loads, but the DLC arena layers don't exist in the PC WAD.
    No layer load requests are issued.
    refcount stays at 1.

18. STATE_WAITFORSTREAMING never exits — INFINITE HANG
    Game appears frozen; player is teleported but mission never starts.
```

---

## 2. Key Lua Tables

Six tables govern mission lifecycle. DLC missions are only partially
registered — present in `tMissionData` (via bootstrap injection) but absent
from the reward, flow, and save-data tables.

| Table | Path from `_G` | Con-keys | DlcCon001? | Purpose |
|-------|-----------------|----------|------------|---------|
| `tMissionData` | `_MODULES.wifmissiondata.tMissionData` | 56 | **YES** (registered by ASI bootstrap) | Mission metadata: sStarter, nLevels, sModuleName, tMilestones, sFactionId, bContract, tStartLocations, bRepeatable |
| `_tRewards` | `MrxRewardData._tRewards` | 94 | **NO** | Wager/reward: nWagerMin, nWagerMax, sFactionId, nWager, sMissionId |
| `_tMyFlowData` | `_MODULES.wifmissionflow.MrxMissionFlow._tMyFlowData` | 92 | **NO** | Flow state machine (numeric state enum per mission) |
| `tActiveMissions` | `_MODULES.vz._tPreContractSaveData.tFlowData.tActiveMissions` | 17 | **YES** (added at acceptance) | Currently active missions |
| `tFlowData` | `_MODULES.vz._tPreContractSaveData.tFlowData.tMyFlowData` | 92 | **NO** | Save-game flow data |
| `tRewardData` | `_MODULES.vz._tPreContractSaveData.tRewardData` | 7 (PMC) | **NO** | Save-game reward data |

### What "NO" means for DLC

When `_tRewards[DlcCon001]` is nil, the briefing prints `"NOT A WAGER!"` but
continues anyway — the wager system silently skips. The briefing and acceptance
succeed because `tMissionData` has the entry.

The absence from `_tMyFlowData` is more serious: the flow state machine may
not properly track the mission through its accept → active → complete
lifecycle, and the mission module may not issue the correct layer-load
requests because the flow data that tells it *which* state to activate is
missing.

---

## 3. Base Game Mission Example (PmcCon033)

### tMissionData entry

```lua
tMissionData["PmcCon033"] = {
    sStarter        = "PmcBoss",
    nLevels         = 3,
    sModuleName     = "PmcCon033",
    tMilestones     = { ... },  -- 1 key
    sFactionId      = "Pmc",
    bContract       = true,
    tStartLocations = { ... },  -- 2 keys
    bRepeatable     = true
}
```

### _tRewards entry

```lua
_tRewards["PmcCon033"] = {
    nWagerMin  = 10000,
    nWagerMax  = 100000,
    sFactionId = "Pmc",
    nWager     = 10000,
    sMissionId = "PmcCon033"
}
```

### Successful loading sequence (observed via Debug.Printf)

```
STATE_WAITFORGAME enter (refcount=1)
... briefing plays ...
=-= PmcCon033 <reward_value>                   ← _tRewards lookup succeeds
STATE_WAITFORSTREAMING enter (refcount=1)       ← first streaming (PMC unload)
nPendingOps: 4→3→2→1→0
_TeleportHero
_TeleportComplete: bStreamingComplete=true
STATE_WAITFORSTREAMING exit (refcount=0)        ← first streaming completes
Starter PmcBoss removing briefing PmcCon033
STATE_WAITFORSTREAMING enter (refcount=1)       ← second streaming (mission load)
Dynamically imported module pmccon033
... layer loads: refcount 1→2→3→4→5 ...
... layer completions: refcount 5→...→0 ...
STATE_WAITFORSTREAMING exit (refcount=0)        ← second streaming completes
... gameplay begins ...
```

---

## 4. The Streaming Refcount Problem

The native C++ streaming system manages a **refcount** separate from
any Lua-side state. This refcount gates the `STATE_WAITFORSTREAMING` exit.

### Refcount lifecycle

```
MrxState.Enter(STATE_WAITFORSTREAMING)
  → native refcount initialized to 1

Each Sys.LoadLayer() call (Lua → native):
  → native refcount += 1

Each layer load completion (native callback):
  → native refcount -= 1

Initial "entry" refcount decremented when ???:
  → native refcount -= 1  (the "base" decrement)

When native refcount == 0:
  → STATE_WAITFORSTREAMING can exit
```

### Why DLC hangs

1. `STATE_WAITFORSTREAMING` enters with refcount = 1
2. DLC mission module loads (`dynamic_import` succeeds)
3. The mission's `Activated()` function expects to request DLC arena layers
   (e.g. `dlc01_state_dlccon001`, `dlc01_terrain`, `dlc01_base`)
4. Those layers don't exist in the PC WAD — no `Sys.LoadLayer()` calls fire
5. No layer load → no completions → refcount stays at 1
6. `STATE_WAITFORSTREAMING` never exits

### Lua-side gating functions

Two Lua functions check whether the streaming state can exit:

- **`_StateComplete()`** — checks a Lua-side flag or native binding
- **`_AttemptGlobalExit()`** — attempts to transition the global state machine

Both ultimately read from the native refcount. Calling them from injected
Lua does not help because the refcount is managed in C++ and the Lua wrappers
are read-only checks:

```
_StateComplete()       → reads native refcount, returns false if > 0
_AttemptGlobalExit()   → calls _StateComplete() internally, no-ops if false
```

Patching Lua-side variables (`_bStateComplete`, `nStreamRefCount`, etc.) has
no effect because the native side maintains its own counter independently.

---

## 5. Key Addresses (Cracked EXE, 53,482,288 bytes)

All virtual addresses are specific to the cracked retail EXE. LTCG calling
conventions apply to the raw Lua C API functions.

### Lua C API

| Function | VA | Calling Convention |
|----------|----|--------------------|
| `luaL_loadbuffer` | `0x00860240` | EAX=name, EDX=L, stack: buff, sz; caller cleans (ADD ESP,8); returns EAX=status |
| `lua_pcall` | `0x0085DF50` | EAX=L, ECX=errfunc, EDI=nresults, stack: nargs; caller cleans (ADD ESP,4); returns EAX=status |
| `luaB_loadstring` | `0x00860FC0` | Standard cdecl `lua_CFunction` |
| `luaB_pcall` | `0x008615F0` | Standard cdecl `lua_CFunction` |
| `luaB_setfenv` (db_setfenv) | `0x008607E0` | Standard cdecl `lua_CFunction` |

### Stubs and Pointers

| Symbol | VA | Notes |
|--------|----|-------|
| Print stub | `0x006D5640` | `33 C0 C3` (xor eax,eax; ret) — shared by 60+ functions including `print`, `Debug.Printf` |
| Debug.Printf func ptr | `0x00B9882C` | luaL_Reg `.func` slot in `.rdata`; patched by ASI to redirect to `Hook_LogPrintf` |
| Debug table base | `0x00B98828` | Start of Debug luaL_Reg array |
| Base print func ptr | `0x00B9251C` | luaopen_base "print" entry |

### Crash Sites

| Address | Trigger | Description |
|---------|---------|-------------|
| `0x005AE372` | Script command dispatch | NULL dereference — hit when executing Lua on a thread whose script cmd table is uninitialized. Requires `CRASH_PATCH` code-cave JMP to survive |
| `0x0059C82A` | `__newindex` on `_G` during `dynamic_import` | Triggered when pcall-wrapping native functions or setting metatables on the global table. Forensic tracer must avoid instrumenting native C functions |

### Previously Misidentified (kept for cross-reference)

| Label | VA | Actual Function |
|-------|----|-----------------|
| "luaL_loadbuffer" (wrong) | `0x0085F050` | `luaL_typerror` |
| "lua_pcall" (wrong) | `0x00868AD0` | `luaD_pcall` (internal) |

### Section Layout

| Section | Start VA | Size |
|---------|----------|------|
| `.text` | `0x00401000` | `0x00703000` |
| `.rdata` | `0x00B05000` | `0x000F1000` |

---

## 6. DLC Bootstrap

The ASI (`dlc_enable.asi`) hooks into the game's Lua environment to load DLC
content that was ported from Xbox 360 via `vz-patch.wad`.

### Injection sequence

```
1. DllMain → log init, EXE size verification
2. Hook IsOnlineConnected() → returns true (bypasses EA Online check)
3. Hook HasPlayerUnlockedCode() → returns true (bypasses DLC entitlement check)
4. Detect "Loading vz level with vz masterscript" in Debug.Printf output
5. Capture lua_State* from the calling thread
6. Execute: import("dlc01")
   → dlc01 master script runs
     → import("dlccon001")  (Merc Blitz)
     → import("dlccon002")  (Arms Race)
     → import("dlccon003")  (Urban Rampage)
     → import("dlccon004")  (Death Race)
7. DLC contracts register in tMissionData
8. DLC missions appear in PDA contract list
```

### What works

- DLC module loads successfully via `dynamic_import`
- Contract entries registered in `tMissionData` with correct metadata
- Briefing cinematic plays (starter NPC interaction works)
- Mission can be accepted through the UI
- Player is teleported to the mission start location
- First `STATE_WAITFORSTREAMING` (PMC interior unload) completes normally

### Where it breaks

- Second `STATE_WAITFORSTREAMING` hangs (see §4)
- `_tRewards` has no DLC entry → `"NOT A WAGER!"` (non-fatal)
- `_tMyFlowData` has no DLC entry → flow state tracking may be incomplete
- DLC arena layers don't exist in the PC WAD → no streaming ops to complete

---

## 7. What Needs to Be Fixed

The fundamental problem: the native streaming refcount starts at 1 when
`STATE_WAITFORSTREAMING` enters, and nothing ever decrements it because the
DLC mission requests no layer loads (the layers don't exist on PC).

### Possible approaches

#### (a) Provide empty/dummy layers

Register stub layer data that the streaming system can "load" and immediately
complete, triggering the native callbacks that decrement the refcount.

- **Pro:** works within the existing state machine; no native code patches
- **Con:** requires understanding the native layer registration format;
  the stub layers must be valid enough for the streaming system to accept
  and complete them without crashing

#### (b) Find and call the native refcount decrement function

Locate the C++ function that decrements the streaming refcount (called when
a layer load completes) and call it directly from the ASI when a DLC mission
is detected.

- **Pro:** surgical fix; doesn't require understanding layer format
- **Con:** requires finding the function VA and its calling convention;
  must be called at exactly the right time (after `STATE_WAITFORSTREAMING`
  enters but before the game assumes layers are loaded)

#### (c) Intercept STATE_WAITFORSTREAMING for DLC missions

Detect when a DLC mission enters the second streaming state and skip it
entirely by patching the state machine transition.

- **Pro:** avoids the refcount problem completely
- **Con:** may skip necessary initialization that happens during the
  streaming state; DLC mission may lack expected world state

#### (d) Register DLC in all missing tables

Populate `_tRewards`, `_tMyFlowData`, `tFlowData`, and `tRewardData` with
DLC entries so the full mission code path executes, including whatever
layer management the flow system is supposed to trigger.

- **Pro:** most correct solution; DLC missions behave like base-game missions
- **Con:** requires reverse-engineering the exact values for each table;
  DLC arena layers still don't exist, so even a fully registered mission
  may still request non-existent layers

### Most likely path forward

A combination of **(d)** and **(a)** or **(b)**: register DLC missions in
all required tables to ensure the Lua code path runs correctly, then either
provide stub layers or patch the native refcount for the DLC arena layers
that cannot exist on PC.

---

## 8. Forensic Tracing Notes

The forensic tracer (`DLC_ENABLE_FORENSIC_TRACE=1`) instruments the Lua
environment to log mission-relevant function calls during the loading
sequence. It was built to diagnose exactly which functions run (and which
don't) during DLC mission acceptance vs. base-game missions.

### Architecture

The tracer injects a Lua chunk that:

1. Wraps the global `import()` function with arg/return logging
2. Scans `_MODULES` for tables matching mission/streaming/state keywords
3. Wraps matching functions with `pcall`-based proxies that log entry and exit
4. Optionally installs `__newindex` watchers on key tables

Output format:
```
[TRACE] <tick_ms> <module>.<function>(<args>)
[TRACE] <tick_ms> <module>.<function> -> <return_values>
[TRACE:W] <tick_ms> <table>.<key> = <value>
```

### Critical safety constraints

| Technique | Safe? | Notes |
|-----------|-------|-------|
| Wrapping `import()` (pure Lua) | **YES** | pcall wrapper works correctly |
| Wrapping other pure-Lua module functions | **YES** | Standard Lua function wrapping |
| Wrapping native C functions (`dynamic_import`, `Sys.*`) | **NO** | Crashes at `0x0059C82A` — native functions cannot be pcall-wrapped |
| Setting `__newindex` on `_G` | **NO** | `dynamic_import` writes to `_G`; metamethod triggers crash at `0x0059C82A` |
| Setting `__newindex` on module tables | **RISKY** | Works for some tables; crashes if native code writes to them |

### Installation timing

The forensic tracer must install at a specific point in the boot sequence:

1. **Too early** (before VZ masterscript): `_MODULES` is empty, `Sys` table
   doesn't exist, mission infrastructure isn't initialized
2. **Correct window:** after `"Loading vz level with vz masterscript"` is
   logged — all game modules are populated, `Sys` table exists, mission
   infrastructure is ready
3. **Too late** (after mission acceptance): misses the critical loading
   sequence

Mission table scans (deep discovery of `tMissionData`, `_tRewards`, etc.)
must run **after full game init** — they are triggered by streaming hang
detection rather than at tracer install time, because the save-data tables
are populated lazily during gameplay.

### Build and usage

```bash
# Build with forensic tracer enabled
make -C tools/dlc_enable_asi mingw EXTRA_CFLAGS="-DDLC_ENABLE_FORENSIC_TRACE=1"

# Or via top-level Makefile
make dlc-asi-native EXTRA_CFLAGS="-DDLC_ENABLE_FORENSIC_TRACE=1"
```

The `CRASH_PATCH` at `0x005AE372` is recommended when using the forensic
tracer, as some code paths may hit the script command NULL dereference:

```bash
make dlc-asi-native EXTRA_CFLAGS="-DDLC_ENABLE_FORENSIC_TRACE=1 -DDLC_ENABLE_CRASH_PATCH=1"
```

Output is written to `dlc_enable_crash.log` alongside the game EXE.

---

## 9. Havok Animation Byte-Swap Fix (vz-patch.wad)

> **Date:** 2026-05-24
> **Status:** Resolved — base game UCFX substitution approach working

### Problem

The DLC port (`tools/dlc_port.py`) converts Xbox 360 big-endian (BE) blocks
to PC little-endian (LE) for inclusion in `vz-patch.wad`. Most UCFX chunk
types convert correctly with simple u32/u16 array swaps, but **Havok 5.5
animation packfiles** embedded in `data` descriptor bodies require field-level
conversion that is impossible without full `hkClass` type metadata.

### Havok packfile structure (within a UCFX `data` body)

```
[0,8)       Magic: 57 E0 E0 57 10 C0 C0 10 (palindromic)
[8,16)      user_tag(u32), file_version(u32)
[16,20)     pointer_size(u8), is_little_endian(u8), reuse_pad(u8), empty_base(u8)
[20,ver)    num_sections(u32), content_section_idx(u32), content_section_off(u32)
[ver,sec)   Version string "Havok-5.5.0-r1" + 0xFF padding
[sec,+144)  3 × 48-byte section headers: 20-byte ASCII name + 7 × u32 fields
            Sections: __classnames__, __types__, __data__
```

The `__data__` section contains serialized Havok objects with mixed field
sizes (u8, u16, u32, f32, pointers) whose layout is determined by hkClass
definitions compiled into the game executable.

### Failed approaches

| Approach | Result |
|----------|--------|
| **Passthrough** (leave all data in BE, is_le=0) | Crash at `0x956d58`: runtime reads `num_sections` as native LE → huge loop count (50M iterations) → access violation |
| **Header LE + u32 blanket swap of `__data__`** | Crash at `0x9ff19f`: animation decompressor reads u16/u8 packed bitstream fields that were corrupted by 4-byte grouping swap |
| **Header LE + empty `__data__` (zeroed section)** | Masks the problem — animations don't load at all |

### Root cause

The PC game's Havok runtime does **NOT** perform endian conversion during
deserialization. It reads all fields as native LE. The Xbox 360 stores Havok
data in BE. Without the complete hkClass type definitions for every serialized
class (which are compiled into the game binary, not stored in the packfile),
field-level BE→LE conversion is impossible.

### Solution: base game UCFX substitution

The same animation assets (by hash) exist in both the DLC and the base game's
`vz.wad`. The base game's copies are already correct LE. The fix:

1. Build a hash→block_index lookup from `vz.wad`'s ASET table (30,006 entries)
2. During block conversion, parse each DLC block's UCFX entry table
3. For entries with `type_hash == 0x18166555` (animation) whose hash exists in
   the base game, extract the correct LE UCFX container from `vz.wad`
4. Substitute it directly (bypassing `_convert_havok_be_to_le()`) via the
   `havok_overrides` parameter to `byteswap_ucfx_block()`

The base game's UCFX containers are **byte-for-byte identical in size** to the
DLC entries (verified: zero mismatches across all tested blocks), so no
padding or truncation is needed.

### Implementation

**`tools/ucfx_be_to_le.py`:**
- `byteswap_ucfx_block()` accepts optional `havok_overrides: dict[int, bytes]`
  mapping entry indices to pre-converted LE UCFX containers (without CSUM)
- Override entries bypass `_convert_container()` entirely; CSUM is recomputed
- Non-override Havok entries still use `_convert_havok_be_to_le()` (structural
  header conversion + u32 swap of `__data__` as fallback)

**`tools/dlc_port.py`:**
- `_build_base_aset_index(source_wad)` → hash→block_index for all entries
- `_extract_base_entry_ucfx(source_wad, block_index, target_hash)` →
  decompresses the base game block, finds the entry by hash, returns UCFX bytes
- Block cache (`base_block_cache`) avoids redundant decompression of large
  blocks (some are 10-27 MB decompressed)
- Per-block override dict built during conversion loop before calling
  `byteswap_ucfx_block()`

### Coverage

Typical full build: **~1,500+ animation entries** across ~90 blocks receive
correct LE data from the base game. DLC-unique animations (if any exist)
still fall through to the u32 fallback, which may produce incorrect animation
playback but won't crash during the header/section parsing stage.

### Key constants

```python
_ANIMATION_TYPE_HASH = 0x18166555   # pandemic_hash_m2("animation")
_HAVOK_MAGIC = b"\x57\xe0\xe0\x57\x10\xc0\xc0\x10"
_HAVOK_VER = b"Havok-5.5.0-r1"
_SECTION_HDR_SIZE = 48              # 20 name + 7×4 fields
```

### Crash addresses (resolved)

| Address | Instruction | Root cause | Status |
|---------|-------------|------------|--------|
| `0x956d58` | `mov edx, [ecx+0x08]` | BE `num_sections` (3) read as LE → 0x03000000; loop overflows ECX | **Fixed** (header correctly LE) |
| `0x9ff19f` | `movzx cx, [edx]` | u32-swapped `__data__` corrupts packed bitstream; computed offset → invalid address | **Fixed** (base game data substituted) |
| `0x59d45f` | `xor cl, [eax+0x44]` | DEPS chunk u8 count included in u32 swap → count becomes 198 instead of 4; engine reads past DEPS into Lua bytecode, loads NULL entries | **Fixed** (DEPS handler preserves count prefix) |

---

## 10. DEPS Chunk Byte-Swap Fix (Script Dependencies)

> **Date:** 2026-05-24
> **Status:** Resolved — `_convert_deps_body()` preserves u8 count prefix

### Problem

Script-type UCFX entries (type_hash `0x42498680`) contain a `DEPS` sub-chunk
listing dependency hashes in the format: `[u8 count] [u32 hash × count]`.

The byte-swapper's fallback (`_convert_u32_array`) treated the entire DEPS
body as a flat u32 array, including the 1-byte count prefix. This produced a
corrupt first u32 group that mixed the count byte with the first hash byte.

### Example (entry `0x701B5FEC` — `mrxguihudrada` GUI script)

```
Xbox BE input:  04 | 0D 87 C6 5D | C9 70 6D 16 | 73 96 2E B2 | E4 42 FD D3
                 ^count  ^hash0        ^hash1        ^hash2        ^hash3

OLD (u32 swap from byte 0 — WRONG):
  C6 87 0D 04 | 6D 70 C9 5D | 2E 96 73 16 | FD 42 E4 B2 | D3
  count=0xC6=198 ← CORRUPTED

NEW (preserve u8 prefix, swap from byte 1):
  04 | 5D C6 87 0D | 16 6D 70 C9 | B2 2E 96 73 | D3 FD 42 E4
  count=4 ← CORRECT (matches base game)
```

### Crash mechanism

1. Engine loads `resident` block (933 entries, 36 scripts)
2. Deserializes entry `0x701B5FEC` — reads DEPS count as 198 (0xC6)
3. Reads 198 × u32 "dependency hashes" from byte 1 onward
4. After 4 actual hashes (16 bytes), reads into BINN (Lua bytecode)
5. Lua instructions are interpreted as asset hashes → factory lookup
6. Most return NULL (no asset with hash = Lua instruction value)
7. Code at `0x59d45f` accesses `[eax+0x44]` without NULL check → crash

### Fix

Added `_convert_deps_body()` in `ucfx_be_to_le.py`:
- Preserves byte 0 (u8 count) verbatim
- Byte-swaps bytes 1..end as u32 values via `_convert_u32_array()`

### Scope

Every script entry in the DLC has a DEPS chunk. The `resident` block alone has
36 scripts affected. The fix applies to all UCFX containers in the patch WAD
that contain `DEPS` sub-chunks.

---

## 11. BINN Script-Reference Byte-Swap Fix (Registry Crash)

### Symptom

Access violation at `0x67d4c0` (`mov [eax+ebx*4], edx`) during script registry
initialization. The engine iterates 3075 script slots building a hash table.
Entry 134 has a completely zeroed data block (0x3800 bytes) — the script was
never loaded because its reference metadata was corrupted.

### Root cause

`resident` block BINN chunks for script-type entries (`type_hash 0x42498680`)
do **not** contain Lua bytecode. They contain a small reference record:

```
Offset  Size  Field
0x00    u32   bytecode_size (size of actual Lua in scripts_vz block)
0x04    u32   zero
0x08    u32   zero
0x0C    u8    marker (always 0x05)
0x0D    u8    metadata byte
0x0E    u8    zero
0x0F    var   script name (ASCII, no null terminator)
```

Total size = 15 + strlen(name). All 126 BINN entries in the patch WAD use this
format (sizes 19–150 bytes).

When `_convert_lua_be_to_le()` scanned for the `\x1bLua` signature and found
none, it fell back to `_convert_u32_array(be)` which treated the entire body as
big-endian u32 values. This corrupted the name string at offset 0x0F by
byte-swapping ASCII characters as part of 4-byte groups.

With a corrupted name, the engine could not resolve the reference to the actual
Lua bytecode in the `scripts_vz` block. The script slot remained uninitialized
(all zeros), and the hash-table builder crashed on the NULL pointer.

### Execution trace

```
0x67d4ba:  mov eax, [edi]          ; EAX = [0x1FE475A0] = 0 (empty slot)
0x67d4c0:  mov [eax+ebx*4], edx    ; write to NULL → access violation
```

### Failed approach

The original `_convert_u32_array` fallback was designed for unknown chunk types
but is catastrophically wrong for mixed-format data (u32 header + byte fields +
ASCII strings).

### Fix

Added `_convert_binn_script_ref()` in `ucfx_be_to_le.py`:
- Only byte-swaps the first u32 (bytecode_size field)
- Preserves all remaining bytes verbatim (zeros, flags, name string)

Modified `_convert_lua_be_to_le()` to call `_convert_binn_script_ref()` instead
of `_convert_u32_array()` when no LuaQ signature is found or when Lua parsing
fails.

### Verification

```python
>>> be = bytes.fromhex('00002b93' + '00000000' * 2 + '050e006d72786775696875647261646172001500...')
>>> _convert_binn_script_ref(be)
# First u32 swapped: 0x00002B93 → 0x932B0000 (LE)
# Name 'mrxguihudrada' preserved intact at offset 15
```

### Scope

Affects all 126 script BINN entries across `resident` (block 464) and
`scripts_vz` (block 2196) in the patch WAD. Every script reference entry was
corrupted by the previous u32 fallback.

---

## Related Documents

- [`dlc_arena_loading_analysis.md`](dlc_arena_loading_analysis.md) — DLC arena
  architecture mismatch (standalone maps vs. Venezuela world)
- [`dlc_bootstrap_implementation.md`](dlc_bootstrap_implementation.md) — Bootstrap
  injection history (superseded chain-load approach)
- [`dlc_pc_activation_checklist.md`](dlc_pc_activation_checklist.md) — Gate checklist
  for DLC activation on PC
- [`vanilla_mission_lifecycle_analysis.md`](vanilla_mission_lifecycle_analysis.md) —
  Full mission system architecture from Lua bytecode analysis
- [`dlc_loader_cross_reference.md`](dlc_loader_cross_reference.md) — Cross-reference
  of DLC loader components
- [`dlc_pc_port_status.md`](dlc_pc_port_status.md) — Overall DLC port status tracker
