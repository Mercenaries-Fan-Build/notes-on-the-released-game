# Vehicles — PC code map

**Scope:** the drivable-vehicle system in retail PC `Mercenaries2.exe` — the control-verb →
command-ring → drain/dispatch path, the nine physics-actor classes, and the custom drive
model (car/boat/heli/tank). Scoreboard row 25. Binds the Xbox-PDB symbol names
([`vehicles.md`](../mercs2-pdb-analysis/vehicles.md), [`data-defaults.md`](../mercs2-pdb-analysis/data-defaults.md)
§1.2, [`havok-physics.md`](../mercs2-pdb-analysis/havok-physics.md)) to concrete PC addresses.
Companion JSON [`vehicle_code_map.json`](../data/vehicle_code_map.json). Road-following / AI
driving / traffic-graph runtime is mapped separately in
[`road_graph_ai_driving_code_map.md`](road_graph_ai_driving_code_map.md).

**Binary:** unpacked SecuROM image `output/_ghidra/securom_dump/mercs2_unpacked.exe`, base
`0x400000`. Bodies read from `output/_ghidra/mercs2_unpacked.exe_decomp.txt` plus the
noreturn-fixed re-decompiles `output/_ghidra/vehicle_phys_decomp.txt` /
`vehicle_phys_decomp2.txt`.

## 0. Boundary & two structural findings

Two things make this map possible that blocked every prior attempt:

1. **The drive model is NOT the Havok Vehicle Kit.** The Xbox doc flagged the drive math as
   UNKNOWN ("lives in the unnamed `hkpVehicleInstance` step", VMX128-truncated). On PC there
   are **zero** `hkpVehicle*` classes or strings — the shipped game runs Pandemic's own
   **custom raycast car / raycast tank / buoyant boat / servo heli** simulation, implemented
   as nine `hkpUnaryAction`-derived actor classes (§3). The `hkpVehicleData` member table in
   `data-defaults.md` §1.2 is **dead SDK payload** compiled into the Xbox devkit binary and
   never instantiated on either platform.

2. **A Ghidra defect had been hiding it.** `FUN_00401740` (x87 `sqrt` helper) and
   `FUN_00401750` (`abs`) were flagged **noreturn** in the project, so every prior global
   export truncated every vehicle-physics function **at its first sqrt** — within ~20
   instructions in vector-math-heavy code. Fixed by
   `scripts/ghidra_scripts/DecompileVehiclePhysics.java` (clears the flag + re-decompiles the
   cluster; verified: `FUN_0044db60` car applyAction now decompiles through its trailing
   sqrt). **⚠ Action item:** re-export `all_functions_decomp.txt` and
   `mercs2_unpacked.exe_decomp.txt` — every float-heavy function in them is potentially
   truncated the same way.

Confidence: control-path setup + physics-actor identity + car/boat/heli/tank per-frame flow =
high/med (bodies read). Vtable callers of the per-class HandleCommand + several
producer/enqueue endpoints sit behind vtables or SecuROM thunk islands → **confirm-live**.

---

## 1. Control path — verb → command ring → drain

### 1.1 Binding table (Xbox → PC)

| Xbox symbol / VA | PC fn / VA | Bridge | Conf |
|---|---|---|---|
| `FUN_8239cd98` car enqueue (4-word rec, `0x1ff<` cap, lock `+0x893`, count slot 0) | **`FUN_00538c90`** | same shape: lock-byte drop (`DAT_011C2458`), `count<0x200`, 0x10-byte copy, count bump; PC adds `EnterCriticalSection(&DAT_011C2460)` + per-record subscriber byte | high |
| `FUN_8239ce50` boat/heli enqueue (`99<` cap) | **`FUN_00538d20`** | `count<100`, recs `DAT_011C24A0`, lock `DAT_011C2B44` | high |
| `FUN_823a4878` turret enqueue (6-word, cap 0x400) | ring @`0x0122ECC0` (recs `DAT_0122ECE8`, 0x18 stride, fetch `FUN_00406780`); enqueue = `thunk_FUN_024ba1a0` | span `0x01234CE8−0x0122ECE8 = 0x400×0x18` | med |
| Car controller singleton `830ff930` | car **ring obj @`0x011C0230`** (count +0, recs +0x28, subscriber bytes +0x2028, lock +0x2228 = `DAT_011C2458`, CS `DAT_011C2460`) | 4-word records/cap identical; PC moves the ring out of the controller into a standalone broadcast object (§1.2) | high (identity) |
| Heli `830feb30` / Boat `83101b88` singletons | **shared ring obj @`0x011C2478`** (recs +0x28, masks +0x668, lock +0x6CC = `DAT_011C2B44`, cap 100) | one cap-100 ring serves both; dispatch splits by target handle + per-class HandleCommand | med-high |
| Turret `83103158` singleton | turret ring @`0x0122ECC0`; bit-allocator `FUN_004068d0` (8 chan max) | fetch `FUN_00406780` | high |
| `CarTurn`/`CarBrake`/`HeliElevate`/`TurretAim`… verbs | thin-wrapper cluster `FUN_0056b590/5c0/630/670/6a0`, `FUN_00547d20/d50`, `FUN_005440d0`, `FUN_00538ac0` (clear-all), `FUN_0056b700/730/760/790/7d0`, `FUN_0056b8a0` (pre-scaled) | each 44–101 B: build record in regs (ESI conv — Ghidra elides immediates) → call enqueue | med |
| Xbox dispatch loop reads `0x3483dbf1` back | per-class HandleCommand vtable methods `FUN_00437300` (car/tank), `FUN_00435790` (heli), `FUN_00441900` (boat) | full command-ID switch over `record+4`, float payload `record+8` (§1.4) | high |

### 1.2 PC transport — 6 broadcast rings + subscriber bitmasks

The PC rings are **standalone multi-consumer broadcast queues**, not fields inside per-class
controller singletons (the Xbox layout is a compacted single-consumer variant). This is why
the naive `0x1ff<` / `+0x893` greps miss — the cap is `count < 0x200` and the lock is a named
global plus a win32 CS:

```c
// enqueue FUN_00538c90 (car ring @0x011C0230); record ptr in ESI (custom conv)
if (DAT_011c2458 == '\0') {                       // lock byte (Xbox +0x893 analog)
  EnterCriticalSection(&DAT_011c2460);            // PC-only: thread-safe
  if (DAT_011c0230 < 0x200) {                     // cap 0x200 (Xbox: 0x1ff < count)
    *(rec*)(&DAT_011c0258 + count*0x10) = *rec;   // 4-word record
    (&DAT_011c2258)[count] = DAT_011c0234;        // per-record SUBSCRIBER MASK byte
    DAT_011c0230++;
    for (bit in DAT_011c0234) DAT_011c0238[bit]++; // per-channel pending counts
  }
  LeaveCriticalSection(&DAT_011c2460);
}
```

Consumers register a bit once (`FUN_004068d0`: scan mask, `mask |= 1<<n`, return `~n`), then
each frame call the ring's fetch fn with their channel id — it copies out records still
carrying the caller's bit, clears the bit, compacts records nobody wants. **Every subscriber
sees every command once** (replay/HUD/network can watch the same stream the drive model reads).

| # | ring (count / recs / lock) | rec | cap | fetch | enqueue | role |
|---|---|---|---|---|---|---|
| 1 | `DAT_011CA560` / `DAT_011CA5B0` / `DAT_011CB480` | 0x24 | 160 | `FUN_00406540` | SecuROM | **seat / enter-exit / driver-assignment**; applier `FUN_0053f110`, `rec+0xc` ∈ {0,4,8,0xc,0x10} → mount/dismount `FUN_00540690`/`FUN_00538fe0`/`FUN_0053a9f0`/`FUN_00540990` |
| 2 | `DAT_012476A8` / `DAT_012476F0` / `DAT_0124AEF0` | 0xc | 0x400 | `FUN_004ceba0` | SecuROM | **vehicle state / hijack**; ids `0xB6741F78` (state-advance) / `0xD6F04A29`; applier `FUN_0053f400` |
| 3 | SecuROM: fetch `FUN_004b2230 → (*_DAT_0244F7B8)()` | ? | ? | `FUN_004b2230` | ? | drained into `FUN_0053f6a0` (per-entity ECS fan-out over `PTR_PTR_00DF8188`/`00DF8408`) — the bridge from ring records to per-vehicle objects |
| 4 | **car ring @`0x011C0230`** | 0x10 | **0x200** | `FUN_0040ea90 → (*_DAT_02455C94)()` | **`FUN_00538c90`** | **CAR/TANK control** ↔ Xbox `830ff930` |
| 5 | **boat/heli ring @`0x011C2478`** | 0x10 | **100** | `FUN_0040ec20` | **`FUN_00538d20`** | **BOAT + HELI control** ↔ Xbox `830feb30`/`83101b88` |
| 6 | **turret ring @`0x0122ECC0`** | 0x18 | **0x400** | `FUN_00406780` | `thunk_FUN_024ba1a0` | **TURRET control** ↔ Xbox `83103158` (6-word = aim vector) |

Record layout (rings 4/5): `+0` target vehicle handle, `+4` command-ID, `+8` float payload,
`+0xC` aux/flags. Consumers key on `+4`, filter on `+0`.

### 1.3 Producers

**Native verbs** — thin wrappers; command-ID immediates are register-built (why the PC literal
grep only hits consumer switches): `FUN_0056b590/630/670/6a0`, `FUN_00547d20/d50`,
`FUN_005440d0` = single car-ring verb each; `FUN_0056b5c0` = name-lookup (`FUN_00665af0`) +
two `FUN_00538c90` (paired verb); **`FUN_0056b8a0`** = the HeliElevate analog (pre-scales input
with tunables `_DAT_017D40B8`/`_DAT_00DFCB90` before `thunk_FUN_024ba1a0` — matches the Xbox
"HeliElevate pre-integrates" note); **`FUN_00538ac0`** = "clear all controls" (one
`ClearControls 0x6C5F1491` per ring); `FUN_0056b390` = guarded broadcast (fires only if target
== `thunk_FUN_024e5180()` local vehicle, else posts an event via `FUN_004239f0`).

**AI driving states** are the main native producers (cluster `0x544xxx–0x561xxx`) — detailed in
[`road_graph_ai_driving_code_map.md`](road_graph_ai_driving_code_map.md).

**Lua** — `Vehicle.*` binding table @`0xB98918` (40 entries). No raw driving verbs are exposed;
script control is limited to: `StartTankHijackMotion` `FUN_005e8dd0` (Turn `0x3483DBF1`),
`StopTankHijackMotion` `FUN_005e8ea0`, `SpinHeli` `FUN_005e8f70` (id `0x30FBBF64`, gated on
`vt+0xE0()==4`), `ClearControls` `FUN_005e9c40`, `SetTurretPitch/Yaw` `FUN_005e8970`/`FUN_005e8ac0`.

### 1.4 Consumers — drain + per-class dispatch

**Tick placement** ([`scheduler_tick_code_map.md`](scheduler_tick_code_map.md)): the control
pump runs in the **game layer (idx 4) of the 5-layer master tick**: `FUN_00630ef0` RunFrame →
layer walk `FUN_004c14f0`/`FUN_004c15e0` → game-layer Update `FUN_004c09c0` → `FUN_004c0ec0` →
`FUN_004c9740` (gameplay-systems batch) → **`FUN_00532f80`** (call site `0x004c990c`, fixed
order between `FUN_0062e7b0` and `FUN_0050fcc0`).

**`FUN_00532f80` — the vehicle-control command pump** drains all 6 rings (loop-until-empty):
ring1→`FUN_0053f110`; ring2→`FUN_0053f400`; ring3→`FUN_0053f6a0` (per-entity fan-out); car ring
id `0x3483DBF1`→`FUN_005402b0` (player steering feedback via `thunk_FUN_024e5180()` local
vehicle → `FUN_00535590`); boat/heli ring→`FUN_00540370` (autopilot read-back `vt+0x13C()` for
class-ids `{0x2318B429,0x6A77E320,0xCDB2EC38,0xC49E3E3F,0x072C3307}` in mode `vt+0xE0()==10`);
turret ring→`thunk_FUN_024e9260`.

**Per-class HandleCommand dispatchers** (vtable methods; `param_2`=record, id@+4, float@+8):
- **`FUN_00437300` — car/tank** (`this[0x56]` = drive obj): `0x3483DBF1`→+0x28 =
  `clamp(1.0−payload)` Turn; `0x0490757F`→+0x2C/+0x30 by reverse flag; `0x460C5913`→combined
  accel/brake (1−v swap); `0x55B8E0A1`→+0x30 Brake; `0x574220AC`→+0x38 Handbrake;
  `0x37086E0A`→+0x34 (5th, open); `0x7D3B632C`→accel; `0x6C5F1491`→zero +0x28..+0x38
  ClearControls; `0x262E1E47`→world-pos ping `FUN_008d5ba0/b70`. Sibling `FUN_00437740` emits
  `0x9EAEC21D` (skid/burnout) when wheel side-force > `DAT_00B9B700`.
- **`FUN_00435790` — heli** (drive obj `this+0x140`, 4 axes): `0x7D3B632C`→+0xF8,
  `0x0490757F`→+0xFC, `0x3483DBF1`→+0x100, `0x37086E0A`→+0x104, `0x6C5F1491` zeroes all.
- **`FUN_00441900` — boat** (drive obj `this+0x140`, 2 axes): `0x7D3B632C`→+0x28,
  `0x3483DBF1`→+0x2C as `1.0−v` (BoatTurn reuses CarTurn id — confirmed), `0x6C5F1491` zeroes.

### 1.5 Command-ID table (PC-verified)

| ID | meaning |
|---|---|
| `0x3483DBF1` | Turn/steer (car +0x28, heli +0x100, boat +0x2C) |
| `0x55B8E0A1` | Brake (car +0x30) |
| `0x0490757F` | Accel channel A (car fwd; heli +0xFC) |
| `0x7D3B632C` | Accelerate (boat +0x28, heli +0xF8) |
| `0x460C5913` | Combined accel/brake axis (car) |
| `0x574220AC` | Handbrake (car +0x38) |
| `0x37086E0A` | 5th car channel +0x34 / heli 4th +0x104 |
| `0x6C5F1491` | ClearControls (all classes) |
| `0x262E1E47` | Position/focus ping |
| `0x30FBBF64` | SpinHeli (Lua) |
| `0x9EAEC21D` | Skid/burnout notification |
| `0xB6741F78`, `0xD6F04A29` | Ring-2 state/hijack |
| `0x2318B429`, `0x6A77E320`, `0xCDB2EC38`, `0xC49E3E3F`, `0x072C3307` | Vehicle **class ids** w/ autopilot steering read-back |

**ID hash function is UNKNOWN.** Constants are bit-identical Xbox↔PC (compile-time hashes of
some name set) but tested **negative** vs `pandemic_hash`/`pandemic_hash_m2` (733k rainbow
table), CRC32, FNV-1/1a, and a `0x9E3779B9`-chain over verb-name candidates; not in the PC
name-hash registry CSVs. Likely a distinct control-channel / tool-side enum hash.

---

## 2. Physics-actor class registration (reflection stream classes)

One 159-byte **reflection stream-class descriptor** registrar per class (all call
`FUN_0064a770`), writing `{0xffff, CopyFromStream-vtbl, stream_size, 0x9e3779b9 seed,
name-ptr}` into `_DAT_017bcxxx`. `stream_size` = the serialized tuning-block size.

| Class (string) | registrar | string VA | descriptor base | stream size |
|---|---|---|---|---|
| PhysicsPropertyUncrushable | `FUN_0063e470` | `0x00bc4b20` | `0x017bc098` | 0x4 |
| PhysicsPropertyGravityScaler | `FUN_0063e520` | `0x00bc4b3c` | `0x017bc0e8` | 0x4 |
| `_PropPhysics` | `FUN_0063e5d0` | `0x00bc4b5c` | `0x017bc138` | 0x10 |
| `_DebrisPhysics` | `FUN_0063e680` | `0x00bc4b6c` | `0x017bc188` | 0xc |
| `_BoatPhysics` | `FUN_0063e730` | `0x00bc4b7c` | `0x017bc1d8` | **0x114** |
| `_HumanPhysics` | `FUN_0063e7f0` | `0x00bc4b8c` | `0x017bc228` | 0x84 |
| `_CarPhysicsV2` | `FUN_0063e8b0` | `0x00bc4b9c` | `0x017bc278` | **0x18c** |
| `_TankPhysics` | `FUN_0063e980` | `0x00bc4bb8` | `0x017bc2c8` | 0x78 |
| `_HelicopterPhysics` | `FUN_0063ea40` | `0x00bc4bc8` | `0x017bc318` | 0x58 |
| `_HelicopterPhysicsAi` | `FUN_0063eb00` | `0x00bc4bdc` | `0x017bc368` | 0x54 |
| `_JetPhysics` | `FUN_0063ebc0` | `0x00bc4bf4` | `0x017bc3b8` | 0x4 |
| `_BuildingPhysics` | `FUN_0063ec70` | `0x00bc4c00` | `0x017bc408` | 0x8 |

`_CarWheel` has **no PC registrar/string** — on PC wheels are not stream objects; they are
pool-allocated **0x130-byte** runtime objects (pool `DAT_017d50b0`). The Xbox presize
`_CarWheel 2304` is a pool byte-total/padding, **not** the PC struct size.

**Two stream loaders per class** (the CopyFromStream vtable entries):
- Raw-block (read N bytes → commit): `FUN_00638f80` Car (0x18c), `FUN_00638e80` Boat (0x114),
  `FUN_00638f00` Human (0x84), `FUN_00638da0` Prop, `FUN_00638e10` Debris.
- **Field-by-field with defaults** (`FUN_00656320(default)`=float, `FUN_00656610`=vec3,
  `FUN_00656210`=int/bool, `FUN_00656720(enum,member)`=enum): **`FUN_00658f60` Car** (99 dwords,
  refs `s_CarMaxSlope`/`s_MaxSlopeEnum`), **`FUN_006584a0` Boat** (69 dwords), `FUN_00658ba0`
  Human, **`FUN_00659a80` Tank** (30 dwords), `FUN_00659df0` Jet (1 float), **`FUN_00659e80`
  Heli** (21 floats+bool), `FUN_0065a120` HeliAi (20 floats+bool), `FUN_0065a3a0` Building,
  `FUN_006583d0` Debris. Commit `FUN_0064a600` inserts into class pool.

> **Tuning field NAMES are stripped on PC** — no `EngineTorque`/`GearRatio*`/`SpringStrength`/
> `WaterDrag*`/`MaxElevationSpeed` strings anywhere. Field identity comes from (a) stream ORDER
> (the Xbox registrars define the same order and keep names), (b) default-value fingerprints in
> the loaders, (c) consumer semantics. Extracting the authored defaults + name-aligning against
> the Xbox registrars is the open work item (§5).

---

## 3. The nine hkpUnaryAction-derived actor classes

All nine scalar-deleting dtors call `FUN_008e83e0` = **hkpUnaryAction dtor** (`symbol_map.json`
maps hkpUnaryAction → `FUN_008e83e0`, confirmed). Base ctor `FUN_008e83a0(body, userData)`.
Vtable (MSVC, slot 0=dtor): slot1/2 = hkReferencedObject addRef/release (`0x88c5b0`/`0x88c600`),
**slot 3 = applyAction(stepInfo)** (stepInfo+8 = dt), slot 4 = `0x8e8410`. Slots ≥8 are game
virtuals. `hkpEntityListener::vftable` survives verbatim in the car ctor.

| # | vtable | dtor | applyAction | identity | size | owner slot |
|---|---|---|---|---|---|---|
| A | `0xba9340` | `FUN_00435300` | **`FUN_00447260`** | **BoatPhysics** — ctor `FUN_004465e0` copies the 0x114 boat block; 4 wake-emitter subrecords @+0x168; in/out-water timer @+0x23c | 0x244 | entity+0x140 (act `FUN_00435660`) |
| B | `0xba9858` | `FUN_004391f0` | **`FUN_00453760`** | **HelicopterPhysics / …Ai** — setup `FUN_00439850` copies 22-dword (0x58) or 21-dword (0x54) AI variant. One class serves both streams | 0xe8 | entity[0x50] (act `FUN_00439540`) |
| C | `0xbaa360` | `FUN_004493a0` | **`FUN_0044db60`** | **CarPhysicsV2** — ctor `FUN_00449460` consumes the 0x18c block; wheel ptr array @+0x54, count @+0x208; `numWheels==2`→bike (`FUN_00437260`); `hp_wheel_*` strings @`0xbaa42c` | 0x284 | entity+0x158 (act `FUN_00437080`) |
| D | `0xbaa388` | `FUN_00450240` | `FUN_00450280` | **world-boundary keep-in plane** (6 face flags; projects body back + reflects vel ×0.5); factory `FUN_00432280` | 0x70 | world-edge |
| E | `0xbaa3b0` | `FUN_00450860` | (nullsub; work in slot 9 `FUN_004508a0`) | **CCD anti-tunneling sweep** — sphere swept from last pos, raycast filter `0x22376f6e`, reflect+reposition | 0x44 | ctor `FUN_004507e0` |
| F | `0xbaa400` | `FUN_00453ca0` | `FUN_00453ce0` | **gravity-scaler** (= TtPgGravityScalerAction) — scalar @[10], timer @+0x28 counts down by dt | 0x2c | factory `FUN_00433530` |
| G | `0xbaa470` | `FUN_00454a70` | **`FUN_00454d80`** | **TankPhysics** — 6 contact slots (0x80B @+0xd8, round-robin @+0x360 = tracks fl/fr/ml/mr/rl/rr), track raycast `FUN_00456250`, per-side query `FUN_00455210` | ≥0x3d4 | — |
| H | `0xbaa4c4` | `FUN_004573d0` | `FUN_004574f0` | **yaw/heading-servo** — atan2 heading, target @+0x2c, clamped turn accel, applyAngularImpulse. Used by `FUN_00512e90` (human/turret facing?) | — | — |
| I | `0xbaa4ec` | `FUN_004577c0` | **`FUN_00458ac0`** | **buoyancy/floating** ("vehicleSinking") — 8 AABB-corner sample points @+0x54 + volume weights; waterline query `FUN_00480440` ([`water_code_map.md`](water_code_map.md) §5) every frame, buoyant impulses every other frame, "sunk" latch @+0x2c9 | ≥0x2cc | — |

Notes: JetPhysics (0x4) and PropPhysics (0x10) have **no dedicated action** — jets fly
kinematically via the AI/flight controller; props use the generic D/E/I actions. HumanPhysics
(0x84) is the character controller (H is its facing servo).

**Activate/Deactivate** (streaming-hibernation tie-in) = owner-side lazy create/destroy:
Activate `FUN_00437080` (car, alloc 0x284 + `FUN_00449460` + `FUN_008dae30` hkpWorld::addAction),
`FUN_00435660` (boat 0x244), `FUN_00439540` (heli 0xe8) — all gate on `FUN_004332f0(owner)`
(world/hibernation), alloc from TLS heap `FUN_0088cb70(size,0x29)`, link into the body action
list (body+0xc). Deactivate zeroes entity+0x140/+0x158 and releases. (No `::Activate` strings
on PC.)

---

## 4. What the car drive model computes (CarPhysicsV2)

**Runtime layout (partial):** +0x18 = `hkpUnaryAction.m_entity` (chassis rigid body: +0xe0..0x11c
world transform, +0x130 COM, +0x1a0 linvel, +0x1b0 angvel, +0xf4 up.y, +0x84 gravityFactor, +0xd0
motion vtbl — +0x40 setLinVel / +0x44 applyAngularImpulse / +0x4c applyPointImpulse). +0x28 last
drive dir, **+0x2c/+0x30 = accel/brake inputs**, +0x34 handbrake, +0x40/+0x44 donut heat/boost,
+0x54.. wheel ptrs, +0x98 reverse flag, +0x170 round-robin raycast index, +0x174 fwd speed,
+0x178 drive-force blend, **+0x180/+0x184 = MaxSpeed / MaxSpeedReverse**, +0x188.. tuning copies,
+0x208 numWheels, +0x280 moving-forward flag.

**Tuning block (0x18c, 99 dwords) → actor field map** (ctor `FUN_00449460`): `[0x10]`→+0x180
MaxSpeed, `[0x13]`→+0x184 MaxSpeedReverse, `[0x14..0x1d]` = **front-wheel block** (radius +0x50,
susp strength/damp +0x54/+0x58, cmp/exp lengths +0x5c/+0x60, frictions fwd/side +0x64/+0x68,
brake/emergency +0x6c..+0x74), `[0x1e..0x27]` = **rear-wheel block** (mirror +0x78..0x9c),
`[0x3f,0x40]`→+0x1e8/+0x1ec **DonutBoost/DonutSidePower**, `[0x48..0x4a]` **CenterOfMassOffset**
→ `FUN_008d5290` setCenterOfMass, `[0x4c..0x5b]` = **16-dword gear/engine table @+0x218..+0x254**
(consumer not yet found — §5).

**Per-frame flow:**
1. **applyAction `FUN_0044db60`** — flips gravityFactor when upside-down (+0xf4<0), ages +0x26c,
   `FUN_0044cc90` averages wheel contact normals → ground normal, computes chassis speed at the
   front-axle point (v + ω×r). *(This is the fn that proves the noreturn fix — full body through
   the trailing sqrt.)*
2. **Wheel raycast scheduler `FUN_0044d9b0`** (vtbl slot 9): full raycast for all wheels when
   fast (v² > `_DAT_00beb5dc`) or normals diverge; else ONE wheel/frame round-robin (+0x170).
   Per-wheel `FUN_0044e2c0`: ray from hardpoint along −up × (restLen+radius) via `FUN_00432a30`.
3. **Suspension + tire friction `FUN_00449dc0`** — per-wheel spring `FUN_0044f680` (middle wheels
   clone front), accumulate per-AXLE contact force sums, per-axle clamped friction `FUN_004571b0`
   scaled by the front/rear friction multiplier and a cubic steering blend `1-(1-s)³`, applied as
   a point impulse at the axle centroid.
4. **Drive/traction impulse `FUN_0044a970`** (`FUN_0044a6a0` = 2-contact bike variant): requires
   ≥ half the wheels grounded; axle force =
   `+0x178·(1+DonutHeat·ramp)·speedRatio·dt·Σ(wheelDriveTorque·contact·handbrakeGate)/radius`
   along the averaged contact tangent, where **`speedRatio = clamp01((vmax−v)/(vmax·K))` — linear
   torque falloff to zero at MaxSpeed** (vmax = +0x180 fwd / +0x184 rev). Donut mode adds a
   sine-LUT (`DAT_00cf2900[(t·f)&0x1fff]`) lateral wobble × DonutSidePower when handbrake+throttle.
5. Sleep mgmt `FUN_0044fda0`/`FUN_0044fe20` (budget @+0x94); deactivation gate `FUN_00449440`.

**Boat (A) `FUN_00447260`:** in/out-water timers (+0x23c), then buoyancy + WaterDrag fwd/side/up
+ control forces + wake spawn (`FUN_00447350`/`FUN_00447f00`/`FUN_004477a0`/`FUN_00448210`). Ties
to [`water_code_map.md`](water_code_map.md).

**Heli (B) `FUN_00453760`:** controls `FUN_004514a0`, lift `FUN_004517b0`, pitch/roll servos
`FUN_004516a0`, airborne `FUN_00452540`; setup ground-probe `FUN_00453090`.

**Tank (G) `FUN_00454d80`:** 6 track-contact raycasts round-robin (`FUN_00454ae0` mirrors the car
scheduler with 6 fixed slots); `FUN_00455210(pair, side)` addresses track pairs
`(pair + side*2)·0x80`.

---

## 5. Corrections, open questions, confirm-live

**Corrections to existing docs:**
1. `vehicles.md` "UNKNOWN — the actual drive model" is **RESOLVED** (§4) — never
   `hkpVehicleInstance`; retail ships a custom raycast sim.
2. `vehicles.md` "per-vehicle-class controller singleton's ring" — on PC the rings are
   free-standing multi-subscriber broadcast queues, not embedded in per-class singletons.
3. `vehicles.md` Boat vs Heli — one cap-100 ring (`0x011C2478`) serves both on PC.
4. `resolved_vehicles.txt` "no vtables for vehicle physics classes" is wrong for PC — all nine
   actor vtables exist (no RTTI, but fully recoverable, §3).
5. `_CarWheel 2304` ≠ PC wheel size (PC = 0x130).

**Open questions:**
- The 16-dword gear/engine table (`+0x218..+0x254`, tuning dwords `0x4c..0x5b`) — width matches
  GearRatio1..5 + GearTorqueMulti1..5 + RPM band, but the consumer was not read in the
  applyAction/suspension/drive paths so far (candidate: engine-audio/RPM sim on the controller
  side, or a pass-2 wheel-spin fn).
- Authored tuning defaults are not yet decoded from the field-by-field loaders (§2) — the gold
  input for the Rust reimpl.
- The command-ID hash function (§1.5).

**Confirm-live plan (x32dbg, paused, read-only — never resume):**
1. bp `FUN_00538c90`/`FUN_00538d20`, dump the 16-byte record at ESI while the USER steers/brakes
   → assigns exact IDs to each thin wrapper + pins the player-input verb call sites.
2. bp `FUN_00437300`/`FUN_00435790`/`FUN_00441900`, capture stack → recovers the PC
   CarAction/HeliAction/BoatAction vtables.
3. Read (live, unpacked) SecuROM island targets: `_DAT_02455C94` (car fetch), `_DAT_0244F7B8`
   (ring-3 fetch), `thunk_FUN_024ba1a0` (turret/heli enqueue), `thunk_FUN_024e9260` (turret
   applier), `thunk_FUN_024e5180` (get-local-vehicle).
4. bp `0x00449460`, dump the 0x18c (99-dword) block; diff vs authored stats to name fields. bp
   `0x0044a970` to confirm `speedRatio` vs +0x180 MaxSpeed. bp `0x0044db60`/`0x00447260`/
   `0x00453760`/`0x00454d80` (car/boat/heli/tank applyActions), verify +0x208 wheel count.

---

## 6. Reimpl mapping (mercs2 modernization)

- Command rings → `mercs2_core` per-entity command component (bounded ring + subscriber mask;
  reuse aligns with the shadow-pc input dual-source pattern and the event-bus map).
- Nine actor classes → `mercs2_game` vehicles module; the drive math (§4) is a **direct port
  target** — a raycast car with per-axle friction solve + linear torque falloff, not a physics
  library vehicle. Tuning blocks load as WAD reflection data (like `wpn_*`), keyed by the stream
  sizes in §2.
- Buoyancy action (I) + boat (A) consume the waterline query already mapped in
  [`water_code_map.md`](water_code_map.md).

## 7. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (SecuROM-unpacked, base 0x400000) +
  noreturn-fixed re-decompiles `output/_ghidra/vehicle_phys_decomp.txt` / `vehicle_phys_decomp2.txt`
  (`scripts/ghidra_scripts/DecompileVehiclePhysics.java`).
- Xbox ground truth: `docs/mercs2-pdb-analysis/vehicles.md`, `data-defaults.md`, `havok-physics.md`;
  `output/jul08_prototype/pairing/{symbol_map.json,resolved_vehicles.txt,resolved_havok-physics.txt}`.
- Verified inline: registrar family (159-B descriptor writers, `0x9e3779b9` seed) at unpacked
  lines ~294034+; `s__CarPhysicsV2_00bc4b9c` → descriptor `0x017bc278`; `FUN_0044db60` full body
  (v+ω×r → sqrt, no truncation).
- Confidence stated per row; vtable-gated dispatch + SecuROM-island endpoints are the documented
  confirm-live gaps (§5).