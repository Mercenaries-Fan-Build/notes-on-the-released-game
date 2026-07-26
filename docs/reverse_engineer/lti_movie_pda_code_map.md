# LTI (`LTILibName`) + `Movie` — PC code map

**Scope:** the two Lua binding namespaces that drive the PC front-end's **Scaleform movies** and the
**Bink** video player — `LTILibName` (`luaL_Reg` table **`0x00B99C78`**, **52 cfuncs, 2 stubs**) and
`Movie` (**`0x00B99BBC`**, **4 cfuncs, 0 stubs**) — plus the engine→ActionScript **Invoke** helper
they all funnel through, the option/settings blocks they read and write, and the `key=value`
protocol of the 8 KB shell dispatcher `FUN_005C37E0`. Before this pass `LTILibName` was the only
50+-cfunc namespace in the game with **zero coverage anywhere in the project** and no owner in the
Wave-0 Seam G review.

**This map is PC-only by construction.** LTI is the *PC* platform layer (§1); the Xbox 360 devkit
build has no counterpart, so there is no Xbox↔PC marriage to make here — unlike the vehicle,
physics, or audio rows.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) + [`../data/scaleform_gfx_function_map.json`](../data/scaleform_gfx_function_map.json) | the GFx 2.0.48 library itself, `PgScaleformHAL`, the movie-streaming FSM `FUN_0060E4A0`, the FSCommand dispatcher `FUN_0060DE80`→`FUN_00614540`, the widget/movie lifecycle. This map only uses `widget+0x1E0` and the global GFx lock `DAT_01175FB4`, both of which that map already pins |
| [`input_code_map.md`](input_code_map.md) | DirectInput8 device create/poll/acquire (`FUN_0082BA90`, `FUN_004FC0C0`), the `DIERR_INPUTLOST` re-acquire idiom, and the 53-entry controller-name table `PTR_s_Left_Stick___Left_00cf2560`. LTI is the *screen driver* on top of it. ⚠ **Citation correction (2026-07-26):** earlier revisions of this map cited `FUN_004FA570`, `FUN_004FBBA0`, `FUN_004FBC60`, `FUN_004FD930`, `FUN_0082A960`, `FUN_004FBF20` and `0x00EDAE60` *to* that document. None of those tokens appears in it, or anywhere else under `docs/` — reproduce with `grep -ril FUN_004FBBA0 docs/`, which returns only this file. They were this map's own first-hand disassembly laundered as citations; they are now labelled as such below |
| [`../ui/main_menu_structure.md`](../ui/main_menu_structure.md) | the shell screen inventory, `shell.gfx`, the Lua `MrxGuiShell` handler list. **§10 records three corrections to its §5** |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | the Lua 5.1.2 host, the 60-table binding index, and the shared no-op stub `0x006D5640` |
| [`save_serialize_code_map.md`](save_serialize_code_map.md) | the profile/economy singleton `[0x01176054]` that `LTIChoseOnline` writes one byte of |
| [`audio_code_map.md`](audio_code_map.md) | the Bink audio track wiring and the `FUN_00621AB0`/`FUN_00621BC0` in-game cinematic pause path |
| [`../mercs2_licensing_registration_map.md`](../mercs2_licensing_registration_map.md) | EA registration / SecuROM. **§10 records two corrections**: its "unproven telemetry sink" is this map's Invoke helper, and the sink question is *narrowed, not closed* — `FUN_008482F0` does transmit (§10) |

**Sources.** PC decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
`0x00400000`) — every decompiled body below was fetched and read first-hand this pass. Where Ghidra
produced no body (or produced a body with a SecuROM-veiled callee) the function was **disassembled
directly out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`** with capstone, in binary mode;
that is how §2's central finding was made and it is why several rows here are H rather than open.
Binding name→VA: the live Surface-B `.rdata` walk `mods/lua_trace_asi/reference/binding_map.json`
([[lua-trace-asi-surface-b-oracle]]), corroborated entry-for-entry by an independent re-walk of the
raw `.rdata` bytes done here, and by
[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md) (same VA,
same 52/2 counts). Script traffic: `corpus_calls` census over the 370 decompiled scripts in
`docs/mercs2-luacd/`. Lua layer: `docs/mercs2-luacd/src/{shell,resident}/mrxguishell.lua`,
`mrxguipausescreen.lua`, `mrxguiltiprecache.lua`, `mrxguipda.lua`.

> ⚠ The corpus index was **stale** (52 changed files) during the original pass; searches were run
> anyway and the decisive hits (`main_menu_structure.md` §5, `mrxguishell.lua`,
> `scaleform_gfx_function_map.json`, `mercs2_script/DEFERRED.md`) all predate the staleness, so the
> risk was to *new* docs only.

> **Revision, 2026-07-26.** This map has been through a double-blind validation (Phase A derived from
> primary sources with the map unopened) and every finding below was **re-reproduced from the binary
> and the shipped assets before being folded in** — the validation report was treated as a work order,
> not an authority, which mattered: one of its own headline "defects" (the VSync polarity mismatch)
> is retracted here as not-a-bug. Corrections are marked ⚠ inline with the superseded claim visible,
> so a reader who remembers the old text can see what changed and why. The three figures that did not
> reproduce are recorded in §12 rather than adopted.

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read the body
(decomp or disassembly) with a can't-coincide fingerprint — a constant, an IAT slot, a string, or a
table walk · **M** = one strong structural signal · **L/open** = positional or single-witness →
confirm-live. Where a cfunc has **no decompiled body** it is called *binding-only* and its behaviour
is described only as far as the raw disassembly proves it. **25 of the 52** LTI cfuncs have no Ghidra
body: **2** are the shared no-op stub and **23** were read here instruction-by-instruction. Of the 4
`Movie` cfuncs, 1 has a body and 3 were disassembled.

> **Body census — corrected 2026-07-26.** An earlier revision said "20 leaves + **3 genuinely open**"
> and listed `LTIInputGeneralOptions` `0x005C1600`, `LTIInputKMApplyChanges` `0x005C1D00` and
> `LTIInputJoystickApplyChanges` `0x005C33F0` as open, described only as tail calls. **All three have
> ordinary readable bodies** — this map's own trap note ("binding-only means Ghidra had no static
> caller; disassemble it") applied to its own open list. Re-read here:
> `0x005C1D00` = `8b 15 1c 3b ed 00 33 c0 56` (`mov edx,[0x00ED3B1C]; xor eax,eax; push esi`) opening a
> 24-iteration keymap commit loop over `[eax*8 + 0x00EDAE60]`; `0x005C33F0` = `53 56 8b 35 1c 3b ed 00`
> opening the pad twin over `[eax*4 + 0x00B9BCB0]`; `0x005C1600` = `81 ec 80 00 00 00 56` (a 0x80-byte
> frame) then `call 0x0059D8E0` (Lua string fetch) and a compare loop. Corroborated in a second build:
> the v1.1 image `output/_ghidra/securom_dump/genuine_patched_unpacked.exe` carries all three with
> unstolen prologues at `0x005C1D20` / `0x005C3400` / `0x005C1620`.
> **Reading count: 53 of 56 bodies from the dump alone, 55 of 56 once the clean images are admitted**
> (`0x006D5640` is *read* in `mercs2_nodrm_v2/v3.exe` — §8.1). Exactly one body is genuinely unread:
> `LTIVideoAdvanceDefault` `0x005C13A0` (§9.1).

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]), but here it manifests in a form
> [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) §6 calls a *split body* rather than a
> forwarder: the head of a real `.text` function is replaced by `jmp dword [<Sdata slot>]` and the
> rest of the body is left intact immediately after. Ghidra follows the head and reports a
> content-free `thunk_FUN_024xxxxx`; the tail is readable a few bytes further on. §2 turns on exactly
> that.
>
> ⚠ **Offset correction (2026-07-26).** This paragraph used to say "the first **6 bytes** … the tail
> is fully readable at **`entry+0x12`**", and §0.5/§2.1/§12 pinned the resume at **`0x0061C562`**.
> All three figures were wrong, and mutually inconsistent. Measured, `entry = 0x0061C550`:
>
> ```
> 0061C550  ff 25 70 55 45 02   jmp dword [0x02455570]     ; 6 bytes of splice
> 0061C556  62                  (fill)                     ; entry+6
> 0061C557  74 52               je   0x0061C5AB            ; entry+7  -- ORIGINAL CODE, survives
> 0061C559  a1 b4 5f 17 01      mov eax,[0x01175FB4]       ; entry+9  -- BODY RESUMES HERE
> ```
>
> **7 bytes replaced (`entry+0..+6`); the body resumes at `entry+9` = `0x0061C559`.** `0x0061C562` is
> merely where a naive linear disassembler resyncs. Two independent corroborations, both re-derived
> here: (a) the early-out at `0x0061C5AB` is `32 c0 c2 0c 00` = `xor al,al / ret 0xC` with **no
> `pop ebx`**, while the normal exit at `0x0061C5A7` does `pop ebx` — so the stolen branch must fire
> *before* the `push ebx` at `0x0061C559+5`, which puts the whole splice above `0x0061C559`; and
> (b) the v1.1 build wraps the same function *independently* at `0x0061C470` —
> `ff 25 08 d5 4c 02` (**different slot**) `54` (**different fill**) `74 52` (**byte-identical**), and
> in that build the branch resolves to that build's own `xor al,al / ret 0xC` at `0x0061C4CB`. Two
> independent wraps cannot coincidentally emit the same rel8 at the same offset onto the same
> semantic target, so `je <return-false>` at `entry+7` is **read, not inferred**. Reproduce:
> `python -c "…Img(dump).read(0x0061C550,0x14).hex()"` against both images.

---

## 0. Result in one line

**LTI is not a Lua concept and not an acronym anyone in this project has expanded — it is a
directory in the Mercenaries 2 PC source tree** (`D:\Projects\Mercs2_PC\mercs2\LTI\Src\`, C++
namespace `LtiRender::RenderSystem::`), the **PC platform / D3D9 render-device layer**: `RenderDevice.cpp`,
`RenderSystem.cpp`, `DisplayMode.cpp`, `Dx9_State.cpp`, `PgLtiRendererPc.cpp`, `PgLtiBloomPc.cpp`,
`PgLtiBufferPc.cpp`, `PgLtiRendererShadowPc.cpp`, `PgTextureImplLTI.cpp`, `Precache*.cpp`. The
`LTILibName` Lua namespace is that module's **options-screen face**: 52 cfuncs that let the shell's
Lua drive display mode, resolution, refresh, gamma, view distance, the seven advanced-render
toggles, key/joystick rebinding, the precache screen, and the Bink attract/cinematic movies. It is a
**bidirectional Scaleform bridge**: nearly every LTI cfunc that talks to the UI does so
through one previously-undocumented helper, **`FUN_0061C550`** — `IsAvailable(name)` then
`Invoke(name, pretval, GFxValue* args, nargs)` on `widget+0x1E0` under a global GUI/shell critical
section — with the ActionScript function name passed **in EDI**, which is why **250** call sites had
been sitting in the decomp as an unresolved `thunk_FUN_024b5390`. The return leg is
`fscommand` → `FUN_0060DE80`/`FUN_00614540` → Lua `_LTIFscommand` → back into `LTILibName.*`. The
whole namespace is one screen-driver layer over `[0x00ED3B1C]` (input options) and the 72-byte render
settings block at `DAT_00DF6700`, mirrored to `DAT_00DFC320` (committed) and `DAT_00DF6748`
(advanced-page undo), and flushed to `[Render]`, `[Joystick]` and other keys in the settings INI.

> ⚠ **Headline correction, 2026-07-26.** This map used to say *"194 call sites across 63 functions"*
> and *"the single funnel for **all** engine→AS calls in the exe"*. **Both halves were wrong, in
> opposite directions**, and 194 was Ghidra's number in a document whose whole premise is that Ghidra
> got this function wrong (the decomp text contains 192 `thunk_FUN_024b5390(` tokens). Ground truth,
> re-derived here by whole-image byte scan — see §2.1a for the recipe:
>
> | | count |
> |---|---:|
> | `E8 rel32 → 0x0061C550` | **248** |
> | `E9 rel32 → 0x0061C550` (`0x004CEB7C`, `0x006955A1`) | **2** |
> | funnel total (0 outside `.text`, all 13 sections scanned) | **250** |
> | **inlined bypasses** that never touch the funnel | **27** |
> | **static total** | **277** — funnel share **90.3 %** |
>
> So "the single funnel for all" is **false**: 27 sites inline the same
> `[X+0x1E0] → vtbl+0x28 gate → vtbl+0x48 Invoke` sequence directly. This poisoned several §6 ✔
> marks and §11.5's reimplementation instruction; both are fixed below.

---

## 0.5 Master marriage table

| Role | PC addr | Married by | Conf |
|---|---|---|---|
| **`LTILibName` `luaL_Reg` table** | **`0x00B99C78`**, 52 entries, terminator `0x00B99E18` | raw `.rdata` re-walk here + live Surface-B walk + the audit doc's offline walk all agree entry-for-entry | H |
| **Lua global name is literally `LTILibName`** | registrar record **`0x00DFD5E0`** = `{"LTILibName" @0x00BB6E28, 0x00B99C78, ""}` | read the 12-byte `.data` registrar record; matches every shipped call site `LTILibName.LTIVideoEnter()` | H |
| **`Movie` `luaL_Reg` table** | **`0x00B99BBC`**, 4 entries | registrar record `0x00DFD574` = `{"Movie", 0x00B99BBC, ""}` | H |
| **The namespace registrar array** | **base `0x00DFD478`**, **31** × 12-byte `{const char* global, luaL_Reg* table, const char* glueChunk}`, terminator `{0,0,0}` at **`0x00DFD5EC`**, **1103** cfuncs total | walked stride-12 here; the consumer loop `0x005A2D38` proves both base and stride (`mov edi,0xDFD478` … `lea esi,[esi+esi*2] / add esi,esi / add esi,esi` = ×12). `0x00DFD478` has **4** `.text` refs, `0x00DFD514` has **zero**. **9** of the 31 rows carry a non-empty glue chunk | H |
| **↳ `0x00DFD514` is row 13, not a base** | `(0x00DFD514 − 0x00DFD478)/12 = 13` = `{"Graphics", 0x00B9A4D0, ""}` (95 cfuncs) | ⚠ **correction**: this map used to call `0x00DFD514`–`0x00DFD5E0` "an 18-record registrar array". Rows 13…30 inclusive *are* 18 — it was a mid-array slice presented as the array. Everything §1.3 concluded from it is unaffected | H |
| **AS Invoke helper** | **`FUN_0061C550`** — `bool f(GFxValue* args, int nargs, GFxValue* pretval)`, `const char* asName` **in EDI**, `FlashWidget*` in ESI | disassembled: `EnterCriticalSection([0xB05128])` → `movie=widget[0x1E0]` → `vtbl+0x28(name)` → `vtbl+0x48(name, pretval, args, nargs)` → `LeaveCriticalSection([0xB0512C])`; `ret 0xC` | H |
| **…is what `thunk_FUN_024b5390` really is** | head `0x0061C550` = `jmp [0x02455570]`; **7 bytes replaced**, surviving `74 52` = `je 0x0061C5AB` at `entry+7`, body resumes **`0x0061C559`** (`a1 b4 5f 17 01` = `mov eax,[0x01175FB4]`) | ⚠ **correction**: was "6 bytes / `entry+0x12` / resumes `0x0061C562`" — three mutually inconsistent figures, all wrong. Re-measured in the dump **and** in the independently-wrapped v1.1 build; see the preamble | H |
| **Funnel traffic** | **250** direct sites (248 `E8` + 2 `E9`), **142** distinct AS names, **29** of the 250 take the name from a `.data` slot rather than an immediate | ⚠ **correction**: was "194 across 63 functions", which is a Ghidra artefact (192 `thunk_FUN_024b5390(` tokens in the decomp text). Byte scan of all 13 sections; 0 hits outside `.text` | H |
| **…and the funnel is not the only path** | **27** inlined bypasses → **277** static Invoke sites, funnel share **90.3 %** | detector: every `mov r32,[X+0x1E0]` in `.text` (227 of them) followed within 14 instructions by a `[…+0x28]` load and an indirect `call reg` → 28 distinct call sites, minus the funnel's own `0x0061C574` | H |
| **`_GuiInternal.CallFlashScriptFunction`** | **`0x005BB170`**, funnel site `0x005BB3F8` — a **Lua-callable generic Invoke** | reads the AS name from Lua (`[ebp-0x1C]`, filled by `FUN_0059FA40`), clamps the arg count at **`0x40` = 64** (`cmp esi,0x40 / jle` else `mov [ebp-0x10],0x40`), and is the **only** site passing a non-NULL `presult` (`lea ecx,[ebp-0x34] / push ecx`, then `cmp [ebp-0x34],4` to convert a returned string back to Lua). Name from `binding_map.json` table `0x00B99FF8` | H |
| **`GFxValue` marshalling record** | 16 bytes: `{u32 tag; u32 pad; union payload[8]}` — tag **2**=Boolean **3**=Number(double) **4**=String(`char*`) **5**=StringW(`wchar*`); tag **0**=Undefined also occurs, tag 1 never | read off 3 independent builders (`FUN_005C1900`, `FUN_005C0F40`, `FUN_00847FE0`); matches the real `GFxValue::ValueType` enum. Census of tag immediates stored before funnel calls: **2**×133 · **3**×80 · **4**×56 · **5**×14 · **0**×28 | H |
| **Shell FlashWidget handle** | `[0x01175F4C]` cached, else `FUN_00609940([0x01175FB0])` | the first three instructions of 11 LTI cfuncs | H |
| **Global GUI/shell critical section** | `DAT_01175FB4` | `[0x00B05128]`/`[0x00B0512C]` resolve by name to `KERNEL32!EnterCriticalSection`/`LeaveCriticalSection` (import-directory parse). ⚠ **de-specified**: calling it "the **GFx** lock" over-claims — it has ~109 references image-wide, blanketing the whole `0x005C1xxx`–`0x005C3xxx` LTI input block. `scaleform_gfx_function_map.json`'s `0060e4a0` entry reads `*(DAT_01175FB4+0x234)`, i.e. treats it as a pointer to the GFx singleton whose *head* is the CRITICAL_SECTION. "Global GUI/shell lock at the head of the GFx singleton" is what the evidence supports | H (lock) / M (ownership) |
| **Render settings — live block** | **`DAT_00DF6700`**, 0x48 bytes (`rep movsd` × 0x12) | `FUN_005C0A20` / `FUN_005C1210` copy loops | H |
| **Render settings — committed mirror** | **`DAT_00DFC320`** (constant delta **+0x5C20** from live) | every `LTIVideoSwitchOpt1` branch writes both, at the same intra-block offset | H |
| **Render settings — advanced-page undo** | **`DAT_00DF6748`** (live + 0x48) | `FUN_005C1210` snapshots live→here; `FUN_005C0A20` restores here→live | H |
| **Working display-mode tuple** | `DAT_00EDAF7C` (device), `DAT_00EDAF80`/`DAT_00EDAF84` (packed mode) | shared by all five mode/res/refresh cfuncs and `FUN_00755590` | H |
| **Display-mode enumerator** | **`FUN_00755590`** = `GetNextMode`, **`FUN_00755770`** = `GetPrevMode` | own log strings `"GetNextMode(): Display mode %u x %u…"` / `"GetPrevMode(): …"` | H |
| **Settings INI writer** | **`FUN_0074BB50(section /* stack */)`**, key in EDI, value in ESI → `GetPrivateProfileIntA([0xB050B4])` then, on mismatch, `sprintf("%i")` + `WritePrivateProfileStringA([0xB050A8])` | read body: `sub esp,0x20 / push ebx / mov ebx,[esp+0x28]` — the **section is a stack argument**, not a fixed literal. ⚠ **correction**: this row used to say *"section literal is `Render` at every LTI call site"*, which contradicted §3 row 23. Census of all **47** call sites: Render 28 · Audio 5 · Network 5 · **Joystick 4** · Game 3 · Mouse 2. Two of the seven LTI sites write `[Joystick]`: `0x005C178E` → `Invert` (in `FUN_005C1470`) and `0x005C18EB` → `Rumble` (in `FUN_005C18B0`) | H |
| **Input-options object** | **`[0x00ED3B1C]`**; `+0xFC0` KM table valid · `+0xFC4` rebind armed · `+0xFC8` joystick mode · `+0xFCC` text-input mode · `+0x54` · keymap array `+0xEA0 + i*8` | read **first-hand here** (not cited — see the `input_code_map.md` note in the boundary table) from `FUN_005C1900`, `FUN_005C2950`, `FUN_005C3690`, `FUN_005C36B0`, `FUN_005C3780`, `FUN_005C37A0`, `FUN_005C1CC0`, `FUN_005C1D00` | H |
| **Default keymap source array** | **`0x00EDAE60`**, 24 × 8 bytes | `LTIInputKMApplyChanges` `0x005C1D13`: `mov ecx,[eax*8 + 0x00EDAE60]` → `mov [edx + eax*8 + 0xEA0], ecx`, loop bound `cmp eax,0x17`. **First-hand finding, not a citation** | H |
| **Bindable action count** | **24**, pushed as `Invoke("LTIInputMaxActionBind",[24.0])` from `DAT_00BEB948` | read the double constant | H |
| **Action-name token table** | `PTR_DAT_00D1E5D8[0..23]` → stringdb tokens `[0xa4bcfdd8]` … `[0x72abfa75]`; out-of-range → `""` (`DAT_00BA8B09`) | walked the pointer array | H |
| **Bink player** | `Movie.Pause`/`Resume` and `LTIMoviePause`/`Resume` call **`binkw32.dll!_BinkPause@8`** via IAT `[0x00B055FC]`; record `+0x30` = play state, a **dword** (1=playing, 2=paused), `+0x38` = HBINK | slot resolved by name from the import directory's **OriginalFirstThunk** (the dump's FirstThunk is bound, so a FirstThunk parse yields nothing). `LTIMoviePause` `0x005C0637`: `cmp dword [eax+0x30],1` / `mov dword [eax+0x30],2` / `push 1 / push [eax+0x38] / call [0xB055FC]` | H |
| **Movie record lookup** | **`FUN_00709640(name)`** — inline m2 FNV-1a (`0x811C9DC5`, `\|0x20` lowercase fold, `^0x2A` then `*0x1000193` final) over records of stride **0x16C**, **record base `0x017C64F0`**, hash field at record `+0x08` | read body: `mov edi,0x17C64F8` (first hash), `add edi,0x16c`, `cmp edi,0x17C6AA8 / jl` (exclusive end guard), and on hit `imul eax,eax,0x16c / add eax,0x17C64F0` — **so the function returns record base `0x017C64F0`+i·0x16C, not `0x017C64F8`**. §7 restates every field against this one base | H |
| **Movie start** | **`FUN_00709CB0(flag)`** — takes **record+4**, not the record base; formats `"%sMovies\%s.bik"` (`0x00BD1EB0`) from root `".\Data\"` (`0x00ED2010`); reads `[Render] FirstRun` and clears it | read body. ⚠ note the **backslash** — the map used to print forward slashes. It also formats `"%sMovies\%s.ogg"` (`0x00BD1EC0`) into `DAT_00F79218`; **no `.ogg` asset ships** — see §7 | H |
| **Shared no-op stub** | **`0x006D5640`** — its real body is **`33 c0 c3`** = `xor eax,eax; ret`. 62 bindings across the binding map point at it; 2 of them are LTI (`LTIMovieStart`, `LTIupdateSupportQuickSlot`) | ⚠ **correction**: this row used to grade the mechanism **M** because "the static image holds only `jmp 0x6FCD20C0`, resolved by SecuROM at load". That `E9` is **not SecuROM** — it is a `pmc_bb.dll` runtime **hot-patch captured in the memory dump**. `mercs2_nodrm_v2.exe` / `v3.exe` (built from the *on-disk* decrypted exe) and the v1.1 build's equivalent slot `0x006AEF90` all read `33 c0 c3`. Reproduce by diffing `.text` between `mercs2_unpacked.exe` and `mercs2_nodrm_v3.exe`: **exactly 3** byte-runs differ, all 5-byte `E9` splices — `0x005E9DE0`, `0x005E9F40`, `0x006D5640` | H (behaviour now **read**, in two images) |

---

## 1. What "LTI" is — and what it is not

### 1.1 Proven: a source module, not a Lua concept — H

Scanning printable strings in `output/_ghidra/securom_dump/mercs2_unpacked.exe` for source paths
yields **45 distinct** `.cpp/.h` paths, of which **16 are under one directory**:

```
D:\Projects\Mercs2_PC\mercs2\LTI\Src\RenderDevice.cpp        …\RenderSystem.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\DisplayMode.cpp         …\Dx9_State.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiRendererPc.cpp     …\PgLtiRendererShadowPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiBloomPc.cpp        …\PgLtiBufferPc.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgTextureImplLTI.cpp    ..\LTI\src\Dx9_State.h
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheMain.cpp        …\PrecacheTexture.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheSurface.cpp     …\PrecacheVertexBuffer.cpp
D:\Projects\Mercs2_PC\mercs2\LTI\src\PrecacheIndexBuffer.cpp …\PrecacheVertexDecl.cpp
```

Its sibling top-level modules in the same tree are `Pal`, `Pangea`, `Odin`, `Lua-5.1.2`. The C++
namespace is visible in two RTTI-style assert strings: **`LtiRender::RenderSystem::ReadSurfaceData`**
at **`0x00BD470C`** and **`…::WriteSurfaceData`** at **`0x00BD4764`**, both in `.rdata`, both starting
`4c 74 69 52 65 6e 64 65 72 3a 3a` (`"LtiRender::"`). So **LTI = the PC platform/render-device
layer** — D3D9 device + display-mode enumeration + render state + the PC bloom/shadow renderers +
the GPU-resource precache system. 40+ `PgLti*` shader names (`PgLtiSkin1VP.sho`,
`PgLtiSkin1ShadowVP.sho`, …) and the shipped `shell/LTI_precache.gfx` corroborate.

> ⚠ **Correction, 2026-07-26.** This paragraph used to cite those two strings at **`0x007D470C`** and
> **`0x007D4764`** — a `BD`→`7D` digit slip, made twice. `0x007D470C` is inside `.text` and holds
> machine code (`4c 24 08 51 83 c7 08 89 44 24 10 e8` = the tail of a `mov ecx,[esp+8]`); `0x007D4764`
> holds `46 44 2b 46 40 …`. The finding was right; the citations were unusable as printed.

That single fact explains the whole namespace: the LTI Lua bindings are **video options, display
mode, gamma, view distance, advanced render toggles, and the precache screen** — i.e. exactly what a
`RenderDevice`/`DisplayMode`/`Precache` module owns — with input remapping and the Bink hooks
carried along because they live on the same PC options screens.

### 1.2 Not proven: what the letters stand for — open

**No string in the binary expands the acronym.** Every `LTI`-containing string is either a module
path above, the `LtiRender::` namespace, or an API name catalogued in §3/§6. Plausible expansions
("Low-level Technology Interface", "Layered Technology Interface", …) are **guesses and are not
recorded here as fact**.

> ⚠ **Count correction.** This paragraph used to say "all **218** `LTI`-containing strings". That
> figure is not reproducible. Independent extraction here (printable runs ≥ 4 bytes, whole image,
> all 13 sections) gives **172** — 171 in `.rdata`, 1 in `Srdata`. Case-insensitive `lti` gives 415,
> which is not 218 either. The *conclusion* is unaffected and has now been reached three times
> independently.

**The acronym is not determinable from any source available to this project**, and that is a finding
rather than a gap: it is absent from the exe, from all **83** shipped `.gfx` movies, from the Xbox-360
PDB symbol corpus `docs/mercs2-pdb-analysis/` (zero `Lti`/`LTI` symbols — consistent with a PC-only
module), and from `C:\GOG Games\The Saboteur\Saboteur.exe`, the same studio's next title on the same
engine family (zero `LTI`/`PgLti`/`LtiRender` strings), so there is no sibling-title corroboration
either.

`docs/ui/main_menu_structure.md` §5 heads its section **"LTI (Lua To Interface)"**. That expansion is
**invented** — it has no support in any primary source and is contradicted by the module contents
(the same directory holds the D3D9 device and the GPU precache system, neither of which touches Lua).
§10 records the correction; that document is not edited from here.

One caveat in the other direction, worth stating so the two are not conflated: the **Lua table**
named `LTILibName` is *broader* than the render module — it also carries input remapping, profile,
camera, shell-state and movie entry points. "LTI = the render-device layer" describes the **source
module**, not the **contents of the Lua table**.

### 1.3 The namespace name is `LTILibName` — H

The Lua global is not `Lti`. `.data` at **`0x00DFD478`** holds a **31**-record registrar array of
`{const char* globalName, luaL_Reg* table, const char* glueChunk}`, terminated by `{0,0,0}` at
`0x00DFD5EC`; its last record is

```
0x00DFD5E0:  0x00BB6E28 -> "LTILibName"    0x00B99C78 (the table)    "" (empty glue chunk)
```

and the shipped Lua agrees verbatim — `mrxguishell.lua`, `mrxguipausescreen.lua`, `mrxguipda.lua`
all call `LTILibName.LTIVideoEnter()`, `LTILibName.ChangeShellState(true)`, etc. Corpus check:
`LTILibName.` appears **220** times across the 370 `.lua` files in `docs/mercs2-luacd/` (**221** if
the corpus's own `.md` index files are counted — one prose hit in `05_gui_hud_shell.md:466`); `Lti.`
appears **0** times. The raw `.rdata` reads `…\x00\x00\x00\x00LTILibName\x00\x00LTIVideoSetSwitchOpt1…`,
so the name really is the C identifier: somebody wrote `"LTILibName"` where they meant the *value* of
a `LTILibName` constant. Whatever the cause, **`LTILibName` is the shipped global**, and the same
array proves `Movie` for `0x00B99BBC`. This closes the corresponding open item in
`mercs2_script/DEFERRED.md` (see §11).

> ⚠ **Correction, 2026-07-26.** This section used to give the array as "`.data` at **`0x00DFD514`** …
> an **18-record** registrar array". That is a **mid-array slice presented as the array**.
> `(0x00DFD514 − 0x00DFD478)/12 = 13`, so `0x00DFD514` is **row 13 = `Graphics`**
> (`0x00B9A4D0`, 95 cfuncs), and rows 13…30 inclusive happen to number 18. Decisive: the consumer
> loop at `0x005A2D38` walks from `0x00DFD478`, and `0x00DFD478` has **4** `.text` references
> (`0x005A2D3A`, `0x005A2D49`, `0x005A2DED`, `0x005A2DF3`, plus `0x005A2D55` reaching `+4`) while
> `0x00DFD514` has **zero**. Nothing this section concludes *from* the array changes.

**The full 31 rows**, walked here, with cfunc counts — **1103 cfuncs total**:

| row | VA | global | cfuncs | row | VA | global | cfuncs |
|---|---|---|---:|---|---|---|---:|
| 0 | `00DFD478` | `_SYS` | 6 | 16 | `00DFD538` | `Net` | 92 |
| 1 | `00DFD484` | `Sys` | 64 | 17 | `00DFD544` | `math` | 17 |
| 2 | `00DFD490` | `Pg` | 80 | 18 | `00DFD550` | `Camera` | 14 |
| 3 | `00DFD49C` | `Object` | 87 | 19 | `00DFD55C` | `Junk` | 24 |
| 4 | `00DFD4A8` | `Player` | 107 | 20 | `00DFD568` | `ObjectState` | 9 |
| 5 | `00DFD4B4` | `Event` | 4 | 21 | `00DFD574` | **`Movie`** | 4 |
| 6 | `00DFD4C0` | `Ai` | 66 | 22 | `00DFD580` | `Animation` | 6 |
| 7 | `00DFD4CC` | `Human` | 32 | 23 | `00DFD58C` | `VO` | 11 |
| 8 | `00DFD4D8` | `Debug` | 6 | 24 | `00DFD598` | `Weapon` | 9 |
| 9 | `00DFD4E4` | `Vehicle` | 40 | 25 | `00DFD5A4` | `String` | 1 |
| 10 | `00DFD4F0` | `Airstrike` | 12 | 26 | `00DFD5B0` | `Table` | 2 |
| 11 | `00DFD4FC` | `Gui` | 38 | 27 | `00DFD5BC` | `Report` | 5 |
| 12 | `00DFD508` | `_GuiInternal` | 114 | 28 | `00DFD5C8` | `Disguise` | 1 |
| 13 | `00DFD514` | `Graphics` | 95 | 29 | `00DFD5D4` | `FactionZone` | 1 |
| 14 | `00DFD520` | `Sound` | 88 | 30 | `00DFD5E0` | **`LTILibName`** | 52 |
| 15 | `00DFD52C` | `ObjectFilter` | 16 | — | `00DFD5EC` | `{0,0,0}` terminator | — |

**Nine** rows carry a **non-empty** glue chunk (§9.8 previously said three; 19 rows hold a *pointer*,
but 10 of those point at `""`): `_SYS` (`_G._MODULES = {}; _MODULESMETATABLE = …`, 491 B), `Sys`
(`_tostring = tostring; tostring = Sys.ToStringL; …`, 98 B), `Pg` (`GetGuidByName = Pg.GetGuidByName; …`,
460 B), `Debug` (`ASSERT = Debug.Assert; print = Debug.Printf`, 43 B), `Gui` (`_G.Marker = {} …`, 745 B),
`_GuiInternal` (`_GuiInternal.nVersion = 2`, 25 B), `ObjectFilter`
(`_OFMETATABLE = { __gc = ObjectFilter._GC, __index = ObjectFilter }`, 66 B), `math` (`Math = math`,
11 B), `VO` (`VO.PRIORITY_CINEMATIC = 0; VO.PRIORITY_SCRIPTED_BRIEFING = 1; …`, 193 B).

---

## 2. The bridge: `FUN_0061C550` — 90 % of the Lua→ActionScript calls in the game

### 2.1 The find — H

Ghidra renders the call sites as `thunk_FUN_024b5390(<ptr>, <n>, 0)` with no
callee body, because `0x024B5390` lies in `.securom`. Two prior docs stopped there:
`mercs2_licensing_registration_map.md` calls it an "unproven online/telemetry sink"; the LTI bodies
looked like they were building structures for nothing.

Disassembling a call site directly settles it. `LTIVideoNextRefresh` (`0x005C0F40`, 178 B), tail:

```asm
005c0fc3  mov   dword [esp+0x10], 3          ; GFxValue.tag = VT_Number
005c0fd3  push  0                            ;   pretval
005c0fd5  fstp  qword [esp+0x1c]             ; GFxValue.payload = (double)refreshIndex
005c0fd9  push  1                            ;   nargs
005c0fdb  lea   edx, [esp+0x18]
005c0fdf  push  edx                          ;   args
005c0fe0  mov   edi, 0xbb6f38                ;   name = "LTIVideoSetRefresh"   <-- in EDI
005c0fe5  call  0x0061c550
```

`0x0061C550` is a **SecuROM split body**: 7 bytes are replaced by `jmp dword [0x02455570]` plus a fill
byte; the original `je` survives at `entry+7` and the rest of the body resumes at **`0x0061C559`**,
intact. Full listing, byte-for-byte:

```asm
0061c550  ff 25 70 55 45 02  jmp   dword [0x02455570]     ; SecuROM splice (6 B)
0061c556  62                 (fill)
0061c557  74 52              je    0x0061c5ab             ; SURVIVING original: "no movie" early-out
0061c559  a1 b4 5f 17 01     mov   eax, [0x01175fb4]      ; <-- BODY RESUMES HERE
0061c55e  53                 push  ebx
0061c55f  50                 push  eax
0061c560  32 db              xor   bl, bl
0061c562  ff 15 28 51 b0 00  call  dword [0xb05128]       ; KERNEL32!EnterCriticalSection
0061c568  8b 8e e0 01 00 00  mov   ecx, [esi+0x1e0]       ; GFxMovieRoot* on the FlashWidget
0061c56e  8b 11              mov   edx, [ecx]             ; vtable
0061c570  8b 42 28           mov   eax, [edx+0x28]        ; vtbl+0x28  = IsAvailable(path)
0061c573  57                 push  edi                    ;   name  <-- arrives in EDI
0061c574  ff d0              call  eax
0061c576  84 c0              test  al, al
0061c578  74 1f              je    0x61c599                ; AS function absent -> silently do nothing
0061c57a  8b 44 24 0c        mov   eax, [esp+0xc]         ;   nargs
0061c57e  8b 8e e0 01 00 00  mov   ecx, [esi+0x1e0]
0061c584  8b 11              mov   edx, [ecx]             ; <-- FRESH vtable load (see note)
0061c586  8b 52 48           mov   edx, [edx+0x48]        ; vtbl+0x48  = Invoke(name, pretval, args, nargs)
0061c589  50                 push  eax
0061c58a  8b 44 24 0c        mov   eax, [esp+0xc]         ;   args
0061c58e  50                 push  eax
0061c58f  8b 44 24 18        mov   eax, [esp+0x18]        ;   pretval
0061c593  50                 push  eax
0061c594  57                 push  edi                    ;   name
0061c595  ff d2              call  edx
0061c597  8a d8              mov   bl, al
0061c599  a1 b4 5f 17 01     mov   eax, [0x01175fb4]
0061c59e  50                 push  eax
0061c59f  ff 15 2c 51 b0 00  call  dword [0xb0512c]       ; LeaveCriticalSection
0061c5a5  8a c3              mov   al, bl
0061c5a7  5b                 pop   ebx                    ; <-- normal exit POPS
0061c5a8  c2 0c 00           ret   0xc
0061c5ab  32 c0              xor   al, al                 ; <-- early-out does NOT pop
0061c5ad  c2 0c 00           ret   0xc
```

Two things the previous revision of this listing got wrong, both fixed above:

* it pinned the resume at `0x0061C562` and described the splice as 6 bytes in one place and
  `entry+0x12` in another. **It is 7 bytes replaced, resume at `0x0061C559`** — see the preamble for
  the `pop ebx` asymmetry and the two-build proof that `74 52` is original code.
* it jumped from `0061c57e` straight to `0061c586`, **silently dropping `0061c584 mov edx,[ecx]`**.
  As printed, `edx` looked like a stale value carried over from the `IsAvailable` path; it is a fresh
  vtable load.

**What remains unread** is the 7 bytes at `entry+0..+6` (§9.3), and the reconstruction is now
near-forced rather than merely plausible — see §9.

The identical `vtbl+0x28` → `vtbl+0x48` sequence appears **inlined and fully decompiled** in
`FUN_005C1900` (`LTIInputKMEnter`), which is the independent witness that fixes the semantics.

**Signature: `bool ShellInvoke(GFxValue* args, int nargs, GFxValue* pretval)` — `const char* asName`
in EDI, `FlashWidget*` in ESI.** The register-passed name is exactly why Ghidra's `__cdecl` guess
produced a nonsense arg list. That is byte-for-byte Scaleform's
`GFxMovieRoot::Invoke(const char*, GFxValue* presult, const GFxValue* pargs, UInt numArgs)`.

### 2.1a How many call sites there really are — H

Reproduce both numbers with a byte scan; no Ghidra, no decomp text.

**Funnel sites.** Scan every section for `E8`/`E9` + `rel32` whose target is `0x0061C550`:

```python
for i in range(len(sec)-5):
    if sec[i] in (0xE8, 0xE9):
        rel = struct.unpack_from('<i', sec, i+1)[0]
        if (sec_va + i + 5 + rel) & 0xFFFFFFFF == 0x0061C550: hit(sec_va + i)
```

→ **248 `E8` + 2 `E9`** (`0x004CEB7C`, `0x006955A1`) = **250**, and **0 hits outside `.text`** across
all 13 sections. Every one of the 250 re-validates as a real instruction under linear disassembly —
no false positives from data that happens to encode a matching displacement.

**The name behind each site.** Back-scan for the last write to EDI:

| source | sites |
|---|---:|
| `mov edi, imm32` → `.rdata` literal | ~220 |
| `mov edi, [<.data slot>]` — **27 distinct slots**, statically initialised | **29** |
| Lua-supplied string (`0x005BB3F8`, `mov edi,[ebp-0x1C]`) | 1 |
| **distinct AS names** | **142** |

The slot group lives in a **contiguous 37-entry `.data` name table at `0x00D121B8`–`0x00D12248`**
(`loadProfile`, `loadDefaultProfile`, `noDefaultProfile`, `getListProfiles`, `profileName`,
`keyboardEntry`, `renameKeyboardEntry`, `AddProfile`, `ProfilesComplete`, `EnableUsingFakeProfile`,
`serverOnline`, `serverAccept`, `serverEAagreement`, `profileCharacter`, `joingameSavegame`,
`joingameFilter{FriendlyFire,Mission,Map}`, `videoBrightness`, `gameSensitivity`, `gameInvert`,
`gameRumble`, `gameAutoSave`, `gameAutosave`, `gameTutorials`, `videoSubtitles`, `gameSubtitles`,
`audioSFX`, `audioMusic`, `audioDialog`, `addSaveGame`, `saveGameSlot`, `maximumProfiles`,
`multiplayerHost`, `multiplayerClient`, `player2Name`, `videoWidescreen`). A `mov edi, <literal>`
harvest — which is what §12 said was done — cannot see any of them.

**Inlined bypasses.** The compiler inlined the same helper in several translation units. Detector:
every `mov r32, [X+0x1E0]` in `.text` (**227** occurrences) followed within 14 instructions by a
`mov r,[…+0x28]` and an indirect `call reg` → **28 distinct call sites**, one of which is the funnel's
own `0x0061C574`, leaving **27 genuine bypasses** at

```
0x004FAAEE 0x004FB499 0x005C1A0B 0x005C1AFE 0x005C1BDE 0x005C1C40 0x005C1FAB 0x005C207C
0x005C20DA 0x005C2A6D 0x005C2B41 0x005C2C02 0x005C2C75 0x005C2DAD 0x005C2E12 0x005C3600
0x005C365D 0x005C422A 0x005C44BE 0x0061C459 0x0061C4A4 0x0061C6EE 0x0061C7DD 0x00620C86
0x008487AB 0x0084883C 0x008488C5
```

carrying names including `LTIInputControllerNames`, `LTIInputKMSetActionName`, `LTIInputKMKeyMap`,
`LTIInputKMUpdateTable`, `LTIInputJoystickMap`, `LTIInputJoystickUpdateTable`,
`LTIInputSeeButtonsPushed`, `LTISetUSZip`, `LTI_TOSText`, `addDropDownItem`, `clearDropDownItem`,
`controllerDisplay`, `confirmButtonReversed`, `leftAnalog`/`rightAnalog`, `AddGPSLine`,
`setTerritory`. **Static total 250 + 27 = 277; the funnel carries 90.3 %.**

> **Do not quote a "distinct containing functions" figure.** It is not a stable quantity — it depends
> entirely on the function-boundary model, and the candidate models disagree badly. Ghidra's decomp
> text yields 62–63; a start-set union model yields 73–74; a re-harvest of decomp starts done here
> yields **47**. Three methods, three answers, same 250 sites. The **site count is the fact**; the
> function count is an artefact of whoever drew the boundaries. The map's original "63 functions" is
> not a corroboration of anything.

### 2.1b The funnel is also a **Lua-callable generic Invoke** — H

Funnel site `0x005BB3F8` is the one site whose AS name is not statically knowable: it comes from
`[ebp-0x1C]`, filled by `FUN_0059FA40`, a Lua string accessor. Its containing function `0x005BB170`
has `callers=[]` in Ghidra because it is itself a **binding** — `binding_map.json` table `0x00B99FF8`
(114 entries) names it **`_GuiInternal.CallFlashScriptFunction`**, confirmed here by walking that
table.

It resolves a widget by Lua id, takes an **arbitrary AS function name from Lua**, marshals further Lua
arguments into `GFxValue`s (typing each: tag 3 number / tag 2 boolean / tag 4 or 5 string) — clamped
at **`0x40` = 64** (`0x005BB275: cmp esi,0x40 / jle` else `mov dword [ebp-0x10],0x40`) — calls
`FUN_0061C550` with a **non-NULL `presult`** (`0x005BB3E2: lea ecx,[ebp-0x34] / push ecx`), and then
at `0x005BB405` reads `[ebp-0x34]`, compares the tag to `4` (`VT_String`) and converts the **return
value** back onto the Lua stack. **It is the only site in the game that reads an Invoke result.**

The Lua layer wraps it as `FlashWidget:CallActionScriptCallback(sName, tArgs)`
(`mrxguibase.lua:1274`), which has **176 call sites** across the two Lua corpora — 120 with a literal
name (**57 distinct**) and 56 with a variable name. Consequences:

* **§6's ActionScript vocabulary is not a closed set.** Static harvest = 142 (funnel) + the inlined
  additions = ~155; the Lua literals add **41 more** → **≈196 distinct names statically knowable**,
  plus 56 sites that name the function only at runtime. §6 lists roughly 70.
* **`presult` is used.** §11.5's reimplementation rule needs a return channel.
* **64 is the argument ceiling** a reimplementation must support, not the 1–6 seen at LTI sites.
* `_GuiInternal.CreateMovieWidget` / `SetMovieFile` / `PlayMovie` / `PauseMovie` / `StopMovie` /
  `GetMovieCurrentFrameNumber` / `SetMovieEndCallback` (`0x005BC1A0`–`0x005BC640`) live in the same
  table — the concrete VAs behind §3.1's claim that MovieWidget superseded `Movie.*`.

### 2.2 Two consequences worth acting on

1. **`IsAvailable` makes a wrong AS name a silent no-op.** There is no log, no assert, no return
   check at most call sites. **Four such no-ops are real and shipped**, established by an exact
   NUL-delimited token census over the decompressed payload of all **83** movies
   (`zlib.decompress(open(gfx,'rb').read()[8:])`, then search for `name + b'\0'`):

   | AS name the engine Invokes | funnel sites | defined in a shipped movie? |
   |---|---:|---|
   | `ProfilesComplete` | 2 | **no — 0 of 83** |
   | `AddProfile` | 1 | **no — 0 of 83** |
   | `loadProfile` | 1 | **no — 0 of 83** |
   | `joingameSavegame` (`.data` slot `0x00D121F0`) | 1 | **no** — SHELL.gfx spells it `joingameSaveGame`, a **case mismatch** |

   All four are dead pushes into `IsAvailable`.

   > ⚠ **Retraction.** This item used to point at `LTIVideoSetVSync` (`0x00BB6F90`) vs
   > `LTIVideoSetVsync` (`0x00BB7398`) as the candidate defect, hedged pending confirm-live. **That
   > pair is not a defect** and the item is closed — see §9.2. The mechanism was right; the example
   > was wrong. Use the four above instead.

2. **`GFxValue` is a 16-byte record**, tag at `+0`, payload at `+8`. Tags `2/3/4/5` =
   Boolean/Number/String/StringW are the *used* set; tag `0` (Undefined) also occurs and tag `1`
   (Null) never does. Census of tag immediates stored before funnel calls: **2**×133 · **3**×80 ·
   **4**×56 · **5**×14 · **0**×28. Arrays are built by
   `push <ctor>; push <count>; push 0x10; lea ecx; call 0x00401860`. Anything reimplementing or
   hooking this layer must match that stride; three independent builders in the binary confirm it.

### 2.3 The return leg — cited, not re-derived

`fscommand("<name>")` from AS → `GFxFSCommandHandler::Callback` **`FUN_0060DE80`** (m2-hashes the
command, ~15 hard cases) → fallback parser **`FUN_00614540`** → the Lua GUI bridge
**`FUN_0060994E`** → `mrxgui` `_LTIFscommand(oFlash, sFuncName)` → a long `if/elseif` chain that
calls back into `LTILibName.*`. **Three** of those four engine functions are classified in
[`../data/scaleform_gfx_function_map.json`](../data/scaleform_gfx_function_map.json)
(`layer=engine_integration`, `class=ExternalInterface`/`LuaBinding`) — `0060de80`, `00614540`,
`0060994e`. ⚠ **Correction**: this used to say "all four". `0x0061C550` is **absent** from that file,
as is `FUN_00847FE0` — `grep -c 0061c550 docs/data/scaleform_gfx_function_map.json` returns 0. §10
records what to add. The Lua half is
`docs/mercs2-luacd/src/shell/mrxguishell.lua` and `…/resident/mrxguipausescreen.lua`.

So the full round trip for one option click is:

```
shell.gfx  --fscommand("LTIVideoNextRes")-->  FUN_0060DE80 -> FUN_00614540 -> FUN_0060994E
        -> Lua _LTIFscommand -> LTILibName.LTIVideoNextRes()          [Lua -> engine]
        -> FUN_005C0CE0 -> FUN_00755590 (GetNextMode)
        -> FUN_0061C550 x3: Invoke("LTIVideoSetRes"|"LTIVideoSetResolution"|"LTIVideoSetRefresh")
                                                                       [engine -> AS]
```

---

## 3. The `LTILibName` binding surface — all 52, name → VA

Table `0x00B99C78`, 8 bytes/entry, terminator `{NULL,NULL}` at `0x00B99E18`.
**⬤** = Ghidra body · **◐** = no Ghidra body, read here from raw disassembly · **○** = still unread.
**calls** = call sites in `docs/mercs2-luacd/` (**220** over the 370 `.lua` files; **48 of 52** are
called; `LTILibName.` is the only form that counts — `MrxGuiLTIPrecache` ×45, `_LTIFscommand` ×8 and
`LTI_precache` ×13 are ActionScript names passed to `SetFlashEventHandler`, not cfunc calls).
Caveat for anyone re-running the census: four of the fourteen files exist byte-identically under both
`src/resident/` and `src/shell/`, so the **deduplicated** site count is 148. **After this pass exactly
one row is ○** (#17).

| # | Name | name str | cfunc VA | | calls | What it does (evidence in §4–§8) | Conf |
|---|---|---|---|---|---|---|---|
| 0 | `LTIMovieStart` | `0x00BB6DF4` | `0x006D5640` | ◐ | 0 | **shared no-op stub** `xor eax,eax; ret` — not implemented on PC. Body **read** in `mercs2_nodrm_v2/v3.exe` (§8.1). Also absent from all 83 `.gfx` | H |
| 1 | `LTIMovieStop` | `0x00BB6DE4` | `0x005C05A0` | ◐ | 0 | name→`FUN_00709640`; log `"MOVIE Stop(): Stopping due to movie stopped"`; `rec+0x14E = 1` | H |
| 2 | `LTIMoviePause` | `0x00BB6DD4` | `0x005C0600` | ◐ | 0 | if `rec+0x30==1` → `=2`, `BinkPause(rec+0x38, 1)` | H |
| 3 | `LTIMovieResume` | `0x00BB6DC4` | `0x005C0660` | ◐ | 0 | if `rec+0x30==2` → `=1`, `BinkPause(rec+0x38, 0)` | H |
| 4 | `LTIVideoEnter` | `0x00BB6DB4` | `0x005C0A20` | ⬤ | 6 | enter Video page: restore live block from committed (or from the advanced-undo snapshot), re-read the device mode, `FUN_005C0870` | H |
| 5 | `LTIVideoSwitchMode` | `0x00BB6DA0` | `0x005C0AF0` | ⬤ | 6 | toggle fullscreen/windowed via `GetNextMode`; Invokes `LTIVideoSetMode`, `…VideoViewDistance`, `…SetRes`, `…SetRefresh` | H |
| 6 | `LTIVideoNextRes` | `0x00BB6D90` | `0x005C0CE0` | ⬤ | 6 | `GetNextMode` on width/height; Invokes `LTIVideoSetRes`, `LTIVideoSetResolution`, `LTIVideoSetRefresh` | H |
| 7 | `LTIVideoPrevRes` | `0x00BB6D80` | `0x005C0E10` | ⬤ | 6 | as above via `GetPrevMode` `FUN_00755770` | H |
| 8 | `LTIVideoNextRefresh` | `0x00BB6D6C` | `0x005C0F40` | ⬤ | 6 | `GetNextMode` on refresh only; Invoke `LTIVideoSetRefresh` | H |
| 9 | `LTIVideoPrevRefresh` | `0x00BB6D58` | `0x005C1000` | ⬤ | 6 | as above, `GetPrevMode` | H |
| 10 | `LTIVideoSetGamma` | `0x00BB6D44` | `0x005C10C0` | ◐ | 3 | float arg → `DAT_00DF6720` = the **raw** slider as an int64; the **transformed** value `1.5 − f*0.01` goes only to `FUN_0074AE20(0x017CFAF0, …)`. ⚠ was "`DAT_00DF6720 = (i64)(1.5 − f*0.01)`" — see §4 | H |
| 11 | `LTIVideoGetViewDistance` | `0x00BB6D2C` | `0x0063EF20` | ⬤ | 2 | **6 bytes: `mov eax,1; ret`** — claims 1 Lua result but pushes none, so it echoes its own argument. Functionally a no-op | H |
| 12 | `LTIVideoApplyChanges` | `0x00BB6D14` | `0x005C1140` | ⬤ | 6 | `FUN_0074C7A0()` (commit) + `FUN_00753D40()` (apply/serialize) | H |
| 13 | `LTIVideoDefault` | `0x00BB6D04` | `0x005C1160` | ◐ | 2 | 5 hardware probes (`FUN_005E6820/005E69C0/0074BC70/0074C380/0074C520`) pick preset **1 or 3** → `FUN_007546E0(DAT_00DF6700, preset)`; then `FUN_005C13A0(0)` + `FUN_005C0870` | H |
| 14 | `LTIVideoCancel` | `0x00BB6CF4` | `0x005C11D0` | ◐ | 6 | restore gamma from the committed copy `DAT_00DFC340` → `FUN_0074AE20` | H |
| 15 | `LTIVideoAdvanceEnter` | `0x00BB6CDC` | `0x005C1210` | ◐ | 8 | `rep movsd 0x12` live→`DAT_00DF6748` (undo snapshot); `DAT_01175F2A = 1`; `FUN_005C06C0` pushes the advanced page | H |
| 16 | `LTIVideoSwitchOpt1` | `0x00BB6CC8` | `0x005C1240` | ⬤ | 3 | **the advanced-video setter** — one encoded index for all 7 toggles (§5.1) | H |
| 17 | `LTIVideoAdvanceDefault` | `0x00BB6CB0` | `0x005C13A0` | ○ | 6 | SecuROM steal (`ff 25 88 87 45 02` = `jmp [0x02458788]`). ⚠ **the map's "body resumes `0x005C13B0`" is CONTRADICTED** — the real body is an **NVIDIA vendor/device-ID gate**, relocated out of `.text`. §9.1 | **open** |
| 18 | `LTIInputGeneralEnter` | `0x00BB6C98` | `0x005C1470` | ⬤ | 8 | pushes the General-input page: Invokes `LTIInputSetMouseSense`, `…SetJoySense`, `…SetInvertJoystick`, `…SetInvertMouse`, `…SetRumble`, `…NumberControllers` | H |
| 19 | `LTIInputGeneralOptions` | `0x00BB6C80` | `0x005C1600` | ◐ | 2 | **body read** (⚠ was ○/M "tail call"): `81 ec 80 00 00 00 56` (0x80-byte frame) → `call 0x0059D8E0` fetches a Lua string, then a compare loop. Touches `FUN_004FD930`/`FUN_0082A960`/`FUN_004FBF20` — **all three first-hand here, not citations**. INI keys `[Joystick] Invert`, `Rumble`, `Sensitivity` (⚠ shipped `Mercs2.ini` has no key named `Joystick`) | M (role) / H (body) |
| 20 | `LTIInputGeneralInvertMouse` | `0x00BB6C64` | `0x005C17B0` | ⬤ | 1 | int arg → `FUN_004FD930` (mouse config) | H |
| 21 | `LTIInputGeneralMouseSense` | `0x00BB6C48` | `0x005C17F0` | ⬤ | 1 | float arg → `FUN_004FD930` | H |
| 22 | `LTIInputGeneralJoySense` | `0x00BB6C30` | `0x005C1860` | ⬤ | 1 | float arg → `FUN_0082A960` → `FUN_004FBF20` | H |
| 23 | `LTIInputGeneralRumble` | `0x00BB6C18` | `0x005C18B0` | ⬤ | 1 | bool arg → INI `[Joystick] Rumble` via `FUN_0074BB50` | H |
| 24 | `LTIInputKMEnter` | `0x00BB6C08` | `0x005C1900` | ⬤ | 6 | **the KB/M remap page**: `Invoke("LTIInputMaxActionBind",[24])`, then per action 0..23 `Invoke("LTIInputKMSetActionName",[i, token])` + 2× `Invoke("LTIInputKMKeyMap",[i, slot, keyNameW])`, then `Invoke("LTIInputKMUpdateTable")`; sets `[0x00ED3B1C]+0xFC0 = 1` | H |
| 25 | `LTIInputKMChangeInput` | `0x00BB6BF0` | `0x005C1CC0` | ◐ | 3 | arms a rebind: if not already capturing, store action index in `DAT_00EDAF78`, set `+0xFC4 = 1` and `DAT_01175F2E = 1` | H |
| 26 | `LTIInputKMApplyChanges` | `0x00BB6BD8` | `0x005C1D00` | ◐ | 6 | **not a tail call** (⚠ was ○/M "tail-calls `FUN_004FBBA0`", falsely cited to `input_code_map.md`). Body read: `mov edx,[0x00ED3B1C] / xor eax,eax / push esi`, then a 24-row commit loop `mov ecx,[eax*8 + 0x00EDAE60]` → `mov [edx + eax*8 + 0xEA0], ecx`, bound `cmp eax,0x17`. Confirmed again in the v1.1 build at `0x005C1D20` | H |
| 27 | `LTIInputKMDefault` | `0x00BB6BC4` | `0x005C1ED0` | ⬤ | 6 | reset keymap to defaults, re-Invoke `LTIInputKMKeyMap` per row + `LTIInputKMUpdateTable` | H |
| 28 | `LTIOverBoundResponse` | `0x00BB6BAC` | `0x005C2730` | ⬤ | 3 | resolve a key already bound elsewhere; Invokes `LTIInputKMKeyMap`, `LTIFinishedGettingInput` | H |
| 29 | `LTIInputKMCancelInput` | `0x00BB6B94` | `0x005C2720` | ◐ | 6 | `DAT_01175F2E = 0; DAT_00EDAF78 = 0` (shared body with #34) | H |
| 30 | `LTIInputKMExit` | `0x00BB6B84` | `0x005C2950` | ◐ | 6 | `[0x00ED3B1C]+0xFC0 = 0` | H |
| 31 | `LTIInputJoystickEnter` | `0x00BB6B6C` | `0x005C2970` | ⬤ | 6 | joystick remap page; Invokes `LTIInputMaxActionBind`, `LTIInputNumberControllers`, `LTIInputControllerNames`, `LTIInputKMSetActionName`, `LTIInputJoystickMap`, `LTIInputJoystickUpdateTable` | H |
| 32 | `LTIInputJoystickChangePrimary` | `0x00BB6B4C` | `0x005C2CB0` | ⬤ | 3 | select primary pad; refresh `LTIInputJoystickMap`/`…UpdateTable` | H |
| 33 | `LTIInputJoystickChangeInput` | `0x00BB6B30` | `0x005C2E50` | ◐ | 3 | arms a pad rebind (`DAT_01175F2E`, `DAT_00EDAF78`) | H |
| 34 | `LTIInputJoystickCancel` | `0x00BB6B18` | `0x005C2720` | ◐ | 6 | **same body as #29** | H |
| 35 | `LTIInputJoystickApplyChanges` | `0x00BB6AF8` | `0x005C33F0` | ◐ | 6 | **not a tail call** (⚠ was ○/M "tail-calls `FUN_004FBC60`", falsely cited to `input_code_map.md`). Body read: `push ebx / push esi / mov esi,[0x00ED3B1C] / xor eax,eax`, then a commit loop over `[eax*4 + 0x00B9BCB0]` and `movzx edx, byte [eax + 0x00EDAD28]`. Confirmed again in the v1.1 build at `0x005C3400` | H |
| 36 | `LTIInputJoystickDefault` | `0x00BB6AE0` | `0x005C3500` | ⬤ | 6 | reset pad map; refresh `LTIInputJoystickMap`/`…UpdateTable` | H |
| 37 | `LTIInputJoystickExit` | `0x00BB6AC8` | `0x005C3690` | ◐ | 6 | `+0xFC8 = 0; +0x54 = 0` (leave joystick mode) | H |
| 38 | `LTIInputJoystickReEnter` | `0x00BB6AB0` | `0x005C36B0` | ◐ | 4 | `+0xFC8 = 1; +0x54 = 1` | H |
| 39 | `LTIJoystickOverBoundResponse` | `0x00BB6A90` | `0x005C3200` | ⬤ | 3 | pad twin of #28; Invokes `LTIInputJoystickMap`, `LTIFinishedGettingJoystickInput` | H |
| 40 | `LTIGetStartButton` | `0x00BB6A7C` | `0x005C36D0` | ⬤ | 2 | `Invoke("LTIPressStart", [localized "press start" string])`; tokens `[0x72a00bd4]`, `[0x5085D0F3:%s]` | H |
| 41 | `ChangeShellState` | `0x00BB6A68` | `0x005C3740` | ◐ | **24** | bool arg → `DAT_01175F2F`; clearing it also clears `[0x01176034]`. **Highest-traffic binding in the namespace** — every Flash sub-screen (support shop, numeric box, briefing, multipage menu) brackets itself with it | H |
| 42 | `LTIProfileEnter` | `0x00BB6A58` | `0x005C3780` | ◐ | 4 | `[0x00ED3B1C]+0xFCC = 1` (text-input/profile mode on) | H |
| 43 | `LTIProfileExit` | `0x00BB6A48` | `0x005C37A0` | ◐ | 4 | `+0xFCC = 0` | H |
| 44 | `LTIPauseItemChanged` | `0x00BB6A34` | `0x005C37E0` | ⬤ | 3 | **the 8064-byte `key=value` dispatcher** — §5 | H |
| 45 | `LTIPrecacheDone` | `0x00BB6A24` | `0x005C37C0` | ◐ | 4 | `DAT_0117660F = 1`. Returns EAX=1 while pushing nothing (§8.3) | H |
| 46 | `LTIPrecacheSmokeDone` | `0x00BB6A0C` | `0x005C37D0` | ◐ | 4 | `DAT_0117660C = 1`. Same return quirk | H |
| 47 | `LTIChoseOnline` | `0x00BB69FC` | `0x005C5800` | ⬤ | 2 | int arg → `[0x01176054] + 0x10 = (arg == 1)`. The **singleton** `[0x01176054]` is owned by `save_serialize_code_map.md`; **`+0x10` is not** — it appears in no other document and is a new single-witness offset here, adjacent to that map's documented `+0x11` dirty flag | H (write) / M (field role) |
| 48 | `LTIGetDateFormat` | `0x00BB69E8` | `0x005C5840` | ⬤ | 2 | region `**[0x01176018]`; `Invoke("LTISetUSDateFormat",[bool])` — true iff region ∈ {0, 6} | H |
| 49 | `LTICamera` | `0x00BB69DC` | `0x005C58B0` | ⬤ | 3 | int arg; if `== 4` and no cached widget, resolve the shell widget. Otherwise inert — see §9.4 | M |
| 50 | `LTIupdateSupportQuickSlot` | `0x00BB69C0` | `0x006D5640` | ◐ | 1 | **shared no-op stub** `xor eax,eax; ret`, body **read** in the clean images — §8.1/§8.2 | H |
| 51 | `FirstRun` | `0x00BB69B4` | `0x005C5900` | ◐ | 2 | pushes **one Lua number** (tag 3): `1.0` iff `DAT_00DFC364 == 0`, i.e. "this is the first run" | H |

Zero-call bindings: exactly the four `LTIMovie*`. Two entries share `0x005C2720` (#29/#34) and two
share `0x006D5640` (#0/#50) — hence "52 cfuncs, 2 stubs" in the audit doc, and 50 distinct addresses.

Row 41 (`ChangeShellState`) also carries the type-error path in §8.3: **all 24 shipped call sites pass
a boolean** (15× `true`, 9× `false`); zero string arguments exist, which contradicts
`main_menu_structure.md` §1's `ChangeShellState("newGame")` (§10).

### 3.1 The `Movie` table — `0x00B99BBC`, 4 cfuncs

| Name | cfunc VA | | calls | Behaviour | Conf |
|---|---|---|---|---|---|
| `Start` | `0x005C6510` | ⬤ | 0 | argc via `FUN_0059FA40`; up to 4 string args via `FUN_0059F820`; a boolean via `FUN_0059F6D0`; then `mov esi, 0x017C64F4 / call 0x00709CB0` — i.e. it **hard-codes record[0]** (base `0x017C64F0` + 4) and never indexes by the name it just fetched. Pushes a **light-userdata** (`tt = 2`) whose value is `[0x017C64F8]`, record[0]'s hash. ⚠ the "+ sibling `.ogg`" claim is retracted — §7 | M (arg roles), H (start path) |
| `Stop` | `0x005C6480` | ◐ | 0 | `FUN_005C63E0(arg)` → record; log `"MOVIE Stop(): …"`; `rec+0x14E = 1` | H |
| `Pause` | `0x005C64B0` | ◐ | 0 | if `rec+0x30 == 1` → `= 2`, `BinkPause(rec+0x38, 1)` | H |
| `Resume` | `0x005C64E0` | ◐ | 0 | if `rec+0x30 == 2` → `= 1`, `BinkPause(rec+0x38, 0)` | H |

`FUN_005C63E0` is another SecuROM split head (`jmp [0x024558F0]`) that fetches the Lua arg then
resolves the record — the `Movie.*` twin of `FUN_00709640`.

> **Re-walking `.rdata` on an 8-byte grid will miss this table.** `0x00B99BBC ≡ 4 (mod 8)` while
> `0x00B99C78 ≡ 0 (mod 8)`, and the linker interleaved a stray `0x40490FDB` (3.14159f) between the
> arrays — read here at `0x00B99BB8` and `0x00B99BE4`, each preceded by a `{0,0}` terminator. A walk
> stepping 8 bytes from the neighbouring `math` table (`0x00B99BE8`) skips `Movie` entirely.

**The `Movie` namespace has zero call sites in either Lua corpus** (`docs/mercs2-luacd/` and
`docs/mercs2-dlc-luacd/`). In-game cinematics go through the `_GuiInternal` **MovieWidget** instead
(`mrxguicinematic.lua`: `ShowMovie` / `PlayMovie` / `PauseMovie` drive
`oWidget.CustomData.oShowWidget:Play()/:Pause()`), and the shell's intro/attract movies (`EA`,
`Pandemic`, `attract`) are widget-driven too. `Movie.*` is a **live but unused** API surface — it is
the direct-to-Bink route the widget layer superseded.

---

## 4. The settings blocks — where an option actually lands

Three copies of one 0x48-byte record, at a **constant delta**:

| Block | VA | Role | Written by |
|---|---|---|---|
| **live** | `DAT_00DF6700` | what the renderer reads | every setter |
| **committed** | `DAT_00DFC320` (= live **+0x5C20**) | last-applied / defaults source | every setter writes both; `LTIVideoEnter` restores *from* it |
| **advanced undo** | `DAT_00DF6748` (= live **+0x48**) | snapshot taken on entering the Advanced page | `LTIVideoAdvanceEnter` writes it, `LTIVideoEnter` restores from it when the page was left un-accepted |

Field offsets proven by the setters (offset is from the block base; add `0x5C20` for the committed
twin):

| Off | Field | Read from | Conf |
|---|---|---|---|
| `+0x08` | **mode width** | `FUN_005C0AF0`: `DAT_00DF6708 = mode & 0xFFFF`, and `sprintf("%u x %u", DAT_00DF6708, DAT_00DF670C)` names them outright — a can't-coincide fingerprint. **Promoted M → H** | H |
| `+0x0C` | **mode height** | same (`DAT_00DF670C = packed >> 16`). **Promoted M → H** | H |
| `+0x14` | **refresh-rate index** | `FUN_005C0F40` (`(mode>>8)&0xFF`; also mirrored to `DAT_00ED278F`) | H |
| `+0x19` | **fullscreen flag** | `FUN_005C0AF0` (drives the ×4/3 view-distance rescale going fullscreen, ×0.75 `[0x00BEB950]` going windowed) | H |
| `+0x20` | **gamma — the RAW slider**, not the transformed value | `FUN_005C10C0` set, `FUN_005C11D0` restore. **⚠ corrected — see below** | H |
| `+0x24` | **EnableWaterEffects** | `FUN_005C1240` | H |
| `+0x28` | **view distance** | `FUN_005C0AF0`, `FUN_005C37E0` | H |
| `+0x2C` | **`PresentImmediate`** — the VSync byte, **inverted sense** (1 = VSync OFF) | **new field, §9.2.** Live `DAT_00DF672C`, committed `DAT_00DFC34C`; key string `"PresentImmediate"` at `0x00BD58B0`, written by the serializer at `0x007535C0`: `mov edi,0xBD58B0 / call 0x0074BB50` | H |
| `+0x31` | **Rumble** | **new field.** `LTIInputGeneralRumble` `0x005C18E4`: `mov byte [0x00DFC351], al` immediately before `FUN_0074BB50("Joystick","Rumble")` | H |
| `+0x37` | **WaterDetail** (0..2) | `FUN_005C1240` | H |
| `+0x38` | **SkyDetail** (also `DAT_00D2AEFC`) | `FUN_005C1240` | H |
| `+0x40` | **EnableShadows** | `FUN_005C1240` | H |
| `+0x41` | **ModelDetailLevel** | `FUN_005C1240` | H |
| `+0x42` | **ParticleDetailLevel** | `FUN_005C1240` | H |
| `+0x43` | **MotionBlur** | `FUN_005C1240` | H |
| `+0x44` | **not-first-run flag** | `FUN_005C5900` (`FirstRun`), `FUN_00709CB0` | H |

Two page-state flags sit outside the block: `DAT_01175F2A` ("advanced page was entered") and
`DAT_01175F2B` ("advanced page was accepted" — set by the `AdvAccept` key in §5). `LTIVideoEnter`
branches on both to decide whether to reload from the committed copy or from the undo snapshot.

> ⚠ **Gamma: CONTRADICTED, 2026-07-26.** This map said `DAT_00DF6720 = (i64)(1.5 − f*0.01)`. Reading
> `FUN_005C10C0` instruction by instruction, the two lanes carry **different values**:
>
> ```asm
> 005c10e2  d9 44 24 04       fld    dword [esp+4]          ; the RAW slider  <-- x87 lane
> 005c10e6  f3 0f 10 44 24 04 movss  xmm0, [esp+4]
> 005c10ec  f3 0f 59 05 …     mulss  xmm0, [0x00b97eec]     ; * 0.01f
> 005c10fd  f3 0f 10 0d …     movss  xmm1, [0x00b9c650]     ; 1.5f
> 005c1113  f3 0f 5c c8       subss  xmm1, xmm0             ; 1.5 - f*0.01   <-- SSE lane
> 005c1117  f3 0f 11 0c 24    movss  [esp], xmm1            ;   -> arg to FUN_0074AE20
> 005c1121  df 7c 24 10       fistp  qword [esp+0x10]       ; pops the RAW value
> 005c1129  89 15 20 67 df 00 mov    [0x00df6720], edx      ; <-- RAW lands here
> 005c1133  e8 …              call   0x0074ae20             ; (0x017CFAF0, 1.5 - f*0.01)
> ```
>
> Constants verified: `[0x00B97EEC] = 0.01f`, `[0x00B9C650] = 1.5f`. So **`[0x00DF6720]` holds the raw
> slider; `1.5 − f*0.01` is the *applied* value and is never stored.** Decisive data-side check:
> shipped `docs/game_config/Mercs2.ini` has `[Render] Gamma=50`, and `1.5 − 50*0.01 = 1.0` — neutral
> gamma. Had the field held the transformed value it would read `1`. `LTIVideoCancel` re-derives
> `1.5 − x*0.01` from the committed copy `[0x00DFC340]`, so the round trip is symmetric and the
> "double transform" the old wording implies does not exist.

Persistence is `GetPrivateProfileIntA`/`WritePrivateProfileStringA` through
**`FUN_0074BB50(section /* stack arg */, key /* EDI */, value /* ESI */)`**. ⚠ the section is **not**
a fixed `"Render"` literal — see §0.5; two LTI sites write `[Joystick]`. (`FUN_00709CB0` uses the same
INI for `[Render] FirstRun`, section string `0x00BB6FD0 = "Render"`, key `0x00BB69B4 = "FirstRun"`.)

### 4.1 `LTIVideoSwitchOpt1` — one encoded index for seven toggles — H

`FUN_005C1240(n)` takes a single Lua number and decodes it as **`group*10 + value`**:

| `n` | Setting | live | committed | `[Render]` key |
|---|---|---|---|---|
| 0–19 | water effects (**on iff `n == 11`**) | `+0x24` | `DAT_00DFC344` | `EnableWaterEffects` |
| 20–29 | water detail, clamped 0..2 | `+0x37` | `DAT_00DFC357` | `WaterDetail` |
| 30–39 | sky detail (`n−30`) | `+0x38` | `DAT_00DFC358` | `SkyDetail` |
| 40–49 | shadows (**on iff `n == 41`**) | `+0x40` | `DAT_00DFC360` | `EnableShadows` |
| 50–59 | model detail (`n−50`) | `+0x41` | `DAT_00DFC361` | `ModelDetailLevel` |
| 60–69 | particle detail (`n−60`) | `+0x42` | `DAT_00DFC362` | `ParticleDetailLevel` |
| 70–79 | motion blur (**on iff `n == 71`**) | `+0x43` | `DAT_00DFC363` | `MotionBlur` |
| ≥ 80 | **falls through and writes nothing** | — | — | — |

Note the asymmetry: the three boolean groups only clamp *by equality* (`== group*10 + 1`), so any
other in-range value reads as "off"; the four level groups clamp by range. Only `WaterDetail` clamps
its value (0..2); `SkyDetail`, `ModelDetailLevel` and `ParticleDetailLevel` take `n − base` raw.

---

## 5. `LTIPauseItemChanged` `FUN_005C37E0` — the `key=value` dispatcher

The single largest function in the namespace (8064 B) and the busiest Invoke site in the game: **62 of
the 250** `FUN_0061C550` calls, re-counted here by restricting the funnel byte-scan to
`[0x005C37E0, 0x005C37E0+8064)`. ⚠ the numerator was always right; the denominator used to read
"194" (§0). It takes **one Lua string**, splits it at the first `'='` into key and value, then runs a
`_stricmp` chain.

**Control keys** (no `=`): `AdvAccept` (sets `DAT_01175F2B = 1`), `loadMainShell`,
`loadPauseMenuVariables` (the big "push every current option into the movie" branch),
`enterControllerDisplay`, `pauseOpen`, `pauseSave`, `pauseCancel`, `videoEnter`, `audioEnter`,
`audioApply`, `audioCancel`, `audioDefaults`, `gameEnter`, `gameApply`, `gameCancel`, `gameAccept`,
`gameDefaults`, `serverEnter`.

**Value keys** (`key=value`), **all 33 of them** (⚠ the table below always listed 33; the prose said
"30". Game 6 + Video 9 + Advanced 9 + Audio 5 + Controls 3 + Server 1 = 33), read verbatim from the
`_stricmp` chain and re-verified here by extracting every string operand inside the function's
8064-byte extent — 33/33 present, and 18/18 control keys present:

| Group | Keys |
|---|---|
| Game | `gameInvertVar` · `gameSensitivityVar` · `gameRumbleVar` · `gameTutorialsVar` · `gameSubtitleVar` · `gameAutoSaveVar` |
| Video | `videoModeVar` · `videoGammaVar` · `videoVsyncVar` · `videoVideoDetailVar` · `videoViewDistance` · `videoShaderSetting` · `videoAntiAliasLevel` · `videoNextAntiAliasLevel` · `videoPrevAntiAliasLevel` (+ the literals `VSyncOn` / `VSyncOff`) |
| Advanced video | `advvideo1Var` · `advvideoSkyDetailVar` · `advvideoWaterDetailVar` · `advvideoEnableShadowsVar` · `advvideoTreeShadowsVar` · `advvideoModelShadowsVar` · `advvideoParticleVar` · `advvideoShaderVar` · `advvideoMotionblurVar` |
| Audio | `audioSFXVolumeVar` · `audioMusicVolumeVar` · `audioDialogVolumeVar` · `audioInVoiceVolumeVar` · `audioOutVoiceVolumeVar` |
| Controls | `controlsMouseInvertVar` · `controlsMouseSensVar` · `controlsJoySensVar` |
| Server | `serverFriendlyFireVar` |

`loadPauseMenuVariables` is guarded by a one-shot latch (`DAT_00CFBC19`) and then Invokes the whole
option state back into the movie — the 43 distinct AS names listed in §6 under "pause dispatcher".
It also reaches into non-render subsystems: `FUN_0074C7A0` (settings commit), `FUN_004FD930` (mouse),
`FUN_0082A960` (joystick), `FUN_005FAEE0` (audio), `FUN_007546E0` (detail preset), plus
`FUN_005C13A0`, `FUN_005C0870`, and — omitted before — `FUN_00609940` ×10 (widget resolve),
`FUN_00401860` ×5 (GFxValue array construct), `FUN_0059D8E0`, `FUN_009EE850`. `LTIVideoSetSwitchOpt2`
is the one member of the `Opt1..8` family this function never Invokes.

Not mentioned here but owned next door: `input_code_map.md` documents a **53-entry controller-name
table `PTR_s_Left_Stick___Left_00cf2560`** consumed inside this same function — the `[Controller]`
INI vocabulary.

Two adjacent, non-Lua-visible helpers do the same "push a whole page" job:

- **`FUN_005C0870`** — the **Video page** refresh: 8 Invokes (`LTIVideoSetMode`, `LTIVideoSetRes`,
  `LTIVideoSetRefresh`, `LTIVideoSetGamma`, `LTIVideoSetVideoViewDistance`, `LTISetGraphicDetail`,
  `AntiAliasText`, `LTIVideoSetVSync`). Called by `LTIVideoEnter`, `LTIVideoDefault`,
  `LTIPauseItemChanged`.
- **`FUN_005C06C0`** — the **Advanced Video page** refresh: 9 Invokes (`LTIVideoSetSwitchOpt1`…`Opt8`
  + `LTIVideoDisableHighShaders`). Its **only** static caller is `LTIVideoAdvanceEnter`
  (`0x005C122A`); `LTIVideoCancel` and `LTIVideoSetGamma` do *not* refresh the page, they only write
  the value and call the apply path.

---

## 6. The ActionScript vocabulary (engine → movie)

Every name below is a `.rdata` string that is **not** a Lua binding. Names marked **✔** were proven
by reading the `mov edi, <str>` immediately before a `call 0x0061C550`; **✚** marks names whose
listed source **inlines** the sequence and pushes the name as an immediate operand instead, so they
reach the movie without ever touching the funnel; the rest are present in `.rdata` and referenced by
the listed function but their exact call was not individually disassembled.

> ⚠ **Six ✔ marks were false and are now ✚.** They claimed a `mov edi,<str>` before a
> `call 0x0061C550` at sites that inline. Re-derived: restrict the funnel name-harvest to each name
> and count. `LTIInputControllerNames`, `LTIInputJoystickUpdateTable`, `LTIInputKMUpdateTable`,
> `LTIInputKMSetActionName`, `LTIInputSeeButtonsPushed`, `LTISetUSZip` and `LTI_TOSText` all score
> **0 funnel sites** — every occurrence is an inlined bypass (§2.1a). By contrast
> `LTIInputKMKeyMap` = 3, `LTIInputJoystickMap` = 2, `LTIInputMaxActionBind` = 2 do also reach the
> funnel, so those rows keep ✔ *and* gain ✚.
>
> **This list is not a closed set.** Static funnel harvest = 142 distinct names; the inlined bypasses
> add more; and `_GuiInternal.CallFlashScriptFunction` (§2.1b) lets Lua name **41 further** AS
> functions from literals alone (plus 56 sites that name it at runtime) — **≈196 statically knowable
> against the ~70 listed here.** Treat §6 as a well-evidenced sample, not an inventory.
>
> **Also missing entirely: the 29 slot-sourced names** (§2.1a, `.data` table `0x00D121B8`–`0x00D12248`)
> — `AddProfile`, `ProfilesComplete`, `EnableUsingFakeProfile`, `loadProfile`, `serverOnline`,
> `serverAccept`, `serverEAagreement`, `profileCharacter`, `joingameSavegame`,
> `joingameFilter{Map,Mission,FriendlyFire}`, `videoBrightness`, `gameSensitivity`, `gameInvert`,
> `gameRumble`, `audioSFX`/`Music`/`Dialog`, `addSaveGame`, `videoWidescreen`, `maximumProfiles`,
> `multiplayerHost`, `multiplayerClient`, `player2Name` — plus, from the online block,
> `onlineLoginAccount`, `onlineLoginAccountError`, `onlineLoginSuccessful`, `onlineCreateAccountError`,
> `onlineConnectionFailure`, `onlineIsConnectedReturn`, `clearDropDownItem`, `addDropDownItem`,
> `confirmButtonReversed`, `leftAnalog`, `rightAnalog`, `AddGPSLine`, `ClearGPS`, `setTerritory`.

| AS function | Invoked from | |
|---|---|---|
| `LTIVideoSetMode` `LTIVideoSetRes` `LTIVideoSetRefresh` `LTIVideoSetVideoViewDistance` | `FUN_005C0AF0`, `FUN_005C0870` | ✔ |
| `LTIVideoSetResolution` | `FUN_005C0CE0`, `FUN_005C0E10` | ✔ |
| `LTIVideoSetResolution2` `LTIVideoSetRefresh2` `LTIVideoSetGamma` `LTIVideoSetVsync` `LTIVideoDetail` | `FUN_005C37E0` (pause dispatcher) | ✔ |
| `LTIVideoSetVSync` (capital S) `LTISetGraphicDetail` `AntiAliasText` | `FUN_005C0870` | ✔ |
| `LTIVideoSetSwitchOpt1..8` `LTIVideoDisableHighShaders` | `FUN_005C06C0` | ✔ |
| `setAntiAliasVar` `LTISetParticleVar` `LTISetShaderVar` `LTIvideoSubtitles` | `FUN_005C37E0` | ✔ |
| `LTIAudioSFXVolume` `LTIAudioMusicVolume` `LTIAudioDialogVolume` `LTIAudioInVoiceVolume` `LTIAudioOutVoiceVolume` | `FUN_005C37E0` | ✔ |
| `LTIGameSensitivity` `LTIGameSetAutosave` `LTIGameSetTutorial` `gameTutorials` `gameAutosave` `videoSubtitles` `LTIControlsMouseInvert` | `FUN_005C37E0` | ✔ |
| `LTIServerOnline` `LTIServerAccept` `serverFriendlyFire` `maximumProfiles` `player2Name` `multiplayerHost` `multiplayerClient` | `FUN_005C37E0` | ✔ |
| `LTIInputSetMouseSense` `LTIInputSetJoySense` `LTIInputSetInvertJoystick` `LTIInputSetInvertMouse` `LTIInputSetRumble` `LTIInputNumberControllers` | `FUN_005C1470`, `FUN_005C37E0` | ✔ |
| `LTIInputMaxActionBind` | `FUN_005C1900`, `FUN_005C2970`, `FUN_005C2950` | ✔ (2 funnel) ✚ (`0x005C1A0B`) |
| `LTIInputKMKeyMap` | `FUN_005C1900`, `FUN_005C1ED0`, `FUN_005C2730` | ✔ (3 funnel) ✚ (4 inlined) |
| `LTIInputKMSetActionName` `LTIInputKMUpdateTable` | `FUN_005C1900`, `FUN_005C1ED0`, `FUN_005C2970` | ✚ **only** — 0 funnel sites |
| `LTIInputJoystickMap` | `FUN_005C2970`, `FUN_005C2CB0`, `FUN_005C3500`, `FUN_005C3200` | ✔ (2 funnel) ✚ (3 inlined) |
| `LTIInputJoystickUpdateTable` `LTIInputControllerNames` | `FUN_005C2970`, `FUN_005C2CB0`, `FUN_005C3500` | ✚ **only** — 0 funnel sites |
| `LTIFinishedGettingInput` | `FUN_005C2730` | ✔ |
| `LTIFinishedGettingJoystickInput` | `FUN_004FA570`, `FUN_005C2E80`, `FUN_005C3200` | ✔ |
| `LTIPressStart` | `FUN_005C36D0`, `FUN_005C3690`, `FUN_005C36B0` | ✔ |
| `LTISetUSDateFormat` | `FUN_005C5840` | ✔ |
| `LTITextInputEnterButton` `LTITextReleaseEnterButton` `LTITextInputBackSpaceButton` `LTITextInputSpaceButton` `LTITextInputTabButton` `LTITextInputUpButton` `LTITextInputDownButton` `LTITextInputLeftButton` `LTITextInputRightButton` `LTITextInputEscapeButton` `LTITextInputUpdateString` | `FUN_004FA570` (live text/key capture — `input_code_map.md`) | |
| `LTIInputSeeButtonsPushed` | `FUN_004FB270` | ✚ **only** — 0 funnel sites (`0x004FB499`) |
| `LTIgotoGame` `LTIProfileOnlinePlay` `LTIonlineMsgBox` | `FUN_00614540` (FSCommand fallback parser) | |
| `LTIAllowFlashMouse` | `FUN_004CEB00` | |
| `LTIstopConnectingDisplay` | `FUN_006CAF20`, `FUN_00848CA0` (online connect UI) | |
| `LTIUnlockableResult` | `FUN_006CC920` | |
| `LTIRegisterBox` | **`FUN_00847FE0`** (`0x0084811A`, `0x0084821A`) and `FUN_00848AE0` (`0x00848BAA`, `0x00848C87`) | ✔ (4 funnel) |
| `LTISetUSZip` `LTI_TOSText` `addDropDownItem` `clearDropDownItem` | `FUN_008486F0` (EA account/registration screen) | ✚ **only** — all inlined, 0 funnel sites |

> ⚠ **Attribution correction.** `LTIRegisterBox` was listed under `FUN_008486F0`. It is **not** there.
> The literal `0x00BE3114` has exactly four `.text` references — `0x00848116`, `0x00848216`,
> `0x00848BA6`, `0x00848C83` — the first two inside `FUN_00847FE0`, the last two inside
> `FUN_00848AE0`. `FUN_008486F0` carries `LTISetUSZip`, `LTI_TOSText` and `addDropDownItem`, all
> **inlined**. All of `LTIRegisterBox`, `LTISetUSZip`, `LTI_TOSText`, `LTIonlineMsgBox`,
> `LTIstopConnectingDisplay`, `LTIProfileOnlinePlay`, `LTIgotoGame` are defined in `shell/SHELL.gfx`.

**Not in this namespace despite the prefix:** `LTIGetPrecacheBypass` is a **`Sys` binding**
(table `0x00B98A78`, cfunc `0x005E4F70`); `LTI_precache` / `LTIenterControlDisplay` / `LTIFscommand`
are Lua-side or `.gfx`-side identifiers, not exe symbols in this table; and — not previously noted —
`LTIStartNewGame`, `LTIStartKeyboardInput`, `LTIEndKeyboardInput` are `"LTI…"` **Lua string literals**
belonging to none of the 52 bindings.

---

## 7. Movie playback (Bink)

Records live in an array of **stride 0x16C** with **record base `0x017C64F0`**, keyed by the **m2 name
hash** computed inline in `FUN_00709640` (FNV-1a seeded `0x811C9DC5`, each byte OR-ed with `0x20` for
case folding, final `^0x2A` then `*0x1000193`). The lookup walks the hash *field* from `0x017C64F8`
(`mov edi,0x17C64F8`, `add edi,0x16c`, `cmp edi,0x17C6AA8 / jl` — the exclusive end bound) and on a
hit returns `imul eax,eax,0x16c / add eax,0x17C64F0`.

> ⚠ **Base correction.** `DAT_017C64F8` is the **hash field of record 0**, i.e. base **+ 8** — not the
> record base. And `Movie.Start` passes `0x017C64F4` = base **+ 4** to `FUN_00709CB0`. Field offsets
> quoted from those two functions were therefore expressed **against two different bases**, and the
> table below re-publishes every field against one: `FUN_00709640`'s return value.

`FUN_00709CB0(flag)` starts one. Against **record base**, it sets `+0x14D = 1`, `+0x14E = 0`,
`+0x14C = flag`, computes the name hash into `+0x08`, and `sprintf`s the path
**`"%sMovies\%s.bik"`** (`0x00BD1EB0`) into `+0x48` from the root `".\Data\"` (`0x00ED2010`) — note
the **backslash**; this map used to print forward slashes. On the way it reads `[Render] FirstRun`
from the settings INI and clears it — `GetPrivateProfileIntA("Render","FirstRun",1,…)` and, if
non-zero, `sprintf("%i",0)` + `WritePrivateProfileStringA`. (Same INI key `FirstRun` that `0x005C5900`
reports to Lua; shipped `Mercs2.ini` has `FirstRun=0`, so `FirstRun()` returns 1.0 on a normal
install.)

**Record fields, all against `FUN_00709640`'s returned base:**

| Off | Field |
|---|---|
| `+0x08` | name hash (this is the field the lookup walks) |
| `+0x30` | play state — a **dword**, 1 = playing, 2 = paused |
| `+0x38` | HBINK handle passed to `BinkPause` |
| `+0x48` | `.bik` path |
| `+0x14C` | start flag |
| `+0x14D` | started |
| `+0x14E` | **stop-requested / finished** |

⚠ The old table listed `+0x04 / +0x44 / +0x148 / +0x149 / +0x14A` (record+4-relative, from
`FUN_00709CB0`) alongside `+0x30 / +0x38 / +0x14E` (base-relative, from `FUN_00709640`) as if they
shared a base. In particular **`+0x14A` and `+0x14E` were the same byte** listed twice under two
names ("finished" and "stop-requested"): `FUN_00709CB0` clears it at start, `LTIMovieStop` /
`Movie.Stop` set it.

### 7.1 The `.ogg` sidecar does not exist — **RETRACTED**

The old text concluded, graded **H** in §0.5 / §3.1 / §7: *"a Mercenaries 2 movie is a `.bik` video
with a sibling `.ogg` audio stream."* **The shipped assets refute it.**

* `game-files/PC-Movies/` holds **45 files, all `.bik`**. `find . -iname "*.ogg"` over the whole tree
  returns **zero** — there is not one `.ogg` anywhere.
* `docs/movies_pc_vs_ps3_catalog.md` (ffprobe ground truth) records the PC Binks as carrying **8
  internal audio tracks** at 22 050 Hz, which matches `audio_code_map.md`'s `BinkSetSoundTrack(4,…)`.
  Audio is *inside* the Bink; there is nothing for a sidecar to carry.

The `sprintf` of `"%sMovies\%s.ogg"` (`0x00BD1EC0`) into `DAT_00F79218` is real code. The correct
scope is therefore: **the start path also formats an `.ogg` path that no shipped asset satisfies** —
vestigial or dev-era. This is a good example of an H-graded *inference* from code being refuted by
the data it claims to describe; the code was read correctly and the conclusion drawn from it was
wrong.

`audio_code_map.md` already owns the in-game cinematic pause path (`FUN_00621AB0`/`FUN_00621BC0`),
which calls the same `FUN_00709CB0`.

---

## 8. Stubs, shared bodies, and dead paths

### 8.1 The shared no-op `0x006D5640` — 62 bindings

**Its body is `33 c0 c3` = `xor eax, eax; ret`** — read, not inferred, in two clean images.
`scripting_host_binding_code_map.md` §5.4 was right all along.

> ⚠ **Mechanism CONTRADICTED, 2026-07-26.** This section used to say the address "contains only
> `jmp 0x6FCD20C0` — a target outside the mapped image, **resolved by SecuROM at load**", and cited
> the behaviour rather than reading it. That `E9` is **not SecuROM**. It is a `pmc_bb.dll` runtime
> **hot-patch that happened to be captured in the memory dump**:
>
> | image | bytes at `0x006D5640` |
> |---|---|
> | `mercs2_unpacked.exe` (memory dump), `mercs2_nodrm_v1.exe` (built *from* the dump) | `e9 7b ca 5f 6f` |
> | **`mercs2_nodrm_v2.exe`, `mercs2_nodrm_v3.exe`** (built from the *on-disk* decrypted exe) | **`33 c0 c3`** |
> | **v1.1 build**, same binding-table slot (`0x006AEF90`) | **`33 c0 c3`** |
>
> Reproduce by byte-diffing `.text` between `mercs2_unpacked.exe` and `mercs2_nodrm_v3.exe`: the two
> sections are the same length and **exactly three** byte-runs differ, each a 5-byte `E9` splice to
> the `0x6Fxxxxxx` region — `0x005E9DE0`, `0x005E9F40`, `0x006D5640`. Three hooked entry points, and
> one of them is in this map's scope. **Where the dump and the on-disk images disagree, the on-disk
> image wins** — the dump is not a neutral primary source.

Across the binding map, **62 entries** point at `0x006D5640`, spread over 13 tables (`Ai` 15, `Junk`
15, `Sound` 9, `Debug` 5, `Pg` 2, `ObjectState` 2, `Net` 2, `LTILibName` 2, plus `Gui`, `Sys`,
`Object`, `Graphics` and stdlib `print`) — the retail-stripped developer surface, `/OPT:ICF`-folded
because the bodies are identical. Two are LTI: `LTIMovieStart` and `LTIupdateSupportQuickSlot`.

> ⚠ **"62 bindings across all 60 binding tables" and "the registrar array" are two different
> populations**, and this map used the terms interchangeably.
> `mods/lua_trace_asi/reference/binding_map.json` has **60 tables / 1357 entries**, of which 62 are
> the stub. The `.data` **registrar** (§1.3) registers **31** globals / **1103** cfuncs, of which
> **61** are the stub. The JSON includes sub-tables and metatables the registrar never walks. Both
> numbers are right; they are answers to different questions.

### 8.2 The PDA support quick-slot is a dead round trip on PC — H

`mrxguipda.lua:1540` registers `oPda.CustomData.oMapFlash:SetFlashEventHandler("LTIupdateSupportQuickSlot", _LTIupdateSupportQuickSlot)`,
and line 1858 forwards it: `LTILibName.LTIupdateSupportQuickSlot(sParm)`. On PC that lands on the
shared stub — now **read** as `xor eax,eax; ret` (§8.1), so the notification reaches the engine and is
provably discarded.

**It is dead at both ends, and worse than that.** Three findings, each re-derived here:

1. **Flash never raises the event.** `LTIupdateSupportQuickSlot` — and the bare
   `updateSupportQuickSlot` — appear in **none of the 83 shipped `.gfx` movies**, `Map.gfx` (the movie
   the handler is attached to) and `SUPPORT.gfx` included. Method: inflate each movie
   (`zlib.decompress(bytes[8:])`) and search the decompressed payload for the NUL-terminated token.
   The extraction is provably complete against the shipped WADs — `docs/data/aset_export.csv` lists
   **83** assets of `type_hash 0xFE0E8320` (`cfx_pack`): vz.wad 64 + shell.wad 16 + Loading.wad 3, and
   `output/gfx_movies/` holds exactly 64 + 16 + 3. (Raw-grepping the WADs proves nothing — they are
   compressed.) Same story for `LTIMovieStart`.
2. **The Lua implementation exists and is orphaned.** `mrxguipda.lua:1861` defines
   **`EnableQuickSlot(sId)`**, ~37 lines that do the real work — remove the current support, look up
   `tSupportIdIndex[sId]`, `AddItem`, `SetSupportName` / `SetFuelCost` / `SetCashCost` / `Commence`,
   animate the ammo counter — and it has **zero callers anywhere in either Lua corpus**
   (`grep -rn EnableQuickSlot docs/mercs2-luacd/ docs/mercs2-dlc-luacd/` → the definition line and
   nothing else).
3. So the feature has **two implementations and neither runs**: the Flash event is never raised, the
   cfunc is a no-op, and the written Lua implementation is dead code three lines below the forwarder
   that would have called it.

That reads as a genuine shipped bug with a plausible one-line fix (`_LTIupdateSupportQuickSlot` →
`EnableQuickSlot(sParm)`), pending an in-game repro (§9.5). **This item survives** — an earlier
reading closed it as "nothing is lost by the stub", which is true of the engine leg alone and misses
the orphaned Lua body entirely.

### 8.3 **Twenty-two** cfuncs declare a Lua result they never push — H (disassembly) / open (impact)

⚠ This section used to name **three** (`LTIVideoGetViewDistance`, `LTIPrecacheDone`,
`LTIPrecacheSmokeDone`). A mechanical census over all 56 cfuncs finds **22**. Detector: disassemble
each body and look for a `ret` reached with `EAX = 1` while the function contains no Lua-stack bump
(`add dword ptr [reg+8], 8`, the Lua 5.1 `L->top += 8` idiom). **Only `FirstRun` and `Movie.Start`
actually push.**

**Class A — the *success* path returns 1 with nothing pushed** (the live quirk):

`LTIVideoGetViewDistance` `0x0063EF20` (literally `b8 01 00 00 00 c3`) · `LTIPrecacheDone`
`0x005C37C0` · `LTIPrecacheSmokeDone` `0x005C37D0` · **`LTICamera`** · **`LTIChoseOnline`** ·
**`LTIGetDateFormat`** · **`LTIPauseItemChanged`** · **`LTIMovieStop` / `LTIMoviePause` /
`LTIMovieResume`** · **`Movie.Stop` / `Movie.Pause` / `Movie.Resume`**.

**Class B — only the argument-type-error path does it**: `LTIVideoSetGamma`, `LTIVideoSwitchOpt1`,
`LTIInputGeneral{InvertMouse,MouseSense,JoySense,Rumble}`, `LTIInputJoystickChangePrimary`,
`LTIJoystickOverBoundResponse`, `ChangeShellState`.

`LTIPauseItemChanged` is the extreme case and had to be measured separately because it exceeds a
naive extent cap: across its 8064 bytes there are **45** `mov eax,1` sites and **zero** Lua-stack
bumps.

A Lua cfunc returning 1 with nothing pushed hands back whatever occupies the top slot — in practice
its own last argument. Every shipped call site ignores the result, so this is latent rather than
live; recorded so a reimplementation does not "fix" it into a behaviour change (see §11.7, whose rule
was written for three of these and is wrong for the other 19).

### 8.4 Shared bodies

`LTIInputKMCancelInput` and `LTIInputJoystickCancel` are the same 13-byte function `0x005C2720` —
deliberate, not an artifact: both clear `DAT_01175F2E` (capture armed) and `DAT_00EDAF78` (pending
action index).

---

## 9. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — prefer one-shot
breakpoints and HW-write watchpoints.

**Six of the eight items this section carried are now CLOSED** (§9.2, §9.5, §9.6, §9.7, §9.8 and
three of the four "open bodies"). What remains genuinely open is **two** items, both with the map's
own previous answer *disproved* rather than merely unconfirmed.

### 9.1 `LTIVideoAdvanceDefault` `0x005C13A0` — STILL OPEN, and the map's answer is CONTRADICTED

The table slot holds `ff 25 88 87 45 02` = `jmp [0x02458788]` — a full SecuROM steal, identical in
all four dump-lineage images (dump, nodrm v1/v2/v3).

**`0x005C13B0` is not the continuation.** The map asserted it was. The code there is
`push ebx / push ebp / mov ebp,[esp+0xc] / xor bl,bl / mov [edi],bl / push 0x5C13D3 / push 0x54B370 /
ret` — a SecuROM control-flow trampoline — and further on `cmp dword [esi+0x710],0` /
`cmp byte [esi+0x718],bl` / `ret 4`. That signature (`83 be 10 07 00 00 00 7e`) lives at `0x005F8A1E`
in the v1.1 build, ~0x2C000 away from where that build puts `LTIVideoAdvanceDefault` — **it is a
different function's code sitting in the hole**. It also touches **none** of the `DAT_00DF67xx`
settings bytes an "advanced defaults" reset must write.

**The real body is an NVIDIA vendor/device-ID gate, and it is readable — just not in `.text`.** In
the v1.1 build the code immediately after that slot's stolen head is plain `.text` at `0x005C13D0`:

```asm
005c13d0  81 bf 28 04 00 00 de 10 00 00   cmp dword [edi+0x428], 0x10DE   ; NVIDIA vendor ID
005c13db  0f 85 8f 00 00 00              jne 0x005c1470
005c13e1  8b b7 2c 04 00 00              mov esi, [edi+0x42c]             ; device ID
005c13e7  3b 35 e4 da 4d 02              cmp esi, [0x024ddae4]
005c13ef  81 fe d3 01 00 00              cmp esi, 0x1d3   ; then 0x1df, 0x393, 0x395, 0x2e2, 0x1dd
```

The same shape exists in the dump build **only in `.securom`, at `0x02487D20`** — relocated — with
that build's own device list (`0x3D1, 0x3D2, 0x242, 0x3D5, 0x241, …`), ending
`mov eax,1 / pop esi / ret` and `xor eax,eax / pop esi / ret`. The dump's `.text` has **no** `0x10DE`
compare anywhere in `0x005C13xx`; a whole-`.text` scan for `28 04 00 00 de 10 00 00` finds exactly
one hit image-wide, at `0x004EF9B0`, unrelated. This matches what
`securom_unwrap_devirtualization.md` describes for the 743 splice sites.

*Why it is still open, stated honestly:* the slot `[0x02458788]` resolves to `0x024E6220`, a **live
self-decrypting VM stub** (`push/push/push/pushfd/sub [esp+4],0x12CD4/popfd/ret` → dispatch into
`Stext`), so it cannot be statically proven that `0x02487D20` is the target of *this* slot rather
than a sibling. And the recovered body takes its argument in **EDI**, which is not a `lua_CFunction`
shape — so either the hole holds packed foreign code in both builds, or the binding table genuinely
points at a `__usercall` helper, which would be a shipped defect since 6 Lua sites call it.

*Static exhaustion demonstrated:* all four dump-lineage images checked (identical stolen head), the
v1.1 build checked, the `.securom` slot chain followed to a self-decryptor, and a whole-image byte
scan for the vendor-ID immediate run (2 hits per build, both located).
*Runtime recipe:* one-shot bp at `0x005C13A0`, single-step the `jmp [0x02458788]`, read EIP after the
VM returns; **or** HW-write watchpoints on `DAT_00DF6724 / 37 / 38 / 40 / 41 / 42 / 43` while calling
`LTILibName.LTIVideoAdvanceDefault()` from console — if none fires, it is not a settings reset at all.

### 9.2 `LTIVideoSetVSync` vs `LTIVideoSetVsync` — **CLOSED: NOT A BUG**

This was raised as a candidate silent-no-op defect. It is not one, and the item should not survive
into the fix-pack backlog. Three independent lines of evidence agree.

**(a) The byte is named, and its sense is inverted.** `[0x00DF672C]` (live) / `[0x00DFC34C]`
(committed, `+0x5C20`) is **`[Render] PresentImmediate`** — key string `0x00BD58B0`, written at
`0x007535C0` (`mov edi,0xBD58B0 / call 0x0074BB50`), and present in the shipped `Mercs2.ini` as
`PresentImmediate=1`. Field `+0x2C`, which §4 previously omitted.

**(b) D3D9 settles the semantics.** `FUN_00755380` at `0x00755407`:

```asm
00755407  a0 4c c3 df 00     mov al, [0x00dfc34c]
0075540c  f6 d8              neg al
0075540e  1b c0              sbb eax, eax
00755410  25 00 00 00 80     and eax, 0x80000000
00755415  89 86 b8 05 00 00  mov [esi+0x5b8], eax
```

and the change-detector at `0x0074C927` compares `[ebx+0x5B8] == 0x80000000`. **`0x80000000` is
`D3DPRESENT_INTERVAL_IMMEDIATE`; `0` is `D3DPRESENT_INTERVAL_DEFAULT`.** So **byte = 1 ⇒ present
immediately ⇒ VSync OFF; byte = 0 ⇒ VSync ON.** The dispatcher's own inbound keys agree:
`VSyncOn` → `[0x00DF672C] = 0` (`0x005C51BD`), `VSyncOff` → `= 1` (`0x005C51D5`), and
`videoVsyncVar=<v>` → `= (_stricmp(v,"true") != 0)` (`0x005C51FF`).

**(c) The ActionScript cancels the engine-level asymmetry.** Both functions were lifted from AVM1
bytecode here (inflate the movie, locate `defineFunction2` = opcode `0x8E` immediately preceding the
name token, decode the body against the nearest preceding `constantPool`):

* `shell/SHELL.gfx` → `LTIVideoSetVSync(val)`, 241-byte body:
  `if (settingVSync == val) return; settingVSync = val;` then `equals2` against `1` selecting
  `crosshair_1_mc.gotoAndPlay("_on")` / `crosshair_2_mc "_off"` versus the reverse. **No
  re-inversion.**
* `pause_menu.gfx` → `LTIVideoSetVsync(val)`, 67-byte body:
  `push reg1, "videoVsyncVar", reg2, 1 ; equals2 ; if→push false : else push true ; setMember`, i.e.
  **`this.videoVsyncVar = (val != 1)`**. The compiled form is `equals2 ; if→else` with **no `not`
  opcode**, where *every other* compiled `if/else` in both movies emits `cond ; not ; if→else` (e.g.
  `LTIVideoSetVideoViewDistance` in the same movie: `less2 ; NOT ; if`). The missing `not` is a
  deliberate source-level inversion, not a decode artefact.

Composing engine sender with AS receiver, for `b = [0x00DF672C]`:

| path | engine sends | AS computes | lights `crosshair_1` |
|---|---|---|---|
| shell `FUN_005C0870` @ `0x005C09EA` | `cmp byte [0x00DF672C],al / sete al` → `(b == 0)` | `val == 1` | iff **b == 0** |
| pause `FUN_005C37E0` @ `0x005C3D7D` | `movzx eax, byte [0x00DF672C]` → raw `b` | `videoVsyncVar = (val != 1)` | iff **b == 0** |

**They agree exactly.** The engine-level asymmetry is *cancelled* by the AS-level one; both menus
display the setting correctly. The `sete` in the shell path is not a stray inversion — it is the
correct compensation for a byte that stores "VSync **dis**abled".

Spelling census over all 83 movies, for completeness: `LTIVideoSetVSync`, `VSyncOn`, `VSyncOff`,
`settingVSync`, `vsync_btn` exist **only** in `shell/SHELL.gfx`; `LTIVideoSetVsync`, `videoVsyncVar`
exist **only** in `pause_menu.gfx`. Each engine path targets the movie that defines its spelling, and
`IsAvailable` makes the mismatch harmless in the other direction — `0x00BB6F90` has exactly one
`.text` reference (`0x005C09FD`) and `0x00BB7398` exactly one (`0x005C3D95`).

> The map's caution was correct **in kind** — `IsAvailable` really does hide wrong names — but this
> was the wrong example. §2.2 now points at `ProfilesComplete`, `AddProfile`, `loadProfile` and
> `joingameSavegame`, which are defects of exactly this class and are real.

### 9.3 `FUN_0061C550`'s stolen prologue — STILL OPEN, reduced from 9 bytes to 7

See §2.1: `74 52` at `entry+7` is **read**, not inferred, so only **`entry+0..+6`** is unreadable, and
it ends on an instruction boundary. Encoding exhaustion over 7-byte x86 forms that (a) set ZF,
(b) can only use **ESI** — the sole live register at a `ret 0xC` entry; EAX and EBX are first written
at `entry+9` and `entry+0x10` — and (c) must guard the otherwise-unchecked `mov ecx,[esi+0x1E0]` at
`entry+0x18`, leaves **`cmp dword ptr [esi+0x1E0], 0`** (`83 be e0 01 00 00 00`) as the only sensible
fit. Corroboration: the **immediately adjacent** function (`0x0061C5B0` in the dump, `0x0061C4D0` in
v1.1) opens `push ebp / mov ebp,esp / and esp,-8 / sub esp,0x28 /` **`83 bf e0 01 00 00 00`** — the
identical 7-byte encoding with a different base register, in the same family, at the next address.
Ruled out: decryption. `[0x02455570]` → `0x024B5390` is a live SecuROM VM record
(`push/push/push/pushfd/sub [esp+4],0x271C/popfd/ret` → `0x01AAFF10` in `Stext`, itself a
flag-preserving trampoline in front of an encrypted-island loop); all five available images checked,
all stolen. **Grade: inferred (high), not proven.**
*Runtime recipe:* bp at `0x0061C559` and read the 7 bytes at `0x0061C550` from memory after SecuROM's
loader has run — or simply read ZF and ESI on entry.

### 9.4 Remaining confirm-live items (lower value)

* **`FUN_0061C550`'s ESI** — the widget is passed in a register, so *which* widget a given Invoke
  targets is set by the caller. Every LTI caller resolves it the same way
  (`[0x01175F4C]` else `FUN_00609940([0x01175FB0])`), but the non-LTI callers were not audited.
  One-shot bp at **`0x0061C559`** (not `0x0061C562`), read ESI and EDI, to confirm there is exactly
  one shell movie in play.
* **`LTICamera` `0x005C58B0`** — 67 bytes that fetch an int, compare it to 4, and at most resolve a
  widget. Three Lua call sites exist. Either the body is a leftover, or the camera effect is a side
  effect of the widget resolve. HW-read watchpoint on `[0x01175FB0]` while calling it from console.

### 9.5 `LTIupdateSupportQuickSlot` — narrowed to a single in-game repro

Everything static is now settled against it (§8.2): the AS event is absent from all 83 movies, the
cfunc is a read `xor eax,eax; ret`, and the Lua implementation `EnableQuickSlot` has zero callers.
The only remaining question is **user-visible symptom**: does the PDA quick-slot demonstrably fail?
Reproduce in-game before writing the fix-pack entry.

### 9.6 `Movie.*` / `LTIMovie*` unreachable — CLOSED

Zero Lua call sites in either corpus, re-verified (`Movie.` in any form = 0; the four `LTIMovie*`
= 0). `mrxguicinematic.lua` drives `MovieWidget` (`mrxguibase.lua:1365`) over
`_GuiInternal.CreateMovieWidget` (`0x005BC1A0`, §2.1b); nothing in the fscommand vocabulary reaches
`Movie.*`, and `LTIMovieStart` / `MovieStart` are absent from all 83 movies.

### 9.7 `[0x01176018]` region ids — CLOSED

`FUN_0061C440` switches on `*[0x01176018]` through the jump table at `0x0061C524` and Invokes
`setTerritory` with `"SP"` (`0x00BBC794`) / `"IT"` / `"FR"` / `"GR"` / `"RU"` (`0x00BBC7A4`) / `"EN"`
(`0x00BBC7A8`, the out-of-range default). The same function Invokes **`confirmButtonReversed`** as a
Boolean `(*[0x00D1E50C] == 8)`; that global reads **6** in the dump. `LTIGetDateFormat`'s `{0, 6}` US
set is consistent with `EN` = 6.

### 9.8 The registrar glue chunks and its consumer loop — CLOSED

§1.3 now carries both. Two corrections to what this item used to say: it is **nine** non-empty glue
chunks, not three; and "no `.text` reference to the table VAs exists, so it is data-driven" is true of
the *table* VAs but false of the **array base** — `0x00DFD478` has four `.text` references and the
consumer loop is plain at `0x005A2D38`–`0x005A2DF7`. `0x005A2FD0` (the per-library registrar) is a
full SecuROM steal whose stolen body at `0x02471B40` **is decrypted in this dump** and calls back into
`0x005A2E40` / `0x005A2E90` — the `{name, 0xFFFFFFFF}` / `0xFFFFFFFE` marker-row walker
(`cmp ecx,-1` at `0x005A2E55`). Image-wide there are 11 of each marker row and **none is in the LTI
or `Movie` table**. This also closes `scripting_host_binding_code_map.md` §1.2/§6 without a debugger.

---

## 10. Corrections to sibling documents

These are recorded here rather than edited in, so the owning maps can adopt them deliberately.

**`docs/ui/main_menu_structure.md` §5:**

1. **"LTI (Lua To Interface)" is invented.** §5's heading reads verbatim
   `## 5. LTI (Lua To Interface) Callback Functions`. That expansion appears in **no** primary
   source: not in the exe (172 `LTI`-containing strings, none an expansion), not in any of the 83
   shipped `.gfx`, not in the Xbox-360 PDB corpus `docs/mercs2-pdb-analysis/` (zero `Lti`/`LTI`
   symbols), and not in `Saboteur.exe` (zero `LTI`/`PgLti`/`LtiRender` strings). LTI is the PC
   render/platform source module (§1); **the acronym is not determinable and should be stated as
   unknown**, not glossed.
2. **"Registration Table located at `0x00B99D00`"** — the table starts at **`0x00B99C78`**.
   `0x00B99D00` is entry **#17** (`LTIVideoAdvanceDefault`), i.e. off by exactly 17 entries. ⚠ **this
   map's own diagnosis of the String-VA column was wrong**: it said the column "is shifted by one
   entry from about `LTIProfileExit` onward". It is not a uniform shift. Of §5's 15 rows, 4 are
   correct, 5 are AS names with no cfunc at all, and of the 6 wrong VAs only
   `LTIChoseOnline = 0x00BB69DC` lands on another real entry (`LTICamera`'s). The rest —
   `0x00BB6A4C`, `0x00BB6A00`, `0x00BB69EC`, `0x00BB69C4`, `0x00BB69A4` — are off-by-4/8/12 drift
   landing mid-string, not entry-granular. §3 has the verified column.
3. **It merges two opposite directions into one list.** `LTIPressStart`, `LTIgotoGame`,
   `LTIProfileOnlinePlay`, `LTIAllowFlashMouse`, `LTIVideoSetResolution2`, `LTIVideoSetRefresh2`,
   `LTIVideoDetail`, `LTIVideoSetVsync`, `LTIVideoSetSwitchOpt1..8`, `LTIVideoDisableHighShaders`,
   `LTISetGraphicDetail`, `LTIvideoSubtitles` and the whole `LTIAudio*` group are **ActionScript
   function names the engine Invokes** (§6) — they are *not* Lua bindings and have no cfunc VA.
   `AdvAccept` is a `LTIPauseItemChanged` key string (§5), not a callback. Its "Movie LTI Functions"
   sub-table is right that `LTIMovie*` exist, but `LTIMovieStart` is a no-op stub on PC. ⚠ the ~20 AS
   names named above are an **undercount**: §5 merges directions across six sub-tables, and at least
   25 more are affected, including two entire sub-tables (all 4 "Game Options", all 3 "Multiplayer")
   plus 13 `LTIInput*` and 4 `LTIVideoSet*`.
4. **New: §5 omits 10 of the 52 real bindings** — `LTIInputKMDefault`, `LTIInputKMCancelInput`,
   `LTIInputKMExit`, `LTIInputJoystickChangePrimary`, `LTIInputJoystickCancel`,
   `LTIInputJoystickDefault`, `LTIInputJoystickExit`, `LTIInputJoystickReEnter`, `LTIGetDateFormat`,
   `LTIupdateSupportQuickSlot`.
5. **New: its §1 asserts scripts call `ChangeShellState("newGame")`.** They do not — **all 24 shipped
   call sites pass a boolean** (15× `true`, 9× `false`); zero string arguments exist. Its §1 also
   disassembles `0x005C3740` with the `[0x01176034]` guard the *opposite* way round from §3 row 41.
   Re-read here, row 41 is right: `if ([0x1175F2F] == 0) [0x01176034] = 0`.

**`docs/mercs2_licensing_registration_map.md`** — its "Unproven: `thunk_FUN_024b5390` sink
(telemetry vs DiP vs Nucleus auth)" is **resolved for that function**: it is `FUN_0061C550`, the
Scaleform Invoke helper (§2), which contains only
`EnterCriticalSection → IsAvailable → Invoke → LeaveCriticalSection` — no socket, no file, no HTTP,
no crypto. But the map's follow-on sentence, *"the CD key is being displayed, not transmitted"*, is
**true of `FUN_00847FE0` and misleading as a statement about the `0x00848xxx` block**, and is
corrected here. What the block actually does, from a full enumeration of `.rdata`
`0x00BE3100`–`0x00BE32E0` with `.text` cross-references:

* **`FUN_00847FE0` displays.** `mov edi, 0x00BE3114` = `"LTIRegisterBox"`, two `GFxValue`s of tag 4
  (`VT_String`) — one copied from the `ergc` key buffer `0x00F7F1D0`, one a localisation token
  selected by the region compare at `0x00848043` — `presult = NULL`, `numArgs = 2`. `LTIRegisterBox`
  ships in `shell/SHELL.gfx`. ⚠ **this map previously attributed that Invoke to `FUN_008486F0`; it is
  `FUN_00847FE0`** (§6).
* **`FUN_00848990` compares, and does not transmit.** It is the **sole referencer of all four**
  `Account.*` names — `Account.BirthDate` `0x00BE3234` (ref `0x00848A06`), `Account.EmailAddress`
  `0x00BE3258` (`0x00848A22`), `Account.ParentalEmailAddress` `0x00BE3270` (`0x00848A34`) and
  **`Account.Address.Zip` `0x00BE3290`** (`0x00848A52`) — and it receives an *error code* plus a
  *field name from the server*, `memcmp`s that name against the four literals to pick a stringdb
  token, builds a 6-element `GFxValue` array and Invokes **`LTIonlineMsgBox`** at `0x00848AD1`.
  **An error-message formatter. No sink.**
* **`FUN_008482F0` DOES transmit.** It is the sole referencer of `GAME-MERCENARIES2-WIF`
  (`0x00BE3174`, ref `0x0084831D`). It assembles the product code on the stack byte-by-byte, does
  `strcpy(DAT_00F7F1D0, <key in EDI>)` (`0x00848358`: `mov edx,0xF7F1D0 / sub edx,edi` then the inline
  copy loop at `0x00848380`), then issues an **asynchronous service request** — `call 0x0096DAC0` →
  `vtbl+4` → `vtbl+0x18` / `vtbl+8`, passing `&DAT_01176460`, `&DAT_01176480`, a **10 000 ms timeout**
  (`push 0x2710` at `0x008483E0`) and **`FUN_00847FE0` as the completion callback**
  (`mov esi, 0x847FE0` at `0x008483D1`). Single caller `0x006C9CF5`.
* **The account form leaves the movie in cleartext.** `shell/SHELL.gfx` hosts the registration screen
  (`lticreateAcct_mc`, `createAcctpageListener`, `inCreateAccountPage`) with fields `ltiusername`,
  `ltipassword`, `ltiemail`, `ltiparent_email`, `ltibMonth/Day/Year`, `lticountry`, `ltizip_code`; the
  payload builder concatenates them **`&`-delimited** into `createstr` and ships them with
  `fscommand("onlineCreateAccountNamePass", createstr)`. Siblings: `onlineExistingAccountNamePass`,
  `onlineLoginAccountPass`, `onlineSetParameters`, `onlineTOSAllowEA`, `onlineLTIRegisterGame`. The
  movie has no `LoadVars`/`XML`/`getURL` of its own — these are host `fscommand`s into the engine.

  **Net effect: the licensing map's open item is narrowed, not eliminated.** `thunk_FUN_024b5390` is
  cleared; the sink behind `FUN_008482F0`'s service vtable is not, and it is the one that matters.

  ⚠ **Provenance correction.** An earlier note in this map implied the licensing map already
  documents an `Account.EmailAddress` / `BirthDate` / `ParentalEmailAddress` / `GAME-MERCENARIES2-WIF`
  inventory. **It does not** — none of those tokens appears in that document. That inventory is this
  map's own first-hand finding and is graded as such.

**`docs/reverse_engineer/scaleform_gfx_class_map.md`** — §6 documents 56 *pure-forwarder* trampolines
**and** split bodies, with a worked example (`Execute` @`0x0076AB40` + tail @`0x0076F252`), so this
map previously overstated its own novelty there. The genuinely new part is that **chain-following
fails for this shape**: `FUN_0061C550`, `FUN_005C63E0`, `FUN_005C13A0`, `FUN_0074AE20`,
`FUN_0074C7A0`, `FUN_005C0870` and `FUN_005C0550` have a `jmp dword [<Sdata>]` overwriting the
prologue with the body intact a few bytes later (**7 bytes / resume at `entry+9`** for
`FUN_0061C550` — §2.1; the "6 bytes / `entry+0x12`" formula was wrong). Read the tail instead.
Conversely that map's §7.2 **independently gives `+0x28 IsAvailable`, `+0x48 Invoke` at `obj+0x1E0`**
— the strongest external corroboration of §2, which this map failed to cite.

**`docs/data/scaleform_gfx_function_map.json`** — add a row for `0x0061C550`
(`class=ExternalInterface`, `role=Invoke helper`) and one for `FUN_00847FE0`; both are currently
absent. ⚠ **Do not import "194"** — the figure is **250** funnel sites, 277 static Invoke sites total
(§2.1a), and the earlier recommendation would have written a Ghidra artefact into a data file.
Also worth a row: `_GuiInternal.CallFlashScriptFunction` `0x005BB170` (§2.1b).

---

## 11. Reconciliation with the Rust reimpl

`docs/modernization/wave0_seam_review.md` Seam G left `LTILibName` **unassigned**. It should belong to
**`mercs2_ui`**, not to a render crate: despite LTI being the render module in the original tree, all
52 bindings are screen drivers.

`tools/wad_simulator/crates/mercs2_script/src/bindings/lti.rs` currently holds the 52 `Required`
names with `install` unfilled. Items 1–3 below **have since been applied in the repo** and are kept
only as a record of what changed and why.

1. ✅ **DONE — `GLOBAL = "Lti"` was wrong; it is `"LTILibName"`** (§1.3, proven from the `.data`
   registrar). `lti.rs` now carries `NAMESPACE = GLOBAL = "LTILibName"`.
   `mercs2_script/DEFERRED.md` flagged this exact uncertainty ("`Lti` (corpus prefix was the
   module-local `LTILibName`)") and asked for a confirm-live read of the registrar; the registrar has
   been read statically, and the module-local prefix **was** the global. The same array settles **all
   31** globals, not just the two that file lists — including `_SYS`, `Sys`, `Pg`, `Object`, `Player`,
   `Event`, `Ai`, `Human`, `Debug`, `Vehicle`, `Airstrike`, `Gui`, `_GuiInternal`, and of course
   **`Report`** (not "Infraction") and **`ObjectFilter`** (not "Filter"). Full list in §1.3.
2. ✅ **DONE — every `corpus_calls` was 0, and every one was wrong** for the 48 called bindings: the
   census heuristic matched `Global.Func(` while the shipped prefix is `LTILibName.`. Re-run under
   the correct key, `lti.rs` now shows **48 of 52 rows nonzero, 220 call sites** — a **mid-traffic**
   namespace, not a dead one. (Whichever rule a future re-run uses, state it: 220 raw over the 370
   `.lua` files, 221 if the corpus's `.md` index files are walked, 148 deduplicated.)
3. ✅ **DONE — `movie.rs` created.** The `Movie` namespace (registry row 21, `0x00B99BBC`, 4 cfuncs)
   was absent from `bindings/` entirely, so `binding_smoke.rs` could not see it and the coverage
   scoreboard under-counted the engine surface by four. Note the file records the distinction
   honestly: these are stubs because *we* have no Bink path, **not** because retail does nothing —
   unlike `LTIMovieStart`, which genuinely is a no-op.
4. **Still to do: `LTIMovieStart` and `LTIupdateSupportQuickSlot` must be `b.stub(..)`** — they are
   the shared `xor eax,eax; ret` on retail PC (§8.1, now **read** rather than inferred). ⚠ the
   instruction as originally written is unactionable: there is no `b.real("LTIMovieStart")` line to
   change. All 51 non-`FirstRun` names go through `super::record_all(...)`, so the fix is to lift
   those two names out of that array. Also: `FirstRun` returns `Ok(0i64)` (an mlua Integer) where
   retail pushes a **float** (`cvtsi2ss` → `tt = 3`), and returns 0 where retail returns **1.0** on a
   normal install (`Mercs2.ini` has `FirstRun=0`).

What the retail engine says a reimplementation must model:

5. **One funnel, name-gated — but it is not the *only* path, and it has a return channel.**
   ⚠ this item used to read "Everything engine→UI goes through a single
   `invoke(movie, name, &[Value])`". Corrected: the funnel carries **250 of 277** sites (90.3 %); the
   other **27 are inlined bypasses** (§2.1a), so a reimplementation built to a strict single-funnel
   rule silently drops them. And the signature is wrong twice over — `_GuiInternal.CallFlashScriptFunction`
   (§2.1b) passes a **non-NULL `presult`** and converts the result back to Lua, and it supports up to
   **64** arguments, not the 1–6 seen at LTI sites. Model
   `invoke(movie, name, &[Value]) -> Option<Value>`. Reproduce the `IsAvailable` guard: a missing AS
   function must be a silent no-op, not an error, or the front end will start throwing on movies that
   shipped fine — and note that **four shipped names really do miss** (`ProfilesComplete`,
   `AddProfile`, `loadProfile`, `joingameSavegame` — §2.2), so the guard is load-bearing, not
   defensive.
6. **Three copies of the settings block, not one** (§4). Live / committed / advanced-undo, with
   `Enter`/`Apply`/`Cancel`/`Default` moving between them. Collapsing them into one struct breaks
   Cancel and breaks the Advanced page's undo.
7. **Preserve the quirks that scripts do not observe** (§8.3, §4.1's asymmetric clamps). They are
   part of the oracle. ⚠ this item used to be scoped to three cfuncs; **the "declares a result it
   never pushes" class is 22 cfuncs** (§8.3), so an oracle built from the old rule will diverge on 19
   further bindings. In particular `LTIVideoGetViewDistance` is a no-op that echoes its argument —
   implementing a real getter would change what 2 shipped call sites see.
8. **`FirstRun` returns a Lua *number*, not a boolean** (tag 3), and `LTIChoseOnline` writes a byte on
   the profile singleton, not on any UI object.
9. **Gamma stores the raw slider** (§4), not `1.5 − f*0.01`. A reimplementation that stores the
   transformed value will read back `1` where retail reads back `50`, and `LTIVideoCancel` — which
   re-derives the transform from the committed copy — will then double-transform.
10. **The INI section is a per-call argument**, not a constant `"Render"` (§0.5): `[Joystick] Invert`
    and `[Joystick] Rumble` are written from inside this namespace.

---

## 12. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`). Bodies read first-hand this pass: the 27 decompiled LTI cfuncs (§3), `Movie.Start`
  `FUN_005C6510`, the page-refresh helpers `FUN_005C0870`/`FUN_005C06C0`, the movie layer
  `FUN_00709640`/`FUN_00709CB0`, the settings writer `FUN_0074BB50`, the display-mode enumerators
  `FUN_00755590`/`FUN_00755770`, the Lua arg accessors `FUN_0059D730`/`FUN_0059D7C0`/`FUN_0059D850`/
  `FUN_0059D8E0`/`FUN_0059F6D0`/`FUN_0059F820`/`FUN_0059FA40`, the widget resolve `FUN_00609940`, and
  the licensing packager `FUN_00847FE0` (cross-check for §10).
- **Direct disassembly** of `output/_ghidra/securom_dump/mercs2_unpacked.exe` (capstone x86-32, PE
  section-mapped, binary-mode offsets) for the 23 cfuncs with no Ghidra body, for the split-body
  tails at **`0x0061C559`** / `0x005C63E6`, and for the EDI-name harvest behind **all 250**
  `call 0x0061C550` sites image-wide (not just the ones in this namespace, and not just the immediate
  form — see §2.1a for the 29 slot-sourced names an immediate-only harvest cannot see).
- ⚠ **The memory dump is not a neutral primary source.** `mercs2_unpacked.exe` is a *live dump*, and
  at least one address in this map's scope (`0x006D5640`) holds a **runtime hot-patch artifact**
  rather than retail bytes (§8.1). Where the dump and the on-disk images disagree, the on-disk image
  wins. Three further images are used as controls:
  - **`mercs2_nodrm_v2.exe` / `mercs2_nodrm_v3.exe`** — built from the *on-disk* decrypted exe.
    **Clean.** (`mercs2_nodrm_v1.exe` was built *from the dump* and inherits its corruption.)
  - **`genuine_patched_unpacked.exe`** — the **v1.1 build**. It is a different compile at different
    addresses, and the project's standing note flags it as a trap for that reason. It is also a
    *byte-level control*: `LTILibName` sits at the same `0x00B99C78` with the same 52 entries in the
    same order, and its `.text` is decrypted where the dump's is stolen. Used here to prove the
    `74 52` prologue byte (§2.1), to re-read the three "open" bodies (preamble), to read
    `LTIVideoAdvanceDefault`'s real body (§9.1) and to confirm `0x006D5640` (§8.1).
- **ActionScript**: all **83** shipped `.gfx` were inflated (`zlib.decompress(bytes[8:])` — the `CFX`
  header is followed by a zlib stream) and searched for exact NUL-delimited tokens; the two VSync
  handlers were additionally **lifted from AVM1 bytecode** (`defineFunction2` = opcode `0x8E`, body
  decoded against the nearest preceding `constantPool`) for §9.2. Extraction completeness is checked
  against `docs/data/aset_export.csv`: 83 assets of `type_hash 0xFE0E8320` (vz.wad 64 + shell.wad 16
  + Loading.wad 3) and `output/gfx_movies/` holds exactly 64 + 16 + 3.
- **Shipped data as a check on code-derived inferences**: `docs/game_config/Mercs2.ini`
  (`Gamma=50`, `PresentImmediate=1`, `FirstRun=0`, `[Joystick] Invert/Rumble/Sensitivity`),
  `game-files/PC-Movies/` (45 `.bik`, 0 `.ogg`), `docs/movies_pc_vs_ps3_catalog.md` (8 internal audio
  tracks). §7.1 is the case that justifies the habit: an H-graded conclusion read correctly off the
  code and refuted by the assets.
- **Binding table:** `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk,
  [[lua-trace-asi-surface-b-oracle]]), plus an independent raw `.rdata` re-walk performed here
  (identical, 52 entries, terminator `0x00B99E18`), plus
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)'s offline
  walk (same VA, 52 cfuncs, 2 stubs).
- **IAT resolution:** import-directory parse of the same image — `binkw32.dll!_BinkPause@8`
  `[0x00B055FC]`, `KERNEL32!EnterCriticalSection` `[0x00B05128]`,
  `KERNEL32!LeaveCriticalSection` `[0x00B0512C]`.
- **Script traffic:** `corpus_calls` census over `docs/mercs2-luacd/` (370 scripts), recomputed here
  against the `LTILibName.` prefix; `docs/mercs2-dlc-luacd/` checked for `Movie.*` (zero).
- **Cited, not re-derived:** [`scaleform_gfx_class_map.md`](scaleform_gfx_class_map.md) +
  [`../data/scaleform_gfx_function_map.json`](../data/scaleform_gfx_function_map.json) (GFx library,
  HAL, movie lifecycle, FSCommand dispatch; also §7.2's independent `+0x28`/`+0x48` derivation),
  [`input_code_map.md`](input_code_map.md) (**DirectInput8 device path `FUN_0082BA90`/`FUN_004FC0C0`,
  the 53-entry `PTR_s_Left_Stick___Left_00cf2560` table** — and *only* those; see the citation
  correction in the boundary table),
  [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) (the 60-table index, the
  forcing-script recovery),
  [`save_serialize_code_map.md`](save_serialize_code_map.md) (the singleton `[0x01176054]` — **not**
  its `+0x10`),
  [`audio_code_map.md`](audio_code_map.md) (the in-game cinematic pause path
  `FUN_00621AB0`/`FUN_00621BC0`, and `BinkSetSoundTrack`),
  [`../ui/main_menu_structure.md`](../ui/main_menu_structure.md) and
  [`../ui/shell_menu_lua_anatomy.md`](../ui/shell_menu_lua_anatomy.md) (shell inventory).

  ⚠ **Citation hygiene, 2026-07-26.** Three groups of claims in earlier revisions were presented as
  citations to sibling maps and are not in those maps. They are re-labelled above and in §0.5/§3 as
  **first-hand findings of this map**, and graded accordingly:
  1. `FUN_004FA570`, `FUN_004FBBA0`, `FUN_004FBC60`, `FUN_004FD930`, `FUN_0082A960`, `FUN_004FBF20`
     and `0x00EDAE60`, all cited to `input_code_map.md` — **none appears in that document, or
     anywhere else under `docs/`**.
  2. `+0x10` on the profile singleton, cited to `save_serialize_code_map.md` — that map owns
     `[0x01176054]` and documents `+0x11`, but `+0x10` appears in no other document.
  3. The `FUN_00709CB0`/`FUN_00709640` ↔ Bink-audio linkage and the `.ogg` sidecar, cited to
     `audio_code_map.md` — neither function nor `.ogg` appears in it. (§7.1 retracts the `.ogg`
     conclusion outright.)
  4. Likewise the `Account.*` / `GAME-MERCENARIES2-WIF` inventory is **not** in
     `mercs2_licensing_registration_map.md` (§10).
- **Figures that did *not* reproduce cleanly on re-derivation**, recorded rather than silently
  adopted, because each is a place where a future reader will get a different number:
  1. **"Distinct containing functions" of the funnel sites.** Reported variously as 62–63 (Ghidra
     decomp text), 73–74 (start-set union). Re-derived here with a decomp-start harvest: **47**.
     Three methods, three answers, same 250 sites. **Do not quote this quantity at all** — it is an
     artefact of the boundary model, not a property of the binary.
  2. **The `.data` AS-name slot table extent.** Reported as "a contiguous 39-entry table at
     `0x00D121B8`–`0x00D12250`". Walked here, the last valid string pointer is at `0x00D12248`
     (`videoWidescreen`); `0x00D1224C` reads `0x08040302` and is not a pointer. **37 entries,
     `0x00D121B8`–`0x00D12248`** is what the bytes support.
  3. **`FUN_0074BB50`'s whole-image section split.** Reported as "Render 23 · Network 5 · Audio 5 ·
     Joystick 4 · Game 3 · Mouse 2 · 5 register-sourced". A back-scan here resolves a literal at all
     47 sites and gives **Render 28** with none register-sourced — a method difference in how far
     back the scan looks, not a disagreement about the binary. The LTI-specific fact that matters
     (**2 sites write `[Joystick]`**, at `0x005C178E` and `0x005C18EB`) reproduces exactly.
- Confidence is stated per row. **Open items after this pass: two** — `LTIVideoAdvanceDefault`'s body
  (§9.1) and `FUN_0061C550`'s 7 stolen prologue bytes (§9.3), both with the earlier answer disproved,
  the residue bounded and a one-shot-breakpoint recipe. Lower-value confirm-lives remain for
  `LTICamera`'s role, `FUN_0061C550`'s ESI across non-LTI callers, the exact argument roles of
  `Movie.Start`, and an in-game repro for the PDA quick-slot (§9.4/§9.5). Everything marked H was
  read.
