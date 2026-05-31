# Spatial Hash Table Crash Analysis: Asset Registration Overflow

**Date**: 2026-05-28 (updated 2026-05-30)  
**Primary crash sites**: `0x248BB7C` (read), `0x248BBE2` (write) — same function `0x248BB60`  
**Status**: OPEN — rebuild after **flgs** + **compact Transform** + **compact numeric ECS strides** (Rust 2026-05-30); re-run `dlc-port` + deploy

## Log correlation (`dlc_enable_crash.log`, 2026-05-30)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`):

| Field | Value |
|-------|-------|
| Last Lua line | `[lua] Loading vz level with vz masterscript` |
| FATAL (earlier) | `exception 0xC0000005 at 0x0248BBE2 fault=0x03CEA014` |
| FATAL (2026-05-30 rebuild) | `exception 0xC0000005 at 0x0248BB7C fault=0x03CEA074` |
| Timing | ~4.3 s after VZ masterscript line (watchdog still alive) |

This matches the spatial-hash insert at `0x248BB60` during **main-thread WAD registration**
(call stack in §Call Stack), not the audio mixer crash (`0x83664E`, separate thread — see
`docs/audio_crash_analysis.md`).

### Instruction map (verified in x32dbg, 2026-05-30)

| EIP | Instruction | Access | Notes |
|-----|-------------|--------|-------|
| `0x248BB6D` | `mov esi, ecx` | — | **ECX = cell index** (bucket selector) |
| `0x248BB6F` | `imul esi, esi, 0x1F0` | — | `esi = cell_index × 0x1F0` |
| `0x248BB75` | `add esi, ebp` | — | `ebp = [0x01175DD8]` table base |
| `0x248BB7C` | `cmp word ptr [esi+0x1E4], dx` | **READ** | `dx = 0x20` (bucket capacity); **new crash here** |
| `0x248BBE2` | `mov dword ptr [esi+ecx*4], eax` | **WRITE** | **Prior crash**; `ecx` = slot index within bucket |

**Fault address identity:** `fault = esi + 0x1E4` on the `0x248BB7C` read. Example from log:
`fault=0x03CEA074` ⇒ `esi = 0x03CE9E90`. That `esi` is **not** `table_base + cell×0x1F0` in the
heap block; it is produced when **ECX (cell index) is garbage**, e.g. `ECX = 0x038E2840`:

```
esi = (0x2060A290 + (0x038E2840 * 0x1F0)) & 0xFFFFFFFF = 0x03CE9E90
fault = esi + 0x1E4 = 0x03CEA074
```

Same root as the older `0x248BBE2` / `nvgpucomp32.dll` write: **overflowing cell index** from corrupt
entity XYZ fed to `0x516B10`, not a different bug class.

**Production byte-swap:** `make dlc-port` uses **Rust** `ucfx_byteswap`, not Python `ucfx_be_to_le.py`.
Until 2026-05-30, Rust treated ECS `flgs` as a flat `u32` sweep (corrupting 42-byte vz_state placement
records); Python had a typed `_convert_vz_state_flgs` but was not on the port path. Rebuild required.

## Post–flgs-fix crash still reproduces (2026-05-30)

If retail PC + `dlc_enable.asi` still dies at `0x248BBE2` after a claimed rebuild, work through
**deployment verification** first, then the remaining corruption sources below.

### Did the fix ship? (checklist)

| Check | How |
|-------|-----|
| Rust binary rebuilt | `make build-ucfx-byteswap` — timestamp on `tools/wad_simulator/target/release/ucfx_byteswap.exe` **newer** than `convert.rs` |
| Patch re-ported | `make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` — **not** redeploying an old `vz-patch.wad` |
| Deployed WAD is the new build | Compare SHA-256 of `output/data/vz-patch.wad` on build host vs game `data/vz-patch.wad` |
| No stale trim | If you use `make trim-patch-wad`, re-run **after** `dlc-port` |
| Port log clean | `dlc_port` must report **0 skipped** blocks; any `byte-swap failed` = block missing from patch |
| `--permissive` unused | Flag is wired in CLI but **not** passed to `byteswap_block_rust` (harmless if set) |
| Simulator gate | `wad_simulator --wad output/data/vz-patch.wad --base-wad game-files/pc-game-vz.wad` → `position_violations: 0` |

`dlc_port.py` always calls `byteswap_block_rust(decompressed)` (no Python `ucfx_be_to_le` fallback).
`base_block_cache` only caches **decompressed Xbox slices** for base-game overrides, not LE output.

### Confirmed on port path (Rust `ucfx_byteswap`)

- **ECS** containers (`type_hash` `0xE6B81A54` layer, `0x5647C35D` world_entity_data): `ChunkTag::Flgs` → `convert_vz_state_flgs_inplace` (42-byte records, mixed u32/u16).
- **ECS** `Transform` COMP `data`: typed f32 swap when component name resolves (ASCII or compact hash `0x753EB623`).
- **Non-ECS** containers: `Flgs` still uses blind `swap_u32_array` — only matters if a non-layer entry carries `flgs` placement records (unusual).

### Second bug fixed 2026-05-30: compact Transform without `schm`

Many DLC / vz_state COMP groups use **16-byte compact `info`** (hash only, no ASCII name, **no `schm`**).
Python (`ucfx_be_to_le._ECS_COMP_DEFAULT_STRIDE`) still runs `_convert_transform_records`.
Rust `convert_comp_data_inplace` previously hit `schema == None` → **full-body `swap_u32_array`**, corrupting
XYZ at +4/+8/+12 — same crash signature as bad `flgs`.

**Fix:** treat `comp_name == "Transform"` with stride 42 even when `schm` is absent (`convert.rs`).

### Third bug fixed 2026-05-30: compact non-Transform ECS components

Python `_ECS_COMP_DEFAULT_STRIDE` + `_convert_numeric_records` apply to **Road** (40), **RoadIntersection** (124),
**AiBehavior** (48), etc. Rust still used **whole-body `swap_u32_array`** for any compact component that was not
`Transform`, misaligning record boundaries and corrupting embedded floats.

**Fix:** `compact_default_stride()` + `swap_numeric_records_inplace()` in `convert.rs` (mirror Python).

Non-ECS `Flgs` in `convert_generic_bodies` remains a blind `swap_u32_array` — only affects non-layer UCFX
containers; DLC `dlc01_state_*` uses the ECS path (`convert_vz_state_flgs_inplace`).

### `wad_simulator` on current patch (SHA `1E6CA26C…`, 2197 blocks)

| Metric | Value |
|--------|-------|
| `position_violations` | **22** (all in **block 0** only) |
| Block 0 path | `blocks\dlc01\dlc01_terrain_P000_Q3.block` |
| Pattern | Transform grid Y = ±800/±1200/±1600, X ≈ 0 — **arena terrain lattice**, not LE swap corruption |
| `flgs` placement violations | **0** |
| Transform NaN/Inf | **0** |

The 22 terrain hits are **simulator false positives** (`WORLD_Y_MIN = -500`; arena grid uses Y below that).
They are unlikely to be the `ECX = 0x038E2840` path unless the engine registers those lattice points as
world entities at load time (needs confirmation).

### Remaining placement float sources (ranked)

| Priority | Source | Risk | Notes |
|----------|--------|------|-------|
| P0 | Compact **Transform** COMP `data` (no `schm`) | Was **High** | Fixed in Rust 2026-05-30 |
| P0 | Compact **Road / numeric ECS** (no `schm`) | **High** | Fixed in Rust 2026-05-30 (`swap_numeric_records_inplace`) |
| P0 | **flgs** in ECS layer blocks (`dlc01_state_*`) | Was **High** | Fixed in ECS path; simulator shows 0 flgs violations |
| P1 | **BNDS** AABB floats on meshes | Medium | Bad bounds → wrong spatial queries; `wad_simulator` checks envelope |
| P1 | **STRM** positions (if ever registered) | Lower for hash @ `0x516B10` | Engine path reads **entity** XYZ (+4/+8/+12), not mesh verts |
| P2 | **world_entity_data** (`0x5647C35D`) | Medium | Uses ECS convert path; simulator uses `consume_structural` only (no placement scan) |
| P2 | Base-game **override** entries | Low | Whole UCFX replaced from retail PC LE — correct by definition |
| P3 | **CHDR-internal** absolute offsets | Low for port | Byteswap walks **UCFX descriptor** table (`data_area_off + row_u0`), same as Python; CHDR child table in docs is a separate view |

DLC blocks often have **both** `flgs` placements and **Transform** COMP data in the same `dlc01_state_*` layer block.

### Validation gaps

| Tool | Coverage | Misses |
|------|----------|--------|
| `wad_simulator` | All **resolved ASET** assets (base+patch overlay), `consume_layer` on type_id 9 | `world_entity_data` (type_id 8) not placement-scanned; won't flag compact Transform until consumed as layer |
| `verify_ucfx_endian.py` | Patch WAD scan | **`flgs` probe uses wrong offsets** (4/18/22 = Transform layout, not flgs +0x12/+0x16/+0x1A) — false negatives |
| `audit_dlc_conversion.py` | Entries with **same (hash, type_hash) in base vz.wad** | All DLC-unique ecs_node / state blocks |
| `validate_ecs_dlc.py` | DLC-unique ecs_node list | Alignment only; no world-bounds on floats |
| `ucfx_byteswap --validate-only` | CSUM, descriptors, BNDS/STRM/IBUF | Not placement-specific |

### Bisect strategy (minimal patch)

1. **Simulator on full patch:**  
   `wad_simulator --wad output/data/vz-patch.wad --base-wad <retail-vz.wad> --strict`  
   Note first `position NaN/Inf` / `out of world bounds` label (includes block path via ASET).

2. **Half WAD:** `make dlc-port-assets-only` (2196 blocks, no bootstrap) or `trim_patch_wad.py --exclude-indices` / `--auto` to drop half of `dlc01_state_*` paths; redeploy; binary-search.

3. **Single block:**  
   `extract_single_block.py --wad <x360-doh-or-patch> --path "dlc01_state_dlccon003"`  
   `--decode ".venv/Scripts/python.exe tools/placement_extractor.py …"`  
   Compare BE Xbox vs LE patch floats at Transform +0x04 and flgs +0x12.

4. **High-risk path patterns:** `dlc01_state_*`, `dlc01_state_*_spawns`, `dlc01_base`, `dlc01_commonlocations`, any `*layers_static*` in DLC (rare).

5. **x32dbg** (MCP `user-x32dbg` when attached):  
   - Conditional: `bp 0x248BB6D` with condition `ecx > 0x4000` (fires before bad bucket address).  
   - On hit: **ECX** = garbage cell index; **EBP** = `[0x01175DD8]`; after `add esi, ebp`, check `esi+0x1E4` vs fault.  
   - Caller **`0x516EF6`**: read entity pointer from stack / **EBX**; floats at **`[entity+4]` `[entity+8]` `[entity+0xC]`** (Transform layout).  
   - Frame 2 return **`0x0063DA1F`** = WAD block loader.  
   - Healthy stop (index `0x26A`): entity floats ≈ `(-0.21, 831.35, 0)` — valid Maracaibo-range XYZ.  
   - Crash stop (`ECX = 0x038E2840`): `esi = 0x03CE9E90`, fault `0x03CEA074` on **read** at `0x248BB7C`.

### Recommended bisect blocks (patch WAD)

| Step | Action |
|------|--------|
| 1 | `trim_patch_wad.py --exclude-indices 0` — drop **`dlc01_terrain_P000_Q3`** only; redeploy |
| 2 | If still crashes: `--exclude-indices 4,12,15,16,17` (all **`dlc01_state_*`**) |
| 3 | Half-split remaining DLC blocks with `--auto` or manual index ranges |
| 4 | `make dlc-port-assets-only` (2196 blocks, no bootstrap) to separate loader hook issues |

`dlc01_state` indices in current patch: **4** `…_spawns`, **12** `…_dlccon003`, **15** pathfinding, **16** missionhub, **17** atmofx.

### Action plan (other machine)

1. `make build-ucfx-byteswap && make dlc-port …`  
2. `wad_simulator --wad output/data/vz-patch.wad --base-wad …` — must show **0** position violations  
3. `make verify-dlc-endian` (know flgs offsets in script are wrong; trust simulator for placements)  
4. Copy `vz-patch.wad` + rebuilt `dlc_enable.asi`; confirm SHA-256  
5. Fresh x32dbg session: conditional bp at hash insert; capture EDX entity floats + return addresses  
6. If clean simulator but still crashes → suspect **runtime** (wrong entity pointer, not swap) or **non-placement** cell index input  
7. Bisect with `dlc-port-assets-only` or trimmed WAD if simulator is clean but game still fails  
8. File-level proof: `extract_single_block` on flagged `dlc01_state_*` block  

## Register State at Crash

| Register | Value | Meaning |
|----------|-------|---------|
| EIP | `0x0248BBE2` | Asset registry hash table insert function |
| ESI | `0x6F319DA0` | "Bucket" pointer — actually inside `nvgpucomp32.dll` (.rdata, PAGE_READONLY) |
| ECX | `0x00002E70` | "Count" read from garbage at `[ESI+0x1E4]` — bogus (should be 0–32) |
| EAX | `0x0000356B` | Value being inserted (entity/asset index = 13,675) |
| EBP | `0x2060A290` | Hash table base pointer `[0x01175DD8]` |
| EBX | `0x00003500` | (saved register) |
| EDX | `0x20E54074` | Pointer to entity data being registered |
| ESP | `0x03C0F534` | Stack pointer |

## Root Cause: Spatial Cell Index Overflow

The crash occurs in a **spatial hash table** used during WAD asset registration. An entity's
world-position coordinates are converted to a grid cell index via function `0x516B10`. That
index is then used to access a bucket in the hash table at `0x248BB60`. When the index is
too large, the computed bucket address (`base + index * 0x1F0`) overflows past the allocated
table memory and lands in unrelated address space.

### Why PAGE_READONLY didn't crash on the READ

The function reads `[ESI+0x1E4]` (at `0x6F319F84`) successfully — getting garbage value
`0x2E70` — because `nvgpucomp32.dll` data sections are readable. It then tries to WRITE
at `[ESI + 0x2E70*4]` = `[0x6F325760]` which is beyond the mapped region → ACCESS VIOLATION.

## Hash Table Structure (0x248BB60)

```
Function: 0x248BB60 (reached via thunk at 0x517DC0 → jmp [0x245A0F8])
Base pointer: [0x01175DD8] = 0x2060A290
Heap region: 0x18040000 — 0x3E266000 (610 MB allocation)
Bucket stride: 0x1F0 (496 bytes)
Max entries per bucket: 32 (capacity check: cmp [esi+0x1E4], 0x20)
Overflow chain: [bucket+0x1E8] → next bucket (heap-allocated)
```

### Bucket Layout (inferred)

```
+0x000: entry[0]  — 4 bytes × 32 slots? (data values like block/entity index)
+0x0A0: entry2[0] — 4 bytes × 32 slots? (secondary data)
+0x1E4: count     — u16, number of entries in this bucket (0–32)
+0x1E8: chain_ptr — pointer to next overflow bucket (or NULL)
```

### Insert Logic (pseudocode)

```c
void SpatialHashInsert(int cell_index, int value, int value2) {
    int* table_base = *((int*)0x01175DD8);
    char* bucket = table_base + cell_index * 0x1F0;  // NO BOUNDS CHECK!
    
    while (*(short*)(bucket + 0x1E4) >= 32) {   // bucket full?
        char* next = *(char**)(bucket + 0x1E8); // follow chain
        if (!next) { next = allocate_bucket(); *(bucket + 0x1E8) = next; }
        bucket = next;
    }
    
    short count = *(short*)(bucket + 0x1E4);
    bucket[count * 4] = value;           // ← CRASH (write to bad address)
    bucket[0xA0 + count * 4] = value2;
    *(short*)(bucket + 0x1E4) = count + 1;
}
```

## Caller Chain: Spatial Cell Computation

```
0x516C00  — Entry: computes LOD/distance value, clamps to max 0x3FFF
0x516C76  —   cmp eax, 0x3FFF; jle skip; mov eax, 0x3FFF  (CLAMP)
0x516C98  —   call 0x516B10  (spatial cell computation from entity XYZ)
0x516C9D  —   mov ebp, [esp+0x18]  ← OUTPUT of 0x516B10 = cell index
0x516EEF  —   mov ecx, ebp         ← pass cell index as bucket index
0x516EF1  —   call 0x517DC0        ← hash table insert (crashes)
```

Function `0x516B10` converts entity world-position floats to a spatial grid cell index.
It reads XYZ from a float vector pointed to by its ECX/'this' parameter. If the position
floats are corrupt (NaN, Inf, or out of expected range), `cvttss2si` produces `0x80000000`
(integer indefinite) which propagates through bit-shifts and OR operations to produce a
garbage cell index like `0x0449B62F`.

### Grid Parameters (globals)

| Address | Value | Purpose |
|---------|-------|---------|
| `0x01175DD4` | `0x01` (byte) | Spatial system enable flag |
| `0x01175DD8` | `0x2060A290` | Hash table base pointer |
| `0x0179C7B6` | (s16) | Grid divisor (used in `idiv` at 0x516CBD) |
| `0x0179C7E4` | (float) | Position-to-cell scale factor |
| `0x0179C7BC` | (float) | World origin X offset |
| `0x0179C7C4` | (float) | World origin Z offset |

## Call Stack

| # | Return Addr | Context |
|---|-------------|---------|
| 0 | `0x00516EF6` | `0x516C00` — spatial registration caller |
| 1 | `0x0051812F` | Higher-level registration loop |
| 2 | `0x0063DA1F` | WAD loading / block processing |
| 3 | `0x0063D904` | WAD streaming controller |
| 4 | `0x00654E4E` | Asset loading dispatcher |
| 5 | `0x004B11D8` | Virtual call (indirect `call edx`) |
| 6 | `0x004C9C80` | Block load orchestrator |
| 7 | `0x004C0EDB` | Main loop / tick |
| 8 | `0x004C0B6F` | Game init / startup |

## Patch WAD Verification

The patch WAD's ASET table was verified clean:
- **Block count (INDX)**: 2,197
- **ASET entries**: 5,451
- **Max block index in ASET**: 2,196 (valid — within 0 to 2,196 range)
- **No hash `0xBC10BF80`** found in either base or patch ASET tables

The value `0x356B` (13,675) being registered is NOT directly from a corrupt ASET entry.
It likely represents an internal runtime object/entity slot index that the engine computed
during block loading.

## Hypothesis: Corrupt Position Floats from Byte-Swap

The most likely cause is an entity whose XYZ position floats are corrupt after byte-swapping
(entity structure **+0x04/+0x08/+0x0C** in the crash register dump — matches **Transform** layout,
not vz_state **flgs** +0x12/+0x16/+0x1A, but both swap bugs produce garbage at engine read sites).
When `cvttss2si` converts NaN/Inf/out-of-range floats to integers, x86 returns `0x80000000`
(integer indefinite). The spatial cell computation in `0x516B10` then produces a garbage
cell index that overflows the hash table.

Potential sources (see **Post–flgs-fix** section for current status):
1. **Transform COMP `data`** — 42-byte records; compact format without `schm` was blind-swept in Rust until 2026-05-30.
2. **flgs** vz_state records — blind sweep in Rust ECS path until 2026-05-30.
3. **BNDS** / mesh bounds — unlikely to match entity +4/+8/+12 unless wrong pointer.
4. **STRM** vertex data — separate code path from entity registration at `0x516B10`.

## Next Steps: Fresh Reboot with Conditional Breakpoint

The crash log does not preserve registers. On a fresh run with x32dbg:

```
bp 0x248BB6D
```

Set **condition** `ecx > 0x4000` on that breakpoint (break at `mov esi, ecx` before `imul`).

When triggered on the **bad** entity:
1. **ECX** ≈ `0x038E2840` (or similar huge index) — not the clamped `≤ 0x3FFF` path.
2. After `add esi, ebp`, **`cmp [esi+0x1E4]`** will AV at `esi+0x1E4` (`0x248BB7C`) if index is wild.
3. At **`0x516EF6`**, dump **`[entity+4..+0xC]`** as floats — expect NaN/Inf or byte-swapped garbage.
4. Map to patch block via loader stack / last-loaded path; use `extract_single_block.py` on that block.

When triggered on a **healthy** entity (e.g. `ECX = 0x26A`), floats look like normal world coords — continue.

## Relationship to Previous Crashes

This is a **different crash** from the PalSoundEngine/audio crash documented in
`docs/audio_crash_analysis.md`. That crash was caused by soundbank u8x4 byte-swap
corruption leading to a buffer overflow on the audio mixer thread. This crash is in
the main-thread asset loading path and relates to spatial data (positions/coordinates),
not audio.

Both crashes share the same root pattern: **byte-swap gaps in `ucfx_be_to_le.py`**
cause the engine to interpret corrupt data as valid, leading to downstream overflows.
