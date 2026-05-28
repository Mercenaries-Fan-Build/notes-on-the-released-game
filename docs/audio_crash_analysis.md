# Audio Crash Analysis: PalSoundEngine::MixSources

**Date**: 2026-05-25  
**Crash address**: `0x83664E`  
**Crash instruction**: `mov eax, [eax+0x04]` — vtable dereference on freed object  

## Register State at Crash

| Register | Value | Meaning |
|----------|-------|---------|
| EIP | `0x0083664E` | Inside `PalSoundEngine::MixSources` |
| ECX | `0x2006FBA8` | PalSoundEngine* — **DANGLING** (freed memory, all zeros) |
| EAX | `0x00000000` | vtable read from `[ECX]` — zeroed because object freed |
| ESI/EDI | `0x019C6170` | Mixer thread context object (`this`) — valid |
| EBP | `0x4CB7FF74` | Stack frame |
| ESP | `0x4CB7FF50` | Stack pointer |
| lastError | `5` (ERROR_ACCESS_DENIED) | Last Win32 error before crash |

## Root Cause: Use-After-Free on Audio Mixer Thread

The crash is a **dangling pointer dereference** on a dedicated audio mixing thread. The
PalSoundEngine object at `0x2006FBA8` was destroyed (vtable zeroed, memory freed/decommitted)
while the mixer thread was still actively running.

### Evidence

1. **`MemoryIsValidPtr(0x2006FBA8)` returns `false`** — the page has been decommitted
2. **32 bytes at `0x2006FBA8` are all zeros** — vtable and first fields wiped
3. **Global pointer `[0x01176404]` still holds `0x2006FBA8`** — not cleared on destruction
4. **Shutdown flag `[0x01175FFF]` = `0x00`** — thread was never told to stop
5. **Mixer init flags `[0x019C6694]` = `0x03`** — both init phases completed; mixer was running

## Disassembly: PalSoundEngine::MixSources (0x836610)

```asm
; Function prologue
0x836610: push ecx
0x836611: mov ecx, [0x01176404]       ; ECX = g_pPalSoundEngine (0x2006FBA8)
0x836617: push ebx
0x836618: xor ebx, ebx                ; EBX = 0
0x83661A: cmp ecx, ebx                ; null check
0x83661C: push esi
0x83661D: jz  0x836659                ; skip if NULL — but ptr is non-null (dangling!)

; Phase 1: Lock/init sound engine for mixing
0x83661F: test byte [0x019C6694], 0x01 ; "phase 1 initialized" flag
0x836626: jnz  0x836646               ; already initialized → skip init (taken: flag=3)

; Phase 1 init (skipped because flag bit 0 already set):
; 0x836628: mov eax, [ecx]            ; vtable
; 0x83662A: mov edx, [eax+0x0C]       ; vtable[3]
; 0x836634: push "PalSoundEngine::MixSources"
; 0x836639: call edx                  ; init/lock method

; Phase 1 main call:
0x836646: mov edx, [0x019C6690]       ; EDX = cached init result (0x00000000)
0x83664C: mov eax, [ecx]              ; EAX = vtable = *0x2006FBA8 = 0x00000000
0x83664E: mov eax, [eax+0x04]         ; *** CRASH *** [0x00000004] → access violation
0x836651: push edx
0x836652: push "PalSoundEngine::MixSources"
0x836657: call eax                    ; would call vtable[1] — the actual MixSources impl
```

## Thread Loop: Audio Mixer Thread (0x831EE0)

The crash occurs on a **dedicated audio thread** (call stack depth = 4: thread entry → loop → MixSources).

```asm
; Thread entry at 0x831EE0 — arg1 = this (0x019C6170)
0x831EE0: push ebp / mov ebp, esp / and esp, -8
0x831EE9: mov esi, [ebp+0x08]         ; esi = this (mixer context)
0x831EEC: mov eax, [esi+0x43C]        ; eax = wait handle

; Main loop:
loop_top:
0x831EF6: call [WaitForSingleObject]  ; WaitForSingleObject(handle, 5ms)
0x831EFC: cmp eax, 0x102              ; WAIT_TIMEOUT?
0x831F01: jnz exit_loop               ; event signaled → exit

0x831F03: cmp byte [0x01175FFF], 0    ; g_shutdownFlag
0x831F0A: jz  do_mix                  ; not shutting down → mix audio

; Normal path (shutdown flag = 0):
do_mix:
0x831F13: lea ebx, [esi+0x1C0]        ; ebx = &this->criticalSection
0x831F19: push ebx
0x831F1A: call [EnterCriticalSection]
0x831F20: mov edi, esi
0x831F22: call 0x836610               ; ← PalSoundEngine::MixSources — CRASH
0x831F27: push ebx
0x831F28: call [LeaveCriticalSection]

0x831F2E: push 45
0x831F30: call [Sleep]                 ; Sleep(45ms)
0x831F36: <reload handle, jmp loop_top>
```

### Pseudocode

```c
void AudioMixerThread(MixerContext* ctx) {
    while (WaitForSingleObject(ctx->waitHandle, 5) == WAIT_TIMEOUT) {
        if (!g_shutdownFlag) {
            EnterCriticalSection(&ctx->cs);
            PalSoundEngine_MixSources();   // ← crashes here
            LeaveCriticalSection(&ctx->cs);
        }
        Sleep(45);
    }
}
```

## Call Stack

| # | Address | From | Comment |
|---|---------|------|---------|
| 0 | `0x4CB7FF78` | `0x83664E` | PalSoundEngine::MixSources+0x3E |
| 1 | `0x4CB7FF88` | `0x76BF7BA9` | kernel32.BaseThreadInitThunk+0x19 |
| 2 | `0x4CB7FFE0` | `0x77E7C0CB` | ntdll.RtlInitializeExceptionChain+0x6B |
| 3 | `0x4CB7FFF0` | `0x77E7C04F` | ntdll.RtlClearBits+0xBF |

Only 4 frames — this is a thread entry function, not called from deep game logic.

## Global State Summary

| Address | Value | Meaning |
|---------|-------|---------|
| `[0x01176404]` | `0x2006FBA8` | g_pPalSoundEngine — **dangling** (freed object) |
| `[0x01995D70]` | `0x00BE2440` | g_pPalSoundWave — **valid** (static vtable for "PalSoundWave::UpdateMixVolumes") |
| `[0x019C6694]` | `0x03` | Mixer phase flags — bits 0,1 set (both phases initialized) |
| `[0x019C6690]` | `0x00000000` | Cached result from phase 1 init call |
| `[0x019C615C]` | `0x01` | Secondary audio subsystem initialized |
| `[0x01175FFF]` | `0x00` | **Shutdown flag NOT set** — thread was never signaled |

## Mixer Thread Context Object (0x019C6170)

```
+00: 0x00BE1D48  — vtable (valid, 8 entries in .rdata)
+04: 0x00000000
+08: 0x00000000
+0C: 0x00000000
+10: 0x00000060  — 96 (sample count? buffer size?)
+14: 0x00000040  — 64
+18: 0x00000001
+1C: 0x00000001
+20: 1.0f        — volume/matrix entry
+24: 0.0f
...
+34: 1.0f        — volume/matrix entry
```

The context object itself is healthy — the problem is solely with the PalSoundEngine it references.

## Crash Timeline (Revised — May 28, 2026)

Previous analysis theorized a self-destruct path. x32dbg hardware breakpoint tracing
revealed the actual mechanism is a **buffer overflow from the audio mixing loop**.

1. **Game loads DLC WAD** — soundbank/wavebank entries are byte-swapped by
   `_convert_soundbank_data` and `_convert_wavebank_data` in `ucfx_be_to_le.py`
2. **Soundbank byte-swap corruption** — the u8x4 flag field map was absolute (covered
   only the first 2 records of section 1), not periodic.  Soundbanks with 3+ sounds
   have their codec/channel/flag bytes corrupted for the 3rd+ sound (record stride =
   `count × 4` = 116 bytes; u8x4 relative offsets 12, 20, 44 within each record)
3. **Game tries to play a sound** from a corrupted soundbank record — the audio setup
   function at `0x416C90` fails to resolve the clip (wrong codec byte → wrong lookup
   path → no matching clip) and **returns without initializing the local mixing buffer**
4. **Caller at `0x409457` doesn't check** the setup return value and calls the mixing
   function (`0x4157C0` → `0x57EBAB`) with the uninitialized buffer
5. **Mixing loop reads stale stack data** as audio parameters:
   - `[EDI+0x18]` = `0x3C0282B0` → points to a **LAYER-type UCFX container's data area**
     containing script text (`"FireAngleEnum"`, `"Narrow"`, `"Medium"`)
   - `[EDI+0x04]` = `0xE6B81A54` → `TYPE_HASH_LAYER` (stale from prior frame)
   - Loop counter (EBX) ≈ `0x72656D61` → ASCII `"amer"` (from "Camera") → **~1.9 billion**
6. **Buffer overflow** — the mixing loop at `0x28CB273`–`0x28CB2A7` writes 8 bytes per
   iteration to the output buffer (EBP).  After ~86K iterations, EBP reaches `0x2006FBA8`
   (the **PalSoundEngine object**) and overwrites its vtable and fields with zeros
7. **MixSources crash** — on the next mixer tick, `PalSoundEngine::MixSources` at
   `0x83664E` dereferences the zeroed vtable → `[0x00000000 + 4]` → ACCESS VIOLATION

### Root Cause: Periodic u8x4 soundbank byte-swap bug

The `_SOUNDBANK_U8X4_BODY_OFFSETS` set contained absolute offsets `{0x2C, 0x34, 0x4C,
0xA0, 0xA8, 0xC0}` — exactly covering records 0 and 1 of the 116-byte record stride.
Records 2+ had their u8x4 fields (codec, channels, flags) byte-swapped, corrupting them.

**Fix**: replaced absolute offset set with `_SOUNDBANK_U8X4_RECORD_RELATIVE = {12, 20, 44}`
applied periodically to every record in sections 1 and 3 using modular arithmetic:
`(off - section_start) % record_stride in u8x4_set`.

## Key Functions Identified

| Address | Name / Purpose |
|---------|---------------|
| `0x836610` | `PalSoundEngine::MixSources` — crash site |
| `0x831EE0` | Audio mixer thread entry (WaitForSingleObject loop) |
| `0x83C810` | PalSoundWave singleton initializer (sets `[0x01995D70]` = static vtable) |
| `0xB03A70` | atexit-style callback: `mov [0x01995D70], 0xBE242C; ret` |
| `0x9EE331` | atexit registration function |
| `0xBE1D48` | Mixer context vtable (8 entries, all valid code pointers) |
| `0xBE2440` | PalSoundWave static vtable ("PalSoundWave::UpdateMixVolumes" at +0x14) |

## Remediation

### Fix applied: periodic u8x4 soundbank byte-swap (primary)
`_convert_soundbank_data` in `tools/ucfx_be_to_le.py` now uses periodic u8x4 field
protection: the relative offsets `{12, 20, 44}` within each 116-byte record are applied
to **every** record in sections 1 and 3 via `(off - section_start) % record_stride`.
This replaces the old absolute offset set that only covered 2 records.

Rebuild the WAD with `make dlc-port` to apply the fix.

### Fallback: Strip DLC audio entries from WAD
Pass `--strip-audio` to `dlc_port.py` to remove soundbank/wavebank entries entirely.
The DLC content loads without custom audio (falls back to base game sound banks).

### Fallback: ASI hook — null guard on MixSources
In `dlc_enable.asi`, guard the vtable dereference at `0x83664C`: if `[0x01176404]`
has vtable == 0, set the pointer to NULL so the existing null check at `0x83661D`
skips the call.  This doesn't fix the overflow but prevents the crash symptom.

## Runtime Trace Integration

For repeatable runtime investigation and reuse-oriented artifact handling, use:

- `docs/runtime_trace_loop.md` for the operational loop and acceptance criteria
- `mods/engine_trace_asi/` for trace probe scaffolding
- `tools/runtime_trace/` for normalization, migrations, and simulator bundle assembly

The first probe priority remains the mixer call-chain up to `PalSoundEngine::MixSources`.
