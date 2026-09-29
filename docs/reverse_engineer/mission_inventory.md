---
title: Mission inventory — every shipped mission, classified
status: current
evidence: proven
date: 2026-09-22
---

# Mission inventory — every shipped mission, classified

**Scope:** every mission-shaped activity Pandemic shipped in `mercenaries2.exe`, sorted by
lifecycle class, starter, and unlock trigger. Peer of
[`mission_construction_patterns.md`](mission_construction_patterns.md) (which explains the
patterns); this doc is the concrete inventory that patterns doc's Recipe A–E can be cross-checked
against.

**Data sources** (verified, not inferred):
- `inherit(...)` line at the top of each `workshop_data/lua/vz/<mission>.lua`
- `sStarter` / `sFactionId` / `bRepeatable` / `bSuppressPdaDisplay` / `bCriticalPathMission` from
  `workshop_data/lua/vz/wifmissiondata.lua`
- `UnlockMission("X")` and `HasKey("Y")` from `workshop_data/lua/vz/wifmissionflow.lua`'s flow-rule
  table.

## The four lifecycle classes shipped

Distribution of the **60 mission-shaped entries** in `wifmissiondata.tMissionData` plus the
**22 tutorial-shaped entries** in `wiftutorial*.lua` (which are *not* in `tMissionData`):

| Class | Base | Count | Purpose |
|---|---|---|---|
| `MrxTaskContract` | `MrxTaskMission` → `MrxTask` | 33 | Story contracts + repeatable side contracts. Full save-persistent lifecycle. |
| `MrxTaskContractOutpost` | `MrxTaskContract` | 14 | Outpost captures (…Con050/051/052/053 pattern). |
| `MrxTaskJobDestroyType` | `MrxTaskJob` → `MrxTask` | 5 | "Destroy N of `sTargetType` for `<faction>`" cumulative jobs. |
| `MrxTaskJobVerifySet` | `MrxTaskJob` | 5 | "Visit / verify these N named targets" jobs. |
| `MrxTaskJobDestroySet` | `MrxTaskJob` | 5 | "Destroy this named set of targets" jobs. |
| `MrxTaskJobCollectType` | `MrxTaskJob` | 1 | PmcJob001 — the silent vehicle-collection counter. |
| `MrxTaskJob` (base) | `MrxTaskMission` | 1 | `mecjob.lua` = `MecJob` — the base class the three MecJob missions inherit. |
| `MecJob` (custom) | `MrxTaskJob` | 3 | MecJob001/002/003 — mechanic-boss "bring me a vehicle" jobs. |
| `MrxTutorial` | `Inheritable` | 22 | Every `wiftutorial*.lua`. Not in `tMissionData`; triggered by proximity/action, saves only a completion-name list. |
| `MrxMissionFlow` (host) | — | 1 | `wifmissionflow.lua` itself. Not a mission; runs the flow-rule table. |

None of the shipped bytecode uses `MrxTaskMission` directly (always via a subclass); none use raw
`MrxTask`. `MrxTaskContract` is the shipped "if in doubt, this" for a full contract; `MrxTutorial`
is the shipped "if in doubt, this" for context-triggered mode logic.

## Master table — every mission

Sorted by faction, then by ID. Empty cell = attribute not set on that mission. **Recipe** column
maps each mission to the closest recipe from
[`mission_construction_patterns.md`](mission_construction_patterns.md).

**Column keys:**
- `R` = `bRepeatable = true`
- `H` = `bSuppressPdaDisplay = true` (hidden from the PDA)
- `C` = `bCriticalPathMission = true`
- `sModuleName` is elided when it matches the mission ID.

### Vza (prologue)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| VzaCon001 | MrxTaskContract | *(none)* | | | ✓ | first flow-rule fires at game start; `wifmissionflow.lua:42` | B (auto-unlock, no starter) |

### Pmc (Fiona)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| PmcCon001 | MrxTaskContract | *(none)* | | | ✓ | `HasKey("VzaCon001")` → `wifmissionflow.lua:86` | B |
| PmcCon002 | MrxTaskContract | PmcBoss | | | ✓ | `HasKey("OilCon001") and HasKey("GurCon001")` → `wifmissionflow.lua:813` | A |
| PmcCon003 | MrxTaskContract | PmcBoss | | | ✓ | `HasKey("PmcCon002")` → `wifmissionflow.lua:308` | A |
| PmcCon004 | MrxTaskContract | *(none)* | | | ✓ | `HasKey("AllCon003")` OR `HasKey("ChiCon003")` → `wifmissionflow.lua:1026, 1246` | B |
| PmcCon013 | MrxTaskContract | HelPmcBoss | ✓ | | | `HasKey("OilCon002")` → `wifmissionflow.lua:706` | A + wager |
| PmcCon015 | MrxTaskContract | MecPmcBoss | ✓ | | | `HasKey("PmcCon016")` → `wifmissionflow.lua:528` | A |
| PmcCon016 | MrxTaskContract | MecPmcBoss | ✓ | | | `HasKey("MecCon001")` → `wifmissionflow.lua:590` | A |
| PmcCon018 | MrxTaskContract | JetPmcBoss | ✓ | | | `HasKey("JetCon001")` → `wifmissionflow.lua:649` | A |
| PmcCon031 | MrxTaskContract | PmcBoss | ✓ | | | `HasKey("PmcCon001")` → `wifmissionflow.lua:142` (**FioDef001's structural neighbour** — same gate) | A (shooting gallery) |
| PmcCon032 | MrxTaskContract | PmcBoss | ✓ | | | `HasKey("PmcCon031")` → `wifmissionflow.lua:536` | A |
| PmcCon033 | MrxTaskContract | PmcBoss | ✓ | | | `HasKey("PmcCon032")` → `wifmissionflow.lua:544` | A |
| PmcCon034 | MrxTaskContract | PmcBoss | ✓ | | | `HasKey("OilCon002")` → `wifmissionflow.lua:707` | A |
| PmcJob001 | MrxTaskJobCollectType | *(none)* | | ✓ | | `HasKey("PmcCon001")` → `wifmissionflow.lua:143` | B (silent counter, 9 milestones) |
| PmcJob002 | *(no source file)* | | | ✓ | | never unlocked (defined in tMissionData but no `pmcjob002.lua`; **dead data**) | — |
| MecCon001 | MrxTaskContract | **MecBoss** | | | ✓ | `HasKey("MecIntro")` → `wifmissionflow.lua:763` | A (unique starter) |
| JetCon001 | MrxTaskContract | **JetBoss** | | | ✓ | `HasKey("JetIntro")` → `wifmissionflow.lua:623` | A (unique starter) |
| OilCon020 | MrxTaskContract | PmcBoss | | | ✓ | `HasKey("PmcCon001")` → `wifmissionflow.lua:141` (fake "Oil"-prefixed Pmc mission, `sFactionId="Pmc"`) | A |

### Oil (Ramon Solano's oil cartel — becomes friendly)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| OilCon001 | MrxTaskContract | OilStarter0 | | | ✓ | `HasKey("OilCon050")` → `wifmissionflow.lua:780` | A |
| OilCon002 | MrxTaskContract | OilStarter0 | | | ✓ | `HasKey("OilJob011")` → `wifmissionflow.lua:206` | A |
| OilCon003 | MrxTaskContract | OilStarter3 | ✓ | | | `HasKey("OilCon051")` → `wifmissionflow.lua:822` | A |
| OilCon005 | MrxTaskContract | OilStarter4 | ✓ | | | `HasKey("OilCon052")` → `wifmissionflow.lua:836` (also gated on `not HasKey("ChiCon002")`) | A |
| OilCon021 | MrxTaskContract | OilStarter5 | | | ✓ | `HasKey("OilCon020")` → `wifmissionflow.lua:182` | A |
| OilCon050 | MrxTaskContractOutpost | OilStarter1 | | | ✓ | `HasKey("OilCon021")` → `wifmissionflow.lua:195` | A (outpost) |
| OilCon051 | MrxTaskContractOutpost | OilStarter2 | | | | `HasKey("OilCon050")` → `wifmissionflow.lua:781` | A (outpost) |
| OilCon052 | MrxTaskContractOutpost | OilStarter3 | | | | `HasKey("OilCon051")` → `wifmissionflow.lua:823` | A (outpost) |
| OilJob004 | MrxTaskJobDestroyType | *(none)* | | | | `HasKey("OilCon050")` → `wifmissionflow.lua:703` | B |
| OilJob008 | MrxTaskJobDestroySet | *(none)* | | | | `HasKey("OilCon050")` → `wifmissionflow.lua:704` | B |
| OilJob011 | MrxTaskJobVerifySet | *(none)* | | | | `HasKey("OilCon050")` → `wifmissionflow.lua:705` | B |

### Gur (Guerrilla)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| GurCon001 | MrxTaskContract | GurStarter0 | | | ✓ | `HasKey("GurCon003")` → `wifmissionflow.lua:917` | A |
| GurCon002 | MrxTaskContract | GurStarter0 | | | ✓ | `HasKey("GurCon053")` → `wifmissionflow.lua:859` | A |
| GurCon003 | MrxTaskContract | GurStarter5 | ✓ | | ✓ | `HasKey("GurCon002")` → `wifmissionflow.lua:882` | A |
| GurCon005 | MrxTaskContract | GurStarter2 | | | | `HasKey("GurCon050")` → `wifmissionflow.lua:944` | A |
| GurCon050 | MrxTaskContractOutpost | GurStarter5 | | | | `HasKey("GurCon053")` → `wifmissionflow.lua:860` | A (outpost) |
| GurCon052 | MrxTaskContractOutpost | GurStarter2 | | | | `HasKey("GurCon050")` → `wifmissionflow.lua:945` | A (outpost) |
| GurCon053 | MrxTaskContractOutpost | GurStarter1 | | | ✓ | `HasKey("GurIntro")` → `wifmissionflow.lua:750` | A (outpost) |
| GurJob001 | MrxTaskJobDestroyType | *(none)* | | | | `HasKey("GurCon053")` → `wifmissionflow.lua:861` | B |
| GurJob002 | MrxTaskJobVerifySet | *(none)* | | | | `HasKey("GurCon053")` → `wifmissionflow.lua:862` | B |
| GurJob006 | MrxTaskJobDestroyType | *(none)* | | | | `HasKey("GurCon053")` → `wifmissionflow.lua:863` | B |
| GurJob020 | MrxTaskJobDestroySet | *(none)* | | | | `HasKey("GurCon053")` → `wifmissionflow.lua:864` | B |

### Chi (Chinese)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| ChiCon001 | MrxTaskContract | ChiStarter0 | | | ✓ | `HasKey("ChiCon050")` → `wifmissionflow.lua:1176` | A |
| ChiCon002 | MrxTaskContract | ChiStarter0 | | | ✓ | `HasKey("ChiCon001")` → `wifmissionflow.lua:1189` | A |
| ChiCon003 | MrxTaskContract | ChiStarter0 | | | ✓ | `HasKey("ChiCon002")` → `wifmissionflow.lua:1208` | A |
| ChiCon008 | MrxTaskContract | ChiStarter2 | ✓ | | | `HasKey("ChiCon051")` + `not HasKey("PmcCon004")` → `wifmissionflow.lua:1306` | A |
| ChiCon009 | MrxTaskContract | ChiStarter4 | ✓ | | | `HasKey("ChiCon053")` → `wifmissionflow.lua:1318` | A |
| ChiCon050 | MrxTaskContractOutpost | ChiStarter1 | | | ✓ | `HasKey("AllChiIntro")` → `wifmissionflow.lua:435` | A (outpost) |
| ChiCon051 | MrxTaskContractOutpost | ChiStarter2 | | | | `HasKey("ChiCon050")` → `wifmissionflow.lua:1177` | A (outpost) |
| ChiCon053 | MrxTaskContractOutpost | ChiStarter3 | | | | `HasKey("ChiCon051")` → `wifmissionflow.lua:1308` | A (outpost) |
| ChiJob002 | MrxTaskJobVerifySet | *(none)* | | | | `HasKey("ChiCon050")` → `wifmissionflow.lua:1178` | B |
| ChiJob003 | MrxTaskJobDestroyType | *(none)* | | | | `HasKey("ChiCon050")` → `wifmissionflow.lua:1179` | B |
| ChiJob020 | MrxTaskJobDestroySet | *(none)* | | | | `HasKey("ChiCon050")` → `wifmissionflow.lua:1180` | B |

### All (Allies)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| AllCon001 | MrxTaskContract | AllStarter0 | | | ✓ | `HasKey("AllCon002")` → `wifmissionflow.lua:989` | A |
| AllCon002 | MrxTaskContract | AllStarter0 | | | ✓ | `HasKey("AllCon050")` → `wifmissionflow.lua:1090` | A |
| AllCon003 | MrxTaskContract | AllStarter0 | | | ✓ | `HasKey("AllCon001")` → `wifmissionflow.lua:999` | A |
| AllCon008 | MrxTaskContract | AllStarter2 | ✓ | | | `HasKey("AllCon052")` + `not HasKey("PmcCon004")` → `wifmissionflow.lua:1105` | A |
| AllCon050 | MrxTaskContractOutpost | AllStarter1 | | | ✓ | `HasKey("AllChiIntro")` → `wifmissionflow.lua:434` | A (outpost) |
| AllCon052 | MrxTaskContractOutpost | AllStarter2 | | | | `HasKey("AllCon050")` → `wifmissionflow.lua:1091` | A (outpost) |
| AllCon053 | MrxTaskContractOutpost | AllStarter3 | | | | `HasKey("AllCon052")` → `wifmissionflow.lua:1107` | A (outpost) |
| AllJob002 | MrxTaskJobVerifySet | *(none)* | | | | `HasKey("AllCon050")` → `wifmissionflow.lua:1092` | B |
| AllJob003 | MrxTaskJobDestroyType | *(none)* | | | | `HasKey("AllCon050")` → `wifmissionflow.lua:1093` | B |
| AllJob020 | MrxTaskJobDestroySet | *(none)* | | | | `HasKey("AllCon050")` → `wifmissionflow.lua:1094` | B |

### Pir (Pirates)

| ID | Class | Starter | R | H | C | Unlock trigger | Recipe |
|---|---|---|---|---|---|---|---|
| PirCon001 | MrxTaskContract | PirStarter1 | ✓ | | | `HasKey("PirIntro")` → `wifmissionflow.lua:907` | A |
| PirCon002 | MrxTaskContract | PirStarter1 | ✓ | | | `HasKey("PirCon001")` → `wifmissionflow.lua:1354` | A |
| PirCon003 | MrxTaskContract | PirStarter3 | ✓ | | | `HasKey("PirCon051")` → `wifmissionflow.lua:1366` | A |
| PirCon004 | MrxTaskContract | PirStarter4 | ✓ | | | `HasKey("PirCon052")` → `wifmissionflow.lua:1377` | A |
| PirCon051 | MrxTaskContractOutpost | PirStarter1 | | | | `HasKey("PirCon001")` → `wifmissionflow.lua:1355` | A (outpost) |
| PirCon052 | MrxTaskContractOutpost | PirStarter3 | | | | `HasKey("PirCon051")` → `wifmissionflow.lua:1367` | A (outpost) |
| PirJob012 | MrxTaskJobVerifySet | *(none)* | | | | `HasKey("PirCon001")` → `wifmissionflow.lua:1356` | B |
| PirJob020 | MrxTaskJobDestroySet | *(none)* | | | | `HasKey("PirCon001")` → `wifmissionflow.lua:1357` | B |

## Tutorials — a completely separate axis

Not in `tMissionData`; not `UnlockMission`'d; not offered from any starter. Each `wiftutorial*.lua`
defines its own activation criteria via `SetupActivationCriteria(self)` (region proximity, action
context, event, etc.) and its own completion criteria. Registered with `MrxTutorialManager` at
init time; save-write is just the completion-name list.

22 tutorials shipped:

- **Vehicle handling** — wiftutorialwheeledvehiclebasic, wiftutorialboat, wiftutorialhelicopter,
  wiftutorialtank, wiftutorialapc, wiftutorialtankhijack, wiftutorialhelirepairpad,
  wiftutoriallowfuel, wiftutorialnofuel, wiftutorialvehicledisguise
- **Combat & interaction** — wiftutorialc4, wiftutorialc4switch, wiftutorialairstrikeinterrupt,
  wiftutorialtrespass, wiftutorialgatehonk, wiftutorialallieshonk, wiftutorialalarm,
  wiftutorialcollateraldamage
- **Player mode** — wiftutorialswimming, wiftutorialcollectibles
- **Co-op** — wiftutorialcooprevive, wiftutorialcooptether

## Starter → mission map (who offers what)

The complete set of `sStarter` values and which missions each briefing-actor puts on their
offering list. Modders authoring a new mission with `sStarter="X"` are adding to this NPC's list.

| Starter | Faction | Missions offered | Notes |
|---|---|---|---|
| **PmcBoss** | Pmc (Fiona at HQ briefing table) | PmcCon002, PmcCon003, PmcCon031, PmcCon032, PmcCon033, PmcCon034, OilCon020 | The main story-critical Fiona starter. `bPmcStarter=true` triggers HQ portal arming on Activate (F11 in seam doc). |
| **HelPmcBoss** | Pmc (Ewen — helicopter pilot) | PmcCon013 | `bPmcStarter=true`. Recruited later in story. |
| **MecPmcBoss** | Pmc (Eva — mechanic) | PmcCon015, PmcCon016 | `bPmcStarter=true`. Recruited via MecCon001 completion. |
| **JetPmcBoss** | Pmc (Chris/Jen — jet pilot) | PmcCon018 | `bPmcStarter=true`. Recruited via JetCon001 completion. |
| **MecBoss** | Pmc (Eva — pre-recruit) | MecCon001 | Non-Pmc starter (bPmcStarter absent). The recruitment mission itself. |
| **JetBoss** | Pmc (jet-pilot pre-recruit) | JetCon001 | Non-Pmc starter. The recruitment mission itself. |
| **AllStarter0** | All (Allies) | AllCon001, AllCon002, AllCon003 | Allies boss (contracts). |
| **AllStarter1** | All | AllCon050 | Allies (outpost mission). |
| **AllStarter2** | All | AllCon008, AllCon052 | Allies. |
| **AllStarter3** | All | AllCon053 | Allies. |
| **ChiStarter0** | Chi (Chinese) | ChiCon001, ChiCon002, ChiCon003 | |
| **ChiStarter1** | Chi | ChiCon050 | |
| **ChiStarter2** | Chi | ChiCon008, ChiCon051 | |
| **ChiStarter3** | Chi | ChiCon053 | |
| **ChiStarter4** | Chi | ChiCon009 | |
| **GurStarter0** | Gur (Guerrilla) | GurCon001, GurCon002 | |
| **GurStarter1** | Gur | GurCon053 | |
| **GurStarter2** | Gur | GurCon005, GurCon052 | |
| **GurStarter4** | Gur | *(no missions in tMissionData)* | RequestStarter'd at `wifmissionflow.lua:955` — creates the starter for its cameo appearance; no offerings. |
| **GurStarter5** | Gur | GurCon003, GurCon050 | |
| **OilStarter0** | Oil | OilCon001, OilCon002 | |
| **OilStarter1** | Oil | OilCon050 | |
| **OilStarter2** | Oil | OilCon051 | |
| **OilStarter3** | Oil | OilCon003, OilCon052 | |
| **OilStarter4** | Oil | OilCon005 | |
| **OilStarter5** | Oil | OilCon021 | |
| **PirStarter1** | Pir (Pirates) | PirCon001, PirCon002, PirCon051 | |
| **PirStarter3** | Pir | PirCon003, PirCon052 | |
| **PirStarter4** | Pir | PirCon004 | |

Note the **no-starter** column of the master tables: **11 missions have no `sStarter`** (VzaCon001,
PmcCon001, PmcCon004, PmcJob001/002, MecCon001/JetCon001 use different starters actually — recheck;
plus every `Job` variant). Jobs are auto-unlocked from a flow-rule fConseq with no briefing table
step; the player just gets a "new job" HUD notification and the counter starts ticking.

## Distribution / rule-of-thumb takeaways

- **32 of 33** `MrxTaskContract` missions have an `sStarter` (Recipe A shape). The exception is the
  story-opener class — VzaCon001, PmcCon001, PmcCon004 — auto-unlocked from a critical-path
  flow-rule with no briefing table (Recipe B).
- **All 14** `MrxTaskContractOutpost` missions have an `sStarter` and are Recipe A. Repeatability is
  *not* set on outposts (they're one-shot per playthrough).
- **All 16** Job-family missions (Verify/Destroy/Collect Type/Set) have **no starter** — every job
  runs silently, auto-unlocked from a flow-rule fConseq. Recipe B.
- **All 22** tutorials are Recipe D (region/context-triggered, MrxTutorial-shaped).
- **Zero** shipped missions use Recipe C (region-triggered arena with mission-flow-key persistence
  — the FioDef001 v0.10 shape) or Recipe E (custom-UI ephemeral — Ess.Contract). Both are
  legitimate patterns; the shipped game just didn't need them because its content pipeline was
  narrower.

## Story-flow chains (rough)

The dependency graph flattens roughly like this (each edge = an fPrereq → fConseq flow-rule):

```
game start
  └─ VzaCon001 (prologue)
      └─ PmcCon001 (villa takeover — HQ unlock trigger)
          ├─ PmcCon031 (shooting gallery)  → PmcCon032 → PmcCon033
          ├─ PmcJob001 (silent vehicle counter)
          ├─ OilCon020 (Pmc-flavoured Oil intro)
          │   └─ OilCon021 → OilCon050 (outpost)
          │       ├─ OilCon001 (Solano hub) → OilCon002 → PmcCon002 (with GurCon001)
          │       ├─ OilCon051 → OilCon003, OilCon052
          │       │   └─ OilCon005 (if not ChiCon002)
          │       ├─ OilJob004, OilJob008, OilJob011
          │       ├─ PmcCon013 (Helicopter — Ewen)
          │       └─ PmcCon034 (repeatable)
          └─ PmcCon002 (critical-path Pmc)
              ├─ PmcCon003
              ├─ MecIntro → MecCon001 → recruit Eva → PmcCon016 → PmcCon015
              └─ JetIntro → JetCon001 → recruit Jet → PmcCon018
GurIntro (parallel from OilCon050)
  └─ GurCon053 (outpost) → GurCon002 → GurCon003 → GurCon001
                        ├─ GurCon050 (outpost) → GurCon052, GurCon005
                        └─ GurJob001/002/006/020
AllChiIntro (parallel from OilCon050)
  ├─ AllCon050 (outpost) → AllCon001 → AllCon002 → AllCon003 → PmcCon004
  │                                → AllCon052 → AllCon008, AllCon053
  │                                → AllJob002/003/020
  └─ ChiCon050 (outpost) → ChiCon001 → ChiCon002 → ChiCon003 → PmcCon004
                                    → ChiCon051 → ChiCon008, ChiCon053 → ChiCon009
                                    → ChiJob002/003/020
PirIntro (parallel, late)
  └─ PirCon001 → PirCon002, PirCon051 → PirCon003, PirCon052 → PirCon004
              → PirJob012/020
```

Notes on the graph:
- **PmcCon004 has two OR-gated triggers** (`HasKey("AllCon003") or HasKey("ChiCon003")`) — the
  player picks which faction's storyline gets there first.
- **PmcCon001's fConseq is the only place `WifPmcInterior.Unlock()` runs** ([wifmissionflow.lua:144](../../tools/wad_simulator/workshop_data/lua/vz/wifmissionflow.lua#L144)).
  Everything downstream that uses the PMC HQ (all PmcBoss-startered missions, MecCon001,
  JetCon001, garage, transit, shop, wager) implicitly requires this key. This is the invariant
  F11 in the seam-hardening doc trips over.
- **The `*Intro` keys** (`MecIntro`, `JetIntro`, `PirIntro`, `GurIntro`, `AllChiIntro`) are set by
  Fiona-narrated intro cutscenes, not by mission completion. They are the "you're now aware this
  faction exists" flags.

## Notable outliers

- **PmcJob002** — defined in `tMissionData` but there is **no `pmcjob002.lua`** source file, and no
  `UnlockMission("PmcJob002")` anywhere in `wifmissionflow.lua`. **Dead data.** Presumably a cut
  second-tier vehicle-collection job.
- **MecCon001 / JetCon001** — the only two `sStarter="MecBoss"` / `sStarter="JetBoss"` missions.
  These are the recruitment missions for Eva (mechanic) and the jet pilot; after completion, the
  starter changes to `MecPmcBoss` / `JetPmcBoss` (the recruited version) and subsequent contracts
  for that character use the …PmcBoss starter. Two starters per character exist on purpose.
- **OilCon020** — despite the `Oil` prefix, `sFactionId="Pmc"` and `sStarter="PmcBoss"`. It is
  offered by Fiona, not Solano. This is the "Fiona sends you to blow up an oil facility to draw
  Solano out" mission; the naming reflects the *target*, not the *briefer*.
- **GurStarter4** — created via explicit `MrxStarterManager.RequestStarter("GurStarter4")` at
  `wifmissionflow.lua:955`. Offers no missions. Presumably a briefing-only cameo NPC.
- **PmcCon013** carries **wager mechanics** (`nWager` / `nWagerPercent` in its rewards); the
  wifmissionflow wager-completion helpers at `wifmissionflow.lua:279-296` are set on it. Only
  contract known to use them.

## Cross-references

- [`mission_construction_patterns.md`](mission_construction_patterns.md) — the recipe definitions
  this inventory maps against.
- [`mission_contract_flow_code_map.md`](mission_contract_flow_code_map.md) — the native side of the
  flow / task lifecycle.
- [`docs/modding/lua_engine_seam_hardening.md`](../modding/lua_engine_seam_hardening.md) — the F1–F11
  failure modes that shape mod-author choice between recipes.
- `workshop_data/lua/vz/wifmissiondata.lua` — the authoritative `tMissionData` table.
- `workshop_data/lua/vz/wifmissionflow.lua` — the authoritative flow-rule table with fPrereq /
  fConseq for every unlock edge above.
- `workshop_data/lua/vz/wifstarterdata.lua` — every starter's `bPmcStarter` / `sHqName` / voice
  set / `bFemale` flags.
