# Group 04 — Tutorials & WIF Data/Config Scripts

Decompiled Lua source from **Mercenaries 2: World in Flames** (`docs/mercs2-luacd/src/vz/`).
This group covers the in-game **tutorials** (`wiftutorial*`) and the **data/config tables** (`wif*data`,
`wifhq*`, `wifpmc*`, `wifvz*`, `wifbios`, `wifhints`, `wiffreeplay`).

> All line refs are clickable to the canonical source under `src/vz/`.

---

## 1. Overview

### (a) Tutorials (`wiftutorial*`)
22 tutorial scripts. Each `inherit("MrxTutorial")` (line 1), implements `GetMessage()` returning the
help-text localization key, and wires activation / cancel / complete criteria through `self:_CreateEvent(...)`.
The **default completion timer is `Event.TimerRelative, {10}` (10 seconds)** in the simpler "fire-and-forget"
tutorials. They teach vehicle entry (car/boat/heli/tank/APC), C4, swimming, fuel warnings, co-op
revive/tether, collectibles, disguises, horns, trespass and collateral damage. See §3 for the full table.

### (b) Data / Config scripts (`wif*data`, `wifhq*`, `wifpmc*`, `wifvz*`, etc.)
Pure data tables read by engine/`Mrx*` managers:

| Script | Role | Key global / table |
|---|---|---|
| [wifequipmentdata.lua](src/vz/wifequipmentdata.lua) | Shop equipment defs (fuel silos, grappling hook) | `_tEquipment`, `GetEquipmentData()` |
| [wifstarterdata.lua](src/vz/wifstarterdata.lua) | Faction "starter" / boss contacts & HQ wiring | `_sStarters`, `<Faction>Starter*` |
| [wifcheatstockpile.lua](src/vz/wifcheatstockpile.lua) | Debug-cheat loadouts (cash/fuel/support/equipment) | `<Mission>Con*` tables |
| [wifhqdata.lua](src/vz/wifhqdata.lua) | HQ/outpost interior, portal, icons, landing zones | `_tHqConfigs`, `GetHqConfigFromId()` |
| [wifbriefingdata.lua](src/vz/wifbriefingdata.lua) | Mission-briefing VO sequences (338 KB) | `Intros`, `<Mission>Con*` VO trees |
| [wifrecommendationdata.lua](src/vz/wifrecommendationdata.lua) | "Recommended loadout" hints per mission | `_tRecommendations` |
| [wifbios.lua](src/vz/wifbios.lua) | PDA dossier bio entries | `_tBios`, `AddDossierEntry()` |
| [wifhints.lua](src/vz/wifhints.lua) | Freeplay hint VO cues per speaker | `_tHints` |
| [wiffreeplay.lua](src/vz/wiffreeplay.lua) | "Nag" timer logic for Fiona hints | nag delays |
| [wifpmcgarage.lua](src/vz/wifpmcgarage.lua) | PMC HQ vehicle garage storage | `_tRegions`, `_tDropOffs`, `_tSpawnPoints` |
| [wifpmcinterior.lua](src/vz/wifpmcinterior.lua) | PMC interior portals & starter briefing locs | `_tStarters`, `_tPortalData` |
| [wifvzambience.lua](src/vz/wifvzambience.lua) | Ambience-stream boundary triggers | `tBoundaryList` (empty default) |
| [wifvzatmosphere.lua](src/vz/wifvzatmosphere.lua) | Sky/atmosphere boundary triggers | `tBoundaryList` |
| [wifvzboundary.lua](src/vz/wifvzboundary.lua) | POI map labels + Fiona POI VO | `tBoundaryList` |
| [wifvzregionnames.lua](src/vz/wifvzregionnames.lua) | Region-name boundary table | `tBoundaryList` |
| [wifmissiondata.lua](src/vz/wifmissiondata.lua) | Mission registry (covered in mission docs) | — |
| [wifmissionflow.lua](src/vz/wifmissionflow.lua) | Mission flow state machine (covered in mission docs) | — |

---

## 2. DATA TABLES — full dumps

### 2.1 Equipment — `wifequipmentdata.lua`

Type enum ([1-3](src/vz/wifequipmentdata.lua#L1)): `knTypeFuelTank=1`, `knTypeCostume=2`, `knTypeGrapplingHook=3`.
Unlock-status enum ([4-5](src/vz/wifequipmentdata.lua#L4)): `_knUnlockStatusNew=1`, `_knUnlockStatusViewed=2`.

`_tEquipment` ([L6-140](src/vz/wifequipmentdata.lua#L6)) — all fuel silos share name `[Generic.FuelSilo]`,
description `[Generic.FuelSiloDescription]`, texture `support_bombing_run`, `nType=knTypeFuelTank`:

| Id | nCost | nFuelCapacity | nFuelTankId | Ref |
|---|---:|---:|---:|---|
| FuelTank1 | 100000 | 200 | 1 | [L7](src/vz/wifequipmentdata.lua#L7) |
| FuelTank2 | 100000 | 200 | 2 | [L16](src/vz/wifequipmentdata.lua#L16) |
| FuelTank3 | 100000 | 200 | 3 | [L25](src/vz/wifequipmentdata.lua#L25) |
| FuelTank4 | 100000 | 200 | 4 | [L34](src/vz/wifequipmentdata.lua#L34) |
| FuelTank5 | 100000 | 200 | 5 | [L43](src/vz/wifequipmentdata.lua#L43) |
| FuelTank6 | 100000 | 200 | 6 | [L52](src/vz/wifequipmentdata.lua#L52) |
| FuelTank7 | 100000 | 200 | 7 | [L61](src/vz/wifequipmentdata.lua#L61) |
| FuelTank8 | 100000 | 200 | 8 | [L70](src/vz/wifequipmentdata.lua#L70) |
| FuelTank9 | **250000** | **700** | 9 | [L79](src/vz/wifequipmentdata.lua#L79) |
| FuelTank10 | 250000 | 700 | 10 | [L88](src/vz/wifequipmentdata.lua#L88) |
| FuelTank11 | 250000 | 700 | 11 | [L97](src/vz/wifequipmentdata.lua#L97) |
| FuelTank12 | 250000 | 700 | 12 | [L106](src/vz/wifequipmentdata.lua#L106) |
| FuelTank13 | 250000 | 700 | 13 | [L115](src/vz/wifequipmentdata.lua#L115) |
| FuelTank14 | 250000 | 700 | 14 | [L124](src/vz/wifequipmentdata.lua#L124) |

> **Cost tier break:** FuelTank1–8 = 100 000 / 200 fuel; FuelTank9–14 = 250 000 / 700 fuel.

`GrapplingHook` ([L133](src/vz/wifequipmentdata.lua#L133)): `sName="[weapon.grapple]"`,
`sDescription="[Fiona.Grapple01]"`, `sTexture="weapons_grappling"`, `nType=knTypeGrapplingHook`, **`nCost=100000`**.

API: `GetEquipmentData(sId)` ([L142](src/vz/wifequipmentdata.lua#L142)) is the single read accessor;
`UnlockItem`/`IsItemUnlocked`/`IsItemNew`/`SetItemViewed` ([L146-187](src/vz/wifequipmentdata.lua#L146))
manage per-faction `tUnlockStatus`; `GetPlayerVisibleName` ([L189](src/vz/wifequipmentdata.lua#L189))
returns `sName`. `SaveSingleton`/`LoadSingleton` persist only `tUnlockStatus`.

### 2.2 Cheat stockpile — `wifcheatstockpile.lua`

Debug "give me the loadout for mission X" tables, keyed by mission id (`<Mission>Con*`). Each holds
`tSupport` (support-item → qty), optional `tEquipment` (fuel-tank item ids), `nCash`, `nFuel`.

**Cash / fuel / equipment summary** (the headline tunables):

| Mission | nCash | nFuel | tEquipment | Ref |
|---|---:|---:|---|---|
| AllCon001 | 800000 | 1500 | FuelTank01-03 | [L1](src/vz/wifcheatstockpile.lua#L1) |
| AllCon002 | 1100000 | 2000 | FuelTank01-04 | [L37](src/vz/wifcheatstockpile.lua#L37) |
| AllCon003 | 2000000 | 2600 | FuelTank01-05 | [L84](src/vz/wifcheatstockpile.lua#L84) |
| ChiCon001 | 800000 | 1500 | FuelTank01-03 | [L137](src/vz/wifcheatstockpile.lua#L137) |
| ChiCon002 | 1100000 | 2000 | FuelTank01-04 | [L173](src/vz/wifcheatstockpile.lua#L173) |
| ChiCon003 | 2000000 | 2600 | FuelTank01-05 | [L218](src/vz/wifcheatstockpile.lua#L218) |
| GurCon001 | 400000 | 600 | FuelTank01-02 | [L266](src/vz/wifcheatstockpile.lua#L266) |
| GurCon002 | 300000 | 400 | FuelTank01-03 | [L285](src/vz/wifcheatstockpile.lua#L285) |
| GurCon050 | — | — | (support only) | [L306](src/vz/wifcheatstockpile.lua#L306) |
| GurCon052 | — | — | (support only) | [L319](src/vz/wifcheatstockpile.lua#L319) |
| GurCon005 | — | — | (support only) | [L333](src/vz/wifcheatstockpile.lua#L333) |
| JetCon001 | 350000 | 500 | FuelTank01-03 | [L349](src/vz/wifcheatstockpile.lua#L349) |
| OilCon001 | 250000 | 400 | FuelTank01 | [L369](src/vz/wifcheatstockpile.lua#L369) |
| OilCon003 / 050 / 051 / 052 | — | — | (support only) | [L385](src/vz/wifcheatstockpile.lua#L385) |
| PmcCon002 | 500000 | 700 | FuelTank01-03 | [L438](src/vz/wifcheatstockpile.lua#L438) |
| PmcCon003 | 800000 | 1500 | FuelTank01-04 | [L474](src/vz/wifcheatstockpile.lua#L474) |
| PmcCon004 | **225000** | **3000** | FuelTank01-05 | [L507](src/vz/wifcheatstockpile.lua#L507) |
| PirCon051 | — | — | `{gl=1, daisycutter=1}` | [L560](src/vz/wifcheatstockpile.lua#L560) |
| PirCon052 | — | — | surgicalstrike/patrolboatvz/c4/strategicmissile | [L561](src/vz/wifcheatstockpile.lua#L561) |

**Sample `tSupport` (GurCon001, [L266-284](src/vz/wifcheatstockpile.lua#L266)):**
`tankbuster=1, combatairpatrol=2, piranha=2, artillery=4, offroadmotorcyclegr=1, m113gr=1, m15150calgr=1, m35guntruckgr=1, gr=1, lightmg=1, c4=3, turbosquidoc=1`.

> **Note (likely data bug):** several `tSupport` tables list the same key twice (e.g. AllCon002 has two
> `combatairpatrol`, `gl`, `covert`, `lightmg`, `c4` entries — [L41-73](src/vz/wifcheatstockpile.lua#L41));
> in Lua the last literal wins, so the duplicate top entries are dead. Many tables append the same
> "common GR/vehicle" block. `tankbuster`/`bunkerbuster` appear repeated across blocks too.

**Aliases ([L567-582](src/vz/wifcheatstockpile.lua#L567))** — these missions reuse `PmcCon003` wholesale:
`AllCon008, AllCon050, AllCon052, AllCon053, AllJob002, AllJob003, AllJob010, AllJob020, ChiCon050,
ChiCon051, ChiCon008, ChiCon009, ChiJob002, ChiJob003, ChiJob010, ChiJob020 = PmcCon003`.

### 2.3 Recommendation data — `wifrecommendationdata.lua`

`_tRecommendations` ([L6-94](src/vz/wifrecommendationdata.lua#L6)) — per-mission recommended support items
(id → desired qty), shown on the PDA map. Imports `MrxFactionManager`, `MrxPmc`, `MrxRewardData`,
`MrxShop`, `MrxSupportData` ([L1-5](src/vz/wifrecommendationdata.lua#L1)).

| Mission | Recommendations | Ref |
|---|---|---|
| OilJob008 | `c4=3` | [L7](src/vz/wifrecommendationdata.lua#L7) |
| OilCon001 | gl=1, extgl=1, upcombatairpatrol=2 | [L8](src/vz/wifrecommendationdata.lua#L8) |
| OilCon051 | c4=1 | [L13](src/vz/wifrecommendationdata.lua#L13) |
| OilCon003 | extgl=1 | [L14](src/vz/wifrecommendationdata.lua#L14) |
| OilCon052 | uptankbuster=1, artillery=3, stingrayii=1 | [L15](src/vz/wifrecommendationdata.lua#L15) |
| GurJob020 | artillery=3 | [L20](src/vz/wifrecommendationdata.lua#L20) |
| GurCon002 | uptankbuster=3, c4=2, upcombatairpatrol=1 | [L21](src/vz/wifrecommendationdata.lua#L21) |
| GurCon001 | artillery=4, piranha=2, upcombatairpatrol=2, c4=3 | [L26](src/vz/wifrecommendationdata.lua#L26) |
| GurCon050 | uptankbuster=1, c4=1 | [L32](src/vz/wifrecommendationdata.lua#L32) |
| GurCon005 | sniperch=1, coandaattack=1 | [L33](src/vz/wifrecommendationdata.lua#L33) |
| GurCon052 | daisycutter=1, endriagoattack=1 | [L34](src/vz/wifrecommendationdata.lua#L34) |
| PmcCon002 | artillery=3, patrolboatvz=1, alouette3transportvz=1, sniperru=2, c4=2, pr=1 | [L35](src/vz/wifrecommendationdata.lua#L35) |
| PirCon051 | gl=1, daisycutter=1 | [L43](src/vz/wifrecommendationdata.lua#L43) |
| PirCon052 | artillery=1, patrolboatvz=1, c4=1, strategicmissile=1 | [L44](src/vz/wifrecommendationdata.lua#L44) |
| JetCon001 | mi35=2, patrolboatvz=2, artillery=2 | [L50](src/vz/wifrecommendationdata.lua#L50) |
| PmcCon003 | alouette3superiority=2, combatairpatrol=2, tankbuster=2 | [L55](src/vz/wifrecommendationdata.lua#L55) |
| AllJob020 | surgicalstrike=3 | [L60](src/vz/wifrecommendationdata.lua#L60) |
| AllCon002 | smartbomb=3, laserguidedbomb=3, laviiimgs=1 | [L61](src/vz/wifrecommendationdata.lua#L61) |
| AllCon001 | laserguidedbomb=3, carpetbomb=1, wz10=2, atal=2, dinghy=2 | [L66](src/vz/wifrecommendationdata.lua#L66) |
| AllCon003 | moab=1, tankbuster=2, laserguidedbomb=2, surgicalstrike=3 | [L73](src/vz/wifrecommendationdata.lua#L73) |
| ChiJob020 | fuelairbomb=3 | [L79](src/vz/wifrecommendationdata.lua#L79) |
| ChiCon001 | rocketartillery=3, mh53j=1, cruisemissile=3, atch=2 | [L80](src/vz/wifrecommendationdata.lua#L80) |
| ChiCon002 | carpetbomb=2, strategicmissile=3, fuelairbomb=5, cruisemissile=3, atch=3 | [L86](src/vz/wifrecommendationdata.lua#L86) |
| ChiCon003 | fuelairbomb=3, smartbomb=3 | [L93](src/vz/wifrecommendationdata.lua#L93) |

`GenerateRecommendationString` ([L100](src/vz/wifrecommendationdata.lua#L100)) builds the checklist string;
`_FormatLineItem` ([L119](src/vz/wifrecommendationdata.lua#L119)) prepends type icons
(`Airstrike=[airstrike]`, `Supply=[supply]`, `Light=[vehmlight]`, `Heavy=[vehmheavy]`,
`Civilian=[vehcivilian]`, `Boat=[vehboat]`, `Heli=[vehheli]` — [L130-138](src/vz/wifrecommendationdata.lua#L130)),
marks `[check1]`/`[check0]` against `MrxPmc.GetSupportQty`, and lists stocking factions
(order: Pmc, Oil, Gur, Pir, All, Chi — [L146-153](src/vz/wifrecommendationdata.lua#L146)).

### 2.4 Starter / boss data — `wifstarterdata.lua`

Faction-contact ("starter") definitions, keyed `<Faction>Starter<N>` plus PMC bosses. Common fields:
`sPlayerVisibleName`, `sVoBankName`, `sHqName`, `tActors{Starter={sTemplate,sPosition}}`,
`tAssetPreload{wavebank,soundbank}`, `sFaceFxSet`, `tCardData`, `bShop`, `bBoss`, `bFemale`.

| Starter | sVoBankName | sHqName | sTemplate | flags | Ref |
|---|---|---|---|---|---|
| AllStarter0 | — | AllHq | Allied Boss (Invincible) | bBoss | [L1](src/vz/wifstarterdata.lua#L1) |
| AllStarter1 | Nicholas | AllOutpost1 | Allied Starter 01 | bShop | [L12](src/vz/wifstarterdata.lua#L12) |
| AllStarter2 | Conrad | AllOutpost2 | Allied Starter 02 | bShop | [L42](src/vz/wifstarterdata.lua#L42) |
| AllStarter3 | Patterson | AllOutpost3 | Allied Starter 05 | bShop, bFemale | [L72](src/vz/wifstarterdata.lua#L72) |
| AllStarter4 | Lo | AllOutpost4 | Allied Starter 04 | bShop | [L103](src/vz/wifstarterdata.lua#L103) |
| ChiStarter0 | — | ChiHq | Chinese Boss (Invincible) | bBoss | [L133](src/vz/wifstarterdata.lua#L133) |
| ChiStarter1 | Chan | ChiOutpost1 | Chinese Starter 03 | bShop | [L144](src/vz/wifstarterdata.lua#L144) |
| ChiStarter2 | Chu | ChiOutpost2 | Chinese Starter 04 | bShop | [L174](src/vz/wifstarterdata.lua#L174) |
| ChiStarter3 | Sun | ChiOutpost3 | Chinese Starter 03 | bShop | [L204](src/vz/wifstarterdata.lua#L204) |
| ChiStarter4 | Lee | ChiOutpost4 | Chinese Starter 04 | bShop | [L234](src/vz/wifstarterdata.lua#L234) |
| GurStarter0 | — | GurHq | Guerilla Boss | bBoss, bFemale | [L264](src/vz/wifstarterdata.lua#L264) |
| GurStarter1 | Diaz | GurOutpost1 | Guerilla Starter 01 | bShop | [L276](src/vz/wifstarterdata.lua#L276) |
| GurStarter2 | Huang | GurOutpost2 | Guerilla Starter 03 | bShop (name=`[SG3.Name]`) | [L306](src/vz/wifstarterdata.lua#L306) |
| GurStarter4 | Vega | GurOutpost4 | Guerilla Starter 04 | bShop | [L336](src/vz/wifstarterdata.lua#L336) |
| GurStarter5 | Vargas | GurOutpost5 | Guerilla Starter 05 | bShop, bFemale | [L366](src/vz/wifstarterdata.lua#L366) |
| OilStarter0 | — | OilHq | OC Boss (phone) + Shredder actor | bBoss, bFemale | [L397](src/vz/wifstarterdata.lua#L397) |
| OilStarter1 | Marlowe | OilOutpost1 | OC Starter 1 | bShop | [L413](src/vz/wifstarterdata.lua#L413) |
| OilStarter2 | Wahlquist | OilOutpost2 | OC Starter 2 | bShop | [L443](src/vz/wifstarterdata.lua#L443) |
| OilStarter3 | Kresge | OilOutpost3 | OC Starter 3 | bShop | [L473](src/vz/wifstarterdata.lua#L473) |
| OilStarter4 | McKinney | OilOutpost4 | OC Starter 4 | bShop | [L503](src/vz/wifstarterdata.lua#L503) |
| OilStarter5 | — | OilTalkbox | _global_intercomA (Invincible) | bBoss, action `[ContextAction.Talk]` | [L533](src/vz/wifstarterdata.lua#L533) |
| PirStarter1 | Devilbwoy | PirOutpost1 | Pirate Starter 01 | bShop | [L544](src/vz/wifstarterdata.lua#L544) |
| PirStarter3 | Jane | PirOutpost3 | Pirate Starter 03 | bShop, bFemale | [L574](src/vz/wifstarterdata.lua#L574) |
| PirStarter4 | Stoosh | PirOutpost4 | Pirate Starter 04 | bShop, bFemale | [L605](src/vz/wifstarterdata.lua#L605) |
| JetBoss | — | JetHq | Recruit Misha Milanich | bBoss | [L636](src/vz/wifstarterdata.lua#L636) |
| MecBoss | — | MecHq | Recruit Eva Navarro (+ MonsterV1-4 unlockables) | bBoss, bFemale | [L646](src/vz/wifstarterdata.lua#L646) |

**PMC bosses** (system-flag bundles, [L686-711](src/vz/wifstarterdata.lua#L686)):

| Boss | Flags | sFaceFxSet |
|---|---|---|
| PmcBoss | bPmcStarter, bHintSystem, bBribeSystem, bFemale | Global_Job_Briefing_Fiona |
| HelPmcBoss | bPmcStarter, bHintSystem, bTransitSystem | Global_Job_Briefing_Ewan |
| MecPmcBoss | bPmcStarter, bHintSystem, bGarageSystem, bCustomVehicleShop, bFemale | Global_Job_Briefing_Eva |
| JetPmcBoss | bPmcStarter, bHintSystem | Global_Job_Briefing_Misha |

`MecBoss` unlockable actors ([L653-672](src/vz/wifstarterdata.lua#L653)): `MonsterV1`=Monster truck phase1,
`MonsterV2`=phase2, `MonsterV3`=Monster truck, `MonsterV4`=`_merida_pmcautoshop_sportscar`
(each gated by `sUnlockKey`).

`_sStarters` ([L712-743](src/vz/wifstarterdata.lua#L712)) is the master list (30 ids).
`Init()` ([L745](src/vz/wifstarterdata.lua#L745)) groups starters by faction and, for non-boss starters
with a `sVoBankName`, synthesizes `tBriefingWrapper` greeting/goodbye VO cue trees
([L795-839](src/vz/wifstarterdata.lua#L795)) using the per-character suffix convention
(`<VoBank>.ChrisHappyOnce01`, `.Happy01..03`, `.Goodbye01..03`, `.NoJob01`, `.ActiveJob01`).
`GetPlayerVisibleName` ([L845](src/vz/wifstarterdata.lua#L845)) reads `_THIS[sStarterId].sPlayerVisibleName`.

### 2.5 HQ data — `wifhqdata.lua`

`_tHqConfigs` ([L1-551](src/vz/wifhqdata.lua#L1)) — per-HQ/outpost interior template, portal points, PDA/radar
icons, atmosphere, and **landing-zone numbers** (the main tunables here). Accessors: `GetHqConfigFromId`,
`GetHqIndexFromId`, `GetHqIdFromIndex` ([L553-577](src/vz/wifhqdata.lua#L553)).

Landing-zone / atmosphere / parking summary (selected — full set in source):

| HQ id | sAtmosphere | nLandingZone / nAltLandingZone | sLzUnlockStyle | sParkingLot | Ref |
|---|---|---|---|---|---|
| AllHq | all | nAlt=7 | — | 07_all_hq_parking | [L2](src/vz/wifhqdata.lua#L2) |
| AllOutpost1 | small | 7 | visit | 07_all_hq_parking | [L23](src/vz/wifhqdata.lua#L23) |
| AllOutpost2 | small | 20 | auto | 20_all_con050_parking | [L44](src/vz/wifhqdata.lua#L44) |
| AllOutpost3 | small | 22 | auto | 22_all_con052_parking | [L65](src/vz/wifhqdata.lua#L65) |
| AllOutpost4 | small | 21 | auto | 21_all_con053_parking | [L86](src/vz/wifhqdata.lua#L86) |
| ChiHq | chi | 12 (bWatchBuildingHealth) | visit | 12_chi_hq_lz_playerone | [L107](src/vz/wifhqdata.lua#L107) |
| ChiOutpost1 | small | 30 | visit | 30_chi_hqb_parking | [L130](src/vz/wifhqdata.lua#L130) |
| ChiOutpost2-4 | small | 23 / 24 / 25 | auto | 23/24/25_chi_con*_parking | [L151](src/vz/wifhqdata.lua#L151) |
| GurHq | gur | nAlt=5, nRotation=180 | — | 05_gur_hq_parking | [L214](src/vz/wifhqdata.lua#L214) |
| GurOutpost1 | gur | 5 | visit | 05_gur_hq_parking | [L236](src/vz/wifhqdata.lua#L236) |
| GurOutpost2 | gur | 4 | auto | 04_mer_white_parking | [L257](src/vz/wifhqdata.lua#L257) |
| GurOutpost4/5 | gur | 18 / 17 | auto | 18/17_gur_con*_parking | [L278](src/vz/wifhqdata.lua#L278) |
| OilHq | oil | 2 | — | 02_oil_hq_parking | [L320](src/vz/wifhqdata.lua#L320) |
| OilOutpost1-4 | small | 29 / 15 / 3 / 16 | visit/auto | various | [L341](src/vz/wifhqdata.lua#L341) |
| OilTalkbox | oiljob | — (nDrawDistance=500) | — | 02_oil_talkbox_parking | [L425](src/vz/wifhqdata.lua#L425) |
| PirOutpost1 | pir | 8 | visit | 08_pir_hq_parking | [L451](src/vz/wifhqdata.lua#L451) |
| PirOutpost3/4 | pir | 27 / 28 | auto | 27/28_pir_con*_parking | [L472](src/vz/wifhqdata.lua#L472) |
| JetHq | pir | — | — | 08_pir_jet_parking | [L514](src/vz/wifhqdata.lua#L514) |
| MecHq | mec | nAlt=6 | — | 06_gua_upperclass_parking | [L532](src/vz/wifhqdata.lua#L532) |

> `nDrawDistance=500` ([L447](src/vz/wifhqdata.lua#L447)) is the only draw-distance override.
> `OilTalkbox` sets `sAtmosphere` twice (`small` then `oiljob`, [L446-448](src/vz/wifhqdata.lua#L446)) — last wins.
> Radar icons follow `MiniMap_Icon_Faction_<AN|CH|GR|OC|PR>` (+ `_locked`); PMC bosses use
> `MiniMap_Icon_<Misha|Eva>` / `HUD_PMC_<Misha|Eva>`.

### 2.6 Briefing data — `wifbriefingdata.lua` (338 KB, VO sequences)

This is **not** a small value table — it is the mission-briefing **voice-over sequence tree** (largest file in the
group). Header enum ([L1-3](src/vz/wifbriefingdata.lua#L1)): `knContact=1`, `knSimple=2`, `knRecruit=3`.
`Intros` ([L4-145](src/vz/wifbriefingdata.lua#L4)) holds per-faction intro cinematics; each `tSequence` is an
ordered list of `{sSpeaker, sCue}` lines, raw floats = pauses (e.g. `0.1`, [L18](src/vz/wifbriefingdata.lua#L18)),
and `{sFlashFile, nTime}` flash overlays with **`nTime` durations** (Gur=35 [L14], Pir=35 [L54],
AllChi=50 [L84]). Accessors: `GetIntroIdByIndex` ([L147](src/vz/wifbriefingdata.lua#L147)),
`GetIntroIndexById` ([L158](src/vz/wifbriefingdata.lua#L158)).

The bulk ([L169+](src/vz/wifbriefingdata.lua#L169)) is per-mission VO trees keyed by mission id
(`AllCon001` @ [L169](src/vz/wifbriefingdata.lua#L169), `AllCon002` @ L1130, `AllCon003` @ L2916,
`ChiCon001` @ L3847, `ChiCon002` @ L5340, `ChiCon003` @ L6265, `GurCon001` @ L6833, `GurCon002` @ L7444,
`OilCon001` @ L8600, `OilCon002` @ L9525, `PmcCon002` @ L11248, `PmcCon003` @ L12027, `JetCon001` @ L12512,
`MecCon001` @ L14820, `OilCon021` @ L16435, …). **These `<Mission>Con*` entries are dialogue scripts, not
loadout values** — distinct from the same-named loadout tables in `wifcheatstockpile.lua`.

### 2.7 Bios — `wifbios.lua`

`_tBios` ([L42-148](src/vz/wifbios.lua#L42)) — PDA dossier entries, each `{sTitle, sText, sIcon="icon_people"}`.
Keys/titles: `Default` ([L43](src/vz/wifbios.lua#L43)), `BioChris`, `BioJennifer`, `BioMattias` (the three
playable mercs), and faction/NPC bios: `BioAcosta, BioAllies, BioBlanco, BioCarmona, BioChina, BioDevilbwoy,
BioEva, BioEwan, BioFiona, BioJoyce, BioMisha, BioPeng, BioPirates, BioPLAV, BioRubin, BioSolano, BioUP`
([L48-147](src/vz/wifbios.lua#L48)). `AddDossierEntry` ([L28](src/vz/wifbios.lua#L28)) pushes to
`Pda.Database`; `_sCurrentBio="Default"` ([L149](src/vz/wifbios.lua#L149)); `_tActiveBios`/`_nNum` track state.

### 2.8 Hints — `wifhints.lua`

`_tHints` ([L131-392](src/vz/wifhints.lua#L131)) — freeplay VO hints per speaker. Each hint = `{sCue, [tFactionAttitudeConstraint]}`.
- **Fiona** ([L132](src/vz/wifhints.lua#L132)): 33 hints `Fiona.Hints.01..33`. Many gated by faction attitude,
  e.g. FionaHint01 requires `{"All","Pmc","<=","Hostile"}` ([L135](src/vz/wifhints.lua#L135)); FionaHint13/14
  require `{"Gur","Pmc",">=","Friendly"}` ([L201](src/vz/wifhints.lua#L201)).
- **Ewan** ([L299](src/vz/wifhints.lua#L299)): 6 hints `Ewan.Misc.Hints01..06`.
- **Eva** ([L319](src/vz/wifhints.lua#L319)): 7 hints `Eva.Misc.Hint01..06, 08` (no 07).
- **Misha** ([L342](src/vz/wifhints.lua#L342)): 16 hints `Misha.Misc.Hint01..16`.

`_TestHintConstraints` ([L49](src/vz/wifhints.lua#L49)) checks `MrxFactionManager.TestAttitude`;
`GetHint` ([L17](src/vz/wifhints.lua#L17)) round-robins active hints via `_tLastPlayed`. `AddActiveHint`
([L80](src/vz/wifhints.lua#L80)) calls `WifFreePlay.StartNag()`. Imports `MrxFactionManager`, `WifFreePlay`.

### 2.9 Freeplay nag — `wiffreeplay.lua`

Tunable nag timings ([L8-10](src/vz/wiffreeplay.lua#L8)):
`_knInitialDelay=60`, `_knSubsequentDelay=600`, `_knRetryDelay=30` (seconds).
`StartNag`→`_CreateNagTimer(60)` ([L12](src/vz/wiffreeplay.lua#L12)); on success re-arms at 600s, on retry 30s.
Nag picks a random cue from `{"Fiona.Misc.NoState01","Fiona.Misc.NoState02"}` ([L60-63](src/vz/wiffreeplay.lua#L60)).
`_TestNagConditions` ([L79](src/vz/wiffreeplay.lua#L79)) requires player free, not in hijack/HQ/PMC-interior,
and `WifHints.HasHint("Fiona")`. Imports: `MrxActionHijack, MrxHqManager, MrxPlayState, MrxUtil,
MrxVoSequence, WifHints, WifPmcInterior`.

### 2.10 PMC garage — `wifpmcgarage.lua`

Vehicle-storage system at the PMC HQ. Key constants:
`_ksFionaCar="Phoenix (Racing)"` ([L8](src/vz/wifpmcgarage.lua#L8)), `_knMaxVehicleSlots=3`
([L106](src/vz/wifpmcgarage.lua#L106)), region ids `_kvGarage=1, _kvHelipad=2, _kvDock=3`.

`_tDropOffs` ([L22-47](src/vz/wifpmcgarage.lua#L22)) carries the **drop-off search radii**:
Garage=`5`, Helipad=`15`, Dock=`10` (the `[2]` element of each entry).
`_tSpawnPoints` ([L48-76](src/vz/wifpmcgarage.lua#L48)) starts with a hero-count per region (Garage=`6`,
Helipad=`4`, Dock=`4`). Three garage doors with region-boundary auto open/close ([L77-90](src/vz/wifpmcgarage.lua#L77)).

Garage category mapping ([L194-199](src/vz/wifpmcgarage.lua#L194)): Garage→`Civilian`, Helipad→`Helicopters`,
Dock→`Boats`; accepts car/tank in garage, helicopter on helipad (not while flying), boat at dock
([L591-609](src/vz/wifpmcgarage.lua#L591)). **Destroying Fiona's car costs `-10000`** via
`MrxPmc.AddCashQty(-10000, true, "[Garage.replacefionacar]")` ([L455](src/vz/wifpmcgarage.lua#L455)).
Fade timings: vehicle fade-out `0.2` / `0.3`, cleanup timer `0.03`, add-complete timer `0.5`.

### 2.11 PMC interior — `wifpmcinterior.lua`

`_tStarters` ([L25-54](src/vz/wifpmcinterior.lua#L25)) maps each PMC boss to its interior source object,
layer name, briefing locator and `sWldBlpTexture` (HUD_PMC_Fiona/Ewan/Eva/Misha).
`_tPortalData` ([L56+](src/vz/wifpmcinterior.lua#L56)) defines exterior↔interior portal hotspots
(entrance/start pairs, interior exit, interior room). Heavy importer (24 modules,
[L1-24](src/vz/wifpmcinterior.lua#L1)) — interior state/layer/briefing orchestration.

### 2.12 VZ environment scripts

- **wifvzambience.lua** — `tBoundaryList={}` **empty by default** ([L1](src/vz/wifvzambience.lua#L1)); generic
  enter→`Sound.CueAmbience`, exit→`Sound.StopAmbience` boundary plumbing ([L27-32](src/vz/wifvzambience.lua#L27)).
- **wifvzatmosphere.lua** — `tBoundaryList` ([L1-13](src/vz/wifvzatmosphere.lua#L1)): `rgn_atmo_GRstripmine`
  (no-op), `rgn_atmo_GR Cave`→sky `afternoon`, `rgn_atmo_Caracas`→sky `Maracaibo`, `rgn_atmo_PMC Outpost`→
  `afternoon`. Default sky = `afternoon` ([L17](src/vz/wifvzatmosphere.lua#L17)). Setup retries every `2`s while
  loading/streaming ([L27](src/vz/wifvzatmosphere.lua#L27)).
- **wifvzboundary.lua** — `tBoundaryList` ([L5-86](src/vz/wifvzboundary.lua#L5)): ~40 POI regions; those with a
  `VO` key play a Fiona POI cue once on enter (`bVoPlayed` guard). Map label shows for `nDuration=10`s
  ([L149](src/vz/wifvzboundary.lua#L149)). Caracas `DisableDBs` boundary toggles
  `DangerousBuilding.SetRarity("all","never"/"default")` ([L102-122](src/vz/wifvzboundary.lua#L102)).
- **wifvzregionnames.lua** — region-name boundary table (same enter/exit pattern).

---

## 3. Tutorials — what each teaches + tunables

All `inherit("MrxTutorial")` @ L1. "Complete timer" = `Event.TimerRelative, {N}` seconds. Distances are
engine units.

| Script | Teaches (msg key) | Trigger | Tunables (value@line) |
|---|---|---|---|
| [airstrikeinterrupt](src/vz/wiftutorialairstrikeinterrupt.lua) | `[Tutorial.SatelliteInterrupted]` (L4) | ScriptEvent "Satellite Targetting Start"→"…Cancelled"; activates only if player took damage (L27) | complete `{10}` @L35 |
| [alarm](src/vz/wiftutorialalarm.lua) | `[Tutorial.Alarms]` (L4) | (completion only) | complete `{10}` @L8 |
| [allieshonk](src/vz/wiftutorialallieshonk.lua) | `[Tutorial.VehicleHorn.Attract]` (L40) | exit→re-enter seat 0, proximity to faction; needs `Ai.GetRelation(faction,"PMC")>0` (L84) | proximity `500` @L77; relation `>0` @L84 |
| [apc](src/vz/wiftutorialapc.lua) | `[Tutorial.APC]` (L4) | `Event.ObjectInSeat APC D E` (L8); cancel D X | — |
| [boat](src/vz/wiftutorialboat.lua) | `[Tutorial.Boat]` / PC `[SHELL.PCShell.Tutorial_Boat_PC]` (L6-7) | ObjectInSeat Boat D E | — |
| [c4](src/vz/wiftutorialc4.lua) | `[Tutorial.C4]` (L4) | WeaponEvent Equip c4, needs reserve ammo >0 (L21); complete on TriggerDetonator transition | ammo `>0` @L21 |
| [c4switch](src/vz/wiftutorialc4switch.lua) | `[Tutorial.C4Switch]` (L4) | WeaponEvent Pickup "C4 Pickup"; complete on Equip c4 | — |
| [collateraldamage](src/vz/wiftutorialcollateraldamage.lua) | `[Tutorial.Collateral]` (L4) | (manager-driven; guarded) | complete `{10}` @L15 |
| [collectibles](src/vz/wiftutorialcollectibles.lua) | `[Tutorial.Collectibles]`/`2` (L8-11) | ObjectProximity to "SpareParts" filter `<5` (L29) | proximity `5` @L29; show `{10}` @L49; end `{10}` @L63; cap `2<nCount` @L58 |
| [cooprevive](src/vz/wiftutorialcooprevive.lua) | `[Fiona.Misc.Revive01]` (L4) | (completion only) | complete `{10}` @L8 |
| [cooptether](src/vz/wiftutorialcooptether.lua) | `[Tutorial.Tether]` (L4) | (completion only) | complete `{10}` @L8 |
| [gatehonk](src/vz/wiftutorialgatehonk.lua) | `[Tutorial.GateHonk]` (L6) | Proximity to gate GUID `0x000f9a64` `<20`; needs `Player.GetVehicleDisguiseState=="true"` (L25) | gate `0x000f9a64` @L10; proximity `20` @L14 |
| [helicopter](src/vz/wiftutorialhelicopter.lua) | `[Tutorial.Helicopter]` (L4) | ObjectInSeat helicopter D E | — |
| [helirepairpad](src/vz/wiftutorialhelirepairpad.lua) | `[Tutorial.LandingZoneHealth]` (L4) | activate gated on vehicle `HasLabel "Helicopter"` (L12) | complete `{10}` @L19 |
| [lowfuel](src/vz/wiftutoriallowfuel.lua) | `[Tutorial.LowFuel]` (L4) | (completion only) | complete `{10}` @L8 |
| [nofuel](src/vz/wiftutorialnofuel.lua) | `[Tutorial.NoFuel]` (L4) | (completion only) | complete `{10}` @L8 |
| [swimming](src/vz/wiftutorialswimming.lua) | `[Tutorial.Swimming]` (L4) | HumanStateTransition →`Swim.*`; cancel on Swim→Upright/InVehicle | — |
| [tank](src/vz/wiftutorialtank.lua) | `[Tutorial.Tank]` (L4) | ObjectInSeat "Tank && !APC" D E | — |
| [tankhijack](src/vz/wiftutorialtankhijack.lua) | `[Tutorial.TankHijack]` (L5) | Proximity to "tank" `<20`; checks attitude + gunner count, needs `1<nGunners` (L34) | proximity `20` @L13; gunners `>1` @L34. Never marks complete (forces `bComplete=false` @L44) |
| [trespass](src/vz/wiftutorialtrespass.lua) | `[Tutorial.Trespassing]` (L4) | (manager-driven; guarded) | complete `{10}` @L15 |
| [vehicledisguise](src/vz/wiftutorialvehicledisguise.lua) | `[Tutorial.VehicleDisguise.Key1/2:<icon>]` (L38,L42) | `Player.VehicleDisguise` callback (L18); cancel on seat A X | end after `3<=nCount` (L68); end `{6}` @L69; hide `{10}` @L74 |
| [wheeledvehiclebasic](src/vz/wiftutorialwheeledvehiclebasic.lua) | `[Tutorial.WheeledVehicleBasic]` / PC variant (L5,L7) | ObjectInSeat Car D E / D I | — |

**Notes:** only **allieshonk** and **tankhijack** carry `Debug.Printf` (see §5). Imports occur only in
allieshonk, collectibles, gatehonk, tankhijack, vehicledisguise (`MrxTutorialManager` and/or `MrxFactionManager`).
Likely bug in **wheeledvehiclebasic** ([L26-32](src/vz/wiftutorialwheeledvehiclebasic.lua#L26)):
`ActivateTutorial2` deletes `_oActivate1` twice instead of `_oActivate2`.

---

## 4. Logging & debug markers (`Debug.Printf`)

| Source | String | Line |
|---|---|---|
| wiftutorialallieshonk | `"Tutorial - Activate tutorial : "` + bSuccess | [L86](src/vz/wiftutorialallieshonk.lua#L86) |
| wiftutorialtankhijack | `"TANK FACTION ATTITUDE! thingy:" .. sFactionAttitude` | [L28](src/vz/wiftutorialtankhijack.lua#L28) |
| wifpmcgarage | `"Pmc Garage moving to advanced mode!"` | [L119](src/vz/wifpmcgarage.lua#L119) |
| wifpmcgarage | `"Opening Garage Door " .. nIndex` / `"Closing Garage Door " .. nIndex` | [L336](src/vz/wifpmcgarage.lua#L336), [L347](src/vz/wifpmcgarage.lua#L347) |
| wifpmcgarage | `"Entered region …, slot …"` / `"Exited region …"` | [L484](src/vz/wifpmcgarage.lua#L484), [L509](src/vz/wifpmcgarage.lua#L509) |
| wifpmcgarage | `"Activating Eva…"` / `"Deactivating Eva…"` / `"Eva activate, moving…"` | [L281](src/vz/wifpmcgarage.lua#L281), [L285](src/vz/wifpmcgarage.lua#L285), [L298](src/vz/wifpmcgarage.lua#L298) |
| wifpmcgarage | `"Attemping to add … to Storage"` + many `"Failed to add - …"` reasons | [L578-636](src/vz/wifpmcgarage.lua#L578) |
| wifpmcgarage | `"Attemping to remove … from storage"` / `"Failed to remove - invalid type"` | [L641](src/vz/wifpmcgarage.lua#L641), [L651](src/vz/wifpmcgarage.lua#L651) |
| wifpmcgarage | `"… is in the way, deleting"` / `"Adding old vehicle back to storage - …"` | [L272](src/vz/wifpmcgarage.lua#L272), [L269](src/vz/wifpmcgarage.lua#L269) |
| wifpmcgarage | `"Unable to find matching support for …"` | [L696](src/vz/wifpmcgarage.lua#L696) |
| wifvzambience | `"Ambience: creating boundary check for boundary \"…\""` / `"Ambience: … enter/exit (…)"` | [L12](src/vz/wifvzambience.lua#L12), [L26](src/vz/wifvzambience.lua#L26) |
| wifvzatmosphere | `"Atmosphere: default VZ settings"` / `"Atmosphere: creating boundary check …"` / `"Atmosphere: … enter/exit"` | [L16](src/vz/wifvzatmosphere.lua#L16), [L38](src/vz/wifvzatmosphere.lua#L38), [L52](src/vz/wifvzatmosphere.lua#L52) |
| wifvzboundary | `"Re-enabling all DBs--you have exited Caracas (or you're not there)"` | [L104](src/vz/wifvzboundary.lua#L104) |
| wifvzboundary | `"Disabling all DBs--you have entered Caracas"` | [L115](src/vz/wifvzboundary.lua#L115) |

The `wif*data` pure-data scripts (equipment/starter/cheat/hq/recommendation/bios/hints/briefing) contain **no**
`Debug.Printf` — they are loaded and read, not executed for side effects.

---

## 5. Cross-references & future-dev notes

**Who reads these tables**
- **Equipment** → `WifEquipmentData.GetEquipmentData(sId)` ([L142](src/vz/wifequipmentdata.lua#L142)) is the
  shop's single lookup; unlock state flows through `UnlockItem`/`IsItemUnlocked`/`IsItemNew`/`SetItemViewed`.
  Persisted via `SaveSingleton`/`LoadSingleton` (only `tUnlockStatus` survives a save).
- **Starters** → `WifPmcInterior` (imports it @ [L20](src/vz/wifpmcinterior.lua#L20) via `WifBriefingData`),
  `MrxStarterManager`. `Init()` builds the `tBriefingWrapper` cue trees consumed by the briefing system.
- **Cheat stockpile** → debug-only granter; reads support ids resolved against `MrxSupportData`,
  equipment ids against `wifequipmentdata`, and grants `nCash`/`nFuel` via `MrxPmc`.
- **Recommendations** → PDA map (`GenerateRecommendationString`), checking live stock with
  `MrxPmc.GetSupportQty` and shop availability with `MrxRewardData.GetAllPotentialShopItems`.
- **HQ data** → `WifMissionFlow` / `MrxHqManager` use `GetHqConfigFromId` for interior, portal and landing-zone.
- **Hints/Freeplay** → `WifHints.HasHint("Fiona")` gates `WifFreePlay`'s nag loop; hints filtered by
  `MrxFactionManager.TestAttitude`.

**How to add an entry**
- *New equipment:* add a key to `_tEquipment` with `sName, sDescription, sTexture, nType, nCost` (+
  `nFuelCapacity, nFuelTankId` for fuel tanks). `GetEquipmentData`/save logic pick it up automatically; no list
  to register against — only the localization keys must exist.
- *New starter/contact:* add a `<Faction>Starter<N>` table (mirror an existing entry's fields), append its id to
  `_sStarters` ([L712](src/vz/wifstarterdata.lua#L712)) **and** to the matching faction list inside `Init()`
  ([L746-789](src/vz/wifstarterdata.lua#L746)) so the briefing-wrapper VO gets built.
- *New cheat loadout:* add a `<MissionId>Con*` table (or alias to `PmcCon003` like the [L567+](src/vz/wifcheatstockpile.lua#L567) block).
- *New recommendation:* add `<MissionId> = { supportId = qty, … }` to `_tRecommendations`.
- *New HQ:* add to `_tHqConfigs` with `tInterior`, `tPortal`, icon set, `sAtmosphere`, landing-zone fields.

**Gotchas / data bugs surfaced**
- Duplicate `tSupport` keys throughout `wifcheatstockpile.lua` (last-wins; top duplicates are dead) — see §2.2.
- `OilTalkbox.sAtmosphere` set twice in `wifhqdata.lua` ([L446-448](src/vz/wifhqdata.lua#L446)).
- `GurStarter2` uses `[SG3.Name]` (not `[SG2.Name]`) — name-id off-by-one vs slot
  ([L307](src/vz/wifstarterdata.lua#L307)); `GurStarter3` does not exist (gap in `_sStarters`).
- `wiftutorialwheeledvehiclebasic` double-deletes the same activation handle (see §3 note).
- `wifvzambience.tBoundaryList` ships **empty** — ambience boundaries are data-driven but no data is wired in.

**Note on `wifmissiondata.lua` / `wifmissionflow.lua`** — present in this manifest but they are mission-registry
and flow-state-machine scripts (not value tables); they belong with the mission-system documentation group, not
the data-table dumps above. Flagged here for completeness. (`wifmissionflow.lua` is also the file whose hook-time
BINN/UCFX corruption caused the phase-10 world-load regression noted in project memory — content untouched here.)
