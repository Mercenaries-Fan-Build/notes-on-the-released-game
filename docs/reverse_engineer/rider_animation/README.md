---
status: current
evidence: proven
---

# Seated-rider animation in retail (pc-v10): spec for the Speed Boat driver

Read of 2026-11-25. Each claim carries its own grade. Sources:
- the unpacked exe `game-files/canonical/dumps/mercs2_unpacked.exe`, sha256 `8c179a99…ebc7ba` (verified this run), read with `objdump -d --x86-asm-syntax=intel`;
- the corpus Ghidra exports for pc-v10;
- `vz.wad`, read with `mercs2_probe` and `humanstate_probe` from the game-parity worktree;
- the capture `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp`, read with `dump-entity`, `dump-read`, `dump-find`, `dump-pool`, `dump-near` and `dump-containers`.

The live Ghidra bridge was locked by another JVM and was left alone.

Grades:
- **PROVEN**: read this run from bytes, a disassembly or a capture.
- **INFERRED**: reasoned from proven facts but not checked.
- **SPECULATIVE**: a guess.

The files this page names were working files and are not kept:
- `emu_*.txt` (table emulation);
- `vehanimlookup.txt`, `actiontable.txt` and `humanstate.txt` (table dumps: `mercs2_probe anim-table` and
  `humanstate_probe` give them again);
- `dis_*.txt` (disassembly: `objdump -d` of the image at the cited addresses gives them again).

---

## 0. The answer in one paragraph

**Mattias** (hero `0x40004E98`, template `0x80000003` "mattias") is seated as driver of the Speed Boat. He is in state **`InVehicle.Idle`** (`0x5E2CD838` / `0xB4DA003B`). The ActionTable row that matches is row 226, `InVehicle / Idle / Seat = seat_driver 0xF8B8325F`. It gives **Handle `0x340FE8DB`** with **Looping = TRUE**. That Handle is resolved through the **VehicleAnimationLookup** `0x182624E1`, not the human AnimationLookup. The key is `(Handle 0x340FE8DB, VehicleClass Boat 0x45847B03, VehicleName Cigarette 0x8F3CE8CB, SeatName seat_driver)`, and it lands on data row 1504.

The result is clip **`0x3D50E160`**:
- it is in block **3348, `vehiclenameanimgroup_cigarette`**;
- it is a wavelet clip, 2.002 s long, with 61 poses and 60 tracks, all of which bind to the `pmc_hum_mattias` skeleton;
- it plays as a single looping clip with no input-driven blend weight. The crossfade on a state change is INFERRED (§3.1).

This VehicleAnimationLookup row has no character column, so every hero plays the same clip in this seat.

While the boat steers, the driver's state switches between discrete looping clips (§3). The switch is driven by the vehicle **Turn** command value:

| State | Clip |
|---|---|
| `SteerLeft45` | `0xF1B22381` |
| `SteerLeft90` | `0x827092DB` |
| `SteerRight45` | `0xED04FC3E` |
| `SteerRight90` | `0x6AD9BAAC` |
| `SteerZero` | back to Idle, `0x3D50E160` |

Grade:
- the capture chain and the table decode are PROVEN (§4, §2);
- the steering rule is PROVEN by disassembly;
- the sign convention of the Turn value is NOT DETERMINED.

---

## 1. Entering a seat: the state and the key

### 1.1 `Vehicle.Enter` (PC `0x005E8060`). PROVEN by disassembly (`dis_5e8060.txt`)

| Lua arg | Read at | Default | Meaning |
|---|---|---|---|
| 1 vehicle | `0x5E8098` → `[esp+0x14]` | — | |
| 2 character | `0x5E80F7` → `[esp+0x1C]` | — | |
| 3 seat type | `0x5E8110` → `ebx` | `"d"` (`0x5E8122`, `0x00BB23E8`) | first char, `tolower`, jump table at `0x5E8238` (see `seat_type.md`) |
| 4 bool | `0x5E8130` → `[esp+0xF]` | **true** (`0x5E813D`) | **true** means immediate: `FUN_00539FF0(char, seat, 0, arg5)` at `0x5E81D8`. **false** means the entrance path: `FUN_00535CC0(char, seat, 0)` picks an entrance (`0x5E81FA`), then `FUN_00538FE0(char, entrance)` runs (`0x5E8208`) |
| 5 bool | `0x5E814B` → `[esp+0x18]` | false (`0x5E8154`) | passed to the immediate path only |

The return value goes through `FUN_004B86E0` as a Lua value. New Game (`vzacon001.lua:96`) calls `Vehicle.Enter(uBoat, uChar, "d", false)`, so it takes the **entrance path** and not the immediate one. Grade: PROVEN.

### 1.2 Immediate path `FUN_00539FF0`. PROVEN

At `0x53A23E`–`0x53A262` it posts a human state transition through `FUN_00423D10({rider, name, 0})`:
- **`EnterVehicleImmediate` `0xD7DFD0BE`**;
- or **`MountLadderImmediate` `0x9E74E20B`**, when the entrance's `EntranceParameters` (`0x017BD858`) word `+0x18` has bit `0x4` set.

In the HumanStateTable, `EnterVehicleImmediate` leads to **`InVehicle.Idle`** from `Upright.Idle` and from every InVehicle action (`humanstate.txt`). Grade: PROVEN.

### 1.3 Entrance path `FUN_00538FE0(rider, entrance)`. PROVEN for the branches below

- `0x5390BC` `FUN_00534790(rider)`: if this returns false, the code falls back to the immediate `FUN_00539FF0` (`0x5390D0`). What `FUN_00534790` tests was not read.
- `0x5392B0` `FUN_005347F0(seat, entrance)`: if this returns true, the code also takes the immediate path (`0x5392C3`). Not read.
- Otherwise `FUN_00537A10(EntranceParameters+0x10, 1)`, which is a door test (INFERRED):
  - true: RiderLink record `+4 = 6`, then post **`EnterVehicleOpenDoor` `0x32F44843`** (`0x539317`);
  - false: post **`EnterVehicle` `0xFDB50EC7`** (`0x539335`).
- `0x53929F` posts a second event, `FUN_004239F0`, with `{2, rider, entrance, seat, …}`. INFERRED: a seat or attach request.
- From the state graph, `EnterVehicle` on `Complete` leads to `InVehicle.Idle`. PROVEN in `humanstate.txt`.

So the 4th argument is **`bImmediate`**. `false` requests an animated enter through an entrance (`EnterVehicle`, then `Complete`, then `Idle`). It can still collapse to the immediate path through the two untested predicates above.

**Whether New Game visibly plays the enter clip is NOT DETERMINED.** The capture is taken after the enter, and the two predicates were not read. One fact is consistent with the entrance path: the capture's RiderLink record `+8` = `0x400052A4`, which is an entrance (§4.4). That supports the entrance path (INFERRED) but does not prove the clip played.

**The player's Use key** reaches the same `FUN_00538FE0`. That the case-0 record is the Use key is INFERRED, because its producer was not read. The seat ring applier `FUN_0053F110` case 0 dispatches on the flags word `+0x3C`:
- bit `0x800` set: `FUN_00540690`;
- neither `0x1000` nor `0x40` set: `FUN_00538FE0(rec+8, rec+0x14)`.

Grade: PROVEN for the dispatch (decomp of `FUN_0053F110`).

### 1.4 The state key the engine writes. PROVEN (`FUN_0068A8C0`, `dis_68a8c0.txt`)

`FUN_0068A8C0(controller, entity, dt, flags)` is the per-frame ActionTable evaluator. `controller` is the `HumanAnimationControllerNEW` object. It builds an 8-column key from a copy of the defaults row, which is all `*` (`0x27DE7135`).

| Key col | Source | Instruction |
|---|---|---|
| 0 Stance | `HumanStateMachine +0x04` | `0x68A922` |
| 1 Action | `HumanStateMachine +0x08` | `0x68A932` |
| 2 AimState | `TRUE 0x1E5208DD` when `(flags[+0x3C] & 3) == 2` | `0x68AA0D`–`0x68AA1C` |
| 3 Tandem | when `flags & 0x200`: `0x2877CDDE`, or `0xF623D45B` if `flags & 0x400` (names not cracked) | `0x68AA23`–`0x68AA41` |
| **4 Seat** | **`SeatLink` record `+4` of the rider's seat**. The seat is the RiderLink owner (`0xDF8458` → `[0xDF846C]` → `[0xDF844C]`). This is set only when the rider also has a `RuntimePhysicalLink` owner (`0xDF9160`) | `0x68A943`–`0x68A9BD` |
| **5 Target** | RiderLink record `+8` (`0x68A9CD`). If it is a seat, its SeatLink `+4` is used (a seat-to-seat transfer target). Otherwise its `RuntimeEntranceLink` (`0xDF9210`) `+4` is used (the entrance name) | `0x68A9D4`–`0x68AA07` |
| 6 ActionDirection | `RuntimeAnimationParams` (`0x017BF428`) `+0x00`, when it is non-zero | `0x68AA51`–`0x68AA57` |
| 7 DamageDirection | `RuntimeAnimationParams +0x10`, when it is non-zero | `0x68AA5A`–`0x68AA61` |

The query is `FUN_0067CF20(ActionTable, key, 8)` at `0x68AA7D`. The result goes to controller `+0xA4` (`0x68AB23`). The row's `AnimationHandles` (`+0x20`) is then switched on at `0x68ACE6`:

| Handle | Node built | Into |
|---|---|---|
| `0x4FF9F863` = m2("NONE") | no new node; the locomotion controller `+0x88` is used | — |
| `0x7EB27FFB` | `FUN_007437B0` (0x38 bytes) | `+0xA0` |
| `0x1BEB81AA` | `FUN_00741250` (0x9C bytes) | `+0xA0` |
| `0x847AD822`, `0xE22B6FE7` | `FUN_00741950` (0xB8 bytes) | `+0xA0` |
| `0xD6FE195E` | `FUN_00742D10` (0x6C bytes) | `+0xA0` |
| **any other** | **`FUN_00743F20(rider=ECX, handle=EAX)`, a 0x50-byte single-clip node, vtable `0x00BD3330`** (`0x68AD79`–`0x68AD91`). Then `vtable+0x34(startTime)` is called (`0x68ADA2`). `startTime = (clock[sm+0x14] − sm+0x10) × [0xF800AC]`, where `[0xF800AC] = 1/3000` | `+0xA0` |

**For a seated rider, the seat comes from the SeatLink and the target from the RiderLink's third word (the entrance or the target seat).** Nothing comes from the seat type letter. The `SeatParameters` and `EntranceToSeat` values are not read on this path. Grade: PROVEN for the code shown.

### 1.5 Handle to clip for a node: `FUN_00743E60`. PROVEN (`dis_7439c0.txt`)

`FUN_00743F20` calls `FUN_00743E60(rider, handle, forceHuman = 0, &out)` (`0x743F83`). Node `+0x4C` = 0. The sibling `FUN_00743FB0` stores `+0x4C = 1`.

- If `forceHuman == 0` **and** the rider has a RiderLink owner (`0x743E6B`–`0x743E96`), the vehicle lookup is used: `FUN_007439C0` builds the key, then `FUN_00743C40` queries VehicleAnimationLookup.
- Otherwise the human lookup is used: `FUN_00743B20` builds the key, then `FUN_00743CD0` queries AnimationLookup (already documented in `human_animation_selection.md` §3).
- `FUN_00743D80(out, rider, …)` turns the clip hash into an asset reference. In the capture that reference is `{clip, type 0x18166555 = m2("Animation")}` (§4.3).

---

## 2. `VehicleAnimationSet` and `VehicleAnimationLookup 0x182624E1`

### 2.1 `VehicleAnimationSet` component

The schema comes from `mercs2_probe we-template --class VehicleAnimationSet`: stride 8, version 79. Container `0x017BCD68`, C50, id 74, keyed by template.

| Off | Hash | Field |
|---|---|---|
| +0 | `0xB818CE01` | `VehicleClass` |
| +4 | `0xA61B7F72` | `VehicleName` |

Speed Boat `0x80006A22` holds `VehicleAnimationSet 45847B03 8F3CE8CB` = **`Boat`**, **`Cigarette`**. These are `pandemic_hash_m2("Boat")` and `("Cigarette")`. The template also carries `Label 45847B03`. The live record (`dump-pool VehicleAnimationSet`, key `0x80006A22` at `0x21377F00`) holds the same values. Grade: PROVEN.

### 2.2 Table layout

From `mercs2_probe anim-table 0x182624E1`: 6 key columns out of 9, 2847 data rows, **no ASTO pool**.

`Handle, VehicleClass, VehicleName, SeatName, MountedEquipmentClass, MountedEquipmentName, Animation, MinTimeScale, MaxTimeScale`

- `Animation` is the clip hash itself. There is no list and no random draw. The default value is `0x9D886544`.
- `MinTimeScale` and `MaxTimeScale` are f32, `-1` meaning the default.
- There is **no Gender or CharacterName column**.

Grade: PROVEN.

### 2.3 The query. PROVEN (`0x7439C0`–`0x743CCA`)

**Key, built by `FUN_007439C0(rider)`:**
1. Copy the table defaults row (`+0x2C`; `0x743A17`–`0x743A1C`).
2. seat = RiderLink owner of the rider (`0x743A28`–`0x743A49`).
3. Col 3 `SeatName` = the seat's SeatLink record `+4` (child index `0xDF81D8`, paged record; `0x743A54`–`0x743A9A`).
4. vehicle = the seat's SeatLink owner (`[0xDF81CC]`; `0x743A9D`–`0x743AC3`). If that is zero, the rider's `RuntimePhysicalLink` owner is used instead (`0x743ACC`–`0x743AED`).
5. Col 1 and col 2 = the vehicle's `VehicleAnimationSet` `{class, name}` (`0x743AEF`–`0x743B0B`).
6. Cols 4 and 5 (`MountedEquipment*`) are **never written** and stay `*`.

**Query, `FUN_00743C40`:**
1. Col 0 = Handle.
2. Output defaults to `{0x9D886544, −1, −1}`; `[0xDFDB5C]` = −1.0, read in the capture.
3. `FUN_0067CF20(table, key, 6)` (`0x743C58`–`0x743C6F`).
4. The winning row is accepted only if `VehicleClass ∈ {key, default}` **and** `VehicleName ∈ {key, default}` (`0x743C78`–`0x743CB2`).
5. Output = row `+0x18/+0x1C/+0x20` = `Animation, MinTimeScale, MaxTimeScale`.

The scoring inside `FUN_0067CF20` is the one documented for AnimationLookup: 2 per cell equal to the key, 1 per cell equal to the default, the first strictly highest wins. The candidate filter column is table `+0x54`, which reads `0xFFFFFFFF` in the capture for both this table (object `0x1FEDF7D0`) and the ActionTable (object `0x1FEDF1A0`). Grade: INFERRED for both points; the scorer was not re-read for this table.

### 2.4 Decoded rows for the Speed Boat driver seat

Every Cigarette row (VAL data rows 1502–1520) has `SeatName = *`. The seat is told apart by the **ActionTable** `Seat` column, which gives each seat its own Handle. Columns below: ActionTable row, then VAL row; VAL rows are 0-based data rows as `anim-table` prints them.

| State (`InVehicle.*`) | AT row | Handle | Looping | Driven | VAL row | Clip |
|---|---|---|---|---|---|---|
| **Idle** | 226 | `340FE8DB` | TRUE | * | 1504 | **`3D50E160`** |
| EnterVehicle | 220 | `1391E6D2` | * | TRUE | 1510 | `61B0138E` |
| ExitVehicle | 223 | `8E04C9B9` | * | TRUE | 1511 | `8C52015D` |
| SteerLeft45 | 229 | `EE2DAFCD` | TRUE | * | 1506 | `F1B22381` |
| SteerLeft90 | 230 | `9349CEE7` | TRUE | * | 1508 | `827092DB` |
| SteerRight45 | 231 | `87015E22` | TRUE | * | 1507 | `ED04FC3E` |
| SteerRight90 | 232 | `864150F0` | TRUE | * | 1509 | `6AD9BAAC` |
| Die | 227 | `32424AF7` | * | * | 1505 | `55E41DD3` |
| Dead | 228 | `F54D3417` | TRUE | * | none for Cigarette or `*` | `9D886544` (placeholder) |
| EnterHijack | 237 | `82EBC219` | * | TRUE | 1512 | `2D3EE6B5` |
| ExitHijack | 238 | `5D9DD84C` | * | TRUE | 1513 | `5E2AC3E0` |
| EnterVehicleOpenDoor / CloseDoor | 221 / 222 | `DD9A3585` / `44A49F61` | * | TRUE | none | placeholder (the boat has no doors) |
| ExitVehicleOpenDoor / CloseDoor | 224 / 225 | `FDB5B624` / `A64B6D9A` | * | TRUE | none | placeholder |
| SteerSweep | 233 | `FB7333DF` | * | * | none for Cigarette | placeholder (not used for Cigarette, §3) |

The raw Cigarette VAL rows are in `vehanimlookup.txt`, lines 1520–1538.

**Robustness (PROVEN, `emu_*.txt`).** The Idle, Enter, Exit, Steer, Die, Dead and Hijack rows win under all four candidate rules tried:
- Stance + Action;
- Stance only;
- all rows;
- exact-or-wildcard matching.

For each of these the winning row matches the key in every non-`*` cell. Two other kinds of output depend on the candidate rule and are **not** retail behaviour as established here: Scan, Dive, Fidget, Proximity, Driveby, DeathEject and SeatToSeatTransfer for this seat, and the boarding seats resolving to row 226.

The Target column does not change the driver rows: no `seat_driver` row has Target `0x004FA930`, so the key's Target scores 1 against `*`. PROVEN by grep on `actiontable.txt`.

---

## 3. While seated and driving

### 3.1 Single clip or blend

The Idle and Steer handles go through the default single-clip node `FUN_00743F20`. The handle values are not in the special switch list of §1.4. Each frame `FUN_0068A8C0` does the following (`0x68B121`–`0x68B236`):
- play mode = 2, or **3 when the row's `Looping` (`+0x28`) == TRUE** (`0x68B15B`);
- `node->vtable+0x24(dt, mode, rider)` advances the clip;
- when `node->vtable+0x28()` reports completion, it posts the transition **`Complete` `0xB6741F78`** (`0x68B21B`–`0x68B236`).

Rows 226 and 229–232 are Looping TRUE with Driven `*`. **So each state plays one looping clip, and no input-driven blend weight (left/right steer blend or throttle lean) exists on this path.** Grade: PROVEN for the code path.

How partitions and the controller's `+0x84`/`+0x90` children combine the clip is not decoded (§4.3). The weight slots read in the capture are all 1.0, but a separate upper-body layer is not ruled out by code.

**The Driven column** is TRUE on the Enter, Exit, Hijack and SeatToSeat rows and `*` on the Idle and Steer rows. So Driven plays no part in steering. What Driven = TRUE does (`FUN_0068A4B0`) was not read. That it means root motion for the enter and exit clips is SPECULATIVE. Crossfades between states come from the transition table `0xAB8FE34B`, which has no row naming any of these handles. That the wildcard row 0 applies (type `0xFB729A36`, name not cracked, duration 0.125 s) is INFERRED; the transition query was not read.

### 3.2 What changes the state: the steering rule. PROVEN (`dis_535590.txt`, `dis_5402b0.txt`, `dis_532f80.txt`)

The vehicle control rings are drained by `FUN_00532F80`. Each record with id **`0x3483DBF1`**, the vehicle **Turn** command (the same command the boat actor stores at `+0x100`; see `boat/drive_spec.md`), is handled as follows:
- car ring `0x011C0230`: `FUN_005402B0` (`0x5330A9`);
- boat/heli ring `0x011C2478`: **`FUN_00540370`** (`0x533105`).

Both take `v = record+8` and the rider returned by the SecuROM thunk `thunk_FUN_024E5180(record+0)` (INFERRED: the driver of the target vehicle). They then call `FUN_00535590(v, sweep)` with EAX = rider.

`FUN_00540370` sets `sweep = 1` and replaces `v` with `actor->vtable+0x13C()` only when both of these hold:
- the vehicle's `VehicleAnimationSet` has `VehicleClass == Jetski 0x2318B429`, **or** `VehicleName ∈ {Dinghy 0x6A77E320, 0xCDB2EC38 (name not cracked), swamp 0xC49E3E3F, Turbosquid 0x072C3307}` (`0x5403D5`–`0x5403FE`);
- its physics actor's type `vtable+0xE0() == 10`.

Cigarette `0x8F3CE8CB` is not in the list. **For the Speed Boat, `sweep = 0` and `v` is the raw Turn payload.** `FUN_005402B0` does the same for `VehicleClass == Motorcycle 0xA14A4912` with actor type 2.

`FUN_00535590`, discrete branch (`sweep = 0`). Thresholds were read from the capture:
- `[0xB984B8]` = −0.1
- `[0xBEAF2C]` = −0.8
- `[0xB92B58]` = 0.1
- `[0xB9852C]` = 0.8

| Turn value v | Transition posted (`FUN_00423D10({rider, name, 0})`) |
|---|---|
| v < −0.8 | `SteerRight90` `0x6AC757B5` |
| −0.8 ≤ v < −0.1 | `SteerRight45` `0x31884D47` |
| −0.1 ≤ v ≤ 0.1 | `SteerZero` `0x2CF5015A`, which leads to `InVehicle.Idle` from the Steer and Sweep states; `Idle` has no `SteerZero` TRNS |
| 0.1 < v ≤ 0.8 | `SteerLeft45` `0x1B83964E` |
| v > 0.8 | `SteerLeft90` `0x41560D60` |

Two boundary cases are taken from the `comiss`/`jbe` order and are PROVEN by disassembly: exactly −0.1 is not Right, and exactly 0.8 is Left45.

The transition names are the action names. The edges are `InVehicle.Idle --SteerLeft45--> InVehicle.SteerLeft45` and so on, plus edges between the Steer states themselves (`humanstate.txt`).

**Sweep branch (`sweep = 1`)**, for completeness:
- L = `[0xDF57CC] × [0xD1E430]` = 0.0174533 × 45 = 0.785 rad;
- `RuntimeAnimationParams[+4] = (clamp(v, −L, L) / L + 1) × 0.5`, written via `FUN_0064A600` at `0x535697`;
- the transition posted is `SteerSweep`;
- in `FUN_0068A8C0` (`0x68B179`–`0x68B1DB`), when the row's Action is `SteerSweep` and `params[+4] ≥ 0`, the clip time is set to `duration × params[+4]` (`clip->vtable+0x58`, then `+0x34`). `params[+4]` is then reset to −1. This is a scrubbed (driven) pose.

**Boat driver rule.** The state is Idle or one of the four Steer states. Each Turn command record re-posts the transition for its band. How often records are posted (every frame or only on change) was not read and is INFERRED. Each state plays its own looping clip from §2.4. Only the sign convention of v (whether a stick push to the left gives a positive v) is **NOT DETERMINED**: the producer of `0x3483DBF1` was not read, and `drive_spec.md` has the same gap.

### 3.3 Inputs that do not apply here

- `RuntimeAnimationParams` (container `0x017BF428`, stride 40) has **0 live records** in the capture (`dump-containers`). PROVEN. So ActionDirection, DamageDirection and the sweep parameter are unset for the hero.
- AimState and Tandem come from a flags word that was not decoded. The Tandem names are not cracked. Row 841 (Tandem `0xF623D45B`) uses the same Handle `340FE8DB` for the driver Idle.

---

## 4. Ground truth from the capture (hero `0x40004E98`)

### 4.1 Identity. PROVEN

- `dump-near` reports the hero's template as `0x80000003` "mattias".
- That template carries `HumanAnimationSet 51728909 030E6C38` = Hero / mattias and `ModelName 0BBA3066` = `pmc_hum_mattias`.
- **The hero is Mattias, not Chris**, even though the capture folder is named "chris".

### 4.2 State and selected row. PROVEN

| Read | Value |
|---|---|
| `HumanStateMachine` record → object `0x1EC3D660` | `+0` `0x40004E98`; `+4` **`0x5E2CD838` InVehicle**; `+8` **`0xB4DA003B` Idle**; `+0xC` `0x1FE45FD0` (HumanStateTable); `+0x10` stamp `0xFAAF`; `+0x14` `0x00DCBAD4` (clock, now `0x1EA19`). PROVEN for these values. Reading the difference as 20.4 s since the transition assumes 1/3000 s per tick, which is INFERRED |
| `HumanAnimationControllerNEW` → object `0x1EC40B60` (vtable `0x00BCDA90`) | `+0x30` `0x1FEDF1A0` (ActionTable object); `+0x3C` `0x1EC3D660`; `+0xA0` `0x1F3616D0`; `+0xA4` `0x22018DAC`; `+0xB8` `0x40004E98` |
| `[0x22018DAC+4]` | `0x2201E488`, an in-memory copy of **ActionTable row 226**: `5E2CD838 B4DA003B * * F8B8325F * * * 340FE8DB 1C36E1D9 1E5208DD * 8D3433B6 4FF9F863` |

### 4.3 The playing node. PROVEN

Node `0x1F3616D0`, vtable `0x00BD3330`. This is the class `FUN_00743F20` constructs; its field offsets match that constructor.

| Off | Value | Meaning |
|---|---|---|
| +0x24 | `0x1EC40B80` | constructor arg (inside the controller) |
| **+0x28** | **`0x1EC7D3A0`** | asset reference, vtable `0x00BCD310`: **`+4 = 0x3D50E160`**, `+8 = 0x18166555 = m2("Animation")` |
| +0x30 | 0.62971 | set to 0 by the constructor and advancing. Lies in [0, 2.002). Seconds or phase: NOT DETERMINED |
| +0x34, +0x38 | 1.0, 1.0 | `DAT_00B9B664` defaults, unchanged |
| +0x44 | `0x40004E98` | rider |
| **+0x48** | **`0x340FE8DB`** | Handle |

There is one clip node at `+0xA0`, and it is the only reference to the clip asset `0x1EC7D3A0` reachable from the controller. `dump-find 0x1EC7D3A0` gives five hits:
- this node's `+0x28` at `0x1F3616F8`;
- `0x00DC4044`, a global table;
- `0x1EB27844`, `0x1EB72A04` and `0x2090ACD0`, which are asset lists outside the controller.

The other children were not decoded:

| Child | What was read |
|---|---|
| `+0x84` | vtable `0xBD2DA0` |
| `+0x90` | vtable `0xBD2E00` |
| `+0xA8` | vtable `0xBD33A8`; its `+0x3C` points back to the node |
| `+0x8C` | slot array `0x1EC8E628`. Its entries carry `0x00740028` and `0x00740010` (`0x74` = 116 = the Mattias HIER bone count) and point at `0x1EBF2940` and `0x1EBF4920` |

The two slot targets read as follows:
- `0x1EBF2940`: 16 f32 of 1.0 read;
- `0x1EBF4920`: `{1, 0x01969858, 0x019745A8}`, then 1.0 repeated.

These look like per-bone weight arrays at full weight. That is INFERRED; the partition logic (PartitionMask `0x1C36E1D9`) was not decoded.

A second asset reference of the same class sits at `0x1EC7D400`. It holds clip `0xC88866FB`, which is the Cigarette boarding-seat EnterVehicle clip. It is referenced only from `0x00DC56B0`, `0x1EB729F0`, `0x2090AC80` and `0x21E25A84`, and not from the hero's controller or node. INFERRED: it is another clip loaded from the same animgroup. `0x3D50E160` is found in only 7 places in the capture (`dump-find`). Apart from this node's reference and the table copies, it sits in the animation index entry `0x209C9130` = `{3D50E160, …, block 0x0D14}`. `0x0D14` = 3348.

### 4.4 Links. PROVEN

- RiderLink (container `0x00DF8408`) slot 404:
  - child keys `0x1FD6D650` / `0x1FD6F650` = hero;
  - owner `0x1FD6E650` = seat **`0x400052AB`** (template `0x8000A01D`, the driver seat);
  - record `{0, 0, 0x400052A4}`.
- `0x400052A4` is an entrance (template `0x8000A981`). Its RuntimeEntranceLink record is `{0x688C4858, 0x004FA930}`, so its name `0x004FA930` matches the driver seat's `EntranceToSeat 004FA930 1 5`. The key's Target column is therefore `0x004FA930`.
- The boat's SeatLink records are `{hardpoint, seat name}`. The driver seat's is `{0xD6EBE292, 0xF8B8325F}`, and `0xF8B8325F` = m2("seat_driver").

### 4.5 Reproduction

The table decode gives the same result: InVehicle / Idle / seat_driver leads to AT row 226, Handle `340FE8DB`, then VAL row 1504 (Boat, Cigarette), clip `3D50E160`. `mercs2_probe find-ref 0x3D50E160` lists exactly two blocks: 3185 (the resident tables) and **3348 `vehiclenameanimgroup_cigarette_P000_Q3`**. `trackmap --model 0x0BBA3066 --clip 0x3D50E160` reports a wavelet clip, duration **2.0020 s**, 61 poses, and 60 of 60 tracks resolving to the `pmc_hum_mattias` HIER. Grade: PROVEN.

**Result: Mattias driving the Speed Boat plays clip `0x3D50E160` from animgroup `vehiclenameanimgroup_cigarette` (block 3348). It is one looping clip (play mode 3), not driven, and has no weight blending.**

---

## 5. Leaving the seat

- Exit is ring case 4: `FUN_0053F110` calls `FUN_0053A9F0`, which calls `FUN_0053BD90` (caller at `0x53ABD4`). That posts **`ExitVehicle` `0x57B25A1F`** (`0x53BDF8`). PROVEN that the constant is posted there; the conditions were not read.
- State graph: `InVehicle.ExitVehicle` (and `ExitVehicleOpenDoor`) on `ExitVehicleComplete` `0xF6834DA2` leads to **`Upright.Idle`**. `ExitVehicleDitch` leads to `Upright.Jump`, `ExitVehicleRagdoll` to `Upright.Knockdown`, and `Die` while seated to `InVehicle.DeathEject` (`humanstate.txt`). PROVEN.
- `ExitVehicleComplete` is posted by `FUN_0053B0D0` (`0x53B3DF`), at `0x53B05D` (no function), and by `FUN_0053C2D2` (`0x53C4BB`). PROVEN for the constant sites; the triggers were not read.
- **The exit animation exists:** driver ExitVehicle leads to Handle `8E04C9B9`, then clip **`8C52015D`** (VAL row 1511). PROVEN from data.
- On return to `Upright.Idle`, ActionTable row 2 has `AnimationHandles = 0x4FF9F863` ("NONE"). `FUN_0068A8C0` at `0x68AC66` then uses the locomotion controller. That restores the Upright locomotion set (human_animation_selection §4). PROVEN for the branch. Whether the exit Target is the exit entrance in RiderLink `+8` is INFERRED.

---

## 6. Passenger and gunner seats (data only)

**Passenger `seat_front_left` `0xF7BE15DE`** (template `0x8000A01E`, SeatParameters `0x120`, with `SeatToSeat F8B8325F 5` to the driver):

| State | AT row | Handle | VAL row | Clip | Notes |
|---|---|---|---|---|---|
| Idle | 317 | `68BFF914` | 1514 | `2241D859` | rows 328 (`41266777`) and 337 (`3EB8A8D1`) carry the same key; the first wins under the scorer. INFERRED |
| Enter | | `D70B9DA3` | | `058F5D24` | |
| Exit | | `9A5F7E72` | | `7BDE82CF` | |
| Die | | `B1FB3796` | | `1FDD0BB1` | |
| SeatToSeatTransfer, Target `seat_driver` | 329 | `7208F1CE` | | `1B93A8AD` | |

A passenger never receives Steer transitions: those are posted only to the Turn-record rider. INFERRED.

**Boarding seats `0x6E9501D2` and `0x3734298B`** (cargo, `0x1004`):
- EnterVehicle: `ED93F455` → `C88866FB` and `89A751F2` → `D078D168`;
- Dive: `7BF78376` → `52E0EC98` (VAL row 1, all `*`);
- they have **no Idle row of their own**. What retail plays there depends on the candidate rule and is NOT DETERMINED.

**Gunner.** The Speed Boat has no gunner seat. In the ActionTable, the InVehicle Idle rows for 12 other seat names map to the special handles `0xE22B6FE7`, `0x847AD822` and `0x1BEB81AA`:

| Handle | Seats |
|---|---|
| `0xE22B6FE7` | `B7B967D0`, `35F5F13C`, `543EBC7C`, `846C49BB`, `1B217B8A`, `385591E0` |
| `0x847AD822` | `3A7F35D1`, `A6461966`, `4619F5A8`, `CC2CA902`, `4C13DA9C` |
| `0x1BEB81AA` | `12531EB9` |

The switch at `0x68ACF2` builds multi-clip nodes for these handles (`FUN_00741950`, `FUN_00741250`) instead of the single-clip node. So a gunner's pose is a composite node, presumably aim-driven. That this is gunner or aim behaviour is INFERRED; the internals of `FUN_00741950` and `FUN_00741250` were not read, and the seat names are not cracked.

---

## 7. How to compute the clip from `vz.wad` with the existing Rust readers

1. **Tables.** `AnimSelector::from_resident_block(block 3185)` already attaches the ActionTable and, through `with_vehicle_lookup`, the VehicleAnimationLookup. It errors if the VAL has an ASTO pool; retail's has none.
2. **Seat facts from templates.** The vehicle's `SeatLink` records are `{seat template, hardpoint, seat name}`. The seat name is the **Seat** key. The vehicle's `VehicleAnimationSet` `{VehicleClass, VehicleName}` gives VAL cols 1 and 2. `we-template` prints both.
3. **State.** When the rider is seated, set Stance `InVehicle 0x5E2CD838` and Action `Idle 0xB4DA003B`. When the enter path is not immediate, start from `EnterVehicle` and go to `Idle` on `Complete`.
4. **ActionTable row.** Key = `[Stance, Action, *, *, seatName, target, *, *]`, where target is the entrance name or `*`. Score it with the same 2/1/0 rule `AnimSelector::query` already uses for AnimationLookup. Retail calls `FUN_0067CF20` with 8 key columns. Take `AnimationHandles` (col 8) and `Looping` (col 10). `handle_actions(handle)` lists the reverse join for checking.
5. **Special handles.** If the handle is `0x4FF9F863`, use locomotion. If it is one of `0x7EB27FFB`, `0x1BEB81AA`, `0x847AD822`, `0xE22B6FE7` or `0xD6FE195E`, it is a special multi-clip node (not specified here). Otherwise it is a single clip.
6. **VAL query.** Candidates are the rows with `Handle == handle` (`vehicle_context(handle)` gives them in table order). Score cols 0–5 (2 for key, 1 for default). Take the first strictly highest. Reject the row unless `vehicle_class ∈ {key, *}` and `vehicle_name ∈ {key, *}`; on rejection, or when no row matches, play `0x9D886544`. The clip is `VehicleClip::clip`, with no list draw. Leave `MountedEquipment*` as `*`.
7. **Clip source.** Load the clip from the vehicle's animgroup. For the Speed Boat that is `vehiclenameanimgroup_cigarette` (block 3348). The human animgroup does not hold it. That the group name comes from `VehicleName` is INFERRED, from one example.
8. **Playback.** Loop when `Looping == TRUE`. On a non-looping clip's end, fire the state's `Complete` transition.
9. **Steering.** For each Turn command value v on a boat, post SteerRight90 / SteerRight45 / SteerZero / SteerLeft45 / SteerLeft90 using the ±0.1 / ±0.8 bands. Only the listed names (Jetski class; Dinghy, `0xCDB2EC38`, swamp, Turbosquid) and motorcycles use the scrubbed `SteerSweep`.

Speed Boat driver result: `(InVehicle, Idle, seat_driver)` → `340FE8DB` → `(Boat, Cigarette)` → **`0x3D50E160`**.

---

## 7a. Settled after the first read

- **The candidate rule of `FUN_0067CF20`** (§8 gap 5). `FUN_0067CBC0(table, out, max, key)` gathers the
  candidates. PROVEN (decomp; disassembly `0x67CBC0`–`0x67CC8D`):
  - table `+0x18` is a bit mask of indexed columns; for each one it takes the posting list of the key's cell
    (`[key+4][col]`, `0x67CC52`) and, when the byte at table `+0x58` is not 0, the posting list of the defaults
    row's cell (`[table+0x30][col]`, `0x67CC26`), and merges the lists across the indexed columns: a candidate's
    cell in every indexed column is the key's or the default;
  - table `+0x54`, when not negative, is a column whose cell must be the defaults row's or the key's.
  - The loader `FUN_0067C780` sets `+0x18 = 3` for every table, then `+0x18 = 1`, `+0x54 = 3`, `+0x58 = 0` for the
    AnimationLookup `0xE00B080C`, and `+0x18 = 2`, `+0x54 = 1`, `+0x58 = 0` for the two names at `0x00B986D0`.
  - Capture: the ActionTable `0x1FEDF1A0` and the VehicleAnimationLookup `0x1FEDF7D0` both read `+0x18 = 3`,
    `+0x54 = −1`, `+0x58 = 1`. So ActionTable candidates have `Stance` and `Action` each the key's or `*`, and
    VehicleAnimationLookup candidates have `Handle` and `VehicleClass` each the key's or `*`.
- **The placeholder `0x9D886544` is in no animgroup**: `mercs2_probe find-ref 0x9D886544` lists the resident
  tables' block 3185 alone. PROVEN. What a node shows with it is not read.
- **Every driver's seat** (`bIsDriverSeat`, 896 over all vehicle templates), resolved with the rule above: 539
  have the idle and the four steering clips, 227 the idle alone (their steering states resolve to the
  placeholder), 111 resolve the idle to the placeholder, 12 have a composite idle (`0xE22B6FE7` ten times,
  `0x847AD822` twice), and 7 are on a vehicle without a `VehicleAnimationSet`. PROVEN (the wad repo's
  `mercs2_engine` test `rider_animation_retail`).
- **The Turn value's sign** (§8 gap 2), in part. The seat nodes are named by side: `hp_seat_fl` `0xD721FC8C` at
  +X, `hp_seat_fr` `0xD6EBE292` at −X; the Speed Boat's driver sits at `hp_seat_fr`, the cars' at `hp_seat_fl`.
  A positive Turn yaws the boat toward +X ([`drive_spec`](../boat/drive_spec.md) §G), its left, and posts
  `SteerLeft`. The producer's sign (which way the stick gives a positive value) is still unread.

## 8. NOT DETERMINED

| # | Gap | What was tried or what is missing |
|---|---|---|
| 1 | Whether New Game's `Vehicle.Enter(…, false)` plays the enter clip `61B0138E` or collapses to the immediate path | `FUN_00534790(rider)` and `FUN_005347F0(seat, entrance)` were not read; the capture is after the enter |
| 2 | Sign convention of the Turn value v (does a left stick push give positive v) | The producer of `0x3483DBF1` was not read; same gap as `drive_spec.md` |
| 3 | Meaning of node `+0x30` (0.62971) | Seconds or phase; it does not equal (time since the transition) mod 2.002 |
| 4 | Meaning of node `+0x1C` (3.5885) | Not read |
| 5 | The ActionTable and VAL candidate rule inside `FUN_0067CF20` | `+0x54 = −1` in both tables. The driver results do not depend on it (§2.4); passenger duplicates and boarding seats do |
| 6 | Crossfade time between seated states | INFERRED to be wildcard row 0 (0.125 s); the transition query was not read |
| 7 | How the vehicle animgroup block is made resident or chosen | Only the index entry `{3D50E160 → block 0x0D14}` at `0x209C9130` was seen |
| 8 | Internals of the special multi-clip nodes | `FUN_00741950`, `FUN_00741250`, `FUN_00742D10`, `FUN_007437B0`; gunner behaviour |
| 9 | Names | Tandem values `0x2877CDDE` / `0xF623D45B`, transition type `0xFB729A36`, VehicleName `0xCDB2EC38`, and most seat names other than `seat_driver` and `seat_front_left` |
| 10 | Exit triggers | What posts `ExitVehicle` and `ExitVehicleComplete` beyond the constant sites listed in §5 |
| 11 | `thunk_FUN_024E5180` | Ring record target to rider; SecuROM thunk, not followed |
| 12 | What `Driven = TRUE` does | `FUN_0068A4B0` was not read; root motion is SPECULATIVE |
| 13 | Partition and layer structure of the controller | `+0x84`, `+0x90`, `+0xA8` and the `+0x8C` slots (per-bone weights all 1.0 in the capture) were not decoded |
