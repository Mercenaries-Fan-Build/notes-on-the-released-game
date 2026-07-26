# Human character controller — PC code map

**Scope:** the **`Human` Lua namespace** (`luaL_Reg` array `0x00B99EF0`, **21 top-level cfuncs plus a
9-cfunc `Inventory` sub-table**, 0 stubs) and the small amount of engine surface those bindings
*reach that no sibling map already owns*: the containers a "human" is spread across, the
**Stance/Action** pair that is the character controller's actual state variable, the
**`HumanStateTable` transition engine** that owns it, and the command path
(`RuntimeAnimationParams` fill → shared command ring → optional network replication) that the
action verbs travel down.

**This map is deliberately a JOIN, not a re-derivation.** The character *runtime* — the
`hkpCharacterProxy` swept-capsule controller, the 5-state on-foot machine, `HumanPhysics::Activate`,
the ragdoll — is already fully recovered in [`physics_code_map.md`](physics_code_map.md); clip
selection is already fully recovered in [`animation_code_map.md`](animation_code_map.md) +
[`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md); the
player↔character binding is already recovered in [`player_code_map.md`](player_code_map.md). Those
are **cited**, not repeated.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`physics_code_map.md`](physics_code_map.md) | `HumanPhysics::Activate` `FUN_004255c0` (7 capsules + phantom + proxy), `hkpCharacterProxy` `FUN_0094f2c0` + `hkpCharacterContext` `FUN_0094d2e0` and the 5-state machine (OnGround `FUN_0094ce90` / InAir `FUN_0094d7b0` / Jumping `FUN_00951ef0`), the ragdoll builder `FUN_009463a0`, the grapple/winch **constraint** layer |
| [`animation_code_map.md`](animation_code_map.md) · [`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md) | the ActionTable `0x6802C321` → AnimationLookup `0xE00B080C` → `ASTO[index]` clip picker and its 14 key columns. This map supplies the **upstream state graph** that produces two of those columns, not the picker |
| [`player_code_map.md`](player_code_map.md) | the player object, `player+0x20` = attached character GUID, `FUN_006a4060` attach-by-marker-component, the 107-cfunc `Player` table |
| [`weapons_combat_code_map.md`](weapons_combat_code_map.md) | weapon state, damage, `RuntimeWeapon`. The 9 `Human.Inventory.*` cfuncs are a **marker-delimited sub-table inside this same array** (§3.1) and are not among the 21 |
| [`vehicle_code_map.md`](vehicle_code_map.md) | seats and ride mechanics; `ForceExitSeatNoSnap` only *calls into* them |
| [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md) | `FUN_005857e0`, the object→component instance resolver, and the `CopyFromStream` registrar shape |
| [`ai_code_map.md`](ai_code_map.md) | the command ring `FUN_00423d10` / `DAT_012476f0` itself — this map only adds the **Human** ids that ride it |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) for the 9 cfuncs Ghidra found an entry point for, and **first-hand
capstone disassembly of `output/_ghidra/securom_dump/mercs2_unpacked.exe`** for the other 12 and for
every worker behind a SecuROM slot. Shipped-data ground truth from `vz.wad` via
`mercs2_probe humanstate_probe` and `action_table_probe`. Script-side signatures and traffic counts
re-counted this pass over `docs/mercs2-luacd/` (370) **and** `docs/mercs2-dlc-luacd/` (75). Name
hashes computed with `tools/pandemic_hash.py --m2` ([[no-arbitrary-hashes]]).

> **Provenance correction.** Earlier revisions credited the traffic counts to "the 370 decompiled
> scripts in `docs/mercs2-luacd/`". Every count was actually the **base + DLC union**; the split is
> given per-binding in §3. The "cutscene/hijack-driver profile" conclusion is unaffected.

### R. Reproduce anything in this map

Four mechanisms carry almost every claim below. All four are static and need no debugger.

1. **VA → file offset.** `mercs2_unpacked.exe` (53,485,568 B, 13 sections) is a live memory dump
   written back flat: for **all 13 sections `RVA == raw pointer`** (checked section-by-section:
   `.text` `0x00401000`/`0x0001000`, `.rdata` `0x00B05000`/`0x0705000`, `Stext` `0x01A49000`/
   `0x1649000`, `.securom` `0x023E9000`/`0x1FE9000`, …). So `offset = VA − 0x00400000`. Verify
   before relying on it — the shortcut is a property of *this* image, not of PE files.
2. **The SecuROM slot deref.** A body that reads `jmp dword ptr [0x02xxxxxx]` is **not** a wall
   ([[securom-decompiled-not-a-blocker]]). The slot is *already resolved in the dump*: read the
   dword, seek to the target, disassemble. Only `push imm32; call 0x01AAFF10` VM stubs are genuinely
   hard (§8).
3. **The container master key.** `[*(container) + 0x34]` is a name accessor. If the target is
   literally `B8 <imm32> C3` (`mov eax,<char*>; ret`), the `imm32` is the container's registered
   name. Every container address in this map was named this way and the name **verified**, not
   assumed (§1).
4. **Shipped data.**
   `MERCS2_VZ_WAD=".../Mercenaries 2 World in Flames/data/vz.wad" cargo run -q -p mercs2_probe --bin humanstate_probe`
   dumps the `HumanStateTable`; `--bin action_table_probe` dumps the ActionTable.

**Two traps that cost this map four findings each time they were hit.**

- **Ghidra drops `mov ecx/esi/edi, imm32` register arguments.** Four separate errors in earlier
  revisions of this map (`PersistTransform`'s container, `Scrub`'s container, `Scrub`'s component
  filter, and the weapons-gate container) were all the *same* dropped-ECX artefact. Any
  `FUN_005857e0` call whose component container is invisible in decompiled C is one instruction
  above it in the raw bytes.
- ⚠ **`output/_ghidra/securom_dump/genuine_patched_unpacked.exe` is a DIFFERENT BUILD.** It sits
  beside the dump and looks like a de-SecuROM'd twin with the stolen bodies restored. It is not:
  **12 sections vs 13**, and `Human.SetState`'s byte stream (`83 EC 0C 53 8B 5C 24 14 …`) lives at
  `0x005BD750` there against `0x005BD760` here — a shift that is **not uniform across regions**, so
  it is a recompile, not a rebase. **A body recovered from it must be discarded.** (`mercs2_nodrm_v1/
  v2/v3.exe` *are* the same build as the dump and carry the same stubs, so they add nothing either.)

**Xbox side — the earlier "thin by construction" claim is REFUTED.** This map used to state that
*"the devkit build exposes no `PgSysHuman`-shaped symbol for the control layer, so there is no
symmetric Xbox↔PC marriage to make"*. Both halves are false:

- `PgSysHumanStateMachine` exists — `docs/mercs2-pdb-analysis/pangea-engine-core.md:55`.
- `HumanStateMachine @ 0x823551E0` is in **the very file this map cited** for "all five are
  physics-step symbols" — `docs/mercs2-pdb-analysis/physics-game.md:243`. That is the exact
  counterpart of PC container `0x00DF9990`, whose registered name is `HumanStateMachine` (§1).
  *(Caveat carried from that file's own §294: the PPC function bearing the name is a system-slot
  registrar, so marry the **container/system**, not a behaviour body.)*
- `PgHumanStateTable` is a first-class Xbox **asset type** (`pangea-engine-core.md:106,118`) —
  independent corroboration of `0xECE70371`.
- `GetTranslationForStanceAndAction` (`output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt:3757`)
  is the two-level stance×action dispatch that `FUN_0068CC00` performs (§2.2).
- **18 of the 21 binding names are contiguous in the devkit strings**
  (`mercs2_xenon_p.pe_full_strings.txt:4076-4092`, bounded above by `Inventory` — the sub-table
  marker, §3.1). Only `Scrub` is absent.

Only the *animation-sampling math* is genuinely Xbox-thin (VMX128/inlined, `animation-skeleton.md:458`).

**Method / honesty model.** Confidence: **H** = read the bytes with a can't-coincide fingerprint (a
named constant, a container global, an offset write) · **M** = one strong structural signal ·
**L/open** = positional, confirm-live. Every offset states the function it was read from.

---

## 0. Result in one line

A **"human" is not one object**: it is a **GUID** joined across many containers, and the two the
`Human` bindings lean on hardest are **named in the file itself** — `0x00DF9990` =
**`HumanStateMachine`**, `0x00DF9A10` = **`HumanAnimationControllerNEW`** — alongside the reflected
ECS components `RTHuman`, `RuntimeAnimationParams`, `PhysicsActor`, `BoneControllerRuntime`,
`RuntimeInventory`, `RuntimePhysicalLink`, `Sticky` and `Label` (§1). The controller's actual state
variable is a **(Stance, Action) pair of name-hashes** at **`humanObj+0x04`** and **`humanObj+0x08`**,
and `FUN_0068CC00(human /*EDI*/, stanceHash, actionHash)` is the single setter that writes both —
**its body is fully recovered** (§2.2): it is the **`HumanStateTable` transition engine**, a
two-level `Find(stance) → Find(action)` over the table handle at `human+0x0C`, which stages a
transition-event record and caches the resolved entries at `+0x18`/`+0x1C`. `Human.Knockdown` is
literally `SetState(Upright, Knockdown)` plus a duration. Action verbs
(`DoAction`/`Emote`/`PlayRawAnimation`) do **not** call a controller: they fill a
`RuntimeAnimationParams` record and post `{guid, nameHash, 0}` onto the **shared command ring**
`FUN_00423d10` — but only `DoAction` is gated, by `DAT_00DFBD77` = **`Net.IsClient`** and
`DAT_00DFBD78` = **`Net.IsServer`** (§5). All 21 bindings are bound to clean `.text` bodies;
**20 of 21 have their effect pinned to a concrete offset, call or container** — `StopGrappling` is
the sole exception. And the two offsets `player_code_map.md` §2.2 left unresolved are **settled:
both are on the PLAYER object** (§9).

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **`Human` `luaL_Reg` array** | 18/21 names @ `mercs2_xenon_p.pe_full_strings.txt:4076-4092` | **`0x00B99EF0`**, **33 rows / 264 B**: 21 cfuncs + `Inventory` markers + 9 + `{NULL,NULL}` | `.rdata` walk from `0x00B99EE8` (`{NULL,NULL}`) to `0x00B99FF0` (§3.1) | H |
| **Human cfunc cluster** | — | **`0x005BD1E0`–`0x005BE890`** (contiguous) | every table slot lands in the range | H |
| **`HumanStateMachine`** | `HumanStateMachine @ 0x823551E0`; `PgSysHumanStateMachine` | container **`0x00DF9990`** (ctor `FUN_00a7c630`, vtable `PTR_FUN_00bc3bc8`) | master key: `[0x00BC3BC8+0x34] = 0x00647620` → `B8 <"HumanStateMachine"> C3`. Stride 4, page shift 7 | H |
| ↳ **Stance field** | — | **`humanObj+0x04`** = Stance name-hash | written at `0x031C00D9` (`mov [edi+4], ecx`); read by `IsSwimming` (`cmp [eax+4], 0x614DB965`) | H |
| ↳ **Action field** | — | **`humanObj+0x08`** = Action name-hash | written at `0x031C00DC` (`mov [edi+8], edx`); read at `0x004FA1DF` (`cmp [ebx+8], 0xB4DA003B` = `Idle`) | H |
| ↳ **HumanStateTable handle** | `PgHumanStateTable` | **`humanObj+0x0C`** | stored by `FUN_00667CB0` at **`0x00667DF7`** (`mov [eax], edx` after `add eax,0xC`); consumed at `0x031C0000` (`mov eax,[edi+0x0C]`) | H |
| ↳ resolved SINF / AINF cache | — | **`+0x18`** (stance record), **`+0x1C`** (action record) | `0x031C00D3`/`0x031C00D6`; nulled at `0x00667E0D` when there is no table | H |
| ↳ transition stamp | — | **`+0x10`** ← `[0x00DCBAD4]` | `0x031C00F7` | H |
| **Stance/Action setter** | `GetTranslationForStanceAndAction` | **`FUN_0068cc00`** → `jmp [0x0245E1D8]` → **`0x031C0000`–`0x031C0112`** | body read in full (§2.2); `bool __stdcall f(EDI = human*, [esp+4] = stance, [esp+8] = action)`, `ret 8` | H |
| **Transition-event ring** | `HumanStateTransition` (`:935`) | **`FUN_0068CF20`**, ring `0x0122ECE8`, count `0x0122ECC0`, cap **`0x400`**, CS `0x012350F0`, gate byte `0x012350E8` | `cmp byte [0x12350E8],0` @ `0x0068CF20`; `cmp eax,0x400` @ `0x0068CF4E`. The native side of Lua `Event.HumanStateTransition` | H |
| **`HumanStateTable` asset** | `PgHumanStateTable` | name hash **and** type hash `0xECE70371`; **561,024 B**, **resident block 3185**, ASET `type_id 33` | `humanstate_probe`: `ASET rows for name 0xECE70371: [(33, true, 3185)]`; exactly **one** archive-wide | H |
| ↳ contents | — | **17 stances / 394 states / 8,744 transitions**, 9,156 chunks, names as ASCII | `humanstate_probe` chunk census: `INFO×1 SINF×17 AINF×394 TRNS×8744` | H |
| **`HumanAnimationControllerNEW`** | `HumanAnimationControllerNEW 128 64` (Xbox pool budget) | container **`0x00DF9A10`** (ctor `FUN_00a7c660`, vtable `PTR_FUN_00bc3c38`) | master key: `[0x00BC3C38+0x34] = 0x00647630` → `"HumanAnimationControllerNEW"` | H |
| ↳ preemptive-ragdoll arm | — | **`+0xC0 = 1`** | `SetPreemptiveRagdoll` `mov byte ptr [eax+0xc0], 1` | H |
| **`RTHuman`** | `RTHuman 128 64` | container **`0x017BF9C8`**, registrar **`FUN_00646540`**, elem `0x48`, page shift 6 | master key → `"RTHuman"`; `PTR_s_RTHuman_017bfa04 = s_RTHuman_00bc5b54` | H |
| ↳ **`HumanPhysics` join** | `HumanPhysics` (`physics-game.md`) | `humanPhys+0x41C = 0x017BF9C8` | `0x00425928  mov dword ptr [edi+0x41c], 0x17bf9c8` — literal | H |
| ↳ facing vector (×2) | — | **`+0x00..0x08`** and **`+0x0C..0x14`** | `PersistTransform` writes the rotation matrix's **third row**, twice (§6.4) | H |
| ↳ knockdown duration | — | **`+0x38`** (f32) | `Knockdown` `movss [eax+0x38], xmm0` @ `0x005BD8F5` | H |
| ↳ carry flag | — | **`+0x3C`, bit 11** (u16) | `IsCarrying` reads it, `Drop` guards on it — two independent sites | H |
| **`RuntimeAnimationParams`** | `RuntimeAnimationParams 8 8` | container **`0x017BF428`**, registrar **`FUN_006457e0`**, elem `0x28`, page shift 3 | master key → name; `DoAction` + `FUN_005bd450` both `mov esi, 0x17bf428; call FUN_00532de0` | H |
| **`PhysicsActor`** | `PgPhysicsActorHuman` | container **`0x017BF888`**, registrar **`FUN_0063d910`**, elem `4`, page shift 8 | master key → name; `IsGrappling` reaches it via `FUN_00432740` | H |
| ↳ grappling flag | — | **`physActor+0x2F4`** | `IsGrappling` `mov dl, [eax+0x2F4]` @ `0x005BDF98` | H |
| **`BoneControllerRuntime`** | `BoneCtrlJostle 8 8` | container **`0x017C00F8`**, registrar **`FUN_006477c0`**, elem `4`, page shift 8 | master key → name | H |
| ↳ jostle flag | — | **`boneCtrl+0xA4`, bit 1** | `SetJostleEnabled` `and al,0xFD; or al,dl` | H |
| **`RuntimeInventory`** | — | container **`0x017BF3D8`** | master key: `[0x00BC2B88+0x34] = 0x006457D0` → `"RuntimeInventory"`. Home of the **weapons gate** and of `Scrub`'s held-item field | H |
| ↳ **weapons-disabled bit** | — | **`RuntimeInventory+0x2C`, bit 3** (set = disabled) | `0x006FC560` is the binary's **sole writer** (§6.1) | H |
| ↳ currently-held item | — | **`RuntimeInventory+0x1C`** | `Scrub` `cmp esi, [edi+0x1c]` @ `0x005BE814` (§7.2) | H |
| **`RuntimePhysicalLink`** | — | container **`0x00DF9110`** | master key: `[0x00BC1F90+0x34] = 0x00644680` → `"RuntimePhysicalLink"` | H |
| **`Sticky`** | — | container **`0x017BE5C8`** | master key: `[0x00BC13B0+0x34] = 0x006438A0` → `"Sticky"`. `Scrub`'s filter | H |
| **`Label`** | — | container **`0x00DF8108`** (ctor `FUN_00a7ac50`, vtable `PTR_FUN_00bbfb58`) | master key: `[0x00BBFB58+0x34] = 0x00641610` → `"Label"`. `SetAllowCorpseCleanup` adds/removes `0xFAF6DA61` | H |
| **`MaterialControllerRuntime`** | — | container **`0x00DF9A90`** | master key → name; **added** by the teardown path (§1.1) | H |
| **Human create / activate** | — | **`FUN_00667cb0`** (1290 B), sole caller **`0x006686D6`** | adds both native blocks and acquires two typed assets | H |
| ↳ acquired assets | — | `0xECE70371` = **`HumanStateTable`**, `0x207359C7` = **`AnimationTable`** | `pandemic_hash_m2` recomputed; both are the **type** halves of an `(assetName, assetType)` acquire | H |
| **Human teardown** | — | **`FUN_006681c0`** (**622 B**, `0x006681C0`–`0x0066842D`, caller `FUN_006686f0`) | removes both native blocks via container vtable `+0x64`, drops `RTHuman` via `FUN_005e0580`, and **adds `MaterialControllerRuntime`** (`0x0066841F push 0xdf9a90; call 0x649180`) | H |
| **Command ring post** | — | **`FUN_00423d10`** — `{guid, hash, 0}`, ring `DAT_012476f0`, cap `0x400`, CS `DAT_0124aef8` | **already owned by [`ai_code_map.md`](ai_code_map.md); cited** | H |
| **Params publish** | — | **`FUN_00532de0`**`(container /*ESI*/, record /*EAX*/, guid)` | both action verbs call it against `0x017BF428` immediately before the ring post | H |
| **`DAT_00DFBD77` = `Net.IsClient`** | — | `Net.IsClient` cfunc **`0x005C67D0`** | `005C67D1  mov bl, byte ptr [0xdfbd77]` — a six-instruction body that pushes that byte as a boolean (§5) | H |
| **`DAT_00DFBD78` = `Net.IsServer`** | — | `Net.IsServer` cfunc **`0x005C6810`** | `005C6811  mov bl, byte ptr [0xdfbd78]` | H |
| **`Player`+`0x158`/`+0x199`** | — | **on the PLAYER object, container `0x00DF9B90` = `Players`** | `mov esi,0xdf9b90; call 0x423dc0` in *both* `FUN_005dfbb0` and `FUN_005dc4f0`; master key names the container **`Players`** — **settles `player_code_map.md` §9.2** | H |

---

## 1. What a "human" is made of

There is no single `Human` struct, and — contrary to an earlier revision of this map — **none of the
containers involved is anonymous.**

> **Correction (old claim struck).** This map used to say the two `0x00DF9xxx` blocks "publish **no
> type-name string**" and filed *"dump their vtables live to give them real names"* as open item
> §10.8. That was wrong, and the cost was a reader sent to a debugger for a **two-instruction static
> read**. Every container in the engine carries its registered name at `[vtable+0x34]` as
> `mov eax,<char*>; ret`. `0x00DF9A10`'s nickname in that revision — *"the ragdoll-arm block"* — was
> also wrong; it is the animation controller, and the actual ragdoll containers are separate
> (`0x017BF928` `PhysicsActorRagdoll`, `0x017C0508` `RagdollController`).

**Names, verified not trusted.** Each row below was produced by reading `*(container)`, then
`[vtable+0x34]`, then checking the target is literally `B8 <imm32> C3` before dereferencing the
string. The four this map already named were re-checked the same way and all four were correct.

| Container | vtable | name stub | Name |
|---|---|---|---|
| `0x00DF9990` | `0x00BC3BC8` | `0x00647620` | **`HumanStateMachine`** |
| `0x00DF9A10` | `0x00BC3C38` | `0x00647630` | **`HumanAnimationControllerNEW`** |
| `0x00DF9B90` | `0x00BC3FB8` | `0x00647BA0` | **`Players`** (§9) |
| `0x00DF9110` | `0x00BC1F90` | `0x00644680` | **`RuntimePhysicalLink`** |
| `0x00DF8108` | `0x00BBFB58` | `0x00641610` | **`Label`** |
| `0x00DF9A90` | `0x00BC3D98` | `0x00647880` | **`MaterialControllerRuntime`** |
| `0x017BF9C8` | `0x00BC32E0` | `0x00646600` | **`RTHuman`** |
| `0x017BF428` | `0x00BC2BD8` | `0x00645890` | **`RuntimeAnimationParams`** |
| `0x017BF888` | `0x00BC31A0` | `0x00648C80` | **`PhysicsActor`** |
| `0x017C00F8` | `0x00BC3D48` | `0x00647870` | **`BoneControllerRuntime`** |
| `0x017BF3D8` | `0x00BC2B88` | `0x006457D0` | **`RuntimeInventory`** |
| `0x017BE5C8` | `0x00BC13B0` | `0x006438A0` | **`Sticky`** |
| `0x017BF928` | `0x00BC3240` | `0x00646530` | **`PhysicsActorRagdoll`** |
| `0x017C0508` | `0x00BC4468` | `0x006481E0` | **`RagdollController`** |
| `0x017BE848` | `0x00BC1A68` | `0x00643DF0` | **`GrappleParameters`** |

The composition the `Human` bindings actually touch:

```
character GUID
 ├─ 0x00DF9990  HumanStateMachine   (ptr, shift 7)  ← Stance @+0x04, Action @+0x08,
 │                                                    StateTable @+0x0C, stamp @+0x10,
 │                                                    SINF @+0x18, AINF @+0x1C
 │                                    SetState, Knockdown, IsSwimming, DoAction
 ├─ 0x00DF9A10  HumanAnimationControllerNEW (ptr, shift 6) ← preemptive ragdoll @+0xC0
 ├─ 0x017BF9C8  RTHuman             (inline 0x48, shift 6) ← facing @+0x00/+0x0C,
 │                                                    kd time @+0x38, carry @+0x3C.11
 ├─ 0x017BF428  RuntimeAnimationParams (inline 0x28, shift 3)  DoAction/Emote/PlayRawAnimation
 ├─ 0x017BF888  PhysicsActor        (ptr, shift 8)  ← grapple flag @+0x2F4
 ├─ 0x017C00F8  BoneControllerRuntime (ptr, shift 8) ← jostle bit @+0xA4.1
 ├─ 0x017BF3D8  RuntimeInventory    ← held item @+0x1C, weapons-disabled @+0x2C.3
 ├─ 0x00DF9110  RuntimePhysicalLink ← the child-object links Scrub walks
 ├─ 0x017BE5C8  Sticky              ← Scrub's filter component
 └─ 0x00DF8108  Label               ← corpse-cleanup marker 0xFAF6DA61
```

> **Correction (old claim struck).** "A human is a GUID joined across **six** containers" was an
> undercount. `FUN_00667CB0` + `FUN_006681C0` alone touch **eight** named containers
> (`PhysicsActor`, `RTHuman`, `HumanStateMachine`, `HumanAnimationControllerNEW`, `SceneObject`,
> `Carryable` `0x017BE758`, `EntranceParameters` `0x017BD858`, `MaterialControllerRuntime`), and the
> 21 bindings add five more. **≥13** is the honest figure; the module around them
> (`0x00666xxx`–`0x0066Bxxx`) references 97 distinct containers in total.

**Stride tells you whether to deref.** Stride 4 = the container stores **pointers** (hence
`mov eax,[eax]` after a lookup); `RTHuman`'s stride `0x48` = **72-byte records inline** (hence
`movss [eax+0x38], xmm0` with no deref). Both shapes appear in the disassembly and agree.

The reflected `0x017Bxxxx`/`0x017Cxxxx` components additionally publish a name at `+0x3C` and follow
the `CopyFromStream` registrar shape [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md)
documents. The `0x00DF9xxx` family does not — `+0x3C` is NULL there, and that is the real content of
the "Controllers/Physics = opaque C++ block" split in [[ecs-component-registry-corpus]]: **not
reflected/serialised, but still named.**

> **Correction.** The earlier generalisation "capacity `0x100`, page shift **8** at `+0x26`" holds
> for only two of the four reflected components. Measured page shifts: `PhysicsActor` 8,
> `BoneControllerRuntime` 8, `RTHuman` **6**, `RuntimeAnimationParams` **3**. The seed `0x9E3779B9`
> at `+0x2C` does hold for all four.

### 1.1 Lifecycle — H

- **Create/activate: `FUN_00667cb0`** (1290 B). Adds both native blocks and — under CS
  `DAT_01174ffc` — issues two `FUN_00874150` typed-asset acquires. Each acquire is an
  `(assetName, assetType)` **pair**: the name half comes from the prototype (`[edi+4]`, `[edi+0]`),
  the type half is the literal **`0xECE70371` = `HumanStateTable`** / **`0x207359C7` =
  `AnimationTable`**. It then installs the state-table handle:

  ```
  00667DA8  mov  ecx, 0xdf9990 ; call 0x6496b0   ; find/create the HumanStateMachine record
  00667DE6  mov  eax, [eax]                      ; the human state object
  00667DE8  mov  edx, [esp+0x24]                 ; the acquired HumanStateTable handle
  00667DF2  add  eax, 0xc
  00667DF7  mov  [eax], edx                      ; ★ human+0x0C = HumanStateTable
  00667DFB  mov  eax, [edi+8] ; mov ecx, [edi+4] ; current Action / Stance
  00667E03  call 0x68cc00                        ; ★ re-run the setter with the SAME pair
  00667E0D  else: mov [edi+0x18], 0 ; mov [edi+0x1c], 0
  00667E18  mov  edi, 0xb4da003b                 ; default Action  = Idle
            ... [esp+0x14] = 0x12c07b18          ; default Stance  = Upright
  ```

  Three consequences worth carrying into a reimpl: **`+0x18`/`+0x1C` are a derived cache** the engine
  re-resolves on table assignment and explicitly nulls when there is no table — never independent
  fields; a fresh human's default state is **`(Upright, Idle)`**; and `FUN_00667cb0` has exactly
  **one** direct caller, at **`0x006686D6`**.

  > **Correction (old claim struck).** "A human's *state vocabulary* is streamed **per-character** at
  > spawn" over-reads this. The *name* half varies per prototype, but for type `0xECE70371` there is
  > exactly **one asset in the whole archive** (§2.3) — every character resolves the same resident
  > table. `AnimationTable` (`0x207359C7`) genuinely does vary: 22 entries over 15 name hashes.

- **Teardown: `FUN_006681c0`** — **622 B** (`0x006681C0`–`0x0066842D`, `int3` pad at `0x0066842E`),
  caller `FUN_006686f0`. *(Old claim: 304 B.)* It removes both native blocks through container vtable
  slot `+0x64` and drops `RTHuman` via `FUN_005e0580(&PTR_PTR_017bf9c8)` — but it is **not purely
  teardown**: at `0x0066841F` it **adds** `MaterialControllerRuntime` (`push 0xdf9a90; call 0x649180`).
  Note the removal slot is **`+0x64`** here and **`+0x70`** in `SetAllowCorpseCleanup` — two different
  container entry points (remove-by-container vs remove-by-key); worth not conflating.

- **Physics activate: `FUN_004255c0`** — **owned by [`physics_code_map.md`](physics_code_map.md)**.
  The one fact this map adds: `0x00425928  mov dword ptr [edi+0x41c], 0x17bf9c8` — the physics actor
  caches the **`RTHuman` container pointer**. That is the concrete edge between the physics map's
  object and this map's.

> **Correction (old claim struck).** "`FUN_00667cb0` and `FUN_0066a2c0` … **neither has a static
> caller**" was half wrong. A full `.text` `E8` scan finds `FUN_00667CB0` ← **1** caller at
> `0x006686D6`; only `FUN_0066A2C0` has none (0 calls, 0 immediate references).

---

## 2. The state variable: Stance + Action

**`humanObj+0x04` holds the Stance and `humanObj+0x08` holds the Action**, both as 32-bit
name-hashes, both on container `0x00DF9990` = `HumanStateMachine`.

> **Correction (gap closed).** Earlier revisions modelled the state as a `(Stance, Action)` pair but
> only ever located the **Stance** field. The Action field is `+0x08`, and it is now proven from
> *both* sides — a binary-wide immediate census finds `[reg+0x08]` compared against Action values at
> 3 sites and never against a Stance value, and the setter's recovered body writes it outright.

Read side, decisive because it is a *paired* test:

```
004FA1D2  cmp dword ptr [ebx + 4], 0x35365d24   ; Stance = KnockedDown
004FA1DF  cmp dword ptr [ebx + 8], 0xb4da003b   ; Action = Idle
```

and at `0x004F973E` the same pair, immediately followed by
`push 0xb4da003b; push 0x35365d24; call 0x68cc00`.

`Human.IsSwimming` is nothing but a one-field compare against the Stance:

```c
rec = <0x00DF9990 page walk on guid>;          // falls back to the shared zero record 0x00DF9A0C
obj = *rec;
push_boolean(obj && *(u32*)(obj + 4) == 0x614DB965);   // pandemic_hash_m2("Swim")
```

**`FUN_0068cc00(human /*EDI*/, stance, action)` is the setter**, called from exactly two places in
this namespace:

| Caller | first arg | second arg |
|---|---|---|
| `Human.SetState` `0x005BD760` | Lua arg 2, hashed | Lua arg 3, hashed |
| `Human.Knockdown` `0x005BD860` | literal **`0x12C07B18`** (`Upright`) | literal **`0x9C9F3F13`** (`Knockdown`) |

```
; Human.SetState tail                        ; Human.Knockdown tail
005BD836  mov esi, 0xdf9990   ; the pool     005BD8E1  mov ecx, 0x17bf9c8   ; RTHuman
005BD83B  call 0x520ef0                      005BD8E6  call 0x5857e0
005BD844  mov edx, [esp+0x10] ; action hash  005BD8F5  movss [eax+0x38], xmm0  ; duration
005BD848  mov ecx, [esp+0x14] ; stance hash  005BD941  push 0x9c9f3f13      ; action
005BD84C  mov edi, [eax]      ; this in EDI  005BD946  push 0x12c07b18      ; stance
005BD84E  push edx ; push ecx                005BD94B  mov edi, eax
005BD850  call 0x68cc00                      005BD94D  call 0x68cc00
```

**`Knockdown` is `SetState` with a fixed pair plus a duration.** Knockdown is not a subsystem; it is
one Action value. `FUN_0068CC00` has **22 direct callers** binary-wide — it is a general engine state
setter, not a Human-Lua-private helper.

The two call sites are type-identical because **`FUN_0059fb00` — the "get string argument" helper —
does not return a `char*`; it returns the name-hash.**

```
0059FB25  call 0x59f990          ; lua_tostring -> const char*
0059FB2A  mov edx, eax
0059FB2C  call 0x824270          ; hash it
0059FB3C  mov dword ptr [ecx], eax   ; *out = HASH
```

> **Correction (old claim struck).** This map called `FUN_00824270` "the engine **name-hash table
> resolver**" and described the value as "**interned**". Neither is true. `FUN_00824270` **is
> `pandemic_hash_m2` itself** — a pure computation with no table, no registry, nothing to miss:
>
> ```
> 00824280  movsx ecx, cl        ; 00824298  xor  eax, 0x2a           ; the M2 finaliser
> 00824283  or    ecx, 0x20      ; 0082429B  imul eax, eax, 0x1000193
> 00824286  xor   eax, ecx       ; 008242A1  ret
> 00824288  mov   cl, [edx+1]    ; 008242A2  xor  eax, eax ; ret      ; NULL/empty -> 0
> 0082428B  imul  eax, eax, 0x1000193
> ```
>
> The FNV basis is loaded at `0x004BDFB6` from the SecuROM slot `[0x0245D6D8]`, which in the dump
> reads **`0x811C9DC5`** — the standard FNV-1a offset basis, i.e. exactly what
> `tools/pandemic_hash.py --m2` uses. The genuine *resolver* is a separate open-addressed probe at
> `0x008242B0` which `FUN_0059FB00` never calls. The conclusion the map drew from this — that a
> cfunc "taking a string" is really storing a 32-bit id — **stands**; only the mechanism was wrong,
> and it matters because "interned" implies a registry lookup that could miss.

### 2.1 The join to clip selection

[`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md) §1
documents the resident **ActionTable `0x6802C321`** (1020 rows, 14 columns) whose first three key
columns are **`Stance, Action, AimState`**. This map reaches the same constants from the *opposite*
direction — literals inside Lua bindings and the engine's own state setter — which is why
`Stance 0x12C07B18 = "Upright"` is independently corroborated rather than merely plausible.

But the join is **not** binding → ActionTable. It is binding → **`HumanStateTable`** → (downstream)
ActionTable, and the difference matters enough that it invalidated two of this map's earlier
vocabulary claims. §2.2 recovers the setter that walks the state graph, §2.3 measures the two tables
against each other from shipped data, and §2.4 gives the resulting vocabulary — all 18 Stance values
named, which retires that doc's "⏳ Name the remaining ActionTable state-value hashes" for the Stance
column.

### 2.2 `FUN_0068CC00` is the HumanStateTable transition engine — H

> **Correction (old claim struck), and the most consequential one in this map.** §8 used to file
> this function as **"partly followed"** and its dispatch as *"obfuscated"*; a prior validation pass
> went further and called it **"SecuROM-stolen … its internals are not statically readable in this
> dump."** Both are wrong. `mercs2_unpacked.exe` is a **live memory dump**; the indirect slot is
> already resolved on disk. Two reads recover the whole body.

```
0068CC00  ff25d8e14502   jmp dword ptr [0x245e1d8]
[0x0245E1D8] = 0x031C0000                  ; inside .securom, plain relocated code
```

The complete body, `0x031C0000`–`0x031C0112` (275 B), disassembled:

```
031C0000  mov  eax, [edi+0x0c]          ; edi = human; +0x0C = the HumanStateTable handle
031C0006  test eax, eax ; je fail
031C0011  lea  ebx, [eax+0x18]          ; &table.stanceMap  (level-1 map at table+0x18)
031C0014  mov  eax, [esp+0x30]          ; arg1 = stanceHash
031C0018  push eax ; mov ecx, ebx       ; __thiscall Find(stanceMap, stanceHash)
031C001B  push 0x31c0032 ; jmp 0x31c0032    ; -> encrypted-call trampoline, returns to 0x31C004D
031C004D  test eax, eax ; jl fail       ; eax = index, negative = miss
031C0055  mov  ecx, [ebx]
031C0057  mov  ebx, [ecx+eax*4]         ; ebx = level-1 (Stance) entry ; je fail if null
031C0062  mov  esi, [esp+0x34]          ; arg2 = actionHash
031C0066  push esi ; mov ecx, ebx       ; __thiscall Find(stanceEntry, actionHash)
031C0069  push 0x31c007c ; push 0x68d270 ; ret     ; = call FUN_0068D270
031C007E  jl   fail
031C0084  mov  edx, [ebx]
031C0086  mov  ebp, [edx+eax*4]         ; ebp = level-2 (Action) entry ; je fail if null
          ; stage a 0x18-byte transition record at [esp+0x10]:
          ;   [0x10]=[edi+0]  [0x14]=stance  [0x18]=action
          ;   [0x1C]=[edi+4] old stance  [0x20]=[edi+8] old action  [0x24]=0
031C00A1  lea  esi, [esp+0x10]          ; ← REGISTER ARG (Ghidra drops it)
031C00B9  push 0x31c00cb ; jmp 0x68cf20 ; = call FUN_0068CF20(esi = &record)
031C00D3  mov  [edi+0x18], ebx          ; ★ resolved Stance (SINF) entry
031C00D6  mov  [edi+0x1c], ebp          ; ★ resolved Action (AINF) entry
031C00D9  mov  [edi+0x04], ecx          ; ★★ STANCE HASH
031C00DC  mov  [edi+0x08], edx          ; ★★ ACTION HASH
031C00E2  mov  eax, 0x6be45b87 ; xor eax,[0x245fc80] ; call eax   ; -> 0x01A53D80 notify veneer
031C00F7  mov  eax, [0x00DCBAD4] ; mov [edi+0x10], eax            ; transition stamp
031C00FF  mov  al, 1 ... ret 8          ; TRUE
031C010A  fail: xor al, al ... ret 8    ; FALSE
```

The obfuscated targets all resolve out of the dump — each is one arithmetic step, reproducible:

| Site | Encoding | Reads | Resolves to |
|---|---|---|---|
| `0x031C0033` | `~[0x0245A63C] ^ [0x02479B4A]` | `~0x62CFD208 ^ 0x9D58FF87` | **`0x0068D270`** |
| `0x031C006E` | literal `push 0x68d270; ret` | — | **`0x0068D270`** |
| `0x031C00BE` | literal `jmp 0x68cf20` | — | **`0x0068CF20`** |
| `0x031C00E2` | `0x6BE45B87 ^ [0x0245FC80]` | `^ 0x6A416607` | **`0x01A53D80`** (`Stext`) |

**What this settles.**

1. The **signature** is confirmed from the body, not inferred from call sites:
   `bool __stdcall FUN_0068CC00(EDI = human*, [esp+4] = stanceHash, [esp+8] = actionHash)`, `ret 8`.
   `this` in **EDI** is exotic and Ghidra would drop it.
2. `human+0x04` and `+0x08` are written here, unconditionally, on the success path.
3. `human+0x0C` is the **`HumanStateTable` handle** and the table is a **two-level
   Stance → Action → record map** with the level-1 map at `table+0x18`.
4. **`FUN_0068CF20` is a transition-event recorder.** Gated on byte `[0x012350E8]`, it appends the
   staged `0x18`-byte `{obj, newStance, newAction, oldStance, oldAction, 0}` record to a
   **`0x400`-entry ring at `0x0122ECE8`** (count `0x0122ECC0`) under CS `0x012350F0`. This is the
   **native side of the Lua `Event.HumanStateTransition`** the script corpus subscribes to.

**Honest limit — one VM stub remains.** `FUN_0068D270`, the hash-map `Find` used for *both* levels,
is `jmp [0x02459C4C] → 0x024E3590 →` a `push … call 0x01AAFF10` SecuROM-interpreter dispatch. It does
not matter for the model: `Find` is a keyed lookup returning an index or a negative miss, which both
call sites establish unanimously and which the container's on-disk shape (§2.3) confirms.

### 2.3 The two state tables, measured — §10.2 is CLOSED

> **Old claim struck.** This map nominated the `HumanStateTable`-vs-`ActionTable` relationship as
> *"the highest-value open item"* and filed it as live work — *"dump the streamed asset once the
> human spawns"*. No debugger is needed: the asset ships in `vz.wad`. Run
> `MERCS2_VZ_WAD=… cargo run -q -p mercs2_probe --bin humanstate_probe`.

**Location.** Exactly **one** `HumanStateTable` exists archive-wide: name hash **and** type hash both
`0xECE70371` (the asset's name *is* `"HumanStateTable"`), **561,024 B**, **resident block 3185** — the
same block that carries the ActionTable. ASET `type_id 33`. Zero copies in `shell.wad` /
`English.wad` / `English-patch.wad` / `Loading.wad`.

**Schema — not a dim table.** No `TYPE`/`VALU` chunks, so the ActionTable decoder does not apply. It
is a flat ordered chunk stream of **9,156 chunks**, and it ships the state names as **ASCII**:

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
> record, `human+0x1C` = the resolved **AINF** record. The setter's two-level `Find` and the
> container's two-level chunk nesting are the same shape, derived independently from opposite ends.

**The relationship, measured.** The two are halves of one system joined on `(Stance, Action)` over a
shared name-hash vocabulary:

- **`HumanStateTable` = the authoritative state graph.** It declares which 394 `(stance, action)`
  states exist, their per-state behaviour flags, and the 8,744 event-driven edges between them. It is
  what `FUN_0068CC00` walks, and the only asset in the archive that ships the state names as text.
- **`ActionTable` = a decoration table on top of it.** 1,020 rows whose 6-column key *extends* the
  same pair with `AimState/Tandem/Seat/Target/ActionDirection/DamageDirection`, attaching
  `AnimationHandles` and the partition/looping/driven masks, with `*` as don't-care.
- **Join:** of the ActionTable's 387 distinct `(Stance, Action)` pairs, **377 are declared states**,
  2 are wildcard, 8 are not declared (7 of those carry uncracked Action hashes; the one genuine
  mismatch is `Crouched/Grapple`, which the state graph declares under `InAir`). Conversely 377 of
  394 states have an exact row and **17 do not**.

So the map's original §2.1 guess — *"most likely the former declares the legal Stance/Action
vocabulary and transitions and the latter maps a key to clip handles, but that is inference, not a
read"* — is **exactly right, and is now a read**. The warning box below stands and is strengthened.

> **Do not confuse the two state tables.** `HumanStateTable` (`0xECE70371`) is the state graph;
> `ActionTable` (`0x6802C321`) is the clip-selection decoration on top of it. They share a
> vocabulary, not a schema.

### 2.4 The vocabulary — Stance is 18/18 named

Because the state graph ships its names as ASCII, the whole Stance column falls out at once. Every
name below was re-verified with `tools/pandemic_hash.py --m2` rather than taken from the container's
own string:

| Hash | Name | states/transitions | ActionTable rows |
|---|---|--:|--:|
| `0x12C07B18` | `Upright` | 111/3737 | 171 |
| `0x5E2CD838` | `InVehicle` | 174/3169 | 740 |
| `0xC8886020` | `Crouched` | 29/861 | 37 |
| `0x614DB965` | `Swim` | 12/208 | 12 |
| `0x4BE8214B` | `Scuba` | 12/210 | 9 |
| `0x22948D2A` | `OnLadder` | 8/83 | 8 |
| `0x4416D310` | `InAir` | 7/138 | 6 |
| `0xFC8D859D` | `Prone` | 6/86 | 6 |
| `0xE2FC8CB1` | `Carried` | 6/46 | 6 |
| `0x35365D24` | `KnockedDown` | 5/38 | 3 |
| `0xB9832CE2` | `UprightCoverLeft` | 4/29 | 4 |
| `0x42C96259` | `UprightCoverRight` | 4/29 | 4 |
| `0x403991E8` | `CrouchCover` | 4/29 | 3 |
| `0x1E5B33F7` | `Cower` | 4/22 | 2 |
| `0xE7B64876` | `Carrying` | 3/16 | 3 |
| `0x67EAAA1B` | `Subdued` | 3/15 | 1 |
| `0xBC671C97` | `HumanShield` | 2/28 | 2 |
| **`0x27DE7135`** | **`*`** | — (ActionTable only) | 3 |

The Action column goes from ~2 named to **296 of 303**, from this container's string pool alone. The
7 residual ActionTable Action hashes (`0xA3C54951`, `0xDA882AB8`, `0xF2F71296`, `0xF37538A1`,
`0x1930E5FF`, `0xA7E56A1B`, `0xBBA5334E`) survived a brute force over all 826,229 ASCII runs in
resident block 3185 and belong to
[`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md),
not here.

> **Correction (old claim struck): `0x27DE7135` is `pandemic_hash_m2("*")` — a WILDCARD, not a "NONE
> sentinel".** It is the literal asterisk string, and the shipped tables use it as one: **1012 of
> 1020** `AimState` cells, **961 of 1020** `ActionDirection`. The Lua corpus writes it the same way
> in dotted `Stance.Action` filters —
> `Event.HumanStateTransition, { filter, "KnockedDown.*", "Upright.*" }`
> (`mrxtaskobjectiveverify.lua:45-53`). It does **not** occur anywhere in the HumanStateTable's
> 371-string pool: it is a key-matching device belonging to the decoration table, which is why the
> state graph has no need of it. `mercs2_core::ANY_STATE`'s doc comment now says so.

> **Correction (old claim struck): `Knockdown` is not "a new value for the ActionTable's open
> vocabulary".** `0x9C9F3F13` does **not** appear anywhere in the shipped ActionTable — not in its
> 303 Action values, not in Stance. It is a **HumanStateTable state**: `ACTION KnockDown` under
> stance `Upright` (`trns=25`, flags `[FALSE,FALSE,FALSE,TRUE,TRUE,FULL]`), plus 136 uses as a TRNS
> *event* and 320 as a TRNS *target action*. There is **no anomaly to explain**: it is one of **17
> declared states with no exact ActionTable row** (alongside `Upright/MeleeASubdue`,
> `Upright/GrappleStandup`, `Cower/Die`, `Cower/Dead`, `KnockedDown/Die`, `Subdued/Dead` and five
> `Scuba` grenade actions). Those states are legal to *enter*; their clip is then selected by a
> **wildcard** ActionTable row rather than an exact one. The tell is that the ActionTable *does*
> carry `0x35365D24 = KnockedDown` in its **Stance** column — the stance you end up in — while
> `Knockdown` is the action that puts you there. Two words, two tables.
> (`KnockDown` and `Knockdown` both hash to `0x9C9F3F13`; the container uses both spellings.)

The Lua corpus corroborates the model from a third direction. `Human.SetState` arg-2 values across
the corpora are exactly stance-shaped — `"Upright"`, `"InVehicle"`, `"Cower"`, `"Subdued"` — and all
four are declared stances. The complete `Stance.Action` literal set in the corpora is `Swim.*` ×3,
`Upright.*` ×2, `Upright.TriggerDetonator`, `Subdued.Idle`, `subdued.idle`, `KnockedDown.Idle`,
`KnockedDown.*`, `InVehicle.*` — script-level attestation of the `(Stance, Action)` model, of
`Event.HumanStateTransition`, and of the wildcard. **H.**

> **Correction.** `Swim`'s master-table row used to carry one `H` covering two claims, the second of
> which — *"sole use is `Human.IsSwimming`"* — is false. `0x614DB965` occurs at **10 `.text` sites**
> (`0x004AD620, 0x0052A050, 0x005344EE, 0x00555A61, 0x0058B776, 0x005BDCB1, 0x005FCC0A, 0x005FCCF2,
> 0x00689BE7, 0x0069C257`), in 12 ActionTable rows, and in 3 Lua `"Swim.*"` filters. The *name* is
> H; the *sole-use* claim was never evidenced.

---

## 3. The 21 bindings — name → VA → body → effect

Cfuncs are `undefined4 f(lua_State *L)`; args via `FUN_0059ff50` (GUID/lightuserdata),
`FUN_0059f6d0` (boolean), `FUN_0059f780` (number), `FUN_0059fb00` (**string → name-hash**, §2);
results via `FUN_0085d5d0` (reserve) + the `*(L+8) += 8` push idiom, `FUN_004b86e0` (push boolean),
errors via `FUN_004b2a50`.

**⬤ = Ghidra decompiled (9)** · **◐ = no Ghidra entry point, read by first-hand disassembly of the
image (12)** · *base/dlc* = script call sites in `docs/mercs2-luacd/` (370) and
`docs/mercs2-dlc-luacd/` (75), re-counted this pass.

| # | Name | VA | | base | dlc | Signature (from Lua corpus) | Effect | Conf |
|--:|---|---|:-:|--:|--:|---|---|:-:|
| 0 | `DoAction` | `0x005BD260` | ⬤ | 6 | 2 | `(guid, sAction)` | fill `RuntimeAnimationParams`; ring-post `{guid, hash(sAction), 0}`, `IsClient`/`IsServer` gated (§5) | H |
| 1 | `SetState` | `0x005BD760` | ◐ | 21 | 3 | `(guid, sStance, sAction)` | `FUN_0068cc00(human, stanceHash, actionHash)` (§2, §2.2) | H |
| 2 | `Knockdown` | `0x005BD860` | ⬤ | 4 | 0 | `(guid, nDuration)` → bool | `RTHuman+0x38 = nDuration`; `FUN_0068cc00(human, Upright, Knockdown)` | H |
| 3 | `SetPreemptiveRagdoll` | `0x005BD9B0` | ◐ | 4 | 0 | `(guid)` | `HumanAnimationControllerNEW` → **`obj+0xC0 = 1`** (unconditional; no value arg) | H |
| 4 | `ForceExitSeatNoSnap` | `0x005BD1E0` | ◐ | 8 | 2 | `(guid)` | `FUN_0053ad30(guid, 0)` — the vehicle module's seat-exit (`vehicle_code_map`) | H |
| 5 | `Emote` | `0x005BD740` | ◐ | 0 | 0 | `(guid, sName, bFullBody, …)` — **8 args** | **16-byte thunk** → `FUN_005bd450(L, 0)`; **not** net-gated (§5) | H |
| 6 | `PlayRawAnimation` | `0x005BD750` | ◐ | 5 | 4 | `(guid, sAnim, bLoop, bBlend, nBlendTime, b, b)` — **7 args**, last 2 optional, returns bool | **16-byte thunk** → `FUN_005bd450(L, 1)`; **not** net-gated | H |
| 7 | `PersistTransform` | `0x005BDA70` | ⬤ | 3 | 2 | `(guid)` → true | latches the **facing vector** into `RTHuman+0x00..0x08` **and** `+0x0C..0x14` (§6.4) | H |
| 8 | `IsSwimming` | `0x005BDC00` | ◐ | 2 | 0 | `(guid)` → bool | `human+0x04 == hash("Swim")` (§2) | H |
| 9 | `IsCarrying` | `0x005BDD10` | ◐ | 3 | 2 | `(guid)` → bool | **`RTHuman+0x3C` bit 11** | H |
| 10 | `Drop` | `0x005BDDD0` | ⬤ | 3 | 2 | `(guid, bForce)` → bool | guard on `RTHuman+0x3C` bit 11, then `FUN_004f9e10(bForce)` | H |
| 11 | `IsGrappling` | `0x005BDF00` | ◐ | 2 | 1 | `(guid)` → bool | `FUN_00432740(guid)` → `PhysicsActor` native object → **`+0x2F4`** | H |
| 12 | `StopGrappling` | `0x005BDFC0` | ⬤ | 2 | 1 | `(guid)` | builds a 13-byte record in **ECX**, hands it to `FUN_005BF7E0` — **interpreter-dispatched** (§8) | M / **effect open** |
| 13 | `EnableWeapons` | `0x005BE220` | ◐ | 2 | 0 | `(guid)` | **16-byte thunk** → `FUN_005be050(L, 1)` → **clears `RuntimeInventory+0x2C` bit 3** (§6.1) | H |
| 14 | `DisableWeapons` | `0x005BE230` | ◐ | 25 | 2 | `(guid)` | **16-byte thunk** → `FUN_005be050(L, 0)` → **sets `RuntimeInventory+0x2C` bit 3** (§6.1) | H |
| 15 | `SetFireLock` | `0x005BE240` | ◐ | 4 | 0 | `(guid, bLock)` → true | `FUN_00529d50(guid /*EAX*/, bLock)` | H |
| 16 | `EquipWeapon` | `0x005BE340` | ⬤ | 0 | 0 | `(charGuid, weaponGuid)` → bool | slot `+0x0C` / `+0x10` on `Equipment`/`RuntimeInventory`; `FUN_00527730` (primary) or `FUN_00527c70` (secondary), rollback on failure (§6.1) | H |
| 17 | `StowWeapon` | `0x005BE4C0` | ⬤ | 0 | 0 | `(charGuid, weaponGuid)` → bool | matches against current primary/secondary, then `FUN_00527540` / `FUN_00527c70` (§6.1) | H |
| 18 | `SetAllowCorpseCleanup` | `0x005BE5F0` | ⬤ | 3 | 0 | `(guid, bAllow)` → constant `true` | `bAllow == false` **adds** `Label` `0xFAF6DA61`; `true` removes it via vtable `+0x70` (§7.1) | H |
| 19 | `Scrub` | `0x005BE730` | ⬤ | 1 | 1 | `(guid)` → 0 values | detach every **`Sticky`** child physically linked to the character except the held item (§7.2) | H |
| 20 | `SetJostleEnabled` | `0x005BE890` | ◐ | 1 | 1 | `(guid, bOn)` | gate on `BoneControllerRuntime`; collect ≤32 via `FUN_00685c90(0xE551D91A = hash("StrapOn"), …)`; **`+0xA4` bit 1** | H |

**Traffic.** `DisableWeapons` 27 · `SetState` 24 · `ForceExitSeatNoSnap` 10 · `PlayRawAnimation` 9 ·
`DoAction` 8 (base+DLC) — a cutscene/hijack-driver profile, not a locomotion one. **Three have zero
call sites in either corpus** (`Emote`, `EquipWeapon`, `StowWeapon`) and the census is exhaustive —
there is no `Human[...]` dynamic dispatch anywhere. `EquipWeapon` also exists on the `Inventory`
sub-table, which is what scripts actually use. There is also a **DLC-only `Human.SetChatterSet(guid,
sSet)`** with 7 call sites that is **not** among the 21 in this build.

**Arity is proven from the body, not the corpus.** `FUN_005bd450` reads, in order: GUID
(`FUN_0059ff50`), string→hash (`FUN_0059fb00`), **[one extra boolean, only when `param_2 == 0`]**,
boolean, boolean, number, boolean, boolean. The conditional is explicit:

```
005BD512  cmp  byte ptr [ebp+0xc], 0     ; param_2 (the 0/1 mode selector)
005BD516  lea  esi, [eax+2]              ; esi = running argument cursor
005BD519  jne  0x5bd537                  ; param_2 == 1 -> SKIP the third boolean
005BD524  call 0x59f6d0                  ; the extra boolean -> bl
```

So `PlayRawAnimation` (`param_2 == 1`) = **7 args** and `Emote` (`param_2 == 0`) = **8 args**, **H**
for both — the earlier `M` on `Emote`'s arity is retired, since the proof is in the byte stream and
does not depend on script call sites. The extra boolean `bl` is precisely the §5 command-id selector,
so **`Emote`'s third argument is a full-body flag** (the two ids are `Emote` and `emotefullbody`).
Corpus notes: `PlayRawAnimation` returns a boolean (`mrxbriefing.lua:2326`) and one site passes only
6 args (`danceradio.lua:39`), so args 6–7 are optional; `SetAllowCorpseCleanup` pushes a constant
`{1,1}` at `0x005BE70F`, so the `tostring(...)` wrapper at `mrxtaskobjectiveverify.lua:227` is always
`"true"`.

### 3.1 The array is 33 rows, and `Human.Inventory` is a SUB-TABLE — H

> **Correction (old claim struck).** The boundaries table and §11 used to state that
> *"the `Human.Inventory` table is a **separate `luaL_Reg` at `0x00B99FA0`**"*. There is no table at
> `0x00B99FA0` — that address is **row 22** of the `Human` array. The error was inherited from
> `mods/lua_trace_asi/reference/binding_map.json`, whose `.rdata` walk stops at the marker row and
> therefore reports two tables. **The bytes were not read.** Reading them:

| Row | Address | name | cfunc |
|--:|---|---|---|
| 0–20 | `0x00B99EF0`–`0x00B99F90` | the **21** `Human.*` cfuncs | `0x005BD260`…`0x005BE890` |
| **21** | **`0x00B99F98`** | `"Inventory"` | **`0xFFFFFFFF`** — sub-table **OPEN** marker |
| 22–30 | `0x00B99FA0`–`0x00B99FE0` | the **9** `Human.Inventory.*` cfuncs | `GetPrimaryWeapon 0x005BE9B0`, `GetSecondaryWeapon 0x005BEB30`, `GetVehicleWeapon 0x005BECB0`, `GetAllWeapons 0x005BED60`, `SetAllWeapons 0x005BF160`, `DropWeapon 0x005BF420`, `EquipWeapon 0x005BF4E0`, `ReloadAll 0x005BF6B0`, `DestroyAllWeapons 0x005BF630` |
| **31** | **`0x00B99FE8`** | `"Inventory"` | **`0xFFFFFFFE`** — sub-table **CLOSE** marker |
| 32 | `0x00B99FF0` | `NULL` | `NULL` — array terminator |
| — | `0x00B99FF8` | already the **`_GuiInternal`** table (`CreateWidget`, …) | |

**33 rows / 264 bytes / 30 cfuncs.** The array is preceded by a `{NULL,NULL}` at `0x00B99EE8`, so
`0x00B99EF0` really is the start. The namespace registry (`0x00DFD478`, 12-byte
`{name, luaL_Reg*, doc}` triples) contains **exactly one** pointer into this array —
`{"Human", 0x00B99EF0, …}` — and a file-wide search for pointers to `0x00B99FA0` finds **none**.

Two things follow. First, `{name, 0xFFFFFFFF}` / `{name, 0xFFFFFFFE}` is a **general marker-row
convention** in this binary's `luaL_Reg` arrays; any tool walking `.rdata` must model it or it will
split one namespace into two. Second — the practical conclusion the map already drew still holds:
**do not fold the 9 into the 21.** They are a child namespace, not siblings.

**`EquipWeapon` appears twice under the same name pointer.** Rows `0x00B99F70` and `0x00B99FD0` both
point at name string `0x00BB6730`, with **different cfuncs** `0x005BE340` (`Human.EquipWeapon`) and
`0x005BF4E0` (`Human.Inventory.EquipWeapon`). The duplication is visible in the table itself.

---

## 4. Two facts about the cfunc prologue worth recording

1. **Four of the 21 are 16-byte tail thunks** — `Emote`/`PlayRawAnimation` → `FUN_005bd450` and
   `EnableWeapons`/`DisableWeapons` → `FUN_005be050` — each of the form
   `mov eax,[esp+4]; push <0|1>; push eax; call <worker>; add esp,8; ret`. *(An earlier revision said
   "three" and then listed four.)* Ghidra never emitted them as functions, which is precisely why
   they showed as "missing bodies". A reimpl should model each pair as **one function with a mode
   flag**, not two.
2. **`FUN_0059fb00` returns a name-hash, not a string** (§2). Any cfunc in this cluster that looks
   like it is passing a `const char*` is passing a 32-bit id.

---

## 5. The command path — `DoAction` / `Emote` / `PlayRawAnimation`

The three action verbs share the *publish* half and **none of them calls a character controller**:

```
1.  fill a 0x28-byte RuntimeAnimationParams record on the stack
    (blend time float, loop/blend booleans, the raw-anim name-hash)
      ↓
2.  005BD3CC  mov esi, 0x017BF428      ; RuntimeAnimationParams container
    005BD3D1  call FUN_00532de0        ; publish the record against the character GUID
```

but **only `DoAction` is network-gated**:

```
3.  005BD3D6  cmp byte ptr [0x00DFBD77], bl   ; ← Net.IsClient : if NOT a client…
    005BD3F2  call FUN_00423d10              ;   …ring-post {guid, nameHash, 0}
4.  005BD3F7  cmp byte ptr [0x00DFBD78], bl   ; ← Net.IsServer : if a server…
    005BD3FF  memset(payload, 0, 0x38); payload[0] = 0x1E;   //   …also replicate, msg id 0x1E
              thunk_FUN_024e96c0(...); FUN_006f8520(); thunk_FUN_00526847(payload);
```

> **Correction (old claim struck).** The map used to say all three verbs "share one shape",
> gates included. They do not. A file-wide immediate scan finds `DAT_00DFBD77` at **exactly one**
> site in the whole `0x005BD200`–`0x005BD800` span (`0x005BD3D6`) and `DAT_00DFBD78` at exactly one
> (`0x005BD3F7`) — **both inside `DoAction`'s own body**. The shared worker `FUN_005BD450`
> (`0x005BD450`–`0x005BD73F`) that `Emote` and `PlayRawAnimation` call reads **neither**. So
> `Emote`/`PlayRawAnimation` are **not** client-gated and **not** replicated. Given what the gates
> turn out to be (below), that is a real behavioural difference a reimpl must preserve.

**The gates are named by the engine itself — §10.3 is CLOSED, and this map's reading was right.**

```
; Net.IsClient   luaL_Reg 0x00B99900 -> cfunc 0x005C67D0
005C67D1  mov bl, byte ptr [0xdfbd77]     ; …test bl,bl; setne cl; push_boolean(cl)

; Net.IsServer   luaL_Reg 0x00B99908 -> cfunc 0x005C6810
005C6811  mov bl, byte ptr [0xdfbd78]
```

Each cfunc is a six-instruction body that does nothing but push that byte as a boolean. This is not
inference. **Five consecutive `Net` accessors sit over five consecutive bytes** — `Net.IsEnabled`
`0x005C6710` reads `[0xDFBD74]`, `IsActive` `0x005C6750` → `75`, `IsLobby` `0x005C6790` → `76`,
`IsClient` `0x005C67D0` → `77`, `IsServer` `0x005C6810` → `78`, each with the identical
`mov bl, byte ptr [0xdfbd7X]` prologue. The publisher `FUN_006CECF0` shows they are one-hot decodes
of a single session-mode enum at `[session+0x0C]`:

```
006CEDC1  mov  edx, [edi+0x24]     ; the net-session object
006CEDC4  mov  eax, [edx+0x0c]     ; ★ session MODE enum
006CEDC7  cmp  eax, 4 ; sete cl    -> [esp+0x16]      (IsLobby)
006CEDCD  cmp  eax, 1 ; sete dl    -> [esp+0x17]      (IsClient)
006CEDDA  cmp  eax, 2 ; sete al    -> [esp+0x18]      (IsServer)
006CEEB4  movq xmm0, [esp+0x14] ; movq [0x00DFBD74], xmm0   ; commits 0x74..0x7B in one shot
```

| Global | Meaning | Lua accessor |
|---|---|---|
| `0x00DFBD74` / `75` | session valid / active | `Net.IsEnabled` `0x005C6710` / `Net.IsActive` `0x005C6750`; `Net.IsMultiplayer` `0x005C66C0` tests `[0x74] == 1` |
| `0x00DFBD76` | `mode == 4` | `Net.IsLobby` `0x005C6790` |
| **`0x00DFBD77`** | **`mode == 1`** | **`Net.IsClient`** `0x005C67D0` |
| **`0x00DFBD78`** | **`mode == 2`** | **`Net.IsServer`** `0x005C6810` |

`DoAction`'s shape now reads perfectly: *if not a client, apply locally; if a server, also
replicate.* Offline (`mode == 0`) applies locally and sends nothing; a pure client neither applies
nor sends — it waits for the server's replicated command.

> **Corrections this map owes its siblings.** This map's "local-apply gate / replicate gate" reading
> was **correct in effect** and is now correct in name. But
> [`player_code_map.md`](player_code_map.md) §7 and
> [`object_entity_core_code_map.md`](object_entity_core_code_map.md) describe `DAT_00DFBD77` as a
> **"shutdown/teardown guard"**, which is **wrong and should be struck**: the early-outs they cite
> (`RemoveBoundary`, `Object.Remove`, `Pg.UnloadLayer`) are *client* guards — a client must not
> authoritatively destroy or unload. The recurring companion test `(guid & 0xF0000000) == 0x40000000`
> is a **networked-object GUID tag**, which is why it always appears beside `IsClient`.
> [`mission_contract_flow_code_map.md`](mission_contract_flow_code_map.md)'s "net host/client flags"
> is **correct**.

The ring at step 3 is **not new** — it is the `{guid, hash, 0}` command ring
([`ai_code_map.md`](ai_code_map.md): `FUN_00423d10`, `DAT_012476f0`, cap `0x400`, 12-byte records
under CS `DAT_0124aef8`) that [`vehicle_code_map.md`](vehicle_code_map.md) §2 also rides. **This
map's contribution is the Human ids on it:**

| Command id | Meaning | Where read |
|---|---|---|
| `hash(sAction)` | `DoAction` — the action name is *itself* the id | `FUN_005bd260` @ `0x005BD3EA` |
| **`0xDE9D82CB`** = `pandemic_hash_m2("Emote")` | `Emote` with its 3rd arg false/absent | `FUN_005bd450` @ `0x005BD6FA` |
| **`0x03DD7B78`** = `pandemic_hash_m2("EmoteFullBody")` | raw-animation play (`PlayRawAnimation` always; `Emote` when arg 3 is true) | same site, `0xDE9D82CB + 0x253FF8AD` |

The selector is computed branchlessly — `ebx = (-(flag != 0) & 0x253FF8AD) + 0xDE9D82CB` — which is
why the second id never appears as a literal. **`0x03DD7B78` is now named: `EmoteFullBody`.** It is
not a guess and not a dictionary hit: it is a **declared `HumanStateTable` action name**, shipping as
ASCII under two stances (`trns=17` and `trns=76`) right beside `Emote` in the same container, and it
recomputes under `pandemic_hash.py --m2`. Both ids also appear in the shipped ActionTable's Action
column (2 rows each). *(The lower-case form `emotefullbody` at `docs/data/wad_vocab.txt:77580` hashes
identically — the hash is case-suppressing — but the container's `EmoteFullBody` is canonical.)*
That in turn names `Emote`'s third argument: it is a **full-body flag**, and `PlayRawAnimation` is
permanently in full-body mode.

---

## 6. Carry, weapons, grapple, transform

### 6.1 Weapons — H

Two separate axes, and both now have a home.

**Slots.** `EquipWeapon` / `StowWeapon` take **two GUIDs** (character, weapon) and resolve **two**
component records via `FUN_005857e0` (`Equipment` and `RuntimeInventory`). The equip record holds:

| Off | Field | Read from |
|---|---|---|
| `+0x00` | current **primary** weapon GUID | `FUN_005be340` (`*piVar3 != local_4` test) |
| `+0x04` | current **secondary** weapon GUID | `FUN_005be340` |
| `+0x0C` | **primary slot** write target | `FUN_005be340` (`piVar3[3] = weapon`) |
| `+0x10` | **secondary slot** write target | `FUN_005be340` (`piVar3[4] = weapon`) |

`EquipWeapon` picks primary vs secondary on `*piVar4 == 0`, writes the slot, calls
**`FUN_00527730(charGuid)`** (primary) or **`FUN_00527c70(charGuid, 0)`** (secondary), and **restores
the previous GUID if the call returns false** — a genuine transactional rollback worth preserving.
`StowWeapon` reads the current primary through the interpreter-dispatched `thunk_FUN_024e8df0` and
stows via **`FUN_00527540`** or the same `FUN_00527c70`. The `0x00527xxx` cluster is weapon-state and
belongs to [`weapons_combat_code_map.md`](weapons_combat_code_map.md).

**The gate — `EnableWeapons` / `DisableWeapons`, effect CLOSED.** The map used to file these as its
two unpinned effects. The shared worker `FUN_005be050` is genuinely interpreter-dispatched (§8), but
the *effect* is pinned statically by a **sole-writer** argument. `0x006FC560` takes exactly the
`(object, bool)` shape the thunks imply:

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
006FC586  call 0x529c00(eax=obj,0) ; call 0x527870(0,obj,1) ; ret   ; bit 3 left CLEAR
006FC59E  disable: call 0x527670(obj,0) ; call 0x529c00(eax=obj,1)
006FC5B0  or   byte [esi+0x2c], 8       ; ★ SET bit 3
```

Binary-wide census of that bit, by opcode/modrm/disp/imm pattern over `.text`:

| Access | Sites |
|---|---|
| `and byte [r+0x2C], 0xF7` (clear) | **1** — `0x006FC576` |
| `or byte [r+0x2C], 8` (set) | **1** — `0x006FC5B0` |
| `test byte [r+0x2C], 8` (read) | **20**, of which 13 are in the `0x00527xxx`/`0x00529xxx`/`0x0052Axxx` weapon cluster |

`0x006FC560` is the **sole writer, binary-wide**, of the only bit that 20 weapon-path readers test,
and one of those readers (`0x00529DDC`) sits inside the `FUN_00529D50` cluster that `SetFireLock`
calls — exactly the "expect a flag adjacent to `SetFireLock`'s" prediction the old §10.1 made.

> **Effect: `Human.DisableWeapons(guid)` sets bit 3 of `RuntimeInventory+0x2C`** (and zeroes `+0x20`);
> **`Human.EnableWeapons(guid)` clears it. Bit 3 set == weapons disabled.** The gate lives on
> **`RuntimeInventory`** — not on a weapon, not on a human block — which corrects this map's older
> framing of it as "a different axis" with no home.

`SetFireLock` is a third, clean axis: `FUN_00529d50(guid /*EAX*/, bLock)`.

### 6.2 Carry — H

`IsCarrying` and `Drop` independently read **bit 11 of the `u16` at `RTHuman+0x3C`**
(`movzx edx,[eax+0x3c]; shr dx,0xb; and edx,1` and `test [iVar1+0x3c], 0x800`). `Drop` returns
`false` without side effect when the bit is clear, and otherwise calls `FUN_004f9e10(bForce)`. Two
sites, one bit.

### 6.3 Grapple — H (except `StopGrappling`)

`IsGrappling` calls **`FUN_00432740`**, a 7-byte thunk into `FUN_004b1131`, which loads a container
pointer out of the SecuROM data slot `[0x0245D6B8]` and falls through to `FUN_00432747`. In the dump
that slot holds **`0x017BF888` = the `PhysicsActor` container** (§8), so the chain is
`guid → PhysicsActor → native actor`, and the grappling flag is the byte at **`+0x2F4`**
(`mov dl, byte ptr [eax+0x2f4]` @ `0x005BDF98`). `FUN_00432747` is worth reading once: it resolves
*twice* and returns the **second** object if its byte `+0x130` is set, else the first — an
**alternate-actor override**, consistent with `physics_code_map.md` §5's note that death/impact swaps
the human from the character proxy to the ragdoll instance (and with the existence of a separate
`PhysicsActorRagdoll` container, §1). The grapple/winch **constraint** machinery is
`physics_code_map.md` §6, not here.

`StopGrappling` is the map's **one remaining open effect**. *(Payload correction: the map used to say
it "builds `{guid, guid, 0, 1, 0}`". It builds a **4-field, 13-byte** record — `[esp+0x0C] = guid`,
`[esp+0x10] = 0`, `[esp+0x14] = 1`, `[esp+0x18] = 0` (byte) — and passes it in **ECX**
(`005BE027  lea ecx, [esp+0x0c]`), another dropped register arg. There is no second `guid`.)*

### 6.4 `PersistTransform` — it writes a FACING VECTOR onto `RTHuman` — H

> **Correction (old claim struck).** This map called the arithmetic a **"quaternion → basis"**
> conversion writing "six floats", said the target record was "not statically pinned", and filed
> §10.5 as *"likely a save/serialize record, which would hand it to `save_serialize_code_map.md`"*.
> All three are wrong, and the reason the container looked invisible is the dropped-ECX trap — it is
> **one instruction** above the resolve:

```
005BDAEA  call 0x4f9290
005BDAEF  mov  eax, edi                 ; guid
005BDAF1  mov  ecx, 0x17bf9c8           ; ★ RTHuman  (REGISTER ARG)
005BDAF6  call 0x5857e0                 ; -> eax = the RTHuman record
005BDB0B  call 0x665af0                 ; esi = &transform buffer; bails if it returns false
```

`FUN_00665AF0` fills a transform at `[esp+0x18..0x37]`: position, then a quaternion at `+0x28`(x)
`+0x2C`(y) `+0x30`(z) `+0x34`(w). The arithmetic is **not** a full basis — it is **one column**:

```
s   = 2.0 / (x²+y²+z²+w²)              ; DAT_00b92874 = 2.0
[rec+0x0C] = s(xz + wy)                 ; also -> [rec+0x00]
[rec+0x10] = s(yz − wx)                 ; also -> [rec+0x04]
[rec+0x14] = s(w²+z²) − 1.0             ; also -> [rec+0x08]   ; DAT_00b9b664 = 1.0
```

That is the **third row of the rotation matrix — the facing/forward axis** — written **twice**, to
`RTHuman+0x00..0x08` and `RTHuman+0x0C..0x14` (a live copy and a persisted copy). It writes "six
floats" only in the sense of *the same three floats, twice*. It is **not** a save/serialize record
and does not belong to [`save_serialize_code_map.md`](save_serialize_code_map.md). Returns `true`
(`{value=1, type=1}`) on success, `nil` when the argument is missing. **H** — the target container is
now a literal, so the row is promoted from M.

This also grows the `RTHuman` (elem `0x48`) layout: `+0x00..0x14` facing pair, `+0x38` knockdown
duration (f32), `+0x3C` u16 flags with bit 11 = carrying.

---

## 7. Corpse cleanup, scrub, jostle

### 7.1 `SetAllowCorpseCleanup` — H

A textbook **marker component**, the same idiom `player_code_map.md` §5 found for possession:

```c
if (bAllow == false)  FUN_00649180(&PTR_PTR_00df8108, guid, 0, 0xFAF6DA61, &0xFAF6DA61);  // ADD
else                  (**(code**)(PTR_PTR_00df8108 + 0x70))(guid, 0xFAF6DA61);            // REMOVE
```

Note the **inverted polarity**: `SetAllowCorpseCleanup(guid, false)` *adds* the label. Container
`0x00DF8108` is named **`Label`** by the master key (§1) — no longer an inference from a sibling
hash. A sibling label in the same container is `0xF956736B = pandemic_hash_m2("Disposable")`. On the
`true` path it additionally queries `FUN_006657f0` and, if false, calls `FUN_004b5f80` (whose **sole
caller** in the binary is this cfunc) — a re-arm of the cleanup timer, **inferred (M)**.

`0xFAF6DA61` is still uncracked but is now located: it occurs at **5 `.text` sites** — `0x004B6608`,
`0x0053FB81`, and three inside this cfunc (`0x005BE6AE`, `0x005BE6BE`, `0x005BE6D7`) — so **two other
subsystems use the same label**, which is the strongest lead for naming it (§10).

### 7.2 `Scrub` — it strips **`Sticky`** children — H

> **Correction (old claim struck), and the `+0x1C` field was on the wrong object.** The map said
> `Scrub` "iterates `0x00DF9110` and, for each entry whose id differs from **`humanObj+0x1C`**, calls
> `FUN_004f30d0` with a 4-byte zero block", and then §10.6 built an inference on top of that
> (*"`+0x1C` is also what `FUN_00532de0` watches for change… plausibly an owning-group/room id"*).
> Two ECX register args were dropped, and one of them changes the meaning of the function. **The
> object is wrong, so that inference is void.**

```
005BE7A5  mov  ecx, 0x17bf3d8           ; ★ RuntimeInventory   (REGISTER ARG)
005BE7AA  call 0x5857e0
005BE7AF  mov  edi, eax                 ; edi = the INVENTORY record  ← not the human object
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

> **`Human.Scrub(guid)` = "detach every `Sticky` object physically linked to this character, except
> the one it is currently holding."** The `Sticky` component filter is the entire point of the
> function and the old text omitted it.

Three specific fixes: **`+0x1C` is on `RuntimeInventory`**, and it is the currently-held item GUID;
the record handed to `FUN_004F30D0` is **8 bytes** (`{guid, 4 zero bytes}`) via **ESI**, not "a 4-byte
zero block"; and `0x00DF9110` / `0x017BE5C8` are `RuntimePhysicalLink` / `Sticky`.

The script corpus corroborates exactly this reading: `mrxbriefing.lua:2686-2692` runs
`Human.Drop(uChar)` → `Human.Scrub(uChar)` → `Human.SetJostleEnabled(uChar, bOn)` — strip the
character of carried and stuck junk before a cutscene, which is what the name says.

`FUN_004F30D0` itself is a split thunk (`push ecx; jmp [0x02450014]` → `0x024B8130` → VM), but its
**tail is present in `.text` at `0x004F30DE`** and terminates with the matching `pop ecx; ret` at
`0x004F316D` — SecuROM stole only the leading gate check. The recovered tail appends an 8-byte record
to a `0x4000`-entry table at `0x016E9778` (count `0x016E9730`) with a parallel u16 tag array at
`0x01709778`, under CS `0x01711780`. It has 36 callers engine-wide and a compacting sweep at
`0x006C74B0` that drops entries whose tag is 0 — a *retained registration table*, not a
fire-and-forget log. What the drain ultimately does to a scrubbed `Sticky` child is engine-general
and outside this map.

> **Correction for [`player_code_map.md`](player_code_map.md) §7 — restated more precisely.** That
> map calls `DAT_00EDBAA4` + `PTR_DAT_00EDBAC0` the **"seat-reservation pool"** because `ClaimSeat`
> uses them. It is not seat-specific — but "general scratch-block pool", which this map said in an
> earlier revision, also understates it. `0x00EDBAA4` is byte-for-byte an **`RTL_CRITICAL_SECTION`**
> (`DebugInfo = -1`, `LockCount = -1`, `RecursionCount = 0`, `SpinCount = 0x020007D0`) passed to
> `KERNEL32!EnterCriticalSection` / `LeaveCriticalSection` (IAT `0x00B05128` / `0x00B0512C`), and
> `0x00EDBAC0` is the head of an **intrusive singly-linked free list** with the link at
> `object+0x18`. It is *the* process-wide block lock: the address occurs as a 4-byte immediate at
> **1060 `.text` sites** (`0x00EDBAC0` at 1063), spread from `0x00403xxx` to `0x009xxxxx`, and the
> identical idiom appears in `Scrub` (`0x005BE85C`) and in wholly unrelated code at `0x004031C2`.

### 7.3 `SetJostleEnabled` — H

Gates on the character having a `BoneControllerRuntime` record, then collects **up to 32** items via
`FUN_00685c90(0xE551D91A, &buf, 0x20)` and, for each, sets **bit 1 of byte `+0xA4`**:
`al = (al & 0xFD) | ((bOn & 1) << 1)`.

**`0xE551D91A` is now named: `pandemic_hash_m2("StrapOn")`.** The name is attested — the exe carries
`BoneCtrlStrapOn` at `0x00BC4A8C` and `StrapOnAnimation` at `0x00BCC318`; the Xbox build carries the
budget line `BoneCtrlStrapOn 768` and the animation-node symbols `StrapOn SamplePose/Update/ctor`
(`docs/mercs2-pdb-analysis/animation-skeleton.md:106,322,334`). So the selector picks the
**`StrapOn`** member of the `BoneCtrl*` procedural-controller family, and `SetJostleEnabled` toggles
secondary motion on strapped-on attachments — which is why the constant did not resolve to anything
containing "jostle". The hash occurs at exactly 2 `.text` sites: `0x005BE968` (here) and `0x00677411`.
The bit write is **H**; the collect call's GUID is still not in its explicit arguments (it rides in
EAX), so the *per-character* selection remains **M**.

---

## 8. The SecuROM veneer inventory

> **Correction (old claim struck).** The blockquote at the head of this map used to say *"19 of the
> 21 cfunc bodies are clean `.text`"* while §12 said the opposite. §12 was right: **all 21 cfunc
> bodies are clean `.text`, read byte-for-byte. No cfunc in this map is "binding-only."** The
> SecuROM seam is one level *down*, in the workers — and even there it is mostly not a seam.

The useful distinction is whether the slot resolves to plain relocated code (**followed**) or
dispatches into the interpreter at `0x01AAFF10` (**interpreter-dispatched**). All slot values below
were read out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`; all four originally-listed slot
values were re-checked and are exact.

| Reached from | Slot | Resolves to | Verdict |
|---|---|---|---|
| `SetState` container resolve `FUN_00520ef0` | `[0x0245E768]` | `0x02908000` | **Followed.** A relocated copy of the container `Find(guid)` walk: `mov ecx, esi; call FUN_006496b0` then the identical mask `+0x20` / stride `+0x24` / shift `+0x26` / key `+0x48` / page `+0x70` walk. Functionally == `FUN_00423dc0`. **H** |
| `IsGrappling` container ptr (`FUN_004b1131`) | `[0x0245D6B8]` | **`0x017BF888`** | **Followed.** A *data* slot holding the `PhysicsActor` container. **H** |
| `SetState`/`Knockdown` worker `FUN_0068cc00` | `[0x0245E1D8]` | `0x031C0000` | **FOLLOWED IN FULL** — §2.2. *(Was "partly followed / dispatch obfuscated"; all four obfuscated targets resolve arithmetically out of the dump.)* **H** |
| `FUN_0059FB00`'s `lua_tostring` `FUN_0059F990` | `[0x0245F0E4]` | — | Split thunk; the hash path around it is fully read (§2) |
| `Scrub`'s `FUN_004F30D0` | `[0x02450014]` | `0x024B8130` | **Partly stolen only.** The leading gate check is VM'd; the **tail is present in `.text`** at `0x004F30DE`–`0x004F316D` and was read (§7.2) |
| `EnableWeapons`/`DisableWeapons` worker `FUN_005be050` | `[0x02458448]` | `0x024E6250` | **Interpreter-dispatched.** `push 0x24E625A; call 0x01AAFF10`. Body unreadable — but the **effect is pinned by a sole-writer argument** (§6.1) |
| `StopGrappling`'s `FUN_005BF7E0` | `[0x02455A2C]` | `0x024BA620` | **Interpreter-dispatched.** Same shape. Effect **open** |
| `StowWeapon` `thunk_FUN_024e8df0`, `DoAction` `thunk_FUN_024e96c0` | — | `0x024E8DF0` / `0x024E96C0` | **Interpreter-dispatched** (same shape); both callers' effects are pinned by their surroundings |
| The `Find` inside `FUN_0068CC00`: `FUN_0068D270` | `[0x02459C4C]` | `0x024E3590` | **Interpreter-dispatched.** Immaterial: `Find` is a keyed lookup returning index-or-negative, established by both call sites and by the container's on-disk shape (§2.3) |

**Effect-pinning tally, honestly.** An earlier revision claimed "**19 of 21** have their effect
pinned", counting only `EnableWeapons`/`DisableWeapons` as unpinned — while §3 itself rated
`PersistTransform`, `StopGrappling` and `Scrub` at **M with open effects** and §10 listed all three as
open. By its own rows the number was **16 of 21**. After this pass: `PersistTransform` (§6.4),
`Scrub` (§7.2) and the weapons pair (§6.1) are pinned, so the honest number is now **20 of 21**, with
**`StopGrappling` the single genuinely open effect**.

---

## 9. Settled: `player+0x158` and `player+0x199`

[`player_code_map.md`](player_code_map.md) §2.2 / §9.2 recorded these as that map's "one structural
ambiguity" — `SetGrappleEnabled` and `SetHealthClamp` write them on the object returned by
`FUN_00423dc0`, whose container was not statically visible because it arrives in **ESI** and Ghidra
dropped it (the same trap as §6.4 and §7.2). It is visible in the raw bytes:

```
; Player.SetGrappleEnabled  FUN_005dfbb0
005DFC5D  8b442410      mov eax, [esp+0x10]          ; player GUID
005DFC61  be909bdf00    mov esi, 0x00DF9B90          ; ★ the PLAYER container
005DFC66  e85541e4ff    call 0x00423DC0
005DFC6B  8b00          mov eax, [eax]
005DFC81  8a4c2418      mov cl,  [esp+0x18]
005DFC85  888858010000  mov byte ptr [eax+0x158], cl ; ★

; Player.SetHealthClamp    FUN_005dc4f0
005DC59D  8b442410      mov eax, [esp+0x10]
005DC5A1  be909bdf00    mov esi, 0x00DF9B90          ; ★ same container
005DC5A6  e81578e4ff    call 0x00423DC0
005DC5AB  8b00          mov eax, [eax]
005DC5C1  8a4c2418      mov cl,  [esp+0x18]
005DC5C5  888899010000  mov byte ptr [eax+0x199], cl ; ★
```

**Verdict: both are on the PLAYER object. H.** The argument is stronger than "same container": the
master key **names** `0x00DF9B90` — its vtable `0x00BC3FB8` slot `+0x34` is `0x00647BA0` =
`mov eax, 0x00BC5DAC; ret` → the literal string **`"Players"`**. Two further independent lines agree:

- **Attribution.** Of the 133 `.text` references to `0x00DF9B90`, those landing inside a registered
  cfunc belong to **47 distinct `Player.*` cfuncs** (`GetCharacter`, `GetCash`, `CreatePlayer`,
  `SetInputEnabled`, …) and to **zero `Human.*` cfuncs**. Conversely `0x00DF9990`
  (`HumanStateMachine`) is referenced by `Human.DoAction/SetState/Knockdown/IsSwimming` and
  `Object.Revive`, and by **zero `Player.*` cfuncs**.
- **Geometry.** `0x00DF9B90`'s page shift is **3** (8 slots/page) — a handful of players.
  `0x00DF9990`'s is **7** (128 slots/page) — a crowd of humans.

Practical consequences:

- `player_code_map.md` §2.2's second table should be **merged into the main Player object layout**
  (`+0x158` grapple-enabled byte, `+0x199` health-clamp byte), and §9.2 struck from its open list.
- The "these are plausibly on the human because `FUN_00423dc0` sits in the `0x0042xxxx` module
  alongside `HumanPhysics`" reasoning was **a false lead** — module adjacency is not ownership.
  Recorded so it is not re-derived.
- Both cfuncs also **return `true`** (they push `{1, 1}`), which the player map did not note.
- `GrappleParameters` (registrar `FUN_00643d50`, container `0x017BE848`, name verified by the master
  key) remains a **separate** per-character component from the player's `+0x158` gate — the gate is
  on the player, the tunables are on the character. A reimpl must not merge them.

---

## 10. Open questions — 3 remain

Seven of the nine items this section used to carry were closed **statically**, without a debugger:
§10.1's effect by a sole-writer census (§6.1), §10.2 by dumping the shipped asset (§2.3), §10.3 by the
`Net.IsClient`/`IsServer` accessors (§5), §10.4 by a `.text` call scan (§1.1), §10.5 and §10.6 by
recovering the two dropped ECX arguments (§6.4, §7.2), and §10.8 by the master key (§1). **All of
them had been filed as live-debugging work.** That pattern — *stop one read short, then send the
reader to a debugger* — is the failure mode this map has now been burned by twice, and both times the
missing read was one of the four mechanisms in §R.

What is genuinely left. *(The validation that drove this pass scored "2 still open" — three hash
pre-images counted as one register item, plus the static edge. That register did not carry
`StopGrappling`'s effect as a separate line because it had already been booked under an
overstatement. Counted as work a reader can pick up, there are **three**.)*

1. **Three name-hash pre-images.** Static evidence is **exhausted**, and this is a corpus problem,
   not a debugger problem.

   | Hash | `.text` sites | Context |
   |---|--:|---|
   | `0x2108278F` | **1** — `0x005BE179` | **inside the `FUN_005BE050` region** (`0x005BE056`–`0x005BE21F`), pushed as an argument to the `0x01A53D80` veneer. *(An earlier note mislabeled this "StopGrappling"; `StopGrappling`'s body contains no such constant.)* |
   | `0xFAF6DA61` | 5 — `0x004B6608`, `0x0053FB81`, `0x005BE6AE/BE/D7` | the corpse-cleanup `Label`; two other subsystems use it (§7.1) |
   | `0xE60C6CA2` | 3 — `0x00578781`, `0x005A8F9A`, `0x005A8FAA` | a sibling `Label` |

   Ruled out: all ~1.3M whole strings from the exe (including UTF-16), the Xbox strings dump, both
   Lua corpora, `docs/data/` (incl. all 648,202 `wad_vocab.txt` lines verbatim), `docs/mercs2-ecs/`,
   `docs/mercs2-pdb-analysis/`, all 826,229 ASCII runs in resident block 3185, a curated ~30,000
   candidate affix sweep, and `Stance.Action` dotted pairs over the now-known vocabulary. An
   unbounded compound sweep was **deliberately abandoned**: the piece vocabulary is 717,651 tokens,
   so a V² product is ~5×10¹¹ candidates against a 32-bit space — false positives are *guaranteed*
   and would produce a confidently-wrong name, the exact failure [[no-arbitrary-hashes]] exists to
   prevent. **Recipe:** a *new corpus* — the string tables of the DLC WADs, or the Xbox `.xex`
   `.rdata` — then re-run the same cracker. A live shortcut exists for the two `Label` hashes only:
   one-shot bp at `0x005BE6D6` and read the `Label` container's name table.

2. **The static edge `FUN_005BE050 → 0x006FC560`** is not demonstrated. `0x006FC560` has exactly
   **one** direct `E8` caller (`0x006FE4FC`, inside a `ret 4` dispatcher keyed on a byte `[ebp+8]`)
   and **zero** immediate references, so the Lua path must reach it through the SecuROM interpreter
   or through that dispatcher. **Recipe:** one-shot bp at **`0x005BE237`** (the `call` inside
   `DisableWeapons`), step **over** it, then read `RuntimeInventory+0x2C` for the target GUID; or set
   a HW write-watchpoint on that byte and call `Human.DisableWeapons` from script. Either confirms in
   one step. **This is confirmation of an already-pinned effect (§6.1), not discovery** — the
   sole-writer census stands on its own.

3. **`StopGrappling`'s effect** (§6.3) — the one binding of 21 with no pinned effect. `FUN_005BF7E0`
   is interpreter-dispatched and the consumer of its 13-byte ECX record is unknown. **Recipe:**
   one-shot bp at `0x005BE037`, step over, and diff `PhysicsActor+0x2F4` plus the grapple constraint
   state that `physics_code_map.md` §6 owns.

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — prefer
**one-shot** breakpoints and HW-write watchpoints. And do **not** reach for
`genuine_patched_unpacked.exe` for any of this: it is a different build (§R).

---

## 11. Reconciliation with the Rust reimpl

`tools/wad_simulator/crates/mercs2_script/src/bindings/human.rs` holds all 21 `Required` names. The
humanoid vocabulary lives in **`mercs2_core`** — `Human` (marker), `HumanState`, and
`PlayerControlled { slot }` — deliberately **not** in `mercs2_player`, so ai/anim/combat can act on
people without an edge to the player crate. Retail **validates that placement**, and sharpens it:

1. **`HumanState.stance` / `.action` must be `u32` name-hashes, not enums.** Retail's fields are two
   32-bit hashes at `humanObj+0x04`/`+0x08`, script types the values as *strings*, and both the
   state graph and the ActionTable key on the same hashes. An enum cannot round-trip a stance the
   shipped Lua invents. Store the hash; resolve to a name only for display — and the display table
   is now available: **all 17 stance names and 296 action names ship as ASCII in the
   `HumanStateTable`** (§2.3), so a reimpl can build the hash→name map from the asset instead of
   hard-coding it.
2. **`knocked_down` should not be a separate bool.** Retail models it as `action == hash("Knockdown")`
   plus a duration float (`RTHuman+0x38`). Keep the duration, drop the bool.
3. **`swimming` is likewise derived**, not stored: `stance == hash("Swim")`.
4. **The other flags really are separate storage, on different objects.** `carrying` →
   `RTHuman+0x3C.11`; `grappling` → `PhysicsActor+0x2F4`; `jostle_enabled` →
   `BoneControllerRuntime+0xA4.1`; **`weapons_enabled` → `RuntimeInventory+0x2C` bit 3, inverted
   (set = disabled)**; `allow_corpse_cleanup` → *presence of a `Label` component*, not a bool;
   `preemptive_ragdoll` → a **one-shot arm** (`+0xC0 = 1`, no value argument — the Lua binding cannot
   clear it). Collapsing them into one `HumanState` struct is the right ergonomic call, but
   `allow_corpse_cleanup` inverts, `weapons_enabled` inverts, and `preemptive_ragdoll` is
   write-1-only — three easy ways to get it backwards.
5. **`SetState` is a state-machine transition, not a setter.** Model `FUN_0068CC00` faithfully: look
   the pair up in the state graph, **fail (return false) if either level misses**, emit a
   `HumanStateTransition` event carrying `{obj, newStance, newAction, oldStance, oldAction}`, cache
   the resolved records, and stamp the time. Treat the resolved-record cache as **derived state
   invalidated by a table swap** (§1.1), never as independent fields. A fresh human starts at
   `(Upright, Idle)`.
6. **Action verbs are commands on a queue, not method calls**, and **only `DoAction` is net-gated**
   (§5). `bindings/mod.rs` already has the right primitive — `record_all` / `EngineHost::script_cmd`.
   Backing the three with `script_cmd` is **faithful**, not a stub, and the animation system should
   drain that queue rather than have Lua call it directly.
7. **`Human.Inventory` is a child namespace, not a sibling table** (§3.1). `bindings/inventory.rs`
   now reflects retail: `GLOBAL = "Human.Inventory"` and it installs via `b.install_child("Human",
   "Inventory")`. `Human.EquipWeapon` and `Human.Inventory.EquipWeapon` are **different cfuncs behind
   one name pointer**; the 21-name `REQUIRED` list must not absorb the inventory nine.
8. **`mercs2_core::ANY_STATE` is `pandemic_hash_m2("*")`, a wildcard** (§2.4) — its doc comment now
   says so, and `mercs2_formats::anim_select::NONE_SENTINEL` holds the same number under a less
   accurate name.

The `mercs2_player` boundary holds cleanly: nothing in the 21 touches the player object, and the two
offsets that looked like they might (§9) are on the player after all — so `Human` bindings need **no**
edge to `mercs2_player`, exactly as the crate split assumed.

---

## 12. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (base `0x00400000`). Bodies read
  first-hand: `FUN_005bd260`, `FUN_005bd450`, `FUN_005bd860`, `FUN_005bda70`, `FUN_005bddd0`,
  `FUN_005bdfc0`, `FUN_005be340`, `FUN_005be4c0`, `FUN_005be5f0`, `FUN_005be730`, plus
  `FUN_005857e0`, `FUN_00423d10`, `FUN_00532de0`, `FUN_0059fb00`, `FUN_00824270`,
  `FUN_00432740`/`FUN_004b1131`/`FUN_00432747`, `FUN_00667cb0`, `FUN_006681c0`, `FUN_006fc560`,
  `FUN_006cecf0`, `FUN_0068cf20`, and the registrars `FUN_00646540`, `FUN_006457e0`, `FUN_0063d910`,
  `FUN_006477c0`, `FUN_00a7c630`, `FUN_00a7c660`, `FUN_00a7ac50`, `FUN_00a7bae0`.
- **Raw disassembly:** `output/_ghidra/securom_dump/mercs2_unpacked.exe` (13 sections, `RVA == raw`
  verified per section; capstone x86-32). The **12 cfuncs Ghidra found no entry point for** were read
  this way — `0x005BD1E0`, `0x005BD740`, `0x005BD750`, `0x005BD760`, `0x005BD9B0`, `0x005BDC00`,
  `0x005BDD10`, `0x005BDF00`, `0x005BE220`, `0x005BE230`, `0x005BE240`, `0x005BE890` — plus the §9
  player cfunc tails (`0x005DFBB0`, `0x005DC4F0`), the `Net` accessors (`0x005C6790`/`D0`/`0x005C6810`)
  and **the relocated `.securom` body of `FUN_0068CC00` at `0x031C0000`** (§2.2). **No cfunc in this
  map is "binding-only", and all 21 are clean `.text`.**
- **Binding table:** walked directly in `.rdata` from `0x00B99EE8` to `0x00B99FF8` (§3.1). ⚠ **Not**
  from `mods/lua_trace_asi/reference/binding_map.json` — that file reports two tables where the bytes
  have one array with marker rows, and this map inherited the artefact for a full revision. Trust the
  bytes over the tool.
- **Shipped data:** `mercs2_probe humanstate_probe` (HumanStateTable `0xECE70371`, block 3185,
  561,024 B → 17/394/8,744) and `mercs2_probe action_table_probe` (ActionTable `0x6802C321`, 1,020
  rows × 14 columns) over `vz.wad`. Both are one-command reproductions (§R.4).
- **Script traffic + signatures:** re-counted this pass over `docs/mercs2-luacd/` (370) **and**
  `docs/mercs2-dlc-luacd/` (75); per-binding base/DLC split in §3.
- **Hashes:** `tools/pandemic_hash.py --m2`, per [[no-arbitrary-hashes]]; the FNV basis the engine
  itself uses is `[0x0245D6D8] = 0x811C9DC5`, i.e. standard FNV-1a, matching the tool. Resolved and
  re-verified: `0x614DB965`=`Swim`, `0x9C9F3F13`=`Knockdown`/`KnockDown`, `0x12C07B18`=`Upright`,
  `0xB4DA003B`=`Idle`, `0xDE9D82CB`=`Emote`, `0x03DD7B78`=`EmoteFullBody`, `0xE551D91A`=`StrapOn`,
  `0x27DE7135`=`*`, `0xECE70371`=`HumanStateTable`, `0x207359C7`=`AnimationTable`,
  `0xF956736B`=`Disposable`, plus all 17 stance names (§2.4). **Three remain unresolved** (§10.1) and
  are recorded as bare hashes rather than guessed.
- **Xbox side:** `docs/mercs2-pdb-analysis/pangea-engine-core.md` (`PgSysHumanStateMachine`,
  `PgHumanStateTable`), `physics-game.md:243` (`HumanStateMachine @ 0x823551E0`),
  `animation-skeleton.md` (`BoneCtrlStrapOn`, the `BoneCtrl*` family, pool budgets),
  `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`
  (`GetTranslationForStanceAndAction`, `HumanStateTransition`, 18/21 binding names at `:4076-4092`).
  The old "no symmetric Xbox↔PC marriage to make" claim is **refuted** (§Sources).
- **Cross-refs:** [`physics_code_map.md`](physics_code_map.md) (character proxy, state machine,
  ragdoll, grapple constraints), [`animation_code_map.md`](animation_code_map.md) +
  [`../modernization/human_animation_selection.md`](../modernization/human_animation_selection.md)
  (ActionTable → AnimationLookup → ASTO; §2.4 retires that doc's Stance-column open item),
  [`player_code_map.md`](player_code_map.md) (§9 settles its §9.2; §5 and §7.2 correct its
  `DAT_00DFBD77` and `DAT_00EDBAA4` readings),
  [`object_entity_core_code_map.md`](object_entity_core_code_map.md) (same `DAT_00DFBD77`
  correction), [`mission_contract_flow_code_map.md`](mission_contract_flow_code_map.md) (whose
  net-flag reading was right), [`ai_code_map.md`](ai_code_map.md) (the command ring),
  [`ecs_reflection_registry_code_map.md`](ecs_reflection_registry_code_map.md) (`FUN_005857e0`,
  registrar shape — and §1's master key names every container it left bare),
  [`weapons_combat_code_map.md`](weapons_combat_code_map.md) (the `0x00527xxx` cluster),
  [`vehicle_code_map.md`](vehicle_code_map.md) (`FUN_0053ad30`).
- Confidence stated per row. The documented gaps are now exactly three: `StopGrappling`'s effect, the
  `FUN_005BE050 → 0x006FC560` static edge, and three name-hash pre-images (§10).
