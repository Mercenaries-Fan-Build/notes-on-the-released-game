# Mercs 1 → Mercs 2 node-name recovery: findings

Everything below is from the Mercenaries 1 source tree. Paths are repo-relative.
Companion artifact: `mercs1_wordlist_hashed.csv` (38,052 candidates, pre-hashed).

---

## 0. ⚠️ FIRST: your hash function has a bug (for node names)

The brief's `pandemic_hash_m2()` applies a trailing `h ^= 0x2A; h *= prime` finalize.
**Node hashes do not have that finalize.** Two independent proofs:

1. The brief's own test vector. `piece1a → 0x39422307` is what you get with **no** finalize.
   With the finalize you get `0x501d5fd7`. The brief's code and its expected value disagree.
2. Mercs 1's source is full of `0xHASH /* "name" */` comments emitted by
   `Projects/Tools/Hash/Hash.c`. **23/23 of them reproduce with the un-finalized hash.**

The real function is Mercs 1's `PblHash::_MakeHash` — `Projects/Pebble/Source/PblHashTable.cpp:14`:

```c
uint32 PblHash::_MakeHash( const char* pcText )
{
    if( !pcText || !*pcText ) return 0;
    uint32 uiValue = 0x811c9dc5;
    while( *pcText )
    {
        uiValue ^= ( uint32 )*pcText++ | 0x20;  // Suppress case.
        uiValue *= 0x01000193;
    }
    return uiValue;
}
```

The `0x2A` you observed is real, but it is **not a finalize** — `0x2A` is `'*'`, and
`'*' | 0x20 == 0x2A`, so it is simply one more FNV round over a literal `*` appended to the
string. So:

| use | function |
|---|---|
| **node / bone / hardpoint names** | `PblHash(s)` — plain, no star |
| ECS class + asset-type names | `PblHash(s + "*")` — the "m2" variant |

The wordlist CSV gives **both** columns; join node hashes on `hash_pbl_PLAIN__use_this_for_nodes`.

---

## 1. ⚠️ EVERY node name ships with TRAILING DIGITS STRIPPED

The highest-leverage rule here, and it applies to **all** nodes, not just hardpoints.

`Projects/Tools/ModelMunge/Source/ModelMunge.cpp:91` — writing the `NODE` chunk (the name that ships):

```c
if( pChunk->Open( "NODE" ) )
{
    pChunk->WriteString( pFlat->_Name.RemoveTrailingDigits() );
    pChunk->Close();
}
```

`Projects/Tools/HandyLib/Source/HandyString.cpp:145` — and it is **digits only**:

```c
while( i >= 0 && pcText[ i ] >= '0' && pcText[ i ] <= '9' )   // DIGITS ONLY, no underscores
{
    pcText[ i ] = 0;
    i -= 1;
}
```

**The rule: strip trailing `[0-9]+`. Underscores are NOT stripped.**

Why it exists: XSI auto-numbers duplicate node names. The `VehiclePanelDamage` wiki says so outright
— *"XSI will append numbers to identically named nodes. The expectation is that these numbers are
stripped by ModelMunge."* And `spec_rider.html`: *"Numbers appended to hardpoint names in XSI are
ignored."*

It validates against the source's own hash tables:

```
wheel_fl3          -> ships as wheel_fl           0xde4cb333  == uiWheelHashes[0]  ✓
hp_centerOfMass2   -> ships as hp_centerOfMass    0x83b27b7e                       ✓
L1_wheel_geometry5 -> ships as L1_wheel_geometry  0x813859ef                       ✓
ruin12             -> ships as ruin               0x0726035f
hp_light_A_01      -> ships as hp_light_A_        0xd228ccc7   (trailing '_' KEPT)
cbvlbp_9           -> ships as cbvlbp_            0x3019d3d5   (trailing '_' KEPT)
```

⚠️ **Correction to an earlier draft of this doc.** `FlatModel.cpp:45` `HpFilter()` strips trailing
digits *and* underscores, from `hp_` nodes only — but it is **dead code**. `grep -rn HpFilter` over
the entire tree returns nothing but its own definition; it is never called. Do **not** strip trailing
underscores, and do not restrict the rule to `hp_`.

The wordlist marks the shipped form as `source = m1_node_SHIPPED_rtd`. **Join on those.**

`MustKeepNode()` (`FlatModel.cpp:144`) separately shows `hp_` is the one prefix auto-kept from pruning:
```c
if( pcText[0]=='h' && pcText[1]=='p' && pcText[2]=='_' ) // Our lovely hardpoint naming convention.
```

---

## 2. Q1 — what hangs under a wheel bone: **THREE LOD MESHES** ✅

Answer: `L1_wheel_geometry`, `L2_wheel_geometry`, `L3_wheel_geometry`.

```
pbl("L1_wheel_geometry") = 0x813859ef
pbl("L2_wheel_geometry") = 0x287b9614
pbl("L3_wheel_geometry") = 0xe77ebbf5
```

In Mercs 1 the wheel is its own `.msh`, referenced by the ODF property `geometryNameWheel`
(`RsActorVehicleCar.cpp:148`), and instanced per wheel. Its contents:

```
allies_veh_humvee_wheel.msh
  wheel                 (root, Null)
  ├── hp_centerOfMass1  (hardpoint)
  ├── cxvpb_collision   (collision)
  ├── L1_wheel_geometry (Static)
  ├── L2_wheel_geometry (Static)
  └── L3_wheel_geometry (Static)
```

This matches your description exactly — three children, same size as the wheel, on the
centreline, **no side token, no index, individually named**. Same shape in
`allies_veh_cargotruck_wheel.msh`, `china_veh_bj2020_wheel.msh`, `allies_veh_lavstryker_wheel.msh`.

**Negative result that saves you time:** there are **no** `tire`, `rim`, `hub`, `axle`, `susp`,
`shock`, or `brake` node names anywhere in Mercs 1. Those words exist only as physics ODF params
(`physicsWheelRadiusCalculated`, `physicsWheelFrictionFront`…) and sound cues. The only tire-ish
nodes are `hp_tiresmoke` (an FX hardpoint) and `Spare_tire`. Stop searching that vocabulary.

The wheel **bones** are: `wheel_fl` `wheel_fr` `wheel_rl` `wheel_rr` `wheel_mid`
(`RsActorVehicleCar.cpp:40`, a literal `uiWheelHashes[4]` table).

---

## 3. Q2 — the destruction group stem: two strong candidates ✅

### 3a. `pristine` is a literal Mercs 1 survivor

`Projects/RetroStrike/Source/RsLocationalDamage.cpp:6` — a 32-entry table of **verbatim node
names**, alternating pristine/damage (the header notes: *"It's important that pristine/damage
panels alternate."*):

```c
const uint32 uiPanelHashes[RsLocationalDamage::NumPanels] =
{
    0xc6e01396 /* "segment_pristine_FL" */ ,  0x5b72ed55 /* "segment_damage_FL" */ ,
    0x9cc7cc92 /* "segment_pristine_LF" */ ,  0x4163b9dd /* "segment_damage_LF" */ ,
    0xe247a400 /* "segment_pristine_L"  */ ,  0x186c3ca9 /* "segment_damage_L"  */ ,
    0x98c7c646 /* "segment_pristine_LB" */ ,  0x3d63b391 /* "segment_damage_LB" */ ,
    0xa6ea6e92 /* "segment_pristine_BL" */ ,  0x3b7bb551 /* "segment_damage_BL" */ ,
    0xb92e889a /* "segment_pristine_HoodL"*/, 0x0ec9a03b /* "segment_damage_HoodL"*/,
    0x964c1c59 /* "segment_pristine_TopL"*/,  0xbe57df76 /* "segment_damage_TopL"*/,
    0xec47b3be /* "segment_pristine_F"  */ ,  0x1e6c461b /* "segment_damage_F"  */ ,
    ... (mirrored for FR/RF/R/RB/BR/HoodR/TopR/B)
};
```

Location tokens: `FL LF L LB BL HoodL TopL F FR RF R RB BR HoodR TopR B`.
**Mercs 2 appears to have renamed the `damage` state to `ruin`** and moved the state token from a
suffix to the group level. All of `segment_{pristine,damage,ruin,intact}_{LOC}` are in the wordlist.

### 3b. The group node that holds the branches

Observed hierarchy on Mercs 1 cars:

```
Alliescargotruck                (model root)
└── L1_chassis_geometry         <-- destructible body group
    ├── pristine                (Null)  -> segment_pristine_*
    ├── damage                  (Null)  -> segment_damage_*
    └── door_rf / door_lf / ...
```

So the ≥9-char stem you want is most likely the **`*_geometry` group name**. Ranked candidates
(hash to join on the plain column):

| candidate | `<STEM>` | `<STEM>_pristine` | `<STEM>_ruin` |
|---|---|---|---|
| `body_geometry` (13ch) | `0xa09ea1d2` | `0x65a90d6f` | `0x03cd8041` |
| `chassis_geometry` (16ch) | `0xa6e5b7f0` | `0xce796fd1` | `0x70e1feb7` |
| `L1_body_geometry` (16ch) | `0x37c649ac` | `0x87169745` | `0x93b4a413` |
| `L1_chassis_geometry` (19ch) | `0x64d0d59e` | `0x4cbacbe3` | `0x59cfbf9d` |

### 3c. Alternative hypothesis: the stem is the MODEL'S OWN ROOT NAME

In Mercs 1, pristine and ruin were **separate `.msh` files**, and the ruin file's root node is the
model's root name + `_ruin`:

```
china_veh_cargotruck.msh       root = chinacargotruck        (0xc062dc27)
china_veh_cargotruck_ruin.msh  root = chinacargotruck_ruin   (0xe8211c02)
```

Note the root is **not** the filename — it's the artist's XSI scene root, a squashed form with
`veh` dropped. Mercs 2 merged these two files under one SWIT node, so `<STEM>` may simply be the
**per-model root name**. This fits your evidence well: it is long (≥9 chars), it differs per model
(you see it in 172 vehicles), and it is never spelled in string tables because it's a scene-graph
name, not an asset path.

**Cheap decisive test:** you already resolve 457/464 `model_name_hash` values to real VZ assets.
For one vehicle, take its asset name, squash it (drop separators and the `veh` token), and hash
`<squashed>`, `<squashed>_pristine`, `<squashed>_ruin`. If they hit, the stem is per-model and
**every one of the 172 vehicles unlocks at once.**

The wordlist contains all 2,085 Mercs 1 model roots (566 of which already have a `_ruin` twin), and
generated `_pristine`/`_ruin`/`_intact` forms for each (`source = q2_rootstem`).

---

## 4. Q4 — human rig bones (partial) ✅

Verbatim from source hash comments, all verified:

```
bone_head 0x4313ebf2   bone_ribcage 0xb813dae5   bone_root 0xbe794a08
bone_pelvis            bone_spine_1 0x730b6c7b   bone_spine_2 0x740b6e0e
bone_l_foot 0x7ef01c45 bone_r_foot 0x93cf18b3
bone_l_hand 0x159233ac bone_r_hand 0xf427ac52
dummyroot 0x1f9229b7
```

**Facial rig** (`RsAnimHuman.cpp:1079`, via `GetJointIdxByCrc`) — this is your jaw/tongue chain:

```
bone_jaw 0x9c5820be          bone_brow 0x3cdb69ea
bone_l_eye 0x07b867ae        bone_r_eye 0x0fb25b14
bone_mouth_left 0xd6dbdc75   bone_mouth_right 0x3abf198e
bone_mouth_top 0xdbaf1137    bone_upper_eyelids 0x50176030
```

From the extracted `.msh` dump, the full Mercs 1 biped is `bone_*` + `eff_*` (IK effector) +
`root_*` (IK prerotation) triples:
`bone_head, bone_neck, bone_ribcage, bone_spine_1, bone_spine_2, bone_l_clavicle,
bone_l_upperarm, bone_l_forearm, bone_l_hand` (+ r_ mirrors), each with `eff_<same>` and
`root_<same>`.

⚠️ Mercs 1 uses `bone_l_upperarm`, **not** `Bone_LBicep`. Mercs 2's rig was renamed to the glued
`L`/`R` dialect. So Mercs 1 gives you the *skeleton topology* and the `eff_`/`root_` sibling
convention, but the Mercs 2 spelling differs. Treat these as structural hints, not direct hits.

**Not recovered here:** the `Mercs 2 Skeleton` XSI file *is* in this tree —
`Mercs 1 Animation Tools/Mercs 2 Skeleton/Mercs2_Skeleton_Male-MASTERFILE-07.scn` (9.8 MB,
Oct 2006). It is an OLE2 compound doc whose XSI 4.2 streams store object names **encoded** — the
literal bytes `bone`, `spine`, `pelvis`, `clavicle` appear **zero** times in any encoding I tried
(raw, UTF-16, dword-deswapped, zlib). Cracking it needs a real XSI `.scn` decoder. **This file is
the single highest-value unopened artifact in the tree** — it is literally the Mercs 2 male rig.

---

## 5. Other name tables found (all verbatim, all verified)

**Vehicle lights** — `RsActorVehicleCar.cpp:48`:
`hp_headLightL` `hp_headLightR` `hp_brakeLightL` `hp_brakeLightR` `hp_reverseLightL` `hp_reverseLightR`

**FX-bearing nodes the engine will attach effects to** — `RsEffectGenerator.cpp:49`, `PreProcessJoint()`.
This is the authoritative hardpoint/FX list:
```
fx_chimneysmoke fx_smokestack fx_flame fx_flamesmall fx_tempsparks fx_sparkingwire
fx_damagesmoke fx_tempflame fx_tempflamesmall fx_flametiny fx_waterfall fx_waterfalldark
hp_wingtip_l hp_wingtip_r hp_wingtip hp_tiresmoke
hp_light_a hp_light_b hp_light_c hp_light_d hp_light_e hp_light_f
Rotor TailRotor k_fana k_fanb k_fanc
```

**Rotors** — `RsActorVehicleHelicopterGeneral.cpp:111`:
`rotor` `tailrotor` `crotor` `rotor_stop` `tailrotor_stop` `crotor_stop`

**Treads** — `RsActorVehicleTank.cpp:141`: `treadleft` `treadright`
plus `hp_treadfrontL/R`, `hp_treadbackL/R`

**Full `hp_` set harvested from source comments:**
```
hp_attachmentPoint hp_barrel hp_barreltip_a hp_brakeLightL hp_brakeLightR hp_cargo hp_cargoMax
hp_cargoMin hp_centerOfMass hp_connectionPoint hp_dock_gps hp_dock_left hp_dock_right hp_fluid
hp_garagedoorproximity hp_headLightL hp_headLightR hp_light_a..f hp_pivot hp_player
hp_reverseLightL hp_reverseLightR hp_ropeAttachment hp_sellcar hp_sellchopper hp_shelleject
hp_shopexit hp_siren hp_sparks hp_target hp_tiresmoke hp_treadbackL hp_treadbackR hp_treadfrontL
hp_treadfrontR hp_weapons hp_wingtip hp_wingtip_l hp_wingtip_r
```
From the `.msh` dump, also: `hp_seat_lf/rf/lr/rr/ct`, `hp_dock_lf/rf/lr/rr`, `hp_spawn`,
`hp_hijack`, `hp_getup`, `hp_starter`, `hp_chair`, `hp_camera[a-e]`, `hp_dynacamA/B`.
⚠️ Note Mercs 1 orders the side token **`lf`/`rf`/`lr`/`rr`** (side-first); your Mercs 2 brief says
`fl`/`fr` (front-first). The convention flipped between games — try both.

---

## 6. LOD naming: there is NO token table (definitive negative)

`Projects/Tools/ModelMunge/Source/FlatModel.cpp:70` — `GetLOD()` is the entire parser:
a name starting with `l` followed by up to 4 digits in `'1'..'4'`, each setting a **bit** in a
mask (`MAX_LOD_COUNT 4`). Parsing **stops at the first non-`1..4` char**.

So in `L1_small`, the `_` terminates it → `uLOD = 0b0001`. **`_small`, `_faraway`, `_far`, `_big`
are purely cosmetic artist labels the munger never reads.** `L12_ruin` means "present in LODs 1
and 2". Don't look for an LOD suffix vocabulary — there isn't one.

Dominant art-team habits (frequency from the `.msh` dump): `L1_small` (980), `L3_faraway` (709),
`L3_far` (176), `L1_body_geometry` (151), `L1_big` (108), `L2_body_geometry` (92).

---

## 7. Buildings destruct differently (negative result for Q3)

Buildings do **not** use in-model pristine/ruin nodes — they swap whole `.msh` files, selected by
ODF properties (`RsActorBuilding.cpp:1455`):

```c
_uiDamageModel = pSpore->FindPropertyHash( 0x1ecfb739 /* "geometrynamedamaged" */ );
_uiRuinsModel  = pSpore->FindPropertyHash( 0x3a612a5d /* "geometrynameruined" */ );

char cPropRuinName[25]     = "geometryNameRuinA";
char cPropRuinNodeName[20] = "nodeNameRuinA";
for (uint8 uiPropRuin = 0; uiPropRuin < uiMaxPropRuinsPerBuilding; uiPropRuin++ )
{
    ...
    cPropRuinName[16]++;      // geometryNameRuinA -> ...RuinB -> ...RuinC
    cPropRuinNodeName[12]++;  // nodeNameRuinA     -> nodeNameRuinB
}
```

So the ODF props run `geometryNameRuinA`…`geometryNameRuinY` / `nodeNameRuinA`…`nodeNameRuinY`
(max 25). **The debris node name is arbitrary and lives in the ODF, not in code** — which is
exactly why your Q3 debris stems can't be found by grepping code. To crack Q3 you want the ODF
files themselves (`Editor/BUILD/DATA/**/*.odf`), not the source.

Mercs 1 debris nodes observed in the `.msh` dump are simply `ruin1`…`ruin16`, `wheelruin1`…, under
`L1_body_ruin_geometry` / `L1_small*`. No `propdebris`/`propattach` string exists anywhere in
Mercs 1 — **that vocabulary is new in Mercs 2.**

### 7a. But Mercs 1 DOES have a `propattach` equivalent: the `k_` prefix ✅

The ODF `nodeNameRuin*` values are the **attach-node names**, and they are all `k_`-prefixed:

```
nodeNameRuinA("k_ruin")            x467
nodeNameRuinB("k_prop_ruin")       x406
nodeNameRuinA("k_tail")            x228
nodenameruina("k_bottomcontainer") x175   nodenameruinb("k_topcontainer")
nodenameruinc("k_beama")           x175   nodenameruine("k_beamc")
k_dmz_fencecornera/b  k_barrel_ruin  k_turret_ruin  k_barrelprop  k_alarmtower01prop
k_catwalkstraight  k_cranetower  k_cranearmmiddle  k_facadeleft  k_billboardbsignb…
```

paired with `geometryNameRuin*` values like `warehouse_container_bottom_prop`,
`nk_veh_emplacedgun_prop_ruin`, `global_sandbagsstraight_ruin`.

So the Mercs 1 grammar is **`k_<thing>` (attach point) + `<asset>_prop` / `<asset>_ruin` (geometry)**.
Mercs 2's `propattach` / `propdebris` are the renamed descendants of exactly this system. When
brute-forcing Mercs 2 debris stems, the productive vocabulary is these `k_*` body words
(`beam`, `facade`, `catwalk`, `container`, `crane`, `billboard`, `tower`, `fence`, `barrel`, `wing`,
`tail`, `nose`, `engine`, `turret`), not generic dictionary words.

All 4,661 distinct ODF string values are in the wordlist as `source = m1_odf_value`.

⚠️ Correction to §2's negative: `k_axle`, `k_axle_front`, `k_axle_rear` **do** exist as node names.
This does not change the Q1 answer (your three wheel children were geometrically proven not to be
axles), but "axle" is not absent from the vocabulary.

---

## 8. Collision node grammar (bonus — fully decodes the `cbvlb_*` families)

`Projects/Tools/ModelMunge/Source/Collision.cpp:49-181` — `GetCollisionProxyFlags()`.
Comment on :89 states the grammar: `// assume low-case input, trailing digits removed. cb{dlvbp}_ or ct{dlvbp}_`

Char 1 = `c`. Char 2 = geometry type. Chars 3..n = flags in **any order**, terminated by a
**mandatory** `_`.

| geom (char 2) | | flag letters | flag | bit |
|---|---|---|---|---|
| `b` boxes | | `v` | OBSTACLE_FOR_VEHICLES | 0x01 |
| `t` triangles | | `b` | OBSTACLE_FOR_BULLETS | 0x02 |
| `x` convex vertices | | `l` | OBSTACLE_FOR_VISIBILITY (line of sight) | 0x04 |
| | | `p` | OBSTACLE_PHYSICS_DYNAMIC | 0x08 |
| | | `s` | OBSTACLE_SOFT | 0x10 |
| | | `m` | OBSTACLE_FOR_MISSILES_ONLY | 0x20 |
| | | `o` | OBSTACLE_ONE_WAY | 0x40 |

Two behaviours worth knowing:
- **No flag letters ⇒ all three of v/b/l assumed** (:175). That's why bare `cb_` works.
- **`p` + triangles is silently promoted to convex** (:169).

So `cbvlb_` = boxes, blocks vehicles+LOS+bullets. `cbmv_` = boxes, missiles-only + vehicles.
`cxvpb_collision` = convex, vehicles + physics-dynamic + bullets.
Obsolete forms it warns about: `drive_collision`, `c_vlb`, bare `collision`.

⚠️ The letters `m`, `s`, `o` and geom type `x` are **not documented in any wiki** — only in
`Collision.cpp`. The artist-facing FAQ (`Documentation/Mercs1Faq/.../faq_collision.html`) only ever
mentions `v`, `l`, `b`.

---

## 9. The art bible: `Documentation/Vehicle Creation.doc`

This is the "how to build a vehicle" document. Verbatim rules that pin the grammar:

- **Doors:** `door_rl` `door_rr` `door_fl` `door_fr`
- **Turrets:** *"Turrets have three parts: `turret_a` < `barrel_a` < `hp_barreltip_a`. For each
  additional set, change the suffix to the next letter of the alphabet (`turret_b`, `turret_c`…)"*
- **Wheels:** `wheel_fr` `wheel_fl` `wheel_rr` `wheel_rl`, extras are `wheel_mid`. And decisively:
  *"The wheel object is actually not part of the hierarchy and is exported as a different file."*
  *"Wheels are present in the scene, but are exported as separate reference objects, **with three
  levels of detail each**."* ← independent confirmation of §2.
- **Prop ruins:** *"Prop ruins require that a null be placed in the pristine model and be named with
  a `k_` preceding the name. Ex. `K_tail` would refer to the prop ruin 'tail'."* ← confirms §7a.
- **Ruin models:** *"All ruins need the null `hp_centerofmass`… Another null used in ruins is
  `fx_tempflame`."*
- **Export naming:** `nk_veh_cargotruck.msh` / `nk_veh_cargotruck_ruin.msh` /
  `nk_veh_cargotruck_wheel.msh` / prop ruin `nk_veh_cargotruck_door.msh`
- **Shadow volumes:** node named `shadowvolume` (91 models use it).

**Building-destruction prop ruins** (wiki `BuildingDestruction`) — the geometry naming rule is
*"originalname_ruin_piecename"*:
```
nodeNameRuinA = "k_cranetower"      geometryNameRuinA = "warehouse_bld_crane_ruin_tower"
nodeNameRuinB = "k_cranearmmiddle"  geometryNameRuinB = "warehouse_bld_crane_ruin_arm"
nodeNameRuinC = "k_container"       geometryNameRuinC = "warehouse_bld_crane_ruin_container"
```

**Asset file naming** (`faq_asset_naming_v3.html`, 10/10/2003): `group_type_name_variant`, all
lowercase, no underscores inside a part. `type` ∈ `hum|veh|bld|env|pic`. `variant` ∈ `_ruin|_moving`.
e.g. `pyongyang_bld_apartmentblock01_ruin`. **This is the rule to invert when generating Mercs 2
stem candidates from resolved asset names** (§3c).

---

## 10. Seat / dock location codes (Mercs 1 dialect — differs from Mercs 2!)

`Documentation/Mercs1GDD/.../spec_rider.html`. Naming is `hp_seat_<code>`, `hp_dock_<code>`,
`door_<code>`, where `<code>` is:

```
LF = left front     RF = right front
LM = left middle    RM = right middle
LR = left rear      RR = right rear
LB = left back      RB = right back
CB = center back
LT = left top       RT = right top      CT = center top (e.g. humvee gunner)
```

⚠️ **Mercs 1 puts the side FIRST (`lf` = left-front). Your Mercs 2 brief lists `hp_seat_fl` /
`hp_dock_fr` — front-first.** The convention inverted between games. Try both orderings.

The same spec independently confirms §1: *"Numbers appended to hardpoint names in XSI are ignored."*

---

## 11. Corrections to earlier claims in this doc

- §2's negative said "no `tire`/`rim`/`hub`/`axle` node names exist". Verified precisely:
  **exact `tire` = 0, exact `rim` = 0** — the negative holds for the wheel-mesh question. But
  `k_axle`, `k_axle_front`, `k_axle_rear` **do** exist (12 models), and `rotorhub` exists. Apparent
  `tire`/`hub` "families" are substring artifacts of `hp_tiresmoke` / `hp_tiredust` / `rotorhub` /
  `trim`. The Q1 answer is unaffected.
- The `pristine` / `damage` group nulls **did ship** (13 models each) but the wiki
  (`VehiclePanelDamage`, 09 Dec 2003) says they are **vestigial**: *"you'll note that they are still
  under the 'damage' and 'pristine' nodes, but these two are ignored, they're just left in for
  organization purposes."* Only the `segment_pristine_*` / `segment_damage_*` prefix matters.
- **No `foundation` / `rubble` / `debris` / `wreck` / `intact` / `shard` / `chunk` / `slice` /
  `destructible` group-node vocabulary exists anywhere in Mercs 1** (docs or shipped nodes). That
  vocabulary is a Mercs 2 innovation. This *strengthens* the §3c hypothesis that `<STEM>` is the
  model's own root name rather than a keyword — because Mercs 1 has no keyword to inherit.

---

## 12. Which name tokens are REAL vs. artist convention

**`_geometry` and `_collision` are NOT keywords.** `grep -rn '_geometry'` across all of `Tools/`
returns **zero hits**. `L1_body_geometry` parses as `L1_` + the free text `body_geometry`;
`cxvpb_collision` parses as `c`+`x`+`vpb`+`_` + the free text `collision`. Both suffixes are pure
artist habit, inherited from the FAQ's own examples. They carry no semantics in the toolchain.

Everything meaningful is a **prefix**:

| token | mechanism |
|---|---|
| `L1_`…`L4_`, `L12_`, `L123_`, `L1234_` | `GetLOD()`, bitmask |
| `lod*` | legacy, `IsOldStyleLODName()` |
| `c[btx][lvbmpso]*_` | `GetCollisionProxyFlags()` |
| `collision*`, `c_vlb*` | legacy collision |
| `drive_collision*` | **ignored entirely** |
| `hp_` | hardcoded keep |
| `k_`, `fx_`, `segment_` | `-keep` wildcards (data-driven!) |
| `l1_k_` | `-keep` wildcard (animation) |
| `p_`, `c_` | scale-exempt proxies (exporter VBS) |
| `skipnode_`, `ACTOR_`, `_char`, `player0` | CinShotMunge (`CinShot.h:57`) |
| `_ruin`, `_moving`, `_wreck` | **asset-file** suffixes, not node names |

The keep-lists are on the munge command line, not in code —
`Tools/BAT/update_assets_msh.bat:10`: `-keep k_* fx_* segment_*`
`Tools/BAT/update_assets_animations.bat:12`: `-keep k_* hp_* l1_k_*`

**`shadowvolume` is a custom XSI property, not a name test.** A node is a shadow volume iff its MSH
segment carries shadow verts (`FlatModel.cpp:515`). The name is convention only.

**The XSI exporter DLL does not generate node names.** `XSI2MSHExporter.dll` is the generic
LucasArts/Pandemic "Zero" MSH exporter (Star Wars Battlefront lineage); its string table holds only
`ModelType{null|child_skin|cloth|envelop|skin|static}`, `Name{%s}`, `Parent{%s}`, `Prefix{%s}`,
`CollisionsVolumes {%d}`. It passes artist names through as opaque text. **There is no
`sprintf`-style node-name builder anywhere in the pipeline** — every name in Mercs 1 is typed by a
human in XSI. (Mercs 2's `propdebris00..95` series implies Mercs 2 *added* a generator; it does not
exist here.)

**Dead enum worth knowing about:** `Tools/ZenAsset/msh.h:319` declares
`Model::ModelType { Null_Node, Skin_Node, Cloth_Node, Envelop_Node, Static_Node, Child_Skin_Node,
Shadow_Volume, Destructible_Node, SWCI_Collision_Node }`. **`Destructible_Node` is never assigned or
tested anywhere**, and no exporter emits it. It is aspirational — but its existence in the 2005
codebase suggests Mercs 2's SWIT/destruction-node system is the *realisation* of this stub.

**Extra bone vocabulary** from `Mercs 1 Animation Tools/Netview Char Tool/*.htm` — an IK **control**
sub-family not in the shipped `.msh` dump:
`bone_ctrl_l_clavicle`, `root_ctrl_l_upperarm`, `eff_ctrl_l_clavicle`, `bone_l_clavicle1`,
`bone_l_upperarm1`, `bone_l_forearm1`, `root_l_hand1`, `root_spine_1`, plus
`bone_l_thigh/calf/foot/toe` and `bone_lower_eyelids`.

**Extra ODF model-property names** (from `update_world.bat:18` and `WorldMunge.cpp:110`) not present
in any shipped ODF: `geometrynameweapon`, `geometrynamefriendly`, `geometrynameenemy`.

**`destructible` is an ODF enum, not a bool:**
`"false"`(722) `"true"`(672) `"fence"`(119) `"small"`(80) `"gaterailed"`(64) `"pole"`(56)
`"explosive"`(18) `"indestructible"`(1).

---

## 9. How to use `mercs1_wordlist_hashed.csv`

38,052 candidates. Columns:

| column | meaning |
|---|---|
| `candidate` | the literal string |
| `source` | where it came from (see below) |
| `hash_pbl_PLAIN__use_this_for_nodes` | **join your node hashes on this** |
| `hash_pbl_star__use_this_for_classes` | the `+"*"` variant, for ECS/asset-type hashes |

`source` values: `m1_node` (observed in a Mercs 1 `.msh`), `m1_node_hpfiltered` (the same name after
`HpFilter()` — the form that actually ships), `m1_model_root` (a model's scene root = stem
candidate), `m1_locdamage` (the verbatim `RsLocationalDamage` panel table), `q1_lod` / `q2_group` /
`q2_rootstem` / `m2_gen` (generated from the recovered grammar).

---

## 10. Ranked next actions

1. **Re-run your whole unresolved set with the un-finalized hash.** If your production tool has the
   `0x2A` finalize in it, every node match you've made is suspect and every miss may be a false
   negative. This is a one-line change with potentially thousands of hits.
2. **Normalize `hp_*` by stripping trailing `[0-9_]+` before hashing.** (§1)
3. Test the four Q2 group candidates and the per-model-root stem hypothesis. (§3)
4. Test `L1/L2/L3_wheel_geometry` against a Mercs 2 wheel's 3 children. (§2)
5. Get an XSI `.scn` decoder onto `Mercs2_Skeleton_Male-MASTERFILE-07.scn`. It is the Mercs 2 rig. (§4)
6. For Q3 debris, mine the `.odf` files under `Editor/BUILD/DATA/`, not the code. (§7)
