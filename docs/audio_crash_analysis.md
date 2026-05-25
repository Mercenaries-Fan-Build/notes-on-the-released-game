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

## Crash Timeline

1. **Game loads DLC WAD** containing Xbox 360 XMA-encoded audio entries
2. **Audio streaming begins** — the mixer thread runs its WaitForSingleObject/MixSources loop normally
3. **Engine encounters XMA codec** — attempts to stream `dlctest_streaming.pws` or `vo_stream_dlctest.pws` which are XMA-encoded (Xbox 360 format, not PC ADPCM/PCM)
4. **PalSoundEngine self-destructs** — the engine hits a fatal error, zeros its vtable, and frees its memory at `0x2006FBA8`. **Critical bug**: it does NOT:
   - Clear the global pointer at `[0x01176404]`
   - Set the shutdown flag at `[0x01175FFF]`
   - Signal the mixer thread's wait handle to wake it
5. **Mixer thread wakes up** (5ms WaitForSingleObject timeout), sees shutdown flag = 0
6. **Thread enters critical section** and calls `MixSources`
7. **MixSources reads stale pointer** → `[0x01176404]` is non-null → passes null check
8. **Vtable dereference fails** → `[0x2006FBA8]` = 0 → `[0x00000000 + 4]` → **ACCESS VIOLATION**

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

## Remediation Options

### Option 1: Strip DLC audio entries from WAD (recommended)
Remove or zero the 10 soundbank (type `0x9F8BCA10`) and 11 wavebank (type `0xF753F6D0`)
entries from `vz-patch.wad`. The DLC missions/content can still load — they just won't
have custom audio, falling back to the base game's sound banks.

### Option 2: Convert XMA → PC codec
Re-encode the `.pws` files from Xbox 360 XMA to the PC's expected audio format. Requires
reverse-engineering the PC `.pws` container structure.

### Option 3: ASI hook — null guard on MixSources
In `dlc_enable.asi`, patch the instruction at `0x83664C` or intercept the global pointer
read. If `[0x01176404]` points to freed memory (vtable == 0), set it to NULL so the
existing null check at `0x83661D` skips the call safely.

### Option 4: ASI hook — proper shutdown synchronization
Hook the PalSoundEngine destructor to set `[0x01175FFF] = 1` and signal the wait handle
before freeing the object. This is the correct fix but requires identifying the destructor.
