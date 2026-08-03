---
name: density_upgrade_state
description: Current state of the Mercenaries 2 vegetation/prop density-upgrade effort — what is diagnosed, built, verified, and what remains. Root cause of every density wall pinned to the byte; M1 registry graft verified in-game; entity placement proven to top out at the render packet cap; M4 hardware-instancing diagnosed and designed but not yet built.
status: current
evidence: proven (root causes from live dumps + decomp) + built/verified (M1, tooling, runway) + designed-not-built (M4)
date: 2026-08-03
---

# Density upgrade — state of the effort

## 0. Objective

Make the retail 2008 Mercenaries 2 (Pangea) engine render JC2-scale vegetation/prop density —
without an engine rewrite. Everything ships additively: MinHook `.asi` grafts (loaded by `pmc_bb`),
overlay WADs that shadow base blocks (never mutating `vz.wad`), and additive shader variants. The
work is delivered as surgical splices at named decompiled seams (base `0x400000`, from
`output/_ghidra/mercs2_unpacked.exe_decomp.txt`).

The engine presents **two independent density walls**. Both are now root-caused to the byte.

---

## 1. Wall 1 — instantiation (the world-load hang)

Registering N entities into the world causes a main-thread hang at high N.

### 1a. SceneObject registry grow-storm — FIXED + VERIFIED
- The keyed `SceneObject` registry (`DAT_017c02f0`) inits with **capacity 0** and grows **linearly**
  (`new_cap = cap + 256`), full-rehashing every live entry on each grow (`FUN_0064a600`). Filling to
  ~130k entities is `256+512+…` = O(N²) rehash work on the main thread → a multi-minute freeze.
- **Fix (`density_regpresize.asi`, `tools/density_regpresize/`):** a MinHook detour on the one-shot
  registry init `FUN_00648850` overwrites the grow-from-empty size `DAT_017c0318` (base+0x28 — written
  exactly once in the whole binary, and never used in slot addressing) so the first insert presizes
  the entire table in a single allocation. The O(N²) storm becomes O(N). Config
  `scripts/density_regpresize.ini` `PresizeCapacity` (default 524288).
- **Verified in-game** (`density_regpresize.log`): the detour fires and re-applies `DAT_017c0318
  256 → 524288` post-init. The delivery constraint mandated a graft, not an `.ini` — statically
  proven that the registry does **not** presize from `cdbsizes` (`FUN_00648850` writes capacity=0 as
  its only literal; the dump's grown capacity `162048 = 129597/0.80` rounded to a page).

### 1b. The veg spatial-hash pool is an architectural DEAD END for dense veg
A second, distinct structure — the veg 3D spatial-hash (base `DAT_01175dd8`, stride `0x1F0`,
keyed on `(x,y,z)` floats via `FUN_005168b0`) — livelocked at ~92k densely-clustered plants.
- Root cause (live x32dbg on a paused freeze): an infinite loop in `FUN_00517ec0` @0x517f19 walking a
  `+0x1E8` overflow chain whose node pointed to **itself**. The overflow pool is a **fixed 4000 nodes**
  (confirmed 3 ways: live span, the `push 0xFA0; push 0x1F0` allocation call at VA `0x4F217F`, and the
  exhausted cursor at 4003) and the allocator `FUN_005161e0` has **no bounds check** → OOB read →
  corrupt `+0x1E8` → self-loop.
- **The wall:** a home-bucket id is a **12-bit field** (`entity+0x18 & 0xFFF`) holding the pool node
  index → the pool is hard-capped at 4096 nodes. Enlarging past 4096 truncates ids (worse corruption);
  a reuse-on-exhaustion backstop re-creates the self-loop (the reservation loop links
  `node[i]->+0x1E8 = node[i+1]`). Neither enlarge nor backstop is safe.
- **Conclusion:** dense veg cannot go through the entity/spatial-hash path. It must be rerouted (§2)
  or kept sparse enough to stay under the pool (which also keeps the render side under §3).

---

## 2. The reroute — dense veg via the engine's own per-cell foliage system (tool built)

The engine's native trees are **veg MODELS** (chunk `0x5B724250`) bundled inside c3 quad-tree
streaming cells; a **cluster model** (e.g. `largecanopy01` 0xFF7ABB3B — 14 mesh groups on multiple
bones, ~44 m stand) fills most of a 77.5 m cell with a stand of trees. Base-game trees are sparse
only because few cells carry cluster models. Placing cluster models into more cells → continuous
canopy through the engine's native collect→transform→render→stream→LOD path, with **zero entity
registration** (Wall 1 cannot fire).

- **`c3_veg_forge` (`tools/wad_simulator/crates/mercs2_formats/src/bin/c3_veg_forge.rs`)** extracts a
  cluster model body from a donor cell and appends it (entry + bundled body, count++) to existing c3
  cells near a world point, wrapping each as an override `PatchBlock` → overlay WAD. c3-cell block
  format proven: `[u32 count][count×16B entries {name,type,field_c,chunk_size}][contiguous bodies]`,
  entry[i]↔body[i]; **models are BUNDLED** (each target cell gets a ~1.27 MB copy). The full model
  lives in **LOD slot 3** (the bare `c3####` block).
- First overlay `output/foliage/vz-c3veg.wad` passes `aset_refcheck`; the builder auto-sentinels
  dangling LOD rungs to `0xFFFF` (avoids the 549GB-buffer stream wedge). **Loaded with NO hang** —
  proving the reroute is structurally sound.
- **Open items:** the render pipeline has two instance representations (a `+0x708/0x1c` collection
  table and a separate render array), so a runtime injection graft is fragile — the c3-authoring
  (data) route is preferred. Base c3 veg cells are often out-of-bounds background terrain; useful
  in-bounds targeting + the bundled-copy overlay-size question remain for scaling.

---

## 3. Wall 2 — draw calls (the render packet cap)

Rendering N draws overflows the frame packet buffer.

- **Root cause (proven, decomp + two dumps):** the packet producer `FUN_008546a0` bounds-checks
  `if (DAT_00ff46f0 == 0x2000) return;` — the frame packet buffer holds **8192 packets** (stride
  `0x58`). Packets past 8192 are dropped → the downstream command buffer (replayed by the interpreter
  `FUN_00856760`) becomes inconsistent → it hits a value that is not a valid opcode → the `switch`
  dispatch loops without advancing → the render thread spins, the frame never finishes → freeze.
- **The ceiling is exact:** each palm model is **34 draw groups = 34 packets**. `8192 / 34 ≈ 240`
  palms. 150 palms = 5,100 packets (renders clean); 462 palms = 15,708 packets (overflows → freeze).
  This matches the observed safe ceiling (~240–250 entity draws) precisely.
- The static packet arrays (fixed strides, e.g. `0xB0000 = 8192×0x58`) are not simply enlargeable; the
  cap and the array size are tied, and the layout is assumed engine-wide. The real fix is to reduce
  the number of packets, i.e. instancing (§4).

---

## 4. M4 — hardware instancing (diagnosed + designed; NOT built)

Instancing collapses N identical draws into one. The palms are the ideal case: 34 draw groups that are
**identical across all palms**, differing only in world matrix → **34 packets total, any palm count.**
Density stops mattering, and Wall 2 disappears. Design reference:
`docs/reverse_engineer/density_render_instancing_design.md`.

**Mapped seam (proven):** producer `FUN_008546a0` → sort `FUN_008548f0` (key `DAT_0116474c`) →
consumer `FUN_00854b38` → command interpreter `FUN_00856760`. Do **not** hook the hot DIP choke
`FUN_007512f0` (it has wedged the game). The `0x58`-byte packet layout is read.

**Shader crux (solved on paper):** every static-prop transform is delivered as a `vs_3_0` constant via
`SetVertexShaderConstantF` (`FUN_00748e00`). Hardware instancing needs the VS to read the transform
from a per-instance stream. For the common pre-combined-`WorldViewProj` case this is a **mechanical
register swap**: declare four instance inputs (`v5..v8`), redirect the transform's `c[N..N+3]` reads to
them, bump the input-usage token. Delivered additively (a new shader variant, never overwriting a
shipped shader). Shader store located: `data/shader3.bin` (302 `vs_3_0` + 810 `ps_3_0` blobs, nameless
in-file); static-mesh VS is `PgMeshVP` / `PgMeshVPAmbientWind` (registered in `FUN_0084f130`).

**The five build pieces that remain (in order):**
1. **Shader splice (self-contained, offline-verifiable):** identify `PgMeshVP` among the 302 blobs,
   decode its DXBC, confirm the pre-combined-WVP case, swap `c[N..N+3] → v5..v8`, validate the edited
   `vs_3_0`.
2. **Instance-buffer builder:** gather the palm world matrices into a per-instance D3D vertex buffer
   (stream 1).
3. **Packet coalescer (the high-risk core):** a Rust MinHook graft that, in the consumer/command path,
   detects a run of same-`(VB,IB,decl,VS,PS)` draws and re-emits it as `[SetStreamSourceFreq(1,N); one
   instanced DIP]` instead of N draws. This runs on the render hot path — the primary wedge risk.
4. **D3D state wiring** for the instanced stream + the additive shader.
5. **In-game verification** via the live-test loop (§5).

**Honest status:** this is a from-scratch D3D9 hardware-instancing retrofit into a closed engine. The
diagnosis and design are complete and the shader crux is reduced to a register swap, but the
implementation is a substantial, staged build with real wedge risk on the render hot path. It is not
yet built. Piece 1 (the shader splice) is the correct next increment — verifiable without touching the
running engine.

---

## 5. Tooling built/used this effort

- **`density_regpresize.asi`** — the verified Wall-1 registry-presize graft (C + MinHook,
  `tools/density_regpresize/`).
- **`c3_veg_forge`** — c3-cell cluster-model injector (§2).
- **`densify --line x1,z1,x2,z2 --half-width W --spacing S --y Y --model 0xH`** — new line-fill mode
  (`tools/wad_simulator/crates/densify/`) that carpets a strip with one model via the entity path →
  overlay WAD. Used to build the runway; caps at ~240 palms per §3.
- **Live-test loop** (`mercs2-lua-essentials` harness): `lua_repl.py` sends Lua into the running game
  and reads results; `Object.GetPosition(char)` reads a position, `DebugTeleport(x,y,z)` moves the
  hero (async, next frame). Wally's heightmap gives ground Y (mapping verified against a known point).
  This is the verification feedback channel — there is no screen capture.
- **Gates:** `aset_refcheck` (LOD-rung integrity), `loadprobe` (world-load verdict), a minidump parser
  (exception/thread/command-buffer walk) that produced the Wall-2 root cause from two freeze dumps.

## 6. Incidental fix — anisotropic filtering

Grazing-angle texture smear on dense receding foliage rows was `AnisotropicFiltering = 0` in
`dxwrapper.ini` (dxwrapper is the active D3D layer; `dgVoodoo.conf` is absent). Set to `16` — a
whole-game improvement, not just for foliage.

## 7. Bottom line

- Wall 1 (instantiation): **solved** for props/crowds (`density_regpresize.asi`, verified). Dense veg
  routes around it via the c3 system (tool built, structurally proven).
- Wall 2 (draw): **root-caused to the 8192 packet cap**; the entity path tops out at ~240 draws of a
  34-group model. Removing this ceiling requires M4 hardware instancing — fully designed, seam mapped,
  shader crux solved, **not yet built**. The next build increment is the `vs_3_0` shader splice.
