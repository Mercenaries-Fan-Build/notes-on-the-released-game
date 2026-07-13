# crowd_fog_couple.asi

Makes the ambient **crowd cull radius equal the fog distance**, so crowds fill the visible world and
dissolve into the fog instead of popping out of clear air. Default coupling = **400 m**.

## The problem it fixes
- Fog far distance = `ViewDistance*20 + 400` (env-block `+0x44`, set by `FUN_007140b0`). Stock
  `ViewDistance=100` → fog at **2400 m**. The in-game slider is inert — it writes a global the fog
  path never reads; only the INI `[Render] ViewDistance` (`DAT_00dfc348`) reaches fog.
- Ambient actors are distance-culled far nearer by `FUN_00501f20` (the cache-out gate): squared
  distance `dx²+dz²` vs a per-mode threshold (80²–400²), so crowds vanish at ~80–200 m — into a fog
  wall 2400 m away, i.e. clear air.

Full reverse-engineering: `docs/reverse_engineer/render_distance_and_density_levers.md`.

## What it does (runtime only — no exe/WAD edit)
1. **Fog → D**: forces `DAT_00dfc348` so fog = D (`VD = (D-400)/20`), re-enforced every second so the
   video-options menu can't reset it.
2. **Despawn cull → D**: redirects the 9 threshold `movss xmm,[disp32]` loads *inside* `FUN_00501f20`
   to a private `D²` float. Only this function's cull radius changes — the shared mode constants
   (`DAT_00bea9b0` etc., referenced by 9–13 other systems) are **never written**; the instruction
   operands are, not the data. A 9/9 byte-signature check aborts (patches nothing) on mismatch.
3. **Spawn reach → R** (default = D): the ambient activation ring in `FUN_005049b0` is placed at
   `player + unitcircle·DAT_00b984ac` (50 m). That constant is shared by 59 functions, so we redirect
   only its placement-load operand (`MOVSS xmm2,[0x00b984ac]` @`0x00504b2d`, disp32 @`0x00504b31`) to
   a private `R` float; the in-function fade `FLD` is left alone. Signature-guarded.
4. **Density ceiling ×N**: MinHook on `FUN_004d60e0` (the region-select that writes the desired
   ped/veh counts into `DAT_00ed55c8[]`/`DAT_00ed55b0[]` from WAD `PopulationDensity` data). After the
   original runs, multiply each by `CROWD_DENSITY_MULT`, clamped to `CROWD_PED_CAP`/`CROWD_VEH_CAP`.
   `DensityUpdate` (`FUN_005051a0`) then spawns toward the raised ceiling (batch = fill-rate only; the
   engine already ×2's peds in free-roam). Caps are deliberately conservative to stay inside the
   **stock** pools (`Ai 1024` shared with enemies/mission NPCs; `ControllerCar 64` = AI-car hard cap).

5. **Geometry render distance** (props/trees/LOD): MinHook on `FUN_00490220`, the RtGenericLOD
   per-frame band consumer. Each LOD object holds up to 4 bands `{near²@+0, far²@+4, …}` at `[obj+0]`,
   count `[obj+0x40]`; a band renders iff `near² ≤ camDist² < far²`. After computing which band is
   coarsest (largest far²), we rewrite far²: coarsest → `RENDER_COARSE_DIST`² (1000 m), all finer →
   `RENDER_DETAIL_DIST`² (800 m). We touch **only far²**, so it can extend visibility but never hide
   geometry. **Coverage:** this is the RtGenericLOD/proxy set — vegetation/trees + the ~128 authored-
   LOD objects. The mass of instanced rocks/fences/lamps go through `HibernationControl` directly
   (per-frame wake test not yet pinned to a clean static site) — confirm live whether they also move;
   if not, that gate needs a follow-up (likely an x32dbg-guided load-time `dist0` clamp).

### Why cull alone did nothing (patch 2 in isolation)
Raising the despawn radius keeps actors alive further out but spawns none there — so reach (3) and
density (4) are the levers that actually populate the space. See the doc for the full RE.

## Build & deploy
```
cd mods/crowd_fog_couple
i686-w64-mingw32-gcc -O2 -Wall -Wno-unused-function -shared -Wl,--enable-stdcall-fixup \
  -o crowd_fog_couple.asi src/crowd_fog_couple.c -lkernel32 -luser32
cp crowd_fog_couple.asi "<game>/scripts/"
```
(`make` also works where GnuWin32 make is on PATH.) Requires an ASI loader in the game dir (same one
that loads `windowed_mode.asi`). Writes `crowd_fog_couple.log` next to the exe.

## Tuning (env vars)
Baked defaults: **fog 800 m, spawn reach 1000 m, despawn cull = max(fog,reach) = 1000 m, density ×3**.
- `CROWD_FOG_DIST` — fog distance (metres, default 800, clamped 400–4000). Below 400 the VD fog path
  can't reach — use `fAtmosphereLimit` for that.
- `CROWD_PLACE_RADIUS` — spawn reach, independent of fog (default 1000). The despawn cull is set to
  `max(fog, reach)` automatically so peds spawned past the fog still persist.
- `CROWD_DENSITY_MULT` — desired-count multiplier (default 3.0, clamped 1–20).
- `CROWD_PED_CAP` / `CROWD_VEH_CAP` — hard clamps on desired ped/veh count (defaults 200 / 15) that
  keep live counts inside the STOCK pools. **Raise these only after** bumping the pools.

## Scaling past the stock caps
The default caps keep live counts inside stock pools, so this ASI needs **no** `cdbsizes.ini` change.
To go denser/further you must also:
- **Pools** — grow the actor cluster in `data/cdbsizes.ini` (`Ai`, `_HumanPhysics`, `RTHuman`,
  `HumanStateMachine`, `Perception`, `StateMachine`, `Health`, + `_CarPhysicsV2`/`ControllerCar`/
  `VehiclePart`, + `SceneObject` headroom). Config-driven, no binary patch, safe to u16=65534. Then
  raise `CROWD_PED_CAP`/`CROWD_VEH_CAP`. (Pool bumps change the arena layout — re-verify world-load.)
- **Residency** — much past ~400 m, peds spawn onto non-resident terrain (`HibernationControl.dist0`
  median 231 m); pushing that out is separate WAD work.

## Verification / expectations
- 400 m fogs the whole world (buildings included) — this is the airstrike-preset look. Watch for
  pool-exhaustion (loadprobe on `pmc_blackbox.log`; the `0x4CC064` exhaustion line) on dense streets;
  if it appears, bump the actor pools in `cdbsizes.ini`.
- Fog note: `DAT_00dfc348` only drives fog for atmosphere presets left on the "auto" sentinel
  (`2400.0`). If a scene sets `fAtmosphereLimit` explicitly (e.g. airstrikes, already ≤400), that
  wins — which is fine. If the default world atmosphere turns out to be explicit and fog stays far,
  escalate to clamping the atmosphere apply.

## Uninstall
Delete `<game>/scripts/crowd_fog_couple.asi`. Everything reverts (fog → 2400, crowds → stock ~200 m);
no files were modified.
