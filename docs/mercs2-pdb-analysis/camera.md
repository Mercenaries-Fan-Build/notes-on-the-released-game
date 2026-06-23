# Camera

Scope: the camera system — cameras and camera modes, cinematic/marketing cameras, FOV control, camera shake, collision, and the viewport/render-camera interface.

Provenance: all evidence is symbol/string data recovered from the Jul 11 2008 preview "Profile" devkit build of `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, PowerPC/Xbox 360). This is not a real `.pdb`. Offsets are PE offsets exactly as they appear in `output/jul08_prototype/inventory/camera.txt`. String line numbers reference `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt`.

## Overview

The camera subsystem drives the player's view across the game's many control contexts: on-foot human, vehicles (car/tank/turret), and helicopter, plus scripted cinematic and "marketing" cameras. It is integrated with Pandemic's Pangea engine — the string `PgSysCamera` (@7804) names the engine-side camera system, sitting alongside the named entity-component blocks (e.g. `CameraCarPreset`, `CameraHelicopter`, `CameraTank`, `CameraTurret`, `CameraShake`) that appear in the entity allocator-size table (strings @1618-1623). FOV, pitch/yaw offsets, blend time, shake, and collision casting are all exposed as named tunable parameters (strings @6481-6962), and there is a debug "Camera Tweak"/"Camera Gauges" menu path for live tuning.

The symbols cluster into: (1) named camera entity-component blocks, (2) tunable camera parameters (offset/pitch/yaw/zoom/FOV/shake), (3) the engine camera system & per-frame update entry points, (4) Lua/script bindings for cameras and cinematic mode, and (5) debug-menu camera tools. No camera-specific C++ source path or RTTI class survives in the recovered evidence (see Evidence & confidence).

## Source files

No camera-specific build path is present in `output/jul08_prototype/mercs2_xenon_p.source_paths.txt`. The only directly adjacent path is the Xenon movie player, reached through the cinematic path:

```
d:\projects\ReleaseLine\Mercs2\Pangea\Src\Xenon\PgMoviePlayerXenon.cpp
```

(This file is referenced by the `Failed Loading Movie %s` error string @7800; its relationship to camera is via cinematics, not proven by a camera symbol.)

## Key classes

No camera RTTI class (`.?AV.../.?AU...`) is present in `output/jul08_prototype/mercs2_xenon_p.rtti_classes.txt`. The closest class-like tokens come from strings rather than the RTTI table:

- `PgSysCamera` (string @7804) — engine camera-system object (class/singleton name).
- `hkxCamera` (string @10641) — Havok scene-export camera type (Havok `hkx*` namespace; present in the binary, but not necessarily used at runtime).

## Symbols by area

All entries below are from `output/jul08_prototype/inventory/camera.txt` (25 symbols, all `.rdata`).

### 1. Engine camera system & per-frame update

| Offset | Section | Symbol |
|---|---|---|
| 0x0014f54 | .rdata | Camera::EndFrame |
| 0x0047ac0 | .rdata | CameraUpdate |
| 0x0047aa8 | .rdata | CameraCollisionCastRay |

`Camera::EndFrame` is the only namespaced (`Class::method`) camera symbol, indicating a `Camera` class with an `EndFrame` per-frame finalize step. `CameraUpdate` is the update tick; `CameraCollisionCastRay` is the camera-against-world collision probe — a ray cast to keep the camera out of geometry. The matching string `ffCameraStateUpdate` (@7813) and runtime label `PgSysCamera` (@7804) corroborate an engine-side state-update entry.

### 2. Named camera entity-component blocks

| Offset | Section | Symbol |
|---|---|---|
| 0x00312a8 | .rdata | CameraCarPreset |
| 0x0032420 | .rdata | CameraCarPresetLink |
| 0x0032434 | .rdata | CameraHelicopter |
| 0x0032448 | .rdata | CameraTurret |
| 0x0032458 | .rdata | CameraTank |
| 0x00312b8 | .rdata | CameraShake |
| 0x0013c2c | .rdata | CameraCtrl |
| 0x001219c | .rdata | CameraPathSpawnMode |

These name distinct camera modes per controlled object: a car preset (with a "link" variant), helicopter, turret, and tank. `CameraShake` is its own block. The entity allocator-size table lists these with pool counts (strings @1618-1623): `CameraCarPreset 128 32`, `CameraCarPresetLink 2048`, `CameraHelicopter 160 32`, `CameraShake 384 128`, `CameraTank 192 32`, `CameraTurret 768`, and a related on-foot block `HumanCameraModifier 64 64` (@1692). `CameraCtrl` is the camera-controller token; `CameraPathSpawnMode` relates to spawning along a camera path, matching the "Predefined Path Cam"/"Rover Fixed Path" debug entries below.

### 3. Tunable camera parameters (offset / pitch / yaw / zoom)

| Offset | Section | Symbol |
|---|---|---|
| 0x003cfa0 | .rdata | CameraOffset |
| 0x0049270 | .rdata | CamOffset |
| 0x003cfd4 | .rdata | CameraOffsetScaleAtMaxPitch |
| 0x003cff0 | .rdata | CameraOffsetScaleAtMinPitch |
| 0x003e1a8 | .rdata | CameraPitchOffset |
| 0x003e1c0 | .rdata | CameraYawOffset |
| 0x003e200 | .rdata | CameraZoomOffsetAttached |
| 0x003e21c | .rdata | CameraZoomOffset |
| 0x003cef8 | .rdata | CameraBlendTime |
| 0x003cec8 | .rdata | CamDistToHeli |

Positional/orientation tuning: a base `CameraOffset`/`CamOffset`, pitch- and yaw-relative offsets, zoom offsets (including an "Attached" variant), pitch-scaled offset scaling at min/max pitch, the camera-to-helicopter distance (`CamDistToHeli`), and the `CameraBlendTime` used when transitioning between cameras (corroborated by the tunable string `CameraOffsetZ` @7989).

### 4. FOV & camera shake

| Offset | Section | Symbol |
|---|---|---|
| 0x003edc0 | .rdata | FovMaxSpeed |
| 0x003eebc | .rdata | CameraShakeScale |
| 0x003b1d0 | .rdata | CameraShakeTypeEnum |
| 0x0026ad4 | .rdata | CameraFade |

`FovMaxSpeed` is one of a cluster of FOV tunables seen in strings (`MaxFov`, `DefaultFov`, `CrouchFov`, `StickLengthAtMaxFovSpeed`, `VisionFOV` @6829-6963) — FOV widening tied to movement speed. `CameraShakeScale` scales shake intensity, and `CameraShakeTypeEnum` enumerates shake kinds (string @6033 lists members `HardRandom`, `MediumRandom`, ... @6034+). `CameraFade` is the screen fade tied to camera transitions.

## Notable strings

Tunable parameter names (the camera-tweak parameter labels, padded for the debug UI):

- `FovMaxSpeed` (@6947), `MaxFov` (@6948), `DefaultFov` (@6949), `CrouchFov` (@6963), `StickLengthAtMaxFovSpeed` (@6956), `VisionFOV` (@6829) — FOV control set.
- `CameraOffset` (@6496), `CameraOffsetScaleAtMaxPitch` (@6499), `CameraOffsetScaleAtMinPitch` (@6500), `CameraOffsetZ` (@7989), `CameraPitchOffset` (@6751), `CameraYawOffset` (@6752), `CameraZoomOffsetAttached` (@6755), `CameraZoomOffset` (@6756), `CameraBlendTime` (@6484), `CamDistToHeli` (@6481).
- `CameraShakeScale` (@6962, also `CameraShakeScale    (modifer)` @7978 — note the in-build typo "modifer"), `CrouchFov           (modifer)` (@7979), `Fov                 (modifer)` (@7980) — these are weapon/state modifiers that adjust camera FOV/shake.

Debug / format strings (Profile build instrumentation):

- `FOV: %3.2f degrees` (@7532), `?S33FOV: %.2f` (@7814) — live FOV readout.
- `camera: %s` (@7808), `Tweaking is not available for this camera` (@7811) — camera-tweak gating message.
- `ffCameraStateUpdate` (@7813), `PgSysCamera` (@7804), `Mercs2D cam` (@7802) — engine update entry / system / 2D camera label.
- `Tank Camera` (@7998) with `Current Pitch: %.2f` / `Current Yaw: %.2f` readouts; turret block follows (`CamOffset`, `turret`, @8019+) with pitch/yaw clamp warnings `WARNING [PitchMin > PitchMax] WARNING` and `WARNING [YawMin > YawMax] WARNING`.

Debug menu entries (the in-game "Camera Tweak"/"Camera Gauges" tooling):

- `Camera Tweak Toggle` (@681), `Camera Gauges` (@696), `Toggle Camera Shake` (@830).
- `Predefined Path Cam`, `Rover Fixed Path`, `Rover Free Eye Camera` (@837), `Ground Free Eye Camera` (@838), `Toggle FreeEye Cam`, `Toggle Marketing Cam` — free-eye/marketing/path camera modes.
- `F5 "Switch Camera Mode"` (@2177), `F6 "Switch Camera Mode"` (@2178) — devkit hotkeys.

Script (Lua) bindings — camera & cinematic control exposed to mission scripting:

- `GetCamera` (@4529), `TeleportCamera` (@4528), `GetCameraXZHeading` (@4532), `FindPointFromCamera` (@4378), `SpawnFromCamera` (@4399), `FaceCamera` (@6223), `useTrackingCamera` (@9729), `nCameraHeading` (@7527).
- `GetViewport` / `GetViewportId` (@ adjacent to `GetCamera`, ~line 4529) — viewport accessors bound next to the camera accessors.
- `InCinematicMode` (@4514), `SetCinematicMode` (@4515), `SetBriefingCheapCinematic` (@4142), `NetSafePlayCheapCinematic` (@7750), `VO.PRIORITY_CINEMATIC = 0;` (@4775) — cinematic-mode control.

Enum/category labels:

- `Camera3D` (@5963), `Camera2D` (@5964) — 2D/3D camera spawn types.
- `CameraShakeTypeEnum` (@6033), `HumanCameraBehaviorCategory` (@6029) with members `UNKNOWN`/`Heavy`/`Rifle` (@6030+).

Renderer-side viewport (the GPU constants the camera feeds): `InvViewport` (@15568), `viewport` (@15575), `cameraPos` (@15576) appear in a shader constant-buffer field list (`viewContextData.ViewProj`, `LocalToWorld`, ...).

## PC decompilation cross-reference

These map the camera system's Xbox symbols to functions in the PC retail decomp (`output/_ghidra/all_functions_decomp.txt`). The Xbox build has no recovered camera RTTI vtables, so there are no high-confidence vtable bridges for this system; all matches here are string-anchored (medium confidence — the cited string literally appears in the function body, but the function is a registrar/descriptor-builder, not a 1:1 method). Each FUN_ below was confirmed by reading the body.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| `CameraCarPreset` | `FUN_006401b0` | string | component-block descriptor registrar (stamps `s_CameraCarPreset`) |
| `CameraShake` | `FUN_006402b0` | string | component-block descriptor registrar (stamps `s_CameraShake`) |
| `CameraShakeTypeEnum` | `FUN_0064ac50` | string | global enum-registry (registers 65 enums incl. `CameraShakeTypeEnum`, 7 members) |
| `CameraShakeTypeEnum` | `FUN_0065ea10` | string | per-component field emitter referencing `CameraShakeTypeEnum` |

`CameraShakeTypeEnum` appears via two distinct functions (`FUN_0064ac50` registers the enum; `FUN_0065ea10` consumes it when building a component's field layout) — the resolver listed both; they are not duplicates of one method.

### Annotated excerpts

`FUN_006401b0` (and its twin `FUN_006402b0` for `CameraShake`) is a one-shot descriptor initializer for an ECS component block. It fills a global descriptor struct, installs a stream-copy vtable, seeds a hash, then stamps the block's type-name string:

```c
_DAT_017bce1c = 3;                              // field/version count
_DAT_017bce08 = &PTR_CopyFromStream_00bbed00;   // stream-deserialize vtable
DAT_017bce34 = 0x9e3779b9;                       // golden-ratio hash seed
FUN_0064a770();
_DAT_017bce44 = s_CameraCarPreset_00bc4e7c;     // <-- the anchored type name
```

This is the PC-side counterpart to the Xbox `CameraCarPreset`/`CameraShake` allocator-table entries: it is where the named camera-component block is registered with the engine's serializer, not a per-frame camera method.

`FUN_0064ac50` is the engine-wide enum table builder (16,897 bytes, 65 enum registrations). It allocates each enum's value array, fills `{handle, ordinal}` pairs, then registers it by name. The camera shake enum is registered with 7 members (ordinals 0–6), matching the documented `HardRandom`/`MediumRandom`/... member set:

```c
DAT_00edc6d4[0xc] = uVar3;
DAT_00edc6d4[0xd] = 6;          // 7th member, ordinal 6
DAT_00edc6d0 = 7;              // member count = 7
thunk_FUN_004935d1(s_CameraShakeTypeEnum_00bc6288);  // <-- registers the enum by name
```

`FUN_0065ea10` then references the same `s_CameraShakeTypeEnum` string (`FUN_00656720(s_CameraShakeTypeEnum_00bc6288,0)`) while pushing default field values (`0x3f800000` = 1.0f scale) into a `CameraShake` component descriptor — i.e. it wires the shake-type enum into the component's editable field set.

## Cross-references

- `docs/mercs2-pdb-analysis/rendering-shaders.md` — the camera produces the view matrix / `cameraPos` / `InvViewport` shader constants (string cluster @15565-15576).
- `docs/mercs2-pdb-analysis/vehicles.md` — `CameraCarPreset`, `CameraTank`, `CameraTurret`, `CameraHelicopter`, `CamDistToHeli` are per-vehicle camera modes.
- `docs/mercs2-pdb-analysis/weapons-combat.md` — the `(modifer)` camera FOV/shake adjustments (`CrouchFov`, `Fov`, `CameraShakeScale`) are weapon/aim modifiers; `VisionFOV`, `AimAssist` cluster.
- `docs/mercs2-pdb-analysis/havok-physics.md` — `CameraCollisionCastRay` uses Havok ray casting; `hkxCamera` is a Havok type.
- `docs/mercs2-pdb-analysis/gui-hud.md` — `CameraFade`, reticle, and the debug camera-gauges overlay.
- `docs/mercs2-pdb-analysis/game-systems.md` — Lua bindings `GetCamera`/`SetCinematicMode`/`TeleportCamera` and `PgMoviePlayerXenon.cpp` cinematics.
- `docs/mercs2-pdb-analysis/pangea-engine-core.md` — `PgSysCamera` engine system.

## Evidence & confidence

Symbol count: 25 distinct camera symbols in the inventory, all in `.rdata`. Expanded with ~90 camera/FOV/viewport/cinematic strings from the full strings dump.

Directly attested in the evidence:
- All 25 inventory symbols above exist at the cited offsets in `.rdata` (e.g. `Camera::EndFrame` @0x0014f54, `PgSysCamera` is a string @7804, `CameraCollisionCastRay` @0x0047aa8, `FovMaxSpeed` @0x003edc0).
- The named entity blocks with pool counts (`CameraHelicopter 160 32`, `CameraShake 384 128`, etc.), the FOV/offset/shake tunable labels, the debug-menu entries, and the Lua bindings (`GetCamera`, `SetCinematicMode`, `TeleportCamera`, `GetViewport`) all appear verbatim as strings.
- `hkxCamera` (@10641) and `PgMoviePlayerXenon.cpp` (source path) are present in the binary.

Read from naming and adjacency rather than proven outright: that `CameraCollisionCastRay` keeps the camera out of geometry, that `CameraBlendTime`/`CameraFade` cover camera transitions, that the FOV cluster widens FOV with speed, and that `CameraPathSpawnMode` ties to the "Predefined Path Cam"/"Rover Fixed Path" modes. The viewport shader-constant linkage (`InvViewport`/`cameraPos`) at the camera→renderer boundary comes from a constant-buffer field list, not a camera symbol.

No camera C++ source file or RTTI class survives in the recovered evidence, so the `Camera`/`PgSysCamera` class internals are not directly attested; only `Camera::EndFrame` confirms a `Camera` C++ class with that method. The purpose of `CameraCtrl` vs `Camera` is unclear from symbols alone.
