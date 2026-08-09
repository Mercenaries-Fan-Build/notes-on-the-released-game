# Asset Injection Playbook — novel models/textures → in-game assets

> Consolidated from the corpus (cube_mod PoC, heli-store experiment, DLC-skin work, spawn/name
> registry, PMC coordinates). Target = **retail PC** (`vz.wad` + a `vz-patch.wad` overlay,
> last-opened-wins). No original game file is ever modified; reverting = delete `vz-patch.wad`.
> This is the process doc for the five community tasks in `game-files/new-models/`.

## 0. The five tasks at a glance

| # | Asset | Source file | Content class | Placement / access | Difficulty | Status of the path |
|---|-------|-------------|---------------|--------------------|-----------|--------------------|
| 1 | Gas station | `gas_station_building.fbx` (24 MB) | **static prop** | in front of PMC main gate | 🟢 Low | Proven (companion-cube = static import in-game) |
| 2 | Survival character | `survival_character.fbx` (9.4 MB) | **skinned humanoid** | PMC wardrobe | 🔴 High | Loads; **weight-transfer/deform is the open link** |
| 3 | Soviet tank (T-34-85) | `soviet-medium-tank-…zip` | **vehicle** | buy from Eva (stockpile) | 🟠 Med-High | Model override proven; store-entry pattern proven; vehicle HIER/PHY2 is the risk |
| 4 | Russian transport heli | `russian-transport-heli.zip` | **vehicle** | buy from Eva | 🟠 Med | **Already scoped** in `heli_store_injection_experiment.md`; needs the round-3 close-out |
| 5 | German shepherd dog | `rsg_dogspack_…zip` | **novel static entity** | PMC, next to Fiona | 🟡 Med | Static import proven; novel = must be *new-asset* injection (no donor to override) |

The two things that make an asset "hard": **(a) is it skinned** (needs a rig + per-vertex weights on
the Mercs2 skeleton), and **(b) is it a genuinely new asset hash** (needs its own ASET entry, vs.
overriding an existing hash which is the easy last-wins path). Tasks 2 and 5 hit both; task 1 hits
neither.

---

## 1. The shared pipeline (four stages)

Every task is some subset of these four stages. The tools already exist — see
[cube_mod_poc.md](docs/cube_mod_poc.md) for the enabling reverse-engineering.

### Stage A0 — DCC preprocess (REQUIRED for asset-store models)  ⚠️ discovered 2026-07-08
Real community source models are **not** engine-ready. The gas station FBX is **27 parts,
~3.7 M triangles, multi-material, PBR, with unbaked FBX node transforms** — and
[tools/fbx_reader.py](tools/fbx_reader.py) reads *raw* Geometry verts, so it (a) ignores node
transforms (every part collapses to the origin) and (b) has no decimation. The target is a **2008
D3D9 console-era engine** (props ≈ 5–30 k tris). So every heavy model goes through Blender first:
- [tools/fbx_preprocess.py](tools/fbx_preprocess.py) (Blender 5.1 headless): import FBX (bakes node
  transforms) → join → triangulate → **decimate to a tri budget** → unweld to per-corner
  pos/uv/normal → convert Blender Z-up(RH) → engine Y-up → write the `.npz`
  `gltf_to_ucfx_model.py` consumes (+ a `.glb` for preview).
- **Tri budget cap**: the prototype game converter's degenerate strip uses ~6 indices/tri and the
  strip index is **u16**, so keep tris **< ~10,900** (default 9000). Verts must be < 65535 too.
- **Single merged mesh / single material** (converter limit). To keep the source's own materials you
  must bake a **texture atlas** in Blender and remap UVs; first-pass ships the **donor's material**
  (exactly how the companion cube shipped). Run:
  `"<blender>" -b -P tools/fbx_preprocess.py -- in.fbx out.npz --tris 9000 --glb preview.glb`

> Blender is a DCC authoring tool (mesh prep), orthogonal to the Rust-tooling mandate for the WAD
> pipeline. A proper **Rust multi-material importer + efficient strip encoder** is the real fix and
> would lift the single-material / ~9k-tri ceiling — backlog item.

### Stage A — Import & verify geometry  (universal mesh → engine UCFX model container)
1. **FBX → universal mesh** — for engine-ready low-poly single-part FBX,
   [tools/fbx_reader.py](tools/fbx_reader.py) (binary FBX 7100-7700 → per-part `.npz`) suffices; for
   anything heavy/multi-part use **Stage A0** (Blender) instead. All five source FBX are FBX 7400.
2. **universal → game container** — [tools/gltf_to_ucfx_model.py](tools/gltf_to_ucfx_model.py):
   maps into the donor model's vertex space, builds a verified `IBUF` triangle strip, computes
   per-triangle `AREA`, encodes `STRM`/`IBUF`, rewrites `PRMG` bounds + `PRMT`, **re-packs the
   container** (offsets + `CSUM` recomputed) while preserving `INFO/HIER/MTRL/SEGM/PHY2/STAM`
   byte-for-byte from the donor.
3. **Verify before injecting** — drag-drop the `.obj/.gltf/.glb` into **`mercs2_workshop`** (native
   engine renderer) to eyeball orientation/scale/geometry, or use the three.js viewer
   (`/browser-screenshot`). This catches decl/tangent bugs offline. See
   [mercs2-workshop-devtool](memory/mercs2-workshop-devtool.md).

> **Reference vertex layout** (`STRM` stride-20): f16 pos@0, pad@6, f16×2 UV@8, f16×4 normal@12.
> Skinned human strides differ (stride-40, BLENDINDICES/WEIGHT @ +16/+20) — see Stage A′.

> ⚠️ **Destructible / LOD donor gotcha (IN-GAME-PROVEN 2026-07-08).** Most buildings and all vehicles
> are **destructibles**: a cheap **`SWIT` node-swap** (intact↔broken HIER node) where each mesh group
> carries **twin/multi PRMT records** (a state/LOD pair). The state machine iterates those sub-records,
> so a converter that **collapses PRMT to one record** makes it read off the end → AV into `CSUM` at
> `0x00478E43` **at model instantiation** (crashed the gas station until fixed). `gltf_to_ucfx_model.py`
> now **preserves the donor's PRMT record count** (duplicates the full-strip draw per sub-record,
> keeping each material). It is NOT a Havok/SEGM problem and needs no destruction recompute — the twins
> are byte-identical. `wad_simulator` does NOT catch this (ASET/consumption only) → test in-game.
> Applies directly to the tank & heli donors.

### Stage A′ — Skinning (character rigs — SOLVED 2026-08-02)
Foreign skinned **characters** are **proven loadable AND deforming** in-game (RuMerc1, user-confirmed
his real skin renders + animates). The old "loads but renders **rigid-to-bone-0 (A-pose, no per-bone
deform)** until weights are transferred" limitation is **lifted for characters**. How it was solved:
- **Retarget onto a hero donor** — `retarget:` on `add_outfit` rigs the foreign mesh to the donor's
  skeleton (character-only: humanoid Role → hero like `pmc_hum_mattias` / `_jen`), producing the
  per-vertex `BLENDINDICES`+`WEIGHT`. This **supersedes** the earlier plan of a manual
  nearest-donor-vertex spatial copy through a hand-rolled multi-group split.
- **Dense rigs (>48 distinct bones) need `single_group: true`** — otherwise the rig is forced onto the
  multi-group balanced-split injector, which neuters donor host groups → renders **unstably**
  (culls/teleports on camera rotation). `single_group` skips donor transfer and packs the whole mesh
  into **one** host group on its own retargeted weights (RuMerc1: 53 bones/5 groups → 40 bones/45
  slots/1 group; commit `b02a605`). Residual costs: per-material textures collapse to one **baked
  diffuse atlas**, and the donor-resampled limb polish is skipped.
  ([dense-foreign-rig-needs-single-group](memory/dense-foreign-rig-needs-single-group.md)).
- Still-true structural fact: joints are **per-group palette-relative**, indexing the group `INFO(56)`
  range-table, NOT the global HIER
  ([blendindices-per-group-palette](memory/blendindices-per-group-palette.md)).
- Known skinned-render traps already solved: **DEC3N tangent** is 10-10-10-2
  ([dec3n-tangent-layout-bug](memory/dec3n-tangent-layout-bug.md)); atlas sub-textures with
  `sub_idx=0xFFFF` hang instantiation
  ([v5-skin-hang](memory/v5-skin-hang-is-engine-instantiation-not-deadlock.md)); a custom skin block
  missing its NAME chunk/`0xFFFF` sentinel loads but never binds → **samples black** (ship via
  `build_resident_texture`, commit `4691fbf` —
  [injected-texture-missing-name-chunk](memory/injected-texture-missing-name-chunk.md)).
- **Not proven beyond characters** — `retarget` is character-only; arbitrary skinned props/vehicles
  still take the template-conform geometry path (Stage A / `valid_model_structure_map.md`).

### Stage B — Textures  (PNG/JPG → fully-resident UCFX texture)
- **Engine is D3D9-era**: it consumes **base color (diffuse) + normal**, plus optional specular.
  The supplied **PBR maps — Roughness / Metallic / AO / Emissive / Opacity — have no native
  channel** and are dropped (or baked down: AO can be multiplied into base color, roughness→spec
  approximation). Only BaseColor + Normal survive as-is.
- **PNG/JPG → DDS → UCFX**: encode an uncompressed RGBA `.dds` with
  [tools/dds_to_ucfx_texture.py](tools/dds_to_ucfx_texture.py) → a **fully-resident** DXT1/5 texture
  (`INFO[26:32]=0` + `FFFF` sentinel, `BODY` = exact `linear_mip_chain_size`). Fully-resident =
  read inline, **no mip streaming, no `BUFFER_TOO_SMALL` livelock** — this is the safe path; do NOT
  ship partial-mip textures that stream (that's the whole [worldload-livelock](memory/worldload-livelock-dxt1-buffer-too-small.md) family).
- Watch the huge source textures: the heli set alone is 173 MB of PNG. Downscale to power-of-two
  (2048² max, usually 1024²) before encoding.

### Stage C — WAD injection  (build `vz-patch.wad`)
Two modes, chosen by whether you replace or add:

- **Override an existing asset by hash** (easy, proven) —
  [smuggler](tools/wad_simulator/crates/mercs2_smuggler/src/main.rs) (formerly `cube_mod`) `--inject-container <file>` overrides
  a model by hash; `--inject-extra HASH:TYPEID:file` adds texture(19=model,27=texture,35=script)
  overrides. **Source the donor container from its ASET-*primary* `block_index`** so `HIER`/`MESH`
  layout the spawn path expects is preserved (the cube-crate crash was a HIER-less donor LOD).
  Ship **model-only** overrides and let textures stream from base *unless* you also ship them
  fully-resident.
- **Inject a genuinely NEW asset hash** (fiddly, proven for scripts) — needed for the dog and any
  new store script. Requires **its own ASET entry** (block-idx + sub `0xFFFF` + type id). The
  heli experiment proved that without the ASET row the loader **wedges silently** at world-load
  ([heli_store_injection_experiment.md](docs/heli_store_injection_experiment.md) round 3).

Always **validate offline** with `wad_simulator` (0 violations, `model issues=0`, ASET hash
ownership verified) and **hash the output** before/after deploy
([verify-artifacts-by-hash](memory/verify-artifacts-by-hash-not-size-mtime.md)). Score the in-game
result with `loadprobe` on `pmc_blackbox.log`, never by eye (use `/analyze-game-log`).

### Stage D — Placement / registration  (making it appear & be usable)
This is where the four content classes diverge:

| Class | Mechanism | Key refs |
|-------|-----------|----------|
| **Static world prop** | Lua `Pg.Spawn(name_or_hash, x, y, z)` at a coordinate/marker. **Spawn-by-hash works natively** — a *number* arg to `Pg.Spawn` is used directly as the m2 hash, no patch. | [name-registry-spawn-by-hash](memory/name-registry-spawn-by-hash.md) |
| **Wardrobe skin** | Append `{Name,Model,PlayerVisibleName}` to `_tOutfits[sHero]` in `wifpmcinterior.lua`; lift the `GetAvailableCostumes()` gate; applied via `Player.SetProfileCostume` + `Player.SetOutfit`. Pure Lua. | [dlc-skin-swap-via-pmc-wardrobe](memory/dlc-skin-swap-via-pmc-wardrobe.md), [wifpmcinterior.lua:155](docs/mercs2-luacd/src/vz/wifpmcinterior.lua#L155) |
| **Store / stockpile item (Eva)** | Add a `tSupportData` catalog entry (`sName,nCashCost,nFuelCost,nMaxStock,sType,oSupport`) + register in `MrxRewardData.GetAllPotentialShopItems` + unlock (`tUnlockStatus={Pmc=1}`). `nCashCost=0`→free. **Requires full resident-block-3185 replacement + Lua recompile.** | [01_support_economy_delivery.md](docs/mercs2-luacd/01_support_economy_delivery.md), [heli experiment](docs/heli_store_injection_experiment.md) |
| **Layers_static placement** (baked, alternative to Pg.Spawn) | Add a `Transform`+`Name`+`ModelName{key,model_hash}` COMP triple. Faithful but injecting a *new* placement into retail is untested — prefer Lua `Pg.Spawn` for new objects. | [world_streaming_spec.md §2A](docs/modernization/world_streaming_spec.md) |

**Lua deployment**: resident scripts load from the block, **not per-hash** — a new/edited script
needs full block-3185 replacement (`build_patch_wad --block-index 3185` carries all ~7018 entries),
and a genuinely new script chunk needs `INFO/DEPS/BINN` + an ASET row + a non-cyclic parent DEPS
edge. Compile bytecode with `tools/lua51-mercs2/luac.exe` (PC LE header). Deploy as **overlay**, not
splice (splice broke world-load at 95%).

**Known coordinates** ([pmc-teleport-coords-and-interior](memory/pmc-teleport-coords-and-interior.md)):
- PMC **interior** (game-start spawn, where Fiona/wardrobe live): `(3794.04, 450.75, -3911.03)` — off-map high-Y cell.
- PMC **exterior** (back door → pool, ground level): `(2560.26, -13.18, -926.25)`.
- Named markers exist for gate/garage/helipad/dock/Fiona — resolve at runtime with
  `Pg.GetGuidByName(...)` + `Object.GetPosition(guid)` (e.g. `"PMC Fiona Car Spawn"`,
  `PMC001_Door_Front`). The **exact front-gate coordinate is an open lookup** (see §3).

---

## 2. Per-asset playbooks

### 2.1 Gas station building — static prop at the PMC main gate  🟢
The clean, low-risk case: no rig, no new gameplay behaviour.
1. **Import** (Stage A): `fbx_reader.py gas_station_building.fbx` → glTF; `gltf_to_ucfx_model.py`
   into a static donor's vertex space (any HIER-less static prop container). Verify in
   `mercs2_workshop`.
2. **Textures** (Stage B): base color + normal only → `dds_to_ucfx_texture.py` fully-resident.
3. **Inject** (Stage C): choose one —
   - **Simplest / proven**: `smuggler --inject-container` to **override an existing gate-area
     prop** by hash (e.g. a `pmcoutpost_*` building block). Zero new-asset risk; it appears exactly
     where that prop already is.
   - **True new building**: new-asset injection (new hash + ASET entry) + `Pg.Spawn(gas_hash, gx,
     gy, gz)` at the front-gate coordinate in a resident hook script.
4. **Placement** (Stage D): front-gate coordinate — resolve a PMC gate marker via
   `Pg.GetGuidByName`, or place relative to exterior `(2560, -13, -926)` after locating the gate
   (see §3). Buildings are large — set the transform so it faces the road, `y` snapped to terrain.

### 2.2 Survival character — PMC wardrobe
Skinned deform is **no longer the blocker** — solved 2026-08-02 (see Stage A′). Sequence:
1. **Assess the FBX**: confirm it's humanoid, closed mesh, A/T-pose (best retarget). If it
   has its own rig, `retarget:` maps it onto the Mercs2 human skeleton.
2. **Import + skin** (Stage A′): `retarget:` onto a hero donor rigs it (deformed + animated,
   not the old bone-0 A-pose); dense rigs (>48 distinct bones) add `single_group: true`. The earlier
   plan of a manual spatial nearest-vertex BLENDINDICES/WEIGHT copy is superseded.
3. **Textures** (Stage B): map to head/upper-body/lower-body slots; fully-resident; mind the DLC
   MTRL layout trap (DLC-human MTRLs parsed as 0 records — the `convert_mtrl` flag-word case). For a
   *fresh* import we control the MTRL, so we sidestep the DLC-only bug.
4. **Wire the wardrobe** (Stage D): append
   `{Name='Survival', Model='pmc_hum_survival', PlayerVisibleName='Survival'}` to
   `_tOutfits.mattias` (or chris/jennifer), lift `GetAvailableCostumes()`, ship in the resident
   block. Selection → `SetProfileCostume`/`SetOutfit`.
5. **Fallback if deform isn't ready**: it will load and display **rigid (A-pose)** — usable as a
   static-look skin proof while the weight-transfer lands. Be honest that animation is the open item.

### 2.3 Soviet tank (T-34-85) — buy from Eva  🟠
Vehicle = model + vehicle template (HIER turret/wheel bones + PHY2) + store entry.
1. **Import** (Stage A): tank FBX is low-poly (`T34_LP.fbx`, 3.4 MB) — good. Encode into a **donor
   tank** container (`vehicles_tank_*`, e.g. `m1a2`/`ztz98`) to **inherit its HIER + PHY2 + vehicle
   template** — do NOT author these from scratch. Turret won't rotate unless imported geometry is
   split onto the donor's turret HIER node (acceptable first pass: static turret).
2. **Textures** (Stage B): base color + normal (drop Roughness/Metallic/AO/Opacity).
3. **Inject** (Stage C): `smuggler --inject-container` overriding the donor tank's model hash.
4. **Store entry** (Stage D): add a `tSupportData` entry, `sType="Heavy"` (tank), `nCashCost` (or
   0 = free), unlock `{Pmc=1}`, register in `MrxRewardData.GetAllPotentialShopItems`. Follow the
   **heli experiment recipe exactly** (full block-3185 replace + ASET row + non-cyclic DEPS). If you
   reskin an *existing* purchasable tank rather than adding a new item, you skip the store-script
   work entirely — decide new-item vs reskin (see §3).

### 2.4 Russian transport heli — buy from Eva  🟠 (most scoped)
This one is **already half-built** in [heli_store_injection_experiment.md](docs/heli_store_injection_experiment.md).
- **Store entry** is defined: `tSupportData.russianheli` = `mrxsupportcopterdelivery` of
  `"Mi26 (PMC) (Driver)"`, `sType="Heli"`, `nCashCost=5000`, `tUnlockStatus={Pmc=1}`, appended to
  the PMC shop list.
- **Proven recipe** (round-3 lesson): (1) full resident-block-3185 replacement, (2) append the
  `mrxrussianheli` chunk with `INFO/DEPS/BINN`, (3) wire its hash into a **non-cyclic** parent DEPS
  (`mrxshop`, empty own-DEPS), (4) **add an ASET entry** for `0x3679F003` (block-idx + sub `0xFFFF`
  + type 35). Step 4 is the one that silently wedges if missed.
- **Then layer the model**: override `0x3177639B` → russian heli via the proven per-hash
  `smuggler` path (import the 1.76 MB `russian transport helicopter free.fbx` first; downscale its
  173 MB texture set hard).
- **Next action** = close out round 3 (V3fix2 was deployed but its in-game result table is
  unfilled) — boot, open Eva's vehicle menu, grep `RUSSIANHELI:` in `pmc_blackbox.log`.

### 2.5 German shepherd dog — GENUINELY NEW world entity by Fiona  🔴 (user: "test the limits" — option B)
Truly novel: no dog exists, and we disturb **nothing** existing. Chosen path = a brand-new
**`SceneObject`** world entity (not a `Pg.Spawn` template, not an override).

**What a spawnable/placed entity actually is (2026-07-08 research):**
- The engine's placed objects are **`SceneObject`** components (`0xb6185886`, stride 0x1c — "base
  placement/transform entity record"). The ~62k `layers_static` props ARE SceneObjects: a `Transform`
  COMP + `Name` COMP + `ModelName` COMP sharing one `u32 entity_key`
  ([world_streaming_spec.md §2A](docs/modernization/world_streaming_spec.md)). The engine simply
  loads and renders whatever placements it finds — no template registry needed for a static prop.
- `Pg.Spawn(name,…)` is the *other* mechanism (named entity **templates**, bit-31 handles in the name
  registry `0x00DF6B88`); creating a new template = ECS `worldentity` singleton authoring (deeper —
  not needed here).

**Recipe (the correct "new entity, disturbs nothing"):**
1. **Model = new asset** — `Mesh/SK_GermanShepherd_01.fbx` bind-pose (discard rig + `Animations/`) →
   Blender preprocess → container (structural donor for INFO/decl/MTRL) → `smuggler --inject-extra
   "0x<doghash>:19:dog.bin"` mints a NEW model asset + its own ASET entry. `doghash =
   pandemic_hash_m2("rsg_dog")`.
2. **Entity = new SceneObject placement** — add a `{Transform(key,pos,quat), Name(key,"rsg_dog
   0xKEY"), ModelName(key, doghash)}` triple to the **PMC interior state block (667)** at a spot next
   to Fiona. The dog then exists standing in the PMC — no Lua, no template, no animation.
3. **Textures** (Stage B): `T_GermanShepherd_B` (base) + `_N` (normal); drop `_R`.

**Tooling gap (the one thing to build):** `placement.rs` is **read-only**; there is **no COMP-block
writer**. Option B needs a new **COMP/CHDR writer** that parses the interior state block, appends the
three COMP records (correct relative/absolute child offsets — layers_static child offsets are relative
to data_area_start, vz_state absolute), and re-emits counts/offsets. This is the concrete build task
for the dog. Alternative interim (declined by user): override a spawnable statue template's model.

---

## 3. Open gaps / decisions

**Resolved (2026-07-08, user):** tank **and** heli = **new store items** (both full block-3185); the
survival character ships **rigid A-pose first**, animated deform as a follow-up *(superseded 2026-08-02:
animated deform now shipped — see Stage A′)*; textures downscale to
**1024²**; **build all five into ONE combined `vz-patch.wad` and run a single in-game test only once
all five are in it** (no per-asset in-game testing — offline `wad_simulator` validation between assets).

Still to look up while building:

1. ~~New item vs reskin~~ — **both new items** (resolved above).
2. **Exact PMC front-gate coordinate** — I have interior/exterior anchors but not the gate marker's
   world XYZ. Resolvable by dumping PMC named markers (`registry_hash_dump` / `Pg.GetGuidByName` on
   candidates like `PMC001_Door_Front`) or scanning layers_static for a `_pmcoutpost_*gate*`
   placement. One quick lookup.
3. **Fiona's live spawn position** — use the `"PMC Fiona Car Spawn"` marker or Fiona's GUID at
   runtime rather than a hardcoded coordinate (interior is off-map high-Y).
4. **Character animation expectation** — is a **rigid A-pose** survival skin acceptable as the first
   deliverable while weight-transfer lands, or is animated deform required up front? This sets task-2
   scope.
5. **Texture budget** — the heli's 173 MB / tank's 60 MB PBR sets must be downscaled + reduced to
   diffuse+normal; confirm acceptable resolution (1024² default).

## 4. Recommended execution order (easy→hard, each proves reusable machinery)

1. **Gas station** (static override) — exercises Stage A/B/C end-to-end, lowest risk, visible win.
2. **Dog** (static *new-asset*) — adds the new-hash + ASET-entry discipline on a model (small, static).
3. **Heli** (store item) — finish the already-scoped round-3; proves the Eva store-item pipeline.
4. **Tank** (store item + vehicle donor) — reuses #3's store pipeline + a vehicle HIER/PHY2 donor.
5. **Survival character** (wardrobe, skinned) — last by complexity (most moving parts: rig + textures +
   wardrobe wiring), though skinned deform is **no longer a blocker** (solved — see Stage A′).

## 5. Combined-WAD assembly (the build workflow)

Each asset is built as its own **part WAD** under `output/parts/`, then merged into ONE combined
`output/data/vz-patch.wad` (staging — NOT copied to the game `data/` until all five are in, per the
single-test-at-the-end rule). Reverting a bad asset = re-merge without it.

```bash
# per asset → a part WAD (model override / new-asset / store-block / placement)
smuggler --source-wad vz.wad --block-index <donor> --inject-container <c>.bin --output output/parts/<name>.wad
# fold into the combined WAD (copies each block + its ASET entries; replaces same-path blocks)
wad_builder merge-blocks --source output/parts/<name>.wad --target output/data/vz-patch.wad
# inspect + validate the combined
wad_builder list-blocks --patch-wad output/data/vz-patch.wad
wad_simulator --wad output/data/vz-patch.wad --base-wad vz.wad --skip-audio     # expect VERDICT clean, 0 violations
sha256sum output/data/vz-patch.wad                                              # verify by hash before deploy
# FINAL (only when all 5 in): cp output/data/vz-patch.wad "<game>/data/vz-patch.wad"  → single in-game test + loadprobe
```

### 5.1 A patch WAD's BLOCK SET is the contract — not its block count

A vehicle swap is **never** just the model. The custom tank at Fiona's spawn is **8 blocks**:

| block | what it does |
|---|---|
| `ch_veh_tank_ztz98_P000_Q3` | the conformed model container (`inject_parts` output) |
| `inject_<hash>` × 6 | the six skins (both road-wheel groups share material 7 → one texture) |
| `scripts_vz_P000_Q3` | **the `wifpmcgarage` bytecode redirect** — makes the garage spawn `ZTZ98` instead of `_ksFionaCar = "Phoenix (Racing)"` |

Drop `scripts_vz` and the model is still in the WAD, still correct, still validates — and the game
simply hands you **Fiona's stock car**, because nothing ever asks for the tank. The spawn redirect and
the model are two independent halves of one feature.

```bash
smuggler --source-wad vz.wad --exact-block --block-index 3565 \
  --inject-container ct.ucfx --inject-block "scripts_vz:scripts_vz_ztz.bin" \
  --inject-extra "0x<tex>:27:<tex>.bin" ...   # one per skin
```

**Always diff the block PATHS after a rebuild, never just the count** — a dropped script block and an
added texture both land on "8 blocks", and `wad-list` (models only) shows the model intact either way:

```bash
wad_builder list-blocks --patch-wad <new>.wad | grep '^  blocks'   # compare against the last good WAD
```

**Current combined WAD** (`output/data/vz-patch.wad`): gas station only —
1 block (`0xd5d65249` override), ASET 1/1 verified, 0 position violations, 29940 assets consumed,
VERDICT clean. sha256 `9127d617c73aa2bfbe9ef2b816be371a7db54520fb6b241c98936d024d345e33`.
```
