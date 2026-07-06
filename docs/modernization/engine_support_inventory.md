# mercs2_engine vs base game — support inventory

**Purpose.** One table of record: what `tools/wad_simulator/crates/mercs2_engine` (plus its spine
crates `mercs2_core`, `mercs2_script`) actually implements today, against what the shipped game's
Pangea engine supports as documented in `docs/mercs2-pdb-analysis/` (20 system docs),
`docs/mercs2-ecs/` (231-class component registry), and `docs/mercs2-luacd/` (370-script Lua corpus
and the engine-binding surface it consumes).

**Compiled 2026-07-04** from a full read of all 12 `mercs2_engine` sources + the three doc corpora.
Sibling docs this consolidates (does not replace):
- [`pangea_engine_alignment.md`](pangea_engine_alignment.md) — subsystem→crate mapping + evidence discipline (its guard rails apply here too)
- [`rendering_fx_lighting_gap.md`](rendering_fx_lighting_gap.md) — the *detailed* rendering/FX/lighting checklist; this doc only summarizes it
- [`world_streaming_spec.md`](world_streaming_spec.md) — authoritative streaming spec

Status legend: ✅ **BUILT** (works on retail data) · 🟡 **PARTIAL** (exists, limited — the note says how) ·
⭕ **STUB** (placeholder/no-op) · ❌ **ABSENT** (no code at all).

---

## 1. Scoreboard

| # | Subsystem | Base game (per docs) | Our engine | Status |
|---|-----------|----------------------|------------|--------|
| 1 | Render core (geometry, materials, textures) | Multi-pass PgScene, multi-sub-material models, texture streaming w/ mip swap | Forward pass, per-PRMT multi-material, BC1/BC3 + hi-mip streaming, baked vertex lighting | ✅ core / 🟡 overall |
| 2 | Lighting | Placed `LightObject` point/spot + `_pl`/`_sl` shader permutations, sun/day-night, `LightAnimation` | 32 forward point lights from `LightObject` + fixed sun + Blinn-Phong spec (`_sm` slot 1) | 🟡 |
| 3 | Shadows | `ShadowBuffer` depth maps + per-mesh-type shadow VPs + `BlobShadow` · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | none | ❌ |
| 4 | Particles / FX | PgFX job-parallel, `fxdict` 630 effect params, EFCT/EMTR templates, ECS spawners, ribbons · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | CPU billboard sim + COLR gradients + glow cards; templates must be fed by game code (no fxdict auto-map) | 🟡 |
| 5 | Sky / post / HDR | PgSky/PgSun/PgCloud, adaptive-luminance tone-map, bloom, motion blur, rain/underwater · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | Scattering-gradient sky + HDR → bright-pass/blur → ACES/Reinhard + bloom; exposure approximated | 🟡 |
| 6 | Decals | Projected decals as parallel job, "super decal" · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | none | ❌ |
| 7 | Water | `PgWater*` heightmap/wake/reflection shaders + buoyancy · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | none (scoped separately — see `water-and-swimming-scope`) | ❌ |
| 8 | World streaming | StreamingManager pre/post-load, per-object hibernation, 2-tier terrain LOD, overlays | Decision core (proximity, budgets, hysteresis, per-entity distances) + GPU unload + terrain LOD swap + vz_state overlays | ✅ |
| 9 | Load areas / region cache | `PgSysPopulation` CacheIn/Out/Required region cache (distinct from hibernation) | per-object hibernation only | ❌ |
| 10 | Prop LOD / imposters | MESH/TINY imposters, `RtGenericLOD` | 4-tier LOD computed but informational (retail props ship ~no alt meshes); terrain swap is real | 🟡 |
| 11 | Assets / formats | WAD/UCFX, MTRL, Havok packfiles, wavelet/delta/spline anim | WAD/ASET/container extraction, mesh de-strip + POFF + SEGM state-mask, MTRL, wavelet decode (168/168 tests) | ✅ |
| 12 | ECS / reflection registry (Keystone A) | 232 stream-deserialized component classes, `0x9e3779b9` seed, cdbsizes pools | hecs world + descriptor table w/ cdbsizes budgets; **field-schema deserialization not implemented**; 4 native hot-path components vs 231 documented classes | 🟡 |
| 13 | Event/RPC bus (Keystone B) | name-hash + typed-TLV (≤7 args), shared GUI/Net/AI/audio; wire router unrecovered on Xbox · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | in-memory pub/sub, hash + ≤7 typed args, 2048 deferred cap | ✅ (in-memory; wire N/A) |
| 14 | Scheduler / tick (Keystone C) | `PgSys*` 32-slot registry + framerate policies; master tick order was unknown even in exe · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | fixed-timestep `Schedule` + `run_fixed`; **not used by the streaming loop** (own dt loop) | 🟡 |
| 15 | Jobs / threading (Pimp) | worker pool, lock-free a64 queue, per-CPU timers, Havok MT glue · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | none (candidate: rayon) | ❌ |
| 16 | Scripting host | Lua 5.1.2 VM, `Sys.*` table, import/inherit module system, console/debugger | Lua 5.4 (mlua) + compat prelude + import/dynamic_import/inherit + EngineHost seam + auto-stub tracer | ✅ host |
| 17 | Script binding surface | ~53 namespaces / ~1216 fns (Surface-B trace); see §3 | boot/PMC-spawn slice: `Debug`, partial `Sys`/`Pg`/`Object`, fake `Event.Create`; `Ai`/`Vehicle` no-ops | 🟡 (thin slice) |
| 18 | Input | XDK module-level only (no per-fn list recoverable) | data-driven 25-action set from `Mercs2.ini`, KB/mouse + gilrs gamepads, analog; streaming loop still uses its own hardcoded free-fly keys | ✅ |
| 19 | Camera | `PgSysCamera`: per-vehicle modes, shake, FOV set, collision cast, ≤5 viewports, cinematic | free-fly + auto-orbit + `set_view` injection seam (3P cam lives in game crate) | 🟡 |
| 20 | Animation | Havok hka/hkb: MT sampling w/ CPU budget, bone controllers, IK, ragdoll blend, FaceFX, GPU skin | wavelet/Havok clip decode + faithful `hkQsTransform` compose + GPU 4-influence LBS + nlerp crossfade (fn exists, loop plays single clip) + data-driven clip index + root-motion strip | 🟡 (sampling/skinning ✅; controllers/IK/ragdoll/FaceFX ❌) |
| 21 | Audio (Pal) | voices w/ priority steal, 16-state instance FSM, ducking, dynamic faction/action music, banks, 3D · **[PC code map ↓](#1a-pc-reverse-engineering-code-maps)** | none (but fully mapped: DirectSound8 + EAX backend, software mixer thread, dual-deck music FSM, sounddb/banks, 88-fn Lua surface) | ❌ (impl) / ✅ (mapped) |
| 22 | Physics | Havok 5.5 world/MOPP/constraints/character proxy + `PgPhysicsActor*` bridge family, grapple, winch | terrain heightmap `height_at` sampling only; no rigid bodies/character/casts | ❌ (sim) |
| 23 | AI | percept→context→goal planner (~30 verbs), cover FSM, squads, pedestrians, AI driving; pathfinding algorithm unrecovered | none (`Ai.Enable` no-op) | ❌ |
| 24 | Population / spawners | `PgSysPopulation`: faction spawn lists, traffic/window/path/hardpoint spawners, cache-in/out | none (streaming wakes pre-placed entities only) | ❌ |
| 25 | Vehicles | per-class drive models on Havok Vehicle SDK, command rings, turrets, huge tuning surface (math undecoded) | none (`Vehicle.EnableTurret` no-op) | ❌ |
| 26 | Weapons / combat | data-driven `Weapon*` ECS family, projectile lifecycle, homing FSM, damage/explosion taxonomy (solver undecoded) | none | ❌ |
| 27 | GUI / HUD | Scaleform GFx + `_GuiInternal` widget backend + per-player `Gui*Update` events, PDA, minimap · **[Scaleform code map ↓](#1a-pc-reverse-engineering-code-maps)** | loading screen (shell.wad plate + spinner) + 2D UI pass (`ui.rs`/`ui.wgsl`: instanced quads + 8x8 bitmap-font text over the shell pass) + GAME shell menu (`mercs2_game::menu`: main menu w/ retail option set `autoContinue`/`newGame`/load/`quitGame` + save browser over `SaveGames\*.profile`, boots the picked save; KB + gamepad nav) | 🟡 (shell menu ✅ native; Scaleform/HUD/PDA ❌) |
| 28 | Networking | Keystone-B replication (`NetSubCat*`/`NetSafe*`/`NetClient*`), join-time module pull, LIVE/XLSP | none in-engine (online-restore mod is a separate exe patch) | ❌ |
| 29 | Save / serialize | versioned save w/ hash + corruption handling; `SetLuaSaveVersion` | read-side only: `.profile` header + SaveState parse (`mercs2_formats::save`) drives boot + the shell save browser; no write/versioning | 🟡 (read ✅ / write ❌) |
| 30 | Entity state machines | `PgModelStateMachine` + ECS STAT/SWIT destruction graph (`CollapseState`) | DATA LAYER DONE (2026-07-05, `docs/destruction_orchestrator_format.md`): `orchestrator::parse_state_machine` parses the engine's named-state machine (recovered from `FUN_004cf340`); `decode_script` reads the Enter/Exit command scripts (SHOW/Hide/SetState/SetStateOnMsg/StartEmitter/StopEmitter/CreateObject/KillObjectsLinkedToHP/DisableConstraint/SetRootNode/StartAnim/SetNodePhysicsModelKeyframed); `machine_group_visibility` EXECUTES SHOW/Hide → per-group visibility (workshop-proven, interactive). Missing: ECS component + tick system, message routing (SetStateOnMsg ← damage events), CreateObject/emitter/physics command execution | 🟡 (formats ✅ / runtime ❌) |
| 31 | Destruction | `BuildingDestruction`/`DestructionLink`, pristine/ruined vz_state, debris | SEGM state-mask tier selection + #30's default-visibility execution (per-node init states → SHOW/Hide). NOTE: the ENGINE world path still renders ALL SWIT subtrees — spawned vehicles show floating break pieces in-game; first wiring step = apply `machine_group_visibility` defaults wherever `build_indexed_*` models reach `Scene::load_model` (prop wake + game loaders), then the runtime graph (damage msgs → SetStateOnMsg transitions → StartEmitter via the existing particle system, CreateObject debris) | 🟡 |
| 32 | Diagnostics | ~250-item debug menu, profiler zones, per-system dumps | 24 headless diag fns (anim gates, stream probe, placement/hash hunting) + 2 env flags | ✅ (different shape, serves the RE workflow) |

**One-line read:** the engine is a faithful streaming world *renderer* with a real
ECS/streaming/scripting spine (rows 1–20 mostly green/yellow) and **no gameplay simulation layer**
(rows 21–30 red). That matches the charter's current phase; the red rows are the Phase-3+ surface.

---

## 1a. PC reverse-engineering code maps

Deep function-level maps of the shipped **PC** engine (from the unpacked SecuROM image
`output/_ghidra/securom_dump/mercs2_unpacked.exe`), one per subsystem. Each binds the Xbox-PDB
symbol names to concrete PC addresses and records what stays vtable/SecuROM-gated as explicit
`confirm-live` (x32dbg) items. These are the RE reference for a faithful reimpl; they do **not**
change the "Our engine" status above (which tracks what `mercs2_engine` implements).

| Row | Subsystem | Code map | Machine-readable | What it recovered |
|---|---|---|---|---|
| 3 | Shadows | [`shadow_code_map.md`](../reverse_engineer/shadow_code_map.md) | [`particle_fx_shadow_code_map.json`](../data/particle_fx_shadow_code_map.json) | Shadow-map RT creator `FUN_00755d90` (4-tile 1024² atlas), per-mesh-type shadow-VP selection, caster collection + distance-LOD gate, `BlobShadow` fallback, `EnableShadows` cvar chain |
| 4 | Particles / FX | [`particle_fx_code_map.md`](../reverse_engineer/particle_fx_code_map.md) | [`particle_fx_shadow_code_map.json`](../data/particle_fx_shadow_code_map.json) | ECS FX component family + reflection registrars, `fxdict`/effect-template loaders (`FUN_00491320`/`FUN_00492af0`, chunk→offset map, the `0x493102` crash field), shader registry, Ribbon runtime; runtime emit/`Render3DParticles` vtable-gated |
| 5 | Sky / post / HDR | [`sky_post_hdr_code_map.md`](../reverse_engineer/sky_post_hdr_code_map.md) | [`sky_decal_water_code_map.json`](../data/sky_decal_water_code_map.json) | Atmosphere struct + exact scatter offsets, full `Graphics.Atmosphere.*` setter→C table (`@0xb9a570`), cloud RTs (`FUN_0047d710`, R32F `mCloudOutRT`), 7-stage HDR post driver `FUN_0074f8d0` + adaptive-exposure loop; **motion-blur/velocity ABSENT on PC** |
| 6 | Decals | [`decal_code_map.md`](../reverse_engineer/decal_code_map.md) | [`sky_decal_water_code_map.json`](../data/sky_decal_water_code_map.json) | `decaltable` ASET loader (`FUN_004cb1b0`/`FUN_004cb1f0`, type `0x3B0AABF8` → `PgDecalTable`), decal shader register, `DisableDecals`/`Disable3DDecals` components; create/`DecalJob`/`DamageShadow` strings stripped → confirm-live |
| 7 | Water | [`water_code_map.md`](../reverse_engineer/water_code_map.md) | [`sky_decal_water_code_map.json`](../data/sky_decal_water_code_map.json) | Shader sub-loader `FUN_00484380` (R2VB/NVT/plain tiers), pass driver `FUN_00466d40` (wake → occlusion → reflection mirror-matrix `FUN_004677d0` → surface), ping-pong sim RTs, waterline query `FUN_00480440`, `Buoyancy` comp `0xb9659f7b` |
| 13 | Event/RPC bus | [`event_bus_code_map.md`](../reverse_engineer/event_bus_code_map.md) | [`keystone_code_map.json`](../data/keystone_code_map.json) | Subscriber registry + dispatch recovered on PC (18-bucket per-category hash, 11-tick deferred-delete GC, `(bucket<<16)\|id16` handles, registry `DAT_00edaf88`) + Lua `Event.*` path; local-vs-wire branch stays SecuROM-virtualized → confirm-live |
| 14 | Scheduler / tick | [`scheduler_tick_code_map.md`](../reverse_engineer/scheduler_tick_code_map.md) | [`keystone_code_map.json`](../data/keystone_code_map.json) | Master tick recovered: RunFrame `FUN_00630ef0` 9-stage order → `FUN_004c14f0`→`FUN_004c15e0` 5-layer stack ticked 0→4; QPC decoupled fixed-sim + variable-render; corrected the Xbox "update-fn list" to per-object |
| 15 | Jobs / threading (Pimp) | [`pimp_job_system_code_map.md`](../reverse_engineer/pimp_job_system_code_map.md) | [`keystone_code_map.json`](../data/keystone_code_map.json) | Per-CPU worker `FUN_00876400`, 96-B Jobtype+fence+params jobs, **a64 lock-free queue degraded to CRITICAL_SECTION-guarded ring on x86**, `pimpGetNumCpus FUN_008767b0`; profiler-zone timer tree strings stripped → confirm-live |
| 21 | Audio (Pal + Pangea) | [`audio_code_map.md`](../reverse_engineer/audio_code_map.md) | [`audio_code_map.json`](../data/audio_code_map.json) | Full stack: 24 self-named Pal anchors, **DirectSound8 + EAX2–5 backend `FUN_00831b10` (Xbox `*Xenon`→PC `*DX8`)**, software mixer thread `FUN_00831ee0` (45 ms), dual-deck music FSM `FUN_0082d7a0`, sounddb parser `FUN_00835b80` (`'\x1d'` tag cross-verified vs Xbox), 14-slot msg bus `FUN_005fda10`, 3 tick call sites in `FUN_004c9740`, full 88-fn `Sound.*`/11-fn `VO.*` Lua tables; SecuROM-thunked cue-dispatch/stream-open → confirm-live |
| 27 | GUI / HUD (Scaleform) | [`scaleform_gfx_class_map.md`](../reverse_engineer/scaleform_gfx_class_map.md) | [`scaleform_gfx_function_map.json`](../data/scaleform_gfx_function_map.json) | Scaleform GFx **2.0.48** (Flash 8/AS2); 2,596-function lib map (`0x75F000–0x812000`) + engine PgScaleform HAL + FlashWidget bridge; SecuROM trampolines resolved; all 83 `.gfx` movies extracted to `output/gfx_movies/` |

**Common method + caveats** (shared by all nine): the retail PC build strips most profiler-marker
symbol strings and dispatches per-frame render/tick through vtables, so *setup* code (shader/RT/
reflection registration, format parsers, Lua setters, cvars) is high/med confidence while the
*per-frame draw/dispatch* is often recorded as a vtable addr + slot and flagged confirm-live rather
than guessed — the same honesty model as the SecuROM gaps. Reconciliation note: `FUN_00466d40` is
mapped as both `Water::Render` (#7) and the shadow caster-collection driver (#3) — it is most likely
a shared per-viewport scene-pass driver both render-actions route through.

---

## 2. The gameplay-simulation gap, quantified

What "❌ gameplay layer" means concretely, from the doc corpora:

- **ECS coverage:** 4 native components (`Transform`, `ModelRef`, `AnimState`, `SkinPalette`) vs
  **231 registry classes** documented in `docs/mercs2-ecs/` (34 combat, 25 AI, 31 controllers/physics,
  23 player/vehicle, 34 presentation/audio/FX, 30 world/roads, 35 gameplay/health/mission, 7 misc,
  12 render-pipeline). The registry mechanism exists (descriptors + pool budgets) but cannot yet
  deserialize field schemas, so none of the 231 stream in.
- **Minimal-playable ECS core** (per the ecs survey): `SceneObject`+`Model`, `Health`/`RuntimeHealth`,
  `ObjectScript`+`StateMachine`, `WeaponProjectileBase`, `ControllerPlayer`+`PhysicsActor`,
  `Equipment`, `FactionMarker`, `Perception`/`AiSkill`/`AiBehavior`, regions + `RuntimeLayerId`.
- **Lua binding coverage:** the corpus depends on ~20 engine namespaces (§3); we implement real
  bodies in 4 (`Debug`, parts of `Sys`, `Pg`, `Object`) plus a fake `Event.Create`. Everything the
  game Lua does — missions, economy, HUD, AI orders, audio, support drops — blocks on the rest.
- **The load-gate seam:** `Sys.RequestGameState("WaitForStreaming"/"WaitForTether")` +
  `Event.GameStateChange` + `MrxLayerManager.Add` is how game Lua drives world-load (the exact
  markers loadprobe scores). Our streaming runtime can satisfy this — the binding glue is what's
  missing.

---

## 3. Lua → engine binding surface (what game scripts require vs what we provide)

Consolidated from `docs/mercs2-luacd/` (all 8 docs; DLC adds no new namespaces). ✅ = real body in
`mercs2_script::register_engine`, ⭕ = no-op stub installed, ❌ = nothing (auto-stub layer logs it).

| Namespace | Game usage (top functions) | Ours |
|---|---|---|
| `Debug` | Printf/Print | ✅ |
| `Sys` | **RequestGameState**, RequestAutosave, GetLevelName, StartWithResources, GuidToString, SetAssetRequestMax | 🟡 GetLevelName/GetMasterScriptName/StartWithResources only |
| `Pg` | GetGuidByName, Spawn, FastCollect\*, Load/UnloadAsset, SaveGame/LoadGame, Contract\*, AddContextAction | 🟡 GetGuidByName/Spawn only |
| `Object` | GetHealth, IsAlive, Get/SetPosition/Yaw, HasLabel, Kill, FadeOut, ApplyImpulse, SetInfiniteAmmo, SetHibernationDistance, OpenGate | 🟡 SetName/SetPosition/SetYaw/GetPosition/GetYaw real; Attach/DisablePhysics ⭕ |
| `Event` | Create/CreatePersistent/Delete/Post + ~18 event types (GameStateChange, ObjectProximity/Death/InSeat, Boundary, Timer…) | ⭕ constants + handle counter, **no event loop** |
| `Ai` | Goal, Role, Deploy, Set/GetRelation, SetPriorityTarget, LivingWorld | ⭕ Enable only |
| `Vehicle` | GetDriver/GetRiders, Enter/Exit, SetParts, OpenDoor, GetSeatParams | ⭕ EnableTurret only |
| `ObjectState` | GetLinkGuid, SetState, SendDamage, **StartEmitter/StopEmitter** | ❌ (engine has `Scene::fx_start/fx_stop` ready to back the emitter half) |
| `Player` | Get/SetCash, Get/Set/AddFuel, FuelCapacity, GetPrimaryCharacter, VehicleDisguise | ❌ |
| `Hud` / `Pda` / `Gui` / `Marker` / `_GuiInternal` | full HUD/PDA widget + per-player `Gui*Update` event surface | ❌ |
| `Sound` / `VO` | CueSound, banks w/ callbacks, category fades, AddMusicState/Transition/BindMusicCue, VO priorities | ❌ |
| `Airstrike` / `Munitions` | Flyby, SpawnOrdnance, designators | ❌ |
| `Net` | IsServer/IsClient, SendCustomEvent, SendEvent_\* (support, revive, PDA, fanfare), SetLoadingScreen | ❌ |
| `Human.Inventory`, `Weapon`, `Camera`, `String.GetHash`, `Graphics`, `DangerousBuilding` | SetAllWeapons, SetReserveAmmo, GetYaw, GetHash, InitTinyGeometry, SetRarity | ❌ |

The auto-stub `_G` metatable (Surface-B tracer) means unimplemented namespaces log-and-continue
rather than crash — the corpus can already be *executed* for coverage measurement, just not *obeyed*.

---

## 4. Notes and traps carried forward

- **Evidence discipline** is inherited from `pangea_engine_alignment.md` §4: all `Pg*` behavior is
  string-inferred (no RTTI), the VMX128 numeric cores (drive model, hit solver, anim/audio/shader
  math) are undecoded in both builds — behavior-gate against the exe, never claim the math.
- **Rows that look done but have known seams:** streaming's c3 building-`Model` (0x5b724250)
  residency is deliberately disabled (authored placement unrecovered — `worldutil.rs:316-322`);
  SEGM byte-3 is treated as a state mask but the registry calls it `group` (reconcile vs the SEGM
  consumer decomp before building on it); the HDR path is gated on `sky_enabled` and falls back to
  direct present.
- **Two loops today:** `game_world::run_game_world` runs its own dt loop with hardcoded free-fly
  input; the `Schedule`/`Time` fixed tick and the `input.rs` action layer are built but consumed by
  `mercs2_game`/tests, not by the streaming loop. Unifying these is cheap and unblocks Keystone-C
  fidelity.
- **Retail-data realities:** props ship essentially no Havok clips (prop-anim layer is correct but
  idle on retail data) and ~no alternate LOD meshes (2/446) — so rows 10 and 20's "partial" is
  partly the *data's* fault, not the code's.
