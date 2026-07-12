# Game config files (loose, moddable) — ground truth for pool sizes & quality knobs

These are copied verbatim from the retail install root / `data/`. They are **loose text config**
(not in `vz.wad`), so they were designer-tunable and are authoritative ground truth.

## `cdbsizes.ini` — component-database (CDB) pool presizing

Each line presizes one ECS component class's pool: `ClassName primary [secondary]`. `primary` = the
number of instances preallocated for the whole loaded world; the optional `secondary` (present on
~⅓ of lines) is **inferred** as a grow-chunk / overflow reserve (not verified against the loader).
The class names match the ECS component corpus (`docs/mercs2-ecs/`) and the COMP `info` type-names
our `placement.rs` parses.

Why this matters: the pool sizes are a direct readout of **what the world is made of, by scale**, and
they **corroborate the streaming architecture** we arrived at in
`docs/modernization/world_streaming_spec.md` §10 / 2b.

### Corroboration — LOD is a rare special case; hibernation is the pervasive residency mechanism

| Class | Pool | What it tells us |
|---|---:|---|
| `SceneObject` | **161280** | the world's total renderable-object ceiling — streaming must scale to ~161k objects |
| `HibernationControl` | **14080** | per-object stream-out/LOD distance directive is applied at huge scale → **this is how residency is driven** (matches per-object streaming) |
| `GenericLOD` | **128** | authored distance-LOD component exists for only ~128 objects world-wide |
| `RtGenericLOD` / `RtGenericLODProxy` | **32 / 32** | the runtime distance-LOD proxy system covers a handful of objects |
| `ModelName` | **4608** | the placement→mesh link (our keystone content path) — pervasive |
| `Model` | **8** | direct mesh-handle component is rare (content flows through `ModelName`, not `Model`) |
| `LowResTerrainObject` | **512** | ≈ our 400 assembled low-res terrain tiles (pool ≥ usage ✓) |
| `TerrainGuidMappingHighResToLowRes` | **512** | confirms the terrain **hi-res↔low-res GUID pairing** (the 2-tier terrain LOD, a real feature) |
| `TerrainObject` / `TerrainKey` / `RtTerrainChildren` | 1024 / 512 / 32 | terrain streaming/child pools |
| `Road` / `RoadIntersection` | 4608 / 2304 | the road graph is large (matches `layers_static` Road/RoadIntersection COMP counts) |
| `Flags` / `Name` / `ModifierKey` / `Label` | 14848 / 6912 / 6656 / 6400 | high-frequency per-entity metadata pools |
| `PropPhysics` (`_PropPhysics`) | **768** | per-prop physics is streamed for only ~768 props (matches `PropPhysics::Activate/Deactivate` by proximity) |

**Punchline:** `GenericLOD 128` vs `HibernationControl 14080` vs `SceneObject 161280` is the game's
own confirmation of our RCA — distance-LOD is a ~128-object special case, **not** the mechanism for
the world's geometry. The ~161k SceneObjects are kept resident/culled by per-object hibernation +
the size-keyed c3 spatial index, exactly the per-object streaming model in the spec (§10 2b). This
is why the earlier c3 "coarse↔fine LOD swap" was a misread and was reverted.

## `Mercs2.ini` — user quality settings (the LOD/streaming knobs)

`[Render]` holds the sliders that scale detail/LOD/streaming at runtime (0–3 style levels unless
noted):
- `ViewDistance=100` — **fog/atmosphere far-distance only, NOT draw or stream distance.** Unclamped
  (`FUN_00753280` → `DAT_00dfc348`). Its one and only reader is `FUN_007140b0`, which writes the
  atmosphere env-block's far field (`+0x44`) as `far = ViewDistance * k1 * k2 + base`, and only when
  the active atmosphere preset leaves that field on the "auto" sentinel `DAT_00beaef8`. It is read by
  no culling, LOD, streaming or block-residency code. See `render_distance_and_density_levers.md`.
- `ModelDetailLevel`, `DetailLevel`, `ParticleDetailLevel`, `ShaderLevel`, `WaterDetail`, `SkyDetail`.
- `EnableShadows`, `EnableScrub`, `EnableWaterEffects`, `MotionBlur`.

These are the real knobs our streaming/LOD tunables (e.g. `StreamingConfig::tier_stream_out`,
`block_unload_margin`) should eventually be *derived from* rather than hard-coded, so a `ViewDistance`
setting scales the per-object stream-out distances the way retail does.

> `GL.ini` is the EA GameLauncher/DRM string table (UTF-16), not world config — ignore for engine work.
