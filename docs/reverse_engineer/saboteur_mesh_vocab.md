# The Saboteur as a mesh/node name oracle for Mercenaries 2

**Date:** 2026-07-14. **Author:** mining pass over the Saboteur binary + full game install.
**Verifier:** every candidate below was hashed with `tools/fnv.py` (`pandemic_hash_m2`, case-insensitive)
and checked against `docs/data/bone_census.csv` (unnamed = `name` empty) and the Q2 target `0x765CD254`.

## TL;DR

- **No new bone/node names were cracked.** Comprehensive mining of the Saboteur's binary and its entire
  shipped data set produced **zero** verified hits against Mercs 2's 5,504 unnamed node hashes, and **no**
  match for the Q2 destruction stem `0x765CD254`.
- **But the Q1 and Q2 STRUCTURES were solved/re-confirmed by exact FNV inversion** (below). The remaining
  unknown in both is a single word that is not spelled anywhere in either game's data — i.e. a GPU
  preimage job, not a mining job.
- **Two provenance witnesses gained** for already-named bones: the Saboteur FaceFX rig ships
  `Bone_Cheek_Left`/`Bone_Cheek_Right`, which hash to the Mercs 2 named bones `bone_cheek_left`
  (`0x30103344`) / `bone_cheek_right` (`0x9AB50943`). Second-witness corroboration, not new cracks.
- **Q4 (face rig) negative is now confirmed against a REAL bone list**, not just the binary — see §5.

## Sources mined (all on disk)

| Source | Size | What it yielded |
|---|---|---|
| `output/_ghidra_saboteur/saboteur_all_functions_decomp.txt` | 54 MB, 36,935 fns | 2,571 string literals, 24,854 symbols, 410 `FUN_00db7e10` (find-bone) args |
| `C:\GOG Games\The Saboteur\Saboteur.exe` | 14.8 MB | 38,155 ASCII strings (bone/hp/format-string set) |
| `…\FaceFX\{Male,Female}.fxa` | 57 KB / 54 KB | **37-entry face-bone list** (the real oracle for Q4) |
| `…\France\*.megapack` + `Global\*.megapack` (~3.4 GB) | | 13.1 M strings → 1.28 M identifiers = asset/model names |
| `…\France\loosefiles_BinPC.pack`, `LuaScripts.luap`, `*.kiloPack`, `particle.pack`, `dfe` | | pack/script strings |
| `…\ModelInfo.txt`, `tuner.txt`, `startlocs.ini`, `ai.ini` | | LOD/slice tags, vehicle model list |

## 1. Q1 — the 3 nodes under every wheel bone: STRUCTURE SOLVED

`tools/fnv.py`'s `m2` is invertible (FNV-1a + two fixed finalization multiplies). Define
`U(h) = ((h·P⁻¹) ^ 0x2A)·P⁻¹` = the FNV state just before the *last* character, XORed with that
character. Two names that differ **only in their final character** satisfy `U(a) ^ U(b) < 0x80`.

Applying this across every model's wheel children (`docs/data/bone_skeleton.csv`, parent ∈
`bone_wheel_*`):

- **Within a single wheel**, the 3 children do **not** differ by one character (0 pairs) — they are 3
  distinct mesh parts.
- **Across wheels of the same model**, the *same part* differs by **exactly one trailing digit**
  (2,897 such pairs where random noise predicts ~0.0004 — astronomically significant).

Decoding the trailing digit against wheel identity (e.g. `vz_veh_tank_scorpion90`, 10 wheels):

```
part-stem state 0x1D089B4D:
  bone_wheel_l_02 → digit 1    bone_wheel_r_01 → digit 5
  bone_wheel_l_03 → digit 2    bone_wheel_r_02 → digit 6
  bone_wheel_l_04 → digit 3    bone_wheel_r_03 → digit 7
  bone_wheel_l_05 → digit 4    bone_wheel_r_04 → digit 8
                               bone_wheel_r_05 → digit 9
```

**Verdict: a wheel child is named `<partStem><wheelIndexDigit>`** — the trailing digit is a global
wheel index, and `<partStem>` is a fixed word shared across all wheels of the model (2 stems for
tanks/APCs, 3 for wheeled trucks/trailers). This *revises* the prior note that the children "carry no
index": they carry a wheel-index digit; what they do **not** carry is a side token or the parent name.

**The stem word is unknown.** Every plausible source was tested against the recovered stem-states
(968 distinct states across 115 models):
- Dictionary match of 1.06 M mined tokens (Saboteur binary + all game packs + prior vocab) under prefixes
  `bone_wheel_ / bone_ / wheel_ / (none) / hp_ / veh_` → **0 real-word matches** (only FNV-collision
  gibberish like `bone_wheel_ejykx`, which is expected noise at that pool size).
- Curated wheel-part dialect (`tire, tyre, rim, hub, hubcap, tread, rubber, disc, brake, caliper, spoke,
  rotor, axle, roller, roadwheel, idler, bogie, sprocket, render, shadow, collision, proxy, cage, lod, …`)
  × prefixes × the recovered stem-states → **0 matches**.
- Bounded brute force of the 671 wheel-child hashes over `[a-z0-9_]` up to `prefix+4` chars (prefixes
  `bone_wheel_`, `bone_`, `wheel_`, empty, `hp_`, `veh_`, …): 35 hits total, **all** non-wheel-child
  false positives (matching the ~24 expected from S·T/2³² ≈ 19 M·5504/2³²). **No wheel child is a short
  name.** The stem is a longer non-dictionary token — a GPU preimage against the exact stem-states, not
  a mine.

## 2. Q2 — the vehicle destruction group node: STRUCTURE RE-CONFIRMED EXACTLY

The Q2 node `0x765CD254` appears in 172 models; in each its parent is `bone_frame` and it has two
children. FNV inversion pins its exact pre-finalize state to **`0xE141A8F6`**, and confirms the
pristine/ruin relationship with certainty:

```
state(STEM)              = 0xE141A8F6   (finalizes to 0x765CD254 ✓)
m2(STEM + "_pristine")   = 0x255EAB53   ← exactly matches child 1 ✓
m2(STEM + "_ruin")       = 0x75F1F74D   ← exactly matches child 2 ✓
```

So the triad is unambiguously `<STEM>` / `<STEM>_pristine` / `<STEM>_ruin` under `bone_frame`, and any
STEM candidate can be verified against **three** independent constraints at once.

**The STEM word is still unknown.** Tested and rejected: 1.06 M mined single tokens; curated destruction
vocabulary (`destructible, breakable, damageable, destruction, damagegroup, damagemodel, breakgroup,
swapgroup, stategroup, wreckgroup, bodygroup, vehiclebody, chassis, superstructure, dynamicpart,
damregion, …`); prefix/suffix compounds of those. None hash to `0x765CD254`. The Saboteur's own
destruction dialect is `_DAM` suffix + `Destroyed`/`Ruin`/`wrecked` asset-name tokens (§4) — it does
**not** share Mercs 2's group-node stem.

## 3. Shared-dialect witnesses (what the Saboteur DID confirm)

Hashing the Saboteur's complete `FUN_00db7e10` (find-bone-by-name) argument set (410 literals) and its
exe `Bone_*`/`hp_*` strings against the census re-confirms the shared Pandemic rig but cracks nothing new:

| Saboteur literal | m2 | Mercs 2 census |
|---|---|---|
| `GlobalSRT` | `0xCBC1EB51` | already named `GlobalSRT` (2nd witness) |
| `hp_shelleject` | `0x3D106439` | already named `hp_shelleject` (2nd witness) |
| `hp_CenterOfMass` | `0xA5F8253C` | already named `hp_CenterOfMass` |
| `Bone_Cheek_Left` (FaceFX) | `0x30103344` | already named `bone_cheek_left` (**new witness**) |
| `Bone_Cheek_Right` (FaceFX) | `0x9AB50943` | already named `bone_cheek_right` (**new witness**) |
| `Bone_LFootBone1/2`, `Bone_RFootBone1/2`, `Bone_Attach_L/RHand`, `Bone_Spine1`, `Bone_Root`, … | | already named (body rig, confirmed shared) |

Saboteur-only literals absent from Mercs 2 entirely (not even present as hashes): `Bone_Valve`,
`Bone_HeadBase`, `Bone_Hip`, `bone_grab`, `hp_hat`, `hp_Stow1/2`, `hp_rifleslot1/2`, `hp_particleEject`,
`HP_WepSpawnLeft/Right`, `hp_buoyancy_xyz`, `hp_Ladder_A_Start/End`.

## 4. Saboteur vehicle/wheel/destruction dialect (for the record)

- **Virtual-wheel system** (RTTI): `WSVirVehicleWheelBlueprint`, `WSPhysicsVehicleWheel`,
  `WSPhysicsVehicleWheelFXBlueprint`, `VirVehicleChassis`, `VirVehicleSetup`, `?VirtualWheelBlueprint%d`.
- **Swappable wheel meshes** (asset names, not intra-mesh nodes): `14InchSportFrontWheel`,
  `15InchFrontWheel`, `17InchLimoRearWheel`, `21InchHeavyDutyFrontWheel`, `24InchHeavyDutyRearWheel`…
  i.e. the Saboteur attaches a whole wheel *model* to a hub, rather than naming rim/tire sub-nodes.
- **Mesh-variant / LOD tags** (`ModelInfo.txt`): `RENDERSLICE0..3`, `SHADOWSLICE0..3`, `ZCULL`,
  `LODDIST25/30`, `FOLIAGE`, `ALWAYSRENDER`, and a `_DAM` suffix marking a model's damaged variant.
- **Destruction/debris asset tokens**: `*_Destroyed`, `*_Ruin[B-G]`, `*_wrecked_*`, `*_Chunk[0-9]`,
  `*_Endpiece`, `Zep_INT_SliceA`, `DDynamicPart%i`, `DamRegionSpawner%d`, `HumanDamRegTransfer%d`.
  None of these crack the Mercs 2 debris/`_pristine`/`_ruin` stems.

New tokens harvested this pass were appended to `docs/data/saboteur_vocab.txt` (+78 entries: face-rig,
virtual-wheel, mesh-slice, ladder/stow hardpoints).

## 5. Q4 — character/face rig: NEGATIVE, now against a real bone list

`FaceFX/{Male,Female}.fxa` contains the Saboteur's full facial rig (37 bones):
`Bone_JawBone, Bone_MouthBase, Bone_UpperLip_Left/Right, Bone_LowerLip_Left/Right,
Bone_InnerUpperLip_*, Bone_OuterUpperLip_*, Bone_LipCorner_*, Bone_Eye_Left/Right,
Bone_EyeBlink_*, Bone_LowLid_*, Bone_UnderEye_*, Bone_Brow_*, Bone_OutBrow_*, Bone_Cheek_*,
Bone_LowerCheek_*, Bone_Teeth_Top/Bottom, Bone_Tongue_Mid, Bone_Sneer, Bone_HeadBase, …`.

Hashed against the census: **only `Bone_Cheek_Left/Right` exist in Mercs 2** (already named, §3). Every
other Saboteur face bone is **absent from Mercs 2's hash set entirely** — not unnamed, simply not
present. So Mercs 2's ~15 missing human-rig bones are not these FaceFX facial bones, and the face dialect
is (apart from the cheeks) genuinely not shared. This closes Q4 with the actual bone list the prior pass
asked for.

## Error bars / honesty

- Every "witness" in §3/§5 is an S=1 literal → error bar ~1e-9 (certain). No fabricated names were added;
  `docs/data/bone_saboteur.json` was **not** created because nothing new was verified.
- The two structural results (§1 `<partStem><digit>`, §2 exact `0xE141A8F6` stem-state with verified
  pristine/ruin children) are algebraic identities on the hash — certain, not guesses.
- Brute/dictionary negatives are quantified: short wheel-child names ruled out to `prefix+4` chars
  (~19 M candidates, 0 wheel-child hits vs ~24 expected FP); Q2 stem ruled out for all mined tokens and
  curated compounds.

## Next technical step (not mining)

Both remaining unknowns are single non-dictionary words with an **exact known FNV state**
(Q2: `0xE141A8F6`; Q1: each of the recovered per-model stem-states). Feed those states to the GPU
preimage cracker (`tools/gpu_fast.py` / `gpu_product.py`) over `[a-z0-9_]` for lengths ≥5. Q2 gets a
free triple-check (`STEM`, `STEM_pristine`, `STEM_ruin`), so any GPU hit there is self-verifying.
