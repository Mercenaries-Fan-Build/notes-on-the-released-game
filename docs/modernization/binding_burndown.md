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

### 1. HUD renderer — `Hud.*` (~91), most of `Gui.*` — HIGH (player-visible)
On-screen widgets, markers, objectives, meters, prompts. Needs a HUD/2D-overlay system (extend
`mercs2_ui`'s bitmap-text pass into a widget/marker layer) + a host seam feeding it live game state.
No-op today = a running game with no HUD.

### 2. Presentation / FX / post — `Atmosphere`, `Bloom`, `Fade`, `Graphics`, `Lti` (lighting), `CameraFx` — HIGH
Screen fades, bloom/HDR knobs, atmosphere/sky params, dynamic lights, camera shake/effects. Needs the
render-graph carve (see `rendering_fx_lighting_gap.md`): post pipeline, light objects, fade compositor.
Back these as those render passes land.

### 3. Object gameplay actions — `object_filter` (~12+), `object_state` (~8), `Object` residue, `Fire`, `Airstrike` (~11), `Weapon`, `Inventory` — HIGH
Damage/state transitions, filters/queries over live objects, fire propagation, airstrike delivery,
weapon fire/reload, inventory. Back against the ECS `World` + `mercs2_physics`/`mercs2_combat`. The
getters already read host state; the *actions* need the ECS write seam + combat solver (note: the
damage/explosion solver itself is still a reverse-engineering wall — see `rows-26-29` memory).

### 4. VO / dialogue / faces — `Vo` (~10), `Face` (~7) — MEDIUM
Voice-over cue playback, subtitle routing, facial animation. Needs a VO/dialogue director over
`mercs2_audio` + the facial-anim channel. `vo_cue` host method exists; the surrounding surface no-ops.

### 5. World / asset / install — `PgWorld` (~8: Spawn*/Region/Alarm/Install/Dump), `Pg` residue — MEDIUM
Region creation, alarms, model-spawn-by-asset, install-manager, dev asset dumps. Needs the streaming +
asset-DB host seam (`world_streaming_spec.md`). The `Dump*` family mirrors retail dev stubs and can
stay no-ops (genuinely-stripped class).

### 6. Vehicle depth — `Vehicle` residue (hijack FSM, turret articulation) — MEDIUM
Seat/driver/flying getters are backed; the hijack state machine + turret aiming need
`mercs2_vehicle` FSM extension (`vehicle_road_ai` map has the drive model).

### 7. Sound depth — `Sound` residue (bank load/unload callbacks, DSP reverb/lowpass) — MEDIUM
Cue/category/music are backed against `mercs2_audio`; residency-bank callbacks and DSP effects need
audio-engine extension.

### 8. Net / session — `Net` residue, `Socket`, `Report` — LOW (SP correct today)
Session/matchmaking/telemetry. The SP-correct defaults are already faithful (`Net.IsActive`→false path);
back against `mercs2_net` when co-op restore is wired into the reimpl.

### 9. Sys / settings / profile — `Sys` residue, `Player` profile residue — LOW
Config getters/setters and profile fields. Needs a small settings+profile store (retail-PC defaults
today). Cheap to back; low gameplay impact.

### 10. Ai residue — perception subjects, spawn-list channels, exclusion zones, road/lane spawning (~20) — LOW
`AddSubject`/`RemoveSubject`/`ThreatPerception` (perception subject list), `SetSpawnList`/spawn-list
channel model, `SetExclusionZone`/road exceptions, `SetTrafficSpawning`/`SetRoadSpawning`/`SetLaneActive`.
Back as the perception + traffic/spawn-list models grow in `mercs2_ai`/`mercs2_population`.

## Genuinely-stripped (stub IS faithful — do not "fix")
Retail strips these to no-op/return-0 stubs; a no-op here is correct, not debt. Keep documented:
- `Debug.*` menu (PC ships the shared return-0 stub `0x006D5640`).
- `Pg.Dump*` / diagnostic dumps (retail dev-only stubs).
Everything else above is real work.
