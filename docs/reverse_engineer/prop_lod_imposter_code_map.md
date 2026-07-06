# Prop LOD / imposters — Xbox↔PC code map

**Scope:** scoreboard **row 10 (Prop LOD / imposters)** — the *distance-driven* level-of-detail and
imposter surface: the runtime generic-LOD proxy system (`RtGenericLOD`/`RtGenericLODProxy`), the
per-model `MESH`/`TINY` imposter chunk dispatchers, the whole-region `_tiny` satellite/far-LOD
layers, and the `SEGM` state/LOD mask on prop sub-objects. This marries the **Xbox 360 devkit
(Jul-08 Profile build)** symbol/PDB ground truth to the **PC retail decompilation**
(`Mercenaries2.exe`, unpacked image, base `0x00400000`).

This is the row-10 companion to the streaming spine
([`world_streaming_code_map.md`](world_streaming_code_map.md)) and population
([`population_spawner_code_map.md`](population_spawner_code_map.md)) maps. **Residency** (per-object
hibernation, `HibernationControl` 14080-pool, terrain two-tier LOD `FUN_004a88a0`) lives in the
streaming map and is only cross-referenced here, not redone.

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/rendering-shaders.md`](../mercs2-pdb-analysis/rendering-shaders.md)
(renderable lifecycle + `Rt*` descriptor set) + `output/_ghidra_x360/xenon_decomp_named.c`
(base `0x82000000`). PC: the 27k-fn Ghidra decomp of the unpacked exe (function bodies read
first-hand and cited as `ghidra/FUN_xxxx`), the ECS registry
[`docs/mercs2-ecs/06_world_terrain_roads_streaming.md`](../mercs2-ecs/06_world_terrain_roads_streaming.md)
(the `Rt*` LOD section, verified + expanded below), the validated chunk-handler table
`tools/wad_simulator/crates/mercs2_formats/src/tag_registry.rs` (MESH/TINY/SEGM handler VAs),
`docs/game_config/cdbsizes.ini` (pool budgets), and the static-layer list
`docs/mercs2-luacd/src/vz/xQ!L.lua` (the `_tiny` region layers). Gap context:
[`docs/modernization/rendering_fx_lighting_gap.md`](../modernization/rendering_fx_lighting_gap.md) §A.
Companion memory: [[world-lod-and-destruction-scope]], [[world-streaming-spec]],
[[cdbsizes-component-pool-config]], [[multi-material-draw-groups]].

**Method / honesty model.** Same discipline as the sibling maps. PC retail strips every `Rt*`/`Pg*`
profiler string, and the LOD `Rt*` records are **engine-generated at world-load** (not stream-parsed
into named fields), so **there is no Xbox string anchor for the LOD runtime bodies** — the Xbox side
is *unlocated by name* and the marriages are **PC-anchored + structural**. Where a PC body was read
first-hand it is stated; where a claim rests on the tag-registry RE or on inference it is stated.
Confidence: **H** can't-coincide fingerprint (read body + matching constants/role) · **M** one strong
structural signal · **L/open** positional / confirm-live.

---

## 0. Result in one line

Row 10 is **PC-in-the-clear, Xbox-structural**: the `RtGenericLOD` generator (`FUN_0066ee80`), the
per-frame LOD-proxy consumer (`FUN_00490220`) and its **4-tier pre-squared band {near²,far²,handle,
proxy}** layout, its tick site (the layer-4 `Rt*` updater `FUN_00675e50` ← `FUN_004c9740`), and the
`MESH`/`TINY`/`SEGM` chunk surface are all recovered. The decisive retail fact stands and is
**confirmed by both the data and the pools**: distance-LOD is a **~128-object special case**
(`GenericLOD 128`, `RtGenericLOD/Proxy 32/32`) — the world's geometry residency is per-object
hibernation (14080), and the real "imposter" mechanism is the **whole-region `_tiny` static layers**,
not per-prop mesh swapping. The Xbox LOD runtime bodies stay **unlocated by name** (string-stripped +
runtime-generated).

---

## 1. Master marriage table (whole row at a glance)

Per-cluster evidence in §3–§6. A bare Xbox `.rdata` offset (or "—") means the Xbox *code body* is
unlocated (no string / runtime-generated) and the marriage is **PC-anchored**.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **RtGenericLOD generator** (bakes tier bands) | `Rt*` descriptor family (name-stripped; runtime-gen) | **`FUN_0066ee80`** (0x17b B) | read PC body: pre-squares near/far, writes 4×`{near²,far²,handle,0}`, count@+0x40 | H (PC) |
| RtGenericLOD **descriptor/registrar** | `RtGenericLOD` (PC-x-ref only) | **`FUN_00648680`** (desc `0x017c0708`, name@`0x017c0774`) | read PC body: stride **0x44**, pool 0x100, seed `0x9e3779b9`, `s_RtGenericLOD_00bc5f30` | H |
| **RtGenericLODProxy consumer** (per-frame band test) | — (runtime-gen; unlocated) | **`FUN_00490220`** (0x26c B) | read PC body: cam-dist², per-band spawn/despawn, §3 | H (PC) |
| RtGenericLODProxy **descriptor/registrar** | `RtGenericLODProxy` (PC-x-ref only) | **`FUN_00648740`** (desc `0x017c0758`, name@`0x017c07c4`) | read PC body: stream stride **0x04** (single handle), `s_RtGenericLODProxy_00bc5f40` | H |
| **Per-frame LOD tick** (drives the consumer) | game-systems master tick `FUN_822ff9b0` | **`FUN_00675e50`** ← `FUN_004c9740` | read PC body: iterates `RtGenericLOD` pool (`DAT_017c0758`) → `FUN_00490220(elem,handle)` | H |
| LOD-proxy **spawn** (create + pool-insert) | — | `FUN_006746d0` build → `FUN_0064a600` insert | read in `FUN_00490220` | H |
| LOD-proxy **despawn** (out-of-band) | — | **`FUN_004f30d0`** | read in `FUN_00490220` (proxy cleared to 0) | H |
| LOD-proxy **keep-alive** (in-band, exists) | — | `FUN_006658b0` | read in `FUN_00490220` | M |
| Authored **`GenericLOD`** component (design input) | `GenericLOD` (pool 128) | descriptor **unlocated this pass** (`0x0064xxxx` cluster) | pool `cdbsizes.ini` 128/64; it is the spatial-hash source the generator reads | M/open |
| **`MESH` imposter dispatcher** | renderable lifecycle `PgRenderableInitializer::Activate` `0x0041138` | **`0x00471900`** (entry `0x00471923`) | tag-registry RE: fixed **0x10-B** renderable / descriptor, **u16-indexed**, no body read | M |
| **`TINY` (low-LOD) dispatcher** | (same renderable lifecycle) | **`0x00471a01`** | tag-registry RE: fixed **0x18-B** renderable / descriptor, index-driven like MESH, no body read | M |
| `SKIN` / `INDX` sibling dispatchers | — | `0x0047192a` / `0x004719f3` | same jump-table cluster as MESH/TINY | M |
| **Mesh chunk assembler** (PRMG/INFO/…) | `Model::Render` family `0x0014ef8` | `FUN_00478120` → **`FUN_00478270`** | read PC bodies: PRMG/INFO/STRM/PRMT/IBUF/BSHI/BSHP/AREA walk | H |
| **`SEGM` state/LOD-mask consumer** (draw gate) | — (SEGM SecuROM-packed) | draw-setup **`FUN_00477e20`** + draw loop `~0x477Exx` | read: record `{u16 bone@0, u8 seg_id@2, u8 state_mask@3}`; byte-3 gates draw vs state @model+0x352 | H |
| **`_tiny` region satellite layers** (real imposter) | (static-layer load) | `Pg.LoadingStaticLayers` path (Lua-driven) | `xQ!L.lua` static list: `vz_*_tiny` per region; `TinyGeometryObject` ECS `0x06468e56` | M |
| `TinyGeometryObject` descriptor | `TinyGeometryObject` (pool 32) | `FUN_0063ed20` (deser `FUN_00639270`, 4-B handle) | ECS-doc 08; string-anchored | H |
| Renderable lifecycle (Activate/Deactivate/CanActivate) | `PgRenderableInitializer::{Activate,Deactivate,CanActivate}` `0x0041138`/`0x0041114`/`0x00410ec` | vtable slots in `&PTR_FUN_00bc5ff8` cluster | reference (rendering-shaders.md); confirm-live | L |

---

## 2. Where LOD sits in the frame (tick integration)

The LOD-proxy consumer is **not** a render-pass hook — it is a per-frame **simulation** step that
runs inside the same fixed-order layer-4 game-system list that ticks streaming and population
(cross-ref [`world_streaming_code_map.md`](world_streaming_code_map.md) §1):

```
FUN_004c14f0  MASTER UPDATE
  └─ FUN_004c15e0  5-layer stack (0→4)
       layer 4 → FUN_004c0ec0 → FUN_004c9740   (layer-4 per-system call list)
            ├─ FUN_00872d30   Stream_Manager_Update        (streaming map §2)
            ├─ FUN_00502510   PgSysPopulation::Update       (population map)
            └─ FUN_00675e50   Rt* per-frame updater  ← THIS  (LOD proxies + Rt anims/flow)
```

`FUN_00675e50` (5089 B, `param_1 = dt`, caller `FUN_004c997d` inside `FUN_004c9740`) is a **bulk
runtime-component updater**: read first-hand, it walks a series of `Rt*` pools in sequence — light
flicker/fade (head loop, `pfVar13[1] = clamp(handle.rate·dt + cur)`), color/alpha/scale animations,
`RtFlowCycleTimer`, and near the tail the **`RtGenericLOD` pool** (`DAT_017c0758` count, stride
`DAT_017c075c=0x44`, table `DAT_017c0770`), calling **`FUN_00490220(element, handle)`** per instance.
Gated off while `PTR_DAT_01175cdc[0x62] != 0` (a world/pause flag).

> **Doc reconciliation:** `rendering-shaders.md` labelled `FUN_00675e50` "`RtLightAnimation::Update`"
> (medium conf, string-bridged). That is **one arm** of this function — it is really the *shared*
> per-frame `Rt*` updater and the light-animation loop is just its head. The row-10 fact is that the
> **LOD-proxy consumer is dispatched from here**, from the layer-4 list, once per frame per LOD object.

---

## 3. LOD runtime core (H — PC bodies read first-hand)

### 3.1 `RtGenericLOD` generator — `FUN_0066ee80` (bakes the tier bands)

Reached via the `Rt*` world-load generation pass. It resolves the object's authored LOD source
(`FUN_005857e0`), then iterates a spatial-hash bucket writing the tier-band array and stamping the
band count at `+0x40`:

```c
// band cursor starts at record+0x08 (puVar3), stride 0x10, writes puVar3[-2..+1]:
puVar3[-2] = *(float*)(iVar4+4) * *(float*)(iVar4+4);   // near²  = (src.dist_near)²
puVar3[-1] = *(float*)(iVar4+8) * *(float*)(iVar4+8);   // far²   = (src.dist_far)²
*puVar3    = *(undefined4*)(iVar4+0xc);                 // handle = src LOD mesh/proxy handle
puVar3[1]  = 0;                                         // live proxy slot (runtime, 0 = none)
*(int*)(iVar2+0x40) = iVar5;                            // band COUNT at +0x40
```

**Field layout of the 0x44 record (read-confirmed):** four bands at `+0x00`, stride `0x10`,
`{near²:f32, far²:f32, handle:u32, proxy:u32}`; **band count at `+0x40`**. `0x40 / 0x10 = 4` ⇒ the
system is a **hard 4-tier** LOD. Radii are **pre-squared at bake time** so the per-frame test is a
bare float compare (no sqrt). The source record supplies un-squared `dist_near@+4`, `dist_far@+8`,
`handle@+0xc`.

**Descriptor/registrar `FUN_00648680` (read):** stride `0x44`, pool cap `0x100`, hash seed
`0x9e3779b9`, `CopyFromStream` vtable `0xbc4710`, shared pool vtable `&PTR_LAB_00bc5ff8`, name string
`s_RtGenericLOD_00bc5f30` written last. (m2 hash `0x0c51b633`.)

### 3.2 `RtGenericLODProxy` consumer — `FUN_00490220` (per-frame band test)

Read first-hand. Called once per `RtGenericLOD` instance from `FUN_00675e50` (§2), `param_1` = the
0x44 LOD record, `param_2` = the entity handle:

```c
if (PTR_DAT_01175cdc[99]=='\0' || *(u16*)(PTR_PTR_00dfc2f8+0x2b90) < 2) return;  // world+cam gate
cam = {*(f)(cam+0x19a8), *(f2)(cam+0x19a0)};        // camera pos @ PTR_PTR_00dfc2f8+0x19a0/0x19a8
FUN_00665af0();                                       // fetch this object's world pos (local_1c..24)
fVar6 = (dx*dx + dy*dy + dz*dz);                      // camera distance², un-squared vs pre-squared bands

for (band in [record+0x0c .. record+0x40], stride 0x10) {   // piVar5[-3]=near² -2=far² -1=handle 0=proxy
    if (dist² < near²  ||  far² <= dist²) {           // OUT of this band
        if (proxy != 0) { FUN_004f30d0(); proxy = 0; }        //   despawn proxy
    } else if (proxy == 0) {                          // IN band, no proxy yet
        for (vp in DAT_00d2ae64 viewport list, stride 0x810)  //   per active viewport
            FUN_006746d0(PTR_PTR_01176108, handle, &pos, &proxy, 0, 0);   // build proxy entity
        if (proxy) FUN_0064a600(proxy, &param_2);     //   insert into RtGenericLODProxy pool
    } else {
        FUN_006658b0(proxy);                          // IN band, proxy exists → keep-alive/update
    }
}
```

So each band is an **annular shell** `[near², far²)`; the object shows the band's `handle` renderable
while the camera distance is inside the shell, spawning a proxy entity on entry and despawning it on
exit. This is a **swap-in/swap-out of a distinct proxy entity per tier**, not an in-place mesh-LOD
index change.

**Descriptor/registrar `FUN_00648740` (read):** the **stream record stride is `0x04`** (a single
proxy handle — `DAT_017c07ac = 4`, the `name-0x18` elemSize slot), pool `0x100`, seed `0x9e3779b9`,
name `s_RtGenericLODProxy_00bc5f40` (m2 `0xce91973d`).

> **Resolves ECS-doc 06 ⚠ (0x04 vs 0x68).** The builder sets *two* size-shaped fields:
> `DAT_017c0790 = 0x68` and the elemSize slot `DAT_017c07ac = 4`. Only the latter is the **stream
> record stride** (mirror of `RtGenericLOD`'s `DAT_017c075c = 0x44`). `0x68` is a *different*
> descriptor slot (mirror of `RtGenericLOD`'s `_DAT_017c0740 = 8` — a runtime/bucket parameter, not a
> serialized stride). **Canonical stream stride = 0x04**; the `0x68` reading was a mis-attribution of
> that adjacent slot.

### 3.3 Pool budgets (both builds — the RCA)

| Class | Pool (`cdbsizes.ini`) | Meaning |
|---|---:|---|
| `GenericLOD` (authored) | **128 / 64** | authored distance-LOD directive exists for ~128 objects world-wide |
| `RtGenericLOD` | **32 / 32** | runtime baked tier-band arrays — a *handful* of objects |
| `RtGenericLODProxy` | **32 / 32** | live proxy entities — same handful |
| `TinyGeometryObject` | **32 / 32** | the "tiny" region/proxy geometry objects |
| `HibernationControl` | **14080** | per-object stream-out distance — **this** is how residency is driven |
| `SceneObject` | **161280** | the world's renderable ceiling |

`GenericLOD 128` ⋅ `RtGenericLOD/Proxy 32` vs `HibernationControl 14080` vs `SceneObject 161280` is
the engine's own confirmation of the row-10 RCA: **distance-LOD is a rare special case; per-object
hibernation + the size-keyed c3 spatial index is the world's residency mechanism** (see
[`world_streaming_code_map.md`](world_streaming_code_map.md) §4, [[world-streaming-spec]]).

---

## 4. Imposter chunk readers — `MESH` / `TINY` (and the mesh assembler)

### 4.1 `MESH` / `TINY` dispatchers (M — tag-registry RE; entry points are jump-table targets)

`MESH` (`0x00471900`, entry `0x00471923`) and `TINY` (`0x00471a01`) are **not standalone decomp
functions** — the handler VAs are mid-function jump-table entry points inside the model/renderable
consumer (siblings `SKIN 0x0047192a`, `INDX 0x004719f3` share the same cluster), so the dispatcher
body was **not read as a discrete `FUN_`**; the description is from the **validated** tag-registry RE:

- **`MESH`** — allocates a **fixed 0x10-byte renderable** per descriptor, **indexed by a u16**; *no
  body read, no count-driven array* ("engine-safe; no self-contained body invariant").
- **`TINY`** — allocates a **fixed 0x18-byte renderable** per descriptor, **index-driven like MESH**;
  no body read. `TINY` = the low-LOD imposter renderable variant (larger struct = it also carries the
  distance/fade state MESH doesn't).

So on retail data a model's LOD/imposter wiring is **a table of small renderable records keyed by
index**, not an inline geometry payload — the actual geometry comes from the shared mesh assembler
(§4.2) via the referenced handle. The distance switch that selects MESH-vs-TINY is the
`RtGenericLOD`/`Proxy` band test (§3), *not* logic inside these readers.

### 4.2 Mesh chunk assembler — `FUN_00478120` → `FUN_00478270` (H — read)

The geometry a MESH/TINY renderable points at is assembled here (read first-hand):

- **`FUN_00478120`** (MeshLOD_ReadChunks) walks the container's chunk table (`0x14`-stride entries),
  dispatching `PRMG` (`0x474d5250`) → `FUN_00478270` per drawing group (advancing a **0x1c4-byte**
  per-group struct), and `INFO` (`0x4f464e49`) → group-count header + `count·0x1c4` allocation.
- **`FUN_00478270`** (Mesh_ConsumeChunk, 1092 B) consumes the per-group sub-chunks: `STRM`
  (`0x4d525453`), `AREA` (`0x41455241`), `IBUF` (`0x46554249`), `BSHI` (`0x49485342`), `INFO`
  (reads **0x3c**=60 B of group bbox/decl into `+0x58..+0x69`), `BSHP` (`0x50485342`), `PRMT`
  (`0x544d5250`, per-sub-strip index/vertex buffers). **Multi-material note:** a `PRMG` group carries
  *many* `PRMT` sub-strips each with its own material (see [[multi-material-draw-groups]]) — relevant
  when an imposter/LOD mesh is a merged multi-material group.

This is the same assembler for full-detail and imposter meshes — LOD selection happens *above* it
(band test), not inside it.

---

## 5. `SEGM` state/LOD mask — reconciliation (H — consumer read)

`SEGM` itself is SecuROM-packed (absent from `output/_ghidra`), but the **runtime consumer is
decompiled** and pins the record byte-for-byte:

- **`FUN_00477e20` (draw setup):** `DAT_01164754 = *(u16*)(model+0x1c4 + (*(u16*)(model+0x1c2))*4)` —
  a stride-4 SEGM record array at `model+0x1c4`, indexed by the per-object seg index at `model+0x1c2`.
- **Draw loop (`~0x477Exx`):** `record = *(model+0x1e0)+0x50 + k*4`; indexes a **per-seg pointer
  array** `*(model+0x1e0)+0x58` by `record.byte@+2` (= **seg_id**) to fetch that segment's draw
  sub-object, and **gates drawing by `record.byte@+3` (state_mask)** against the current object state
  byte at `model+0x352`.

⇒ the SEGM record is **`{u16 bone@0, u8 seg_id@2, u8 state_mask@3}`**.

**Reconciliation (registry "group" vs engine "state_mask/LOD"):** the two names describe **different
bytes** and are both correct:

- **byte @+2 = `seg_id`** — the array index → draw sub-object. This is what the ECS registry loosely
  calls the **"group"** (which sub-object group this strip belongs to).
- **byte @+3 = `state_mask`** — the **state/LOD gate**: draw iff mask shares a bit with the object's
  current state byte (`model+0x352`). Our engine treats this as the LOD/state bitmask (default active
  bit `0x01` = top LOD/intact; destructible "livedin" shells invert: `0x02`/`0x03`=ruined, `0x04`
  =intact — `mesh.rs::build_indexed_state`). This is a **state/LOD selector, confirmed**, not a group.

So the engine's `active_bit` gate on byte-3 is validated against the decomp; the registry's "group"
label refers to byte-2. **Retail reality:** of 446 prop meshes, 766 sub-objects are SEGM
`state_mask=0x01` (tier-0), only ~7 sub-objects use other masks, and only 2–3 models have real
intra-model LOD — so byte-3 as a *distance*-LOD swap is a **near-no-op on retail props** (it is used
mainly for destruction-state variants, not LOD).

---

## 6. The real imposter mechanism: whole-region `_tiny` static layers (M)

Per-prop LOD being near-absent (§5) and the `RtGenericLOD` pools being tiny (§3.3), the actual
far/imposter representation of the world is **per-region single "tiny" meshes loaded as static
layers**. The master static-layer list (`docs/mercs2-luacd/src/vz/xQ!L.lua`, the
`_tDefaultStaticLayers` array) enumerates them alongside `vz_LowResTerrain` / `VZ_terrain` /
`vz_*_billboard`:

```
vz_caracas_tiny, vz_maracaibo_tiny, vz_amazon_tiny, vz_angel_falls_tiny,
vz_jungle_mountain_tiny, vz_merida_tiny, vz_guanare_tiny, vz_cumana_tiny,
vz_pirate_isles_tiny, vz_pmc_tiny
```

- These are **one satellite/far-LOD mesh per geographic region** (Caracas, Maracaibo, Amazon, …),
  loaded through the ordinary `Pg.LoadingStaticLayers` static-layer path (same mechanism as the
  low-res terrain and billboard layers), **not** per-prop.
- The chunk-level carrier is the **`TINY` renderable** (§4.1) + the **`TinyGeometryObject`** ECS class
  (m2 `0x06468e56`, descriptor `FUN_0063ed20`, deser `FUN_00639270` = a 4-byte handle/id; pool **32**,
  ECS-doc 08) — a lightweight object that just references a shared region geometry by id.
- **Satellite/overview view:** the string set `satellite` / `satelliteview` exists in the reversed
  identifier corpus (`docs/data/bone_name_candidates.txt`), consistent with a `Sys.RequestGameState`
  satellite/map view that toggles these whole-region `_tiny` layers on to render the zoomed-out world.
  The exact Object-switch / game-state binding is **inferred, not read** → confirm-live.

This is the honest answer to "per-prop vs region imposters": **the region `_tiny` layers are the
imposter system that actually ships content**; the `RtGenericLOD`/`Proxy` runtime is a real but
small-scale (32-object) system for specific proxy/vegetation-style objects; per-prop intra-model LOD
(`SEGM` byte-3) is essentially unused for LOD on retail data.

---

## 7. Xbox side (honest — mostly unlocated by name)

- The **LOD runtime** (`RtGenericLOD` generator, `RtGenericLODProxy` consumer) is **runtime-generated
  and string-stripped on both builds** — there is *no* Xbox profiler string for these bodies, so they
  are **unlocated by name on Xbox** and every marriage above is **PC-anchored**. The Xbox side is
  present only as the shared `Rt*` **descriptor registrar** (same `FUN_824fd430`/`FUN_824fcac8`/
  `FUN_824fd490` mechanism that registers all 232 descriptors; `0x9e3779b9` + the shared deserialize
  vtable `&PTR_FUN_82030fa0`) — see `rendering-shaders.md` "Render descriptor/components share the ECS
  reflection backbone".
- The **renderable lifecycle** that MESH/TINY renderables plug into *is* named on Xbox:
  `PgRenderableInitializer::Activate` `0x0041138` / `::Deactivate` `0x0041114` / `::CanActivate`
  `0x00410ec`, and the per-type `Model::Render`/`RenderZPass`/`RenderShadow` (`0x0014ef8`/`0x0014ec0`/
  `0x0014ed4`) + `TerrainMeshRenderable::*`. These are the Activate/Deactivate slots the PC
  `&PTR_FUN_00bc5ff8` component vtable cluster implements (structural; confirm-live to bind the exact
  PC vtable slots).
- **`RenderFadingTrees` (`0x0016a2c`) + `PgBillboardTree*` shaders** are the Xbox analog of the
  vegetation/billboard far-LOD path — the tree-specific cousin of the `_tiny` imposters.

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **`FUN_00490220` band constants live** — break entry, read the object's `RtGenericLOD` record
   (`+0x00..+0x40`): dump the 4 `{near²,far²,handle}` bands to recover the **actual LOD switch radii**
   (they're baked pre-squared; `sqrt` them). Confirms whether retail authors 2, 3 or 4 real tiers.
2. **Camera-pos source** — confirm `PTR_PTR_00dfc2f8 + 0x19a0/0x19a8` is the render camera (vs a
   viewport) and `+0x2b90 < 2` is the "need ≥2 viewports?" gate.
3. **Proxy spawn/despawn** — break `FUN_006746d0` (build) and `FUN_004f30d0` (despawn) with a proxy
   object in view to confirm they create/destroy a distinct entity (proxy entity vs in-place swap).
4. **Which objects even have `RtGenericLOD`** — with the 32-slot pool, dump `DAT_017c0758` count +
   the pool live and resolve the handles against the name registry (`0xDF6B88` family) to identify the
   ~≤32 LOD objects (vegetation? proxy props?).
5. **`GenericLOD` authored descriptor** — locate the `0x0064xxxx` registrar for the authored
   `GenericLOD` (pool 128) that feeds the `FUN_0066ee80` generator's spatial-hash source; unlocated
   this pass.
6. **`_tiny` / satellite toggle** — break the static-layer load and `Sys.RequestGameState` to confirm
   the `vz_*_tiny` region meshes are the satellite/overview imposters and how the view swaps them in.
7. **MESH/TINY dispatcher body** — the entry points `0x471923`/`0x471a01` are jump-table targets;
   break there to read the enclosing renderable-consumer function proper (0x10-B vs 0x18-B alloc
   confirmed statically from the tag-registry RE, not from a discrete decomp body).

---

## 9. Reconciliation with `mercs2_engine` (scoreboard row 10 = 🟡)

**Status: 🟡 — a 4-tier LOD is *computed* but informational; the terrain swap is the only real LOD
in-engine; per-prop imposter swap and the region `_tiny` imposters are not implemented.**

- **What matches:** the engine reads real `HibernationControl` distances for props and uses the real
  c3 spatial index for proximity (binary wake/hibernate) — the residency behaviour is faithful
  ([[mercs2-streaming-runtime]]). It also honours **`SEGM` byte-3 as the state/LOD mask**
  (`build_indexed_state` `active_bit`), which §5 validates against the decomp.
- **What is informational-only:** the engine computes a **4-tier proxy distance** `[350,350,700,1200]`
  for baked geometry but these are **inferred, not read from data** ([[world-lod-and-destruction-scope]]);
  §3 now gives the real mechanism to replace them — bake `RtGenericLOD` 4-band `{near²,far²,handle}`
  arrays and run the `FUN_00490220` shell test per frame in the sim tick.
- **What is missing (the faithful-impl targets):**
  1. **`RtGenericLOD`/`Proxy` runtime** — a 32-cap pool of 4-tier band records + the per-frame
     spawn/despawn shell test (§3), ticked from the engine's fixed schedule slot (mirrors
     `FUN_00675e50` ← `FUN_004c9740`). Applies to the ≤32 proxy/vegetation objects only.
  2. **`MESH`/`TINY` imposter renderables** — index-keyed 0x10/0x18-B renderable records that select a
     lower-detail handle; the geometry still assembles through the existing `FUN_00478270` path.
  3. **Region `_tiny` satellite layers** — load the `vz_*_tiny` meshes as static layers and swap them
     in for the satellite/overview view (the *actual* imposter system that ships content, §6).
- **Do NOT** gate draw groups on the destruction/variant state machine (`STAT`/`SWIT`/`CHDR` →
  `FUN_004cf340`) as if it were LOD — it is a gameplay state machine (buildings collapse), orthogonal
  to distance-LOD (`rendering_fx_lighting_gap.md` §J).
