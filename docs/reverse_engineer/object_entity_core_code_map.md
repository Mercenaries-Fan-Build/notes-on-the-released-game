# Object / entity core — PC code map

**Scope:** the **generic entity surface** as retail PC `Mercenaries2.exe` exposes it to script — the
complete **`Object` Lua binding table** (`luaL_Reg` VA `0x00B99608`, **87 cfuncs, 0 stubs** — the
**3rd-most-used namespace in the game**, 1272 script call sites) and, behind it, the **two
GUID-keyed component-container arrays** those cfuncs read and write. This map answers the question
the sibling maps kept deferring: *when Lua says `Object.GetPosition(uGuid)`, what data structure does
the engine touch?*

**This map owns the generic entity plumbing. It does not own any subsystem.** Health *policy*,
destruction, physics bodies, streaming residency and the player object each belong to a sibling map;
this map only pins where the `Object.*` cfunc lands and hands off.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`world_streaming_code_map.md`](world_streaming_code_map.md) | the hibernation set (`IsHibernated 0x5CF240`, `GetHibernationDistance 0x5CF420`, `SetHibernationDistance 0x5CF4F0`, `RevertHibernationDistance 0x5CF600`), residency, the streaming node state machine |
| [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) | what a *death* does — `SetStateOnMsg`, `SetState` `FUN_004D3E10`, the node-state vocabulary, `OnStateChange` |
| [`weapons_combat_code_map.md`](weapons_combat_code_map.md) | damage application, ammo, the weapon side of `SetInfiniteAmmo` |
| [`physics_code_map.md`](physics_code_map.md) | the Havok body itself, `hkpCharacterProxy`, ragdoll — this map only pins the *handle* lookup `FUN_00432740` |
| [`player_code_map.md`](player_code_map.md) | the player object, the ≤2 roster, the profile singleton; the `Players` container's **contents** |
| [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md) | the reflection/type registry internals, `CopyFromStream` descriptors, the component-instance resolver `FUN_005857E0` |
| [`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md) | the entity-as-bag-of-components reframe, spawn/template instantiation, the render-node split |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | how `luaL_Reg` tables are installed and dispatched |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) **plus raw disassembly of the same image**
`output/_ghidra/securom_dump/mercs2_unpacked.exe` with `capstone` + `pefile`, VA→file offset via the
PE section table. That second tool is why this revision exists: Ghidra drops register arguments, and
the container that every `FUN_005857E0` call site resolves against arrives in `ECX` as a plain
`mov ecx, imm32` two instructions above the call. Binding name→VA is the live Surface-B `.rdata` walk
`mods/lua_trace_asi/reference/binding_map.json` ([[lua-trace-asi-surface-b-oracle]]), corroborated by
[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)'s
independent offline re-walk (same VA, 87 entries, 0 stubs) and re-walked a third time this pass
directly from `.rdata`. Script traffic is a regex census over the Lua corpora — exact recipe in §9.

**Reproduction harness.** Every raw-byte citation below re-derives with:

```
.text  VA 0x00401000 → raw 0x1000      .rdata VA 0x00B05000 → raw 0x705000
.data  VA 0x00BF6000 → raw 0x7F6000    Stext  VA 0x01A49000 → raw 0x1649000
```
(`RVA == raw` does **not** hold for this image; both container arrays lie inside `.data`.)

**Method / honesty model.** Same discipline as [`player_code_map.md`](player_code_map.md).
Confidence: **H** = read a body with a can't-coincide fingerprint (a global address, a constant, a
table walk) · **M** = one strong structural signal · **L/open** = positional, needs a live confirm.
Every offset states the function it was read from, and — new in this revision — the decisive
instruction bytes, so a reader can re-derive it without trusting this document.

> **The honesty caveat that used to head this map is now closed.** It read: *"roughly a third of the
> recovered cfuncs resolve their component through `FUN_005857E0` … which component pool is being
> resolved is not present in the decompiled text … one breakpoint settles ~20 rows at once."* The
> diagnosis was right, the remedy was wrong. **No breakpoint is required.** The pool is
> `mov ecx, imm32` in the raw bytes; e.g. `Object.GetHealth`:
> ``0x005CBE1F: B9 78 EF 7B 01  mov ecx, 0x17bef78`` → `0x017BEF78` = `RuntimeHealth`.
> **55 of the 87 cfuncs** carry a direct container reference and all of them are now named (§3.1).

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). The whole `Object` cfunc
> cluster `0x005CBC50–0x005D29F0` is clean `.text`. Where a body tails into `thunk_FUN_024E****`
> (`Remove`, `SetHibernationDistance`, `StopMaterialAnimation`, …) that is the split-thunk seam, and
> the real `.text` body is reachable by following it.

**Recovery: 87 of 87 cfuncs are readable. Ghidra decompiled 63; the other 24 are Ghidra-blind, not
missing.**
Reproduce: walk the 87 function pointers from `0x00B99608` and disassemble each, bounded by
`ret`/`jmp` + `int3` padding or the next binding VA — all 87 terminate cleanly. Then grep the Ghidra
export for a *definition* line `^\s*\w[\w *]*FUN_<va>\s*\(` — 63 hit, 24 miss, and the missing 24 are
exactly `DetachCargoFromWinch, DisablePhysics, EnablePhysics, GetCashValue, GetHealth, GetMass,
GetMaxHealth, GetModelName, GetName, GetPhysicsType, HasLabel, HasWinch, InSeat, InVehicle, IsAlive,
IsDisguised, IsHibernated, IsTemplate, IsValid, IsWinching, RemoveQualityRef,
RevertHibernationDistance, Revive, StopAllAnimation`.

> ⚠ **Superseded claim, kept visible.** An earlier revision of this map said *"Recovery score: 63 of
> 87 (72 %); 24 are binding-only"* and made recovering them **§8.8, a forcing-script pass**, calling
> it "the highest-value forcing-script target in the project right now". That was too pessimistic:
> "binding-only" is a statement about Ghidra's *auto-analysis* (a binding-table-only function has no
> static caller to walk from), not about the binary. Sizes of the 24 range from **16 B**
> (`EnablePhysics`/`DisablePhysics`) to **1128 B** (`GetPhysicsType`, 407 instructions). §8.8 is
> **closed**; the forcing pass is unnecessary. It also wrongly demoted two *previously recovered*
> functions — see §5.5 and `world_streaming_code_map.md` §11.

---

## 0. Result in one line

**`Object.*` does not talk to an entity object at all.** There is no per-entity struct that
`Object.GetPosition` dereferences. The engine keeps **334 GUID-keyed component containers**, one per
runtime component type, split across **two arrays with different layouts**:

| | the **`0x80`** array | the **`0x50`** array |
|---|---|---|
| span | `0x00DF6B88 … 0x00DF9E10` | `0x017BBF58 … 0x017C0788` |
| count | **102** | **232** |
| stride | `0x80`, with exactly one `0x88` step at `0x00DF8408` (`RiderLink`) | uniform `0x50` |
| type ids | `0x001 … 0x14C` | `0x005 … 0x14E` |
| descriptor | mask/cap `+0x20` · stride `+0x24` · shift `+0x26` · keys `+0x44`/`+0x60` · slots `+0x48`/`+0x64` · pages `+0x70` · zero record `+0x7C` | hash sub-object at `+0x18`: stride `+0x24` · shift `+0x26` · cap `+0x28` · slots `+0x34` · pages `+0x38` |
| resolver | inline, or `FUN_00423DC0` / `FUN_00649C60`, probe `FUN_00648D80` | **`FUN_005857E0`** (fast) / `FUN_00649C00` (slow), probe `FUN_0064A090` |

Each container is a paged open-addressed table resolved by one idiom (`guid → hash probe → packed key
→ record = (mask & key)*stride + pageTable[key >> shift]`), and an `Object.*` cfunc is a **thin
Lua-arg shim that picks one container and touches one record**. Adding/setting is one shared
function, **`FUN_00649180(container, ownerGuid, key2, subKey, &value)`**; iterating is
**`FUN_006499F0`/`FUN_00649A80`** over a pooled cursor. That is the whole entity-component picture
from the script side: **table-per-component-type, keyed by GUID — not a component list hanging off an
entity pointer.**

**All 334 containers name themselves**, and the names are the engine's own (§1.1, full census in
§10). Position lands in **`RuntimeSceneObject` `0x00DF9C90`**, names in **`Name` `0x00DF6B88`**,
labels in **`Label` `0x00DF8108`** (multi-valued, keyed `(guid, labelHash)`), attachments in
**`RuntimePhysicalLink` `0x00DF9110`**, gates in **`RtPoweredGate` `0x00DF9890`**, health in
**`RuntimeHealth` `0x017BEF78`**.

Three consequences worth stating up front: (1) `Object.Kill` **posts a message** into a bounded
0x400-entry queue (`FUN_0042BE60`), it does not kill anything synchronously, and on overflow it
**drops the newest**; (2) `Object.AddToDisposer` is not its own mechanism — it adds the **reserved
label `0xF956736B = pandemic_hash_m2("disposable")`** to the `Label` container (but it is *not* the
same call as `AddLabel`, §4.3); (3) `Object.AreEqual` and `Object.IsValid` touch no engine state at
all — both are pure Lua tag work.

> ⚠ **Two superseded claims from earlier revisions, kept visible.**
> 1. *"a flat array of 102 GUID-keyed component containers … the container array that **every one**
>    of those cfuncs reads and writes."* The 102-container measurement was right to the byte, but it
>    is **one of two arrays**, and it is *not* the one the health functions use. 30 `Object` cfuncs
>    resolve against the `0x50` array, including all four health cfuncs.
> 2. *"the Transform container `0x00DF9C90`"* and *"a shared per-entity flag container `0x00DF9B10`
>    whose element layout is undecoded"*. `0x00DF9C90` is **`RuntimeSceneObject`**; **no container
>    named `Transform` exists in either array.** `0x00DF9B10` is **`CheatInfiniteAmmo`**, element
>    stride **1 byte**, capacity 128.

---

## 0.5 Master marriage table

| Role | PC addr | Married by | Conf |
|---|---|---|---|
| **`Object` `luaL_Reg` table** | **`0x00B99608`**, 87 entries, `{NULL,NULL}` terminator at `0x00B998C0` | live `.rdata` walk + two independent offline re-walks agree entry-for-entry; `object.rs` `REQUIRED` matches 87/87 by name | H |
| **`Object` cfunc cluster** | **`0x005CBC50`–`0x005D29F0`** (contiguous) | every one of the 87 table slots lands inside the range | H |
| **Container array — `0x80` class** | **`0x00DF6B88` … `0x00DF9E10`, 102 containers** | header sweep (below); `101×0x80 + 8 = 0x3288` = the measured span, to the byte | H |
| **Container array — `0x50` class** | **`0x017BBF58` … `0x017C0788`, 232 containers** | same sweep; uniform `0x50`, no irregular step | H |
| **★ Master key — a container names itself** | vtable slot **`+0x34`**, body literally `B8 <imm32> C3` | the engine itself uses it: `FUN_0064A7E0` does `mov eax,[edx+0x34]; call eax` then hashes the result (§1.1) | H |
| **Container self-registration** | **`FUN_0064A770`** | writes `container+0x06 = countA + countB` — one monotone type-id counter across both registries | H |
| **Container name hash (runtime)** | **`container+0x10`** | `FUN_0064A7E0`: `0x0064A834: 89 4E 10  mov [esi+0x10], ecx` after the FNV fold; zero in the static image | H |
| **Container type id** | **`container+0x06`** (`+0x04` is a constant `0xFFFF` sentinel) | `0x0064A7A5: 66 89 48 06  mov word ptr [eax+6], cx`; `+0x04 == 0xFFFF` for all 334 | H |
| **Container resolve — `0x80` class** | inlined; non-inlined **`FUN_00423DC0`**, probe **`FUN_00648D80`**, alias wrapper **`FUN_006496B0`**, `[rec+0x34]` variant **`FUN_00649C60`** | `FUN_00423DC0` exhibits `+0x48/+0x20/+0x26/+0x24/+0x70/+0x7C` in one 0x36-byte body | H |
| **Container resolve — `0x50` class** | **`FUN_005857E0`** (`this` in `ECX`, guid in `EAX`) | `0x005857ED: 8D 79 18  lea edi,[ecx+0x18]` then `[edi+0x0C]` stride, `[edi+0x0E]` shift, `[edi+0x10]` cap, `[edi+0x1C]` slots, `[edi+0x20]` pages; slow path `add ecx,0x18; jmp 0x649c00` | H |
| **Component add/set** | **`FUN_00649180(container, guid, key2, subKey, &value)`** | read body; grows via `FUN_00649060`; inserts into **both** hash indexes via two `FUN_00648CB0` calls; bumps `+0x18`; then vtable `+0x58` (added) or `+0x5C` (updated) | H |
| **Component remove** | container vtable **`+0x70`**`(guid, subKey)`, or **`+0x64`**`(guid)` | `RemoveFromDisposer` `FUN_005D29F0` (`+0x70`); `SetInfiniteAmmo` false-path (`+0x64`) | H |
| **Container iterate** | **`FUN_006499F0(&container, arg, whichIndex)`** + **`FUN_00649A80(&cursor)`** | `0x00649A11: lea eax,[ebp+0x34]` / `jne` → `0x00649A16: lea eax,[ebp+0x50]` — the third argument **selects the hash index**; cursor pooled under critsec `DAT_00EDBAA4`, free-list `PTR_DAT_00EDBAC0` | H |
| **`RuntimeSceneObject`** (position/orientation) | **`0x00DF9C90`**, id 316, stride **56**, cap 256 | `FUN_00665AF0`: `0x00665AF6: B9 90 9C DF 00  mov ecx, 0xdf9c90`; name via `[vtable 0x00BC4138 + 0x34]` | H |
| **Transform read / write** | **`FUN_00665AF0`** / **`FUN_006658B0`** (thunk → `FUN_004245B1`) | read copies 8 dwords, skips and bumps dword 3; write paired with it in `SetPosition`/`SetYaw`/`SetTransformToObject` | H (read) / M (write) |
| **`Name` registry** | **`0x00DF6B88`**, id 1, stride 4 | `Object.SetName` `FUN_005CCAF0` writes it; default string `s_Unknown_00BAA594`; the spawn name registry of [`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md) §3 | H |
| **`ModelName`** | **`0x00DF6C08`**, id 2, stride 4 | `Object.SetModelName` `FUN_005CCD00`, `AddQualityRef` `FUN_005D1B00`, `GetModelName`, `IsAwake`; same container `Player.SetOutfit` uses | H |
| **`Label`** | **`0x00DF8108`**, id 119, stride 4 | `AddLabel`/`RemoveLabel`/`HasLabel`/`AddToDisposer`/`RemoveFromDisposer`; multi-valued — the label hash goes in the `subKey` slot | H |
| **`"disposable"` reserved label** | **`0xF956736B`** | `0x005D29B9: 68 6B 73 56 F9  push 0xf956736b`; `pandemic_hash_m2("disposable") == 0xF956736B` — **recomputed, exact** | H |
| **`RuntimePhysicalLink`** (attachment) | **`0x00DF9110`**, id 219, stride 40 | `Attach`/`Detach`/`IsAttached`/`GetAttachedObjects` | H |
| **`RtPoweredGate`** | **`0x00DF9890`**, id 294, stride 48 | `OpenGate` `FUN_005D18E0` / `CloseGate` `FUN_005D19E0` iterate it | H |
| **`CheatInfiniteAmmo`** | **`0x00DF9B10`**, id 311, **stride 1**, cap 128 | `SetInfiniteAmmo` `FUN_005CE7E0` and the player-attach worker `FUN_006A4060` both write it — **both cheat-gated** (§6.9) | H |
| **`Players`** | **`0x00DF9B90`**, id 312, stride 4, **cap 8** | `IsPlayerControlled` `FUN_005CDFF0` inlines the exact `DAT_00DF9BA8/BB0/BB4/BB6/C00` walk the player map pins; `IsDisguised` probes `Players+0x50` then `0x005CEFCD: F6 80 38 04 00 00 02  test byte ptr [eax+0x438], 2` | H |
| **`SeatLink`** | **`0x00DF8188`**, id 124, stride 8 | `IsPlayerControlled` reads `DAT_00DF81CC`/`DAT_00DF81EC` = `base+0x44`/`+0x64`; same container `Player.ClaimSeat` works | H |
| **`RuntimeHealth`** | **`0x017BEF78`**, id 234, **stride 12**, hash `0xF9B9B2A5` | `GetHealth`/`GetMaxHealth`/`SetHealth`/`IsAlive`/`Revive` all `mov ecx, 0x17bef78` | H |
| **`SceneObject`** (life/awake/visibility state) | **`0x017C02D8`**, id 314, stride 28 | `IsAlive`/`GetHealth`/`Revive`/`IsAwake`/`IsHibernated`/`IsVisible`; `+0x1A` bit 0 = **dead latch** (§5.5) | H |
| **Physics-body handle lookup** | **`FUN_00432740`** (thunk → `FUN_004B1131`) | every velocity/mass/impulse cfunc calls it and then dispatches through the returned object's vtable | H |
| **Hardpoint lookup by name-hash** | **`FUN_006886A0`** (indirect jump `_DAT_0245A084`) | `GetHardpoint*`, `Attach`, `SetPositionToObject`, `SetTransformToObject` all gate on `0 < FUN_006886A0(hash)` | H |
| **Message-bus post (`Object.Kill`)** | **`FUN_0042BE60`** | 0x400-entry bounded queue at `DAT_011B51A8`, 16-byte entries, critsec `DAT_011BA1B0`, gated on `DAT_011BA1A8`; **no modulo anywhere** | H |

---

## 1. The container arrays — the structure behind every `Object.*` call

### 1.1 There are two arrays, all 334 containers name themselves, and both are checkable — H

**The master key.** `container[0]` is a vtable; **`[vtable+0x34]` is a two-instruction accessor
`mov eax, <char*>; ret`** — literally the byte pattern `B8 <imm32> C3`. Validate that *shape*, never
the slot number ([[no-arbitrary-hashes]]).

This is not a pattern imposed from outside — **the engine itself uses it.** `FUN_0064A7E0` walks the
registry and hashes each container's own name string:

```
0064A7F4  8B 34 BD C8 BE ED 00   mov   esi, [edi*4 + 0xedbec8]   ; registry[i]
0064A7FB  8B 16                  mov   edx, [esi]                ; vtable
0064A7FD  8B 42 34               mov   eax, [edx + 0x34]         ; <-- the name accessor
0064A802  FF D0                  call  eax
0064A80E  B9 C5 9D 1C 81         mov   ecx, 0x811c9dc5           ; FNV-1a offset basis
0064A813  0F BE D2 / 83 CA 20    movsx edx, dl / or edx, 0x20    ; case-suppress
0064A819  33 CA                  xor   ecx, edx
0064A81E  69 C9 93 01 00 01      imul  ecx, ecx, 0x1000193       ; FNV prime
0064A82B  83 F1 2A               xor   ecx, 0x2a                 ; the M2 tail
0064A82E  69 C9 93 01 00 01      imul  ecx, ecx, 0x1000193
0064A834  89 4E 10               mov   [esi + 0x10], ecx         ; container+0x10 = name hash
```

That is `pandemic_hash_m2` verbatim. So the string at `[vtable+0x34]` **is** the component's shipped
identity, and `container+0x10` holds its hash at runtime (it is zero in the static image).

**The sweep.** Scan all of `.data` for
`{ vtable in .rdata, u16@+0x04 == 0xFFFF, [vtable+0x34] decodes to B8/C3, target is ASCII }`. It
returns **exactly 334 hits, in exactly two contiguous runs, and nothing else** — 102 at
`0x00DF6B88` (stride `0x80`, one `0x88` step at `0x00DF8408`) and 232 at `0x017BBF58` (uniform
`0x50`). Full census: **§10**.

**One type-id space, proven two ways.**

*(a) Arithmetic.* The union of the 334 ids at `container+0x06` is **exactly `1 … 334`, contiguous,
zero gaps, zero collisions** between the arrays — and `0x14E = 334` is the total container count. Two
independent numberings could not tile a shared range perfectly and never collide.

*(b) Mechanism.* `FUN_0064A770`, tail-called by every ctor, makes the id a **running total of both
registry counters**:

```
0064A770  8B 48 08 / C1 E9 03 / F6 C1 01   ; flags>>3 & 1 selects the registry
;--- bit-3 SET path   (registry 0x00EDBAC8, counter [0x0117605C])
0064A790  8B 0D 58 60 17 01   mov   ecx, [0x1176058]        ; the OTHER counter
0064A7A3  03 CA               add   ecx, edx
0064A7A5  66 89 48 06         mov   word ptr [eax + 6], cx  ; id = countA + countB
;--- bit-3 CLEAR path (registry 0x00EDBEC8, counter [0x01176058])
0064A7BF  8B 15 5C 60 17 01   mov   edx, [0x117605c]        ; the OTHER counter
0064A7D2  03 CA               add   ecx, edx
0064A7D4  66 89 48 06         mov   word ptr [eax + 6], cx
```

**The registry split is orthogonal to the array split.** `flags & 8` picks `0x00EDBAC8` vs
`0x00EDBEC8`; the container's *storage class* (`0x80` vs `0x50`) is a different partition. Neither
array is "the Runtime array". [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md)
already has `FUN_0064A770`, `FUN_0064A7E0`, both registries and the `[vtable+0x34]` accessor — it
simply never applied the key to the `0x80` array, which is why its census is an undercount.

**Independent validation of the census.** Two component hashes recorded in
[`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md) from an
entirely unrelated derivation reproduce from the name string alone:
`pandemic_hash_m2("RuntimeHealth") == 0xF9B9B2A5` and
`pandemic_hash_m2("RuntimeNodeHealth") == 0x76927BF5`. Per [[aset-name-export]] a bare hash match is
not evidence — but here the *name*, the *hash*, the *container address* and the *cfunc that uses it*
all agree, which is a four-way join. `docs/game_config/cdbsizes.ini` is a third, data-side witness:
it budgets `CheatInfiniteAmmo 256 128`, and the static descriptor says **cap = 128**.

> ⚠ **Superseded.** An earlier revision described "one templated container type instantiated 102
> times" and made naming the other 93 confirm-live **§8.1** (*"break `FUN_0064A770` once at
> static-init and dump the pairs"*). There are **two** templated types, **334** instances, and no
> breakpoint is needed. §8.1 is closed.

### 1.2 The container layouts

Read from `FUN_00423DC0`, `FUN_00665AF0`, `FUN_00649180`, `FUN_00648D80`, `FUN_005857E0`,
`FUN_006499F0`, and the inlined walks in `IsPlayerControlled`/`Detach`/`IsAttached`/`InSeat`.

**The `0x80` class** (102 containers). Every one carries **two** hash-index sub-objects, at `+0x34`
and `+0x50`, each shaped `{cap@+0x08, mult@+0x0C = 0x9E3779B9, keys@+0x10, slots@+0x14,
ownerBackPtr@+0x18}`. The back-pointer is decisive: for `RuntimeSceneObject`, both
`[0x00DF9C90+0x4C]` and `[0x00DF9C90+0x68]` read back `0x00DF9C90`.

| Off | Field | Read from | Conf |
|---|---|---|---|
| `+0x00` | vtable (`+0x34` name · `+0x50` alloc page · `+0x54` copy-construct · `+0x58` on-add · `+0x5C` on-update · `+0x64` erase-by-guid · `+0x70` erase-by-(guid,subKey)) | ctors + `FUN_00649180` + `FUN_005D29F0` + `FUN_0064A7E0` | H |
| `+0x04` | constant `0xFFFF` sentinel | true for all 334 | H |
| `+0x06` | **type id** (u16) | `FUN_0064A770` `mov word ptr [eax+6], cx` | H |
| `+0x08` | flags — **bit 3** selects the registry *and* the resolver path; `Object.SetName` also tests bit 1 | `FUN_0064A770`, `FUN_005857E0`, `FUN_006496B0`, `FUN_00649180` | H |
| `+0x10` | name hash (written at init by `FUN_0064A7E0`; **0 in the image**) | `mov [esi+0x10], ecx` | H |
| `+0x18` | **live record count** (0 in the image) | `IsPlayerControlled` bounds its scan by `DAT_00DF9BA8`; `FUN_00649180` bumps it | H |
| `+0x1C` | capacity | `FUN_00649180` grow test `[ebx+0x1c]` vs `[ebx+0x18]` | H |
| `+0x20` | **records per page** = page mask + 1 (**boot-written**, §1.2.1) | `(DAT_00DF9CB0 - 1 & key)` in `FUN_00665AF0`; `= 0x100` for `RuntimeSceneObject` | H |
| `+0x24` | **element stride** (i16 — **static for this class**, §1.2.1) | `movsx edx, word ptr [esi+0x24]` in `FUN_00423DC0`; `= 0x38` (56) for `RuntimeSceneObject` | H |
| `+0x26` | **page shift** (u8, **boot-written**, §1.2.1) | `mov cl, byte ptr [esi+0x26]`; `= 8` | H |
| `+0x28` | hash multiplier `0x9E3779B9` | golden ratio; the same constant `FUN_00648D80` uses | H |
| `+0x34` | **hash index 1** sub-object | `FUN_006496B0` `lea esi,[edi+0x34]` | H |
| `+0x44` | index-1 key array (dense **owner-GUID**) | `= +0x34+0x10`; `FUN_00649180` writes `param_1[0x11][slot]`; `IsPlayerControlled`/`Detach` read it | H |
| `+0x48` | index-1 slot table (**bucket → packed record key**) | `= +0x34+0x14`; `key = *(u32*)(DAT_00DF9CD8 + slot*4)` | H |
| `+0x4C` | index-1 owner back-pointer (`== container`) | measured; the decisive fingerprint | H |
| `+0x50` | **hash index 2** sub-object | `FUN_006499F0` `lea eax,[ebp+0x50]`; `IsPlayerControlled` probes `0x00DF9BE0` = `Players+0x50` | H |
| `+0x60` | index-2 key array (dense **secondary key**) | `FUN_00649180` `param_1[0x18][slot] = key2` under flag bit 1; `GetAttachedObjects` reads it as the attached GUID | H |
| `+0x64` | index-2 slot table | `IsPlayerControlled`, `Detach`, `IsAttached`, `InSeat` | H |
| `+0x68` | index-2 owner back-pointer (`== container`) | measured | H |
| `+0x6C` | dense **subKey** array | `FUN_00649180` `param_1[0x1b][slot] = subKey` under flag bit 0 | M |
| `+0x70` | **page table** (0 in the image — pages are heap-allocated on first insert) | `*(int*)(DAT_00DF9D00 + (key >> shift)*4)` | H |
| `+0x74` | zeroed by the ctor | every ctor | H |
| `+0x7C` | shared **zero record** returned on miss | `FUN_00423DC0` `lea eax,[esi+0x7c]` | H |

> **This collapses four rows of the old table into one repeated structure.** The old map listed
> `+0x44` "dense owner-GUID array", `+0x48` "bucket → packed record key", `+0x60` "dense
> secondary-key array" and `+0x64` "hash bucket table" as four ad-hoc arrays at **M**. Every offset
> it stated is correct; they are **two instances of one index type** at `+0x34` and `+0x50`, which is
> why the third argument of `FUN_006499F0` is an index selector, and all four are now **H**.

**The `0x50` class** (232 containers) keeps a **single** hash sub-object at `+0x18` with a
*different* internal layout, per `FUN_005857E0`:

| Off | Field | Read from |
|---|---|---|
| `+0x18` | hash sub-object base | `0x005857ED: 8D 79 18  lea edi, [ecx+0x18]` |
| `+0x24` | element stride (i16) = `[edi+0x0C]` | `0x00585815: 0F BF 57 0C  movsx edx, word ptr [edi+0xc]` |
| `+0x26` | page shift (u8) = `[edi+0x0E]` | `0x0058580B: 8A 4F 0E  mov cl, byte ptr [edi+0xe]` |
| `+0x28` | **capacity / records per page** = `[edi+0x10]` | `0x00585808: 8B 47 10  mov eax, [edi+0x10]` |
| `+0x34` | slot table = `[edi+0x1C]` | `0x005857FF: 8B 47 1C` |
| `+0x38` | page table = `[edi+0x20]` | `0x0058581E: 8B 4F 20` |
| `+0x2C` | hash multiplier `0x9E3779B9` | measured |

> ⚠ **A measured correction to the brief this revision was written against.** The claim *"array A's
> capacity fields are populated, array B's are all zero"* does **not** reproduce **as an offset
> question**. Read at the class-correct offset, every one of the 334 containers in the **live dump**
> has a populated descriptor; the `0x50` class shows `0` at `+0x20` simply because `+0x20` is not its
> capacity field (it is `+0x28`). **Self-validating check: in the dump, `capacity == 2^page_shift`
> holds for all 334 with the per-class offsets above, without a single exception** — two
> independently read fields agreeing arithmetically 334/334 is proof the right offsets were read, and
> a read that *fails* the identity means the wrong offset for that class, not a real exception. (A
> known way to trip it: reading `+0x28` on an `0x80`-class container returns the FNV seed
> `0x9E3779B9`, not a capacity.) Strides are real and varied: 1…396 bytes in the `0x50` class,
> 1…740 in the `0x80` class.
>
> **But "populated in the dump" is not "static data" — see §1.2.1.** The brief's claim was half-right
> for a reason it did not state.

#### 1.2.1 Which descriptor fields are static, and which are written at boot — measured

`output/_ghidra/securom_dump/mercs2_unpacked.exe` is a **live dump**, so its `.data` is post-boot.
Diffing it field-by-field against the clean on-disk image
`output/_ghidra/securom_dump/mercs2_nodrm_v3.exe` splits cleanly by class:

| | `0x80` class (102) | `0x50` class (232) |
|---|---|---|
| **stride** `+0x24` | **identical in both images — 0 of 102 differ.** Genuinely static | **all 232 differ; on disk the value is `0`** |
| **capacity** (`+0x20` / `+0x28`) | on disk a uniform placeholder **`256`**; **44 of 102** are overwritten at boot | on disk **`0`**; **all 232** written at boot |
| **page shift** `+0x26` | on disk a uniform **`8`**; same 44 overwritten | on disk `0`; all 232 written |
| **multiplier** | `0x9E3779B9` static | `0` on disk; written at boot |

**276 of 334 containers have a different capacity in the dump than on disk** (44 + 232).

The writer is the per-component **registrar**, which builds the whole descriptor and then tail-calls
`FUN_0064A770`. `FUN_00640410` (`ControllerPlayer`, `0x017BCEF8`) is the pattern in full:

```
00640463  C7 05 F8 CE 7B 01 D0 EF BB 00   mov [0x17bcef8], 0xbbefd0     ; +0x00 vtable
0064046D  66 C7 05 1C CF 7B 01 0C 00      mov word ptr [0x17bcf1c], 0xc ; +0x24 stride = 12
00640476  66 C7 05 1E CF 7B 01 08 00      mov word ptr [0x17bcf1e], 8   ; +0x26 shift  = 8
0064047F  89 0D 20 CF 7B 01               mov [0x17bcf20], ecx          ; +0x28 cap    = 0x100
00640485  C7 05 24 CF 7B 01 B9 79 37 9E   mov [0x17bcf24], 0x9e3779b9   ; +0x2C multiplier
0064049F  E8 CC A2 00 00                  call 0x64a770                 ; self-register
```

Note the registrar writes cap **256 / shift 8** — the same default the `0x80` class carries on disk —
yet the dump shows `ControllerPlayer` at **cap 32 / shift 5**. Something resizes it after
registration, and that something is shipped data:

> **★ `docs/game_config/cdbsizes.ini` `[presize]` is the authority on capacity.** Joining its rows
> against the census: **325 rows join, and all 325 agree with the dump — zero mismatches.** Where a
> row has two columns the **second** is the page capacity (`ControllerPlayer 96 32` → dump 32;
> `Rotor 384 128` → dump 128; `BoneCtrlJostle 8 8` → dump 8; `HumanAnimationControllerNEW 128 64` →
> dump 64; `CheatInfiniteAmmo 256 128` → dump 128; `Players 8 8` → dump 8). Where a row has one
> column (114 of them, e.g. `RuntimeHealth 1280`) the capacity stays at the **256** default.

So the dependency chain is **registrar default → `cdbsizes.ini` resize → the values this map's §10
table reports**. For a reimpl that means: **read pool sizes from `cdbsizes.ini`, never from one
run's snapshot of `.data`.**

What is genuinely runtime-only in *both* images remains the **allocated page memory**: live count
`+0x18`, page table `+0x70`/`+0x38` and the records themselves are zero because pages are
heap-allocated on first insert.

> ⚠ **This also retires an older claim properly.** An earlier revision said *"every container's
> capacity, stride, page table and live count are zero in the static image, so read `container+0x24`
> live."* On disk the **`0x50` class genuinely is all-zero** — that half was right — but the
> conclusion "read it live" was wrong twice over: for the `0x80` class the stride was static all
> along, and for both classes the *declared* capacity is in a shipped `.ini`, not in memory at all.

### 1.3 The resolve idiom — H

Verbatim from `Object.GetPosition`'s worker `FUN_00665AF0` (`RuntimeSceneObject 0x00DF9C90`):

```
00665AF6  B9 90 9C DF 00   mov ecx, 0xdf9c90
00665AFD  E8 AE 3B FE FF   call 0x6496b0                     ; hash probe (+ alias fallback)
00665B06  [0xdf9cd8]=+0x48  [0xdf9cb0]=+0x20  [0xdf9cb6]=+0x26  [0xdf9cb4]=+0x24  [0xdf9d00]=+0x70
```
```c
slot   = FUN_006496B0(guid);                                      // < 0 → miss
key    = *(u32*)(DAT_00DF9CD8 + slot*4);                          // +0x48
record = (DAT_00DF9CB0 - 1 & key) * (short)DAT_00DF9CB4            // +0x20 mask, +0x24 stride
       + *(int*)(DAT_00DF9D00 + (key >> (DAT_00DF9CB6 & 0x1f))*4); // +0x70 page table, +0x26 shift
```

`FUN_00648D80` is the probe proper: `bucket = ([esi+0x0C] * guid) % [esi+0x08]`, open-addressed
linear probe over `slots = [esi+0x14]` against `keys = [esi+0x10]`, branchless wrap
(`sub ecx,[esi+8]; sar ecx,0x1f; and eax,ecx`), and it **returns the bucket index**.

`FUN_006496B0` is `FUN_00648D80` **on index 1** plus one alias step:

```
006496BA  8D 77 34   lea  esi, [edi + 0x34]   ; hash index 1
006496C0  E8 ..      call 0x648d80
006496C7  7C 2E      jl   done                ; guid < 0 (template) -> NO alias attempt
006496CF  F6 C1 01   test cl, 1               ; flags bit 3 set -> suppress alias
006496D4  83 F8 FF   cmp  eax, -1 / jne done  ; only on miss
006496DA  E8 ..      call 0x6654b0            ; guid -> alias/source guid
006496F2  E8 B9 FF FF FF  call 0x6496b0       ; *** RECURSES on the alias ***
```

A GUID that is not itself in the container can still resolve **through its source** — a
template/prototype indirection. Worth knowing before any reimpl models the lookup as a plain map.
Note the detail the old map omitted: **the alias step is skipped for negative (template) GUIDs.**

`FUN_00423DC0` is the non-inlined form, and it is the single best witness for the whole layout —
36 bytes exhibiting `+0x48`, `+0x20`, `+0x26`, `+0x24`, `+0x70` and the `+0x7C` shared zero record
returned on **both** the probe-miss and the null-record path (`0x00423DF2: 8D 46 7C  lea eax,[esi+0x7c]`).

> **One correction to a sibling map, stated plainly, and re-verified.**
> [`player_code_map.md`](player_code_map.md) §2.1 describes `FUN_006496B0` as *"guid → dense slot"*.
> `FUN_00648D80` returns the **hash bucket**; `container+0x48` then maps bucket → packed record key.
> Every arithmetic step in that map is right — only the name of the intermediate is off. No
> downstream claim changes.

### 1.4 Add / set — one function for all 334 containers — H

```c
int FUN_00649180(container, ownerGuid, key2, subKey, &value)
```

- Probes for an existing record (`FUN_00648D80`, or an **iterated** search over `subKey` when flag
  bit 0 is set — that is how multi-valued containers like `Label` avoid duplicating a `(guid, label)`
  pair).
- **Miss** → grow if needed (`0x0064924A`/`0x00649282: call 0x649060`, geometric via `_DAT_00D09AB4`),
  allocate the page through vtable `+0x50` if absent, copy-construct through vtable `+0x54`, write
  `+0x44 ← ownerGuid`, `+0x60 ← key2`, `+0x6C ← subKey`, insert into **both** hash indexes
  (`0x00649309` and `0x0064932F`, two `call 0x648cb0`), `0x00649340: 83 43 18 01  add [ebx+0x18], 1`,
  then fire vtable **`+0x58`**.
- **Hit** → overwrite in place through vtable `+0x54`, then fire vtable **`+0x5C`**.
- `0x00649344: 80 3D 8A B5 CF 00 00  cmp byte ptr [0xcfb58a], 0` gates
  `0x0064935E: call 0x665590` — a **cross-registration hook** (component-added notification) fired
  when `container+0x04` is a non-negative i16. Its consumer is **open** (§8.3).

The `+0x58`/`+0x5C` split is the on-add-vs-on-update callback pair, and it is why a scripted
`Object.SetName` on an already-named object behaves differently from naming a fresh one.

### 1.5 Iterate — pooled cursors, and the index selector — H

`FUN_006499F0(&container, arg, whichIndex)` fills a stack cursor; `FUN_00649A80(&cursor)` advances
it; `local_24 < 0` terminates. The cursor is drawn from and returned to a **free-list**
(`PTR_DAT_00EDBAC0`) under critical section `DAT_00EDBAA4` — the same pool
[`player_code_map.md`](player_code_map.md) §7 found behind `Player.ClaimSeat`. Confirms it is a
generic container-cursor pool, not seat-specific.

The third argument is the **hash-index selector**, which the old map did not have:

```
00649A11  8D 45 34   lea eax, [ebp + 0x34]   ; index 1 (forward)
00649A14  75 03      jne 0x649a19
00649A16  8D 45 50   lea eax, [ebp + 0x50]   ; index 2 (reverse)
```

Three independent confirmations that the second index is load-bearing: `Object.InSeat` probes
`0x00DF8458` = `RiderLink+0x50`; `Object.GetName` probes `0x00DF6BBC` = `Name+0x34`;
`IsPlayerControlled` probes `0x00DF9BE0` = `Players+0x50` and `0x00DF81D8` = `SeatLink+0x50`.

---

## 2. `RuntimeSceneObject` `0x00DF9C90` — the hottest structure in the game

`Object.GetPosition` alone is **201 script call sites**, the single most-called binding in the
namespace. Its worker (read in full; every line below is in the disassembly at the stated VA):

```
00665AF6  mov  ecx, 0xdf9c90                ; RuntimeSceneObject
00665AFD  call 0x6496b0                     ; probe + alias
00665B38  fld [eax]    / fstp [esi]         ; dword 0
00665B3F  fld [eax+4]  / fstp [esi+4]       ; dword 1
00665B45  fld [eax+8]  / fstp [esi+8]       ; dword 2
00665B4B  movq [eax+0x10] -> [esi+0x10]     ; dwords 4,5
00665B55  movq [eax+0x18] -> [esi+0x18]     ; dwords 6,7
00665B5F  eax=[eax+0x0c]; ecx=[esi+0x0c]; if(ecx>eax) eax=ecx; eax+=1; [esi+0x0c]=eax   ; ★ serial
00665B76  (miss) mov ecx, 0x17c02d8 -> SceneObject -> FUN_00434F80
```

- **32 bytes are copied out**, and dword `[3]` is skipped by the copy and instead **max-merged and
  incremented** — a change serial / dirty counter, not payload. **H.**
- The remaining 7 dwords are `[0..2]` and `[4..7]`. Position at `[0..2]`; **`[4..7]` is a
  quaternion `(x, y, z, w)` with `w` last — PROVEN**, promoted from the old map's **M**.
  `Object.GetYaw` does `0x005CC565: lea eax, [esp+0x28]` (= out `+0x10`, exactly dwords `[4..7]`)
  then `0x005CC569: call 0x823bc0`, and `FUN_00823BC0` is the textbook Shoemake yaw:

  ```
  00823BC6  load q = { x=[+0], y=[+4], z=[+8], w=[+0xC] }
  00823BD9  xmm5 = x²+y²+z²+w²                        ; squared norm
  00823C01  xmm4 = [0xB92874] / xmm5   ([0xB92874] = 2.0f)      -> s = 2/‖q‖²
  00823C1B  xmm2 = s(xz + yw)
  00823C2E  xmm0 = s(z² + w²) − [0xB9B664]            ([0xB9B664] = 1.0f)
            -> atan2(xmm2, xmm0)
  ```
  `2(z²+w²) − 1 ≡ 1 − 2(x²+y²)` for a unit quaternion, so this is exactly
  `yaw = atan2(2(xz + yw), 1 − 2(x² + y²))` — rotation about **Y**. `GetYaw` then scales by
  `0x005CC58D: F3 0F 59 05 1C AB BE 00  mulss xmm0, [0xbeab1c]`, and `[0x00BEAB1C] = 57.29583` =
  180/π. A `2/‖q‖²` normalization and the exact Shoemake terms cannot coincide with four arbitrary
  floats.
- **The record is 56 bytes, not 32** (`RuntimeSceneObject` stride = `0x38`). `FUN_00665AF0` copies
  the first 32; `+0x20…+0x37` is untouched by the transform read and is **undecoded**.
- **There is a second, slower path**: on a miss it resolves the **`SceneObject`** component
  (`0x00665B78: B9 D8 02 7C 01  mov ecx, 0x17c02d8`) and produces a transform from it via
  `FUN_00434F80`. So "no `RuntimeSceneObject` record" is not the same as "no position". (The old map
  called this "the world object"; it is a named component.)
- `FUN_006658B0` (thunk → `FUN_004245B1`) is the paired **commit**. **M** — the pairing is
  unambiguous, the body is behind the thunk.

**Writing a position is not a field write.** `Object.SetPosition` `0x005CCF10` only marshals
arguments and tail-calls `FUN_005CCE00`:

```
005CCE16  call 0x665af0                      ; fetch/validate; false -> push nil
005CCE83  call 0x6658b0                      ; ★ THE COMMIT
005CCE8D  mov  ecx, 0x17bf888                ; PhysicsActor  (id 271)
005CCE92  call 0x5857e0
005CCE9B  mov  esi, [eax]                    ; embedded world/actor pointer
005CCEA3  mov  eax, [edx + 0xE0] / call eax  ; ★ VIRTUAL CALL, return compared to 1
005CCEAD  cmp  eax, 1 / jne skip
005CCEB4  call [[esi] + 0x84] (&newPos, -1)  ; hook 1
005CCEC5  call [[esi] + 0x88] (pos)          ; hook 2
```

So a teleport is: mutate transform → commit → two world notifications, **and only if
`vtable+0xE0()` returns 1**. Note this is a *virtual method whose return value is compared to 1*, not
a memory field — the old map's pseudocode showed this correctly but the shorthand "`+0xE0 == 1` gate"
elsewhere in the map is only right if `+0xE0` is understood as a vtable slot. A reimpl that writes a
transform component and stops will silently desync spatial partitioning.

---

## 3. The `Object` binding surface — all 87, name → VA

`luaL_Reg` table **`0x00B99608`**, **0 stubs**, terminator `{NULL,NULL}` at `0x00B998C0`. Cfuncs are
`undefined4 f(lua_State *L)`; args via `FUN_0059FF50` (lightuserdata/GUID), `FUN_0059F6D0` (boolean),
`FUN_0059F780` (float), `FUN_0059F820`/`FUN_0059FB00` (integer/string-hash), `FUN_0059FC30` (vector);
results reserved with `FUN_0085D5D0` then pushed with the `*(L+8) += 8` idiom; errors via
`FUN_004B2A50`. **Lua tags:** `1` = boolean, `2` = lightuserdata (**GUIDs**), `3` = number (32-bit
float — a pushed `3` appears as `4.2039e-45`), `7` = table.

**⬤ = Ghidra decompiled a body (63)** · ○ = **Ghidra-blind, body readable by disassembly (24)** ·
*calls* = script call sites (1272 total; 18 names are never called).

**`resolves via` legend** — `XF-read`/`XF-write` = `RuntimeSceneObject 0x00DF9C90` via
`FUN_00665AF0`/`FUN_006658B0` · `CMP` = `FUN_005857E0` against a `0x50`-class container, **now named
in §3.1** · `ADD` = `FUN_00649180` component add/set · `ITER` = `FUN_006499F0` container walk ·
`PHYS` = physics-body handle `FUN_00432740` · `HP` = hardpoint hash `FUN_006886A0` · `HASH` =
a direct `FUN_00648D80` probe · `NAMEREG` = the `Name` container `0x00DF6B88` · `pure` = no engine
state · `other` = see §4–§6.

| Name | VA | | calls | resolves via | | Name | VA | | calls | resolves via |
|---|---|:-:|--:|---|---|---|---|:-:|--:|---|
| `AddLabel` | `0x005CE900` | ⬤ | 7 | ADD | | `InsideBoundary` | `0x005CF790` | ⬤ | 8 | XF-read |
| `AddQualityRef` | `0x005D1B00` | ⬤ | 1 | ADD | | `IsAlive` | `0x005CD8C0` | ○ | 139 | CMP (§5.5) |
| `AddToDisposer` | `0x005D2900` | ⬤ | 4 | ADD | | `IsAttached` | `0x005D13C0` | ⬤ | 1 | HASH |
| `ApplyAngularImpulse` | `0x005D0230` | ⬤ | 2 | XF-read+PHYS | | `IsAwake` | `0x005CF300` | ⬤ | 17 | CMP |
| `ApplyImpulse` | `0x005CFEE0` | ⬤ | 8 | XF-read+PHYS | | `IsDisguised` | `0x005CEF20` | ○ | 1 | CMP |
| `ApplyPointImpulse` | `0x005D0060` | ⬤ | 3 | XF-read+PHYS | | `IsHibernated` | `0x005CF240` | ○ | 5 | CMP |
| `AreEqual` | `0x005CE320` | ⬤ | 0 | **pure** | | `IsPlayerControlled` | `0x005CDFF0` | ⬤ | 74 | HASH |
| `Attach` | `0x005D1060` | ⬤ | 8 | ADD+HP | | `IsTemplate` | `0x005CBD20` | ○ | 1 | **pure** (`guid < 0`) |
| `AttachCargoToWinch` | `0x005D1FE0` | ⬤ | 5 | XF-read+XF-write+CMP+PHYS | | `IsValid` | `0x005CDF60` | ○ | 2 | **pure** (Lua tag) |
| `BeginQueuedAcceleration` | `0x005D2700` | ⬤ | 0 | other | | `IsVisible` | `0x005D04C0` | ⬤ | 11 | XF-read+CMP |
| `CloseGate` | `0x005D19E0` | ⬤ | 15 | ITER | | `IsWinched` | `0x005D1EA0` | ⬤ | 7 | CMP+PHYS |
| `Detach` | `0x005D1280` | ⬤ | 7 | HASH | | `IsWinching` | `0x005D1DE0` | ○ | 0 | CMP |
| `DetachCargoFromWinch` | `0x005D21C0` | ○ | 7 | CMP | | `Kill` | `0x005CDEC0` | ⬤ | 29 | other |
| `DisablePhysics` | `0x005D0750` | ○ | 29 | **16 B thunk** (§6.1) | | `OpenGate` | `0x005D18E0` | ⬤ | 10 | ITER |
| `EnablePhysics` | `0x005D0740` | ○ | 11 | **16 B thunk** (§6.1) | | `OutsideBoundary` | `0x005CF880` | ⬤ | 1 | XF-read |
| `FadeOut` | `0x005CDD40` | ⬤ | 21 | CMP | | `PlayAnimation` | `0x005D0BD0` | ⬤ | 4 | CMP |
| `GetAttachedObjects` | `0x005D1520` | ⬤ | 1 | ITER | | `PlayMaterialAnimation` | `0x005D1660` | ⬤ | 13 | other |
| `GetCashValue` | `0x005CC360` | ○ | 1 | CMP | | `QueueAcceleration` | `0x005D2480` | ⬤ | 0 | other |
| `GetDistanceFrom` | `0x005CD3F0` | ⬤ | 11 | XF-read | | `Remove` | `0x005CDC00` | ⬤ | 83 | other |
| `GetHardpointPitch` | `0x005CFCB0` | ⬤ | 0 | HP | | `RemoveFromDisposer` | `0x005D29F0` | ⬤ | 0 | other |
| `GetHardpointPosition` | `0x005CFA80` | ⬤ | 12 | HP | | `RemoveLabel` | `0x005CEBA0` | ⬤ | 4 | other |
| `GetHardpointYaw` | `0x005CFB70` | ⬤ | 0 | HP | | `RemoveQualityRef` | `0x005D1C70` | ○ | 1 | other |
| `GetHealth` | `0x005CBDB0` | ○ | 48 | CMP (§5.1/§5.5) | | `RevertHibernationDistance` | `0x005CF600` | ○ | 0 | CMP |
| `GetHeightAboveTerrain` | `0x005D27E0` | ⬤ | 0 | XF-read | | `Revive` | `0x005CE170` | ○ | 12 | CMP (§5.5) |
| `GetHibernationDistance` | `0x005CF420` | ⬤ | 5 | CMP | | `SetHealth` | `0x005CBEE0` | ⬤ | 9 | CMP |
| `GetInvincible` | `0x005CE4D0` | ⬤ | 2 | CMP | | `SetHibernationDistance` | `0x005CF4F0` | ⬤ | 2 | CMP |
| `GetLocalizedName` | `0x005CC250` | ⬤ | 25 | CMP | | `SetInfiniteAmmo` | `0x005CE7E0` | ⬤ | 28 | ADD |
| `GetMass` | `0x005CF030` | ○ | 5 | PHYS | | `SetInvincible` | `0x005CE5E0` | ⬤ | 35 | other |
| `GetMaxHealth` | `0x005CC030` | ○ | 12 | CMP (§5.1) | | `SetMass` | `0x005CF110` | ⬤ | 0 | PHYS |
| `GetModelName` | `0x005CCC20` | ○ | 0 | CMP | | `SetModelName` | `0x005CCD00` | ⬤ | 2 | ADD |
| `GetName` | `0x005CCA00` | ○ | 13 | HASH (`Name+0x34`) | | `SetName` | `0x005CCAF0` | ⬤ | 9 | ADD |
| `GetNodeHealth` | `0x005CC120` | ⬤ | 1 | CMP | | `SetPosition` | `0x005CCF10` | ⬤ | 23 | XF-read+XF-write (via `FUN_005CCE00`) |
| `GetParent` | `0x005CBC50` | ⬤ | 17 | other | | `SetPositionToObject` | `0x005CCFF0` | ⬤ | 0 | XF-read+XF-write+HP+NAMEREG |
| `GetPhysicsType` | `0x005D0760` | ○ | 3 | CMP ×5 (§6.1) | | `SetTransformToObject` | `0x005CD1F0` | ⬤ | 28 | XF-read+XF-write+HP+NAMEREG |
| `GetPosition` | `0x005CC410` | ⬤ | 201 | XF-read | | `SetUnkillable` | `0x005CE6E0` | ⬤ | 3 | other |
| `GetVelocity` | `0x005CC700` | ⬤ | 12 | CMP+PHYS | | `SetVisible` | `0x005D03B0` | ⬤ | 7 | other |
| `GetVelocitySquared` | `0x005CC5E0` | ⬤ | 0 | CMP+PHYS | | `SetWinchState` | `0x005D2350` | ⬤ | 5 | CMP |
| `GetVelocityVector` | `0x005CC830` | ⬤ | 0 | XF-read+CMP+PHYS | | `SetYaw` | `0x005CD6A0` | ⬤ | 19 | XF-read+XF-write+CMP |
| `GetWinchState` | `0x005D2250` | ⬤ | 0 | CMP | | `StopAllAnimation` | `0x005D0FD0` | ○ | 3 | CMP |
| `GetYaw` | `0x005CC4E0` | ⬤ | 50 | XF-read | | `StopAnimation` | `0x005D0DF0` | ⬤ | 0 | CMP |
| `HasLabel` | `0x005CEE40` | ○ | 117 | HASH (`FUN_00649440`) | | `StopAnimationChannel` | `0x005D0EE0` | ⬤ | 1 | CMP |
| `HasWinch` | `0x005D1D30` | ○ | 0 | CMP | | `StopMaterialAnimation` | `0x005D17F0` | ⬤ | 3 | other |
| `InSeat` | `0x005CD9F0` | ○ | 6 | HASH (`RiderLink+0x50`) | | `TransformLocalToWorld` | `0x005CF980` | ⬤ | 0 | XF-read |
| `InVehicle` | `0x005CDAD0` | ○ | 2 | HASH | | | | | | |

**Traffic (the reimpl's build order).** Top ten by call sites: `GetPosition` 201 · `IsAlive` 139 ·
`HasLabel` 117 · `Remove` 83 · `IsPlayerControlled` 74 · `GetYaw` 50 · `GetHealth` 48 ·
`SetInvincible` 35 · `Kill` 29 · `DisablePhysics` 29. Those ten are **805 of 1272 call sites (63 %)**.

> ⚠ **Superseded.** An earlier revision wrote: *"The uncomfortable overlap: 4 of the top 7 are
> binding-only … **344 call sites, 27 % of all `Object` traffic, sit on functions with no decompiled
> body.** That is the highest-value forcing-script target in the project right now."* Those 344 call
> sites sit on functions that **Ghidra** did not walk to. All of them read. §7.8's advice ("do not
> implement them from their names") was the right call for the wrong reason.

### 3.1 Every cfunc's container, by name — §8.2 closed statically

**55 of 87** cfuncs carry a direct container reference (a `mov ecx, imm32` to the base, or a
`mov esi/eax, imm32` to one of its hash-index sub-objects). Ghidra hid all of these because the
container is a register argument. Reproduce: disassemble each of the 87 bodies (bounded as in the
header) and attribute every immediate that falls inside `[containerVA, containerVA+stride)` for the
334 census entries.

| cfunc | container(s) |
|---|---|
| `AddLabel` | `Label` |
| `AddQualityRef` | `ModelName` |
| `AddToDisposer` | `Label` |
| `Attach` | `RuntimePhysicalLink` |
| `AttachCargoToWinch` | `PhysicsActorWinch` |
| `CloseGate` | `RtPoweredGate` |
| `Detach` | `RuntimePhysicalLink` |
| `DetachCargoFromWinch` | `PhysicsActorWinch` |
| `FadeOut` | `RtAlphaAnimation` |
| `GetAttachedObjects` | `RuntimePhysicalLink` |
| `GetCashValue` | `CashValue` |
| `GetHealth` | `Health`, `RuntimeHealth`, `SceneObject` |
| `GetHibernationDistance` | `HibernationControl` |
| `GetInvincible` | `RtDamageFlags` |
| `GetLocalizedName` | `LocalizedName` |
| `GetMaxHealth` | `Health`, `RuntimeHealth` |
| `GetModelName` | `ModelName` |
| `GetName` | `Name` |
| `GetNodeHealth` | `RuntimeNodeHealth` |
| `GetPhysicsType` | `_BoatPhysics`, `_CarPhysicsV2`, `_HelicopterPhysics`, `_HumanPhysics`, `_TankPhysics` |
| `GetVelocity` | `ControllerVelocity` |
| `GetVelocitySquared` | `ControllerVelocity` |
| `GetVelocityVector` | `ControllerVelocity` |
| `GetWinchState` | `PhysicsActorWinch` |
| `HasLabel` | `Label` |
| `HasWinch` | `PhysicsActorWinch` |
| `InSeat` | `RiderLink` |
| `InVehicle` | `RiderLink`, `SeatLink` |
| `IsAlive` | `Health`, `RuntimeHealth`, `SceneObject` |
| `IsAttached` | `RuntimePhysicalLink` |
| `IsAwake` | `ModelName`, `SceneObject` |
| `IsDisguised` | `Players` |
| `IsHibernated` | `SceneObject` |
| `IsPlayerControlled` | `Players`, `SeatLink` |
| `IsVisible` | `SceneObject` |
| `IsWinched` | `PhysicsActorWinch` |
| `IsWinching` | `PhysicsActorWinch` |
| `OpenGate` | `RtPoweredGate` |
| `PlayAnimation` | `BoneControllerRuntime` |
| `RemoveFromDisposer` | `Label` |
| `RemoveLabel` | `Label` |
| `RevertHibernationDistance` | `HibernationControl` |
| `Revive` | `HumanStateMachine`, `RuntimeHealth`, `SceneObject` |
| `SetHealth` | `RuntimeHealth` |
| `SetHibernationDistance` | `HibernationControl` |
| `SetInfiniteAmmo` | `CheatInfiniteAmmo` |
| `SetModelName` | `ModelName` |
| `SetName` | `Name` |
| `SetPositionToObject` | `Name` |
| `SetTransformToObject` | `Name` |
| `SetWinchState` | `PhysicsActorWinch` |
| `SetYaw` | `PhysicsActor`, `RTHuman` |
| `StopAllAnimation` | `BoneControllerRuntime` |
| `StopAnimation` | `BoneControllerRuntime` |
| `StopAnimationChannel` | `BoneControllerRuntime` |

Not in that table but resolved through a worker: all `XF-read`/`XF-write` cfuncs reach
**`RuntimeSceneObject`** via `FUN_00665AF0`/`FUN_006658B0`, and `SetPosition`'s worker
`FUN_005CCE00` additionally resolves **`PhysicsActor`** (`0x005CCE8D: B9 88 F8 7B 01`).

> **Discrepancy recorded, not papered over.** The validation pass this revision folds in reported
> "55 cfuncs → **33** distinct containers". Re-derived here with bodies bounded at the first
> `ret`+`int3` seam **or** the next binding VA, it is **55 cfuncs → 29 containers**. The extra four
> come from extents that run past a function's end into the following helper: `RevertHibernationDistance`
> ends at `0x005CF6BE` (191 B) and the region-shape dispatch over `SphereRegion`/`CircleRegion`/
> `LineRegion` belongs to the *separate* function at `0x005CF6C0`; `RemoveFromDisposer` likewise. The
> per-cfunc rows above are the bounded reading.

---

## 4. Identity, naming and labels

### 4.1 `SetName` → the `Name` container `0x00DF6B88` — H

```c
name = s_Unknown_00BAA594;                          // "Unknown" — the default
if ((DAT_00DF6B90 >> 1 & 1) == 0) key2 = 0;         // container+0x08 bit 1 gate
FUN_00649180(&PTR_PTR_00DF6B88, guid, key2, key2, &name);
```

This is the **same registry `Pg.Spawn` resolves against**
([`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md) §3) — so
`Object.SetName` is not cosmetic: it makes the object findable by `Pg.GetGuidByName`. Note the local
is overwritten with `"Unknown"` *before* the add in the decompiled text; whether the actual string
argument survives in a register is **open** — the Lua string is fetched by `FUN_0059FB00` into
`local_c` and used as `key2`, which suggests **the name is passed as a hash, not a pointer**, and
`"Unknown"` is the stored display value. **M**, confirm-live §8.4.
(`Name` stride is **4**, which is consistent with a hash or a handle and *not* with an inline string
— that raises the hash reading but does not settle which of the two it is.)

`GetName` (13 calls) reads the **forward index**, `Name+0x34` (`0x00DF6BBC`); `GetLocalizedName`
(25 calls) resolves the separate **`LocalizedName`** component (`0x017BD768`, id 122) and pushes via
`FUN_0085D9F0`.

### 4.2 Labels are a multi-valued container — `Label` `0x00DF8108` — H

```c
labelHash = FUN_00824270();                              // string → hash, from the Lua arg
for (each remaining GUID argument)
    FUN_00649180(&PTR_PTR_00DF8108, guid, 0, labelHash, &labelHash);
```

- **`AddLabel` is variadic** — it loops arguments 1..n and applies the *same* label to every GUID
  (loop `0x005CEAC4`–`0x005CEB04`, re-entering `FUN_0059FF50` per arg). `RemoveLabel` mirrors it.
  That is a real API shape a reimpl must match.
- The label hash goes in the **`subKey`** slot, and `FUN_00649180`'s flag-bit-0 path searches by
  subKey before inserting — so `(guid, label)` pairs are a set, not a bag.
- Removal is container vtable **`+0x70`**`(guid, labelHash)`.
- Query is **`FUN_00649440(container, guid, hash)`**, the multi-key probe — `HasLabel` `0x005CEE40`
  (218 B) is a thin wrapper over it returning a boolean. **Now read; the old map declined to assert
  its behaviour.**
- **The engine uses this container for its own labels too.** Two engine-side literals, both now
  shown to be genuine `Label` subKeys:
  - `0xE60C6CA2` — inserted at `0x005A8F99: 68 A2 6C 0C E6  push 0xe60c6ca2` /
    `0x005A8FA1: push 0xdf8108` / `call 0x649180`; queried at `0x00578780` via `FUN_00649440`.
  - `0xFAF6DA61` — inserted at `0x005BE6AD` / `push 0xdf8108` / `call 0x649180`; removed at
    `0x005BE6D6` through vtable `+0x70`.

  Both preimages are still **unresolved** — see §8.5 for exactly what was swept.

### 4.3 `AddToDisposer` is the reserved label `"disposable"` — H

```
005D29B9  68 6B 73 56 F9        push 0xf956736b            ; subKey
005D29C1  68 08 81 DF 00        push 0xdf8108              ; the Label container
005D29C6  C7 44 24 2C 6B 73 56 F9  mov [esp+0x2c], 0xf956736b   ; the VALUE local, same hash
005D29CE  E8 AD 67 07 00        call 0x649180
005D29D7  A1 0C 3B ED 00        mov eax, [0xed3b0c]
005D29DD  E8 4E 13 F2 FF        call 0x4f3d30              ; ★ extra call AddLabel does not make
005D29E4  33 C0 / C3            xor eax, eax; ret          ; ★ ZERO Lua return values
```

`pandemic_hash_m2("disposable") == 0xF956736B` — **recomputed exactly** with the verified M2 hash
(FNV-1a, case-suppressed via `|0x20`, `^0x2A` then `*prime`; the same function that yields
`pandemic_hash_m2("texture") == 0xF011157A`). So the "disposer" is not a separate system: it is a
**label the cleanup pass scans for**. `RemoveFromDisposer` does vtable `+0x70`(guid, `0xF956736B`)
plus `thunk_FUN_024EBD20(DAT_00ED3B0C)` — the scheduler side, not modelled here.

> **But `AddToDisposer` is NOT `AddLabel(guid, "disposable")`.** They differ in two observable ways:
> `AddLabel` is **variadic** and **pushes a boolean** (`0x005CEB7D: mov [eax],1` /
> `0x005CEB85: mov [eax+4],1`); `AddToDisposer` takes **one** GUID and returns **zero** values, and
> makes the extra `FUN_004F3D30(lifetime)` call. §7.5 of an earlier revision stated the shorthand
> equality as reimpl guidance; a reimpl following it literally gets the return arity wrong. The
> shared fact — **`Object.AddLabel(uGuid, "disposable")` and `Object.AddToDisposer(uGuid, n)` write
> the same container row** — is still true and still a directly useful modding fact.

### 4.4 `AreEqual` and `IsValid` touch no engine state — H

`AreEqual` `FUN_005CE320` (424 B, 148 instructions) is pure Lua-stack work: it reads slot 1, accepts
tag **2** (lightuserdata) or tag **7** (table, using `*ptr + 0x18` as the identity), then compares
every remaining argument's lightuserdata against it. Its **complete** call set is
`{FUN_0059FF50, FUN_0085D5D0}` — argument fetch and stack push. Its size is an inlined variadic loop,
not engine work. (0 script call sites — it exists for the C++ side.)

**`Object.IsValid` `0x005CDF60` (132 B) is the same shape, and this matters more.** Its complete
engine footprint is nil: it bounds-checks the Lua stack, falls back to the shared TValue at
`0x00B9228C`, then `0x005CDF9F: cmp eax, 7` / `0x005CDFA4: cmp eax, 2` and pushes a boolean. **It
does not ask whether the entity exists.** A reimpl that makes `IsValid` a liveness query diverges
from retail on all 2 of its call sites. `IsTemplate` `0x005CBD20` is likewise pure — its entire
payload is `setl` on `guid < 0`, i.e. bit 31.

---

## 5. Health, life and death

### 5.1 The `RuntimeHealth` record is `{max, current}` — H, settled three ways

Container **`0x017BEF78` = `RuntimeHealth`** (id 234, hash `0xF9B9B2A5`, **stride 12**, cap 256).

| cfunc | decisive instruction | reads / writes |
|---|---|---|
| `GetMaxHealth` `0x005CC030` | `0x005CC09E: B9 78 EF 7B 01  mov ecx, 0x17bef78` → `0x005CC0AC: F3 0F 10 00  movss xmm0, [eax]` | **`+0x00`** |
| `GetHealth` `0x005CBDB0` | `0x005CBE1F: B9 78 EF 7B 01  mov ecx, 0x17bef78` → `0x005CBE2D: F3 0F 10 40 04  movss xmm0, [eax+4]` | **`+0x04`** |
| `SetHealth` `0x005CBEE0` | `0x005CBF8F: mov ecx, 0x17bef78`; clamps against `[esi]`, `0x005CBFE9: F3 0F 11 46 04  movss [esi+4], xmm0` | ceiling `+0x00`, written `+0x04` |

```c
pf = (float*)FUN_005857E0();                         // ecx = 0x017BEF78
if (pf == NULL) return FUN_004B2A50();               // hard Lua error, not nil
if (pf[0] == pf[1] && newHp < pf[1]) FUN_00665BE0(); // ★ "damaged from full" notify
newHp = (newHp < 0.0) ? 0.0 : min(newHp, pf[0]);     // clamp to [0, max]
pf[1] = newHp;
```

✅ **`{ +0x00: f32 max, +0x04: f32 current }` — three mutually-corroborating readings, no breakpoint.**
`object_assembly_model.md` §2 said `{cur, max}` and **has been corrected**, along with five sibling
docs that had copied it (`mercs2-ecs/07_gameplay_state_health_mission.md`, `mercs2-ecs/README.md`,
`ecs_reflection_registry_code_map.md`, `state_machine_destruction_code_map.md`,
`weapons_combat_code_map.md`). Verified still corrected as of this pass.

- **The record is 12 bytes, so `+0x08` is a third field no document identifies.** That is what
  remains open, not the ordering — §8.6.
- The **full-health→damaged edge fires a dedicated notify**, `FUN_00665BE0` (the map previously
  named it by its thunk, `thunk_FUN_028D1000`). That is the hook a "first hit" reaction (AI alert,
  HUD flash) would hang off.
- Missing component is an **error**, not a nil return (`0x005CC01B: call 0x4b2a50`) —
  `Object.SetHealth` on a healthless object raises in Lua.

### 5.2 `GetNodeHealth` — per-node health is a **u16** — H

```
005CC1D8  B9 C8 EF 7B 01     mov   ecx, 0x17befc8      ; RuntimeNodeHealth (id 235, stride 4)
005CC1E3  E8 ..              call  0x5857e0
005CC1EC  8B 38              mov   edi, [eax]          ; embedded pointer to the node table
005CC1F6  E8 ..              call  0x435140            ; lookup node by name-hash arg
005CC1FF  0F B7 40 06        movzx eax, word ptr [eax + 6]   ; ★ u16 at node+0x06
005CC203  F3 0F 2A C0        cvtsi2ss xmm0, eax              ; INTEGER widening
```

`cvtsi2ss` is an integer conversion, so this cannot be a float reinterpretation.
[`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md) §2 described
`RuntimeNodeHealth (0x76927BF5)` as "one **float** per destructible node" — wrong on storage, and
corrected. The container stride of **4** is consistent: the container holds a 4-byte handle per
entity and the per-node `u16`s live in the pointed-to node table, so "one value per destructible
node" is right about *cardinality* and wrong about *type and location*. Promoted from **M** to **H**.
Destruction semantics belong to
[`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md).

### 5.3 `Kill` posts a message; it does not kill — H

```
005CDF26  8B 4C 24 08     mov  ecx, [esp+8]        ; guid
005CDF2A  33 C0           xor  eax, eax
005CDF30  89 4C 24 0C     mov  [esp+0x0c], ecx     ; word 0 = guid
005CDF34  89 44 24 10     mov  [esp+0x10], eax     ; word 1 = 0   ← NOT a repeat of the guid
005CDF38  89 44 24 14     mov  [esp+0x14], eax     ; word 2 = 0
005CDF3C  88 44 24 18     mov  byte [esp+0x18], al
005CDF40  88 44 24 19     mov  byte [esp+0x19], al
005CDF44  E8 17 DF E5 FF  call 0x42be60            ; post
005CDF4A  33 C0           xor  eax, eax            ; ★ pushes no result
```

> ⚠ **Corrected.** The old map showed the message as `{ guid, guid, 0, 0, 0, 0 }`. The second dword
> is **0**. The record is `{u32 guid, u32 0, u32 0, u8 0, u8 0}`.

`FUN_0042BE60` (144 B, 40+ callers) is the **message-bus post**: a bounded **0x400-entry** queue at
`DAT_011B51A8` (16-byte entries via two `movq`s), a per-channel bit-population counter at
`DAT_011B5128`, guarded by critical section `DAT_011BA1B0` and gated on `DAT_011BA1A8`.

> ⚠ **Terminology corrected: it is not a ring.** There is no modulo and no wrap anywhere in the
> function. `0x0042BE8E: 3D 00 04 00 00  cmp eax, 0x400` / `0x0042BE93: 7D 4F  jge 0x42bee4` jumps
> **straight to `LeaveCriticalSection`**. The index only ever increments, so a full buffer **drops
> the newest** entry — a ring would overwrite the oldest. (A near-identical sibling queue at
> `0x0042BEF0` uses a bound of `0x80`.)

So `Object.Kill` is **asynchronous and lossy under saturation**, and returns nothing. This is the
producer side of the damage-message path
[`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) §3.4 describes
(drained by `FUN_0059BE00` → `SetStateOnMsg`). A reimpl that makes `Object.Kill` synchronous will get
ordering wrong on scripts that kill and immediately query.

### 5.4 Invincibility is two independent flags on `RtDamageFlags` — H

`GetInvincible` `FUN_005CE4D0` resolves **`RtDamageFlags`** (`0x017C0238`, id 310, stride 4) and
branches on an optional second argument:
- no arg → `*(i16*)(rec + 2) != 0`;
- with arg → `FUN_00526220()` and masks the returned pair.

`SetInvincible` `FUN_005CE5E0` → `FUN_00526220` + `FUN_005263A0`; `SetUnkillable` `FUN_005CE6E0` →
`FUN_00526220` + `FUN_00526450`. **Two distinct setters against the same `FUN_00526220` resolver** —
"invincible" (takes no damage) and "unkillable" (damage applies but health floors above 0) are
separate bits. The container's **stride of 4** and its name independently support the reading that
these are **two bits in one damage-flags word**, not two components. Promoted from **M** to **H**.
`SetInvincible` has 35 call sites, `SetUnkillable` 3. (The player-attach worker clears bits here too:
`0x006A40A8: and word ptr [eax+2], 0xfffe` / `0x006A40AE: and word ptr [eax], 0xfffe`.)

### 5.5 "Alive" is not `health > 0` — there is a dead latch on `SceneObject` — H

`Object.IsAlive` (139 calls, the 2nd-busiest binding) reads three containers in order:

```
005CD92E  B9 78 EF 7B 01     mov ecx, 0x17bef78         ; RuntimeHealth
005CD93C  F3 0F 10 40 04     movss xmm0, [eax+4]        ; current
005CD941  0F 2F 05 EC 7E B9 00  comiss xmm0, [0xb97eec]  ; ★ [0x00B97EEC] = 0.01f, NOT zero
005CD948  76 10              jbe  -> false
005CD973  B9 58 BF 7B 01     mov ecx, 0x17bbf58         ; Health (id 5) fallback
005CD990  B9 D8 02 7C 01     mov ecx, 0x17c02d8         ; SceneObject
005CD99E  0F B6 48 1A        movzx ecx, byte ptr [eax + 0x1a]
005CD9A2  F6 D1              not  cl                    ; ★ result = NOT bit 0
```

`Object.GetHealth` tests the same byte (`0x005CBEAE: F6 40 1A 01  test byte ptr [eax+0x1a], 1`) and
returns **0.0** when it is set, regardless of the stored value. `Object.Revive` clears it:
`0x005CE266: 80 60 1A FE  and byte ptr [eax+0x1a], 0xfe`, after writing
`0x005CE24D: movss [eax+4], xmm0` on `RuntimeHealth` and touching `HumanStateMachine`
(`0x005CE26B: B9 90 99 DF 00  mov ecx, 0xdf9990`).

**So `SceneObject+0x1A` bit 0 is an explicit DEAD flag**, the aliveness threshold is `0.01f` rather
than zero, and `Object.Revive` is a two-part operation (restore health *and* clear the latch). A
reimpl modelling `IsAlive` as `hp > 0` will resurrect corpses. This section is new — the old map
said only *"`IsAlive`, `Revive` and `GetHealth` are all binding-only — the read side of this system
is unrecovered."*

---

## 6. Space, physics, attachment, visibility

### 6.1 Physics is a *handle*, not a component — H

`FUN_00432740` (thunk → `FUN_004B1131`) maps a GUID to a **physics-body object**, and every physics
cfunc then dispatches through *its* vtable — e.g. `GetVelocity`:

```c
if ((body = FUN_00432740()) != NULL) {
    v = (float*)(**(code**)(*body + 0x4C))(buf);          // linear velocity vec3
    return push(sqrt(v.x*v.x + v.y*v.y + v.z*v.z));
}
if ((c = FUN_005857E0()) != 0) return push(*(float*)(c + 8));   // ★ ControllerVelocity +0x8
return FUN_004B2A50();                                          // else Lua error
```

**Two paths.** An object without a Havok body still answers `GetVelocity` from a cached float at
`ControllerVelocity+0x8` (`0x017BCB38`, id 65, stride 24). `GetVelocitySquared`, `GetVelocityVector`,
`SetMass`, `ApplyImpulse`, `ApplyPointImpulse`, `ApplyAngularImpulse` and `IsWinched` all take the
`FUN_00432740` route. The body itself belongs to [`physics_code_map.md`](physics_code_map.md).

**`EnablePhysics`/`DisablePhysics`/`GetPhysicsType` — the old map's hypothesis, now read.** It said
*"their adjacency says they are one-liners over the same handle; that is a hypothesis, not a
reading."* Confirmed by 32 bytes:

```
005D0740  8B 44 24 04 / 6A 01 / 50 / E8 04 FF FF FF / 83 C4 08 / C3   ; EnablePhysics  = FUN_005D0650(guid, 1)
005D0750  8B 44 24 04 / 6A 00 / 50 / E8 F4 FE FF FF / 83 C4 08 / C3   ; DisablePhysics = FUN_005D0650(guid, 0)
```

Both are **16 bytes**. `GetPhysicsType` `0x005D0760` is the opposite extreme — **1128 B, 407
instructions**, a switch that probes five physics pools in turn: `_CarPhysicsV2` (`0x017BC278`),
`_TankPhysics`, `_HelicopterPhysics`, `_BoatPhysics`, `_HumanPhysics`. 43 call sites' worth of
traffic settled without a debugger.

### 6.2 Hardpoints — H

`FUN_006886A0` (an indirect jump through `_DAT_0245A084`) resolves a **hardpoint name-hash** and is
gated as `0 < FUN_006886A0(hash)`. Used by `GetHardpointPosition`/`Yaw`/`Pitch`, `Attach`,
`SetPositionToObject`, `SetTransformToObject`. Where a hardpoint is supplied,
`SetTransformToObject` takes a *different* branch (`FUN_008231D0` matrix compose) than the plain
transform copy — i.e. "snap to object" and "snap to object's hardpoint" are separate code paths.
Hardpoint naming is already covered by [`dialect_hardpoints.md`](dialect_hardpoints.md).

### 6.3 Attachment — `RuntimePhysicalLink` `0x00DF9110` — H

```c
// Attach(child, hardpointName, parent)
if (parent < 0) { FUN_008244D0(); FUN_006746D0(PTR_PTR_01176108, parent, buf, &parent, 0, 0); }  // template deref
FUN_0042C1E0(DAT_017BAEF3);
FUN_00824790();
FUN_00649180(&PTR_PTR_00DF9110, child, parent, parent, &{hardpointHash, parent});
```

- A **negative GUID is a template handle** and is dereferenced through `PTR_PTR_01176108` before use
  — consistent with `object_assembly_model.md` §3's "value bit-31 = template handle", and
  independently corroborated by `Object.IsTemplate` being literally `guid < 0`. **H.**
- `IsAttached`/`Detach` probe the container's **index 2** (`+0x50`) and read `+0x44`;
  `GetAttachedObjects` **iterates** and pushes `container+0x60[i]` (the index-2 key) as a
  lightuserdata per attached object. That asymmetry is what identifies `+0x44` as the *owner* and
  `+0x60` as the *attached* GUID. Now that both are known to be **hash-index key arrays** (§1.2), the
  reading is structural rather than positional. Promoted from **M** to **H**.

### 6.4 Visibility is an inverted bit — and `IsVisible` is not a frustum test — H

```
005D0448  E8 13 98 07 00        call 0x649c60                  ; resolve -> [rec + 0x34]
005D0478  80 7C 24 1C 00        cmp  byte ptr [esp+0x1c], 0    ; the Lua bool argument
005D047F  66 81 60 10 FE FF     and  word ptr [eax+0x10], 0xfffe   ; visible=TRUE  -> CLEAR bit 0
005D0487  66 09 58 10           or   word ptr [eax+0x10], bx       ; visible=FALSE -> SET   bit 0 (bx==1)
```

The polarity is **inverted** — bit 0 of the u16 at `rec+0x10` means *hidden*. Getting this backwards
produces a world that renders exactly wrong. Note `FUN_00649C60` does not return the record: it
returns **`[record + 0x34]`**, an embedded pointer, and `word[+0x10]` is a field of *that* object.
There is also a one-shot latch `DAT_0198E180 |= 1` on first scripted use.

`IsVisible` `FUN_005D04C0` asks a completely different question. It resolves `SceneObject`, calls
`FUN_00665AF0`, pre-gates on a **different field** (`0x005D05B5: 66 81 E2 00 30  and dx, 0x3000`,
requiring `== 0x2000`, otherwise returning **true**), then runs the camera (`FUN_0070F640`),
`FUN_00665BB0` and `FUN_00424770`, and compares the result to
`0x005D061B: 0F 2F 05 28 B5 BE 00  comiss xmm0, [0xbeb528]` where `[0x00BEB528] = 0.0005f`.

> ⚠ **Corrected.** The old map called `IsVisible` a **"frustum/occlusion query"**. `FUN_00424770`,
> read in full, is neither a frustum nor a plane test:
> ```
> 00424770  xorps xmm0, xmm0                  ; acc = 0.0
> 00424780  cmp  [ebp], esi / jle done        ; n = list count
> 00424790  lea  edi, [ebp + 0x10]            ; items
> 00424793  mov  eax, [ebx] / mov edx, [eax+4]; virtual method at vtable +0x04
> 00424799  fstp dword ptr [esp]              ; push acc as an argument
> 0042479F  call edx
> 004247A1  fst  dword ptr [esp + 0x18]       ; acc = returned float
> 004247A8  add  edi, 0x50                    ; next item (0x50 stride)
> 004247AB  cmp  esi, [ebp] / jl loop
> ```
> It is an **accumulator fold**: `acc = 0; for each of n items (0x50 stride): acc = obj->vf04(item,
> acc); return acc`. A frustum test returns a boolean or a signed plane distance; it does not fold a
> float across a list and threshold at 5·10⁻⁴. The "occlusion" half stands: `IsVisible` is best
> described as **"is at least 0.05 % of this object visible?"** — which also explains why the
> `word[+0x18] & 0x3000` pre-gate returns *true* for objects outside the tested class.
> **`IsVisible` is still not the inverse of `SetVisible`** — different field, different question.

### 6.5 `IsAwake` reads a 2-bit state field on `SceneObject` — H (read) / M (semantics)

```c
bVar6 = (*(u16*)(rec + 0x18) & 0x3000) == 0x2000;     // awake
if (levelArg != -1 && bVar6) {
    node = FUN_004352B0();
    return (int)(*(u16*)(node + 0x16) >> 6 & 7) <= levelArg;    // 3-bit LOD/tier compare
}
return bVar6;
```

A **2-bit lifecycle field at bits 12–13** of `SceneObject+0x18`, awake == `0b10` — the *same* field
`IsVisible` pre-gates on. With the optional second argument it further compares a **3-bit tier at
bits 6–8** of a node record. `IsAwake` also touches `ModelName`. Hibernation policy is
[`world_streaming_code_map.md`](world_streaming_code_map.md)'s; this is only where the script-visible
bits live.

### 6.6 Gates — `RtPoweredGate` `0x00DF9890` — H

`OpenGate`/`CloseGate` **iterate the whole container** (`FUN_006499F0` / `FUN_00649A80`) rather than
doing a keyed lookup, and `OpenGate` early-outs on `*(char*)(DAT_0117504C + 0x23B0) != 0` — a global
gate-lock. 15 + 10 call sites. The per-record work is `FUN_004103E0`.

### 6.7 `Remove` is a five-way disposal decision — H (shape) / L (semantics)

`FUN_005CDC00` (305 B, 83 call sites) is the busiest non-getter. It classifies the GUID by **bit
pattern** before choosing a destroyer:

| Test | Instruction | Route |
|---|---|---|
| `guid < 0` (template handle) | `0x005CDC94: 7C 57  jl` | `thunk_FUN_024E4FB0` → `thunk_FUN_024E40E0` |
| `guid != 0 && (guid & 0xC0000000) == 0` and `FUN_006B2EC0()` | `0x005CDC98: F7 C7 00 00 00 C0  test edi, 0xc0000000` | same |
| `DAT_00DFBD77 != 0` and `(guid & 0xF0000000) == 0x40000000` and `thunk_FUN_0052025A() != -1` | `0x005CDCAB` guard; `0x005CDCB6/BC: and edx,0xf0000000 / cmp edx,0x40000000` | same |
| `thunk_FUN_024E8BF0()` or `FUN_006CD880()` | — | same |
| else, with the optional bool arg set | — | `thunk_FUN_024EBD80` |
| else | — | `thunk_FUN_024E8250(0)` |

**The GUID's top nibble is a type tag** (`0x4` is one class; bit 31 is the template flag) — that is a
reusable fact, and bit 31 = template is independently corroborated by `IsTemplate`. `DAT_00DFBD77` is
the same teardown guard `Player.RemoveBoundary` early-outs on
([`player_code_map.md`](player_code_map.md) §7). The destroyers are behind split thunks. `Remove`
**returns nothing** in every branch.

### 6.8 `IsPlayerControlled` joins **two** containers — H

```
005CE065  BE E0 9B DF 00   mov  esi, 0xdf9be0          ; ★ Players + 0x50  (hash index 2)
005CE06A  E8 ..            call 0x648d80
005CE073  [0xdf9bf4] = Players+0x64 (slots) ; [0xdf9bd4] = Players+0x44 (keys)
005CE099  [0xdf9ba8] = Players+0x18 (live count) — bounds the scan
005CE0B6  [0xdf9bb0]=+0x20 mask · [0xdf9bb4]=+0x24 stride (movsx word) · [0xdf9bb6]=+0x26 shift · [0xdf9c00]=+0x70 pages
005CE0DC  8B 40 24         mov  eax, [eax + 0x24]      ; ★ player+0x24 = CONTROLLED OBJECT
005CE0E7  BE D8 81 DF 00   mov  esi, 0xdf81d8          ; ★ SeatLink + 0x50 (hash index 2)
005CE0F9  [0xdf81ec] = SeatLink+0x64 ; [0xdf81cc] = SeatLink+0x44
005CE10B  cmp [esp+0x14], eax / je -> true
```

> ⚠ **Corrected.** The old map's heading was *"the one cfunc that joins **three** containers"*. It is
> **two** — `Players` (id 312) and `SeatLink` (id 124). The "three" counted three *probes*: an
> initial `Players` probe, the `Players` scan, then `SeatLink`. Every global the old map cited is
> correct; only the count is not. Also new: **both probes target hash index 2** (`+0x50`), which the
> old map did not distinguish.

Two independent confirmations of the player map still fall out: the scan globals
`DAT_00DF9BA8/BB0/BB4/BB6/C00` are byte-for-byte
[`player_code_map.md`](player_code_map.md) §2.1's player container, and `0x00DF8188` is its
`ClaimSeat` container.

**`player+0x24` is the *controlled object*, not the character — settled.** Re-reading `FUN_006A4060`
(the attach worker) first-hand:

```
006A422E  89 43 20         mov [ebx + 0x20],  eax   ; the CHARACTER guid (attach arg)
006A4279  89 7B 24         mov [ebx + 0x24],  edi   ; edi == 0 (xor edi,edi at 0x006A417C) — CLEARED
006A4314  89 83 A8 03 00 00  mov [ebx + 0x3a8], eax ; cached copy of the character
```

So `+0x20` = attached character · **`+0x24` = the currently-controlled object** (the ridden vehicle,
else 0) · `+0x3A8` = cached character. That is exactly why `Player.GetCharacter` and
`Player.GetControlledObject` are separate bindings. Cross-checked with
[`player_code_map.md`](player_code_map.md) §2.2, which records all three. **H.**

Semantically: an object is "player controlled" if it is directly marked, **or** if it is the object
any player is currently *controlling* — i.e. the query answers **"is this vehicle player-driven?"**,
not "is this the player's character". With 74 call sites that distinction matters: scripts use it to
exclude the player's ride from AI/cleanup passes, not to find the hero.

**Remaining confirm-live (§8.7):** nothing statically located ever sets `+0x24` to **non-zero**.

### 6.9 `0x00DF9B10` is `CheatInfiniteAmmo`, its element is **one byte**, and both writers are cheat-gated — H

The container names itself **`CheatInfiniteAmmo`** (id 311, hash `0x989C4290`) via `[vtable+0x34]`,
and its static descriptor is **stride `1`, capacity `128`** — cross-checked against
`docs/game_config/cdbsizes.ini`, which budgets `CheatInfiniteAmmo 256 128`.

> ⚠ **A retraction that was itself wrong, corrected in the open.** An earlier revision named this
> container after `SetInfiniteAmmo`, then **retracted** that as "overreach" and re-labelled it *"a
> shared per-entity flag container whose element layout is undecoded … at least two unrelated
> features share it"*, adding §8.11 (*"read `container+0x24` (stride) live; if the element is one
> byte they clobber each other and that is a **shipped bug**"*). **The engine's own name is the
> cheat.** The original name was right; the retraction was the error, and it was already stale
> relative to [`player_code_map.md`](player_code_map.md), which had named it by the same method.
> The map's *"more likely the element is a small struct and the two zero arguments select a field"*
> is **contradicted** — stride is literally 1.

The `0x00DF9B10` user list was also badly undercounted: an earlier revision said *"those are the
container's only non-ctor users"* (three writers). A byte-scan of `.text` for the literal dword
`10 9B DF 00` finds **20** references:
`0x4C5382, 0x4C538D, 0x51A2D1, 0x51AF0B, 0x51DD4B, 0x51E237, 0x51F580, 0x51F60D, 0x52D8D5, 0x585878,
0x5CE89E, 0x5CE8B8, 0x5CE8C1, 0x66B768, 0x6A4083, 0x6A408B, 0x6A416E, 0xA7C7A1, 0xA7C7B8, 0xB03211`.
A `PTR_PTR_` symbol sweep over the Ghidra text cannot see most of them.

**Both writers store the same value, and both are gated on the cheat bank at `0x01175F59…0x01175F5C`:**

```
Object.SetInfiniteAmmo  0x005CE7E0:
  005CE86D  80 3D 5C 5F 17 01 00   cmp byte ptr [0x1175f5c], 0   ; cheat flag
  005CE878  74 15                  je  0x5ce88f                  ; flag clear -> plain bool path
  005CE87C  E8 .. (call 0x6cdaf0)  / 005CE888  8B 40 20  mov eax,[eax+0x20]   ; player CHARACTER guid
  005CE88B  3B F0 / 74 04          cmp esi, eax / je force-insert            ; target IS the player -> insert regardless
  005CE89D  68 10 9B DF 00         push 0xdf9b10
  005CE8A2  C6 44 24 30 01         mov byte ptr [esp+0x30], 1    ; ★ payload byte = 1, key2 = subKey = 0
  005CE8A7  E8 D4 A8 07 00         call 0x649180
  005CE8B7  (false path) mov eax,[0xdf9b10]; mov edx,[eax+0x64]; ecx=0xdf9b10; call edx   ; virtual ERASE

player attach  0x006A4060:
  006A4083  ...vtable +0x64 ERASE for the PREVIOUSLY-controlled guid
  006A414F  80 3D 5C 5F 17 01 00   cmp byte ptr [0x1175f5c], 0   ; \  DAT_01175F5C || DAT_01175F59
  006A4156  75 09                  jne 0x6a4161                  ;  |
  006A4158  80 3D 59 5F 17 01 00   cmp byte ptr [0x1175f59], 0   ; /
  006A415F  74 1B                  je  0x6a417c                  ; skip the insert entirely
  006A4172  C6 44 24 23 01         mov byte ptr [esp+0x23], 1    ; ★ identical payload
  006A4177  E8 04 50 FA FF         call 0x649180
```

**Consequences, stated precisely.**
- The two features do **not** corrupt each other's payload — they write the same byte with the same
  keys. The old map's predicted collision (*"granting infinite ammo would drop player control"*) is
  **dead**.
- The real hazard is the **erase**: the row is unkeyed, so the player-attach path's vtable `+0x64`
  erase at `0x006A4083` can silently revoke a script-installed `SetInfiniteAmmo` when control moves
  off the object — the *opposite* direction from the one the old map predicted.
- And that scenario requires the **cheat flags to be live**, so it is a cheat-system interaction, not
  a general entity-marker collision. Not a shipped bug in normal play.
- `SetInfiniteAmmo` special-cases the player: when the cheat flag is set and the target GUID equals
  the player's **character** (`player+0x20`), it inserts regardless of the boolean argument.

---

## 7. What this map settles for `mercs2_core` / `mercs2_script` (the reimpl)

`tools/wad_simulator/crates/mercs2_script/src/bindings/object.rs` holds all 87 `Required` names with
`install` unfilled (read-only this pass; another agent owns that tree). The engine's answer to the
design questions that crate faces:

1. **Retail is table-per-component-type keyed by GUID, not entity→component-list.** **334** paged
   containers in **two classes with different descriptor layouts** (§1.2) — a reimpl told "one
   templated container type instantiated 102 times" will model the wrong thing. The Rust `World`
   (hecs archetype ECS) is a *different* shape. That is fine — but the **GUID must be the stable
   key**, and `Object.*` must resolve `guid → component`, never `guid → entity → component`, or the
   alias fallback in §1.3 (a GUID resolving through a *source* GUID) has nowhere to live.
2. **Component identity is the name, and the names are all recovered** (§10). Use them; do not invent
   component names, and do not treat `Transform` as a component — retail has `RuntimeSceneObject`.
3. **`Object.GetPosition` is the single hottest binding in the game (201 sites).** It already works
   against the live transform in `script_host.rs`
   (`object_get_position_reflects_a_live_world_move`) — that is the right shape. Add: the **change
   serial** (record dword 3) and the **fallback path** through `SceneObject` when no
   `RuntimeSceneObject` record exists.
4. **`SetPosition` must notify the world.** Retail commits then calls world vtable `+0x84`/`+0x88`
   behind the `vtable+0xE0() == 1` gate (§2). A bare component write is not faithful.
5. **`Object.Kill` must be a queued message, not a direct kill** (§5.3), must push **no** return
   value, and must **drop the newest** on overflow, not overwrite the oldest.
6. **`AddLabel` is variadic over GUIDs and returns a boolean; `AddToDisposer` takes one GUID and
   returns nothing.** They write the same `(guid, 0xF956736B)` row, but they are **not** the same
   call (§4.3). Implementing the disposer as its own list would diverge on `HasLabel("disposable")`.
7. **`SetVisible`'s bit is inverted, and `IsVisible` is a coverage fold thresholded at 0.0005, not a
   frustum test** (§6.4).
8. **Health is `{max, cur}`, clamped to `[0, max]`, full→damaged fires an edge notify, and a missing
   component is a Lua error** (§5.1). **And "alive" is not `hp > 0`** — there is a dead latch at
   `SceneObject+0x1A` bit 0 and the threshold is `0.01f` (§5.5). The
   `health_binding_shares_the_combat_health_component` test in `script_host.rs` already has the right
   sharing invariant; the clamp, the edge notify, the error-on-missing-component and the death latch
   are missing.
9. **`AreEqual`, `IsValid` and `IsTemplate` are host-level, not engine queries** (§4.4). `IsValid` in
   particular must **not** become "does this entity exist?".
10. **`EnablePhysics`/`DisablePhysics` are one shared worker with a bool** (§6.1) — 43 call sites for
    32 bytes of code.

---

## 8. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]); never put a
conditional breakpoint on a per-frame function ([[x32dbg-mcp-pitfalls]]). Prefer one-shot breakpoints
and HW-write watchpoints.

**Closed this pass** — recorded so nobody re-opens them:

| was | now |
|---|---|
| §8.1 "name the other 93 containers" (proposed a static-init breakpoint) | **CLOSED** — all **334** named statically via the `[vtable+0x34]` master key; census in §10 |
| §8.2 "resolve `FUN_005857E0`'s container per call site" (proposed a breakpoint, est. ~20 rows) | **CLOSED** — **55** cfuncs, 29 containers, from `mov ecx, imm32` in the raw bytes (§3.1) |
| §8.6 the `{max,cur}` vs `{cur,max}` conflict, and node-health type | **CLOSED** — `{max, cur}`, node health u16; siblings corrected. Only `RuntimeHealth+0x08` remains (below) |
| §8.8 "recover the 24 binding-only bodies via the forcing-script pass" | **CLOSED** — ceiling is **87/87**; all 24 disassemble from the same image; no forcing pass needed |
| §8.11 "`0x00DF9B10`'s element layout — read `container+0x24` live" | **CLOSED statically** — `CheatInfiniteAmmo`, stride **1**, cap 128; and the third writer `FUN_0066B710` is one of **20** references (§6.9) |
| "is the container capacity/stride/page-shift table all zero statically?" | **CLOSED, with a split** — in the live dump all 334 are populated and `cap == 2^shift` verifies 334/334 (§1.2). On disk only the `0x80` class's **stride** is static; capacities are boot-written from `cdbsizes.ini` (§1.2.1) |
| "is `FUN_00424770` a frustum test?" | **CLOSED** — no; an accumulator fold over a `0x50`-stride list via vtable `+0x04` (§6.4) |
| "do the two arrays share one type-id space?" | **CLOSED** — one space, proven by arithmetic *and* by `FUN_0064A770`'s mechanism (§1.1) |

**Still open:**

1. **`RuntimeHealth+0x08` — the third dword.** The record is 12 bytes; `+0x00` (max) and `+0x04`
   (cur) are settled, `+0x08` is unidentified and no document records it. **73 `.text` sites**
   reference `0x017BEF78`; sweeping them is static, tractable and not yet done. Recipe: byte-scan
   `.text` for `78 EF 7B 01`, disassemble ±0x60 around each hit, and collect every `[reg+8]`
   access on the returned pointer.
2. **`FUN_00665590(guid, id)`** — the cross-registration hook `FUN_00649180` fires when
   `DAT_00CFB58A` is set and `container+0x04 >= 0`. What consumes it? If it is a component-added
   event bus, it is the hook a reimpl needs for reactive systems. **Static, not attempted.**
3. **`Object.SetName`'s string** — the decompiled body overwrites the local with `"Unknown"` before
   the add and passes the Lua value as `key2`. `Name`'s stride of **4** rules out an inline string
   but does not distinguish hash from pointer. Break `FUN_005CCAF0`, call
   `Object.SetName(uGuid, "Foo")`, and read what lands in the record (§4.1).
4. **The two engine label hashes `0xE60C6CA2` and `0xFAF6DA61`.** Both are now *proven* to be `Label`
   subKeys (§4.2), and both preimages are unknown. **Ruled out this pass:** all 334 container names,
   plus **23,845** distinct ASCII strings extracted from `.rdata` and `.data` — none hashes to
   either value under `pandemic_hash_m2`. Next: the `docs/reverse_engineer/naming_dialect_*.md`
   vocabularies, the Xbox PDB symbol strings, and the `vz.wad` string tables.
5. **`player+0x24`'s non-zero setter.** Nothing statically located ever sets it to non-zero — the
   only located write is the clear-on-attach at `0x006A4279`, and `0x0069FEA7` is the player-struct
   constructor zeroing it. The one shape-matching candidate is **`FUN_006AA7C0`**
   (`0x006AA805: cmp eax, [esi+0x20]` pairs with `0x006AA893: mov [esi+0x24], ecx`, and it resolves
   `EntranceParameters`), but it has **zero static callers** because it is a virtual method — whether
   its `esi` is the player struct is decided at the indirect call site. *Runtime recipe:* HW-write
   watchpoint on `player+0x24` (player base via `FUN_006CDAF0(0)`), then drive into a vehicle; when
   it fires, walk the call stack — expect `0x006AA893`. Until then the "ridden vehicle" reading is
   best-supported, not proven.
6. **`RuntimeSceneObject+0x20 … +0x37`.** The record is 56 bytes and `FUN_00665AF0` copies only the
   first 32. The remaining 24 bytes are untouched by the transform read and undecoded (§2).
7. **`FUN_0064A5C0` — the slow-path fallback record.** Not a wall
   ([[securom-decompiled-not-a-blocker]]): `0x0064A5C0: jmp dword ptr [0x2458a98]` →
   `[0x02458A98] = 0x024EFA10` → SecuROM's arithmetic-return trick
   (`push 0x1ab7ff8; pushfd; sub [esp+4], 0x80e8; popfd; ret` → **`0x01AAFF10`**, inside `Stext`,
   which the export covers). It chains once more through `jmp dword ptr [0x21FD554]` and was not
   walked to the end. Status: **unfinished, not blocked.** Not needed for any verdict here —
   `FUN_00423DC0` already establishes the `+0x7C` shared zero record.
8. **GUID top-nibble type tags** (§6.7) — enumerate the tag space; likely load-bearing for save/load
   and for any tool that mints GUIDs.
9. **The container-cursor pool is global and lock-guarded** (`DAT_00EDBAA4`). Confirm whether
   `Object.GetAttachedObjects` / `OpenGate` can be called from a non-main thread; if not, the lock
   is vestigial and the reimpl can drop it.
10. **Record *payload* contents remain runtime-only.** Descriptors are static (§1.2), but live counts,
    page-table pointers and the records themselves are zero in the image because pages are
    heap-allocated on first insert. Claims about payloads — e.g. `object_assembly_model.md`'s "value
    bit-31 = template handle" for `Name` records — are still runtime questions.

### 8.A Fix-pack spin-off — `Object.GetInfiniteAmmo` does not exist on retail PC

*(Lettered, not numbered: the numbered §8 references above are the historical item ids, several of
which this pass closes.)*

Three `Object.<X>(` names appear in the Lua corpora that are **not** among the 87: `GetInfiniteAmmo`
(2 call sites + 2 bare references), `GetPos` (1, `mrxharmstrike.lua:59`) and `Delete` (1,
`dlccon004_cash.lua:98`). The first is live logic in the DLC PDA
(`docs/mercs2-dlc-luacd/src/dlc01/dlc01_mrxguipda.lua`) and it is **feature-guarded**:

```lua
132  L0_2 = Object.GetInfiniteAmmo
133  if not L0_2 then
134    return                              -- ← _CheatToggleInfiniteAmmo bails out entirely
135  end
...
510  L2_2 = Object.GetInfiniteAmmo
511  if L2_2 then L2_2 = Object.GetInfiniteAmmo(L0_2) end     -- OnPlayerJoin state sync
```

The retail PC table at `0x00B99608` has no such entry (87, terminator `0x00B998C0`, walked three
times), so **`_CheatToggleInfiniteAmmo` is a silent no-op on retail PC** and the PDA cannot read its
own toggle state on join. The DLC was authored against a build that had the getter. The container is
pinned — `CheatInfiniteAmmo`, stride 1, cap 128, written by `FUN_00649180` and erased by vtable
`+0x64` — which is exactly the shape a `Get`/`Set` pair wants. Route and cost belong to
[`../fixpack/bug_register.md`](../fixpack/bug_register.md); recorded here because this map owns the
binding table.

---

## 9. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`), extracted with a binary-offset index (`fx.py --build`; text-mode seek corrupts on
  Windows). Used for structure and for measuring *its own* coverage — never as the sole authority for
  a fact that a register argument could hide.
- **★ PC raw disassembly (the primary source for this revision):**
  `output/_ghidra/securom_dump/mercs2_unpacked.exe` with `capstone` + `pefile`, VA→file offset via
  the PE section table (map in the header). ⚠ `mercs2_nodrm_v2/v3.exe` are clean rebuilds and
  `genuine_patched_unpacked.exe` is a **different build** — do not mix them; the dump and `v1` carry
  `pmc_bb` hot-patches at `0x005E9DE0`/`0x005E9F40`/`0x006D5640`, none of which is in any range cited
  here. Bodies read first-hand this pass: **all 87 `Object` cfuncs**; the container primitives
  `FUN_00648D80`, `FUN_006496B0`, `FUN_00649180`, `FUN_00423DC0`, `FUN_00649C60`, `FUN_006499F0`,
  `FUN_005857E0`; the registry pair `FUN_0064A770`, `FUN_0064A7E0`; the transform read
  `FUN_00665AF0`; the position worker `FUN_005CCE00`; the quaternion `FUN_00823BC0`; the message post
  `FUN_0042BE60`; the visibility fold `FUN_00424770`; and the player attach worker `FUN_006A4060`.
- **Container census:** a `.data` sweep for
  `{vtable in .rdata, u16@+0x04 == 0xFFFF, [vtable+0x34] == B8 <imm32> C3, target is ASCII}` →
  exactly **334** hits in exactly two runs, 0 false positives, 0 gaps in the id space. Self-check:
  `capacity == 2^page_shift` for **334/334**. Names are the engine's own strings; hashes are
  `pandemic_hash_m2` recomputed over those strings, matching what `FUN_0064A7E0` computes at init
  ([[no-arbitrary-hashes]] — the *name* is the identity; no hash here was invented, and
  [[aset-name-export]]'s warning is respected by requiring the name, the address, the id and the
  using cfunc to agree).
- **Binding table:** `mods/lua_trace_asi/reference/binding_map.json` (live `.rdata` walk,
  [[lua-trace-asi-surface-b-oracle]]) filtered to `table_va == 0x00B99608` — 87/87 — corroborated by
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)'s
  independent offline re-walk and by a third direct `.rdata` walk this pass.
- **★ Script traffic — exact recipe.** Count matches of `\bObject\.(\w+)\s*\(` (the trailing
  open-paren is load-bearing) over **`docs/mercs2-luacd/src/` *and* `docs/mercs2-dlc-luacd/src/`**.
  That reproduces **1272 total** (1056 + 216), **18 names with zero sites**, and every spot-check:
  `GetPosition` 201, `IsAlive` 139, `HasLabel` 117, `Remove` 83, `IsPlayerControlled` 74, `GetYaw`
  50, `GetHealth` 48, `SetInvincible` 35, `Kill` 29, `DisablePhysics` 29, `GetModelName` 0,
  `AreEqual` 0.
  *Two provenance corrections:* an earlier revision said "`corpus_calls` over `docs/mercs2-luacd/`
  (370 scripts)" — that directory **alone** gives 1056, so the DLC corpus was always part of the
  figure and the stated source was incomplete (`object.rs`'s header comment carries the same error).
  And dropping the open-paren requirement gives **1360**, not 1272 — there are 88 further bare
  `Object.X` references (assignments and guards, including the `GetInfiniteAmmo` guard of §8.1).
- **Cross-refs:** [`world_streaming_code_map.md`](world_streaming_code_map.md) (hibernation),
  [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) (death →
  transition), [`weapons_combat_code_map.md`](weapons_combat_code_map.md),
  [`physics_code_map.md`](physics_code_map.md), [`player_code_map.md`](player_code_map.md),
  [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md),
  [`../modernization/object_assembly_model.md`](../modernization/object_assembly_model.md),
  [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md).
- **No Xbox marriage column.** The Xbox PDB carries no `Object`-namespace symbols
  (`docs/mercs2-pdb-analysis/`), so unlike the vehicle/physics rows there is no symmetric join to
  make here; the deliverable is the PC binding table plus the container census.
- **Corrections landed elsewhere, reflected not re-derived:** `mercs2_core::ObjectFilter::add` now
  takes `bExclude` (verified present in `crates/mercs2_core/src/object_filter.rs`); five binding
  namespaces renamed to their registry names (`_GuiInternal`, `LTILibName`, `Junk`,
  `Graphics.FuelTrail`, `Human.Inventory`); `mercs2_script/src/bindings/movie.rs` added; the
  health-ordering corrections are in place in `object_assembly_model.md` and the five siblings.
- Confidence is stated per row. Nothing in this map is asserted from a function name. Where an
  earlier revision was wrong, the wrong claim is quoted in place rather than deleted — including the
  case where it *retracted a correct name* (`CheatInfiniteAmmo`, §6.9).

---

## 10. Appendix — the complete container census (334)

`arr` = storage class: **`0x80`** = `0x00DF6B88 + n·0x80` (102 containers) · **`0x50`** =
`0x017BBF58 + n·0x50` (232). `id` is the engine type id at `container+0x06`, assigned by
`FUN_0064A770` as a running total across both registries — hence the two arrays interleave and the
union tiles `1…334` with no gaps. `name` is the string at `[vtable+0x34]`. `name-hash` is
`pandemic_hash_m2(name)`, matching what `FUN_0064A7E0` writes to `container+0x10` at init.
`stride` and `cap` read from `+0x24` and from `+0x20` (`0x80` class) / `+0x28` (`0x50` class);
`cap == 2^shift` verifies for every row — see §1.2.

> **⚠ Read the `cap` column as *dump-observed*, not as static data — §1.2.1.** These values come from
> `mercs2_unpacked.exe`, which is a **live dump**. On disk (`mercs2_nodrm_v3.exe`) the `0x80` class
> carries a uniform placeholder **`256`** and the `0x50` class reads **`0`**; **276 of the 334
> capacities below differ from the on-disk bytes.** The declared limit is not in `.data` at all — it
> is the **second column of `[presize]` in `docs/game_config/cdbsizes.ini`**, which agrees with every
> one of the 325 rows that join this table (one-column rows keep the 256 default). **Size a reimpl's
> pools from that file, not from this column.**
>
> **`stride` is the citable static fact — but only for the `0x80` class**, where it is byte-identical
> in dump and clean image for all 102. For the `0x50` class the entire descriptor is zero on disk and
> written by the registrar at boot, so its strides below — including `RuntimeHealth` **12** and
> `RuntimeInventory` **0x30**, the two that settle those record sizes — are also dump-observed. They
> are still the right numbers; they are just witnessed at runtime rather than read out of the file.

This closes the old §8.1. Rows relevant to the `Object` namespace are cross-referenced in §3.1;
the rest are the raw census and are the join key for
[`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md), `docs/mercs2-ecs/`
(which covers the `0x50` array only) and `docs/game_config/cdbsizes.ini` (which budgets containers
from **both** arrays by name).

| id | arr | VA | name | name-hash | stride | cap |
|--:|:-:|---|---|---|--:|--:|
| 1 | `0x80` | `0x00DF6B88` | `Name` | `0x1DE5C824` | 4 | 256 |
| 2 | `0x80` | `0x00DF6C08` | `ModelName` | `0x5CF81991` | 4 | 256 |
| 3 | `0x80` | `0x00DF6C88` | `Path` | `0xBCFE6314` | 4 | 256 |
| 4 | `0x80` | `0x00DF6D08` | `Flags` | `0x3CE51772` | 32 | 256 |
| 5 | `0x50` | `0x017BBF58` | `Health` | `0x06BE1ABF` | 8 | 256 |
| 6 | `0x80` | `0x00DF6D88` | `PhysicalLink` | `0x7FBCE14E` | 40 | 256 |
| 7 | `0x80` | `0x00DF6E08` | `DestructionLink` | `0xBCE6FAD7` | 12 | 256 |
| 8 | `0x80` | `0x00DF6E88` | `Rotor` | `0x045CF1FB` | 28 | 128 |
| 9 | `0x80` | `0x00DF6F08` | `BoneCtrlLookAt` | `0xD7AA0796` | 16 | 256 |
| 10 | `0x80` | `0x00DF6F88` | `BoneCtrlRotationCopy` | `0x530F1DF9` | 28 | 64 |
| 11 | `0x80` | `0x00DF7008` | `BoneCtrlFakeWheel` | `0x31F592F4` | 24 | 256 |
| 12 | `0x80` | `0x00DF7088` | `MaterialCtrlTankTread` | `0xDCB942BF` | 24 | 64 |
| 13 | `0x80` | `0x00DF7108` | `BoneCtrlLocalRotation` | `0xA2B8C2AF` | 36 | 64 |
| 14 | `0x80` | `0x00DF7188` | `BoneCtrlLocalTranslation` | `0x99BA2DF2` | 40 | 16 |
| 15 | `0x80` | `0x00DF7208` | `BoneCtrlTentacle` | `0x69567E62` | 56 | 64 |
| 16 | `0x80` | `0x00DF7288` | `BoneCtrlStrapOn` | `0x64E7D6F9` | 140 | 256 |
| 17 | `0x80` | `0x00DF7308` | `BoneCtrlJostle` | `0xF328AA09` | 68 | 8 |
| 18 | `0x80` | `0x00DF7388` | `BoneCtrlWind` | `0x5A24921A` | 48 | 32 |
| 19 | `0x50` | `0x017BBFA8` | `BoneCtrlPhysicsActor` | `0x1AFAED2A` | 4 | 256 |
| 20 | `0x50` | `0x017BBFF8` | `InitialVelocity` | `0x6537A65A` | 48 | 256 |
| 21 | `0x80` | `0x00DF7408` | `PhysicsPropertyCrashable` | `0x367708CC` | 12 | 256 |
| 22 | `0x50` | `0x017BC048` | `PhysicsPropertyFakeContinuous` | `0x639F9491` | 4 | 32 |
| 23 | `0x50` | `0x017BC098` | `PhysicsPropertyUncrushable` | `0xA61BD97B` | 4 | 16 |
| 24 | `0x50` | `0x017BC0E8` | `PhysicsPropertyGravityScaler` | `0x841BA027` | 4 | 32 |
| 25 | `0x50` | `0x017BC138` | `_PropPhysics` | `0xB03943A2` | 16 | 256 |
| 26 | `0x50` | `0x017BC188` | `_DebrisPhysics` | `0x3E1EF7C4` | 12 | 256 |
| 27 | `0x50` | `0x017BC1D8` | `_BoatPhysics` | `0xD05CF17D` | 276 | 32 |
| 28 | `0x50` | `0x017BC228` | `_HumanPhysics` | `0x73790892` | 132 | 128 |
| 29 | `0x50` | `0x017BC278` | `_CarPhysicsV2` | `0xD1DE7E4D` | 396 | 256 |
| 30 | `0x80` | `0x00DF7488` | `_CarWheel` | `0x2A98060F` | 20 | 256 |
| 31 | `0x50` | `0x017BC2C8` | `_TankPhysics` | `0x537E1C8F` | 120 | 64 |
| 32 | `0x50` | `0x017BC318` | `_HelicopterPhysics` | `0x493E1D4E` | 88 | 32 |
| 33 | `0x50` | `0x017BC368` | `_HelicopterPhysicsAi` | `0x95C0E57C` | 84 | 32 |
| 34 | `0x50` | `0x017BC3B8` | `_JetPhysics` | `0xC0AEF1E0` | 4 | 8 |
| 35 | `0x50` | `0x017BC408` | `_BuildingPhysics` | `0x75C70083` | 8 | 256 |
| 36 | `0x50` | `0x017BC458` | `TinyGeometryObject` | `0x06468E56` | 4 | 32 |
| 37 | `0x50` | `0x017BC4A8` | `_CollapsePhysics` | `0x2119DCE4` | 4 | 8 |
| 38 | `0x50` | `0x017BC4F8` | `PhysicsDefaultActivator` | `0x2E2659F0` | 1 | 64 |
| 39 | `0x50` | `0x017BC548` | `Winch` | `0x9C6B3368` | 44 | 32 |
| 40 | `0x80` | `0x00DF7508` | `Turret` | `0x01212327` | 68 | 256 |
| 41 | `0x80` | `0x00DF7588` | `Door` | `0x78CF19B9` | 40 | 256 |
| 42 | `0x80` | `0x00DF7608` | `DoorCoupling` | `0x64745818` | 16 | 256 |
| 43 | `0x80` | `0x00DF7688` | `PoweredGate` | `0x997A8E5E` | 12 | 32 |
| 44 | `0x80` | `0x00DF7708` | `ConnectPoint` | `0xFFF58A2D` | 8 | 256 |
| 45 | `0x50` | `0x017BC598` | `Rope` | `0x330B1105` | 28 | 8 |
| 46 | `0x50` | `0x017BC5E8` | `Buoyancy` | `0xB9659F7B` | 20 | 256 |
| 47 | `0x50` | `0x017BC638` | `ExplosionFudge` | `0x5AEABC23` | 4 | 64 |
| 48 | `0x50` | `0x017BC688` | `WeaponEffects` | `0xF24D2021` | 16 | 128 |
| 49 | `0x50` | `0x017BC6D8` | `WeaponRecoilVehicle` | `0x557E4B99` | 8 | 64 |
| 50 | `0x50` | `0x017BC728` | `WeaponBarrel` | `0x180E2B95` | 4 | 256 |
| 51 | `0x50` | `0x017BC778` | `WeaponProjectileBase` | `0xEB505C8B` | 40 | 128 |
| 52 | `0x50` | `0x017BC7C8` | `WeaponScatter` | `0xE7234615` | 28 | 256 |
| 53 | `0x50` | `0x017BC818` | `AiSkill` | `0xEBA09B1A` | 4 | 128 |
| 54 | `0x50` | `0x017BC868` | `AiPatrol` | `0xB0CA290D` | 24 | 256 |
| 55 | `0x50` | `0x017BC8B8` | `AiHelicopter` | `0x78EB1ADC` | 36 | 128 |
| 56 | `0x50` | `0x017BC908` | `AiDriving` | `0x67AB955C` | 8 | 256 |
| 57 | `0x50` | `0x017BC958` | `Squad` | `0x9788C501` | 4 | 16 |
| 58 | `0x80` | `0x00DF7788` | `SquadUnitLink` | `0x383DBB5F` | 4 | 16 |
| 59 | `0x80` | `0x00DF7808` | `SquadSource` | `0x0C641B52` | 4 | 16 |
| 60 | `0x50` | `0x017BC9A8` | `WeaponThrown` | `0x24870CFF` | 52 | 16 |
| 61 | `0x50` | `0x017BC9F8` | `WeaponTrigger` | `0xC526A637` | 8 | 16 |
| 62 | `0x50` | `0x017BCA48` | `WeaponUI` | `0xE5D5E31F` | 24 | 128 |
| 63 | `0x50` | `0x017BCA98` | `WeaponScope` | `0x27CA777F` | 20 | 16 |
| 64 | `0x50` | `0x017BCAE8` | `Explosive` | `0xF74044BA` | 36 | 32 |
| 65 | `0x50` | `0x017BCB38` | `ControllerVelocity` | `0xD61C71B4` | 24 | 64 |
| 66 | `0x50` | `0x017BCB88` | `ProjectilePhysics` | `0x11E6C283` | 40 | 128 |
| 67 | `0x50` | `0x017BCBD8` | `FlightNoise` | `0x10ED85AF` | 24 | 32 |
| 68 | `0x50` | `0x017BCC28` | `TriggerOnTimer` | `0xFB35CD6F` | 8 | 64 |
| 69 | `0x80` | `0x00DF7888` | `SpawnOnDeath` | `0x7D8A24A9` | 16 | 128 |
| 70 | `0x50` | `0x017BCC78` | `TimerResponse` | `0xC122D3ED` | 12 | 32 |
| 71 | `0x80` | `0x00DF7908` | `Pickup` | `0x8602E37D` | 28 | 256 |
| 72 | `0x50` | `0x017BCCC8` | `HumanAnimationSystem` | `0x27A3C8A9` | 52 | 128 |
| 73 | `0x50` | `0x017BCD18` | `HumanAnimationSet` | `0xE8F41716` | 8 | 128 |
| 74 | `0x50` | `0x017BCD68` | `VehicleAnimationSet` | `0x35E09A35` | 8 | 256 |
| 75 | `0x50` | `0x017BCDB8` | `Equipment` | `0xDAB653E7` | 32 | 32 |
| 76 | `0x80` | `0x00DF7988` | `EquipmentDock` | `0x95513516` | 28 | 256 |
| 77 | `0x80` | `0x00DF7A08` | `EquipmentLink` | `0x094E7D13` | 12 | 256 |
| 78 | `0x80` | `0x00DF7A88` | `AnimationResponse` | `0x4E2B6C54` | 20 | 64 |
| 79 | `0x50` | `0x017BCE08` | `CameraCarPreset` | `0x5D1F87EF` | 80 | 32 |
| 80 | `0x80` | `0x00DF7B08` | `CameraCarPresetLink` | `0x773B1B9B` | 8 | 256 |
| 81 | `0x80` | `0x00DF7B88` | `CameraHelicopter` | `0x9479F2E3` | 80 | 32 |
| 82 | `0x80` | `0x00DF7C08` | `CameraTurret` | `0xBC68F146` | 96 | 256 |
| 83 | `0x80` | `0x00DF7C88` | `CameraTank` | `0xCB5AC0E4` | 64 | 32 |
| 84 | `0x50` | `0x017BCE58` | `CameraShake` | `0x412D1576` | 16 | 128 |
| 85 | `0x50` | `0x017BCEA8` | `HumanCameraModifier` | `0x212FFCB2` | 56 | 64 |
| 86 | `0x50` | `0x017BCEF8` | `ControllerPlayer` | `0x6CA511B2` | 12 | 32 |
| 87 | `0x50` | `0x017BCF48` | `ControllerVehicle` | `0xBFB1AECB` | 4 | 16 |
| 88 | `0x50` | `0x017BCF98` | `ControllerCar` | `0xEEEA744D` | 4 | 64 |
| 89 | `0x50` | `0x017BCFE8` | `ControllerBoat` | `0x4F89A7C7` | 4 | 64 |
| 90 | `0x50` | `0x017BD038` | `ControllerTank` | `0x55BC62BD` | 4 | 32 |
| 91 | `0x50` | `0x017BD088` | `ControllerLW` | `0x1BB0A5BE` | 4 | 16 |
| 92 | `0x80` | `0x00DF7D08` | `ControllerTurret` | `0x25A79C5B` | 8 | 256 |
| 93 | `0x80` | `0x00DF7D88` | `ControllerWeapon` | `0x0CAE3C35` | 12 | 256 |
| 94 | `0x80` | `0x00DF7E08` | `WeaponCoupling` | `0x87F3C810` | 12 | 256 |
| 95 | `0x80` | `0x00DF7E88` | `TurretCoupling` | `0xD28FEA46` | 12 | 256 |
| 96 | `0x50` | `0x017BD0D8` | `ControllerHelicopter` | `0x495A0CEA` | 4 | 64 |
| 97 | `0x50` | `0x017BD128` | `ControllerLadder` | `0x964E010D` | 4 | 32 |
| 98 | `0x50` | `0x017BD178` | `HibernationControl` | `0xE18AFD65` | 6 | 256 |
| 99 | `0x50` | `0x017BD1C8` | `Ai` | `0xFB31F1EF` | 48 | 256 |
| 100 | `0x50` | `0x017BD218` | `AiBehavior` | `0xDECD8889` | 48 | 256 |
| 101 | `0x50` | `0x017BD268` | `Anchor` | `0xFA55F6BA` | 16 | 128 |
| 102 | `0x50` | `0x017BD2B8` | `Perception` | `0x3F6AB8F0` | 20 | 256 |
| 103 | `0x50` | `0x017BD308` | `Stimulus` | `0x06408D71` | 12 | 256 |
| 104 | `0x50` | `0x017BD358` | `StimulusModifier` | `0xB9388F0A` | 24 | 256 |
| 105 | `0x50` | `0x017BD3A8` | `Target` | `0xAFF6B246` | 4 | 64 |
| 106 | `0x50` | `0x017BD3F8` | `Alarm` | `0xBE65FDD0` | 4 | 32 |
| 107 | `0x50` | `0x017BD448` | `SocialUse` | `0x7E6BF93D` | 16 | 32 |
| 108 | `0x50` | `0x017BD498` | `ChatterSet` | `0x949A1E44` | 4 | 256 |
| 109 | `0x50` | `0x017BD4E8` | `SkirmishZone` | `0xFC5923AF` | 8 | 16 |
| 110 | `0x50` | `0x017BD538` | `SkirmishSpawnList` | `0xAFBA5846` | 24 | 16 |
| 111 | `0x80` | `0x00DF7F08` | `Relationship` | `0x321FEDC3` | 4 | 32 |
| 112 | `0x80` | `0x00DF7F88` | `Association` | `0x3B3CF882` | 4 | 256 |
| 113 | `0x50` | `0x017BD588` | `FactionMarker` | `0x9B98CB09` | 4 | 256 |
| 114 | `0x80` | `0x00DF8008` | `CoverHintOffset` | `0xE7375904` | 64 | 256 |
| 115 | `0x50` | `0x017BD5D8` | `VehicleDisguiseScale` | `0x8B3A2B88` | 12 | 256 |
| 116 | `0x80` | `0x00DF8088` | `AiHintNode` | `0xBE4DDF50` | 12 | 64 |
| 117 | `0x50` | `0x017BD628` | `FactionZone` | `0x67267CC1` | 4 | 16 |
| 118 | `0x50` | `0x017BD678` | `AiWaterZone` | `0xDF6533DE` | 4 | 16 |
| 119 | `0x80` | `0x00DF8108` | `Label` | `0x06DA8775` | 4 | 256 |
| 120 | `0x50` | `0x017BD6C8` | `LandingZone` | `0x2A20B640` | 8 | 32 |
| 121 | `0x50` | `0x017BD718` | `CashValue` | `0x564990C3` | 4 | 256 |
| 122 | `0x50` | `0x017BD768` | `LocalizedName` | `0xA49AFEC1` | 4 | 256 |
| 123 | `0x50` | `0x017BD7B8` | `FactionValue` | `0x8BFC69D6` | 4 | 64 |
| 124 | `0x80` | `0x00DF8188` | `SeatLink` | `0xECC4A256` | 8 | 256 |
| 125 | `0x50` | `0x017BD808` | `SeatParameters` | `0xA2D3AE72` | 20 | 256 |
| 126 | `0x80` | `0x00DF8208` | `EntranceLink` | `0x619FEE87` | 8 | 256 |
| 127 | `0x50` | `0x017BD858` | `EntranceParameters` | `0x70D05913` | 28 | 64 |
| 128 | `0x80` | `0x00DF8288` | `EntranceToSeat` | `0xF7E8B25B` | 12 | 256 |
| 129 | `0x80` | `0x00DF8308` | `SeatToSeat` | `0x574C208A` | 8 | 256 |
| 130 | `0x80` | `0x00DF8388` | `Rider` | `0x03F7D697` | 8 | 256 |
| 131 | `0x80` | `0x00DF8408` | `RiderLink` | `0x8C8A5803` | 12 | 256 |
| 132 | `0x50` | `0x017BD8A8` | `StateMachine` | `0x98A3661F` | 16 | 256 |
| 133 | `0x50` | `0x017BD8F8` | `Road` | `0xEA0F3AA3` | 40 | 256 |
| 134 | `0x80` | `0x00DF8490` | `RoadIntersectionHint` | `0xCBA80A4B` | 28 | 32 |
| 135 | `0x50` | `0x017BD948` | `IntersectionToIntersection` | `0xEB6DE962` | 8 | 256 |
| 136 | `0x50` | `0x017BD998` | `LaneData` | `0x6A08E327` | 64 | 128 |
| 137 | `0x50` | `0x017BD9E8` | `LaneZeroDirection` | `0x7CF73564` | 4 | 256 |
| 138 | `0x50` | `0x017BDA38` | `SphereRegion` | `0x4CA3FD52` | 4 | 32 |
| 139 | `0x50` | `0x017BDA88` | `PointLocation` | `0x60B7ABE0` | 36 | 64 |
| 140 | `0x50` | `0x017BDAD8` | `PopulationDensity` | `0x6FA2F9D4` | 28 | 64 |
| 141 | `0x50` | `0x017BDB28` | `DangerousBuilding` | `0x543977F7` | 4 | 256 |
| 142 | `0x80` | `0x00DF8510` | `PopulationSimpleSpawner` | `0x00891D0A` | 112 | 256 |
| 143 | `0x50` | `0x017BDB78` | `PopulationDynamicRoad` | `0xFFC5BAA5` | 12 | 32 |
| 144 | `0x80` | `0x00DF8590` | `PopulationList` | `0x0699BE8C` | 8 | 256 |
| 145 | `0x50` | `0x017BDBC8` | `PopulationFlow` | `0x322750EC` | 12 | 64 |
| 146 | `0x50` | `0x017BDC18` | `CircleRegion` | `0x6691B221` | 4 | 8 |
| 147 | `0x50` | `0x017BDC68` | `LineRegion` | `0x6310807F` | 4 | 128 |
| 148 | `0x50` | `0x017BDCB8` | `BoundaryData` | `0x5A59763F` | 4 | 256 |
| 149 | `0x50` | `0x017BDD08` | `PathData` | `0xAEF6F7B4` | 4 | 8 |
| 150 | `0x50` | `0x017BDD58` | `ObjectScript` | `0xD81512A1` | 8 | 256 |
| 151 | `0x50` | `0x017BDDA8` | `BuildingDestruction` | `0x17A5555B` | 24 | 32 |
| 152 | `0x50` | `0x017BDDF8` | `ParticleEmitter` | `0xE595AB2F` | 16 | 8 |
| 153 | `0x50` | `0x017BDE48` | `HumanInventory` | `0xE672296C` | 28 | 8 |
| 154 | `0x50` | `0x017BDE98` | `ObjectMaterial` | `0xC1F1F72F` | 4 | 32 |
| 155 | `0x80` | `0x00DF8610` | `MaterialMapping` | `0x49F0D0EC` | 8 | 256 |
| 156 | `0x80` | `0x00DF8690` | `ModifierKey` | `0x99C2B81F` | 8 | 256 |
| 157 | `0x80` | `0x00DF8710` | `ParticleKey` | `0x35EF2B84` | 8 | 256 |
| 158 | `0x80` | `0x00DF8790` | `SoundKey` | `0xAA54B95B` | 8 | 256 |
| 159 | `0x50` | `0x017BDEE8` | `SoundRuinKey` | `0xBC1F685D` | 4 | 8 |
| 160 | `0x80` | `0x00DF8810` | `DrivingKey` | `0x6BBE8E8F` | 8 | 8 |
| 161 | `0x50` | `0x017BDF38` | `DamageKey` | `0xEF41976F` | 4 | 256 |
| 162 | `0x50` | `0x017BDF88` | `TerrainKey` | `0x0868B0CD` | 4 | 256 |
| 163 | `0x50` | `0x017BDFD8` | `SoundEffect` | `0xB40954F5` | 28 | 256 |
| 164 | `0x50` | `0x017BE028` | `SoundAmbience` | `0x514CAD3A` | 20 | 32 |
| 165 | `0x50` | `0x017BE078` | `SoundInterior` | `0x05D1D9BA` | 12 | 8 |
| 166 | `0x50` | `0x017BE0C8` | `MusicSource` | `0xB52A3A81` | 8 | 32 |
| 167 | `0x50` | `0x017BE118` | `MusicRegion` | `0x79DCBE56` | 4 | 64 |
| 168 | `0x50` | `0x017BE168` | `MeleeCombatant` | `0xBF438E92` | 40 | 128 |
| 169 | `0x50` | `0x017BE1B8` | `TickDamage` | `0x8DEF82AD` | 16 | 256 |
| 170 | `0x80` | `0x00DF8890` | `NodeHealth` | `0xFEA92137` | 24 | 256 |
| 171 | `0x50` | `0x017BE208` | `BlobShadow` | `0x40349618` | 36 | 256 |
| 172 | `0x80` | `0x00DF8910` | `DebrisEffect` | `0x4EC11797` | 48 | 256 |
| 173 | `0x80` | `0x00DF8990` | `TreeFoliage` | `0x2A8A1456` | 32 | 32 |
| 174 | `0x50` | `0x017BE258` | `Flammable` | `0xD930020E` | 4 | 256 |
| 175 | `0x50` | `0x017BE2A8` | `Ignitor` | `0x37C12455` | 12 | 32 |
| 176 | `0x50` | `0x017BE2F8` | `ObjectHint` | `0x2A390A27` | 12 | 256 |
| 177 | `0x50` | `0x017BE348` | `WeaponHint` | `0xD390834A` | 52 | 128 |
| 178 | `0x50` | `0x017BE398` | `RedEffectComponent` | `0x60A13E3E` | 56 | 256 |
| 179 | `0x50` | `0x017BE3E8` | `EffectTemplate` | `0xABAA1F3C` | 4 | 256 |
| 180 | `0x80` | `0x00DF8A10` | `RedEffectTweak` | `0xAFABFD0F` | 8 | 32 |
| 181 | `0x50` | `0x017BE438` | `EffectAiOccluder` | `0x20E89C9D` | 4 | 64 |
| 182 | `0x80` | `0x00DF8A90` | `EffectModel` | `0x52DFAE51` | 12 | 64 |
| 183 | `0x50` | `0x017BE488` | `LightAnimation` | `0xBD5349F7` | 44 | 64 |
| 184 | `0x50` | `0x017BE4D8` | `FlareObject` | `0x9F3EBFBA` | 64 | 16 |
| 185 | `0x50` | `0x017BE528` | `ColorAnimation` | `0x2C9FB394` | 12 | 8 |
| 186 | `0x50` | `0x017BE578` | `ScaleAnimation` | `0x60E3D029` | 16 | 16 |
| 187 | `0x50` | `0x017BE5C8` | `Sticky` | `0x97870D10` | 4 | 16 |
| 188 | `0x80` | `0x00DF8B10` | `OSMParameter` | `0xE60A85D9` | 8 | 256 |
| 189 | `0x80` | `0x00DF8B90` | `OSMStateParameter` | `0x06613270` | 8 | 256 |
| 190 | `0x80` | `0x00DF8C10` | `ConstraintLink` | `0x5C694EE8` | 12 | 32 |
| 191 | `0x80` | `0x00DF8C90` | `DamageChunks` | `0x73839D40` | 40 | 32 |
| 192 | `0x50` | `0x017BE618` | `HomingWeapon` | `0x1A4DB6ED` | 24 | 64 |
| 193 | `0x50` | `0x017BE668` | `HomingProjectile` | `0xE81B2874` | 12 | 64 |
| 194 | `0x50` | `0x017BE6B8` | `HomingTarget` | `0xB9EA3B32` | 16 | 256 |
| 195 | `0x80` | `0x00DF8D10` | `BuildingCollapseAnim` | `0x57F0BC07` | 24 | 256 |
| 196 | `0x50` | `0x017BE708` | `ModelMixerProfile` | `0x1611C502` | 4 | 256 |
| 197 | `0x50` | `0x017BE758` | `Carryable` | `0x712AF756` | 4 | 8 |
| 198 | `0x80` | `0x00DF8D90` | `MaterialEmitter` | `0x8B80E30C` | 8 | 256 |
| 199 | `0x80` | `0x00DF8E10` | `AtmosphereBase` | `0xB8D2B506` | 740 | 32 |
| 200 | `0x50` | `0x017BE7A8` | `DisableDecals` | `0xFF4533E5` | 4 | 256 |
| 201 | `0x50` | `0x017BE7F8` | `Disable3DDecals` | `0x69A0E0E4` | 4 | 256 |
| 202 | `0x80` | `0x00DF8E90` | `DisableMaterialEffect` | `0x5A6DB5B7` | 20 | 8 |
| 203 | `0x80` | `0x00DF8F10` | `DisableDamageEffect` | `0x9FC02FAF` | 20 | 256 |
| 204 | `0x50` | `0x017BE848` | `GrappleParameters` | `0x6AC5EE26` | 28 | 64 |
| 205 | `0x50` | `0x017BE898` | `Ribbon` | `0x059B95B9` | 44 | 32 |
| 206 | `0x50` | `0x017BE8E8` | `SpeedLimit` | `0x9ADD960B` | 12 | 16 |
| 207 | `0x80` | `0x00DF8F90` | `EffectVelocityControl` | `0x96D18CFE` | 24 | 256 |
| 208 | `0x50` | `0x017BE938` | `MassiveComponent` | `0xF482C286` | 4 | 32 |
| 209 | `0x50` | `0x017BE988` | `Crusher` | `0x24463D8B` | 4 | 32 |
| 210 | `0x80` | `0x00DF9010` | `VehiclePart` | `0xC163F6F8` | 16 | 256 |
| 211 | `0x80` | `0x00DF9090` | `GenericLOD` | `0x7E5F1839` | 16 | 64 |
| 212 | `0x50` | `0x017BE9D8` | `RoadIntersection` | `0x6FD048F4` | 124 | 256 |
| 213 | `0x50` | `0x017BEA28` | `ScrubObject` | `0xAB92C697` | 4 | 256 |
| 214 | `0x50` | `0x017BEA78` | `TerrainObject` | `0x6C82EBE5` | 4 | 256 |
| 215 | `0x50` | `0x017BEAC8` | `TerrainFade` | `0x26AE8736` | 20 | 32 |
| 216 | `0x50` | `0x017BEB18` | `LightObject` | `0x97E8EE92` | 52 | 256 |
| 217 | `0x50` | `0x017BEB68` | `LowResTerrainObject` | `0x2D8D2435` | 8 | 256 |
| 218 | `0x50` | `0x017BEBB8` | `NetCategoryInfo` | `0x99CDCA52` | 2 | 256 |
| 219 | `0x80` | `0x00DF9110` | `RuntimePhysicalLink` | `0xFE770464` | 40 | 256 |
| 220 | `0x80` | `0x00DF9190` | `RuntimeConstraintLink` | `0x197EF056` | 296 | 32 |
| 221 | `0x80` | `0x00DF9210` | `RuntimeEntranceLink` | `0x63FF60AD` | 8 | 256 |
| 222 | `0x50` | `0x017BEC08` | `RuntimeWeapon` | `0xEC62E3A3` | 52 | 64 |
| 223 | `0x50` | `0x017BEC58` | `RuntimeWeaponProjectile` | `0x7A303AD6` | 108 | 32 |
| 224 | `0x50` | `0x017BECA8` | `RuntimeAlternatingFire` | `0x9BB55CF2` | 16 | 8 |
| 225 | `0x80` | `0x00DF9290` | `RuntimeTriggerable` | `0x547F025D` | 4 | 8 |
| 226 | `0x50` | `0x017BECF8` | `RuntimeVelocity` | `0xE493BF82` | 8 | 16 |
| 227 | `0x50` | `0x017BED48` | `RuntimeProjectile` | `0x9D2AB1A6` | 160 | 128 |
| 228 | `0x50` | `0x017BED98` | `RuntimeFakeProjectile` | `0x750BC641` | 68 | 8 |
| 229 | `0x50` | `0x017BEDE8` | `RuntimeFlightNoise` | `0xEBF6D595` | 32 | 8 |
| 230 | `0x50` | `0x017BEE38` | `RuntimeProjectileThrown` | `0xF394DE30` | 4 | 16 |
| 231 | `0x50` | `0x017BEE88` | `RuntimeTimer` | `0x38437A4E` | 16 | 16 |
| 232 | `0x50` | `0x017BEED8` | `RuntimeAssetRef` | `0xD2435030` | 4 | 256 |
| 233 | `0x50` | `0x017BEF28` | `RuntimeExplosion` | `0x5529DD38` | 64 | 8 |
| 234 | `0x50` | `0x017BEF78` | `RuntimeHealth` | `0xF9B9B2A5` | 12 | 256 |
| 235 | `0x50` | `0x017BEFC8` | `RuntimeNodeHealth` | `0x76927BF5` | 4 | 256 |
| 236 | `0x50` | `0x017BF018` | `RuntimeSoundRuinKey` | `0x25E2DEF3` | 4 | 16 |
| 237 | `0x50` | `0x017BF068` | `RuntimeSoundEffect` | `0x0E83BCB7` | 28 | 256 |
| 238 | `0x50` | `0x017BF0B8` | `RuntimeSoundAmbience` | `0x5FE773CC` | 1 | 64 |
| 239 | `0x50` | `0x017BF108` | `RuntimeMusicRegion` | `0xAA6964E8` | 1 | 64 |
| 240 | `0x50` | `0x017BF158` | `RuntimeOwnerGuid` | `0xAFF006A7` | 4 | 32 |
| 241 | `0x50` | `0x017BF1A8` | `RuntimeAirstrikeProjectile` | `0xF67A894A` | 40 | 8 |
| 242 | `0x50` | `0x017BF1F8` | `RuntimeAirstrikeAirplane` | `0x23D5DE91` | 176 | 4 |
| 243 | `0x50` | `0x017BF248` | `RuntimeObjectiveMarker` | `0x2A77B292` | 112 | 32 |
| 244 | `0x50` | `0x017BF298` | `RuntimeScriptCallback` | `0x3B105827` | 8 | 8 |
| 245 | `0x50` | `0x017BF2E8` | `RuntimeScrub` | `0x7DA4BD48` | 8 | 256 |
| 246 | `0x80` | `0x00DF9310` | `RuntimeModelState` | `0xFC97DD05` | 56 | 256 |
| 247 | `0x80` | `0x00DF9390` | `RuntimeFacialExpression` | `0x921EFC0D` | 48 | 32 |
| 248 | `0x50` | `0x017BF338` | `RuntimeHeadLookAt` | `0x6B1666DF` | 44 | 64 |
| 249 | `0x80` | `0x00DF9410` | `RuntimeDebrisEffect` | `0xD255212D` | 88 | 8 |
| 250 | `0x80` | `0x00DF9490` | `RuntimeTurret` | `0x937EA0CD` | 4 | 64 |
| 251 | `0x50` | `0x017BF388` | `RuntimeIgnitor` | `0x1CA3ABD7` | 28 | 8 |
| 252 | `0x80` | `0x00DF9510` | `RuntimeEquipmentLink` | `0x77C00AA9` | 12 | 256 |
| 253 | `0x50` | `0x017BF3D8` | `RuntimeInventory` | `0xA364FC7D` | 48 | 64 |
| 254 | `0x50` | `0x017BF428` | `RuntimeAnimationParams` | `0x9606E589` | 40 | 8 |
| 255 | `0x50` | `0x017BF478` | `RuntimeLayerId` | `0x2284FE19` | 4 | 256 |
| 256 | `0x50` | `0x017BF4C8` | `RuntimeRiderDiveEnter` | `0x8A15415F` | 68 | 256 |
| 257 | `0x50` | `0x017BF518` | `RuntimeRiderCrawlExit` | `0xA7D4D8CA` | 52 | 8 |
| 258 | `0x50` | `0x017BF568` | `RuntimeVehicleCrawlExits` | `0x1FA43615` | 108 | 8 |
| 259 | `0x50` | `0x017BF5B8` | `RuntimeClaim` | `0x5D5CB7BD` | 12 | 16 |
| 260 | `0x80` | `0x00DF9590` | `RuntimeClaimCover` | `0x340C811E` | 24 | 16 |
| 261 | `0x50` | `0x017BF608` | `RuntimeLastDamageApplied` | `0x9CBD437B` | 28 | 32 |
| 262 | `0x50` | `0x017BF658` | `RuntimeTravelGroup` | `0x5F187FA4` | 8 | 8 |
| 263 | `0x50` | `0x017BF6A8` | `RuntimeHomingWeapon` | `0xC09ADB1B` | 84 | 8 |
| 264 | `0x50` | `0x017BF6F8` | `RuntimeHomingProjectile` | `0xC45D369E` | 88 | 8 |
| 265 | `0x50` | `0x017BF748` | `RuntimeHomingTarget` | `0x14F6DE44` | 48 | 64 |
| 266 | `0x50` | `0x017BF798` | `RuntimeLaserDesignator` | `0x735B0EAA` | 16 | 4 |
| 267 | `0x50` | `0x017BF7E8` | `RuntimeVehicleInventory` | `0x9A6DB283` | 2 | 32 |
| 268 | `0x80` | `0x00DF9610` | `RuntimeVehiclePart` | `0x31202C8E` | 16 | 64 |
| 269 | `0x80` | `0x00DF9690` | `RtRisingRuinPhysicsAnimation` | `0x22968ABC` | 4 | 8 |
| 270 | `0x50` | `0x017BF838` | `RuntimeMassiveSubscriber` | `0x4172E975` | 4 | 256 |
| 271 | `0x50` | `0x017BF888` | `PhysicsActor` | `0xFE9497DB` | 4 | 256 |
| 272 | `0x50` | `0x017BF8D8` | `PhysicsActorWinch` | `0x025B7AB6` | 4 | 16 |
| 273 | `0x50` | `0x017BF928` | `PhysicsActorRagdoll` | `0xF365E0EC` | 4 | 64 |
| 274 | `0x50` | `0x017BF978` | `RtDebris` | `0x964BEBAA` | 28 | 64 |
| 275 | `0x50` | `0x017BF9C8` | `RTHuman` | `0x2C6E46B6` | 72 | 64 |
| 276 | `0x50` | `0x017BFA18` | `RtPopHint` | `0x036DC9CB` | 1 | 128 |
| 277 | `0x50` | `0x017BFA68` | `RtPopMembership` | `0x8C8E5490` | 20 | 32 |
| 278 | `0x80` | `0x00DF9710` | `RtExhaustionCounter` | `0x6F49F3A9` | 12 | 8 |
| 279 | `0x50` | `0x017BFAB8` | `RtDriverData` | `0xE2636501` | 16 | 64 |
| 280 | `0x50` | `0x017BFB08` | `RtJunction` | `0x643B62AF` | 16 | 8 |
| 281 | `0x50` | `0x017BFB58` | `RtRedEffect` | `0x9B2DAF6F` | 32 | 8 |
| 282 | `0x50` | `0x017BFBA8` | `RtVFX` | `0x757B2069` | 16 | 256 |
| 283 | `0x50` | `0x017BFBF8` | `RtTickDamage` | `0x27E19BF7` | 16 | 16 |
| 284 | `0x50` | `0x017BFC48` | `RtLightAnimation` | `0x8AA117BD` | 44 | 32 |
| 285 | `0x50` | `0x017BFC98` | `RtColorAnimation` | `0x52DA71DE` | 16 | 8 |
| 286 | `0x50` | `0x017BFCE8` | `RtScaleAnimation` | `0xC1EDC09B` | 20 | 8 |
| 287 | `0x50` | `0x017BFD38` | `RtAlphaAnimation` | `0xA7B2F925` | 20 | 8 |
| 288 | `0x80` | `0x00DF9790` | `RtAttachedFlowControl` | `0x56F7F6B2` | 4 | 256 |
| 289 | `0x50` | `0x017BFD88` | `RtFlowControl` | `0xB6CB89DE` | 92 | 64 |
| 290 | `0x50` | `0x017BFDD8` | `RtFlowCycleTimer` | `0xD4CA71DA` | 68 | 32 |
| 291 | `0x50` | `0x017BFE28` | `RtRoadIntersection` | `0x5E137672` | 196 | 64 |
| 292 | `0x80` | `0x00DF9810` | `RtPathMember` | `0x99C8FCE4` | 4 | 32 |
| 293 | `0x50` | `0x017BFE78` | `RtLivingWorld` | `0x115B2B5C` | 16 | 16 |
| 294 | `0x80` | `0x00DF9890` | `RtPoweredGate` | `0x3E74EBD8` | 48 | 32 |
| 295 | `0x50` | `0x017BFEC8` | `RuntimeTerrainBound` | `0x745C6D6A` | 28 | 32 |
| 296 | `0x50` | `0x017BFF18` | `ContextAction` | `0xF957A94C` | 160 | 16 |
| 297 | `0x50` | `0x017BFF68` | `Model` | `0x5B724250` | 4 | 8 |
| 298 | `0x50` | `0x017BFFB8` | `CenterOfMassInWorld` | `0xE5276B5C` | 12 | 8 |
| 299 | `0x50` | `0x017C0008` | `RuntimeRope` | `0xA9C2A15B` | 4 | 8 |
| 300 | `0x80` | `0x00DF9910` | `RuntimeFakeWheel` | `0xC9E072D1` | 4 | 8 |
| 301 | `0x80` | `0x00DF9990` | `HumanStateMachine` | `0x07B5A5C2` | 4 | 128 |
| 302 | `0x80` | `0x00DF9A10` | `HumanAnimationControllerNEW` | `0xECB746CC` | 4 | 64 |
| 303 | `0x50` | `0x017C0058` | `AnimationController` | `0xF1D5ADD9` | 4 | 16 |
| 304 | `0x50` | `0x017C00A8` | `ControlBinding` | `0x3486768B` | 4 | 16 |
| 305 | `0x50` | `0x017C00F8` | `BoneControllerRuntime` | `0x09A0962D` | 4 | 256 |
| 306 | `0x80` | `0x00DF9A90` | `MaterialControllerRuntime` | `0xA5FAE422` | 4 | 256 |
| 307 | `0x50` | `0x017C0148` | `RtCoverHint` | `0x4350B887` | 1 | 256 |
| 308 | `0x50` | `0x017C0198` | `RtAlarm` | `0x7A3425CE` | 1 | 32 |
| 309 | `0x50` | `0x017C01E8` | `Usable` | `0xB3AF2A59` | 8 | 128 |
| 310 | `0x50` | `0x017C0238` | `RtDamageFlags` | `0x93621235` | 4 | 256 |
| 311 | `0x80` | `0x00DF9B10` | `CheatInfiniteAmmo` | `0x989C4290` | 1 | 128 |
| 312 | `0x80` | `0x00DF9B90` | `Players` | `0x451C2119` | 4 | 8 |
| 313 | `0x50` | `0x017C0288` | `SpawnerAdjust` | `0x1003413E` | 96 | 16 |
| 314 | `0x50` | `0x017C02D8` | `SceneObject` | `0xB6185886` | 28 | 256 |
| 315 | `0x80` | `0x00DF9C10` | `PendingSceneObject` | `0xD25A84AB` | 8 | 256 |
| 316 | `0x80` | `0x00DF9C90` | `RuntimeSceneObject` | `0x72D1A144` | 56 | 256 |
| 317 | `0x50` | `0x017C0328` | `TerrainGuidMappingHighResToLowRes` | `0x23B3D1E4` | 4 | 256 |
| 318 | `0x50` | `0x017C0378` | `SysPathRoadIndex` | `0x805AD569` | 4 | 256 |
| 319 | `0x50` | `0x017C03C8` | `SysPathIntersectionIndex` | `0x2EEF9DD2` | 4 | 256 |
| 320 | `0x80` | `0x00DF9D10` | `RuntimePickup` | `0x9579AF7B` | 4 | 64 |
| 321 | `0x80` | `0x00DF9D90` | `RuntimeEntranceUsable` | `0xEAEB68D5` | 4 | 256 |
| 322 | `0x50` | `0x017C0418` | `RuntimeEntrance` | `0x55D8D2B1` | 1 | 128 |
| 323 | `0x50` | `0x017C0468` | `RuntimeHijackState` | `0xD5F2B17A` | 20 | 8 |
| 324 | `0x50` | `0x017C04B8` | `RuntimeSeatPlayerUsable` | `0xE5FB2B37` | 1 | 256 |
| 325 | `0x50` | `0x017C0508` | `RagdollController` | `0x34EA185E` | 4 | 64 |
| 326 | `0x50` | `0x017C0558` | `AiUnUsable` | `0x4A548962` | 1 | 8 |
| 327 | `0x50` | `0x017C05A8` | `Suspect` | `0x1AFC276C` | 32 | 32 |
| 328 | `0x50` | `0x017C05F8` | `RtFactionZone` | `0xA67114C7` | 28 | 16 |
| 329 | `0x50` | `0x017C0648` | `RtRibbon` | `0x9AB86EB3` | 32 | 16 |
| 330 | `0x50` | `0x017C0698` | `RtSpeedLimit` | `0xFF142695` | 28 | 8 |
| 331 | `0x50` | `0x017C06E8` | `RtTerrainChildren` | `0x0FF1C703` | 64 | 32 |
| 332 | `0x80` | `0x00DF9E10` | `RtEffectVelocityControl` | `0x9EBF9F5C` | 28 | 256 |
| 333 | `0x50` | `0x017C0738` | `RtGenericLOD` | `0x0C51B633` | 68 | 32 |
| 334 | `0x50` | `0x017C0788` | `RtGenericLODProxy` | `0xCE91973D` | 4 | 32 |
