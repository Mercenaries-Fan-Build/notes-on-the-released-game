# Render distance & crowd density — the real levers (PC retail)

Status: recovered 2026-07-10. Supersedes the "push `ViewDistance`, it extends draw distance" advice
that circulated in earlier sessions — that claim is **wrong** and is corrected below.

Anchors verified by reading `output/_ghidra/all_functions_decomp.txt` unless marked INFERRED.

---

## 1. `ViewDistance` is a fog knob, not a draw-distance knob [VERIFIED]

`Mercs2.ini [Render] ViewDistance` → `FUN_00753280` → `DAT_00dfc348`, stored raw with **no clamp**
(contrast `ModelDetailLevel`/`ParticleDetailLevel`, both guarded by `if ((byte)v < 3)`).

`dfc348` appears at exactly **three lines** in the whole 27k-function decomp: one write (the loader)
and one read. The single reader is `FUN_007140b0`, the atmosphere/fog env-block rebuilder:

```c
bVar1 = *(float *)(param_1 + 0x5e4) == DAT_00beaef8;   // preset field == "auto" sentinel?
*(float *)(env + 0x44) = *(float *)(param_1 + 0x5e4);
if (bVar1) {
    fVar2 = (float)DAT_00dfc348;                        // ViewDistance
    *(float *)(env + 0x44) = fVar2 * DAT_00b97eec * DAT_00d2d8bc + DAT_00ba874c;
}
```

`env+0x44` is the **fog / atmosphere far-distance limit**. It is populated from the active atmosphere
preset, and falls back to the ViewDistance-derived value only when the preset leaves it on the
sentinel. The three env-block initialisers (`FUN_00466550`, `FUN_00466046`, `FUN_0070aef6`) all seed
`+0x44 = DAT_00beaef8`, so "auto → use ViewDistance" is the common case.

Consequences:
- Raising `ViewDistance` pushes the **haze fade-out** further away. It draws no additional geometry.
- It is read by **none** of `FUN_00872d30` (streaming manager), `FUN_0084ae70` (LOD budget),
  `FUN_00858150` (per-caster distance classify), nor any HibernationControl/block-residency code.
- Units: `far = a*ViewDistance + b` — a linear scale, no `/100` and no table index. The default `100`
  reads as "100%". [formula VERIFIED, scale constants INFERRED — `.rdata` floats not in the dump]
- Safe to set large: pure float math, no divide, no array index. Ceiling is visual, not a crash.
- **Not** clobbered by the video-options menu: `s_ViewDistance_00bd58d0` has exactly one xref (the
  `GetPrivateProfileIntA` read). No `WritePrivateProfileStringA` writes that key.

### The menu slider is decorative
The in-game `videoViewDistance` slider (`atoi(v)+10` → `DAT_00df6728`) is read only by menu-widget
code (`FUN_005c0af0`, `FUN_005c37e0`). It never writes `dfc348` and never reaches the fog path. The
Lua-facing getter `LTIVideoGetViewDistance` @`0x0063ef20` is a **stub — `return 1;`**.

### What actually controls draw distance
| Want | Lever | Where |
|---|---|---|
| Camera far-clip | `Graphics.SetNearFar(vp, near, far)` cfunc @`0x005b0600` | writes camera struct `[0x011761B0] + vp*0x620 + 0x20` via `FUN_0070a960`; `RestoreNearFar` @`0x005b06f0` |
| LOD bands | `Graphics.SetLodParams` cfunc @`0x005b0b50` | real cfunc (body is arg-marshalling; payload target not yet traced) |
| Geometry residency | per-object `HibernationControl.dist0` + c3 block `stream_out` | WAD `layers_static`; dist0 median 231, max 5037 |
| Haze | `[Render] ViewDistance` | §1 |

Pushing perceived render distance therefore requires moving **residency first** (dist0 / block
stream_out), then **far-clip** (`SetNearFar`), then **fog** (`ViewDistance`). Moving only the last
one changes nothing but the haze.

### The fog sits ~12× beyond where crowds live [VERIFIED numerically]

Fog constants, read straight out of the exe (`.rdata`/`.data`): `fog_far = ViewDistance * 0.01 * 2000.0 + 400.0`.
So stock `ViewDistance=100` → **fog_far = 2400** (identical to the "auto" sentinel `DAT_00beaef8 = 2400.0`,
by design). Ladder: `VD 0 → 400`, `25 → 900`, `50 → 1400`, `300 → 6400`.

Ambient actors (peds/traffic) despawn+fade far nearer. The despawn distance gate lives in the shared
helper `FUN_005007d0` (PC; = Xbox `DeathCompute FUN_8235efc0`, called from both DeathCheck
`FUN_00500b40` and DeathCompute `FUN_00500ac0`). Xbox carries the per-viewport **squared-distance
table** `50² / 80² / 100² / 140² / 150² / 160² / 200² / 250² / 400²` + a `2.0`-unit fade. The PC per-
entity fade commit is `FUN_00503020` → `thunk_FUN_024b9f30(entity, alpha∈[0.001,0.999], 200.0, flag)`;
the alpha is clamped by `DAT_00b929d8=0.001 / DAT_00beae20=0.999` and the distance arg `DAT_00b984a8`
= **200.0**, which matches the `200²=40000` table entry — so the PC band is the same 50–400 m range,
most categories in **80–200 m**. `thunk_FUN_024b9f30 → thunk_FUN_02a30028` is the SecuROM VM
dispatcher, but it is **not** a wall here: it is only the terminal commit, and its numeric inputs
(200.0, the alpha clamp) are in cleartext at the `.text` call site — no devirtualization needed.
(`024b9f30`/`02a30028` are **not** in the 743-splice inventory.)

### The crowd cache-out distance gate (the lever to push the band out) [VERIFIED]

`FUN_00501f20` (called from the cache-out sweep `FUN_005020e0` + `FUN_0050aec0`) is the per-entity
distance cull for ambient/cached actors: per player it computes `dx²+dz²` to each entity and culls
past a squared threshold chosen by a `param_2` mode:
- mode 0 → `DAT_00bea9b0` (100²=10000) / `DAT_00beab3c` (50²=2500)
- mode ≠0,≠3 → the **6-entry near table at `0x00d1e404`**: `90²/140²/80²/160²/150²/50²`
- mode 3 → `DAT_00beaeb0` (250²=62500) / `DAT_00beaeb4` (200²=40000); outer bound `DAT_00beaaa8` (400²=160000)

The near table is **config-driven with baked exe defaults**: `FUN_004c2c20` (a 126-key hashed-config
loader; same `FUN_00826820(hash)`/`FUN_00826990` DB family as the `cdbsizes` presize reader)
overwrites each entry only *if* its config key is present, then **squares** it
(`DAT_00d1e408 = v*v`). Keys: `0x4d74eb9c`→140 m, `0xa739c2a5`→50 m, `0xa2ba992f`→90 m (not in our
harvested string set). No shipped config sets them, so the pre-squared floats in the exe ARE the live
values → a **24-byte patch to `0x00d1e404` (+ the `0xbea9b0/beab3c/beaeb0/beaeb4/beaaa8` mode
constants)** changes the cull radius. All are `.rdata`/`.data`, patchable.

**"Crowd radius = fog distance" is a distance edit + a cascade, not one number.** Cull area scales
as D². Pushing the band from ~200 m to the default fog 2400 m is 144× the populated area →
(1) blows the actor pools (`Ai 1024`, `PopulationSimpleSpawner 768`, `_HumanPhysics`, `RTHuman`, …) →
exhaustion crash unless grown (safe to u16=65534, the June cluster bump); and (2) spawns actors onto
**non-resident terrain** — geometry residency `HibernationControl.dist0` medians 231 m, so at 2400 m
the roads/sidewalks peds need aren't loaded. The achievable form is to bring fog IN and push crowd OUT
so they **meet at a moderate D** (~300–500 m): fog `VD=0`→400 (or `fAtmosphereLimit`), cull table → D,
+ ~2–4× the actor-pool cluster. Beyond ~500 m you also have to push `dist0`/block `stream_out`
(the residency work).

### Geometry render distance — RtGenericLOD bands (props/trees/LOD) [VERIFIED] + OPEN gate

Two gates decide whether static geometry renders at distance:
- **Per-object LOD (RtGenericLOD).** Builder `FUN_0066ee80` squares source LOD distances into per-object
  bands; consumer **`FUN_00490220(param_1=obj, param_2)`** (single caller `FUN_00675e50`, per-frame)
  keeps a band's mesh iff `near² ≤ camDist² < far²`. Band layout: `[obj+0]` array, stride `0x10`,
  `near²@+0 / far²@+4 / handle@+0xc`, count `[obj+0x40]` (≤4 bands). **Prologue** `a1 dc 5c 17 01`
  (`mov eax,[0x1175cdc]`) = clean 5-byte MinHook target. Lever: hook it, rewrite each band's far² —
  coarsest (max far²) → render-coarse dist², finer → detail dist² (touch far² ONLY → can extend, never
  hide). Shipped in `crowd_fog_couple.asi` patch 5 (coarse 1000 / detail 800). **Coverage caveat:**
  RtGenericLOD is a LIMITED set (32 RtGenericLOD + ~128 GenericLOD + vegetation/tree proxies) — NOT
  the ~62k instanced props.
- **Coarse c3 block residency** — the streaming manager `FUN_00872d30`/`FUN_008739e0` is a
  memory-BUDGET pump (`[mgr+0x4c350]` resident cap, `[mgr+0x4c358]` in-flight cap) + LOD-budget tier
  `FUN_0084ae70`; it has **no proximity-radius constant**. Residency is triggered by the spawn requests
  the RtGenericLOD load-branch (`FUN_006746d0`) issues, so raising far² also drives block-in — bounded
  by the byte budget, not distance.

**★OPEN (the unfinished thread):** the MASS of instanced props (rocks/fences/lamps, the ~62k named
placements) go through **`HibernationControl` dist0 directly**, and their per-frame wake/hibernate
distance test was NOT pinned to a clean static byte site (the agent found no single dist0-vs-camDist²
imm-site; `FUN_00490220` is RtGenericLOD-only). To push those out too, the likely path is a **load-time
`dist0` clamp** — hook the HibernationControl stream-deserializer `PTR_CopyFromStream_00bbf430`
(installed at `DAT_017bd178` by ctor `FUN_00640a40`) and raise the first-u16 dist0 as each record
loads — but the exact record offset + a live confirm (x32dbg) are needed. `Object.SetHibernationDistance`
cfunc `0x5CF4F0` is the per-object Lua equivalent (terminal commit is SecuROM `thunk_FUN_024ecab0`).

### Spawn PLACEMENT + density (why raising the cull alone did nothing) [VERIFIED]

Raising `FUN_00501f20`'s cull to 400 m keeps actors alive further out but does NOT place any there —
ambient actors spawn in a small player-following bubble. There is **no single spawn-radius scalar**;
placement is distributed and every candidate is a **shared** constant (data-write unsafe → operand-
redirect only, unlike the single-reader cull table):
- `DAT_00b984ac = 50.0` — per-player ring-scan radius in `FUN_005049b0` (spawn point = player +
  unit-circle(sinLUT `DAT_00cf2900`)×50). Read by **59 functions**. The placement-radius load is a
  single site: `MOVSS xmm2,[0x00b984ac]` at VA `0x00504b2d`, disp32 `AC 84 B9 00` at **`0x00504b31`**
  (redirect this, leave the `FLD [0x00b984ac]` fade load at `0x00504bd1`). It is an *activation scan
  ring*, so raising it activates content at that band — a shell, not a fill.
- `DAT_00b9b980 = 20.0` — road-query seed proximity in `FUN_00503020` (118 readers); real road extent
  is the geometry-bounded walk in `FUN_004dc990`, not a scalar.
- Sidewalk/building spawners activate by **streaming residency** (`HibernationControl.dist0`, median
  231 m, per-object WAD data) + per-spawner radii (`+0x78/+0x7c`), not a global.

**Density / count:** PC `DensityUpdate` = `FUN_005051a0` (from `FUN_00502510`), hardcoded imm8 budgets
(function-exclusive, imm-patch-safe): "enough" gates people 10 (`0x005051ff`) / veh 5 (`0x00505204`);
batch caps 10/tick (`0x0050524b`,`0x00505263`) + trickle 2/tick (`0x0050527b`,`0x0050528f`). These
only fill the deficit FASTER — the **ceiling** is the desired count in per-player arrays
`DAT_00ed55c8[]`/`DAT_00ed55b0[]`, written by region-select (`FUN_004d8490`→`FUN_004d60e0`) from the
`PopulationDensity` COMP records in the WAD. No global density multiplier exists.

**Consequence for "crowd = fog":** extent (placement radius) and density (count ceiling) are separate.
Pushing placement to 400 m at the fixed WAD density ceiling = **sparser** crowds, not a fuller world.
A dense living world out to the fog needs the cascade: placement radius (operand-redirect) + count
ceiling (WAD `PopulationDensity` edit, or a runtime hook that scales the `ed55c8/ed55b0` desired-count
write) + pools (`cdbsizes.ini`) + residency (`dist0`). The runtime-only ASI can move extent and fill
rate; it cannot raise the WAD-authored density ceiling without a hook on the count write.

**Net:** crowds already alpha-fade out at ~80–200 m, but into **clear air**, because fog is parked at
2400 m. "Crowds disappear into fog" = pull the fog wall in to coincide with the ~200 m ped band:
`ViewDistance=0` (fog 400) or, for tighter, `Graphics.Atmosphere.SetValue("fAtmosphereLimit", n)` with
n≈125–400 — the exact range the airstrike atmosphere presets use (bombrun 125 … tactnuke 400). Caveat:
the `fAtmosphereLimit` Lua path *overrides* `ViewDistance` (the INI value only applies when the active
atmosphere preset leaves the field on the 2400 sentinel).

---

## 2. Pursuit / skirmish spawn table — `(mode + faction*6)*0x14 + level` [VERIFIED]

Recovered while chasing density; this is the **enemy-wave** dial, distinct from ambient population.

`FUN_004d8490` (the per-player population/pursuit region-select) picks five desired counts and spawns
toward them:

```c
if (DAT_01175cff == '\0') {                       // zone table
    iVar9 = (DAT_00ed27b8 + DAT_00ed27dc * 6) * 0x14;   // (playerMode + faction*6) * 20
    cVar2 = (&DAT_00ed2800)[iVar9 + DAT_00ed27d8];      // + pursuitLevel selects the BYTE LANE
    ...
} else {                                          // per-mode fallback defaults, stride 5
    cVar2 = (&DAT_00ed27e0)[DAT_00ed27b8 * 5];
    ...
}
if ((0 < cVar1 - DAT_016d3078) && (DAT_00ed2791 == '\0')) FUN_004d9840();       // desired − live > 0 → spawn
```

| Field (zone tbl) | Default tbl | Live count | Kill-switch | Spawner |
|---|---|---|---|---|
| `ed2800 +0x00` | `ed27e0` | `016d2f6c` | `ed2790` | `thunk_FUN_024e7aa0` |
| `ed2804 +0x04` | `ed27e1` | `016d3078` | `ed2791` | `FUN_004d9840` |
| `ed2808 +0x08` | `ed27e2` | `016d3184` | `ed2792` | `FUN_004db7e0` |
| `ed280c +0x0c` | `ed27e3` | `016d3290` | `ed2793` | `thunk_FUN_031a0000` |
| `ed2810 +0x10` | `ed27e4` | `016d339c` | `ed2794` | `FUN_004db100` |

Index decomposition [VERIFIED via the owning cfunc cluster]:
- `DAT_00ed27b8` = player-state mode 0..5, assigned by `FUN_00503d90` (called from `FUN_00503020`).
- `DAT_00ed27dc` = faction index, bounded by `5 < DAT_00ed27dc` and gate array `(&DAT_00ed2788)[f]`
  → **6 factions** (matches VZ/Pir/Oil/Gur/Chi/Ali).
- `DAT_00ed27d8` = **pursuit level**, mirrored from `DAT_00ed2ae4` which is clamped `0..3`.
- Fields sit at byte offsets `0,4,8,0xc,0x10` and the level (0..3) is added as a **byte** index, so
  each int32 packs **four per-level counts, one byte each**. Effective per-category cap = 127 (signed
  char compare `0 < cVar - live`). [packing INFERRED from the addressing; worth an instruction-level
  confirm]

Both tables live in the **uninitialised `.data` tail** (VA `0xed27e0`/`0xed2800` fall past
`.data` raw size `0x209000`) → zero at load, populated at runtime. Zeroed/seeded by `FUN_004d742c`
(population reset), which also sets `DAT_00ed27b8 = 4` (default mode) and `DAT_00ed27dc = DAT_00ed27d8 = -1`.

### Owning Lua cfuncs (`0x005d8xxx`–`0x005d9xxx` = the pursuit namespace)
`SetPursuit` `0x5d8690` · `SetPursuitSeconds` `0x5d87d0` (clamps against `DAT_00ed2ae8 = 700`) ·
`AdjustPursuitLevel` `0x5d8910` · `AdjustPursuitTimer` `0x5d8b50` · `SetMaxPursuitLevel` `0x5d93c0`
(→ `FUN_004db860`, clamp `0..3`) · `SetPursuitLevelTimes` `0x5d94a0` (writes `ed27bc = 200`,
`ed27c0 = 400` — **seconds, not metres**) · **`SetSkirmishTable` `0x5d9cc0`** ·
`AddSkirmishTemplate` `0x5da010` · `SetGlobalSkirmishState` `0x5da130`.

`FUN_004d742c` seeds `ed27bc=200 / ed27c0=400 / ed2ae8=700 / ed2ae4=2`. Given the cfunc names these
are pursuit **times** and **max level**, not distances.

> Correction guard: the `0x14` stride here is the *skirmish* record, **not** `PopulationDensity`
> (stride `0x1c`). An earlier read of this session conflated them because `5*4 + 4 + 4 = 0x1c`
> coincidentally matches. They are different tables.

---

## 3. Ambient pedestrian / traffic density — data-side, no live lever [VERIFIED where cited]

- The obvious script toggles are **dead on PC**: `Ai.SetTrafficSpawning`, `SetSidewalkSpawning`,
  `SetRoadSpawning`, `ShowObjectSpawners` **all resolve to `0x006D5640`**, the shared debug-stripped
  `return 0` stub (per `mods/lua_trace_asi/reference/binding_map.json`).
- Real spawner cfuncs that do work: `Ai.TweakAttachedSpawners` `0x5a4c40` /
  `TweakAttachedSpawnersInGroup` `0x5a4d10` (SpawnerState / SpawnList / SecondsPerCycle /
  ChanceNotActive / SkipPercentChance) — but they reach only **attached (building) spawners**, not
  sidewalk crowds or road traffic. `SetSpawnList` `0x5a5180` changes *which* units spawn, not how many.
- The only density clamp reachable from script is Lua-side, `dangerousbuilding.lua` `ProcessProperties`:
  `Density` is `math.min(100, math.max(0, ceil(Density)))` → `ChanceNotActive = SkipPercentChance = 100 - Density`.
  Building-spawner specific; does not generalise to ambient population.
- Ambient density values live in `PopulationDensity` / `PopulationFlow` / `PopulationDynamicRoad`
  **COMP records in the WAD**, attached to Sphere/Circle population regions and consumed at world-load
  by `FUN_0066f300`. They are **not** in `layers_static`'s harvested COMP set (`docs/ecs_components.md`
  lists 43 types / 10,030 records; these are absent), so they ship in the vz_state overlays and/or the
  resident region set. **vz_state COMP extraction is unimplemented** — this is the tooling gap.
- No loose config file carries them. `data/cdbsizes.ini` sets **pool ceilings only**.

### Ceilings (from `data/cdbsizes.ini`)
`PopulationDensity 128 64` · `PopulationFlow 192 64` · `PopulationDynamicRoad 32 32` ·
`PopulationList 1024` · `PopulationSimpleSpawner 768` · **`ControllerCar 64 64`** (the AI-driven-car
ceiling) · `Ai 1024` · `AiPatrol 768` · `StateMachine 768` · `SceneObject 161280` ·
`HibernationControl 14080`.

Pools are **config-driven, not baked constants**: `FUN_004c1840` reads each count from `[presize]`,
sums them, does one `VirtualAlloc`, then carves the arena with
`FUN_0084adc0(start, end, stride, name, count, flag)` — every base is computed at init, so raising a
count needs **no binary patch**. Format is `Name <count> [<second>]`; scale the second number
proportionally.

**Handle width:** component free-list heads are initialised as two `0xffff` **words** and the
generators sign-extend them as `short` (e.g. ControllerCar `FUN_006405a0` → `DAT_017bcf9c = 0xffff`;
`FUN_00660980` uses `(int)(short)PTR_LAB_017bdadc`). So component handles are **u16 → hard ceiling
65535**. Raising `ControllerCar` / `PopulationSimpleSpawner` / `PopulationList` anywhere below 65534
is width-safe. [VERIFIED for the reflection/component-manager handle; the inner ped/car loop indices
were not confirmed — a u8 there is still possible]

Raising pools raises the **ceiling, not the dial**. It is a prerequisite for denser crowds, not a
cause of them.
