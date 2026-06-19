# Group 01 — Support / Economy / Delivery System

Decompiled-source reference for the Mercenaries 2: World in Flames **Support** subsystem:
the player-callable airstrikes, vehicle/supply deliveries, troop/extraction transport, the
in-world **Store** (shop) and its **economy** (cash + fuel), the data-driven catalog, and the
designator/targeting layer that all of it shares.

All clickable refs are relative to `docs/mercs2-luacd/`. Lines cited are from the unluac output
in `src/resident/`.

---

## 1. Overview

The Support system lets the player spend **cash** and **fuel** to call in airstrikes, vehicle
crate-drops, helicopter deliveries, troop reinforcements and extractions. It is a small,
self-contained class hierarchy driven by a single giant data table.

### Pipeline (catalog → purchase → equip → designate → deliver → deploy)

```
MrxSupportData (catalog)                    ← every item, its cost, its behaviour object
   │  tSupportData[id] = { sName, nCashCost, nFuelCost, nMaxStock, sType, oSupport=<behaviour> }
   │  tFreebieData[id] = { sName, nFreebieQty, oSupport }    (mission-granted free uses)
   ▼
MrxRewardData → MrxShop  (catalog → purchase)
   │  Shop.Open(vender) builds the store from unlocked items, applies faction price-scale,
   │  spends MrxPmc cash → MrxPmc.AddSupportQty(id, +n)  (adds to stockpile)
   ▼
PDA "Support Menu" → MrxSupport:Commence()  (equip → use)
   │  oSupport (a MrxSupport subclass) owns an oDesignator (smoke/laser/beacon/satellite/flare)
   ▼
MrxSupportManager  (designate → validate → cooldown)
   │  queues designation, validates the drop/landing zone (Ai.TestDropZone),
   │  enforces recruit cooldown + fuel gate, then calls oDesignator:CompleteDesignation()
   ▼
MrxSupport:BeginSupportSequence()  (consume → fire)
   │  consumes fuel / freebie / stockpile (in that priority), net-syncs, posts "SupportUsed"
   ▼
DesignationCallback()  (deliver → deploy)
      per-module: spawns the jet/heli, flies it in (Airstrike.Flyby), drops ordnance or winches
      cargo to the designated point, then GoHome() / Land() / FadeOut().
```

### Module families

| Family | Base class | Members |
|---|---|---|
| **Core base** | `MrxSupport` | every behaviour inherits it |
| **Manager / queues** | `MrxSupportManager` | recruit cooldown, designation/validation queues |
| **Catalog/data** | `MrxSupportData` | catalog `tSupportData` + freebies `tFreebieData` |
| **Store / economy** | `MrxShop`, `MrxGuiSupportShop` | purchase UI + cash/fuel spending |
| **Designators** | `MrxSupportDesignator` + Smoke/Laser/Beacon/Satellite/Flare | targeting + drop-zone validation |
| **Airstrikes** | inherit `MrxSupport` | artillery, bombingrun, bunkerbuster, carpetbomb, clusterbomb, combatairpatrol, cruisemissile, daisycutter, fuelairbomb, gunship, harmstrike, laserguidedbomb, moab, rocketartillery, satclusterbomb, satelliteguidedbomb, smartbomb, strategicmissile, surgicalstrike, tankbuster |
| **Deliveries** | `MrxSupportDelivery` → `MrxCrateDelivery`/`MrxBoatDelivery`; `MrxSupportCopterDelivery`; `MrxSoldierDelivery` | crate/vehicle/boat/heli/troop drops |
| **Pickups / transit** | `MrxSupportPickup`, `MrxMunitionsPickup`, `MrxSupportTransit` | extraction, munitions retrieval, taxi |
| **World-spawn helpers** | `MrxApcDrop`, `Paradrop`, `ParadropLocation`, `BountyCopter`, `PursuitCopter`, `SupportAirplane` | scripted (non-purchased) drops & radar blips |

---

## 2. Per-module reference

### MrxSupport — the base behaviour class
`src/resident/mrxsupport.lua` (752 lines). Every purchasable support inherits this. Holds a
designator, owner, costs, recruit, and the consume/refund/abort/go-home machinery.

Key functions:
- [mrxsupport.lua:29 `Create`](src/resident/mrxsupport.lua#L29) — prototype clone; sets delivery vehicle/bomb/owner.
- [mrxsupport.lua:87 `GetDenialCondition`](src/resident/mrxsupport.lua#L87) — returns a localised denial string (AA test, hostile faction, rearming).
- [mrxsupport.lua:170 `BeginSupportSequence`](src/resident/mrxsupport.lua#L170) — **the consume step**: spends fuel, then freebie-or-cash, then stockpile; net-syncs; `Event.Post("SupportUsed")`.
- [mrxsupport.lua:222 `Configure`](src/resident/mrxsupport.lua#L222) / [228 `Commence`](src/resident/mrxsupport.lua#L228) — entry point; attaches designator completion callback to `BeginSupportSequence`.
- [mrxsupport.lua:256 `BlipAircraft`](src/resident/mrxsupport.lua#L256) — radar blip with death/hibernation cleanup.
- [mrxsupport.lua:303 `AddAntiAir`](src/resident/mrxsupport.lua#L303) / [331 `TestAALevel`](src/resident/mrxsupport.lua#L331) — AA-denial bookkeeping; `basic` cascades to `medium`.
- [mrxsupport.lua:345 `DenialMessage`](src/resident/mrxsupport.lua#L345) — maps a reason code to a red `[PDA.Support.denied.*]` HUD message + VO.
- [mrxsupport.lua:398 `SynchNetImportModule`](src/resident/mrxsupport.lua#L398) / [402 `SynchNetAction`](src/resident/mrxsupport.lua#L402) — multiplayer replication of a support use.
- [mrxsupport.lua:477 `RefundCosts`](src/resident/mrxsupport.lua#L477) — refunds fuel/stockpile/freebie if the run aborts.
- [mrxsupport.lua:492 `SetupDamageEvent`](src/resident/mrxsupport.lua#L492) / [512 `Abort`](src/resident/mrxsupport.lua#L512) — aborts at <60% health; **PMC copter repair cash penalty**.
- [mrxsupport.lua:599 `GoHome`](src/resident/mrxsupport.lua#L599) / [661 `Land`](src/resident/mrxsupport.lua#L661) / [686 `FadeOut`](src/resident/mrxsupport.lua#L686) — flies the vehicle back to its faction LZ and despawns.
- [mrxsupport.lua:746 `GetSpawnHeight`](src/resident/mrxsupport.lua#L746) — 250 in co-op (secondary char present), else 50.

### MrxSupportManager — designation queues, recruit cooldown
`src/resident/mrxsupportmanager.lua` (387 lines).

- [mrxsupportmanager.lua:5 `CurrentlyEquippedSupport`](src/resident/mrxsupportmanager.lua#L5) — per-character equipped support.
- [mrxsupportmanager.lua:47 `ValidationQueue`](src/resident/mrxsupportmanager.lua#L47) — serialises drop-zone validation (one at a time).
- [mrxsupportmanager.lua:97 `CompleteDesignation`](src/resident/mrxsupportmanager.lua#L97) — final gate: recruit availability + **fuel gate** (`GetFuelCost() > GetFuelQty()` ⇒ deny "fuel") then starts cooldown.
- [mrxsupportmanager.lua:221 `IsRecruitAvailable`](src/resident/mrxsupportmanager.lua#L221) / [229 `StartRecruitCooldown`](src/resident/mrxsupportmanager.lua#L229) / [258 `MakeRecruitAvailable`](src/resident/mrxsupportmanager.lua#L258) — recruit state machine, hashed by `String.GetHash(sRecruit)`.
- [mrxsupportmanager.lua:307 `SupportTimer`](src/resident/mrxsupportmanager.lua#L307) — GUI-tick-driven countdown class used per recruit.
- [mrxsupportmanager.lua:384 `Init`](src/resident/mrxsupportmanager.lua#L384) — resets recruit state/timer tables.

### MrxSupportData — the catalog + freebies + unlock state
`src/resident/mrxsupportdata.lua` (2487 lines). The single largest file; `Init()` builds
`tSupportData` (≈120 purchasable items) and `tFreebieData` (mission-granted free uses).

- [mrxsupportdata.lua:45 `IsSupportEquippable`](src/resident/mrxsupportdata.lua#L45) — checks recruit + optional `tRequirementList`.
- [mrxsupportdata.lua:114 `Init`](src/resident/mrxsupportdata.lua#L114) — builds the entire catalog (each entry pattern shown below).
- [mrxsupportdata.lua:2211 `Init` tail loop](src/resident/mrxsupportdata.lua#L2211) — **clamps every `nMaxStock` to `_kMaxStock` (99)** and sets each oSupport's name.
- [mrxsupportdata.lua:2221 `GetFreebie`](src/resident/mrxsupportdata.lua#L2221) / [2324 `AddFreebie`](src/resident/mrxsupportdata.lua#L2324) / [2338 `RemoveFreebie`](src/resident/mrxsupportdata.lua#L2338) — grant/revoke mission free uses (net-synced).
- [mrxsupportdata.lua:2383 `Add`](src/resident/mrxsupportdata.lua#L2383) — **unlocks** items for a faction; grants `ACHIEVEMENT_DIGITAL_MAN` when all shops fully unlocked.
- [mrxsupportdata.lua:2410 `IsItemUnlocked`](src/resident/mrxsupportdata.lua#L2410) / [2418 `IsItemNew`](src/resident/mrxsupportdata.lua#L2418) / [2426 `SetItemViewed`](src/resident/mrxsupportdata.lua#L2426) — per-faction unlock/"new" badge state.
- [mrxsupportdata.lua:2459 `AddSupportData`](src/resident/mrxsupportdata.lua#L2459) — **DLC extension hook** (only works when `g_bIsDlc`).
- [mrxsupportdata.lua:2471 `GetMaxQuantity`](src/resident/mrxsupportdata.lua#L2471) — returns `_kMaxStock`.

A catalog entry is created by 3-4 lines, e.g. [mrxsupportdata.lua:128](src/resident/mrxsupportdata.lua#L128):
```lua
oSupport = mrxcratedelivery:Create()
oSupport:SetCargo("Supply Drop (AA)")
oSupport:SetCareless(true)
tSupportData.aa = { sName="[support.supply.aa.name]", sIcon="supplies_anti_air",
                    nMaxStock=99, nCashCost=15000, nFuelCost=40, oSupport=oSupport, sType="Supply" }
```

### MrxShop — store logic / purchasing (economy core)
`src/resident/mrxshop.lua` (364 lines).

- [mrxshop.lua:8 `tTypeToIcon`](src/resident/mrxshop.lua#L8) — sType → icon-tag map.
- [mrxshop.lua:21 `Init`](src/resident/mrxshop.lua#L21) — builds `_tGlobalShopList` per faction.
- [mrxshop.lua:36 `Open`](src/resident/mrxshop.lua#L36) — builds the store: applies price scale, separates unlocked/locked, sorts by cost.
- [mrxshop.lua:233 `_GetPriceScale`](src/resident/mrxshop.lua#L233) — **1.0** for custom vehicle shops, otherwise `MrxFactionManager.GetPriceScale(faction,"Pmc")`.
- [mrxshop.lua:241 `_ShopSelection`](src/resident/mrxshop.lua#L241) — **the purchase**: `nCost = base*scale*amt`; if `nCost <= MrxPmc.GetCashQty()` then add stock + subtract cash.
- [mrxshop.lua:319 `GetTotalNumberOfItems`](src/resident/mrxshop.lua#L319) / [333 `GetNumberOfPurchasedItems`](src/resident/mrxshop.lua#L333) / [341 `GetNumberOfUnlockedItems`](src/resident/mrxshop.lua#L341) — shop-completion accounting.
- [mrxshop.lua:358 `SaveSingleton`](src/resident/mrxshop.lua#L358) / [362 `LoadSingleton`](src/resident/mrxshop.lua#L362) — persistence of purchased-item set.

### MrxGuiSupportShop — the Flash "store" front-end
`src/resident/mrxguisupportshop.lua` (427 lines). Drives the `store` SWF (`sFlashFile = "store"`,
[line 7](src/resident/mrxguisupportshop.lua#L7)). Falls back to a dialog box if no SWF.

- [mrxguisupportshop.lua:9 `Create`](src/resident/mrxguisupportshop.lua#L9) — instantiates a `FlashWidget`, wires AddItem/Commence/etc.
- [mrxguisupportshop.lua:220 `_CreateShopDialogBox`](src/resident/mrxguisupportshop.lua#L220) — text fallback; color-codes by affordability (`[green]`/`[red]`).
- [mrxguisupportshop.lua:251 `_SetupShopFlash`](src/resident/mrxguisupportshop.lua#L251) — pushes `AddStockpile`(cash,fuel,fuelcap), `AddShopItem`, `AddSupportEquipped` to ActionScript; **3 equip slots** (`nSlots = 3`).
- [mrxguisupportshop.lua:357 `_FlashSupportBoughtCallback`](src/resident/mrxguisupportshop.lua#L357) — parses the buy event and calls `MrxShop._ShopSelection`.
- [mrxguisupportshop.lua:380 `_FlashSupportEquippedCallback`](src/resident/mrxguisupportshop.lua#L380) — sets the equipped support on the PDA.

### MrxSupportDesignator (base) + subclasses
`src/resident/mrxsupportdesignator.lua` (356 lines). Targeting + **drop-zone geometry tables**.

- [mrxsupportdesignator.lua:14 `GetTarget`](src/resident/mrxsupportdesignator.lua#L14) — returns `nX,nY,nZ,uGuid,uTarget` once `bDesignationComplete`.
- [mrxsupportdesignator.lua:139 `Commence`](src/resident/mrxsupportdesignator.lua#L139) — `Airstrike.EquipDesignator`, then `Weapon.SetReserveAmmo(weapon,1)`.
- [mrxsupportdesignator.lua:155 `_cargoTemplateData`](src/resident/mrxsupportdesignator.lua#L155) / [186 `_heliTemplateData`](src/resident/mrxsupportdesignator.lua#L186) — per-template drop-zone radii (see tunables §3).
- [mrxsupportdesignator.lua:273 `ValidateGroundDropZone`](src/resident/mrxsupportdesignator.lua#L273) / [297 `ValidateWaterDropZone`](src/resident/mrxsupportdesignator.lua#L297) / [301 `ValidateLandingZone`](src/resident/mrxsupportdesignator.lua#L301) — `Ai.TestDropZone` wrappers; fail ⇒ `fCallback(false,"nodrop"/"noland")`.
- [mrxsupportdesignator.lua:324 `CompleteDesignation`](src/resident/mrxsupportdesignator.lua#L324) — fires all complete-callbacks, posts `Airstrike/DesignationComplete`.

Subclasses (each overrides `Create`, `GetType`, AA level, validation fn):

| Subclass | file | `sDesignationType` | default `sAATestLevel` | validation fn | GetType |
|---|---|---|---|---|---|
| Smoke | mrxsupportdesignatorsmoke.lua | "Smoke Designator" | `"basic"` | `ValidateGroundDropZone` | "smoke" |
| Laser | mrxsupportdesignatorlaser.lua | "Laser Designator" | `"medium"` | (none) | "laser" |
| Beacon | mrxsupportdesignatorbeacon.lua | "Beacon Designator" | `"jammer"` | nil | "beacon" |
| Satellite | mrxsupportdesignatorsatellite.lua | "Satellite Designator" | `bil`*(nil, typo) | self | "satellite" |
| Flare | mrxsupportdesignatorflare.lua | "Flare Designator" | `"none"` | `ValidateWaterDropZone` | "flare" |

- Smoke colors: [mrxsupportdesignatorsmoke.lua:3 `tColorList`](src/resident/mrxsupportdesignatorsmoke.lua#L3) — red/green/blue/yellow → particle hashes; auto-removed after **10 s** ([line 74](src/resident/mrxsupportdesignatorsmoke.lua#L74)).
- Satellite designator has its own **cost/zoom/radius** (mini-game) — [mrxsupportdesignatorsatellite.lua:8](src/resident/mrxsupportdesignatorsatellite.lua#L8): `nStartZoom/nMinZoom/nMaxZoom = 170`, `nRadius = 100`, `nCost = 5000`.

### Airstrike modules (inherit MrxSupport)
All follow the same shape: `Create` builds a designator + sets recruit; `DesignationCallback`
spawns a jet via `Airstrike.Flyby(vehicle, spawnX,spawnZ, targetX,targetZ, altY, speed, DropCB,{self})`
then `DropBomb`/`Strike` spawns ordnance via `Airstrike.SpawnOrdnance/SpawnTargettedOrdnance/ConeSpawn`.

| Module | file:Create | recruit | designator | distinctive constants |
|---|---|---|---|---|
| Artillery | [mrxartillery.lua:5](src/resident/mrxartillery.lua#L5) | Fiona | Beacon | 12 shells, 8 s, 25-unit spread ([:23](src/resident/mrxartillery.lua#L23)) |
| RocketArtillery | [mrxrocketartillery.lua:6](src/resident/mrxrocketartillery.lua#L6) | Fiona | Satellite (3 sectors) | 30 shells, width 100, height 50, 8 s ([:24](src/resident/mrxrocketartillery.lua#L24)) |
| StrategicMissile | [mrxstrategicmissile.lua:8](src/resident/mrxstrategicmissile.lua#L8) | Fiona | Beacon | launch dist 500, drop dist 80, 6 shrapnel cones ([:35](src/resident/mrxstrategicmissile.lua#L35)) |
| BombingRun | [mrxbombingrun.lua:6](src/resident/mrxbombingrun.lua#L6) | Pilot | Smoke(basic) | 2 bombs, speedScale 33 ([:41](src/resident/mrxbombingrun.lua#L41)) |
| ClusterBomb | [mrxclusterbomb.lua:4](src/resident/mrxclusterbomb.lua#L4) | Pilot | Smoke(red,basic) | speedScale 35, ConeSpawn 15/30 ([:46](src/resident/mrxclusterbomb.lua#L46)) |
| SatClusterBomb | [mrxsatclusterbomb.lua:9](src/resident/mrxsatclusterbomb.lua#L9) | Pilot | Satellite (2 sectors, cost 0) | 4 ConeSpawn lines ([:58](src/resident/mrxsatclusterbomb.lua#L58)) |
| CarpetBomb | [mrxcarpetbomb.lua:4](src/resident/mrxcarpetbomb.lua#L4) | Fiona | Satellite | 7 lines, 0.35 s interval, "Support Vehicle (B2)" ([:8](src/resident/mrxcarpetbomb.lua#L8)) |
| LaserGuidedBomb | [mrxlaserguidedbomb.lua:7](src/resident/mrxlaserguidedbomb.lua#L7) | Pilot | Laser | speed 80, ±25 scatter ([:42](src/resident/mrxlaserguidedbomb.lua#L42)) |
| BunkerBuster | [mrxbunkerbuster.lua:11](src/resident/mrxbunkerbuster.lua#L11) | Pilot | Laser (inherits LGB) | staged ground explosions r=20/45/65; nuke variant r=80 ([:29](src/resident/mrxbunkerbuster.lua#L29)) |
| SmartBomb | [mrxsmartbomb.lua:6](src/resident/mrxsmartbomb.lua#L6) | Pilot | Beacon | "Smart Bomb Projectile" ([:18](src/resident/mrxsmartbomb.lua#L18)) |
| SatelliteGuidedBomb | [mrxsatelliteguidedbomb.lua:6](src/resident/mrxsatelliteguidedbomb.lua#L6) | Pilot | Satellite(cost 0, 3 sectors) | bomb speed 110 ([:51](src/resident/mrxsatelliteguidedbomb.lua#L51)) |
| DaisyCutter | [mrxdaisycutter.lua:8](src/resident/mrxdaisycutter.lua#L8) | Fiona | Smoke(basic) | "Support Vehicle (C130)", debris @150 m ([:44](src/resident/mrxdaisycutter.lua#L44)) |
| MOAB | [mrxmoab.lua:7](src/resident/mrxmoab.lua#L7) | Fiona | Smoke (inherits DaisyCutter) | "MOAB Projectile", C130 ([:1](src/resident/mrxmoab.lua#L1)) |
| FuelAirBomb | [mrxfuelairbomb.lua:6](src/resident/mrxfuelairbomb.lua#L6) | Pilot | Smoke(red,basic) | speed 60, fireball 1.6 s later ([:51](src/resident/mrxfuelairbomb.lua#L51)) |
| CruiseMissile | [mrxcruisemissile.lua:8](src/resident/mrxcruisemissile.lua#L8) | Fiona | Beacon | "Support Vehicle (Cruise Missile)" ([:44](src/resident/mrxcruisemissile.lua#L44)) |
| CombatAirPatrol | [mrxcombatairpatrol.lua:4](src/resident/mrxcombatairpatrol.lua#L4) | Pilot | Smoke(red,basic) | targets flying enemies w/in 200 ([:38](src/resident/mrxcombatairpatrol.lua#L38)) |
| Gunship | [mrxgunship.lua:5](src/resident/mrxgunship.lua#L5) | Fiona | Smoke(red,basic) | "Support Vehicle (AC130)", 4-rd salvo every 3 s ([:33](src/resident/mrxgunship.lua#L33)) |
| HARMStrike | [mrxharmstrike.lua:4](src/resident/mrxharmstrike.lua#L4) | Fiona | Beacon(advanced) | "Support Vehicle (F117)", hits AA(Medium) ([:40](src/resident/mrxharmstrike.lua#L40)) |
| SurgicalStrike | (entry only; uses an airstrike behaviour) | — | — | freebie "ChiCon001_Airstrike" qty 3 ([mrxsupportdata.lua:1848](src/resident/mrxsupportdata.lua#L1848)) |
| TankBuster | [mrxtankbuster.lua:4](src/resident/mrxtankbuster.lua#L4) | Pilot | Smoke(red,basic) | hits tanks w/in 200, kills target on hit ([:35](src/resident/mrxtankbuster.lua#L35)) |

### Delivery modules
- **MrxSupportDelivery** `src/resident/mrxsupportdelivery.lua` (210) — base crate/vehicle drop. Recruit **Copter**. [Create:18](src/resident/mrxsupportdelivery.lua#L18), [_DesignatorCallback:95](src/resident/mrxsupportdelivery.lua#L95) (spawns cargo + heli, winches to designated point), [_WaitCallback:186](src/resident/mrxsupportdelivery.lua#L186), [CargoDropped:207](src/resident/mrxsupportdelivery.lua#L207). Defaults: `nCargoDropHeight = 0.5`, `nAltitude = 250`, vehicle "UH1 Transport (PMC) (Driver)".
- **MrxCrateDelivery** `src/resident/mrxcratedelivery.lua` (16) — thin subclass; ground drop-zone validation, blue smoke, AA "none". [Create:4](src/resident/mrxcratedelivery.lua#L4).
- **MrxBoatDelivery** `src/resident/mrxboatdelivery.lua` (13) — uses **Flare** designator (water). [Create:4](src/resident/mrxboatdelivery.lua#L4).
- **MrxSupportCopterDelivery** `src/resident/mrxsupportcopterdelivery.lua` (136) — delivers a *flyable* helicopter (Ewan flies it in, lands, exits, walks off and fades). Recruit **Copter**. [Create:7](src/resident/mrxsupportcopterdelivery.lua#L7), [_VehicleLanded:73](src/resident/mrxsupportcopterdelivery.lua#L73) (refunds on failed landing), [ExitedVehicle:97](src/resident/mrxsupportcopterdelivery.lua#L97).
- **MrxSoldierDelivery** `src/resident/mrxsoldierdelivery.lua` (184) — troop reinforcements. Recruit **Fiona**. `nAltitude = 50`. [CheckForSoldiers:172](src/resident/mrxsoldierdelivery.lua#L172) caps at **<8** friendly soldiers in an 80-unit radius else denies "toomanysoldiers<Faction>"; [FollowTheLeader:155](src/resident/mrxsoldierdelivery.lua#L155) makes the squad follow the player.

### Pickup / transit modules
- **MrxSupportPickup** `src/resident/mrxsupportpickup.lua` (298) — extraction heli. Recruit **Fiona**. Per-faction arrival/incoming/takeoff VO ([tCues:10](src/resident/mrxsupportpickup.lua#L10)); 30 s idle timeout ([_VehicleLanded:235](src/resident/mrxsupportpickup.lua#L235)). Pluggable callbacks (`SetHeliLandedCB`, etc.).
- **MrxMunitionsPickup** `src/resident/mrxmunitionspickup.lua` (227) — heli retrieves tagged munitions. Recruit **Copter**, green smoke. [PickMunitionsTarget:95](src/resident/mrxmunitionspickup.lua#L95) loops over `Munitions.GetTaggedMunition()`; [Pickup:185](src/resident/mrxmunitionspickup.lua#L185) adds a **+5 faction infraction** per pickup ([:215](src/resident/mrxmunitionspickup.lua#L215)).
- **MrxSupportTransit** `src/resident/mrxsupporttransit.lua` (475) — the taxi/fast-travel heli. Recruit **Copter**, **fuel-unrestricted** (`bUnrestrictedByFuel = true`, [:34](src/resident/mrxsupporttransit.lua#L34)). `nAltitude = 250`. Opens the transit interface when the player boards ([_OpenTransitInterface:204](src/resident/mrxsupporttransit.lua#L204)); 45 s / 10 s timeouts ([:179](src/resident/mrxsupporttransit.lua#L179)/[:253](src/resident/mrxsupporttransit.lua#L253)); teleports the heli to the chosen transit point ([_StartTransit:348](src/resident/mrxsupporttransit.lua#L348)).

### Scripted / world-spawn helpers (not purchased)
- **MrxApcDrop** `src/resident/mrxapcdrop.lua` (167) — generic "fly in, deploy a squad, fly out" helper for mission scripts. Config-driven (`inDest/outDest/squadName/...`); default speeds **0.8** ([:18](src/resident/mrxapcdrop.lua#L18),[:21](src/resident/mrxapcdrop.lua#L21)), squad MoveWithinBoundary radius **8** ([:148](src/resident/mrxapcdrop.lua#L148)).
- **Paradrop** `src/resident/paradrop.lua` (66) — drops **16** paratroopers, 0.75 s apart starting at 5.25 s ([:51](src/resident/paradrop.lua#L51)).
- **ParadropLocation** `src/resident/paradroplocation.lua` (21) — flyby that triggers a paradrop plane.
- **BountyCopter** `src/resident/bountycopter.lua` (44) — drops a Blueprints/Treasure/Light-MG supply crate via winch.
- **PursuitCopter** `src/resident/pursuitcopter.lua` (121) — lands near the player, deploys passengers; **3** LZ retries ([:42](src/resident/pursuitcopter.lua#L42)).
- **SupportAirplane** `src/resident/supportairplane.lua` (66) — radar-blip skin for support aircraft; per-label icon (C130/Mig27/F35/B2/F117/A10/OV10/cruisemissile).

---

## 3. Defaults & tunables table (highest-priority)

### Global / economy constants
| Const | Value | Where |
|---|---|---|
| `_kMaxStock` (max stockpile per item) | **99** | [mrxsupportdata.lua:38](src/resident/mrxsupportdata.lua#L38); re-clamped at [:2215](src/resident/mrxsupportdata.lua#L2215) |
| `_nDefaultCooldownTime` (recruit cooldown, s) | **12** | [mrxsupportmanager.lua:219](src/resident/mrxsupportmanager.lua#L219) |
| Copter cooldown after use | **60 s** | [mrxsupport.lua:217](src/resident/mrxsupport.lua#L217) |
| `SupportTimer.nTotalTime` default | **10 s** | [mrxsupportmanager.lua:310](src/resident/mrxsupportmanager.lua#L310) |
| Spawn height (co-op / single) | **250 / 50** | [mrxsupport.lua:746](src/resident/mrxsupport.lua#L746) |
| Shop equip slots | **3** | [mrxguisupportshop.lua:261](src/resident/mrxguisupportshop.lua#L261) |
| Price scale (custom vehicle shop) | **1.0** | [mrxshop.lua:234](src/resident/mrxshop.lua#L234) |
| Price scale (faction shop) | `MrxFactionManager.GetPriceScale(faction,"Pmc")` | [mrxshop.lua:238](src/resident/mrxshop.lua#L238) |
| Default smoke color (unknown) | red `0x02f6773f` | [mrxsupportdesignatorsmoke.lua:108](src/resident/mrxsupportdesignatorsmoke.lua#L108) |
| Smoke auto-remove | **10 s** | [mrxsupportdesignatorsmoke.lua:74](src/resident/mrxsupportdesignatorsmoke.lua#L74) |
| Abort health threshold | **<60 %** of current HP | [mrxsupport.lua:508](src/resident/mrxsupport.lua#L508) |
| PMC copter-repair penalty | `(maxHP − HP*200)` cash | [mrxsupport.lua:577](src/resident/mrxsupport.lua#L577) |
| Unlock-status enums | new=1, viewed=2 | [mrxsupportdata.lua:2380](src/resident/mrxsupportdata.lua#L2380) |

### Catalog cost/fuel ranges (`tSupportData`, `MrxSupportData.Init`)
Every entry has `nMaxStock = 99` (later forced to `_kMaxStock`). Cash + fuel vary by item:

| Quantity | Range observed | Notes |
|---|---|---|
| `nCashCost` | **5,000 … 1,000,000** | cheapest = supply crates (blanco/cqb/fiona/oc/gr, 5000); priciest = 1,000,000 ([:1718](src/resident/mrxsupportdata.lua#L1718),[:1794](src/resident/mrxsupportdata.lua#L1794)) |
| `nFuelCost` | **40 … 900** | crates 40; FuelAirBomb **900** ([:707](src/resident/mrxsupportdata.lua#L707)); MOAB 400; M1A2 240 |
| `sType` | `Supply / Light / Heavy / Civilian / Boat / Heli / Airstrike` | drives shop icon ([mrxshop.lua:8](src/resident/mrxshop.lua#L8)) |

Representative anchor values (all in `tSupportData`):
| Item | id | nCashCost | nFuelCost | sType | line |
|---|---|---|---|---|---|
| Anti-air supply | `aa` | 15000 | 40 | Supply | [:136](src/resident/mrxsupportdata.lua#L136) |
| Blanco crate (cheapest) | `blanco` | 5000 | 40 | Supply | [:366](src/resident/mrxsupportdata.lua#L366) |
| AH-1Z heli | `ah1z` | 200000 | 180 | Heli | [:148](src/resident/mrxsupportdata.lua#L148) |
| Artillery | `artillery` | 150000 | 140 | Airstrike | [:309](src/resident/mrxsupportdata.lua#L309) |
| BunkerBuster | `bunkerbuster` | 200000 | 300 | Airstrike | [:412](src/resident/mrxsupportdata.lua#L412) |
| CarpetBomb | `carpetbomb` | 250000 | 280 | Airstrike | [:436](src/resident/mrxsupportdata.lua#L436) |
| CruiseMissile | `cruisemissile` | 400000 | 160 | Airstrike | [:581](src/resident/mrxsupportdata.lua#L581) |
| FuelAirBomb | `fuelairbomb` | 200000 | **900** | Airstrike | [:706](src/resident/mrxsupportdata.lua#L706) |
| M1A2 tank | `m1a2` | 425000 | 240 | Heavy | [:1090](src/resident/mrxsupportdata.lua#L1090) |
| MOAB | `moab` | 500000 | 400 | Airstrike | [:1235](src/resident/mrxsupportdata.lua#L1235) |
| (max-cost item) | — | 1000000 | — | — | [:1718](src/resident/mrxsupportdata.lua#L1718),[:1794](src/resident/mrxsupportdata.lua#L1794) |

### Freebie quantities (`tFreebieData`, mission-granted free uses)
`nFreebieQty` observed: **1, 2, 3, 4, 10**, or `nil` (unlimited until removed). Examples:
| Freebie id | nFreebieQty | line |
|---|---|---|
| `OC_ClusterBomb` / `OC_BombingRun` | 1 | [:1907](src/resident/mrxsupportdata.lua#L1907) |
| `GurCon002_Artillery` | 3 | [:1931](src/resident/mrxsupportdata.lua#L1931) |
| `ChiCon002_Bombs` / `AL_LaserGuidedBomb` | 4 | [:1939](src/resident/mrxsupportdata.lua#L1939),[:2202](src/resident/mrxsupportdata.lua#L2202) |
| `OilCon001_Crate` | 4 | [:1950](src/resident/mrxsupportdata.lua#L1950) |
| `Ramp Delivery` (TEMP) | 10 | [:1973](src/resident/mrxsupportdata.lua#L1973) |
| Extraction_* / SoldierDelivery_* / *_Delivery | nil (unlimited) | [:2007](src/resident/mrxsupportdata.lua#L2007)+ |

### Designator drop-zone geometry
`_cargoTemplateData` ([mrxsupportdesignator.lua:155](src/resident/mrxsupportdesignator.lua#L155)):
| template | nRadius | nHeightTolerance | bWater |
|---|---|---|---|
| default | 3 | 2 | false |
| box (+15 named hash aliases) | 2 | 2 | false |
| Jetski | 3 | 2 | true |

`_heliTemplateData` ([mrxsupportdesignator.lua:186](src/resident/mrxsupportdesignator.lua#L186)) — by vehicle GUID hash:
| key | nHeightMax | nInnerRadius | nOuterRadius | inner/outer HeightTol |
|---|---|---|---|---|
| default | 16 | 4 | 13 | 1 / 2.5 |
| 0x80009467 / 0x80009466 | 20 | 6 | 19 | 1 / 2.5 |
| 0x800081FB/FA/0x80008204 | 14 | 3 | 8 | 1 / 2.5 |
| 0x80006F71 (large, e.g. Mi-26) | 29 | 8 | 24 | 1 / 2.5 |
| `nWinchLength` (added to outer tolerance) | **8** | — | — | [:154](src/resident/mrxsupportdesignator.lua#L154) |

### Satellite designator / mini-game
| Const | Value | Line |
|---|---|---|
| `nStartZoom / nMinZoom / nMaxZoom` | 170 | [mrxsupportdesignatorsatellite.lua:8](src/resident/mrxsupportdesignatorsatellite.lua#L8) |
| `nRadius` | 100 | [:11](src/resident/mrxsupportdesignatorsatellite.lua#L11) |
| `nCost` (default satellite use) | 5000 | [:13](src/resident/mrxsupportdesignatorsatellite.lua#L13) |
| SmartBomb satellite cost default | 1000 | [mrxsmartbomb.lua](src/resident/mrxsatelliteguidedbomb.lua#L11) (`nCost or 1000`) |
| SatClusterBomb / SatGuidedBomb cost | 0 (free) | [mrxsatclusterbomb.lua:26](src/resident/mrxsatclusterbomb.lua#L26), [mrxsatelliteguidedbomb.lua:11](src/resident/mrxsatelliteguidedbomb.lua#L11) |

### Mini-game sector tables (satellite "lock" angles)
- RocketArtillery: `{35,55},{170,190},{305,325}` ([mrxrocketartillery.lua:11](src/resident/mrxrocketartillery.lua#L11))
- SatClusterBomb: `{45,135},{225,315}` ([mrxsatclusterbomb.lua:22](src/resident/mrxsatclusterbomb.lua#L22))
- SatelliteGuidedBomb (sat): `{45,90},{152,203},{270,315}` ([mrxsatelliteguidedbomb.lua:13](src/resident/mrxsatelliteguidedbomb.lua#L13))
- SmartBomb: `{135,225},{-45,45}` ([mrxsmartbomb.lua](src/resident/mrxsmartbomb.lua) — note: actual SmartBomb uses Beacon)

### Per-airstrike timing/spread constants
| Module | shells/lines | time/interval | width/spread | speed |
|---|---|---|---|---|
| Artillery | 12 shells | 8 s (start +3) | 25 | — |
| RocketArtillery | 30 shells | 8 s | width 100, height 50 | — |
| CarpetBomb | 7 lines | 0.35 s interval | — | — |
| ClusterBomb | — | — | cones 15/30 | speedScale 35 |
| BombingRun | 2 bombs | — | — | speedScale 33 |
| FuelAirBomb | — | fireball +1.6 s | — | speedScale 60 |
| Gunship | 4-rd salvo / 3 s | 0.25 s/rd | ±25 | 100 |
| LaserGuidedBomb | 1 | — | ±25 | 80 |
| BunkerBuster | staged | 0.5/1/1.5/2.75 s | r 20/45/65; nuke 80 | — |
| Strategic | — | launch dist 500, drop 80 | 6 cones | — |

---

## 4. Logic & formulas

### Purchase gate (the "can I afford it" check)
[mrxshop.lua:241 `_ShopSelection`](src/resident/mrxshop.lua#L241):
```lua
local nCost = tSupport.nCashCost * nPriceScale * nAmt
if nCost <= MrxPmc.GetCashQty() then
   MrxPmc.AddSupportQty(sId, nAmt, false, nCost)   -- add to stockpile
   MrxPmc.AddCashQty(-nCost, nil, "[Generic.ShopItems]")
   ...
```
A **free item** is therefore any item whose effective `nCashCost*scale` is `0` (or whose
`nAmt = 0`) — the `nCost <= GetCashQty()` test passes unconditionally and `AddCashQty(0)` is a
no-op. This is the mechanism by which satellite-cost-0 / freebie items are "purchased" for free.

### Use/consume priority (the spend order on firing)
[mrxsupport.lua:170 `BeginSupportSequence`](src/resident/mrxsupport.lua#L170):
1. **Fuel** first: `nFuelUsed = min(nFuelCost, GetFuelQty())`, subtract it (records `nFuelConsumed`).
2. Then **one** of, in order:
   - if a **freebie** exists for this support name (`GetFreebieQty` non-nil):
     - if `< 1` free left ⇒ pay **cash** (`AddCashQty(-nCashCost)`),
     - else consume a freebie (`AddFreebieQty(name,-1)`).
   - else consume from **stockpile** (`AddSupportQty(name,-1)`).
3. Net-sync (`Net.SendEvent_Support`), `Event.Post("SupportUsed", self)`, Copter cooldown (60 s).

`RefundCosts` ([:477](src/resident/mrxsupport.lua#L477)) reverses whichever of fuel/stockpile/freebie was consumed.

### Designation / validation flow (manager)
`OnDesignate` → AA test (`TestAALevel`) → if a validation fn exists, enqueue in `ValidationQueue`
(serialised) → `Ai.TestDropZone` → on success `CompleteDesignation`:
- recruit must be available, else deny;
- **fuel gate**: `GetFuelCost() > GetFuelQty()` and not `bUnrestrictedByFuel` ⇒ deny "fuel"
  ([mrxsupportmanager.lua:114](src/resident/mrxsupportmanager.lua#L114));
- start recruit cooldown (Copter uses `-1` = manual release on landing).

### Recruit cooldown state machine
Hashed per recruit name. `StartRecruitCooldown` sets state=false, net-syncs, starts a
`SupportTimer` (GUI-tick countdown) whose callback `MakeRecruitAvailable` flips it back true and
posts `"RecruitAvailable"`. `nTime <= 0` means "no auto-recovery" (manual). See
[mrxsupportmanager.lua:229](src/resident/mrxsupportmanager.lua#L229).

### Unlock / shop-completion
`Add(tSupport, sFaction)` flags items as unlocked (status=new) per faction, then totals every
faction's unlocked/total counts; when all equal, grants `ACHIEVEMENT_DIGITAL_MAN`
([mrxsupportdata.lua:2405](src/resident/mrxsupportdata.lua#L2405)).

### Soldier-delivery cap
`CheckForSoldiers` denies the drop if **≥8** friendly soldiers already within 80 units
([mrxsoldierdelivery.lua:179](src/resident/mrxsoldierdelivery.lua#L179)).

---

## 5. Logging & debug markers

`Debug.Printf` strings are the runtime trace anchors. Notable ones:

| String | Module:line | Meaning |
|---|---|---|
| `Shop - Generating Global ShopList...` | [mrxshop.lua:22](src/resident/mrxshop.lua#L22) | shop init |
| `Shop - Purchased <n> of Support <id> for <cost>` | [mrxshop.lua:251](src/resident/mrxshop.lua#L251) | **successful purchase** |
| `Shop - Adding Support/Equipment <id> ... Status - <bool>` | [mrxshop.lua:73](src/resident/mrxshop.lua#L73)/[:123](src/resident/mrxshop.lua#L123) | item populated, locked/unlocked |
| `Shop - No support data for <id>` | [mrxshop.lua:65](src/resident/mrxshop.lua#L65) | dangling catalog ref |
| `MrxSupportData: <name> not found.` | [mrxsupportdata.lua:2260](src/resident/mrxsupportdata.lua#L2260) | bad freebie name |
| `AddFreebie(): ...` (several) | [mrxsupportdata.lua:2276](src/resident/mrxsupportdata.lua#L2276)+ | freebie qty clamping |
| `@@@@@@@@@ MrxSupportData: AddSupportData returned nil!!!` | [mrxsupportdata.lua:2461](src/resident/mrxsupportdata.lua#L2461) | DLC add attempted with `g_bIsDlc=false` |
| `ABORTING SUPPORT` / `--> COPTER DAMAGED` | [mrxsupport.lua:513](src/resident/mrxsupport.lua#L513)/[:525](src/resident/mrxsupport.lua#L525) | abort path |
| `<--> [PDA.Support.denied.denied]<reason>` | [mrxsupport.lua:346](src/resident/mrxsupport.lua#L346) | denial reason logged |
| `MrxSupport.GoHome` / `.Land` / `.Abandon` | [mrxsupport.lua:600](src/resident/mrxsupport.lua#L600)/[:662](src/resident/mrxsupport.lua#L662)/[:590](src/resident/mrxsupport.lua#L590) | return-to-base trace |
| `<recruit> unavailable!` / `<recruit> available!` | [mrxsupportmanager.lua:231](src/resident/mrxsupportmanager.lua#L231)/[:259](src/resident/mrxsupportmanager.lua#L259) | recruit cooldown trace |
| `DELIVERY ERROR: No cargo/copter spawned` | [mrxsupportdelivery.lua:107](src/resident/mrxsupportdelivery.lua#L107)/[:119](src/resident/mrxsupportdelivery.lua#L119) | spawn failure |
| `RECEIVED NOMUNITIONS EVENT` / `Pickup Munition nil` | [mrxmunitionspickup.lua:90](src/resident/mrxmunitionspickup.lua#L90)/[:99](src/resident/mrxmunitionspickup.lua#L99) | munitions pickup |
| `-----= Starting Transit ...` / `-----= Teleporting ...` | [mrxsupporttransit.lua:334](src/resident/mrxsupporttransit.lua#L334)/[:359](src/resident/mrxsupporttransit.lua#L359) | transit teleport trace |
| `BOOOOOOOOOOOOOOOOOOOOOOM` / `Bunker Buster Explosion` | [mrxcruisemissile.lua:78](src/resident/mrxcruisemissile.lua#L78)/[mrxbunkerbuster.lua:30](src/resident/mrxbunkerbuster.lua#L30) | ordnance detonation |
| `Looking for freebie with stringhash = <h>` | [mrxsupportdata.lua:2349](src/resident/mrxsupportdata.lua#L2349) | freebie net-hash resolve |

**Debug hooks / toggles:**
- `bIgnoreRequirements` ([mrxsupportdata.lua:43](src/resident/mrxsupportdata.lua#L43), set via `SetIgnoreRequirements`) — makes every item equippable (dev/test bypass of recruit gates).
- `g_bIsDlc` — global gating `AddSupportData` ([mrxsupportdata.lua:2460](src/resident/mrxsupportdata.lua#L2460)).

---

## 6. Cross-references (engine globals & sibling modules called)

**Engine/native bindings used by this group** (most load-bearing first):
- `MrxPmc.*` — the **economy ledger**: `GetCashQty`, `AddCashQty(delta, bForce, sReason)`, `GetFuelQty`/`AddFuelQty`, `GetFuelCapacity`, `GetSupportQty`/`AddSupportQty(id, n, ?, cost)`, `GetFreebieQty`/`AddFreebieQty`/`SetFreebieQty`, `HasEquipment`/`AddEquipment`.
- `Airstrike.*` — `Flyby`, `SpawnOrdnance`, `SpawnTargettedOrdnance`, `SpawnDirectedObject`, `ConeSpawn`, `SpawnCarpetBombLine`, `EquipDesignator`, `RefillDesignator`, `RemoveDesignator`, `FindDesignatorOwner`, `TestDropZone` (via `Ai`).
- `Ai.*` — `Goal`, `Role`, `Squad`, `Deploy`, `Deliver`, `TestDropZone`, `SetPriorityTarget`, `SetHaste`, `AddInfraction`, `GetRelation`.
- `Object.*` / `Vehicle.*` — `Spawn`/`Pg.Spawn`, `GetPosition`, `SetYaw`, `AttachCargoToWinch`/`DetachCargoFromWinch`/`SetWinchState`, `IsWinched`, `FadeOut`, `Remove`, `GetHealth`/`GetMaxHealth`, `AddLabel`/`HasLabel`, `SetUnkillable`, `GetDriver`/`GetRiders`/`Enter`/`Exit`.
- `Pg.*` — `GetGuidByName`, `Spawn`, `SpawnFromCamera`, `FindPointFromCamera`, `FastCollectBuildings/Humans/Tanks/Flying/GroundVehicles`, `LoadAsset`/`UnloadAsset`.
- `Net.*` — `IsServer`/`IsClient`, `SendEvent_Support`, `SendCustomEvent`, `SendEvent_RecruitsUnlocked`, `SendEvent_RemoveObjective`.
- `Hud.*` — `Shop` (store widget), `SupportMenu`, `MessageBox`, `Radar`.
- `Weapon.SetReserveAmmo`, `ObjectState.GetStringHash`/`StartEmitter`, `String.GetHash`, `Math.*`, `Sound.CueSound`, `Graphics.Effect.Terrain`, `Camera.GetYaw`, `Munitions.GetTaggedMunition`/`PickupAllMunitions`.

**Sibling Lua modules imported:**
`MrxFactionManager` (price scale, attitudes, faction abbrevs), `MrxRewardData`
(`GetAllPotentialShopItems`), `WifEquipmentData` (fuel tanks / grappling hook in the shop),
`WifMissionFlow` (`RefreshAllPdaMissionDetails`), `MrxAchievements`, `MrxVoSequence`, `MrxUtil`,
`MrxGui`/`MrxGuiBase`/`MrxGuiManager`/`MrxGuiDialogBox`/`MrxGuiSatellite`, `MrxTransit`,
`MrxTutorialManager`, `MrxState`, `WifPmcInterior`, `MrxSound`, `Munitions`, `AntiAir`.

Related logic lives in: `MrxRewardData`/`WifEquipmentData` (what *can* appear in a shop and its
unlock state), `MrxFactionManager` (the per-faction `nPriceScale` multiplier applied to every
cost), `MrxTransit` (the actual fast-travel point list and teleport), and `MrxPmc` (the
authoritative cash/fuel/stockpile store + save game).

---

## 7. Future-dev / modding notes

- **Adding a new purchasable support** = one `tSupportData[id] = {…}` entry in
  `MrxSupportData.Init` with `oSupport` pointing at a `MrxSupport` subclass instance. The tail
  loop ([:2211](src/resident/mrxsupportdata.lua#L2211)) auto-names it and clamps `nMaxStock` to
  99 — set anything higher and it will still be capped.
- **DLC extension point**: `AddSupportData(tData, sKey)` ([:2459](src/resident/mrxsupportdata.lua#L2459))
  is the *only* runtime way to inject new catalog rows, and it **silently no-ops unless the global
  `g_bIsDlc` is true** (prints the `@@@@@@@@@` banner otherwise). Set `g_bIsDlc` before calling.
- **Free items / test loadouts**: `AddFreebie(name, qty)` grants free uses;
  `SetIgnoreRequirements(true)` removes recruit/requirement gating;
  satellite `SetCost(0)` makes a satellite-targeted strike free. Cost-0 items pass the
  `nCost <= GetCashQty()` purchase test trivially.
- **Recruit gates are the real lock**: an item is unbuyable-to-use unless its recruit
  (`Fiona`/`Copter`/`Pilot`/`Mechanic`) is in `tRequirementsObtained`. `Init` defaults all four to
  `true` ([:115](src/resident/mrxsupportdata.lua#L115)) — production missions flip them off and
  back on via `SetHeliPilotRecruited`/`SetJetPilotRecruited`/`SetMechanicRecruited`/`SetRequirement`.
- **`bUnrestrictedByFuel`** bypasses the fuel gate (only Transit uses it) — set it on any support
  you want callable at zero fuel.
- **Designator GUID-hash tables** (`_cargoTemplateData` / `_heliTemplateData`) are keyed by the
  *vehicle/cargo template GUID hash string* (e.g. `"0x80009467"`). A new large delivery vehicle
  with tight drop-zone needs an entry here or it falls back to the (smaller) `default` and may fail
  validation. The named `box` aliases ([:171](src/resident/mrxsupportdesignator.lua#L171)) show the
  pattern.
- **Gotchas / decompiler artifacts**:
  - Satellite designator's `Create` sets `sAATestLevel = bil` ([mrxsupportdesignatorsatellite.lua:44](src/resident/mrxsupportdesignatorsatellite.lua#L44)) — `bil` is an *undefined global* (effectively `nil`); satellites have no AA test by default.
  - `MrxSupportData` duplicates the `tFreebieData.OC` block verbatim ([:2135](src/resident/mrxsupportdata.lua#L2135) and [:2146](src/resident/mrxsupportdata.lua#L2146)) — second wins, harmless.
  - `mrxharmstrike.lua:65` has a dangling `Object.Get` (truncated) and a self-referential
    `{uBomb}` callback — a latent bug; don't copy it as a template.
  - `MrxApcDrop` uses `srcObj.__index = srcObj` rather than the usual `self.__index = self`; it is
    config-table-driven (`tConfig`), not the standard `MrxSupport` Create signature.
  - The PMC copter-repair penalty `nMaxHealth - nHealth * 200` ([mrxsupport.lua:577](src/resident/mrxsupport.lua#L577))
    has no parentheses around `nHealth * 200` — operator precedence makes it
    `nMaxHealth - (nHealth*200)`, which goes sharply negative for healthy copters; likely an
    original-source bug worth noting before "fixing" delivery economics.
