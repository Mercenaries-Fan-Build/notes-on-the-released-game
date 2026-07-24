# Just Cause 2 — one-session recon (detour from Mercs2 RE)

Install: `C:\Program Files (x86)\Steam\steamapps\common\Just Cause 2`
Engine: **Avalanche Engine** (same lineage/family as our Saboteur sibling work; NOT Mercs2's engine).
Tool built this session: `tools/jc2/jc2_arc` (Rust, `flate2` only). Naming per `jc2_*` convention.

## TL;DR — what got deciphered
| Layer | Status |
|---|---|
| `.tab`/`.arc` split archive TOC | **SOLVED** — parsing + enumeration |
| Per-file zlib compression | **SOLVED** — 90% of pc0 entries are zlib |
| `SARC` sub-archive bundles | **SOLVED** — walked, **filenames recovered** |
| End-to-end file unpack | **SOLVED** — validated real DDS out of the pipe |
| DDS textures / FMOD FSB+FEV audio | identified (standard formats) |
| Binary property containers (`01 04 00 01`) | identified, structure partially mapped |
| `wrap-0c` gridded 16-bit data | identified, **terrain heightfield candidate (unconfirmed)** |
| Executable | clean 32-bit PE, **full RTTI**, no DRM — prime Ghidra target |

## Archive format (`archives_win32/pc*.{tab,arc}`, DLC/`pc_*`)
- **TAB** = table of contents: **16-byte header**, then **12-byte entries `{u32 nameHash, u32 offset, u32 size}`**.
  Offsets are **2048-aligned** into the sibling ARC. Verified empirically (offset+size chains match, alignment holds).
- **ARC** = raw concatenated payloads. **~90% of pc0 payloads are individually zlib-compressed** (`78 01` header) — inflate per entry.
- Archive set: pc0..pc4 (~3.6 GB) + `DLC/pc_*` + `pc4.arc` (patch/override, highest number wins like most Avalanche games).
- Names in the TAB are **hashes only**; real names live inside SARC bundles (below). The hash algorithm was not identified (not needed — SARC gives names directly).

## SARC bundles = the filename oracle
Some ARC entries decompress to a **small-archive**: `u32 len(=4)` + `"SARC"` + `u32 version` + `u32 dataLen`, then records `{u32 nameLen, name[], u32 offset, u32 size}`. Inner files may themselves be zlib.
- pc0 alone: **816 SARC bundles** (469 MB), **~25.9k embedded names recovered**.
- Asset taxonomy by extension (from recovered names):
  `rbm` 7182 (RenderBlockModel meshes) · `lod` 5052 · `pfx` 3647 (particles) · `dds` 2928 · `psmb` 2600 (physics static-mesh bank, likely) · `ban` 2332 (binary anim, likely) · `epe` 742 (entity/prop defs) · `cdoll`/`mvdoll` (cloth/ragdoll) · `aiteam` 123 · `agui` (GUI) · `event_trackb`, `acsb`, `cgd`, `pal`, `sst`.

## Other payload types
- **Binary property container** (`01 04 00 01`): typed node tree with 32-bit name-hashes + embedded ASCII keys. 1004 in pc0. Sample decoded = the **input-bindings config** (`MOUSE2`, `FIRE_LEFT`, `PLANE_PITCH_UP`, `PLANE_INC_TRUST`, `ZOOM_OUT`). This is Avalanche's runtime property/tweakable format; used for object/config definitions.
- **`wrap-0c`** (`0c 00 00 00` + count + array of smooth 16-bit LE values): pc3 is dominated by these (2522 entries / 424 MB) alongside 686 DDS. Low-entropy 16-bit grids ⇒ **terrain heightfield/clipmap candidate**, not compressed texture. Unconfirmed.
- **FMOD**: `FSB4` sample banks + `FEV1` event banks in pc0 (`fmod_event.dll`/`fmodex.dll` present). Same FMOD family we handled for Mercs2.

## Executable (`JustCause2.exe`) — far friendlier than Mercs2
- Clean **32-bit PE, no SecuROM/DRM virtualization wall**.
- **RTTI-rich**: real MSVC-decorated class names, e.g. `NGraphicsEngine::CRenderBlockFactory`, `NModelSystem::CModelManager`, `CRenderBlockCirrusClouds`, `CCreatureRenderBlock`, `CAIRoadFollower`, `CRoadFileLoader`, boost `sp_counted_impl_p<CFMODdesigner_*>`.
- Third-party: **Havok 5.5** (`hk55x`, `c:\work\3rdparty\havok\modified\hk55x`), FMOD Designer, `PathEngine.dll`, CUDA (`cudart.dll`/`cufft.dll` — GPU water/PhysX-ish).
- ⇒ A headless Ghidra decomp emits **named** classes/methods with almost no manual symbol recovery.

## Ghidra headless decomp — DONE this session
Ghidra 12.1 + JDK 21 are **bundled in the repo** at `tools/ghidra_12.1_PUBLIC` + `tools/jdk21`.
Run wiring (gotchas): the exe path has spaces → copy to a clean path first (`output/jc2_ghidra/JustCause2.exe`); point Ghidra at its JDK via the `JAVA_HOME` **env var** (the `JAVA_HOME_OVERRIDE=` line in `support/launch.properties` must stay empty/clean — a malformed value throws a ParseException). Post-script: `scripts/ghidra_scripts/JC2ExportAll.java`.

Auto-analysis succeeded in 483s (incl. Windows x86 **RTTI Analyzer**). Outputs in `output/jc2_ghidra/`:
- `jc2_functions.txt` — **41,376 functions** (2,792 non-`FUN_` named)
- `jc2_symbols.txt` — **368,374 symbols** (326k labels + 42k funcs)
- `jc2_classes.txt` — **3,554 distinct RTTI classes** (4,282 vftables)
- `jc2_all_functions_decomp.txt` — full decompiled C (ran to completion post-session)

### Subsystem map (RTTI namespace census — symbol counts)
`NAnimationSystem` 3205 · `NCtgAI` 1747 (contextual-goal AI) · `NGraphicsEngine` 1114 · `NCutscene` 732 · `NSoundLibrary` 673 · `NCharacterSystem` 434 · `NPaperDoll` 164 (character/vehicle customization) · `NModelSystem` 139 · `NMissionSystem` 104 · `NGlobalPathfinding` 90 · `NFMODdesigner` 84 · `NNetwork` 81 · `NAccomplishment` 75 · `NRuleSystem` 50 · `NAITeam` 42 · `NEvent` 33.

### RenderBlock types = the `.rbm` decode key (39 geometry types)
Each `.rbm` render block maps to a `CRenderBlock*` class (vertex format + shader). Full set:
`General, Lambert, CarPaint/CarPaintSimple, SkinnedGeneral, Foliage, BillboardFoliage, Grass, Leaves, Bark, Facade, DeformableWindow, Window, Box, AOBox, Merged, Open, Triangle, Line, Beam, Bullet, Flag, Halo, Occluder, SplineRoad, Skidmarks, Font, 3DText, 2DTex1/2DTex2, Clouds/SoftClouds/CirrusClouds, SkyGradient, FogGradient, Weather, Anark, Lights, DecalSimple/DecalSkinned/DecalDeformable`.
(Each has a paired `CRenderBlockType*` factory. Community `.rbm` importers are organized around exactly these.)

### AI goal catalog (`NCtgAI`, contextual-goal system)
`CGoal_AreaGuarded, AtNamedPoint, ChaseFollowTarget, DefendVehicle, Drive, FollowRegardlessly, Idle, InsideAreaOfOperations, NoPanicGoal, RoadPatrolled, TargetIsDead, TargetNotEscaping` (+ `TESTGOAL`). `NCtgAI::TSpecificGoalFactory<CGoal_*>` = the goal registry.

**Contrast with Mercs2:** no SecuROM, no VM-virtualized functions, real class names throughout. This exe is a *far* easier RE target than our primary game.

## `tools/jc2/jc2_arc` usage
```
jc2_arc list   <tab> <arc>              # content-type histogram (real magics, post-inflate)
jc2_arc names  <tab> <arc>              # dump embedded SARC filenames (hash \t size \t name)
jc2_arc unpack <tab> <arc> <outdir> [N] # extract real NAMED files from SARC bundles (validated DDS)
jc2_arc dump   <tab> <arc> <hash>       # hex+ascii of one decompressed payload
jc2_arc extract<tab> <arc> <outdir> [N] # dump every entry as <hash>.<ext>
```
Proof: `unpack pc4` → `pda_map_dif.dds` verified by `file` as `DDS 2048x2048 DXT1`.

## `.rbm` → GLB decoder (`tools/jc2/jc2_rbm`) — vehicles export to glTF
Goal: import JC2 vehicles into the Mercs2 modernization pipeline (GLB in → model-injection).
**Format fully reverse-engineered from the exe decomp** (not guessed):
- **Header (49B):** `[u32 len=5]"RBMDL"[u32 major=1][u32 minor=13][u32 rev][f32×3 bboxMin][f32×3 bboxMax][u32 numBlocks]`. (loader `FUN_00a45d30` checks ver **1.13** exactly.)
- **Block:** `[u32 typeHash]` → `Factory.Create(hash)` → `block.Read(stream)` → `[u32 footer = 0x89ABCDEF]` (validated as `-0x76543211`).
- **Geometry tail:** `[u32 vbCount][vb0=vbCount·s0]( [u32 vbCount][vb1=vbCount·s1] )?[u32 ibCount][ib=ibCount·u16]`, then optional post-index data before the footer.
  - Buffer readers: `FUN_00970e70` (VB stride 0x28), `FUN_00971680` (0x1C), `FUN_00951d80` (0x18), `FUN_0096aa90` (0x1C), index `FUN_0092d7f0` (u16).
  - **`CRenderBlockGeneral::Read` (`0x00973da0`):** `[u8 ver][68/76B consts][mtrl/textures][VB][IB]`, position = **f32×3 @ vertex offset 0**.
  - **`CRenderBlockCarPaint::Read` (`0x00955ef0`)** = hash **0xcd931e75** (car body panels): two vertex streams **s0=24 (f32 pos@0) + s1=28**, then IB, then ~1KB deform data before the footer.
- Resolving Read methods: vtable `Read` = entry `[+4]`; read from `.rdata` (`image_base 0x400000`, section-mapped) — e.g. General vtable `0xf23c9c` → Read `0x973da0`.

Decoder strategy: the material/texture section is polymorphic (vtable-driven), so we **skip it by scanning** for the vbCount whose (vb0[,vb1],ib) counts yield in-range indices covering the buffer, in-bbox f32 positions, and a reachable footer. Type-aware for known hashes (CarPaint two-stream). Self-validating.

**Results (proven):**
- `v024_sportscar` (all parts, hi-LOD): 14 primitives, 6191 verts, 4301 tris, bounds **2.09×1.45×4.74 m**, **0.0% degenerate tris**.
- `v076_jet_blackplane`: 9 primitives, 5924 verts, 5228 tris, bounds **23.8×4.8×28.6 m**, **0.0% degenerate**.
- 0% degenerate triangles across thousands of tris + realistic real-world dimensions = geometry is genuine, not a false byte-alignment fit.

Usage: `jc2_rbm glb <file.rbm | dir-of-parts> <out.glb>` (dir merges a whole vehicle, skips `_lod2/3/4`).
Pull a vehicle's parts first: `jc2_arc unpack pcN.tab pcN.arc <dir> --filter vNNN_lod1`.

**GLB scope now (FULL conversion):** POSITION + **NORMAL** (area-weighted smooth) + **TEXCOORD_0** (real UVs) + **JOINTS_0/WEIGHTS_0 skinning** + **embedded PNG textures / PBR materials**. Each source part = a named glTF joint (rigid bind, weight 1.0, identity inverse-bind) under a `skeleton` root — doors/mirrors/wheels individually poseable, drops into a skinned pipeline like Mercs2's. Verified: v024 sportscar (10 joints, 3 materials, decoded texture = the real **CIVADIER** car atlas), v076 jet (7 joints).

**UVs:** `u16×2` USHORT2N (÷65535) at stream0 offset 16. Confirmed — the main body block spans `uv[0..1, 0..1]` exactly (full atlas), sub-panels map sub-regions.
**Textures:** each block's material section carries length-prefixed `.dds` names (`_dif`/`_nrm`/`_mpm`). `jc2_rbm` extracts the `_dif` map, DXT-decodes it (BC1/BC2/BC3 in `src/image.rs`), PNG-encodes (flate2 zlib), and embeds it as a glTF `image`/`texture`/`material` (baseColorTexture, doubleSided, metallic 0 / rough 0.8). Textures must be in the same unpack dir (or `--textures <dir>`).

### Convert one vehicle (full recipe)
```
# 1. pull the vehicle's parts AND textures (broad filter catches vNNN-*, vNNN_lod1-*, vNNN_*_dif.dds)
jc2_arc unpack pc0.tab pc0.arc out/vNNN --filter vNNN
# (repeat for pc1/pc2 — vehicle assets are spread across archives)
# 2. decode + merge + skin + PBR-texture -> one GLB
jc2_rbm glb out/vNNN out/vNNN.glb
```
Output GLB = skinned, normal-shaded, full-PBR (base/normal/metallic-rough), ready to import.

### Batch — all 88 vehicles (54 unique base models)
```
# 1. one unpack pass per archive grabs EVERY vehicle asset (jc2_arc --vehicles matches vNNN[-_])
for i in 0 1 2; do jc2_arc unpack pc$i.tab pc$i.arc out/all_vehicles --vehicles; done
# 2. vehicle bodies also reference SHARED textures (lightset_*, window_*, flattangentspace_*, decals,
#    engine01_*) + prefixed vehicle textures (c_vNNN_body_*) that vNNN[-_] misses. Discover + fetch them:
find out/all_vehicles -name '*.rbm' -print0 | xargs -0 -n50 strings -n6 \
  | grep -ioE '[a-z0-9_/]+\.dds' | sed 's#.*/##' | tr A-Z a-z | sort -u > out/reftex.txt
for i in 0 1 2 3; do jc2_arc unpack pc$i.tab pc$i.arc out/all_vehicles --names out/reftex.txt; done
# 3. decode each model by prefix from the shared dir (jc2_rbm --prefix)
for v in $(ls out/all_vehicles/*.rbm | grep -oE 'v[0-9]{3}' | sort -u); do
  jc2_rbm glb out/all_vehicles out/$v.glb --prefix $v
done
```
Result: 54 GLBs (88 roster = reskin variants of 54 base models), ~44 MB, **50/54 fully textured** after the
shared-texture pass (step 2 took v024 3→6 materials, and the jet v076 0→4 — its body is `c_v076_body_*`).
`jc2_arc --names <file>` unpacks any SARC entry whose basename is in the list; `extract_textures` prefers
the vNNN-specific `_dif`.

### Import into Mercs2 (the injection path already exists!)
`jc2_rbm` GLB drops straight into the workshop's rigged-import bridge — no new converter needed:
```
mercs2_workshop --wad game-files/vz.wad \
  --mod-skel jc2_sportscar civ_veh_car_crx_racing out/v024.glb --mod-out out/jc2_sportscar_mod.wad
```
`--mod-skel` (`crates/mercs2_workshop/src/main.rs:301`) → `extract_skel_parts` (GLB primitives →
`publish::SkelRawPart`, per-material RGBA base-color) → `publish_skel` → `inject_fresh_skeleton`
(`mercs2_formats::model_inject.rs:4093`) mints a novel model on a fresh HIER skeleton (one bone per
part) inside a **donor** vehicle container, emitting the full HIER/SEGM/MTRL/PRMG/PRMT/INDX/AREA
chain + our PNG textures → MTRL slots.

**Match the donor to the vehicle class** — civilian cars = `civ_veh_car_*` (e.g. `civ_veh_car_crx_racing`,
`civ_veh_car_phoenix_racing`), military = `ch_veh_<tank|apc|boat|plane|truck>_*`. The donor supplies HIER
+ PHY2 + vehicle template, so a car belongs in a car donor, not a tank (a tank donor loads but is a poor
fit — wrong wheels/handling). Donor name is `pandemic_hash_m2(name)`; it must resolve to a container
present in the WAD stack (some model names like `veh_68valiant`/`civ_veh_car_crx` don't resolve — use the
exact resident container, e.g. `civ_veh_car_crx_racing`).

**PROVEN 2026-07-19:** v024 sportscar → donor `civ_veh_car_crx_racing` → self-test PASS
*6329 verts / 4425 tris / 22 groups*, fit scale **0.80** (proper car-to-car size match, vs 1.96 into a
tank). 14 parts → 14 novel HIER bones, 5 materials → MTRL (mip chains built). Whole JC2→Mercs2 chain
works end-to-end and self-tests green.

**MTRL slots — all three wired (2026-07-19).** `extract_skel_parts` now reads `baseColor`/`metallicRoughness`/
`normalTexture` from the GLB, and `publish_skel` encodes each and points the donor MTRL record's slots:
**slot 0 = diffuse (`_dm`) · slot 1 = specular (`_sm`, JC2 `_mpm`) · slot 2 = normal (`_nm`, JC2 `_nrm`, DXT5nm)**.
The slot order was **empirically verified** — I added a read-only `--dump-mtrl <donor>` diagnostic, decoded the
CRX donor's MTRL, and hash-matched its slot hashes to `<name>_sm`/`<name>_nm` (slot1=spec, slot2=normal). This
matches `MtrlMaterial::specular()`; the old `model_inject.rs` comment claiming "slot 1 = normal" was **wrong**
(corrected in place). Normal maps go through `texenc::encode_normal_full_chain` (swizzle `[nx,ny,nz]→[255,ny,255,nx]`,
BC3) = DXT5nm, which the shader's NORMAL slot expects (a plain BC1/BC3 normal renders creased/blotchy).
Verified end-to-end: injected `jc2_sportscar` MTRL 2 = `slot0=_dm slot1=_sm slot2=_nm`, self-test green.

Shared-texture gap CLOSED (2026-07-19): `jc2_arc --names <reftex.txt>` fetches the shared/prefixed textures the
bodies reference (see batch step 2). After that, injecting v024 gives **balanced 6/6/6 slots** (every material has
diffuse+specular+normal), self-test green. Remaining: turret/wheel hardpoint nodes beyond body/rotor; a couple of
textures live only in the pc3 texture archive under alternate names.

**Vertex attribute layout (from the per-stream byte-swap routines):**
- CarPaint stream0 (24B, `FUN_00945fa0`): `pos f32×3 @0` · `packed32 @12` (normal) · `u16×2 @16` · `u16×2 @20` (UV/tangent).
- CarPaint stream1 (28B, `FUN_0091ebd0`): 7× 32-bit fields (normal/tangent/color/extra UV).
- General (40B, `FUN_0091cca0`): 10 dwords — `pos f32×3 @0` + 7 (packed normal, UVs as f32/f16, color).

**Still to wire:** real UVs from the streams + DDS diffuse/normal/spec textures (`_dif`/`_nrm`/`_mpm`) as glTF materials (needs DXT decode → PNG); real (vs computed) normals from the packed field; per-vehicle part transforms via `.epe`.

## Known gaps / next steps (if we revisit)
- SARC name walker slightly over-reads padding at some bundle tails (a few hundred junk "names"); `unpack` is bounds-guarded so output files are clean. Tighten the entry-count/termination in `parse_sarc`.
- Confirm `wrap-0c` = terrain (correlate dims `0c 00 00 00 = 12`, second u32 count, vs known JC2 clipmap tile sizes).
- Decode the property-container node grammar (type tags `01 05 00 02 00`, hash→key table) to read object/tweakable defs.
- `rbm` RenderBlockModel geometry decode (7182 meshes) — the community/gibbed tools + the RTTI `CRenderBlockFactory*` class tree are the roadmap.
- Community reference: "gibbed" Just Cause 2 tools target this exact format — cross-check hash algo + property-container grammar there rather than re-deriving.
