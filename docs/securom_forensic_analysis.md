# SecuROM Forensic Security Analysis — Mercenaries 2 EXE

**Binary**: `output/patched/Mercenaries2.exe` (cracked retail)  
**Size**: 53,482,288 bytes (51.0 MB)  
**DRM**: SecuROM v7.37 (Sony DADC Austria AG)  
**Build path**: `C:\Builds\SecuROM-DRM_7_37\SecuROM_DRM\Wrapper\wrapper.pdb`

---

## Executive Summary

The cracked EXE contains a **hybrid state**: some code was successfully decrypted while other CALL/JMP targets point to **zeroed-out memory** — indicating the crack was a **memory dump** that captured the runtime state of the process *after* the SecuROM loader partially decrypted sections, but **before all trigger functions were resolved**.

### Key Findings

| Finding | Status |
|---------|--------|
| Stext section decrypted? | **PARTIALLY** — 3.69MB zeroed, 2.54MB contains code+data |
| SecuROM VM code present? | **YES** — Sdata, Sidata, Sitext contain obfuscated VM bytecode |
| AES S-box in EXE? | **NO** — not found in any section |
| SecuROM trigger functions? | **YES** — 120+ CALL targets from .text → Stext point to zeroes |
| Stolen code functions? | ~473 legitimate functions in Stext active region |
| Anti-piracy degradation? | **POSSIBLE** — 120 dead call targets could cause silent failures |
| Total unresolved calls/jumps | **~90 calls + 28 jumps → zeroed memory** (will crash/NOP) |

---

## 1. Section Entropy Analysis

| Section | Size | Entropy (4KB) | Entropy (full) | Assessment |
|---------|------|---------------|----------------|------------|
| **Stext** | 6.23 MB | **0.0000** | 3.5149 | 3.69MB zeroes + 2.54MB VM/code |
| **Sitext** | 28 KB | 6.6156 | 6.7952 | Compiled code (SecuROM) |
| **Srdata** | 360 KB | 6.4977 | 6.3983 | Compiled code (SecuROM runtime) |
| **Sdata** | 3.0 MB | 6.1014 | 6.4168 | VM-obfuscated code |
| **Sidata** | 24 KB | 6.2445 | 6.2703 | VM-obfuscated code |
| **.securom** | 19.1 MB | 6.1589 | 2.3897 | SecuROM engine + large zero fill |
| **reloaded** | 816 B | 0.0000 | 0.0000 | Completely zeroed (unused by crack) |
| *.text* (ref) | 7.0 MB | 5.8105 | — | Normal compiled game code |

### Interpretation

- **Stext is NOT encrypted** (entropy 0.0 in prefix) — it was decrypted but incompletely populated
- **Sitext/Srdata/Sdata/Sidata** contain SecuROM's own executable code with moderate entropy (~6.1-6.8) — this is the protection runtime, not encrypted game code
- **The .securom section** has low overall entropy (2.39) because much of it is zero-filled storage area, with the active protection engine in the first ~5MB

---

## 2. The "Stolen Code" Problem

SecuROM v7 uses a technique called **code stealing** (also called "nanomites" or "code displacement"):

1. The protector **removes** critical functions from `.text` during protection
2. These functions are **relocated** into the `Stext` section
3. At runtime, SecuROM decrypts and maps them back
4. CALL/JMP instructions in `.text` are rewritten to point into `Stext`

### Evidence in This EXE

The .text section contains **123 CALL + 31 JMP instructions** targeting addresses in Stext. Analysis reveals:

- **~90 of 120 unique CALL targets point to all-zeroes** — these functions were NEVER recovered
- **~28 of 30 unique JMP targets point to all-zeroes** — same problem
- Only **~7 targets** point to actual code (the SecuROM dispatch stubs at VA 0x01A53xxx and a few data regions)

### ~~The 120 Dead Functions~~ CORRECTED: These Are FALSE POSITIVES

> **CORRECTION (2026-05-20)**: Subsequent instruction-boundary-aware analysis proved
> that ALL "dead call" targets identified below are **false positives**. The E8/E9
> bytes found by the naive scan are actually ModRM operands of other instructions:
> - `C1 E8 xx` = `SHR EAX, imm8` (most common — 30+ instances)
> - `83 E8 xx` = `SUB EAX, imm8`
> - `81 E9 xx xx xx xx` = `SUB ECX, imm32`
> - `D9 E8` = `FLD1` (FPU load constant 1.0)
> - `8B E9` = `MOV EBP, ECX`
> - `0F AF E9` = `IMUL EBP, ECX`
>
> The REAL SecuROM dispatch calls go to **live** stubs at 0x01A53CE0, 0x01A53D80,
> 0x01A53F50, 0x01A54030, 0x01A551C0, and 0x01AAFF10 — which are all functioning
> correctly (captured by the memory dump crack). There are **zero** unresolved
> calls from .text into zeroed Stext memory.
>
> The game crash at 0x005AE372 is caused by an uninitialized script command table
> pointer, not by a dead SecuROM call. See `dlc_enable.c` for the fix.

~~These are game functions that were "stolen" by SecuROM and NOT recovered by the crack:~~

```
VA 0x01649CC3, 0x0168D972, 0x01694AAD, 0x016CA15F, 0x016CC2F8,
0x01730210, 0x0174DDFF, 0x0174DE73, 0x0174DEE1, 0x0174DF57,
0x017554AD, 0x01766087, 0x01774C09, 0x017932FC, 0x017986B8,
0x017C4650, 0x017CA5FF, 0x017D2854, 0x017D2973, 0x017DE54A,
... (90 total pointing to zeroes)
```

~~When game code calls these addresses, execution hits `00 00 00 00` (which decodes as `ADD [EAX], AL`) — this will either crash or silently corrupt memory.~~

### The Callers (Game Functions Affected)

| Caller VA | Likely Function Area |
|-----------|---------------------|
| 0x004301A3 | Early startup / init |
| 0x0043954E | Early startup / init |
| 0x0048A6EE | UCFX/asset loading |
| 0x0048F928 | UCFX/asset loading |
| 0x0049957E | Asset system |
| 0x0054E1F2 | Audio/rendering |
| 0x005643D9 | Core engine |
| 0x0056391C, 0x00563A61 | Core engine |
| 0x0066A9F4 | Gameplay |
| 0x006814C6 | Gameplay |
| 0x006895D9 | Gameplay |
| 0x0072790F | Physics/Havok |
| 0x007369A1, 0x00736A46 | Rendering (gradient tables) |
| 0x00741595–0x007431F4 | **Rendering — color/gradient table lookups (15 calls!)** |
| 0x0086BF60–0x0086BF91 | Gameplay |
| 0x009B4ADB–0x009B4B7B | Networking? |

The **VA 0x00741xxx** cluster (15 calls) all target what appear to be **color gradient lookup tables** that were stored in Stext. The game likely builds visual effects from these — losing them would cause rendering anomalies but not crashes (the data appears to be repeating RGB triples like `FF FF FF`, `B6 B6 B6`).

---

## 3. Stext Active Code Region

The Stext section has a clear two-part layout:

```
Offset 0x000000 - 0x3B0FFF: ALL ZEROES (3.69 MB) — reserved space, never filled
Offset 0x3B1000 - 0x63AFFF: Active content (2.54 MB)
```

The active region contains:
- **473 function prologues** (`push ebp; mov ebp, esp`)
- **5,814 INT3 padding bytes** (function alignment)
- **86,999 NOP bytes** (heavy NOP sledding — characteristic of SecuROM VM dispatch)
- **46 CALL instructions back into .text** (confirming this is game code calling game functions)
- **No readable strings** — the "strings" found are actually repeating byte patterns used as VM opcode tables

### Assessment of the Active Code

The first real functions start at VA 0x01A6FDE0. Examining them:

```
VA 0x01A6FDE0: 55 8B EC 51 56 57 6A 64 BE 1C E3 08 02 56 FF 15
               DD 16 3F 02 ...
```

This is **legitimate x86 code**: `push ebp / mov ebp,esp / push ecx / push esi / push edi / push 100 / mov esi, 0x0208E31C / push esi / call [0x023F16DD]`

The address `0x023F16DD` is in the `.securom` section — this function calls through SecuROM's IAT/import redirection. This proves the code in Stext is **SecuROM's own runtime helper code** plus some relocated game functions.

---

## 4. SecuROM VM-Obfuscated Code (Sdata Section)

The `Sdata` section (3MB) at VA 0x01CE5000 contains SecuROM's **virtual machine**-protected code. The characteristic pattern:

```
74 FF CC 8B 44 24 10 90 8B 7C 24 0C 8B 4C 24 08
56 5E 83 C4 18 90 9D B8 F0 11 09 02 8D 64 24 FC
C7 04 24 B4 B8 CE 01 90 9C 81 44 24 04 C3 00 00
00 9D EB F9 ...
```

This is **metamorphic code** — real x86 instructions mixed with:
- `9C/9D` (PUSHFD/POPFD) — flag save/restore pairs surrounding operations
- `90` (NOP) — padding between VM opcodes
- `EB F9` — short backward jumps (opaque predicate patterns)
- `81 04 24 xx xx xx xx` — ADD [ESP], imm32 (return address manipulation)
- `C7 04 24` — MOV [ESP], imm32 (stack frame rewriting)
- `FF 74 24 04 / 9D / EB F5` — repeated push+pop patterns

This is SecuROM v7's **virtual machine dispatch loop**. Each "function" is a VM handler that:
1. Saves flags
2. Manipulates the stack to redirect returns
3. Decodes a virtual opcode
4. Jumps to the next handler via obfuscated computation

**This code CANNOT be directly decompiled** — it requires VM bytecode analysis to understand what logical operations are being performed.

---

## 5. SecuROM API and Infrastructure

### Protection API (PA_*) Functions

Found in `.securom` at offset 0x01CA2578:

```
PA_REQUEST_GET_INIT_EXPIRY
PA_REQUEST_UNDEFINED
PA_REQUEST_GET_UL_REQUEST
PA_REQUEST_SET_UL_CODE
PA_REQUEST_EVAL_UL_CODE
PA_REQUEST_SET_SERIAL
PA_REQUEST_GET_SERIAL
PA_REQUEST_GET_EXPIRY_INFO
PA_REQUEST_GET_GRACE_INFO
PA_REQUEST_IS_ONLINE
PA_REQUEST_ACTIVATE_ONLINE
PA_REQUEST_VERIFY_ONLINE
PA_REQUEST_IS_REGISTERED
PA_REQUEST_REGISTER
PA_REQUEST_INIT
PA_REQUEST_GETLOGFILENAME
PA_REQUEST_ENABLE_LOG
PA_REQUEST_SET_PADATA_UNLOCK
PA_REQUEST_UPDATE_PADATA
PA_REQUEST_GET_PADATA
PA_REQUEST_GET_PALICENSE
PA_REQUEST_UPDATE_PLAYTIME
PA_REQUEST_IS_PA_LIC
PA_REQUEST_EVAL_UL_CODE_NO_UPDATE
PA_REQUEST_GET_ID
PA_REQUEST_DEL_UD
PA_REQUEST_GET_LIC_ID
PA_REQUEST_INVALIDATE_GRACE_EXPIRY
PA_REQUEST_GET_INIT_GRACE
```

### Event Name Pattern

SecuROM creates a named event `v7_%04d` (formatted with a game-specific ID). Found at:
- Offset 0x007BD19C (in `.rdata` — game code references this)
- Offset 0x01C90F70 (in `.securom` — protection code uses this)

The format `v7_XXXX` is how SecuROM communicates between its DLL and the protected EXE. Our `pmc_bb.dll` already creates this event.

### User Data Storage

```
UserData\securom_v7_01.dat    — license data
UserData\securom_v7_01.bak    — backup
v7_01.tmp                      — temporary during operations
Software\SecuROM\License information  — registry key
Software\SecuROM\UserData      — registry key
Software\SecuROM\Keys          — registry key
Software\SecuROM\WL            — whitelist
```

### Online Activation

SecuROM v7 contacts activation servers:
```
pa02.sonyvfactory.com:443/SecuROM_pa_web/activation
pa01.sonyvfactory.com:443/SecuROM_pa_web/activation
pa02.sonyvfactory.com:80/SecuROM_pa_web/activation
pa01.sonyvfactory.com:80/SecuROM_pa_web/activation
```

These servers are **long defunct** — online activation is impossible.

### DFA (Digital Fingerprint Analysis)

```
DFA.lib: initDFA failed: DFA.dll not found (%i)
DFA.lib: initDFA failed: maybe wrong version of DFA.dll (%i)
DFA.lib: initStub failed: errorcode: %i
```

DFA is SecuROM's disc fingerprint verification — checks physical disc characteristics.

### Anti-Debug/Anti-Tamper

The `.securom` section imports:
- `IsDebuggerPresent` — basic debugger detection
- `GetTickCount` — timing checks
- `VirtualProtect` — runtime memory protection changes
- `DeviceIoControl` — disc drive access for DFA
- `CreateMutexA` / `CreateEventA` — process synchronization
- `GetCurrentProcessId` / `GetCurrentProcess` — self-inspection

### Build Information

```
C:\Builds\SecuROM-DRM_7_37\SecuROM_DRM\Wrapper\wrapper.pdb
Sony DADC Austria AG
SecuROM Security Module
SecuROM User Access Service (V7)
```

Version: **SecuROM DRM 7.37**

---

## 6. The `reloaded` Section

The `reloaded` section (816 bytes, VA 0x03301000) is **completely zeroed**. In the original cracked EXE, this section was added by the cracking tool (likely the "Reloaded" scene group's generic unpacker) to hold:
- Import address table redirections
- Loader stub code

In this particular dump, it appears the section header exists but was never populated — suggesting this is a **memory dump** rather than a traditionally patched executable. The crack likely:
1. Ran the game under a debugger
2. Let SecuROM decrypt code into memory
3. Dumped the process memory to disk
4. Fixed up the PE headers

---

## 7. AES Key Analysis

**No AES S-box, inverse S-box, or round constants were found** anywhere in the EXE. This means:

1. SecuROM v7.37 may use a **custom cipher** rather than standard AES-128 (despite literature claiming AES)
2. OR the key schedule is computed at runtime and never stored as a static table
3. OR the decryption happens in the SecuROM service process (`SecuROM User Access Service`) rather than in-process

The absence of AES tables combined with the heavy VM obfuscation suggests SecuROM v7 uses a **proprietary stream cipher or modified block cipher** implemented inside the VM, making static key extraction essentially impossible.

---

## 8. Can We Recover the Missing Functions?

### Option A: Decrypt from the original protected EXE
**NOT FEASIBLE** — No AES tables found, cipher is VM-implemented, key derivation requires disc fingerprint data that is hardware-specific and the activation servers are dead.

### Option B: Runtime capture (better crack)
**FEASIBLE** — Run the game with a legitimate disc, set breakpoints at the 120 zeroed CALL targets, and capture the decrypted code when SecuROM loads it. Requires:
- Original retail disc
- Windows XP/7 environment
- Debugger that can evade SecuROM's anti-debug

### Option C: Identify functions from Mercenaries 1 source
**PARTIALLY FEASIBLE** — The first game's engine source is available at:
```
game-files/first-game-source-code-with-engine/Final_Editor_And_Projects_Folders/Projects/RedEngine/
```
Since Mercs 2 uses an upgraded version of the same engine (build path `D:\Projects\Mercs2_PC\mercs2\`), many of the stolen functions may have equivalent implementations in the Mercs 1 source. However:
- The functions that ARE present already work (the 473 recovered functions)
- The 90 missing functions may have been specifically targeted by SecuROM as "trigger" functions
- Trigger functions often perform license verification inline — they're designed to degrade the game if the protection isn't running

### Option D: NOP/stub the dead calls
**MOST PRACTICAL** — Since the game already runs (the crack works), the 90 dead CALL targets either:
- Are never reached in normal gameplay (unlikely for all 90)
- Are reached but handled by exception handlers that provide fallback behavior
- Cause subtle degradation (missing visual effects, audio glitches, etc.)

The **15 calls from VA 0x00741xxx** that target color gradient data are particularly interesting — these likely affect rendering quality but not functionality.

---

## 9. SecuROM "Trigger" Function Assessment

SecuROM v7 scatters "trigger" functions throughout the game code. These are legitimate game functions that also verify the protection is active. If verification fails, they can:
- Return wrong values (degraded gameplay)
- Set flags that disable features later
- Cause crashes at calculated intervals

In this EXE, the **120 dead call targets** are almost certainly trigger functions. The fact that the game runs at all suggests:
- Either the calls are rarely hit
- Or there are exception handlers catching the crashes from executing zeroed memory
- Or the crack patched the callers to skip these calls (not confirmed)

### Checking if callers are patched

Looking at CALL 0x009C9CBF → target 0x01649CC3 (zeroes):
```
At VA 0x009C9CBF: E8 FF 03 C8 00  (CALL +0x00C803FF)
```
The CALL instruction is intact — it hasn't been NOPped out. This means when execution reaches this code path, it WILL call into zeroed memory.

---

## 10. Recommendations

1. **Document the 120 dead function addresses** for future reference if a better crack becomes available

2. **Check the Mercs 1 engine source** (`game-files/first-game-source-code-with-engine/`) for functions that match the caller patterns — especially the 15 rendering calls at 0x00741xxx which may be simple gradient/LUT generation

3. **The game runs despite dead functions** — this suggests they are either:
   - Error-handled (SEH catches the access violation)
   - On rarely-hit code paths (debug features, specific scenarios)
   - Related to DRM verification that was bypassed upstream

4. **For modding purposes**: The Lua integration, WAD loading, sges decompression, and all other critical systems are in the fully recovered `.text` section. The SecuROM sections do NOT contain game logic needed for asset extraction or mod injection.

5. **The `v7_%04d` event** (already used in `pmc_bb.dll`) is sufficient to satisfy SecuROM's runtime presence check without needing to understand the VM-protected code.

---

## Appendix: File Offsets of All Sections

| Section | File Offset | VA | Notes |
|---------|-------------|-----|-------|
| .text | 0x00001000 | 0x00401000 | Game code (FULLY RECOVERED) |
| .rdata | 0x00705000 | 0x00B05000 | Read-only data |
| .data | 0x007F6000 | 0x00BF6000 | Read-write data |
| Stext | 0x01249000 | 0x01649000 | Stolen code (PARTIAL — 90 dead targets) |
| Sitext | 0x01884000 | 0x01C84000 | SecuROM VM code |
| Srdata | 0x0188B000 | 0x01C8B000 | SecuROM runtime data |
| Sdata | 0x018E5000 | 0x01CE5000 | SecuROM VM handlers |
| Sidata | 0x01BE3000 | 0x01FE3000 | SecuROM VM handlers |
| .securom | 0x01BE9000 | 0x01FE9000 | SecuROM protection engine |
| reloaded | 0x02F01000 | 0x03301000 | Zeroed (crack placeholder) |
