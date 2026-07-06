# Camera (`PgSysCamera`) — Xbox↔PC code map

**Scope:** scoreboard **row 19 (Camera)** — the `PgSysCamera` engine camera surface in retail PC
`Mercenaries2.exe`: the per-viewport render-camera struct the renderer reads (view/proj/pos), the
≤5-viewport array + active-viewport index, the per-vehicle / on-foot / cinematic camera **modes**
(ECS component blocks), camera **shake**, **FOV**, the keep-camera-out-of-geometry **collision
cast**, the **input→camera** look/aim path, and the `Camera.*` Lua cfuncs. This marries the
**Xbox 360 devkit (Jul-08 "Profile" build)** symbol/PDB ground truth to the **PC retail
decompilation** (unpacked SecuROM image, base `0x00400000`).

Companion to the render/scheduler siblings — it deliberately reuses, and does not re-derive, the
render-view singleton and master-tick facts already established in
[`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) §5, the scene driver in
[`render_core_code_map.md`](render_core_code_map.md) §5, the LOD-proxy camera-pos consumer in
[`prop_lod_imposter_code_map.md`](prop_lod_imposter_code_map.md) §3.2, and the per-vehicle camera
modes noted in [`vehicle_code_map.md`](vehicle_code_map.md).

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/camera.md`](../mercs2-pdb-analysis/camera.md)
(the authoritative `PgSysCamera` inventory — modes, shake, FOV, the `FreezeViewport` debug,
marketing / free-eye / rover cams, and the Xbox PowerPC bodies for `PgSysCamera @825e9830`,
`CameraCollisionCastRay @825ea110`, `CameraBlendTime @825109e0`) +
`docs/mercs2-pdb-analysis/pangea-engine-core.md` (`PgSys*` framework). PC: the 27k-fn Ghidra decomp
`output/_ghidra/mercs2_unpacked.exe_decomp.txt` (bodies read first-hand and cited by VA), plus the
**live x32dbg freecam RE** captured in prior sessions (the camera-struct offsets confirmed at
runtime — [[shadow-pc-absolute-mouse-input]] and the freecam.asi work). Data layer: the camera ECS
component descriptors already bound in `camera.md` §"PC decompilation cross-reference".

**Method / honesty model.** Same discipline as the sibling maps. PC retail **strips every
`PgSysCamera` / `Camera*` runtime profiler string** (only the *ECS-component* type-name strings
`s_CameraCarPreset` / `s_CameraShake` / `s_HumanCameraModifier` / `s_CameraShakeTypeEnum` survive —
verified present at decomp lines 298834/298867/298900/306195), so the camera **runtime bodies are
recovered on PC by call-tree shape + the render-view struct layout + the live freecam capture**, and
the Xbox side is often *unlocated by name* (`camera.md` established the Xbox build has **no camera
RTTI vtable** and most camera symbols are `.rdata` names only). Where a PC body was read first-hand
it is stated; where a claim rests on the live capture or on inference it is stated. Confidence:
**H** can't-coincide fingerprint (read body / matching constants / live-confirmed) · **M** one strong
structural signal · **L/open** positional → confirm-live.

> **SecuROM is not a blocker** ([[securom-decompiled-not-a-blocker]]). Two camera hot paths dispatch
> through SecuROM VM islands: the per-viewport **view/proj matrix builder** `FUN_00858f30`
> (`(*_DAT_02455314)()`) and the camera-writer trampoline behind `FUN_0060f6d0`'s prologue island
> (`(*_DAT_02455370)()`). These are *split thunks*, not walls — the VM residue is read live in the
> unpacked image. Every such site below is flagged; none blocks the marriage.

---

## 0. Result in one line

The **render side is fully in the clear**: the render-view singleton `PTR_PTR_00dfc2f8` (runtime
obj `0x017CFAF0`) holds a **≤5-slot camera array, stride `0xE80`**, indexed by the active-viewport
counter `view+0x2B92`; the per-viewport loop **`FUN_0085a9e0`** (render-view vtable **+4**) builds
each viewport's view/proj from the camera **source transform `cam+0x10`** (via the SecuROM builder
`FUN_00858f30`/`FUN_0085a570`) and drives the scene pass `FUN_00466d40`. The full **camera-struct
offset map** (source transform, view/proj matrices, world pos, FOV) is **live-confirmed** from the
freecam capture. The **gameplay camera** is a *second* ≤5-viewport array (**stride `0x620`, cap 5**,
selected by **`FUN_0070f560`** — the exact PC realization of Xbox `CameraCollisionCastRay`'s 5×`0x620`
loop) that the per-viewport post-render notify **`FUN_0062ef00`** feeds forward via two camera/shake
writers **`FUN_0060f6d0`/`FUN_0060fee0`** (= the *two* `PgSysCamera` sub-systems the Xbox ctor
allocates). Camera **modes** are the ECS component blocks (`CameraCarPreset`/`Tank`/`Turret`/
`Helicopter` / `HumanCameraModifier`, registrars already bound). The camera **collision cast** and
the exact **sim-side mode/follow-cam pose math** stay behind the SecuROM/vtable seam → **confirm-live**
(the freecam RE nailed the override seam `cam+0x10` regardless of the upstream writer name).

---

## 0.5 Master marriage table (whole row at a glance)

Per-cluster evidence in §1–§6. A bare Xbox name (or "—") means the Xbox *code body* is unlocated
(name-string only, or stripped) and the marriage is **PC-anchored**.

| Role | Xbox symbol / addr | PC addr | Married by | Conf |
|---|---|---|---|---|
| **Render-view / camera singleton** | `PgSysRender` family | **`PTR_PTR_00dfc2f8`** → obj `0x017CFAF0` | scheduler §5 + render-view crash doc; `+0x14`/`+0x10`/`+0x34` render slots | H |
| **Per-viewport render loop** (build view/proj, drive scene) | (`ffCameraStateUpdate` / `Camera::EndFrame` region — strings-only on Xbox) | **`FUN_0085a9e0`** (render-view vtable **+4**, caller `0x0046a27f` in `FUN_0046a3c0`) | read body: walks `view+0x2b90` viewports, `cam = view + vpidx*0xE80` | H |
| **View/proj matrix builder** (reads `cam+0x10`) | — | **`FUN_00858f30`** → `(*_DAT_02455314)()`; helper **`FUN_0085a570`** | read: `FUN_00858f30((uint)vpidx*0xE80+0x10+view)`; builder is a SecuROM VM island | H (seam) |
| **Scene-pass driver** (per active scene) | `Model::Render` family | **`FUN_00466d40`** (render_core §5) | read: `FUN_00466d40(*(view+0x2b94))` from `FUN_0085a9e0` | H |
| **≤5 viewport array (gameplay/split-screen)** | `CameraCollisionCastRay @825ea110` (loop `5`, stride `0x620`) | **`FUN_0070f560`** (owner+0x20, stride **0x620**, cap **5**, returns `+0x200`) | read body: `while(i<5) p+=0x620` — byte-for-byte the Xbox 5×0x620 loop | H |
| **Per-viewport post-render notify** (drives cam writers) | (`CameraUpdate` region) | **`FUN_0062ef00`** (render-view listener `view+0x2ba0` = `&PTR_PTR_00df6b0c`, phase 2) | read body: phase==2 → `FUN_0060f6d0`/`FUN_0060fee0`; matches `FUN_0085a9e0`'s `(listener+4)(phase,vp)` calls | H |
| **Camera sub-system A** (writer/shake pass) | `PgSysCamera` sub-obj A (`FUN_8246cf08(0x83102288,…)` → `owner+0x1ec0`) | **`FUN_0060f6d0`** (2045 B, prologue island `_DAT_02455370`) | read: reads active-cam pos `+0xb20`, mode-gates via `FUN_0070f560`, proximity emitter pass | M |
| **Camera sub-system B** (writer/shake pass) | `PgSysCamera` sub-obj B (`FUN_8246cf08(0x83151308,…)` → `owner+0x1ec4`) | **`FUN_0060fee0`** (1982 B) | read: mirror of A (same guard + `FUN_0070f560` + mode gate) | M |
| **Camera pose accessor** (pos + quat) | — | **`FUN_0042ee10`** (packs `{pos@+0x44, quat@+0x50/54/5c, w}`) | read body; called by ~12 `Camera.*` cfuncs | H |
| **`CameraCarPreset` mode descriptor** | `CameraCarPreset @829ef010` (elem `0x50`) | **`FUN_006401b0`** (`s_CameraCarPreset`) | `camera.md` PC xref (string-anchored) | H |
| **`CameraShake` descriptor** | `CameraShake @829ef240` (elem `0x10`) | **`FUN_006402b0`** (`s_CameraShake`) | `camera.md` PC xref | H |
| **`CameraShakeTypeEnum`** (7 members) | `CameraShakeTypeEnum @829f…` | enum reg **`FUN_0064ac50`** + field emitter **`FUN_0065ea10`** | `camera.md` PC xref | H |
| `CameraHelicopter`/`Tank`/`Turret`, `HumanCameraModifier` (elem `0x38`) | allocator-size table `@1618-1623/1692` | descriptor cluster `0x0064xxxx` (siblings of `FUN_006401b0`) | pool sizes from Xbox `FUN_824fcac8` args | M |
| **`Camera.*` Lua cfuncs** (`GetCamera`/`GetCameraXZHeading`/heading/yaw) | `GetCamera`/`GetCameraXZHeading`/`GetViewport` (strings, Xbox) | cfunc cluster **`0x5AED70`/`0x5AEFB0`/`0x5AF5E0`/`0x5D58D0`/`0x69BC60`/`0x70A4C0`…** (all call `FUN_0070f560`+`FUN_0042ee10`) | read bodies: lua_State arg, `luaL` argcheck `FUN_0059ff50`, push pattern; table-walk = confirm-live | M |
| **FOV / near-far** | `FovMaxSpeed`/`MaxFov`/`DefaultFov`/`CrouchFov`/`VisionFOV` | `cam+0x48/+0x4c` (proj params) | read: consumers `FUN_00493d50`/`FUN_004a6590` read `cam+0x48/+0x4c` | M |
| **Collision cast** (keep-out-of-geometry ray) | `CameraCollisionCastRay @825ea110` | generic Havok ray `FUN_00432a30` (`hkpWorldRayCaster`) — no camera-region caller located | Xbox uses Havok ray; PC camera caller behind cluster/SecuROM | open |
| **Cinematic / movie path** | `SetCinematicMode`/`InCinematicMode`/`TeleportCamera`; `PgMoviePlayerXenon.cpp` | Lua cfuncs (binding-only, unlocated) | Xbox strings; PC bodies binding-table-only | open |
| **Debug: `FreezeViewport` / F5 "Switch Camera Mode" / marketing / free-eye / rover** | `FreezeViewport @82277410`, `F5 @2177`, `Toggle Marketing/FreeEye Cam` | — (devkit-only; stripped on retail) | Xbox-only debug tooling | n/a-retail |

---

## 1. Where the camera sits in the frame (render + tick integration)

The camera has **two touch-points per frame**, on opposite sides of the master tick
([`scheduler_tick_code_map.md`](scheduler_tick_code_map.md)):

```
FUN_00630ef0  RunFrame
  5. FUN_004c14f0  MASTER UPDATE  →  FUN_004c15e0 (5-layer 0→4)
        layer 4 → FUN_004c0ec0 → FUN_004c9740   (layer-4 per-system call list)
             │   ├─ FUN_00872d30  streaming     (world_streaming §2)
             │   ├─ FUN_00502510  population
             │   ├─ FUN_00532f80  vehicle-control pump
             │   ├─ FUN_00675e50  Rt* / LOD proxies
             │   └─ (gameplay camera pose update — fills the 0x620 owner records; §4)  ← SIM SIDE
  6. render  =  (*(view+0x14))()   on PTR_PTR_00dfc2f8
        └─ parallel render worker FUN_0046a3c0 : sets view+0x2b94 (active scene), then (*(view+4))()
             (*(view+4))  →  FUN_0085a9e0   ← PER-VIEWPORT CAMERA LOOP (§2)          ← RENDER SIDE
                  per viewport vp in [view+0x2b90 .. 0):
                    FUN_00858f30(cam+0x10)   build view/proj (SecuROM _DAT_02455314; helper FUN_0085a570)
                    (listener+4)(0, vp)      phase 0 pre
                    FUN_00466d40(view+0x2b94)  scene pass
                    (listener+4)(1, vp)      phase 1
                    (listener+4)(2, vp)  →  FUN_0062ef00  post: camera/shake writers (§4)
```

**`FUN_0085a9e0` (render-view vtable +4, read first-hand):**

```c
QueryPerformanceCounter(&t0);
uVar1 = *(u16*)(view + 0x2b90);              // viewport COUNT
do {                                         // count..0, descending
  uVar1--;  if ((short)uVar1 < 0) { /* stamp frame time _DAT_01176624 */ return; }
  *(u16*)(view + 0x2b92) = uVar1;            // set ACTIVE viewport index
  FUN_00858f30(uVar1*0xE80 + 0x10 + view);   // build view/proj from cam+0x10  (SecuROM builder)
  if (view+0x2ba0) (*(*(view+0x2ba0)+4))(0, uVar1);          // listener phase 0
  if (*(char*)(uVar1*0xE80 + 0x3c + view) && view+0x2b94) {  // vp enabled && scene set
    FUN_00466d40(*(view + 0x2b94));                          // SCENE PASS
    if (view+0x2ba0) (*(*(view+0x2ba0)+4))(1, uVar1);        // listener phase 1
    if (view+0x2ba0) (*(*(view+0x2ba0)+4))(2, uVar1);        // listener phase 2 → FUN_0062ef00
  }
} while (true);
```

So the camera geometry the renderer consumes is per-viewport, and each viewport is enabled by its
`cam+0x3c` byte. `view+0x2b94` is the active `PgScene` pointer (set at `0x0053331`/`0x0053334` from
`scene+0x104`, and by the worker `FUN_0046a3c0` before it calls `(*(view+4))`). The listener object
is installed at `view+0x2ba0 = &PTR_PTR_00df6b0c` (decomp `0x98677`); its `+4` method is the
per-viewport notify `FUN_0062ef00` (§4).

---

## 2. The render-view camera struct — the `0xE80` per-viewport slot (H, live-confirmed)

`cam = PTR_PTR_00dfc2f8 + (*(u16*)(view+0x2B92)) * 0xE80`. Offsets below are **read-confirmed in the
decomp** and, for the starred rows, **live-confirmed** from the freecam x32dbg capture.

| Field | Off | Meaning | Evidence |
|---|---|---|---|
| source transform ★ | `+0x10` | camera-to-world matrix the builder reads (**the freecam override seam**) | builder input `FUN_00858f30(cam+0x10)`; translation row at `+0x24/+0x28/+0x2c` (`FUN_0046a730`) |
| enabled | `+0x3c` | per-viewport active byte (gates the scene pass) | `FUN_0085a9e0` `*(cam+0x3c)!='\0'` |
| view sub-record ptr | `+0x38` | per-viewport render sub-object (`*(…+0x38)*0x1c` indexed) | `FUN_0048beb0` line 71119 |
| FOV / proj params | `+0x48`,`+0x4c` | projection floats (near/FOV) read by frustum/proj consumers | `FUN_00493d50` (75791/93), `FUN_004a6590` (84517) |
| viewport rect | `+0x960`,`+0xaa0` | sub-viewport index/array | `FUN_00466d40` line 52669 |
| **view matrix** ★ | `+0xab0` | D3DX view matrix (built from `+0x10`) | `D3DXMatrixMultiply(…,cam+0xab0)` (84061/84208) |
| proj matrix | `+0xaf0` | projection matrix | `D3DXMatrixMultiply(…,cam+0xaf0)` (84061) |
| `+0xb10/+0xb18` | | proj/frustum scalars | `FUN_00493d50` (75750–57) |
| **camera world pos** ★ | `+0xb20`,`+0xb24`,`+0xb28` | camera position (x,y,z) | pos reads `FUN_0049e320` (80203), dist² helpers `FUN_004aaab0`+twins (87367…) |
| `+0xb58/+0xb68` | | fwd/at vector pair | `FUN_00487540` (69221/25) |
| **view-proj matrix** ★ | `+0xb70` | combined view×proj (shader `ViewProj`) | `FUN_0049a3c0` (78674) |

**View-root fields** (off `PTR_PTR_00dfc2f8`, not per-viewport): `+0x2b90` viewport **count**,
`+0x2b92` **active viewport index** (u16), `+0x2b94` active `PgScene` ptr, `+0x2ba0` render-notify
listener (`&PTR_PTR_00df6b0c`), `+0x2bd0` a per-frame shake/blend scalar (`FUN_0060f6d0`),
**`+0x19a0/+0x19a8` = a *cached* camera-pos copy** consumed by the LOD-proxy band test
`FUN_00490220` (prop_lod §3.2; read at decomp 73190/91) — a convenience mirror of the active
`cam+0xb20`, distinct from the per-viewport slot.

> **Live-capture caveat (honest).** In the freecam session `*(0x00DFC2F8)` held `0x017CFAF0` and
> `cam+0xb20` read `[0,0,0]` at the hooked site — i.e. the *static viewport-0 slot* is not the live
> gameplay camera every frame; the live camera pose arrives as a register/arg into the builder path.
> The **override seam `cam+0x10` is nonetheless correct** (hooking `FUN_0085a9e0` and rewriting
> `cam+0x10` changes the rendered view). Treat the offset map as the *layout*; the live slot index is
> `view+0x2b92` (set each iteration), which the static probe did not follow — a confirm-live item.

---

## 3. The gameplay ≤5-viewport array + the two `PgSysCamera` sub-systems (H/M)

Distinct from the render-view `0xE80` slots there is a **gameplay camera-owner array**, `stride
0x620`, capped at **5** — the split-screen/co-op players. **`FUN_0070f560`** is the selector and it
is a **byte-for-byte match to the Xbox `CameraCollisionCastRay @825ea110` loop** (`lVar5 = 5`,
`lVar2 += 0x620`):

```c
undefined4 FUN_0070f560(void) {          // ESI = query record, EDI = owner base
  if (ESI == 0) return 0;
  i = 0;  p = EDI + 0x20;
  while (ESI != p) { i++; p += 0x620; if (4 < i) return 0; }   // ≤5 viewports, stride 0x620
  return *(u32*)(i*0x620 + 0x200 + EDI);                       // the matched viewport's camera-owner
}
```

The **Xbox `PgSysCamera @825e9830` ctor allocates two sub-systems** into `owner+0x1ec0/+0x1ec4`
(`camera.md` §"How it works"). On PC the two sub-systems reappear as the **two per-viewport camera
writers** the post-render notify runs back-to-back:

**`FUN_0062ef00`** (render-view listener `+4`, phase 2 only):

```c
if (in_EAX == 2) {                                   // phase 2 (post) for viewport EDI
  if (*(char*)(view + EDI*0xE80 + 0x3c) && PTR_PTR_00e7adfc[0x108] && *(int*)(…+0x104))
      FUN_00468ed0();                                // render sub-pass
  c = PTR_DAT_01175cdc[99];                          // world-present gate ([99] = 'c')
  if (c && *(int*)(DAT_01175fb0 + 0x6c))  FUN_0060f6d0(*(int*)(DAT_01175fb0+0x6c), EDI);  // sub-A
  (*(*(view)+0x38))();                               // flip/vsync device slot
  if (c && *(int*)(DAT_01175fb0 + 0x6c))  FUN_0060fee0(*(int*)(DAT_01175fb0+0x6c), EDI);  // sub-B
  FUN_00709790(EDI);  FUN_00609e00(EDI);             // post callbacks
}
```

**`FUN_0060f6d0` (sub-system A, prologue SecuROM island `_DAT_02455370`):** reads the active
viewport's world pos (`cam+0xb20/+0xb28`) and a per-frame scalar (`view+0x2bd0 * cam+0x34`),
resolves the local player/vehicle via `FUN_0070f560`, then **mode-gates on the vehicle-camera mode**
(`(*(owner+0x2c))() == 4` and `== 3` — the per-vehicle vs on-foot camera-mode selectors), and runs a
**proximity-weighted per-emitter pass** over records `param_1 + 0x20 + slot*0x18`: for each emitter,
`dist²` to the camera → intensity ramp `(r² - d²)/(r²·k)` → projected to screen via `FUN_0046a680`
(world→screen using the active viewport). This is the **camera-shake / screen-space effect
accumulator** (matches Xbox `CameraShake` + `CameraShakeScale`; the `(modifer)` weapon FOV/shake
modifiers feed the same intensity). **`FUN_0060fee0` (sub-system B)** is the structural mirror (same
world-present guard, same `FUN_0070f560` + mode gate). Confidence **M** — bodies read and the sub-A/B
pairing to the Xbox two-sub-system ctor is a strong fingerprint, but the *exact* semantic of each
emitter pass (shake vs. audio vs. HUD-marker) is inferred from the geometry, not a surviving string →
confirm-live.

> **World→screen / screen→world helpers.** `FUN_0046a680`/`FUN_0046a730` project a point using the
> active viewport (they call the matrix builder `FUN_0085a570(cam+0x10,…)` then apply
> `DAT_00bbb99c` = the half-viewport scale). These are the projection primitives the shake pass and
> the `Camera.*` cfuncs share.

---

## 4. Camera modes (ECS component blocks) — the per-vehicle / on-foot selection

The camera **modes** are data, not code branches: each controlled object carries a
mode-specific ECS component. The **PC registrars are already bound** (`camera.md` §"PC
decompilation cross-reference", read first-hand there):

| Mode component | PC registrar | Xbox elem size | role |
|---|---|---|---|
| `CameraCarPreset` (+`…Link`) | `FUN_006401b0` (`s_CameraCarPreset_00bc4e7c`) | `0x50` | per-car chase-cam preset (offset/pitch/yaw/zoom/blend/FOV) |
| `CameraHelicopter` | descriptor cluster `0x0064xxxx` | `0xa0` (160) | heli cam (`CamDistToHeli`) |
| `CameraTank` | descriptor cluster | `0xc0` (192) | tank cam (`Tank Camera`, pitch/yaw readouts) |
| `CameraTurret` | descriptor cluster | (768 pool) | turret cam (`CamOffset`, pitch/yaw clamp `PitchMin>PitchMax`) |
| `CameraShake` | `FUN_006402b0` (`s_CameraShake_00bc4ed0`) | `0x10` | shake block (type enum + scale) |
| `HumanCameraModifier` | descriptor cluster | `0x38` (56) | on-foot cam modifier (crouch/aim FOV) |
| `CameraShakeTypeEnum` | enum-reg `FUN_0064ac50`; field emit `FUN_0065ea10` | 7 members (`HardRandom`/`MediumRandom`/…) | shake kind |

Each preset is a bag of the tunables `camera.md` lists (`CameraOffset`, `CameraPitchOffset`,
`CameraYawOffset`, `CameraZoomOffset[Attached]`, `CameraOffsetScaleAt{Min,Max}Pitch`,
`CameraBlendTime`, `FovMaxSpeed`/`MaxFov`/`DefaultFov`/`CrouchFov`/`VisionFOV`). On Xbox the runtime
that *materializes* a preset from these named floats is `CameraBlendTime @825109e0`
(`FUN_825047d0(default, key)` per param) — the PC analog is a keyed-float reader in the same camera
cluster (not separately located this pass; the tunables load as ordinary reflection-stream data into
the component blocks above). The **mode selection at runtime** is the `(*(owner+0x2c))()` vtable
query in `FUN_0060f6d0`/`FUN_0060fee0` (returns 4 = a vehicle chase mode, 3 = another) driven off the
player's currently-ridden object — i.e. the same "which vehicle am I in" resolution the vehicle map's
seat/ride rings produce ([`vehicle_code_map.md`](vehicle_code_map.md) §1.4).

**FOV** lives at `cam+0x48/+0x4c` (proj params) and is read by the frustum/proj consumers
`FUN_00493d50`/`FUN_004a6590`; the speed-tied widening (`FovMaxSpeed`) and the `CrouchFov`/`Fov`
`(modifer)` weapon adjustments write these before the builder runs — the write site is in the mode
cluster (confirm-live; no surviving string to pin the exact setter).

---

## 5. Input → camera (look / aim)

The camera yaw/pitch is fed by the same look/aim input the rest of the game consumes
([[shadow-pc-absolute-mouse-input]]): the engine prefers **raw mouse delta** and auto-latches a
`CursorMoved` + recentre fallback (Confined, never Locked) — Shadow streams *absolute* coords via raw
input, so the camera-driving code must consume deltas, not absolute positions. In the retail flow the
right-stick / mouse-look verbs arrive through the input action set (Mercs2.ini-driven, see the input
memory) and are applied to the active camera-owner record (`owner+0x2c` mode object) each frame; the
resulting pose lands in the gameplay `0x620` owner record, which the writers (§3) forward into the
render-view `cam+0x10` source transform. The concrete per-axis apply (yaw += dx, pitch clamp
`PitchMin..PitchMax` — the Xbox `WARNING [PitchMin > PitchMax]` guard) sits in the same mode cluster
and is **confirm-live** (string-stripped; recover by breaking on a write to `cam+0x10` while the USER
moves the look axis). The **modern engine already owns this seam** (§7).

---

## 6. `Camera.*` Lua cfuncs + cinematic (M / open)

A cluster of Lua cfuncs (`callers=[]` = binding-table-only, `param_1 = lua_State`, argcheck
`FUN_0059ff50`, the `*(int*)(L+8)+=8` push idiom) reach the active camera through **`FUN_0070f560`**
(§3) and the pose accessor **`FUN_0042ee10`** (packs `{pos=@+0x44, quat=@+0x50/54/5c, w}` from the
camera-owner record):

| PC cfunc VA | shape | likely Xbox name |
|---|---|---|
| `0x005AED70` | reads camera transform, returns a heading/vector | `GetCamera` / camera getter |
| `0x005AEFB0` | quaternion → XZ heading (normalize `DAT_00b92874`, extract yaw) | **`GetCameraXZHeading`** / `nCameraHeading` |
| `0x005AF5E0` | multi-arg, builds a transform (`FUN_0059fc30`) | `TeleportCamera` / `FindPointFromCamera` candidate |
| `0x005D58D0`, `0x0069BC60`, `0x0070A4C0`, `0x0070AA10` | all call `FUN_0042ee10` | `GetViewport`/`FaceCamera`/`SpawnFromCamera` family |

The exact name→VA binding needs the **`Camera` luaL_Reg table walk** (the same
`file_offset = VA − 0x400000` scan the streaming map validated) → **confirm-live**; the *shapes* above
are read-confirmed. `SetCinematicMode`/`InCinematicMode`/`SetBriefingCheapCinematic` and the
`PgMoviePlayerXenon.cpp` movie path are Xbox strings with **binding-only PC bodies** (unlocated) —
the cinematic set-view path routes through the same `cam+0x10` seam. (A minor `[…] "Camera"="Center"`
key is read from `Mercs2.ini` by `FUN_004fb6b0` via `GetPrivateProfileStringA` — a split-screen/debug
anchor, not the runtime camera.)

---

## 7. Open questions / confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **`cam+0x10` writer** — break on a *write* to `PTR_PTR_00dfc2f8 + [view+0x2b92]*0xE80 + 0x10`
   while the USER moves the camera → names the sim-side pose writer (the layer-4 camera update that
   fills the `0x620` owner record and copies it into the render slot). This is the one true gap: the
   override seam is proven, the upstream writer name is not.
2. **Camera collision cast** — the Xbox `CameraCollisionCastRay` is a per-viewport (≤5, stride
   `0x620`) Havok ray bundle; the PC generic ray wrapper is `FUN_00432a30` (`hkpWorldRayCaster`,
   used by vehicle wheels/tank), but **no camera-region caller of it is statically visible** → break
   `FUN_00432a30` with the camera pushed against a wall to confirm the camera issues the cast (and
   from which cluster fn), or find a distinct camera cast entry behind the SecuROM builder.
3. **SecuROM islands** — read live: `_DAT_02455314` (view/proj builder behind `FUN_00858f30`) and
   `_DAT_02455370` (writer-A prologue behind `FUN_0060f6d0`).
4. **Mode gate values** — break `FUN_0060f6d0`, log `(*(owner+0x2c))()` while switching between
   on-foot / car / heli / tank to map each return (3/4/…) to a camera mode.
5. **FOV setter** — HW-write bp on `cam+0x48` to catch the `FovMaxSpeed`/`CrouchFov` writer and the
   speed-widening curve.
6. **`Camera` luaL_Reg table** — walk it to bind `GetCamera`/`GetCameraXZHeading`/`SetCinematicMode`/
   `TeleportCamera` name→VA (§6), and to confirm the live-camera slot vs. the static probe (§2 caveat).
7. **Shake vs. HUD** — confirm whether `FUN_0060f6d0`/`FUN_0060fee0`'s emitter pass is camera shake
   (writes back a shake offset into `cam+0x10`) or a screen-space marker projection (writes a 2D HUD
   coord) — break and inspect the store targets.

---

## 8. Reconciliation with `mercs2_engine` (scoreboard row 19 = 🟡)

**Status: 🟡 — the render-camera seam and a free-fly / auto-orbit / `set_view` path exist in-engine;
the faithful 3P follow-cam + modes + shake + collision cast are the remaining targets.**

- **What matches / is the seam:** the engine produces a view + view-proj + `cameraPos` for the wgpu
  path (`mercs2_engine::scene`) exactly where the retail engine builds `cam+0xab0/+0xb70/+0xb20` from
  `cam+0x10`. The modern `set_view` seam is the analog of writing `cam+0x10`; a free-fly + auto-orbit
  debug camera already drives it, and a 3P camera lives in the game crate.
- **The reference this map gives the reimpl:**
  1. **A ≤5-viewport model** — two parallel arrays in retail (render slots stride `0xE80`; gameplay
     camera-owner records stride `0x620`, cap 5) with an active-index (`view+0x2b92`). The engine can
     collapse these to one per-player camera + a viewport list, but the **≤5 cap and per-viewport
     enable byte (`cam+0x3c`)** are the split-screen contract.
  2. **Modes as data** — port `CameraCarPreset`(0x50)/`CameraHelicopter`/`CameraTank`/`CameraTurret`/
     `HumanCameraModifier`(0x38) as reflection-loaded components (like `wpn_*`), selected by the
     ridden-object mode query — not as hard-coded camera branches.
  3. **Shake** as a typed (`CameraShakeTypeEnum`, 7 kinds), scalable (`CameraShakeScale`),
     **proximity-weighted** accumulator (the `FUN_0060f6d0` emitter pass), composed onto the base pose
     before `set_view`.
  4. **Collision cast** — a keep-camera-out-of-geometry ray (Xbox `CameraCollisionCastRay`, PC
     `hkpWorldRayCaster` `FUN_00432a30`) pulling the camera in front of world geometry; integrate with
     the engine's physics ray layer.
  5. **Input** — feed yaw/pitch from **raw deltas** ([[shadow-pc-absolute-mouse-input]]) with the
     `PitchMin..PitchMax` clamp; reuse the input action set already built.
  6. **Cinematic / `set_view`** — the cinematic path writes the same seam; script-facing
     `Camera.*` / `SetCinematicMode` map to engine host calls.

---

## 9. Provenance

- **PC decomp:** `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (unpacked SecuROM image, base
  `0x00400000`). Bodies read first-hand: `FUN_0085a9e0` (per-viewport loop), `FUN_00858f30`
  (SecuROM builder `_DAT_02455314`), `FUN_0070f560` (≤5×0x620 selector), `FUN_0062ef00` (post-render
  notify), `FUN_0060f6d0`/`FUN_0060fee0` (camera/shake writers), `FUN_0042ee10` (pose accessor),
  `FUN_0046a680`/`FUN_0046a730` (project), the `0xE80`-stride consumers (`FUN_00466d40`, `FUN_0049e320`,
  `FUN_0049a3c0`, `FUN_00493d50`, `FUN_004a5830`, `FUN_004aaab0`+twins), the `Camera.*` cfunc cluster
  (`0x5AED70`/`0x5AEFB0`/`0x5AF5E0`). Component descriptors `FUN_006401b0`/`FUN_006402b0`/
  `FUN_0064ac50`/`FUN_0065ea10` bound in `camera.md`.
- **Xbox ground truth:** `docs/mercs2-pdb-analysis/camera.md` (`PgSysCamera @825e9830` two-sub-system
  ctor, `CameraCollisionCastRay @825ea110` 5×0x620 loop, `CameraBlendTime @825109e0` preset loader,
  component elem sizes from `FUN_824fcac8`), `pangea-engine-core.md` (`PgSys*` framework),
  `debug-cheat-menu.md` (`FreezeViewport`, F5/F6, marketing/free-eye/rover cams).
- **Live capture:** the freecam x32dbg sessions ([[shadow-pc-absolute-mouse-input]] + freecam.asi
  work) — the `cam+0x10`/`+0xab0`/`+0xb20`/`+0xb70` offset map and the `view = *0x00DFC2F8`,
  `cam = view + [view+0x2b92]*0xE80` reach, plus the honest static-slot caveat (§2).
- **Cross-refs:** [`scheduler_tick_code_map.md`](scheduler_tick_code_map.md) §5,
  [`render_core_code_map.md`](render_core_code_map.md) §5,
  [`prop_lod_imposter_code_map.md`](prop_lod_imposter_code_map.md) §3.2,
  [`vehicle_code_map.md`](vehicle_code_map.md) §1.4, [`world_streaming_code_map.md`](world_streaming_code_map.md).
- Confidence stated per row; the sim-side pose writer, the camera collision-cast caller, the FOV
  setter, and the `Camera` luaL_Reg name→VA table are the documented confirm-live gaps (§7).
