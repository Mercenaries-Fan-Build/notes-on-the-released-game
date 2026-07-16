# The Saboteur / WildStar damage-explosion-destruction solver — symbol map

**The Mercenaries 2 "wall" — named.** The per-hit damage / explosion / destruction
**solver** is the one documented gap in the Mercs2 RE effort: `ApplyDamage*` /
`UpdateExplosions` / `PhysicsCreateExplosion` / `ApplyExplosionToBodies` are string-only
and SecuROM-thunked on both Mercs2 builds, so no readable body was ever recovered by name
(see `mercs2_combat/damage.rs` honesty boundary, weapons_combat_code_map §5, and the
[[rows-26-29-weapons-save-code-maps]] memory).

A leaked pre-release **Xbox 360 devkit** of The Saboteur (Pandemic codename **WildStar**,
sibling engine on the shared **Pebble/Odin** core) ships full linker `.map`s **and PDBs**,
naming that exact subsystem. Source: `C:\Users\Shadow\Desktop\notes-on-reversing-the-sabetour\game-files\symbols`.

| File | What it is |
|---|---|
| `WildStar_d.exe` + `WildStar_d.pdb` (69 MB) | **Full debug build** — PPC-LE PE (machine `0x1f2`), load base `0x82000000`. Richest: struct field layouts, types, likely locals + file/line. |
| `WildStar_p.exe` + `WildStar_p.pdb` (44 MB) | Profile build, same subsystem, lighter symbols. |
| `Saboteur.xex` + `Saboteur.pdb` | The retail-form XEX2 Xbox image (`Saboteur.exe` is a XEX2 despite the extension). |
| `WildStar_d.map` (45,386 WS symbols) | Plaintext linker map used to build this doc. |
| build_info.txt | "The Saboteur (Xbox 360) Pre-Release — May 20 2008". |

**All Xbox 360 PowerPC.** There is no PC x86 build in this drop. The value is
**names + signatures + struct layouts**, which we marry to the clean **x86 bodies** already
in our GOG-retail Saboteur decomp (`output/_ghidra_saboteur/saboteur_all_functions_decomp.txt`,
36,935 fns, currently `FUN_`-named). Full cluster index: `docs/data/saboteur_wildstar_damage_symbols.csv` (376 fns).

## Honesty boundary (read before porting anything to Mercs2)

This is **The Saboteur (WildStar), 2008 Xbox devkit** — a *sibling* engine, **not** Mercs2 and
**not** byte-identical. It is a **faithful reference for the algorithm and data-structure shape**
(shared core, identical `WS*Damageable`/`WSDamageDesc` pattern), not a literal drop-in for Mercs2's
exact damage curve or mitigation constants. Treat recovered numbers as WildStar's until confirmed
against a Mercs2 live capture. This upgrades our `damage.rs` from *conventional stand-in* to
*sibling-engine actual algorithm, named* — and tells us the exact `WSDamageDesc`/`WSForceDesc`
fields to look for in the Mercs2 SecuROM thunks / live capture.

## The core solver (Xbox VAs, `WildStar_d`)

### Health / damageable tree — base class `WSDamageable`
| VA | Symbol |
|---|---|
| `0x82671ef0` | **`WSDamageable::ApplyDamage(WSDamageDesc const&)`** — root applier (the walled fn) |
| `0x82432c20` / `0x82432c08` | `GetHealth` / `SetHealth` |
| `0x82432bf0` | `IsDamageableAlive` |
| `0x826720a0` | `Die` |
| `0x82672108` | `SetupDamagableNode` — builds the damageable tree |
| `0x82672340` / `0x82672388` | `AddDamagableChild` / `RemoveDamagableChild` |
| `0x826724c0` / `0x82672500` | `AncestorDamaged` / `AncestorDied` (upward propagation) |
| `0x826723d0` / `0x82672448` | `TellChildrenAncestorDamaged` / `TellChildrenAncestorDied` (downward) |
| `0x82671e80` | `SetDamageableProperty` |

Per-type virtual overrides (`ApplyDamage` / `ApplyHitDamage`): `WSHuman` (`0x824f0d00` / `0x824f0618`),
`WSProp` (`0x8249bed8` / `0x8249be90`), `WSVehicle` (`0x825d5538`), `WSAnimatedObject`
(`0x8242eec8`), `WSTurret`, `WSTrainCarriage`, `WSGrenade`, `WSWeaponItem`, `WSPlayer`,
`WSSearchTurret`, `WSAIProp`, `WSModule`, `WSHealthEffectFilter`.

### Explosion solver — `WSExplosion`
| VA | Symbol |
|---|---|
| `0x824665e8` / `0x82466510` | `CreateExplosion` / `CreateExplosionDeferred` |
| `0x82465b60` / `0x824663d0` | `Update` / `UpdateDeferred` |
| `0x824653e0` | **`AddVictim(WSPhysicsObject*, WSForceDesc const&, WSDamageDesc const&, float dist)`** — the per-victim force+damage application (= our `ApplyExplosionToBodies`); force and damage computed together, with a distance arg = the falloff input |
| `0x82467318` | **`IsVictimShieldedFromExplosion`** — LOS / cover check (= our stand-in's optional raycast) |
| `0x824672c8` | `VictimShouldWait` (deferred-queue gating) |
| `0x82467178` / `0x82467280` | `RemoveVictim` |
| `0x833496a8` / `0x83349670` | `ms_VictimAllocator` / `s_ExplosionList` (static pools) |

### Destruction → physics — `WSDestructable`
| VA | Symbol |
|---|---|
| `0x82678a50` | **`WSDestructable::UpdatePhysicsObjects`** — decouples destroyed subparts into physics bodies |

### Force / impulse — `WSForceDesc` + `ApplyHitForce`
| VA | Symbol |
|---|---|
| `0x829e8cb0` | **`WSPhysicsObject::ApplyHitForce(WSForceDesc*)`** — Havok impulse leaf |
| `0x826c1510` | `WSOrdnanceReactionHelper(WSHuman*, WSHuman*, WSForceDesc const&)` — ragdoll/reaction from a hit |
| — | `ApplyHitForce(WSForceDesc*)` virtual on Human/Prop/Module/CollisionObject/ItemCache |

### The two descriptor structs (field layouts pending — from PDB type stream)
- `WSDamageDesc` — ctor `0x82459578`, copy-ctor `0x8238f6f8`. Known member accessor `BulletDamage() const` (`0x82503ce0`) ⇒ carries a damage-type/flag set. Consumed by every `ApplyDamage`.
- `WSForceDesc` — ctor `0x824676e0`, assignment `0x82467588`. Consumed by every `ApplyHitForce`.

## How this maps onto our `mercs2_combat/damage.rs` CONFIRM-LIVE gaps
| damage.rs stand-in | WildStar named truth |
|---|---|
| `apply_hit` lowers `Health.cur`, posts DamageMsg/DestroyMsg | `WSDamageable::ApplyDamage` → health tree, `Die` |
| `detonate_explosion` radius sweep + optional LOS raycast | `WSExplosion::Update`→`AddVictim` + `IsVictimShieldedFromExplosion` |
| impulse "lands with the physics silo" | `WSForceDesc` → `WSPhysicsObject::ApplyHitForce` (Havok) |
| DamageKey taxonomy (ordinals guessed) | `WSDamageDesc` fields (exact, from PDB) |
| parent/child damageable propagation (not modeled) | `AncestorDamaged`/`TellChildrenAncestorDied` tree |

## Exploitation plan
1. **Load `WildStar_d.exe` (PPC-LE PE) + `WildStar_d.pdb` in Ghidra** (PowerPC:BE/LE + PDB import)
   → named PPC decomp of the ~10 core fns above **with struct field types**. Start with
   `WSDamageable::ApplyDamage`, `WSExplosion::AddVictim`/`Update`, `WSDestructable::UpdatePhysicsObjects`,
   `WSPhysicsObject::ApplyHitForce`.
2. **Extract `WSDamageDesc` / `WSForceDesc` layouts** from the PDB type stream (llvm-pdbutil / cvdump /
   DIA — none installed yet).
3. **Port names → our x86 GOG decomp** by anchoring on the embedded source-path / assert strings
   (`d:\projects\wildstar\code\{pebble,odin,puckel}\…`) that appear in *both* builds, plus vtable shape.
4. **Replace `damage.rs` CONFIRM-LIVE stand-ins** with the WildStar algorithm, clearly marked
   `// WILDSTAR-SOURCED (sibling engine — verify vs Mercs2 live capture)`.

---

## Recovered algorithm (decompiled — `WildStar_d.exe`, BE PPC)

Ghidra import **`PowerPC:BE:64:A2ALT-32addr`** (Xbox 360 Xenon = 64-bit ISA + AltiVec, 32-bit
addresses), names applied from `WildStar_d.map` → `output/_ghidra_saboteur/wildstar_damage_decomp.txt`
(24 fns). **All 24 decompile with ZERO bad instructions** — full recovery.

> **Language gotcha (recorded so nobody repeats it):** the first import used `PowerPC:BE:32:default`,
> whose SLEIGH lacks the 64-bit `std`/`ld` that Xenon uses in every prologue (`__savegprlr`), so the
> decompiler truncated every function at the first `std` (`halt_baddata`). This looked like a "VMX128
> SIMD gap" but was purely the wrong language. `A2ALT-32addr` fixes it; no VMX128 extension was needed
> (the vector math is done via Havok helper `bl`s, not inline VMX128). Honesty boundary still applies:
> WildStar numbers, verify vs Mercs2.

### `WSDamageable::ApplyDamage(WSDamageDesc const&)` — the core formula
```c
if (!(this->flags@0xC & 0x80)                         // not part-node/invincible-gated
    && (bp==0 || bp->AcceptsDamageOfThisType(desc))   // WSDamageableBlueprint @vtbl, 0x826706e0
    && this->health@0x8 > 0.0) {
    newHealth = GetHealth()                            // vtbl+0x24
             - desc->amount@0x20 * bp->damageScale@0x8;   // ← THE damage line
    SetHealth(newHealth);                              // vtbl+0x20
    this->vtbl+0x2c(this);                             // OnDamaged / propagate to parent
    if (this->health@0x8 <= 0.0) {
        if (this->flags@0xC & 0x80) this->hits@0xE++;  // part node: tally, don't die
        else Die();                                    // vtbl+0x8
    }
    DamageDebugRender::RegisterDamage(this, oldHP-newHP, desc+4, desc->type@0x0);
}
```

### `WSDamageable::Die()`  (0x826720a0)
```c
this->health@0x8 = 0.0;
this->vtbl+0x30(this);        // OnDie: fires destroy notify / spawns wreck
this->flags@0xC |= 0x10;      // set DEAD bit
```

### `WSDamageable::SetupDamagableNode()` — damageable tree by CRC-name
```c
if (this->parentHandle@0x24 == 0 && this->parentCRC@0x20 not empty) {
    obj = WSGameObjectManager::GetObject(this->parentCRC@0x20);   // resolve parent by name-CRC
    parent = obj->GetDamageable();                                // game-obj vtbl+0x1a8
    if (parent) WSDamageable::AddDamagableChild(parent, this);
}
```
⇒ parent/child propagation (`AncestorDamaged`/`TellChildrenAncestorDied`) is wired from a
name-CRC parent reference on each node, not a raw pointer in the asset.

### `WSExplosion::AddVictim(WSPhysicsObject*, WSForceDesc const&, WSDamageDesc const&, float dist)`
Enqueue stage (deferred apply). Copies **{ForceDesc, DamageDesc, dist}** per victim into a
**bounded 32-entry** list (`victimCount@0x2c < 0x20` = `MAX_VICTIM`), dedupes piloted-vehicle
occupants, `PblListInv::AddLast(this@0xCCC, uvictim)`.
`UVictim` layout: `+0x4` ForceDesc, `+0x28` DamageDesc, `+0x68` slot-index, `+0x6c` dist.

### `WSExplosion::CreateExplosion(center, radius, baseDamage, …)` — the **falloff curve**
Havok AABB-phantom radius query, then per overlapping body:
```c
box = target bounding box;
if (box.Contains(center))  falloff = 1.0;              // point-blank / inside → full
else {
    dir  = targetPos - center;  dist = length(dir);
    falloff = (radius - dist) / radius;                // ← LINEAR falloff
    if (falloff < 0) {                                 // center beyond radius: retry vs nearest box point
        p = nearest point on box;  if (!ray hits box) skip;
        dist = length(p - center);  falloff = (radius - dist) / radius;
    }
}
if (falloff >= 0 && baseDamage * falloff > 0) {
    desc = WSDamageDesc(dir, pos, amount = baseDamage*falloff);   // per-victim scaled desc
    force = WSForceDesc(dir, …);
    AddVictim(dist * K_STAGGER, this, physObj, force, desc);      // K_STAGGER = 1/30
}
// after the loop: AddAabbPhantomMultiRayCastCommand(...) → cached per-victim shield factor
//                 (this@0x32d); read later by IsVictimShieldedFromExplosion
CameraShake(baseDamage, radius, ...);  AICombatHiveMind::AddDeferredEvent(...);  // + FX
```
⇒ **linear** falloff to the nearest point of the target's box, point-blank = full, ray/box coverage
gate, LOS via a batched multi-raycast cached per victim. `CreateExplosionDeferred` just queues args
to a list drained next frame by `UpdateDeferred`.

### `WSExplosion::Update()` — the apply loop
```c
this->timer@0x1c += dt;
if (this->timer@0x1c >= DEFER_WINDOW /*1.5s*/) { OnDone(); Deallocate(this); return; }
WSJoystick::SetLightEngine(...);                       // controller rumble on blast
for (uvictim in list@0xCCC) {
    uvictim->countdown@0x6c -= dt;                     // stagger: near victims (small dist*K) fire first
    if (VictimShouldWait(uvictim)) continue;
    if (IsVictimShieldedFromExplosion(uvictim)) { mark-processed; continue; }   // cached LOS shield
    ready = (uvictim->countdown@0x6c <= 0.0);
    victim = uvictim->obj@0x0;  human = victim->GetController();
    if (!human || countdown past ragdoll window) {
        if (ready) { ApplyHitForce(victim, uvictim->force@0x4);                  // impulse
                     if victim has skeleton: stash force on dynamic part, flag@0xac=1; }
    } else if (ragdoll not in world) {
        if (human->GetState()==3 && stateTimer>…) AddSetRagdollStateCommand(…);  // trigger ragdoll
        continue;
    } else if (ready) {                                                          // ragdoll in world
        mag = max(uvictim->amount@0x20, 200 /*force floor*/);
        imp = dir@0x10 * mag;
        for (b in 7 ragdoll bones) {                                             // 7-bone impulse spread
            rb = ragdoll->GetRigidBodyOfBone(boneTable[b]);
            AddApplyImpulseCommand(rb, imp * boneWeight[b]);                     // tables @0x8339ca08/24
        }
    }
    if (ready) { ApplyHitDamage(victim, uvictim->damage@0x28);                   // → WSDamageable::ApplyDamage
                 mark-processed; }
}
for (processed) RemoveVictim(...);
if (list empty) { OnDone(); Deallocate(this); }
```
⇒ blast **staggered by distance** (`dist*1/30` countdown → near victims first), per-victim
`VictimShouldWait` + cached-LOS gate, force via impulse (props) or 7-bone ragdoll spread (humans),
then the health `ApplyHitDamage`. Explosion lives ≤ 1.5s then frees itself.

### `WSPhysicsObject::ApplyHitForce(WSForceDesc*)`
```c
rb = hkGetRigidBody(this->hkBody@0x20);
if (rb && hkCollidable::getType==1 /*rigid*/) {
    mt = hkRigidBody::getMotionType(this->hkBody@0x20);
    if (mt != 7 /*FIXED*/ && mt != 6 /*KEYFRAMED*/)   // only dynamic bodies react
        ... hkRigidBody::applyPointImpulse(...) ...     // impulse math (VMX128 tail)
}
```

### `WSDestructable::UpdatePhysicsObjects()`
Per dynamic part: if the part's break flag@0x55 is set, read the driving bone's world matrix
(`WSSkeletonBone::GetWorldMatrix`), compose with the part's local offset@0x38, convert to Havok
space (`WSHavokManager::WorldToHavok`), and `WSPhysicsObject::SetMatrix` — i.e. keep the physics
body glued to the animated bone until the subpart detaches.

### `WSDamageDesc::BulletDamage() const`  →  `return (this->flags@0x38 & 1) != 0;`

### Struct offsets recovered (WildStar; verify vs Mercs2)
| struct | off | field |
|---|---|---|
| `WSDamageable` | 0x08 | health (f32) |
| | 0x0C | flags byte — `0x10`=dead, `0x80`=part/invincible-gate |
| | 0x0E | hit tally (u16, part nodes) |
| | 0x20 | parent name-CRC (`PblCRC`) |
| | 0x24 | cached parent handle |
| | vtbl +0x08 `Die` +0x20 `SetHealth` +0x24 `GetHealth` +0x2c `OnDamaged` +0x30 `OnDie` | |
| `WSDamageableBlueprint` | 0x08 | damageScale / vulnerability (f32) |
| `WSDamageDesc` | 0x00 | damage type/key | 
| | 0x20 | amount (f32) |
| | 0x38 | flags (bit0 = bullet) |
| `WSForceDesc` | 0x0C | direction vec (asserted normalized) |
| | 0x1C | magnitude (f32) |
| `WSPhysicsObject` | 0x20 | hkRigidBody | 0x34 boneRef | 0x38 local offset mtx | 0x88 skeleton link |
| `WSExplosion` | 0x1C | timer | 0x2C victimCount (max 0x20) | 0xCCC victim list |

### Constants (resolved from `.rdata`, WildStar)
| value | meaning |
|---|---|
| `1/30` (0.03333) | stagger `K` — per-victim delay = `dist × K` (blast "travels" 30 u/s) |
| `1.5` | explosion defer window / lifetime (s) |
| `200` | ragdoll impulse force floor (`max(amount, 200)`) |
| `1.0` / `0.0` | point-blank falloff / zero threshold |
| `0.6`, `50000`, `-1e6` | force-magnitude sanity/assert bounds |

Ragdoll per-bone impulse: 7 bones, bone-index table @`0x8339ca24`, weight table @`0x8339ca08`
(needs a clean re-extract — first read hit the wrong section).

## Mercs2 cross-validation — Jul-08 Xbox360 devkit prototype (`Mercs2_Xenon_P`)

The prototype (`output/jul08_prototype/mercs2_xenon_p.pe_ghidra.bin`, Xenon BE PPC, base 0x82000000,
**decompilable — no SecuROM**) registers its named profiler/action scopes at `0x8237f400–0x8237fbc0`.
That block enumerates the **entire Mercs2 explosion/damage pipeline by name** — confirming the WildStar
solver structure ports to Mercs2, with two Mercs2-specific refinements. Import with the **same Xenon
language** (`PowerPC:BE:64:A2ALT-32addr`); the `0x829d5xxx` decode warnings there are **genuine VMX128**
(unlike Saboteur's damage path) — the biallas VMX128 doc will matter for those bodies.

| Mercs2 scope name | WildStar analog |
|---|---|
| `GetExplosionCollector`/`Update`/`Collect`/`Return...Collector` | WSExplosion victim list + AABB phantom query |
| `ProcessExplosionCast`, **`ProcessDamageShadowCast`**, `Unfiltered/FilteredPass` | `IsVictimShieldedFromExplosion` LOS/occlusion (Mercs2 names it a first-class "damage shadow" cast) |
| `ApplyExplosionToBodies` / `ApplyExplosionToPrimary` / `ExpToObj` / `GetModifierData` | `WSExplosion::AddVictim` per-victim apply |
| `AppendToForceList`, `PhysicsCreateExplosion` | `WSForceDesc`→`ApplyHitForce` (Havok) |
| **`ApplyDamageToPrimaryHealth`** vs **`ApplyDamageToNodeHealth`**, `LookupNodeIdFromBodyId` | `WSDamageable::ApplyDamage` — **Mercs2 splits primary-hull HP vs per-node HP** (`RuntimeHealth` + `RuntimeNodeHealth`/`NodeHealth 11264` ECS pools) |

**Route to the actual Mercs2 bodies — BSim tried, too coarse (recorded so it's not re-attempted naively):**
A full BSim pipeline was built and run (H2 DB `analysis/bsim/xfork`, `medium_nosize`; Mercs2 sigs
committed; the ~10 named WildStar damage fns queried via `scripts/ghidra_scripts/BSimQueryTargets.java`).
**Cross-fork similarity is below the useful threshold:** most queries returned degenerate `sim=1.0`
hits to tiny CRT stubs (empty query vectors), and `WSHuman::ApplyDamage`'s best real cluster
(`FUN_824801e8`/`8247f9b0`/`82480578`/`824804c8`, sim≈0.29) turned out to be **debug-gated wrappers**
(shared `if(DAT_82c4ea68){…}` instrumentation shape), not the applier. The WS↔Pg fork + Havok 6.5→4.5
gap sinks true-match similarity under the instrumentation noise floor. **Better routes:** (a) anchor
on the Havok AABB-phantom overlap query — find its Mercs2 equivalent (via `hkpAabbPhantom` RTTI/vtable)
and xref callers → the explosion collector; (b) decompile the explosion `.obj` neighborhood and read it
against the WildStar template; (c) trace the profiler-scope handle from the `0x8237f400` registration to
its worker. Prototype Ghidra project: `analysis/wildstar_ghidra` program `Mercs2ProtoXenon` (analyzed).

### Status: **fully recovered** (scalar + curve + constants)
Nothing is SLEIGH-blocked. The only genuine SIMD in scope is inside Havok helpers
(`hkRigidBody::applyPointImpulse`, raycast), which are called, not inlined. Remaining refinements:
exact ragdoll bone weights, and confirming `desc.amount = baseDamage*falloff` is stored where
expected (the `func_0x831c3f58` "call" is the register-save thunk mis-modeled as returning the
baseDamage param).
