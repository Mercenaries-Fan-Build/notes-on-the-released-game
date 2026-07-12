# Valid UCFX Model Structure & Encoding — Reference Map

Built from three sources of ground truth: (1) the DLC skins that actually render
in-game (obama, sarah, mattias_v5), (2) real vanilla containers decoded
byte-level (hqsuites building, Phoenix car, UH1 heli), and (3) the engine-format
RE already banked (`Mtrl_Parse`, streaming, texture-component pool).

Purpose: stop authoring model containers from scratch and guessing at the
engine's expectations. This map focuses on **how to produce a container the
engine accepts (conform-not-author)** and on a **per-model-type structural
census** — the two things not already covered elsewhere.

> **AUTHORITATIVE tag/format references (read these first for tag semantics):**
> - [`docs/ucfx_tag_registry.md`](../ucfx_tag_registry.md) — 232 FourCC tags scanned
>   from the exe (VA-anchored, Validated/Registered status) + a curated model-path
>   semantics guide (§3: GEOM walker `FUN_00478120` → PRMG `FUN_00478270`; MTRL;
>   `decl`; the **PRMT field-semantics conflict**; SEGM = draw-group→bone binding).
> - [`docs/format_reference.md`](../format_reference.md) — FFCS WAD / `sges` /
>   UCFX blob / CSUM (§4.0) / **INDX MESH-group→HIER-node map (§4.2)** / texture /
>   Havok / terrain.
>
> This doc does NOT restate those; where it referenced a tag's meaning, defer to
> the registry. Corrections from reconciling against them are folded in below.

---

## 0. The governing principle — CONFORM, don't author

> **The engine REJECTS hand-authored UCFX models.** Custom decl / material /
> shader bindings authored from scratch are the root class of the sarah hang and
> the `0x004CC064` texture-component-pool crash. The proven method is to take a
> **REAL container the engine already accepts** and replace only the geometry,
> keeping the structural scaffolding (decl, chunk layout, material bindings,
> HIER, bone-index space) intact. **Every structural deviation is a bug.**
> (memory: `cj-foreign-model-import`, `sarah-dlc-port-and-skin-pipeline`.)

This reconciles the "no donors" mandate: the **geometry and textures are novel**
(not stolen); the **container structure is conformed** to a template the engine
trusts. obama and sarah are novel meshes inside a mattias/obama-structured
container — that is novel work, not a donor model.

**Consequence for this project:** `build_static_model` /
`build_skinned_model` (author-from-scratch) are the wrong tool. They invent
INFO/HIER/MTRL/GEOM/PRMG/PRMT/decl structure, and each invented field that
diverges from a real container is a latent crash. The gas station that "rendered"
did so via the donor-override (hijack-real-container) path — a pure from-scratch
container has **never** rendered. Confirmed by the `0x004CC064` crash reproducing
in vehicle slot, static slot, and even with a known-good material grafted in.

---

## 1. The chunk tree of a real static model

Decoded from `hqsuites` (0xD5D65249, a real static building). A UCFX container is
`"UCFX"` + `data_off:u32` + 8 reserved + `ndesc:u32` + `ndesc × 20-byte descriptor
rows` + 16-byte-aligned data area + `"CSUM"` + crc32_mercs2.

Descriptor row: `[tag:4][u0:4][size:4][u2:4][u3:4]`.
`u0 == 0xFFFFFFFF` ⇒ container node (children follow); else `u0` = data offset
(relative to `data_off`), `size` = body length, `u2` = #siblings-after,
`u3` = #children.

```
INFO                         model header (flags + bbox + LOD params)
HIER                         skeleton/hierarchy (root node + bones)
MTRL                         material table — N × 128B records (17 for hqsuites)
GEOM                         geometry container
  INFO                       mesh-group count
  INDX                       sub-object → seg_id map (u16 each) — ★NOT a HIER-node map
  MESH                       (one per LOD / group — hqsuites has 2)
    INFO
    PRMG                     primitive group
      INFO                   PRMG bounds (center/radius/min/max) + group hash
      STRM                   vertex stream
        info                 [flag=4][stride][vcount]
        decl                 vertex declaration (element table)
        data                 raw vertex buffer (vcount × stride)
      AREA                   per-strip-triangle surface area (f16)
      IBUF                   index buffer
        info                 [index_count]
        data                 u16 triangle-strip indices
      PRMT                   draw records — 16B each {mat_idx, start, count, ...}
SEGM / SWIT / STAT / CHDR    DESTRUCTION + state machine (destructible models)
CSUM                         crc32 trailer
```

Real static models are **multi-material, multi-group**, and destructible ones add
`SEGM/SWIT/STAT/CHDR`. A model injected into such a template must preserve **all**
of it — dropping the destruction chunks crashes the destruction/state reader
(`0x00478E43` family). Prefer a **non-destructible** template for props that don't
need destruction.

---

## 2. Per-chunk encoding (authoritative)

### MTRL — material record (decompile-verified vs `Mtrl_Parse` FUN_00858790)
Packed array of records; `PRMT.material_index` selects one. Each record:

```
off   size            field
  0   104 (26×u32)    PREAMBLE — color/emissive/specular float params
104   u16             flags       (material-type bits; NOT bounded < 0x200; real ≈0x418)
106   u16             tex_count   (1..=10 — the record-boundary signature)
108   tex_count×u32   texture asset hashes  (slot0=diffuse, 1=specular, 2=normal, 3+=extra)
...   8               trailing float props
```
- Inter-record **stride = 116 + tex_count*4**.
- Engine writes each slot to a **12-byte lazy-handle** `{hash, 0xF011157A, resolved_ptr}`
  at `mat+0xAC + i*12`, hard-capped at **10 slots**; raw hash mirror at `mat+0x144+i*4`.
- `flags & 0x200` ⇒ one extra env/cube texture from a global registry (`mat+0xA4`).
- **`tex_count` is the boundary signature** (high byte 0, low byte 1..10). A wrong
  count makes the engine walk param-floats as texture hashes → garbage
  texture-component → NULL pool pop → **`0x004CC064`** (and the mattias_v5
  `0x00858DB8` crash — same family).
- Texture hashes must resolve to **real texture assets** (type 0xF011157A). The
  playbook placeholder `0x68E14661` (= `pmcoutpost_bld_hqexterior_wall06`, not a
  texture) does not bind.

### STRM — vertex stream
`info` = `[flag:u32][stride:u32][vcount:u32]`. `decl` = D3D vertex-element table
(8B per element `{stream, offset, type, usage}`, `0xFF` terminator). `data` =
`vcount × stride` raw bytes. **Stride and decl must match a layout the shader
bound by the material expects** — this is a primary from-scratch failure point
(the engine rejects a decl the shader doesn't understand).

### PRMT — draw record (16B)
`[material_index:u32][start_index:u32][index_count:u16][base_vertex:u16][max_vertex:u16][vertex_count:u16]`.
`material_index` MUST be `< MTRL material count`. A single-material container whose
geometry references index ≥1 makes the engine read past the material array.

### INFO (model header, 72B), HIER (root 88B), PRMG INFO (60B), GEOM/INDX
See `tools/wad_simulator/crates/mercs2_formats/src/model_build.rs` for the
from-scratch attempt; treat those layouts as **hypotheses**, not authority — the
authority is a real container's bytes at the same tree position.

### CSUM
`"CSUM"` tag then `crc32_mercs2` over everything through the tag (inclusive).
`crc32_mercs2(data) == (zlib.crc32(data, 0xFFFFFFFF) ^ 0xFFFFFFFF) & 0xFFFFFFFF`
(verified against real container trailers). Any byte edit requires recompute.

---

## 3. Real vs from-scratch — the divergence table

| aspect | REAL static (hqsuites) | OUR `build_static_model` heli | risk |
|---|---|---|---|
| materials | 17 | 1 | geometry may ref mat ≥1 |
| MESH/PRMG/PRMT | 2 / 2 / 2 | 1 / 1 / 1 | LOD/group expectations |
| destruction chunks | SEGM/SWIT/STAT/CHDR | none | crashes destructible template reader |
| decl / stride | game-exporter decl | hand-written DECL20/DECL40 | **shader rejects unknown decl** |
| shader | vehicle/scene shaders | static `0x0A164785` everywhere | wrong shader for the render path |
| provenance | game exporter | invented | "every deviation is a bug" |

The from-scratch material is *structurally* plausible (flags 0x80, count 3, stride
128 = 116+3*4) — which is why grafting a known-good material didn't fix the crash.
The fault is in the **geometry↔shader↔decl binding** invented from scratch, the
exact class the corpus says the engine rejects.

---

## 4. The proven pipeline (use this, not from-scratch)

From the working obama/sarah/CJ path (memory `cj-foreign-model-import`,
`sarah-dlc-port-and-skin-pipeline`), the **8-stage template-conform** flow:

1. **Import** novel mesh (GLB/OBJ/FBX).
2. **Conform to a TEMPLATE container** — `model_inject` / hijack-real-container:
   take a real model container the engine accepts and rebuild only the geometry
   (STRM verts, IBUF indices, PRMG bounds, PRMT ranges), keeping decl / material
   bindings / chunk layout / HIER structure. For rigid props, a NON-destructible
   static template; for characters, `pmc_hum_mattias`.
3. **Weight-transfer rig** (skinned only) — novel vert ← nearest template vert's
   bone weights, in the template's bone-index space.
4. **Finalize** — tangent/f16/decl exactly as the template.
5. **Textures** — convert + inject the novel textures as real texture assets
   (type 0xF011157A); resident, coherence-gated, ≤ ~15 distinct.
6. **Package** — recompute page_count + CSUM.
7. **Wardrobe / placement** wiring.
8. **Validate** — `wad_simulator` clean (0/0) + coherence/cap gates.

The minimal proven variant (`model_cubeize.rs`): overwrite **only** per-vertex
POSITION bytes + PRMG bboxes + CSUM, leaving topology/decl/material/index
byte-identical — same total length. Requires the novel mesh to match the
template's vertex count/topology (fine for reposition, not for new topology).

---

## 5. Recommendation for the 5 static models

Retire `build_static_model` as the delivery path. Instead:

1. Pick a **non-destructible** static-model template per prop, sized/shaped
   roughly like the target (building→a real building shell; vehicle-like heli/
   tank→a real vehicle container; dog→a small creature/prop; boat→a boat).
2. Full-geometry-rebuild the novel mesh **into** that template
   (`model_inject`-style: replace STRM/IBUF/PRMG/PRMT geometry, keep decl /
   material-binding / shader / chunk-layout), recompute bounds + CSUM.
3. Inject the prop's **own** textures as real texture assets and point the
   template's material slots at them (keep the template's material COUNT and
   shader; only swap the texture hashes — the mattias_v5 fix pattern).
4. Validate with `wad_simulator` before any in-game test.

This inherits an engine-accepted structure (no `0x004CC064`), keeps the work
novel (our geometry + our textures), and matches how every skin that renders was
actually made.

**Open, separate bug:** inject-extra *resolution* — new asset hashes shipped in a
new block don't resolve into `layers_static` placements (why the 5 statics were
invisible even before any crash). That is a delivery-side issue independent of
container validity; overriding an existing (resolved) asset sidesteps it, which
is why the DLC skins ship as wardrobe overrides rather than brand-new hashes.

---

## 6. Exhaustive tag vocabulary & per-type census

### 6a. Every chunk tag seen in real model containers
(Census over heli/car×2/truck/van/semi/tank/apc/boat/motorcycle/building.)

| tag | role | conform action |
|---|---|---|
| `INFO` | model header (72B: flags+bbox+LOD) at top; also per-GEOM/MESH/PRMG group headers | **update top bbox**; keep group INFOs |
| `HIER` | skeleton/hierarchy — bones AND vehicle attachment hardpoints (wheels, seats, turrets, rotor) | **keep verbatim** |
| `NODE` | hierarchy node records (per HIER entry) | keep |
| `MTRL` | material table, N×128B records | keep; only repoint texture hashes |
| `GEOM`→`MESH`→`PRMG`→{`STRM`{info,decl,data}, `AREA`, `IBUF`{info,data}, `PRMT`} | geometry (see §1) | **rebuild geometry; keep decl** |
| `INDX` | **★CORRECTED 2026-07-12:** sub-object → **seg_id** map (u16). One entry per `MESH`/`SKIN` sub-object (NOT per PRMG group); the value indexes **`SEGM`**, not `HIER`. Node = `SEGM[seg_id].bone`. See `../modernization/vehicle_model_spec.md` §2 | keep; **must have exactly `sub_object_count` rows** |
| `SEGM` | **★RE-CORRECTED 2026-07-12:** the segment table — 4B `{u16 bone (LE), u8 seg_id, u8 state_mask}`. `state_mask` is the **LOD-tier bitmask** (not a "group"); byte order is **LE, not BE**; `SEGM[i].seg_id == i`. The RESIDENT block's SEGM serves the whole LOD chain | **keep verbatim**; if authoring, size it for ALL rungs |
| `PRMT` | ⚠ **field semantics UNRESOLVED (registry §3 / gap #4).** 16B/record; `[0]` is either prim-type (our `inject_static` writes 6) OR `matidx` (registry). Safe on ≥7-material templates; on a small template writing 6 as matidx could overrun → `0x004CC064`. **If the conform test crashes here, preserve the template group's original PRMT `[0]` instead of writing 6.** | rewrite geometry range; keep `[0]` verbatim (TODO) |
| `SWIT` | **★CORRECTED:** a FLAT list of node **hashes** that participate in destruction swaps — not per-state "node-index sets". The states themselves live in the `NODE`/`STAT`/`CHDR`/`CEXE` machine (`PristineState` `SHOW`s `0x255EAB53`, `DestroyedState` `SHOW`s `0x75F1F74D`; `SHOW`/`HIDE` act on the whole SUBTREE). See `../modernization/vehicle_model_spec.md` §5 | keep verbatim |
| `STAT` | destruction state records (state machine states) | keep verbatim |
| `STAM` | state-machine table (destruction/anim states) | keep verbatim |
| `CHDR` | ECS chunk-header / component container | keep verbatim |
| `CEXE` | compiled behavior/destruction bytecode | keep verbatim |
| `PHY2` | Havok collision packfile (hkpConvexShape / hkBaseObject) | **keep verbatim** (never author) |
| `CSUM` | crc32 trailer | **recompute** |

Sub-tags: `info` (chunk header: `[flag][stride/count][count]`), `decl` (vertex
element table), `data` (raw buffer).

### 6b. Per-type structural census (P000_Q3 representatives)

| type | example block | size | MTRL mats | PRMG/PRMT groups | strides | destruction+physics |
|---|---|---|---|---|---|---|
| helicopter | global_veh_uh1huey (3293) | 261 KB | 10 | 32 | 20, 28 | SEGM/SWIT/STAT/CHDR/CEXE/PHY2 |
| car | civ_veh_car (phoenix 3349) | 633 KB | 12 | 79 | 20, 28 | all |
| car | civ_veh_car_crx (3573) | 485 KB | 12 | 85 | 20, 24, 28 | all |
| truck | civ_veh_truck (3035) | 580 KB | 15 | 93 | 20, 28 | all |
| van | global_veh_van (3486) | 590 KB | 13 | 74 | 20, 28 | all |
| semi | oc_veh_semi (3016) | 100 KB | 12 | 8 | 20 | all |
| tank | vz_veh_tank_amx30 (3420) | 66 KB | 8 | 4 | 20 | all |
| apc | al_veh_apc_25mm (3181) | 74 KB | 8 | 9 | 20 | all |
| boat | civ_veh_boat_barco (3323) | 33 KB | 4 | 2 | 16, 20 | all |
| motorcycle | civ_veh_motorcycle (3562) | 69 KB | 9 | 9 | 20 | all |
| building | pmcoutpost_bld_hqsuites (3484) | 92 KB | 17 | 2 | 20 | all |
| trailer | civ_veh_trailer_flatbed (3149) | — | (pending census) | | | |

Fleet counts (P-all): truck 89, car 86, boat 39, tank 29, apc 24, helicopter 23,
semi 16, motorcycle 8, van 7, trailer 4, + named specials (stingray, rib36,
klr650, hondacrx, uh1huey…).

**Full type taxonomy (user-confirmed):** boat, truck, vtol, apc, helicopter,
tank, car, motorcycle, semi, trailer, van, towed. Not-yet-censused (blocks
located, dump flaky): **vtol** = `al_veh_vtol_f35b` (F-35B; also `hijack_f35b`
block 3235, `vehiclenameanimgroup_f35` 3261 — an `al_` faction asset, which is
why the `_veh_` filter missed it); **trailer** = `civ_veh_trailer_flatbed` (3149);
**towed** = `support_artillery` (3404). Expect the same destruction+PHY2 suite as
every other vehicle.

### 6c. The invariants (why conform is safe, and the rules)

1. **Every model — vehicle AND building — is destructible + physics-rigged.**
   All carry `SEGM/SWIT/STAT/STAM/CHDR/CEXE/PHY2`. There is no "simple
   non-destructible" template. `inject_static_into_donor_block` preserves ALL of
   these verbatim (it only rewrites STRM/IBUF/PRMG-bounds/PRMT/top-INFO/CSUM), so
   the destruction/collision/behavior machinery stays intact — this is why the
   conform validated clean where the from-scratch container crashed.
2. **Vertex `decl` varies by richness:** stride 16 (pos+uv+normal, minimal) → 20
   (adds a slot) → 24 → 28 (adds TANGENT). A container mixes strides across
   groups. NEVER impose a decl; read the target group's own decl and encode into
   it (`encode_strm_from_decl`).
3. **Group count scales with model complexity:** boats/tanks 2–9 groups; cars/
   trucks 74–93 (per-part: body panels, glass, wheels, lights, interior, damage
   variants). Injecting one merged mesh into one group + neutralising the rest
   renders the shape but loses articulation (spinning rotor, wheels, damage
   states). **Faithful conform maps novel parts → template groups.**
4. **Collision (`PHY2`) is the template's, not the mesh's.** A conformed model
   collides with the template's Havok shape, not the new silhouette — acceptable
   for render/props; for a drivable vehicle the collision hull should later be
   rebuilt (the model_cubeize commit noted "havok collision" pipelines exist).
5. **HIER carries the hardpoints** (wheels/seats/turret/rotor attachment). Kept
   verbatim → a conformed vehicle still has valid seats/mount points.

### 6d. Conform template selection per novel model (recommendation)

Pick the template whose **type + group structure** best matches the novel model,
so a faithful part→group mapping is possible later:

| novel model | template family | why |
|---|---|---|
| heli | `global_veh_uh1huey` | real heli: rotor/blade/body/gear groups + heli collision |
| tank | `vz_veh_tank_*` | turret + hull groups, tracked collision |
| boat | `civ_veh_boat_*` | hull, water-appropriate collision |
| dog (creature) | small `civ_veh_motorcycle` or a prop | few groups, small bbox |
| gas station (building) | `pmcoutpost_bld_*` (non-`hqsuites`, or accept destruction) | building shader + static collision |
| character | `pmc_hum_mattias` (skinned path, `model_inject`) | skeleton + bone-index space |

**Rule of thumb:** match group count roughly, keep the template's decl/shader/
destruction/collision, swap geometry + texture hashes, recompute bbox + CSUM,
validate with `wad_simulator` before any in-game test.
