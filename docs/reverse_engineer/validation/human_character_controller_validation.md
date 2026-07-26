---
title: Double-blind validation — human_character_controller_code_map.md
date: 2026-07-26
status: current
evidence: proven
subject: docs/reverse_engineer/human_character_controller_code_map.md
method: >
  Phase A written from primary sources ONLY (raw capstone disassembly of
  output/_ghidra/securom_dump/mercs2_unpacked.exe with VA->file via the PE section
  table; shipped vz.wad via mercs2_probe action_table_probe; tools/pandemic_hash.py)
  BEFORE the target map was opened. Phase B compares.
---

# Double-blind validation: the `Human` Lua namespace and the humanoid runtime

## Phase A — independent findings (written before reading the map)

### A0. Method and section mapping

`mercs2_unpacked.exe` (53,485,568 B) is a **flat/unpacked image**: for every section
`raw_ptr == virtual_addr` in size but **not** in value, so RVA==raw is wrong and the
section table must be used. Measured table (ImageBase `0x00400000`):

| section | VA range | raw ptr | raw size |
|---|---|---|---|
| `.text` | `0x00401000`–`0x00B05000` | `0x00001000` | `0x0704000` |
| `.rdata` | `0x00B05000`–`0x00BF6000` | `0x00705000` | `0x00F1000` |
| `.data` | `0x00BF6000`–`0x019FA000` | `0x007F6000` | `0x0E04000` |
| `Stext` | `0x01A49000`–`0x02084000` | `0x01649000` | `0x063B000` |
| `.securom` | `0x023E9000`–`0x03701000` | `0x01FE9000` | `0x1318000` |

> **Trap avoided.** `output/_ghidra/securom_dump/genuine_patched_unpacked.exe` is a
> **different build**, not a de-SecuROM'd twin of `mercs2_unpacked.exe`. Byte-comparing
> `Human.SetState` (`0x005BD760`) across the two shows the same instruction stream shifted
> by ~0x16 bytes, and its `.rdata` vsize differs (`0x0F0000` vs `0x0F1000`). Its restored
> SecuROM bodies are therefore **not admissible** as evidence about VAs in the unpacked
> dump. I discarded a body I had already recovered from it.

### A1. The table's true extent — 21 is right, and a sub-table follows

luaL_Reg array at `0x00B99EF0` (`.rdata`). Preceded by a `{NULL,NULL}` row at
`0x00B99EE8`, so `0x00B99EF0` really is the start.

* rows **0–20** = the **21 top-level `Human.*` cfuncs**.
* row **21** = `{"Inventory", 0xFFFFFFFF}` — **sub-table OPEN marker**.
* rows **22–30** = **9 `Human.Inventory.*` cfuncs**.
* row **31** = `{"Inventory", 0xFFFFFFFE}` — **sub-table CLOSE marker**.
* row **32** = `{NULL, NULL}` terminator at `0x00B99FF0`.
* row **33** (`0x00B99FF8`) is already the **`_GuiInternal`** table (`CreateWidget`, …).

So the array is **33 rows / 264 bytes**, `0x00B99EF0`–`0x00B99FF7`, carrying **30 cfuncs**.

The 21:

| # | name | cfunc |
|---|---|---|
| 0 | DoAction | `0x005BD260` |
| 1 | SetState | `0x005BD760` |
| 2 | Knockdown | `0x005BD860` |
| 3 | SetPreemptiveRagdoll | `0x005BD9B0` |
| 4 | ForceExitSeatNoSnap | `0x005BD1E0` |
| 5 | Emote | `0x005BD740` |
| 6 | PlayRawAnimation | `0x005BD750` |
| 7 | PersistTransform | `0x005BDA70` |
| 8 | IsSwimming | `0x005BDC00` |
| 9 | IsCarrying | `0x005BDD10` |
| 10 | Drop | `0x005BDDD0` |
| 11 | IsGrappling | `0x005BDF00` |
| 12 | StopGrappling | `0x005BDFC0` |
| 13 | EnableWeapons | `0x005BE220` |
| 14 | DisableWeapons | `0x005BE230` |
| 15 | SetFireLock | `0x005BE240` |
| 16 | EquipWeapon | `0x005BE340` |
| 17 | StowWeapon | `0x005BE4C0` |
| 18 | SetAllowCorpseCleanup | `0x005BE5F0` |
| 19 | Scrub | `0x005BE730` |
| 20 | SetJostleEnabled | `0x005BE890` |

The 9 in `Human.Inventory`: `GetPrimaryWeapon 0x005BE9B0`, `GetSecondaryWeapon 0x005BEB30`,
`GetVehicleWeapon 0x005BECB0`, `GetAllWeapons 0x005BED60`, `SetAllWeapons 0x005BF160`,
`DropWeapon 0x005BF420`, `EquipWeapon 0x005BF4E0`, `ReloadAll 0x005BF6B0`,
`DestroyAllWeapons 0x005BF630`.

**Note:** `EquipWeapon` appears twice under the *same* name pointer `0x00BB6730` but with
**two different cfuncs** — `Human.EquipWeapon = 0x005BE340` and
`Human.Inventory.EquipWeapon = 0x005BF4E0`.

Registry check (namespace truth, `0x00DFD478`, `.data`): the registry is an array of
12-byte `{const char* name, luaL_Reg* table, const char* doc}` triples. Row at
`0x00DFD4CC` = `{"Human", 0x00B99EF0, 0x00BA8B09}`. Walking the whole registry yields
**31 namespaces / 1003 distinct cfunc VAs**; `Human` reports **30**, matching 21 + 9.

### A2. Body coverage — 21/21 readable; Ghidra has 9

Every one of the 21 is a real `.text` body, contiguous in `0x005BD1E0`–`0x005BE9B0`.
I read all 21 from raw capstone disassembly.

Ghidra (`output/_ghidra/mercs2_unpacked.exe_decomp.txt`) **defines only 9**:
`DoAction, Knockdown, PersistTransform, Drop, StopGrappling, EquipWeapon, StowWeapon,
SetAllowCorpseCleanup, Scrub`.
**12 have zero references in the decomp**: `ForceExitSeatNoSnap, Emote, PlayRawAnimation,
SetState, SetPreemptiveRagdoll, IsSwimming, IsCarrying, IsGrappling, EnableWeapons,
DisableWeapons, SetFireLock, SetJostleEnabled`. Spot-checked bodies for all 12 below.

Two **helpers** in this address range are SecuROM split-thunks whose bodies are *not*
statically present in the unpacked dump:

* `0x005BE050` — the shared `EnableWeapons`/`DisableWeapons` worker:
  `jmp dword ptr [0x02458448]` → `0x024E6250` → `push 0x024E625A; call 0x01AAFF10`.
  `0x01AAFF10` is itself `jmp dword ptr [0x021FD554]` in `Stext` — the SecuROM dispatcher.
* `0x005BF7E0` — called by `StopGrappling`: `jmp dword ptr [0x02455A2C]` → `0x024BA620`.

Also stolen and relevant: `FUN_00520EF0` (pool lookup used by `SetState`),
`FUN_0059F990` (`lua_tostring`), and **`FUN_0068CC00` itself** (`jmp dword ptr [0x0245E1D8]`).

### A3. `FUN_0059FB00` returns an interned NAME-HASH, not a `char*`

`FUN_0059FB00(esi = lua_State holder, eax = stack index, [esp+4] = u32* out)`:

```
0059FB23  mov eax, esi
0059FB25  call 0x59f990          ; lua_tostring -> const char*
0059FB2A  mov edx, eax
0059FB2C  call 0x824270          ; <-- hashes it
0059FB3C  mov dword ptr [ecx], eax   ; *out = HASH
0059FB3F  mov eax, edx           ; return 1 if non-zero
```

`FUN_00824270` **is literally `pandemic_hash_m2`**:

```
00824280  movsx ecx, cl
00824283  or    ecx, 0x20          ; case suppression
00824286  xor   eax, ecx
0082428B  imul  eax, eax, 0x1000193
...
00824298  xor   eax, 0x2a          ; the M2 finaliser
0082429B  imul  eax, eax, 0x1000193
```

(the FNV basis is loaded at `0x004BDFB6` from `[0x0245D6D8]`, a SecuROM-relocated slot).

**Consequence:** every cfunc in this cluster that "takes a string" actually stores a
32-bit name-hash. Confirmed for `DoAction`, `SetState`.

### A4. Which containers is a "human" composed of?

The ECS container registry is an array of 116 `Container*` at **`0x00EDBAC8`**
(index 0..115, terminated by a NULL dword). But a full `.data` sweep for the container
shape (`+0x00` = `.rdata` vtable whose `+0x34` slot is a `mov eax, <str>; ret` name stub)
finds **293 containers** in total, so that 116-entry array is a *subset*, not the census.

Two structurally distinct families, and the distinction is mechanically visible:

| family | vtable | `+0x3C` name ptr | interpretation |
|---|---|---|---|
| `0x00DF9xxx`, 0x80 stride | shared trivial vtable (`0x00648AC0`…) — identical to the base-class vtable at `0x00BC6000` | **NULL** | not reflected/serialised |
| `0x017Bxxxx`/`0x017Cxxxx`, 0x50 stride | derived vtable (`0x0063FEA0`, `0x00848E30`, …) | set | reflected/serialised |

**But the `0x00DF9xxx` blocks are NOT nameless.** All 116 (and all 293) carry a name via
`vtable+0x34`:

| container | idx | stride | shift | name (from `vtable+0x34` stub) |
|---|---|---|---|---|
| `0x00DF9990` | 82 | 4 | 7 | **`HumanStateMachine`** |
| `0x00DF9A10` | 83 | 4 | 6 | **`HumanAnimationControllerNEW`** |
| `0x00DF9B90` | 93 | 4 | 3 | **`Players`** |
| `0x017BF428` | 35 | 0x28 | 3 | `RuntimeAnimationParams` (also at `+0x3C`) |
| `0x017BF888` | 52 | 4 | 8 | `PhysicsActor` (also at `+0x3C`) |
| `0x017BF9C8` | 56 | 0x48 | 6 | `RTHuman` (also at `+0x3C`) |
| `0x017C00F8` | 86 | 4 | 8 | `BoneControllerRuntime` (also at `+0x3C`) |

Stride 4 means the container stores **pointers** (hence the `mov eax,[eax]` after a
lookup); `RTHuman`'s stride 0x48 means it stores **72-byte records inline** (hence
`movss [eax+0x38]` with no deref). Both are visible in the disassembly and agree.

**Human creation** — `FUN_00667CB0` (`0x00667CB0`–`0x006681BA`, 1290 B) and the block
that follows it (`0x006681C0`–…) touch **at least twelve** containers for one human:

`PhysicsActor`, `RTHuman`, `HumanStateMachine`, `HumanAnimationControllerNEW`,
`BoneControllerRuntime`, `MaterialControllerRuntime`, `HumanAnimationSystem`,
`HumanAnimationSet`, `SceneObject`, `Carryable`, `EntranceParameters`, `ControlBinding`.
Add `RuntimeAnimationParams` (touched by `Human.DoAction`), `Equipment` and
`RuntimeInventory` (touched by `EquipWeapon` / the `Inventory` sub-table) and the
practical composition is **15+**, not six.

Per-cfunc container attribution (raw-disassembly derived):

| cfunc | container(s) |
|---|---|
| DoAction | HumanStateMachine, RuntimeAnimationParams |
| SetState | HumanStateMachine |
| Knockdown | HumanStateMachine, RTHuman |
| SetPreemptiveRagdoll | HumanAnimationControllerNEW |
| PersistTransform | RTHuman |
| IsSwimming | HumanStateMachine |
| IsCarrying | RTHuman |
| Drop | RTHuman |
| EquipWeapon | Equipment, RuntimeInventory |
| SetAllowCorpseCleanup | Label (`0x00DF8108`) |
| Scrub | RuntimeInventory, RuntimePhysicalLink, Sticky |
| SetJostleEnabled | BoneControllerRuntime |
| ForceExitSeatNoSnap, Emote, PlayRawAnimation, IsGrappling, StopGrappling, EnableWeapons, DisableWeapons, SetFireLock, StowWeapon | none directly — they delegate |

### A5. What each cfunc actually writes, and where

Verified writes (raw disassembly):

* **`Knockdown`** — `movss [RTHuman_rec + 0x38], xmm0` where `xmm0` = arg 2 (float), then
  the state call. `RTHuman+0x38` = **knockdown duration**.
* **`SetPreemptiveRagdoll`** — `mov byte ptr [obj + 0xC0], 1` on the
  `HumanAnimationControllerNEW` object.
* **`IsCarrying`** — reads `word [RTHuman_rec + 0x3C]`, `shr dx, 0xB`, `and 1` →
  **bit 11 of the u16 at `RTHuman+0x3C`**.
* **`IsGrappling`** — `call 0x00432740(edi=obj)`; reads `byte [ret + 0x2F4]`.
* **`IsSwimming`** — `cmp dword ptr [human + 4], 0x614DB965`.
* **`SetJostleEnabled`** — `FUN_00685C90(0xE551D91A, &buf, 0x20)` enumerates matching
  bone controllers, then per entry:
  `byte[bc+0xA4] = (byte[bc+0xA4] & 0xFD) | (arg2 << 1)` — **bit 1 of `+0xA4`**.
  (`0xE551D91A` is a real name-hash; I could not crack the pre-image — recorded as unknown,
  not guessed.)
* **`SetAllowCorpseCleanup`** — stages `0xFAF6DA61` (pre-image not cracked) and touches the
  `Label` container.
* **`SetFireLock`** — no direct write; `FUN_00529D50(eax=obj, bool)`.
* **`Scrub`** — links the object onto a global free list (see A8).
* **`Emote`/`PlayRawAnimation`** — 16-byte thunks: `call 0x005BD450` with a literal
  `0`/`1` selector; `0x005BD450` sits *inside* `DoAction`'s address range, i.e. it is the
  shared worker Ghidra folded into `DoAction`.
* **`EnableWeapons`/`DisableWeapons`** — 16-byte thunks: `call 0x005BE050` with `1`/`0`.

### A6. `humanObj+0x04` is the Stance hash — and `+0x08` is the Action hash

Byte-pattern probe over `.text` for `cmp/mov dword ptr [r32 + disp8], imm32` where the
immediate is one of the 17 non-sentinel **Stance** values or a known **Action** value from
the shipped ActionTable:

* `[reg+0x04]` — **13 sites, every one a Stance value** (`0x35365D24` ×2, `InVehicle` ×3,
  `Swim` ×4, `Crouched` ×4). **Zero** Action values.
* `[reg+0x08]` — **3 sites, all the Action value `0xB4DA003B` = "Idle"**. **Zero** Stance
  values.

The clincher is the paired test, e.g. `0x004FA1D2`:

```
004FA1D2  cmp dword ptr [ebx + 4], 0x35365d24   ; Stance
004FA1DF  cmp dword ptr [ebx + 8], 0xb4da003b   ; Action = Idle
```

and at `0x004F973E` the same pair, immediately followed by

```
004F975A  push 0xb4da003b      ; action
004F975F  push 0x35365d24      ; stance
004F9764  call 0x68cc00
```

**So: `human+0x04` = Stance name-hash, `human+0x08` = Action name-hash.**

### A7. `FUN_0068CC00` — the setter, its signature, and Knockdown

`Human.SetState` (`0x005BD760`) tail:

```
005BD832  mov eax, [esp+0xc]        ; arg1 object id
005BD836  mov esi, 0xdf9990         ; HumanStateMachine pool
005BD83B  call 0x520ef0             ; lookup -> slot
005BD844  mov edx, [esp+0x10]       ; hash of arg3  (Action)
005BD848  mov ecx, [esp+0x14]       ; hash of arg2  (Stance)
005BD84C  mov edi, [eax]            ; EDI = human object   <-- 'this' in EDI
005BD84E  push edx                  ; action
005BD84F  push ecx                  ; stance
005BD850  call 0x68cc00
```

`Human.Knockdown` (`0x005BD860`) tail:

```
005BD8E1  mov ecx, 0x17bf9c8               ; RTHuman
005BD8E6  call 0x5857e0
005BD8EF  movss xmm0, [esp+0x10]           ; arg2 = duration
005BD8F5  movss dword ptr [eax + 0x38], xmm0
...                                        ; inlined HumanStateMachine lookup
005BD941  push 0x9c9f3f13                  ; action
005BD946  push 0x12c07b18                  ; stance
005BD94B  mov edi, eax
005BD94D  call 0x68cc00
```

**Confirmed:** `Knockdown` is *exactly* `SetState(stance=0x12C07B18, action=0x9C9F3F13)`
plus `RTHuman+0x38 = duration`.

**Signature (register-arg trap):** `FUN_0068CC00(EDI = human*, [esp+4] = stanceHash,
[esp+8] = actionHash)` — `this` in **EDI**, not ECX/ESI, and Ghidra would drop it.

**Scope caveat:** `FUN_0068CC00` has **22 direct callers** binary-wide. It is a general
engine state setter, not a Human-Lua-private helper. Its own body is **SecuROM-stolen**
(`jmp dword ptr [0x0245E1D8]`), so its internals are not statically readable in this dump;
the signature above is inferred from the call sites, which agree unanimously.

### A8. `DAT_00EDBAA4` / `PTR_DAT_00EDBAC0` — a lock + a global free list

Idiom, identical in `Human.Scrub` (`0x005BE85C`) and in unrelated code at `0x004031C2`:

```
push 0xedbaa4 ; call [0xb05128]    ; EnterCriticalSection
... head/link manipulation, link field at object+0x18, head at [0xedbac0] ...
push 0xedbaa4 ; call [0xb0512c]    ; LeaveCriticalSection
```

IAT resolved from the import directory: `0x00B05128 = KERNEL32!EnterCriticalSection`,
`0x00B0512C = KERNEL32!LeaveCriticalSection`.

`0x00EDBAA4` is byte-for-byte an `RTL_CRITICAL_SECTION`: `DebugInfo=0xFFFFFFFF`,
`LockCount=0xFFFFFFFF` (-1, unlocked), `RecursionCount=0`, `OwningThread=0`,
`LockSemaphore=0`, `SpinCount=0x020007D0`.

**Reference count, binary-wide: `0x00EDBAA4` appears at 1060 `.text` sites; `0x00EDBAC0`
at 1063**, spread from `0x00403xxx` to `0x009xxxxx`. This is unambiguously a **general
process-wide lock + free list**, in no way specific to seats.

### A9. `FUN_004255C0` writes `+0x41C = &RTHuman container`

`FUN_004255C0` spans `0x004255C0`–`0x00426378` (3512 B). At `0x00425928`:

```
00425928  mov dword ptr [edi + 0x41c], 0x17bf9c8   ; &RTHuman container
0042594C  mov ecx, dword ptr [edi + 0x41c]
0042599F  call 0x5857e0                            ; container lookup
```

**Confirmed literally.** (The function is a physics-actor constructor: it zero-inits
`edi+0x140…0x180` and installs vtable `0x00BA8D90`.)

### A10. Streamed tables in human create

```
00667D12  mov eax, [edi+4]
00667D22  mov [esp+0x2c], eax            ; per-character asset NAME hash
00667D26  mov dword ptr [esp+0x30], 0xece70371   ; asset TYPE hash
00667D2E  call [0xb05128]                ; EnterCriticalSection(0x1174FFC)
00667D39  call 0x874150                  ; typed asset acquire(&pair)
00667D47  call [0xb0512c]                ; LeaveCriticalSection
...  same shape with [edi+0] and 0x207359C7
```

Recomputed with `tools/pandemic_hash.py --m2`:

* `pandemic_hash_m2("HumanStateTable")` = **`0xECE70371`** ✔
* `pandemic_hash_m2("AnimationTable")` = **`0x207359C7`** ✔ (case-suppressed, so
  `"animationtable"` hashes identically; the canonical `.rdata` strings are
  `AnimationTable` @ `0x00BC9076` and `HumanStateTable` @ `0x00BC9088`)

These are the **type** hashes of an `(assetName, assetType)` acquire, not stream requests
per se; the per-character part is the *name* half, taken from the prototype.

### A11. ActionTable values, checked against SHIPPED DATA

`pandemic_hash_m2` recomputation:

| hash | pre-image | verified |
|---|---|---|
| `0x12C07B18` | `Upright` | ✔ |
| `0x614DB965` | `Swim` | ✔ |
| `0x9C9F3F13` | `Knockdown` | ✔ |

Ground truth from the shipped table — `mercs2_probe action_table_probe` against
`vz.wad`, ActionTable asset `0x6802C321`, type `0x207359C7`, 1020 rows, columns
`["Stance","Action","AimState","Tandem","Seat","Target","ActionDirection",
"DamageDirection","AnimationHandles","PartitionMask","Looping","Driven","ActionMask",
"LocomotionMask"]`:

**DISTINCT Stance (18 incl. the `0x27DE7135` NONE sentinel):**
`0x12C07B18` Upright ×171 · `0x1E5B33F7` Cower ×2 · `0x22948D2A` ×8 · `0x35365D24` ×3 ·
`0x403991E8` ×3 · `0x42C96259` ×4 · `0x4416D310` ×6 · `0x4BE8214B` ×9 ·
`0x5E2CD838` InVehicle ×740 · **`0x614DB965` Swim ×12** · `0x67EAAA1B` ×1 ·
`0xB9832CE2` ×4 · `0xBC671C97` ×2 · `0xC8886020` Crouched ×37 · `0xE2FC8CB1` ×6 ·
`0xE7B64876` Carrying ×3 · `0xFC8D859D` Prone ×6.

> **`Swim` as a Stance is confirmed against shipped data.** Names recovered by hashing real
> candidates: Upright, Swim, InVehicle, Crouched, Prone, Cower, Carrying. The other
> 10 Stance hashes are **not** cracked and are recorded as unknown.

**`0x9C9F3F13` (Knockdown) does NOT appear anywhere in the base-game ActionTable** —
not in the 303 distinct Action values, not in Stance, not anywhere in the probe output.
So the code definitely passes `Knockdown` as an *action argument*, but the base-game
ActionTable has no row keyed on it. That is a real, checkable asymmetry.

### A12. `0x00DF9B90` — the container behind `+0x158` / `+0x199`

Read literally from the raw bytes:

```
Player.SetGrappleEnabled  (cfunc 0x005DFBB0, body ends 0x005DFCBF)
005DFC61  be909bdf00  mov esi, 0xdf9b90
005DFC66  e85541e4ff  call 0x423dc0
005DFC6B  8b00        mov eax, dword ptr [eax]
005DFC85  888858010000 mov byte ptr [eax + 0x158], cl

Player.SetHealthClamp     (cfunc 0x005DC4F0, body ends 0x005DC5FF)
005DC5A1  be909bdf00  mov esi, 0xdf9b90
005DC5A6  e81578e4ff  call 0x423dc0
005DC5AB  8b00        mov eax, dword ptr [eax]
005DC5C5  888899010000 mov byte ptr [eax + 0x199], cl
```

Both instruction sequences are byte-identical up to the field offset. **The map's cited
evidence is real.** Independently, three stronger lines all agree that `0x00DF9B90` is the
**player** container:

1. **Name.** `0x00DF9B90`'s vtable (`0x00BC3FB8`) slot `+0x34` is
   `mov eax, 0x00BC5DAC; ret` → the literal string **`"Players"`**.
2. **Attribution.** Of the 133 `.text` references to `0x00DF9B90`, those landing inside a
   registered cfunc belong to **47 distinct `Player.*` cfuncs** (`GetCharacter`, `GetCash`,
   `CreatePlayer`, `SetInputEnabled`, …) and to **zero `Human.*` cfuncs**. Conversely
   `0x00DF9990` is referenced by `Human.DoAction/SetState/Knockdown/IsSwimming` and
   `Object.Revive`, and by **zero `Player.*` cfuncs**.
3. **Geometry.** `0x00DF9B90`'s page shift is **3** (8 slots/page) — a handful of players.
   `0x00DF9990`'s is **7** (128 slots/page) — a crowd of humans.

Both cfuncs are also `Player.*` table entries (`Player.SetGrappleEnabled` @ `0x00B992D8`,
`Player.SetHealthClamp` @ `0x00B990D8`).

**Independent verdict: `+0x158` and `+0x199` are fields of the PLAYER object. Not the
human. Settled.**

### A13. Things I could NOT establish in Phase A

* The bodies of `FUN_0068CC00`, `FUN_005BE050`, `FUN_005BF7E0`, `FUN_00520EF0`,
  `FUN_0059F990` — SecuROM-stolen in this dump. The `genuine_patched_unpacked.exe` is a
  different build and cannot substitute.
* The **writer** of `human+0x04`/`+0x08` — it is inside the stolen `FUN_0068CC00`. The
  *reader* side is proved (A6); the write is inferred.
* Pre-images for `0xE551D91A` (SetJostleEnabled selector), `0xFAF6DA61`
  (SetAllowCorpseCleanup), `0x2108278F` (StopGrappling), and 10 of the 17 Stance hashes.
* The FNV basis constant, which lives in a SecuROM-relocated slot (`[0x0245D6D8]`).
* Nothing here was checked against a **live process**; all of it is static plus shipped data.

---

## Phase B — verdicts

*(Written after reading `docs/reverse_engineer/human_character_controller_code_map.md`.)*

### Summary count

| Verdict | Count |
|---|---:|
| **CONFIRMED** | 35 |
| **CONTRADICTED** | 12 |
| **UNVERIFIABLE (static)** | 10 |
| **OVERSTATED** | 4 |
| **MISSING** | 8 |

**Headline:** the map's central technical claims are *correct*, and several of them I was able to
prove more strongly than the map does. The failures cluster in three places: (a) it declares the two
native blocks anonymous and files "name them" as a live-debugging task, when their names are two
instructions away; (b) it mis-describes the `Human.Inventory` table's structure, having inherited a
tool artefact; (c) it never checked its two new ActionTable values against the shipped ActionTable —
one of them is not in it.

---

### CONFIRMED (35)

| # | Claim | How I confirmed it |
|---|---|---|
| 1 | `Human` `luaL_Reg` at `0x00B99EF0`, **21** top-level cfuncs, **0 stubs** | walked `.rdata` from the section table; rows 0–20; registry `0x00DFD4CC` points here |
| 2 | Cfunc cluster `0x005BD1E0`–`0x005BE890` is contiguous | all 21 VAs land in that range, in address order |
| 3 | All 21 name→VA pairs (§3 table) | exact match, entry for entry, against my independent walk |
| 4 | **9 Ghidra-decompiled / 12 raw-disassembly split**, and the exact membership of both sets | counted definitions in `mercs2_unpacked.exe_decomp.txt`: exactly 9 defined; the other 12 have **zero** references. Membership matches the map's ⬤/◐ column exactly |
| 5 | **Zero binding-only.** All 21 are real bodies | read all 21 from raw capstone; every one is `.text` code, none is a stub or a bare jmp. Spot-checked in full: `SetState`, `IsSwimming`, `SetPreemptiveRagdoll`, `SetJostleEnabled`, `IsCarrying`, `IsGrappling`, `SetFireLock`, `Emote`, `PlayRawAnimation`, `EnableWeapons`, `DisableWeapons`, `ForceExitSeatNoSnap` — i.e. **all 12** of the Ghidra-missing set |
| 6 | **`humanObj+0x04` = Stance name-hash** | `IsSwimming` `cmp dword ptr [eax+4], 0x614db965`; plus a binary-wide byte-pattern probe: 13 `[reg+4]` immediate sites, **every one a Stance value, zero Action values** |
| 7 | `FUN_0068CC00(human /*EDI*/, stanceHash, actionHash)` is the setter both `SetState` and `Knockdown` call | read both call sites; `this` really is in **EDI**; push order `action` then `stance` at both |
| 8 | **`Knockdown` is literally `SetState(Upright, Knockdown)`** + duration to `RTHuman+0x38` | `movss [eax+0x38], xmm0` at `0x005BD8F5`; `push 0x9c9f3f13; push 0x12c07b18; mov edi,eax; call 0x68cc00` at `0x005BD941`–`0x005BD94D` |
| 9 | `Stance 0x12C07B18 = "Upright"` | `pandemic_hash_m2("Upright")` recomputed **and** 171 rows of the shipped ActionTable Stance column |
| 10 | `Stance 0x614DB965 = "Swim"` (**new value**) | recomputed **and** present in the shipped ActionTable Stance column, 12 rows |
| 11 | `pandemic_hash_m2("Knockdown") = 0x9C9F3F13` | recomputed ✔ (but see CONTRADICTED #11 for the "ActionTable value" framing) |
| 12 | **`FUN_0059FB00` returns a name-hash, not a `char*`** | read the body: `call 0x59f990` (tostring) → `mov edx,eax` → `call 0x824270` → `mov [out], eax`. This is the map's most useful trap-flag and it is correct |
| 13 | `FUN_004255C0` writes `+0x41C = &RTHuman container` | `0x00425928  mov dword ptr [edi+0x41c], 0x17bf9c8` — literal |
| 14 | `FUN_00667CB0` acquires `0xECE70371` and `0x207359C7` per character | read the two `(nameHash, typeHash)` pairs at `0x00667D26` / `0x00667D5C`; both hashes recomputed from real names |
| 15 | **`+0x158` / `+0x199` are on the PLAYER object, container `0x00DF9B90`** | the cited bytes are exact; and see the three independent strengthenings in A12 |
| 16 | `FUN_00423DC0` is `this`-in-ESI | `mov ecx, esi` at entry; all field reads off `esi` |
| 17 | `EnableWeapons`/`DisableWeapons` share `FUN_005BE050`, a SecuROM slot dispatching into the interpreter at `0x01AAFF10` | `jmp [0x02458448]` → `0x024E6250` → `push 0x24E625A; call 0x1AAFF10`. Byte-for-byte |
| 18 | All four §8 SecuROM slot values (`[0x0245E768]=0x02908000`, `[0x0245D6B8]=0x017BF888`, `[0x0245E1D8]=0x031C0000`, `[0x02458448]=0x024E6250`) | read all four out of the dump; **4/4 exact** |
| 19 | **CORRECTION accepted:** `DAT_00EDBAA4` / `PTR_DAT_00EDBAC0` is **not** seat-specific | far stronger than the map's argument: **1060 / 1063 `.text` references binary-wide**, spread `0x00403xxx`–`0x009xxxxx`. See CONTRADICTED #12 for the replacement name |
| 20 | Container bases and `+0x3C` name pointers for `RTHuman 0x017BF9C8`, `RuntimeAnimationParams 0x017BF428`, `PhysicsActor 0x017BF888`, `BoneControllerRuntime 0x017C00F8` | all four verified: `+0x3C` → the exact `.rdata` strings the map names (`0x017BFA04→0x00BC5B54` etc.) |
| 21 | `Emote`/`PlayRawAnimation` are 16-byte thunks → `FUN_005BD450(L, 0/1)` | read both; exact |
| 22 | carry flag = `RTHuman+0x3C` **bit 11** | `movzx edx,[eax+0x3c]; shr dx,0xb; and edx,1` |
| 23 | grapple flag at `+0x2F4` via `FUN_00432740` | `mov dl, byte ptr [eax+0x2f4]` at `0x005BDF98` |
| 24 | jostle = bit 1 of `+0xA4`, collected via `FUN_00685C90(0xE551D91A, &buf, 0x20)` | `and al,0xfd; or al,dl; mov [esi+0xa4],al` — exact |
| 25 | `SetPreemptiveRagdoll` writes `+0xC0 = 1` on container `0x00DF9A10`, unconditionally | `mov byte ptr [eax+0xc0], 1`; the inlined page walk uses `0xDF9A30/34/36/58/80` = that container |
| 26 | `SetFireLock` → `FUN_00529D50(guid /*EAX*/, bLock)` | exact |
| 27 | Command path: fill `RuntimeAnimationParams` → `mov esi,0x17bf428; call 0x532de0` → ring `FUN_00423D10`; selector `ebx = (…&0x253FF8AD) + 0xDE9D82CB` | every instruction present at `0x005BD3CC`/`0x005BD3D1`/`0x005BD6D6`/`0x005BD6DB`/`0x005BD6F4`/`0x005BD6FA`/`0x005BD704`. `0xDE9D82CB+0x253FF8AD = 0x03DD7B78` ✔ |
| 28 | `DAT_00DFBD77` / `DAT_00DFBD78` gates | `cmp byte ptr [0xdfbd77], bl` @ `0x005BD3D6`, `cmp byte ptr [0xdfbd78], bl` @ `0x005BD3F7` |
| 29 | Ctors `FUN_00A7C630` / `FUN_00A7C660` / `FUN_00A7AC50` for `0x00DF9990` / `0x00DF9A10` / `0x00DF8108` | each begins `mov eax, <container>; call 0x64a770` — exact |
| 30 | `0xDE9D82CB = "Emote"`, `0xF956736B = "Disposable"` | recomputed ✔; and `0xDE9D82CB` appears in the shipped ActionTable Action column (2 rows) |
| 31 | `SetAllowCorpseCleanup` inverted polarity, label `0xFAF6DA61`, container `0x00DF8108`, add via `FUN_00649180`, remove via vtable slot | read the whole body; exact, including the `FUN_006657F0` → `FUN_004B5F80` tail |
| 32 | Registrars `FUN_00646540` / `FUN_006457E0` / `FUN_0063D910` / `FUN_006477C0` | each is a real function start (`or eax,-1; …`) and the corresponding name-string reference falls inside it |
| 33 | "RVA == raw file offset" for this image | true for **all 13 sections**. Method-fragile in general, but the map's shortcut gives the right answer here |
| 34 | `0x03DD7B78` genuinely does not resolve | I could not crack it either; it *is* present in the shipped ActionTable Action column (2 rows), which anchors it |
| 35 | Script-corpus stance vocabulary `"Upright"`, `"InVehicle"`, `"Cower"`, `"Subdued"` | **all four hash into the shipped ActionTable Stance column** — `0x12C07B18` ×171, `0x5E2CD838` ×740, `0x1E5B33F7` ×2, **`0x67EAAA1B` ×1**. The map's Lua-corpus inference is vindicated against real data, and `Subdued` is a 4th Stance name the map earned without claiming |

---

### CONTRADICTED (12)

| # | Map says | Ground truth | Evidence |
|---|---|---|---|
| **1** | §0.5 / §1: the two native blocks "publish **no type-name string**"; §10.8 lists "give them real names" as an **open question requiring a live vtable dump** | **Both are named, statically, in the file.** Every container's vtable slot `+0x34` is a `mov eax,<str>; ret` name accessor | `0x00DF9990` vtable `0x00BC3BC8`, `+0x34` → `0x00647620` → `mov eax,0x00BC5CEC` = **`"HumanStateMachine"`**; `0x00DF9A10` vtable `0x00BC3C38`, `+0x34` → `0x00647630` → **`"HumanAnimationControllerNEW"`**; `0x00DF9B90` vtable `0x00BC3FB8`, `+0x34` → `0x00647BA0` → **`"Players"`**. Verified across **all 116** registry containers and a 293-container `.data` sweep — 116/116 resolve |
| **2** | §0 / §1: `0x00DF9A10` = "the **ragdoll-arm** block" | Its registered type name is **`HumanAnimationControllerNEW`**. `SetPreemptiveRagdoll` writing `+0xC0` there is one flag on an animation-controller block, not evidence the block *is* the ragdoll arm. (The real ragdoll containers exist separately: `PhysicsActorRagdoll 0x017BF928`, `RagdollController 0x017C0508`) | same vtable+0x34 read; container census |
| **3** | Boundaries table + §11.7: "the `Human.Inventory` table is a **separate `luaL_Reg` at `0x00B99FA0`**" and is "**not** part of the 21" | The 9 are a **marker-delimited sub-table inside the `Human` array**. `0x00B99F98` = `{"Inventory", 0xFFFFFFFF}` (OPEN), `0x00B99FE8` = `{"Inventory", 0xFFFFFFFE}` (CLOSE), array terminator `{NULL,NULL}` at `0x00B99FF0`, `_GuiInternal` starts at `0x00B99FF8`. `0x00B99FA0` is **row 22**, not a table start. The namespace registry contains **exactly one** pointer into this array — `0x00DFD4D0 → 0x00B99EF0`. *(Provenance of the error: `binding_map.json` reports two tables, `0x00B99EF0` count=21 and `0x00B99FA0` count=9, because the ASI's `.rdata` walk stops at the marker row. The map inherited the artefact. Its practical conclusion — don't fold the 9 into the 21 — still holds.)* | walked the array; searched the whole file for pointers to `0x00B99FA0` — **none** |
| **4** | §0 / §1: "a human is a GUID joined across **six** containers" | **Undercount.** `FUN_00667CB0` + the block after it touch **at least twelve**: `PhysicsActor`, `RTHuman`, `HumanStateMachine`, `HumanAnimationControllerNEW`, `BoneControllerRuntime`, `MaterialControllerRuntime`, `HumanAnimationSystem`, `HumanAnimationSet`, `SceneObject`, `Carryable`, `EntranceParameters`, `ControlBinding`. `RuntimeAnimationParams`, `Equipment` and `RuntimeInventory` bring it to 15 | container attribution over the create function using the 293-container name map |
| **5** | §2: `FUN_00824270` is "the engine **name-hash table resolver**"; the value is "**interned**" | `FUN_00824270` **is `pandemic_hash_m2` itself** — a pure computation, no table, no interning, no registry insert: `or ecx,0x20 / xor / imul 0x1000193` loop, then `xor eax,0x2a; imul eax,0x1000193`. The *resolver* is the separate open-addressed probe at **`0x008242B0`**, which `FUN_0059FB00` never calls. Matters because "interned" implies a registry that could miss | disassembled both |
| **6** | §0.5 / §1.1: teardown `FUN_006681C0`, **304 B** | **622 B** (`0x006681C0`–`0x0066842E`). And it is not purely teardown: it removes `RTHuman` (`push 0x17bf9c8; call 0x5e0580`) but also **adds** `MaterialControllerRuntime` (`push 0xdf9a90; call 0x649180`), plus `HumanAnimationSystem`, `HumanAnimationSet`, `BoneControllerRuntime` activity | function-extent scan + container attribution |
| **7** | §1.1 / §10.4: "`FUN_00667cb0` and `FUN_0066a2c0` … **neither has a static caller**" | `FUN_00667CB0` has **one** direct `E8` caller, at `0x006686D6`. Only `FUN_0066A2C0` has none | full `.text` relative-call scan |
| **8** | §"SecuROM is not a blocker": "**19 of the 21 cfunc bodies** are clean `.text`" | **All 21** cfunc bodies are clean `.text`. The SecuROM seam is one level *down*, in the workers. §12 states this correctly ("No cfunc in this map is binding-only"), so the map contradicts itself | read all 21 |
| **9** | §4.1: "**Three** of the 21 are 16-byte tail thunks" then lists **four** (`Emote`, `PlayRawAnimation`, `EnableWeapons`, `DisableWeapons`) | Four. Its own §3 table also marks four | arithmetic |
| **10** | §0.5: `Swim` — "**sole use** is `Human.IsSwimming`" | `0x614DB965` occurs at **10 `.text` sites** (`0x004AD622`, `0x0052A052`, `0x005344F0`, `0x00555A63`, `0x0058B778`, `0x005BDCB3`, `0x005FCC0C`, `0x005FCCF4`, `0x00689BE9`, `0x0069C259`) and in **12 rows** of the shipped ActionTable | file-wide constant search + probe |
| **11** | §2.1: `Action 0x9C9F3F13 = Knockdown` is presented as a **new value for the ActionTable's open vocabulary** | `0x9C9F3F13` **does not appear anywhere in the shipped base-game ActionTable** (`0x6802C321`, 1020 rows) — not among the 303 distinct Action values, not in Stance, not anywhere in the probe output. It is a real name-hash and a real argument to the state setter, but it is **not an ActionTable Action value** in shipped data | `mercs2_probe action_table_probe` over `vz.wad` |
| **12** | §7.2 correction: the pair is "a **general scratch-block pool**" | Right that it isn't seat-specific, wrong about what it is. `0x00EDBAA4` is an **`RTL_CRITICAL_SECTION`** (`DebugInfo=-1`, `LockCount=-1`, `SpinCount=0x020007D0`) passed to `KERNEL32!EnterCriticalSection`/`LeaveCriticalSection` (IAT `0x00B05128`/`0x00B0512C`); `0x00EDBAC0` is the **head of an intrusive singly-linked free list** with the link at `object+0x18`. "Pool" understates it — it is *the* global block lock | IAT parse + the identical idiom in `Scrub` (`0x005BE85C`) and at `0x004031C2` |

*(Bonus: §1 generalises the reflected-registrar shape as "capacity `0x100`, page shift **8** at `+0x26`". Page shift is 8 for `PhysicsActor` and `BoneControllerRuntime` but **6** for `RTHuman` and **3** for `RuntimeAnimationParams`; the seed `0x9E3779B9` at `+0x2C` does hold for all four.)*

---

### UNVERIFIABLE from static evidence (10) — and what would settle each

| # | Claim | What would settle it |
|---|---|---|
| 1 | §8: `FUN_0068CC00`'s slot `[0x0245E1D8]` → `0x031C0000` "reads `human+0x0C` and operates on `that+0x18`" | I confirmed the slot value but could not follow into `.securom` to verify the body. The map marks it **M**, correctly. Settle by single-stepping the veneer once while PAUSED |
| 2 | §8/§10.1: `EnableWeapons`/`DisableWeapons` **effect** | genuinely interpreter-dispatched. Map's recipe (one-shot bp at `0x005BE237`, step in, HW-write-watch) is sound. *Do not* substitute `genuine_patched_unpacked.exe` — it is a different build (A0) |
| 3 | §5/§10.3: `DAT_00DFBD77`/`78` = "local-apply gate" / "replicate gate" | inference from shape. I add a datum: they have **141 / 169 `.text` references** binary-wide, i.e. engine-global flags, not Human-local — consistent with a client/authority split, and consistent with `player_code_map`'s reading too. HW-read watchpoint + `Net.IsClient()` |
| 4 | §6.4/§10.5: `PersistTransform`'s target record | arithmetic verified as a quaternion→basis; the destination container is not statically pinned. HW-write watch on the 6-float store |
| 5 | §7.2/§10.6: `Scrub`'s semantics and `humanObj+0x1C` | I can now *name* the container it iterates (see MISSING #6) but not the semantics |
| 6 | The **writer** of `human+0x04`/`+0x08` | inside the SecuROM-stolen `FUN_0068CC00`. The reader side is proven; the write is inferred |
| 7 | §3 traffic counts (24 `SetState`, 27 `DisableWeapons`, …) and Lua signatures | I did not audit `docs/mercs2-luacd/`. The *stance vocabulary* those counts imply does check out against shipped data (CONFIRMED #35) |
| 8 | §3: `PlayRawAnimation` arity 7 / `Emote` arity 8 | I did not reconstruct `FUN_005BD450`'s full argument sequence |
| 9 | §Sources / §12: the Xbox PDB claims | not checked |
| 10 | Every cross-reference to a sibling map (`physics_`, `animation_`, `player_`, `ai_`, `vehicle_`, `weapons_combat_`, `ecs_reflection_registry_`) | out of scope by the validation rules — sibling maps are not evidence |

---

### OVERSTATED (4)

1. **§0 / §8: "19 of 21 have their effect pinned."** Only `EnableWeapons`/`DisableWeapons` are counted as unpinned, but §3 itself rates `PersistTransform`, `StopGrappling` and `Scrub` at **M** with open effects, and §10 lists all three as open. The honest number is **16 of 21**.
2. **§5: the three action verbs "share one shape"** including the `DFBD77`/`DFBD78` gates. The gates are in **`DoAction`'s own body only** (`0x005BD3D6`, `0x005BD3F7`); the shared worker `FUN_005BD450` that `Emote`/`PlayRawAnimation` call reads **neither**. So `Emote`/`PlayRawAnimation` are not gated the way the diagram implies.
3. **§0.5 confidence `H` on the `Swim` row** covers both "the name" (correct) and "sole use is `Human.IsSwimming`" (wrong — CONTRADICTED #10). One row, two claims, one confidence.
4. **§10.8** frames naming the native blocks as live-only work. It is a static two-instruction read, and filing it as an open question sent the reader to a debugger for nothing.

---

### MISSING (8)

1. **`humanObj+0x08` = the Action name-hash.** The map's whole model is a `(Stance, Action)` pair yet it only locates the Stance field. `+0x08` is read against Action values at 3 sites, and the paired test at `0x004FA1D2`/`0x004FA1DF` (`cmp [ebx+4], <stance>` then `cmp [ebx+8], 0xB4DA003B` = `"Idle"`) is decisive.
2. **The `vtable+0x34` name-accessor convention**, which yields a **static census of 293 named containers** (116 in the registry array at `0x00EDBAC8`). This one mechanism resolves the map's §10.8 outright and would let every bare `0x00DFxxxx`/`0x017Bxxxx` address in this and sibling maps be named.
3. **The shipped ActionTable's full Stance vocabulary.** §10.2 calls this "the highest-value open item" needing a live dump; `mercs2_probe action_table_probe` over `vz.wad` already prints all 18 distinct Stance values and all 303 Action values, no debugger involved. Named so far: Upright, InVehicle, Crouched, Swim, Prone, Cower, Carrying, Subdued (8 of 17 non-sentinel).
4. **The sub-table marker rows** `{name, 0xFFFFFFFF}` / `{name, 0xFFFFFFFE}` and the array's true terminator — see CONTRADICTED #3.
5. **Two more SecuROM-stolen functions in the same cluster** that §8's five-row inventory omits: **`FUN_0059F990`** (the `lua_tostring` inside `FUN_0059FB00`, `jmp [0x0245F0E4]`) and **`FUN_005BF7E0`** (called by `StopGrappling`, `jmp [0x02455A2C]` → `0x024BA620` — §8 lists the *thunk* but not that the cfunc reaches it through a `.text` stub at `0x005BF7E0`).
6. **`0x00DF9110`**, the container `Scrub` iterates, is **`RuntimePhysicalLink`** — left as a bare address in §7.2 despite being the key to §10.6.
7. **The `genuine_patched_unpacked.exe` trap.** It sits next to the dump in `securom_dump/` and *looks* like a de-SecuROM'd twin with the stolen bodies restored. It is a **different build** (`.rdata` vsize differs; `Human.SetState`'s byte stream is offset ~0x16). Anyone chasing §10.1 will find it and be misled.
8. **`Human.EquipWeapon` and `Human.Inventory.EquipWeapon` share one name pointer** (`0x00BB6730`) with two different cfuncs (`0x005BE340` / `0x005BF4E0`). §11.7 makes the right call but doesn't note that the duplication is visible in the table itself.

---

### Net assessment

The map is **substantially trustworthy on its core**: the 21-cfunc extent, the 9/12 Ghidra split, the
zero-binding-only claim, the `(Stance, Action)` model, `Knockdown == SetState(Upright, Knockdown)`,
the name-hash-not-`char*` trap, `+0x41C = &RTHuman`, the command ring path, and — most importantly —
**the `+0x158`/`+0x199` verdict, which independently survives three stronger tests than the one the
map used.** Its hash discipline is clean: all seven resolved hashes recompute correctly, and it
correctly refuses to name the four it couldn't crack.

Its weaknesses are of one kind: **it stopped one read short in several places**, then filed the
remainder as live-debugging work. The container names, the Action field, and the ActionTable
vocabulary were all statically available. The one claim that is wrong *and* consequential is the
`Human.Inventory` table structure, which it inherited from a tool rather than reading the bytes —
precisely the failure mode the marker-row convention exists to cause.


---

## Pass 2

**Date:** 2026-07-26 · **Method:** every non-CONFIRMED pass-1 item re-derived from primary
sources. Pass-1 verdicts were treated as untrusted; a pass-1 "unverifiable" was treated as a
hypothesis to disprove. Primary sources this pass: raw capstone disassembly of
`output/_ghidra/securom_dump/mercs2_unpacked.exe` **including the `Stext` / `.securom`
sections via resolved indirect slots**; the shipped `vz.wad` via
`mercs2_probe action_table_probe`; `docs/data/wad_vocab.txt` (648,202-line shipped-WAD string
harvest); the 370+75-script Lua corpora; `docs/mercs2-pdb-analysis/` +
`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`.

**Headline:** pass 1's central failure was accepting "SecuROM-stolen" as a wall. It is not one.
**Four of the five functions pass 1 declared unreadable were read in full this pass**, and the
fifth had its effect pinned by a sole-writer argument. That single correction closed 6 of the 10
"unverifiable" items outright.

### Score

| Pass-1 bucket | Items | Closed in pass 2 | Still open |
|---|--:|--:|--:|
| UNVERIFIABLE (static) | 10 | **9** | 1 (out-of-scope by rule) |
| "What I could not check" (A13) | 5 | **4** | 1 (5 hash pre-images) |
| CONTRADICTED | 12 | **12 re-derived** (10 upheld, 1 overturned, 1 amended) | 0 |
| OVERSTATED | 4 | **4 re-derived** (all upheld) | 0 |
| MISSING | 8 | **8 re-derived** (all upheld) | 0 |
| **Total** | **39** | **37** | **2** |

Still open: **5 name-hash pre-images** and the one **static edge** `FUN_005BE050 → 0x006FC560`.
Nothing else remains open, and neither residual requires a debugger for anything except
confirmation.

---

### Phase 0 — the open register

Numbered checklist built mechanically from pass 1 before any analysis. `U`=unverifiable,
`A`=A13 "could not check", `C`=contradicted, `O`=overstated, `M`=missing.

| # | Item | Pass-2 verdict |
|---|---|---|
| U1 | `FUN_0068CC00` body behind `[0x0245E1D8]` | **CLOSED — body read in full** |
| U2 | `EnableWeapons`/`DisableWeapons` effect | **CLOSED (effect)** — edge still open |
| U3 | `DAT_00DFBD77`/`78` semantics | **CLOSED — named by the engine itself** |
| U4 | `PersistTransform`'s target record | **CLOSED — `RTHuman`** |
| U5 | `Scrub`'s semantics and the `+0x1C` field | **CLOSED** |
| U6 | the **writer** of `human+0x04`/`+0x08` | **CLOSED — `FUN_0068CC00`, both proven** |
| U7 | §3 traffic counts + Lua signatures | **CLOSED — full corpus census** |
| U8 | `PlayRawAnimation` arity 7 / `Emote` arity 8 | **CLOSED — proven byte-for-byte** |
| U9 | the Xbox PDB claims | **CLOSED — claim REFUTED** |
| U10 | cross-refs to sibling maps | out of scope by validation rule (unchanged) |
| A1 | bodies of the 5 "SecuROM-stolen" functions | **4 of 5 read in full; 5th classified** |
| A2 | writer of `human+0x04`/`+0x08` | = U6, **CLOSED** |
| A3 | pre-images for the unresolved hashes | **10 of 15 cracked; 5 STILL-OPEN** |
| A4 | the FNV basis constant in `[0x0245D6D8]` | **CLOSED — `0x811C9DC5`** |
| A5 | nothing checked against a live process | still true, and now unnecessary |
| C1–C12 | the 12 contradictions | **all re-derived** (see below) |
| O1–O4 | the 4 overstatements | **all upheld** |
| M1–M8 | the 8 omissions | **all upheld** |

---

### ⚑ U1/U6/A1 — `FUN_0068CC00` is fully recovered

Pass 1 wrote: *"Its own body is **SecuROM-stolen** … so its internals are not statically readable
in this dump."* **That is wrong.** `mercs2_unpacked.exe` is a live memory dump; the indirect slot
is already resolved on disk. Deref and disassemble:

```
0068CC00  ff25d8e14502   jmp dword ptr [0x245e1d8]
[0x0245E1D8] = 0x031C0000                       ; inside .securom, plain relocated code
```

The complete body, `0x031C0000`–`0x031C0112` (275 B):

```
031C0000  mov  eax, [edi+0x0c]          ; edi = human ; +0x0C = the HumanStateTable handle
031C0003  sub  esp, 0x20
031C0006  test eax, eax
031C0008  push ebx / push ebp / push esi
031C000B  je   fail
031C0011  lea  ebx, [eax+0x18]          ; &table.stanceMap
031C0014  mov  eax, [esp+0x30]          ; arg1 = stanceHash
031C0018  push eax ; mov ecx, ebx       ; __thiscall Find(stanceMap, stanceHash)
031C001B  push 0x31c0032 ; jmp 0x31c0032    ; -> encrypted-call trampoline, returns to 0x31C004D
031C004D  test eax, eax ; jl fail       ; eax = index, negative = miss
031C0055  mov  ecx, [ebx]
031C0057  mov  ebx, [ecx+eax*4]         ; ebx = level-1 (Stance) entry
031C005C  je/test -> fail if null
031C0062  mov  esi, [esp+0x34]          ; arg2 = actionHash
031C0066  push esi ; mov ecx, ebx       ; __thiscall Find(stanceEntry, actionHash)
031C0069  push 0x31c007c ; push 0x68d270 ; ret     ; = call FUN_0068D270
031C007E  jl   fail
031C0084  mov  edx, [ebx]
031C0086  mov  ebp, [edx+eax*4]         ; ebp = level-2 (Action) entry
031C008B  je   fail
          ; stage a 0x18-byte transition record at [esp+0x10]:
          ;   [0x10]=[edi+0]  [0x14]=stance  [0x18]=action  [0x1C]=[edi+4] old stance
          ;   [0x20]=[edi+8] old action  [0x24]=0
031C00A1  lea  esi, [esp+0x10]          ; ← REGISTER ARG (Ghidra drops it)
031C00B9  push 0x31c00cb ; jmp 0x68cf20 ; = call FUN_0068CF20(esi = &record)
031C00CB  mov  ecx, [esp+0x30]          ; stance
031C00CF  mov  edx, [esp+0x34]          ; action
031C00D3  mov  [edi+0x18], ebx          ; ★ resolved Stance entry
031C00D6  mov  [edi+0x1c], ebp          ; ★ resolved Action entry
031C00D9  mov  [edi+0x04], ecx          ; ★★ STANCE HASH  — the write pass 1 called inferred
031C00DC  mov  [edi+0x08], edx          ; ★★ ACTION HASH  — likewise
031C00DF  push eax / pushfd / push edi
031C00E2  mov  eax, 0x6be45b87 ; push 0x24569a5 ; xor eax,[0x245fc80] ; call eax
          ;   -> 0x01A53D80 (Stext), a notify(edi) veneer w/ a trap-flag anti-debug fudge
031C00F7  mov  eax, [0x00DCBAD4]
031C00FC  mov  [edi+0x10], eax          ; transition timestamp / frame counter
031C00FF  mov  al, 1 ... ret 8          ; returns TRUE
031C010A  fail: xor al, al ... ret 8    ; returns FALSE
```

Resolutions of the obfuscated targets (all read out of the dump):

| Site | Encoding | Resolves to |
|---|---|---|
| `0x031C0033` | `~[0x0245A63C] ^ [0x2479B4A]` = `~0x62CFD208 ^ 0x9D58FF87` | **`0x0068D270`** |
| `0x031C006E` | literal `push 0x68d270; ret` | **`0x0068D270`** |
| `0x031C00BE` | literal `jmp 0x68cf20` | **`0x0068CF20`** |
| `0x031C00E2` | `0x6BE45B87 ^ [0x245FC80]` = `^ 0x6A416607` | **`0x01A53D80`** (`Stext`) |

**What this settles.**

1. **U6 / A2 — the writer of `human+0x04` and `+0x08` is proven, not inferred.** Both are
   written here, unconditionally, on the success path, from the two stack arguments. Pass 1's A6
   proved the *reader* side by immediate-pattern census; the *writer* side is now equally hard.
2. **`humanObj+0x08` = the Action name-hash is CONFIRMED** (pass-1 MISSING #1 upheld, and now
   proven from the write side as well as the read side).
3. **Two new fields on the state block:** `human+0x18` = resolved **Stance** record pointer,
   `human+0x1C` = resolved **Action** record pointer, and `human+0x10` = a transition stamp
   copied from `[0x00DCBAD4]`.
4. **`human+0x0C` is the HumanStateTable handle**, and the table is a **two-level
   Stance → Action → record map** (`table+0x18` is the level-1 map). This is the map's §10.2
   "highest-value open item" answered *structurally* from code: `HumanStateTable` is the
   **transition/vocabulary table** keyed exactly on the `(Stance, Action)` pair, and it is a
   different shape from the ActionTable (which is a flat 14-column row table).
5. **The signature is confirmed and the calling convention is exotic:**
   `bool __stdcall FUN_0068CC00(EDI = human*, [esp+4] = stanceHash, [esp+8] = actionHash)` —
   `this` in **EDI**, `ret 8`. Pass 1 inferred this from call sites; the body agrees.
6. **`FUN_0068CF20` is a state-transition event recorder**, not a mystery: gated on byte
   `[0x012350E8]`, it appends the staged 0x18-byte `{obj, newStance, newAction, oldStance,
   oldAction, 0}` record to a **0x400-entry ring at `0x0122ECE8`** (count `0x0122ECC0`) under CS
   `0x012350F0`, plus a category byte and a 8-bin population histogram. This is the native side
   of the Lua `Event.HumanStateTransition` the script corpus subscribes to (see below).

**Honest limit:** `FUN_0068D270` — the hash-map `Find` used for *both* levels — is itself a VM
stub. `0x0068D270 → [0x2459C4C] = 0x024E3590`, which decodes
`push 0x24E35AA; push 0x40437D; push 0x1ACBA9C; pushfd; sub [esp+4],0x1BB8C; popfd; ret`
→ target `0x1ACBA9C − 0x1BB8C = **0x01AAFF10**`, the SecuROM interpreter, with token `0x40437D`.
**Per the rule, that one counts as genuinely harder and is stated as such.** It does not matter
for the map: `Find` is a keyed lookup returning an index or a negative miss, which both call sites
establish unanimously.

---

### ⚑ U3 — `DAT_00DFBD77` / `DAT_00DFBD78`: three maps, three readings, now settled by name

Three sibling maps disagreed (`human_character_controller` = "local-apply / replicate gates";
`player_code_map` §7 + `object_entity_core_code_map` = "shutdown/teardown guard";
`mission_contract_flow_code_map` = "net host/client flags"). The engine names them itself.

```
; Net.IsClient   luaL_Reg 0x00B99900 -> cfunc 0x005C67D0
005C67D1  mov bl, byte ptr [0xdfbd77]
005C67F4  test bl, bl ; setne cl ; push_boolean(cl)

; Net.IsServer   luaL_Reg 0x00B99908 -> cfunc 0x005C6810
005C6811  mov bl, byte ptr [0xdfbd78]
005C6834  test bl, bl ; setne cl ; push_boolean(cl)
```

> **`DAT_00DFBD77` IS `Net.IsClient`. `DAT_00DFBD78` IS `Net.IsServer`.** Each cfunc is a
> six-instruction body that does nothing but push that byte as a boolean. This is not inference.

The publisher confirms it and gives the underlying enum. `FUN_006CECF0` stages a byte block and
commits it in one shot:

```
006CEDC1  mov  edx, [edi+0x24]          ; the net-session object
006CEDC4  mov  eax, [edx+0x0c]          ; ★ session MODE enum
006CEDC7  cmp  eax, 4 ; sete cl   -> [esp+0x16]
006CEDCD  cmp  eax, 1 ; sete dl   -> [esp+0x17]
006CEDDA  cmp  eax, 2 ; sete al   -> [esp+0x18]
...
006CEEB4  movq xmm0, [esp+0x14] ; movq [0x00DFBD74], xmm0   ; commits 0x74..0x7B
006CEEC2  movq xmm0, [esp+0x1c] ; movq [0x00DFBD7C], xmm0
006CEED0  movq xmm0, [esp+0x24] ; movq [0x00DFBD84], xmm0
```

So the whole `0x00DFBD74..0x00DFBD8B` block is one published snapshot of the net session, and
the three "flags" are three equality tests on **one** mode enum:

| Global | Meaning | Lua accessor |
|---|---|---|
| `0x00DFBD74` | session valid | (with `75`) `Net.IsMultiplayer` `0x005C66C0` |
| `0x00DFBD75` | from `FUN_006CFF90()` | " |
| `0x00DFBD76` | `mode == 4` | **`Net.IsLobby`** `0x005C6790` |
| **`0x00DFBD77`** | **`mode == 1`** | **`Net.IsClient`** `0x005C67D0` |
| **`0x00DFBD78`** | **`mode == 2`** | **`Net.IsServer`** `0x005C6810` |
| `0x00DFBD79` | `[session+8]` | — |

**Verdict on the three readings:**

- This map's "**local-apply gate / replicate gate**" is **CORRECT in effect**, and now has real
  names. `DoAction`'s shape reads perfectly: *if not a client, apply locally; if a server, also
  replicate.* Offline (`mode == 0`) applies locally and sends nothing. A pure client neither
  applies nor sends — it waits for the server's replicated command. Internally consistent.
- `player_code_map.md` §7 and `object_entity_core_code_map.md`'s "**shutdown/teardown guard**" is
  **WRONG** and should be struck. The early-outs it describes (`RemoveBoundary`, `Object.Remove`,
  `Pg.UnloadLayer`) are *client* guards — a client must not authoritatively destroy or unload.
  The recurring companion test `(guid & 0xF0000000) == 0x40000000` is a **networked-object GUID
  tag**, which is why it always appears beside `IsClient`.
- `mission_contract_flow_code_map.md`'s "net host/client flags" is **CORRECT**.
- `player_validation.md`'s "per-frame cached predicate: local player's controlled-object state
  == 1" identified the right *mechanism* (`[X+0x0C] == 1`) but the wrong *subject*: the object is
  the **net session** `[this+0x24]`, not a controlled object.

This retires open item §10.3 and the corresponding open items in three sibling maps, with no
debugger.

---

### ⚑ U2 — the `EnableWeapons` / `DisableWeapons` effect

`FUN_005BE050` is the one function of the five that is genuinely interpreter-dispatched:
`jmp [0x02458448] → 0x024E6250 → push 0x24E625A; call 0x01AAFF10`. **Stated explicitly, per the
rule.** (Same for `FUN_005BF7E0 → [0x02455A2C] → 0x024BA620 → push; call 0x01AAFF10`.)

I also tested whether any sibling image restores it. It does not:
`mercs2_nodrm_v1/v2/v3.exe` are **byte-identical to the dump** at `0x005BD860`, `0x006FC560` and
`0x005BE050` — same build, same stub. And `genuine_patched_unpacked.exe` is confirmed a
**different build** (12 sections vs 13; content shifted ~0x10 at `0x005BD860`, and the shift is
not uniform across regions, so it is a recompile, not a rebase). Pass 1's trap flag (MISSING #7)
is upheld and I did not use it.

**But the effect is pinned anyway, statically, by a sole-writer argument.** Pass 1's rival claim
that `0x006FC560` is the real body is *half* right — it is not `FUN_005BE050` (wrong signature:
`FUN_005BE050(lua_State*, mode)` vs `0x006FC560(EDI = object, bool)`), it is the **engine-level
setter that `FUN_005BE050` must reach**:

```
006FC560  push ecx ; push esi
006FC562  mov  eax, edi
006FC564  mov  ecx, 0x17bf3d8           ; ★ RuntimeInventory  (REGISTER ARG — Ghidra drops it)
006FC569  call 0x5857e0                 ; component resolve
006FC56E  mov  esi, eax ; xor eax,eax ; cmp esi,eax ; je out
006FC576  and  byte [esi+0x2c], 0xf7    ; clear bit 3
006FC57A  cmp  byte [esp+0xc], al       ; arg == 0 ?
006FC57E  mov  dword [esi+0x20], 0
006FC582  je   disable
          ; ENABLE (arg != 0):
006FC586  call 0x529c00 (eax=obj, 0) ; call 0x527870 (0, obj, 1) ; ret   ; bit 3 left CLEAR
006FC59E  disable: call 0x527670 (obj, 0) ; call 0x529c00 (eax=obj, 1)
006FC5B0  or   byte [esi+0x2c], 8       ; ★ SET bit 3
```

Binary-wide census of that bit:

| Access | Sites |
|---|---|
| `and byte [r+0x2C], 0xF7` (clear) | **1** — `0x006FC576` |
| `or byte [r+0x2C], 8` (set) | **1** — `0x006FC5B0` |
| `test byte [r+0x2C], 8` (read) | **20**, of which **13** are in the `0x00527xxx`/`0x00529xxx`/`0x0052Axxx` weapon cluster |

`0x006FC560` is the **sole writer, binary-wide**, of the only bit that 20 weapon-path readers
test. It takes exactly the `(object, bool)` shape that `EnableWeapons(L,1)` / `DisableWeapons(L,0)`
imply, and one of its readers (`0x00529DDC`) sits inside the `FUN_00529D50` cluster that
`SetFireLock` calls — precisely the "expect a flag adjacent to `SetFireLock`'s" prediction in the
map's §10.1.

> **Effect: CONFIRMED.** `Human.DisableWeapons(guid)` **sets bit 3 of `RuntimeInventory+0x2C`**
> (and zeroes `+0x20`); `Human.EnableWeapons(guid)` clears it. **Bit 3 set == weapons disabled.**
> The gate lives on **`RuntimeInventory`**, not on a weapon or a human block — which is a real
> correction to the map's §6.1 framing of it as "a different axis" without a home.

**STILL-OPEN (1 of 2):** the *static edge* `FUN_005BE050 → 0x006FC560` is not demonstrated —
`0x006FC560` has exactly **one** direct `E8` caller (`0x006FE4FC`, inside a `ret 4` dispatcher
keyed on a byte `[ebp+8]`) and **zero** immediate references, so the Lua path must reach it
through the interpreter or that dispatcher. **Recipe:** one-shot bp at **`0x005BE237`** (the
`call` inside `DisableWeapons`), step **over** it, then read `RuntimeInventory+0x2C` for the
target guid; or set a HW write-watchpoint on that byte and call `Human.DisableWeapons` from
script. Either confirms in one step. This is confirmation of an already-pinned effect, not
discovery.

---

### ⚑ U4 — `PersistTransform`'s target record: `RTHuman`

Pass 1 could not pin it because **Ghidra dropped the ECX register argument** (trap #1). It is
one instruction:

```
005BDAEA  call 0x4f9290
005BDAEF  mov  eax, edi                 ; guid
005BDAF1  mov  ecx, 0x17bf9c8           ; ★ RTHuman  (REGISTER ARG)
005BDAF6  call 0x5857e0                 ; -> eax = the RTHuman record
005BDB0B  call 0x665af0                 ; esi = &transform buffer; bails if false
```

`FUN_00665AF0` fills a transform at `[esp+0x18..0x37]`: position, then a quaternion at
`+0x28`(x) `+0x2C`(y) `+0x30`(z) `+0x34`(w). The arithmetic is not a full basis — it is **one
column**:

```
s   = 2.0 / (x²+y²+z²+w²)              ; DAT_00b92874 = 2.0
[rec+0x0C] = s(xz + wy)                 ; also -> [rec+0x00]
[rec+0x10] = s(yz − wx)                 ; also -> [rec+0x04]
[rec+0x14] = s(w²+z²) − 1.0             ; also -> [rec+0x08]   ; DAT_00b9b664 = 1.0
```

That is the **third row of the rotation matrix — the facing/forward axis** — written **twice**,
to `RTHuman+0x00..0x08` and `RTHuman+0x0C..0x14`.

> **Verdict: `PersistTransform` latches the character's current FACING VECTOR into two adjacent
> float3 slots on `RTHuman` (a live copy and a persisted copy).** It is not a save/serialize
> record and does **not** belong to `save_serialize_code_map.md` as §10.5 speculated. It writes
> "six floats" only in the sense of *the same three floats, twice*. The map's "quaternion →
> basis" is an overstatement: only one basis column is computed.

Returns `true` (`{value=1, type=1}`) on success; `nil` when the argument is missing. Item CLOSED.
This also grows the `RTHuman` (elem `0x48`) layout: `+0x00..0x14` facing pair, `+0x38` knockdown
duration (f32), `+0x3C` u16 flags with bit 11 = carrying.

---

### ⚑ U5 — `Scrub`'s semantics, and the `+0x1C` field is on the wrong object in the map

Two ECX register args dropped by Ghidra, and one of them changes the meaning of the function:

```
005BE7A5  mov  ecx, 0x17bf3d8           ; ★ RuntimeInventory   (REGISTER ARG)
005BE7AA  call 0x5857e0
005BE7AF  mov  edi, eax                 ; edi = the INVENTORY record  <-- not the human object
005BE7B3  jne  ... (else return the record as a Lua value and stop)
005BE7E1  push 0xdf9110                 ; RuntimePhysicalLink
005BE7EA  call 0x6499f0                 ; open a cursor over THIS GUID's physical links
  loop:
005BE811  mov  esi, [ecx+edx*4]         ; esi = a linked child object
005BE814  cmp  esi, [edi+0x1c]          ; ★ RuntimeInventory+0x1C — the held/equipped item
005BE817  je   skip
005BE81B  mov  ecx, 0x17be5c8           ; ★ Sticky   (REGISTER ARG)
005BE820  call 0x5857e0
005BE827  je   skip                     ; skip children that are NOT Sticky
005BE845  call 0x4f30d0                 ; esi = &{u32 childGuid, 4 zero bytes}   (REGISTER ARG)
005BE85C  ... EnterCriticalSection(0x00EDBAA4); link block onto [0x00EDBAC0] at +0x18; Leave
005BE886  xor  eax, eax ; ret           ; 0 Lua values
```

> **`Human.Scrub(guid)` = "detach every **Sticky** object physically linked to this character,
> except the one it is currently holding."** The `Sticky` component filter is the entire point of
> the function and the map omits it.

Corrections to the map's §7.2:

1. **`+0x1C` is on `RuntimeInventory`, not on `humanObj`.** The map says "each entry whose id
   differs from `humanObj+0x1C`", and then §10.6 builds an inference on top of that
   ("`+0x1C` is also what `FUN_00532de0` watches for change… plausibly an owning-group/room
   id"). The object is wrong, so the inference is void. `RuntimeInventory+0x1C` is the
   currently-held item guid.
2. The record passed to `FUN_004F30D0` is **8 bytes** (`{guid, 4 zero bytes}`) via **ESI**, not
   "a 4-byte zero block".
3. `0x00DF9110` = **`RuntimePhysicalLink`** and `0x017BE5C8` = **`Sticky`** (pass-1 MISSING #6
   upheld and extended).

The script corpus corroborates exactly this reading: `mrxbriefing.lua:2686-2692` runs
`Human.Drop(uChar)` → `Human.Scrub(uChar)` → `Human.SetJostleEnabled(uChar, bOn)` — i.e. **strip
the character of carried and stuck junk before a cutscene**, which is what the name says.

`FUN_004F30D0` itself is a split thunk (`push ecx; jmp [0x2450014]` → `0x024B8130` → VM) but its
**tail is present in `.text` at `0x004F30DE` and terminates with the matching `pop ecx; ret` at
`0x004F316D`** — SecuROM stole only the leading gate check. The recovered tail appends an 8-byte
record to a **0x4000-entry table at `0x016E9778`** (count `0x016E9730`) with a parallel u16 tag
array at `0x01709778` sourced from `[0x016E9734]`, under CS `0x01711780`. It has **36 callers**
engine-wide and a **compacting sweep at `0x006C74B0`** that drops entries whose tag is 0 — so it
is a *retained registration table*, not a fire-and-forget log. What the drain ultimately does to
a scrubbed Sticky child is engine-general and outside this map.

---

### ⚑ U7 / U8 — traffic counts and arities, from the corpora

Full census over `docs/mercs2-luacd/` (370 `.lua`) and `docs/mercs2-dlc-luacd/` (75 `.lua`),
excluding the `Human.Inventory.` prefix and the raw luadec register-form tree:

| Binding | map says | base game | DLC | verdict |
|---|--:|--:|--:|---|
| `DisableWeapons` | 27 | **25** | 2 | map's 27 = base+DLC |
| `SetState` | 24 | **21** | 3 | map's 24 = base+DLC |
| `ForceExitSeatNoSnap` | 10 | **8** | 2 | " |
| `PlayRawAnimation` | 9 | **5** | 4 | " |
| `DoAction` | 8 | **6** | 2 | " |
| `PersistTransform` | 5 | **3** | 2 | " |
| `IsCarrying` | 5 | **3** | 2 | " |
| `Drop` | 5 | **3** | 2 | " |
| `Knockdown` | 4 | **4** | 0 | ✔ |
| `SetPreemptiveRagdoll` | 4 | **4** | 0 | ✔ |
| `SetFireLock` | 4 | **4** | 0 | ✔ |
| `SetAllowCorpseCleanup` | 3 | **3** | 0 | ✔ |
| `IsGrappling` / `StopGrappling` | 3 / 3 | **2 / 2** | 1 / 1 | " |
| `IsSwimming` | 2 | **2** | 0 | ✔ |
| `EnableWeapons` | 2 | **2** | 0 | ✔ |
| `Scrub` / `SetJostleEnabled` | 2 / 2 | **1 / 1** | 1 / 1 | " |
| `Emote` / `EquipWeapon` / `StowWeapon` | 0 | **0** | **0** | ✔ (exhaustive; no `Human[...]` dynamic dispatch anywhere) |

> The map's counts are **base + DLC combined** while §Sources says "the 370 decompiled scripts in
> `docs/mercs2-luacd/`". Every count is right for the union and wrong for the stated corpus.
> Cosmetic, but it is a provenance error, and the "cutscene/hijack-driver profile" conclusion is
> unaffected.

**Arity — proven from the body, not just the corpus.** `FUN_005BD450` reads in strict order:
`GUID(idx 1)` → `string→hash(idx 2)` → **`[boolean, only if param_2 == 0]`** → `boolean` →
`boolean` → `number` → `boolean` → `boolean`. The conditional is explicit:

```
005BD512  cmp  byte [ebp+0xc], 0        ; param_2 (the 0/1 mode selector)
005BD516  lea  esi, [eax+2]             ; esi = running argument cursor
005BD519  jne  0x5bd537                 ; param_2 == 1 -> SKIP the third boolean
005BD524  call 0x59f6d0                 ; the extra boolean -> bl
```

> `PlayRawAnimation` (`param_2 == 1`) = **7 args**; `Emote` (`param_2 == 0`) = **8 args**. The
> map's claim is confirmed byte-for-byte, including the variable-arity cursor. **CLOSED.**

And the extra boolean `bl` is precisely the §5 command-id selector — so `Emote`'s third argument
is a **full-body flag** (see the hash section: the two ids are `Emote` and `emotefullbody`).

Corpus notes worth carrying: `PlayRawAnimation` **returns a boolean**
(`mrxbriefing.lua:2326`), and one call site passes only 6 args (`danceradio.lua:39`), so args 6-7
are optional. `SetAllowCorpseCleanup` returns a constant `true` (`{1,1}` at `0x005BE70F`) — the
`tostring(...)` wrapper at `mrxtaskobjectiveverify.lua:227` is therefore always `"true"`.
There is a **DLC-only `Human.SetChatterSet(guid, sSet)`** with 7 call sites that is **not** among
the 21 in this build.

---

### ⚑ U9 — the Xbox claim is REFUTED

The map states (§Sources, §12): *"The devkit build exposes **no `PgSysHuman`-shaped symbol** for
the control layer, so there is no symmetric Xbox↔PC marriage to make in this map."*

The devkit build exposes a symbol **literally named `PgSysHumanStateMachine`**
(`docs/mercs2-pdb-analysis/pangea-engine-core.md:55`), and the file the map itself cites as
containing "all five physics-step symbols" also carries
**`HumanStateMachine` @ `0x823551E0`** (`docs/mercs2-pdb-analysis/physics-game.md:243`;
independently at `docs/reverse_engineer/xbox_ppc_named_functions.md:123`). That is the exact
symmetric counterpart to this map's container `0x00DF9990` — whose PC name, recovered this pass
via the `vtable+0x34` master key, is **`HumanStateMachine`**. The marriage the map says cannot be
made is a one-line join.

Also left on the table:

- **`PgHumanStateTable`** is a first-class **asset type** on Xbox
  (`pangea-engine-core.md:106,118`) — direct corroboration of `0xECE70371`.
- **`GetTranslationForStanceAndAction`** (`mercs2_xenon_p.pe_full_strings.txt:3757`) — the
  stance×action dispatch the map treats as PC-only, and exactly the two-level lookup
  `FUN_0068CC00` performs.
- **The whole Lua binding table is present on Xbox**, contiguous at
  `mercs2_xenon_p.pe_full_strings.txt:4076-4092`: `SetJostleEnabled, SetAllowCorpseCleanup,
  StowWeapon, EquipWeapon, SetFireLock, DisableWeapons, EnableWeapons, StopGrappling,
  IsGrappling, IsCarrying, IsSwimming, PersistTransform, PlayRawAnimation, Emote,
  ForceExitSeatNoSnap, SetPreemptiveRagdoll, Knockdown, DoAction` — **18 of the 21**, bounded by
  `Inventory` above. Only `Scrub` is absent.
- **ECS pool budgets** (`:1689-1694`, `:1781`, `:1801`): `HumanStateMachine 128 128`,
  `HumanAnimationControllerNEW 128 64`, `RTHuman 128 64`, `RuntimeAnimationParams 8 8`,
  `BoneCtrlJostle 8 8`.
- The stance enum `Upright / Crouch / Prone / Flying` (`:3302-3305`) and
  **`HumanStateTransition`** (`:935`).

The map's "thin by construction" is defensible only for the *animation-sampling math*
(VMX128/inlined, per `animation-skeleton.md:458`). For the **control layer** — where the claim
plants its flag — it is false. Verdict: **CONTRADICTED**; pass-1 U9 CLOSED.

---

### ⚑ A3 — the name-hash pre-images: 10 of 15 cracked

Cracked against a wordlist built from the exe string pool, the Xbox strings dump, both Lua
corpora, and **`docs/data/wad_vocab.txt` (648,202 harvested shipped-WAD strings)**. Every name
below reproduces its hash under `pandemic_hash_m2` **and** is attested as a real string in a
primary source — no invented names ([[no-arbitrary-hashes]]).

| Hash | **Name** | Role | Attested in |
|---|---|---|---|
| `0x27DE7135` | **`*`** | the **WILDCARD**, not a "NONE sentinel" | exe `.rdata`; Lua `"KnockedDown.*"`, `"Upright.*"` |
| `0x03DD7B78` | **`emotefullbody`** | the §5 raw-anim command id | `wad_vocab.txt:77580` |
| `0xE551D91A` | **`StrapOn`** | `SetJostleEnabled`'s collect selector | exe `.rdata` `0x00BCC5D8`; Xbox `StrapOn ctor`; `animation-skeleton.md` |
| `0x35365D24` | **`KnockedDown`** | Stance | `wad_vocab.txt:158310`; Lua `"KnockedDown.Idle"` |
| `0x22948D2A` | **`onladder`** | Stance | `wad_vocab.txt:202064` |
| `0x403991E8` | **`crouchcover`** | Stance | `wad_vocab.txt:48316` |
| `0x4416D310` | **`inair`** | Stance | `wad_vocab.txt:125746`; Xbox `hkpCharacterStateInAir` |
| `0x4BE8214B` | **`scuba`** | Stance | `wad_vocab.txt:259143` |
| `0xBC671C97` | **`humanshield`** | Stance | `wad_vocab.txt:112793` |
| `0xE2FC8CB1` | **`carried`** | Stance | `wad_vocab.txt:45278` |
| `0xC8886020` | `crouched` | Stance (pass-1 claim **upheld**) | `wad_vocab.txt:48317` |
| `0xE7B64876` | `carrying` | Stance (upheld) | `wad_vocab.txt` |
| `0xFC8D859D` | `prone` | Stance (upheld) | `wad_vocab.txt`; `ai.md` |
| `0x1E5B33F7` | `cower` | Stance (upheld) | exe `.rdata` `Cower`; `allcon001.lua` |
| `0x67EAAA1B` | `Subdued` | Stance **and** Action (10 rows) | `mrxtaskobjectiverelease.lua` |

> Note the Xbox enum is `Crouch`, but the PC Stance hash `0xC8886020` is **`crouched`** — checked
> both; only the longer form reproduces. Worth the check.

**`0x27DE7135 = "*"` is the single most useful crack** and it corrects a reading shared by this
map and `human_animation_selection.md`. It is not a "NONE sentinel": it is the literal wildcard
string, and the shipped ActionTable uses it as such — **1012 of 1020** `AimState` values,
**961 of 1020** `ActionDirection`, **870 of 1485** `CharacterName` in the AnimationLookup. The
Lua corpus writes it the same way, in dotted `Stance.Action` filters:

```
mrxtaskobjectiveverify.lua:45-53
  self:_CreatePersistentEvent(Event.HumanStateTransition, { self._uTgtObjFilter, "*", "KnockedDown.Idle" }, ...)
  self:_CreatePersistentEvent(Event.HumanStateTransition, { self._uTgtObjFilter, "KnockedDown.*", "Upright.*" }, ...)
```

The complete `Stance.Action` literal set in the corpora is `Swim.*` ×3, `Upright.*` ×2,
`Upright.TriggerDetonator`, `Subdued.Idle`, `subdued.idle`, `KnockedDown.Idle`, `KnockedDown.*`,
`InVehicle.*`. This is **independent script-level attestation of the map's entire `(Stance,
Action)` model**, of `Event.HumanStateTransition` (the Lua face of `FUN_0068CF20`), and of the
wildcard.

**Stance vocabulary is now 16 of 18 named** (up from 7):
`*`, `Upright` ×171, `InVehicle` ×740, `crouched` ×37, `Swim` ×12, `scuba` ×9, `onladder` ×8,
`prone` ×6, `carried` ×6, `carrying` ×3, `KnockedDown` ×3, `crouchcover` ×3, `cower` ×2,
`humanshield` ×2, `Subdued` ×1.

**STILL-OPEN (2 of 2) — 5 pre-images**, but each now carries new *context* that narrows the next
attempt:

| Hash | `.text` sites | New context recovered this pass |
|---|--:|---|
| `0x42C96259` | 6 | groups with `0xB9832CE2` at **every** site, and at `0x00584F70` the two are stacked as a **triple with `0x403991E8 = crouchcover`** — so both are **cover stances** |
| `0xB9832CE2` | 6 | as above |
| `0x2108278F` | **1** | at `0x005BE178` — **inside the `FUN_005BE050` region** (`0x005BE056`–`0x005BE21F`), pushed as an argument to the `0x01A53D80` veneer. **Pass 1 mislabeled it "StopGrappling"**; it belongs to the weapons-gate worker. `StopGrappling`'s body contains no such constant |
| `0xFAF6DA61` | 5 | `0x004B6607`, `0x0053FB80`, and three in `SetAllowCorpseCleanup` — so it is used by two subsystems beyond this binding |
| `0xE60C6CA2` | 3 | `0x00578780`, `0x005A8F99`, `0x005A8FA9` |

A further find: **`FUN_004D6AE0` is a Stance-class predicate** — a `cmp eax,<hash>; je true` chain
over `{prone, [0x24605B8], KnockedDown, Subdued, crouchcover, 0xB9832CE2, 0x42C96259}` returning
bool. It is reached only via `jmp 0x4d6ae0` at `0x004D6ABE` (no direct callers). The slot
`[0x24605B8]` is **NULL on disk** (runtime-resolved), which is the one class of value the dump
genuinely cannot supply — consistent with `docs/securom_unwrap_devirtualization.md`.

**Static evidence is exhausted.** None of the five matches any of ~1.3M whole strings from the exe
(including UTF-16), the Xbox strings dump, both Lua corpora, `docs/data/`, `docs/mercs2-ecs/` or
`docs/mercs2-pdb-analysis/`; nor any of the 648,202 `wad_vocab.txt` lines tested verbatim; nor a
curated ~30,000-candidate affix sweep (a 100-prefix × 130-suffix × 12-tail cover/stance/disposal
vocabulary, plus `no`/`non`/`not`/`un`/`dis`/`dont`/`allow`/`keep` forms); nor `Stance.Action`
dotted pairs over the now-known vocabulary.

*An unbounded compound sweep was deliberately abandoned.* The full piece-vocabulary is 717,651
tokens; a V² product is ~5×10¹¹ candidates against a 32-bit space, which **guarantees** false
positives and would produce a confidently-wrong name — the exact failure
[[no-arbitrary-hashes]] exists to prevent. Every name reported above came from a *single* attested
token, and each was traced back to its source file before being written down.

**Recipe:** these need a *new corpus*, not a debugger — harvest the string tables of the DLC WADs
and of the `HumanStateTable` assets, or the Xbox `.xex` `.rdata`, and re-run the same cracker. A
live alternative exists for the two Labels only: bp `0x005BE6D6` and read the `Label` container's
name table.

**A4 — the FNV basis is recovered.** Pass 1 listed *"the FNV basis constant, which lives in a
SecuROM-relocated slot (`[0x0245D6D8]`)"* as unestablished. In the dump the slot is resolved:
**`[0x0245D6D8] = 0x811C9DC5`** — the standard FNV-1a offset basis, exactly what
`tools/pandemic_hash.py` uses. Independent validation of every hash in this and every sibling map.

---

### Re-derivation of the 12 CONTRADICTED items

Pass 1 was not assumed correct. Both sides re-derived from the bytes.

| # | Pass-1 verdict | Pass-2 | Evidence |
|--:|---|---|---|
| 1 | native blocks are named via `vtable+0x34` | **UPHELD** | `0x00DF9990`→vt `0x00BC3BC8`→`+0x34`→`0x00647620`→**`HumanStateMachine`**; `0x00DF9A10`→**`HumanAnimationControllerNEW`**; `0x00DF9B90`→**`Players`**. Applied exhaustively to every bare container in the map — see the naming table below |
| 2 | `0x00DF9A10` is not "the ragdoll-arm block" | **UPHELD** | its name is `HumanAnimationControllerNEW`; the real ragdoll containers are `0x017BF928` **`PhysicsActorRagdoll`** and `0x017C0508` **`RagdollController`**, both named the same way |
| 3 | `Human.Inventory` is a marker-delimited **sub-table**, not a separate `luaL_Reg` | **UPHELD, exactly** | walked the array: `0x00B99F98 = {"Inventory", 0xFFFFFFFF}` OPEN · rows `0x00B99FA0`–`0x00B99FE0` = the 9 · `0x00B99FE8 = {"Inventory", 0xFFFFFFFE}` CLOSE · `{NULL,NULL}` at `0x00B99FF0` · `_GuiInternal` `CreateWidget` at `0x00B99FF8`. `0x00B99FA0` is row 22 |
| 4 | "six containers" is an undercount | **UPHELD in direction, AMENDED in number** | pass 1 said "at least twelve" for `FUN_00667CB0` + the block after it. Measured over `0x00667CB0`–`0x0066842E`, the container-shaped immediates that resolve to a named container are **8**: `PhysicsActor, RTHuman, HumanStateMachine, HumanAnimationControllerNEW, SceneObject, Carryable, EntranceParameters, MaterialControllerRuntime`. `BoneControllerRuntime`, `HumanAnimationSystem`, `HumanAnimationSet`, `ControlBinding` appear elsewhere in the `0x00666xxx`–`0x0066Bxxx` module but **not** in those two functions. So: map says 6 → **8 in create+teardown**, ≥13 counting the components the 21 bindings themselves touch (`RuntimeAnimationParams`, `RuntimeInventory`, `Label`, `RuntimePhysicalLink`, `Sticky`) |
| 5 | `FUN_00824270` **is** `pandemic_hash_m2`, not a "resolver"; nothing is "interned" | **UPHELD** | read the body: `movsx ecx,cl; or ecx,0x20; xor eax,ecx; imul eax,0x1000193` loop, then `xor eax,0x2a; imul eax,0x1000193; ret`; returns 0 for NULL/empty. Pure computation, no table |
| 6 | teardown `FUN_006681C0` is **622 B**, not 304, and also *adds* a component | **UPHELD** | body runs `0x006681C0`→`ret` at `0x0066842D`, `int3` pad at `0x0066842E` = **622 B**; `0x0066841F push 0xdf9a90; call 0x649180` **adds `MaterialControllerRuntime`** |
| 7 | `FUN_00667CB0` has **one** caller; only `FUN_0066A2C0` has none | **UPHELD** | full `.text` E8/E9 scan: `0x00667CB0` ← 1 call at **`0x006686D6`**; `0x0066A2C0` ← 0 calls, 0 immediate refs |
| 8 | **all 21** cfunc bodies are clean `.text`, not 19 | **UPHELD** | read all 21; the map contradicts itself between its intro and §12 |
| 9 | "three" tail thunks but four listed | **UPHELD** | `Emote`, `PlayRawAnimation`, `EnableWeapons`, `DisableWeapons` — four, each 16 B |
| 10 | `Swim` "sole use is `Human.IsSwimming`" is wrong | **UPHELD** | `0x614DB965` at **10** `.text` sites (`0x004AD620, 0x0052A050, 0x005344EE, 0x00555A61, 0x0058B776, 0x005BDCB1, 0x005FCC0A, 0x005FCCF2, 0x00689BE7, 0x0069C257`) + 12 ActionTable rows + 3 Lua `"Swim.*"` filters |
| 11 | `Knockdown 0x9C9F3F13` is **not** in the shipped ActionTable | **UPHELD as fact — but pass 1's inference is now OVERTURNED** | see below |
| 12 | `0x00EDBAA4` is an `RTL_CRITICAL_SECTION` + free list, not a "scratch pool" | **UPHELD** | `Scrub` `0x005BE85C/0x005BE87E` pushes it to `[0x00B05128]`/`[0x00B0512C]` = `KERNEL32!Enter/LeaveCriticalSection`; list head `0x00EDBAC0`, link at `object+0x18` |

**C11 — the one place pass 1's *conclusion* was wrong.** Pass 1 wrote: *"It is a real name-hash
and a real argument to the state setter, but it is **not an ActionTable Action value** in shipped
data… That is a real, checkable asymmetry."* The fact is right and the framing is wrong. The
recovered `FUN_0068CC00` body shows the `(Stance, Action)` pair is looked up in the
**HumanStateTable** at `human+0x0C`, **not** in the ActionTable. There is no asymmetry to explain:
`Knockdown` is a *HumanStateTable* Action, and the ActionTable is a downstream clip-selection
table keyed on the resulting state. The corroborating tell is that the shipped ActionTable *does*
carry `0x35365D24 = **KnockedDown**` in its **Stance** column (3 rows) — the *stance you end up
in* — while `Knockdown` is the *action that puts you there*. Two different words, two different
tables, and the map's §2.1 conflates them by listing `Knockdown` as "a new value for the
ActionTable's open vocabulary". **It is not an ActionTable value at all.**

*(Pass-1 bonus item on registrar page shifts is also upheld: `0x00DF9990` shift 7, `0x00DF9A10` 6,
`0x00DF9B90` 3, `RTHuman` 6, `RuntimeAnimationParams` 3, `PhysicsActor` / `BoneControllerRuntime`
8 — the map's blanket "page shift 8" holds for two of four.)*

---

### The master key, applied exhaustively

Every bare container address in the map, named statically from `[vtable+0x34]`
(`mov eax,<char*>; ret`). The four the map already named were **verified, not trusted**:

| Container | vtable | name stub | **Name** | Map's claim |
|---|---|---|---|---|
| `0x00DF9990` | `0x00BC3BC8` | `0x00647620` | **`HumanStateMachine`** | "no reflected type name" ✗ |
| `0x00DF9A10` | `0x00BC3C38` | `0x00647630` | **`HumanAnimationControllerNEW`** | "ragdoll-arm block" ✗ |
| `0x00DF9B90` | `0x00BC3FB8` | `0x00647BA0` | **`Players`** | unnamed |
| `0x00DF9110` | `0x00BC1F90` | `0x00644680` | **`RuntimePhysicalLink`** | bare address |
| `0x00DF8108` | `0x00BBFB58` | `0x00641610` | **`Label`** | "label/marker container" ✔ |
| `0x00DF9A90` | `0x00BC3D98` | `0x00647880` | **`MaterialControllerRuntime`** | absent |
| `0x017BF9C8` | `0x00BC32E0` | `0x00646600` | **`RTHuman`** | ✔ verified |
| `0x017BF428` | `0x00BC2BD8` | `0x00645890` | **`RuntimeAnimationParams`** | ✔ verified |
| `0x017BF888` | `0x00BC31A0` | `0x00648C80` | **`PhysicsActor`** | ✔ verified |
| `0x017C00F8` | `0x00BC3D48` | `0x00647870` | **`BoneControllerRuntime`** | ✔ verified |
| `0x017BF3D8` | `0x00BC2B88` | `0x006457D0` | **`RuntimeInventory`** | absent (the weapons gate + `Scrub` + `EquipWeapon` live here) |
| `0x017BE5C8` | `0x00BC13B0` | `0x006438A0` | **`Sticky`** | absent (the whole point of `Scrub`) |
| `0x017BF928` | `0x00BC3240` | `0x00646530` | **`PhysicsActorRagdoll`** | absent |
| `0x017C0508` | `0x00BC4468` | `0x006481E0` | **`RagdollController`** | absent |
| `0x017BE848` | `0x00BC1A68` | `0x00643DF0` | **`GrappleParameters`** | ✔ named in §9 |

All four map-supplied names are **correct**. The method also names the 97 distinct containers
referenced across the whole `0x00666xxx`–`0x0066Bxxx` module, so no address in this map or its
siblings need remain bare. Map §10.8 ("dump their vtables live") is **retired**.

---

### OVERSTATED (4) — all upheld

1. **"19 of 21 have their effect pinned."** After this pass the honest number is **20 of 21**:
   `PersistTransform` (U4) and `Scrub` (U5) are now pinned, `EnableWeapons`/`DisableWeapons` are
   pinned as a pair, and only `StopGrappling` remains genuinely open — `FUN_005BF7E0` is
   interpreter-dispatched and its payload's consumer is unknown. *Payload correction:* the map
   says `StopGrappling` "builds `{guid, guid, 0, 1, 0}`". It builds a **4-field, 13-byte** record
   — `[esp+0x0C] = guid`, `[esp+0x10] = 0`, `[esp+0x14] = 1`, `[esp+0x18] = 0` (byte) — and
   passes it in **ECX** (`lea ecx,[esp+0x0c]` at `0x005BE027`), another dropped register arg.
   There is no second `guid`.
2. **"The three action verbs share one shape" incl. the two gates.** **UPHELD.**
   `DAT_00DFBD77` occurs at exactly one site in the whole `0x005BD200`–`0x005BD800` span
   (`0x005BD3D6`) and `DAT_00DFBD78` at exactly one (`0x005BD3F7`) — **both inside `DoAction`'s
   own body**. The shared worker `FUN_005BD450` (`0x005BD450`–`0x005BD73F`) reads neither. So
   `Emote` and `PlayRawAnimation` are **not** client-gated and **not** replicated, while
   `DoAction` is both. Given `DAT_00DFBD77` is now known to be `IsClient`, this is a real
   behavioural difference a reimpl must preserve, not a diagram simplification.
3. **One `H` covering two claims on the `Swim` row.** UPHELD (see C10).
4. **§10.8 filed as live-only work.** UPHELD — it is a two-instruction static read.

### MISSING (8) — all upheld

All eight pass-1 omissions re-derived and confirmed; #1 (`humanObj+0x08` = Action) is now proven
from the **write** side too, #2 (the `vtable+0x34` convention) is applied exhaustively above, #3
(the ActionTable vocabulary) is extended from 8 to **16 of 18** names, and #6
(`0x00DF9110` = `RuntimePhysicalLink`) is confirmed and joined to the `Sticky` filter that makes
`Scrub` intelligible. #8 verified in the array walk: `EquipWeapon` at rows `0x00B99F70` and
`0x00B99FD0` share name pointer `0x00BB6730` with cfuncs `0x005BE340` / `0x005BF4E0`.

---

### Net assessment of pass 2

Pass 1's diagnosis — *"it stopped one read short in several places, then filed the remainder as
live-debugging work"* — is correct, and **pass 1 did the same thing itself**, in one specific way:
it accepted the SecuROM boundary. Every one of its ten "unverifiable" items except the
out-of-scope cross-reference rule turned out to be statically decidable, and six of them fell to a
single technique the project already had documented ([[securom-decompiled-not-a-blocker]]):
**deref the indirect slot in the dump and disassemble**.

The two recurring mechanical causes across both passes are worth restating: **Ghidra drops
`mov ecx/esi/edi, imm32` register arguments** (it cost the map `PersistTransform`'s container,
`Scrub`'s container *and* its `Sticky` filter, and `0x006FC560`'s container — four separate
findings), and **a 32-bit hash needs a corpus, not a guess** (`docs/data/wad_vocab.txt` alone
supplied 9 of the 10 cracks).

Residual open surface: **five name-hash pre-images** with static evidence demonstrably exhausted,
and **one static edge** (`FUN_005BE050 → 0x006FC560`) whose *effect* is already pinned by a
sole-writer argument. Everything else in the register is closed.

---

### Addendum — `human+0x0C` is the `HumanStateTable` handle, proven from the write side

The §U1 reading of `FUN_0068CC00` (`table = human+0x0C`, level-1 map at `table+0x18`) was derived
from the setter's body. `FUN_00667CB0` confirms it from the opposite direction — it is the
function that *installs* the handle, and it does so with the two acquires the map already
documents:

```
00667D12  mov  eax, [edi+4]                      ; per-character asset NAME hash
00667D26  mov  dword [esp+0x30], 0xece70371      ; asset TYPE = HumanStateTable
00667D39  call 0x874150                          ; typed acquire -> eax
00667D43  mov  [esp+0x28], eax                   ; stash the handle
00667D58  mov  [esp+0x3c], esi                   ; [edi+0] = the other name hash
00667D5C  mov  dword [esp+0x40], 0x207359c7      ; asset TYPE = AnimationTable
00667D6F  call 0x874150
...
00667DA8  mov  ecx, 0xdf9990 ; call 0x6496b0     ; find/create the HumanStateMachine record
00667DE6  mov  eax, [eax]                        ; eax = the human state object
00667DE8  mov  edx, [esp+0x24]                   ; the acquired HumanStateTable handle
00667DF2  add  eax, 0xc
00667DF7  mov  [eax], edx                        ; ★★ human+0x0C = HumanStateTable
00667DF9  je   0x667e0d                          ; (handle == 0?)
00667DFB  mov  eax, [edi+8]                      ; current Action
00667DFE  mov  ecx, [edi+4]                      ; current Stance
00667E01  push eax ; push ecx
00667E03  call 0x68cc00                          ; ★ re-run the setter with the SAME pair
00667E0D  else: mov [edi+0x18], 0 ; mov [edi+0x1c], 0
```

Three things fall out, all first-hand:

1. **`human+0x0C` is the `HumanStateTable` handle.** Confirmed by the store, not inferred.
2. **`+0x18` / `+0x1C` are a cache, and the engine knows it.** On table assignment it immediately
   re-invokes `FUN_0068CC00(human, human+4, human+8)` — the *same* stance and action — purely to
   re-resolve the two entry pointers against the new table; and when there is no table it nulls
   them explicitly. A reimpl must treat `+0x18`/`+0x1C` as derived state invalidated by a table
   swap, never as independent fields.
3. **A fresh human's default state is `(Upright, Idle)`.** On the no-existing-record path,
   `0x00667E18` loads `edi = 0xB4DA003B` (**`Idle`**) and `[esp+0x14] = 0x12C07B18`
   (**`Upright`**) — both names verified by `pandemic_hash_m2` this pass.

This closes the last inferential step in the `FUN_0068CC00` recovery: the two-level
`Stance → Action` lookup, the table it walks, the cache it fills, and the default pair a character
starts in are all now read from the bytes.

*(Incidental container names recovered while tracing this path, by the same `vtable+0x34` key:
`0x017BE758` = `Carryable`, `0x017BD858` = `EntranceParameters`. The `0x00DF84xx` block walked at
`0x00667E3B` is **not** a standard reflected container — its `[base]` vtable slot is 0 — so it is
left unnamed rather than guessed.)*

---

### Addendum 2 — the `HumanStateTable` is dumped. Map §10.2 is CLOSED.

Map §10.2 nominates the `HumanStateTable`-vs-ActionTable relationship as *"the highest-value open
item"* and files it as live work: *"dump the streamed asset once the human spawns."* No debugger
is needed — the asset ships in `vz.wad` and was dumped from disk this pass.

**Location.** Exactly **one** `HumanStateTable` exists archive-wide: name hash **and** type hash
both `0xECE70371` (the asset's name *is* `"HumanStateTable"`), **561,024 B**, resident block
**3185** — the same block that carries the ActionTable. ASET `type_id 33 == 0xECE70371`. Zero
copies in `shell.wad` / `English.wad` / `English-patch.wad` / `Loading.wad`. Contrast
`0x207359C7` (AnimationTable), which has 22 entries over 15 name hashes. So "a human's state
vocabulary is streamed **per-character** at spawn" (map §1.1) is a misreading of `FUN_00667CB0`:
the *name* half of the acquire varies per prototype, but for this type every character resolves
the same single resident asset.

**Schema — it is not a dim table.** No `TYPE`/`VALU` chunks, so the ActionTable decoder does not
apply. It is a flat ordered chunk stream of 9,156 chunks, and — critically — **it ships the state
names as ASCII**, which is why it cracks the vocabulary the hash sweep could not:

```
INFO (4B)  [u16 0x0005][u16 17]                    ; 17 stances
SINF (var) [name\0][u16 actionCount]               ; x17    stance record
AINF (var) [name\0][u16 trnsCount][6 x ASCII\0]    ; x394   action record + 6 flags
TRNS (var) [7 x ASCII\0]                           ; x8744  transition
```

Nesting is implicit by chunk order; declared counts match actual counts for all 17 stances and all
394 actions. **17 stances / 394 states / 8,744 transitions.** `TRNS` = `{event, targetStance,
targetAction}` with four unused trailing fields. `AINF` flag 6 is the ragdoll mode — `FULL` on
`Die`/`Dead`/`KnockDown`/`MeleeKnockedDown`/`MeleeFall*`, `ON_END` on both `DieAnimatedRagdoll`
entries, `NONE` otherwise.

> **This is exactly the structure `FUN_0068CC00` walks.** `human+0x18` = the resolved **SINF**
> (stance) record; `human+0x1C` = the resolved **AINF** (action) record. The setter's two-level
> `Find` and the container's two-level chunk nesting are the same shape, derived independently
> from opposite ends. The §U1 structural reading is confirmed against shipped data.

**The last two Stance hashes are cracked — and they are exactly what §A3 predicted.** Pass 2's
static work showed `0xB9832CE2` and `0x42C96259` always travel together and are stacked with
`0x403991E8 = CrouchCover` at `0x00584F70`, concluding "both are cover stances". The container
names them:

| Hash | **Name** | Verified |
|---|---|---|
| `0xB9832CE2` | **`UprightCoverLeft`** | `tools/pandemic_hash.py --m2` re-run here ✔ |
| `0x42C96259` | **`UprightCoverRight`** | ✔ |

> **The ActionTable Stance column is now 18/18 named** — the 17 HumanStateTable stances plus the
> `*` wildcard. The map's §10.7 open-vocabulary item and `human_animation_selection.md`'s
> "⏳ Name the remaining ActionTable state-value hashes" are both retired for the Stance column.
> The Action column goes from ~2 named to **296 of 303**, from this container's string pool alone.

Full stance census (`hash · name · actions/transitions`): `0x12C07B18 Upright` 111/3737 ·
`0x5E2CD838 InVehicle` 174/3169 · `0xC8886020 Crouched` 29/861 · `0x614DB965 Swim` 12/208 ·
`0x4BE8214B Scuba` 12/210 · `0x22948D2A OnLadder` 8/83 · `0x4416D310 InAir` 7/138 ·
`0xFC8D859D Prone` 6/86 · `0xE2FC8CB1 Carried` 6/46 · `0x35365D24 KnockedDown` 5/38 ·
`0xB9832CE2 UprightCoverLeft` 4/29 · `0x42C96259 UprightCoverRight` 4/29 ·
`0x403991E8 CrouchCover` 4/29 · `0x1E5B33F7 Cower` 4/22 · `0xE7B64876 Carrying` 3/16 ·
`0x67EAAA1B Subdued` 3/15 · `0xBC671C97 HumanShield` 2/28.

(The engine's own casing differs from the `wad_vocab.txt` forms used in §A3 — `OnLadder` not
`onladder`, `Scuba` not `scuba`, and so on. The hash is case-suppressing so both reproduce; the
container's spelling is canonical and should be preferred.)

**C11 is now fully resolved — from the data side as well as the code side.**
`0x9C9F3F13` is present here as an **AINF action name under stance `Upright`**
(`ACTION KnockDown, trns=25, flags=[FALSE,FALSE,FALSE,TRUE,TRUE,FULL]`), plus 136 uses as a TRNS
*event* and 320 as a TRNS *target action*. (`KnockDown` and `Knockdown` both hash to
`0x9C9F3F13`; the container uses both spellings.) So pass 1's fact — absent from the ActionTable —
is right, and pass 2's §U1 explanation is right: **it is a HumanStateTable state, and the
ActionTable simply has no exact row for it.** It is not alone: **17 of the 394 declared states
have no ActionTable row**, including `Upright/Knockdown`, `Upright/MeleeASubdue`,
`Upright/GrappleStandup`, `Cower/Die`, `Cower/Dead`, `KnockedDown/Die`, `Subdued/Dead` and five
`Scuba` grenade actions. Those states are legal to *enter*; their clip is then selected by a
**wildcard** ActionTable row rather than an exact one. There is no anomaly to explain.

**And the wildcard is confirmed ActionTable-only.** The literal `*` does **not** occur anywhere in
the HumanStateTable's 371-string pool. `0x27DE7135 = "*"` is a *key-matching* device belonging to
the decoration table, not a state value — which is why the state graph has no need of it.

**The relationship, measured.** The two are halves of one system joined on `(Stance, Action)` over
a shared name-hash vocabulary:

- **`HumanStateTable` = the authoritative state graph.** It declares which 394 `(stance, action)`
  states exist, their per-state behaviour flags, and the 8,744 event-driven edges between them.
  It is what `FUN_0068CC00` walks, and the only asset in the archive that ships the state names
  as text.
- **`ActionTable` = a decoration table on top of it.** 1,020 rows whose 6-column key *extends* the
  same pair with `AimState/Tandem/Seat/Target/ActionDirection/DamageDirection`, attaching
  `AnimationHandles` and the partition/looping/driven masks, with `*` as don't-care.
- **Join:** of the ActionTable's 387 distinct `(Stance, Action)` pairs, **377 are declared
  states**, 2 are wildcard, and 8 are not declared (7 of those are uncracked Action hashes; the
  one genuine mismatch is `Crouched/Grapple`, which the state graph declares under `InAir`).
  Conversely 377 of 394 states have an exact row and 17 do not, as above.

So the map's §2.1 guess — *"most likely the former declares the legal Stance/Action vocabulary and
transitions and the latter maps a key to clip handles, but that is inference, not a read"* — is
**exactly right, and is now a read**. The warning box "Do not confuse the two state tables" stands
and is strengthened.

**STILL-OPEN reduces from 5 name-hashes to 3.** `0x2108278F` (in the `FUN_005BE050` region),
`0xFAF6DA61` and `0xE60C6CA2` (the two `Label` hashes). The 7 residual *ActionTable Action* hashes
(`0xA3C54951`, `0xDA882AB8`, `0xF2F71296`, `0xF37538A1`, `0x1930E5FF`, `0xA7E56A1B`,
`0xBBA5334E`) belong to `animation_code_map.md` / `human_animation_selection.md`, not to this map;
they survived a brute force over all 826,229 ASCII runs in resident block 3185 and 3.16M corpus
tokens, so they are recorded, not guessed.

*Tooling note: this dump required a new probe,
`tools/wad_simulator/crates/mercs2_probe/src/bin/humanstate_probe.rs` (added, not committed; no
existing file modified — `tools/wad_simulator` is a NESTED repo, [[nested-repo-wad-simulator]]).
The two new stance names were re-verified with `tools/pandemic_hash.py --m2` rather than taken on
trust.*

### Revised score

| Pass-1 bucket | Items | Closed | Still open |
|---|--:|--:|--:|
| UNVERIFIABLE (static) | 10 | **9** | 1 (out-of-scope by rule) |
| A13 "could not check" | 5 | **4** | 1 (3 hash pre-images) |
| CONTRADICTED / OVERSTATED / MISSING | 24 | **24 re-derived** | 0 |
| **Total** | **39** | **37** | **2** |

Residual: **3 name-hash pre-images** (down from pass 1's 5 + 10 unnamed stances) and **1 static
edge** (`FUN_005BE050 → 0x006FC560`) whose effect is already pinned by a sole-writer argument.
Map open items §10.1 (effect), §10.2, §10.3, §10.4, §10.5, §10.6 and §10.8 are all closed; §10.7
is reduced to three hashes.
