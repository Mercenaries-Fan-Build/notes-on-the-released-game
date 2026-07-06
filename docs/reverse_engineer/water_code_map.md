# Scoreboard #7 — water rendering: PC code map

**Scope:** the PC-side water rendering system in `Mercenaries2.exe` (unpacked image, base 0x400000).
Scoreboard row 7 (was ❌ none). Binds the Xbox PDB names
([world-streaming.md](../mercs2-pdb-analysis/world-streaming.md) §Water) to PC addresses. Companion
JSON `docs/data/sky_decal_water_code_map.json`. Ties into the water-and-swimming scope memory and
[watermap_format.md](../watermap_format.md). Source module confirmed `PgWaterWin32.cpp` (path @0xbac038).

## 0. Boundary

Shader load, the render-target creators, the pass driver, the reflection-matrix pass, and the
buoyancy tunables are statically recovered = high/med confidence. The surface-draw pass split and the
waterline query reach through command-buffer submits / a SecuROM island → confirm-live.

## 1. Shader load — `FUN_00484380` (the sub-loader)

1060 B; callers `FUN_0046a440` + `FUN_0084f130`@0x8522ca. Reads render-config bits
`*(DAT_01176288 + 0x5e4)`, then registers one of three VP variant sets via `FUN_0085ac90(name,.sho,0)`:

- `if (bit3==0 || bit2!=0)` → `bit2==0` registers **`_NVT`** variants, else **plain**;
- `else` (bit3=1 AND bit2=0) → **`_R2VB`** (render-to-vertex-buffer wave path).

So **bit2 set = plain**; bit2 clear → **bit3 picks R2VB (1) vs NVT (0)**. Each set = 12 shaders:
`PgWaterVP{0,2,3,5}` (LOD/quality tiers) × {plain, `Occ` occlusion} + `PgWaterZFullVP{0,2,3,5}` (full
z-prepass). Common tail (always): `PgWaterZSimpleVP`, `PgWaterFPDWE`, `PgWaterFP` (+ `PgWaterFP_LI`
when `DAT_01286310==0`), **`PgUnderwaterFP`**, `PgWaterWakeVP/FP`, `PgWaterHeightMapVP/FP/FP2`.

## 2. Render passes — driver `FUN_00466d40`

Reached per-frame `FUN_0085a9e0 → FUN_00466d40(view+0x2b94)` from a registered water render-action
(`LAB_0046a260`). Water singleton `DAT_00d6af80` (visible flag `+0xca4`). Pass order:

1. `FUN_00486390(water)` — **RenderWakeMap** (Xbox 0x15ed0), first; wake/height gen into RTs. *(med)*
2. `FUN_00482fa0(water+0xa30)` — **RenderOcclusion** (0x15ee8); refs `WaterClip`, builds fmt-0x1a clip tex. *(med)*
3. **RenderReflections** (0x15f00) = **`FUN_004677d0`** (via `FUN_00486fa0`) — builds mirrored view
   matrices (D3DXMatrixMultiply of camera vs the water plane at `+0xab0/+0xb70`) and re-renders scene
   renderables into the reflection RT. *(high — the mirror-matrix pass is unambiguous)*
4. Main scene draw, then surface passes `FUN_00487540` (main surface) + `FUN_00487dd0` (pass2:
   transparency/foam/underwater), ordered by the camera-underwater flag. *(med)*

`FUN_00480570` = **OWater::LOD** (0x15ec3): clips water tessellation triangles against a height band
with edge interpolation → water-surface LOD banding. *(high)*

> **Reconciliation note:** `FUN_00466d40` was also flagged by the shadow pass as the scene
> render-list builder / `CollectShadowCasters` candidate (see [shadow_code_map.md](shadow_code_map.md)
> §4). It is most likely a **shared scene-pass driver** that both the water render-action and the
> shadow-caster collection hang off (a per-viewport render dispatcher), not exclusively either — treat
> the "Water::Render" and "CollectShadowCasters" labels as two render-actions routed through it, and
> confirm the exact dispatch live.

## 3. Water render-target set (all log `::::: CREATED SURFACE`)

- **`FUN_00482a80`** (sim RTs): `pHeightS ×2` (80×80 fmt-0x74, **ping-pong wave height**), `pNormalS`
  (128×128 fmt-0x74, normal-from-height), `pFoamMas` (128×128 fmt-0x74, foam mask). Has the R2VB-bit
  recreate path.
- **`FUN_00485da0`** (reflection/depth RTs): `pReflect` color (fmt-0x15) + `pReflect` depth (fmt-0x4b)
  + `pWaterDepth`; sized `screen*scale/3` by allocator `FUN_00485b90` (+ a 256×1 fmt-0x15 gradient tex,
  hash 0xf011157a). Teardown `FUN_004860b0 → FUN_00482e40`.

## 4. Heightmap + waterline query

- **Dynamic waves:** `PgWaterHeightMapVP/FP/FP2` render into the ping-pong `pHeightS` RTs; `pNormalS`
  derives normals; `pFoamMas` foam — the dynamic wave layer.
- **Static waterline:** watermap `watr` type `0x4D7D30C4`, 257×257 grid, dry height_min ≈ −50 m, wet
  plateau ≈ **−36 m** (open water); layer 0 = f32 height (watermap_format.md).
- **`FUN_00480440`** = the global water/underwater query — a SecuROM island thunk
  `(*_DAT_0244fcd8)()` with ~30 callers (weapons, vehicles, FX, and the render driver's
  camera-underwater flag). Binds to Xbox **UpdateRay::CheckWater** (0x217f0) / IsUnderwater. **Exact
  return semantics (height query vs boolean underwater) = confirm-live** (thunk body not in dump).

## 5. Buoyancy tunables + application

- Boat handling tunables live on the **Boat vehicle-definition** (vehicles.md): `WaterDragFwd/Side/Up`,
  `OutOfWaterGravityFactorUp/Down`, `Wake{Offset,Size,LifeTime,Speed,Rate}`,
  `Shallow{Depth,LinDamp,AngDamp,T}`, `InWaterT`, `WaterDepth`, `HullFriction` — not on the 4-byte
  `ControllerBoat` stub.
- Generic flotation = **`Buoyancy` ECS component** `FUN_006395e0` (m2 `0xb9659f7b`, stride 0x14 = 20 B,
  ~5 floats: waterline offset + up-force + damping) — applies up-force vs the waterline for boats /
  floating debris.

## 6. Xbox → PC bindings

| Xbox | PC |
|---|---|
| Water::Render 0x15f1c | `FUN_00466d40` (shared scene-pass driver — see §2 note) |
| RenderReflections 0x15f00 | `FUN_004677d0` (via `FUN_00486fa0`) |
| RenderOcclusion 0x15ee8 | `FUN_00482fa0` |
| RenderWakeMap 0x15ed0 | `FUN_00486390` |
| OWater::LOD 0x15ec3 | `FUN_00480570` |
| WaterClip 0x160c4 | `FUN_004834d0` |
| WaterGradiant 0x15544 | `FUN_0046d290` (shared with the ScreenEffect shimmer renderable) |
| UpdateRay::CheckWater 0x217f0 | `FUN_00480440` (SecuROM thunk) |
| WaterAction / Splash / … | 6 classes registered in `FUN_0046a440` |
| shader sub-loader | `FUN_00484380` |

## 7. Confirm-live inventory

- Surface-draw split (`FUN_00487540` vs `FUN_00487dd0` vs `FUN_00486fa0`) — drawn via command-buffer
  submits (`thunk_FUN_024bb2a0`) + vtables; the opaque/transparent/underwater role of each is inferred
  from buffer-offset binds.
- `FUN_00486390` WakeMap-vs-HeightMap target — not string-pinned.
- `FUN_00480440` semantics (waterline height vs boolean underwater) — SecuROM island body not in dump.
- `Water::Begin`/`BeginFrame` (Xbox 0x14c10/0x14a70) — best candidates `FUN_00466670`/`FUN_00466850`
  (water-object init), not asserted.

For the reimpl (water-and-swimming scope): this gives the pass structure (wake→occlusion→reflection→
surface), the ping-pong height/normal/foam sim RTs, the reflection mirror-matrix technique, the
static watermap + dynamic wave split, the `FUN_00480440` waterline query used by buoyancy/swim, and
the `Buoyancy` component + boat tunables for the swim/float feel.
