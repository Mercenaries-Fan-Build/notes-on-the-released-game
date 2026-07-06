# Human animation selection — the engine's data-driven clip picker (de-hardcoded)

**Purpose:** replace the three hardcoded player clips (`CLIP_IDLE/WALK/RUN` = Mattias/Jennifer
hashes) with the *actual* engine mechanism, so **every** character (all 3 mercs + NPCs + DLC
costumes) animates from data, exactly as the retail game does. Nothing here is invented — every
table, column, and hash below is parsed out of retail `vz.wad` and cross-checked against a live
x32dbg capture.

Compiled 2026-07-04. Tool: `mercs2_probe --bin action_table_probe` (reuses
`wad_simulator::action_table` + `mercs2_formats::animgroup`).

## The problem

The engine hardcodes `CLIP_IDLE 0x24F8C8E6 / CLIP_WALK 0x53682784 / CLIP_RUN 0x867B166D`. Those are
one character's clips (idle is actually **Jennifer's**, which is why it warps Mattias). The base
game never hardcodes a clip hash — it selects clips through a chain of **`animationtable`** assets
(type `pandemic_hash_m2("animationtable") = 0x207359C7`, ASET type_id 11). This is the
indirection layer the type registry describes as *"between gameplay state machines and raw
animation clips."*

## The selection chain (fully reverse-engineered)

```
 game state  ─(ActionTable)→  Handle  ─(AnimationLookup + CharacterName)→  Animation index
                                                                                  │
                                                          (per-character animation set)
                                                                                  ▼
                                                                             Havok clip
```

### 1. ActionTable — `0x6802C321` (resident block 3185, 1020 rows, 14 cols)

One row per action. Columns (keyDims=6, totalDims=14):

`Stance, Action, AimState, Tandem, Seat, Target, ActionDirection, DamageDirection,`
**`AnimationHandles`**`, PartitionMask, Looping, Driven, ActionMask, LocomotionMask`

The engine forms a key from the character's current state — `Stance=Upright`, `Action=Idle/Move`,
`AimState`, `ActionDirection=Front/Left/Right/Back`, … — and the matching row's **`AnimationHandles`**
(col 8) is a *logical* **Handle** (782 distinct across the table), plus `Looping`/`Driven`/
`LocomotionMask` flags. Container layout: `UCFX → INFO[u16 keyDims,u16 totalDims,u16 count] →
TYPE[totalDims × (ASCII name \0 u16)] → VALU[count × totalDims × u32]`; none-sentinel `0x27DE7135`.

### 2. AnimationLookup — `0xE00B080C` (resident block 3185, 1485 rows, 10 cols)

The per-character resolver. Columns:

`Handle, Gender, `**`CharacterName`**`, PrimaryEquipmentClass, PrimaryEquipmentName,`
`InUseEquipmentClass, InUseEquipmentName, `**`Animation`**`, MinTimeScale, MaxTimeScale`

- `Handle` (col 0) matches the ActionTable's `AnimationHandles` — **158 of the 262 lookup handles
  overlap** the ActionTable's 782, i.e. this is the join.
- **`CharacterName` (col 2) is the per-character key** — it is literally `pandemic_hash_m2` of the
  merc name (VERIFIED):

  | Merc | CharacterName hash | lookup rows |
  |---|---|---|
  | Mattias | `0x030E6C38` | 135 |
  | Chris | `0xD64BB122` | 166 |
  | Jennifer | `0xF3144C8E` | 179 |

  `0x27DE7135` (the none-sentinel) appears in 870 rows = "any character" defaults. 18 distinct
  CharacterName values total (3 mercs + NPCs, still to be individually named).
- The row is further keyed by **equipment** (`PrimaryEquipmentClass/Name`, `InUseEquipmentClass/
  Name`) and `Gender` — so the *same* Handle gives a different clip when holding a rifle vs a
  pistol vs empty-handed.
- **`Animation` (col 7) is a small integer INDEX**, not a clip hash (all 1485 values < 3041). The
  same Handle (e.g. `0x9E6D9806`) resolves to a *different* index per character — **this is the
  per-character mechanism**. Each merc owns a contiguous, non-overlapping index block:

  | Merc | Animation-index range | distinct |
  |---|---|---|
  | Mattias | `0x07AE .. 0x08BE` | 135 |
  | Chris | `0x08C0 .. 0x0A0D` | 166 |
  | Jennifer | `0x0A0F .. 0x0B76` | 179 |

  `MinTimeScale/MaxTimeScale` (cols 8/9, f32) give the allowed playback-rate range (`-1` = default).

### 3. Transition graph — `0xAB8FE34B` (497 rows)

`FromHandle, ToSequence, SequenceIndex, TransitionType, TransitionDuration, TransitionAnimation` —
the blend/crossfade rules between handles (what our engine currently approximates with a fixed
`ANIM_BLEND_SEC`). Siblings in the same family: `VehicleAnimationLookup 0x182624E1` (the vehicle
analogue of §2, keyed by `VehicleClass/Name/Seat`), plus Sounds/Chatter/Spawn tables.

### 4. Animation index → clip — SOLVED (`ASTO[index]`)

The AnimationLookup container carries a **4th chunk `ASTO`** (12180 B = **3045 u32**) after
INFO/TYPE/VALU — a value pool. The `Animation` index (§2) is a **direct u32-element index into
`ASTO`**, and **`ASTO[index]` is the clip name-hash** (the animgroup clip). Verified:

- Chris: **165/166** indices resolve to a clip in his animgroup (block 3278); the ~1 miss is a
  shared/common animation not in his own animgroup.
- Mattias 129/135, Jennifer 178/179 (same: the handful of misses are shared anims).
- **`ASTO[Chris idle index] == 0xED37BC56`** — the exact clip the retail engine plays for Chris
  idling (independently captured via `LtSampleWave`). The chain is airtight.

Chunk layout of `0xE00B080C`: `INFO(6B) → TYPE(166B) → ASTO(12180B) → VALU(59400B)`. (ASTO = the
value/string pool referenced by index-typed columns; the ActionTable has no ASTO, so its columns
are all inline hashes/floats/enums.)

### 5. Full-chain validation (end to end)

```
ActionTable row  Stance=0x12C07B18(Upright)  Action=0x0C0A7FA6(Fidget)/0x23872F86/0xCD9B7E20
   → AnimationHandles = Handle 0x700D4DE0
   → AnimationLookup[Handle 0x700D4DE0, CharacterName 0xD64BB122(chris)] → Animation index
   → ASTO[index] = 0xED37BC56  == Chris's live-captured idle clip  ✓
```

Named state vocabulary so far: `Stance 0x12C07B18 = "Upright"`, `Action 0x0C0A7FA6 = "Fidget"`
(an idle-variant action; the idle Handle 0x700D4DE0 is shared by 3 Upright actions). The engine
assembles the per-character set (`HumanAnimationSet` `FUN_0065af90`, driven by
`HumanAnimationSystem` `FUN_0065ade0`); `ASTO` **is** that set's index→clip map, shipped in the
lookup asset — no runtime reconstruction needed.

## Why this is the right target

- **One code path for every character.** Mattias, Chris, Jennifer, NPCs, and DLC costumes all go
  through the same ActionTable + AnimationLookup; only their animgroup + CharacterName differ. No
  per-merc hardcoding, no per-merc x32dbg captures.
- **Equipment- and aim-aware for free.** Weapon-in-hand and aim state already select the right
  clip because they are lookup key columns.
- **It is the game's data.** All three tables parse byte-clean out of retail `vz.wad` block 3185.

## Implementation plan (engine)

1. **Parse the tables** into typed structs (extend `wad_simulator::action_table`, which already
   reads the header, to expose VALU rows + the `ASTO` pool generically for any `0x207359C7` table).
   The resolver is a pure function: `(state key, CharacterName) → clip hash` via
   ActionTable → Handle → AnimationLookup(row match) → `ASTO[Animation]`.
2. **`HumanAnimationSet` component:** per entity, hold `CharacterName = pandemic_hash_m2(merc)`;
   the resolver reads the shared resident tables (parsed once at load).
3. **`HumanAnimationSystem`:** each tick, derive the state key (Stance/Action/AimState/
   ActionDirection from movement + aim + equipment) → resolver → clip hash → look it up in the
   entity's loaded animgroup → drive the existing pose/blend path. Use the transition graph
   (`0xAB8FE34B`) for crossfades and `Min/MaxTimeScale` for playback rate.
4. Fall back to a shared/common human animgroup for the handful of `ASTO` clips that aren't in the
   character's own animgroup (the 1–6 shared anims per merc).
5. Delete `CLIP_IDLE/WALK/RUN`.

## Shipped in the engine (2026-07-04)

The per-character **idle** is now data-driven — the hardcoded `CLIP_IDLE = 0x24F8C8E6` (Jennifer's
clip, used for everyone) is gone from the player path:

- **`mercs2_formats::anim_select`** — parses the resident AnimationLookup (`INFO/TYPE/ASTO/VALU`)
  and resolves `AnimSelector::primary_idle(character)` = `ASTO[ AnimationLookup[Handle 0x700D4DE0,
  CharacterName] .Animation ]`. Static `fallback_idle` (the validated hashes) covers a WAD variant.
- **`world.rs`** — `load_world_data` derives the merc from the hero base model in the candidate
  list, resolves the idle through `resolve_player_idle` (base resident block 3185, then any
  `resident`-named block), and feeds it as the player's idle clip; the locomotion state machine
  keys its idle state off the resolved hash (`player_idle`) instead of the constant.
- Engine-path check (`action_table_probe`): **mattias `0x6EA88E00`, chris `0x835DA06A`, jennifer
  `0x24F8C8E6`** — each merc now idles on their own clip. Unit tests in `anim_select` guard the
  parse + resolution.

Walk/run still use the shared clips (they resolve through a separate base-locomotion default path,
not the per-character lookup) — the next step.

## Verified so far / open

- ✅ ActionTable, AnimationLookup, transition-graph schemas + row data (parse clean).
- ✅ CharacterName = `pandemic_hash_m2(merc)` — Mattias/Chris/Jennifer confirmed.
- ✅ Handle join (ActionTable.AnimationHandles ↔ AnimationLookup.Handle, 158 overlap).
- ✅ **Hop §4 SOLVED:** `Animation` = u32 index into the lookup's `ASTO` pool; `ASTO[index]` =
  clip hash. Chris/Mattias/Jennifer all resolve into their animgroups (165/166, 129/135, 178/179).
- ✅ **Full chain validated end to end:** `(Upright, Fidget) → Handle 0x700D4DE0 → chris →
  ASTO → 0xED37BC56`, matching the independent x32dbg `LtSampleWave` capture.
- ✅ State vocabulary partially named: `Stance 0x12C07B18 = Upright`, `Action 0x0C0A7FA6 = Fidget`.
- ⏳ Name the remaining ActionTable state-value hashes (Idle/Move/Run action names, directions)
  + the other 15 CharacterNames — for a fully readable state machine (mechanical; not a blocker).
- ⏳ Build the engine `HumanAnimationSet`/`HumanAnimationSystem` per the plan above.
