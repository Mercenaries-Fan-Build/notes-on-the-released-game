# Prediction A — mi35hind rotor rig + universal vehicle group nodes

**Study ID: A (blind).** Author POV: Pandemic TA/rigger, XSI + ModelMunge, 2005–2008.
Hash primitive: `tools/fnv.py` `m2()` — verified: it reproduces `pristine=0x86DE6639`,
`ruin=0xB5D7712F`, `bone_rotor_blade_0=0xE6810AC0`, so the shipped Mercs 2 node hashes DO carry the
`^0x2A` finalize (the Mercs 1 "no finalize" caveat is a Mercs 1 fact only — I used `m2()` throughout).

---

## Bottom line

- **Confirmed new name→hash cracks: 0.** None of the ~40,000 structured candidates, the full 43,246-row
  Mercs 1 wordlist, or all 865,391 distinct rainbow-table names hashes to any target. The template rotor
  names and the universal group stem are genuinely stripped strings that survive in **no** recovered
  corpus. Cracking them is a GPU-exhaustive job (below), not a dictionary job.
- **Confirmed STRUCTURAL proofs (each a 2^-32 event, i.e. certain): 3.** These do not hand over the name
  strings but they lock down the *scheme*, the *suffix grammar*, and the exact GPU targets — which is the
  real blocker on this problem.
- **New witness discovered:** the **solano Hind block** (`0x342EDDD4`, same model-name hash
  `0x1CE8F54F` = `vz_veh_helicopter_mi35hind`) hand-named the rotor roots `bone_rotor` / `bone_tailrotor`,
  giving a structural homology that pins two of the target nodes' *roles* precisely.

---

## Confirmed proof 1 — the 3 universal group nodes are `STEM / STEM_pristine / STEM_ruin`

Verified by suffix-unwinding (FNV-1a is invertible; a shared unwound state is a 2^-32 proof of a shared stem):

```
SWIT   0x765CD254  = m2(STEM)            -> stem-state 0xE141A8F6
INTACT 0x255EAB53  = m2(STEM + "_pristine") -> stem-state 0xE141A8F6   (SAME)
RUIN   0x75F1F74D  = m2(STEM + "_ruin")     -> stem-state 0xE141A8F6   (SAME)
```

All three unwind to the identical FNV state `0xE141A8F6`. This is decisive and it **kills the
per-model-root hypothesis** (Mercs1 findings §3c): 172 *different* models carry the *identical*
`0x765CD254`, so the stem is ONE universal group name, not a squashed per-vehicle root.

- The stem is `>=9` chars, is not spelled by any shipped string, and is **not**: `body_geometry`,
  `chassis_geometry`, `L1_body_geometry`, `L1_chassis_geometry`, `L1_vehicle_geometry`, `vehicle_geometry`,
  `L1_geometry`, `damage_geometry`, `L1_damage_geometry`, `destructible_geometry`, `vehicledamage`,
  `vehicledestruction` (all tested this session — see verification table).
- **The exact GPU target is the stem-state `0xE141A8F6`** (a single 32-bit value; exhaustive S≤1e9 costs
  0.25 expected-false). Search `L{1,12,123,1234}_ <word> [_geometry]` and long single tokens, 6–14 chars.

**My committed best guess for STEM (unconfirmed):** `L1_body_geometry` in *spirit* (the Mercs 1
`L1_chassis_geometry`-holds-`pristine`/`damage` pattern, with `damage→ruin` and the state moved to the
group level), but since the obvious spellings are ruled out, the real string is a longer studio-specific
group name. If forced to type one: **`L1_vehicle_geometry`** — but treat as a hypothesis; it does not hash.

---

## Confirmed proof 2 — the 5 main-rotor blades are `STEM + <digit 0..4>`

Pairwise suffix-unwind of the 5 blade hashes: every pair's last-char XOR is a small value in 1..7, and
under the **digit** hypothesis all five collapse to ONE stem-state; under the letter hypothesis they do
**not**. So the blades are provably `STEM` + a single trailing decimal digit:

```
stem-state = 0xB16B92D5   (all 5 blades agree)   digits run 0..4
```

| brief node | hash | position (x,y,z) | blade index (proven) |
|---|---|---|---|
| 36 | `0x02EA1FCF` | (+3.38,+4.63,-4.73) | **0**  ← `FirstRotorBladeBoneName` points here |
| 35 | `0xE0E7ABB2` | (-3.43,+4.38,-4.63) | **1**  (currently carries the junk brute-name `Y7EzN3L7`; it is blade 1) |
| 34 | `0x62EF341D` | (-6.10,+4.38,+2.10) | **2** |
| 33 | `0x78ED1828` | (+0.17,+4.38,+6.47) | **3** |
| 32 | `0x7AE04F5B` | (+5.70,+4.63,+1.73) | **4** |

The five sit at ~72° spacing on a 6 m radius = a 5-blade main rotor (correct for the Mi-24/35 Hind).
The digit is the last char, so this is NOT the Ka-29 string `bone_rotor_blade_N` (that hashes elsewhere,
`0xE6810AC0`≠any target). The Hind template uses a *different, shorter* stem I could not recover.
**GPU target: stem-state `0xB16B92D5`.** Likely shapes: `bone_rotorblade`, `bone_blade`, `rotorblade`,
`bone_rotor` (+ glued digit) — all tested and rejected, so it is something adjacent I have not enumerated.

---

## Confirmed proof 3 (new) — solano-Hind homology fixes the rotor-root roles

Dumping the solano Hind block `0x342EDDD4` (root node = `0x1CE8F54F` = `vz_veh_helicopter_mi35hind`) shows
the rotor chain partially hand-named, over the *same* internal hashes as the base block:

```
intact(0x255EAB53)
 └─ bone_rotor (0x2C3C46E2)          ← base block uses 0xB366B8C7 here  (brief node 29)
     └─ 0xA998B636                    (brief node 30, SHARED verbatim in both blocks)
         ├─ 0x8F96690F  → 5 blades    (brief node 31 + blades 32–36, SHARED)
         └─ 0xD06B9499  → 0x4CC628FA,0x2C9F4CEC   (brief node 37 + discs 38,39, SHARED)
tailpivot(0x1D4F731C)                 (brief node 40)
 └─ 0x17664A2B                        (brief node 43)
     └─ bone_tailrotor (0x7EC75420)   ← base block uses 0x59748439 here (brief node 44)
         └─ 0x05F65F7E,0xC0657B1C     (brief nodes 45,46, SHARED)
```

Fleet-wide count of the two conventions (models sharing this rotor template):

```
main rotor root (parent of 0xA998B636):  0xB366B8C7 x12 (unnamed) | bone_rotor  x2
tail rotor node (parent of 0x05F65F7E):  0x59748439 x11 (unnamed) | bone_tailrotor x5
```

So there are exactly two authoring variants of the same rig. The **majority template** leaves the roots as
the stripped `0xB366B8C7` / `0x59748439`; a couple of bespoke blocks renamed just the top node to
`bone_rotor` / `bone_tailrotor` while keeping every child as the template's stripped hashes. This proves:

- **brief node 29 (`0xB366B8C7`) is the `bone_rotor` slot** (main-rotor root).
- **brief node 44 (`0x59748439`) is the `bone_tailrotor` slot** (tail-rotor drive node).

Their hashes differ from `m2(bone_rotor)`/`m2(bone_tailrotor)`, so the *template* spelled these two roots
differently — but the ROLE is now certain.

---

## The engine mechanism that names these parts (vocabulary for the GPU pass)

`docs/mercs2-pdb-analysis/animation-skeleton.md` §"Named vehicle/object control bones" lists the reflection
field keys the vehicle animation controllers read; their string *values* are the node names:

```
RotorHubBoneName   FirstRotorBladeBoneName   RotorBlurOnBone   RotorBlurOffBone
```

Mapping onto the confirmed structure (bbox and child geometry from `bone_census.csv`):

| brief node | census evidence | engine field it satisfies |
|---|---|---|
| 30 `0xA998B636` | bare pivot, bbox 0.03, spins under the rotor root | `RotorHubBoneName` (the hub) |
| 31 `0x8F96690F` | holds the 5 discrete blades, bbox 18 | `RotorBlurOffBone` (blades shown when NOT blurred) |
| 37 `0xD06B9499` | holds 2 huge flat disc meshes, bbox 47/42 | `RotorBlurOnBone` (motion-blur disc shown when spinning) |
| 32–36 | the blades | `FirstRotorBladeBoneName` = value points at blade 0 (node 36) |

Asset-name corroboration (from `ps3-VZ.strings.txt`): the blur disc mesh is literally `global_veh_rotorblur`,
`vz_veh_rotorblur_dm`; tail form `al_veh_helicopter_ah1z_tailblur_dm`; abbreviated `..._rotblur`. So the
blur node's authored name is almost certainly built on the token **`rotorblur`** / **`tailblur`**.

---

## Committed per-node predictions (unconfirmed — none hash-match; ranked, with reasoning)

Format: node — **top pick** / alt — reasoning. Confidence is for the exact STRING (structure/role above is proven).

### Main rotor
- **29 `0xB366B8C7`** — **`bone_rotor`** / `rotor` / `bone_mainrotor` — proven `bone_rotor` slot (proof 3);
  the template variant differs in spelling only. *Confidence: role HIGH, string LOW.*
- **30 `0xA998B636`** — **`bone_rotorhub`** / `bone_rotor_hub` / `rotorhub` — `RotorHubBoneName`; bare spin
  pivot directly under the rotor root. *string LOW.*
- **31 `0x8F96690F`** — **`bone_rotorblades`** / `bone_rotor_blades` / `bone_rotor` — `RotorBlurOffBone`;
  parents the 5 blades. *string LOW.*
- **37 `0xD06B9499`** — **`bone_rotorblur`** / `bone_rotor_blur` / `rotorblur` — `RotorBlurOnBone`; parents
  the two blur discs; asset token `rotorblur` is attested. **My single most-confident semantic pick.** *string LOW.*
- **38 `0x4CC628FA`, 39 `0x2C9F4CEC`** — **`bone_rotorblur_a` / `bone_rotorblur_b`** (or `_0`/`_1`) — the two
  motion-blur disc meshes (they do NOT share a single-char stem, so if suffixed they differ by more than one
  char, e.g. `_hi`/`_lo` or `_a`/`_b`). *string LOW.*
- **32–36 (blades)** — **`bone_rotorblade0 … bone_rotorblade4`** (glued digit) or `bone_rotor_blade0..4` —
  proven `STEM+digit`, indices as the table in proof 2; `FirstRotorBladeBoneName` = the `...0` value.
  *scheme + index HIGH, stem string LOW.*

### Tail rotor
- **40 `0x1D4F731C`** — **`bone_tailrotorhub`** / `bone_tailrotor_hub` — bare tail pivot (bbox 0.03), the tail
  analogue of node 30. *string LOW.*
- **41 `0x8EC23BD5`** — **`bone_tailrotorblades`** / `bone_tailrotor_blades` — parents the tail blade(s);
  `RotorBlurOffBone` for the tail. *string LOW.*
- **42 `0xAE7F16A4`** — **`bone_tailrotorblade0`** / `bone_tailrotorblade` — the tail blade leaf. *string LOW.*
- **43 `0x17664A2B`** — **`bone_tailrotorblur`** — parents `bone_tailrotor` in solano and the blur discs;
  `RotorBlurOnBone` for the tail. *string LOW.*
- **44 `0x59748439`** — **`bone_tailrotor`** — proven `bone_tailrotor` slot (proof 3); template spelling
  differs. *role HIGH, string LOW.*
- **45 `0x05F65F7E`, 46 `0xC0657B1C`** — **`bone_tailrotorblur_a` / `_b`** (asset token `tailblur`) — the two
  tail blur-disc meshes. *string LOW.*
- **176 `0x76943CCF`** — **`hp_fx_tailrotor`** / `hp_tailrotor` / `bone_tailrotortip` — leaf, bbox 0.03 =
  hardpoint, under the tail-blade holder, offset forward/below the tail-rotor centre; the FX cue
  `global_particle_smoke_heli_tailrotor` attaches to a tail-rotor FX point. *string LOW.*

### Universal group nodes (target C)
- **`0x765CD254`** — **STEM**, stem-state `0xE141A8F6`, `>=9` chars, an `L1_*_geometry`-style destruction
  group. Best-typed guess `L1_vehicle_geometry` (does not hash; see proof 1).
- **`0x255EAB53`** — **`STEM_pristine`** (proven).
- **`0x75F1F74D`** — **`STEM_ruin`** (proven).

---

## Verification table (every string I committed to, checked this session)

| node / target hash | string tested | m2(string) | result |
|---|---|---|---|
| 29 `0xB366B8C7` | `bone_rotor` | `0x2C3C46E2` | miss |
| 30 `0xA998B636` | `bone_rotorhub` | `0xE3841353` | miss |
| 31 `0x8F96690F` | `bone_rotorblades` | `0xA45EE47F` | miss |
| 37 `0xD06B9499` | `bone_rotorblur` | `0x4D1FDCBD` | miss |
| 38 `0x4CC628FA` | `bone_rotorblur_a` | `0xD2AD6E75` | miss |
| 39 `0x2C9F4CEC` | `bone_rotorblur_b` | `0xB0A67D2A` | miss |
| 40 `0x1D4F731C` | `bone_tailrotorhub` | `0xAD6DCFC1` | miss |
| 44 `0x59748439` | `bone_tailrotor` | `0x7EC75420` | miss |
| 45 `0x05F65F7E` | `bone_tailrotorblur_a` | `0x721621E7` | miss |
| 176 `0x76943CCF` | `hp_fx_tailrotor` | `0xADB04A9D` | miss |
| STEM `0x765CD254` | `L1_vehicle_geometry` | `0xDD4E748C` | miss |

Blade stem `0xB16B92D5` and group stem `0xE141A8F6`: no dictionary hit across ~40k structured candidates +
43,246 Mercs 1 wordlist rows + 865,391 rainbow-table names.

---

## Confirmations count

- **Confirmed new name-string cracks (name that hashes to a target): 0.**
- **Confirmed structural proofs (2^-32 each): 3** — group-node stem grammar (`STEM/_pristine/_ruin`,
  state `0xE141A8F6`); blade `STEM+digit` grammar with exact index map (state `0xB16B92D5`); solano-Hind
  role homology fixing node 29 = `bone_rotor` slot and node 44 = `bone_tailrotor` slot.

## Confidence & honest assessment

The *structure* of every target is now nailed down; the *strings* are not. This template's rotor names and
the universal destruction-group stem were stripped at export and appear in no shipped string table, no
Mercs 1 name table, and no cracked name in the rainbow table — so they cannot be dictionary-recovered, only
brute-forced. The two GPU targets to hand to an exhaustive wild search are the single 32-bit stem-states
**`0xE141A8F6`** (group, 6–14 chars, `L*_..._geometry` bias) and **`0xB16B92D5`** (blade stem, `bone_`/`rotor`
bias, likely 8–16 chars). At T=1 each, S up to ~1e9 costs <0.25 expected-false, so a hit there is trustworthy.
