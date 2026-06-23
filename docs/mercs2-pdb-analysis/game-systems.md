# Game Systems

Gameplay meta-systems: achievements, stats, economy/cash, rewards, unlocks, missions/contracts/objectives, save/profile, factions, scoring/progression.

Provenance: Symbol/string evidence recovered from the Xbox 360 devkit "Profile" build `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview, PowerPC). Decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. This is symbol/string evidence, NOT a real `.pdb`. Build tree on the dev machine was `d:\projects\ReleaseLine\Mercs2\`.

## Overview

This subsystem covers the gameplay "meta" layer of Mercenaries 2 sitting above the moment-to-moment simulation: persistent player profile/save data, the in-game economy (cash), the contract/mission/objective flow, faction relations and reputation, and the achievement/stats/leaderboard pipeline. Almost all of the symbols are exported names sitting in `.rdata` (string-literal pools), which is consistent with these being Lua-binding/event names and tunable identifiers rather than raw functions. The `SendEvent_*` prefixes and verb-style naming point to a gameplay-systems layer that is heavily Lua- and event-driven.

The one build source path that belongs unambiguously to this area is `Pangea\Src\PgGameSystem.cpp` — the engine "game system" host. The richer back-end evidence (the `achievements.%d.*`, `achiDefs.%d.*`, `histories.%d.*`, `AchievementManagerParameters`, `GetGameSummary`/`AddStats`/`AddAchievements`/`score`/`ranked` strings, and the `fesl.ea.com` host) marks the achievement/stats/leaderboard side as an EA online/Blaze-style telemetry+reporting back-end.

The achievement list itself is concrete: ~30 named achievement IDs (`ACHIEVEMENT_*`) and a matching set of `achievement_*.png` icon assets in `.reloc` confirm the shipped achievement set.

## Source files

From `output/jul08_prototype/mercs2_xenon_p.source_paths.txt` (verbatim):

```
d:\projects\releaseline\mercs2\pangea\Src\PgGameSystem.cpp
```

(No other source path in the recovered list maps cleanly to this system; the achievement/stats back-end source files are not present in the 48-path list.)

## Key classes

No RTTI class in `mercs2_xenon_p.rtti_classes.txt` demangles to a game-systems class (the only `...Save...` RTTI hit, `class hkpSaveContactPointsUtil::EntitySelector`, is Havok physics, not save-games). The class names visible for this subsystem appear only as plain string identifiers, not as RTTI type descriptors:

- `AchievementManager` (0x010d4a0, .rdata) — manager object name (string-only; no RTTI descriptor).

## Symbols by area

Offsets and sections are copied from `output/jul08_prototype/inventory/game-systems.txt`.

### Save / profile persistence

| Offset | Section | Symbol |
|---|---|---|
| 0x0020c78 | .rdata | SaveGame |
| 0x0020a9c | .rdata | NoTRCSave |
| 0x0024c54 | .rdata | SaveSingleton |
| 0x0024ca4 | .rdata | SaveData |
| 0x0024cb0 | .rdata | InitialSaveData |
| 0x0024d90 | .rdata | SaveComplete |
| 0x002c5a4 | .rdata | SetLuaSaveVersion |
| 0x002c6ec | .rdata | GetINILoadLastSave |
| 0x002f958 | .rdata | maximumProfiles |
| 0x002f978 | .rdata | addSaveGame |
| 0x002fee4 | .rdata | autoSave |
| 0x002fd34 | .rdata | deleteSaveGame |
| 0x002fc64 | .rdata | clearSaveGames |
| 0x002fb64 | .rdata | loadProfile |
| 0x002fb50 | .rdata | loadDefaultProfile |
| 0x002fb3c | .rdata | noDefaultProfile |
| 0x002fd08 | .rdata | saveProfile |
| 0x002faf0 | .rdata | AddProfile |
| 0x002fb2c | .rdata | getListProfiles |
| 0x002fac4 | .rdata | EnableUsingFakeProfile |
| 0x002c4f8 | .rdata | HaveActiveProfile |
| 0x002fadc | .rdata | ProfilesComplete |
| 0x002fe14 | .rdata | hasCorruptedSave |
| 0x002fd70 | .rdata | disableManageSaves |
| 0x002fd90 | .rdata | disableSave |
| 0x002f9d8 | .rdata | gameAutoSave |
| 0x003fc78 | .rdata | ProfileHash |
| 0x002b00c | .rdata | SetProfileCostume |
| 0x002b020 | .rdata | GetProfileCostume |
| 0x002b034 | .rdata | SetProfileUpgrade |
| 0x002b048 | .rdata | GetProfileUpgrade |
| 0x002b05c | .rdata | SetProfileCharacter |
| 0x002b070 | .rdata | GetProfileCharacter |
| 0x00316fc | .rdata | ModelMixerProfile |

This is the save-game and player-profile layer. The `Save*`/`Profile*` verbs (`loadProfile`/`saveProfile`/`AddProfile`/`getListProfiles`, `addSaveGame`/`deleteSaveGame`/`clearSaveGames`) and the `maximumProfiles` tunable indicate a multi-slot profile manager. `NoTRCSave` plus the format strings `NoTRCSave%02d.sav` / `ConvertNoTRCSave%02d.sav` (see Notable strings) are the on-disk save filename pattern; "TRC" = Technical Requirements Checklist, i.e. a non-cert/dev save path. `SetLuaSaveVersion` and `ProfileHash` indicate versioning/integrity of the persisted blob; `hasCorruptedSave` + the `File corrupted!` string is the corruption check. `SetProfileCostume/Upgrade/Character` and `ModelMixerProfile` persist the player's character customization. Per-symbol roles beyond the literal verb names are read from the naming.

### Economy / cash

| Offset | Section | Symbol |
|---|---|---|
| 0x002b0bc | .rdata | AddCash |
| 0x002b0c4 | .rdata | SetCash |
| 0x002b0cc | .rdata | GetCash |
| 0x0029e7c | .rdata | GetCashValue |
| 0x0021cec | .rdata | AddCashQty |
| 0x003141c | .rdata | CashValue |

The cash economy. `GetCash`/`SetCash`/`AddCash`/`AddCashQty` are the accessor/mutator API; `CashValue` also appears in the ECS component-pool dump as `CashValue 1024` (a component with a pool, see Notable strings), so cash is modeled as an entity component — and the PC decomp confirms this (see the component-registrar `FUN_006416d0` in the cross-reference section).

### Missions / contracts / objectives

| Offset | Section | Symbol |
|---|---|---|
| 0x002a62c | .rdata | ContractCompleted |
| 0x002a640 | .rdata | ContractCancelled |
| 0x002a654 | .rdata | ContractActivated |
| 0x002f45c | .rdata | sContract |
| 0x001ff48 | .rdata | GetMissionStates |
| 0x0028fbc | .rdata | UnloadMissionSpiel |
| 0x002c710 | .rdata | SetSkipMission |
| 0x002c730 | .rdata | GetSkipMission |
| 0x002fa34 | .rdata | joingameFilterMission |
| 0x0047194 | .rdata | AddPdaMissionDetails |
| 0x00471ac | .rdata | RemovePDAMission |
| 0x0028fe4 | .rdata | SendEvent_RemovePDAMission |
| 0x0029000 | .rdata | SendEvent_AddPDAMission |
| 0x002775c | .rdata | AddObjective |
| 0x0046f60 | .rdata | AddObjectiveToLocalPlayer |
| 0x0046f0c | .rdata | DeleteObjectiveForLocalPlayer |
| 0x0047574 | .rdata | DisplayObjectiveMessage |
| 0x0041290 | .rdata | UpdateObjectiveMarker |
| 0x0031968 | .rdata | RuntimeObjectiveMarker |
| 0x0029514 | .rdata | SendEvent_AddObjective |
| 0x00294f8 | .rdata | SendEvent_RemoveObjective |
| 0x0029460 | .rdata | SendEvent_AddPdaObjective |
| 0x0029440 | .rdata | SendEvent_RemovePdaObjective |
| 0x002949c | .rdata | SendEvent_AddMarkerObjective |
| 0x002947c | .rdata | SendEvent_RemoveMarkerObjective |
| 0x00294dc | .rdata | SendEvent_AddRadarObjective |
| 0x00294bc | .rdata | SendEvent_RemoveRadarObjective |
| 0x002939c | .rdata | SendEvent_ObjectiveMessage |
| 0x0029294 | .rdata | SendEvent_ClearObjectiveTraySlot |
| 0x00292b8 | .rdata | SendEvent_SetObjectiveTraySlotImage |
| 0x00292dc | .rdata | SendEvent_SetObjectiveTraySlotText |

The mission/contract/objective flow. Contracts have a clear lifecycle (`ContractActivated` → `ContractCompleted`/`ContractCancelled`) with a string field `sContract`. Missions are tracked (`GetMissionStates`) and can be skipped in dev (`SetSkipMission`/`GetSkipMission`) and filtered for co-op join (`joingameFilterMission`). Objectives drive the HUD through fire-and-forget events — PDA list (`*PdaObjective`/`AddPdaMissionDetails`), on-screen markers (`*MarkerObjective`, `UpdateObjectiveMarker`, `RuntimeObjectiveMarker`), radar (`*RadarObjective`), and an objective "tray" widget (`*ObjectiveTraySlot*`). The `SendEvent_*` prefix indicates these go through a generic event bus rather than direct calls.

### Factions / reputation

| Offset | Section | Symbol |
|---|---|---|
| 0x001fdf0 | .rdata | SameFaction |
| 0x0039e90 | .rdata | SingleFaction |
| 0x0039ea0 | .rdata | BanFaction |
| 0x0024e60 | .rdata | GetFactionGuid |
| 0x0029204 | .rdata | ApplyCachedFactionRelations |
| 0x002a534 | .rdata | RestrictPursuitFaction |
| 0x00444f3 | .rdata | xPgSysNetFactionRelations |
| 0x002ba28 | .rdata | FactionZone |
| 0x0031438 | .rdata | FactionValue |
| 0x00313dc | .rdata | FactionMarker |
| 0x00275dc | .rdata | SetFactionMarkerSize |
| 0x00275f4 | .rdata | EnableFactionMarkers |
| 0x002760c | .rdata | SetFactionMarkerVisibleDistance |
| 0x002c07c | .rdata | IsFactionLockedMusic |
| 0x002c094 | .rdata | LockFactionMusic |
| 0x002c0a8 | .rdata | SetFactionMusic |
| 0x002c0b8 | .rdata | AddFactionMusic |

Faction relations and reputation. `SameFaction`/`SingleFaction`/`BanFaction`/`GetFactionGuid` identify and compare factions; `ApplyCachedFactionRelations` and `xPgSysNetFactionRelations` indicate faction-relation state that is networked/replicated (in strings nearby: `NetInitializeClientFactionRelations`, `NetClientFactionSetValue`, `NetClientFactionStartPursuit`, `NetClientFactionHideMeter`). `RestrictPursuitFaction` ties into the "heat"/pursuit logic. `FactionValue`/`FactionMarker`/`FactionZone` are ECS components (they show in the component-pool dump, and resolve to component-registrars in the PC decomp — see cross-reference). The `*FactionMusic` set links faction state to the dynamic music system. Reputation-meter semantics are read from the `Net*Faction*` and marker names.

### Achievements

| Offset | Section | Symbol |
|---|---|---|
| 0x002922c | .rdata | GrantAchievement |
| 0x002a5d8 | .rdata | AchievementAddCount |
| 0x002a5ec | .rdata | AchievementIsGranted |
| 0x010d4a0 | .rdata | AchievementManager |
| 0x010cb4c | .rdata | AddAchievements |
| 0x010c51c | .rdata | GetOwnerAchievements |
| 0x010c534 | .rdata | GetOwnerAchievementsByGroup |
| 0x010c550 | .rdata | GetAchievementDefinitions |
| 0x010c56c | .rdata | GetAchievementDefinitionsByGroup |
| 0x010c590 | .rdata | GetAchievementGroupDefinitions |
| 0x010c5b0 | .rdata | GetAchievementHistories |
| 0x010c5c8 | .rdata | GetAchievementHistoriesByGroup |
| 0x010c5e8 | .rdata | SetAchievements |
| 0x010c5f8 | .rdata | UnsetAchievements |
| 0x010c60c | .rdata | SynchAchievements |
| 0x010c620 | .rdata | EvalAchievements |
| 0x010c634 | .rdata | EvalAchievementsByGroup |
| 0x010c64c | .rdata | AchievementStatusChange |

Two tiers are visible. The gameplay-facing tier is `GrantAchievement` / `AchievementAddCount` / `AchievementIsGranted` (count-based and boolean achievements). The back-end tier (offsets clustered around 0x010c5xx, adjacent to the stats back-end below) is a full definitions/history/sync service: define groups (`Get*AchievementGroupDefinitions`), evaluate (`Eval*`), set/unset, and sync to a server. The ~30 shipped achievement IDs and their icons are listed under Notable strings.

### Stats / leaderboards / scoring (online back-end)

| Offset | Section | Symbol |
|---|---|---|
| 0x001eef8 | .rdata | PgStats1 |
| 0x0028af0 | .rdata | DumpStats |
| 0x010cb40 | .rdata | AddStats |
| 0x010ce08 | .rdata | includeStats |
| 0x010cf9c | .rdata | UpdateStats |
| 0x010cfa8 | .rdata | GetStats |
| 0x010cfb4 | .rdata | GetStatsForOwners |
| 0x010cfc8 | .rdata | GetRankedStats |
| 0x010cfd8 | .rdata | GetRankedStatsForOwners |
| 0x010d008 | .rdata | GetTopNAndStats |
| 0x0030e84 | .rdata | LeaderboardScore |

The persistent stats/leaderboard service. `GetRankedStats*` and `GetTopNAndStats` plus `LeaderboardScore` are leaderboard queries; `AddStats`/`UpdateStats`/`GetStats*` are the stat read/write API. This cluster sits in the same `.rdata` region as the achievement back-end and the EA Blaze report vocabulary (`StartReport`/`AddGameSummary`/`AddPlayerInfo`/`AddGameEvents`/`EndReport`, host `fesl.ea.com`), so it is the same online telemetry/reporting subsystem — the PC decomp confirms the report serializers (e.g. `FUN_0097f090` writing the `includeStats` field; see cross-reference). `PgStats1` and `DumpStats` are the local/engine-side stat hooks.

### Rewards / unlocks / progression notifications

| Offset | Section | Symbol |
|---|---|---|
| 0x0028edc | .rdata | HasPlayerUnlockedCode |
| 0x005d664 | .rdata | footUnlockGain |
| 0x00290d4 | .rdata | SendEvent_BatchUnlockFanfare |
| 0x00290f4 | .rdata | SendEvent_UnlockFanfare |
| 0x0029334 | .rdata | SendEvent_RecruitsUnlocked |
| 0x00ac158 | .rdata | onLoadProgress |
| 0x00ad478 | .rdata | getProgress |

The unlock/reward layer. `HasPlayerUnlockedCode` gates content behind cheat/unlock codes; `SendEvent_UnlockFanfare`/`SendEvent_BatchUnlockFanfare`/`SendEvent_RecruitsUnlocked` fire the celebratory UI when something is unlocked. `footUnlockGain` is an animation/state name tied to unlocks. `onLoadProgress`/`getProgress` are progress callbacks (load and/or progression — purpose ambiguous from name alone).

## Notable strings

All copied from `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` unless noted.

Save / profile:
- `(SaveGameData` , `SaveGame`
- `NoTRCSave` , `NoTRCSave%02d.sav` , `ConvertNoTRCSave%02d.sav` — save filename format.
- `File corrupted!` — corruption path (pairs with `hasCorruptedSave`).
- `ifs.loadsave_xbox.save02` … `save19`, `ifs.loadsave_xbox.freemoreblocks`, `ifs.loadsave_xbox.cancel/yes/no` — load/save UI string keys.

Faction:
- `Warning: GetFactionGuid(0x%0x) = 0` — assert/warning when a faction GUID resolves to zero.
- `xPgSysNetFactionRelations`, `NetInitializeClientFactionRelations`, `NetClientFactionSetValue`, `NetClientFactionStartPursuit`, `NetClientFactionHideMeter` — networked faction-relation replication.

ECS component-pool dump entries (`<ComponentName> <size> [<size>]`), confirming these are entity components with allocation pools:
- `CashValue 1024`
- `FactionMarker 1280`
- `FactionValue 64 64`
- `FactionZone 16 16`
- `RtFactionZone 16 16`
- `RuntimeObjectiveMarker 32 32`

Achievements — back-end serialization keys and parameter dump:
- `[achievements]`
- `AchievementManagerParameters:`
- `Achievement #%d  - (Group: %s)(Id: %s)(Xbox360Id: %i [0x%x])` — ties internal achievement IDs to Xbox 360 achievement IDs.
- `OfflineAwardIds: (%d total)`
- `achievements.%d.ownerId` / `.count` / `.name` / `.groupName` / `.date`
- `achiDefs.%d.name` / `.groupName` / `.pos` / `.attribs.{`
- `achiGrpDefs.%d.name` / `.attribs.{`
- `histories.%d.name` / `.groupName` / `.date` / `.expireDate`

Online report/leaderboard back-end (EA Blaze-style), adjacent to the achievement/stats symbols:
- `fesl.ea.com`
- `StartReport`, `AddGameSummary`, `AddTeamInfo`, `AddPlayerInfo`, `AddGameEvents`, `AddGameData`, `AddStats`, `AddAchievements`, `EndReport`, `GetGameSummary`, `GameSummaryUpdateState`
- report fields: `ranked`, `score`, `gameDuration`, `gameMode`, `teamPosition`, `outcome`, `timePlayed`, `disconnectPoint`

Achievement IDs (shipped set, from the `ACHIEVEMENT_*` string block):
`ACHIEVEMENT_MILLIONAIRE`, `ACHIEVEMENT_BILLIONAIRE`, `ACHIEVEMENT_NEVER_SAY_DIE`, `ACHIEVEMENT_SCREAMING_VENGANCE`, `ACHIEVEMENT_BURNOUT`, `ACHIEVEMENT_WHEREVER_I_MAY_ROAM`, `ACHIEVEMENT_HAIL_AND_KILL`, `ACHIEVEMENT_EVERYBODY_WANTSSOME`, `ACHIEVEMENT_PLAY_COOP`, `ACHIEVEMENT_NOTHIN_BUT_GOODTIME`, `ACHIEVEMENT_FLIGHT_OF_ICARUS`, `ACHIEVEMENT_QUICK_OR_DEAD`, `ACHIEVEMENT_HOLY_SMOKE`, `ACHIEVEMENT_LITTLE_SAVAGE`, `ACHIEVEMENT_ARMAGGEDON`, `ACHIEVEMENT_UR_DOING_IT_WRONG`, `ACHIEVEMENT_PIPELINE`, `ACHIEVEMENT_SCHOOLS_OUT`, `ACHIEVEMENT_RAGE`, `ACHIEVEMENT_HELLOHURRAY`, `ACHIEVEMENT_WILD_ONE`, `ACHIEVEMENT_RIDE_DRAGON`, `ACHIEVEMENT_SHOOTTHRILL`, `ACHIEVEMENT_DAMAGE_INC`, `ACHIEVEMENT_NO_COMPROMISE`, `ACHIEVEMENT_RUNNING_WITH_DEVIL`, `ACHIEVEMENT_BETTER_RUN`, `ACHIEVEMENT_ANALOG_KID`, `ACHIEVEMENT_OIL_AND_GAZ`, `ACHIEVEMENT_HERO_AND_MADMAN`, `ACHIEVEMENT_FIRE_AND_STEEL`, `ACHIEVEMENT_BALLS_TO_THE_WALL`. (Note `oACHIEVEMENT_SHOOTTHRILL` also appears.)

Achievement icon assets (`.reloc`, from the inventory file): `achievement_play_coop.png`, `achievement_wild_one.png`, `achievement_wheels_of_steel.png`, `achievement_techno_viking.png`, `achievement_shootthrill.png`, `achievement_schools_out.png`, `achievement_ride_dragon.png`, `achievement_rage.png`, `achievement_quick_or_dead.png`, `achievement_pipeline.png`, `achievement_oil_and_gaz.png`, `achievement_no_compromise.png`, `achievement_never_say_die.png`, `achievement_millionaire.png`, `achievement_little_savage.png`, `achievement_justice_for_all.png`, `achievement_holy_smoke.png`, `achievement_highway_to_hell.png`, `achievement_hero_and_madman.png`, `achievement_hellohurray.png`, `achievement_hail_and_kill.png`, `achievement_gone_shootin.png`, `achievement_forever_free.png`, `achievement_fire_and_steel.png`, `achievement_dirty_deeds.png`, `achievement_digital_man.png`, `achievement_damage_inc.png`, `achievement_burn_the_sky.png`, `achievement_billionaire.png`, `achievement_better_run.png`, `achievement_armageddon.png`, `achievement_analog_kid.png` (icon basenames mostly match the `ACHIEVEMENT_*` ID list — `ACHIEVEMENT_WHEELS_OF_STEEL`, `ACHIEVEMENT_JUSTICE_FOR_ALL`, `ACHIEVEMENT_HIGHWAY_TO_HELL`, `ACHIEVEMENT_GONE_SHOOTIN`, `ACHIEVEMENT_FOREVER_FREE`, `ACHIEVEMENT_DIRTY_DEEDS`, `ACHIEVEMENT_DIGITAL_MAN`, and `ACHIEVEMENT_BURN_THE_SKY` all exist verbatim. The one mismatch is the `armageddon` icon: the ID block has no `ACHIEVEMENT_ARMAGEDDON`; the binary uses the misspelling `ACHIEVEMENT_ARMAGGEDON` instead.)

## PC decompilation cross-reference

These map this system's Xbox symbols/strings to functions in the PC retail decompilation (`output/_ghidra/all_functions_decomp.txt`). The pairing for this system has **no vtable-resolved classes** (this layer is string/Lua-binding driven, not RTTI-class driven — consistent with the symbols being `.rdata` identifiers), so every entry below is a **string-anchored** match. All FUN_ addresses were confirmed by reading the body and verifying it references the cited string.

| Symbol / class | PC function | Bridge | Role | Confidence |
|---|---|---|---|---|
| `CashValue` | `FUN_006416d0` | string | ECS component-descriptor registrar (stores `s_CashValue`) | high (distinctive name + structural pattern) |
| `FactionMarker` | `FUN_00641340` | string | ECS component-descriptor registrar (stores `s_FactionMarker`) | high |
| `FactionValue` | `FUN_00641830` | string | ECS component-descriptor registrar | high |
| `FactionZone` | `FUN_006414b0` | string | ECS component-descriptor registrar | high |
| `RuntimeObjectiveMarker` | `FUN_00645300` | string | ECS component-descriptor registrar | high |
| `ModelMixerProfile` | `FUN_00643a40` | string | ECS component-descriptor registrar | high |
| `SaveData` / `InitialSaveData` | `FUN_005a4520` | string | save-event handler (dispatches on the event name) | high (two distinct anchors converge) |
| `hasCorruptedSave` | `FUN_00614080` | string | save state-machine dispatcher (fires `hasCorruptedSave`/`hasAutosave` triggers) | medium |
| `autoSave` | `FUN_00614540` | string | autosave dispatcher (matches `s_autoSave`) | medium |
| `getProgress` | `FUN_007b2af0` | string | progress query | low (generic name) |
| `includeStats` | `FUN_0097f090` | string | online-report serializer (writes the `includeStats` report field) | medium |
| `ShowSaveIcon` | `FUN_00634fa0` | string | save-icon UI (heavily called helper; name shared widely) | low |
| `SavedMotion` | `FUN_008dd8a0` | string | animation/motion save (uncalled in this build) | low |

### The ECS component registrars are a single repeated template

The six component symbols (`CashValue`, `FactionMarker`, `FactionValue`, `FactionZone`, `RuntimeObjectiveMarker`, `ModelMixerProfile`) all resolve to byte-identical 159-byte functions that differ only in their target globals and the final name string. This is the per-component descriptor-registration boilerplate. `FUN_006416d0` (`CashValue`):

```c
  DAT_017bd71c = 0xffff;          // free-list / handle sentinels
  _DAT_017bd724 = 0x100;          // pool size = 256
  _DAT_017bd718 = &PTR_CopyFromStream_00bbfc20;  // per-component stream-deserialize vtable
  _DAT_017bd744 = 0x9e3779b9;     // golden-ratio hash seed (component-name hash)
  _DAT_017bd730 = &PTR_FUN_00bc5ff8;
  FUN_0064a770();                 // shared registrar -> hands the descriptor to the ECS
  _DAT_017bd754 = s_CashValue_00bc50dc;  // <-- the component name
```

This confirms the Xbox-side observation that `CashValue`/`FactionValue`/`FactionZone`/`RuntimeObjectiveMarker` are real ECS components with allocation pools: the `0x100` pool size and `CopyFromStream` deserializer are visible here, and `FUN_0064a770` is the shared registration entry point. (`0x9e3779b9` is the standard golden-ratio constant used as a hash seed for the component name.)

### `FUN_005a4520` — the save-event handler

`SaveData` and `InitialSaveData` both anchor to this function, which dispatches on the incoming event-name string:

```c
  iVar5 = _stricmp(param_2,s_retry_00bb4604);
  *(bool *)(param_1 + 0xc3d) = iVar5 == 0;
  ...
    iVar6 = _stricmp(param_2,s_InitialSaveData_00bb4630);
  ...
  EnterCriticalSection((LPCRITICAL_SECTION)&DAT_01174ffc);
  iVar5 = FUN_00874150();
  LeaveCriticalSection((LPCRITICAL_SECTION)&DAT_01174ffc);
```

It takes a (state, event-name) pair, compares the name against `retry` and `InitialSaveData`, and runs the save under a critical section. This is the dispatch site behind the `SaveData`/`InitialSaveData`/`SaveComplete` event names.

### `FUN_0097f090` — online-report serializer (`includeStats`)

```c
  *(undefined4 *)(param_1 + 0x18) = 0x6773756d;          // 'msug' tag
  FUN_00975940(s_gameId_00b5f5b0,param_2);
  sprintf(local_20,s__I64d_00b5dfa8,param_3,param_4);
  FUN_00975940(s_userId_00b608e4,local_20);
  FUN_00975800(s_includeStats_00b60a34,param_5 != '\0');
```

This builds a key/value record (`gameId`, a 64-bit `userId`, an `includeStats` bool) via the writer helpers `FUN_00975940`/`FUN_00975800`. It is part of the EA-Blaze-style report back-end referenced in the achievement/stats section, not a gameplay-side stat call.

## How it works (decompiled)

Grounded in the Xbox PowerPC decomp `output/_ghidra_x360/xenon_decomp_named.c`. Every VA was confirmed present with the quoted snippet. The Xbox build *names* the entitlement/paying/pricing functions (the PC cross-ref above did not cover them), so this section adds the online-commerce layer.

### `GetEntitlementByBundle` / `GetPayingStatus` — EA-Nucleus "subs" (subscription) requests

These two register/build a back-end request and are nearly identical. Both stamp a request via a shared helper and then bind one parameter:

```c
==== GetEntitlementByBundle @821828b8  size=88 ====
  FUN_82182698(param_1,param_2,PTR_s_GetEntitlementByBundle_82d72630);  // name the request
  FUN_8218a788(param_2,0xffffffff8210d0dc,param_3);                     // bind a param

==== GetPayingStatus @82182a48  size=88 ====
  FUN_82182698(param_1,param_2,PTR_s_GetPayingStatus_82d72660);
  FUN_8218a788(param_2,0xffffffff8210d0dc,param_3);
```

The shared builder `FUN_82182698` stamps the request type tag `0x73756273` = ASCII **`'subs'`** and binds the method name:

```c
==== FUN_82182698 @82182698 ====
  *(undefined4 *)(param_2 + 0x18) = 0x73756273;          // 'subs' service tag
  FUN_8218a788(param_2,0xffffffff8210c2f4,param_3);      // method-name field
```

So `GetEntitlementByBundle`/`GetPayingStatus`/`GetSubscriptionAbility`/`SuspendEntitlement`/`GetCouponsByBundle` are all methods of an EA **subscription/entitlement** service (`'subs'`). This matches the string block (`entitlementStatus`, `entitlementSuspendDate`, `revenueType`, `recurringCycles`, `couponsByBundle.%d.*`, `pricingSelections.%d.*`) — an EA-Nucleus/Blaze commerce back-end, the same online layer as the achievement/stats reporter documented above.

### `GetPricingSelectionsByCode @82182ad8` — linked-list lookup by code string

Unlike its siblings, this one resolves locally: it reads a code string and walks a global linked list of pricing-selection records, returning the matching node's payload:

```c
==== GetPricingSelectionsByCode @82182ad8 ====
  cVar3 = FUN_8218ad78(param_2,0x...8210c2f4,local_30,0x20);   // read the "code" arg (<=0x20)
  if (cVar3 != '\0') {
    ppuVar4 = &PTR_PTR_82d71c4c;  puVar2 = PTR_PTR_82d71c4c;    // head of pricing-selection list
    while (puVar2 != 0) {
      pcVar6 = *(char **)(puVar2 + 4);                          // node's code string
      ... strcmp(pcVar6, local_30) ...
      if (match) return *ppuVar4;                               // return the matching selection
      ppuVar4 = ppuVar4 + 1;  puVar2 = *ppuVar4;
    }
  }
  return 0;
```

This is a client-side registry of pricing selections keyed by a short code (≤0x20 chars), returning a record pointer or NULL — i.e. "look up the offer/SKU for this code."

### Save-event handler and ECS registrars: Xbox confirms the PC cross-ref

The PC doc resolved `SaveData`/`autoSave`/`CashValue` etc. to PC functions. On Xbox, `SaveGameData @8236dc20` and `EnableUsingFakeProfile @824a5ea8` are present as named functions (the dev "fake profile" path the doc cites from the `EnableUsingFakeProfile` string), and the cash/faction/objective components appear as the same one-shot ECS registrars (`CashValue @829f05b0`, `RuntimeObjectiveMarker @829f44f0`, `ModelMixerProfile @829f2c30`) — confirming the PC-side `FUN_006416d0` template has Xbox twins. (I did not fully decode `SaveGameData`'s body; it is named and present, corroborating the save layer, but its internal state machine is not re-derived here.)

## Corrections & open questions

- **Entitlement/paying/pricing are an EA subscription service (new fact):** `GetEntitlementByBundle`/`GetPayingStatus` stamp the `'subs'` (`0x73756273`) request tag via `FUN_82182698` and are method-name registrations against an online commerce back-end (Nucleus/Blaze), not local gameplay. The string block (`recurringCycles`, `revenueType`, `couponsByBundle.*`) is a subscription/coupon model. This is consistent with — and extends — the doc's "EA-Blaze online back-end" framing into the commerce/entitlement domain.
- **`GetPricingSelectionsByCode` is a local list lookup (new fact):** it walks `PTR_PTR_82d71c4c` and string-matches a ≤0x20-char code, returning a record or NULL — confirmed in code, not inferred.
- **Achievements/stats back-end (unchanged, corroborated):** the doc's read that achievements/stats/leaderboards/entitlements are one online EA back-end is supported — the entitlement methods sit in the same `.rdata` neighborhood and share the request-builder style. Still, the *gameplay-facing* `GrantAchievement`/`AchievementIsGranted` vs the back-end `Eval/Synch/SetAchievements` split is **not re-verified in Xbox code** (those remain string-level).
- **Economy/components (corroborated):** `CashValue`/`FactionValue`/`RuntimeObjectiveMarker`/`ModelMixerProfile` are confirmed as ECS components on Xbox (named registrars `@829f05b0`/`@829f44f0`/`@829f2c30`), matching the PC `FUN_006416d0` template. The doc's "cash is an entity component" claim is **confirmed on both builds**.
- **Open / unresolved in code:** the contract/mission lifecycle (`ContractActivated`→`Completed`/`Cancelled`), the `SendEvent_*Objective*` event bus, and the achievement-grant gameplay path have no decompiled bodies under those names in the Xbox set — they stay string/event inference (as the doc flags). The save-corruption state machine (`hasCorruptedSave`) is resolved only on PC (`FUN_00614080`), not re-derived on Xbox here.
- **Cheat/unlock link:** `HasPlayerUnlockedCode` (the doc's content-gate) ties to the Lua `Cheat` table surfaced by the debug menu — see the new `docs/mercs2-pdb-analysis/debug-cheat-menu.md`; the actual God-Mode/Infinite-Ammo effects are Lua-driven, **not** a native game-systems toggle in this decomp.

## Cross-references

- `docs/mercs2-pdb-analysis/debug-cheat-menu.md` — the Lua-bound `Cheat` table (God Mode / Infinite Ammo), `HasPlayerUnlockedCode`, and the developer debug menu.
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `PgGameSystem.cpp` is the engine host for this layer (`Pg*` classes, event bus).
- `docs/mercs2-pdb-analysis/physics-game.md` and `docs/mercs2-pdb-analysis/vehicles.md` — gameplay components these systems read/score.
- Existing project docs that overlap this system's scope:
  - `docs/support-store-system-map.md` / memory note "Support/store supply-drop system map" — the cash economy / store (`AddCash`/`SetCash`/`nCashCost`).
  - `docs/contract_analysis_*.md` (e.g. `contract_analysis_oil_vza.md`, `contract_analysis_pmc_jet_mec.md`) — contract/mission content (`ContractActivated`/`Completed`/`Cancelled`).
  - `docs/ecs_components.md` and `docs/mercs2-ecs/` — the `CashValue`/`FactionValue`/`FactionZone`/`RuntimeObjectiveMarker` ECS components.
  - `docs/dlc_mission_loading.md` — mission/PDA flow (`AddPdaMissionDetails`, `GetMissionStates`).

## Evidence & confidence

- Symbol count: 161 symbols in `inventory/game-systems.txt` (129 in `.rdata`, 32 achievement-icon names in `.reloc`). This doc cites a representative subset across all areas plus expansion strings found by grep.
- Sections involved: `.rdata` (almost all identifiers/tunables/Lua-binding names) and `.reloc` (achievement PNG asset names). One source path: `Pangea\Src\PgGameSystem.cpp`.

Directly present in the evidence files at the cited offsets/regions: every `.rdata` identifier in the tables (e.g. `AddCash`/`SetCash`/`GetCash`, `ContractCompleted/Cancelled/Activated`, the `SendEvent_*Objective*` set, `GetFactionGuid`, the `Get*Achievement*`/`*Stats`/`GetRankedStats` cluster, `loadProfile`/`saveProfile`/`maximumProfiles`); the achievement ID block and the `achievements.%d.*` / `achiDefs.%d.*` / `histories.%d.*` serialization keys, `AchievementManagerParameters:`, the `Achievement #%d ...(Xbox360Id...)` format, `fesl.ea.com`, and the EA report API verbs; the ECS component-pool entries (`CashValue 1024`, `FactionMarker 1280`, `FactionValue 64 64`, `FactionZone 16 16`, `RuntimeObjectiveMarker 32 32`); the save filename formats `NoTRCSave%02d.sav` / `ConvertNoTRCSave%02d.sav`, `File corrupted!`, and `Warning: GetFactionGuid(0x%0x) = 0`.

Two larger claims go beyond what any single symbol states: that this layer is Lua/event-driven (argued from the `SendEvent_*` and verb-style binding names), and that the achievement/stats/leaderboard cluster is one online EA-Blaze back-end (argued from `.rdata` adjacency plus the `fesl.ea.com`/report-API vocabulary, now corroborated by the report serializers in the PC decomp). Smaller name-derived readings — "TRC" = Technical Requirements Checklist, reputation-meter behavior, `footUnlockGain` as an animation state, `onLoadProgress`/`getProgress` purpose, and the imperfect `ACHIEVEMENT_*`↔`achievement_*.png` mapping — should be read as naming interpretation, not confirmed behavior.
