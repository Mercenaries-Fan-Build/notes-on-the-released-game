---
title: Double-blind validation — lti_movie_pda_code_map.md
status: current
evidence: proven
date: 2026-07-26
subject: docs/reverse_engineer/lti_movie_pda_code_map.md
method: Phase A derived from primary sources with the target map unopened; Phase B compares.
---

# Double-blind validation: `lti_movie_pda_code_map.md`

Subject: the Lua cfunc table at `0x00B99C78` (52 entries) and the `Movie` table at `0x00B99BBC` (4 entries).

**Primary sources actually used**

| # | Source | Use |
|---|---|---|
| 1 | `output/_ghidra/securom_dump/mercs2_unpacked.exe` | all addresses, all disassembly. VA→file via the PE section table (`.text` VA `0x00401000` raw `0x1000`; `.rdata` VA `0x00B05000` raw `0x705000`; `.data` VA `0x00BF6000` raw `0x7F6000`; `.securom` VA `0x023E9000` raw `0x1FE9000`). Disassembled with capstone x86-32. |
| 2 | `output/_ghidra/mercs2_unpacked.exe_decomp.txt` | only to compare Ghidra's *rendering* against the binary. |
| 3 | `output/gfx_movies/**` (67 + `shell/` + `loading/`) | shipped ActionScript identifier strings (zlib-inflated `CFX` payloads). |
| 4 | `docs/mercs2-luacd/` | real script call counts. |
| 5 | `docs/ui/main_menu_structure.md`, `docs/mercs2_licensing_registration_map.md` (2026-07-01), `docs/data/scaleform_gfx_function_map.json` | claims under test / pointers, not evidence. |
| 6 | `C:/GOG Games/The Saboteur/Saboteur.exe` | negative cross-check for the LTI module. |

Scripts: `…/scratchpad/v/{mype,t1..t13}.py` (scratch, not committed).

---

## Phase A — independent findings (written before reading the map)

### A1. The Lua global is literally `LTILibName` — and the registry base is `0x00DFD478`, 31 rows

The registrar is a **12-byte-record array of `{const char* libname, luaL_reg* table, const char* post_lua}`**.

Walking it from `0x00DFD478` with stride 12 until the `{0,0,0}` terminator at `0x00DFD5EC` gives **exactly 31 records**:

```
 0 00DFD478 _SYS(6)        13 00DFD514 Graphics(95)    26 00DFD5B0 Table(2)
 1 00DFD484 Sys(64)        14 00DFD520 Sound(88)       27 00DFD5BC Report(5)
 2 00DFD490 Pg(80)         15 00DFD52C ObjectFilter(16)28 00DFD5C8 Disguise(1)
 3 00DFD49C Object(87)     16 00DFD538 Net(92)         29 00DFD5D4 FactionZone(1)
 4 00DFD4A8 Player(107)    17 00DFD544 math(17)        30 00DFD5E0 LTILibName(52)
 5 00DFD4B4 Event(4)       18 00DFD550 Camera(14)      -- 00DFD5EC {0,0,0} terminator
 6 00DFD4C0 Ai(66)         19 00DFD55C Junk(24)
 7 00DFD4CC Human(32)      20 00DFD568 ObjectState(9)
 8 00DFD4D8 Debug(6)       21 00DFD574 Movie(4)
 9 00DFD4E4 Vehicle(40)    22 00DFD580 Animation(6)
10 00DFD4F0 Airstrike(12)  23 00DFD58C VO(11)
11 00DFD4FC Gui(38)        24 00DFD598 Weapon(9)
12 00DFD508 _GuiInternal(114) 25 00DFD5A4 String(1)
```
Total 1103 cfunc entries across all 31 libraries.

The **only** pointer to `0x00B99C78` anywhere in the image is at `0x00DFD5E4` (record 30, field 1). The only pointer to `0x00B99BBC` is at `0x00DFD578` (record 21, field 1 = `Movie`).

**`0x00DFD478` vs `0x00DFD514` — reconciled.** They are the *same array*. `0x00DFD514` is **record 13 (`Graphics`)**, not a base: `(0x00DFD514 − 0x00DFD478)/12 = 13`. Counting from there to the last record gives `(0x00DFD5E0 − 0x00DFD514)/12 + 1 = 18` — which is exactly where "18 records at `0x00DFD514`" comes from. The binary settles it:

```
005A2D38  cmp dword ptr [0x00DFD478], ebx      ; ebx = 0 -> empty-array guard
005A2D48  mov edi, 0x00DFD478                  ; base
005A2D50  mov eax, [edi]                       ; record[i].libname
005A2D53  mov eax, [esi + 0x00DFD47C]          ; record[i].table
005A2D5B  call 0x005A2FD0                      ; register(name, table)
...
005A2DE4  lea esi, [esi + esi*2] / add esi,esi / add esi,esi   ; i*12
005A2DEB  cmp dword ptr [esi + 0x00DFD478], ebx ; loop while name != NULL
```
`0x00DFD478` has **4 code references**; `0x00DFD514` and `0x00DFD5E0` have **zero**. Verdict: **`0x00DFD478` / 31 rows is right; `0x00DFD514` / 18 rows is a mid-array slice of the same structure.**

The name string is genuinely the C identifier: raw `.rdata` at `0x00BB6E24` reads `… \x00\x00\x00\x00LTILibName\x00\x00LTIVideoSetSwitchOpt1\x00…`. This is a shipped source defect — somebody wrote `"LTILibName"` where they meant the *value* of a `LTILibName` constant.

**Confirmed independently in script:** `LTILibName.` appears **221 times** in `docs/mercs2-luacd/`; `Lti.` appears **0 times**.

`0x005A2FD0` (the per-library registrar) is itself a full SecuROM steal (`jmp [0x02458A68]`), but its stolen body at `0x02471B40` is *decrypted* in this dump and calls back into `0x005A2E40` / `0x005A2E90` — the `{name, 0xFFFFFFFF}` / `0xFFFFFFFE` marker-row walker (`cmp ecx, -1` at `0x005A2E55`). Image-wide there are 11 `0xFFFFFFFF` and 11 `0xFFFFFFFE` marker rows; **none of them are in the LTI or Movie tables**.

### A2. What "LTI" actually is — and what it is *not*

**Source-tree evidence (16 paths, all under one directory):**

```
D:\Projects\Mercs2_PC\mercs2\LTI\Src\DisplayMode.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\Dx9_State.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiBloomPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiBufferPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiRendererPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiRendererShadowPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgTextureImplLTI.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\RenderDevice.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\RenderSystem.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheIndexBuffer.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheMain.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheSurface.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheTexture.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheVertexBuffer.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheVertexDecl.cpp
d:\projects\mercs2_pc\mercs2\lti\src\Dx9_State.h
```
**Namespace evidence:** `.rdata` contains `LtiRender::RenderSystem::ReadSurfaceData` and `LtiRender::RenderSystem::WriteSurfaceData` (function-name literals, presumably for asserts/PIX). Plus 40+ `PgLti*` shader names (`PgLtiSkin1VP.sho`, `PgLtiSkin1ShadowVP.sho`, …). And `LTI_precache.gfx` ships in `shell/`.

So the module **LTI is the PC/D3D9 render+display+precache layer** — that part is solid.

**The acronym itself is NOT determinable.** No expansion string exists anywhere in the exe, in any of the 67+ shipped `.gfx` movies, or in the Xbox-360 PDB symbol corpus (`docs/mercs2-pdb-analysis/` contains zero `Lti`/`LTI` symbols — consistent with a PC-only module). Saboteur.exe (same studio, same engine family) contains **zero** `LTI`/`PgLti`/`LtiRender` strings, so there is no sibling-title corroboration either. **I decline to expand the acronym.**

What I *can* say about the gloss "Lua To Interface": it is unsupported and it mis-describes the module. LTI is where `Dx9_State.cpp` and `RenderDevice.cpp` live, not where Lua bindings live. Note also the caveat in the other direction: the *Lua table* named `LTILibName` is broader than the render module — it contains input remapping, profile, camera, shell-state and movie entry points as well as video options. So "LTI = the render-device layer" describes the **source module**, not the **contents of the Lua table**, and the two should not be conflated.

### A3. Bodies readable — 52 + 4

Full canonical table at `0x00B99C78` (52 entries, `{0,0}`-terminated at `0x00B99E18`):

| # | name | fn | # | name | fn |
|---|---|---|---|---|---|
|0|LTIMovieStart|`006D5640` **stub**|26|LTIInputKMApplyChanges|`005C1D00`|
|1|LTIMovieStop|`005C05A0`|27|LTIInputKMDefault|`005C1ED0`|
|2|LTIMoviePause|`005C0600`|28|LTIOverBoundResponse|`005C2730`|
|3|LTIMovieResume|`005C0660`|29|LTIInputKMCancelInput|`005C2720`|
|4|LTIVideoEnter|`005C0A20`|30|LTIInputKMExit|`005C2950`|
|5|LTIVideoSwitchMode|`005C0AF0`|31|LTIInputJoystickEnter|`005C2970`|
|6|LTIVideoNextRes|`005C0CE0`|32|LTIInputJoystickChangePrimary|`005C2CB0`|
|7|LTIVideoPrevRes|`005C0E10`|33|LTIInputJoystickChangeInput|`005C2E50`|
|8|LTIVideoNextRefresh|`005C0F40`|34|LTIInputJoystickCancel|`005C2720` *(= #29)*|
|9|LTIVideoPrevRefresh|`005C1000`|35|LTIInputJoystickApplyChanges|`005C33F0`|
|10|LTIVideoSetGamma|`005C10C0`|36|LTIInputJoystickDefault|`005C3500`|
|11|LTIVideoGetViewDistance|`0063EF20`|37|LTIInputJoystickExit|`005C3690`|
|12|LTIVideoApplyChanges|`005C1140`|38|LTIInputJoystickReEnter|`005C36B0`|
|13|LTIVideoDefault|`005C1160`|39|LTIJoystickOverBoundResponse|`005C3200`|
|14|LTIVideoCancel|`005C11D0`|40|LTIGetStartButton|`005C36D0`|
|15|LTIVideoAdvanceEnter|`005C1210`|41|ChangeShellState|`005C3740`|
|16|LTIVideoSwitchOpt1|`005C1240`|42|LTIProfileEnter|`005C3780`|
|17|LTIVideoAdvanceDefault|`005C13A0` **SecuROM**|43|LTIProfileExit|`005C37A0`|
|18|LTIInputGeneralEnter|`005C1470`|44|LTIPauseItemChanged|`005C37E0`|
|19|LTIInputGeneralOptions|`005C1600`|45|LTIPrecacheDone|`005C37C0`|
|20|LTIInputGeneralInvertMouse|`005C17B0`|46|LTIPrecacheSmokeDone|`005C37D0`|
|21|LTIInputGeneralMouseSense|`005C17F0`|47|LTIChoseOnline|`005C5800`|
|22|LTIInputGeneralJoySense|`005C1860`|48|LTIGetDateFormat|`005C5840`|
|23|LTIInputGeneralRumble|`005C18B0`|49|LTICamera|`005C58B0`|
|24|LTIInputKMEnter|`005C1900`|50|LTIupdateSupportQuickSlot|`006D5640` **stub**|
|25|LTIInputKMChangeInput|`005C1CC0`|51|FirstRun|`005C5900`|

`Movie` at `0x00B99BBC`, 4 entries, all real bodies: `Start 005C6510`, `Stop 005C6480`, `Pause 005C64B0`, `Resume 005C64E0`.

**Readability census (52):** 49 fully readable real bodies · 1 SecuROM-stolen (`LTIVideoAdvanceDefault` `005C13A0` = `jmp [0x02458788]` → `0x024E6220`, which is still *encrypted* in this dump: `push/push/pushfd/sub [esp+4],imm/popfd/ret` self-decryptor) · 2 pointing at the shared stub `0x006D5640`. **Movie: 4/4 readable.** So **53 of 56 bodies read; 3 not.**

`0x006D5640` is itself SecuROM-stolen (`e9 7b ca 5f 6f` → out-of-image, fixed up at load). It is shared by **61 entries across all 31 libraries** — `Debug.Printf`, `Debug.Assert`, `Debug.LogError`, `Debug.GetCallstack`, all 15 `Junk.*` debug dumpers, 15 `Ai.Plan*/spawn-debug`, `Sound._SummonEd`, `Sys.WriteToConsole`, `ObjectState.PrintStateMachine`, … i.e. the retail-stripped developer surface. That it is the ICF-folded **no-op** is a very strong inference but it is an **inference**, not a read — the body is encrypted here.

Table separators: each table is preceded by `{0,0}` and a stray `0x40490FDB` (float π) that the linker interleaved between the arrays. `0x00B99BBC` is 4-mod-8; the alignment is real, not a transcription error.

### A4. Script call counts (`docs/mercs2-luacd/`)

**48 of the 52 cfuncs are called from Lua.** The 4 that are never called are exactly `LTIMovieStart`, `LTIMovieStop`, `LTIMoviePause`, `LTIMovieResume`. The `Movie` library is called **0 times** (`Movie.` → no hits; the bare token `Movie` appears 6 times, none as a namespace call).

Top counts: `ChangeShellState` 24 · `LTIVideoAdvanceEnter` 8 · `LTIInputGeneralEnter` 8 · then a long tail of 6/4/3/2/1. `LTIupdateSupportQuickSlot` = **1** (`mrxguipda.lua:1858`).

Note the ambiguity trap: many `LTI*` tokens in the Lua corpus are **ActionScript** names passed to `SetFlashEventHandler`, not cfunc calls (`MrxGuiLTIPrecache` ×45, `_LTIFscommand` ×8, `LTI_precache` ×13). Only the `LTILibName.X` form is a cfunc call.

### A5. `FUN_0061C550` — the Scaleform Invoke wrapper

**The SecuROM split is real.** At `0x0061C550`:

```
0061C550  ff2570554502   jmp dword ptr [0x02455570]      ; -> 0x024B5390 (still encrypted here)
          <9 bytes stolen: 0061C550..0061C558>
0061C559  a1 b45f1701    mov eax, [0x01175FB4]           ; body resumes HERE
0061C55E  53             push ebx
0061C55F  50             push eax
0061C560  32db           xor bl, bl
0061C562  ff15 2851b000  call [EnterCriticalSection]
0061C568  8b8ee0010000   mov ecx, [esi + 0x1E0]
0061C56E  8b11           mov edx, [ecx]                  ; vtable
0061C570  8b4228         mov eax, [edx + 0x28]           ; +0x28 = IsAvailable
0061C573  57             push edi                        ; <- AS function name arrives in EDI
0061C574  ffd0           call eax
0061C576  84c0           test al, al
0061C578  741f           je 0x0061C599                   ; not present -> skip, return false
0061C57A  ...            mov ecx,[esi+0x1E0]; edx=[[ecx]+0x48]
0061C589  50 / 50 / 50 / 57   push presult, pargs, numArgs, name
0061C595  ffd2           call edx                        ; +0x48 = Invoke
0061C597  8ad8           mov bl, al
0061C599  a1b45f1701     mov eax, [0x01175FB4]
0061C59F  ff152c51b000   call [LeaveCriticalSection]
0061C5A5  8ac3 / 5b / c20c00   return bl ; ret 0xC
0061C5AB  32c0 / c20c00  xor al,al ; ret 0xC            ; the "no movie" early-out
```

Signature recovered from the disassembly (Ghidra cannot show it — see A6):

```
bool __usercall FUN_0061C550(
        ESI      = PgShellObject*   (movie holder; movie view at +0x1E0)
        EDI      = const char*      ActionScript function name
        [esp+4]  = GFxValue*        pargs
        [esp+8]  = UInt             numArgs
        [esp+0xC]= GFxValue*        presult (usually NULL)
) ; ret 0xC
```
That is byte-for-byte `GFxMovieRoot::Invoke(const char*, GFxValue* presult, const GFxValue* pargs, UInt numArgs)`.

**The 9 stolen bytes are recoverable by pattern, not by decryption.** 24 *inlined* copies of the same helper survive elsewhere, and every one of them opens with the identical guard, e.g. `0x008488A0`:
```
83bee001000000   cmp dword ptr [esi + 0x1E0], 0     ; 7 bytes
74 xx            je   <return false>                ; 2 bytes   = 9 bytes exactly
```
so the prologue is almost certainly `cmp [esi+0x1E0],0 / je 0x0061C5AB`. Flagged **inferred**.

`+0x28` = **IsAvailable**, `+0x48` = **Invoke**: confirmed at 26 independent sites (the funnel plus 24 inlined copies plus `0x0061C494`), always in the pair `+0x28` gated then `+0x48`.

**The lock is real but is not proven to be "the GFx lock".** `0x01175FB4` is a `CRITICAL_SECTION*` (zero at rest, `EnterCriticalSection`/`LeaveCriticalSection` from `KERNEL32.dll` via IAT `0x00B05128`/`0x00B0512C`). It has **109 references** image-wide, including the whole `0x005C1xxx`–`0x005C3xxx` LTI-input block — so it is a shell/GUI-wide lock that *happens to* cover the Invoke. Calling it "the GFx lock" over-specifies.

**`GFxValue` = 16 bytes, tag at +0, payload at +8.** Constructed via `push <ctor>; push <count>; push 0x10; lea ecx; call 0x00401860` (array-construct helper); then `mov dword [esp+X], <tag>` and `movsd [esp+X+8], xmm0`. Census of tag immediates stored before funnel calls: **`2`×133, `3`×80, `4`×56, `5`×14, `0`×28**. That is exactly Scaleform `GFxValue::ValueType {Undefined=0, Null=1, Boolean=2, Number=3, String=4, StringW=5}` — the map's "tags 2/3/4/5" is the used set, with `0` also used and `1` never.

### A6. The Invoke count is **250**, not 194 — and the funnel is not exclusive

Byte-scan of `.text` for `E8`/`E9 rel32` resolving to `0x0061C550`:

| | count |
|---|---|
| `E8` call sites | **248** |
| `E9` tail-jumps (`0x004CEB7C`, `0x006955A1`) | **2** |
| **total direct references** | **250** |
| other sections | 0 |

Backward-linear-sync decode recovers the EDI name at **247 of 250** sites: 218 from `mov edi, imm32`, 29 from `mov edi, [<.data slot>]` where the slot holds a statically-initialised name pointer (e.g. `[0x00D121D8]='ProfilesComplete'`, `[0x00D1223C]='multiplayerHost'`, 27 distinct slots). 3 remain indeterminate (`0x005BB3F8` via `[ebp-0x1C]`; `0x00614B69` and `0x00848D44` where my back-sync did not settle). **≈142 distinct ActionScript names.**

**Where "194" plausibly comes from:** Ghidra renders `0x0061C550` as `thunk_FUN_024b5390` and the decomp text contains **192** occurrences of that token. A Ghidra-derived xref count is in that neighbourhood; the binary says 250. Any figure near 194 is a Ghidra artefact, not ground truth.

**The funnel is not the only path.** Scanning for the inlined shape `mov r,[X+0x1E0] / mov r2,[r] / mov r3,[r2+0x28] / push <name> / call r3` finds **25 sites**, one of which is the funnel itself (`0x0061C568`) — so **24 genuine bypasses** with 14 distinct names, several of which never appear in the funnel list at all:

```
LTIInputControllerNames, LTIInputJoystickUpdateTable ×3, LTIInputKMUpdateTable ×2,
LTIInputKMSetActionName ×2, LTIInputSeeButtonsPushed, LTI_TOSText, LTISetUSZip,
addDropDownItem, controllerDisplay ×2, LTIInputJoystickMap ×3, LTIInputKMKeyMap ×4,
AddGPSLine, setTerritory
```
at `0x004FAADE, 0x004FB489, 0x005C19FB, 0x005C1AEE, 0x005C1BCE, 0x005C1C30, 0x005C1F9B, 0x005C206C, 0x005C20CA, 0x005C2A5D, 0x005C2B31, 0x005C2BF2, 0x005C2C65, 0x005C2D9D, 0x005C2E02, 0x005C35F0, 0x005C364D, 0x005C421A, 0x005C44AE, 0x0061C494, 0x00620C76, 0x0084879B, 0x0084882C, 0x008488B5`.

So: **≈274 engine→ActionScript Invoke sites total; the funnel carries 250 (~91%).** "ALL" is false.

### A7. The licensing "telemetry sink" — it is a Scaleform Invoke, and I can name it

`docs/mercs2_licensing_registration_map.md` (2026-07-01) lists as open: *"Exact data sink of `thunk_FUN_024b5390` (telemetry vs DiP vs Nucleus auth) — lands in the packed `.securom` region."* `thunk_FUN_024b5390` **is** `0x0061C550`.

`FUN_00847FE0`, disassembled directly:

```
0084802D  call 0x00401860              ; construct GFxValue[2], elem size 0x10
00848070  mov cl,[eax+0x00F7F1D0]      ; copy the ergc key buffer into a stack string
008480DD  mov eax, 4                   ; tag = 4  (VT_String) for BOTH records
008480F4  mov edx,[0x01176054]
0084810E  mov esi,[edx+0xA884]         ; the shell object (movie view at +0x1E0)
00848115  mov edi, 0x00BE3114          ; "LTIRegisterBox"
0084811A  call 0x0061C550              ; -> IsAvailable / Invoke
```
Pushes before the call: `0` (presult), `2` (numArgs), `lea ecx` (pargs). The second string arg comes from `.rdata` `0x00BE3104 / 0x00BE3114 / 0x00BE3124 / 0x00BE3134` — all of the form `[0x9f804e15]`, i.e. **string-database hash references** (localisation tokens), selected by the region compare at `0x00848043` (`cmp esi, 0xBBA/0xBBC`, `sub esi, 0xB4`).

`LTIRegisterBox` is defined in the shipped `shell/SHELL.gfx`.

**Conclusion:** `FUN_00847FE0` renders the CD-key and a localised label into the on-screen registration box. `FUN_0061C550` contains **only** `EnterCriticalSection → IsAvailable → Invoke → LeaveCriticalSection` — no socket, no file, no HTTP, no crypto. There is no data-exfiltration path *through this function*.

Residual, stated honestly: (a) the 9 stolen prologue bytes are encrypted in this dump — but anything hidden there must fit in 9 bytes and fall through to `0x0061C559`, which rules out any sink; (b) this clears **`thunk_FUN_024b5390`** specifically. It does **not** clear the rest of the licensing map's surface — the neighbouring `0x00848xxx` block genuinely handles `Account.EmailAddress`, `Account.BirthDate`, `Account.ParentalEmailAddress`, `GAME-MERCENARIES2-WIF`, and whatever ships those fields onward is a separate question I did not audit.

### A8. `LTIVideoSetVSync` vs `LTIVideoSetVsync` — two strings, **but not a defect**

Both strings exist, at different addresses, each referenced exactly once:

| string | VA | referenced from | containing fn | value pushed |
|---|---|---|---|---|
| `LTIVideoSetVSync` | `0x00BB6F90` | `0x005C09FC` | `0x005C0870` | `cmp byte [0x00DF672C],0 / sete al` → **inverted** |
| `LTIVideoSetVsync` | `0x00BB7398` | `0x005C3D94` | `0x005C37E0` = `LTIPauseItemChanged` | `movzx eax, byte [0x00DF672C]` → **raw** |

Same backing byte `0x00DF672C`. So the case mismatch *is* real in the exe. **But the shipped ActionScript defines both spellings, in different movies:**

* `shell/SHELL.gfx` → `LTIVideoSetVSync` (capital S), alongside `VSyncOn`, `VSyncOff`, `settingVSync`, `vsync_btn`.
* `pause_menu.gfx` → `LTIVideoSetVsync` (lower s), alongside `videoVsyncVar`.

`0x005C0870` (capital-S sender) is called from `0x005C0AE2` (inside `LTIVideoEnter`), `0x005C11C0` (`LTIVideoDefault`) and `0x005C55A2` — the **shell** options paths. `LTIPauseItemChanged` (lower-s sender) is the **pause-menu** path. Each engine path targets the movie that defines its spelling, and `IsAvailable` makes the mismatch harmless in the other direction.

**Verdict: NOT a silent no-op defect.** It is a naming inconsistency between two front-ends. *A real* inconsistency does exist and is more interesting: the two senders disagree on **polarity** — the shell sends `vsync == 0`, the pause menu sends `vsync`. One of the two menus must be displaying the setting backwards unless `SHELL.gfx` inverts it again in ActionScript (undetermined — I did not decompile the AS bytecode).

### A9. PDA support-quick-slot round trip

`docs/mercs2-luacd/src/resident/mrxguipda.lua`:
```lua
1540:  oPda.CustomData.oMapFlash:SetFlashEventHandler("LTIupdateSupportQuickSlot", _LTIupdateSupportQuickSlot, {})
1857:  function _LTIupdateSupportQuickSlot(oFlash, sParm)
1858:    LTILibName.LTIupdateSupportQuickSlot(sParm)
```
`LTILibName.LTIupdateSupportQuickSlot` → `0x006D5640` — the shared retail-stripped stub (A3). Additionally, `LTIupdateSupportQuickSlot` does **not** appear as an identifier in **any** of the 67+ extracted `.gfx` movies, including `Map.gfx` (the movie the handler is attached to) and `SUPPORT.gfx`. So the round trip is dead at **both** ends on PC: Flash never raises the event and the cfunc is a stub.

Same for `LTIMovieStart` → stub, and it is not called from Lua (A4) and not present in any `.gfx`.

Caveats: `0x006D5640`'s no-op nature is inferred (A3); and `output/gfx_movies/` is a prior extraction whose completeness against `vz.wad`/`shell.wad` I did not re-verify (the WADs are compressed, so a raw grep returns 0 for every string and proves nothing).

### A10. Settings block: three copies, and the `group*10 + value` decode

`LTIVideoAdvanceEnter` (`0x005C1210`) — snapshot **live → +0x48**:
```
mov ecx, 0x12 ; mov esi, 0x00DF6700 ; mov edi, 0x00DF6748 ; rep movsd
mov byte ptr [0x01175F2A], 1
```
`LTIVideoEnter` (`0x005C0A20`) — restore, choosing the source by that flag:
```
cmp byte [0x01175F2A], 0
 je  -> rep movsd 0x12 from 0x00DFC320 -> 0x00DF6700      ; committed  -> live
 else if [0x01175F2B] != 0
     -> rep movsd 0x12 from 0x00DF6748 -> 0x00DF6700      ; undo snap  -> live
```
`LTIVideoApplyChanges` (`0x005C1140`): `mov eax,0x00DF6700; call 0x0074C7A0` (apply the live block) then `mov ecx,0x00DFC320; call 0x00753D40` (persist the committed block).

Block size = `0x12` dwords = **0x48 bytes**, which is exactly why the undo copy sits at base+0x48 — they are adjacent. `0x00DFC320 − 0x00DF6700 = 0x5C20`. **All three copies and both offsets confirmed.** Roles: `0x00DF6700` live · `0x00DF6748` (+0x48) advanced-menu undo snapshot · `0x00DFC320` (+0x5C20) committed/persisted. References: 14 to the live base, 15 to the committed base.

(`LTIVideoCancel` `0x005C11D0` does **not** restore the block; it only recomputes gamma from `[0x00DFC340]` and calls `0x0074AE20`.)

**`LTIVideoSwitchOpt1` (`0x005C1240`) — `group*10 + value` confirmed:**
```
cmp eax, 0x14 ; jge ...   -> group 1 : sub eax,0x0A ; cmp eax,1 ; sete -> [0x00DF6724] and [0x00DFC344]
cmp eax, 0x1E ; jge ...   -> group 2 : sub eax,0x14 ; clamp 0..2      -> [0x00DF6737] and [0x00DFC357]
cmp eax, 0x28 ; jge ...   -> group 3 : sub eax,0x1E                   -> [0x00DF6738] and [0x00DFC358] (+ [0x00D2AEFC])
cmp eax, 0x32 ; jge ...   -> group 4 : sub eax,0x28 ; cmp 1 ; sete    -> [0x00DF6740] and [0x00DFC360]
cmp eax, 0x3C ; jge ...   -> group 5 : sub eax,0x32                   -> [0x00DF6741] and [0x00DFC361]
cmp eax, 0x46 ; jge ...   -> group 6 : sub eax,0x3C ...
```
Every branch writes the **live** byte and the **committed** byte (`+0x5C20`) together. The argument is fetched by `call 0x0059D850` (a Lua get-integer helper) which returns false → the function returns `1` (one Lua return value) on a type error.

### A11. `docs/ui/main_menu_structure.md` §5 — independently audited

1. **Title "LTI (Lua To Interface)"** — the expansion appears nowhere in any primary source (A2). Unsupported gloss.
2. **"Registration Table located at `0x00B99D00`"** — **wrong**. The table starts at `0x00B99C78`. `(0x00B99D00 − 0x00B99C78)/8 = 17`, and `0x00B99D00` holds entry 17, `LTIVideoAdvanceDefault`. **Off by exactly 17 entries.**
3. **8 of the 15 string VAs in the "Shell/Menu" table are wrong.** Checked byte-for-byte against `.rdata`:

| claimed | VA | actually at that VA |
|---|---|---|
| `LTIProfileExit` | `0x00BB6A4C` | `"rofileExit"` (real: `0x00BB6A48`) |
| `LTIProfileOnlinePlay` | `0x00BBC520` | `"ame"` |
| `LTIgotoGame` | `0x00BBC510` | `"592]"` |
| `LTIPrecacheDone` | `0x00BB6A00` | `"hoseOnline"` (real: `0x00BB6A24`) |
| `LTIPrecacheSmokeDone` | `0x00BB69EC` | `"etDateFormat"` (real: `0x00BB6A0C`) |
| `LTIChoseOnline` | `0x00BB69DC` | `"LTICamera"` (real: `0x00BB69FC`) |
| `LTIPauseItemChanged` | `0x00BB69C4` | `"pdateSupportQuickSlot"` (real: `0x00BB6A34`) |
| `LTICamera` | `0x00BB69A4` | `"%02d"` (real: `0x00BB69DC`) |

(`ChangeShellState`, `LTIPressStart`, `LTIProfileEnter`, `LTIGetStartButton`, `AdvAccept`, `FirstRun` check out.)
4. **Category error.** §5 presents `LTIVideoSetVsync`, `LTIVideoSetSwitchOpt1..8`, `LTIAudio*Volume`, `LTIVideoSetMode`, `LTISetGraphicDetail`, `LTIvideoSubtitles`, `LTIInputSet*`, `LTIPressStart`, `LTIgotoGame`, `LTIAllowFlashMouse`, `AdvAccept`, … as "LTI Callback Functions" registered in Lua. **None of them are in the registration table.** They are *ActionScript* function names invoked **engine → Flash** through `0x0061C550`. §5 merges the two opposite directions of the same interface into one list.

### A12. What I could NOT check

* `0x006D5640`'s body (encrypted). No-op status is inferred from 61-way ICF folding with the known-stripped developer surface.
* `LTIVideoAdvanceDefault` (`0x005C13A0`) body — SecuROM-stolen to `0x024E6220`, still encrypted; the code after the island at `0x005C13B0` uses `ret 4` while `LTIVideoDefault` calls it cdecl-style (`push 0 / call / add esp,4`), so I do **not** believe that island is its continuation.
* `0x0061C550`'s 9 stolen prologue bytes — reconstructed by pattern, not decrypted.
* No ActionScript **bytecode** was decompiled; `.gfx` evidence here is identifier-string presence only. So the VSync polarity question (A8) is open.
* `output/gfx_movies/` completeness vs the shipped WADs was not re-verified.
* No live run / x32dbg. Everything is static.

---

## Phase B — verdicts

The map is, on the whole, **unusually good**: the table walk, the registrar record, the LTI-module
identification, the settings-block triad, the `group*10+value` decode, the small-cfunc bodies, and
the Lua traffic census all reproduce exactly against the binary — several of them byte-for-byte,
including things I had no prior reason to expect (all seven `[Render]` key strings, the 220 call
total, the 27/25 Ghidra-body split, the 62 shared-stub bindings). Its §10 corrections to
`main_menu_structure.md` are correct and its licensing conclusion is right.

Its headline is nevertheless wrong in both directions, its SecuROM offsets are wrong, and one
"defect" it half-raises is not one.

### Summary

| Verdict | Count |
|---|---|
| CONFIRMED | 33 |
| CONTRADICTED | 5 |
| OVERSTATED | 6 |
| UNVERIFIABLE | 8 |
| MISSING | 7 |

---

### CONTRADICTED

**C1 — THE HEADLINE. "194 call sites across 63 functions" and "the single funnel for **all 194**
engine→AS calls in the exe" (§0, §2.1, §5, §10).** Both halves fail.

*The count.* Byte-scanning `.text` for `E8`/`E9 rel32 → 0x0061C550` gives **250** references —
**248 calls + 2 tail-jumps** (`0x004CEB7C`, `0x006955A1`) — in **74** distinct containing functions.
194/63 is a **Ghidra artefact**: parsing the decomp text for `thunk_FUN_024b5390(` gives **192**
occurrences in **62** functions, which is the same neighbourhood. The map opens by saying it
disassembled the image *because Ghidra was wrong here*, then reports Ghidra's count as fact for the
rest of the document.

*"All".* The compiler **inlined** the same helper in several translation units. Scanning for the
shape `mov r,[X+0x1E0] / mov r2,[r] / mov r3,[r2+0x28] / push <name> / call r3` finds **25** sites,
one of which is the funnel itself → **24 genuine bypasses**, at
`0x004FAADE, 0x004FB489, 0x005C19FB, 0x005C1AEE, 0x005C1BCE, 0x005C1C30, 0x005C1F9B, 0x005C206C,
0x005C20CA, 0x005C2A5D, 0x005C2B31, 0x005C2BF2, 0x005C2C65, 0x005C2D9D, 0x005C2E02, 0x005C35F0,
0x005C364D, 0x005C421A, 0x005C44AE, 0x0061C494, 0x00620C76, 0x0084879B, 0x0084882C, 0x008488B5`,
carrying **14** names including `LTIInputControllerNames`, `LTIInputKMUpdateTable`,
`LTIInputKMSetActionName`, `LTIInputJoystickUpdateTable`, `LTIInputSeeButtonsPushed`, `LTI_TOSText`,
`LTISetUSZip`, `controllerDisplay`, `addDropDownItem`. **Total ≈274 Invoke sites; the funnel carries
250 (~91%).**

This propagates into §6: several rows are marked ✔ "proven by reading the `mov edi, <str>`
immediately before a `call 0x0061C550`", but their listed sources **inline** the sequence and push
the name as an immediate operand instead — `LTIInputControllerNames` / `LTIInputJoystickUpdateTable`
from `FUN_005C2970`, `LTIInputKMUpdateTable` / `LTIInputKMSetActionName` from `FUN_005C1900`,
`LTIInputSeeButtonsPushed` from `FUN_004FB270`. Those ✔ marks cannot be what they say they are.

And it propagates into §11.5 ("One funnel, name-gated"): a reimplementation built to that rule will
silently drop 24 call sites.

**C2 — The SecuROM split offsets are wrong, and the map contradicts itself.** The preamble says "the
first **6 bytes** … are replaced by `jmp dword [<Sdata slot>]` and the rest of the body is left
intact immediately after"; the same paragraph then says "the tail is fully readable at **`entry+0x12`**";
§0.5, §2.1 and §12 all pin the resume at **`0x0061C562`**. Measured:

```
0061C550  ff 25 70 55 45 02      jmp dword ptr [0x02455570]     ; 6 bytes
0061C556  62 74 52               <-- 3 more bytes of the 9 stolen (0x0061C550..0x0061C558)
0061C559  a1 b4 5f 17 01         mov eax, [0x01175FB4]          ; <-- BODY RESUMES HERE
0061C55E  53                     push ebx
0061C55F  50                     push eax
0061C560  32 db                  xor bl, bl
0061C562  ff 15 28 51 b0 00      call [EnterCriticalSection]    ; the map's claimed resume point
```
**9 bytes stolen, body resumes at `0x0061C559`** — not 6, not `0x12`. Corroboration that `0x0061C559`
is the true boundary: the early-out at `0x0061C5AB` is `xor al,al / ret 0xC` with **no `pop ebx`**,
while the normal exit at `0x0061C5A7` does `pop ebx` — so the stolen `je` must branch *before* the
`push ebx` at `0x0061C55E`, which places the entire stolen region above `0x0061C559`. `0x0061C562`
is merely where a naive linear disassembler resyncs.

Also, §2.1's asm listing jumps from `0061c57e mov ecx,[esi+0x1e0]` straight to
`0061c586 mov edx,[edx+0x48]`, silently dropping `0061c584 mov edx,[ecx]`. As printed, `edx` looks
like a stale value carried from the `IsAvailable` path; it is a fresh vtable load.

**C3 — The `LtiRender` string VAs are wrong.** §1.1 gives `LtiRender::RenderSystem::ReadSurfaceData`
at **`0x007D470C`** and `…WriteSurfaceData` at **`0x007D4764`**. They are at **`0x00BD470C`** and
**`0x00BD4764`** (`.rdata`). `0x007D470C` is inside `.text` and holds machine code
(`8b 4c 24 08 51 83 …`). A `BD`→`7D` digit slip, repeated twice. The finding itself is correct; the
citations are unusable as printed.

**C4 — Two cfuncs described as "tail-calls" have substantial bodies.** §3 rows #26 and #35 grade
`LTIInputKMApplyChanges` (`0x005C1D00`) and `LTIInputJoystickApplyChanges` (`0x005C33F0`) as **○
binding-only (open)**, confidence **M**, "tail-calls `FUN_004FBBA0`" / "`FUN_004FBC60`". Both have
readable loops:

```
005C1D00  mov edx,[0x00ED3B1C] ; xor eax,eax ; push esi
005C1D10  cmp eax, 0x17                     ; 24 bindable actions
005C1D13  mov ecx,[eax*8 + 0x00EDAE60]      ; the keymap array the map itself pins at +0xEA0/i*8
...
005C33F0  push ebx ; push esi ; mov esi,[0x00ED3B1C] ; xor eax,eax
005C3400  mov ecx,[eax*4 + 0x00B9BCB0]
005C3407  movzx edx, byte ptr [eax + 0x00EDAD28]
```
These are commit loops, not tail calls. Same for `LTIInputGeneralOptions` (`0x005C1600`, §3 #19,
also ○/M): it fetches a Lua string via `FUN_0059D8E0` and runs a `0x26`-iteration compare loop. The
map's own trap note ("binding-only usually means no static caller — disassemble it") applies to its
own §9.1, and the recovery needed no forcing script.

**C5 — The VSync "silent no-op" is not a defect.** §2.2 and §9.2 raise it (hedged: "*If*
`shell.gfx`/`pause_menu` define only one spelling…", "the movie may define both"). Ground truth from
the shipped movies:

| spelling | engine sender | containing fn | defined in |
|---|---|---|---|
| `LTIVideoSetVSync` | `0x005C09FC` | `FUN_005C0870` (shell video page) | **`shell/SHELL.gfx`** ✔ |
| `LTIVideoSetVsync` | `0x005C3D94` | `FUN_005C37E0` (pause dispatcher) | **`pause_menu.gfx`** ✔ |

Each engine path drives the movie that defines its spelling; `SHELL.gfx` also carries `VSyncOn`,
`VSyncOff`, `settingVSync`, `vsync_btn`. **Close §9.2 as "not a bug".** The map's caution was correct
in kind, but the item should not survive into the fix-pack backlog.

*(What the map missed here is the actual anomaly — see M3.)*

---

### OVERSTATED

**O1 — "194" is presented as binary fact.** Even setting aside C1's "all", the number is Ghidra's,
in a document whose §0 premise is that Ghidra got this function wrong. It appears four times
unqualified, including in the §10 correction proposed for
`docs/data/scaleform_gfx_function_map.json`, which would import the error into a data file.

**O2 — §5's "62 of the 194".** The **numerator is exactly right** — `FUN_005C37E0` contains **62**
direct calls to `0x0061C550`, confirmed by byte scan, and it is comfortably the busiest site
(next: `0x00616C40` with 32, `FUN_005C06C0` with 9, `FUN_005C0870` with 8). Only the denominator is
wrong: 62 of **250**.

**O3 — §3 rows #0 and #50 grade "shared no-op stub — not implemented on PC" at H.** The *address
sharing* is H; the *behaviour* is not readable — `0x006D5640` contains only `e9 7b ca 5f 6f`
(a jump out of the mapped image, fixed up at load). §0.5 grades this correctly ("H (count) / M
(mechanism)") and §8.1 says so explicitly; §3 then asserts H. Inconsistent grading between three
sections of the same document, resolving toward the strongest claim.

**O4 — "the **global GFx** critical section `DAT_01175FB4`".** It is a genuine `CRITICAL_SECTION*`
(`KERNEL32` IAT `0x00B05128`/`0x00B0512C` confirmed by import-directory parse), but it has **109**
references image-wide, blanketing the whole `0x005C1xxx`–`0x005C3xxx` LTI input block, not just GFx
entry points. "Global GUI/shell lock that also covers Invoke" is what the evidence supports. (The map
cites this from `scaleform_gfx_class_map.md` rather than deriving it, so the over-specification is
inherited.)

**O5 — "62 bindings across all 60 binding tables" vs the registrar's population.** Confirmed **as
stated**: `mods/lua_trace_asi/reference/binding_map.json` has 60 tables / 1357 entries, of which
**62** point at `0x006D5640`, spread over 13 tables. But the `.data` **registrar** array registers
only **31** Lua globals / **1103** entries, of which **61** are the stub. The two populations differ
(the JSON includes sub-tables and metatables that the registrar does not walk). The map uses "60
binding tables" and "the registrar array" interchangeably; they are not the same object.

**O6 — "All **218** `LTI`-containing strings" (§1.2).** I count **172** printable runs containing
`LTI` in the image. The gap is almost certainly a different string-extraction rule (minimum length,
overlapping runs, `.securom` inclusion). The *conclusion* — no expansion string exists — I verified
independently and confirm; the number is not reproducible as stated.

---

### UNVERIFIABLE — and what would settle each

**U1 — "`LTIVideoAdvanceDefault`'s body resumes at `0x005C13B0`" (§3 #17, §9.1, §12).** Ghidra
assigns `size=32` to `0x005C13A0`, so `0x005C13B0` *is* inside its extent, and the caller arithmetic
is consistent (`0x005C11B8: push 0 / call 0x005C13A0` with a `ret 4` at `0x005C1425`, the trailing
`add esp,4` cleaning the earlier `push edi`). **But** the code at `0x005C13B0` is itself SecuROM
control-flow-scrambled — `push 0x5C13D3 / push 0x54B370 / ret` and `push 0x5C144D / jmp 0x567B10`
trampolines with encrypted islands between them — and it touches **none** of the `DAT_00DF67xx`
settings bytes that an "advanced defaults" reset must write. *Settle:* decrypt `0x024E6220` (the real
stolen body, still self-encrypting in this dump: `push/push/pushfd/sub [esp+4],0x12CD4/popfd/ret`),
or a one-shot bp at `0x005C13A0`.

**U2 — `0x006D5640` returns 0.** *Settle:* one-shot bp; or dump the resolved target after SecuROM
fixes up the `E9`. Circumstantially very strong: 61 of its 62 siblings are the retail-stripped dev
surface (`Debug.Printf/Assert/LogError/GetCallstack`, all 15 `Junk.*`, `Ai.Plan*`, `Sound._SummonEd`,
`Sys.WriteToConsole`), i.e. `/OPT:ICF` folded them because their bodies are identical.

**U3 — `FUN_0061C550`'s 9 stolen bytes.** Reconstructed as `cmp dword [esi+0x1E0],0 / je 0x0061C5AB`
(exactly 9 bytes) from the 24 inlined copies plus the `pop ebx` asymmetry in C2. *Settle:* decrypt
`0x024B5390`, or bp at `0x0061C559`.

**U4 — The whole Bink section (§7).** Stride `0x16C`, base `DAT_017C64F8`, end guard `0x017C6AA7`,
the inline FNV-1a with `|0x20` fold and `^0x2A`, `"%sMovies/%s.bik"` + `"%sMovies/%s.ogg"`,
`binkw32!_BinkPause@8` at IAT `0x00B055FC`, and the `+0x30/+0x38/+0x148/+0x149/+0x14A/+0x14E` record
fields — **not re-derived this pass.** I confirmed only that the four `Movie` cfuncs have real
bodies and that `Movie.Stop` calls `0x005C63E0`. *Settle:* read `FUN_00709640`/`FUN_00709CB0` and
parse the import directory for `binkw32`.

**U5 — §5's key vocabulary.** 18 control keys and 30 `key=value` keys read "verbatim from the
`_stricmp` chain". Not re-derived. *Settle:* walk the `_stricmp` chain in `FUN_005C37E0`.

**U6 — §4's non-`SwitchOpt1` field offsets** (`+0x08`/`+0x0C` mode components at M, `+0x14` refresh,
`+0x19` fullscreen, `+0x20` gamma, `+0x28` view distance, `+0x44` not-first-run). I re-derived
`+0x24/+0x37/+0x38/+0x40/+0x41/+0x42/+0x43` exactly from `FUN_005C1240`, and `+0x20`
(`DAT_00DFC340`) is consistent with `LTIVideoCancel`. The rest stand on the map's own reading.

**U7 — `LTIVideoSetGamma` = `(i64)(1.5 − f*0.01)`.** Spot-consistent (`FUN_0059D7C0` float fetch,
`mulss [0x00B97EEC]`, `fnstcw` int conversion), constants not re-derived.

**U8 — The VSync polarity question (M3).** Needs the `pause_menu.gfx` / `SHELL.gfx` ActionScript
**bytecode** decompiled; identifier-string presence cannot answer it.

---

### MISSING

**M1 — The 24 inlined Invoke sites are absent entirely.** See C1. This is the single most
consequential omission: it is a whole second dispatch shape inside functions the map already
documents, and §11.5 tells the reimpl there is only one.

**M2 — 29 funnel call sites take the AS name from a `.data` slot, not an immediate.** `mov edi,
dword ptr [0x00D121xx]`, **27 distinct slots**, all statically initialised to string pointers:
`AddProfile`, `ProfilesComplete`, `EnableUsingFakeProfile`, `loadProfile`, `serverOnline`,
`serverAccept`, `serverEAagreement`, `profileCharacter`, `joingameSavegame`,
`joingameFilterMap/Mission/FriendlyFire`, `videoBrightness`, `gameSensitivity`, `gameInvert`,
`gameRumble`, `audioSFX/Music/Dialog`, `addSaveGame`, `videoWidescreen`, `maximumProfiles`,
`multiplayerHost`, `multiplayerClient`, `player2Name`. A `mov edi, <literal>` harvest — which is what
§12 says was done — cannot see any of them. §6's vocabulary is missing this whole group.

**M3 — The VSync *polarity* mismatch, which is the real anomaly.** Both senders read the same byte
`[0x00DF672C]`, and they disagree:

```
005C09EA  cmp byte ptr [0x00DF672C], al   ; al = 0
005C09F2  sete al                          ; -> sends (vsync == 0)   INVERTED   ["LTIVideoSetVSync"]
...
005C3D7D  movzx eax, byte ptr [0x00DF672C] ; -> sends  vsync          RAW        ["LTIVideoSetVsync"]
```
Unless `SHELL.gfx` re-inverts in ActionScript, one of the two menus displays the VSync checkbox
backwards. That is a plausible real fix-pack entry — and it is exactly what the map's §2.2 walked
past while chasing the (non-)spelling bug.

**M4 — `LTIupdateSupportQuickSlot` does not exist in any shipped `.gfx`.** Not in `Map.gfx` — the
movie `mrxguipda.lua:1540` attaches the handler to — nor in `SUPPORT.gfx` nor any of the other 65+
extracted movies. So the round trip is dead at **both** ends, not just the engine end. This answers
§9.5 ("does the PDA quick-slot visibly fail? … the AS side may already do the work locally") with a
static negative: **the AS side never raises the event**, so nothing is lost by the stub and the
fix-pack entry §8.2 proposes has no user-visible symptom to fix. Same story for `LTIMovieStart`.

**M5 — The registrar consumer loop exists and is at `0x005A2D38`–`0x005A2DF7`.** §9.8 asks for it and
says "no `.text` reference to the table VAs exists, so it is data-driven". True of the *table* VAs,
but the **array base** `0x00DFD478` has four `.text` references, and the loop is plain:
`cmp [0x00DFD478],0` guard → `mov edi,0x00DFD478` → per-record `call 0x005A2FD0` → `lea esi,[esi+esi*2]
/ add esi,esi / add esi,esi` (×12) → `cmp [esi+0x00DFD478],0`. `0x005A2FD0` is a full SecuROM steal
whose stolen body at `0x02471B40` **is decrypted in this dump** and calls back into `0x005A2E40` /
`0x005A2E90` — the `{name,0xFFFFFFFF}`/`0xFFFFFFFE` marker-row walker. This closes §9.8 without a
debugger and would also close `scripting_host_binding_code_map.md` §1.2/§6.

**M6 — The AS function behind the licensing Invoke is `LTIRegisterBox`, and it ships.** §10 stops at
"Invokes it onto the EA-account **Scaleform screen**". `FUN_00847FE0` sets `mov edi, 0x00BE3114` =
`"LTIRegisterBox"`, builds **2** `GFxValue`s of tag **4** (`VT_String`) — one copied from the ergc
buffer `0x00F7F1D0`, one a localisation token — and calls `0x0061C550` with `presult=NULL`,
`numArgs=2`. `LTIRegisterBox` is present in the shipped `shell/SHELL.gfx`. Naming it is what turns
"probably a UI call" into a checkable claim. (§10 also attributes `LTIRegisterBox` to `FUN_008486F0`;
it is `FUN_00847FE0`. `LTISetUSZip` and `LTI_TOSText` are the ones in `FUN_008486F0` — and both are
*inlined*, not funnel calls.)

**M7 — The `Movie` table is 4-mod-8 aligned, and a float π sits between the tables.** `0x00B99BBC ≡ 4
(mod 8)`, and every table in this `.rdata` run is preceded by `{0,0}` plus a stray `0x40490FDB`
(3.14159f) the linker interleaved. Anyone re-walking `.rdata` on an 8-byte grid from a neighbouring
table will miss `Movie` entirely. Worth one line in §3.1.

---

### The two contested addresses — final answer

**`0x00DFD478` (31 rows) is the base. `0x00DFD514` (18 rows) is row 13 of the same array.**

* Stride is 12, proven by the loop's `lea esi,[esi+esi*2] / add esi,esi / add esi,esi`.
* `(0x00DFD514 − 0x00DFD478)/12 = 13`, and record 13 is `{"Graphics", 0x00B9A4D0, NULL}`.
* Rows 13…30 inclusive = 18 — which is where "18 records" comes from.
* `0x00DFD478` has **4** `.text` references (`0x005A2D3A`, `0x005A2D49`, `0x005A2DED`, `0x005A2DF3`,
  plus `0x005A2D55` to `+4`); `0x00DFD514` has **zero**.
* The terminator is `{0,0,0}` at `0x00DFD5EC`, immediately after the `LTILibName` record at
  `0x00DFD5E0`.

So `lti_movie_pda_code_map.md` §0.5 / §1.3 ("`.data` at `0x00DFD514` holds an **18-record** registrar
array") is **a correct description of a mid-array slice presented as the array**, and the sibling
map's `0x00DFD478` / 31 rows is right. Both are views of one structure; only one of them is the base.
Everything §1.3 concludes *from* it — that the last record is `0x00DFD5E0`, that the global is
`LTILibName`, that `Movie` owns `0x00B99BBC`, and the §11.1 corrections to `mercs2_script` about
`Report`/`ObjectFilter` — is unaffected and correct. §11.1's list of settled names is also
**incomplete**: the array settles all 31, including `_SYS`, `Sys`, `Pg`, `Object`, `Player`, `Event`,
`Ai`, `Human`, `Debug`, `Vehicle`, `Airstrike`, `Gui`, `_GuiInternal`, which it does not mention.

---

### Verdict on the map

Adopt it, with C1–C5 fixed. The parts a reimplementation depends on most — the binding surface, the
settings triad, the option decode, the Lua traffic, the `LTILibName` global — are correct and
verifiable. The parts that would mislead are the Invoke funnel's exclusivity and count, the SecuROM
resume offset, and a fix-pack entry (§9.2) that should be closed as not-a-bug.

---

# Pass 2 — closing the open register

**Mandate:** close every item Pass 1 did not explicitly CONFIRM (5 CONTRADICTED · 6 OVERSTATED ·
8 UNVERIFIABLE · 7 MISSING) plus its §A12 "what I could not check". Pass 1's verdicts were treated
as untrusted and re-derived. Nothing is left open without demonstrated static exhaustion **and** a
runtime recipe.

**Result: 32 of the 34 register items are CLOSED. 2 remain open (U1, U3), both with the map's
answer disproved, the residue bounded, and a one-shot-breakpoint recipe.**

## Artifacts Pass 1 did not use — and what each unlocked

| Artifact | What it settled |
|---|---|
| **The v1.1 build family** — `output/_ghidra/securom_dump/genuine_patched_unpacked.exe`, `output/mercs2_v1.1_uncracked.exe`, `game-files/Mercenaries2.patched.uncracked.exe` (53,944,080–53,944,320 B) | A *sibling oracle*. Pass 1 and the map both treat it only as "a DIFFERENT BUILD — trap". It is: the code is at different addresses and is a different compile. But **`LTILibName` sits at the same `0x00B99C78` with the same 52 entries in the same order**, so it is a byte-level control for every claim about this table — and its `.text` is decrypted where the dump's is stolen. |
| **`mercs2_nodrm_v2/v3.exe`** (built from the *on-disk* RELOADED-decrypted exe, not the dump) | Settled `0x006D5640` outright (U2). |
| **`.securom` as relocated game code** (per `securom_unwrap_devirtualization.md`) | Located `LTIVideoAdvanceDefault`'s displaced body region (U1). |
| **A purpose-written AVM1/AS2 disassembler** over all **83** shipped `.gfx` | Settled the VSync polarity (U8/M3) and the AS vocabulary (§6 of the map). |
| **Import-directory parse + D3D9 constant identification** | Turned the bare byte `[0x00DF672C]` into a *named, semantically anchored* field. |
| **`docs/game_config/Mercs2.ini`** (shipped, authoritative) | Independent data-side check on §4 / §4.1 / §7. |

**Note on `mercs2_unpacked.exe` as "the" primary source.** It is a memory dump, and at least one
address in this map's scope (`0x006D5640`) holds a **runtime hot-patch artifact** rather than retail
bytes. Pass 1 treated the dump as authoritative and inherited that corruption. Where the dump and
the on-disk images disagree, the on-disk image wins.

---

## 1. The open register — item by item

### CONTRADICTED (5/5 closed)

**C1 — the Invoke count and "all". CONFIRMED, and extended.**
Re-derived from scratch and then *validated*, which Pass 1 did not do: a raw byte scan gives 250
`E8`/`E9 rel32 -> 0x0061C550` hits (248 + 2 at `0x004CEB7C`, `0x006955A1`), 0 outside `.text`; linear
disassembly from every recovered function start then confirms **250 of 250 as real instructions,
0 false positives**. The map's 194 is a Ghidra artefact. See §2 for the corrected totals — Pass 1's
"24 inlined bypasses / ~274 total / 91%" is itself an undercount.

**C2 — the SecuROM split offsets. CONFIRMED, and sharpened: it is 7 bytes stolen, not 9.**
Pass 1 said "9 bytes stolen (`0x0061C550`–`0x0061C558`), body resumes `0x0061C559`". Two of those
nine are **not stolen — they are original code, and they are readable**:

```
        DUMP build (fn @0x0061C550)              V1.1 build (fn @0x0061C470)
+0..+5  ff 25 70 55 45 02  jmp [0x02455570]      ff 25 08 d5 4c 02  jmp [0x024CD508]   <- SecuROM
+6      62                 (fill)                54                 (fill)             <- differs
+7..+8  74 52              je +0x52              74 52              je +0x52           <- IDENTICAL
+9      a1 b4 5f 17 01     mov eax,[0x01175FB4]  a1 b4 4f 17 01     mov eax,[0x01174FB4]
```

The two builds were wrapped independently: the slot address differs, the fill byte at +6 differs —
and `74 52` is **byte-identical in both**. In each build the branch resolves to that build's own
`xor al,al / ret 0xC` early-out (`0x0061C5AB` and `0x0061C4CB` respectively, both verified). Two
independent wraps cannot coincidentally produce the same rel8 pointing at the same semantic target.
**So: 7 bytes replaced (`entry+0..+6`), `je <return-false>` survives at `entry+7`, body resumes at
`entry+9`.** The map's "6 bytes" / "`entry+0x12`" / "`0x0061C562`" are all wrong; Pass 1's
`0x0061C559` is right; Pass 1's "9 stolen" is right about the *gap* but wrong about what is
unreadable. Pass 1's dropped `0061c584 mov edx,[ecx]` is also confirmed.

**C3 — the `LtiRender` string VAs. CONFIRMED.** `LtiRender::RenderSystem::ReadSurfaceData` =
**`0x00BD470C`**, `...WriteSurfaceData` = **`0x00BD4764`**, both `.rdata`. `0x007D470C` is `.text` and
holds `4c 24 08 51 83 c7 08 89`. A `BD`->`7D` slip, twice.

**C4 — "tail-calls" that are commit loops. CONFIRMED twice over.** Re-read in the dump *and* in the
v1.1 build, where all three have ordinary unstolen prologues:
`LTIInputKMApplyChanges` v1.1 `0x005C1D20` = `8b 15 1c 2b ed 00 33 c0 56 8d...` (`mov edx,[0x00ED2B1C]`
— the v1.1 twin of `[0x00ED3B1C]`, data shifted -0x1000 in that build);
`LTIInputJoystickApplyChanges` v1.1 `0x005C3400` = `53 56 8b 35 1c 2b ed 00 33 c0...`;
`LTIInputGeneralOptions` v1.1 `0x005C1620` = `81 ec 80 00 00 00 56 8d 44 24...` (a 0x80-byte frame).
None is a tail call. §9.1's "three open bodies" is closed.

**C5 — the VSync spelling is not a defect. CONFIRMED** (see §3; the AS census reproduces Pass 1's
finding exactly and adds the byte-level completeness proof Pass 1 lacked).

### OVERSTATED (6/6 closed)

**O1 — "194" as fact. CONFIRMED.** 250, not 194.

**O2 — "62 of the 194". CONFIRMED.** `FUN_005C37E0` contains exactly **62** `call 0x0061C550`,
re-counted. Numerator right, denominator wrong (62 of 250). Pass 1's "next: `0x00616C40` with 32"
and my "`0x00616CC0` with 31" are *both* attribution artefacts — `FUN_00616CC0` is a 12-byte
indirect thunk (`jmp [_DAT_024501BC]`) and Ghidra recovered no starts for ~1.7 KB after it. **The
"distinct containing functions" figure (63 / 73 / 74 depending on the boundary model) is not a
stable quantity and should not be quoted as one.** The site count is.

**O3 — `0x006D5640` graded H in §3 but M in §0.5/§8.1. CONFIRMED as an inconsistency, and now
moot: the behaviour is PROVEN (see U2), so H is the correct grade — but for the opposite reason
than the map gives.**

**O4 — "the global GFx critical section". CONFIRMED as over-specified.** `[0x00B05128]` /
`[0x00B0512C]` are `KERNEL32!EnterCriticalSection` / `LeaveCriticalSection` (import-directory parse,
by name). Pass 1's 109 image-wide references stand. Adding to it:
`scaleform_gfx_function_map.json`'s `0060e4a0` entry reads `loader at *(DAT_01175fb4+0x234)+4` —
i.e. it treats `DAT_01175FB4` as a **pointer to the GFx singleton**, whose head happens to be the
CRITICAL_SECTION. "Global GUI/shell lock at the head of the GFx singleton" is what is supported.

**O5 — "62 bindings across all 60 binding tables" vs the registrar. CONFIRMED, both halves
re-derived.** `binding_map.json` = 60 tables / **1357** entries / **62** pointing at `0x006D5640`,
spread over **13** tables (`Ai` 15, `Junk` 15, `Sound` 9, `Debug` 5, `Pg` 2, `ObjectState` 2,
`Net` 2, `LTILibName` 2, plus `Gui`, `Sys`, `Object`, `Graphics` and stdlib `print`). The `.data`
registrar registers **31** globals / **1103** cfuncs. Two different populations; the map uses the two
terms interchangeably.

**O6 — "218 `LTI`-containing strings". CONFIRMED not reproducible.** Independent extraction
(printable runs >= 4 bytes, whole image): **172** runs contain `LTI` — 171 in `.rdata`, 1 in
`Srdata`. I reproduce Pass 1's 172 exactly. (Case-insensitive `lti` gives 415, which is not 218
either.) The *conclusion* — no expansion string exists — is confirmed a third time.

### UNVERIFIABLE (6 of 8 closed; U1 and U3 remain open with the map's answer disproved)

**U1 — `LTIVideoAdvanceDefault`'s body. STILL OPEN, but the map's answer is CONTRADICTED.**

Three new facts:

1. **`0x005C13B0` is not the continuation.** The code there (`cmp dword [esi+0x710],0` /
   `cmp byte [esi+0x718],bl` / `lea ecx,[esi+0x294]` / `cmp byte [esi+0x1E6],0` / `ret 4`) carries the
   signature `83 be 10 07 00 00 00 7e`. In the **v1.1 build that byte sequence lives at
   `0x005F8A1E`** — ~0x2C000 away from where that build puts `LTIVideoAdvanceDefault`
   (`0x005C13C0`). It is a different function's code sitting in the hole.
2. **The real body is a GPU vendor/device-ID gate, and it is readable.** In the v1.1 build the code
   immediately after that table slot's stolen head is, in plain `.text` at `0x005C13D0`:
   `cmp dword [edi+0x428], 0x10DE` (**NVIDIA vendor ID**) then a device-ID chain
   (`0x1D3, 0x1DF, 0x393, 0x395, 0x2E2, 0x1DD` + one against a `Sdata` slot), returning a bool.
   The **same shape exists in the dump build only in `.securom`, at `0x02487D20`** — relocated —
   with that build's own device list (`0x3D1, 0x3D2, 0x242, 0x3D5, 0x241, 0x245, 0x240`), ending
   `mov eax,1 / pop esi / ret` and `xor eax,eax / pop esi / ret`. The dump's `.text` has **no**
   `0x10DE` compare anywhere in `0x005C13xx`. This is consistent with SecuROM having relocated the
   body out of `.text` into `.securom`, which is what `securom_unwrap_devirtualization.md`
   describes for the 743 splice sites.
3. **Why it is still open.** The slot `[0x02458788]` resolves to `0x024E6220`, a *live
   self-decrypting VM stub* (`push 0x24E623A / push 0x40728B / push 0x1AC2BE4 / pushfd /
   sub [esp+4],0x12CD4 / popfd / ret` -> dispatch into `Stext`), so I cannot statically prove that
   `0x02487D20` is the target of *this* slot rather than a sibling. And the recovered body takes its
   argument in **EDI**, which is not a `lua_CFunction` shape — so either the hole holds packed
   foreign code in both builds, or the binding table genuinely points at a `__usercall` helper (which
   would be a shipped defect, since 6 Lua sites call it).

   *Static exhaustion demonstrated:* all four available dump-lineage images checked (dump, nodrm
   v1/v2/v3 — all carry the identical stolen head `ff 25 88 87 45 02`); the v1.1 build checked; the
   `.securom` slot chain followed to a self-decryptor; a whole-image byte scan for the vendor-ID
   immediate run (2 hits per build, both located).
   *Runtime recipe:* one-shot bp at `0x005C13A0`, single-step the `jmp [0x02458788]` and read EIP
   after the VM returns; **or** HW-write watchpoints on `DAT_00DF6724 / 37 / 38 / 40 / 41 / 42 / 43`
   while calling `LTILibName.LTIVideoAdvanceDefault()` — if none fires, it is not a settings reset.

**U2 — `0x006D5640` returns 0. CLOSED — PROVEN, by two independent images.**

| image | bytes at `0x006D5640` |
|---|---|
| `mercs2_unpacked.exe` (memory dump) / `image.bin` / `nodrm_v1` (built *from* the dump) | `e9 7b ca 5f 6f` = `jmp 0x6FCD20C0` |
| **`mercs2_nodrm_v2.exe` / `mercs2_nodrm_v3.exe`** (built from the **on-disk** RELOADED-decrypted exe) | **`33 c0 c3`** = `xor eax, eax ; ret` |
| **v1.1 build, same binding-table slot** (`LTIMovieStart` / `LTIupdateSupportQuickSlot` -> `0x006AEF90`) | **`33 c0 c3`** |

The `E9` is a **runtime hot-patch captured in the dump**, not SecuROM stolen bytes — which is why
`securom_unwrap_devirtualization.md`'s "build from the on-disk exe, not the memory dump" rule matters
here. `scripting_host_binding_code_map.md` §5.4 was right all along. **§8.1's mechanism sentence
("contains only `jmp 0x6FCD20C0` ... resolved by SecuROM at load") is CONTRADICTED**, and §3 rows #0
and #50 may keep their H — the *behaviour* is now read, in two images, in two builds.
Consequently O3 resolves in favour of H and §11.4's `b.stub` recommendation is fully justified.

**U3 — the 9 stolen prologue bytes. STILL OPEN, but reduced from 9 unreadable bytes to 7, and the
reconstruction is now near-forced.** See C2: `je <return-false>` is *read*, not inferred. That
leaves exactly **7 bytes at `entry+0..+6`** ending on an instruction boundary at `entry+7`. Encoding
exhaustion over 7-byte x86 forms that (a) set ZF, (b) can only use ESI (the only live register at a
`ret 0xC` entry — EAX and EBX are first written at `entry+9` / `entry+0x10`), and (c) must guard the
unchecked `mov ecx,[esi+0x1E0]` at `entry+0x18`, leaves `cmp dword ptr [esi+0x1E0], 0`
(`83 be e0 01 00 00 00`) as the only sensible fit. Corroboration is now stronger than Pass 1's:
the **immediately adjacent** function (`0x0061C5B0` in the dump, `0x0061C4D0` in v1.1) opens
`push ebp / mov ebp,esp / and esp,-8 / sub esp,0x28 /` **`83 bf e0 01 00 00 00`** — the identical
7-byte encoding with a different base register, in the same family, at the next address.
*Static exhaustion:* the stolen-byte carrier followed (`[0x02455570]` -> `0x024B5390`), which is a
live SecuROM VM record (`push / push / push / pushfd / sub [esp+4],0x271C / popfd / ret` ->
`0x01AAFF10` in `Stext`, itself a flag-preserving trampoline in front of an encrypted-island loop);
all 5 images checked, all stolen. Grade: **inferred (high)**, not proven.
*Runtime recipe:* bp at `0x0061C559` and read the 7 bytes at `0x0061C550` in memory after SecuROM's
loader has run — or read ZF/ESI on entry.

**U4 — the whole Bink section §7. CLOSED. Mostly confirmed; three concrete corrections.**

Confirmed by reading `FUN_00709640` / `FUN_00709CB0` / all seven `Movie`/`LTIMovie` bodies and by
parsing the import directory:

* inline FNV-1a, seed `0x811C9DC5`, `| 0x20` case fold, final `^ 0x2A` then `* 0x1000193` — yes
* stride **`0x16C`** — yes (`piVar7 + 0x5B` dwords; the tail is literally `imul eax,eax,0x16C`)
* hash-field base `0x017C64F8` — yes; end guard `0x017C6AA7` — yes (`cmp edi, 0x17C6AA8 / jl`)
* `binkw32.dll!_BinkPause@8` at IAT **`[0x00B055FC]`** — yes, entry 7 of the 15-slot `binkw32`
  descriptor, resolved by name from the **OriginalFirstThunk** (the dump's FirstThunk is bound, so a
  FirstThunk parse yields nothing — presumably why the map cited it without showing work)
* `rec+0x30` play state (1<->2) — yes; `rec+0x38` HBINK — yes; `[Render] FirstRun` read-then-cleared
  — yes (`GetPrivateProfileIntA("Render","FirstRun",1,...)`; if non-zero, `sprintf("%i",0)` +
  `WritePrivateProfileStringA`). Shipped `Mercs2.ini` has `FirstRun=0`.

Corrections:

1. **The record field offsets mix two different bases, and two named fields are the same byte.**
   `FUN_00709640` returns **`0x017C64F0 + i*0x16C`**; `Movie.Start` calls `FUN_00709CB0` with
   `mov esi, 0x017C64F4` — i.e. **record + 4**. So `FUN_00709CB0`'s `+0x04 / +0x44 / +0x148 /
   +0x149 / +0x14A` are record `+0x08 / +0x48 / +0x14C / +0x14D / +0x14E`, while `FUN_00709640`-based
   readers use `+0x30 / +0x38 / +0x14E` directly. §7 lists both conventions in one table. In
   particular **`+0x14A` (start clears it) and `+0x14E` (Stop sets it) are one and the same byte** —
   record `+0x14E`, the stop/finish flag. Corrected, record-relative:
   `+0x08` name hash · `+0x30` play state (a **dword**, not a byte) · `+0x38` HBINK · `+0x48` `.bik`
   path · `+0x14C` start flag · `+0x14D` started · `+0x14E` stop-requested.
2. **The path literals use a backslash**: `"%sMovies\%s.bik"` (`0x00BD1EB0`) and
   `"%sMovies\%s.ogg"` (`0x00BD1EC0`), root `".\Data\"` (`0x00ED2010`). The map prints forward
   slashes.
3. **The `.ogg` sidecar conclusion is refuted by the shipped assets.** `game-files/PC-Movies/`
   holds **45 files, all `.bik`; zero `.ogg` exist anywhere in the tree**, and
   `docs/movies_pc_vs_ps3_catalog.md` (ffprobe ground truth) records the PC Binks as carrying **8
   internal audio tracks** — matching `audio_code_map.md`'s `BinkSetSoundTrack(4,...)`. The
   `sprintf` into `DAT_00F79218` is real code; the inference "a Mercenaries 2 movie is a `.bik`
   video with a sibling `.ogg` audio stream", graded **H** in §0.5 / §3.1 / §7, is **wrong about the
   shipped game** and must be re-scoped to "the start path also formats an `.ogg` path that no
   shipped asset satisfies" (vestigial / dev-era).

Also new: **`Movie.Start` hard-codes record[0]** (`mov esi, 0x017C64F4`, never indexed by the name),
and the light-userdata it pushes is `[0x017C64F8]` — record[0]'s **hash value**, written into the
TValue as `{value = hash, tt = 2}`.

**U5 — §5's key vocabulary. CLOSED. The lists are exact; one count is wrong.**
Every string operand inside `FUN_005C37E0`'s 8064-byte extent was extracted and classified.
**18 control keys — the map's list, verbatim and complete.** **33 value keys — the map's table lists
all 33 correctly but calls them "all 30 of them".** (Game 6 + Video 9 + Advanced 9 + Audio 5 +
Controls 3 + Server 1 = 33.) The direct-callee census also confirms §5's helper list and adds three
the map omits: `FUN_00609940` x10 (widget resolve), `FUN_009EE850`, `FUN_0059D8E0`, `FUN_00401860` x5.
Note `LTIVideoSetSwitchOpt2` is the one member of the `Opt1..8` family this function never Invokes.

**U6 — §4's field offsets. CLOSED, all confirmed, and `+0x08`/`+0x0C` deserve H not M.**
From `FUN_005C0AF0`: `DAT_00DF6708 = mode & 0xFFFF`, `DAT_00DF670C = packed >> 16`,
`DAT_00DF6714 = (packed >> 8) & 0xFF` (refresh), `DAT_00DF6719 = fullscreen`,
`DAT_00DF6728` = view distance, rescaled `x4/3` when going fullscreen and `x [0x00BEB950] = 0.75`
when going windowed. **`sprintf("%u x %u", DAT_00DF6708, DAT_00DF670C)`** proves `+0x08` / `+0x0C` are
width / height outright — a can't-coincide fingerprint, so M is too conservative.
`+0x44` confirmed via `FirstRun` reading the committed twin `DAT_00DFC364`.
**New field the map omits: `+0x31` = Rumble** (`LTIInputGeneralRumble` writes `[0x00DFC351]`).
**New field, and the key to §9.2: `+0x2C` = `PresentImmediate`** — see §3.

**U7 — the gamma formula. CLOSED — CONTRADICTED.** The map says
`DAT_00DF6720 = (i64)(1.5 - f*0.01)`. Reading `FUN_005C10C0` instruction by instruction:
the SSE lane computes `xmm1 = [0x00B9C650] - f * [0x00B97EEC]` and stores it to `[esp]` as the
argument to `FUN_0074AE20(0x017CFAF0, ...)`; the **x87 lane** does `fld dword [esp+4]` (the raw
argument) and `fistp qword [esp+0x10]`, and it is *that* — the **raw slider as an integer** — that
lands in `[0x00DF6720]`. Constants verified: `[0x00B97EEC] = 0.01f`, `[0x00B9C650] = 1.5f`.
Decisive data-side confirmation: shipped `Mercs2.ini` has **`[Render] Gamma=50`**, and
`1.5 - 50*0.01 = 1.0` — neutral gamma. Had the field held the transformed value it would read `1`.
`LTIVideoCancel` re-derives `1.5 - x*0.01` from the committed copy `[0x00DFC340]` and is therefore
symmetric and correct — the "double transform" the map's wording implies does not exist.

**U8 — VSync polarity. CLOSED. See §3. Verdict: NOT a bug.**

### MISSING (7/7 closed)

**M1 — inlined Invoke sites. CONFIRMED and enlarged: 27, not 24.** See §2.

**M2 — 29 slot-sourced names, 27 distinct slots. CONFIRMED exactly** (218 immediate + 29 slot +
3 indeterminate = 250; 142 distinct names). The slots are a **contiguous 39-entry `.data` name table
at `0x00D121B8`–`0x00D12250`**, of which §6 sees none. The 10 the funnel does not reach —
`loadDefaultProfile`, `noDefaultProfile`, `getListProfiles`, `profileName`, `keyboardEntry`,
`renameKeyboardEntry`, `gameAutoSave`, `gameSubtitles`, `saveGameSlot`, `videoWidescreen` — are
still shipped AS vocabulary.
**All 3 of Pass 1's indeterminates are now resolved** by control flow (Pass 1's linear back-sync
desynced on `pop edi`): `0x005BB3F8` -> a **Lua-supplied string** (see §2); `0x00614B69` ->
`"onlineIsConnectedReturn"` (`0x00BBC4D0`, set at `0x00614812`, reached via `jne 0x614B59` from
`0x0061481B`); `0x00848D44` -> `"onlineLoginAccount"` (`0x00BE32D4`, set at `0x00848CF5`, reached via
`je 0x848D31`). **250 of 250 named.**

**M3 — the VSync polarity mismatch. RETRACTED — it is not an anomaly.** See §3.

**M4 — `LTIupdateSupportQuickSlot` absent from every `.gfx`. CONFIRMED, and the extraction is now
proven complete.** Pass 1 could not verify `output/gfx_movies/` against the WADs.
`docs/data/aset_export.csv` lists **83** assets of `type_hash 0xFE0E8320` (`cfx_pack`): vz.wad 64 +
shell.wad 16 + Loading.wad 3; `output/gfx_movies/` holds exactly 64 + 16 + 3, mapping 1:1 including
the hash-named ones. Searched as raw bytes *and* as NUL-delimited exact tokens over the full
decompressed payload of all 83: `LTIupdateSupportQuickSlot`, `updateSupportQuickSlot`,
`LTIMovieStart`, `MovieStart` are **absent from all 83**, `Map.gfx` and `SUPPORT.gfx` included.

**Fix-pack implication — stronger than the map's §8.2, and different from Pass 1's.** Pass 1 closed
§9.5 as "nothing is lost by the stub". The Lua side says otherwise: `mrxguipda.lua:1861` defines
**`EnableQuickSlot(sId)`**, ~37 lines that do the real work (remove the current support, look up
`tSupportIdIndex[sId]`, `AddItem`, `SetSupportName` / `SetFuelCost` / `SetCashCost` / `Commence`,
animate the ammo counter) — and it has **zero callers anywhere in either Lua corpus**. So the
feature has two implementations and neither runs: the Flash event is never raised, the cfunc is a
no-op, and the written Lua implementation is dead code three lines below the forwarder. That reads
as a genuine shipped bug and a plausible one-line fix (`_LTIupdateSupportQuickSlot` ->
`EnableQuickSlot(sParm)`), pending an in-game repro.

**M5 — the registrar consumer loop. CONFIRMED, and the contested address is settled.**
`0x00DFD478` has exactly **4** `.text` references (`0x005A2D3A`, `0x005A2D49`, `0x005A2DED`,
`0x005A2DF3`); `0x00DFD514`, `0x00DFD5E0`, `0x00B99C78` and `0x00B99BBC` have **zero**. Walking
stride-12 from `0x00DFD478` gives **31 rows**, terminator `{0,0,0}` at `0x00DFD5EC`,
`0x00DFD514` = row **13** = `Graphics` (`0x00B9A4D0`, 95 cfuncs), `0x00DFD5E0` = row 30 =
`LTILibName`. 1103 cfuncs total. **`0x00DFD478` / 31 is the array; `0x00DFD514` / 18 is a mid-array
slice.** Everything §1.3 concludes *from* it is unaffected.

**M6 — `LTIRegisterBox` is the licensing Invoke, from `FUN_00847FE0`. CONFIRMED.** The name-harvest
puts `LTIRegisterBox` (`0x00BE3114`) at `0x0084811A` and `0x0084821A` (both in `FUN_00847FE0`) and at
`0x00848BAA` / `0x00848C87` (in `FUN_00848AE0`). `FUN_008486F0` carries `addDropDownItem`,
`LTISetUSZip`, `LTI_TOSText` — all three **inlined**, not funnel calls, exactly as Pass 1 says. The
AS census confirms `LTIRegisterBox`, `LTISetUSZip`, `LTI_TOSText`, `LTIonlineMsgBox`,
`LTIstopConnectingDisplay`, `LTIProfileOnlinePlay`, `LTIgotoGame` are all defined in
`shell/SHELL.gfx`. But see §4 — the *conclusion* the map draws from this needs re-scoping.

**M7 — `Movie` is 4-mod-8 and a float pi separates the tables. CONFIRMED byte-for-byte.**
`0x00B99BB8 = 0x40490FDB` (3.14159f) and `0x00B99BE4 = 0x40490FDB`, each preceded by `{0,0}`;
`0x00B99BBC = 4 (mod 8)`, `0x00B99C78 = 0 (mod 8)`. An 8-byte-grid re-walk from the neighbouring
`math` table (`0x00B99BE8`) skips `Movie` entirely.

### Pass 1's §A12 "what I could not check" (6/6 addressed)

| A12 item | Pass 2 |
|---|---|
| `0x006D5640`'s body | **CLOSED — read** (U2) |
| `LTIVideoAdvanceDefault`'s body | **Map's answer disproved; body region located; still open** (U1) |
| the 9 stolen prologue bytes | **Reduced to 7; 2 of the 9 read; reconstruction near-forced** (U3) |
| no AS bytecode decompiled | **CLOSED — full AVM1 lift of both functions** (§3) |
| `output/gfx_movies/` completeness | **CLOSED — 83 of 83, cross-checked against the WAD ASET index** (M4) |
| no live run | Still true. Everything below is static; runtime recipes are given for U1 and U3 only. |

---

## 2. The true Invoke-site count

| | count | method |
|---|---:|---|
| `E8 rel32 -> 0x0061C550` | **248** | whole-`.text` byte scan |
| `E9 rel32 -> 0x0061C550` | **2** | `0x004CEB7C`, `0x006955A1` |
| other sections | **0** | all 13 sections scanned |
| **funnel total** | **250** | **250/250 re-confirmed as real instructions by linear disassembly — 0 false positives** |
| inlined bypasses (`[X+0x1E0]` -> `vtbl+0x28` gate -> `vtbl+0x48` Invoke, excluding the funnel body) | **27** | 28 detected pairs minus the funnel's own `0x0061C574` / `0x0061C595` |
| **static total** | **277** | funnel share **90.3 %** |

**"All 194" is wrong twice over: the number is 250, and the funnel carries 90 %, not 100 %.**

Pass 1 found 24 bypasses / 14 names. A detector keyed on the *call* rather than on a fixed byte
shape finds **27 / 17 distinct names**, adding three sites Pass 1's pattern missed — all in the
`0x0061C4xx`–`0x0061C7xx` sibling-helper block:

| site | function | AS name |
|---|---|---|
| `0x0061C492` | `FUN_0061C440` | **`confirmButtonReversed`** — absent from the map entirely |
| `0x0061C70D` | `FUN_0061C5B0` | **`leftAnalog`** |
| `0x0061C7FC` | `FUN_0061C5B0` | **`rightAnalog`** |

The other 24 reproduce Pass 1's list (`LTITextInputUpdateString`, `LTIInputSeeButtonsPushed`,
`LTIInputKMSetActionName` x2, `LTIInputKMKeyMap` x4, `LTIInputKMUpdateTable` x2,
`LTIInputControllerNames`, `LTIInputJoystickMap` x3, `LTIInputJoystickUpdateTable` x3,
`controllerDisplay` x2, `addDropDownItem`, `LTISetUSZip`, `LTI_TOSText`, `AddGPSLine`,
`setTerritory`, plus one whose name arrives in a register at `0x005C1B1C`).

### M8 (new) — the funnel is also a **Lua-callable generic Invoke**, and it is the largest omission in §6

Funnel site `0x005BB3F8` takes its AS name from `[ebp-0x1C]`, which is filled by `FUN_0059FA40` — a
Lua string accessor. Its containing function `FUN_005BB170` has `callers=[]` in Ghidra because it is
a **binding**: `binding_map.json` table `0x00B99FF8` (114 entries) names it
**`_GuiInternal.CallFlashScriptFunction`**.

It resolves a widget by Lua id, reads an arbitrary AS **function name from Lua**, marshals up to
**0x40 = 64** further Lua arguments into `GFxValue`s (typing each: tag 3 number / tag 2 boolean /
tag 4 or 5 string), calls `FUN_0061C550` with a non-NULL `presult`, and converts the **return value**
back onto the Lua stack. It is the only site in the game that reads an Invoke result.

The Lua layer wraps it as `FlashWidget:CallActionScriptCallback(sName, tArgs)`
(`mrxguibase.lua:1274`), which has **176 call sites** across the two Lua corpora — 120 with a
literal name (**57 distinct**) and 56 with a variable name.

Consequences the map and Pass 1 both miss:

* **§6's ActionScript vocabulary is not a closed set.** Static harvest = 142 (funnel) + 13 new
  (inlined) = 155; the Lua literals add **41 more** -> **196 distinct names statically knowable**,
  and 56 further Lua sites name the function at runtime. §6 lists roughly 70.
* **`presult` is used.** §0.5 describes the signature with `pretval` and every documented caller
  passes 0; §11.5's reimpl rule (`invoke(movie, name, &[Value])`) has no return channel. One caller
  needs one.
* **64 is the argument ceiling** a reimplementation must support, not the 1–6 seen at LTI sites.
* `_GuiInternal.CreateMovieWidget` / `SetMovieFile` / `PlayMovie` / `PauseMovie` / `StopMovie` /
  `GetMovieCurrentFrameNumber` / `SetMovieEndCallback` (`0x005BC1A0`–`0x005BC640`) are in the same
  table — the concrete VAs behind §3.1's correct claim that MovieWidget superseded `Movie.*`.

### M9 (new) — three AS names the engine Invokes are defined in no shipped movie, and one is a case mismatch

The AS census over all 83 movies (exact NUL-delimited tokens):

* **`ProfilesComplete`** (2 funnel sites), **`AddProfile`**, **`loadProfile`** — **defined in no
  movie**. `IsAvailable` makes each a silent no-op.
* **`joingameSavegame`** — the engine's `.data` slot `0x00D121F0` holds lowercase-g; SHELL.gfx spells
  it **`joingameSaveGame`**. A genuine case mismatch -> silent no-op.

These are exactly the defect class §2.2 warns about, and they are real — unlike the VSync pair the
map chased.

### M10 (new) — "declares a Lua result it never pushes" is 22 cfuncs, not 3

Mechanical census over all 56 cfuncs (a push = the Lua 5.1 `L->top += 8` bump,
`add dword ptr [reg+8], 8`): **22 of 56 have at least one `ret` with `EAX = 1` and no push.** Two
classes, and §8.3 / §11.7 name only three members of the first:

* **success path returns 1 with nothing pushed** — `LTIVideoGetViewDistance`, `LTIPrecacheDone`,
  `LTIPrecacheSmokeDone`, **`LTICamera`**, **`LTIChoseOnline`**, **`LTIGetDateFormat`**,
  **`LTIPauseItemChanged`**, **`LTIMovieStop` / `LTIMoviePause` / `LTIMovieResume`**,
  **`Movie.Stop` / `Movie.Pause` / `Movie.Resume`**.
* **argument-type-error path only** — `LTIVideoSetGamma`, `LTIVideoSwitchOpt1`,
  `LTIInputGeneral{InvertMouse,MouseSense,JoySense,Rumble}`, `LTIInputJoystickChangePrimary`,
  `LTIJoystickOverBoundResponse`, `ChangeShellState`.

Only `FirstRun` and `Movie.Start` actually push. A reimpl oracle built from §8.3's "three" will
diverge on 19 further bindings.

### M11 (new) — `FUN_0074BB50`'s section is a stack argument, and it is not always `"Render"`

§0.5 says *"section literal is `"Render"` at every LTI call site"*. Read: the signature is
`f(section /*stack*/, key /*EDI*/, value /*ESI*/)` -> `GetPrivateProfileIntA(section, key, esi+1, ini)`,
and on mismatch `sprintf("%i", esi)` + `WritePrivateProfileStringA`. All **47** call sites, by section:
Render 23 · Network 5 · Audio 5 · Joystick 4 · Game 3 · Mouse 2 · 5 register-sourced.
Inside LTI itself: `FUN_005C1240` x5 Render, but `FUN_005C1470` and `FUN_005C18B0` write
**`[Joystick] Invert` and `[Joystick] Rumble`** — which §3 row 23 states correctly, so §0.5
contradicts §3. Shipped `Mercs2.ini` confirms `[Joystick] Invert / Rumble / Sensitivity` and has
**no key named `Joystick`** — §3 row 19's key list should drop it and add `Sensitivity`.
The same census surfaces `[Network] MailEA` / `MailThirdParty` / `FriendlyFire`, written by
`FUN_00847550` — relevant to §4 below.

---

## 3. The VSync polarity verdict — **NOT A BUG. Close §9.2 and retract Pass 1's M3.**

Settled from three independent directions that agree.

**(a) The byte is named, and it is inverted-sense.** `[0x00DF672C]` (live) / `[0x00DFC34C]`
(committed, `+0x5C20`) is **`[Render] PresentImmediate`** — the key string `0x00BD58B0` written at
`0x007535C5` in the settings serializer, and the key is present in the shipped `Mercs2.ini`
(`PresentImmediate=1`). Field offset **`+0x2C`**, which §4 omits.

**(b) D3D9 proves the semantics.** `FUN_00755380` at `0x00755407`:
`mov al,[0x00DFC34C] / neg al / sbb eax,eax / and eax,0x80000000 / mov [esi+0x5B8],eax`, and the
change-detector at `0x0074C927` compares `[ebx+0x5B8] == 0x80000000`. **`0x80000000` is
`D3DPRESENT_INTERVAL_IMMEDIATE`; `0` is `D3DPRESENT_INTERVAL_DEFAULT`.** So
**byte = 1 => present immediately => VSync OFF; byte = 0 => VSync ON.**
The dispatcher's own inbound keys agree: `VSyncOn` -> `[0x00DF672C] = 0` (`0x005C51BD`),
`VSyncOff` -> `= 1` (`0x005C51D5`), and `videoVsyncVar=<v>` -> `= (_stricmp(v,"true") != 0)`
(`0x005C51FF`).

**(c) The ActionScript closes it.** Both functions were lifted from AVM1 bytecode:

`shell/SHELL.gfx` -> `LTIVideoSetVSync(val)` (241-byte `defineFunction2`):
`if (settingVSync == val) return; settingVSync = val; if (val == 1) crosshair_1 "_on" else
crosshair_2 "_on"`. **No re-inversion.**

`pause_menu.gfx` -> `LTIVideoSetVsync(val)` (67-byte `defineFunction2`):
`this.videoVsyncVar = (val != 1)`. The compiled form is `equals2 ; if->else` with **no `not`
opcode**, where every other compiled `if/else` in both movies emits `cond ; not ; if->else`. The
missing `not` is a deliberate source-level inversion, not a decode artefact.

Composing engine sender with AS receiver, for `b = [0x00DF672C]`:

| path | engine sends | AS computes | lights crosshair_1 |
|---|---|---|---|
| shell `FUN_005C0870` @ `0x005C09EA` | `sete (b == 0)` | `val == 1` | iff **b == 0** |
| pause `FUN_005C37E0` @ `0x005C3D7D` | raw `b` | `videoVsyncVar = (val != 1)` | iff **b == 0** |

**They agree exactly.** The engine-level asymmetry is *cancelled* by the AS-level asymmetry, and both
menus display the setting correctly. The `sete` in the shell path is not a stray inversion — it is
the correct compensation for a byte that stores "VSync **dis**abled".

Spelling census over all 83 movies, for completeness: `LTIVideoSetVSync`, `VSyncOn`, `VSyncOff`,
`settingVSync`, `vsync_btn` exist **only** in `shell/SHELL.gfx`; `LTIVideoSetVsync`, `videoVsyncVar`
exist **only** in `pause_menu.gfx`. Each engine path targets the movie that defines its spelling.

**Actions:** §9.2 -> close as *not a bug*. §2.2 claim 1 -> keep the mechanism, drop the example, and
point it at **`joingameSavegame` / `ProfilesComplete` / `AddProfile` / `loadProfile`** (M9), which
are real. Pass 1's **M3, A8's closing paragraph, and U8 are retracted.**

---

## 4. The `0x00848xxx` account-data audit

**Provenance correction first:** the claim that `mercs2_licensing_registration_map.md` documents an
`Account.EmailAddress` / `BirthDate` / `ParentalEmailAddress` / `GAME-MERCENARIES2-WIF` block is
**false**. None of those tokens appears in that document; the only `0x848` reference in it is
`FUN_00847FE0`, twice. Repo-wide those four tokens appear in exactly one file — Pass 1's own §A7
residual note. It was a self-generated lead, not a sibling-map claim.

**Findings.** Every `.rdata` string in `0x00BE3100`–`0x00BE32E0` was enumerated with its `.text`
cross-references:

1. **`FUN_00848990` is the only referencer of all four `Account.*` field names** (`Account.BirthDate`
   `0x00BE3234`, `Account.EmailAddress` `0x00BE3258`, `Account.ParentalEmailAddress` `0x00BE3270`,
   **`Account.Address.Zip` `0x00BE3290`** — a fourth field Pass 1 did not know about). It receives an
   **error code** and a **field name from the server**, `memcmp`s the name against those four
   literals to select a stringdb token (`[0xaf649a22]`, `[0xc46f54f4]`, `[0x639146df]`,
   `[0x2b69cadf]`, `[0x9216be77]`, `[0xc13b9039]`), builds a **6-element `GFxValue` array** and
   Invokes **`LTIonlineMsgBox`** at `0x00848AD1`. **This is an error-message formatter. The field
   names are compared, never transmitted. No sink.**
2. **`FUN_008482F0` — the only referencer of `GAME-MERCENARIES2-WIF` (`0x00BE3174`) — DOES
   transmit.** It assembles the product code on the stack byte-by-byte, does
   `strcpy(DAT_00F7F1D0, <key in EDI>)` (the `ergc` buffer the licensing map owns), then issues an
   asynchronous request through a service singleton (`FUN_0096DAC0` -> `DAT_00E74EC0`, `vtbl+4` ->
   `vtbl+0x18` / `vtbl+8`) passing `&DAT_01176460`, `&DAT_01176480`, a **10000 ms timeout**, and
   **`FUN_00847FE0` as the completion callback**. Single caller `0x006C9CF5`.
3. **The form fields leave the movie in cleartext.** `shell/SHELL.gfx` hosts the registration screen
   (`lticreateAcct_mc`, `createAcctpageListener`, `inCreateAccountPage`) with fields `ltiusername`,
   `ltipassword`, `ltiemail`, `ltiparent_email`, `ltibMonth/Day/Year`, `lticountry`, `ltizip_code`
   and an EA-contact opt-in. The lifted payload builder concatenates them `&`-delimited into
   `createstr` and ships them with `fscommand("onlineCreateAccountNamePass", createstr)`; siblings
   are `onlineExistingAccountNamePass`, `onlineLoginAccountPass` (`"LTIpw"`), `onlineSetParameters`,
   `onlineTOSAllowEA`, `onlineLTIRegisterGame`. The movie itself has **no** `LoadVars` / `XML` /
   `ExternalInterface` / `getURL` to any http target — these are host `fscommand`s into the engine.
4. **`[Network] MailEA` / `MailThirdParty`** (`FUN_00847550`, and again in the settings serializer)
   are the marketing opt-in flags persisted to the INI.
5. **New AS names in this block that §6 lacks:** `onlineLoginAccount`, `onlineLoginAccountError`,
   `onlineLoginSuccessful`, `onlineCreateAccountError`, `onlineConnectionFailure`,
   `clearDropDownItem`, `onlineIsConnectedReturn`.

**Verdict.** §10's *"The CD key is being displayed, not transmitted"* is **true of `FUN_00847FE0`
and false as a statement about the block.** `FUN_0061C550` is display-only — that stands, proven.
But `FUN_008482F0`, two functions away, is a genuine transmit path for the CD key plus the
`GAME-MERCENARIES2-WIF` product code, and the account form's username / password / e-mail /
parental e-mail / DOB / country / ZIP reach the engine in cleartext through `fscommand`. The
licensing map's open item is **narrowed, not eliminated**: `thunk_FUN_024b5390` is cleared; the sink
behind `FUN_008482F0`'s service vtable is not, and it is the one that matters. §10 should say so
rather than implying the whole block is inert.

---

## 5. `docs/ui/main_menu_structure.md` — the three corrections, tested

| Map §10 correction | Verdict |
|---|---|
| 1. "LTI (Lua To Interface)" is unsupported | **CONFIRMED.** §5's heading is verbatim `## 5. LTI (Lua To Interface) Callback Functions`. 172 `LTI` strings, no expansion (O6). |
| 2. "Registration Table located at `0x00B99D00`" | **CONFIRMED as wrong** (`0x00B99C78`; `0x00B99D00` is entry #17). **But the map's diagnosis is wrong.** It says the String VA column is "shifted by one entry from about `LTIProfileExit` onward". It is not a uniform shift: of the 15 rows, 4 are correct, 5 are AS names with no cfunc, and of the 6 wrong VAs only `LTIChoseOnline = 0x00BB69DC` lands on another real entry (`LTICamera`'s). The rest (`0x00BB6A4C`, `0x00BB6A00`, `0x00BB69EC`, `0x00BB69C4`, `0x00BB69A4`) are off-by-4/8/12 drift, not entry-granular. |
| 3. "merges two opposite directions" | **CONFIRMED, and badly under-counted.** §5 merges directions across six sub-tables; the map names ~20 AS functions and misses **at least 25 more**, including two entire sub-tables (all 4 "Game Options", all 3 "Multiplayer") plus 13 `LTIInput*` and 4 `LTIVideoSet*`. |

**A fourth correction is owed.** §5 omits **10 of the 52 real bindings** entirely
(`LTIInputKMDefault`, `LTIInputKMCancelInput`, `LTIInputKMExit`, `LTIInputJoystickChangePrimary`,
`LTIInputJoystickCancel`, `LTIInputJoystickDefault`, `LTIInputJoystickExit`,
`LTIInputJoystickReEnter`, `LTIGetDateFormat`, `LTIupdateSupportQuickSlot`), and its §1 asserts
scripts call `ChangeShellState("newGame")` — **all 24 shipped call sites pass a boolean**
(15x `true`, 9x `false`; zero string arguments exist). That doc's §1 also gives a disassembly of
`0x005C3740` whose `[0x01176034]` guard is the *opposite* of §3 row 41's. Re-read here, §3 row 41 is
right: `if ([0x1175F2F] == 0) [0x01176034] = 0` — the counter is cleared when the flag is cleared.
Row 41 should also note the `mov eax,1 / ret` type-error path (M10).

---

## 6. Sibling-map boundary claims, tested as claims

| Claim | Verdict |
|---|---|
| `scripting_host_binding_code_map.md` owns `0x006D5640` | **Its bytes are right and the map's are wrong** — see U2. The dump is corrupt at that VA. |
| `input_code_map.md` owns `FUN_004FBBA0` / `FUN_004FBC60` / `FUN_004FA570` / `FUN_004FD930` / `FUN_0082A960` / `FUN_004FBF20` / `0x00EDAE60` | **FALSE — none of those tokens appears in that document, or anywhere else in `docs/`.** The map's boundary table, §3 rows 26/35 and §12 launder its own first-hand disassembly as citations. They must be re-labelled as new findings and re-graded. (What that map *does* own and the LTI map should cite: it already claims `FUN_005C1900/1ED0/2970/2CB0` and `FUN_005C37E0` at M confidence, and its §4 independently derives the `DAT_00DFC34x/36x` committed mirror. It also documents a **53-entry controller-name table `PTR_s_Left_Stick___Left_00cf2560`** inside `FUN_005C37E0` that §5 never mentions.) |
| `save_serialize_code_map.md` owns `[0x01176054]` | Ownership holds, but **`+0x10` appears in no other document** — §3 row 47 is a new single-witness offset adjacent to the documented `+0x11` dirty flag. Downgrade from H or flag as new. That map also owns `FUN_00614540` (as the game-state dispatcher), an overlap the boundary table omits. |
| `audio_code_map.md` owns the Bink audio path | `FUN_00621AB0` / `FUN_00621BC0` holds. But **`FUN_00709CB0` / `FUN_00709640` appear nowhere in it**, and neither does `.ogg` — the linkage and the sidecar claim are the LTI map's own, presented as cited. See U4.3. |
| `scaleform_gfx_class_map.md` §6 documents only pure forwarders | **The map overstates its own novelty** — §6 already documents split bodies explicitly, with a worked example (`Execute` @0x76AB40 + tail @0x76F252). The genuinely new part is that chain-following fails for this shape. Conversely §7.2 **independently gives `+0x28 IsAvailable`, `+0x48 Invoke` at `obj+0x1E0`** — the strongest external corroboration of §2, and the map does not cite it. |
| `mercs2_licensing_registration_map.md`'s telemetry-sink item | Its own wording is hedged ("Interpretation (not proven)") in §1 but flat in §3. **Resolved for `thunk_FUN_024b5390`; not resolved for the block** — see §4. |
| `scaleform_gfx_function_map.json` classifies "all four" return-leg functions | **Three, not four.** `0060de80`, `00614540`, `0060994e` are present; **`0x0061C550` and `FUN_00847FE0` are both absent.** §2.3 should say "three of the four", and §10's JSON recommendation should add `FUN_00847FE0` — and must not import "194". |

---

## 7. Other items closed in passing

* **§9.7 region ids — CLOSED.** `FUN_0061C440` switches on `*[0x01176018]` through the jump table at
  `0x0061C524` and Invokes `setTerritory` with `"SP"` (`0x00BBC794`) / `"IT"` / `"FR"` / `"GR"` /
  `"RU"` (`0x00BBC7A4`) / `"EN"` (`0x00BBC7A8`, the default for out-of-range). The same function
  Invokes **`confirmButtonReversed`** as a Boolean `(*[0x00D1E50C] == 8)`; that global reads **6** in
  the dump. `LTIGetDateFormat`'s `{0, 6}` US set re-read and confirmed (tag **2 = Boolean**, name
  `0x00BB7848`), consistent with `EN` = 6.
* **§9.8 glue chunks — CLOSED, and the map's "three" is an undercount.** **9 of the 31** registrar
  rows carry a non-empty glue chunk: `_SYS` (`_G._MODULES = {}; _MODULESMETATABLE = ...`),
  `Sys` (`_tostring = tostring; tostring = Sys.To...`), `Pg` (`GetGuidByName = Pg.GetGuidByName; ...`),
  `Debug` (`ASSERT = Debug.Assert; print = Debug.Pri...`), `Gui` (`_G.Marker = {} ...`),
  `_GuiInternal` (`_GuiInternal.nVersion = 2`), `ObjectFilter` (`_OFMETATABLE = { __gc = ...`),
  `math` (`Math = math`), `VO` (`VO.PRIORITY_CINEMATIC = 0; VO.PRIORITY_S...`).
* **§9.6 `Movie.*` unreachable — CLOSED.** Zero Lua call sites in either corpus (both re-verified);
  `Movie.` in any form = 0; the four `LTIMovie*` = 0. `mrxguicinematic.lua` drives `MovieWidget`
  (`mrxguibase.lua:1365`) over `_GuiInternal.CreateMovieWidget`; nothing in the fscommand vocabulary
  reaches `Movie.*`.
* **The 220 count — CLOSED and reconciled.** 220 over the 370 `.lua` files; **221** if the corpus's
  own `.md` index files are walked (one prose hit in `05_gui_hud_shell.md:466`). **220 is right.**
  All 52 per-binding counts in §3 reproduce exactly, `ChangeShellState` = 24 included. Caveat worth
  adding to §3: four of the 14 files exist byte-identically under both `src/resident/` and
  `src/shell/`, so **the deduplicated site count is 148**, and §11.2's "true counts" should say which
  rule it uses.
* **§11 is 18 days stale.** `lti.rs` was last touched 2026-07-07; `install` **is** filled, and the
  file already binds the `LTILibName` alias explicitly (`lua.globals().set("LTILibName", lti)`), so
  §11.1's defect is now cosmetic (the coverage key). §11.4's instruction is unactionable as written —
  there is no `b.real("LTIMovieStart")` line; all 51 non-`FirstRun` names go through
  `super::record_all(...)`, and the fix is to lift the two names out of that array. Also `FirstRun`
  returns `Ok(0i64)` (an mlua Integer) where retail pushes a **float** (`cvtsi2ss` -> `tt = 3`), and
  returns 0 where retail returns 1.0 on a normal install (`Mercs2.ini` has `FirstRun=0`).
* **`LTIStartNewGame`, `LTIStartKeyboardInput`, `LTIEndKeyboardInput`** are `"LTI..."` Lua string
  literals belonging to none of the 52 bindings; §6's "not in this namespace despite the prefix" note
  covers only `LTIGetPrecacheBypass`, `LTI_precache`, `LTIenterControlDisplay`, `LTIFscommand`.

---

## 8. Pass 2 verdict

The map's core remains sound and is now verified far more deeply than in Pass 1: the binding table,
the registrar record, the LTI-module identification, the settings triad, the `group*10+value` decode,
all 52 Lua call counts, the 18 control keys and 33 value keys, the Bink hash/stride/IAT, and the
`FUN_0061C550` mechanism all reproduce — several byte-for-byte, and several now in a **second
independent build**.

What must change before it ships, in priority order:

1. **C1 / O1 / O2** — 250 sites, 27 bypasses, 277 total, funnel 90 %. Do not export "194" to
   `scaleform_gfx_function_map.json`. Do not quote a "distinct containing functions" figure.
2. **M8** — `_GuiInternal.CallFlashScriptFunction` (`0x005BB170`): a Lua-callable generic Invoke,
   64 args, uses `presult`, 176 Lua sites, 41 further AS names. §6 and §11.5 both need it.
3. **U4.3** — retract the `.ogg` sidecar conclusion; 45/45 shipped movies are `.bik` with internal audio.
4. **U7** — `[0x00DF6720]` holds the **raw** gamma slider; `1.5 - f*0.01` is the applied value.
   Shipped `Gamma=50` -> 1.0.
5. **U2 / O3 / §8.1** — `0x006D5640` is `xor eax,eax; ret`, **read** in two images. The dump is
   corrupt there.
6. **§9.2 / §2.2** — VSync is **not** a bug; retract it and Pass 1's M3. Redirect §2.2 at
   `joingameSavegame`, `ProfilesComplete`, `AddProfile`, `loadProfile` (M9).
7. **M10** — 22 cfuncs return `nresults=1` without pushing, not 3. §11.7's oracle rule is wrong for
   19 of them.
8. **Boundary / citation hygiene** — the six `input_code_map.md` addresses are not citations;
   `+0x10` on the profile singleton is not a citation; the `FUN_00709CB0` <-> audio-map link is not a
   citation. Re-label as first-hand findings and grade accordingly.
9. **M11 / U6** — `FUN_0074BB50`'s section is a stack argument and is `"Joystick"` at two LTI sites;
   add `+0x2C` PresentImmediate and `+0x31` Rumble to §4; promote `+0x08` / `+0x0C` to H.
10. **U4.1** — republish §7's record fields against one base (`FUN_00709640`'s return); `+0x14A` and
    `+0x14E` are the same byte.
11. **M4** — the PDA quick-slot fix-pack entry is stronger than §8.2 says and **survives** Pass 1's
    "no user-visible symptom" dismissal: `EnableQuickSlot` exists, does the work, and has zero callers.

Still open after two passes, with recipes: **U1** (`LTIVideoAdvanceDefault`'s body — map's answer
disproved, body region located in `.securom` at `0x02487D20`, needs a one-shot bp at `0x005C13A0`)
and **U3** (7 stolen prologue bytes — 2 of the 9 now read, reconstruction near-forced by encoding
exhaustion plus an adjacent identical encoding, needs a bp at `0x0061C559`). Everything else in the
register is closed.
