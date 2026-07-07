# Weapons / combat — Xbox↔PC code map

**Scope:** scoreboard **row 26 (Weapons / combat)** — the firing pipeline, projectile
lifecycle, the homing/lock-on FSM, and the explosion/damage descriptor family, plus the
per-frame **weapon-system driver tick** that drives them. This marries the **Xbox 360 devkit
(Jul-08 "Profile" build, `Mercs2_Xenon_P.exe`, PowerPC, base `0x82000000`)** symbol/PDB ground
truth to the **PC retail decompilation** (`Mercenaries2.exe`, unpacked SecuROM image, base
`0x00400000`).

This is the row-26 companion to the sibling gameplay-sim maps
([`vehicle_code_map.md`](vehicle_code_map.md) — the closest analog, a custom numeric solver +
command dispatch; [`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md)
— the destruction consumer this system feeds damage into; and the scheduler/streaming spine
[`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) /
[`world_streaming_code_map.md`](world_streaming_code_map.md)). It deliberately leaves the
particle/FX render side to [`particle_fx_code_map.md`](particle_fx_code_map.md) (muzzle flashes,
explosion FX) and the damage→state-machine consumer to the destruction map.

**Sources.** PC oracle: [`../mercs2-ecs/01_combat_weapons_projectiles.md`](../mercs2-ecs/01_combat_weapons_projectiles.md)
(the full 34-component weapon/projectile registry with PC descriptor addresses, hashes, strides,
CopyFromStream vtables). Xbox oracle: [`../mercs2-pdb-analysis/weapons-combat.md`](../mercs2-pdb-analysis/weapons-combat.md)
(`PgWeaponSystem`, `PgWeaponProjectile.cpp`, component byte-sizes, the `DamagePerson` command,
the honest "solver unresolved" notes) + [`xbox_ppc_named_functions.md`](xbox_ppc_named_functions.md)
(`Runtime*` descriptor RVAs `@0x829f3940`–`0x829f50f0`). Lua surface:
[`../lua_engine_bindings_audit.md`](../lua_engine_bindings_audit.md) (`Weapon.*` binding table)
+ the decompiled mission corpus (`docs/mercs2-luacd/`, `Airstrike.*` call sites). Data layer:
memory [[weapon-definitions-wpn-blocks]] (stats in 26 `wpn_*` reflection blocks). PC bodies read
first-hand from the 27k-fn Ghidra decomp and cited as `ghidra/FUN_xxxx`.

**Method / honesty model.** Same discipline as the sibling maps. PC retail strips every
`PgWeaponSystem`/`RuntimeWeapon`/`Update::*`/`ApplyDamage*` profiler string, so the weapon-system
spine is recovered on PC by **call-tree shape + shared reflection constants (`0x9e3779b9` seed,
descriptor strides) + role**, and the marriage to the Xbox symbols is descriptor-anchored
(the class-name strings survive) or PC-anchored where the Xbox body is unlocated. Confidence:
**H** can't-coincide fingerprint (read body + matching constants/role) · **M** one strong
structural signal · **L/open** positional / confirm-live. Where a leaf is virtualised behind a
SecuROM indirect (`thunk_FUN_02xxxxxx`) or is genuinely string-only on both builds, the row says so.

**One structural correction up front (vs. the row-26 brief).** The two `RuntimeWeapon`
"runtime updater" functions the brief names — `FUN_00666f00` / `FUN_006670e0` @315791 — are **not**
the per-frame firing solver. Read first-hand, they are the **RuntimeWeapon instance
serializers** (local vs. remote variant) that stamp the spawn transform `DAT_011766f0/f4/f8`
into a fresh 0x34 record — exactly ecs-01's "the `Runtime*` templates are runtime-state
serializers, not editable schemas." The actual per-frame firing/projectile/homing work lives in
the **weapon-system driver tick `FUN_0051cff0`** (§2) and its pooled per-type update leaves. This
is stated honestly and the real driver is mapped below.

**One correction the other way (vs. the Xbox "VMX128" gap).** On Xbox the projectile/homing
ballistics were flagged VMX128-undecoded. On **PC they are x86 and the homing-guidance vector
integration decompiles in the clear** (§4, `FUN_0052e1f0`). What stays opaque on *both* builds is
the **per-hit damage / explosion solver** (`ApplyDamage*`, `UpdateExplosions`,
`PhysicsCreateExplosion`, `ApplyExplosionToBodies`) — string-only / SecuROM-thunked (§5).

---

## 0. Result in one line

**Row 26 is recovered end-to-end on PC with one honest wall.** The weapon-system per-frame driver
(`FUN_0051cff0`, called from the layer-4 game-system list `FUN_004c9740` at `0x004c9a1d`) is fully
in the clear as a structure — it runs a homing sub-update then ~12 pooled per-runtime-type update
passes; the **homing/lock-on FSM** (`FUN_0052dce0` lock, `FUN_0052d120` launch, `FUN_0052e4b0`
per-weapon timer, `FUN_0052e1f0` guided-flight integration) is read first-hand with the
`HomingLockStart→Update→Clear` events and the guided-missile steering math visible; the
`RuntimeWeapon/RuntimeProjectile/RuntimeHomingWeapon/RuntimeExplosion` descriptors and instance
serializers are married to their Xbox `@0x829f39xx` RVAs by name+stride. The **per-hit damage and
explosion solver** is the wall: `DamagePerson` (Xbox `@8245af18` / PC `FUN_005e0720`) is a
scoring/authoring serializer, not the applier, and `ApplyDamage*`/`UpdateExplosions`/
`PhysicsCreateExplosion` are string-only on both builds — confirm-live only.

---

## 0.5 Master marriage table (whole system at a glance)

Per-cluster evidence in §2–§6. A bare Xbox `@0x829fXXXX`/`.rdata` offset means the Xbox *code
body* is unlocated (descriptor/name string only) and the marriage is PC-anchored. "Married by" =
the concrete signal.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Weapon-system per-frame driver** (PgWeaponSystem::Update) | `PgWeaponSystem`/`WeaponSystem` (str `0x0021a18`; `PgWeaponProjectile.cpp`) | **`FUN_0051cff0`** (2514 B) | read body: caller `FUN_004c9740@0x004c9a1d` (layer-4 list); pause-gated `PTR_DAT_01175cdc[0x62]`; runs homing update + ~12 pooled per-type passes | H (PC) |
| Weapon-system pre-pass / setup | — | `FUN_0051cf40`, `FUN_006385a0`, `FUN_005329e0`, `FUN_00532bf0`, `FUN_0052c730` | called at head of `FUN_0051cff0` before the pooled loops | M |
| **Homing update driver** (Cache+Update Weapons/Targets/Projectiles) | `HomingCacheWeapons/Targets/Projectiles`, `HomingUpdateWeapons/Guided` (str `0x0021624`–`0x0021694`) | **`FUN_0052e730`** (400 B) | read body: rebuilds 3 caches (`PTR_PTR_017bf6c0/017bf710/017bf760` via `FUN_00407610`) then lock FSM + guided update | H (PC) |
| **Homing lock FSM** (Start→Update→Clear) | `HomingLockStart/Update/Clear` (str `0x0021df4/0x0021de0/0x0021db8`) | **`FUN_0052dce0`** (1287 B) | read body: emits `s_HomingLockClear/Start/Update` via `FUN_0052f0d0` on lock-state `local_44∈{1,2,3}`; `StingerReticleUpdate` | H (PC) |
| **Homing launch / fire path** | `HomingLaunched` (str `0x0021da8`) | **`FUN_0052d120`** (560 B) | read body: emits `s_HomingLaunched`; spawns RuntimeHomingWeapon inst via `FUN_0064a600`→pool `DAT_017bf714` | H (PC) |
| Homing per-weapon lock timer | `HomingLockUpdate` | **`FUN_0052e4b0`** (207 B) | read body: decrements lock timer `weapon+0x4c`; `HomingLockClear` on target change; re-enters `FUN_0052dce0` | H (PC) |
| **Guided-missile flight integration** | `HomingUpdateGuided`, `RuntimeHomingProjectile::Update` (str `0x0021668`) | **`FUN_0052e1f0`** (692 B) | read body: steering vector (cross-prod of vel), gravity term `DAT_00b9b664`, detonation lock timer, `FUN_0052d350` step | H (PC) |
| RuntimeWeapon instance serializer (local / remote) | `RuntimeWeapon` (`@0x829f3940`) | **`FUN_00666f00`** / **`FUN_006670e0`** @315791 | read body: stamps spawn xform `DAT_011766f0/f4/f8` → 0x34 rec → pool `DAT_017bec24`; `local_10`=0/1, flag=1/2 | H (PC) |
| RuntimeWeapon descriptor registrar | `RuntimeWeapon` (`@0x829f3940`) | **`FUN_0063dcf0`** | read body: stride `0x34`, `CopyFromStream_00bc20f8`, seed `0x9e3779b9`, `s_RuntimeWeapon_00bc56f4` (hash `0xec62e3a3`) | H |
| RuntimeProjectile descriptor registrar | `RuntimeProjectile` (`@0x829f3bf0`) | **`FUN_0063dda0`** | read body: stride `0xa0`, `CopyFromStream_00bc22a8`, `s_RuntimeProjectile_00bc5758` (hash `0x9d2ab1a6`) | H |
| RuntimeHomingWeapon descriptor registrar | `RuntimeHomingWeapon` (`@0x829f4f40`) | **`FUN_00645e30`** | read body: stride `0x54`, `CopyFromStream_00bc2ed0`, `s_RuntimeHomingWeapon_00bc5a50` (hash `0xc09adb1b`) | H |
| RuntimeExplosion producer/serializer | `RuntimeExplosion` (`@0x829f3f50`) | **`FUN_0066ae30`** @317985 | read body: `FUN_0052a680`→`FUN_0064a600` into pool `DAT_017bef44`, descriptor `PTR_DAT_017bef2c` (hash `0x5529dd38`) | H |
| RuntimeWeaponProjectile descriptor | `RuntimeWeaponProjectile` (`@0x829f39d0`) | desc base `0x017bec58` (stride `0x6c`, hash `0x7a303ad6`) | ecs-01 registry (string-anchored) | H |
| Static gun-stat descriptor (core) | `WeaponProjectileBase 384 128` (str `0x003116c`; Xbox ctor `FUN_829ee168`, size `0x28`) | reg `FUN_0063f390` · schema `FUN_0065ca70` @310427 | ecs-01 + weapons-combat.md; stride `0x28`, `s_WeaponProjectileBase` | H |
| Static weapon-aspect descriptors | `WeaponBarrel`/`Scatter`/`Scope`/`Thrown`/`Trigger`/`UI`/`Effects`/`RecoilVehicle`/`Hint` | reg family `FUN_0063dbb0…0063fc00` · schemas `FUN_0065c860…0065d5f0` | ecs-01 registry, byte-for-byte registrar template (§6) | H |
| Homing design descriptors | `HomingWeapon`/`HomingProjectile`/`HomingTarget` (str `0x00316c8/d8/ec`) | reg `FUN_0063dc50`/`FUN_006438f0`/`FUN_00643990` · schema `FUN_0065d930/da40/db10` | ecs-01; strides `0x18/0x0c/0x10` | H |
| Explosion/damage descriptors | `ExplosionFudge`/`Explosive`/`DamageKey`/`TickDamage` (`@0x829f1e90` TickDamage) | `FUN_0063f180`/`FUN_0065d6e0`/`FUN_006429a0`/**unlocated** | ecs-01 + weapons-combat.md; strides `4/0x24/4/—` | H / open |
| Homing lock-state event emit | `SendHomingGuiEvent`, `HomingWeapon::GuiEvent` | `FUN_0052f0d0` | callee of all 4 homing fns; takes event-name string + args | H |
| **Combat→FACTION mood-report bridge** (NOT the hit applier) | `DamagePerson @8245af18` (Xbox command) | **`FUN_005e0720`** | read body: serializes a 7-entry `{score,flags}` array under `DamagePerson/DestroyPerson/DamageObject/DestroyObject/Hijack/Trespassing/SpecialEvent` — the **exact** set + role of `mrxfactionmanager.lua:1212` "Report mood weights" (§5.2) | H |
| **Damage→destruction bridge** (applier→FSM) | — | **LOCATED live 2026-07-06** (§5.3A): `FUN_0066f220`→`FUN_004b67b0`→`FUN_004d3f00`→`FUN_004d4010`(OnStateChange)→`FUN_004d2e20`→`FUN_006696a0` | H (live-captured) |
| **Raw ballistic math** (`ApplyDamage*` amount) | string-only (`ApplyDamageToPrimaryHealth`…) | **upstream/open** | runs in weapon-hit code before the FSM; capture via HW write-BP on `RuntimeHealth.cur` (§5.3B) | open |
| **Explosion solver** (create + apply to bodies) | string-only (`UpdateExplosions`/`PhysicsCreateExplosion`/`ApplyExplosionToBodies`) | **unresolved** / SecuROM-thunked | not a code literal on either build | open |
| `ReadyToReload` magazine predicate | `ReadyToReload @822ed658` | — | Xbox name only; PC body unlocated (indexes RuntimeWeapon struct) | open |
| `Weapon.*` Lua cfuncs | (Lua binder names) | reg table `0x00798770–0x00799200` | `luaL_Reg` walk (VAs binding-table-only) | M |
| `Airstrike.*` Lua ordnance surface | `Mission_SpawnAirstrike`-class | binding-table VAs **unlocated** | confirmed from mission scripts (`SpawnOrdnance`/`ConeSpawn`/`Flyby`) | M |

---

## 1. Where weapons sit in the frame (tick integration)

From [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md), confirmed first-hand here via the
`FUN_0051cff0` caller edge:

```
FUN_00631670 WinMain ─(each loop)→ FUN_00630ef0 RunFrame
  RunFrame:
    5. FUN_004c14f0  MASTER UPDATE
         └─ FUN_004c15e0  5-layer app stack, ticked 0→4
                layer 4 Update(+0xc) → FUN_004c0ec0 → FUN_004c9740  (gameplay-systems batch)
                     FUN_004c9740 per-system call list (fixed order), incl.:
                          ├─ FUN_00502510  PgSysPopulation::Update      (population map)
                          ├─ FUN_00532f80  vehicle-control command pump  (vehicle map §1.4)
                          └─ FUN_0051cff0  WEAPON-SYSTEM UPDATE  ← call site 0x004c9a1d   §2
                                 ├─ FUN_0052e730  homing update           §4
                                 └─ (~12 pooled per-runtime-type passes)  §2/§3
```

`FUN_0051cff0` is the direct sibling of the vehicle pump `FUN_00532f80` and
`PgSysPopulation::Update` `FUN_00502510` — all three are entries in the same layer-4 fixed-order
per-system list, each pumping its own component pools. It is the PC realization of the Xbox
`PgWeaponSystem`/`WeaponSystem` driver (build source `PgWeaponProjectile.cpp`).

**Gate.** The whole body runs only when `PTR_DAT_01175cdc[0x62] == '\0'` — the same
world-present / not-paused object the streaming map uses (`+0x61` world-present, `+0x62` here reads
as a pause/suspend bit), so weapons freeze during loading/pause exactly like the streaming pump.

---

## 2. The weapon-system driver + firing pipeline — `FUN_0051cff0` (H, read first-hand)

`FUN_0051cff0` (2514 B, caller `FUN_004c9740@0x004c9a1d`) is a **fan-out of pooled update
passes**, the same "fetch a batch of N records from a pool/ring, update each, repeat until empty"
shape as the vehicle command pump and the population update. Read structure:

```c
void FUN_0051cff0(param_1) {
  FUN_0051cf40(param_1);                         // pre-pass (frame reset)
  if (PTR_DAT_01175cdc[0x62] == '\0') {          // not paused / world present
    FUN_006385a0(param_1);                       // weapon setup passes
    FUN_005329e0(param_1); FUN_00532bf0(param_1);
    FUN_0052e730(param_1);                       // HOMING update  §4
    FUN_0052c730(param_1);
    // ── pooled per-runtime-type passes (batch-fetch → per-record update) ──
    for (batch of thunk_FUN_03410000)  FUN_0051b140();        // pass A
    for (batch of FUN_004ce810)         FUN_0051b1e0();        // pass B
    for (rec in pool DAT_01532fc0, 0x5c stride) FUN_00525ce0(rec);  // pass C
    for (batch of thunk_FUN_03520000)   FUN_00525170();        // pass D
    FUN_00524a10(); FUN_005228a0();
    for (rec in FUN_005203b0(DAT_01532fd4), 4 words) FUN_005234f0(rec);  // pass E
    for (rec in FUN_00520910, 3 words)  thunk_FUN_024e4d00(rec);
    for (rec in FUN_00406780, 6 words)  FUN_0051c200(rec);     // pass F = RuntimeWeapon equip/vis  §2.2
    for (batch of FUN_00520b40)         FUN_0051c050();
    for (rec in FUN_00406540(DAT_01532fe8), 9 words) FUN_0051c8d0(rec);
    for (batch of FUN_004f4050(DAT_01532fec)) FUN_0051cb90();
    // ── weapon-visibility reconcile over the RuntimeHomingTarget-adjacent pool ──
    for (rec in FUN_00406d40, 0x80):   // key rec[..] into hash DAT_00df99c4 → obj, then
        // resolve second hash DAT_017bf3f8/017bf40c → weapon; set vis-state weapon+0x28
        thunk_FUN_024f19f0(state);      // 2 = show, {0,1} = hide/first-person
    for (batch of FUN_004b2420)         FUN_0051cd60();
  }
}
```

**What each pass is (by pool + leaf role).** The passes iterate the `Runtime*` component pools in
a fixed order; the `0x5c`/`0x50` strides and the `FUN_00401860(rec, 6, 2, …)` init calls are the
same broadcast-ring record shape used by the vehicle map. The per-record leaves
(`FUN_0051b140`/`FUN_0051b1e0`/`FUN_00525ce0`/`FUN_00525170`/`FUN_005234f0`/`FUN_0051c050`/
`FUN_0051c8d0`/`FUN_0051cb90`/`FUN_0051cd60`) are the RuntimeWeapon / RuntimeWeaponProjectile /
RuntimeProjectile / RuntimeIgnitor / RuntimeVelocity per-type updates — this is where a
trigger-pull turns into a shot, magazine/reload advances, and fire-rate delay counts down. **These
leaf bodies were not all read this pass** (several route through the SecuROM **VM dispatcher**
`FUN_02a30028` via `thunk_FUN_024e4d00`/`thunk_FUN_024f19f0`/`thunk_FUN_03410000`/`thunk_FUN_03520000`/
`thunk_FUN_024e2ce0` — the same trampoline behind `Pg.Spawn`'s terminal commit); the *driver structure*
is H, and the virtualized commits are **read live in the unpacked image** ([[securom-decompiled-not-a-blocker]]),
not a blocker (§8). The Xbox `Update::Raycast`/`Update::Gravity`/`Update::FlightNoise`/
`Update::Movement`/`UpdateRay::ProcessCast`/`UpdateRay::CheckWater` profiler labels
(weapons-combat.md) name the sub-phases these leaves run.

### 2.2 RuntimeWeapon equip/visibility pass — `FUN_0051c200` (H, read)

`FUN_0051c200` (1161 B, from the pass-F loop) is the RuntimeWeapon **equip / weapon-visibility
state update**: it resolves the record's object (double pool-hash `DAT_00df99c4` then
`FUN_005857e0`), then dispatches on a command/state id `rec+0x10` (`param_1[4]`) through a large
switch, driving equip/attach/detach and first-person-vs-world visibility via `FUN_0051c140`,
`FUN_005192f0`, `FUN_00519540`, `FUN_00519c50`, `FUN_00529db0`, `FUN_004d51e0`. This is the native
backing of the `RuntimeWeapon` equip dump (`bSwitchingPrimary`/`eWeaponVisibility`/`bEquipping`/
`iWeaponInUse`/`iEquippedPrimaryGuid`… in weapons-combat.md).

**Equip/visibility ID set (PC-verified constants, names unknown).** The switch keys on:
`0x5429d8ec` `0x1cf3e94e` `0x10fb87af` `0x0798a42d` `0x0a5e85b3` `0x14d7a0fd` `0x27bc0fe7`
`0x38825c5a` `0x526719dd` `0xca7bde42` `0x5d1c7a0c` `0xdbbc44e9` `0xdfd8fac6` `0xe65af5d5`
`0x86f6e3d4` `0x93cd36f9` `0x4407202d`, with sub-cases on `rec+8` (`param_1[2]`) values
`0x326423c4`/`0x3f2b1372`/`0xdbbc44e9`/… . These are **compile-time name hashes** of the equip
verbs/weapon-slot ids — the *same unknown hash family* the vehicle map hit on its command ids
(bit-identical Xbox↔PC, tested negative vs `pandemic_hash_m2`/CRC32/FNV; §8).

### 2.3 RuntimeWeapon instance serializers — `FUN_00666f00` / `FUN_006670e0` (H, read — the brief's "updaters")

These are the two functions the row-26 brief calls the RuntimeWeapon updaters. Read first-hand,
they are **instance producers/serializers**, not the firing solver (matching ecs-01's finding that
every `Runtime*` "template" is a runtime-state serializer):

```c
void FUN_00666f00(param_1) {                 // LOCAL RuntimeWeapon variant
  FUN_005857e0();                            // resolve owning actor
  local_28=local_34=DAT_011766f0;            // spawn transform (pos.x)
  local_24=local_30=DAT_011766f4;            // pos.y
  local_20=local_2c=DAT_011766f8;            // pos.z
  local_e = local_e & 0xc1 | 1;              // variant flag = 1
  local_10 = 0;                              // local_10 = 0  (LOCAL)
  FUN_0064a600(param_1,&local_34);           // commit 0x34 record into RuntimeWeapon pool
  if (iVar1 != DAT_017bec24) …               // pool bumped → spatial-register FUN_00665590
  FUN_0051fee0(param_1,*puVar2); FUN_005e0580(&PTR_PTR_017bf158);
}
```

`FUN_006670e0` is byte-identical except `local_e & 0xc2 | 2` and `local_10 = 1` — the **remote /
alternate** variant (local vs. remote weapon instance, the `iOwner`/`iPlayer` split in the
`RuntimeWeapon` dump). Both write into the pool anchored by descriptor `DAT_017bec24` (registrar
`FUN_0063dcf0`, §6). So the firing *state object* is produced here; the firing *behaviour* runs in
the `FUN_0051cff0` pooled passes.

---

## 3. Projectile lifecycle (M/H)

The projectile side is the Xbox `ProjectileInstantiate → ProjectileCacheGet → ProjectileSetup →
ProjectilePhysics → ProjectileCollision → ProjectileDestroy` chain (weapons-combat.md
`0x0021738`–`0x0021764`). On PC:

- **Descriptors** (both builds, married by name+stride): `RuntimeProjectile` reg `FUN_0063dda0`
  (stride **0xa0**, `CopyFromStream_00bc22a8`, `s_RuntimeProjectile_00bc5758`, hash `0x9d2ab1a6`)
  ↔ Xbox `@0x829f3bf0`; `RuntimeWeaponProjectile` desc base `0x017bec58` (stride **0x6c**, hash
  `0x7a303ad6`) ↔ Xbox `@0x829f39d0`; the design-time `ProjectilePhysics` schema `FUN_0065dc00`
  (stride 0x28: MinVelocity/Velocity/Accel/AccelTime/damage-dropoff + `NeedsDriver` bool, ecs-01).
- **Per-frame flight** = the pooled passes in `FUN_0051cff0` (§2) whose Xbox sub-phase labels are
  `Update::Raycast` / `Update::Gravity` / `Update::FlightNoise` / `Update::Movement` /
  `UpdateRay::ProcessCast` / `UpdateRay::CheckWater`. The velocity-integration + gravity +
  raycast-impact structure is **readable on PC** for the homing/guided variant (§4,
  `FUN_0052e1f0` — the same `FUN_0052d350` step is the impact/lifetime tester); the generic
  (non-homing) projectile leaf and its raycast-vs-water impact test route through the
  `thunk_FUN_03410000`/`thunk_FUN_03520000` pool fetchers and are **confirm-live** for the exact
  impact predicate. The Xbox note "projectile ballistics VMX128-undecoded" **does not carry to PC**
  (x86) — the math decompiles; the only reason a given leaf is unread is the SecuROM ring fetch,
  not vector-ISA opacity.
- **Water interaction** ties to [`water_code_map.md`](water_code_map.md) via the
  `UpdateRay::CheckWater` phase (waterline query shared with the boat buoyancy action).

---

## 4. Homing / lock-on FSM (H — read first-hand, the scoreboard's "homing FSM")

This is the cleanest recovery in the map. The Xbox pipeline
(`HomingCacheTargets/Projectiles/Weapons` → `HomingUpdateGuided/Weapons/WeaponAi` →
`HomingLockStart→Update→Clear` → `HomingLaunched`) maps to a tight PC cluster driven from the
weapon-system tick.

### 4.1 Driver — `FUN_0052e730` (H)

Called from `FUN_0051cff0`, it **rebuilds three caches then runs the two updates**:

```c
FUN_0052e730(param_1) {
  cacheWeapons  = &PTR_PTR_017bf6c0; if (DAT_017bf6c8) FUN_00407610();   // HomingCacheWeapons
  cacheTargets  = &PTR_PTR_017bf710; if (DAT_017bf718) FUN_00407610();   // HomingCacheTargets/Proj
  cacheProj     = &PTR_PTR_017bf760; if (DAT_017bf768) FUN_00407610();
  if (weapons && targets && proj-nonempty) {
     FUN_0052d7f0(param_1, &cacheWeapons, …, &nWeapons, …);   // collect active weapons
     FUN_0052daa0(&cacheTargets, …, &nTargets, …);            // collect candidate targets
     if (nWeapons>0 || nTargets>0) {
        FUN_0052dbf0(&cacheProj, …, &nProj, …);               // collect guided projectiles
        if (nProj>0) {
           FUN_0052dce0(param_1, nWeapons, projBuf, nProj);   // LOCK FSM  §4.2
           FUN_0052e1f0(param_1, projBuf, nProj);             // GUIDED FLIGHT  §4.4
        }
     }
  }
}
```

The pool `PTR_PTR_017bf710` is the RuntimeHomingWeapon pool the launch path writes into (§4.3);
`&PTR_PTR_017bf760` is the RuntimeHomingProjectile pool.

### 4.2 Lock state machine — `FUN_0052dce0` (H, read)

Per active weapon × candidate target, `FUN_0052dce0` evaluates lock geometry (angle/distance via
`FUN_0052efc0`/`FUN_00649c00`/`FUN_0064a090` hash lookups against the target set), advances a
per-weapon **lock timer** (`weapon[8]` countdown seeded from `weapon[9]` = current target), and
emits the lock event by state:

```c
if (local_44 == 1) pcVar6 = s_HomingLockClear_00bb39c4;   // lost lock
else if (local_44 == 2) pcVar6 = s_HomingLockStart_00bb3a10;  // acquired, timer starts
else if (local_44 == 3) pcVar6 = s_HomingLockUpdate_00bb39fc; // holding lock
FUN_0052f0d0(pcVar6, weaponGuid, targetGuid, 0, -1, lockStrength, &DAT_01176710);
```

It also drives the **Stinger reticle**: on a held lock it fires `s_StingerReticleUpdate_00bb39e4`
via `FUN_0052f0d0`. Tunables in the clear: `DAT_00d2d898` (min lock weight), `DAT_00b9b664` (angle
falloff base), `DAT_00df57bc` (angle scale), `DAT_00dfdb5c` (default weight). The
`LockOnTime`/`LockOnMaxAngle`/`LockOnMaxDistance`/`LockOnMinWeight` design fields (`HomingWeapon`
schema `FUN_0065d930`, ecs-01) are the authored inputs to this FSM.

### 4.3 Launch / fire — `FUN_0052d120` (H, read)

The missile-fire path: resolves the launching weapon (`FUN_005857e0`), reads its current lock
(`weapon[9]`, `FUN_0052e8c0`), emits `s_HomingLaunched_00bb39d4` (and `s_HomingLockClear` on the
now-consumed lock) via `FUN_0052f0d0`, then **spawns the RuntimeHomingWeapon instance**:

```c
FUN_0052f0d0(s_HomingLaunched_00bb39d4, weaponGuid, targetGuid, param2, param3, DAT_00dfdb5c, &DAT_01176710);
FUN_0064a600(param_3, local_58);                       // commit RuntimeHomingWeapon record
if (iVar2 != DAT_017bf714) … FUN_00665590(param_3, PTR_DAT_017bf6fc);  // spatial-register
```

`FUN_0052e4b0` (207 B) is the companion **per-weapon lock-timer decrement**: ages `weapon+0x4c`,
fires `HomingLockClear` on a target change, and re-enters `FUN_0052dce0(1)` to re-evaluate.

### 4.4 Guided-missile flight — `FUN_0052e1f0` (H, read — the "VMX128" correction)

The guided-projectile per-frame integration, **fully decompiled on PC** (this is what was opaque
on Xbox). Per live guided projectile it: refreshes the target handle, computes a **steering vector
as a cross-product of the current velocity with the target-relative vector**, applies a gravity
bias, enforces the **detonation-distance / arm-timer** (`piVar1[0x11]` armed-target,
`piVar1[0x12]` timer counting down by `param_2` = dt), and calls the shared step `FUN_0052d350` to
advance position + test impact:

```c
fVar10 = DAT_00b92874 / (vx²+vy²+vz²+…);           // normalize
local_34 = vy*fx − vz*fy;  local_38 = vz*fy + vx*fx;  // steering (cross-product terms)
local_30 = (vx*fx + vz*fy) − DAT_00b9b664;          // gravity term
…
if (piVar1[0x11] == target) { timer -= dt; if (timer<=0) commit-detonate; }  // arm/detonate
iVar4 = FUN_0052d350(&pos, &steer, *proj, &speed, …, targets, nTargets, 0);   // step + impact
piVar1[0x14] = iVar4;                               // updated impact/flight flag
```

Tunables `DAT_00b92874` (turn/normalize), `DAT_00b9b664` (gravity) — the `TurnSpeed`/`Accel`/
`AccelTime`/`DetonationDistance` design fields (`HomingProjectile`/`HomingTarget` schemas
`FUN_0065da40`/`FUN_0065db10`, ecs-01) feed this. `FUN_0052d350` is the shared integrate+impact
step used by both the lock FSM and the guided update — the projectile-flight core.

---

## 5. Explosion / damage taxonomy + the honest solver gap (H descriptors / open solver)

### 5.1 Descriptors (both builds, H)

| Class | Xbox | PC descriptor | Schema / stride | Payload (ecs-01) |
|---|---|---|---|---|
| `Explosive` | `Explosive 96 32` | reg `FUN_0065d6e0` cluster | stride `0x24` | MaxForce, MinForceFalloff, Damage, Arc, `ExplosiveDetailEnum` |
| `ExplosionFudge` | `@0x829edf28` (size 4) | reg `FUN_0063f180` · schema `FUN_0065ab40` | stride `0x04` | 1 float (radius/damage fudge, default 1.0) |
| `RuntimeExplosion` | `@0x829f3f50` | producer `FUN_0066ae30` (pool `DAT_017bef44`) | stride `0x40` (hash `0x5529dd38`) | live explosion instance |
| `DamageKey` | `@0x829f1a10` (size 4) | reg `FUN_006429a0` · desc `FUN_006616c0` | stride `0x04` | `DamageKeyEnum` (Explosion/BulletLarge/BulletAM/RocketLarge/ExplosionLarge/WheelBurnout/BunkerBuster) |
| `TickDamage` | `@0x829f1e90` (size 0x10) | **unlocated** | — | per-tick damage applier (open) |
| `Ignitor` / `RuntimeIgnitor` | `@0x829f48d0` | schema `FUN_006627a0` / base `0x017bf388` | `0x0c` / `0x1c` | fire-start 3 floats |

**Explosion size taxonomy** (Xbox debug menu, weapons-combat.md): Tiny / Small / Grenade / VS /
Large / Huge Explosion — a size enum + an in-game "Display Explosion Debug" visualizer.

### 5.2 The combat→FACTION mood-report bridge — `FUN_005e0720` (H)

The `DamagePerson` string on PC resolves to `FUN_005e0720`. It is **not** a weapon function and
**not** the per-hit applier — it is the **combat→faction attitude bridge**: it reads a live 7-entry
`{score, flags}` array (`puVar2[0..0xd]`, `int→float`) and serializes each score out under its
event-name key:

```c
puVar2 = thunk_FUN_024e9930();                            // the accumulated mood-event scores
FUN_0059f470(dst, s_DamagePerson_00bb3d48,  &score0);     // -> a Lua event/table entry per key:
FUN_0059f470(dst, s_DestroyPerson_00bb3d68, &score1);
FUN_0059f470(dst, s_DamageObject_00bb3d58,  &score2);
FUN_0059f470(dst, s_DestroyObject_00bb3d78, &score3);
FUN_0059f470(dst, s_Hijack_00bb3d88,        &score4);
FUN_0059f470(dst, s_Trespassing_00bb9940,   &score5);
FUN_0059f470(dst, s_SpecialEvent_00bb994c,  &score6);     // then FUN_0059dbe0() posts the event
```

**This is the native emitter of the exact "mood-event" set the faction manager consumes.**
`mrxfactionmanager.lua:1212-1219` (the "Report mood weights") weights precisely these seven keys —
`DamagePerson×3, DestroyPerson×50, DamageObject×1, DestroyObject×25, Trespassing×20, Hijack×10`
(+ `SpecialEvent`), clamped ≥ −60 — and applies the result via `MrxFactionManager.ChangeRelation` →
`Ai.SetRelation(subjGuid, objGuid, nRelation)` → `Event.Post("Attitude", …)`. That attitude then
drives **price scaling** (Hostile = can't buy / Neutral 1.5× / Friendly 1.0×,
`mrxfactionmanager.lua:20-50`), **pursuit "heat"** (`Pg.SetPursuitLevelTimes`,
`RestrictPursuitFaction`), spawn tables, the HUD faction meter (`Hud.FactionDisplay:SetValue`), and
the PDA. The civilian-casualty penalty (`-5000`, doubling every 20 kills, floor `-1M`) rides the same
path.

So `FUN_005e0720` belongs to the **faction/reputation system**, not weapons — it is where a hostile
act (routed here after the hit lands) becomes a faction-relation delta. Faction is not a scoreboard
row of its own, but its engine hooks are the `Faction*` ECS components (`FactionMarker 0x9b98cb09
FUN_0065c0f0` = faction id, `FactionValue 0x8bfc69d6 FUN_0065c7d0` = per-entity scalar, `FactionZone
FUN_0065c490`, ecs-07), the Xbox `xPgSysNetFactionRelations`/`ApplyCachedFactionRelations`/
`GetFactionGuid` set (game-systems.md §Factions), and the `Ai.Get/SetRelation` cfuncs; the tables +
attitude math live in `MrxFactionManager` (Lua). Cross-referenced here because the weapon system's
damage event **terminates** in this bridge — a candidate for its own faction/reputation code map.

### 5.3 The per-hit solver — damage→destruction bridge LOCATED (2026-07-06); raw ballistic math still upstream

**Status update (2026-07-06, live x32dbg on genuine v1.1, mapped v1.0↔v1.1 by `FnMnemonicSig`):** the
question splits cleanly in two, and one half is now **resolved live**.

**(A) The damage→destruction-state bridge — LOCATED (was "unresolved").** Breakpointing the
`RuntimeHealth` writer live and walking the stack pinned the full model-destruction chain (v1.0 addrs):

```
FUN_0066f220  per-model destruction poll (callers=[] → vtable/registry-driven update;
              gate hash 0x5b724250 = pandemic_hash("model") → operates on destructible MODELS)
  → FUN_004b67b0  model state-update (699 B): reads a health-RATIO float in XMM0, compares to a
                  threshold (DAT_00b97744, or DAT_00b9c174 when DAT_00dfbd75!=0) → decides the
                  destruction-state transition; branches to FUN_004d3f00 or FUN_004d3e10 (SetState)
  → FUN_004d3f00  apply-state-to-all-nodes (262 B): allocs a per-node array, loops FUN_004d4010
  → FUN_004d4010  OnStateChange (444 B): walks the state list, fires enter/exit callbacks via
                  FUN_004d1b00 (=(*_DAT_0244fd28)() VM thunk), sets the new node state, and posts
                  s_OnStateChange_00bb12a4 via thunk_FUN_024f28c0
  → FUN_004d2e20  per-node event pump (706 B): drains a 5-word-record stack-ring (param_1+4=top),
                  keys on msg hashes 0x15c02da4 / 0xBA71C11C, dispatches FUN_006746d0
  → FUN_006746d0 → … → FUN_006696a0  RuntimeHealth {cur,max} writer
```

Live record observed carried a **unit hit-direction vector** (`0.82,-0.28,0.49`, |v|≈1) + runtime-computed
event hashes (which is why they never grep as literals — same wall as the vehicle command-IDs). This is
exactly the map's old "per-hit applier that subtracts `RuntimeHealth`/`RuntimeNodeHealth` and posts into
the destruction FSM" — now with addresses. **Caveat:** this FSM *reacts* to an already-dropped health
ratio; it is the destruction bridge, **not** the ballistic amount computation.

**(B) The raw ballistic MATH — still upstream/open.** The actual `damage = weapon_damage ×
falloff(distance) × mitigation → subtract RuntimeHealth.cur` runs in the **weapon-hit code** *before*
(A) polls the ratio. It has **no PC code literal by name** (`ApplyDamage*`, `ProcessExplosionCast`,
`ApplyExplosionToBodies`, `ExpToObj` are string-only). **Capture method (definitive):** HW **write**-BP
on a target's `RuntimeHealth.cur` float (`{cur,max}` stride `0xc`, producer `FUN_004cfed0`) — prefer the
**player's** `cur` (only player-taken damage writes it, no destructible-FSM noise); the write's call
stack + XMM registers are the ballistic applier and its distance/falloff math. The `RuntimeExplosion`
producer `FUN_0066ae30` is a **startup registrar** (confirmed live: never runs in gameplay), so it is
*not* a runtime anchor.
- **Firing-leaf VM residue — read live in the unpacked image.** The `FUN_0051cff0` pooled-pass leaves
  that call `thunk_FUN_024e2ce0`/`thunk_FUN_024e4d00`/`thunk_FUN_03410000`/`thunk_FUN_03520000` route
  through the SecuROM **VM dispatcher `FUN_02a30028`** (the same trampoline behind `Pg.Spawn`'s terminal
  commit `thunk_FUN_024f3200`). The *drivers* are fully decompiled; the virtualized commit is read in
  the SecuROM-**unpacked** x32dbg session (it is unpacked in memory — that is the recovery path, not a
  gap). Follow simple split-thunks straight to their `.text` bodies in the corpus.
- The damage-dropoff curve fields (`DamageMinimum`/`DamageDropoffStart`/`Stop`/`DamageRadius`/
  `DamageModifier`/`MaxDamage`/`HeroMultiplier`) are authored in the `ProjectilePhysics`/`Explosive`
  reflection blocks (ecs-01) — the *inputs* are in the clear; the *solver that consumes them* is not.

The **output** of the solver is visible, though: a health drop routes into the destruction runtime
(`FUN_004cfed0` RuntimeHealth/RuntimeNodeHealth producer, `FUN_004d05c0` force-destroy) and posts
`DamageMsg 0xC6507EE1` / `DestroyMsg 0x1ED7AD78` — see
[`state_machine_destruction_code_map.md`](state_machine_destruction_code_map.md) §3–4. So the
weapon system's damage event lands in the destruction state machine even though the ballistic hit
math between them is the unrecovered link.

---

## 6. Descriptor registrar family + pool sizes (reference)

Every weapon/projectile component is registered by the same **one-shot descriptor registrar**
template (weapons-combat.md §PC cross-ref + ecs-01): fill a global descriptor struct with a
`CopyFromStream` vtable ptr, the `0x9e3779b9` seed, pool size `0x100`, a record stride, and the
class-name string, then call the shared registrar `FUN_0064a770`. Verified shape (RuntimeWeapon,
read first-hand `FUN_0063dcf0`):

```c
PTR_PTR_017bec08 = &PTR_CopyFromStream_00bc20f8;   // (de)serializer
DAT_017bec2c = 0x34;  _DAT_017bec2e = 8;           // stride 0x34, type tag 8
DAT_017bec34 = 0x9e3779b9;  DAT_017bec30 = 0x100;  // seed, pool
PTR_PTR_017bec20 = &PTR_LAB_00bc5ff8;              // shared component method vtable
FUN_0064a770();
PTR_s_RuntimeWeapon_017bec44 = s_RuntimeWeapon_00bc56f4;
```

**Strides / hashes / Xbox RVAs (verified: PC ecs-01 + read registrars; Xbox
`xbox_ppc_named_functions.md`):**

| Class | PC hash | PC stride | PC registrar | Xbox RVA / size |
|---|---|---|---|---|
| RuntimeWeapon | `0xec62e3a3` | 0x34 | `FUN_0063dcf0` | `@0x829f3940` |
| RuntimeWeaponProjectile | `0x7a303ad6` | 0x6c | (base `0x017bec58`) | `@0x829f39d0` |
| RuntimeProjectile | `0x9d2ab1a6` | 0xa0 | `FUN_0063dda0` | `@0x829f3bf0` |
| RuntimeExplosion | `0x5529dd38` | 0x40 | producer `FUN_0066ae30` | `@0x829f3f50` |
| RuntimeHomingWeapon | `0xc09adb1b` | 0x54 | `FUN_00645e30` | `@0x829f4f40` |
| RuntimeHomingProjectile | `0xc45d369e` | 0x58 | (base `0x017bf6f8`) | `@0x829f4fd0` |
| RuntimeHomingTarget | `0x14f6de44` | 0x30 | (base `0x017bf748`) | `@0x829f5060` |
| RuntimeIgnitor | `0x1ca3abd7` | 0x1c | (base `0x017bf388`) | `@0x829f48d0` |
| RuntimeLaserDesignator | `0x735b0eaa` | 0x10 | (base `0x017bf798`) | `@0x829f50f0` |
| RuntimeVelocity | `0xe493bf82` | 0x08 | (base `0x017becf8`) | `@0x829f3b60` |
| WeaponProjectileBase | `0xeb505c8b` | 0x28 | `FUN_0063f390`/schema `FUN_0065ca70` | ctor `FUN_829ee168` (0x28) |
| WeaponEffects | `0xf24d2021` | 0x10 | `FUN_0063dbb0`/schema `FUN_0065c860` | `@0x829edfb8` (0x10) |
| WeaponBarrel | `0x180e2b95` | 0x04 | `FUN_0063f2e0`/schema `FUN_0065c9e0` | `@0x829ee0d8` (4) |
| WeaponRecoilVehicle | `0x557e4b99` | 0x08 | `FUN_0063f230`/schema `FUN_0065c930` | `@0x829ee048` (8) |
| WeaponScatter | `0xe7234615` | 0x1c | `FUN_0063db10`/schema `FUN_0065cc50` | — |
| WeaponScope | `0x27ca777f` | 0x14 | `FUN_0063fab0`/schema `FUN_0065d5f0` | — |
| WeaponThrown | `0x24870cff` | 0x34 | `FUN_0063f8c0`/schema `FUN_0065d290` | — |
| WeaponTrigger | `0xc526a637` | 0x08 | `FUN_0063f960`/schema `FUN_0065d440` | — |
| WeaponUI | `0xe5d5e31f` | 0x18 | `FUN_0063fa00`/schema `FUN_0065d4f0` | `WeaponUI 384 128` |
| WeaponHint | `0xd390834a` | 0x34 | `FUN_00643280`/schema `FUN_00662860` | `WeaponHint 384 128` |
| HomingWeapon | `0x1a4db6ed` | 0x18 | `FUN_0063dc50`/schema `FUN_0065d930` | str `0x00316c8` |
| ProjectilePhysics | `0x11e6c283` | 0x28 | `FUN_0063fc00`/schema `FUN_0065dc00` | `ProjectilePhysics 128 128` |
| ExplosionFudge | `0x5aeabc23` | 0x04 | `FUN_0063f180`/schema `FUN_0065ab40` | `@0x829edf28` (4) |
| DamageKey | (DamageKeyEnum) | 0x04 | `FUN_006429a0`/desc `FUN_006616c0` | `@0x829f1a10` (4) |

**Xbox pool sizes (weapons-combat.md descriptor dump — `count grow`):** `WeaponProjectileBase 384
128`, `WeaponBarrel 512`, `WeaponScatter 256`, `WeaponCoupling 512`, `WeaponScope 16 16`,
`WeaponThrown 16 16`, `WeaponTrigger 16 16`, `WeaponEffects 384 128`, `WeaponRecoilVehicle 64 64`,
`WeaponHint 384 128`, `HomingWeapon 128 64`, `ProjectilePhysics 128 128`, `RuntimeWeapon 192 64`,
`RuntimeProjectile 512 128`, `RuntimeWeaponProjectile 160 32`, `ExplosionFudge 256 64`,
`Explosive 96 32`. Core gun-stat defaults (`WeaponProjectileBase` schema `FUN_0065ca70`, ecs-01):
`iClipSize 30`, `MaxAmmoReserve 60`, `iBulletsPerShot 1`, `RateOfFire 120.0`, `FireType Automatic`,
`MaxAimAngleAi 15.0`.

---

## 7. Data + Lua surface (M)

**Weapon-stat data.** Editable stats live in **26 `wpn_*` reflection blocks**, NOT Lua (memory
[[weapon-definitions-wpn-blocks]]): `wpn_rocket`/`wpn_rifle`/`wpn_pistol`/`wpn_grenade`/
`wpn_emplacedgun`/`wpn_designator`/`wpn_clip`/`wpn_c4` (+ projectile material keys
`projectile_grapple`/`projectile_rocket`/`projectile_bullet_rifle`/`projectile_bullet_heavymg`).
Each block deserializes into the `WeaponProjectileBase`/`WeaponScatter`/`ProjectilePhysics`/… pools
via the schema functions in §6.

**Lua surface** (registration table `0x00798770–0x00799200`, `luaL_Reg` walk; VAs are
binding-table-only, recover with a `DecompileProfileAccessors.java`-style forcing script):

- `Weapon.*` — `GetClipAmmo`, `SetClipAmmo`, `GetReserveAmmo`, `SetReserveAmmo`, `IsDesignator`,
  `IsPrimary` (the native backing is the RuntimeWeapon pool read/write, §2.2/§2.3).
- `Human.Inventory.SetAllWeapons(uChar, {…})` / `ResetWeapons` — force a loadout
  (docs/mercs2-luacd 07 §8); `Object.SetInfiniteAmmo(uChar, bEnable)` — native infinite-ammo toggle
  (07 §2.7), plus the `CheatInfiniteAmmo` debug string.
- **`Airstrike.*`** — the ordnance/support surface, confirmed live from mission scripts
  (`mrxstrategicmissile.lua`, `mrxfuelairbomb.lua`, `mrxsatclusterbomb.lua`):
  `Airstrike.SpawnOrdnance(name, x,y,z, vx,vy,vz, "distance", dist, owner, cb, data)`,
  `Airstrike.ConeSpawn(...)`, `Airstrike.Flyby(...)`, `Airstrike.SpawnDirectedObject(...)`. Generic
  spawns (explosions, projectiles) also go through `Pg.Spawn(name, x,y,z)`.
  **Correction:** the brief's "`Munitions.SpawnOrdnance`" is not a namespace — `munitions` is a
  pickup entity script (`munitions.lua`); the ordnance-spawn cfuncs live under `Airstrike.*`.
- **Combat event types** (Lua listeners, bindings audit App-B): `WeaponEvent`,
  `AirstrikeDeliveryReady`, `GuiWeaponEquippedUpdate`, `GuiReticleUpdate`, `GuiAmmoUpdate`,
  `GuiPlayerReceiveDamage`, `ObjectHealthLessThan`, `ObjectHealth`.

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

**Firing / driver (the leaf math)**
1. bp `FUN_0051cff0` head; step the pooled passes and, for each `Runtime*` pool leaf
   (`FUN_0051b140`/`FUN_00525ce0`/`FUN_005234f0`/`FUN_0051c8d0`/`FUN_0051cb90`/`FUN_0051cd60`), dump
   the record + read the SecuROM fetch targets (`thunk_FUN_03410000`, `thunk_FUN_03520000`,
   `thunk_FUN_024e2ce0`, `thunk_FUN_024e4d00`) — this recovers the trigger→shot / fire-rate /
   magazine leaf that this static pass could not read.
2. bp `FUN_0051c200` with a live weapon equip; capture the `rec+0x10` id to name the equip/vis ID
   set (§2.2) and resolve `thunk_FUN_024f19f0` (weapon-visibility setter) + `thunk_FUN_024e5220`.
3. Crack the equip/weapon-slot ID hash family (`0x5429d8ec`/`0x10fb87af`/… — same unknown scheme as
   the vehicle command ids) by breaking on the producer that posts them.

**Homing**
4. bp `FUN_0052dce0` / `FUN_0052d120` / `FUN_0052e1f0` during a Stinger lock+fire; confirm the
   `HomingLockStart/Update/Clear` + `HomingLaunched` emit args, the lock-timer offsets
   (`weapon[8]/[9]`), and the guided steering tunables `DAT_00b92874`/`DAT_00b9b664`; read
   `FUN_0052d350` (the shared integrate+impact step) to pin the impact predicate.

**Damage / explosion (the wall)**
5. HW-bp the `RuntimeHealth` write in `FUN_004cfed0` (destruction map) and walk **back** through the
   caller to find the per-hit `ApplyDamageToPrimaryHealth`/`ApplyDamageToNodeHealth` applier — the
   one function string-only on both builds. Same for `PhysicsCreateExplosion`/`ApplyExplosionToBodies`:
   bp `Pg.Spawn` of an `Explosion (…)` template, follow into `RuntimeExplosion` (`FUN_0066ae30` pool
   `DAT_017bef44`) and out to the body-impulse applier.
6. `ReadyToReload @822ed658` (Xbox) — find the PC magazine-ready predicate by breaking the reload
   leaf during a live reload; confirm the `bReloading`/`iRoundsPerReload`/`iClipAmmo` offsets in the
   RuntimeWeapon 0x34 struct.
7. `TickDamage @0x829f1e90` (Xbox, size 0x10) — PC descriptor unlocated; bp the per-tick fire/DoT
   applier to bind the PC VA.

**Lua**
8. Recover the binding-only `Weapon.*` / `Airstrike.*` cfunc bodies (`GetClipAmmo`/`SetReserveAmmo`/
   `SpawnOrdnance`) with the profile-accessor forcing script; verify each reads/writes the
   RuntimeWeapon pool resolved via `FUN_005857e0`.

---

## 9. Reconciliation with `mercs2_engine` (scoreboard row 26 = ❌ — this map = the reimpl target)

**Status: ❌ — there is no combat layer in the engine.** `mercs2_engine`/`mercs2_core` implement
streaming, rendering, input, the ECS spine, and (partially) the destruction state machine, but
**no weapon system, no projectiles, no damage, no explosions** exist. This map is the
faithful-implementation reference. Direct port targets, in build order:

1. **Weapon-system tick** — a `WeaponSystem::update(dt)` entry in the layer-4 fixed-order list
   (beside the vehicle pump and population update), gated on world-present, that iterates the
   `Runtime*` component pools. Structure = `FUN_0051cff0` (§2): homing sub-update then per-type
   passes. Tuning loads from the 26 `wpn_*` reflection blocks (like vehicle tuning blocks), keyed
   by the strides in §6.
2. **Firing → shot** — RuntimeWeapon per-frame leaf: trigger-down → fire-rate delay
   (`RateOfFire`) → hitscan raycast **or** projectile spawn (`iBulletsPerShot`, scatter from
   `WeaponScatter`), magazine/reload (`iClipSize`/`iRoundsPerReload`, `ReadyToReload` predicate).
   The RuntimeWeapon instance producer is `FUN_00666f00`/`006670e0`'s role (local/remote).
3. **Projectile flight** — RuntimeProjectile (0xa0) integration: velocity + gravity + raycast
   impact + lifetime, with the `Update::Raycast/Gravity/FlightNoise/Movement/CheckWater` phases (§3).
   The homing/guided variant's math (`FUN_0052e1f0`, §4.4) is a **direct port** — cross-product
   steering + gravity + detonation-timer + shared integrate step.
4. **Homing FSM** — the `HomingLockStart→Update→Clear`/`HomingLaunched` state machine (§4) with the
   `LockOnTime`/`LockOnMaxAngle`/`LockOnMaxDistance`/`LockOnMinWeight` inputs; emits the same events
   for the reticle/HUD.
5. **Damage → destruction bridge** — a per-hit damage applier that subtracts `RuntimeHealth`/
   `RuntimeNodeHealth` and posts `DamageMsg`/`DestroyMsg` into the destruction state machine (the
   consumer is already partly built — destruction map §9). The PC solver is the wall (§5/§8), so the
   engine **implements** the applier from the authored dropoff/radius fields, not a port. Explosions:
   a radial `PhysicsCreateExplosion` → `ApplyExplosionToBodies` impulse+damage over a queried body
   set, feeding both physics and the damage applier.
6. **Do NOT** conflate the notoriety scoring serializer (`FUN_005e0720`, §5.2) with the hit applier —
   it feeds faction reputation, not health.

## 10. Provenance

- PC decomp: `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (SecuROM-unpacked, base 0x400000).
  Bodies read first-hand and cited as `ghidra/FUN_xxxx`: `FUN_0051cff0` (driver), `FUN_0052e730`/
  `FUN_0052dce0`/`FUN_0052d120`/`FUN_0052e4b0`/`FUN_0052e1f0` (homing), `FUN_0051c200` (equip/vis),
  `FUN_00666f00`/`FUN_006670e0` (RuntimeWeapon serializers), `FUN_0063dcf0`/`FUN_0063dda0`/
  `FUN_00645e30`/`FUN_0066ae30` (descriptor registrars/producers), `FUN_005e0720` (scoring serializer),
  `FUN_0052dce0`/`FUN_0052d120` (event emit `FUN_0052f0d0`).
- Xbox ground truth: `docs/mercs2-pdb-analysis/weapons-combat.md` (77 `.rdata` symbols,
  `PgWeaponProjectile.cpp`, component byte-sizes, `DamagePerson @8245af18`, `ReadyToReload
  @822ed658`), `docs/reverse_engineer/xbox_ppc_named_functions.md` (`Runtime*` RVAs
  `@0x829f3940`–`0x829f50f0`).
- Data oracle: `docs/mercs2-ecs/01_combat_weapons_projectiles.md` (34-component registry, strides,
  hashes, CopyFromStream vtables, field schemas + defaults); memory [[weapon-definitions-wpn-blocks]].
- Lua: `docs/lua_engine_bindings_audit.md` (`Weapon.*`), `docs/mercs2-luacd/` (`Airstrike.*` call
  sites, `Object.SetInfiniteAmmo`, `Human.Inventory.SetAllWeapons`).
- Confidence stated per row; the per-hit damage/explosion solver and the SecuROM-thunked firing
  leaves are the documented confirm-live gaps (§8).
