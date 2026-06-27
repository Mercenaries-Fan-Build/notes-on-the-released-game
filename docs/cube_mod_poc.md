# Custom-Geometry Proof-of-Concept — "Cube Mod"

> First demonstration of injecting **custom mesh geometry** into the native
> Mercenaries 2 (PC) engine via a `vz-patch.wad` overlay. Status: **WORKING
> in-game** — the supply-drop crate spawns as a cube and the game runs clean
> (loadprobe `REACHED-WORLD`, no crash). Date: 2026-06-20.
> Working build: `vz-patch.wad` sha256 `cad495af9c8629f30a794263ac5a5dd283ac9beffa8241fb70b3e2aee615bf8c`.

## What it proves

The modding deep-dive rates "new asset injection" as the hardest tier and lists
the ASET *name*-hash as an unsolved blocker (Open Question #6). This PoC sidesteps
that by **overriding an existing asset by hash** (last-opened-wins overlay) and by
**reusing a real model container's scaffolding** instead of authoring a model UCFX
from scratch — so the engine sees a vertex declaration, material/texture binding
and chunk layout it already accepts, with only the geometry changed.

Target: the **global delivery crate** (`resident2-global_deliverycrate`,
asset hash `0xE6A22510`) — already box-shaped and itself a spawnable supply-drop
object, so a cube is a clean, recognizable swap.

## How it works

`cube_mod` (Rust, `tools/wad_simulator/crates/cube_mod`) does:

1. Load FFCS from the source `vz.wad`; read + sges-decompress the target block
   (default the deliverycrate, PTHS index 5127).
2. Find the `model`-type UCFX container in the block and pass it to
   `mercs2_formats::model_cubeize::cubeize_model_container`, which:
   - snaps every STRM vertex's FLOAT16 position to a unit-cube corner
     (cube spans `x,z ∈ [-0.5,0.5]`, `y ∈ [0,1]`, sitting on the ground);
   - rewrites every 60-byte PRMG `INFO` bounding sphere + AABB to the cube;
   - recomputes the container's `CSUM` (`crc32_mercs2`).
   Everything else — chunk offsets, index buffers, vertex declarations,
   materials, texture references — is left **byte-identical**, so the output is
   the same length and splices back with no entry-table change.
3. Recompress the block (`sges::compress_sges`) and assemble a single-block
   `vz-patch.wad` with `patch_wad::build_patch_wad_multi`, carrying the block's
   ASET entries (selected by the block's own entry-table name-hashes). The
   builder repoints those hashes at the patch's block 0, so the overlay overrides
   the originals.

Because override is by **hash**, the source block is irrelevant to correctness:
the engine resolves `0xE6A22510` to the patch block and streams the cube. (The
base ASET actually maps that hash into `resident2_P000_Q3.block` entry 169; the
overlay supersedes it.)

## Build & deploy

```bash
cd tools/wad_simulator
cargo build --release -p cube_mod
WAD="…/Mercenaries 2 World in Flames/data/vz.wad"
./target/release/cube_mod --source-wad "$WAD" \
    --block-index 5127 \
    --output "$HOME/Desktop/Mercenaries 2 World in Flames/data/vz-patch.wad" --verbose
# --list to enumerate deliverycrate candidates; --target-name to auto-select.
```

Deploy = drop `vz-patch.wad` next to `vz.wad` in the game's `data/`. Reverting =
delete that one file. No original game files are modified.

## Validation performed (offline)

- `cargo test -p mercs2_formats --lib` — 146 pass, incl. the `model_cubeize`
  round-trip (output re-parses through `ucfx`/`model` readers; CSUM verifies).
- `cube_mod` run: 7 sub-meshes, 3442 vertices snapped, CSUM valid; LOD0's 1194
  vertices land on exactly the 8 cube corners, zero strays.
- `wad_simulator --wad vz-patch.wad --base-wad vz.wad` overlay simulation:
  **VERDICT — full consumption path completed without violations**;
  `type_id 19 model consumed … issues=0`; ASET "Hash Ownership Validation: all
  verified against block content".
  - The "ASET sub_entry OOB / heap corruption risk" line is a **retail-wide
    false positive**: retail's own entry for this asset has `sub_entry=5127` with
    `block_index=3183` (333 entries), which trips the same heuristic. The engine
    resolves by hash, not by `sub_entry` indexing.

## In-game verification (to run on the Proton box)

1. Launch (see `docs/linux_proton_runbook.md`):
   ```bash
   GAME="$HOME/Desktop/Mercenaries 2 World in Flames"
   STEAM="$HOME/.steam/debian-installation"
   PROTON="$STEAM/steamapps/common/Proton - Experimental/proton"
   SNIPER="$STEAM/steamapps/common/SteamLinuxRuntime_sniper/_v2-entry-point"
   STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM" \
   STEAM_COMPAT_DATA_PATH="$HOME/.local/share/mercs2-proton" \
   "$SNIPER" --verb=waitforexitandrun -- "$PROTON" waitforexitandrun "$GAME/Mercenaries2.cracked.exe"
   ```
2. Trigger a supply drop / find a global delivery crate — it should render as a cube.
3. Confirm the load itself is healthy:
   `tools/wad_simulator/target/release/loadprobe --no-color "$GAME/pmc_blackbox.log"`
   → expect `REACHED-WORLD` (note `EIP=0x00874E7D` is a hard-close, not a crash).

## Iteration log

- **v1 (model + textures override)** — loaded the world and spawned the player,
  then crashed at `EIP=0x004719C0` (AV WRITE) ~8.5s into world-load during model
  instantiation. Faulting object held `0xE6A22510` + `0x5B724250`; texture-stream
  return addresses (`0x008745xx`) were up the stack. Cause: the patch carried the
  crate's **texture** ASET entries and repointed them at the patch block, which has
  no mip data → broke texture mip-streaming.
- **v2 (model-only override)** — the patch now contains only the cube model as a
  single PRIMARY ASET entry; textures stream from the base WAD untouched. Offline
  re-validation: ASET OOB **0**, hash ownership verified, model issues **0**,
  verdict no violations. Awaiting in-game confirmation.
  - `cube_mod --no-cubeize` builds the same model-only override with geometry
    **unchanged** — run it to bisect plumbing vs geometry if v2 still crashes.

- **v3 (all crate models)** — the supply drop spawned a *different* faction crate
  than the one v2 overrode, so `cube_mod` became multi-block and now cube-izes all
  8 crate models (every faction `deliverycrate` + `crateaid`). The supply copter
  then winched in a cube-model crate — and hard-crashed at the same
  `EIP=0x004719C0` the instant it spawned.
- **Crash root cause = degenerate geometry.** `0x004719C0` sits in the engine's
  MESH chunk-handler cluster (`docs/exe_analysis_agent_a.md`: MESH `0x00471923`,
  SKIN `0x0047192A`). The models carry **no SKIN/HIER/bone/NAME** chunks (checked),
  and all sub-meshes store f16 positions at offset 0 (snap wrote the right bytes).
  The fault is that **corner-snapping collapses each sub-mesh's vertices onto ≤8
  points** — small sub-meshes (e.g. 48-vert LODs) collapse to a single point →
  zero-area mesh → AV write through a null spatial node. v1 (full block) and v3
  (model-only) differ in plumbing but crash identically, isolating geometry as the
  cause.
  - Index aside: the python `sges_decompress --index` scans sges blocks by
    occurrence, which diverges from the INDX `page_index` order the engine uses —
    always cross-reference blocks via the Rust path / INDX, not python `--index`.
- **v4 (clamp instead of snap)** — `model_cubeize` now **clamps** each f16 position
  into the cube bounds instead of snapping to corners. Outer vertices project onto
  the cube faces while inner ones stay put, so every face keeps its area (global
  crate LOD0: 329 distinct positions, not 8) — non-degenerate, still cube-shaped.
  Offline re-validation clean (8 primary, model issues 0, verdict no violations).
  Awaiting in-game confirmation.

- **v5 (identity bisection)** — a `--no-cubeize` override (byte-identical original
  geometry) crashed at the *same* `0x004719C0`. That ruled out the cube-ize edits
  entirely: the crash is triggered by *what model we override with*, not the shape.
- **Root cause = wrong source LOD (missing HIER).** The crate model hash exists in
  two structurally different forms, and the ASET `block_index` points at the
  **`resident2_P000_Q3`** aggregate (block 3183): **2 meshes + a HIER node**
  (~29 KB). `cube_mod` had been sourcing from the **`P001_Q2`** standalone block:
  **11 meshes, no HIER** (~155 KB). Overriding the asset with the HIER-less copy
  dropped the skeleton the spawn path wires up → null node → AV in the MESH
  handler. (Exactly the "bone at the top of the model" the user suspected.)
- **v6 (source from the ASET block)** — `cube_mod` now resolves each model hash to
  its ASET primary `block_index` and sources the container from THAT block, so the
  HIER and the engine-expected MESH/STRM layout are preserved (the cube-ize only
  rewrites STRM positions + PRMG bounds + CSUM). Verified: up-crate patch block has
  `HIER=1, MESH=2, STRM=2`, CSUM valid; sim verdict clean. Awaiting in-game test.

## Full custom-model import (FBX → universal → game) — WORKING

The PoC was extended from "reshape the crate" to a real asset-import pipeline, and
a Portal **companion cube** FBX now renders in-game on the spawned supply crate
(beveled edges + emblem insets clearly visible; using the crate's material for now).

Root format reversed (the enabler):
- **`IBUF`** = u16 **triangle strip**, degenerate-index joins (`tris = index_count − 2`).
- **`AREA`** = one **f16 per strip triangle = its surface area** (0 for degenerate
  joiners). Verified 24/24 by recomputing geometric area from the STRM positions.
- **`PRMT`** = 16-byte records `{u32 material, u32 start_index, u16 index_count,
  u16 base_vertex, u16 max_vertex_index, u16 vertex_count}` (one per material draw).
- **`STRM`** stride-20: f16 pos@0, pad@6, f16×2 UV@8, f16×4 normal@12;
  `info` = `{u32 flag(=4), u32 stride, u32 vertex_count}`.

Pipeline:
1. **FBX → universal** — parse the (6100) binary FBX, regenerate to glTF + npz with
   smooth normals + per-vertex UVs (`/tmp/companion_cube.gltf`).
2. **universal → game** — `tools/gltf_to_ucfx_model.py`: map into the model's vertex
   space, build a verified triangle strip, compute per-triangle AREA, encode STRM/
   IBUF, rewrite PRMG bounds + PRMT; **re-pack the container** (data area re-emitted,
   every offset recomputed, CSUM recomputed) while preserving INFO/HIER/MTRL/SEGM/
   PHY2/STAM byte-for-byte.
3. **Inject** — `cube_mod --inject-container <file>` builds the patch via the proven
   ASET/block plumbing.

Validation: `wad_simulator` `consume_model` → `model issues=0`, ASET verified,
verdict no violations; CSUM valid; HIER + PHY2 intact. In-game: spawns clean.

### Texture path (heart) — added

The companion model's material samples one texture, `0x21A2AFD1` ("global_pallet",
128x128 DXT1). Overriding that hash with the heart image puts it on the cube (the
FBX UVs already map the heart atlas onto the faces). `tools/dds_to_ucfx_texture.py`
encodes an uncompressed RGBA `.dds` to a **fully-resident** DXT1 UCFX texture
(INFO[26:32]=0 + `FFFF` sentinel, BODY = exact `linear_mip_chain_size`, so the
engine reads it inline — no streaming, no BUFFER_TOO_SMALL). `cube_mod
--inject-extra 0xHASH:TYPEID:file` carries it as a second PRIMARY override block
alongside the model. Validated: ASET verified, texture sweep clean, verdict no
violations. (Note: `global_pallet` is shared, so other pallets show the heart too.)

### On-hit crash: the crate is a multi-piece breakable (PAUSED here)

v9 (detailed companion cube + heart texture) renders beautifully but **crashes when
the crate is hit** — because the crate is a destructible and we preserved its
destruction data while replacing the geometry it indexes.

Findings (for resume):
- The crate breaks into pieces via an **undocumented** system: `SEGM` (per-piece
  `{u16 count, u8 node, u8 type}`, 13 records tied to the 13 `HIER` nodes; counts
  `2,2,2,8,8,7,7,6,6,5,5,4,4`), `SWIT` (intact↔destroyed HIER-node pairs, see
  `ucfx_mesh_codec.py:974`), and a `STAM`/`NODE`/`STAT`/`CEXE` state machine.
- Crash `EIP=0x00478F2A` (mesh-geometry handler), AV READ wild ptr, `EDX="CSUM"`.
  Registers show `EAX` → an array of **6 piece-objects** (400 B each, spaced 0x190)
  = the 6 SEGM count-pairs. On hit the engine builds the 6 pieces from SEGM/HIER and
  reads each piece's geometry; our re-pack (1 mesh, 1 PRMT, no per-piece partition)
  makes that read run off the end.
- Faithful break needs: reverse the SEGM→geometry partition, rebuild SEGM/SWIT/
  per-piece PRMT/HIER for the partitioned cube, and almost certainly **regenerate the
  PHY2 Havok 5.5 breakable bodies** (write a Havok 5.5 packfile — the hard wall;
  Sonic-Unleashed/`HavokAnimationExporter` 5.5 tooling is the lead).

**Status: PAUSED** pending an updated `wad_simulator` that validates the geometry/AREA
work (AREA tag now reversed — see [docs note]). Deployed in-game: v9 (detailed cube +
heart, crashes on hit). Options to resume: structure-preserving breakable (lower
detail, high confidence) vs. full destruction RE vs. keep v9 + make non-breakable.

## Notes / next steps

- The cube reuses the crate's original textures/material, so it renders shaded.
- To make a cube visible at the PMC base without triggering a drop, re-run
  `cube_mod` against a static base prop (e.g. a `pmcoutpost_*` model block) — the
  tool is generic via `--block-index` / `--target-name`.
- This "cube-ize an existing model" path proves geometry control; a from-scratch
  model encoder (true arbitrary import) is the natural follow-up, now that the
  block/ASET/CSUM/overlay plumbing is proven end-to-end.
