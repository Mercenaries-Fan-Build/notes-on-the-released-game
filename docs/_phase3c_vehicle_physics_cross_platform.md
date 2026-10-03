# Phase 3c — Vehicle physics tuning: cross-platform (PC / Xbox 360 / PS3)

**Status:** current · **Evidence:** proven (byte-level SHA-256 match on all 11 physics
component classes across all three platforms, after u32-word-swap on consoles).

**Question answered:** Do PC, Xbox 360 and PS3 ship different per-vehicle TUNING
constants (mass, drag, suspension, torque, max speed, etc.) for drivable vehicles?

**Verdict: NO.** Every vehicle on every platform ships byte-identical tuning. The pool-size
divergence found in Phase 2 §3.4 (consoles' bigger `_CarPhysicsV2 / _HelicopterPhysics` pools)
affects only **how many** of each physics-actor class can live concurrently; the per-vehicle
behaviour is cross-platform-identical by byte.

---

## 1. Where vehicle physics tuning is stored (PROVEN)

The per-vehicle tuning constants live inside a **single giant "worldentity"-type UCFX
container** that is a resident entry of one WAD block per vehicle-level WAD. Phase 2 §3.4's
`cdbsizes.ini` INI blob holds pool caps only — not per-vehicle tuning. A section-header
scan of each binary (`[Vehicle]`, `[Physics]`, `[cars]`, `vehicles.ini`, …) returns zero
hits in `mercs2_unpacked.exe`, `default.pe.bin` and `EBOOT.elf`; the tuning is not baked
into any binary (`scratchpad/bin-pattern-scan.log`).

**The container is addressed per platform as:**

| Platform | WAD | WAD endian | Resident-block index | Worldentity size |
|---|---|---|---:|---:|
| PC retail (v1.1 unpacked) | `game-files/pc-game-vz.wad` | LE (`FFCS`) | **3185** | **1,819,324 B** |
| Xbox 360 NTSC-US (JTAGRip) | `game-files/xbox-vz.wad` | BE (`SCFF`) | **3180** | **1,639,764 B** |
| PS3 BLUS30056 | `game-files/ps3-VZ.WAD` | BE (`SCFF`) | **3527** | **1,639,764 B** |

Verified by iterating every WAD block, decompressing (`sges`/`segs` deflate — Phase 2 §3.8
notes consoles use the `segs` BE spelling), and matching an entry whose `type_hash` ==
`pandemic_hash_m2("worldentity") = 0x5647C35D` (console-side `type_id` is still u32-LE per
the mixed-endian ASET note in `mercs2_formats::ffcs`). Xbox+PS3 ship **identical**
worldentity size (1,639,764 B); PC ships 179,560 B more because its `info`-chunk bodies carry
null-terminated ASCII class names (`Ai`, `_CarPhysicsV2`, …) that consoles strip to a 16-byte
`[u32 class_name_hash][u32][u32][u32 0]` tuple.

**UCFX descriptor count:** 785 on PC vs **589** on both consoles (–196). **COMP group
count: 195 on all three.** PC's extra descriptor overhead sits almost entirely in the
longer `info` bodies.

**Per-COMP ECS data layout** (`crates/mercs2_probe/src/bin/worldentity_template_block.rs`
`parse_buckets`):

```
data body = concat of buckets
bucket    = [u32 count N] [N × u32 handle] [stride-byte payload shared by all N handles]
```

The payload is the serialized ECS component struct for the vehicle class. For
`_CarPhysicsV2` the stride is `0x18c` = 99 u32 slots, matching the stream-class
descriptor's `stream_size` recorded at PC `0x017bc278` and reverse-engineered in
`docs/reverse_engineer/vehicle_code_map.md` §2.

---

## 2. Cross-platform diff — all 11 physics component classes (PROVEN)

Method: extract each class's full data body on every platform, normalise console payloads
by u32 word-swap (every 4 bytes reversed; consoles store multi-byte fields big-endian
because the engine code reads them with the platform's native integer load), sort each
bucket's handle list, SHA-256 the resulting byte stream. Script:
`scratchpad/veh_phys_diff.py` → `scratchpad/veh_phys_proof.py`.

| Component class | Stride | Buckets | Handles (vehicles) | Unique tuning tables | SHA-256 (first 16 hex) PC == XB == PS3 |
|---|---:|---:|---:|---:|:---:|
| `_CarPhysicsV2` | 0x18c | 107 | **454** | 105 | `e76b8703e9bc73ec` |
| `_CarWheel` | 0x14 | 214 | **2,002** | 38 | `25e53106e345ba51` |
| `_BoatPhysics` | 0x114 | 27 | **110** | 25 | `c443af26f19609e0` |
| `_HelicopterPhysics` | 0x58 | 21 | **143** | 14 | `67b3add6e0ec9ffe` |
| `_HelicopterPhysicsAi` | 0x54 | 12 | **138** | 4 | `e5c2d0c644ac00af` |
| `_TankPhysics` | 0x78 | 15 | **72** | 15 | `d0c431e81354cb37` |
| `_JetPhysics` | 0x4 | 1 | **1** | 1 | `4a1542d775fdbe29` |
| `_HumanPhysics` | 0x84 | 7 | **297** | 7 | `6bfe33c032ae269f` |
| `_BuildingPhysics` | 0x8 | 59 | **1,484** | 3 | `4a0b05e1919af4f0` |
| `_DebrisPhysics` | 0xc | 42 | **96** | 16 | `34d9605c4840ddcf` |
| `_PropPhysics` | 0x10 | 102 | **567** | 35 | `e65f9d59981fffed` |

Per-row match verdict: `ALL3` for all 11 classes. **Zero bucket count divergence, zero
handle divergence, zero unique-payload divergence, zero byte divergence.**

Per-handle check — the stronger version of the diff (does the SAME vehicle on every
platform get the SAME tuning payload?):

| Class | Common handles across all 3 | PC==XB on common | PC==PS3 on common | All 3 agree |
|---|---:|---:|---:|---:|
| `_CarPhysicsV2` | **454 / 454** | 454/454 | 454/454 | **454/454** |
| `_BoatPhysics` | 110 / 110 | 110/110 | 110/110 | **110/110** |
| `_HelicopterPhysics` | 143 / 143 | 143/143 | 143/143 | **143/143** |
| `_HelicopterPhysicsAi` | 138 / 138 | 138/138 | 138/138 | **138/138** |
| `_TankPhysics` | 72 / 72 | 72/72 | 72/72 | **72/72** |
| `_HumanPhysics` | 297 / 297 | 297/297 | 297/297 | **297/297** |

Every ECS handle present on PC is also present on Xbox and PS3 with the SAME tuning
payload. This closes the question at the byte level — not just "the data looks the same",
but "the data IS the same".

---

## 3. Spot-check — bucket 0 of `_CarPhysicsV2` decoded as floats

The first bucket (5 handles sharing one tuning table) decodes to the same 32 floats
whether read PC-LE, Xbox-BE or PS3-BE:

| u32 slot | PC (LE f32) | Xbox (BE f32) | PS3 (BE f32) |
|---:|---:|---:|---:|
| 0 (mass? / chassis I) | 1000.0 | 1000.0 | 1000.0 |
| 1 | 0.70 | 0.70 | 0.70 |
| 2 | 0.70 | 0.70 | 0.70 |
| 3 | 0.80 | 0.80 | 0.80 |
| 4 | 0.95 | 0.95 | 0.95 |
| 5 | 0.93 | 0.93 | 0.93 |
| 6 | 0.90 | 0.90 | 0.90 |
| 7 | 5.0 | 5.0 | 5.0 |
| 8 | 35.0 | 35.0 | 35.0 |
| 9 | 0.77 | 0.77 | 0.77 |
| 10 | 0.50 | 0.50 | 0.50 |
| 11 | 0.75 | 0.75 | 0.75 |
| 12 | 0.0 | 0.0 | 0.0 |
| 13 | 1.5 | 1.5 | 1.5 |
| 14 | 3.0 | 3.0 | 3.0 |
| 15 | 1.0 | 1.0 | 1.0 |
| **16 (MaxSpeed)** | **90.0** | **90.0** | **90.0** |
| 17 | 100.0 | 100.0 | 100.0 |
| 18 | 1.2 | 1.2 | 1.2 |
| **19 (MaxSpeedReverse)** | **65.0** | **65.0** | **65.0** |
| 20 | 0.29 | 0.29 | 0.29 |
| 21 | 35.0 | 35.0 | 35.0 |
| 22 | 2.0 | 2.0 | 2.0 |
| 23 | 0.10 | 0.10 | 0.10 |
| 24 | 0.20 | 0.20 | 0.20 |
| 25 | 0.10 | 0.10 | 0.10 |
| 26 | 1.3 | 1.3 | 1.3 |
| 27 | 0.10 | 0.10 | 0.10 |
| 28 | 7.0 | 7.0 | 7.0 |
| 29 | 0.10 | 0.10 | 0.10 |
| 30 | 0.29 | 0.29 | 0.29 |
| 31 | 35.0 | 35.0 | 35.0 |

Slot semantics from `docs/reverse_engineer/vehicle_code_map.md` §4 (ctor `FUN_00449460`):
`[0x10]` = MaxSpeed, `[0x13]` = MaxSpeedReverse, `[0x14..0x1d]` = front-wheel block,
`[0x1e..0x27]` = rear-wheel block, `[0x3f,0x40]` = DonutBoost/DonutSidePower,
`[0x48..0x4a]` = CenterOfMassOffset, `[0x4c..0x5b]` = 16-dword gear/engine table.

---

## 4. Spread of car tuning (PC-identical to consoles — see §2)

Across all **105 unique `_CarPhysicsV2` tuning tables** on PC:

- **MaxSpeed (slot 16)**: ranges 75 (slow civilian cars) up to **165** (fastest car) —
  Pandemic game-units (likely mph given the HUD readout).
- **MaxSpeedReverse (slot 19)**: 10 up to 100.
- **Slot 0 (chassis mass or inertia)**: 200 up to 26,000.
- Example extremes (PC-decoded, identical bytes on consoles):
  - Slowest: slot0 = 200, MaxSpeed = 75, MaxSpdRev = 30 (handles `0x8000A46D`, `0x8000AAB6`)
  - Fastest: slot0 = 1800, MaxSpeed = 165, MaxSpdRev = 50 (handle `0x8000A265`)

These values are identical byte-for-byte on Xbox 360 and PS3 after u32-swap.

---

## 5. Why the consoles diverge in pool size but not in tuning

The authoring pipeline is identical: all three WAD bakes consume the same source scenes
and serialize the same `_CarPhysicsV2 / _BoatPhysics / _HelicopterPhysics / _TankPhysics /
_JetPhysics / _CarWheel / _HumanPhysics / _BuildingPhysics / _DebrisPhysics / _PropPhysics`
component instances. The only pre-baking per-platform rewrites are structural (byte-swap
to BE on consoles, class-name hashing in `info` bodies, block repackaging per §3.8). The
engine code consuming the tuning (PC `FUN_00658f60` field-by-field loader for Car,
`FUN_006584a0` Boat, etc.) is identical on all three platforms — the exe differs only in
how far it unrolls defaults for strings. Consoles handle larger populations by **having
more ECS slots**, not by **running cheaper per-vehicle physics**.

**Implication for the modernization reimpl (`docs/modernization/00_charter.md`):** the
tuning gold set is single-source. Any platform's WAD is a valid oracle; the Rust vehicle
system (`docs/reverse_engineer/vehicle_code_map.md` §4 → `mercs2_vehicle`) only needs to
match ONE set of 99 dwords per Car template, 69 per Boat, 22 per Heli, 30 per Tank. No
per-platform tuning switch is required.

---

## 6. Reproduction

```sh
# Extract per-platform physics data (writes veh_phys_dump.json).
python3 scratchpad/veh_phys_diff.py

# Byte-level SHA-256 proof + float decode of bucket 0.
python3 scratchpad/veh_phys_proof.py
```

Scratchpad artefacts (one agent run, 2026-10-03):

- `scratchpad/veh_phys_diff.py` — WAD → worldentity → UCFX → COMP bucket dump (handles LE +
  BE WADs, resolves console class-names via `pandemic_hash_m2`).
- `scratchpad/veh_phys_proof.py` — normalises consoles via u32 word-swap, SHA-256s each
  class's bucket stream, decodes bucket 0 of `_CarPhysicsV2`.
- `scratchpad/veh_phys_cmp.py` — set + per-handle equality verifier.
- `scratchpad/veh_phys_dump.json` — raw hex of every bucket per platform.
- `scratchpad/bin-pattern-scan.log` — proves no `[Vehicle]`/`[Physics]`/`vehicles.ini`
  section exists in any of the three binaries.

---

## 7. Open items (out of scope for Phase 3c)

- **ECS handle → vehicle NAME resolution.** The `Name` COMP group's variable-length
  schema stops the parser after 14 entries on PC (likely a sub-field with embedded nulls
  breaks the double-NUL terminator heuristic). Full name resolution would let future
  reports write "the Piranha ships identical tuning on all three platforms" rather than
  "handle `0x8000A265` ships identical tuning on all three platforms". The byte-level
  verdict is unchanged.
- **Field-level NAMING for the 99-slot Car tuning struct.** `vehicle_code_map.md` §2 flags
  this as the open "authored tuning defaults are not yet decoded from the field-by-field
  loaders" item. Field positions 16 (MaxSpeed) and 19 (MaxSpeedReverse) are proven here;
  the other 97 are still numeric.
- **Three small-stride physics classes** (`_CollapsePhysics` 12 B total body,
  `_JetPhysics` stride 4 single-handle, `PhysicsPropertyFakeContinuous` 28 B) — the first
  two were parsed; `_CollapsePhysics` carries no buckets at all (the 12-byte body is a
  pure schema entry). This matches `_CollapsePhysics 8 8` in `cdbsizes.ini` (presize 8
  entries, no authored data).
