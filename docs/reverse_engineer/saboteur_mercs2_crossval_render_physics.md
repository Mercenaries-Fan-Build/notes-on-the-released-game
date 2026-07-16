# Saboteur ↔ Mercs2 cross-validation — particles, ragdoll, water, lighting

Companion to [`saboteur_damage_solver_symbol_map.md`](saboteur_damage_solver_symbol_map.md) and
[`saboteur_mercs2_crossval_vehicle_save.md`](saboteur_mercs2_crossval_vehicle_save.md). Four WildStar
(Saboteur Xbox360 devkit) subsystems recovered as references for **open Mercs2 reimpl gaps**.

Reference decompiles: `output/_ghidra_saboteur/wildstar_subsystems_decomp.txt` (35 fns, Ghidra
`PowerPC:BE:64:A2ALT-32addr`, names from `WildStar_d.map`). **Honesty boundary:** WildStar is a sibling
fork (WS↔Pg, Havok 6.5 vs 4.5, Odin vs Pangea renderer) — algorithm *shape* is the reference; physics-
and render-touching constants are version-caveated; verify vs Mercs2. Some vector bodies are VMX128-heavy
(the SIMD math shows as stack temporaries); scalar structure is clear.

## Particle / FX  (Mercs2 gap: ALL particles/FX MISSING — the biggest hole)
1316 fns; the whole pipeline is named with bodies: `WSParticleEmitter` (Update/Render/RenderAsEmitter),
`WSParticleObject` (Update/Render/UpdateMatrix), `WSParticleTransformer::Update`,
`WSParticleEmitterSpawner::Update`, `WSParticleCluster` (Render/UpdateMatrix), `WSParticleGeometry::Render`,
`WSParticleRender::Render`.
- **Structure:** an emitter owns a chain of **transformers/sub-objects** (`+0x38`) and a **particle list**
  (`+0x28`). `Emitter::Update(dt)` ticks each transformer via its vtable; a transformer returning 0 =
  expired → `DeleteAndReturnNext` culls it. Emission/lifetime is a linked-list update+cull loop.
- **Reimpl value:** the *simulation* (emit → transform → lifetime cull → matrix update) is engine-agnostic
  and ports cleanly; only `*::Render` binds to the Odin backend (swap for wgpu). This is the reference to
  build Mercs2's absent particle silo against.

## Ragdoll  (extends the blast→ragdoll impulse in `mercs2_combat::damage`)
`WSHumanRagdoll` (44 fns): `Update`, `SetBodyToRagdoll`, `SetBodyDynamic`, `SetMotorStrengths`,
`SetBoneVelocity`, `SetInitVel`/`SetFinalVel`, `GetRigidBodyOfBone`, `GetRagDollBoneIndex`, `IsInWorld`.
- **Alive→ragdoll handoff (`SetBodyToRagdoll`):** for the bone, `hkRagdollInstance::getRigidBodyOfBone` →
  read the current animated bone transform (`hkQsTransform::getTranslation`) → world-to-Havok convert →
  `hkRigidBody::setPosition`. i.e. snap each ragdoll rigid body onto its animated pose, *then* release to
  physics. `SetMotorStrengths`/`SetBoneVelocity` blend the powered→limp transition.
- **Reimpl value:** completes the reaction the explosion path starts — `damage::detonate_explosion`
  computes the 7-bone impulse; `GetRigidBodyOfBone`/`GetRagDollBoneIndex` are the *same* calls the explosion
  apply used. Havok-version-caveated (6.5→4.5) but the state model (alive → snap bodies → dynamic → motored
  ragdoll) is faithful.
- **✅ LANDED (single-body stand-in):** `mercs2_combat::ragdoll` — a lethal blast on a `Ragdollable`
  character launches a `Ragdoll` body with the WildStar blast impulse (`max(damage, FORCE_FLOOR)` along
  blast dir, lofted), integrated under gravity + terrain-height collision + settle. Wired:
  `detonate_explosion` triggers it (`SetBodyToRagdoll` handoff), `gameplay::tick` runs `ragdoll_system`
  with the heightmap sampler, `spawn::spawn_character` marks humans `Ragdollable`. Closes the
  damage → death → visible-reaction loop. **Bounded:** one rigid body, not the 7-bone constrained Havok
  ragdoll — that lands with the physics silo. 31 combat tests pass.

## Water  (Mercs2 gap: water/swim scoped, not built)
`WSWater` (44 fns): `GetHeight`, `CalcWaveOffsets`, `GetVelocity`, `GetWaterLevel`, `Init`, `AddRiver`,
`DrawOcean`/`DrawRiver`.
- **Surface model = animated sine waves (`CalcWaveOffsets`, the clearest body):**
  `offset.x = cos((time + phase)·(freq/const))·amp`, `offset.y = sin(…)·amp`, plus a second wave component
  summed in — a two-component sine/Gerstner surface, not an FFT ocean. `GetHeight(pos)` samples that field;
  `GetVelocity(pos)` returns flow (for current/buoyancy drag); rivers are separate spline sources (`AddRiver`).
- **Reimpl value:** compact and complete — enough to build the watermap-query → water-render → swim-state
  chain: `GetHeight` drives the swim/buoyancy test, `GetVelocity` the current. (`GetHeight`/`GetVelocity`
  bodies are VMX128-heavy; the wave model from `CalcWaveOffsets` is the spec.)

## Lighting  (Mercs2 gap: dynamic `LightObject` unmapped, shadows absent)
`WSLight` (52 fns). `WSLight::Update` is a thin tail-call — **the light is a parameter container**, not a
solver. The value is the **cone/spot parameter set** (all named getters): `ConeColor`, `ConeLength`,
`ConeFallOffMin`/`Max`, `ConeEdgeFade`, `ConeAlphaMultiplier`, `ConeOnly`, plus `Activate`/`DeActivate`
(add/remove from the active light list).
- **Reimpl value:** names the exact spot/cone-light parameter set Mercs2's `LightObject` (0x97e8ee92)
  leaves unmapped — the fields a wgpu light needs. Renderer differs (Odin vs Pangea) so this is a param/
  structural reference, not a shading port.

## Recommended order for reimpl
1. **Particle/FX** — biggest hole, cleanest port (sim is engine-agnostic).
2. **Ragdoll** — completes the damage/explosion reaction already in `mercs2_combat`.
3. **Water** — small, self-contained, unblocks swim.
4. **Lighting** — param set for the light silo (shading is a separate wgpu effort).
