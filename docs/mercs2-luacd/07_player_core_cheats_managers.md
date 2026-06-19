# 07 — Player, Core Economy, Cheats & Managers

Decompiled Lua from *Mercenaries 2: World in Flames* (resident modules). This group covers the
player-character lifecycle, the PMC economy (cash / fuel / support stockpile), the in-game **cheat
menu**, and the supporting manager singletons (factions, layers, outposts, stats, transit, timers,
achievements, co-op, AI/follow helpers, and the shared `MrxUtil` library).

> All line references point into `docs/mercs2-luacd/src/resident/<name>.lua`.

---

## 1. Overview

| Module | Role |
|---|---|
| **MrxPlayer** (`mrxplayer.lua`) | Player-character lifecycle: create/destroy/change characters, costumes, co-op join/leave, death/revive, medevac→sickbay, default weapon loadout, save/load of equipment. |
| **MrxPmc** (`mrxpmc.lua`) | The economy singleton: cash, fuel (+ fuel capacity / fuel-tank equipment), the support **stockpile**, freebies, reimbursement, HUD resource counters, save/load. |
| **MrxCheatBootstrap** (`mrxcheatbootstrap.lua`) | **The cheat menu.** Builds a multi-page debug menu (`_G.Cheat.DisplayOptions`) plus mission-skip / teleport debug helpers. |
| **MrxFactionManager** (`mrxfactionmanager.lua`) | Faction relations/attitudes, price scaling, reporting/pursuit, civilian-casualty penalty, flybys. |
| **MrxLayerManager** (`mrxlayermanager.lua`) | Async streaming-layer add/remove/reload request queue. |
| **MrxOutpostManager** (`mrxoutpostmanager.lua`) | Tiny registry of outpost capture/destroy callbacks. |
| **MrxStatsManager** (`mrxstatsmanager.lua`) | Progress %, PDA statistics, fav weapon/vehicle timers, credit/debit/fuel/death counters. |
| **MrxStats / Achievements** (`mrxachievements.lua`) | Achievement list + grant/add-count, net sync, faction-mood achievement. |
| **MrxTransit** (`mrxtransit.lua`) | Landing-zone fast-travel; `UnlockAllLandingZones` (used by cheat menu). |
| **MrxParkingLotManager** (`mrxparkinglotmanager.lua`) | Tracks the last-driven vehicle and relocates it to the PMC parking lot. |
| **MrxTimer** (`mrxtimer.lua`) | Generic HUD countdown/count-up timer object (objective tray). |
| **MrxCoop** (`mrxcoop.lua`) | Co-op "tether" boundary between P1 and P2 characters. |
| **MrxUtil / MrxUtilShell** (`mrxutil.lua`, `mrxutil_shell.lua`) | Shared library: callbacks, table ops, money formatting, hero teleport, marker tables, faction/character identity helpers. |
| **MrxAi / MrxFollow** (`mrxai.lua`, `mrxfollow.lua`) | Hibernation-safe AI goal wrappers; "follow me" companion behaviour. |

Player identity model: three heroes — **mattias / jen(jennifer) / chris** — each with upgrade
templates and costume models (`_tCharacterMap`, `mrxplayer.lua:20`). **Co-op** = player 0 (host /
primary) + player 1 (client / secondary). `Player.GetPrimaryCharacter()` / `GetSecondaryCharacter()`
are the canonical accessors used throughout (e.g. revive logic `mrxplayer.lua:546-549`).

---

## 2. THE CHEAT SYSTEM — `MrxCheatBootstrap`

The cheat menu is a self-contained debug UI built on `MrxMultiPageMenu`. It is exposed globally:

```lua
_G.Cheat = { DisplayOptions = DisplayOptions }   -- mrxcheatbootstrap.lua:281
```

So the entire menu is triggered by calling **`Cheat.DisplayOptions()`** from anywhere a Lua console /
hook can reach (highly relevant for ASI / console injection — see §8). It calls `DisplayOptions()`
(`:23`) → `_DisplayRootDialog()` (`:35`).

### 2.1 Root menu — every option

`_DisplayRootDialog` (`mrxcheatbootstrap.lua:35-60`). Title: **"Welcome to the Cheat Menu."**

| Menu label | Handler | What it does | Line |
|---|---|---|---|
| **Skip to a mission** | `_DisplaySkipDialog(false)` | List all missions; pick one to jump to it (no briefing). | `:38` |
| **Skip to a briefing** | `_DisplaySkipDialog(true)` | Same list, jumps to the mission **briefing**. | `:39` |
| **Complete current contract (`<parent>`)** | `_CompleteCurrentContract` | Calls `oCurrentContract:Complete()` on the active mission's parent. Only shown if a mission is active. | `:40-44`, `:62-65` |
| **Traverse mission hierarchy** | `_DisplayTraverseDialog` | Walk the task tree; Complete / Cancel / Up-a-level on the current task node. | `:46`, `:86-130` |
| **Add cash** | `_DisplayAddCashDialog` | Submenu of fixed cash grants. | `:48`, `:132` |
| **Add fuel** | `_DisplayAddFuelDialog` | Submenu of fixed fuel grants. | `:49`, `:154` |
| **Add support** | `_DisplayAddSupportDialog` | Stockpile/cash/fuel "The Works!" + per-item +1. | `:50`, `:177` |
| **Modify attitude** | `_DisplayModAttitudeDialog` | Set faction↔faction relation (subject/object/attitude). | `:51`, `:207` |
| **Unlock all landing zones** | `MrxTransit.UnlockAllLandingZones` | Enables + un-suppresses every LZ as PMC-owned. | `:56` → `mrxtransit.lua:407` |
| **Dispense all rewards** | `MrxRewardData.DispenseAllRewards` | Grants all reward-data entries (external module). | `:57` |
| **Close this menu** | `nil` | Dismiss. | `_AddCloseOption :31` |

The first four (mission/contract/traverse) are **hidden when inside the PMC interior**
(`if not WifPmcInterior.IsInside()`, `:37`). `_AddRootOption` (`:27`) / `_AddCloseOption` (`:31`) add
"Return to root menu" / "Close this menu" to every sub-dialog.

### 2.2 Add Cash submenu — `_DisplayAddCashDialog` (`:132-152`)

Fixed buttons, each calls `MrxPmc.AddCashQty(nCash)` then refreshes:

```
+$1000   +$10000   +$100000   +$1000000   +$10000000   +$100000000   (mrxcheatbootstrap.lua:134-141)
```

Title shows current balance: `Add Cash ($<MrxPmc.GetCashQty()>)`.

### 2.3 Add Fuel submenu — `_DisplayAddFuelDialog` (`:154-175`)

Buttons: **+10, +100, +1000, +9999** (`:156-161`). If the grant would exceed capacity it first calls
`MrxPmc.SetFuelCapacity(9999, true)` (cheat flag bypasses the cap) then `AddFuelQty(nFuel)`.

### 2.4 Add Support submenu — `_DisplayAddSupportDialog` (`:177-205`)

- **"The Works! + $ + F"** (`:187-195`): tops up *every* support item to its `nMaxStock`, adds
  **$10,000,000**, sets fuel capacity to **9999** and adds **9999** fuel, and calls
  `MrxSupportData.SetIgnoreRequirements(true)` (disables unlock prerequisites). This is the master
  "give me everything" cheat.
- Then one button per support item: `"<sName> (cur/max)"` → `MrxPmc.AddSupportQty(sKey, 1)`.
  Sorted by `tSupportData[*].sName`.

### 2.5 Modify Attitude submenus

- `_DisplayModAttitudeDialog(sSubject, sObject, nRelation)` (`:207-232`): defaults subject `"All"`,
  object `"Pmc"`. If `nRelation` given → `MrxFactionManager.SetRelation`; else reads current. Shows
  Subject / Object / Attitude (label).
- `_DisplayFactionDialog(bSubject)` (`:234-252`): lists faction abbrevs (`GetFactionAbbrevs`) to pick
  the subject or object.
- `_DisplayAttitudeDialog` (`:254-279`): lists attitude labels with their relation numbers
  (Hostile/Neutral/Friendly) sorted descending; selecting one sets the relation.

### 2.6 Mission-skip & teleport debug helpers (non-menu API)

- **`_G.DebugTeleport(x, y, z)`** (`:283-294`): teleports all heroes to a location via
  `MrxUtil.TeleportHeroesToLocations`. Global → directly callable from a console/hook.
- **`EnableSkipMode(bEnable, sMissionId, bBriefing)`** (`:296-327`): on disable it reads
  `WifCheatStockpile[missionId]` and grants the expected support items, equipment, **sets** cash, and
  **sets** fuel to the values that mission expects (so you can test a mission with its intended
  loadout). `IsSkipModeEnabled` / `GetMissionSkipData` / `SetMissionSkipDialogCallback` are the
  accessors (`:329-339`). Note `MrxUtil.TeleportHeroesToLocations` short-circuits while skip-mode is
  enabled (`mrxutil.lua:143`).

### 2.7 Native infinite-ammo binding

`Object.SetInfiniteAmmo(uCharacter, bEnable)` is a **native C binding** (not defined in Lua). It is
*not* wired into the cheat menu, but it is the canonical "infinite ammo" toggle and is used by
mission scripts and the shooting gallery:

- `vz/pmccon031.lua` … `pmccon034.lua` (boss fights toggle it on at start, off at end).
- `resident/mrxshootinggallery.lua:53`.

To add an infinite-ammo cheat you would call `Object.SetInfiniteAmmo(Player.GetPrimaryCharacter(), true)`
(and the secondary). See §8.

---

## 3. Player & Economy API

### MrxPlayer (`mrxplayer.lua`)

| Function | Signature / behaviour | Ref |
|---|---|---|
| `Init` / `Deinit` / `Start` / `Reset` | Create/destroy all `Player.GetMaximumPlayers()` slots; register join/left callbacks. | [mrxplayer.lua:114](src/resident/mrxplayer.lua#L114) |
| `OnPlayerJoined(iPlayerId, sPlayerName, tCharacterConfig, bLocalPlayer, iLocalId)` | Spawns the hero, binds local/remote, creates GUI, posts `mpPlayerJoin`. Client fuel-cap sync. | [:176](src/resident/mrxplayer.lua#L176) |
| `OnPlayerLeft(iPlayerId, sPlayerName, bLocalPlayer)` | Plays "abandoned" VO, cancels mission if no heroes alive, destroys char. | [:286](src/resident/mrxplayer.lua#L286) |
| `CreatePlayerCharacter(bLocalPlayer, iPlayerId, sCharacterName, vLocation)` | `Pg.Spawn` + attach. | [:562](src/resident/mrxplayer.lua#L562) |
| `ChangePlayerCharacter(iPlayerId, sCharacterName, sCharacterModel)` | Respawn at current transform. | [:605](src/resident/mrxplayer.lua#L605) |
| `GetSelectedCharacter(iPlayerId)` → `"mattias"|"jen"|"chris"` | By label on the character template. | [:630](src/resident/mrxplayer.lua#L630) |
| `RiseFromYourGrave()` | Revives `Player.GetPrimaryCharacter()`; for secondary sends `Net.SendEvent_RevivePlayer(1)`. | [:542](src/resident/mrxplayer.lua#L542) |
| `ResetWeapons(uCharGuid, sNewWeapon)` | **Default loadout.** See below. | [:528](src/resident/mrxplayer.lua#L528) |
| `MedEvac` / `MoveToSickbay` | Cancel mission / return to sickbay; charges medevac cost. | [:443](src/resident/mrxplayer.lua#L443), [:457](src/resident/mrxplayer.lua#L457) |
| `GetMedEvacCost()` → `10000` | Flat medevac cost. | [:524](src/resident/mrxplayer.lua#L524) |
| `AreAnyHeroesAlive()` | true if any player char alive. | [:650](src/resident/mrxplayer.lua#L650) |
| `SaveSingleton` / `LoadSingleton` | Per-hero health + weapon inventory (parent + reserve ammo). | [:661](src/resident/mrxplayer.lua#L661) |

**Default weapon loadout** (`ResetWeapons`, [mrxplayer.lua:528](src/resident/mrxplayer.lua#L528)):

```lua
sPrimary = sNewWeapon or "Pistol"; sGrenade = "Grenade"; sC4 = "C4"
Human.Inventory.SetAllWeapons(uCharGuid, { uPrimary, uGrenade, uC4 })   -- Pistol / Grenade / C4
```

### MrxPmc — economy (`mrxpmc.lua`)

| Function | Signature / behaviour | Ref |
|---|---|---|
| `AddCashQty(nAmt, bMateriel, sReason, bSuppressDisplay)` | Clamps each delta and the **total** to `[0, 1e9]`; `Player.SetCash`; posts `CashAdded`; routes to stats credit/debit. | [mrxpmc.lua:45](src/resident/mrxpmc.lua#L45) |
| `GetCashQty()` → `Player.GetCash()` | | [:81](src/resident/mrxpmc.lua#L81) |
| `AddFuelQty(nAmt)` | Clamp to `[0, capacity]`; triggers NoFuel/LowFuel tutorials; stats. | [:85](src/resident/mrxpmc.lua#L85) |
| `GetFuelQty()` → `Player.GetFuel()` | | [:107](src/resident/mrxpmc.lua#L107) |
| `SetFuelCapacity(nFuelCapacity, bCheat, bDoNotSyncFuel)` | Enforces `[300, 9999]` **unless** `bCheat` true. | [:111](src/resident/mrxpmc.lua#L111) |
| `AddFuelCapacity` / `GetFuelCapacity` | | [:122](src/resident/mrxpmc.lua#L122), [:136](src/resident/mrxpmc.lua#L136) |
| `AddSupportQty(sName, nAmt, bDspFanfare, nCost)` | Adds to `_tStockpile[sName].nAmt`; client-side cost tracking; threshold callbacks; unlock fanfare. | [:140](src/resident/mrxpmc.lua#L140) |
| `SetSupportQty` / `GetSupportQty` | | [:169](src/resident/mrxpmc.lua#L169), [:178](src/resident/mrxpmc.lua#L178) |
| `AddEquipment(sName, bDoNotAddCapacity)` | Fuel tanks add capacity + spawn a tank object; grappling hook enables grapple. | [:296](src/resident/mrxpmc.lua#L296) |
| `AddFuelTank` / `RemoveFuelTank` / `_OnFuelTankDeath` | Spawns `_pmcoutpost_bld_fueldepot`; capacity adjusts on death. | [:375](src/resident/mrxpmc.lua#L375) |
| `GetClientReimburseAmount` / `NetClientReimburse` | Co-op client refund of unused support spend. | [:442](src/resident/mrxpmc.lua#L442) |
| `DisplayCash` / `DisplayResources` | `Hud.ResourceCounter:SetCash/SetFuel`. | [:347](src/resident/mrxpmc.lua#L347), [:363](src/resident/mrxpmc.lua#L363) |
| `SaveSingleton` / `LoadSingleton` | Cash, fuel, capacity, equipment, stockpile, freebies. | [:500](src/resident/mrxpmc.lua#L500) |

---

## 4. Defaults & Tunables Table

### Economy / fuel (MrxPmc)

| Constant / value | Meaning | Ref |
|---|---|---|
| `_knMinFuelCapacity = 300` | Min (and starting) fuel capacity. Set at `Init`. | [mrxpmc.lua:37](src/resident/mrxpmc.lua#L37), [:41](src/resident/mrxpmc.lua#L41) |
| `_knMaxFuelCapacity = 9999` | Max fuel capacity (cheat bypasses). | [:38](src/resident/mrxpmc.lua#L38) |
| `knBillion = 1000000000` | Hard cash ceiling (per-delta and total). | [:46](src/resident/mrxpmc.lua#L46) |
| LowFuel tutorial at ≤ 10% capacity; NoFuel at ≤ 0 | | [:94-96](src/resident/mrxpmc.lua#L94) |
| `_ksFuelTank = "_pmcoutpost_bld_fueldepot"` | Fuel-tank prop template. | [:9](src/resident/mrxpmc.lua#L9) |

> **Starting cash:** not hard-coded here (set elsewhere via `Player.SetCash`). **Starting fuel
> capacity = 300.** The `_kMaxStock=99` mentioned in the brief is per-support-item `nMaxStock`, which
> lives in the external `MrxSupportData.tSupportData` table (read by the cheat menu at
> `mrxcheatbootstrap.lua:189,197`), not in this module group.

### Cheat-menu grant amounts (MrxCheatBootstrap)

| Set | Values | Ref |
|---|---|---|
| Cash buttons | 1000, 10000, 100000, 1000000, 10000000, 100000000 | [mrxcheatbootstrap.lua:134](src/resident/mrxcheatbootstrap.lua#L134) |
| Fuel buttons | 10, 100, 1000, 9999 | [:156](src/resident/mrxcheatbootstrap.lua#L156) |
| "The Works!" cash / fuel | +$10,000,000 / cap 9999 + 9999 fuel | [:192-193](src/resident/mrxcheatbootstrap.lua#L192) |

### Faction attitudes & price scaling (MrxFactionManager)

| Constant | Value | Ref |
|---|---|---|
| `_knAttitudeMeterMin / Max` | 0 / 100 | [mrxfactionmanager.lua:9](src/resident/mrxfactionmanager.lua#L9) |
| `_knRelationMin / Max` | -100 / 100 | [:11](src/resident/mrxfactionmanager.lua#L11) |
| **Hostile** | range `[-100, -33)`, **no prices** (can't buy), RGB 255/0/0 | [:20](src/resident/mrxfactionmanager.lua#L20) |
| **Neutral** | range `[-33, 33)`, **price scale 1.5×**, RGB 200/200/200 | [:35](src/resident/mrxfactionmanager.lua#L35) |
| **Friendly** | range `[33, 100]`, **price scale 1.0×**, RGB 0/127/255 | [:50](src/resident/mrxfactionmanager.lua#L50) |
| Pursuit level times | `Pg.SetPursuitLevelTimes(120, 300)` | [:367](src/resident/mrxfactionmanager.lua#L367) |
| Report mood weights | DamageObject×1, DestroyObject×25, Trespassing×20, Hijack×10, DestroyPerson×50, DamagePerson×3; clamped ≥ -60 | [:1212-1219](src/resident/mrxfactionmanager.lua#L1212) |
| Civilian-casualty penalty | starts `-5000`; doubles every 20 kills, floor `-1,000,000` | [:815-823](src/resident/mrxfactionmanager.lua#L815) |
| Faction abbrevs → templates | All=Allied, Chi=China, Civ=Civ, Gur=Guerilla, Oil=OC, Pir=Pirate, Pmc=PMC, Vza=VZ | `_tFactions` [:66](src/resident/mrxfactionmanager.lua#L66) |
| Initial relations | Pir = median(Neutral)=0; Gur/Oil = median(Friendly); All=Oil↔Pmc rel; Chi=Gur↔Pmc rel | [:73,:119,:170,:218,:266](src/resident/mrxfactionmanager.lua#L73) |

`GetPriceScale(subj, obj)` returns the `nPrices` of the current attitude level
([:549](src/resident/mrxfactionmanager.lua#L549)) — shops multiply by this.

### Transit (MrxTransit)

| Constant | Value | Ref |
|---|---|---|
| `_nTransitFuelCost = 20` | Fuel per fast-travel. | [mrxtransit.lua:10](src/resident/mrxtransit.lua#L10) |
| Faction sort order in UI | Pmc1, Oil2, Gur3, Pir4, All5, Chi6, Vza7 | [:16](src/resident/mrxtransit.lua#L16) |
| LZ #6 flagged `bFake` | Excluded from unlockable count. | [:343](src/resident/mrxtransit.lua#L343) |

### Stats / progress weights (MrxStatsManager)

| Constant | Value | Ref |
|---|---|---|
| `nTotalToolbox = 100` | Toolbox collectible total. | [mrxstatsmanager.lua:12](src/resident/mrxstatsmanager.lua#L12) |
| Progress weights | Contract 25, Recruit 10, Shop 2, Destroy 3, HVT 5, Toolbox 1, LZ 3 | [:39-45](src/resident/mrxstatsmanager.lua#L39) |
| Recruits denominator | `/4` | [:263](src/resident/mrxstatsmanager.lua#L263) |
| Destroy-bounty totals | Pir 11, Oil 13, Gur 13, Chi 8, All 24 (others 0) | [:31-38](src/resident/mrxstatsmanager.lua#L31) |

### Timer defaults (MrxTimer, `Create`)

| Field | Default | Ref |
|---|---|---|
| `nStartTime` 30, `nStopTime` 0, `nStep` 1, `bUseTenths` false, `nWarning` 5, `iTray` 1, `bPlaySounds` true | | [mrxtimer.lua:7-13](src/resident/mrxtimer.lua#L7) |

### Co-op tether (MrxCoop) & misc

| Constant | Value | Ref |
|---|---|---|
| `Pg.SetBoundaryRadius(38.5)` | Tether boundary radius. | [mrxcoop.lua:11](src/resident/mrxcoop.lua#L11) |
| Parking lot: `kiParkingLotLimit = 8`, `kfTutorialTime = 6`, `kiBlipSize = 6` | | [mrxparkinglotmanager.lua:4-6](src/resident/mrxparkinglotmanager.lua#L4) |
| Layer mgr `_knLayersToProcessCap = 10` | Max concurrent layer ops. | [mrxlayermanager.lua:12](src/resident/mrxlayermanager.lua#L12) |
| Achievement money tiers | thousand/million/billion/1e12/1e15 string hashes | [mrxutil.lua:981-985](src/resident/mrxutil.lua#L981) |

---

## 5. Logic notes

- **Cash add/spend** (`MrxPmc.AddCashQty`): single clamped path used for *all* money flow. Positive
  → `MrxStatsManager.IncreaseCreditAmount`; negative → `IncreaseDebitAmount`. `sReason` is mapped
  plural→singular for the HUD (`_tPluralReasonToSingular`, `mrxpmc.lua:21`).
- **Fuel** is capped at capacity on add; capacity itself capped `[300,9999]` except via the `bCheat`
  flag (this is exactly how the cheat menu pushes fuel to 9999, `mrxcheatbootstrap.lua:164,192`).
- **Faction price scaling**: shops query `GetPriceScale`; Hostile = no `nPrices` (purchase blocked),
  Neutral = 1.5×, Friendly = 1.0×. Relations clamp to `[-100,100]`; reaching +100 grants the
  faction's `sMaxRelationAchievement` (`mrxfactionmanager.lua:579`).
- **Reporting / pursuit** (`HandleReporter0/1/2`, `FinishedReporting`): an enemy soldier "reports"
  the player; accumulated infractions lower PMC relation; relation ≤ -100 increments pursuit level
  (max 3). Civilian kills by a player character apply the escalating cash penalty above.
- **Layer streaming** (`MrxLayerManager`): coalesces add/remove/reload requests per layer into an op
  queue, throttled to 10 concurrent (`_ProcessOpQueue`), raises `Sys.SetAssetRequestMax` to match
  pending ops then restores the original. `FindLayerIntersection` (`:327`) diffs loaded vs saved
  layers on load.
- **Outposts** (`MrxOutpostManager`): one-shot callback registry keyed by outpost GUID; `knStatusCaptured=1`,
  `knStatusDestroyed=2`; fires then unregisters.
- **Co-op tether** (`MrxCoop`): keeps P2 within `[iTetherMin, iTetherMax]` of P1 using
  `Event.ObjectProximity` state transitions; outside max → `Player.SetOutBoundary(true)`.
- **Parking lot** (`MrxParkingLotManager`): tracks up to 8 recently exited vehicles; on
  `parkingLotStart` moves the nearest valid one to the normal/heli point and removes the rest.

---

## 6. Logging & debug markers (`Debug.Printf`)

Notable strings (grep targets when reading `pmc_blackbox.log`):

- MrxPlayer: `"creating player <i>"`, `"destroying player <i>"`, `"registering player callbacks"`,
  `"LUA: <name> joined as player <id> ..."`, the `"@@@@@@@@@@ MrxPlayer.CreatePlayerCharacter: ..."`
  banner (`mrxplayer.lua:563`), `"@@@@@@@@@@ MrxPlayer.LoadSingleton: new equipment item ..."`.
- MrxPmc: `"AddSupportQty(): <n> of <name> for $<cost>"` (`:144`), `"GetClientReimburseAmount(): +$..."`,
  `"FuelTank <id> died!"`, `"callback is nill!!"` (typo in threshold check, `:220`).
- MrxFactionManager: `"CAN'T SET RELATION ... ATTITUDE IS NOT MUTABLE"` (`:556`),
  `"REPORTING - state 0/1/2"`, `"You've been reported (...)"`, `"CivCasualtySetup function has been called"`,
  the long `"...........................................Entering Trespasser Zone!"` markers.
- MrxLayerManager: `"... MUST FIX TO MAKE QUIT TO SHELL WORK!"` on a failed layer op (`:259`),
  `"Culling layer <x> ..."`, `"Setting asset request max to <n>"`.
- MrxUtil teleport: `"@@@@@@@@@@ MrxUtil._TeleportHero: Teleporting to ..."`,
  `"@@@@@@@@@@ MrxUtil._TeleportComplete: ..."`.
- Marker-table misses print `"!!!!!!!!!!! CLIENT WON'T SEE THIS ... Could not find marker <x> ..."`
  (`mrxutil.lua:944` etc.) — useful when a HUD/PDA/radar icon name is wrong.

---

## 7. MrxUtil quick reference (shared library)

| Function | Purpose | Ref |
|---|---|---|
| `CallWithOptionalArgs(f, tArgs)` | The universal "call f(unpack(tArgs))" used everywhere. | [mrxutil.lua:8](src/resident/mrxutil.lua#L8) |
| `FormatMoney(n)` | Localized money string; clamps `[0, 1e15]`; suffix table in `Init`. | [:71](src/resident/mrxutil.lua#L71) |
| `TeleportHeroesToLocations(tLocations, fCb, ...)` | Multi-hero teleport (skip-mode aware). | [:142](src/resident/mrxutil.lua#L142) |
| `TeleportHeroesToHardpoints(...)` | Teleport to object hardpoints. | [:206](src/resident/mrxutil.lua#L206) |
| `EnterBestAvailableSeat(uChar, uVeh, uAvoid, bImm)` | d→g→p→c seat priority. | [:381](src/resident/mrxutil.lua#L381) |
| `GetCharacterIdentity(uChar)` → mattias/jennifer/chris | By label. | [:649](src/resident/mrxutil.lua#L649) |
| `EnableHeroWeapons(bEnable)` | Enable/disable both heroes' weapons + aim mode. | [:664](src/resident/mrxutil.lua#L664) |
| `SpawnObject` / `SpawnActor` | Template spawn at a location/anchor. | [:447](src/resident/mrxutil.lua#L447), [:463](src/resident/mrxutil.lua#L463) |
| Marker tables `tObjWorldMarkers / tObjPdaMarker / tObjRadarMaker` + index lookups | Net-synced icon name↔index maps. | [:823](src/resident/mrxutil.lua#L823) |
| `ClearVehiclesNearPoint` | Despawn ground veh/heli near a point (used by parking lot). | [:1013](src/resident/mrxutil.lua#L1013) |

`MrxUtilShell` (`mrxutil_shell.lua`) is a trimmed shell-context copy of `CallWithOptionalArgs` +
`ProcessCallbackTable` (28 lines).

---

## 8. Cross-references & future-dev / injection notes

**Native bindings referenced (defined in the engine, not Lua) — candidate cheat hooks:**

- `Player.SetCash(n)`, `Player.GetCash()`, `Player.AddFuel(n)`, `Player.SetFuel(n)`,
  `Player.GetFuel()`, `Player.SetFuelCapacity(n)` — direct economy pokes.
- `Object.SetInfiniteAmmo(uChar, bEnable)` — **infinite ammo** (see §2.7).
- `Object.Revive`, `Object.SetHealth`, `Object.GetMaxHealth` — godmode-style pokes.
- `Human.Inventory.SetAllWeapons(uChar, {...})` — force a loadout (cf. `ResetWeapons`).
- `Ai.SetRelation` / `Ai.GetRelation` — backing store for all faction attitudes
  (`MrxFactionManager.SetRelation`/`GetRelation`).
- `Pg.AchievementAddCount` — achievements (via `MrxAchievements`).

**Easiest Lua-injection cheat entry points (for an ASI / console hook):**

1. **`Cheat.DisplayOptions()`** — opens the full debug menu (global, §2). Most powerful single call.
2. **`MrxCheatBootstrap.DisplayOptions()`** — same thing namespaced.
3. **`_G.DebugTeleport(x, y, z)`** — global teleport.
4. Direct economy: `MrxPmc.AddCashQty(100000000)`, `MrxPmc.SetFuelCapacity(9999, true)` then
   `MrxPmc.AddFuelQty(9999)`.
5. Infinite ammo: `Object.SetInfiniteAmmo(Player.GetPrimaryCharacter(), true)` (and
   `Player.GetSecondaryCharacter()` for co-op P2). No existing menu item — add one in
   `_DisplayRootDialog` if a toggle is wanted.
6. Max all factions: loop `MrxFactionManager.GetFactionAbbrevs()` →
   `MrxFactionManager.SetRelation(abbrev, "Pmc", 100)` (drives prices to 1.0× and grants the
   per-faction max-relation achievements).
7. Unlock travel: `MrxTransit.UnlockAllLandingZones()`.

**Dependency map (imports):** `MrxCheatBootstrap` pulls in `MrxFactionManager`, `MrxLayerManager`,
`MrxMultiPageMenu`, `MrxPlayState`, `MrxRewardData`, `MrxTaskState`, `MrxTransit`, `MrxUtil`,
`WifMissionData/Flow`, `WifVzBoundary`, `WifCheatStockpile`, `MrxPmc`, `MrxSupportData`,
`WifPmcInterior`, `Munitions` (`mrxcheatbootstrap.lua:1-16`). `MrxUtil` imports `MrxCheatBootstrap`
(for `IsSkipModeEnabled`) — note the circular link between teleport and skip-mode.

**Save/load surface:** `MrxPlayer`, `MrxPmc`, `MrxFactionManager`, `MrxLayerManager`,
`MrxStatsManager`, `MrxAchievements`, `MrxTransit` all expose `SaveSingleton`/`LoadSingleton` — the
canonical persistence hooks if you mod starting resources or unlocks.
