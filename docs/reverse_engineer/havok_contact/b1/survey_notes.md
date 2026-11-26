# b1 capture survey: every hkpRigidBody in two pc-v10 captures

Grades: P = PROVEN (read this run, file/command named), I = INFERRED, S = SPECULATIVE.
Scripts (all in this folder): `survey.py <dmp> <tag> [world]`, `cluster.py`, `analyze.py`, `massprops.py`,
`wrapcmp.py`, `wraptree.py`, `wrapmass.py`, `misc.py`, `layeruse.py`, `typeinfo.py` (exe hkTypeInfo →
`vtable_names.tsv`), `rtti.py`, `vtwriters.py`. Outputs: `bodies_{newgame,winch}.tsv`, `shapes_*.txt`,
`raw_*.json`, `layers_*.txt`, `clusters_*.txt`, `an_*.txt`, `massprops_*.txt`, `wraptree.txt`, `wrapmass.txt`,
`misc.txt`, `layeruse.txt`, `sphere.txt`.

## 1. Method and counts (P)
- Scan every 4-aligned word == 0x00B58A2C (hkpRigidBody vtable; exe hkTypeInfo at 0xE77FCC names it).
  Valid = world(+0x08) == 0x20007800 (vtable 0x00B58F9C = hkpWorld by hkTypeInfo), +0x18 == body+0xE0,
  ownerOffset +0x20 == −16.
- newgame: 116 candidates, **86 bodies**; 27 rejects have world=0 but valid motion/ownerOffset (bodies not in
  a world), 3 are code/data hits. winch (same world address 0x20007800): 1869 candidates, **1824 bodies**,
  42 world-less, 3 code/data.
- Vtable names: `vtable_names.tsv` (59 hkTypeInfo records {name, finish, cleanup, vtable} found in the exe).
  Motions by RTTI: 0xB5921C hkpBoxMotion, 0xB592EC hkpFixedRigidMotion, 0xB58A4C hkpSphereMotion.
  Pandemic classes (owner objects, listeners) have **no RTTI**; they are named below only by vtable + ctor site.

## 2. Owner classes (body +0x0C userData → object with vtable V). Ctor/dtor vtable-write sites from `vtwriters.txt`
| V | write sites | bodies (newgame / winch) | what the capture shows (I/S naming) |
|---|---|---|---|
| 0x00BA9368 | 0x435DB6, 0x435E15 | 65 / 1677 | static props & buildings: FIXED; 2 winch bodies BOX (1d95c600, 1e2ec000, mass ≈4.7–4.8 t, = CC mass) |
| 0x00BAA0A0 | 0x602E24, 0x66CE9C | 14 / 12 | terrain cells: FIXED, layer 1, friction 1.0, one MOPP child, cell origin e.g. (−1800,0,2200) |
| 0x00BA9C28 | 0x43CC0A | 4 / 94 | dynamic props: BOX/SPHERE (or FIXED until woken, newgame), layers 18/13/12/14, maxLin 57.41 |
| 0x00BA9200 | 0x435495, 0x4354ED | 1 / 2 | boats (mass 8000, collision listener vt 0xBAA310, action vt 0xBA9340) |
| 0x00BA94A0 | 0x436277, 0x4362ED | 0 / 3 | wheeled vehicles (S): friction 0, layer 8, inertia round numbers (§5) |
| 0x00BA9720 | 0x43930B, 0x43935A | 0 / 2 | 26-child aircraft (S: helicopter; layer 8 + 24) mass 8000 |
| 0x00BAA1D8 | 0x442887, 0x442AF6 | 0 / 32 | winch rope (31 capsules, mass 5) + hook (1 convex, mass 320); share the heli's system group 0x20BD (S: the rope) |
| none | — | 2 / 2 | 1ffd7e00 = world fixedRigidBody (world+0x24, P); 1ffd7c00 same settings, owner unknown |
No body has a human/ragdoll-like owner: **no character rigid bodies exist in either capture** (P for the census;
whether characters use phantoms instead is NOT DETERMINED).

## 3. Clusters (motion, quality, body layer, group≠0, root shape, #children) — full lists in `clusters_*.txt`
newgame: FIXED/q1/L0/Pg-list/2 ch ×34 (static, child layers 4+5); FIXED/q1/L3/Pg-list/1 ×31 (static); FIXED/q1/L1/
Pg-list/1 ×14 (terrain); FIXED/q1/L13/Pg-list/1 ×4 (dynamic-prop class, fixed, one shared MOPP 21a674a0 under 4
separate lists); BOX/q3/L0/Pg-list/13 ×1 (boat); 2 null-shape world bodies.
winch (top): FIXED/L3/convex (no list) ×710; FIXED/L3/Pg-list/1 ×371; FIXED/L19/convex ×196; FIXED/L0/Pg-list/2 ×147;
FIXED/L0/**null shape** ×124 (+1); FIXED/L3/ConvexTranslate ×82; BOX/q3/L18/convex ×51 (props); SPHERE/q4/L27/capsule
×31 (rope); SPHERE/q3/L18/convex ×16; FIXED/L1/list ×15 (12 terrain + 3 static); BOX/q3/L18/list-2 ×10; boats
BOX/L0/list-5 ×2 (1df9d000, 1e198e00); cars BOX/L8/list ×3; aircraft BOX/L8/list-26 ×2.
- Shape classes seen (whole trees): Pandemic list 0xBA8C44 (never Havok's 0xB58458 list), hkpConvexVerticesShape,
  hkpConvexTranslateShape 0xB584B4 (87 as body root, 20 as list child), hkpConvexTransformShape 0xB58594 (2, list
  children), hkpBoxShape 0xB56F44 (109, **always** under a translate/transform wrapper), hkpCapsuleShape, MOPP
  0xB6C588 → WpMeshShape16 0xBD23E0, null. No sphere, cylinder or hkpTransformShape (P, both captures).
- The wrapper carries the leaf AA node's transform: 105/107 translate shapes have translation == their child's
  AA translation (+4..+0xC) with identity quaternion; the 2 ConvexTransform shapes (1dfa2be0, 1dfa2c40) have
  rotation = the AA quaternion (0.07063,0,0,0.9975) and translation = AA translation; 2 translate shapes
  (1c8ddc40, 1c8ddc10) differ from their own node's translation (composition with ancestors, I). `xlate_check.txt`.
- Every Pandemic list (84 + 598) has enabledChildren +0x50..+0x6F all 0xFFFFFFFF (P, `enabled_check.txt`).
  +0x70..+0x9F of the 0xA0 object: byte +0x70 = 0 always; other words vary (floats on vehicles, e.g. car
  +0x78 = 2.558, +0x8C = 2.733; garbage-like on some statics) — meaning NOT DETERMINED.
- One shape object can serve many bodies (winch: one convex shared by up to 53 bodies; no Pg list is shared):
  instances of one model share their leaf shapes (refcounted), each body gets its own list (P, `an_winch.txt`).

## 4. Filter infos (P unless marked)
- Subsystem and subSystemDontCollideWith bits are **0 on every body and every child** in both captures (`layeruse.txt`).
- System group: one per owner object, odd numbers (952/953 groups odd). The owner holds it: owner+0x14 ==
  (group<<16)|1 and owner+0x18 == group+1 in 1780/1822 bodies; exceptions are the rope (owner group 0x20F7,
  bodies carry the heli's 0x20BD) and 5 dynamic props with group 0 (filter 0x00000012).
- Body vs children: children always carry the body's group; body layer == the children's layer when all
  children share one layer, else 0 (newgame 84/84; winch 596/598). Exceptions: the 2 aircraft bodies (children
  layers 8 and 24, body layer 8).
- Layer use by class (`layeruse.txt`): terrain 1; statics 3 (single), 4+5 (two-part: MOPP 4 + hull 5 or
  MOPP+MOPP), 2, 19, 30, 7, 0; dynamic props 18 (also 12, 13, 14); boat newgame 28 (whole hull) + 29 (11 detail
  hulls + MOPP); boat winch 24 + 28 + 29 + 8 ×2; cars 8; aircraft 8 + 24; rope/hook 27.
- Layer table (filter 0x1FFFF700, vt 0x00B6CB7C hkpGroupFilter, type 2, nextFreeSystemGroup 0): **identical in both
  captures** (`cmp layers_newgame.txt layers_winch.txt` → rc 0), symmetric (0 asymmetric pairs). Row b lists the
  layers a with table[b]&(1<<a): see `layers_newgame.txt`. Notable: 0 and 23 collide with all (23 not with 24);
  24 only with 0; 30/31 only with 0, 23; 4 and 7 only with {0,23,27,28}; 14/17 only {0,23,27}; 1 not with 1.

## 5. Mass properties vs the PHY2 wrapper (P; `massprops_winch.txt`, `wrapmass.txt`, `sphere.txt`)
- Fixed bodies: invInertiaAndMass = 0, comLocal 0, objectRadius = bound radius.
- Non-fixed bodies with an AA→CC chain (103; 79 match exactly): **invInertia[i] = 0.9375 / (I_cc[i][i] · m / M_cc)**
  to 6–7 digits on all three axes, where I_cc (3×3, off-diagonals dropped) and M_cc come from the wrapper CC record of
  the nearest ancestor AA node and m is the body mass (≠ M_cc in 97/103: e.g. props 200 kg vs M_cc 812/1401/424,
  boat 8000 vs 60791.5). Newgame boat: 0.937500/0.937500/0.937500.
- Sphere-inertia bodies (16): all three components = 0.9375 / max_i(I_cc[i][i]·m/M_cc) (1d2a1000: 44.38285 = max).
- 4 bodies (e.g. 1e2d6a00, mass 50): x,y follow the rule, z inertia = 1/15 of the largest (0.11526 = 1.72889/15);
  a minimum-inertia clamp (I).
- Wheeled vehicles (0xBA94A0) ignore the CC: inertia = (4500, 5500, 1250) for 1d959800 and (28000, 4000, 12000)
  for 1e560000 — round numbers, so set from data (source NOT DETERMINED). Hook 1d9b7200: 1329.51 isotropic, no rule found.
- comLocal: = CC com for props and aircraft; = **list aabbCenter** for both boat classes (newgame (0,0.82666,−0.0265),
  winch (0,0.081013,−0.0077028)); cars: neither (NOT DETERMINED).

## 6. Other body fields (P, both captures)
| field | fixed (statics, terrain) | dynamic props | boats / cars / aircraft | rope (capsule) / hook |
|---|---|---|---|---|
| quality +0x2A | 1 | 3 | 3 | 4 / 4 |
| allowedPenetrationDepth | FLT_MAX | 0.1 (77), 0.0859, 0.0475, 0.0293, 0.0327, 0.066 | 0.1 | 0.012 / 0.0779 |
| friction / restitution / response | 0.3 / 0 / 1 (terrain 1.0) | 1.0 (L18) or 0.3 / 0 | 0.3 boat/air, **0 cars** / 0 | 0 / 0.4 ; 0.3 / 0 |
| deactivationClass | 1 | 2 | 2 | 2 |
| maxLin / maxAng (hkUFloat8) | 136.2 / 9.551 | 57.41 / 9.551 | 136.2 / 9.551 | 202.8 / 202.8 ; 136.2/9.551 |
| lin / ang damping | 0 / 0.8 | 0 / 0.8 | 0 / 0.8 | 0.3/0.3 ; 0.99/0.99 |
| processContactCallbackDelay | 65535 | 65535 | 0 | 65535 |
pccDelay = 0 exactly on the bodies that have a collision listener (newgame: the boat; winch: 207 = 200 FIXED +
7 BOX), 65535 otherwise. World fixed bodies: friction 0.5, restitution 0.4, maxLin/Ang 202.8, angDamp 0.05 (Havok defaults, I).
124 winch FIXED bodies of the static class have **no shape** (shape 0, objectRadius 1, no constraints, in an island).

## 7. Properties, listeners, actions (P)
- Every owned body has property key **0x2001** whose value is a pointer to a per-body link object: vt 0x00BA8CB4 at
  +0, second vtable 0x00BA8CC4 at +4, the body pointer at +0x34 and +0x38. The same object is the body's activation
  listener (+0) and entity listener (+4) in extendedListeners. The owner keeps an array of them at owner+0x4C
  (ptr, count +0x50, cap +0x54): count 1 for the boat (element == the property value), 19 for a 19-body building,
  32 for the rope owner.
- Extra keys on some bodies: 0x2003 = float 20000.0, 0x2008 = 0.02, 0x2009 = 7.0 (stored in the low word).
- Actions: boat 0x00BA9340; dynamic props 0x00BAA4EC; cars 0x00BAA4EC + 0x00BAA360; aircraft 0x00BA9858 +
  0x00BAA4EC (+ 0x00B59994 = hkpConstraintChainInstanceAction on 1ed4ce00); hook 0x00B59994.
- Second entity listener on vehicles: boat 0xBAA324 (from listener 0xBAA310 object +4), car 0xBAA34C, aircraft 0xBAA3EC,
  terrain 1e45c800 0xBA8EF4.

## 8. One instance → how many bodies (P)
- Most owners have 1 body. Buildings: one owner, one system group, up to 19 FIXED bodies (13 lists + 6 convex),
  e.g. group 8099 owner 1c852d60. Statics are separate fixed bodies per owner; no merged static body was seen.

## 9. Winch capture: contact managers (P, `misc.txt`)
Agent-entry layout seen: byte0 2, byte1 agent type (9 or 8), byte3 0x80, **contact mgr at +0x08**, collidables at
+0x10/+0x14. All four managers (vt 0x00B589D4 hkpSimpleConstraintContactMgr) pair a dynamic body with the terrain cell
body 1e45c800 (owner 0xBAA0A0, cell origin (2600,0,−1000), filter 0x19ED0001):
| mgr | body | owner | children / mass |
|---|---|---|---|
| 1c8a6c80 | 1df9d000 | boat 0xBA9200 | 5 children (layers 24, 29, 28, 8, 8), 8000 kg — the "boat-class body with 5 children" |
| 1c8aa800 | 1d995600 | dynamic prop 0xBA9C28 | ConvexTranslate, 20000 kg, layer 13 |
| 1c8acf00 | 1e560000 | car 0xBA94A0 | 11 children layer 8, 4000 kg, friction 0 |
| 1c9a1a00 | 1e381e00 | dynamic prop 0xBA9C28 | list of 2 (layers 12, 14), 6000 kg |

## 10. Boat hull userData vs PHY2 trailing wrapper (P; `wrapcmp.txt`, `wraptree.txt`, `wrapmass.txt`)
- Model 0xB1EB099F: PHY2 body at model+12004 (26820 B), packfile 21648 B, wrapper 5124 B at body+21696.
- The runtime wrapper is the file wrapper **in place**: runtime body base 0x29665510; of 1281 wrapper words all
  match the file except (a) offsets → base+offset, (b) 0xFFFFFFFF → 0, (c) EE+0x64: file holds the **WpArray index**
  (0..21), runtime holds the shape pointer, (d) one EE+0x4C (0x6800 → 0). 23 such words.
- AA record (68 B): +0 0xAAAAAAAA; +4..+0xC translation (0); +0x10..+0x1C quaternion (−0,−0,−0,1); +0x20 node hash;
  +0x24 K (small int); +0x28 → CC (mass record) or none; +0x2C → EE (shape record) or none; +0x30 none;
  +0x34 parent AA; +0x38 first child AA; +0x3C next sibling AA; +0x40 0xBBBBBBBB.
- CC record: 3×3 inertia (9 floats), com (3), mass, 0.3 ×4, zeros, 1, 0xDDDDDDDD.
- EE record (108 B): +0x64 shape (index in file).
- Boat tree: root AA@w+0 (0x255EAB53 K3, CC M 60791.5) → 13 leaves AA@w+1020..1836 (K3) = WpArray 21,20,…,9 =
  runtime list children 0..12 in that order (child 12 = WpArray 9 = the MOPP). Sibling AA@w+68 (0x75F1F74D K5, CC M
  22160) → 5 leaves (WpArray 8..4) + nodes 0x243A5276 K6, 0x063C61D3 K7, 0x2C3EDC3C K8, 0xA641DAE1 K9 (each with a CC
  and one leaf: WpArray 3, 2, 1, 0). So **WpArray order = hulls 0–8, MOPP, hulls 9–20** (phy2-probe skips the MOPP in
  its numbering).
- Hulls 0–8 exist at runtime (0x296658C0…0x29667470, refcount 1), referenced only by the WpArray, their EE record
  and (hulls 7, 8) one word each at 0x1EE61490 / 0x1EE616F8; they are **in no body's list**.
- Each list child's userData = its leaf AA record (runtime address of the relocated wrapper record).
