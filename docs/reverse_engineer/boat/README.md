---
status: current
evidence: proven
---

# Boats and seats (pc-v10): reads of 2026-11-24

Three reads of `game-files/canonical/dumps/mercs2_unpacked.exe` (sha256
`8c179a99d7fad88bab288826db19a579b53512801d8e0d1c1a761bbc30ebc7ba`, file offset = VA − 0x400000) and one of
the capture `game-files/memory-dumps/updated-chris-exports/20261103_new-game-first-mission-start.dmp`.
Each claim in the three reads carries its instruction addresses and a grade.

| Page | What it has |
|---|---|
| [`drive_spec.md`](drive_spec.md) | The boat actor's input, engine, thrust and steering: the `_BoatPhysics` record → actor field map (65 fields), the owner's command handler `FUN_00435790`, the pre-step `FUN_00446BD0`, thrust `FUN_00447350`, steering `FUN_00447F00`, the smoother `FUN_00714D90`, the physics substep count |
| [`float_spec.md`](float_spec.md) | Flotation: hull setup `FUN_00446930`, the water query `FUN_00480440`, the springs `FUN_004477A0`, drag, the extra gravity and self-righting `FUN_00448210` |
| [`seat_type.md`](seat_type.md) | How `Vehicle.Enter` (`0x005E8060`) and `Vehicle.GetSeatByType` (`0x005E72D0`) turn a seat type (`d`, `g`, `c`, `p`) into a seat |

The disassembly listings the three pages name were working files and are not kept; `objdump -d` of the
image at the cited addresses gives them again.

## The opening boat in the capture

Read with `mercs2_probe dump-entity` and `dump-read`. The boat is placed key `0x000B378F`
(`VzaCon001_StartingBoat`, template `Speed Boat` `0x80006A22`, model `0xB1EB099F`); the hero is `0x40004E98`.

| Fact | Where | Value |
|---|---|---|
| The boat's owner object | `PhysicsActor` of `0x000B378F` → `0x1F0AD280`, vtable `0x00BA9200` | actor at `+0x140` = `0x1F232400`; mass at `+0x144` = 8000 |
| The hull's box in the body's frame | owner `+0xC8` | (−1.37857, −0.57766, −6.21877) .. (1.37857, 2.23099, 6.16576) |
| The actor's copied fields | actor `+0x28` on | as `drive_spec.md` §A maps them (`MaxSpeed` 120 at `+0x28`, `EngineInertia` 0.975 at `+0x148`, …) |
| In-water factor, ground and water heights | actor `+0x154`, `+0x15C`, `+0x160` | 1.0, −99.33484, −35.67583 |
| The four spring records | actor `+0x16C`, stride 0x34 | corners (±1.37857, 0.6 / 1.0, 6.16576 / −6.21877); roll coefficient ±0.40725, pitch coefficient 1.23280 on the two at +Z; smoothed water heights −36.128, −35.938, −36.149, −36.101 |
| The body | actor `+0x18` = `0x1EBB8000`; motion at `+0xD0`, vtable `0x00B5921C` (`hkpBoxMotion`) | position (−1726.966, −36.357, 2068.791); centre of mass in the body (0, 0.82666, −0.0265) at `+0x160` |
| The motion's inverse inertia and inverse mass | body `+0x190` | (1.4259e-5, 1.4071e-5, 1.9357e-4), 1.25e-4 |
| The motion's damping | body `+0x184`, `+0x188` | linear 0, angular 0.8 |
| The body's friction | body `+0x84` | 0.3 (`HullFriction`) |
| The body's restitution | body `+0x88` | 0.0 |
| The body's shape | body `+0x10` = `0x1EB93480`, vtable `0x00BA8C44`, a second (container) vtable `0x00BA8C6C` at `+0x10` | a list shape of 13 children (`+0x18` = `0x1ED44E00`, count `+0x1C` = 13): the model's authored convex pieces. Its cached box: half extents (1.37857, 1.40433, 6.19226) at `+0x30` with 0.05 in the fourth word, centre (0, 0.82666, −0.0265) at `+0x40`, which is the owner's hull box and the body's centre of mass |
| The physics world's gravity | body `+0x08` = world `0x20007800`, `+0x10` | (0, −9, 0) |
| The watermap object | `[0xD6AF84]` = `0x20016380` | 257 × 257 cells (`+0x18`, `+0x1C`), cell 32 (`+0x28`), origin (−4096, −4096) (`+0x30`, `+0x38`) |
| The wave table | `0xD6AD80`, records of 0x14 bytes `{kx, kz, 1/‖k‖, amplitude, ω}` | the first five amplitudes are 0.1452, 0.1224, 0.0654, 0.0606, 0.0504; the sixth is 0.0408, under the 0.05 the water query stops at |
| The seated hero | `RuntimeSceneObject` of `0x40004E98` | position (−1728.734, −36.368, 2067.652), the boat's rotation: the boat's origin moved by (−0.650, −0.011, −2.000) in the boat's frame |
| The driver's seat node | model `0xB1EB099F`, node `0xD6EBE292` (`mercs2_probe hier --model 0xB1EB099F`) | (−0.65, 0.00, −2.00): the `HardPoint` of the `SeatLink` whose seat is `Vehicle Seat (Cigarette) (Driver)` (`0x8000A01D`) |
| The link from seat to rider | `RuntimePhysicalLink` of `0x000B378F` at `0x20A5DFD8` | hardpoint `0xD6EBE292`, the hero's key, no offset, rotation (0, 0, 0, 1) |

The model's authored collision (`PHY2`) as a box is 0.05 inside the captured box on each side and at the
top, 0.014 at the bottom; as a solid of mass 8000 its inertia is (68269, 69570, 4541) against the
capture's (70131, 71068, 5166).

## `SeatParameters`

The class's `schm` names its flag bits: bit 0 `bIsDriverSeat`, 1 `bIsGunnerSeat`, 2 `bIsCargoSeat`,
3 `bIsLivingWorld`, 4 `bIsFriendlyTransfer`, 5 `bIsHijackable`, 6 `bIsHijackBlocker`, 7 `bIsRiderInvisible`,
8 `bIsRiderVulnerable`, 9 `bIsRiderBashable`, 10 `bIsStowable`, 11 `bCanReport`, 12 `bCanPlayerUse`,
13 `bIsPlayerVulnerable`; then `uStowSeat`, `TossSpeedChange`, `MinDitchSpeed`, `SeatDieAction`
(`mercs2_probe we-template --class SeatParameters`). The masks `seat_type.md` reads in the Xbox 360 image
(bit 31, 30, 29) are these first three bits in that build's bit order.

In retail `vz.wad`, 959 templates carry 3670 `SeatLink` records; 892 seats have `bIsDriverSeat`, 1493 seat
templates carry one of the six `Controller*` records `GetControlBindingType` probes, 874 have both, and
one seat template (`0x80006619`, `JetTest`'s) has no record at all.

## What these reads correct elsewhere

- [`vehicle_code_map.md`](../vehicle_code_map.md): the boat's command handler is `FUN_00435790`, not
  `FUN_00441900`; it writes actor `+0xF8` throttle, `+0xFC` brake and reverse, `+0x100` turn, `+0x104`
  handbrake, each payload as it comes. The helicopter's handler is `0x4396C0` (its offsets not read here).
  Actor `+0x23C` is a contact listener, not a water timer; `+0x168` is the reversing flag and the spring
  records start at `+0x16C`. `FUN_004465E0` copies the record field by field; the actor is allocated by
  `FUN_00435660`.
- [`water_code_map.md`](../water_code_map.md): `FUN_00480440` returns a height and whether the point is at
  or under it; it interpolates the four cells around the point and takes any non-zero wet byte as water.
  `InWaterT`, `WaterDepth` and `ShallowT` are not fields the PC loader reads.
- Self-righting starts as soon as the hull's up leans past 60° and runs for 0.5 s after; `VisRudderBone` is
  copied to actor `+0xAC`; the speed cap stops thrust only in the direction of motion.
