---
title: Mission construction patterns
status: current
evidence: proven
date: 2026-09-22
---

# Mission construction patterns

**Scope:** the *Lua-side authoring patterns* the shipped game uses to build mission-like activities
— how offering (how the player finds it), lifecycle (what class runs it), and persistence (what
survives save/reload) combine, and how to reassemble those parts to construct custom gamemodes
without hitting the seam-hardening failure modes documented in
[`docs/modding/lua_engine_seam_hardening.md`](../modding/lua_engine_seam_hardening.md).

This is the peer of [`mission_contract_flow_code_map.md`](mission_contract_flow_code_map.md), which
maps the *native* mission surface (Pg cfuncs, `Sys.RequestGameState`, layer streaming, context
actions, `Pg.Contract*`). Read that map for engine internals; read this for how the shipped Lua
composes them.

## Why this exists

A modder authoring a new mission has three fundamental choices to make — **offering**, **lifecycle**,
**persistence** — and each is a separately-shipped mechanism inside the game. The shipped scripts
combine them in ~4 distinct ways to produce every mission-like thing in the game (story contracts,
job counters, tutorials, shooting galleries, in-game training). The choice determines whether the
mission is save-safe, whether it can survive reload, whether it interacts with `_tActiveMissions`,
whether it activates a starter, and whether it ends up on the F1–F11 poisoning list in the seam-
hardening doc.

Author intent should drive the choice; today, modders (including this project's own FioDef001 pre-
v0.9.7) tend to reach for the most heavyweight option (MrxTaskContract with a starter) even when a
lighter one would be structurally safer and semantically closer.

## The three axes

### Axis 1 — Offering (how the player gets in)

How the player becomes aware of the mission and initiates it.

| Pattern | Mechanism | Shipped users |
|---|---|---|
| **Briefing-table NPC** | `oStarter:AddBriefing(sMissionName, ...)` at [mrxstarter.lua:137](../../tools/wad_simulator/workshop_data/lua/resident/mrxstarter.lua#L137). Puts the mission on the actor's offering list; player walks up to the actor and interacts. `sStarter="PmcBoss"` for Fiona at HQ, `sStarter="AllStarter0"` for the Allies boss, etc. | PmcCon031 (shooting gallery), PmcCon002/003 (critical-path Fiona contracts), Chi/Gur/Oil/Pir/All starter-driven contracts. |
| **Auto-unlock from flow-rule** | `UnlockMission("X")` called from `wifmissionflow.lua`'s fConseq for a completed prior mission; no `sStarter`. Player never explicitly accepts; the mission just begins (usually with a blocking cutscene). | VzaCon001 (game intro), PmcCon001 (villa takeover), PmcCon004 (act finale). |
| **PDA waypoint marker** | `Pda.Map:AddBlip{...}` + `Hud.Radar:AddObjective{...}`. No offering per se; the map just has a labeled marker; the player walks to it and something (region trigger, context action, MrxTutorial activation) fires. | Most tutorial trigger regions; every mission's post-accept objective marker (once accepted, the mission's objectives blip on the PDA). |
| **Region entry** | `Event.Create(Event.ObjectProximity, {uPlayer, uRegion, "<", nRadius, false, false}, fn)` or an `Event.RegionEnter`-style bind. Player walks into a defined area; the callback fires. Used both as an *offering* mechanism (activate the mode) and as an *in-mission trigger*. | Every wiftutorial\*.lua that's not vehicle-specific; PMC HQ portal entry (`_OnEnter` at [wifpmcinterior.lua:386](../../tools/wad_simulator/workshop_data/lua/vz/wifpmcinterior.lua#L386)); atmosphere boundary triggers (`rgn_atmo_*`). |
| **Context action** | `Pg.AddContextAction(uObject, sName, fn)` — player is near the object and presses the action button. | Vehicle-hijack prompts, capture-point interactions, briefing-station "sit down" actions. |
| **Custom UI menu** | Author builds their own accept UI. Not a shipped native pattern; Wally's `Ess.Contract.UI.Panel` (aliased to `Ess.UI.Panel` at [80_contract.lua:53](../../../mercs2-lua-essentials/src/80_contract.lua#L53)) does this. | Ess.Contract only. |

*Important:* the **PDA is not a mission-selection menu**. It is a map with markers and waypoints
for missions *the player already has*. All shipped mission offering happens through one of the
first four patterns above. A mod that tries to "add itself to the PDA menu" is trying to use a
menu that doesn't exist.

### Axis 2 — Lifecycle (what class runs it)

How the mission's state is managed while it's running.

**MrxTaskContract** ([mrxtaskcontract.lua](../../tools/wad_simulator/workshop_data/lua/resident/mrxtaskcontract.lua),
`inherit("MrxTaskMission")` → `inherit("MrxTask")`). The heavyweight, save-persistent class:
- Full state machine (`MrxTaskState._knInactive/_knActive/_knCompleted/_knCancelled`).
- Nested `oContainer` → `oMission` → child objective tree, each an MrxTask instance.
- Registered in `_tActiveMissions[sMissionName]` on `UnlockMission`.
- `SaveInstance` serialises `nState` + `_tSaveData` for reload.
- Framework Activated (line 41) does play-state, checkpoint, faction hostility, contract music,
  parking-lot mark, all the "you are on a contract now" ceremony.
- Full lifecycle chain: `Activate` → `dynamic_import` → `_ModuleLoaded` → `PreLoadAssets` →
  `LoadAssets` → `AssetsLoaded` → `_IssueAssetsLoadedCallbacks` → `Activated`.

**MrxTaskMission** — MrxTask + subtitle/vo helpers. Middle-weight; used where you want the full
save-persistent lifecycle but not the contract-specific music/wager/HUD ceremony.

**MrxTaskJob** ([mrxtaskjob.lua](../../tools/wad_simulator/workshop_data/lua/resident/mrxtaskjob.lua)) —
milestone/counter-tracked contracts (destroy 10 vehicles, deliver 50 crates). Same MrxTask base
class, milestone-key award at each threshold.

**MrxTutorial** ([mrxtutorial.lua](../../tools/wad_simulator/workshop_data/lua/resident/mrxtutorial.lua)).
The lightweight, ephemeral class:
- **No** `MrxTaskState`. **No** `SaveInstance`. **No** `_tSaveData`.
- **Never registers into `_tActiveMissions`.** **Never touches any starter.**
- Just: `Create(mModule, self)` sets metatable, `_tEvents = {}`, three overridable hooks:
  `SetupActivationCriteria` / `SetupCompletionCriteria` / `SetupCancellationCriteria`.
- `MrxTutorialManager.SaveSingleton` at [line 219](../../tools/wad_simulator/workshop_data/lua/resident/mrxtutorialmanager.lua#L219)
  saves *only* a flat list of completed-tutorial names — a bounded string set that cannot cause
  the save-poisoning failure modes F1–F11.
- Suitable for anything where the state-during-execution doesn't need to survive save/reload —
  tutorials, arena modes, wave defence, timed challenges, skill trials.

**Home-rolled ephemeral (Ess.Contract-shape)** ([80_contract.lua](../../../mercs2-lua-essentials/src/80_contract.lua)).
A parallel framework built entirely out of `Event.*`, `Pg.Spawn`, `Object.*`, `MrxPmc` primitives.
- Same "no save touch" property as MrxTutorial.
- Adds its own briefing/HUD/fanfare/reward UI so the offering is menu-driven rather than context-
  driven.
- Fully custom lifecycle (`C._newTask` at line 90, `C.Accept` / `.Abort` / `.Status`).
- Trades save-persistence for save-safety by construction.

**MrxTaskObjective\* / MrxTaskContractOutpost / MrxTaskJobDestroyType** — specialised subclasses
of MrxTaskMission for specific gameplay verbs (destroy set of things, capture outpost, patrol,
etc.). All still MrxTask-family, all save-persistent, all `_tActiveMissions`-bound.

### Axis 3 — Persistence (what survives save/reload)

What ends up in the `.profile` file when the game saves, and how it re-hydrates on load.

| Pattern | Save payload | Reload | F1/F11 exposure |
|---|---|---|---|
| **MrxTask.SaveInstance** ([mrxtask.lua:388](../../tools/wad_simulator/workshop_data/lua/resident/mrxtask.lua#L388)) | `{nState, ...deep-copy of _tSaveData}` for every entry in `_tActiveMissions` | `WifMissionFlow.LoadSingleton` at [line 609](../../tools/wad_simulator/workshop_data/lua/resident/mrxmissionflow.lua#L609) calls `UnlockMission(name, saveData, false)` per entry | **High** — F1 uninstall poison, F3 schema drift, F4 userdata deepcopy, F11 starter side-effect |
| **MrxTutorialManager.SaveSingleton** ([line 219](../../tools/wad_simulator/workshop_data/lua/resident/mrxtutorialmanager.lua#L219)) | Flat list of completed-tutorial names (strings) | `LoadSingleton` at [line 229](../../tools/wad_simulator/workshop_data/lua/resident/mrxtutorialmanager.lua#L229) marks matching entries `bComplete=true`; unknown names silently no-op | **None** — bounded strings, no side-effects on load |
| **MrxStarterManager.SaveSingleton** ([line 101](../../tools/wad_simulator/workshop_data/lua/resident/mrxstartermanager.lua#L101)) | Per-starter `{bFanfareDisplayed, bCardDisplayed, tIntros, tOldBriefings}` for every starter that's ever been created | `LoadSingleton` at [line 114](../../tools/wad_simulator/workshop_data/lua/resident/mrxstartermanager.lua#L114) calls `RequestStarter(name, ...)` → `CreateStarter(name, ...)` → **unconditional `oStarter:Activate()`** at [mrxstartermanager.lua:48](../../tools/wad_simulator/workshop_data/lua/resident/mrxstartermanager.lua#L48). Any starter in the save is re-Activate'd. | **High** — F11 cascade: Activate → RefreshBriefingRoomDisplay → WifPmcInterior.RefreshUiDisplay → _EnablePortals arms HQ portals for any bPmcStarter starter that ends up in the save |
| **WifPmcInterior.SaveSingleton** ([line 1616](../../tools/wad_simulator/workshop_data/lua/vz/wifpmcinterior.lua#L1616)) | `{bUnlocked, tStockpileQty, tIntroduced}` | `LoadSingleton` at [line 1631](../../tools/wad_simulator/workshop_data/lua/vz/wifpmcinterior.lua#L1631) calls `Unlock()` if `bUnlocked` was saved | Medium — F11-adjacent: if a mod ever caused `_bUnlocked=true` before PmcCon001, this preserves it |
| **Custom SaveSingleton per subsystem** | Every subsystem that participates in save has its own. Aggregated at [xQ!L.lua:530-556](../../tools/wad_simulator/workshop_data/lua/vz/xQ!L.lua#L530-L556) into the master `.profile` payload | Loaded in matching order at [xQ!L.lua:790-820, 858-865](../../tools/wad_simulator/workshop_data/lua/vz/xQ!L.lua#L790-L820) | Depends on subsystem; each is a potential poisoning site if a mod injects into it |
| **No SaveSingleton participation** | Nothing serialised | Nothing to hydrate | **None** by construction (the Ess.Contract choice) |
| **External file (custom)** | Author writes to `%APPDATA%` or the game folder via `Pg.WriteFile`-style native calls (if exposed) or side-channels a Steam Cloud file | Author reads on OnLoad | None from the game's perspective — the risk is entirely on the author's file-format management. Suitable for high-score tables, per-mode progress, anything the game itself doesn't need to know about. |

## The combinability matrix

Every shipped mission-like activity is one of the cells here. The row is the offering, the column
is the lifecycle. Persistence follows from the lifecycle.

|  | MrxTaskContract | MrxTaskJob | MrxTutorial | Ess.Contract |
|---|---|---|---|---|
| **Briefing-table NPC** | ✅ shipped norm (PmcCon031, most Fiona/Chris contracts) | ✅ shipped (PmcJob001 — although it's `bSuppressPdaDisplay=true`, offered silently in the background) | ❌ never — MrxTutorial doesn't use starters | ❌ Ess doesn't touch native starter briefing tables |
| **Auto-unlock from flow-rule** | ✅ shipped (VzaCon001, PmcCon001, PmcCon004) | ✅ possible | ❌ tutorials aren't flow-rule driven | N/A |
| **PDA waypoint marker** | ✅ (after accept, every mission adds its own via AddPdaMissionDetails) | ✅ | ⚠ marker alone doesn't fire the tutorial; needs a region/context action to actually trigger | ✅ Ess builds its own markers via Ess.Mark |
| **Region entry** | ⚠ rare — usually mid-mission, not offering | ⚠ rare | ✅ shipped norm (wiftutorial*.lua) | ✅ common in Ess.Contract patterns |
| **Context action** | ⚠ mid-mission usually | ⚠ mid-mission usually | ✅ common (press-to-start tutorials) | ✅ |
| **Custom UI menu** | Requires custom offering code layered on top of MrxTaskContract | Same | Same | ✅ native to Ess.Contract |

**The invariant that catches modders**: an MrxTaskContract with `sStarter="PmcBoss"` unlocked
before PmcCon001 completes hits F11 — it forces PmcBoss into being created + activated, which
cascades to arming the PMC HQ portals. Vanilla never violates this because every PmcBoss-startered
contract in the shipped data is UnlockMission'd only from PmcCon001's fConseq. Custom missions
that want to be Fiona-offered must gate on `HasKey("PmcCon001")`; see
[[custom-mission-inherit-mrxtask-required]] for the concrete failure.

## Recipes for common custom-mission shapes

### Recipe A — Story-shaped contract (Fiona hands you the mission)

*When to use:* the mission is a "real" contract with briefing dialogue, wager mechanics, save-
persistent state, and it earns a slot in the player's progression path.

- Offering: **Briefing-table NPC** (`sStarter="PmcBoss"`).
- Lifecycle: **MrxTaskContract** (`inherit("MrxTaskContract")`).
- Persistence: **MrxTask.SaveInstance** (via `_tActiveMissions`).
- Gates: `wifmissionflow.lua`-style fPrereq (typically `HasKey("PmcCon001")` for PMC-faction).
- Requires the seam hardening the shipped Lua takes for granted: the mission must handle
  cancel/complete/cleanup deterministically, its `_tSaveData` must contain only serialisable
  primitives, and the mod must be present on any machine that loads the save.

### Recipe B — Silent counter job (destroy 100 vehicles for a bonus)

*When to use:* the mission tracks a cumulative count in the background without ever appearing on
the PDA as an offering; milestones award keys the flow-system can gate on.

- Offering: **Auto-unlock from flow-rule**, `bSuppressPdaDisplay=true`.
- Lifecycle: **MrxTaskJob**.
- Persistence: **MrxTask.SaveInstance** (state is small — the counter).
- Vanilla example: PmcJob001 ([wifmissiondata.lua:978-1021](../../tools/wad_simulator/workshop_data/lua/vz/wifmissiondata.lua#L978-L1021)) —
  nine milestones from 10 to 100 vehicles.

### Recipe C — Region-entry challenge arena (wave defense, driving trial, shooting gallery)

*When to use:* the "mission" is a distinct arena/mode the player physically enters; state is
per-session and shouldn't survive save/reload; a high-score or completion count is what persists.

- Offering: **Region entry** on the arena boundary; typically also a PDA waypoint pointing to it.
- Lifecycle: **MrxTutorial** (or an Ess.Contract-shaped ephemeral if custom UI is wanted).
- Persistence: **MrxTutorialManager.SaveSingleton**-style (completion list) OR external file for
  high scores.
- **Zero F1–F11 exposure** — no starter, no `_tActiveMissions`, no per-mission save payload.
- Vanilla examples: most `wiftutorial*.lua` files; MrxShootingGallery mode inside PmcCon031's
  gameplay (though PmcCon031 itself is Recipe A).
- The pattern FioDef001 should be — a wave-defense arena on the offshore island, entered by
  physically going there, with per-run session state and a persistent best-wave counter.

### Recipe D — Ephemeral tutorial popup

*When to use:* short in-context guidance (bomb defuse tips, vehicle controls) that fires whenever
the trigger context is met and doesn't otherwise mutate world state.

- Offering: **Region entry** or **Context action**.
- Lifecycle: **MrxTutorial**.
- Persistence: **MrxTutorialManager.SaveSingleton** (bComplete flag only).
- Vanilla examples: every `wiftutorial*.lua`.

### Recipe E — Custom-UI ephemeral contract (Ess-shape)

*When to use:* rich offering UI (multi-page menu, custom accept/decline dialog) is wanted, but
save-persistence is not; a modkit dashboard element wants to expose the mission list.

- Offering: **Custom UI menu**, hand-rolled or via `Ess.UI.Panel`.
- Lifecycle: **Ess.Contract-shape** (home-rolled `_newTask`, per-objective handler registry).
- Persistence: **No SaveSingleton participation** — registry rebuilt on OnLoad from Register calls.
- Save-gate via `Ess.Save.gate(key)` if in-mission mutations should not serialise.
- Vanilla equivalent: none (Ess.Contract was built precisely because this recipe was missing
  from shipped surfaces).

## Cross-references

- [`mission_inventory.md`](mission_inventory.md) — the concrete inventory of every shipped
  mission classified by lifecycle class, starter, and unlock trigger, with each mission mapped
  to a recipe. Answer "which shipped missions match Recipe X" by looking there.
- [`mission_contract_flow_code_map.md`](mission_contract_flow_code_map.md) — the native side:
  which cfuncs (Pg.LoadLayer etc.) each of these patterns ultimately reaches.
- [`docs/modding/lua_engine_seam_hardening.md`](../modding/lua_engine_seam_hardening.md) — F1–F11
  failure modes at the Lua↔engine seam; every mod that picks a heavy pattern above needs to know
  which of them apply to its choice.
- [`docs/modding/manifest_format.md`](../modding/manifest_format.md) — where the `requires:`
  block and future `save_schema:` block on mission contributions land, per the seam-hardening
  proposal.
- [[custom-mission-add-script-loading-screen-wedge]] — the WAITFORSTREAMING wedge that only bites
  MrxTaskContract-family missions authored via `add_script`.
- [[custom-mission-inherit-mrxtask-required]] — F11's canonical failure: forgetting `inherit` on
  an add_script MrxTaskContract module.
- `mercs2-lua-essentials/src/80_contract.lua` — Wally's Ess.Contract framework, worked example
  of Recipe E.

## When to break the recipe

The recipes above are the shipped-native + Ess-provable combinations. Nothing prevents a modder
from wiring, say, a briefing-table offering to a MrxTutorial lifecycle (unusual — nothing in the
shipped game does it) — but every off-recipe combination re-enters the F1–F11 hunt because now
you're combining subsystems in a way the shipped scripts don't stress-test. Prefer to stay on a
recipe unless the mission's UX genuinely requires the composition.
