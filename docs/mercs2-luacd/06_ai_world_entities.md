# 06 — AI, World Entities & Object Scripts

Decompiled Lua reference for Mercenaries 2: World in Flames. This group covers the
**AI behavior framework** (`mrxai`, `mrxfollow`), the **ObjectScript / entity-binding
model**, and the **per-entity / per-object world scripts** — AI units, vehicles-as-objects,
pickups, props, triggers, blippables, emplaced weapons, and the destructible-set scripts.

Source root: `src/resident/<name>.lua`. All scripts in this group live in the `resident`
package (resident, i.e. always-loaded). Line refs are clickable into the decompiled source.

---

## 1. Overview

### 1.1 The ObjectScript / entity binding model

A world placement (an object exported from the level editor) carries the name of a Lua
"object script". When the engine instantiates/streams that object it calls into the script's
**module-level callback functions** by convention. The engine never reads a class; it
dispatches by *function name*:

| Engine callback | Fires when | Typical use |
|---|---|---|
| `Init()` / `Deinit()` | script module load / unload | allocate per-script tables, `ObjectFilter`s |
| `OnActivate(uGuid, uRuntimeOwner, iArg)` | object spawned/streamed in | register events, build instance |
| `OnDeactivate(uGuid)` | object hibernates/streams out | tear down events |
| `OnDeath(uGuid)` | object killed | spawn drops, clean up |
| `OnStateChange(uGuid, uiNodeHashName, uiStateHashName)` | destruction-state node changes | sequenced demolition / FX |
| `OnUse(uGuid, …)` / `Use(aiguid, floatval)` / `UnUse(...)` | context/use action | lifestyle props, hold-objects |
| `QueryRepair(int)` / `QueryActiveUse(int)` | engine asks for an action verb | benches/fountains return a handler name |
| `NetEventCallback(nEventId, tArgs)` | custom net event for that script's channel | MP sync |

`iArg` (a small integer attached to the placement in the editor) selects a variant — e.g.
`antiair` tier 1–4, `mine` trigger mode 2 (proximity), `paratrooper` faction.

**Hibernation gate.** Almost every active script defers real setup until the object is
awake: `Event.Create(Event.ObjectHibernation, {uGuid, "awake"}, <fn>, …)`. The AI module
(`mrxai`) wraps *every* AI command in the same awake-gate (see §5).

### 1.2 The Inheritable / Blippable class hierarchy

A small prototype-based OO layer underlies most stateful entities:

```
Inheritable  (src/resident/inheritable.lua)
  └─ Blippable        (radar/HUD-marker objective)
       ├─ OrientedBlippable   (rotating blip)
       │    └─ VehicleBlippable   (driver-relation colored)
       │         ├─ tank / helicopter / airplane / autogunship
       ├─ EnemyBlippable        (driver-relation colored, faction mood)
       │    └─ antiair
       ├─ munitions / laptop    (pickup blips + context tagging)
       ├─ homingmissile / factionzone
```

- `inherit("Foo")` pulls the named module in as a prototype base; `import("Foo")` just
  makes the module's functions callable.
- `Inheritable` keeps a global `tInstance[uGuid] → oInstance` registry
  ([inheritable.lua:1](src/resident/inheritable.lua#L1)). `Create` sets a metatable with
  `__index = oPrototype` ([inheritable.lua:23](src/resident/inheritable.lua#L23)); `getfenv()`
  is used as the prototype so the *module table itself* is the class.
- `Blippable` adds/removes a radar objective via `Hud.Radar:AddObjective{…}` and an
  off-screen world marker via `Marker.AddBlip(...)` ([blippable.lua:32](src/resident/blippable.lua#L32)).

### 1.3 AI behavior framework

- **`mrxai`** is a thin, awake-gated shim over the engine `Ai.*` API: `Goal`, `DefaultGoal`,
  `RemoveGoal`, `Deploy`, `Role` ([mrxai.lua:1](src/resident/mrxai.lua#L1)).
- **`mrxfollow`** is the full **escort/follow** behavior object (companion characters):
  follow/idle role toggling, lost/found/hostile VO, vehicle transit hand-off, context action
  ("Follow"/"Stay") ([mrxfollow.lua:1](src/resident/mrxfollow.lua#L1)).
- **Goals vs Roles vs DefaultGoal**: `Ai.Goal` = a one-shot task with a fulfillment callback
  and a `Priority` ("hiPri"/"loPri"); `Ai.Role` = a persistent stance ("Follow"/"Idle");
  `DefaultGoal` = fallback behavior. Capture rushers use `Goal "MoveTo"` (see `outpost`, §5).

### 1.4 Entity categories

AI unit · vehicle-object · pickup · prop (inert) · lifestyle prop (context-action) ·
trigger/mine · blippable · emplaced weapon · destructible-set (sequenced demolition) ·
bootstrap/utility · airstrike-FX.

---

## 2. Entity / object-script catalog

| Script | Category | One-line purpose |
|---|---|---|
| `Init` | trigger (C4) | C4-land bomb: 30th-sec material anim + armed beep ([Init.lua](src/resident/Init.lua)) |
| `Multi` | dev tool | spawn N templates in front of camera; `Scatter` helper ([Multi.lua](src/resident/Multi.lua)) |
| `mrxai` | AI framework | awake-gated wrapper for `Ai.Goal/Role/Deploy` ([mrxai.lua](src/resident/mrxai.lua)) |
| `mrxfollow` | AI behavior | escort/follow behavior object w/ VO + vehicle transit ([mrxfollow.lua](src/resident/mrxfollow.lua)) |
| `inheritable` | base class | prototype OO + `tInstance` registry ([inheritable.lua](src/resident/inheritable.lua)) |
| `blippable` | base class | radar objective + world marker ([blippable.lua](src/resident/blippable.lua)) |
| `orientedblippable` | base class | rotating/flashing blip ([orientedblippable.lua](src/resident/orientedblippable.lua)) |
| `vehicleblippable` | base class | driver-relation colored vehicle blip ([vehicleblippable.lua](src/resident/vehicleblippable.lua)) |
| `enemyblippable` | base class | faction-mood colored vehicle blip ([enemyblippable.lua](src/resident/enemyblippable.lua)) |
| `soldier` | AI unit | infantry death → ammo/health pickup drops ([soldier.lua](src/resident/soldier.lua)) |
| `tank` | vehicle-object | tank; VehicleBlippable, radar icon ([tank.lua](src/resident/tank.lua)) |
| `helicopter` | vehicle-object | helicopter; VehicleBlippable ([helicopter.lua](src/resident/helicopter.lua)) |
| `airplane` | vehicle-object | airplane; VehicleBlippable ([airplane.lua](src/resident/airplane.lua)) |
| `autogunship` | AI unit/vehicle | PMC support gunship: auto-targets enemy ground vehicles, fires salvos ([autogunship.lua](src/resident/autogunship.lua)) |
| `paratrooper` | AI unit | parachuting soldier; drops chute at health<100, respawns airborne unit ([paratrooper.lua](src/resident/paratrooper.lua)) |
| `helicopter`/`autogunship` | vehicle blips | see above |
| `outpost` | AI/objective mgr | capturable outpost: rusher AI, capture health, DB spawner tweaks ([outpost.lua](src/resident/outpost.lua)) |
| `dangerousbuilding` | AI spawner mgr | "DB" occupied buildings: random activation, spawner control, radar ([dangerousbuilding.lua](src/resident/dangerousbuilding.lua)) |
| `dropoff` | AI spawner | timed faction copter cargo/vehicle drop ([dropoff.lua](src/resident/dropoff.lua)) |
| `despawner` | trigger (stub) | empty `Use` stub ([despawner.lua](src/resident/despawner.lua)) |
| `antiair` | emplaced/blippable | AA/SAM/jammer site: range activation, homing lock-on tones ([antiair.lua](src/resident/antiair.lua)) |
| `heavymg` | emplaced weapon | dropped heavy MG; removes itself on drop ([heavymg.lua](src/resident/heavymg.lua)) |
| `emplaced` | emplaced weapon | gunner-seat camera focus enter/exit ([emplaced.lua](src/resident/emplaced.lua)) |
| `jammer` | emplaced/support | GPS jammer: context-toggle, registers as anti-air ([jammer.lua](src/resident/jammer.lua)) |
| `homingmissile` | blippable | flashing blip on a launched homing round ([homingmissile.lua](src/resident/homingmissile.lua)) |
| `mine` | trigger/weapon | land mine: material anim, proximity kill, typed explosion ([mine.lua](src/resident/mine.lua)) |
| `proximitymine` | trigger/weapon | pop-up grenade mine at <6m human proximity ([proximitymine.lua](src/resident/proximitymine.lua)) |
| `beacon` | trigger (prop) | airstrike beacon: material anim + armed beep ([beacon.lua](src/resident/beacon.lua)) |
| `crate` | pickup/prop | winchable supply crate; blip while not winched ([crate.lua](src/resident/crate.lua)) |
| `collectable` | pickup | toolbox-style collectible; context "Toolbox" kills it ([collectable.lua](src/resident/collectable.lua)) |
| `munitions` | pickup (blip) | taggable support/fuel/cash stockpile pickup ([munitions.lua](src/resident/munitions.lua)) |
| `laptop` | pickup (blip) | laptop support-munition pickup (weapon "pickup") ([laptop.lua](src/resident/laptop.lua)) |
| `alarm` | trigger/prop | building alarm: activates dangerous buildings nearby ([alarm.lua](src/resident/alarm.lua)) |
| `friendlygate` | gate/trigger | faction gate: opens for allies/hero by attitude ([friendlygate.lua](src/resident/friendlygate.lua)) |
| `pmcgate` | gate | PMC gate: opens 2s after awake ([pmcgate.lua](src/resident/pmcgate.lua)) |
| `goal` | trigger/objective | soccer-goal easter egg: ball-in-net → cash + VO ([goal.lua](src/resident/goal.lua)) |
| `factionzone` | trigger (region) | faction trespass zone: HUD/map region + boundary event ([factionzone.lua](src/resident/factionzone.lua)) |
| `repairpad` | prop | repair pad light toggle ([repairpad.lua](src/resident/repairpad.lua)) |
| `fueltank` | prop (FX) | oilrig fuel tank flame→smoke emitter on state ([fueltank.lua](src/resident/fueltank.lua)) |
| `oilrig` | destructible-set | scripted multi-stage oilrig demolition sequence ([oilrig.lua](src/resident/oilrig.lua)) |
| `islandfortress` | destructible-set | adjacency-propagated fortress slice collapse ([islandfortress.lua](src/resident/islandfortress.lua)) |
| `treetrunk` / `treetrunkpalm` | prop (FX) | play foliage material anim on fire/destroy state ([treetrunk.lua](src/resident/treetrunk.lua)) |
| `materialanimation_largecanopy01/02` | prop (FX) | canopy collapse material anim ([…largecanopy01.lua](src/resident/materialanimation_largecanopy01.lua)) |
| `materialanimation_treeplaza02` | prop (FX) | tree-plaza collapse material anim ([…treeplaza02.lua](src/resident/materialanimation_treeplaza02.lua)) |
| `gurpodium` | lifestyle/prop | guerrilla podium: looped propaganda VO while occupied ([gurpodium.lua](src/resident/gurpodium.lua)) |
| `danceradio` | lifestyle prop | "Dance" context action → techno-viking animation ([danceradio.lua](src/resident/danceradio.lua)) |
| `moonpatrol` | vehicle-object | monster-truck jump-boost (RT) w/ exhaust FX ([moonpatrol.lua](src/resident/moonpatrol.lua)) |
| `spyhunter` | vehicle-object | boost-boat jump/boost (LB) w/ jet-exhaust FX + cooldown ([spyhunter.lua](src/resident/spyhunter.lua)) |
| `opentankhatch` | vehicle-object | open driver hatch if unoccupied ([opentankhatch.lua](src/resident/opentankhatch.lua)) |
| `shootinggallerytarget` | prop (FX) | pivot open/close on state hashes ([shootinggallerytarget.lua](src/resident/shootinggallerytarget.lua)) |
| `lifestyle_oillif001_table` | lifestyle/staging | arm-wrestling staging poses for two riders ([lifestyle_oillif001_table.lua](src/resident/lifestyle_oillif001_table.lua)) |
| `bench` | lifestyle prop (stub) | `QueryRepair/QueryActiveUse` verbs; empty handlers ([bench.lua](src/resident/bench.lua)) |
| `hackybench` | lifestyle prop | inherits Bench; empty `Use` ([hackybench.lua](src/resident/hackybench.lua)) |
| `barbell` | hold-object | detach from holder on UnUse ([barbell.lua](src/resident/barbell.lua)) |
| `livingworldprop` | hold-object | drop weapon-prop from holder on UnUse ([livingworldprop.lua](src/resident/livingworldprop.lua)) |
| `binoculars`/`telephone`/`monument`/`outhouse`/`foodcart`/`fountain` | lifestyle props (stub) | empty `Use` verb stubs ([binoculars.lua](src/resident/binoculars.lua)) |
| `randomlyteleportplayer` | dev/stress | teleport player to random HQ every 5–20s ([randomlyteleportplayer.lua](src/resident/randomlyteleportplayer.lua)) |
| `hijackcontractmanager` | manager | holds active hijack contract; complete/cancel ([hijackcontractmanager.lua](src/resident/hijackcontractmanager.lua)) |
| `verify_flash` | dev/atmosphere | set fixed grey atmosphere (render verify) ([verify_flash.lua](src/resident/verify_flash.lua)) |
| `gamebootstrap` | bootstrap | intro movies (Pandemic/EA) → shell/level load ([gamebootstrap.lua](src/resident/gamebootstrap.lua)) |
| `levelbootstrap` | bootstrap | request level `_base` layer + master script, enter "Loading" ([levelbootstrap.lua](src/resident/levelbootstrap.lua)) |
| `airstrike_atomsphere_*` (bombrun, carpetbomb, clusterbomb, daisycutter, fuelairbomb, moab, tactnuke) | airstrike-FX | per-strike atmosphere/bloom flash + `MrxUtil.ShieldFace` ([…tactnuke.lua](src/resident/airstrike_atomsphere_tactnuke.lua)) |

---

## 3. Per-entity reference (key handlers)

### AI behavior

**mrxfollow** (escort companion object)
- `Activate(self, bEnable, bStartInFollowState)` — start/stop following ([mrxfollow.lua:29](src/resident/mrxfollow.lua#L29)).
- `_ToggleFollowingBehavior` — forces feeling ≥100 to target, issues `Ai.Role "Follow"`
  (MinDistance 2, MaxDistance 30, MoveDistance 4, hiPri, HardPriority) or `"Idle"`
  ([mrxfollow.lua:52](src/resident/mrxfollow.lua#L52)).
- `_OnFollowerCanceled(self, uGuid, sReason)` — handles `"targettoofar"` / `"targethostile"` /
  `"targetdead"` ([mrxfollow.lua:173](src/resident/mrxfollow.lua#L173)).
- `_OnFollowerLost` — re-acquire at proximity <15m ([mrxfollow.lua:185](src/resident/mrxfollow.lua#L185)).
- `_OnTransitStart/_OnTransitEnd` — auto enter/exit a transit vehicle as passenger ([mrxfollow.lua:244](src/resident/mrxfollow.lua#L244)).

### AI units / spawn managers

**soldier** — `OnDeath(uGuid, iArg)`: every 3rd death (or HeavySoldier) drops a pickup
([soldier.lua:8](src/resident/soldier.lua#L8)); rocket→`Ammo Pickup (Rocket)`, heavy→bullet,
low grenade reserve→grenades, and `math.randf()*80 > hero health` → `Health Pickup`
([soldier.lua:32](src/resident/soldier.lua#L32)). Pickup spawned 0.1m up, downward impulse,
`AddToDisposer "pickup"` ([soldier.lua:37](src/resident/soldier.lua#L37)).

**autogunship** — `Start`: blips by faction relation, PMC made unkillable ("Support"), first
`Salvo` after 3s ([autogunship.lua:30](src/resident/autogunship.lua#L30)). `Salvo`: collects
ground vehicles within 200m, picks a VZ/China/Guerilla target ≠ last, fires 4 missiles at
0.25s spacing, repeats every 3s ([autogunship.lua:54](src/resident/autogunship.lua#L54)).
`LaunchMissile`: ±5 aim scatter, `Gunship Shell` ordnance at speed 100 ([autogunship.lua:82](src/resident/autogunship.lua#L82)).

**paratrooper** — `Start`: when health<100, `RemoveChute` removes self (0.25s) and spawns the
faction airborne template (`China`/`Allied`) at same pos/yaw ([paratrooper.lua:12](src/resident/paratrooper.lua#L12)).

**outpost** — full capture sub-game; see §5.

**dangerousbuilding** — `Start`: occupied→`SetupOccupied` (health event + grey blip); else
roll `math.randf()*nMaxDBs*iRarity < nMaxDBs` to `TurnOnRandomDB`
([dangerousbuilding.lua:19](src/resident/dangerousbuilding.lua#L19)). `TurnOn` flips the radar
blip to red active and enables attached spawners ([dangerousbuilding.lua:85](src/resident/dangerousbuilding.lua#L85)).

**dropoff** — every 30–60s, copter-drops a random faction container or vehicle (VZ/GR/CH/OC/AL/PR
tables) via `MrxCopterDrop.Create` ([dropoff.lua:25](src/resident/dropoff.lua#L25)).

### Pickups

**munitions** — `Awake`: classifies stock (support/fuel/cash) and sets blip/marker textures,
adds context "Tag*" action, registers proximity-near event at `_kDistance` (175)
([munitions.lua:42](src/resident/munitions.lua#L42)). `CanActionTarget` enforces taggable /
fuel-full / support-max-stock gates ([munitions.lua:277](src/resident/munitions.lua#L277)).
`PickupMunitions` adds support qty / fuel / cash and fades the object ([munitions.lua:543](src/resident/munitions.lua#L543)).

**laptop** — fixed support-munition pickup; tagged on weapon "pickup" "Laptop" event
([laptop.lua:71](src/resident/laptop.lua#L71)). `_kDistance` = 150 ([laptop.lua:8](src/resident/laptop.lua#L8)).

**crate** — winchable; blip (`pickup_crate_2`, size 48) shown while not winched, removed when
winched ([crate.lua:18](src/resident/crate.lua#L18)).

**collectable** — `[ContextAction.Toolbox]` kills the object; `CollectableInvalidated` label
auto-kills it ([collectable.lua:18](src/resident/collectable.lua#L18)).

### Emplaced / weapon triggers

**antiair** — 4 tiers in `_tPrototype` (basic/medium/advanced/jammer). Activates when player
within `nAARange`; `SetBlipped` registers with `MrxSupport.AddAntiAir`
([antiair.lua:170](src/resident/antiair.lua#L170)). Large homing lock-on subsystem
(`_HomingLockStart/Update/Clear`) drives targeting tones ([antiair.lua:274](src/resident/antiair.lua#L274)).

**mine** — `OnActivate`: plays `global_weapon_c4land_60thsec`; `iArg==2` arms a <1m human
proximity kill ([mine.lua:15](src/resident/mine.lua#L15)). `OnDeath` schedules `Explode` (0.75s
human / 0.25s veh) → spawns grenade / AT-mine / water-mine explosion ([mine.lua:38](src/resident/mine.lua#L38)).

**proximitymine** — <6m human proximity → `Popup`: removes self, spawns
`Grenade MG Projectile` ordnance upward (8) ([proximitymine.lua:15](src/resident/proximitymine.lua#L15)).

**heavymg** — removes itself on `Human Drop` weapon event ([heavymg.lua:4](src/resident/heavymg.lua#L4)).

**emplaced** — gunner enter → `SetFocusParams(0,0,2,2,600,4,0)`; exit restores
([emplaced.lua:38](src/resident/emplaced.lua#L38)).

**jammer** — context-toggle GPS jammer; on activates registers `MrxSupport.AddAntiAir(uGuid,"jammer")`
([jammer.lua:41](src/resident/jammer.lua#L41)).

### Gates / zones / triggers

**friendlygate** — proximity (<20m) candidate set of hero/faction-vehicles; opens if any valid
candidate and not locked; attitude-gated for the player (`_TestAttitude`)
([friendlygate.lua:120](src/resident/friendlygate.lua#L120), [friendlygate.lua:230](src/resident/friendlygate.lua#L230)).
Far-edge re-check at 40m ([friendlygate.lua:145](src/resident/friendlygate.lua#L145)).

**alarm** — context-toggle building alarm; activates occupied buildings within 100m via
`DangerousBuilding.TurnOn`; auto-checks every 8s and self-mutes after 60s
([alarm.lua:95](src/resident/alarm.lua#L95)).

**factionzone** — adds a colored line region to radar/PDA and a boundary event; sends
`TrespassStateChange` GUI events on enter/exit ([factionzone.lua:41](src/resident/factionzone.lua#L41), [factionzone.lua:54](src/resident/factionzone.lua#L54)).

**goal** — soccer easter egg: ball entering `LR_Goal` boundary → `MrxPmc.AddCashQty(100000)`
+ Fiona VO ([goal.lua:25](src/resident/goal.lua#L25)).

### Destructible sets

**oilrig** — `OnStateChange` on hash `0x28825D4C` kicks off `_DestroyOilrigSequence`, a long
timed table of emitter/`_DestroyLinkedGuid`/`SetState`/camera-shake steps run by
`_ProcessNextEvent` ([oilrig.lua:246](src/resident/oilrig.lua#L246), [oilrig.lua:488](src/resident/oilrig.lua#L488)).

**islandfortress** — `tAdjacencyTable` (node hash → neighbor slices) drives a flood-fill
collapse; each `KillNode` damages and schedules neighbors after 0.3–1.0s
([islandfortress.lua:62](src/resident/islandfortress.lua#L62)).

### Bootstrap

**gamebootstrap** — `Init` plays intro movies (`Pandemic`, `EA`) then `Start` routes to
shell / lobby / autoload level. Save-data version = 3 ([gamebootstrap.lua:40](src/resident/gamebootstrap.lua#L40), [gamebootstrap.lua:77](src/resident/gamebootstrap.lua#L77)).

**levelbootstrap** — `LoadLevel`: required asset `<level>_base` layer + master script, request
"Loading" game state ([levelbootstrap.lua:1](src/resident/levelbootstrap.lua#L1)).

---

## 4. Defaults & tunables

### 4.1 Outpost (capture sub-game) — `outpost.lua`
| Constant | Value | Line |
|---|---|---|
| `nCaptureTime` | 10 | [outpost.lua:26](src/resident/outpost.lua#L26) |
| `nStartRange` | 150 | [outpost.lua:27](src/resident/outpost.lua#L27) |
| `nSpawnTime` (seconds per spawn cycle) | 20 | [outpost.lua:28](src/resident/outpost.lua#L28) |
| `iCashReward` | 5000 | [outpost.lua:29](src/resident/outpost.lua#L29) |
| `nStartingHealth` (capture "X" pips) | 3 | [outpost.lua:38](src/resident/outpost.lua#L38) |
| `nRusherQuota` | 1 | [outpost.lua:39](src/resident/outpost.lua#L39) |
| Default defenders / attackers | `VZ` / `OC` | [outpost.lua:24](src/resident/outpost.lua#L24) |
| Rusher collect radius | 50m | [outpost.lua:280](src/resident/outpost.lua#L280) |
| Rusher move-goal timeout | 20s | [outpost.lua:362](src/resident/outpost.lua#L362) |
| Idle-all-rushers radius | 30m | [outpost.lua:545](src/resident/outpost.lua#L545) |

### 4.2 DangerousBuilding — `dangerousbuilding.lua`
| Constant | Value | Line |
|---|---|---|
| `nMaxDBs` (global active cap) | 8 | [dangerousbuilding.lua:7](src/resident/dangerousbuilding.lua#L7) |
| `nDefaultRarity` | 16 | [dangerousbuilding.lua:8](src/resident/dangerousbuilding.lua#L8) |
| `nDefaultCashReward` | 0 | [dangerousbuilding.lua:10](src/resident/dangerousbuilding.lua#L10) |
| Random DB active radius (RADIUS_PLAYER_2D) | 100 | [dangerousbuilding.lua:168](src/resident/dangerousbuilding.lua#L168) |
| Rarity keywords | `never`=-1, `always`=0, `default`=16 | [dangerousbuilding.lua:372](src/resident/dangerousbuilding.lua#L372) |

### 4.3 AntiAir tiers — `antiair.lua` (`_tPrototype`)
| iArg | sLevel | radar tex | `nAARange` | HUD marker |
|---|---|---|---|---|
| 1 | basic | radar_AA | 100 | HUD_anti-air |
| 2 | medium | radar_SAM | 200 | HUD_SAM |
| 3 | advanced | radar_AA | 200 | HUD_anti-air |
| 4 | jammer | radar_Jammer | 200 | HUD_jammer |

All blip `nSize`=8, `nSortOrder`=2, `nVerticalOffset`=3.5 ([antiair.lua:8](src/resident/antiair.lua#L8)).
Alert cooldown `knCueAlertCooldown` = 1s ([antiair.lua:221](src/resident/antiair.lua#L221)).

### 4.4 Munitions / Laptop pickups
| Constant | Value | Line |
|---|---|---|
| `munitions._kDistance` (blip near/far) | 175 | [munitions.lua:10](src/resident/munitions.lua#L10) |
| `laptop._kDistance` | 150 | [laptop.lua:8](src/resident/laptop.lua#L8) |
| Fuel stock amounts | 50 / 500 / 5000 | [munitions.lua:29](src/resident/munitions.lua#L29) |
| Cash stock amount | 100000 | [munitions.lua:32](src/resident/munitions.lua#L32) |
| Blipped-VO cooldown `_nBlippedVOCoolDownTime` | 30s | [munitions.lua:148](src/resident/munitions.lua#L148) |
| Support marker/blip size | 8 (radar) / 40 (marker) | [munitions.lua:60](src/resident/munitions.lua#L60) |

`tMunitions` index list (1–17 = support types, 18–20 fuel, 21 cash) ([munitions.lua:11](src/resident/munitions.lua#L11)).

### 4.5 Mines / proximity
| Constant | Value | Line |
|---|---|---|
| `mine` human trigger radius (`iArg==2`) | 1m | [mine.lua:24](src/resident/mine.lua#L24) |
| `mine` explode delay human / veh | 0.75s / 0.25s | [mine.lua:44](src/resident/mine.lua#L44) |
| `proximitymine` trigger radius | 6m | [proximitymine.lua:19](src/resident/proximitymine.lua#L19) |
| `proximitymine` ordnance launch speed (Y) | 8 | [proximitymine.lua:43](src/resident/proximitymine.lua#L43) |

### 4.6 mrxfollow ranges
| Constant | Value | Line |
|---|---|---|
| `kMaxFollowDistance` | 30 | [mrxfollow.lua:53](src/resident/mrxfollow.lua#L53) |
| MinDistance / MoveDistance | 2 / 4 | [mrxfollow.lua:73](src/resident/mrxfollow.lua#L73) |
| Forced feeling to target | 100 (if <0) | [mrxfollow.lua:67](src/resident/mrxfollow.lua#L67) |
| Re-acquire proximity | <15m | [mrxfollow.lua:189](src/resident/mrxfollow.lua#L189) |
| Context action priority | "hiPri", HardPriority | [mrxfollow.lua:75](src/resident/mrxfollow.lua#L75) |

### 4.7 Other notable numbers
| Where | Constant | Value | Line |
|---|---|---|---|
| autogunship | salvo collect radius / count / interval | 200m / 4 / 3s | [autogunship.lua:61](src/resident/autogunship.lua#L61) |
| autogunship | shell speed scale | 100 | [autogunship.lua:100](src/resident/autogunship.lua#L100) |
| paratrooper | chute-drop health threshold | <100 | [paratrooper.lua:16](src/resident/paratrooper.lua#L16) |
| friendlygate | open / far-recheck radius | 20m / 40m | [friendlygate.lua:113](src/resident/friendlygate.lua#L113) |
| alarm | building collect radius / recheck / mute | 100m / 8s / 60s | [alarm.lua:96](src/resident/alarm.lua#L96) |
| crate | marker tex / size / near / far | pickup_crate_2 / 48 / 16 / 20 | [crate.lua:24](src/resident/crate.lua#L24) |
| dropoff | drop interval | 30–60s | [dropoff.lua:27](src/resident/dropoff.lua#L27) |
| goal | cash reward | 100000 | [goal.lua:37](src/resident/goal.lua#L37) |
| moonpatrol | jump impulse / land timer | 10·mass / 1.5s | [moonpatrol.lua:97](src/resident/moonpatrol.lua#L97) |
| spyhunter | jump stages / cooldown | 6 / 8s (smoke 5.5s) | [spyhunter.lua:176](src/resident/spyhunter.lua#L176) |
| randomlyteleportplayer | teleport interval / +Y | 5–20s / +20 | [randomlyteleportplayer.lua:28](src/resident/randomlyteleportplayer.lua#L28) |
| gamebootstrap | save data version | 3 | [gamebootstrap.lua:78](src/resident/gamebootstrap.lua#L78) |

### 4.8 Blip color conventions (driver-relation / faction mood)
`VehicleBlippable` / `EnemyBlippable` color tables (RGB) — relation thresholds ±60:
- Ally `{0,127,255}` · Neutral `{230,230,255}` · Enemy `{255,0,0}` · Empty `{100,100,100}` ·
  PMC `{0,255,0}` ([vehicleblippable.lua:4](src/resident/vehicleblippable.lua#L4), [vehicleblippable.lua:91](src/resident/vehicleblippable.lua#L91)).
- Default blip color `{255,51,51}`; default marker tex `HUD_objective_destroy`, near 140 / far 150
  ([blippable.lua:38](src/resident/blippable.lua#L38), [blippable.lua:68](src/resident/blippable.lua#L68)).

---

## 5. AI logic

### 5.1 mrxai — awake-gated command shim
Each of `Goal/DefaultGoal/RemoveGoal/Deploy/Role` only fires once the AIGuid object is awake
(`Event.ObjectHibernation … "awake"`), then forwards `tParameters` straight to the engine
`Ai.*` ([mrxai.lua:1](src/resident/mrxai.lua#L1)). This is the single funnel through which
mission/object scripts issue AI orders.

### 5.2 Goal vs Role priorities
- Priorities are string tokens: `"hiPri"`, `"loPri"` (see outpost rusher goals and idle roles).
- `Ai.Role` is a persistent stance: `"Follow"`, `"Idle"`. `mrxfollow` flips between them with
  `HardPriority = true` so the follow can't be pre-empted ([mrxfollow.lua:69](src/resident/mrxfollow.lua#L69)).
- `Ai.Goal` is a task with a fulfillment `Callback(self, uGuid, nState)`; `nState==0` means
  failure/cancel (see `RusherGoalFulfilled` [outpost.lua:379](src/resident/outpost.lua#L379)).
- Feelings/relations: `Ai.GetFeeling/SetFeeling` (0–100), `Ai.GetRelation` (−100..100, ±60
  used as the neutral band everywhere).

### 5.3 Outpost capture AI (`outpost.lua`)
A server-only manager (`Net.IsClient()` early-outs throughout):
- **Capture model**: `nStartingHealth`=3 pips; attacker rusher reaching the capture point
  drives health −1, defender +1; 0 → `Captured` (faction flip + `MrxOutpostManager` status),
  object death → `Destroyed` ([outpost.lua:379](src/resident/outpost.lua#L379), [outpost.lua:525](src/resident/outpost.lua#L525)).
- **TimerTick (1s)**: calls for attackers always, defenders only when damaged ([outpost.lua:136](src/resident/outpost.lua#L136)).
- **CallForRushers**: `Pg.FastCollectHumans` within 50m of capture point, filters out players'
  vehicles, helicopter riders, gunners, and AI with `NoCapture` state; issues `Ai.Goal "MoveTo"`
  with 20s timeout + death event ([outpost.lua:271](src/resident/outpost.lua#L271), [outpost.lua:343](src/resident/outpost.lua#L343)).
- **Spawner control**: `SetDBFaction` / `TweakDBs` retarget the building's attached spawner
  groups (Ground/Balcony/AA/Window/Rooftop) to faction spawn-lists at `nSpawnTime` cadence
  ([outpost.lua:239](src/resident/outpost.lua#L239)).
- **Rusher VO**: per-faction "Advance"/"Attack_Building" cue banks ([outpost.lua:560](src/resident/outpost.lua#L560)).

### 5.4 Follow / escort behavior (`mrxfollow.lua`)
State machine over `Ai.Role`: ON → Follow role + context "Stay"; OFF → Idle role + context
"Follow"; lost → re-acquire proximity event; hostile → VO only; transit → enter/exit vehicle.
Plays cycling VO banks (`tStartFollowVO`, `tStopFollowVO`, `tLostVO`, `tFoundVO`, `tHostileVO`)
unless `bVOOverride` ([mrxfollow.lua:98](src/resident/mrxfollow.lua#L98), [mrxfollow.lua:210](src/resident/mrxfollow.lua#L210)).

### 5.5 Blip / visibility logic
- `Blippable.AddObjective` honors a global `tHiddenGuids` suppression list ([blippable.lua:32](src/resident/blippable.lua#L32), [blippable.lua:90](src/resident/blippable.lua#L90)).
- `OrientedBlippable` adds a 0.05s flash timer ([orientedblippable.lua:17](src/resident/orientedblippable.lua#L17)); `homingmissile` flashes at 0.1s ([homingmissile.lua:24](src/resident/homingmissile.lua#L24)).
- Vehicle blips recolor on every driver enter/exit and faction-attitude change
  (`MrxFactionManager.CreatePersistentAttitudeChangeEvent`) ([vehicleblippable.lua:51](src/resident/vehicleblippable.lua#L51)).
- `factionzone` draws line regions on both radar and PDA map ([factionzone.lua:54](src/resident/factionzone.lua#L54)).

---

## 6. Logging & debug markers (`Debug.Printf`)

Representative strings (useful for grepping live logs):
- AI/follow: `" following ON "`, `" following OFF"`, `"MrxFollow: transit vehicle full: "`,
  `"---=--- "`, `" ooo ENTERING "`, `"--0-- TRANSIT END: "` ([mrxfollow.lua:58](src/resident/mrxfollow.lua#L58),[mrxfollow.lua:250](src/resident/mrxfollow.lua#L250)).
- Outpost: `"@@@@@@@@@@ CallForRushers: Rusher already active, skipping"`,
  `"@@@@@@@@@@ IssueCommand: …"`, `"@@@@@@@@@@ Removing Rusher"`, `"ERROR: Outpost … not found"`
  ([outpost.lua:277](src/resident/outpost.lua#L277),[outpost.lua:51](src/resident/outpost.lua#L51)).
- AntiAir: `"AntiAir.ActivateAA "`, `"CreateNearnessEvent "`, `"CreateDistanceEvent "`,
  `"AntiAir: HomingLock left hanging…"` ([antiair.lua:171](src/resident/antiair.lua#L171),[antiair.lua:365](src/resident/antiair.lua#L365)).
- Blippable/Vehicle: `"Blippable.OnActivate"`, `"VehicleBlippable Create"`,
  `"VehicleBlippable: NO DRIVER FOUND"`, `"Creating MOOD event for…"` ([blippable.lua:6](src/resident/blippable.lua#L6),[vehicleblippable.lua:102](src/resident/vehicleblippable.lua#L102)).
- Alarm: `"Alarm.OnActivate"`, `"LightFront activated …"`, `"CtrlRotation activated …"` ([alarm.lua:18](src/resident/alarm.lua#L18)).
- Mine: `"@@@@@@ ACTIVATING: "`, `"Waiting for proximity"` ([mine.lua:16](src/resident/mine.lua#L16)).
- Autogunship: `"SALVO"`, `"*** Fire in the hole! ***"`, `"No valid target found!"` ([autogunship.lua:55](src/resident/autogunship.lua#L55),[autogunship.lua:87](src/resident/autogunship.lua#L87)).
- Spyhunter: many `"^^^^^^^^^^^^^^^^ …"` markers (ON ENTER / ON EXIT / RESET JUMP / Cooldown) ([spyhunter.lua:21](src/resident/spyhunter.lua#L21)).
- Bootstrap: `"Attempting to play movie …"`, `"All movies complete"`, `"##@ GameBootstrap - bailing …"` ([gamebootstrap.lua:13](src/resident/gamebootstrap.lua#L13)).
- Stress: `"STRESS TEST: going to: …"`, `"STRESS TEST: Bad location: …"` ([randomlyteleportplayer.lua:28](src/resident/randomlyteleportplayer.lua#L28)).
- Hijack mgr: `"****************HIJACKCONTRACTMANAGER.SetActiveContract()"` etc. ([hijackcontractmanager.lua:2](src/resident/hijackcontractmanager.lua#L2)).
- Oilrig: `"********** ERROR on "` (missing destruction link node) ([oilrig.lua:518](src/resident/oilrig.lua#L518)).

---

## 7. Cross-references & future-dev notes

### 7.1 Engine bindings used by this group
- **`Ai.*`** — `Goal`, `DefaultGoal`, `RemoveGoal`, `Role`, `Deploy`, `GetFeeling/SetFeeling`,
  `GetRelation`, `GetFactionGuid`, `GetState`, `SetPriorityTarget`, `LivingWorld`,
  `TweakAttachedSpawners(InGroup)`.
- **`Object.*`** — `GetHealth`, `IsAlive`, `GetPosition`, `GetYaw/SetYaw`, `HasLabel`,
  `Kill`, `Remove`, `FadeOut`, `PlayMaterialAnimation`, `ApplyImpulse/ApplyPointImpulse`,
  `SetUnkillable`, `SetHibernationDistance`, `AddToDisposer`, `OpenGate/CloseGate`,
  `IsPlayerControlled`, `InSeat/InVehicle/IsWinched`, `GetMass`.
- **`Pg.*`** — `Spawn`, `SpawnFromCamera`, `GetGuidByName`, `FastCollectHumans/Buildings/
  GroundVehicles`, `AddContextAction/RemoveContextAction`, `LoadAsset/UnloadAsset`.
- **`Vehicle.*`** — `GetDriver/GetRiders/GetFromRider`, `Enter/Exit`, `SetParts`,
  `OpenDoor/CloseDoor`, `GetSeatParams`.
- **`ObjectState.*`** — `GetLinkGuid`, `SetState`, `SendDamage`, `StartEmitter/StopEmitter`
  (destructible sets, FX props).
- **`Hud.Radar` / `Marker` / `Pda.Map`** — objective + off-screen marker drawing.
- **`Event.*`** — `Create`, `CreatePersistent`, `Delete`, `Post`; event types
  `ObjectHibernation`, `ObjectProximity`, `ObjectInSeat`, `ObjectDeath`, `ObjectHealth`,
  `ObjectWinched`, `ObjectIsReady`, `ObjectIsGrounded`, `WeaponEvent`, `Boundary`,
  `ContextAction`, `TimerRelative/Timer`, `Button`, `ScriptEvent`, `HumanStateTransition`.

### 7.2 How scripts bind to placements
The placement names a script module; the engine resolves it under `resident/` and dispatches
the convention callbacks (§1.1). The integer `iArg` discriminates variants. Many scripts gate
on `Net.IsServer()/IsClient()` and sync via `Net.SendCustomEvent("<Channel>", id, args)` routed
back through that module's `NetEventCallback` (alarm, munitions, outpost, danceradio, moonpatrol,
spyhunter all define their own `NETEVENT_*` enums).

### 7.3 Extension points / observations
- **Adding an AI unit**: subclass nothing — drop an `OnDeath`/`OnActivate` script and use
  `mrxai`/`Ai.*` for behavior; follow `soldier`/`paratrooper` for drop/respawn patterns.
- **Adding a blippable**: `inherit("VehicleBlippable")` (driver-colored) or `inherit("Blippable")`
  (fixed) and set `sTexture`/`nSize`/`tColor`; `Create` is auto-called from `OnActivate`.
- **Destructible content** lives in `OnStateChange` keyed by *hashed* node/state names
  (`String.GetHash`, `Sys.GuidToString`); the oilrig/islandfortress `_ProcessNextEvent` pattern
  is the reusable sequenced-demolition driver.
- **Many lifestyle props are intentionally empty** (`bench`, `binoculars`, `telephone`,
  `monument`, `outhouse`, `foodcart`, `fountain`, `despawner`, `hackybench`): the engine still
  needs the script to exist so its `Use`/`Query*` verbs resolve, but the gameplay is handled
  natively. `danceradio.OnActivate` is *disabled* (returns immediately; old impl is
  `OnActivateOld`) ([danceradio.lua:3](src/resident/danceradio.lua#L3)).
- **`airstrike_atomsphere_*`** are pure render-flash scripts (atmosphere/bloom + `ShieldFace`),
  one per ordnance type; only the bloom/light/restore magnitudes differ (e.g. tactnuke
  `fLightIntensity`=6, `fTimeRestore`=5.5). Safe to treat as a single template family.
- **Save/load**: `munitions` and `friendlygate` implement `SaveSingleton`/`LoadSingleton`
  (taggable flags / locked-gate set) — the pattern for per-script persistent state.
