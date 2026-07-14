# Naming dialect — VEHICLE / WEAPON / PROP ("systems") bones

**Scope.** The naming convention Pandemic used for everything attached to a *non-character* transform
tree: drivable vehicles (tanks, APCs, helicopters, VTOLs, planes, boats, cars, trucks, bikes), mounted
and emplaced weapons (turrets, artillery, SAM/CIWS, naval guns), and destructible props. This is the
**highest-yield dialect** because the team named it by systematic rule (functional part + axis + side +
number), so recovered names cluster into *families* and *mirror pairs* that supply the second witness a
bare 32-bit hash can never give.

**How to read this file.** Everything in §1–§2 is either **confirmed** (witnessed by shipped strings,
Lua, the exe, or the live registry — see `bone_census.md` §4) or **cracked-this-pass** (hash match + family
+ on-model corroboration, listed in §5, *pending human verification, NOT yet in the rainbow table*). The
long vocabulary lists in §2 also include **not-yet-seen** words a 2008 open-world military game must have —
those are explicitly marked and are the fuel for the next `bone_forge` runs.

The hash is `pandemic_hash_m2` — FNV-1a, every byte folded `| 0x20` (so **case-insensitive**; casing below
is cosmetic and carries no evidential weight), `^0x2A` finalize, one more prime mix. Alphabet observed in
every real name: `[a-z0-9_]`.

---

## 1. Structural grammar

A systems bone name is `<prefix>_<body>` where prefix ∈ {`bone`, `hp`} (plus bare destruction-state
words `pristine`/`ruin`). The body is built from ordered SLOTS. Every confirmed pattern:

| # | Slot order | Template | Worked examples (confirmed) |
|---|---|---|---|
| G1 | `bone` · part · **axis** | `bone_{part}_{axis}` | `bone_rudder_yaw`, `bone_propeller_roll` |
| G2 | `bone` · **axis** · part | `bone_{axis}_{part}` | `bone_yaw_radar`, `bone_pitch_radar` |
| G3 | `bone` · **axis** (bare) | `bone_{axis}` | `bone_yaw`, `bone_pitch`, `bone_rotate` |
| G4 | `bone` · part · side · **num** | `bone_{part}_{side}_{NN}` | `bone_wheel_l_01` … `bone_wheel_r_06` (12) |
| G5 | `bone` · part · **glued side** | `bone_{part}{side}` / `bone_{part}_{side}` | `bone_wheel_rl`, `bone_wheel_rr`, `bone_wheel_l02`, `bone_door_lt`, `bone_door_r`, `bone_door_rr` |
| G6 | `bone` · part · **letter** | `bone_{part}{a..e}` / `bone_{part}_{a..c}` | `bone_flaga…e`, `bone_radar_a/b/c`, `bone_antenna_a/b/c`, `bone_backa/b/c`, `bone_fronta/b/c`, `bone_head1..4` |
| G7 | `bone` · part (bare) | `bone_{part}` | `bone_frame`, `bone_flap`, `bone_tail`, `bone_chain`, `bone_chair`, `bone_wires`, `bone_left`, `bone_right`, `bone_mid` |
| G8 | `bone` · `massive` · **NxN** · letter | `bone_massive_{NxN}_{a..f}` | `bone_massive_1x1_a`, `bone_massive_2x1_f`, `bone_massive_4x1_a` (destruction grid) |
| H1 | `hp` · dest · **role/side** | `hp_{dest}_{role}` | `hp_seat_left/right/lt`, `hp_seat_driver`, `hp_seat_cannon`, `hp_dock_left/right` |
| H2 | `hp` · dest · **compound station** | `hp_seat_{station}` | `hp_seat_ciwsfl/fr/rl/rr/fm`, `hp_seat_samfm/samrr`, `hp_seat_turret_f/r` |
| H3 | `hp` · `barreltip` · **weapon** · side | `hp_barreltip_{weapon}_{L/R}` | `hp_barreltip_missile_L`, `hp_barreltip_hellfire_A..D`, `hp_barreltip_archer_a..h`, `hp_barreltip_sidewinder_L/R` |
| H4 | `hp` · `barreltip` · weapon · **rail** · letter | `hp_barreltip_hellfire_rail{a..h}` | `hp_barreltip_hellfire_raila…railah`, `railb..raild` |
| H5 | `hp` · dest · **letter** | `hp_{dest}_{a..c}` | `hp_barrel_a`, `hp_barreltip_a/b/c` |
| H6 | `hp` · `fx` · **effect** | `hp_fx_{effect}` | `hp_fx_light`, `hp_fx_cigar`, `hp_fx_parachute` |
| H7 | `hp` · dest (bare) | `hp_{dest}` | `hp_barrel`, `hp_shelleject`, `hp_CenterOfMass`, `hp_attach`, `hp_health`, `hp_metal` |
| H8 | `hp` · **mission** · role | `hp_{alNN}_{player/starter}` | `hp_al01_player`, `hp_ch02_starter`, `hp_gr001_player` (gameplay spawn/starter points — enumerated per-mission, not per-model) |

### Notes on the rules

- **Axis words are the tell of a functional (animated) mount.** `yaw`/`pitch`/`roll` appear *either
  side* of the part (G1 vs G2) — the team was not consistent, so both orders must be tried
  (`bone_rudder_yaw` but `bone_yaw_radar`). A bone carrying an axis word is almost always animation-driven.
- **Side is highly polymorphic.** Single-letter `l`/`r`; two-letter *position* codes `fl fr ml mr rl rr`
  (front/mid/rear × left/right) and `lt`/`rt`; words `left`/`right`; naval `port`/`starboard`; vertical
  `top`/`bottom`; radial `inner`/`outer`. The wheel family uses BOTH the numbered form (`_l_01`) and the
  glued position form (`rl`,`rr`) on different vehicles.
- **Number suffixes**: bare `1..9`/`10..12`; zero-padded `01..09`; letters `a..h`; and the destruction
  grid's `NxN` (`1x1 2x1 4x1 …`). Glued (`l02`, `head4`, `flaga`) vs underscore-separated (`l_01`,
  `radar_a`) both occur — always try both (bone_forge auto-enumerates the separators).
- **`hp_` = a snap/attach point, not a deform bone.** Destinations are nouns for *what docks there*:
  `seat` (a rider), `dock` (a vehicle/object), `barrel`/`barreltip`/`muzzle`/`shelleject` (weapon muzzle
  geometry & casing ejection), `fx` (a particle emitter). `hp_barreltip_<weapon>` embeds the **weapon
  type name** as an infix — this is where the weapon vocabulary lives.
- **Compound station codes (H2)** glue role+position with no separator: `ciws`+`fl` = `ciwsfl`,
  `sam`+`rr` = `samrr`. These are the destroyer's gun stations. The leaf words (`cannon`, `ciws`, `sam`,
  `driver`) are **plausible-unconfirmed** (see `bone_census.md` §5) — the *family* `hp_seat_*` is proven,
  the specific station spellings are hash-only guesses awaiting a second witness.

---

## 2. Vocabulary by slot — confirmed + the gaps a 2008 mil-sandbox must fill

Legend: **✓** confirmed (real witness); **◆** cracked this pass (§5, pending verify); **·** predicted /
not-yet-seen (feed to bone_forge). Every predicted word is spelled in the observed `[a-z0-9_]` alphabet.

### 2.1 AXIS / MOTION words (slot: axis)
`✓yaw ✓pitch ✓roll ✓rotate` · `·elev ·elevation ·elevate ·recoil ·spin ·turn ·traverse ·open ·close
·raise ·lower ·deploy ·extend ·retract ·aim ·swing ·tilt ·pivot ·steer`
> These are the biggest near-term gap: only 4 of ~20 plausible axis words are witnessed, yet every
> animated gun/rotor/gear/hatch needs one. `recoil`, `traverse`, `elevation`, `open/close`, `retract`
> (landing gear) are the highest-value untested axes.

### 2.2 HELICOPTERS / VTOLs (slot: part)
`◆rotor ◆tailrotor` · `·mainrotor ·rotorhub ·rotorblade ·rotormast ·blade ·mast ·swashplate ·swash
·skid ·landinggear ·gear ·tailboom ·boom ·stabilizer ·stab ·winch ·hook ·hoist ·cable ·door ·ramp
·minigun ·rocketpod ·pod ·pylon ·hardpoint ·intake ·exhaust ·turbine ·collective ·antitorque`
> `rotor` + `tailrotor` were cracked this pass (both high-anim shared rigs). The blade/hub/mast/swashplate
> mechanism, the retractable skids/gear, and the door-gun/winch set are entirely unnamed.

### 2.3 PLANES / JETS (slot: part)
`✓flap ✓tail ✓wing?` · `·aileron ·rudder ·elevator ·elevon ·canard ·slat ·spoiler ·airbrake ·canopy
·cockpit ·landinggear ·gear ·wheel ·nosewheel ·strut ·prop ·propeller ·spinner ·engine ·intake
·afterburner ·nozzle ·nacelle ·wingtip ·fin ·stabilizer ·bomb ·bombbay ·missile ·rail ·pylon ·hook ·flaperon`
> `flap` and `tail` confirmed; `aileron`/`rudder`/`elevator`/`canopy`/`gear`/`afterburner`/`bombbay`
> untested. Control surfaces almost certainly carry an axis word (aileron_roll, elevator_pitch).

### 2.4 TANKS / APCs (slot: part)
`◆pitch_barrel ◆roll_barrel ◆yaw_turret ◆yaw_mg ◆pitch_mg ◆suspension ◆hatch` · `·turret ·cannon ·barrel
·muzzle ·mantlet ·gun ·coax ·mg ·hmg ·breech ·recoil ·tread ·track ·wheel ·roadwheel ·sprocket ·idler
·returnroller ·torsionbar ·swingarm ·suspension ·skirt ·antenna ·smoke ·smokelauncher ·smokegrenade
·commander ·driver ·loader ·spotlight ·searchlight ·rangefinder ·mg_yaw ·mg_pitch ·cupola`
> Turret & barrel elevation cracked (`bone_yaw_turret`, `bone_pitch_barrel`, `bone_roll_barrel`) plus a
> coax MG (`bone_yaw_mg`/`bone_pitch_mg`) and `bone_suspension`/`bone_hatch_fl`. The **track/roadwheel/
> sprocket/idler** running-gear chain and **smoke launchers** are unnamed — high value (every tank has them).

### 2.5 BOATS / SHIPS (slot: part / hp station)
`✓propeller ✓rudder ✓frame` · `◆anchor ◆dish` · `·prop ·screw ·shaft ·screwshaft ·mast ·radar ·dish
·antenna ·bridge ·conning ·deckgun ·cannon ·turret ·ciws ·sam ·samlauncher ·launcher ·missile ·davit
·crane ·hull ·keel ·wake ·hydrofoil ·outrigger ·gunstation ·flak`
> `bone_propeller_roll`/`bone_rudder_yaw`/`bone_frame` confirmed on the destroyer; `bone_anchor` and
> `bone_dish` (radar dish) cracked this pass. Destroyer gun-station **hardpoints** `hp_seat_{cannon,sam,
> ciws*,driver}` are named-but-unconfirmed (family real, leaf words guessed).

### 2.6 CARS / TRUCKS (slot: part)
`✓wheel ✓door ✓chain ◆trunk ◆suspension` · `·tire ·rim ·hubcap ·axle ·halfshaft ·steering ·steeringwheel
·wheel_steer ·hood ·bonnet ·tailgate ·bumper ·fender ·exhaust ·muffler ·mirror ·sidemirror ·wiper
·antenna ·bed ·flatbed ·plow ·winch ·trailer ·hitch ·crane ·boom ·outrigger ·spare ·spoiler ·convertible ·roof`
> Wheels & doors solidly named (incl. new `fl/fr/ml/mr`, §5); `bone_trunk` cracked. The **steering /
> steeringwheel**, exhaust, mirror, wiper, and utility (plow/winch/crane/flatbed/trailer/hitch) set is
> untested — trucks with plows and tow-cranes exist in the game.

### 2.7 MOTORCYCLES (slot: part)
`·fork ·frontfork ·handlebar ·bars ·kickstand ·stand ·pedal ·chain ·sprocket ·exhaust ·brake ·shock
·swingarm ·sidecar ·wheel_f ·wheel_r`
> Entirely unnamed. `chain`/`sprocket`/`fork`/`handlebar`/`kickstand` are the obvious targets; the wheel
> family (G4/G5) already covers the two wheels.

### 2.8 STATIONARY WEAPONS / EMPLACEMENTS (slot: part / hp)
`✓bone_yaw ✓bone_pitch (on towtripod/stinger)` · `◆hp_shelleject_a..d` · `·barrel ·breech ·recoil ·bolt
·slide ·ejector ·shelleject ·casing ·brass ·feed ·ammobelt ·belt ·magazine ·mag ·drum ·trigger ·hammer
·muzzle ·flashhider ·tripod ·mount ·pintle ·elevation ·traverse ·sight ·scope ·tube ·rail ·launcher ·dish
·sensor ·radar ·antenna ·seeker`
> `bone_radar_a/b/c` = the Stinger seeker (confirmed); `bone_yaw` = the TOW tripod (confirmed). The
> **shell-ejection family `hp_shelleject_a..d`** cracked this pass. Belt-feed / breech / bolt mechanism
> unnamed.

### 2.9 HARDPOINT destinations (slot: dest, prefix `hp`)
`✓seat ✓dock ✓barrel ✓barreltip ✓shelleject ✓attach ✓fx ✓CenterOfMass ✓health ✓metal ✓asphalt ✓civilian
✓menu_camera ✓playerA ✓maverick ✓smg ✓pistol ✓grenades ✓starter` · `◆seat_gunner ◆dock_gunner ◆barreltip_d
◆shelleject_a..d` · `·muzzle ·exhaust ·light ·camera ·wheel ·snap ·mount ·winch ·hook ·tow ·spawn ·enter
·ladder ·gun ·turret ·cargo ·eject ·casing ·jetexhaust`

### 2.10 hp SEAT/STATION roles (slot: role — glued or `_`-joined onto seat/dock)
`✓left ✓right ✓lt ✓driver ✓cannon ✓sam ✓ciws{fl,fr,rl,rr,fm} ✓samfm ✓samrr ✓turret_f ✓turret_r` ·
`◆gunner` · `·pilot ·copilot ·commander ·passenger ·rider ·front ·rear ·mid ·cargo ·player ·mg ·coax`

### 2.11 hp WEAPON infixes (slot: weapon, inside `hp_barreltip_<weapon>_<side>`)
`✓archer(a..h) ✓hellfire(A..D + rail a..h) ✓missile(L/R, la/lb/ra/rb, missileL_a/b) ✓sidewinder(L/R)
✓rocket(L/R) ✓smlrokt(l/r) ✓xrocket(L/R) ✓rcketlg(L/R)` · `·tow ·maverick ·hydra ·stinger ·harpoon ·agm
·aim ·gun ·cannon ·bomb ·napalm ·flare ·chaff ·gau ·minigun ·rocketpod`
> The weapon-name infix is a rich seam: `archer`, `hellfire`, `sidewinder` are all real weapon model names.
> Untested but likely: `tow`, `maverick` (both appear as bones/hardpoints elsewhere: `hp_maverick`), `hydra`.

### 2.12 hp FX effects (slot: effect, inside `hp_fx_<effect>`)
`✓light ✓cigar ✓parachute` · `·jetexhaust ·exhaust ·smoke ·flare ·fire ·muzzleflash ·dust ·wake ·spray
·flame ·backfire ·steam`

### 2.13 DESTRUCTION grid (slot: NxN, prefix `bone_massive`)
`✓1x1 ✓1x2 ✓2x1 ✓4x1` (+ letter suffix `a..f`) · `·2x2 ·3x3 ·4x4 ·2x4 ·4x2 ·3x1 ·1x3 ·6x6 ·8x8` ·
state words `✓pristine ✓ruin` · `·grid ·intact ·broken ·rubble ·debris ·chunk ·fragment ·piece ·shard`
> Only the L-shaped and strip tiles (`1x1 1x2 2x1 4x1`) are witnessed; square tiles `2x2`/`4x4` etc. are
> predicted. The 126 unnamed SWIT break-piece nodes (and 291 unnamed destroyer rows) live here.

### 2.14 SIDE / POSITION (slot: side)
`✓l ✓r ✓left ✓right ✓lt ✓rr ✓rl ✓f? ` + compound `✓ciwsfl/fr/rl/rr/fm ✓samfm/rr ✓turret_f/r` ·
`◆fl ◆fr ◆ml ◆mr` · `·front ·rear ·fm ·rm ·port ·starboard ·top ·bottom ·inner ·outer ·fore ·aft ·mid ·center`

---

## 3. bone_forge config (ready to run)

Two configs proven this pass live at the paths below; the merged block is reproduced here. Run with
`python tools/bone_forge.py --config <file> --targets all --gpu` (add `--include-named` to prove the
vocab regenerates the known families).

```json
{
  "arrays": {
    "prefix": ["bone"],
    "part": [
      "turret","cannon","barrel","gun","mantlet","hatch","coax","mg","muzzle","breech","recoil",
      "rotor","mainrotor","tailrotor","rotorblade","rotorhub","blade","mast","swashplate","skid","tailboom","stabilizer","winch","hook","ramp","minigun","rocketpod",
      "aileron","flap","rudder","elevator","canopy","prop","propeller","engine","intake","afterburner","wing","tail","pylon","gear","landinggear","nosewheel",
      "tread","track","sprocket","idler","roadwheel","wheel","suspension","torsionbar","swingarm","antenna","radar","dish","smoke","smokelauncher",
      "mirror","steering","steeringwheel","door","hood","trunk","tailgate","bumper","axle","exhaust","wiper","bed","plow","flatbed","trailer","hitch","crane",
      "fork","handlebar","kickstand","pedal","chain","screw","shaft","hull","bridge","davit","anchor","keel",
      "sam","ciws","launcher","rail","tube","sensor","seeker","feed","ammobelt","bolt","slide","ejector","magazine","drum","tripod","mount","flag","frame","wire","wires","spotlight","searchlight"
    ],
    "axis": ["yaw","pitch","roll","elev","elevation","elevate","recoil","spin","turn","traverse","rotate","open","close","raise","lower","deploy","extend","retract","aim","swing","tilt","pivot"],
    "side": ["l","r","left","right","f","front","rear","fl","fr","rl","rr","fm","rm","ml","mr","port","starboard","lt","rt","top","bottom","inner","outer","fore","aft"],
    "num": ["0","1","2","3","4","5","6","7","8","9","10","11","12","00","01","02","03","04","05","06","07","08","09","a","b","c","d","e","f","g","h"]
  },
  "slot_orders": [
    ["prefix","part","axis"],
    ["prefix","axis","part"],
    ["prefix","part","side","num"],
    ["prefix","part","num"],
    ["prefix","part","side"],
    ["prefix","part","axis","side"],
    ["prefix","part"]
  ]
}
```

Hardpoint companion config (`hp_stations.json`): prefix `["hp"]`, arrays `dest`/`role`/`side`/`fx` and slot
orders `[hp,dest,role]`, `[hp,dest,role,side]`, `[hp,dest,side]`, `[hp,dest]`, `[hp,fx]` — see §2.9–2.12 for
the word lists. Both files are in the session scratchpad.

---

## 4. Prioritized family shortlist (highest hit-probability, run these next)

Ranked by (a) coherent family/mirror structure, (b) universality across the fleet, (c) untested-ness:

1. **Tank running gear** — `bone_track_{l/r}`, `bone_tread_{l/r}`, `bone_roadwheel_{l/r}_{01..08}`,
   `bone_sprocket_{l/r}`, `bone_idler_{l/r}`. Every tank/APC has these; the wheel family already proves
   the `_{side}_{NN}` convention. **Highest expected yield.**
2. **Helicopter rotor mechanism** — `bone_rotorhub`, `bone_mainrotor`, `bone_blade_{a..f}`,
   `bone_swashplate`, `bone_mast_roll/pitch`, `bone_skid_{l/r}`. (`rotor`/`tailrotor` already hit.)
3. **Gun elevation/traverse axes** — extend the barrel/turret/mg axis hits: `bone_barrel_pitch`,
   `bone_turret_yaw`, `bone_gun_recoil`, `bone_gun_pitch`, `bone_cannon_recoil`, `bone_mantlet_pitch`.
   (Both `bone_{part}_{axis}` and `bone_{axis}_{part}` orders — the game uses both.)
4. **Landing gear + control surfaces (planes/heli)** — `bone_gear_{l/r}_retract`, `bone_aileron_{l/r}`,
   `bone_elevator_{l/r}`, `bone_rudder_yaw` (rudder confirmed on boats — try on planes), `bone_flap_{l/r}`.
5. **Smoke launchers / secondary weapons (tanks)** — `bone_smoke_{l/r}_{a..f}`, `bone_smokelauncher_*`.
6. **hp seat/station roles** — `hp_seat_pilot`, `hp_seat_copilot`, `hp_seat_passenger`, `hp_seat_commander`,
   `hp_dock_{pilot/passenger}`. (`hp_seat_gunner`/`hp_dock_gunner` already hit.)
7. **hp_barreltip weapon infixes** — `hp_barreltip_tow_{L/R}`, `hp_barreltip_maverick_*`,
   `hp_barreltip_hydra_*`, `hp_barreltip_stinger_*` (weapon-model names as infix).
8. **Destruction square tiles** — `bone_massive_2x2_{a..f}`, `bone_massive_4x4_*`, `bone_massive_3x3_*`.
9. **Truck utility** — `bone_steering`, `bone_steeringwheel`, `bone_plow`, `bone_winch`, `bone_crane_yaw`,
   `bone_flatbed`, `bone_hitch`.
10. **Motorcycle** — `bone_fork`, `bone_handlebar`, `bone_kickstand`, `bone_sprocket` (chain confirmed).

---

## 5. Cracked this pass — candidate hits (PENDING HUMAN VERIFICATION, not in rainbow table)

Three GPU runs over all 939 unnamed census hashes. **26 total hits at a combined expected-false ≈ 0.26**
(a ~100:1 signal-to-noise ratio — chance alone predicts <1 hit). A `--include-named` control confirmed the
same vocabulary regenerates ~40 known families (`bone_wheel_*`, `bone_door_*`, `bone_radar_*`,
`bone_yaw_radar`, `bone_flag*`, …) exactly, proving the templates encode the real convention.

### TIER 1 — family / mirror corroborated (near-certain)

| candidate | hash | evidence (2nd witness) | census |
|---|---|---|---|
| `bone_wheel_fl` | `0x35415D90` | completes the wheel-**position** set with confirmed `rl`/`rr` | anim=3 |
| `bone_wheel_fr` | `0x94F6BFFE` | ″ (front-right, mirror of fl) | anim=3 |
| `bone_wheel_ml` | `0x917C2C11` | ″ (mid-left) | anim=3 |
| `bone_wheel_mr` | `0x3945878F` | ″ (mid-right, mirror of ml) — 4-member family, all anim=3 | anim=3 |
| `hp_shelleject_a` | `0x3DCEBDE9` | 4-member lettered family extending confirmed `hp_shelleject` | m=1 |
| `hp_shelleject_b` | `0x1BC7CC9E` | ″ | m=1 |
| `hp_shelleject_c` | `0x3DCA40BB` | ″ | m=1 |
| `hp_shelleject_d` | `0xBBD64008` | ″ (clean a/b/c/d run) | m=1 |
| `bone_door_fl` | `0x63484DB7` | mirror pair, extends confirmed `bone_door_lt/r/rr`; high-anim | anim=23 |
| `bone_door_fr` | `0x7B07CC29` | ″ (mirror of fl); very high-anim (busy vehicle rig) | anim=42 |
| `hp_seat_gunner` | `0x1B8194A7` | pairs with confirmed `hp_seat_driver`; obvious mil role | m=5 |
| `hp_dock_gunner` | `0x8834CCCD` | same `gunner` role on the `hp_dock_*` family | m=5 |
| `bone_pitch_barrel` | `0xCC0E3F83` | gun-elevation axis (G2), sibling of `bone_yaw_radar`; anim | anim=8 |
| `bone_roll_barrel` | `0x4AA8633E` | same barrel mount, roll axis | m=2 |
| `bone_yaw_turret` | `0x770765E4` | turret traverse (G2); anim | anim=8, m=1 |
| `bone_yaw_mg` | `0xAB8D5192` | coax/pintle MG traverse — mirror-axis pair with pitch_mg | anim=1 |
| `bone_pitch_mg` | `0xE5F44CCF` | MG elevation — pairs with yaw_mg | anim=1 |
| `bone_rotor` | `0x2C3C46E2` | helicopter main rotor; **high-anim shared rig** | anim=15 |
| `bone_tailrotor` | `0x7EC75420` | helicopter tail rotor; **high-anim shared rig** | anim=13 |
| `bone_chain1` | `0xC4593076` | numbered sibling of confirmed `bone_chain` | m=2 |
| `hp_barreltip_d` | `0x374FFDAA` | extends confirmed `hp_barreltip_a/b/c` | m=1 |

### TIER 2 — sensible lone hit on a plausible model (likely, weaker)

| candidate | hash | note | census |
|---|---|---|---|
| `bone_hatch_fl` | `0x9BAA1A01` | vehicle hatch, `fl` position (matches door family) | anim=3 |
| `bone_suspension` | `0x2E776E19` | vehicle suspension; anim | anim=8 |
| `bone_dish` | `0xA3C6543A` | radar dish (pairs with `bone_radar_a/b/c`) | m=2 |
| `bone_anchor` | `0xAF88ED71` | boat anchor | m=1 |
| `bone_trunk` | `0x86B3D504` | car trunk | m=1 |

**Verification protocol for the human:** for each candidate, dump the owning model's HIER
(`mercs2_probe bone-census` / the destroyer CSVs) and confirm (1) the bone sits on a model of the right
class (a `bone_rotor` on a helicopter, `bone_anchor` on a boat), and (2) mirror partners have mirrored
translations. Tier-1 family members that co-occur on the same model are the safest to merge. Do **not**
merge Tier-2 lone hits on hash alone.

---

## 6. What remains unnamed after this pass

- **~113 anim-driven unnamed bones** — vehicle rig joints. The very-high-anim, zero-mesh nodes
  (`0x19355372` anim=80, `0x962C4871` anim=44, `0x7B07CC29`→now `door_fr` anim=42, `0xAB34F409` anim=25)
  are shared vehicle rigs with no example model to anchor a class guess — attack them with the §4 axis and
  running-gear families, which are class-agnostic.
- **~126 SWIT + ~291 destroyer break-piece nodes** — destruction geometry (§2.13). Mostly bare positional
  pieces; likely un-nameable by convention (they may be procedurally numbered, no string in any artifact).
- **The destroyer station leaf-words** (`cannon`/`ciws`/`sam`/`driver`) remain plausible-unconfirmed; a
  live registry display-name or an unstripped dev build is the only path to promote them past guess.
