# Human animation selection — the engine's data-driven clip picker

The base game never hardcodes a clip hash. It selects clips through a chain of **`animationtable`**
assets (type `pandemic_hash_m2("animationtable") = 0x207359C7`, ASET type_id 11) — the indirection
layer the type registry describes as *"between gameplay state machines and raw animation clips."*
Every table, column and hash below is parsed out of retail `vz.wad` and checked against the v1.0 exe
and live captures (`game-files/memory-dumps`).

Tools: `mercs2_probe anim-table <0xNAME> [--handle 0xH] [--list Animation]` prints a table as the
loader holds it; `mercs2_probe --bin action_table_probe` walks the ActionTable joins.

## The selection chain

```
 game state ─(ActionTable)→ Handle ─(AnimationLookup query, keyed by the character)→ Animation list
                                                                                          │
                                                          one clip, drawn from the game's random state
                                                                                          ▼
                                                                                     Havok clip
```

### 0. `animationtable` container layout (all tables)

`UCFX → INFO[u16 keyDims, u16 totalDims, u16 count] → TYPE[totalDims × (ASCII name \0 u16)] →
[ASTO] → VALU[count × totalDims × u32]`; none-sentinel `0x27DE7135` (`"*"`).

As the loader `FUN_0067C780` holds it:

- **`VALU` row 0 is the defaults row** (table `+0x2C`/`+0x30`), not data. The data rows are `VALU`
  rows `1..count` (table `+0x1C = count − 1`; the live AnimationLookup reads `0x5CC` = 1484).
- **`ASTO` = `[u32 n][n u32 pool]`**; the loader keeps the pool (table `+0x50`).
- The AnimationLookup's index is `+0x18 = 1` (column 0, `Handle`, hashed; posting lists of data-row
  indices, ascending), its candidate filter column is `+0x54 = 3`, `+0x58 = 0`.

### 1. ActionTable — `0x6802C321` (resident block 3185, 14 cols)

Columns (keyDims=6, totalDims=14):

`Stance, Action, AimState, Tandem, Seat, Target, ActionDirection, DamageDirection,`
**`AnimationHandles`**`, PartitionMask, Looping, Driven, ActionMask, LocomotionMask`

The engine forms a key from the character's state — `Stance=Upright`, `Action`, `AimState`,
`ActionDirection`, … — and the matching row's **`AnimationHandles`** (col 8) is a logical **Handle**,
plus the `Looping`/`Driven`/mask flags. `Looping` loops only on `TRUE` `0x1E5208DD` (`FUN_0068A8C0`);
`Driven` is driven on `TRUE` or `0x14BD1BBD` (`FUN_0068A4B0`).

### 2. AnimationLookup — `0xE00B080C` (resident block 3185, 1484 data rows, 10 cols)

The table's real name is not known (`pandemic_hash_m2("AnimationLookup")` is `0x2987300B`).
Columns, read by **position**:

`Handle, Gender, `**`CharacterName`**`, PrimaryEquipmentClass, PrimaryEquipmentName,`
`InUseEquipmentClass, InUseEquipmentName, `**`Animation`**`, MinTimeScale, MaxTimeScale`

- `Handle` matches the ActionTable's `AnimationHandles`.
- `Gender` + `CharacterName` are the template's **`HumanAnimationSet`** component
  (`{u32 gender, u32 character}`, live container `0x017BCD18`). Mercs: Gender `Hero` `0x51728909`,
  CharacterName `pandemic_hash_m2` of `mattias` `0x030E6C38` / `chris` `0xD64BB122` /
  `jennifer` `0xF3144C8E`.
- Equipment classes seen: Bare `0xD20EC345`, `0xD0459A41` (Rifle), `0x5434C7ED`, `0xD48C7D34`
  (Pistol), `0x496D5A75` (Grenade). `0x5434C7ED` matches `pandemic_hash_m2("Rocket")`, but its
  run/sprint clips hold a machine-pistol-like pose, so that name is not established.
- **`Animation` is a pool index pointing at a list `[count][count clip hashes]`.** Lists repeat clips
  as weights (`[0x787CA282 ×3]`). Live: data row 718's cell `0x5B9` is `pool + 0x5B9*4`, which holds
  `[1, 0x937D421D]`.
- `MinTimeScale/MaxTimeScale` (f32) give the allowed playback-rate range (`-1` = default).

### 3. The query (`FUN_00743CD0` → `FUN_0067CF20` → `0x0248A55F` → `FUN_0067CBC0` / `FUN_0067C5D0`)

1. **Key.** A copy of the defaults row (`0x0055BFE0`), then (`0x00743B35`): `Handle`; `Gender` and
   `CharacterName` from the entity's `HumanAnimationSet`, each only when non-zero; the primary
   equipment's class and name from its equipment component — **`Bare`** when the character carries
   no primary; the in-use equipment's class and name when there is one.
2. **Candidates.** The data rows whose `Handle` equals the key's, in table order (the Handle index's
   posting list, read live: ascending), whose `PrimaryEquipmentClass` is the key's or the default.
3. **Score.** Over the first 7 columns: 2 per cell equal to the key, 1 per cell equal to the default,
   0 otherwise — a mismatch does not disqualify.
4. **Winner.** The first candidate with the strictly highest score.
5. **Check.** The winner is rejected unless its `CharacterName` is the key's or the default; retail
   then plays the placeholder `0x9D886544` with time scales `-1`.
6. **Clip.** `list[draw % count]`, `draw = (x & 0xFFFF0000) | (u >> 16)` from two steps of the game's
   global random state `DAT_00DFCBAC` (`mercs2_core::random::Lcg`).

### 4. Upright locomotion handles

The Upright stance hands its locomotion controller a static handle list compiled into the exe
(`0x00689CD1: push 0x00CFFE58`). No ActionTable row names them.

| Entry | Handle | Role | Evidence |
|---|---|---|---|
| 0 | `0xE20D8D5B` | second sprint (weapon held differently) | workshop playback |
| 2 | `0x93C5DE3A` | second run (weapon held differently) | workshop playback |
| 7 | `0x5CC77D41` | full sprint | workshop playback; `footstep_run` annotations |
| 8 | `0xF71C4238` | sprint | workshop playback; `footstep_run` annotations |
| 9 | `0xB99AD3B3` | run | workshop playback; `footstep_run` annotations |
| 10 | `0x695F945A` | walk | every row's clips carry `footstep_walk` annotations |
| 12 | `0x2403F715` | standing idle | its Hero/chris/Rifle row lists `0xED37BC56`, the clip a live `LtSampleWave` capture shows Chris idling on |
| 13 | `0x700D4DE0` | fidget idles | ActionTable `Upright` + `Fidget` rows |

Entries 1, 3–6 and 11 are not identified. `FUN_00738E00` (a controller's vtable `+0x50` init) queries
entries 0–3.

Per-merc unarmed (`Bare`) clips:

| Merc | idle | walk | run | sprint | full sprint |
|---|---|---|---|---|---|
| mattias | `0x6EA88E00` | `0xBBA47DC4` | `0x193879AD` | `0xC49B7F23` | `0xE76E2740` |
| chris | `0x835DA06A` | `0x3EFF5F5B` | `0xB5679590` | `0x4F69D6D5` | `0x73E90A02` |
| jennifer | `0x24F8C8E6` | `0xEB36DB0F` | `0x94B1E4AC` | `0xA1FEF731` | `0xF23B92C6` |

### 5. Transition graph — `0xAB8FE34B` (497 rows)

`FromHandle, ToSequence, SequenceIndex, TransitionType, TransitionDuration, TransitionAnimation` —
the blend/crossfade rules between handles. Siblings: `VehicleAnimationLookup 0x182624E1` (the
vehicle analogue, keyed by `VehicleClass/Name/Seat`, queried with 6 scored columns by `FUN_00743C40`).

## Engine implementation

- **`mercs2_formats::anim_select`** — `AnimTable` (layout §0), `AnimSelector::query` (§3, rule by rule),
  `LookupRow::clip_at` (the list draw), `human_animation_sets` (the `HumanAnimationSet` component).
- **`mercs2_anim::select`** — the Upright handle constants (§4) and `ClipPicker` (ActionTable state →
  clip).
- **`mercs2_engine::game_world::HumanAnimData`** — loads both tables and the worldentity by asset
  name; resolves a template's identity and its locomotion clips. A query that no row survives, or
  a row that lists several clips where one clip is needed, is an error.
