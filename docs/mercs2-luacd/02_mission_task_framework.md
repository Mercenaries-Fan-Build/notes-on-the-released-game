# 02 — Mission / Task / State Framework

Decompiled Lua reference for the **Mrx** mission/task/state framework in *Mercenaries 2: World in Flames*. This group is the spine of the game's progression: the `MrxState` global state machine (the world-load gate), the `MrxTask` task-tree, mission flow / unlock / reward logic, briefings, HQ/starter managers, and the concrete objective/job/contract subclasses.

All paths are relative to `docs/mercs2-luacd/`. Line numbers are real; clickable refs point at `src/resident/<name>.lua`.

> **Load-debug relevance.** The world-load log markers that `loadprobe` and the pmc_blackbox tooling key on (`GlobalEnter - Complete`, `STATE_WAITFORSTREAMING`, `STATE_WAITFORGAME`, `MrxState.Enter/Exit … refcount=N`, `_AttemptGlobalExit`) all originate in [mrxstate.lua](src/resident/mrxstate.lua). The DLC "hang on streaming / never spawns player" symptom is a **refcount that never reaches 0** on `STATE_WAITFORSTREAMING` or `STATE_WAITFORGAME` — see [§7 Future-dev / modding notes](#7-future-dev--modding-notes).

---

## 1. Overview

### 1.1 The `MrxState` global state machine (the load gate)

`MrxState` is **not** the per-task state — it is a small, reference-counted **global gate** that fades the screen to black, suppresses HUD/PDA/input, and blocks until all pending async work (streaming, tether, game-ready, briefing-asset loads) has signalled completion. It is the layer the engine's world-load waits on.

Four states ([mrxstate.lua:7-11](src/resident/mrxstate.lua#L7)):

| Enum | Value | `Enter` behavior | Released by |
|------|-------|------------------|-------------|
| `STATE_NONE` | 0 | (no entry) | — |
| `STATE_CINEMATIC` | 1 | immediately calls `_StateComplete` | self |
| `STATE_WAITFORSTREAMING` | 2 | `Sys.RequestGameState("WaitForStreaming")` + waits on `Event.GameStateChange "exit"` | engine GameStateChange |
| `STATE_WAITFORTETHER` | 3 | `Sys.RequestGameState("WaitForTether")` + waits | engine GameStateChange |
| `STATE_WAITFORGAME` | 4 | immediately calls `_StateComplete` | self / paired `Exit` |

Each state is a record with `nRefCount`, `bLocked`, `tEnterCompleteCallbacks`, `tReadyToExitCallbacks`, `sName`, `safeEnterCount`, `forceExitCount` ([mrxstate.lua:12-73](src/resident/mrxstate.lua#L12)).

**Lifecycle of a global gate cycle:**
1. First `Enter(nState, …)` while not globally locked → sets `_bGloballyLocked`/`_bGloballyFading`, calls `_GlobalEnter` (fade-out, duck audio, suppress player input/scope, set invincible). Logs `###! GlobalEnter - Begin` ([:81](src/resident/mrxstate.lua#L81)).
2. Fade completes → `_CompleteEnter` runs the state's `Enter()`, processes queued enter-callbacks, logs `###! GlobalEnter - Complete` ([:239](src/resident/mrxstate.lua#L239)).
3. Async work finishes → each `Exit(nState)` decrements `nRefCount`. When a state's count hits 0, its `Exit()` runs.
4. Every `Exit`/`_StateComplete` calls `_AttemptGlobalExit` ([:287](src/resident/mrxstate.lua#L287)), which scans **all** states; if every `nRefCount == 0` and no `bLocked`, it calls `_GlobalExit` (fade-in, restore input, run global-exit callbacks). Logs `###! GlobalExit - Begin` / `###! GlobalExit - Complete`.

`Enter` is paired with `Exit`. An `Exit` with `nRefCount <= 0` logs **`UNPAIRED EXIT`** and is a no-op ([:259](src/resident/mrxstate.lua#L259)). `SafeEnter`/`SafeExit` ([:363-382](src/resident/mrxstate.lua#L363)) let exits arrive before enters via `safeEnterCount`/`forceExitCount` bookkeeping.

### 1.2 The `MrxTask` task tree

Missions, briefings, contracts, jobs and individual objectives are all **`MrxTask`** nodes in a parent/child tree ([mrxtask.lua](src/resident/mrxtask.lua)). Each node carries a `_tConfig` and a `_tChildren` map keyed by name. A node has a 4-value lifecycle state from `MrxTaskState`:

| `MrxTaskState` enum | Value | Display name |
|---------------------|-------|--------------|
| `_knLatent` | 0 | `latent` |
| `_knActive` | 1 | `active` |
| `_knCompleted` | 2 | `completed` |
| `_knCancelled` | 3 | `cancelled` |

([mrxtaskstate.lua:1-4](src/resident/mrxtaskstate.lua#L1))

**Task lifecycle:** `Create` → `Configure(tConfig)` → `Activate` (which `dynamic_import`s the per-task module if `sModuleName` is set, then `PreLoadAssets` → `LoadAssets` → `AssetsLoaded` → `Activated`) → … → `Complete` or `Cancel` (both call `Cleanup` then `_SetState` + `_IssueStateChangeCallbacks`). Completing/cancelling a node propagates the state to its children via `_SetChildrenState` ([mrxtask.lua:185](src/resident/mrxtask.lua#L185)).

**Class hierarchy (via `inherit(...)`):**

```
MrxTask  (base node: tree, config, state, assets, save)
├── MrxTaskMission        (adds VO, PDA refresh, contract/job discriminators) _knContract=0 _knJob=1
│   ├── MrxTaskContract   (the "real" contract: playstate, music, fanfare, retry/checkpoint, wager ledger)
│   │   ├── MrxTaskContractOutpost      (outpost-capture contract + tutorials)
│   │   └── MrxTaskContractPlaceholder  (stub → placeholder cinematic → auto-complete)
│   └── MrxTaskJob        (multi-target "bounty" mission: per-target layers, nearby VO, milestones)
│       ├── MrxTaskJobCollectType   (toolbox-part collection, persists collected set)
│       ├── MrxTaskJobDestroySet    (named target set, per-target layers/VO)
│       ├── MrxTaskJobDestroyType   (label-filtered standing bounty, quota)
│       └── MrxTaskJobVerifySet     (HVT capture/kill set + fanfare)
├── MrxTaskObjective      (base objective: target filter, blips/markers, quota, msg display)
│   ├── MrxTaskObjectiveAction       (context-action "talk"/interact target)
│   │   ├── MrxTaskObjectiveAccept   (confirm-dialog wrapper before accept)
│   │   └── MrxTaskObjectiveRelease  (free a subdued prisoner)
│   ├── MrxTaskObjectiveCaptureOutpost
│   ├── MrxTaskObjectiveDeliver      (escort player/NPC/object/vehicle to a destination)
│   ├── MrxTaskObjectiveDestroy
│   ├── MrxTaskObjectiveEnterVehicle
│   ├── MrxTaskObjectiveExtract      (heli pickup of an NPC, state machine)
│   ├── MrxTaskObjectiveProtect
│   └── MrxTaskObjectiveVerify       (HVT subdue/kill + verify animation/extraction)
└── MrxTaskRace           (multi-checkpoint race, gate/ring markers, timer)
```

### 1.3 Mission flow (accept → activate → objectives → complete → reward)

`MrxMissionFlow` ([mrxmissionflow.lua](src/resident/mrxmissionflow.lua)) is the singleton that turns *data* (`WifMissionData`, `WifStarterData`, `WifMissionFlow` binding tables) into *live task trees*:

1. **Unlock** — `UnlockMission(sMissionName, tSaveData, bBlockingSequence)` ([:115](src/resident/mrxmissionflow.lua#L115)) builds a **container** `MrxTask` and a child **mission** `MrxTask`, copies config from `WifMissionData.tMissionData`, computes layers (`"Vz_State_"..sMissionName`), rewards (`MrxRewardData.GetRewards`), and start locations, then `Activate`s the container. If the mission has a starter/briefing it also builds a **briefing** child.
2. **Accept** — for missions with a starter, a briefing is offered; `AcceptMissions` ([:567](src/resident/mrxmissionflow.lua#L567)) completes the briefing node, which fires `_OnBriefingComplete` → `MrxState.Enter(STATE_WAITFORSTREAMING, oMission.Activate, …)` ([:324](src/resident/mrxmissionflow.lua#L324)).
3. **Activate** — the mission task loads its layers; **`fOnAssetsLoaded = _OnAssetsLoaded`** exits **both** `STATE_WAITFORSTREAMING` and `STATE_WAITFORGAME` ([:261-266](src/resident/mrxmissionflow.lua#L261)). This is the critical hand-off that releases the load gate. `MrxTaskContract.Activated` sets `MrxPlayState._knMission`, plays contract music, takes a checkpoint save.
4. **Objectives** — objective subclasses watch game events (death, proximity, seat, winch, …) and call `CompletePart`/`CancelPart`; quota met → `Complete` → mission `RefreshPdaDisplay`.
5. **Complete** — mission `Complete` → container `_OnContainerComplete` ([:153](src/resident/mrxmissionflow.lua#L153)): sets playstate free, awards keys & milestone keys, refreshes flow, removes PDA mission, optionally re-unlocks if repeatable. Contract `Complete2` runs the fanfare/ledger and sets `nCashOverride`.
6. **Reward** — `MrxRewardData.GrantRewardKey` / `DispenseRewards` grant cash/fuel/attitude/support/equipment/stockpile, with unlock fanfares ([mrxrewarddata.lua:1531](src/resident/mrxrewarddata.lua#L1531)).

---

## 2. Per-module reference

### 2.1 Core framework

#### `mrxstate.lua` — global load-gate state machine
[mrxstate.lua](src/resident/mrxstate.lua) · imports MrxUtil, MrxGui, MrxSoundCategories, MrxVoSequence, MrxMunitionsPickup, MrxGuiInterface.

- `_GlobalEnter(fComplete, tData)` [:81](src/resident/mrxstate.lua#L81) — fade-out, duck audio, suppress player scope/input + invincible, suppress PDA & resource counters, pause fanfare queue.
- `_GlobalExit()` [:116](src/resident/mrxstate.lua#L116) — fade-in, restore everything, fire `_tGlobalExitCallbacks`.
- `Enter(nState, fEnterCompleteCb, …, fReadyToExitCb, …)` [:192](src/resident/mrxstate.lua#L192) — increments `nRefCount`, queues callbacks, kicks `_GlobalEnter` on first lock. Defers if `_bGloballyFading`.
- `Exit(nState, fCallback, …)` [:254](src/resident/mrxstate.lua#L254) — decrements `nRefCount`; runs state `Exit()` at 0; `_AttemptGlobalExit`. Logs `UNPAIRED EXIT` if already 0.
- `_StateComplete(nState)` [:179](src/resident/mrxstate.lua#L179) — clears `bLocked`, processes ready-to-exit callbacks, `_AttemptGlobalExit`.
- `_CompleteEnter(tStateData)` [:239](src/resident/mrxstate.lua#L239) — runs state `Enter()`, logs `GlobalEnter - Complete`.
- `_AttemptGlobalExit()` [:287](src/resident/mrxstate.lua#L287) — the gate check; exits globally only if **all** states have `nRefCount==0` and `bLocked` false.
- `_GetTotalRefCount()` [:308](src/resident/mrxstate.lua#L308), `IsLocked()` [:316](src/resident/mrxstate.lua#L316), `PrintStatus()` [:329](src/resident/mrxstate.lua#L329) — diagnostics.
- `SetQuickFade(bEnable)` [:320](src/resident/mrxstate.lua#L320), `EnableFade(bEnable)` [:324](src/resident/mrxstate.lua#L324).
- `SafeEnter/SafeExit/SafeEnterCallback` [:348-382](src/resident/mrxstate.lua#L348) — order-independent enter/exit pairing.
- `AddGlobalExitCallback(fCallback, tArgs)` [:384](src/resident/mrxstate.lua#L384) — run now or on next global exit.

#### `mrxtaskstate.lua` — task state enum
[mrxtaskstate.lua](src/resident/mrxtaskstate.lua). `IsValidState` [:6](src/resident/mrxtaskstate.lua#L6), `GetStateDisplayName` [:10](src/resident/mrxtaskstate.lua#L10) (asserts on unknown).

#### `mrxtask.lua` — base task node
[mrxtask.lua](src/resident/mrxtask.lua) · imports MrxGui, MrxLayerManager, MrxTaskState, MrxTimer, MrxUtil.

- `Create`/`Cleanup`/`CreateChild` [:7,15,72](src/resident/mrxtask.lua#L7) — tree + dynamic-module teardown (`dynamic_remove`).
- `Activate(tSaveData)` [:281](src/resident/mrxtask.lua#L281) — resets state, `dynamic_import`s `sModuleName` then `_ModuleLoaded`, else `LoadAssets`.
- `LoadAssets`/`AssetsLoaded` [:309,321](src/resident/mrxtask.lua#L309) — adds `tConfig.tLayers` via `MrxLayerManager.Add` then `Activated`.
- `Activated` [:80](src/resident/mrxtask.lua#L80) — sets `_knActive`, issues callbacks, starts optional `MrxTimer` (`nTimeLimit`/`tTimerParams`, default done = `Cancel`).
- `Complete`/`Cancel` [:113,124](src/resident/mrxtask.lua#L113) — Cleanup + set state + issue callbacks.
- `Configure`/`AddCallback`/`IsLiveConfigureable` [:223,255,54](src/resident/mrxtask.lua#L54) — only `tOn{Activate,Complete,Cancel}`/`fOn…` are live-configurable on an active task.
- `_SetState`/`_IssueStateChangeCallbacks`/`_SetChildrenState` [:135,151,185](src/resident/mrxtask.lua#L135).
- Tree: `_AddChild`/`_RemoveChild`/`GetChild`/`GetChildren`/`GetLineage` [:336-386](src/resident/mrxtask.lua#L336).
- `SaveInstance`/`_GetSaveData`/`_SetSaveData` [:388-407](src/resident/mrxtask.lua#L388) — persists `nState` + copy of save data.
- `_GetRewards` default `{nCash=0,nFuel=0}` [:409](src/resident/mrxtask.lua#L409); `_CreateEvent`/`_CreatePersistentEvent` track handles for cleanup [:417,423](src/resident/mrxtask.lua#L417).

#### `mrxmissionflow.lua` — mission unlock/accept/reward orchestration
[mrxmissionflow.lua](src/resident/mrxmissionflow.lua) · imports MrxCheatBootstrap, MrxFactionManager, MrxLayerManager, MrxTask, MrxTaskState, MrxPlayState, MrxRewardData, MrxStarterManager, MrxState, MrxUtil, Wif{Mission,Starter,Hq}Data, WifPmcInterior, MrxUnlockFanfare, MrxStatsManager, WifMissionFlow, WifRecommendationData, MrxHqManager.

Key entry points: `UnlockMission` [:115](src/resident/mrxmissionflow.lua#L115), `DestroyMission` [:396](src/resident/mrxmissionflow.lua#L396), `AcceptMissions` [:567](src/resident/mrxmissionflow.lua#L567), `Refresh` [:512](src/resident/mrxmissionflow.lua#L512) (binding `fPrereq`/`fConseq` evaluator), `Autosave` [:751](src/resident/mrxmissionflow.lua#L751), `Save/LoadSingleton` [:597,609](src/resident/mrxmissionflow.lua#L597). Key/value progression: `AwardKey`/`RemoveKey`/`HasKey`/`GetKeyValue` [:475-510](src/resident/mrxmissionflow.lua#L475). PDA: `AddPdaMissionDetails`/`BuildMissionHeader`/`BuildMissionDescription` [:855,944,964](src/resident/mrxmissionflow.lua#L855). Net toggles: `SetGrappleEnabled`/`SetVehicleDisguiseEnabled`/`NetEventCallback` [:682,711,737](src/resident/mrxmissionflow.lua#L682). Blocking-sequence/autosave gating: `_BeginBlockingSequence`/`_EndBlockingSequence`/`_RefreshComplete` [:812,817,844](src/resident/mrxmissionflow.lua#L812).

#### `mrxbootstrap.lua` — first-frame world bootstrap
[mrxbootstrap.lua](src/resident/mrxbootstrap.lua) · imports MrxSoundBootstrap, MrxFactionManager, MrxGuiBootstrap, MrxLayerManager, MrxSupportData, MrxPlayer, MrxPmc, MrxState, MrxUtil.

- `Start(fCallback, tArgs)` [:14](src/resident/mrxbootstrap.lua#L14) — wires GUI-loaded and local-player-joined callbacks, calls `MrxPlayer.Start()`.
- `_GuiLoaded` [:29](src/resident/mrxbootstrap.lua#L29) — on first GUI load, **`MrxState.Enter(STATE_WAITFORGAME, _End)`** (if `_bHandleStateTransitions`).
- `_LocalPlayerJoined` [:41](src/resident/mrxbootstrap.lua#L41), `_End` [:49](src/resident/mrxbootstrap.lua#L49) — requires both GUI loaded **and** local player joined; then `MrxState.Exit(STATE_WAITFORGAME)`, faction setup, default atmosphere for non-`vz` levels, optional `StartWithResources` cheat (10M cash, 9999 fuel).
- `SetDefaultAtmosphere` [:77](src/resident/mrxbootstrap.lua#L77) — hard-coded atmosphere/bloom/monochrome/contrast for non-VZ levels.

#### `mrxplaystate.lua` — free vs. mission play-state
[mrxplaystate.lua](src/resident/mrxplaystate.lua) · imports MrxHqManager, MrxStarterManager, WifPmcInterior, WifFreePlay, MrxMusic. Enums `_knNull=-1`, `_knFree=0`, `_knMission=1`. `Set`/`Get`/`IsFree` [:27,54,73](src/resident/mrxplaystate.lua#L27), `SetCurrentMission`/`GetCurrentMission` (contracts only) [:58,69](src/resident/mrxplaystate.lua#L58), session timer `GetTotalTimeElapsed`/`StartSessionTimer` [:100,110](src/resident/mrxplaystate.lua#L100).

> **Note:** `IsValidState` [:10](src/resident/mrxplaystate.lua#L10) uses `or` where `and` is intended — it returns true for every input (a decompiled-source quirk, harmless since callers pass valid enums).

#### `mrxrewarddata.lua` — reward tables + dispensing
[mrxrewarddata.lua](src/resident/mrxrewarddata.lua) · imports WifEquipmentData, MrxFactionManager, MrxPmc, MrxSupportData, MrxUnlockFanfare, WifMissionData, WifMissionFlow, MrxUtil. The bulk is the `_tRewards` data table (keyed by mission/milestone id, [:48-1420](src/resident/mrxrewarddata.lua#L48)). Logic: `Init` [:1422](src/resident/mrxrewarddata.lua#L1422) (normalizes support/equipment/stockpile item tuples + back-references mission/faction), `GetRewards` [:1484](src/resident/mrxrewarddata.lua#L1484), `DispenseRewards` [:1531](src/resident/mrxrewarddata.lua#L1531), `GrantRewardKey`/`NetEventCallback` [:1630,1621](src/resident/mrxrewarddata.lua#L1621), `GetWagerData` [:1678](src/resident/mrxrewarddata.lua#L1678) (percentage/min/max wager math, rounds to 1000), reward-string builders [:1726-1937](src/resident/mrxrewarddata.lua#L1726).

#### `mrxbriefing.lua` — starter briefing UI / cinematic flow
[mrxbriefing.lua](src/resident/mrxbriefing.lua) (3099 lines) · imports MrxCinematic, WifEquipmentData, MrxFactionManager, MrxGui, MrxGuiDialogBox, MrxUtil, MrxVoSequence, Wif{Briefing,Mission,Hq,Starter,Recommendation}Data, WifMissionFlow, WifPmcInterior, MrxPlayState, MrxState, MrxTransit, MrxSupportTransit, MrxStarterManager, MrxRewardData, MrxPmc, MrxSoundBanks, MrxShop. Drives the in-HQ briefing: root menu → spiel/cinematic → accept/decline/wager → shop/transit/hint/bribe. **Net-safe asset gating** is what touches the load gate: `NetSafeLoadBriefingAssets`/`NetSafeBriefingAssetsLoaded` `Enter`/`Exit` `STATE_WAITFORGAME` [:178,167](src/resident/mrxbriefing.lua#L167); client `_EndBegin` exits `STATE_WAITFORGAME` [:1313](src/resident/mrxbriefing.lua#L1313). `CHEAP_*` cinematic-type enums at [:25-41](src/resident/mrxbriefing.lua#L25). Asset ref-counting via `_ProcessAsset`/`_CheckAssets` (15s timeouts) [:504,543](src/resident/mrxbriefing.lua#L504).

### 2.2 Mission subclasses (`MrxTaskMission` family)

#### `mrxtaskmission.lua` — mission base
[mrxtaskmission.lua](src/resident/mrxtaskmission.lua) · `inherit("MrxTask")`. `_knContract=0`, `_knJob=1`. `Activated` calls `Graphics.InitTinyGeometry()` [:12](src/resident/mrxtaskmission.lua#L12). `RefreshPdaDisplay` walks children collecting objective descriptions/icons → `WifMissionFlow.AddPdaMissionDetails` [:38](src/resident/mrxtaskmission.lua#L38). `IsContract`/`IsJob` default false; `GetMissionId` = parent (container) name [:76](src/resident/mrxtaskmission.lua#L76); `GetNumCompletions` = flow key value [:72](src/resident/mrxtaskmission.lua#L72).

#### `mrxtaskcontract.lua` — contract task
[mrxtaskcontract.lua](src/resident/mrxtaskcontract.lua) · `inherit("MrxTaskMission")` · imports MrxFactionManager, MrxGui, MrxHqManager, MrxPlayer, MrxPlayState, WifPmcInterior, MrxSoundCategories, MrxActionHijack, MrxMusic, MrxState, MrxStatsManager, MrxParkingLotManager, MrxGuiInterface.

- `AssetsLoaded` [:33](src/resident/mrxtaskcontract.lua#L33) — `MrxState.AddGlobalExitCallback(self.Activated, …)` (defers activation until the global gate is fully open).
- `Activated` [:41](src/resident/mrxtaskcontract.lua#L41) — `MrxPlayState.Set(_knMission)`, set current mission, contract music, max-health heroes, **`_Checkpoint`**, faction-hostile cancel watcher, `Pg.ContractActivated`.
- `Complete`→`Complete1`→`Complete2` [:103,123,134](src/resident/mrxtaskcontract.lua#L103) — defers through hijack/HQ/PMC-interior, then fanfare + cash/bonus/total ledger (sets `nCashOverride`/`nCashOverride2`).
- `Cancel`→`Cancel2`→`_DialogBoxDismissed` [:252,278,363](src/resident/mrxtaskcontract.lua#L252) — failure fanfare with retry; retry → `Pg.LoadGame("retry")`, else cancel parent + sickbay/medevac handling.
- `_Checkpoint` [:418](src/resident/mrxtaskcontract.lua#L418) — checkpoint-save-mode → `Pg.SaveGame("retry")` + optional autosave + `[Generic.CheckpointReached]` message.
- `NETEVENT_CLIENTPAUSE=0` / `NetEventCallback` [:475,477](src/resident/mrxtaskcontract.lua#L475).

#### `mrxtaskcontractoutpost.lua` — outpost-capture contract
[mrxtaskcontractoutpost.lua](src/resident/mrxtaskcontractoutpost.lua) · `inherit("MrxTaskContract")`. Loads pristine/staging/defense layers, proximity tutorial (100u radius, 6s message cadence, 29s loop), `Complete` swaps staging/defense → captured layer + `MrxStatsManager.IncreaseOutpostCapturedCounter`. Config keys: `sOutpostBldg`, `sCapturePt`, `tCapturePts`, `sRivalFaction`, `tDangerousBldgs`, `nStartingHealth`, `nRusherQuota`, `s{Pristine,Staging,Defense,Captured}Layer`.

#### `mrxtaskcontractplaceholder.lua` — stub contract
[mrxtaskcontractplaceholder.lua](src/resident/mrxtaskcontractplaceholder.lua) · `inherit("MrxTaskContract")`. `Activated` → `MrxCinematic.PlaceholderSequence` → auto-`Complete`.

#### `mrxtaskjob.lua` — multi-target job base
[mrxtaskjob.lua](src/resident/mrxtaskjob.lua) · `inherit("MrxTaskMission")` · imports MrxLayerManager, MrxPlayState, MrxRewardData, MrxVoSequence, WifMissionFlow, MrxFactionManager. Per-target layer loading in `LoadAssets` [:9](src/resident/mrxtaskjob.lua#L9), `_TargetComplete` grants `<MissionId>_PerTarget` reward key + per-target milestone keys + checkpoint/autosave [:112](src/resident/mrxtaskjob.lua#L112), nearby-VO weighted-random selection `_PlayRandomVoSequenceFromTable` (supports `[`/`]` range syntax) [:367](src/resident/mrxtaskjob.lua#L367). Defaults: near radius 30, far radius 60, autosave-after-every-target true ([:219-229](src/resident/mrxtaskjob.lua#L219)).

#### Job subclasses
- `mrxtaskjobcollecttype.lua` — collect quota of label-filtered items (objective module `MrxTaskObjectiveDestroy`, `bDspCollectible`), grants `MrxStatsManager.CompleteToolboxPart` + cash, persists collected set.
- `mrxtaskjobdestroyset.lua` — named target set w/ per-target layers (`sTargetLayer`/`sPristineLayer`/`sStagingLayer`/`sDefenseLayer`); near 150 / far 200; `bDspBounty`, PDA icon `icon_destroy_3_mc`.
- `mrxtaskjobdestroytype.lua` — label-filtered standing bounty (`[Generic.StandingBounty]`), `_SetHeroOnly`, no autosave, `bDspMsgUpd=false`.
- `mrxtaskjobverifyset.lua` — HVT set, objective module `MrxTaskObjectiveVerify`, fanfare `hvtcapture`/`hvtkill`, Fiona verification VO (`Fiona.Misc.Verification01/02`), `MrxRewardData.EnableCashRewardHalving` around kills; near 150 / far 200; PDA icon `icon_verify_3_mc`.

#### `mrxtaskrace.lua` — checkpoint race
[mrxtaskrace.lua](src/resident/mrxtaskrace.lua) · `inherit("MrxTask")`. `kTYPE_GATE=1`, `kTYPE_RING=2`; net events `NETEVENT_MARKLOC=0`/`UNMARKLOC=1`/`MARKFINISH=2`; world-blip near 200 / far 300; default width 10, tripwires on. Builds a `MrxTaskObjectiveDeliver` per checkpoint, records best time via `MrxStatsManager.RecordBestTime`.

### 2.3 Objective subclasses (`MrxTaskObjective` family)

#### `mrxtaskobjective.lua` — objective base
[mrxtaskobjective.lua](src/resident/mrxtaskobjective.lua) · `inherit("MrxTask")` · imports MrxUtil, MrxGuiInterface, MrxVoSequence. Core machinery for all objectives: target `ObjectFilter` ([:18](src/resident/mrxtaskobjective.lua#L18)), quota tracking (`_nCompleted`/`_nQuota`/`_nTotal`/`_nCancelled`), blip/marker display (radar/PDA/world), and objective messages. Key: `Activated` [:7](src/resident/mrxtaskobjective.lua#L7) (builds filter, sets up targets, pulsates blips, prints `add`/`bonus_add` message), `CompletePart`/`CancelPart` [:163,199](src/resident/mrxtaskobjective.lua#L163) (drive quota, message type, auto-Complete/Cancel), `IsQuotaMet` (`_nCompleted == _nQuota`) [:217](src/resident/mrxtaskobjective.lua#L217), `_RefreshTargetDisplay` [:387](src/resident/mrxtaskobjective.lua#L387) (add/update/remove radar+world+PDA blips; logs `ADDED/UPDATING/REMOVING … OBJECTIVE`), `GetObjectiveDescription` [:652](src/resident/mrxtaskobjective.lua#L652) (`(n/q)` progress formatting). Const `_knMarkerYClampDistance=32` [:5](src/resident/mrxtaskobjective.lua#L5); world-blip near/far default 5/175; radar icon size 10.67/8.

#### Objective subclasses (one-liners + key constants)
| Module | Inherits | Behavior | Notable consts / log markers |
|--------|----------|----------|-------------------------------|
| `mrxtaskobjectiveaction` | MrxTaskObjective | Context-action ("talk") target | action label `[ContextAction.Talk]`, ctx-action prio 2 / dist 200 / type 2; icons `objective_action`/`icon_action_*` |
| `mrxtaskobjectiveaccept` | MrxTaskObjectiveAction | Confirm dialog before accept | dialog default `[Generic.Accept]?`, Yes/No |
| `mrxtaskobjectiverelease` | MrxTaskObjectiveAction | Free subdued prisoner | nearby radius `_knTgtNearbyRadius=100`, label `[ContextAction.ReleasePrisoner]`, relation 0/-100, infraction 5; log `^^^^ No faction found???` |
| `mrxtaskobjectivecaptureoutpost` | MrxTaskObjective | Outpost status → complete/cancel | uses `MrxOutpostManager.knStatusCaptured/Destroyed`; icons `objective_outpost` |
| `mrxtaskobjectivedestroy` | MrxTaskObjective | Kill target (death/ClientKill event) | `bHeroOnly` flag; icons `objective_destroy` |
| `mrxtaskobjectiveprotect` | MrxTaskObjective | Fail if target dies | `bHeroOnly`; icons `objective_defend` |
| `mrxtaskobjectiveentervehicle` | MrxTaskObjective | Player enters seat | seat default `"d"`, `"a"` if `bUseAnySeat` |
| `mrxtaskobjectivedeliver` | MrxTaskObjective | Escort player/NPC/object/vehicle to dest | defaults `fDist=5`, `bStop=true`, `bHumansFollow=true`; disc counter wraps 8192; net `EXITVEHICLE=0/UNWINCH=1/CLEARTUTORIAL=5`; logs `OnAttachment change:`, `OBJECT WINCHED state` |
| `mrxtaskobjectiveextract` | MrxTaskObjective | Heli pickup of NPC (state machine) | heli-near 40, enter-delay 2s, failsafe 50s, far 70, heal thresh -25, complete +4s; logs `The Extaction heli arrived`, `Extraction heli was destroyed!` |
| `mrxtaskobjectiveverify` | MrxTaskObjective | HVT subdue/kill + verify anim/extract | HVT enums `HVTNORMAL=1…HVTDEAD=7`, `NETEVENT_VERIFY=0`, prox 10, out-of-range 150 / recover 140, verify cam 2s; extraction freebie per faction; logs `HeroProximity:`, `CENSORED!!!!`, `You got too far from the HVT` |

### 2.4 Starters, HQ, managers, support, tutorials

| Module | Purpose |
|--------|---------|
| `mrxstarter.lua` ([src](src/resident/mrxstarter.lua)) | A briefing-giver NPC: offered-briefings table, intros, accepted/pending state, async `Load`/`Unload` of actors/layers/faceFX (15s asset timeouts), `End` exits HQ/PMC-interior. `GetPmcName` maps boss starters → Fiona/Ewan/Misha/Eva. |
| `mrxstartermanager.lua` ([src](src/resident/mrxstartermanager.lua)) | `_tStarters` registry: `RequestStarter`/`CreateStarter`/`DestroyStarter`, index↔name mapping for net, save/load singleton, recruits heli-pilot/mechanic/jet-pilot. |
| `mrxhq.lua` ([src](src/resident/mrxhq.lua)) | HQ interior + portal: `RefreshUiDisplay`, `SetPortal`, multi-phase `_KickoffStarter` loader (signals 1/2/3), `GlobalEnter`/`GlobalExit`. Uses `MrxState.Enter/Exit(STATE_WAITFORGAME)` around interior/briefing-asset loads. Default draw distance 50. |
| `mrxhqmanager.lua` ([src](src/resident/mrxhqmanager.lua)) | HQ registry, `UnlockHq`/`LockHq`/`LockAllHq`/`UnlockAllHq`, building-death → relation -100 + respawn-on-hibernation, `IsInside`/`SetInside`/`SetUnloadCallback`. |
| `mrxverifymanager.lua` ([src](src/resident/mrxverifymanager.lua)) | Cross-mission HVT tracker (`alive`/`killed`/`captured` per target, per faction), achievements *Justice for All* / *Techno Viking*, `SetSolanoVerified`. |
| `mrxtutorial.lua` ([src](src/resident/mrxtutorial.lua)) | Base tutorial: `ActivateTutorial`/`EndTutorial`, default 20s completion timeout. |
| `mrxtutorialmanager.lua` ([src](src/resident/mrxtutorialmanager.lua)) | Registry of ~24 tutorials → `WifTutorial*` modules, `ShowMessage`/`HideMessage` (net-synced), save/load completed set. |
| `mrxmultipagemenu.lua` ([src](src/resident/mrxmultipagemenu.lua)) | Paginated dialog (`_knMaxOptionsPerPage=8`), Next/Previous-page injection, cancel-button binding. |
| `mrxmissionboundary.lua` ([src](src/resident/mrxmissionboundary.lua)) | "Leave the mission area" boundary/range watcher with warn(15s)/fail(30s) timers (`iTray=3`), region or point+radius modes, VO on exit/return/warn. |

### 2.5 Specialty mission/support scripts (dynamically-imported per mission)

| Module | Purpose / key constants |
|--------|--------------------------|
| `mrxactionhijack.lua` ([src](src/resident/mrxactionhijack.lua)) | Vehicle-hijack minigame state machine (press/hold/tap/alternate + ragdoll). Rulesets `RULESET_TANK=0`, `RULESET_HELICOPTER=1`, `RULESET_APC=2`, `RULESET_SOLANO=nil`; `tDifficulty` timing table; `nVehicleAnimBlendTime=0.2`. `IsInHijack`/`SetUnloadCallback` consulted by `MrxTaskContract.Complete`. |
| `mrxartilleryattack.lua` ([src](src/resident/mrxartilleryattack.lua)) | Staggered falling-ordnance strike. Defaults shells 5, distance 10, time 4, template `Artillery Shell`, drop height +250, first delay 5s. |
| `mrxchicon001rescue.lua` ([src](src/resident/mrxchicon001rescue.lua)) | `inherit("MrxSupportPickup")` rescue-copter freebie: smoke designator dropzone, lands & extracts prisoners within 60m (min 1), 2s land delay. |
| `mrxoilcon002delivery.lua` ([src](src/resident/mrxoilcon002delivery.lua)) | `inherit("MrxSupportDelivery")` listening-post delivery to 3 fixed posts (A/B/C), 30m validation, `NETEVENT_SETDELIVERYLOCATIONS=0`. |
| `mrxshootinggallery.lua` ([src](src/resident/mrxshootinggallery.lua)) | Confines players to a border; strips/returns weapons, fire-locks outside boundary; client setup on `WaitForTether` exit. |

---

## 3. Defaults & tunables table

### MrxState (load gate)
| Symbol | Value | Ref |
|--------|-------|-----|
| `STATE_NONE / CINEMATIC / WAITFORSTREAMING / WAITFORTETHER / WAITFORGAME` | 0 / 1 / 2 / 3 / 4 | [mrxstate.lua:7](src/resident/mrxstate.lua#L7) |
| `_bEnableFade` | true | [:74](src/resident/mrxstate.lua#L74) |
| `_bUseQuickFade` | false | [:75](src/resident/mrxstate.lua#L75) |
| `_nQuickFadeOutTime` | 0.1 | [:76](src/resident/mrxstate.lua#L76) |
| `_nQuickFadeInTime` | 0.5 | [:77](src/resident/mrxstate.lua#L77) |
| `_nLongFadeOutTime` | 1.1 | [:78](src/resident/mrxstate.lua#L78) |
| `_nLongFadeInTime` | 1.1 | [:79](src/resident/mrxstate.lua#L79) |
| per-state `nRefCount` init | 0 | [:19](src/resident/mrxstate.lua#L19) |
| audio duck on enter | 0.5 | [:97](src/resident/mrxstate.lua#L97) |

### Task / playstate enums
| Symbol | Value | Ref |
|--------|-------|-----|
| `MrxTaskState._knLatent/_knActive/_knCompleted/_knCancelled` | 0/1/2/3 | [mrxtaskstate.lua:1](src/resident/mrxtaskstate.lua#L1) |
| `MrxTaskMission._knContract/_knJob` | 0/1 | [mrxtaskmission.lua:9](src/resident/mrxtaskmission.lua#L9) |
| `MrxPlayState._knNull/_knFree/_knMission` | -1/0/1 | [mrxplaystate.lua:6](src/resident/mrxplaystate.lua#L6) |
| `MrxTask._GetRewards` default | `{nCash=0,nFuel=0}` | [mrxtask.lua:409](src/resident/mrxtask.lua#L409) |

### Mission flow net events
| Symbol | Value | Ref |
|--------|-------|-----|
| `NETEVENT_SETGRAPPLE` | 0 | [mrxmissionflow.lua:21](src/resident/mrxmissionflow.lua#L21) |
| `NETEVENT_AUTOSAVE` | 1 | [:22](src/resident/mrxmissionflow.lua#L22) |
| `NETEVENT_SETVEHICLEDISGUISE` | 2 | [:23](src/resident/mrxmissionflow.lua#L23) |
| default mission layer | `"Vz_State_"..sMissionName` | [:249](src/resident/mrxmissionflow.lua#L249) |
| mission task name suffix | `..."Mission"` / `..."Briefing"` | [:246,361](src/resident/mrxmissionflow.lua#L246) |
| `bBlockingSequence` default | true | [:348](src/resident/mrxmissionflow.lua#L348) |

### Reward tiers (`mrxrewarddata.lua` [:9-47](src/resident/mrxrewarddata.lua#L9))
| Tier | Cash | Fuel | Mood |
|------|------|------|------|
| none | 0 | 0 | 0 |
| chapter_one_tiny | 5,000 | 5 | 5 |
| chapter_one_small | 100,000 | 100 | 25 |
| chapter_one_medium | 300,000 | 250 | 50 |
| chapter_one_large | 500,000 | 500 | 75 |
| chapter_one_boss | 750,000 | 1,000 | 100 |
| chapter_two_tiny | 50,000 | 10 | 5 |
| chapter_two_small | 500,000 | 200 | 25 |
| chapter_two_medium | 1,000,000 | 500 | 50 |
| chapter_two_large | 2,000,000 | 1,000 | 75 |
| chapter_two_boss | 2,000,000 | 2,500 | 100 |

Wager rounds to nearest 1,000 ([:1680](src/resident/mrxrewarddata.lua#L1680)); `EVENT_GRANTREWARDKEY=0` ([:1610](src/resident/mrxrewarddata.lua#L1610)); `StartWithResources` cheat grants 10,000,000 cash / 9999 fuel ([mrxbootstrap.lua:65](src/resident/mrxbootstrap.lua#L65)).

### Briefing cinematic-type enums (`mrxbriefing.lua` [:25-41](src/resident/mrxbriefing.lua#L25))
`CHEAP_GREETING=1, SPECIALCASEGREETING=2, STARTINTRO=3, JOBREQUEST=4, JOBACCEPT=5, JOBDECLINE=6, WAGERBEGINWIN=7, WAGERBEGINLOSE=8, WAGERWON=9, WAGERLOST=10, WAGERCHICKENSUIT=11, HINT=12, GOODBYE=13, CONFIRM=14, DECLINE=15, INTRO=16, PMCWAGER=17`. Asset-load timeout 15s.

### Objective / job / boundary tunables
| Symbol | Value | Module |
|--------|-------|--------|
| `_knMarkerYClampDistance` | 32 | mrxtaskobjective |
| world-blip near / far | 5 / 175 | mrxtaskobjective |
| job near / far radius (base) | 30 / 60 | mrxtaskjob |
| destroyset / verifyset near / far | 150 / 200 | mrxtaskjob* |
| outpost proximity radius | 100 | contractoutpost / release (100) |
| outpost tutorial cadence / loop | 6s / 29s | contractoutpost |
| extract heli-near / far / failsafe / heal / +complete | 40 / 70 / 50s / -25 / 4s | objectiveextract |
| verify HVT enums | 1..7 | objectiveverify |
| verify out-of-range / recover / cam | 150 / 140 / 2s | objectiveverify |
| boundary warn / fail / tray | 15s / 30s / 3 | missionboundary |
| multipage menu max/page | 8 | multipagemenu |
| tutorial default timeout | 20s | mrxtutorial |
| HQ default draw distance | 50 | mrxhq |
| starter asset timeout | 15s | mrxstarter |
| hijack blend / rulesets | 0.2 / TANK=0,HELI=1,APC=2 | actionhijack |
| artillery shells/dist/time/height | 5/10/4/+250 | artilleryattack |
| rescue pickup radius / delay | 60 / 2s | chicon001rescue |
| delivery validation dist | 30m | oilcon002delivery |

---

## 4. Logic & formulas

### 4.1 The global-exit gating formula
`_AttemptGlobalExit` ([mrxstate.lua:287](src/resident/mrxstate.lua#L287)) only opens the gate when, **for every state**, `nRefCount == 0 and not bLocked`. A single state stuck at `nRefCount >= 1` blocks fade-in and player input forever. The matching trace lines:
```
@@@@@@@@@@ MrxState._AttemptGlobalExit
@@@@@@@@@@ MrxState._AttemptGlobalExit:  state STATE_WAITFORGAME still active .. (refcount=1,bLocked=false)
```
This is the canonical "load hung but no crash" signature.

### 4.2 Enter/Exit refcount pairing
- `Enter` increments `nRefCount` and queues an enter-complete + ready-to-exit callback ([:222-226](src/resident/mrxstate.lua#L222)).
- `Exit` decrements; runs `state.Exit()` exactly at 0 ([:280](src/resident/mrxstate.lua#L280)).
- Calls made while `_bGloballyFading` are **deferred** into `_tGlobalEnterCallbacks` and replayed by `_CompleteEnter` — so an `Enter`/`Exit` issued during a fade is not lost, just reordered.
- `WAITFORTETHER` is special-cased: `_StateComplete` zeroes its refcount outright ([:183](src/resident/mrxstate.lua#L183)).

### 4.3 Briefing → mission activation chain (releases the gate)
```
_OnBriefingComplete  (mrxmissionflow.lua:309)
  → MrxState.Enter(STATE_WAITFORSTREAMING, oMission.Activate, {oMission, tSaveData})   (:324)
        → oMission:Activate → LoadAssets (layers) → AssetsLoaded
              → fOnAssetsLoaded = _OnAssetsLoaded   (:261)
                    → MrxState.Exit(STATE_WAITFORSTREAMING)   (:262)
                    → MrxState.Exit(STATE_WAITFORGAME)        (:263)
```
If `_OnAssetsLoaded` never fires (e.g. a layer in `tLayers` never finishes streaming), the two `Exit`s never run and the gate stays closed. `MrxTaskContract.Activated` is itself deferred behind `MrxState.AddGlobalExitCallback` ([mrxtaskcontract.lua:37](src/resident/mrxtaskcontract.lua#L37)), so it only runs once the gate has fully opened.

### 4.4 Objective completion criteria
- Each `CompletePart` increments `_nCompleted`; `IsQuotaMet = (_nCompleted == _nQuota)` ([mrxtaskobjective.lua:217](src/resident/mrxtaskobjective.lua#L217)). Quota defaults to total target count, overridable by `tConfig.nQuota` ([:276-279](src/resident/mrxtaskobjective.lua#L276)).
- `CancelPart` increments `_nCancelled`; if `_nQuota > _nTotal - _nCancelled` (quota can no longer be met) the objective `Cancel`s ([:205](src/resident/mrxtaskobjective.lua#L205)).
- Quota met → `self:Complete()`, which Cleanups, sets `_knCompleted`, and refreshes the ancestor mission's PDA.

### 4.5 Milestone / key progression
On container complete ([mrxmissionflow.lua:171-185](src/resident/mrxmissionflow.lua#L171)): jobs award **all** milestone keys whose key isn't yet held; contracts award the milestone whose `nMilestone == nCompletions` (the completion count from `GetKeyValue`). Jobs also award `<MissionId>_PerTarget` and per-target milestone keys inside `_TargetComplete` ([mrxtaskjob.lua:138,157](src/resident/mrxtaskjob.lua#L138)).

### 4.6 Refresh / blocking-sequence / autosave
`Refresh` ([:512](src/resident/mrxmissionflow.lua#L512)) iterates `_tFlowData` bindings, firing `fConseq()` for any whose `fPrereq()` is true, culling non-recurring bindings, and **re-entering itself** if any action was taken (fixpoint). It is wrapped in `_BeginBlockingSequence`/`_EndBlockingSequence`; the autosave (`Pg.SaveGame("autosave")`) only fires when the blocking-sequence counter returns to 0 and `_bDoMissionAutosave` is set ([:817](src/resident/mrxmissionflow.lua#L817)). Key awards during a refresh are **deferred** into `_tDeferredKeyAwards` and replayed after ([:476,547](src/resident/mrxmissionflow.lua#L476)).

---

## 5. Logging & debug markers (world-load log signals)

These are the exact `Debug.Printf` strings useful for log-based load debugging. The `MrxState` ones are the load-gate ground truth.

**MrxState (the gate):**
- `###! GlobalEnter - Begin` ([:82](src/resident/mrxstate.lua#L82))
- `###! GlobalEnter - Complete` ([:251](src/resident/mrxstate.lua#L251)) ← deepest "enter done" marker
- `###! GlobalExit - Begin` ([:117](src/resident/mrxstate.lua#L117))
- `###! GlobalExit - Complete` ([:159](src/resident/mrxstate.lua#L159)) ← gate fully opened
- `Quick Fading-Out... / Long Fading-Out... / Quick Fading-In... / Long Fading-In...` ([:85,90,125,131](src/resident/mrxstate.lua#L85))
- `@@@@@@@@@@ MrxState._StateComplete:  state <name>, about to _AttemptGlobalExit` ([:181](src/resident/mrxstate.lua#L181))
- `@@@@@@@@@@ MrxState.Enter: state <name> (refcount=N)` ([:223](src/resident/mrxstate.lua#L223))
- `@@@@@@@@@@ MrxState.Exit: state <name> (refcount=N)` ([:278](src/resident/mrxstate.lua#L278))
- `@@@@@@@@@@ MrxState.Exit: UNPAIRED EXIT to state <name>` ([:260](src/resident/mrxstate.lua#L260)) ← over-exit bug signal
- `@@@@@@@@@@ MrxState._AttemptGlobalExit` ([:288](src/resident/mrxstate.lua#L288))
- `@@@@@@@@@@ MrxState._AttemptGlobalExit: not globally locked, bailing out` ([:290](src/resident/mrxstate.lua#L290))
- `@@@@@@@@@@ MrxState._AttemptGlobalExit:  state <name> still active .. (refcount=N,bLocked=…)` ([:296](src/resident/mrxstate.lua#L296)) ← **the hang line**
- `@@@@@@@@@@ MrxState._AttemptGlobalExit: all states exited; success` ([:302](src/resident/mrxstate.lua#L302))
- `@@@@@@@@@@ MrxState.PrintStatus: …` / `no active states` ([:333,338](src/resident/mrxstate.lua#L333))
- `@@@@@@@@@@ MrxState.EnableFade: bEnable=…` ([:325](src/resident/mrxstate.lua#L325))

**Bootstrap:** `gui loaded` ([mrxbootstrap.lua:30](src/resident/mrxbootstrap.lua#L30)), `local player joined` ([:42](src/resident/mrxbootstrap.lua#L42)), `Atmosphere: default (non-VZ) settings` ([:78](src/resident/mrxbootstrap.lua#L78)).

**Task tree:** `Cleaning up <lineage>`, `_SetState "<lineage>" <state>`, `Task "<lineage>" complete` / `cancelled`, `Adding <child> as a child of <parent>`, `Dynamically imported module <name>`, `Activation of task <name> FAILED; already activated` ([mrxtask.lua:16,142,118,339,298,82](src/resident/mrxtask.lua#L16)).

**Mission flow:** `Unlocking mission <name>`, `Mission "<name>" unlock attempt FAILED; …`, `Setting flow data (N bindings)`, `Refreshing (N bindings)...`, `Executing action (binding "<k>") based on fulfilled prereqs.`, `Culling binding "<k>"`, `@@@@@@@@@@ _TrackMission: …`, `@@@@@@@@@@ _EndBlockingSequence: _bDoMissionAutosave=…`, `@@@@@@@@@@ MrxMissionFlow._RefreshComplete: …` ([mrxmissionflow.lua:132,120,104,527,534,537,59,821,847](src/resident/mrxmissionflow.lua#L59)).

**Contract:** `We are starting End Sequence, Setting ActionHijack false`, `In Hijack - Complete paused`, `Not in Hijack`, `FanFare Begining`, `Task "<lineage>" complete`/`cancelled` ([mrxtaskcontract.lua:108,114,117,249](src/resident/mrxtaskcontract.lua#L108)).

**Briefing:** `_bBriefingAssetsLoaded = true` / `= nil` ([mrxbriefing.lua:166,180](src/resident/mrxbriefing.lua#L166)), `@ Loading asset <key> (N)` / `@ Unloading asset …` / `@!! … timed-out`, `Ending Cinematic`, `Starting briefing <id>`, `Briefing mode: …` ([:520,533,1267,914,949](src/resident/mrxbriefing.lua#L520)).

**HQ:** `@@@@@@@@@@ Enabling/Disabling <hq> portal`, `@@@@@@@@@@ MrxHq._KickoffStarter: starter loaded / teleport complete / generic assets loaded` ([mrxhq.lua:394,684](src/resident/mrxhq.lua#L394)).

(Per-mission/objective scripts add many more — see §2.3/§2.5 tables; the delivery/extract/verify/hijack markers are listed there.)

---

## 6. Cross-references

### Into other groups / native bindings (high-traffic)
- **`Sys.*`** — `RequestGameState("WaitForStreaming"/"WaitForTether")` (the engine streaming gate, [mrxstate.lua:28,45](src/resident/mrxstate.lua#L28)), `RequestAutosave`, `GetLevelName`, `StartWithResources`, `GetForceNewGame`, `TimeStamp*`.
- **`Event.*`** — `GameStateChange` (state-exit signal), `TimerRelative`, `ObjectProximity`, `ObjectDeath`, `Boundary`, `ObjectInSeat`, `ScriptEvent "mpPlayerJoin"`, `ObjectIsReady`/`ObjectHibernation`.
- **`Pg.*`** — `LoadAsset`/`UnloadAsset`, `SaveGame`/`LoadGame("retry"/"autosave")`, `GetGuidByName`, `ContractActivated`/`ContractCompleted`/`ContractCancelled`, `LoadingStaticLayers`.
- **`Net.*`** — `IsServer`/`IsClient`, `SendCustomEvent`, `SendEvent_AddPDAMission`/`RemovePDAMission`/`AddMarkerObjective`/…, `SetLoadingScreen`, `SetBriefingStarters`, `LoadMissionSpiel`.
- **`MrxLayerManager`** — `Add`/`Remove`/`MarkForRemoval`/`ProcessMarkedLayers` (mission `tLayers` streaming — the thing that must finish for the gate to release).
- **`Wif*` data tables** — `WifMissionData.tMissionData` (mission config source), `WifStarterData`, `WifBriefingData`, `WifHqData`, `WifMissionFlow` (binding/flow data), `WifRecommendationData`, `WifEquipmentData`, `WifPmcInterior`.
- **Sibling Mrx modules** — `MrxRewardData`, `MrxStarterManager`, `MrxHqManager`, `MrxPlayState`, `MrxFactionManager`, `MrxStatsManager`, `MrxMusic`, `MrxVoSequence`, `MrxUnlockFanfare`, `MrxSupportData`, `MrxCheatBootstrap`, `MrxTutorialManager`, `MrxLayerManager`, `MrxTimer`, `MrxUtil`.

### Module-to-MrxState touch-points (who opens/closes the gate)
| Caller | Enters | Exits |
|--------|--------|-------|
| `mrxbootstrap._GuiLoaded`/`_End` | WAITFORGAME | WAITFORGAME |
| `mrxmissionflow._OnBriefingComplete` / `_OnAssetsLoaded` | WAITFORSTREAMING | WAITFORSTREAMING + WAITFORGAME |
| `mrxbriefing.NetSafeLoadBriefingAssets` / `_EndBegin` (client) | WAITFORGAME | WAITFORGAME |
| `mrxhq._OnEnter` / `NetSafeLoadAssets` / `ExitEnd` | WAITFORGAME | WAITFORGAME |
| `mrxstarter.End` (PMC, no accept) | — | WAITFORGAME |
| `mrxtaskcontract.AssetsLoaded` | — (defers `Activated` via `AddGlobalExitCallback`) | — |

---

## 7. Future-dev / modding notes

### How a mission registers and runs
1. Author adds an entry to `WifMissionData.tMissionData[<MissionId>]` (config: `sModuleName`, `sStarter`, `sFactionId`, `tLayers`, `tMilestones`, `bRepeatable`, `tStartLocations`, …) plus reward rows in `MrxRewardData._tRewards` and (optionally) `WifBriefingData[<MissionId>]`.
2. Progression bindings in `WifMissionFlow` (a `{fPrereq, fConseq, bRecurring}` table) call `MrxMissionFlow.UnlockMission(<MissionId>)` once prereqs (held keys) are satisfied; `Refresh` is the fixpoint evaluator that fires them.
3. `UnlockMission` builds container + mission (+ briefing) `MrxTask` nodes; the per-mission `sModuleName` (e.g. `MrxTaskContractOutpost`, `MrxChiCon001Rescue`) is `dynamic_import`ed and set as the node's metatable, so the mission script just overrides `Activated`/`LoadAssets`/`Complete`/etc.
4. The mission's layers stream in; `fOnAssetsLoaded` exits the load gate; `MrxTaskContract.Activated` (deferred to the global-exit callback) flips playstate to mission and takes a checkpoint.

### Non-obvious gating — why DLC missions can hang on streaming
The load gate ([§4.1](#41-the-global-exit-gating-formula)) opens only when **every** `MrxState` refcount is 0. The DLC failure modes that strand it:

- **A `tLayers` entry never finishes streaming.** `MrxState.Enter(STATE_WAITFORSTREAMING, oMission.Activate, …)` is paired with the `Exit` inside `_OnAssetsLoaded`, which only runs after `MrxLayerManager.Add(tConfig.tLayers, AssetsLoaded, …)` calls back. If a converted/missing/oversized DLC layer (e.g. a `Vz_State_<Mission>` block whose streamed body the engine can't size) never signals "loaded", `_OnAssetsLoaded` never fires → `STATE_WAITFORSTREAMING` stays at refcount 1 → `_AttemptGlobalExit` logs `state STATE_WAITFORSTREAMING still active (refcount=1)` indefinitely. This is the same class as the documented engine streaming `BUFFER_TOO_SMALL` chain — the Lua side is just the visible "hang", the real cause is the streamed layer body.
- **`STATE_WAITFORGAME` never released.** Bootstrap's `_End` exits WAITFORGAME only when **both** `_bGuiLoaded` and `_bLocalPlayerJoined` are true ([mrxbootstrap.lua:49](src/resident/mrxbootstrap.lua#L49)). If the local player never spawns (no player char), the `Exit` is skipped → gate stuck at WAITFORGAME refcount 1 with `GlobalEnter Complete` already logged. This matches the "reached 95%/phase-19, GlobalEnter Complete, but STATE_WAITFORGAME never releases, no player spawn" symptom in the project memory: the Lua gate is correct; the missing piece is upstream (player/spawn not signalled), so look at the engine spawn/streaming side, not at adding/removing `Enter`/`Exit` calls here.
- **Over-exit / `UNPAIRED EXIT`.** If a hook or patched module double-exits a state, the `UNPAIRED EXIT` path ([:259](src/resident/mrxstate.lua#L259)) no-ops the extra exit — so it won't crash, but it can mask a missing enter elsewhere. Watch the `refcount=` deltas in the log to confirm every `Enter` has exactly one matching `Exit`.

### Debugging levers already in the code
- `MrxState.PrintStatus()` dumps every still-active state and its refcount — call it (or grep its output) when a load wedges to identify *which* gate is stuck.
- `MrxState.Enter` also logs `Debug.GetCallstack()` ([:224](src/resident/mrxstate.lua#L224)), so each enter/exit carries its origin — use that to attribute a stuck refcount to the exact caller (briefing-asset load vs. mission-layer load vs. HQ portal vs. bootstrap).
- `MrxState.EnableFade(false)` / `SetQuickFade` can be toggled to remove fade timing from the repro while bisecting a hang.
- Mission/briefing asset loads use **15s timeouts** that log `… timed-out` then call the loaded-callback anyway ([mrxbriefing.lua:454](src/resident/mrxbriefing.lua#L454), [mrxstarter.lua:465](src/resident/mrxstarter.lua#L465)) — so briefing/starter asset stalls self-recover after 15s, but **mission `tLayers` loads via `MrxLayerManager.Add` do not have this Lua-side timeout**, which is why a bad streamed mission layer hangs hard rather than timing out.
