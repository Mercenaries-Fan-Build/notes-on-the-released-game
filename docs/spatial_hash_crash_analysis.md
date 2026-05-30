# Spatial Hash Table Crash Analysis: Asset Registration Overflow

**Date**: 2026-05-28 (updated 2026-05-30)  
**Crash address**: `0x248BBE2`  
**Crash instruction**: `mov dword ptr ds:[esi+ecx*4], eax` — write to read-only NVIDIA driver memory  
**Status**: OPEN — toolchain gaps narrowed; rebuild `vz-patch.wad` after `flgs`/Transform fixes

## Log correlation (`dlc_enable_crash.log`, 2026-05-30)

Retail PC + `dlc_enable.asi` (bootstrap **OFF**, `CRASH_PATCH=1`, `REG_PATCH=1`, `GUARD=1`):

| Field | Value |
|-------|-------|
| Last Lua line | `[lua] Loading vz level with vz masterscript` |
| FATAL | `exception 0xC0000005 at 0x0248BBE2 fault=0x03CEA014` |
| Timing | ~5.6 s after VZ masterscript line (watchdog still alive) |

This matches the documented spatial-hash insert at `0x248BBE2` during **main-thread WAD registration**
(call stack in §Call Stack), not the audio mixer crash (`0x83664E`, separate thread — see
`docs/audio_crash_analysis.md`). The fault address `0x03CEA014` is the bad **write target** from
`[bucket_base + cell_index×4]`; prior x32dbg sessions showed `ESI` landing in `nvgpucomp32.dll`
when `cell_index` is garbage (e.g. `0x2E70` read from beyond the hash table).

**Production byte-swap:** `make dlc-port` uses **Rust** `ucfx_byteswap`, not Python `ucfx_be_to_le.py`.
Until 2026-05-30, Rust treated ECS `flgs` as a flat `u32` sweep (corrupting 42-byte vz_state placement
records); Python had a typed `_convert_vz_state_flgs` but was not on the port path. Rebuild required.

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

The most likely cause is an entity whose XYZ position floats are corrupt after byte-swapping.
When `cvttss2si` converts NaN/Inf/out-of-range floats to integers, x86 returns `0x80000000`
(integer indefinite). The spatial cell computation in `0x516B10` then produces a garbage
cell index that overflows the hash table.

Potential sources of corrupt position data:
1. **COMP placement records** — 42-byte records with XYZ floats at known offsets.
   The `ucfx_be_to_le.py` status shows "UCFX deep swap (COMP placements)" as **Gap**.
2. **STRM vertex data** — position floats in vertex buffers (also listed as **Gap**).
3. **Other float-bearing chunks** — BNDS bounding boxes, HIER transform matrices.

## Next Steps: Fresh Reboot with Conditional Breakpoint

The crash state doesn't preserve the entity's original position data. On fresh reboot:

```
bp 0x248BB6D, ecx > 0x4000
```

This breakpoints the `mov esi, ecx` instruction (saves bucket index) with a condition
that the index exceeds the valid range (max clamped value from caller is 0x3FFF).

When triggered:
1. **ECX** = the overflowing cell index
2. **Stack** will have the caller's context with the entity float pointer
3. Trace back to identify which UCFX block/chunk contains the corrupt position floats
4. Map those bytes to the patch WAD and fix the byte-swap for that data type

## Relationship to Previous Crashes

This is a **different crash** from the PalSoundEngine/audio crash documented in
`docs/audio_crash_analysis.md`. That crash was caused by soundbank u8x4 byte-swap
corruption leading to a buffer overflow on the audio mixer thread. This crash is in
the main-thread asset loading path and relates to spatial data (positions/coordinates),
not audio.

Both crashes share the same root pattern: **byte-swap gaps in `ucfx_be_to_le.py`**
cause the engine to interpret corrupt data as valid, leading to downstream overflows.
