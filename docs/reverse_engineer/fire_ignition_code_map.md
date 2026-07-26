# Fire / ignition — PC code map

**Scope:** everything the retail PC `Mercenaries2.exe` does with **fire** as a *simulation* concept —
the `Ignitor` → `RuntimeIgnitor` ignition volume and its per-frame `UpdateIgnitor` pass, the
`Flammable` marker, the **`Fire` DamageKey** and the falloff math that turns proximity into damage,
the `TickDamage` → `RtTickDamage` burn-over-time timer, the debris **fire trail** enum, the bridge
from the **destruction state machine** into fire emitters, and the `ObjectState.StartEmitter` /
`StopEmitter` cfuncs that Lua uses to hang effects on hardpoints. **The single most
decision-relevant finding is negative and lives in §7.5**: all of this code is real, and no shipped
object in `vz.wad` is authored with any of these components.

It also settles the identity of the namespace this map was commissioned under. **There is no `Fire`
Lua namespace.** `luaL_Reg` table `0x00B9A7A8` is a *nested sub-table* of `Graphics`, named
**`FuelTrail`**, and all three of its cfuncs are dead on PC (§1). The interesting fire system is
somewhere else entirely, and this map is that somewhere else.

**Boundaries with sibling maps** (cited, not re-derived):

| Belongs to | Not here |
|---|---|
| [`particle_fx_code_map.md`](particle_fx_code_map.md) | PgFX itself — fxdict/effect parsers, EffectTemplate, RtRedEffect/RtVFX/RtRibbon, the emit/sim/draw pass. This map stops at the *request* to start an effect. |
| [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) | the destruction machine (`FUN_004CF340` parser, `FUN_004D3E10` SetState, `FUN_004CFED0`, `FUN_004D05C0`), the state/message vocabulary, `SHOW`/`HIDE` subtree semantics. This map only owns the `StartEmitter` command's *engine side*, and hands back a **cracked command/state vocabulary** — 17 names plus `DanglingState`, all out of shipped `vz.wad` data (§6.1). Two rows of the sibling map are corrected there: `0x28825D4C` is a **state**, not a node, and `0x381BE6A4` is `DanglingState`. |
| [`weapons_combat_code_map.md`](weapons_combat_code_map.md) | the firing pipeline, projectile lifecycle, homing FSM, `DamageKey`/`Explosive`/`ExplosionFudge` descriptors, the `0x0052xxxx` weapon-driver leaves. It already lists the `Ignitor`/`RuntimeIgnitor` **descriptors**; this map adds their **runtime** and corrects one attribution (§7.3). |
| [`../mercs2-ecs/01_combat_weapons_projectiles.md`](../mercs2-ecs/01_combat_weapons_projectiles.md) · [`05_presentation_audio_fx.md`](../mercs2-ecs/05_presentation_audio_fx.md) | the reflected schemas for `Ignitor` (0x0C), `RuntimeIgnitor` (0x1C), `Flammable` (0x04). Cited verbatim, not re-derived. |
| [`scripting_host_binding_code_map.md`](scripting_host_binding_code_map.md) | the cfunc arg-read / push / error primitives (`FUN_0059F780`, `FUN_005A0000`, `FUN_0059FF50`, `FUN_0085D5D0`, `FUN_004B2A50`). |

**Sources.** PC: the 27k-fn Ghidra decomp `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked
SecuROM image, base `0x00400000`) — every body cited below was fetched and read first-hand;
where Ghidra under-sized or mis-typed a function (it does, badly, for `FUN_004B7BB0`) the raw bytes
were **disassembled directly out of `output/_ghidra/securom_dump/mercs2_unpacked.exe`** with capstone
and that disassembly is what the row states. That image is a **live memory dump**, so indirect slots
are already resolved and the ECS descriptor tables are already populated — which is what makes the
two "master keys" below work offline. Binding tables: a fresh `.rdata` walk of the same image
(§1), cross-checked against `mods/lua_trace_asi/reference/binding_map.json` and
[`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md).
**Shipped data** (this is where the destruction-state vocabulary was cracked, §6):
`MERCS2_VZ_WAD=<install>/data/vz.wad cargo run -p mercs2_probe --bin block_content_grep -- <needle>`
and `cargo run -p mercs2_workshop -- --states <model hash>`.
Xbox oracle: `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` + `inventory/_uncategorized.txt`
(`UpdateIgnitor @0x0041234`) and [`../mercs2-pdb-analysis/weapons-combat.md`](../mercs2-pdb-analysis/weapons-combat.md)
(`TickDamage @0x829f1e90` = 16 B, `ApplyDamageToPrimaryHealth` / `ApplyDamageToNodeHealth`).
Hashes: `tools/pandemic_hash.py --m2` + `tools/rainbow_table.json` (739 446 entries).

**Method / honesty model.** Same discipline as the sibling maps. Confidence: **H** = read body with a
can't-coincide fingerprint (a matching constant, an exact stride, or a vtable slot that lands on the
function) · **M** = one strong structural signal · **L/open** = positional → confirm-live. Every
offset below names the function it was read from. Where a cfunc has **no decompiled body** it is
listed as *binding-only* and, where it mattered, hand-disassembled instead of guessed. **No hash in
this document is invented**: every name given is `pandemic_hash_m2(name) == target`, checked, and the
hashes that did not crack are reported as not cracked (§6.2).

> ### ⚠ Trap #1 — Ghidra drops register arguments, and it hid half of this map
>
> This is the single highest-yield defect in this area of the binary, and an earlier revision of this
> document got a headline finding backwards because of it. Ghidra's decompilation of
> `FUN_004B7B50` emits
>
> ```c
> case 6:
>   iVar2 = FUN_005857e0();          // <- no operand. The ecx = 0x017BE258 is GONE.
>   return (uint)(iVar2 != 0);
> ```
>
> while the bytes at `0x004B7B7B` say `mov ecx, 0x17BE258` — the **`Flammable` container**. The same
> defect hid the `ModifierKey` row key (`esi`, §2.5), the `dt` and damage floats (`xmm0`, §2.4/§3),
> the hardpoint out-pointer (`edi`, §4.2) and **every authored field name** (`edx`, below).
>
> Two **master keys** recover what Ghidra threw away, both reproducible offline against
> `output/_ghidra/securom_dump/mercs2_unpacked.exe`:
>
> 1. **Container names — `[[container]+0x34]`.** Every ECS descriptor's vtable slot `+0x34` is a
>    `mov eax, <char*>; ret` stub returning the class name. `0x0064A7E0` is the engine doing exactly
>    this over the descriptor tables at `0x00EDBEC8` (218 entries) and `0x00EDBAC8` (116). Applying
>    it to all 334 descriptors names every container in the image — and corrects four this map used
>    to state wrongly (§4.2, §4.3, §4.4).
> 2. **Authored field names — `mov edx, <char*>`.** The schema readers `FUN_00656210` (int),
>    `FUN_00656320` (float) and `FUN_00656720` (enum) take the field name in `edx`. Reading it back
>    turns every "N ints, M floats" row in this map into authored names (§2.1, §3, §5).

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]) — and two of the three leaves
> this map used to list as confirm-live are now **fully recovered by dereferencing the resolved slot**:
> `FUN_00632360` (`jmp [0x0245DE08]` → `0x02FB0000`, 127 B of clean x86, §2.5) and `FUN_00406170`
> (`jmp [0x0244FEA8]` → `0x024B9B50`, the damage post, §3). **Exactly one genuine wall remains**:
> `FUN_004D4680`, which is *virtualized*, not merely relocated — see §4.4 for the full deref chain
> and the string the VM announces itself with.

---

## 0. Result in one line

Fire in Mercenaries 2 is **not an FX feature with gameplay bolted on; it is a damage-volume ECS
system that happens to also spawn particles**. An **`Ignitor`** component (`0x37C12455`,
authored `{float Radius, float MinDamage, float MaxDamage}`) produces a **`RuntimeIgnitor`**
(`0x1CA3ABD7`, 28 B) whose per-frame update **`FUN_004B82D0`** —
the PC body of the Xbox profiler zone **`UpdateIgnitor`**, dispatched from the layer-4 `Rt*` pass
`FUN_00675E50` — runs a **broad-phase overlap query** every frame, filters the hits, and for each one
calls **`FUN_004B7BB0`**, which computes a clamped **oriented-bounding-box distance**, applies a
**linear near→far falloff** between the Ignitor's two rate floats, scales the result by a
**`ModifierKey` × `DamageKey` matrix cell** whose column key is `pandemic_hash_m2("Fire") ==
0x8A552089` (a code-literal, can't-coincide anchor) and whose row key is the *target's* `ModifierKey`
component — so how much fire hurts depends on **what is burning**, not only on the fact that it is
fire — and posts the damage through the **same `FUN_00407B20` + `FUN_00406170` path the weapon and
explosion code uses**, twice: once against
**primary health** and once per **sub-node** (the PC bodies of Xbox `ApplyDamageToPrimaryHealth` /
`ApplyDamageToNodeHealth`). Persistent burning is a **separate 16-byte timer component**,
`TickDamage` → `RtTickDamage`, whose accumulator is advanced in the *same* layer-4 pass and which
posts a damage event every `TickLength` seconds — through the *same* post pair. The particle side is
downstream and optional: the
destruction machine's `StartEmitter` command and `ObjectState.StartEmitter` both land on
**`FUN_004D28C0`**, which resolves an FX **hardpoint transform** and hands a template to PgFX.
**Ownership: fire is combat (silo 10). The FX layer is a consumer, not the owner** (§10).

> **The one thing to read before building any of it (§7.5):** all of this code is real, and
> **no shipped object in `vz.wad` is authored with `Flammable`, `Ignitor` or `TickDamage`**.
> 754 blocks declare `Health`; exactly **one** block mentions the fire components, and it is the
> reflection-schema block. The gate is live code that never fires from authored world data.

---

## 0.5 Master marriage table

| Role | Xbox symbol | PC addr | Married by | Conf |
|---|---|---|---|---|
| **`Graphics.FuelTrail` sub-table** (the "Fire namespace") | `FuelTrail`/`Ignite`/`Extinguish` strings | **`0x00B9A7A8`**, 3 rows, opened by the `0xFFFFFFFF` marker at `0x00B9A7A0`, closed at `0x00B9A7C0` | `.rdata` walk of the `Graphics` compound blob `0x00B9A4D0`→`0x00B9A7C8`; **not** in the 31-row namespace registry `0x00DFD478` | H |
| `FuelTrail.Ignite` / `.Extinguish` | — | **`0x006D5640`** (the shared `xor eax,eax; ret` stub) | both rows point at the known no-op stub | H |
| `FuelTrail.Put` | — | **`0x005B2A50`** | disassembled in full: reads up to 4 Lua args, **does nothing with them**, returns 0 results | H |
| **`Ignitor` descriptor** | — | registrar **`FUN_00643120`**, container `0x017BE2A8`, stride `0x0C`, schema `FUN_006627A0` = **`{float Radius, float MinDamage, float MaxDamage}`** | ecs-01; `s_Ignitor_00BC5400`; `pandemic_hash_m2("Ignitor")==0x37C12455`. Field names read from the `mov edx` operands at `0x006627AF`/`0x006627BE`/`0x006627D3` → `"Radius"`@`0x00BB4A64`, `"MinDamage"`@`0x00BCAEBC`, `"MaxDamage"`@`0x00BCAEC8` | **H** |
| **`Ignitor` class handler → producer** | — | vtable **`0x00BCD0B4`**, slot **`+0x18` = `FUN_0066E650`** | the handler is minted in `FUN_0066F300` at `0x00670FC7` from `pandemic_hash_m2(s_Ignitor_00BC5400)` + container id `[0x017BE2AC]`; `0x0066E650` occupies **exactly one** `.rdata` slot image-wide — `0x00BCD0CC` = `0x00BCD0B4 + 0x18` — so the producer is Ignitor-specific, not shared | **H** |
| **`RuntimeIgnitor` producer** | — | **`FUN_0066E650`** | read body: `mov ecx, 0x17BE2A8; call 0x5857E0` fetches the authored payload, `movss xmm0,[ebx]` (=`Radius`) builds the AABB, `FUN_006654B0`, `FUN_008DC7A0(0x2005,1,0)`, then `FUN_0064A600` inserts the 28-byte instance into container `0x017BF388` (`DAT_017BF3A4` count). **It rotates the three floats** — see §2.2 | **H** |
| **`RuntimeIgnitor` descriptor** | — | registrar **`FUN_00645650`**, container `0x017BF388`, stride `0x1C` | ecs-01; `s_RuntimeIgnitor_00BC594C`; hash `0x1CA3ABD7`; no authored schema (runtime-only) | H (cited) |
| **`UpdateIgnitor`** (per-instance, per-frame) | **`UpdateIgnitor`** `@0x0041234` (.rdata, `PgCdb::Update_*` family) | **`FUN_004B82D0`** | read + disassembled: sole caller is the layer-4 `Rt*` pass `FUN_00675E50` at `0x00677219` (`call 0x4b82d0`, `dt` in `xmm0` from `movss xmm0,[ebp+8]` at `0x006771F1`), iterating **exactly** the `RuntimeIgnitor` container (`0x017BF3AC`/`3AE`/`3B0`/`3C0`) | **H** |
| **Ignition overlap query** | — | **`FUN_004B7B00`** (call site `0x004B836A`) | disassembled: takes `RtIgnitor+0x18` (the broad-phase proxy) and a 35-slot result array; returns the hit count | M |
| **Ignition candidate filter *and* `Flammable` reader** | — | **`FUN_004B7B50`** (real extent `0x004B7B50–0x004B7BA6` incl. both tables; **Ghidra says `size=63`**) | disassembled: vcall `(*obj+0xE0)` object-kind query, then a 3-target jump table — `[0x004B7B90]` = `{0x004B7B74, 0x004B7B77, 0x004B7B8C}`, index bytes `[0x004B7B9C]` = `00 01 00 02 00 02 00 00 00 02 00` for kinds 5..15. Kind **6** lands on `0x004B7B77` = `mov ecx, 0x17BE258; call 0x5857E0` — the **`Flammable` component test** | **H** |
| **Fire damage applier** (falloff + post) | `ApplyDamageToPrimaryHealth`, `ApplyDamageToNodeHealth` (string-only) | **`FUN_004B7BB0`** — real extent `0x004B7BB0–0x004B82C2` (**Ghidra says `size=664`; it is 1811 B**) | disassembled: two `push 0x8A552089; call 0x632360` sites — the primary-health pass at `0x004B7F0D`/`0x004B7F14` and the per-node loop at `0x004B8212`/`0x004B8219` | **H** |
| **`Fire` DamageKey** = a **matrix column** | `DamageKeyEnum` | key hash **`0x8A552089`**; the `push` literals are at **`0x004B7F0D`** and **`0x004B8212`** (the map previously said `0x004B7F12`, which is the `mov esi, eax` that loads the *row* key) | **`pandemic_hash_m2("Fire") == 0x8A552089`** exactly; the same `FUN_00632360` takes `0xDC0A895F` = `pandemic_hash_m2("ExplosionLarge")` (`push` @`0x00630670`, `call` @`0x00630677`) and `0x29EFE0B5` = `MeleeBash` (`push` @`0x004CE2FA`, `call` @`0x004CE301`) | **H** |
| **`ModifierKey` × `DamageKey` matrix** (net-new) | — | **`FUN_00632360`** = `jmp [0x0245DE08]` → **`0x02FB0000`**, 127 B of clean x86 | recovered in full (§2.5): `(ESI = ModifierKey row key, stack = DamageKey column key) → &matrix[nCols*row + col]`. Record at `0x017BBD30` = `{u32 nRows@+00, u32 nCols@+04, u32* rowKeys@+08 (=0x017BBD38), u32* colKeys@+10 (=0x017BBD40), float* matrix@+18 (=0x017BBD48)}` | **H** |
| **Damage descriptor build → post** | — | **`FUN_00407B20`** → **`FUN_00406170`**; the latter is `jmp [0x0244FEA8]`, and **`[0x0244FEA8] = 0x024B9B50`** | `FUN_00407B20` has 12+ callers spanning weapons, explosions and this path; the `&DAT_011766F0` context arg is identical at every site. The relocated body is readable — SecuROM moved it, it did not virtualize it | **H** |
| **`Flammable` descriptor** | — | registrar **`FUN_00643070`**, container `0x017BE258`, stride `0x04`, schema **`FUN_00662720`** (emits **zero** stream reads) | ecs-05; `s_Flammable_00BC53F4`; hash `0xD930020E`. ⚠ the *shipped* schema record in `vz.wad` gives it **1 int field at `+0x00`** (name hash `0x8B50DC56`, uncracked) — so "zero fields" is true of the binary and incomplete about the authored schema (§5) | H |
| **`Flammable` consumer** | — | **`FUN_004B7B50`** arm `0x004B7B77` (`mov ecx, 0x17BE258` at `0x004B7B7B`) — the ignition filter itself | *Was* **open**: an earlier revision reported "none statically visible", because Ghidra prints `iVar2 = FUN_005857e0();` with the `ecx` operand dropped (Trap #1). `.text` references to `0x017BE258` are `0x004B7B7C` (this reader) + `0x006430AF`/`0x006430C5` (its own registrar), and nothing else | **H** |
| **`TickDamage` descriptor** | **`TickDamage @0x829f1e90`**, 16 B | registrar **`FUN_00642EF0`**, container `0x017BE1B8`, stride **`0x10`**, schema **`FUN_00661CB0`** = **`{int DamageThresh=0, float Damage, float TickLength, name NodeName=0x765CD254}`** | Xbox size 16 == PC stride `0x10`; hash `0x8DEF82AD`. Field names from `mov edx` at `0x00661CBE`/`0x00661CCA`/`0x00661CDD`/`0x00661CF8` → `"DamageThresh"`@`0x00BCAB74`, `"Damage"`@`0x00BC9B0C`, `"TickLength"`@`0x00BCAB84`, `"NodeName"`@`0x00BCAB90` | **H** |
| **`RtTickDamage` descriptor** | — | registrar **`FUN_00646AA0`**, container `0x017BFBF8`, stride **`0x10`**, layout **`{float Damage@+00, float TickLength@+04, float acc@+08, u32@+0C}`** | confirms the `rendering-shaders.md` positional guess; `s_RtTickDamage_00BC5BBC`; hash `0x27E19BF7`; `+0x00` proved a float by `movss xmm0,[eax]` at `0x006768F8` (§3) | **H** |
| **Burn-over-time tick** | — | inside **`FUN_00675E50`** (`0x00676881`–`0x00676959`) | read: `acc += dt`; on `acc >= inst[+4]` → `acc -= inst[+4]` (`0x006768DD`), `movss xmm0,[eax]` = the damage amount, then **`call 0x407B20` @`0x00676908` + `call 0x406170` @`0x00676912`** — the *same* post pair as the ignition path, not a separate thunk | **H** |
| **`ObjectState` binding table** | — | **`0x00B995B0`**, 9 rows, 2 stubs | `.rdata` walk; matches the deep-dive audit's count exactly | H |
| `ObjectState.StartEmitter` | — | **`0x005D2FA0`** → **`FUN_004D28C0`** | disassembled (no decomp body): 3 args → `call 0x4D28C0` | **H** |
| `ObjectState.StopEmitter` | — | **`0x005D3090`** → `thunk_FUN_024E76E0` | read body | H (site) / live (body) |
| `ObjectState.SetState` | — | **`0x005D2CE0`** → `thunk_FUN_02908000` then `thunk_FUN_024EF740(machine,node,state)` | read body | H (site) |
| `ObjectState.SendDamage` | — | **`0x005D2BE0`** → **`FUN_004D2580`** (→ SecuROM `_DAT_02455328`) | read body | H (site) |
| `ObjectState.SendMessage` / `GetLinkGuid` / `GetStringHash` | — | `0x005D2AE0` / `0x005D2DE0` / `0x005D3180` | `.rdata` walk (`GetStringHash` binding-only) | H (addr) |
| **Emitter-start engine bridge** | — | **`FUN_004D28C0(guid, hardpointHash, effectHash)`** | read: `FUN_00672F60(effect)` template lookup → `FUN_00688970(guid, hp, &xform)` hardpoint resolve → `FUN_006746D0(PTR_PTR_01176108, …)` spawn → registers the emitter component in `PTR_PTR_00DF9110` → distance gate → `FUN_0048B470` (PgFX) | **H** |
| **Emitter request-drain system** | — | **`FUN_004F4340`** (layer-4, caller `FUN_004C9740` @`0x004C99B8`) | read: drains `thunk_FUN_024EBCF0(&out, DAT_00D6CC18)` and calls `FUN_004D28C0` per request | H |
| **`RuntimeModelState::GetState(node)`** | — | **`FUN_004D4680`** — the **one genuine SecuROM wall** in this map (§4.4) | disassembled `FUN_00683C40`: pool lookup `esi=0x00DF9310` (**= `RuntimeModelState`**, master key) → `FUN_00520EF0(guid)` → `edi=this+0x18` (node) → `call 0x4D4680` → result compared to `0x381BE6A4` (**`DanglingState`**, §6.1) and `0xCA261E5B` (**`GoneState`**) | **H (role)** / live (body) |
| **`[presize]` pool sizes** (`Flammable 256`, `Ignitor 96 32`, **`RuntimeIgnitor 8 8`**, `TickDamage 1024`, `RtTickDamage 16 16`, `DebrisEffect 4608`) | same rows in the Jul-08 devkit dump | `docs/game_config/cdbsizes.ini`, and byte-identically in **PC retail `.rdata` `0x00BAD498`** (file offset `0x7AD498`) | **not** an Xbox symbol table — the game's embedded config INI, present in the PC image between `[achievements]` and `[localization]`. Grammar is `<name> <total-presize> [<page-capacity>]`, and it **resizes the registrar's `0x100` default at boot**: the live dump reads `Ignitor` `+0x0C`=96/`+0x28`=32 and `RuntimeIgnitor` `+0x0C`=`+0x28`=8, matching the INI exactly. **A presize, not a cap** — `FUN_0064A600` grows the pool a page at a time when full (§2.1) | **H** |
| **`(Weapon, Fire)` record scan** (net-new) | — | **`FUN_00693D80`** @`0x00693DE3`/`0x00693DEC` | disassembled: walks the **`AnimationResponse`** container `0x00DF7A88` via `FUN_006499F0`, then `cmp [eax+4], 0x787C0871` (**`pandemic_hash_m2("Weapon")`**) and `cmp [eax+8], 0x8A552089` (`Fire`) → `call 0x693BB0`. This is the **third** `Fire` literal in `.text`; see §7.2 for why it is probably a *false friend* | **H (bytes)** / M (meaning) |
| **`DebrisEffect` `Trail` = `Fire` / `FireNoLight`** | `ChunkTrailEnum` | schema **`FUN_006625E0`**, container `0x00DF8910`, handler vtable `0x00BCCFDC` | read body: `FUN_00656720(edx="Trail" @0x00BCAEB4, s_ChunkTrailEnum_00BC72E8)`; enum values at `0x00BC72D4`/`0x00BC72DC`; handler minted at `0x00671032` from `s_DebrisEffect_00BC53D8`. `Trail` is the *field*; `ChunkTrail` was the enum *type* | **H** |

---

## 1. The "Fire namespace" is `Graphics.FuelTrail`, and it is dead on PC

`binding_map.json` reports table `0x00B9A7A8` as a standalone 3-entry table. **It is not a table.**
The engine's namespace registry at `0x00DFD478` (31 rows, 12-byte stride, terminator at `0x00DFD5EC`)
contains no entry for it. Re-walking `Graphics` (`0x00B9A4D0`) with the compound-blob marker rules the
deep-dive audit documents — `0xFFFFFFFF` opens a nested sub-table named by the row's string,
`0xFFFFFFFE` closes it — the blob runs to a zero terminator at `0x00B9A7C8` and yields **95 rows / 75
callable bindings / 3 stubs** in this shape:

```
Graphics.{ScreenShot … SetBoundaryEffect}          11
Graphics.Camera.{SetNearFar … SetLodParams}         7
Graphics.Atmosphere.{Begin … SetSky}               37   (SetSky → 0x006D5640 stub)
Graphics.Bloom.*  7 · MotionBlur.* 1 · Contrast.* 2 · Monochrome.* 1 · Grainy.* 1 · AA.* 1
Graphics.Effect.{AmbientTop, AmbientSides, Terrain, CameraFade}      4
Graphics.FuelTrail.{Ignite, Extinguish, Put}        3   ← table_va 0x00B9A7A8
```

**75 / 3 is exactly what [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md)
independently reports for `Graphics`** — an entry-for-entry corroboration that the marker-row walk
above reconstructs the same table the audit's offline re-walk did, and therefore that `0x00B9A7A8` is
a sub-table of it rather than a namespace of its own.

So the correct Lua path is **`Graphics.FuelTrail.Ignite/.Extinguish/.Put`**.

**All three are non-functional in retail PC.**

| Lua name | VA | body | verdict |
|---|---|---|---|
| `Ignite` | `0x006D5640` | `xor eax,eax; ret` | the shared no-op stub (`diagnostics_code_map.md`'s `0x006D5640`) |
| `Extinguish` | `0x006D5640` | same | same stub |
| `Put` | `0x005B2A50` | 202 B, disassembled in full | reads Lua args 1–4 via `FUN_0059F780`, pushes `nil` when an arg is missing, raises via `FUN_004B2A50` on a bad type — and on the **success** path (`0x005B2B14`) does `xor eax,eax; ret`. **No engine call whatsoever.** |

> ⚠ **Provenance caveat on the stub.** `xor eax,eax; ret` is the *real* body, but you will **not** see
> it in `output/_ghidra/securom_dump/mercs2_unpacked.exe` — at VA `0x006D5640` that image holds
> `E9 7B CA 5F 6F` = `jmp 0x6FCD20C0`, a SecuROM hook pointing outside the image. The three bytes
> `33 C0 C3` are visible at the same VA in the DRM-free rebuild `mercs2_nodrm_v3.exe` (verify
> byte-identity at `0x004B7BB0`/`0x004B82D0` first before trusting it for anything else). Anyone
> re-checking in the primary image and finding a `jmp` has not caught an error.
>
> Also worth stating: `0x006D5640` is not fire-specific. **693 `.rdata` slots** point at it,
> including `print`, `Debug.Printf`/`Assert`/`LogError`, `Graphics.Atmosphere.SetSky` and
> `ObjectState.PrintStateMachine`/`DebugStateMachine`. It is *the* retail-strip stub.

`Put` is the more interesting of the three because it proves the stripping was deliberate rather than
accidental: the argument-validation prologue was kept (so a script calling it still type-checks and
does not fault) and the body was removed. It is the same shape as the `Pg.Dump*` retail dev stubs.

**Script traffic is zero — and the strong form of that claim is provable from the shipped archive.**
The weak form: the `corpus_calls` census carried in `mercs2_script/src/bindings/fire.rs` is **0/0/0**
over the 370 decompiled scripts in `docs/mercs2-luacd/`. (That census is a hand-maintained
`Required` field in `bindings/mod.rs`, **not** the output of a tool called `corpus_calls`; earlier
revisions of this map cited it as though it were one.) The strong form, which covers *all* shipped
data rather than a decompiled subset:

```
MERCS2_VZ_WAD=<install>/data/vz.wad \
  cargo run -p mercs2_probe --bin block_content_grep -- FuelTrail
```

decompresses all 11 370 blocks (`ok=11370 failed=0`) and returns **0 blocks** — likewise for
`Ignite` and `Extinguish`, against positive controls `Graphics` 2, `ObjectState` 1, `StartEmitter` 1,
`Atmosphere` 6. Lua bytecode stores field names as plain string constants, so **zero occurrences of
`FuelTrail` means no shipped script can even index the sub-table**, let alone call into it.

> ⚠ Method warning: a raw substring scan of the `.wad` file is **invalid** — payloads are
> compressed, and it returns 0 hits for *every* needle including `Graphics`. Use
> `block_content_grep`, which decompresses, and check the `ok=/failed=` tally.

**What it *was*.** `FuelTrail` + `Ignite`/`Extinguish`/`Put` is a fuel-spill mechanic: lay a trail
(`Put`), set it alight (`Ignite`), put it out (`Extinguish`). `FuelTrail` appears in the Jul-08 devkit
string dump too, so it existed at least as a name on Xbox. Whether it ever shipped working on any
platform is **open** — the PC side is empty and there is no PC body to read.

---

## 2. The real ignition model: `Ignitor` → `RuntimeIgnitor` → `UpdateIgnitor`

### 2.1 The component triple (descriptors cited from ecs-01/05)

| Component | m2 hash | container | stride | registrar | authored schema (field names from `mov edx`) |
|---|---|---|---|---|---|
| `Ignitor` | `0x37C12455` | `0x017BE2A8` | `0x0C` | `FUN_00643120` | `FUN_006627A0` — **`{float Radius, float MinDamage, float MaxDamage}`**, all default 0 |
| `RuntimeIgnitor` | `0x1CA3ABD7` | `0x017BF388` | `0x1C` | `FUN_00645650` | runtime — no stream schema, and no schema record in `vz.wad` either |
| `Flammable` | `0xD930020E` | `0x017BE258` | `0x04` | `FUN_00643070` | `FUN_00662720` — **zero** stream reads in the binary (but see §5: the shipped record declares 1 int field) |

#### The pool numbers: **8 is real, but it is a presize, not a cap** — and its provenance was wrong

**Old claim:** *"The **Xbox pool-budget table** gives the design intent of the counts: `Flammable 256`,
`Ignitor 96 32`, **`RuntimeIgnitor 8 8`** — i.e. the world may hold hundreds of burnable things but
only **eight** live ignition volumes at a time."* The number survives; the sourcing and the word
"only" do not. Here is the whole mechanism, established end to end and reproducible in three steps.

**1. The registrar writes a universal default.** Every component's registrar sets total presize
(`desc+0x0C`, mirrored at `+0x40`), page shift (`desc+0x26`) and page capacity (`desc+0x28`) from a
single `mov ecx, 0x100`:

```asm
00643131  mov   ecx, 0x100                      ; FUN_00643120, the Ignitor registrar
00643163  mov   [0x17BE2B4], ecx                ; desc+0x0C = 256   (total presize)
0064318F  mov   [0x17BE2D0], ecx                ; desc+0x28 = 256   (page capacity)
00643186  mov   word [0x17BE2CE], 8             ; desc+0x26 = 8     (page shift, 2^8 = 256)
0064319F  mov   [0x17BE2E8], ecx                ; desc+0x40 = 256
```

This is not an Ignitor fact, it is a *default*: of the **334** call sites of the shared registrar
tail `FUN_0064A770`, all **232** whose `or eax, 0xffffffff` prologue parses write `0x100`, with
**zero exceptions** — including components the config later gives wildly different numbers.
**So "the PC binary budgets `RuntimeIgnitor` at 256" is not a finding**; it is the default, read
before boot has touched it.

**2. `[presize]` resizes it at boot, and it is the authoritative capacity source.** The rows live in
the game's embedded config — `docs/game_config/cdbsizes.ini`, and byte-identically inside **PC
retail `.rdata` at `0x00BAD498`** (file offset `0x7AD498`), between `[achievements]` and
`[localization]`. They are **not** an Xbox symbol dump, which is what an earlier revision of §11
claimed. The grammar is `<name> <total-presize> [<page-capacity>]`.

**3. The live dump shows the result**, because `mercs2_unpacked.exe` is a post-boot memory image.
Join the two and every fire row agrees:

| component | `cdbsizes.ini` | `desc+0x0C` (total presize) | `desc+0x26` (shift) | `desc+0x28` (page cap) | `cap == 2^shift`? |
|---|---|---:|---:|---:|:-:|
| `Flammable` (`:105`) | `256` | 256 | 8 | 256 | ✓ |
| `Ignitor` (`:121`) | `96 32` | **96** | 5 | **32** | ✓ |
| **`RuntimeIgnitor`** (`:248`) | `8 8` | **8** | 3 | **8** | ✓ |
| `TickDamage` (`:315`) | `1024` | **1024** | 8 | 256 *(default kept)* | ✓ |
| `RtTickDamage` (`:222`) | `16 16` | **16** | 4 | **16** | ✓ |

Reproduce: read `[desc+0x0C]`, `word [desc+0x26]`, `[desc+0x28]` out of the dump at the container
bases in the table above. A capacity that fails `cap == 2^shift` means the wrong offset was used for
that descriptor class — the `0x00DFxxxx` array keeps page capacity at `+0x20` with the FNV seed
`0x9E3779B9` at `+0x28`, while the `0x017Bxxxx` array keeps it at `+0x28` with the seed at `+0x2C`.
(A parallel sweep joined all 334 containers against the INI: 325 rows join, 325 agree.)

**So `RuntimeIgnitor 8 8` is a real, citable, static fact: the shipped config presizes the
`RuntimeIgnitor` pool to 8 elements, one page of 8** — and `Ignitor` to 96 elements in pages of 32.
Note also that `Flammable 256` is a *single-column* row, i.e. it keeps the registrar's default page
capacity; it is not a deliberate fire-system budget, and should not be quoted as one.

**But it is a presize, not a cap** — and this is the step the old claim skipped. `FUN_0064A600`, the
insert the producer uses, has a pool-full path at `0x0064A663`: it pushes `[edi+0x10] + count`
(page capacity + current), calls the grow helper `FUN_0064A1D0` (`jmp [0x0245DC3C]` →
**`0x02E90000`**, an allocate-and-rehash routine, readable in full), then retries
`FUN_0064A090` and inserts. **The container grows one page at a time when it fills.**

**Grading, explicitly.** "The config presizes `RuntimeIgnitor` to 8" is **H** — INI and live
descriptor agree, two independent artefacts. "Therefore at most 8 objects burn at once" is **not
supported**: it needs both (a) exactly one `RuntimeIgnitor` per burning source, which is plausible —
`FUN_0066E650` makes exactly one per `Ignitor` entity — and (b) that the pool cannot grow, which is
**false**. What 8 licenses is a statement about *expected* concurrency: the designers sized this
pool for eight live ignition volumes and paid a reallocation for the ninth. **A reimpl should size
its arena for 8 and must not refuse the ninth.**

### 2.2 Authored → runtime: the class handler (H)

`FUN_0066F300` (9911 B, called once from `FUN_004646B0`) mints one 12-byte handler record per class
into `DAT_00ED3D20[]`: `{ vtable, pandemic_hash_m2(className), containerId }`. At `0x00670FC7` it does
exactly that for `s_Ignitor_00BC5400` with vtable **`0x00BCD0B4`** and container id `[0x017BE2AC]`:

```
0x00670FC7  movsx edi, word ptr [0x017BE2AC]   ; Ignitor container id
0x00670FCE  mov   edx, 0xBC5400                ; "Ignitor"
0x00670FD3  call  0x824270                     ; pandemic_hash_m2
0x00670FDE  mov   dword ptr [esi], 0xBCD0B4    ; the class handler vtable
```

Vtable `0x00BCD0B4` slot **`+0x18` is `FUN_0066E650`** — the `RuntimeIgnitor` producer. That vtable
slot is the marriage; it is not inferred from adjacency. It is also **not a shared producer**: a
scan of `.rdata` for the dword `0x0066E650` returns **exactly one** slot, `0x00BCD0CC`
(= `0x00BCD0B4 + 0x18`). (The class-handler vtables are `0x24` apart, so a reader who mistakes the
stride will see `0x00BCD090 + 0x3C` and conclude `ColorAnimation` shares it; `0x00BCD090 + 0x18` is
in fact `0x0066E580`, a different function.) The body settles it anyway — it opens with
`mov ecx, 0x17BE2A8`, the `Ignitor` container.

**`FUN_0066E650` (producer, read) — and it ROTATES the fields.** Resolves the authored payload
(`mov ecx, 0x17BE2A8; call 0x5857E0` @`0x0066E661`), reads **authored field 0** as the radius
(`movss xmm0,[ebx]` @`0x0066E676`), builds an axis-aligned box `centre ± f0`, calls
`FUN_004058B0(DAT_0117504C)` (broad-phase registration) and `FUN_006654B0(guid)`, tags
`FUN_008DC7A0(0x2005, 1, 0)`, then hands a 28-byte stack temp to `FUN_0064A600` @`0x0066E783`
(`edi = 0x017BF3A0`, the `RuntimeIgnitor` descriptor's insert cursor).

The temp is filled at `0x0066E71D`–`0x0066E745`, and the order is the whole point:

| instruction | reads | writes runtime | meaning |
|---|---|---|---|
| `0x0066E71D movss xmm0,[ebx+4]` | authored **`MinDamage`** | `+0x00` | rim rate |
| `0x0066E728 movss xmm0,[ebx+8]` | authored **`MaxDamage`** | `+0x04` | centre rate |
| `0x0066E733 movss xmm0,[ebx]` | authored **`Radius`** | `+0x08` | radius |
| `0x0066E745 mov dword …,0` | — | `+0x0C` | owner key, lazily resolved |
| `0x0066E73A mov byte …,0` | — | `+0x14` | one-shot flag |

> **Corrects an earlier claim.** §2.3 used to say the producer "copies them straight through". It
> does not: **authored `{Radius, MinDamage, MaxDamage}` → runtime `{rim, centre, radius}`**. A
> reimpl that mirrors the authored order into its runtime struct silently swaps the radius with the
> rim damage.

### 2.3 `RuntimeIgnitor` layout — read from `FUN_004B82D0` + `FUN_004B7BB0` (H)

| Off | Field | Read from | Conf |
|---|---|---|---|
| `+0x00` | **damage rate at the RIM** (per second; multiplied by `dt`) — authored `MinDamage` | `0x004B8321 movss xmm1,[ebx]; mulss xmm1,xmm0` → arg `[ebp+0x18]` in the falloff | H |
| `+0x04` | **damage rate at the CENTRE** (per second) — authored `MaxDamage` | `0x004B8332` → arg `[ebp+0x1C]`, the `dist == 0` value | H |
| `+0x08` | **radius** — authored `Radius` | `0x004B83CD fld [ebx+8]` → arg `[ebp+0x14]`, the falloff divisor and the range cutoff | H |
| `+0x0C` | **owner/self key**, lazily resolved once | `0x004B82F2`: if 0, `FUN_00648D80(0x00DF9160, guid)` — `0x00DF9160` is not a container base, it is `RuntimePhysicalLink (0x00DF9110) + 0x50`; used to skip candidates whose `+0x10` matches | H |
| `+0x10` | ignitor id passed to the applier | `0x004B83B2 mov edx,[ebx+0x10]` | M |
| `+0x14` | **one-shot "already ignited something" byte** | read at `0x004B8403` (`cmp byte ptr [ebx+0x14], 0`), **set at `0x004B84B9`** (`mov byte ptr [ebx+0x14], 1`) after the one-time FX/cue block runs | H |
| `+0x18` | broad-phase proxy (its cached AABB lives at `proxy+0xA0…+0xB8`) | `0x004B834A`, and the re-fit at the end of `FUN_004B82D0` | H |

> **Address correction.** An earlier revision cited `0x004B83E2` for the one-shot byte. That
> instruction is `mov byte ptr [esp+0x1b], 1` — a **stack local**, the `hitSomething` accumulator
> that §2.4's pseudocode names correctly. The member itself is only touched at `0x004B8403` (read)
> and `0x004B84B9` (write).

The first three are the authored `Ignitor`'s three floats (stride `0x0C`) **rotated by one position**
— see the producer table in §2.2. They are *not* copied straight through.

### 2.4 `UpdateIgnitor` = `FUN_004B82D0` (H)

Sole caller: the layer-4 `Rt*` pass **`FUN_00675E50`** at `0x00677219`, iterating the `RuntimeIgnitor`
container with its own stride/page globals — so the marriage to the Xbox zone name `UpdateIgnitor`
rests on *which pool it walks*, not on a string.

```c
void UpdateIgnitor(RtIgnitor *ig /*[ebp+8]*/, guid /*[ebp+0xC]*/, float dt /*xmm0*/) {
  if (!(dt > 0)) return;                                   // 0x004B82DF
  if (ig->owner_key == 0) ig->owner_key = FUN_00648D80(0x00DF9160, guid);
  rimRate    = ig->f0 * dt;                                // 0x004B8321
  centreRate = ig->f1 * dt;                                // 0x004B8332
  FUN_00665AF0(&pos);                                      // ignitor world position
  n = FUN_004B7B00(ig->proxy, hits /*35 slots*/);          // broad-phase overlap
  hitSomething = false;
  for (i = 0; i < n; i++) {
      cand = hits[i];  candKey = cand[0x10];
      if (candKey == ig->owner_key) continue;              // never ignite the source
      if (!FUN_004B7B50(cand, candKey)) continue;          // kind filter + Flammable (buildings)
      if (FUN_004B7BB0(guid, ig->id, &pos, ig->radius,
                       rimRate, centreRate, candKey, cand))
          hitSomething = true;
  }
  if (hitSomething && !ig->oneshot) {                      // 0x004B8415
      FUN_00505420(&pos, &nearestId);                      // nearest-of-N lookup
      if (dist < DAT_00BEA9B0) { thunk_FUN_03050000(&p); FUN_004F10D0(&desc); }
      ig->oneshot = 1;
  }
  if (proxy AABB != centre ± radius) FUN_008DE700(&aabb);  // re-fit the broad-phase box
}
```

#### `FUN_004B7B50` is **both** a type filter and the `Flammable` reader (H)

> **Corrects the previous headline claim of this section**, which read: *"`FUN_004B7B50` (the filter)
> is a **type filter, not a `Flammable` lookup** … That is the single most surprising finding in
> this section and it is why §7.1 flags `Flammable` as having no visible consumer."* Both halves
> were wrong, and the cause was Trap #1 (see the Method block): Ghidra emits
> `iVar2 = FUN_005857e0();` with the `ecx` operand dropped, so the `Flammable` descriptor simply is
> not in the decompiled text.

It does vcall `(*cand+0xE0)` — the same object-kind query the destruction message consumer
`FUN_0059BE00` uses — but then it dispatches through a jump table, and one arm is a component test.
Decode it yourself from the bytes (Ghidra says `size=63`; the real extent including both tables is
`0x004B7B50–0x004B7BA6`):

```asm
004B7B56  mov   edx, [eax+0xE0]                  ; object-kind vcall
004B7B5C  call  edx
004B7B5E  add   eax, -5
004B7B61  cmp   eax, 0xA
004B7B64  ja    0x4B7B8C                         ; default -> always burns
004B7B66  movzx eax, byte ptr [eax + 0x4B7B9C]   ; index bytes, 11 of them, kinds 5..15
004B7B6D  jmp   dword ptr [eax*4 + 0x4B7B90]     ; 3 targets
```

`[0x004B7B90] = {0x004B7B74, 0x004B7B77, 0x004B7B8C}` and
`[0x004B7B9C] = 00 01 00 02 00 02 00 00 00 02 00`, which gives:

| target | meaning | kinds |
|---|---|---|
| `0x004B7B74` `xor al,al; ret` | **never burns** | 5, 7, 9, 11, 12, 13, 15 |
| `0x004B7B8C` `mov al,1; ret` | **always burns** | 8, 10, 14, and `default` (any code < 5 or > 15) |
| `0x004B7B77` | **`Flammable` component test** | **6** |

```asm
004B7B77  mov  eax, [esp+4]                  ; entity
004B7B7B  mov  ecx, 0x17BE258                ; <-- the Flammable component descriptor
004B7B80  call 0x5857E0                      ; component fetch
004B7B85  neg eax ; sbb eax,eax ; neg eax    ; -> bool(component present)
004B7B8B  ret
```

**Which kinds are which.** Recover each kind by finding its `mov eax,<k>; ret` stub in `.text`,
finding the `.rdata` slots that hold it, treating `slot − 0xE0` as the vtable base (the object-kind
vcall is `[vtable+0xE0]`), and naming the ECS descriptors the vtable's constructor touches with
master key #1:

| kind | ignition | descriptor the ctor reads | reading |
|---:|---|---|---|
| **6** | **`Flammable` gate** | **`_BuildingPhysics`** (vtable `0x00BA9368`, ctor refs at `0x00435DB6`/`0x00435E15`) | **building** |
| 15 | never | `LowResTerrainObject`, `PhysicsActor` (vtable `0x00BA99B8`, ref at `0x0066D41F`) | terrain — the sanity anchor |

So **the `Flammable` gate covers buildings, and only buildings.** Everything else that burns burns
unconditionally; terrain never burns. Kinds 5, 7, 9, 11, 12, 13 have kind stubs but their
constructors reference no descriptor, and the game ships without RTTI for its own classes, so they
stay unnamed — an honest partial (§8 item 2).

This is exactly the shape a designer would ship: a burning car is always a burning car, but a
building burns only if the artist tagged it. It also sharpens the reimpl consequence — a reimpl that
drops `Flammable` will **over-burn buildings** specifically. (Read §7.5 before acting on that: no
shipped building is actually authored with one.)

### 2.5 The damage math — `FUN_004B7BB0` (H, disassembled)

Ghidra reports `size=664` for this function and decompiles it as a `void` that ends in a distance
calculation. **Both are wrong**: the real body runs `0x004B7BB0 → 0x004B82C2` (~1811 B) and returns a
bool in `al`. Read from the bytes:

1. **Distance.** `FUN_00431480(cand, &bbox)` gets the candidate's box; vcall `+0x3C` its position and
   `+0x40` its orientation quaternion; `D3DXQuaternionNormalize` / `D3DXMatrixRotationQuaternion` /
   `D3DXVec3TransformNormal` put the ignitor centre into the candidate's local frame; then the
   standard clamped per-axis squared distance and `FUN_00401740` (sqrt).
2. **Range gate.** `if (dist > radius) return false;` (`0x004B7E4F`–`0x004B7E58`).
3. **Linear falloff.**
   `v = (rimRate − centreRate) / radius * dist + centreRate` (`0x004B7E63`–`0x004B7E7C`).
   So the damage is `centreRate` at the centre and `rimRate` at the rim, both already `× dt`.
   `if (v <= 0) return false;`
4. **Scale by a 2-D `ModifierKey` × `DamageKey` matrix cell.** The map used to describe this as a
   one-dimensional "DamageKey tunable lookup". It is not — the row key comes from the **target**:
   ```asm
   004B7EDD  mov  eax, 0xDF8690          ; the ModifierKey container (master key #1)
   004B7EE2  call 0x649440               ; component fetch on the TARGET
   004B7EEB  mov  eax, [eax+4]           ; row key   (0 if the target has no ModifierKey)
   004B7EF2  cmp  dword [0x017BBD34], 0  ; nCols  (DamageKey axis)
   004B7EF9  xorps xmm0, xmm0            ; scale := 0.0 BEFORE the branch
   004B7F04  cmp  dword [0x017BBD30], 0  ; nRows  (ModifierKey axis)
   004B7F0D  push 0x8A552089             ; column key = pandemic_hash_m2("Fire")
   004B7F12  mov  esi, eax               ; ESI = row key  <- the register arg Ghidra drops
   004B7F14  call 0x632360
   004B7F19  mov  eax, [eax]             ; the matrix cell, a float
   004B7F28  mulss xmm0, v
   004B7F2E  comiss xmm0, [0x00B9B690]   ; epsilon
   ```
   Note `0x004B7F12` is the **row-key load**, not the `Fire` literal — an earlier revision of §0.5
   and §6.1 cited it as the literal address; the `push` is at `0x004B7F0D`.

   **`FUN_00632360` is fully recovered**, not confirm-live: `jmp [0x0245DE08]`, and
   `[0x0245DE08] = 0x02FB0000`, which is 127 bytes of clean x86 —

   ```c
   float* lookup(u32 modifierKey /*ESI*/, u32 damageKey /*stack, ret 4*/) {
       nRows = [0x017BBD30];  row = 0;
       for (i < nRows) if (rowKeys[i] == modifierKey) { row = i; break; }   // rowKeys = 0x017BBD38
       nCols = [0x017BBD34];  col = 0;
       for (i < nCols) if (colKeys[i] == damageKey)   { col = i; break; }   // colKeys = 0x017BBD40
       return &((float*)[0x017BBD48])[ nCols*row + col ];
   }
   ```

   The descriptor record at `0x017BBD30` is `{u32 nRows@+00, u32 nCols@+04, u32* rowKeys@+08,
   u32* colKeys@+10, float* matrix@+18}`; its initialiser is `0x006322A0` (zeroes the struct,
   installs vtable `0x00BBD06C` at `0x017BBD2C`) and the accessors run `0x00632420`–`0x00632717`.
   `rowKeys` is reached through a SecuROM split constant — `[0x0245A5C8] + [0x0074405F] =
   0xA7EF9739 + 0x598C25FF = 0x1_017BBD38`, truncating to `0x017BBD38` — which is why a naive
   cross-reference search never finds a writer.

   Because `xorps xmm0, xmm0` runs *before* the branch, **if either axis length is zero the scale
   stays `0.0`, the `comiss` fails, and nothing is posted at all.** Both are `0` in the static dump,
   but that dump predates tunable load, so it says nothing about a live session (§8 item 3).

   The identical call with `0xDC0A895F` = `pandemic_hash_m2("ExplosionLarge")` (`push` @`0x00630670`,
   `call` @`0x00630677`, and the same `mov eax, 0xDF8690` row-key preamble at `0x00630640`) and
   `0x29EFE0B5` = `MeleeBash` (`push` @`0x004CE2FA`, `call` @`0x004CE301`) is what proves the key
   domain. **Fire is a column of the combat damage matrix.**

   *Reimpl consequence:* how much fire hurts depends on the target's `ModifierKey`. A scalar
   "fire damage multiplier" is the wrong shape.
5. **Post.** Build the damage descriptor on the stack — `{0x011766F0, 2, id, 0, guid, …}` — then
   `FUN_00407B20(…)` and `FUN_00406170(…)`.
6. **Per-node repeat.** `0x004B80A0`–`0x004B82B2` walks the target's sub-nodes with
   `FUN_0041D340`/`FUN_0041D3C0`, computes a per-node distance, gets a per-node value from
   `FUN_00631E20`, applies **the same `Fire` scale** (second literal at `0x004B8212`) and posts again.

Steps 1–5 are the PC body of Xbox `ApplyDamageToPrimaryHealth`; step 6 is `ApplyDamageToNodeHealth`.
Those Xbox names are string-only, so the marriage is **role + shape**, i.e. **M**, but the two-pass
structure and the `RuntimeHealth`/`RuntimeNodeHealth` pair the destruction map already documents
make it about as tight as a nameless marriage gets.

**Concrete consequence for the reimpl:** fire damage is **continuous and dt-scaled while the volume
overlaps you**, not a per-hit event, and it hits *both* the object's primary HP *and* every node's HP
in the same frame. A reimpl that applies it once per object per frame will burn things down at
roughly `1/(1+nodes)` of the retail rate.

---

## 3. Burning over time: `TickDamage` → `RtTickDamage`

The Ignitor volume only damages what is *currently inside it*. Persistent burning — the thing that
keeps a vehicle cooking after the flame source is gone — is a **separate timer component**.

**`TickDamage`** — registrar `FUN_00642EF0`, container `0x017BE1B8`, stride `0x10`, schema
`FUN_00661CB0`:

```asm
00661CBE  mov edx, 0xBCAB74 ("DamageThresh") ; push 0 ; call 0x656210   ; int
00661CCA  mov edx, 0xBC9B0C ("Damage")       ; fldz   ; call 0x656320   ; float
00661CDD  mov edx, 0xBCAB84 ("TickLength")   ; fldz   ; call 0x656320   ; float
00661CF8  mov edx, 0xBCAB90 ("NodeName")     ; push 0x765CD254 ; call 0x656210
```

i.e. **`{int DamageThresh = 0, float Damage, float TickLength, name NodeName = 0x765CD254}`**. The
`mov edx` operands are the field names (master key #2); the string addresses above are literal and
re-readable. `0x765CD254` is still uncracked (§6.2) but is *not* an opaque int: the shipped schema
record types that field as a **name hash**, and `0x765CD254` is the HMMWV's own body node in the
`--states` dump — so the default is a HIER node name.

Xbox says `TickDamage @0x829f1e90` is **16 bytes**; PC stride is `0x10`. Exact agreement. (The
`[presize]` config gives `TickDamage 1024`, §2.1.)

**`RtTickDamage`** — registrar **`FUN_00646AA0`**, container `0x017BFBF8`, stride `0x10`.
`rendering-shaders.md` listed `FUN_00646AA0` positionally in a 12-name run; the registrar body's
`s_RtTickDamage_00BC5BBC` write confirms it.

**The tick itself** lives in the same layer-4 pass as `UpdateIgnitor`, `FUN_00675E50` at
`0x00676881`–`0x00676959`, and is fully in the clear:

```c
for each RtTickDamage inst:                    // container 0x017BFBF8, stride 0x10,
                                               // live count [0x017BFC18], ids [0x017BFC2C]
    acc = dt + inst[+0x08];  interval = inst[+0x04];
    if (acc < interval) { inst[+0x08] = acc; }            // accumulate  (0x00676919)
    else {
        inst[+0x08] = acc - interval;                     // consume exactly one tick (0x006768DD)
        xmm0 = inst[+0x00];                               // 0x006768F8 movss xmm0,[eax] — the AMOUNT
        FUN_00407B20(guid, 0xFFFF, 0xFFFF, 0, guid, 1, 0, 0, &DAT_011766F0);   // 0x00676908
        FUN_00406170(&desc);                                                   // 0x00676912
    }
```

So `RtTickDamage = { float Damage @+0x00, float TickLength @+0x04, float accumulator @+0x08,
u32 @+0x0C }`, matching the authored `TickDamage.Damage` / `TickDamage.TickLength` exactly.

> **Two corrections to the previous text of this section.**
> 1. *"the damage magnitude is carried in the descriptor, not the timer"* is **wrong**. It is in the
>    timer, at `+0x00`, loaded as a float into `xmm0` at `0x006768F8` — another register argument
>    Ghidra drops (Trap #1). The parenthetical guess that the two authored floats were
>    *(amount, interval)* was right; the sentence around it was not.
> 2. The post was written as `FUN_00407B20(…)` then `thunk_FUN_024B9B50(…)`, as though the second
>    were a different mechanism. **`FUN_00406170` *is* `jmp [0x0244FEA8]`, and `[0x0244FEA8] =
>    0x024B9B50`.** It is literally the same `FUN_00407B20 → FUN_00406170` pair as the ignition
>    path — which *strengthens* §10's evidence line 2 (one shared damage bus, now with three
>    producers on it).

**Honest gap:** the producer that turns an authored `TickDamage` into an `RtTickDamage` is registered
in `FUN_0066F300`'s handler table like every other class, but the `TickDamage` handler's `+0x18` slot
was not chased this pass. And **nothing statically visible attaches a `TickDamage` to an object the
Ignitor burned** — that link is exactly what needs a live check (§8.2). The two teardown sites
`FUN_004CF150` and `FUN_005234F0` both call `FUN_005E0580(&PTR_PTR_017BFBF8)` (remove
`RtTickDamage`), which at least proves the component is added and removed dynamically rather than
being purely authored.

---

## 4. The destruction link — where fire actually gets *started* in normal play

### 4.1 The state machine's `StartEmitter` command (cited + engine side new)

[`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) §3 and
[`../destruction_orchestrator_format.md`](../destruction_orchestrator_format.md) already establish the
vocabulary, and [`../modernization/vehicle_model_spec.md`](../modernization/vehicle_model_spec.md) §5
the state roles. Restated, not re-derived:

| hash | state | what it does |
|---|---|---|
| `0x1D5575A1` | **`DamagedState`** | body still shown, **fire emitters start** |
| `0x92791EBB` | **`StartDestroyedState`** | explosion, `CreateObject` debris, `SetState(DestroyedState)` |

The Enter-script command vocabulary includes `StartEmitter` / `StopEmitter` with **real FX names**
observed in retail data — `global_particle_fire_carhood`, `fx_Explosion_Large`, exhaust effects on
`hp_fx_exhaust_a`/`_b`. So a burning car is: health drops → `DamageMsg`/`DestroyMsg` →
`SetStateOnMsg` → `SetState(DamagedState)` → the Enter script runs
`StartEmitter(global_particle_fire_carhood, <hardpoint>)`.

**What this map adds is the engine side of that command.** Both routes — the machine's `StartEmitter`
and Lua's `ObjectState.StartEmitter` — land on the same function.

### 4.2 `FUN_004D28C0(guid, hardpointHash, effectHash)` — the emitter bridge (H)

```c
if (DAT_00D2AE64 < 0) return;                       // FX slot pool gate, table @0x012875E4 stride 0x810
scale = FUN_00649440(0x00DF8B10, guid)?[+4];        // OSMParameter component
tmpl  = FUN_00672F60(effectHash);                   // EffectTemplate lookup  (particle map §3)
if (!tmpl) return;
if (!FUN_00688970(guid, hardpointHash, &xform)) return;   // ★ resolve the HARDPOINT transform
FUN_008231D0(&desc);
FUN_006746D0(PTR_PTR_01176108, tmpl, &xform, &out, 0, 0); // spawn the effect
FUN_00649180(&PTR_PTR_00DF9110, guid, …, &state);   // register on the object's RuntimePhysicalLink
if (world_live && dist_gate) FUN_0048B470(…);       // PgFX (particle map §1 cluster)
```

Four things worth pinning:

- **The hardpoint resolve `FUN_00688970` is the whole point of the API**, and "hardpoint" is the
  engine's own word, not this map's: the string **`"Hardpoint"` lives at `0x00BC7760`** and is the
  authored name of `DebrisEffect`'s third field (§5), sitting beside `EffectName` and `Template` —
  the same (hardpoint, effect) pair `FUN_004D28C0` takes. The call site pins the signature including
  the two register args Ghidra drops:
  ```asm
  004D292A  mov ecx,[ebp+0xc]   ; node/hardpoint hash -> the one stack arg
  004D292E  mov eax, esi        ; guid                -> EAX
  004D2930  lea edi,[esp+0x74]  ; &out transform      -> EDI
  004D2934  call 0x688970       ; -> bool
  ```
  The `(guid, hardpointHash, effectHash)` notation used above is cdecl shorthand for
  `(EAX=guid, EDI=&xform, stack=hash)`. `FUN_00688970` itself is a thunk (`jmp [0x02459260]`,
  `[0x02459260] = 0x024EFE00`) — and note `0x00688970`–`0x0068897B` is a **block of three
  consecutive thunks**, so `0x00688980` is the *next function*, not this one's body.
- **The parameter is a HIER node-name hash in general**; `hp_*` is just the FX-authoring convention.
  `moonpatrol.lua:82-83` passes `String.GetHash("hp_fx_exhaust_a"/"_b")`, `spyhunter.lua` passes
  `hp_fx_jetexhaust` at all 12 of its sites (an earlier revision of this map cited spyhunter for
  `hp_fx_exhaust_a/_b`; it does not use those), `fueltank.lua:6,17` forwards the destruction
  machine's `uiNodeHashName` straight through, and `mrxsupportdesignatorsmoke.lua:61` passes a bare
  `StringToGuid("0x16516bb1")`. The shipped destruction data resolves both through the same slot —
  the HMMWV's `StartDestroyedState` script contains `StopEmitter(0x06A262B1, HIER:hp_fx_exhaust_a)`.
- **`PTR_PTR_00DF9110` is `RuntimePhysicalLink`** (master key #1; an earlier revision called it "the
  per-object live-emitter component"). `FUN_004F4340` writes it too, and the vehicle teardown
  `FUN_005234F0` clears it (`FUN_006499F0(&PTR_PTR_00DF9110,0,1)`). Likewise **`0x00DF8B10` is
  `OSMParameter`**, not a "per-object FX scale component".
- **`StopEmitter` is asymmetric**: it goes through `thunk_FUN_024E76E0` (SecuROM) rather than a
  visible callee. Its two hash args are read the same way.

### 4.3 `FUN_004F4340` — the deferred emitter-request drain (layer-4, H)

Caller `FUN_004C9740` at `0x004C99B8`, i.e. the same per-system list that holds the streaming pump,
the population tick and the player tick. It drains a request queue
(`thunk_FUN_024EBCF0(&out, DAT_00D6CC18)`) and for each request either calls `FUN_004D28C0` or
constructs the emitter component directly. This is how a `StartEmitter` issued from inside a state
transition (which runs behind the SecuROM `FUN_004D3E10` dispatch) reaches PgFX on a later frame.

Two details this map used to omit: the component it fetches is `FUN_00649440(0x00DF8710, guid)` =
**`ParticleKey`** (master key #1), and it gates on a **second 2-D matrix** with the same descriptor
shape as the DamageKey one — `cmp [0x017BBD58]` at `0x004F43A2`/`0x004F4489` and `cmp [0x017BBD54]`
at `0x004F43B2`/`0x004F4498`. So the drain is `ParticleKey`-keyed, and the engine uses the
`(row key × column key) → float` matrix pattern in at least two places.

### 4.4 `FUN_004D4680` = `RuntimeModelState::GetState(node)` — net-new (H role), and the one real wall

`FUN_00683C40` (a slot in vtable `0x00BCD400`, whose ctor `FUN_0067F870` is called from the
vehicle-physics-adjacent `FUN_00683D70`) does, twice, at `0x00683C70` and `0x00683CF5`:

```asm
mov  esi, 0xDF9310          ; ★ the RuntimeModelState pool
call 0x520EF0               ; pool lookup by guid
test esi, esi ; je skip
mov  edi, [ebp+0x18]        ; this object's switch-node hash
call 0x4D4680               ; ← GetState(machine, node)
cmp  eax, 0x381BE6A4        ; ← DanglingState (§6.1)
je   skip                   ;   skip -> `or [ebp+0x48], 0x20`
call 0x4D4680
cmp  eax, 0xCA261E5B        ; ← GoneState
je   skip
```

**`0x00DF9310` is named `RuntimeModelState`** by the engine itself (master key #1:
`[[0x00DF9310]+0x34]` is `mov eax, 0x00BC58E8; ret`, and `0x00BC58E8` reads `"RuntimeModelState"`).
`state_machine_destruction_code_map.md:84` describes the same pointer as the "runtime state-machine
instance pool", so this map's citation of its sibling was accurate — but neither map knew the
engine's own name for it, and the name *strengthens* the reading: the shipped state machines do
nothing but `Show`/`Hide` HIER meshes per state (§6.1), which is precisely a **model** state. So
`FUN_004D4680` is the read-side companion of `SetState` `FUN_004D3E10` — a `GetState(node)` the
destruction map does not yet list — with exactly **4** call sites image-wide, all in `FUN_00683C40`
(`0x00683C83`, `0x00683C8F`, `0x00683D0B`, `0x00683D17`), all against `RuntimeModelState`, all
comparing the result to state-name hashes.

**This is the one genuine SecuROM wall in this map, and it is worth saying precisely why.** The
usual advice — deref the resolved slot and read the relocated plaintext — works for
`FUN_00632360` (§2.5) and `FUN_00406170` (§3). It does not work here, because this function is
*virtualized*, not merely relocated:

```
FUN_004D4680   = jmp [0x0245A004]
[0x0245A004]   = 0x024E2F00   ->  push 0x024E2F0A ; call 0x01AAFF10
0x01AAFF10     = jmp [0x021FD554]
[0x021FD554]   = 0x02A30000   ->  jmp 0x02A30028 ; <string> ; pushal; pushfd; …
```

Dereferencing recovers a **bytecode dispatcher**, not x86 — and it announces itself: the bytes at
`0x02A30002`, jumped over by that first `jmp`, read
**`"You Are Now Entering a Restricted Area"`**. `mercs2_nodrm_v1/v2/v3.exe` do not restore it either.
The role is pinned by the pool it is called against and by the two constants its result is compared
with; the body needs the debugger (§8 item 1).

---

## 5. Fire as a *cosmetic* attribute: debris chunk trails

`DebrisEffect` (schema `FUN_006625E0`, handler vtable `0x00BCCFDC`, container `0x00DF8910`,
stride **`0x30`**) reads 6 int-family fields, 4 floats, then two enums. With master key #2 the
`mov edx` operands give the authored names:

| # | off | reader | `mov edx` | authored name | type (shipped record) |
|---:|---|---|---|---|---|
| 0 | `0x006625EC` | `FUN_00656210` | `0x00BC5F54` | `Name` | 6 = **name hash** |
| 1 | `0x006625FB` | `FUN_00656210` | `0x00BCAE6C` | `EffectName` | 6 = **name hash** |
| 2 | `0x0066260E` | `FUN_00656210` | `0x00BC7760` | **`Hardpoint`** | 6 = **name hash** |
| 3 | `0x00662621` | `FUN_00656210` | `0x00BCAE78` | `Template` | 6 = **name hash** |
| 4 | `0x00662634` | `FUN_00656210` | `0x00BCAE84` | `MinChunks` = 1 | 5 = int |
| 5 | `0x00662647` | `FUN_00656210` | `0x00BCAE90` | `MaxChunks` = 1 | 5 = int |
| 6 | `0x00662657` | `FUN_00656320` | `0x00BCAE9C` | `MinChunkVel` = 1.0 | 7 = float |
| 7 | `0x0066266A` | `FUN_00656320` | `0x00BCAEA8` | `MaxChunkVel` = 1.0 | 7 = float |
| 8 | `0x0066267F` | `FUN_00656320` | `0x00BCAE9C` ⚠ | **should be `MinChunkTime`** | 7 = float |
| 9 | `0x00662694` | `FUN_00656320` | `0x00BCAEA8` ⚠ | **should be `MaxChunkTime`** | 7 = float |
| 10 | `0x006626B1` | `FUN_00656720` | `0x00BCAEB4` | `Trail` (`ChunkTrailEnum` @`0x00BC72E8`) | 9 = enum |
| 11 | `0x006626C8` | `FUN_00656720` | `0x00BB90E8` | `Type` (`DebrisTypeEnum` @`0x00BC732C`) | 9 = enum |

`ChunkTrailEnum` = **`Fire`** (`0x00BC72D4`) · **`FireNoLight`** (`0x00BC72DC`).
`DebrisTypeEnum` = `OnDamage` · `OnDeathHit` · `OnNodeDeath` · `OnObjectDeath`.

So flying debris can carry a fire trail, with an explicit **"fire that does not cast light"** variant
— a shipped perf lever (a burning chunk is a dynamic light unless the artist picks `FireNoLight`).
This is pure presentation: nothing in `DebrisEffect` touches health.

Three refinements over the earlier "6 ints, 4 floats, then two enums":

1. **"6 ints" is loose.** Fields 0–3 are type-6 **name references**, not plain integers; only 4–5
   are ints. A reimpl that treats all six as integers mis-handles four name hashes. (Type codes,
   calibrated against components the ECS docs already describe: `1=bool, 5=int, 6=name, 7=float,
   9=enum, 10=Vector3`.)
2. **`Trail`/`Type` are the field names**; `ChunkTrail`/`DebrisType` are the *enum type* names. The
   old §0.5 row said `ChunkTrail`.
3. **⚠ A shipped defect in the retail exe.** Fields 8 and 9 pass the *same two string pointers* as
   6 and 7 (`0x00BCAE9C "MinChunkVel"`, `0x00BCAEA8 "MaxChunkVel"`) — and `"Trail"` follows
   immediately at `0x00BCAEB4`, so no `MinChunkTime`/`MaxChunkTime` string exists in the image at
   all. The shipped schema record in `vz.wad` gives fields 8/9 the distinct name hashes
   `0x83BA82B5` / `0x51D7BD57`, and `pandemic_hash_m2("MinChunkTime") == 0x83BA82B5`,
   `pandemic_hash_m2("MaxChunkTime") == 0x51D7BD57` (verified). **Retail registers the two
   chunk-lifetime fields under the chunk-velocity names** — a copy-paste bug invisible to either
   source alone.

Stride cross-check: `0x30` × 96 = 4608 = the `DebrisEffect 4608` row of `[presize]` (§2.1), two
independent numbers agreeing.

> **Corpus gap worth recording:** `DebrisEffect` does not appear anywhere in `docs/mercs2-ecs/` —
> not in `05_presentation_audio_fx.md`, not in `_registry_raw.tsv`, not in `_manifests/`. The
> nearest row is `RtDebris` (`03_controllers_physics.md:93`). The boundary table at the top of this
> map cites ecs-01/05 for `Ignitor`/`RuntimeIgnitor`/`Flammable` only, all three of which do exist
> there; `DebrisEffect` was derived here from the schema function, and the table above is currently
> the only write-up of it.

---

## 6. Hash results (nothing invented)

Everything here is `pandemic_hash_m2(name) == target`, verified with `tools/pandemic_hash.py --m2`.

### 6.1 Cracked

| Hash | **Name** | How | Conf |
|---|---|---|---|
| `0x8A552089` | **`Fire`** (a **DamageKey** — a matrix *column*, §2.5) | exact recompute; **code literal** at `0x004B7F0D`, `0x004B8212` (ignition applier) and `0x00693DEC` (§7.2) | **H** |
| `0xDC0A895F` | `ExplosionLarge` (DamageKey) | same call-site family (`push` `0x00630670`, `call` `0x00630677`) — corroborates the key domain | H |
| `0x29EFE0B5` | `MeleeBash` (DamageKey) | same (`push` `0x004CE2FA`, `call` `0x004CE301`) | H |
| `0x787C0871` | **`Weapon`** | code literal at `0x00693DE3`, paired with `Fire` (§7.2) | **H** |
| **`0x381BE6A4`** | **`DanglingState`** | **newly cracked — see below.** Code literal ×2 in `FUN_00683C40`; the semantic slot was pinned from shipped data first | **H** |
| `0xCE603754` | **`FalloffState`** | see below | **M** (name) / **H** (role) |
| `0x28825D4C` | **`PauseState`** | see below | **M** (name) / **H** (it is a *state*) |
| `0xA530B827` | `DetachState` | present in shipped HMMWV data; the state `0xCE603754` spawns into | H (role) / M (name) |
| `0x37A605FF` | `DebrisState` | present in shipped HMMWV data (nodes 9/10, entered by `StartDestroyedState`'s `CreateObject`) | H (role) / M (name) |

#### The command and message vocabulary, cracked out of shipped destruction data

Every one of these is `pandemic_hash_m2(name) == target`, re-verified with
`tools/pandemic_hash.py --m2`, and every one appears as a live opcode in the dump produced by:

```
MERCS2_VZ_WAD=<install>/data/vz.wad cargo run -p mercs2_workshop -- --states 0xAC990539
```

(`0xAC990539` = `al_veh_truck_hmmwv_avenger`, 90 HIER nodes, 25 switch slots, 11 nodes.)

| hash | name | hash | name |
|---|---|---|---|
| `0x9B31491A` | `SetState` | `0xE1142510` | `SetStateOnMsg` |
| `0x9228E8A2` | `Show` | `0x07EAD185` | `Hide` |
| `0x3347914F` | **`StartEmitter`** | `0x687C78C5` | **`StopEmitter`** |
| `0xC6E8AFA8` | `CreateObject` | `0x6A5C2678` | `PropTemplate` |
| `0x842AE03E` | `DisableConstraint` | `0xC20AB66F` | `SetRootNode` |
| `0x28B83DF1` | `PushLink` | `0x6FDAC686` | `BreakLink` |
| `0xEA0AB8C9` | `Kill` | `0x1ED7AD78` | `DestroyMsg` |
| `0xC6507EE1` | `DamageMsg` | `0x0ACE072A` | `InitState` |
| `0xACB51200` | `PristineState` | | |

`StartEmitter`/`StopEmitter` are a can't-coincide anchor: on the HMMWV body node, `DamagedState`'s
**enter** starts emitter `0xC6666A25` on three nodes and its **exit** stops *the same* emitter on
*the same* three nodes.

#### `0x381BE6A4` = **`DanglingState`** — cracked, and it overturns §6.2's old semantic reading

The HMMWV carries **two parallel state vocabularies**: a *named* one on the body node
`0x765CD254`, and an *unnamed* one on the three detachable panel nodes (`0x2CE53661`, `0x3DF5A3EF`,
`0x962C4871`). Line them up by their `SetStateOnMsg` wiring, which is identical:

| body node (named) | panel node | entered on | role |
|---|---|---|---|
| `0xACB51200` `PristineState` | `0xACB51200` `PristineState` | — | shared |
| `0x1D5575A1` `DamagedState` | **`0x381BE6A4`** | `DamageMsg` | shows the damaged mesh, still attached |
| `0x92791EBB` `StartDestroyedState` | **`0xCE603754`** | `DestroyMsg` | the transition that spawns the piece |
| `0x7687DF41` `DestroyedState` | `0xCA261E5B` `GoneState` | — | terminal |

The panel scripts, verbatim from the `--states` dump:

```
state 0x381BE6A4  enter: Show(HIER:0x2FD85212); SetStateOnMsg(0, DamageMsg, node)
                  exit : Hide(HIER:0x2FD85212); DisableConstraint(node)
state 0xCE603754  enter: SetStateOnMsg(0, DestroyMsg, node); SetStateOnMsg(0, 0x3D0D4C99, node);
                         CreateObject(1, HIER:0x2FD85212, PropTemplate, DetachState, node);
                         SetState(GoneState, node)
state 0xA530B827  DetachState  enter: SetRootNode(node); Show(HIER:0x2FD85212)
```

With the semantic slot known — the damaged-but-still-attached state of a detachable panel — a
targeted sweep over `{prefix} × {damage/attachment cores} × {State, Msg, Command, …}` returns
exactly one hit:

> **`pandemic_hash_m2("DanglingState") == 0x381BE6A4`** — verify with
> `python tools/pandemic_hash.py --m2 DanglingState`.

The vocabulary reads **`Pristine → Dangling → Falloff → Detach → Gone`**. A panel takes damage and
**dangles**; it then **falls off**, spawning itself as a physics prop that enters `DetachState`; the
original node goes `Gone`.

> **This contradicts §6.2's old reading.** That section argued `0x381BE6A4` was *"a post-destruction
> terminal sibling of `GoneState`"* meaning *"this object is finished"*. It is nothing of the sort —
> it is a **mid-life damaged** state. The `FUN_00683C40` compare pair now reads sensibly as *"skip
> this behaviour if the node is dangling or gone"*, i.e. no longer a load-bearing attached part.
> (The old section's **disproof** of `FireDebrisState` `0x4C88281B`, `FireDestroyedState`
> `0x004641A5`, `CollapseFireState` `0x0753C8F7` and `DebrisState` `0x37A605FF` still stands — none
> of them hash to `0x381BE6A4`.)

**`0xCE603754` = `FalloffState` — stays M; do not downgrade it.** The name is still pure hash
arithmetic with no code literal and no string in the image (the dword occurs **zero** times in
`mercs2_unpacked.exe`; only `0x381BE6A4` and `0xCA261E5B` do, twice each). But the older worry that
"the value occurs nowhere, so there is nothing for the crack to explain" is **false**: it occurs in
shipped destruction data, dumpable from `vz.wad` with the `--states` command above and listed in
[`../destruction_orchestrator_format.md`](../destruction_orchestrator_format.md):81. Its **role** is
now demonstrated rather than guessed — `0xCE603754`'s entire job is to spawn the panel as a detached
prop and vanish, i.e. a panel that falls off, with `DetachState` literally as its sibling — and
`DanglingState` cracking in the adjacent slot of the same five-state machine is independent mutual
support. The old counter-argument about the retail `Falloff` strings sitting in a shader/material
cluster (`state_falloff` @`0x00BCA4B0`, `Falloff` @`0x00BCA4C0`, `MinForceFalloff`,
`MinFalloffScale`) can be **retired**:
that cluster was never the evidence, and the shipped machine now is.

*(For the record, this map's own proposed settling test was aimed at the right machine but the wrong
state: `DisableConstraint` and `SetRootNode` turn out to live in `DanglingState`'s **exit** and
`DetachState`'s **enter**, not in `FalloffState`.)*

**`0x28825D4C` = `PauseState`** — the *role* is **H**, the *name* is **M**. That it is a **state**,
not a node, is settled by `docs/mercs2-luacd/src/resident/oilrig.lua:31-45`:

```lua
function OnStateChange(uiGuid, uiNodeHashName, uiStateHashName)
  local sStateHashName = Sys.GuidToString(uiStateHashName)
  if sStateHashName == "0x28825D4C" then
    local sLayer = tTGLayers[Sys.GuidToString(uiGuid)]
    MrxLayerManager.Remove(sLayer .. "_tg")
    Sound.CueSound(uiGuid, "seq_oilrig_destruction")
    Camera.Shake(StringToGuid("0x1"), "ShakeCameraConstantlyRandom", uiGuid, 0.5, 2000)
    local e = Event.Create(Event.TimerRelative, {2.5}, _DestroyOilrigSequence, {uiGuid, uiNodeHashName})
  elseif sStateHashName == "0x694683EB" then …
```

It is stringified from **`uiStateHashName`**; `uiNodeHashName` is never compared in the file, only
forwarded. The `elseif` comparand `0x694683EB` is `pandemic_hash_m2("CollapseState")`, corroborated
in the same file by `oilrig.lua:314` calling `String.GetHash("CollapseState")` — which pins the
argument slot. So `state_machine_destruction_code_map.md:406` ("`0x28825D4C` | node | oilrig
destruction node … needs the model's HIER dump") is a **misattribution**, and the HIER dump is not
needed. Two details this map previously missed: the branch also does a layer swap
`MrxLayerManager.Remove(sLayer .. "_tg")` keyed by the rig's own GUID, and `0x694683EB` is **not**
oilrig-specific — `islandfortress.lua:54` matches the same state gated on node `0xCF37044A`.

`PauseState` fits the handler — cue `seq_oilrig_destruction`, shake the camera, schedule
`_DestroyOilrigSequence` **2.5 s later**, i.e. the machine sits in a pause while the script stages
the demolition. But the **name** is still pure hash arithmetic: the string `PauseState` occurs as an
object state nowhere in the exe and nowhere in the 370-script corpus (the corpus hits are
`MrxSound.EnterPauseState()` audio calls, unrelated). **M for the name, H for the role.**

### 6.2 Not cracked — reported honestly

Nine hashes in this area resist. Each was attacked with: every printable token harvested from the PC
exe, the Jul-08 devkit dump, `vz.wad` block 3185 and the whole `docs/` tree, × ~180 prefix/suffix
combinations (`State`, `Msg`, `Command`, `Node`, `Event`, `Anim`, `Phase`, `Mode`, `Damage`, `Key`,
and `Fire*`/`Debris*`/`Destruction*`/`Building*` prefixes), plus curated multi-token compounds,
`_`-separated variants, `hp_`/`fx_`/`global_particle_`/`node_`/`bone_` prefixed forms, and the
739 446-entry `tools/rainbow_table.json`. Roughly 1.7 M distinct candidates in total. **No hits, and
nothing is invented.**

| Hash | Kind | Note |
|---|---|---|
| `0x765CD254` | `TickDamage.NodeName` default | typed as a **name hash** by the shipped schema record, and it is the HMMWV's own body node in the `--states` dump — so it is a HIER node name, not an opaque int |
| `0x3D0D4C99` | message, travels everywhere `DestroyMsg` does | every `SetStateOnMsg(X, DestroyMsg, n)` in the HMMWV data is paired with `SetStateOnMsg(X, 0x3D0D4C99, n)` |
| `0xB4DBE473` | Enter/Exit command verb | — |
| `0x5A6E8927` | state (the "damage-arming" state: wires the msg handlers, then `SetState(Damaged/Dangling)`) | HMMWV, all nodes |
| `0x5D308F4F` | state (jumps straight to the terminal state) | HMMWV, all nodes |
| `0xC6666A25` | the fire-emitter effect name started by `DamagedState` | HMMWV body node |
| `0x06A262B1` | the exhaust effect name stopped by `StartDestroyedState` on `hp_fx_exhaust_a/_b` | HMMWV body node |
| `0x82794606` / `0x780EC3C8` | Enter-script command verbs seen only in `StartDestroyedState` | HMMWV body node |

Also uncracked, from the shipped reflection records (§5): `Flammable`'s single field name
`0x8B50DC56`, and `DebrisEffect` fields 4/5 `0xC5528D68` / `0xB4CB8AD2`. These appear in no shipped
binary and likely existed only in the authoring tool.

**Retired from this list: `0x381BE6A4`.** It was carried here for two revisions as "not cracked, but
with hard semantic evidence"; that evidence turned out to point the wrong way, and the name is now
**`DanglingState`** (§6.1). The structural observation that made the old entry worth keeping — that
`0x381BE6A4` occurs exactly **twice** image-wide, both in `FUN_00683C40`, each time immediately
paired with a `GoneState` compare on the same value — is still exactly right, and is now the
supporting evidence for the crack rather than a substitute for it. (One clarification the old text
needed: "the only code literal in the whole decomp" is true read as *"the only two occurrences of
this value are these"*, and false read as *"the only destruction-state hash that appears as a code
literal"* — `GoneState` `0xCA261E5B` is a code literal in the very same four instructions.)

---

## 7. Corrections and false friends

### 7.1 ~~`Flammable` has no visible reader~~ — **RETRACTED. It does, and it is in the fire path.**

**Old claim:** *"Registered, schema'd, budgeted for 256 instances on Xbox — and a full-corpus scan
for its container `0x017BE258` returns only the registrar, the schema and the stream-add helper
`FUN_0063C690`. The ignition filter `FUN_004B7B50` filters by object kind, not by this component.
… a reimpl that models 'fire spreads to things tagged Flammable' may be modelling something retail
does not do."*

**Every part of that is wrong.** The reader is `FUN_004B7B50` itself, at `0x004B7B7B`
(`mov ecx, 0x17BE258`), reached for entity kind **6 = `_BuildingPhysics`** — the full decode is in
§2.4. `.text` references to `0x017BE258` are `0x004B7B7C` (this reader) plus `0x006430AF` /
`0x006430C5` (its own registrar); the earlier scan missed the reader because Ghidra prints the
component fetch with **no operand** (Trap #1, Method block).

**The reimpl guidance was therefore inverted.** Retail *does* gate ignition damage on a `Flammable`
component — for buildings. A reimpl that drops `Flammable` will over-burn buildings. Read §7.5
before deciding how much that matters in practice.

### 7.2 `Fire`/`FireNoLight` ≠ `FireAngleEnum` ≠ `LinkedFire` ≠ the `(Weapon, Fire)` record

Four unrelated uses of the token, adjacent enough to be misread:

- `Fire` / `FireNoLight` @`0x00BC72D4` — **`ChunkTrailEnum`**, debris trails (§5).
- `FIREANGLE_NARROW/MEDIUM/WIDE` @`0x00BC740C` — **`FireAngleEnum`**, AI weapon spread (weapons map).
- `LinkedFire` / `AlternateFire` @`0x00BC6304` — **`WeaponCouplingTypeEnum`**, turret coupling.
- `Fuel` @`0x00BC6228` — a **`PickupTypeEnum`** value, nothing to do with `FuelTrail`.

**And a fourth `Fire`-hash site, which is probably a fifth false friend.** `0x8A552089` occurs
**three** times in `.text`, not two: `0x004B7F0D` and `0x004B8212` in the applier, and a third at
`0x00693DEC` inside `FUN_00693D80` (306 B; Ghidra `callers=[]`):

```asm
00693D98  push 0xDF7A88                        ; the AnimationResponse container
00693D9D  lea  esi,[esp+0x14] ; call 0x6499F0  ; enumerate its instances
...
00693DE3  cmp dword ptr [eax+4], 0x787C0871    ; pandemic_hash_m2("Weapon")   -- cracked here
00693DEA  jne skip
00693DEC  cmp dword ptr [eax+8], 0x8A552089    ; pandemic_hash_m2("Fire")
00693DF3  jne skip
00693DF5  push eax ; mov eax,[edi] ; push eax ; call 0x00693BB0
```

`pandemic_hash_m2("Weapon") == 0x787C0871`, verified. So there is a `(Weapon, Fire)`-keyed path
outside the ignition applier, and given that the engine keys damage on *pairs* (§2.5) a two-key
record is on-thesis. **But the container is `AnimationResponse`** (`0x00DF7A88`, named by master
key #1 and independently listed at `object_entity_core_validation.md:1572`), which makes the more
likely reading *"play the animation response registered for (category `Weapon`, event `Fire`)"* —
i.e. `Fire` here is the **verb**, the act of firing a weapon, homonymous with the DamageKey. This
map does **not** claim `FUN_00693D80` reads the same table as `FUN_00632360`; that is unestablished.
(`FUN_00693BB0`, the callee, is another Ghidra mis-size: `size=24` against a real
`0x00693BB0–0x00693CBB`, 268 B.)

Only the DamageKey `Fire` (hash `0x8A552089`, no string in retail `.rdata`) is this map's subject.

### 7.3 The weapons map's `RuntimeIgnitor` update attribution

[`weapons_combat_code_map.md`](weapons_combat_code_map.md) §2.1 lists the weapon-driver leaves
`FUN_0051B140`/`FUN_00525170`/`FUN_005234F0`/… as "the RuntimeWeapon / RuntimeWeaponProjectile /
RuntimeProjectile / **RuntimeIgnitor** / RuntimeVelocity per-type updates". The `RuntimeIgnitor` part
of that list is **not right**: the `RuntimeIgnitor` pool (`0x017BF388`) is walked by `FUN_00675E50`
and dispatched to `FUN_004B82D0`, from the **layer-4 `Rt*` pass**, not from the weapon driver. (The
rest of that sentence is untouched by this finding.) `FUN_005234F0` *does* appear in the fire story,
but only as a teardown that removes `RtTickDamage`.

### 7.4 `FUN_004B7BB0`'s Ghidra output is not usable

`size=664`, `void` return, three recovered parameters against eight actual stack arguments, and the
whole per-node pass missing. Anything derived from the decompiler text for this function is wrong.
The real extent is `0x004B7BB0–0x004B82C2` (`ret` at `0x004B82C2`, returning `al` from `[esp+0xf]`),
1811 bytes; use the disassembly. `FUN_004B7B50` (`size=63` vs 96 B incl. its tables) and
`FUN_00693BB0` (`size=24` vs 268 B) are mis-sized the same way.

### 7.5 ★ The components are registered, schema'd and read — and **nothing in the shipped world is authored with one**

This is the single most decision-relevant fact in the map for anyone about to build the system, and
it is a *negative*, so it has to be stated loudly or it will be missed.

`block_content_grep` over all **11 370** decompressed blocks of retail `vz.wad`
(`ok=11370 failed=0`, so no silent decompression failures) puts every fire component in **exactly
one** block:

| needle | blocks in `vz.wad` |
|---|---:|
| `Health` (positive control) | **754** |
| `Flammable` | **1** |
| `Ignitor` | **1** |
| `TickDamage` | **1** |
| `RuntimeIgnitor` | **0** |
| `RtTickDamage` | **0** |

and that one block is `block=3185  blocks\VZ\resident_P000_Q3.block` — the **reflection block**,
which holds ~160 schema records plus an alphabetical hash→name registry, one row per *type*. It is
where every component in the game is declared, not where any is placed.

Reproduce:

```
MERCS2_VZ_WAD=<install>/data/vz.wad \
  cargo run -p mercs2_probe --bin block_content_grep -- Flammable
```

The negative is decisive rather than a tooling artefact, on three grounds:

1. **Format.** A component instance is declared by a `COMP` chunk whose `info` child is the
   NUL-terminated ASCII class name (`crates/mercs2_formats/src/placement.rs:159-175`). Any block
   declaring a `Flammable` *must* contain the literal bytes.
2. **Positive control.** `Health` appears in 754 blocks, 751 of them `vz_state_*`/`layers_static`.
   The fire components appear in the reflection block only.
3. **COMP inventory.** `layers_static` carries 722 COMPs across 43 types (`Ai`, `ModelName`,
   `ModifierKey`, `StateMachine`, `_BuildingPhysics`, …) — **no fire/ignition component among them**.

**Reading.** `Ignitor` / `Flammable` / `TickDamage` are fully registered types with authored schemas
and **no static authored instances anywhere in the world data**. They are attached at runtime, if at
all — by script, weapon effect or the destruction code — or they are vestigial.

Note how oddly this sits beside §2.1: the shipped config **presizes these pools deliberately**
(`Ignitor 96 32`, `RuntimeIgnitor 8 8`, `TickDamage 1024`, and `Health 3328` / `RuntimeHealth 1280`
for comparison), the schemas are authored and registered, and the reader code is live — and yet
**nothing authored fills them**. The pools are budgeted, the components are declared, and the world
data has zero instances. That combination sharpens the conclusion rather than weakening it: this is
a finished, tuned system wired to an input that the shipped content never provides. `Flammable 256`
in particular is a *single-column* row, i.e. the registrar default retained — it is not even
evidence of a deliberate fire budget, only of the absence of one.

So §7.1's corrected finding should be read with that ceiling on it: retail *can* gate building
ignition on `Flammable`, but nothing in the shipped world is authored with one. **A reimpl should
implement the gate — the code path is real and cheap — while expecting it never to fire from
authored data**, and should not budget engineering for "which buildings are flammable" content
questions that have no shipped answer.

Caveats stated honestly: this covers **`vz.wad` only**, and the corresponding raw little-endian scan
for the five component *hashes* skips blocks larger than 6 MB (the string pass does not). That hash
scan returns 0 blocks for `Flammable 0xD930020E`, `Ignitor 0x37C12455`, `RuntimeIgnitor 0x1CA3ABD7`,
`RtTickDamage 0x27E19BF7` and `DebrisEffect 0x4EC11797`; its single hit for `TickDamage 0x8DEF82AD`
is at an unaligned offset inside a 1 MB `UCFX` geometry payload with no `COMP`/`info`/`schm` tag —
a 4-byte collision, ≈1.4 expected across the search space. **What is still open** is a
prototype/placement dump proving the runtime attach point (§8 item 2).

---

## 8. Open questions / confirm-live inventory

Read-only while **PAUSED**; the USER drives execution ([[x32dbg-mcp-no-resume]]), and a conditional
breakpoint on a per-frame function will kill the session ([[x32dbg-mcp-pitfalls]]) — every item below
is a **one-shot** breakpoint or a HW watchpoint.

Five items that used to be on this list are **closed statically** and are gone: *does anything read
`Flammable`* (yes — §2.4/§7.1), *`FUN_004B7B50`'s kind constants* (kind 6 = `_BuildingPhysics`,
kind 15 = terrain — §2.4), *`FalloffState` and `0x381BE6A4` in real data* (`--states 0xAC990539` —
§6.1), *was `Graphics.FuelTrail` ever reachable* (no shipped block even contains the string — §1),
and *the writers of the tunable-table counts* (the record and its initialiser `0x006322A0` — §2.5).
What remains:

1. **`FUN_004D4680`'s body — the one genuine wall.** One-shot bp at `0x004D4680`, then single-step
   through `[0x0245A004] → 0x024E2F00 → 0x01AAFF10 → [0x021FD554] → 0x02A30000`, which is the
   SecuROM **VM interpreter**, not a relocated body (§4.4). Read `EAX` on return against a model
   whose states are known from `--states`. Confirms `RuntimeModelState::GetState` and, in the same
   sitting, the destruction map's §8 item 1 (`FUN_004D3E10`'s Enter-script interpreter).
2. **What attaches `TickDamage`/`RtTickDamage` to a burning object — and what attaches `Ignitor` at
   all?** HW-write watchpoint on `DAT_017BFC18` (the `RtTickDamage` live count) while burning a
   vehicle; one-shot bp on `FUN_0066E650` and read the owning entity. **§7.5 makes this the
   highest-value item in the map**: nothing in `vz.wad` authors any of these components, so the
   entire attach path is runtime-only and currently unobserved. Until it is observed, "fire spreads
   and things keep burning" is a mechanism this map can describe but cannot show being *used*.
3. **Are the damage-matrix axes non-zero in a live session?** `[0x017BBD30]` (rows) and
   `[0x017BBD34]` (cols) are both `0` in the static dump because it predates tunable load. If either
   is zero at runtime, the `comiss` at `0x004B7F2E` fails and **ignition damage is silently zero**
   (§2.5). One-shot bp at `0x004B7F14` and read the returned cell. This gates everything in §2.5
   step 4 onward.
4. **Entity kinds 5, 7, 9, 11, 12, 13.** Their vtable constructors touch no ECS descriptor and the
   game ships without RTTI for its own classes, so master key #1 cannot name them. One-shot bp at
   `0x004B7B6D`; read the vcall result for a human, a vehicle, a prop, a helicopter.
5. **`FUN_00505420`'s table** (`DAT_01796554`, count `DAT_01175D8C`, ids `DAT_00ED564C`) — a
   nearest-of-N lookup on first ignition, feeding the one-shot cue at `0x004B84B4`. Dump the table
   live; likely "nearest listener/player", but that is a structural guess. The cue also passes an
   uncracked hash `0xBB427635` (`0x004B84A6`).
6. **Was `Graphics.FuelTrail` ever live on *any* platform?** The name is in the Jul-08 devkit
   strings. If the devkit build has real bodies for `Ignite`/`Extinguish`/`Put`, the mechanic
   shipped somewhere and the PC stubs are a port-time strip — a fix-pack-relevant fact. (The PC
   side is settled: dead code, zero reachable call sites.)

---

## 9. Reconciliation with the Rust reimpl

This map does **not** edit that tree — another agent owns it. Two of the four defects this section
used to list have since been **fixed**:

1. ~~Wrong name and wrong install path~~ — **DONE.** `fire.rs` now declares
   `NAMESPACE = GLOBAL = "Graphics.FuelTrail"` and installs via a new
   `b.install_child("Graphics", "FuelTrail")` (`bindings/mod.rs:202`), matching the retail marker-row
   sub-table. The `corpus_calls` census was re-run under the correct key and is **0/0/0 — correct**
   (§1 now proves the strong form of that from `vz.wad`, not just from the decompiled subset).
2. **Still open: two bindings are `b.real` that must be `b.stub`.** `Ignite` and `Extinguish` point
   at `0x006D5640` in retail; `fire.rs:38,40` still give them real bodies calling `host.fire_ignite`
   / `fire_extinguish`, while the file's own doc-comment at `:30-31` says "faithful no-ops".
3. **Still open: `Put` must also be a no-op** — but a *type-checking* one: it reads up to four args
   and raises on a bad type before doing nothing (§1). `fire.rs:42` models it as `Extinguish`
   (identical body, single `i64` arg, no 4-arg type check), which is wrong twice over.
4. ~~`Graphics` is missing 84 of its 95 rows~~ — **overstated; the real gap is 6 rows.** The
   11-row top-level count and the flattening are right, but **69 of the 75 callable rows do exist**
   with real bodies at the wrong Lua paths; only `MotionBlur`/`Contrast`/`Monochrome`/`Grainy`/`AA`
   are absent. This section also named the wrong file: **`camera_fx.rs` is not a `Graphics` child**
   — its `TABLE_VA 0x00b9a7d8` is past the blob terminator `0x00B9A7C8` that §1 establishes. The
   file it should have named is **`fade.rs`** (`TABLE_VA 0x00b9a778` = `Graphics.Effect`).

**What the actual fire system needs, if a silo is to build it:**

- **Read §7.5 first.** Nothing in `vz.wad` is authored with `Ignitor`, `Flammable` or `TickDamage`.
  Build the code paths; do not budget for content plumbing that has no shipped input.
- An **`Ignitor` component** authored as **`{f32 Radius, f32 MinDamage, f32 MaxDamage}`** and a
  **`RuntimeIgnitor`** `{rim, centre, radius, owner_key, id, oneshot, proxy}`. ⚠ **The producer
  rotates the fields** (§2.2): authored `{Radius, MinDamage, MaxDamage}` → runtime
  `{rim=MinDamage, centre=MaxDamage, radius=Radius}`. Mirroring the authored order into the runtime
  struct silently swaps radius and rim damage. **Size the arena for 8 live ignitors and let it
  grow** — the shipped config presizes `RuntimeIgnitor` to exactly 8 (`cdbsizes.ini:248`, confirmed
  against the live descriptor), but retail grows the pool a page at a time when it fills, so a hard
  cap at 8 is a divergence. The old instruction here — "cap **8 live** (Xbox pool budget)" — was
  wrong in both its sourcing and its "cap" (§2.1).
- An `update_ignitors(dt)` system that, per instance: broad-phase overlap → skip `owner_key` →
  kind filter, **with a `Flammable`-component gate on buildings only** → per-candidate clamped-OBB
  distance → **`v = lerp(centre_rate, rim_rate, d/r) * dt`** → × the **`ModifierKey` × `DamageKey`
  matrix cell**, *not* a scalar tunable (§2.5) → apply to **primary health *and* every node's
  health**.
- A **`TickDamage`/`RtTickDamage`** accumulator `{Damage, TickLength, acc}` ticked in the same pass,
  posting one damage event of `Damage` per `TickLength` — through the **same** damage-post path, not
  a parallel one (§3).
- The FX is a *separate* call: `start_emitter(guid, hardpoint_hash, effect_hash)` resolving the
  hardpoint node's world transform. `mercs2_engine::particles::start_emitter(name_hash, origin)`
  exists and indeed **lacks the hardpoint resolve** — the piece `FUN_00688970` provides
  ([`particle_fx_code_map.md`](particle_fx_code_map.md) §7).
- `ObjectState.StartEmitter`/`StopEmitter` are the highest-traffic bindings in this map — but the
  counts this section used to give (14 each) are wrong. Measured over `docs/mercs2-luacd/`:
  **`ObjectState.StartEmitter` = 20 references — 10 syntactic calls** (`fueltank` 2, `moonpatrol` 2,
  `mrxsupportdesignatorsmoke` 1, `spyhunter` 5) **+ 10 deferred `fn = ObjectState.StartEmitter`
  dispatches in `oilrig.lua`**; **`ObjectState.StopEmitter` = 10, all syntactic calls**
  (`spyhunter` 7, `moonpatrol` 2, `fueltank` 1). `object_state.rs:48-49` still carries 14/14 and
  should be corrected. They remain the *only* fire-adjacent bindings the shipped scripts use.
  ⚠ `engine_support_inventory.md` §3 line 161 marks them `❌`, but that row is now **stale**:
  `object_state.rs:81,86` install both as `b.real` (bookkeeping only — they never reach
  `Scene::fx_start`/`fx_stop`, which do exist at `scene.rs:1221-1232`).
- Nothing else of the system exists yet: no `Ignitor`/`RuntimeIgnitor`/`Flammable`/`TickDamage`
  component and no `update_ignitors` anywhere in `tools/wad_simulator`, and
  `mercs2_combat::DamageKey` has no `Fire` variant.

---

## 10. Recommendation: **fire belongs to silo 10 (combat), not silo 3 (particle FX)**

The evidence, in the order it decides the question:

1. **The system is a damage volume.** `UpdateIgnitor` (`FUN_004B82D0`) does an overlap query, a
   distance falloff, and a damage post. There is not one particle-system call in it. The only FX in
   the whole function is a **one-shot** cue behind an `oneshot` flag — three instructions' worth of a
   741-byte function.
2. **It posts through the combat damage path.** `FUN_00407B20` → `FUN_00406170`, the identical pair
   used by the weapon and explosion code, with the identical `&DAT_011766F0` context. Fire is not a
   parallel mechanism; it is another producer on the combat damage bus — and it is **three**
   producers, not two: the `RtTickDamage` burn timer posts through the *same* pair (§3), which an
   earlier revision recorded as a separate `thunk_FUN_024B9B50`.
3. **`Fire` is a column of the combat damage matrix**, which is stronger than "fire is a
   `DamageKey`". `pandemic_hash_m2("Fire") == 0x8A552089` is the column key into the same
   `ModifierKey` × `DamageKey` matrix that `ExplosionLarge` and `MeleeBash` index, resolved by
   byte-identical code at every site (§2.5). The designers did not merely file fire in the
   damage-type table — they gave it a full row of per-target multipliers beside explosions and
   melee. That is an authorial statement of ownership.
4. **Both applications are health applications.** Primary health *and* per-node health — the exact
   pair (`RuntimeHealth` / `RuntimeNodeHealth`) that the destruction pipeline consumes.
5. **Burning-over-time is `TickDamage`**, which Xbox files under **weapons-combat**
   (`weapons-combat.md` §Damage, `TickDamage @0x829f1e90` beside `ApplyDamage*`), not under rendering.
6. **The components live in the combat registry.** `Ignitor`/`RuntimeIgnitor` are already documented
   in `docs/mercs2-ecs/01_combat_weapons_projectiles.md`, and `weapons_combat_code_map.md` already
   carries their descriptors. Silo 10 has been half-owning this for two maps already.
7. **The FX side is a downstream consumer with a clean seam.** `ObjectState.StartEmitter` →
   `FUN_004D28C0` → EffectTemplate + hardpoint + PgFX is a *one-way* call. Nothing in PgFX reads fire
   state; nothing in fire reads PgFX state. That is a silo boundary, not a shared subsystem.
8. **The one thing that *is* pure FX is already silo 3's**, correctly: `global_particle_fire_*`
   templates, the `ChunkTrailEnum` fire trails, and the emitter runtime all sit inside
   `particle_fx_code_map.md`'s scope and should stay there.
9. **`Flammable` — a gameplay component, not an FX one — is read inside the ignition filter**
   (§2.4/§7.1) and gates buildings specifically. This line did not exist when the recommendation was
   first written, because the reader was believed absent; recovering it only pushes in the same
   direction.

**Concretely:** silo 10 owns `Ignitor`, `RuntimeIgnitor`, `UpdateIgnitor`, the falloff/DamageKey math,
`Flammable`, `TickDamage`/`RtTickDamage`, and the `Fire` damage key. Silo 3 owns the effect templates
and the emitter runtime, and exposes exactly one entry point — `start_emitter(guid, hardpoint,
effect)` — which silo 10, the destruction machine, and Lua all call. Silo 3 should **not** be asked to
model burning; silo 10 should **not** be asked to model particles.

**The one dependency to flag:** `Graphics.FuelTrail` (§1) is nominally silo 3's table by nesting, and
it is dead. Whichever silo takes it, the correct implementation is three faithful no-ops installed at
`Graphics.FuelTrail`, not a `Fire` global with real bodies.

---

## 11. Provenance

- **PC decomp** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (base `0x00400000`). Bodies read
  first-hand this pass: `FUN_004B82D0`, `FUN_004B7B50`, `FUN_004B7BB0`, `FUN_0066E650`, `FUN_00675E50`
  (the `RuntimeIgnitor` and `RtTickDamage` loops), `FUN_004D28C0`, `FUN_004F4340`, `FUN_00683C40`,
  `FUN_00683530`, `FUN_0067F870`, `FUN_0066F300` (the `Ignitor`/`DebrisEffect` handler mints),
  `FUN_00643070`/`FUN_00643120`/`FUN_00642EF0`/`FUN_00646AA0`/`FUN_00645650` (registrars),
  `FUN_00662720`/`FUN_006627A0`/`FUN_00661CB0`/`FUN_006625E0` (schemas), `FUN_005D2AE0`–`FUN_005D3180`
  (the `ObjectState` cfuncs), `FUN_00505420`, `FUN_004B2600`/`FUN_004B2690` (message ring),
  `FUN_00407B20`.
- **Raw disassembly** (capstone, over `output/_ghidra/securom_dump/mercs2_unpacked.exe` — a **live
  memory dump**, so slots are resolved and the descriptor tables are populated) where Ghidra had no
  body or an unusable one: `0x005B2A50` (`FuelTrail.Put`), `0x006D5640` (the stub — see §1's
  provenance caveat), `0x005D2FA0` (`StartEmitter`), `0x004B7BB0`–`0x004B82C2` (the applier, in
  full), `0x004B82D0`, `0x004B7B50`–`0x004B7BA6` (the filter **and both its jump tables**),
  `0x0066E650`, `0x006768C0`–`0x00676959` (the tick), `0x00693D80`, `0x00683C40`,
  `0x00670F70`–`0x00671060`, `0x004D4680`, `0x00406170`, `0x00632360`, `0x00688970`,
  `0x006627A0`/`0x00662720`/`0x00661CB0`/`0x006625E0` (the schemas, read for their `edx` operands),
  `0x00643070`/`0x00643120`/`0x00645650` (the registrars).
- **Deref'd out of SecuROM** (resolved slot → relocated plaintext): `FUN_00632360` →
  `[0x0245DE08] = 0x02FB0000` (the damage matrix, §2.5) and `FUN_00406170` →
  `[0x0244FEA8] = 0x024B9B50` (the damage post, §3). **Not** recoverable this way and confirmed
  virtualized: `FUN_004D4680` → `0x02A30000`, the VM interpreter (§4.4).
- **The two master keys** (Method block), applied over the descriptor tables `0x00EDBEC8` (218) and
  `0x00EDBAC8` (116): all **334** containers named, which is what corrected `0x00DF9110`
  (`RuntimePhysicalLink`), `0x00DF9310` (`RuntimeModelState`), `0x00DF8B10` (`OSMParameter`),
  `0x00DF8710` (`ParticleKey`) and identified `0x00DF8690` (`ModifierKey`) and `0x00DF7A88`
  (`AnimationResponse`).
- **Registrar census**: all **334** call sites of the shared tail `FUN_0064A770`, walked back to
  each `or eax, 0xffffffff` prologue — **232 parsed, all `mov ecx, 0x100`, zero exceptions** — then
  joined against `docs/game_config/cdbsizes.ini` `[presize]` via the live descriptors' `+0x0C` /
  `+0x26` / `+0x28`, which is what established that the INI resizes the default at boot (§2.1).
- **Shipped data**: `cargo run -p mercs2_probe --bin block_content_grep -- <needle>` over
  `vz.wad` (11 370 blocks, `ok=11370 failed=0`) for §1 and §7.5;
  `cargo run -p mercs2_workshop -- --states 0xAC990539` for the destruction vocabulary and the
  `DanglingState` crack (§6.1). Both need
  `MERCS2_VZ_WAD=<install>/data/vz.wad` (or the EA Games registry key).
- **Binding tables**: fresh `.rdata` walk of the `Graphics` compound blob `0x00B9A4D0`–`0x00B9A7C8`
  and of `ObjectState` `0x00B995B0`; namespace registry `0x00DFD478` (31 rows). Cross-checked against
  `mods/lua_trace_asi/reference/binding_map.json` ([[lua-trace-asi-surface-b-oracle]]) and
  [`../lua_engine_bindings_audit_deep_dive.md`](../lua_engine_bindings_audit_deep_dive.md).
- **Xbox oracle**: `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` (`UpdateIgnitor`,
  `FuelTrail`, `ApplyDamageToNodeHealth`, `ApplyDamageToPrimaryHealth`),
  `inventory/_uncategorized.txt` (`UpdateIgnitor @0x0041234`, `RuntimeIgnitor @0x00319bc`),
  ⚠ **but not** for the `Flammable 256` / `Ignitor 96 32` / `RuntimeIgnitor 8 8` /
  `RtTickDamage 16 16` lines, which earlier revisions attributed to the Xbox dump. Those are the
  `[presize]` section of the **PC retail** embedded config at `.rdata 0x00BAD498` (§2.1) and appear
  in both images identically,
  [`../mercs2-pdb-analysis/weapons-combat.md`](../mercs2-pdb-analysis/weapons-combat.md),
  [`../mercs2-pdb-analysis/rendering-shaders.md`](../mercs2-pdb-analysis/rendering-shaders.md).
- **Hashes**: `tools/pandemic_hash.py --m2` + `tools/rainbow_table.json` (739 446 entries — note it
  is a random-string table, so a real class name such as `DanglingState` is *not* in it; it only
  ever rules a candidate space out). Brute passes described in §6.2 were run over the retail image's
  strings, the devkit dump's tokens, `vz.wad` block 3185 and the `docs/` tree; the scripts used are
  throwaway and not committed. Every name asserted in this document recomputes with
  `python tools/pandemic_hash.py --m2 <name>`.
- **Script traffic**: measured directly over `docs/mercs2-luacd/` (370 `.lua` files). `FuelTrail`
  0/0/0; `ObjectState.StartEmitter` 20 references (10 calls + 10 deferred), `ObjectState.StopEmitter`
  10 calls. The `corpus_calls` figures carried in `mercs2_script/src/bindings/*.rs` are a
  hand-maintained `Required` struct field, **not** the output of a tool of that name — `fire.rs`'s
  0/0/0 is right, `object_state.rs`'s 14/14 for the emitters is not (§9).
- **Cited, not re-derived**: [`particle_fx_code_map.md`](particle_fx_code_map.md),
  [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md),
  [`weapons_combat_code_map.md`](weapons_combat_code_map.md),
  [`../destruction_orchestrator_format.md`](../destruction_orchestrator_format.md),
  [`../modernization/vehicle_model_spec.md`](../modernization/vehicle_model_spec.md) §5,
  [`../mercs2-ecs/01_combat_weapons_projectiles.md`](../mercs2-ecs/01_combat_weapons_projectiles.md),
  [`../mercs2-ecs/05_presentation_audio_fx.md`](../mercs2-ecs/05_presentation_audio_fx.md),
  [`diagnostics_code_map.md`](diagnostics_code_map.md) (the `0x006D5640` stub).
- Confidence stated per row. The documented gaps are now: **`FUN_004D4680`'s body** (SecuROM VM,
  §4.4), **the runtime attach point for `Ignitor`/`TickDamage`** (§7.5 — nothing authors them), **the
  live values of the damage-matrix axes** (§2.5), **entity kinds 5/7/9/11/12/13** (§2.4), and **nine
  uncracked hashes plus three field names** (§6.2). `Flammable`'s reader and the name behind
  `0x381BE6A4` were on this list for two revisions and are now closed — see §7.1 and §6.1
  respectively for what the old text said and why it was wrong.
