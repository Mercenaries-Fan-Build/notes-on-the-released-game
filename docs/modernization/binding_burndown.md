# Lua binding burn-down — backed vs unbacked

**Status metric (honest):** all 1086 `Required` engine cfuncs across 35 namespaces are installed and
callable (`tests/binding_smoke.rs` enforces it), so the game's Lua never faults on a missing binding.
But *callable ≠ implemented*. Each binding is one of:

- **BACKED** (`b.real`) — wired to a real engine mechanism (`mercs2_ai`/`faction`/`population`/`audio`/…)
  or reads real host state. A wrong body here is a bug. **424** as of the `Ai` vertical.
- **UNBACKED** (`b.stub`) — a deliberate no-op *because the engine system behind it isn't built yet*
  (or, for a documented handful, because the retail cfunc is genuinely stripped). **662** remain.
  **`stub` is NOT "done" — it is this burn-down.**

The source of truth for exactly which names are unbacked is the `b.stub(...)` blocks in
`crates/mercs2_script/src/bindings/*.rs` (the coverage report counts them per namespace). This doc
groups the unbacked surface by the **engine system that has to exist to back it**, in priority order,
so de-stub work is scheduled against real systems and not done blindly.

## The de-stub recipe (worked example: the `Ai` vertical)

Backing a namespace is a vertical, not a binding-file edit:

1. **Find/extend the mechanism crate.** `Ai` order verbs → `mercs2_ai::AiWorld::order` (posts the
   hash-addressed verb to the recovered 1024-slot ring); infractions/attitude → `mercs2_faction`
   (added `add_scripted_infraction` + `set_infraction_multiplier`); spawner tweaks →
   `mercs2_population::tweak_attached_spawners`.
2. **Add the host seam.** New `EngineHost` methods with default impls (so every crate/test still
   compiles), implemented for real on `GameScriptHost` (which now owns `FactionWorld`+`PopulationWorld`).
3. **Rewire the binding** from `b.stub` → `b.real`, forwarding to the host method.
4. **Behavioral test** driving the real Lua and asserting the mechanism changed
   (`game_lua_ai_drives_ring_and_faction`), plus bump the coverage baseline.

`Ai` result: real +31 (order ring, mood bridge, spawner tweaks). Residue below.

## Unbacked surface, grouped by required engine system (priority order)

### 1. HUD — `Hud.*` / `Gui._Marker*` — STATE MODEL DONE (rasterization pending)
✅ **Backed**: `mercs2_ui` fleshed out with a real retained-mode **`WidgetTree`** (`widget.rs`:
container/image/text/sprite/movie/flash/minimap nodes — location/color/visibility/anchoring/children/
z-order + per-kind data) and a **`MarkerSet`** (`marker.rs`: world blips/tripwires/discs/3D/objective
markers tracking a location or followed GUID). Wired through the `EngineHost::hud`/`markers` seam:
- `Hud.*` — create/delete, all widget transform+state setters+getters (`Set*`↔`Get*` round-trip),
  parenting + z-order, image texture/rotation/texcoords, text text/font/wrapping/justification/scale
  (+ width/height estimate), sprite/movie/flash/minimap create+state. (real +55)
- `Gui._Marker*` — add(5 kinds)/remove/location/color/follow/scale/pulse/blip-limit + `AddObjective`;
  `LoadTexture`/`LoadFont` as name-handles. (real +16)
Tests: `mercs2_ui` unit tests (tree parenting/z-order, marker config) + `game_lua_hud_drives_real_widget_tree`.
Residue (unbacked): the **GFx rasterization** (drawing the tree — a render pass) and the render/
callback/animation-only cfuncs (widget update callbacks, interpolation, pie-slice, clock anim, text/
sprite animation, flash VM input/callbacks, PDA blips, faction/vehicle/pickup marker CATEGORY toggles).

### 2. Presentation / FX / post — `Lti` (options menu), `CameraFx` — PARAMS DONE
✅ **Backed**: `mercs2_core::RenderState` (new `render_state.rs`) holds the params the render passes read;
wired via the `EngineHost::render_state` seam:
- `Atmosphere.*` — the generic named-parameter store (`SetValue`×109/`GetValue`, `SetColorValue`×78/
  `GetColorValue`, `SetIntValue`/`GetIntValue`) + `Begin`/`End` + time-of-day + the typed setters
  (`SetLightIntensity`/`SetAmbientColor`/scatter multipliers) routing into canonical keys.
- `Bloom.*` — all 7 HDR knobs (blur/threshold/multiplier/amount/luminance).
- `Graphics.*` — gamma, shadow base distance, screen ratio, boundary effect (`Set*`↔`Get*`).
- `Fade.*` — the four fade colors (ambient top/sides/terrain/camera).
Tests: `mercs2_core::render_state` + `game_lua_render_state_roundtrip`.
Residue (unbacked): the actual **render passes** (post pipeline / fade compositor / light objects — the
`rendering_fx_lighting_gap.md` work) + atmosphere preset/region/interpolation engine; `Lti.*` options
menu (resolution/gamma/refresh/input remap — needs a settings-menu backend); `CameraFx.*` cinematic
camera controller.

### 3. Object gameplay actions — `object_state` (~8), `Object` residue, `Fire`, `Airstrike` (~11), `Weapon`, `Inventory` — HIGH
✅ **Backed**: `ObjectFilter.*` — the label boolean-expression query (`"Hero||(China&&Vehicle)"`,
recursive-descent evaluator in `mercs2_core::object_filter`) + explicit include/exclude sets + a real
per-object **label store** on the host (`Object.AddLabel`/`RemoveLabel`/`HasLabel` now actually work).
Tests: `mercs2_core::object_filter` (parser/sets/registry) + `game_lua_object_filter_evaluates_real_predicate`.
Residue: damage/state transitions, fire propagation, airstrike delivery, weapon fire/reload, inventory —
need the ECS write seam + `mercs2_combat`. The damage/explosion **solver** itself is still a
reverse-engineering wall (see `rows-26-29` memory); `ObjectFilter` association/relation edges unbacked.

### 4. VO / dialogue / faces — `Face` (~7), `Vo` sequences — PARTLY DONE
✅ **Backed** against `mercs2_audio::VoManager` (via the shared AudioEngine): `VO.Cue`/`CueWithoutSubtitles`
(now really impl'd on the host — was a trait-default 0), `Cancel`/`CancelAll`/`Pause`/`PauseAll`/`Unpause`/
`UnpauseAll`/`SetCinematicMode`. Cue names hash (FNV-1a) to a stable cue guid so `Cue`↔`Cancel(name)`
match. Test `game_lua_vo_drives_real_vo_manager`.
Residue (unbacked): `AddSequence`/`RemoveSequence` (VO sequence playlists — needs a sequence model),
VO completion callbacks back into Lua, and `Face.*` facial animation (needs the facial-anim channel).

### 5. World / asset / install — `PgWorld` (~8: Spawn*/Region/Alarm/Install/Dump), `Pg` residue — MEDIUM
Region creation, alarms, model-spawn-by-asset, install-manager, dev asset dumps. Needs the streaming +
asset-DB host seam (`world_streaming_spec.md`). The `Dump*` family mirrors retail dev stubs and can
stay no-ops (genuinely-stripped class).

### 6. Vehicle depth — `Vehicle` residue (seat transfer, ammo) — MOSTLY DONE
✅ **Backed** (`mercs2_vehicle::HijackFsm`/`TurretAim`, held per-vehicle on the host): the whole hijack
lifecycle (`HijackStart`/tank-motion/`SetHijackSuccess`/`HijackComplete`/`HijackAbort`/`HijackAbortDone`/
`CancelHijack`/`SetHijackState`), turret+rotor aim (`SetTurretPitch`/`SetTurretYaw`/`SpinHeli`), and
`RestoreHealth`. Behavioral test `game_lua_vehicle_hijack_and_turret`.
Residue (unbacked): `EnterBySeatGuid`/`TransferToSeat` need the seat-guid resolution seam; `RestoreAmmo`
needs a per-object ammo store.

### 7. Sound depth — `Sound` residue (dynamic-music model, DSP reverb/lowpass) — PARTLY DONE
✅ **Backed** against `mercs2_audio`: cue/category volume/master/music-FSM (prior), plus category
**pitch** and the whole **bank residency** family (`LoadBank`/`LoadSoundBank`/`LoadWaveBank`/
`LoadTempBank`/`LoadBankWithCallback` + the `Unload*` mirror + `RequestAmbienceBank`) → the real
`BankManager` slot table. Behavioral test in `game_lua_sound_drives_real_audio_engine`.
Residue (unbacked): the dynamic **faction/action/source-music** model (`AddFactionMusic`/`SetSourceMusic`/
playlists — needs `music.rs` extension), **EAX reverb + low-pass DSP** (no portable analog, `backend.rs`),
bank-load **completion callbacks** back into Lua (async streaming seam), and misc mode toggles.

### 8. Net / session — `Net` residue, `Socket`, `Report` — LOW (SP correct today)
Session/matchmaking/telemetry. The SP-correct defaults are already faithful (`Net.IsActive`→false path);
back against `mercs2_net` when co-op restore is wired into the reimpl.

### 9. Sys / settings / profile — `Player` profile residue — PARTLY DONE
✅ **Backed**: the `Sys.*` engine-config store on the host — `SetTimeScale`/`SetLevelName`/
`SetMasterScriptName`/`SetTutorialsEnabled`/`SetAutosaveEnabled`/`SetLuaSaveVersion`/
`SetNumberOfViewports`/`SetAssetRequestMax`/`StartSingleplayer`/`WriteToConsole`, with `Set*`↔`Get*`
real roundtrips (`GetMasterScriptName`/`TutorialsEnabled` now read the store). Test
`game_lua_sys_settings_roundtrip`.
Residue (unbacked): asset-preload/streaming controls (`RequiredAsset`/`DisableAssetPreload`/`FlushAssets`),
`AddStringDb`/`ClearStringDb` (localization DB), `PlayIntroMovies`, `SetSkipMission`; plus `Player`
profile fields. `time_scale` is stored but not yet read by the fixed-tick — wire that next.

### 10. Ai residue — perception subjects, spawn-list channels, exclusion zones, road/lane spawning (~20) — LOW
`AddSubject`/`RemoveSubject`/`ThreatPerception` (perception subject list), `SetSpawnList`/spawn-list
channel model, `SetExclusionZone`/road exceptions, `SetTrafficSpawning`/`SetRoadSpawning`/`SetLaneActive`.
Back as the perception + traffic/spawn-list models grow in `mercs2_ai`/`mercs2_population`.

## Genuinely-stripped (stub IS faithful — do not "fix")
Retail strips these to no-op/return-0 stubs; a no-op here is correct, not debt. Keep documented:
- `Debug.*` menu (PC ships the shared return-0 stub `0x006D5640`).
- `Pg.Dump*` / diagnostic dumps (retail dev-only stubs).
Everything else above is real work.
