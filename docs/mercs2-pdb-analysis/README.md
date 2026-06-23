# Mercenaries 2 — Engine Symbol Analysis (from the recovered Xbox 360 binary)

A categorized, evidence-grounded map of the Mercenaries 2 engine, reconstructed from the
**symbol/string evidence inside the recovered Xbox 360 executable** — *not* from a real `.pdb`.

## What this is (and isn't)

The game executable `Mercs2_Xenon_P.exe` (Jul 11 2008 preview disc, a devkit **Profile** build,
PowerPC) was decrypted + LZX-decompressed back to a full 32 MB PE
(see [../reverse_engineer/jul08_prototype_iso.md](../reverse_engineer/jul08_prototype_iso.md)).
Because it is a Profile build it retained a large amount of debug evidence **as string bytes**:
- **324 RTTI C++ class names** (Havok was compiled with RTTI on),
- thousands of **assert / debug / format strings**, often embedding `Class::Method` and source paths,
- **48 source-file build paths** (`d:\projects\ReleaseLine\Mercs2\…`).

That is a **symbol-name map scraped from the binary**, not the symbol table itself. The real
`Mercs2_Xenon_P.pdb` (GUID `5313ddba-1da8-914c-a6f8-75cc9483d5a7`) lived only on the build
machine. So these docs can confidently state **what classes/systems exist and what they're
called**, but anything about **behavior, function signatures, or struct layout is inference** and
is explicitly marked `(inferred)`.

## Provenance & evidence base

| | |
|---|---|
| Binary | `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` (PE32, machine 0x01F2 PowerPC, 13 sections, 32,374,784 B) |
| Engine | Pandemic Studios in-house engine **"Pangea"** (`Pg*` classes); physics = **Havok** (`hk*`/`hkp*`); audio = **Pal** (Pandemic Audio Library); jobs = **Pimp** |
| Inventory | `output/jul08_prototype/inventory/<system>.txt` — 3,480 symbols, each anchored to its PE offset + section |
| Raw evidence | `mercs2_xenon_p.pe_full_strings.txt` (57,161 strings), `.rtti_classes.txt` (324), `.source_paths.txt` (48), `.block0_strings.txt` (richest debug region), `shaders_bin_updb_paths.txt` (344 shader debug-DB names) |

## How these docs were produced (methodology)

1. **Inventory** — every symbol-like string was extracted with its PE offset + section and
   bucketed into 16 systems by namespace/keyword rules (`tools/` inline scripts).
2. **Document** — one agent per system wrote its doc, required to ground every cited symbol by
   grepping the evidence first.
3. **Adversarially verify** — a *separate* agent independently re-grepped the binary for every
   symbol/class/path/offset and flagged any hallucination or unlabeled speculation.
4. **Revise** — flagged items were corrected or removed.

Result: **16/16 systems, all "thorough" coverage** (9 clean on first pass, 7 revised after the
verifier caught issues). An independent post-hoc spot-check of 2,424 cited symbols found only
generic placeholders (`Class::Method`) and properly-labeled inferences outstanding — no surviving
fabricated symbols.

## The 16 systems

| Doc | System | Symbols | Notes |
|---|---|--:|---|
| [havok-physics.md](havok-physics.md) | Havok physics middleware (`hk*`/`hkp*`) | 917 | dynamics, collision, constraints, ragdoll, serialization (`hkXmlParser`, packfile) |
| [pangea-engine-core.md](pangea-engine-core.md) | Pangea engine core (`Pg*`/`Mrx*` foundation) | 563 | object/entity system, managers, memory, containers, math |
| [rendering-shaders.md](rendering-shaders.md) | Rendering & shaders | 472 | materials, textures, lighting, shadows, post-process; 344 `.updb` shader DBs |
| [world-streaming.md](world-streaming.md) | World/terrain streaming & content | 331 | terrain, WAD load, placement, spawn, props/destructibles, water, hibernation |
| [vehicles.md](vehicles.md) | Vehicle simulation (`Tt*` actions) | 288 | car/bike/heli/tank/boat; engine/gear/steer/spring/wheel tuning fields |
| [animation-skeleton.md](animation-skeleton.md) | Animation & skeleton | 222 | bones, poses, ragdoll blend, keyframes, IK |
| [game-systems.md](game-systems.md) | Gameplay meta-systems | 160 | achievements, stats, economy, rewards, missions/contracts, save/profile, factions |
| [audio-pal.md](audio-pal.md) | Audio (Pandemic Audio Library) | 126 | sound events, ambient, music, voice, wavebanks, Bink |
| [weapons-combat.md](weapons-combat.md) | Weapons & combat | 76 | weapons, ammo, projectiles, homing, damage, explosions |
| [gui-hud.md](gui-hud.md) | GUI / HUD | 74 | menus, screens, Scaleform/gfx, minimap, PDA, markers/blips |
| [networking.md](networking.md) | Networking / multiplayer | 60 | sessions, client/server/host, replication, RPC |
| [lua-scripting.md](lua-scripting.md) | Lua 5.1.2 VM + bindings | 58 | VM C source (asserts w/ line numbers); see note below |
| [ai.md](ai.md) | AI | 43 | behavior, patrol, squad, cover, aim, threat, navigation |
| [physics-game.md](physics-game.md) | Game↔Havok physics integration | 42 | `PgPhysics*`, human/ragdoll, raycasts, grappling, fluid droplets |
| [camera.md](camera.md) | Camera system | 24 | cameras, cinematic, FOV, viewport |
| [jobs-threading.md](jobs-threading.md) | Job/threading system (Pimp) | 9 | workers, fibers, queues (`d:\mainline\mercs2\pimp\`) |

> **Note on `lua-scripting.md`:** the binary confirms Lua **5.1.2** is compiled in (source paths
> `ldo.c`/`lstate.c`/`lgc.c`… with assert line numbers + runtime error strings). Function-level
> detail (`luaD_call`, `luaF_newproto`, …) is **inferred from that confirmed module identity**
> against the public Lua 5.1.2 source, and is labeled as such — it is not claimed to be in the
> binary as symbols. Pairs with the decompiled Lua corpora in
> [../mercs2-luacd/](../mercs2-luacd/) and [../mercs2-dlc-luacd/](../mercs2-dlc-luacd/).

## Supplementary deep-dives

Beyond the 16 per-system docs, three docs analyse the exe at the binary level, and six more
cover the rest of the disc (indexed in [../reverse_engineer/jul08_prototype_iso.md](../reverse_engineer/jul08_prototype_iso.md)):

- [data-defaults.md](data-defaults.md) — the 19 MB `.data` section's reflection default/config tables (the actual *values* behind the tuning-param names).
- [imports-exports.md](imports-exports.md) — XDK/kernel API surface (incl. `xbdm.xex` debug monitor, `XHV` voice, `XONLINE`); feature set.
- [pdata-functions.md](pdata-functions.md) — `.pdata` unwind table → complete function inventory (~39,000 functions in `.text`).

## Conventions

- Cited symbols are **copy-exact** from the evidence files; offsets are PE offsets from the inventory.
- **Facts** = "this symbol/string exists in the binary." **Inferences** = behavior/architecture,
  always marked `(inferred)`.
- "Class names" are demangled RTTI (`​.?AVFoo@@` → `class Foo`); they give names only — no methods,
  fields, or layout (that would need the actual `.pdb`).

## Paired with the PC decompilation (done)

These docs say *what exists and what it's called*; the PC retail Ghidra decompilation
(`output/_ghidra/all_functions_decomp.txt`, ~25k function bodies) has the *logic* but anonymous
`FUN_` names. We bridged them (`tools/pair_xbox_pc.py`), and every system doc now has a
**"PC decompilation cross-reference"** section mapping its symbols to real PC functions:

- **Vtable bridge (high confidence):** Ghidra labels recovered RTTI vtables `Class::vftable`, so a
  function assigning one is that class's constructor. **204 of 287 Xbox RTTI classes resolved to PC
  constructors** — consolidated in [symbol-map.md](symbol-map.md) (machine-readable
  `output/jul08_prototype/pairing/symbol_map.json`).
- **String bridge (medium):** shared debug/format strings → the PC functions referencing them.
  **877 string-anchored resolutions** across systems (densest: `pangea-engine-core` 422,
  `world-streaming` 97, `rendering-shaders` 95, `vehicles` 88). Worked example: `FUN_0042ce90` =
  the human-movement state machine (via shared `StInitialCast`/`StCastMove` strings); the shader
  registry/loader is `FUN_0084f130` (it references every shader-name string).

Every cited `FUN_` address was verified to exist in the decomp and to actually reference the
claimed symbol/vtable (adversarial verify pass). Coverage is partial by nature — PC retail is a
*release* build that stripped many of the debug strings the Xbox *Profile* build kept.

Resolver outputs: `output/jul08_prototype/pairing/` (`vtable_map.json`, `string_func_map.json`,
`resolved_<system>.txt`, `summary.json`).
