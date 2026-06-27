# Pangea Engine Core

Foundational engine layer of Pandemic Studios' in-house "Pangea" engine (`Pg*` classes) plus the `Mrx*` runtime/game layer: the object/entity "system" framework, per-frame update/run state machine, resource and asset glue, the heap layout, asset-type registries, and supporting low-level libraries (`Pal*`, `Pimp*`). Physics (Havok `hk*`/`hkp*`), rendering shaders, audio mixing, and AI specifics are documented separately.

Provenance: symbol/string evidence recovered from the Xbox 360 executable `Mercs2_Xenon_P.exe` (Mercenaries 2: World in Flames, Jul 11 2008 preview "Profile" devkit build, PowerPC). Decompressed PE at `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`. Dev build tree was `d:\projects\ReleaseLine\Mercs2\`. This is NOT a real `.pdb` — there is no symbol file on disc; names come from embedded debug strings, RTTI type names, and source-path literals. Offsets are PE-relative as they appear in the inventory.

## Overview

This subsystem is the engine "glue" that ties everything else together. The central source file is `PgGameSystem.cpp` (under `Pangea\Src`), and the strongest structural evidence is a large family of `PgSys*` symbols — engine "systems" registered with and ticked by the game-system manager (e.g. `PgSysPopulation`, `PgSysVehicle`, `PgSysDelete`, `PgSysDisposer`, `PgSysTransformController`, `PgSysCamera`). The per-frame driver is expressed as two state markers, `PgUpdateState` and `PgRunState`, that gate the main loop. The `PgSys*` naming and the `PgGameSystem.cpp` path together point to a system-registry / per-frame `Update` dispatch architecture, with each `PgSys<Name>` an updatable engine system (inferred — no RTTI class layout confirms it).

Around that core sit:
- A set of `.data` singletons that are the **asset-type registries / managers** (`PgConfig`, `PgTemplateDb`, `PgLayerDb`, `PgModel`, `PgScript`, `PgPath`, plus the asset tables `PgMaterialTable`, `PgDecalTable`, `PgAnimationTable`, …).
- A **memory/heap layout** reported in a debug printout (Main, Script, Network, Sound, Device, System heaps; Small Block vs Regular sub-pools).
- An **asset/streaming glue** layer (`PgDecompressionManager::Update`, `Create/ReleaseAsset`, `Read*` block readers) — note this overlaps the world-streaming doc.
- Supporting low-level libraries: `Pimp*` (a multi-CPU job/timer/queue library) and `Pal*` (with generic container/allocator utilities `PalInstanceAllocator`, `PalLookupTable`, `PalGlobalTable`, `PalQueue`).

The scope here is the foundation/glue; many `PgSys*` systems whose *content* is gameplay (AI, vehicles, weapons, population) are owned by sibling docs, but they are listed here because they are instances of the core system framework.

## Source files

Verbatim from `mercs2_xenon_p.source_paths.txt` that belong to this system (core engine, scripting VM, and the supporting Pal/Pimp libraries):

```
d:\projects\releaseline\mercs2\pangea\Src\PgGameSystem.cpp
d:\projects\ReleaseLine\Mercs2\PimpLib\Src\PimpMemory.cpp
d:\mainline\mercs2\pimp\include\pimp_job.h
d:\mainline\mercs2\pimp\include\pimp_queue_a64.h
d:\mainline\mercs2\pimp\include\pimp_timer.h
d:\projects\ReleaseLine\Mercs2\Pal\src\PalEngine.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalGlobalTable.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalInstanceAllocator.cpp
d:\projects\ReleaseLine\Mercs2\Pal\src\PalLookupTable.cpp
d:\projects\releaseline\mercs2\pal\src\PalQueue.h
```

The embedded Lua 5.1.2 VM sources also live under `d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\` (`lstate.c`, `lmem.c`, `ltable.c`, `lstring.c`, `lgc.c`, `ldo.c`, `lfunc.c`, `llex.c`, `lparser.c`, `lundump.c`, `lzio.c`). These are the foundational scripting core but are documented in the lua-scripting doc; see Cross-references.

(Note: `PalSound*` / `PalEngine::BankUpdate` and the `Pangea\Src\PgSound*` / `PgMusic*` paths are audio and are covered by audio-pal; only the generic Pal container/allocator sources are claimed here.)

## Key classes

The recovered RTTI list (`mercs2_xenon_p.rtti_classes.txt`, 324 names) contains **no `Pg*` or `Mrx*` class names** — every demangleable RTTI type is Havok (`hk*`, `hkp*`, `hka*`) or a Havok inner type. So there are no demangled C++ class records to cite for this system. The `Pg*`/`Mrx*` symbols below come from debug/string evidence, not from `.?AV`/`.?AU` RTTI descriptors (absence verified by grepping the RTTI file for `Pg`/`Mrx` — zero hits).

## Symbols by area

### Game-system framework (`PgGameSystem.cpp` + `PgSys*`)

The per-frame engine-system registry. Each `PgSys<Name>` is a tickable system; the inventory and strings include (offsets from the inventory `.rdata` unless noted):

| Symbol | Offset | Section |
|---|---|---|
| `PgSysDelete` | 0x002001c | .rdata |
| `PgSysDisposer` | 0x002002c | .rdata |
| `PgSysEffectBinding` | 0x002006c | .rdata |
| `PgSysHumanStateMachine` | 0x00202f4 | .rdata |
| `PgSysPopulation` | 0x002080c | .rdata |
| `PgSysRumble` | 0x0020970 | .rdata |
| `PgSysTransformController` | 0x0020d68 | .rdata |
| `PgSysTurret` | 0x0020e28 | .rdata |
| `PgSysVehicle` | 0x0020e58 | .rdata |
| `PgSysRider` | 0x0021eb0 | .rdata |
| `PgSysAi` | 0x0024128 | .rdata |
| `PgSysChatter` | 0x001ff5c | .rdata |
| `PgSysMeleeCombat` | 0x001e234 | .rdata |
| `PgSysAlarm` | 0x0030d5c | .rdata |
| `PgSysCamera` | 0x0047a60 | .rdata |
| `PgWeaponSystem` | 0x00213bc | .rdata |

`PgGameSystem.cpp` itself is referenced at string line 2404 (`d:\projects\releaseline\mercs2\pangea\Src\PgGameSystem.cpp`). Additional `PgSys*` systems appear in the strings file but are not in the trimmed inventory (grep-confirmed at the cited string lines): `PgSysGrapplingHook`, `PgSysAnimation`, `PgSysQuality::Update`, `PgSysRender::{Update,RenderFrame,SubmitFrame,EndFrame}`, `PgSysContextAction`, and the networked-system cluster `PgSysNet*` (`PgSysNetworking`, `PgSysNetLayers`, `PgSysNetSmoothing`, `PgSysNetSupport`, `PgSysNetDangerousBuilding`, `PgSysNetDynamicTrees`, `PgSysNetInfinityObjects`, …). The `PgSysNet*` family belongs to the networking doc but is structurally the same framework.

### Per-frame run/update state + frame-loop

| Symbol | Offset | Section | Note |
|---|---|---|---|
| `PgUpdateState` | 0x001de90 | .rdata | also string line 2417 |
| `PgRunState` | 0x001e1c8 | .rdata | also string line 2471 |
| `PgScene::EndFrame` | 0x0014a9c | .rdata | frame boundary |
| `PgJunk::EndFrame` | 0x00307e0 | .rdata | frame boundary |
| `PgGui::BeginFrame` | 0x00308c0 | .rdata | frame boundary |
| `PgDecompressionManager::Update` | 0x0017fdc | .rdata | streaming tick |

Near `PgRunState` the strings expose `CurrentGameState`, `RunState`, and the framerate-mode tunable strings (see Notable strings), placing `PgRunState`/`PgUpdateState` at the top-level loop and its framerate policy.

### Model / object state machine and scripting events

| Symbol | Offset | Section |
|---|---|---|
| `PgModelStateMachine` | 0x001e350 | .rdata |
| `PgModelStateMachine::OnWakeup` | 0x001e30c | .rdata |
| `PgScriptEventManager` | 0x002d83c | .rdata |
| `MrxActionHijack` | 0x002d060 | .rdata |
| `PgMusicStateMachine` | 0x002e648 | .rdata |
| `PgLobbyGameState` | 0x002f64c | .rdata |
| `PgDamageEvent::Update` | 0x00241a0 | .rdata |

Around `PgModelStateMachine` the strings show the state-machine vocabulary: `MSM_Update`, `OnStateChange`, `CreateStateTransTable`, `SetStateOnTimer`, `OnWakeup`, and `ObjectScript`. `PgModelStateMachine` reads as the per-entity state machine, with `PgScriptEventManager` dispatching script-side events into it. `MrxActionHijack` is the only `Mrx*` (runtime/game-layer) symbol in the inventory.

### Asset-type registries / manager singletons (`.data`)

These are global instances in `.data` (the in-engine asset-type registries / DBs). From the inventory:

| Symbol | Offset | Section |
|---|---|---|
| `PgConfig` | 0x0b8a3d8 | .data |
| `PgInterfaceFont` | 0x0b8a3e4 | .data |
| `PgHumanStateTable` | 0x0b8a400 | .data |
| `PgLayerDb` | 0x0b8a414 | .data |
| `PgModel` | 0x0b8a430 | .data |
| `PgPath` | 0x0b8a438 | .data |
| `PgScript` | 0x0b8a440 | .data |
| `PgTemplateDb` | 0x0b8a44c | .data |
| `PgFaceFxActorAsset` | 0x0b8a4b0 | .data |
| `PgScrub` | 0x0b8a4f8 | .data |
| `PgScaleform` | 0x0b8a500 | .data |
| `PgFoliage` | 0x0b8a518 | .data |
| `PgBlock` | 0x0b8a524 | .data |

The full asset-type name table is contiguous in the strings (lines 51093–51114): `PgAnimationTable`, `PgAnimationSequenceTable`, `PgAnimationTransitionTable`, `PgConfig`, `PgInterfaceFont`, `PgHavokData`, `PgHumanStateTable`, `PgLayerDb`, `PgLineRegion`, `PgModel`, `PgPath`, `PgScript`, `PgTemplateDb`, `PgTerrainMesh`, `PgLowResTerrain`, `PgMaterialTable`, `PgDecalTable`, `PgMaterialKeyAsset`, `PgFaceFxActorAsset`, `PgFaceFxAnimationSetAsset`, `PgAnimation`, `PgTexture`. This is the registry of loadable asset classes keyed by name (inferred), matching the WAD model/tag types documented elsewhere in the project.

### Supporting low-level libraries (`Pimp*` jobs/timers, `Pal*` containers)

`Pimp*` = a multi-CPU job / timer / queue library (`PimpMemory.cpp`, `pimp_job.h`, `pimp_queue_a64.h`, `pimp_timer.h`, plus `.\src\CPU\pimp_thread.c`, `pimp_cpu.c`, `pimp_timer.c` seen only in assert strings). `Pal*` provides generic engine utilities reused outside audio: `PalInstanceAllocator`, `PalLookupTable`, `PalGlobalTable` (e.g. `PalGlobalTable::FindCue` at string 15019), and the `PalQueue.h` template. The job library is the threading foundation — see the jobs-threading doc.

`MtAccessChecking` (inventory 0x00581c8) appears in a Havok multithread context (strings around 8886, alongside `MT_ACCESS_CHECKING_ENABLED`/`hkpThreadToken`); it is a Havok multithread tunable, not Pangea-core. Listed for completeness only.

## Notable strings

Memory/heap layout debug report (strings ~2391–2402) — the engine's heap partitioning:
```
 Physical memory:      %10d
 +--code/BSS/data:     %10d
 +--Available memory:  %10d
    +--Main heap:      %10d (b:%d a:%d)
    |  +--Small Block: %10d
    |  +--Regular:     %10d
    +--Script heap:    %10d (b:%d a:%d)
    +--Network heap:   %10d (b:%d a:%d)
    +--Sound heap:     %10d (b:%d a:%d)
    +--Device heap:    %10d
    +--System heap:    %10d
    +--Not used:       %10d
```
Heap/usage category labels nearby: `Buffer`, `Texture`, `DeviceHeap`, `Network`, `Script` (strings 2405–2409); config files `d:\local.ini`, `d:\first.ini`, `code_version.ini`, `CdbSizes.ini`, `multiplayer.ini` (strings 2410–2470).

Frame-rate policy tunables (strings 2783–2801), the run-loop's framerate modes:
```
Variable Framerate / Hybrid Framerate / Adaptive Framerate
Loose Hybrid 30 / Loose Adaptive / Strict Adaptive
Fixed 30 / Fixed 20 / Basic VSYNC
PAUSED / WaitForFrame
variable framerate: %.1f fps (%.1f low)
adaptive framerate: %.0f -> %.0f fps
hybrid framerate: %.0f -> %.0f fps
```

`Pimp*` assert format and messages (strings 51614–51705) — the only assert family clearly in this layer:
```
PIMP ASSERT FAILED - %s(%d): 
pimpQueue full
Too many params for this job
Timers not setup for CPU %d
Must call TimerEndFrame from primary thread
Cpu flush job not init
can't use pimpCriticalSections for non-pimp threads
leaving critical section owned by thread %d from thread %d
Too many Jobtypes
can't call init custom after pimpInit
```

Model state-machine vocabulary (strings ~2479–2487): `MSM_Update`, `OnStateChange`, `CreateStateTransTable`, `SetStateOnTimer`, `ObjectScript`, `OnWakeup`.

`PgSysPopulation` cache verbs (strings 2824–2833): `CacheOut`, `CacheIn`, `CacheRequired`, `CacheOutLump`, `CacheInLump`, `DeathCompute`, `DeathCheck` (population streaming).

## Cross-references

- `docs/mercs2-pdb-analysis/jobs-threading.md` — the `Pimp*` job/timer/queue library and `Mt*` worker dispatch.
- `docs/mercs2-pdb-analysis/world-streaming.md` — `PgDecompressionManager`, `Create/ReleaseAsset`, the `Read*` block readers, and `PgSysPopulation` cache in/out.
- `docs/mercs2-pdb-analysis/game-systems.md` — gameplay-content `PgSys*` systems registered on this framework.
- `docs/mercs2-pdb-analysis/lua-scripting.md` — the Lua 5.1.2 VM core and `PgScript`/`PgScriptEventManager`.
- `docs/mercs2-pdb-analysis/audio-pal.md` — `Pal*` sound engine (this doc claims only the generic Pal container/allocator utilities).
- `docs/mercs2-pdb-analysis/havok-physics.md` — all `hk*`/`hkp*` RTTI classes and `MtAccessChecking`.
- `docs/mercs2-pdb-analysis/networking.md` — the `PgSysNet*` system family.
- Existing project docs that overlap: `docs/comprehensive_engine_understanding.md`, `docs/engine_load_path_map.md`, `docs/mercs2-ecs/` (native ECS/component registry — complements the `PgSys*`/asset-registry view here).

## PC decompilation cross-reference

These map this system's Xbox symbols to functions in the PC retail decompilation (`output/_ghidra/all_functions_decomp.txt`). The resolver found **no vtable-resolved classes** for this system (the recovered RTTI is all Havok, so there are no `Pg*` constructors to anchor) and produced only string-anchored matches. Crucially, every string-anchored hit here is a `Pg*FP`/`Pg*VP`/`.sho` **shader-program name**, and almost all of them collapse to a single function — `FUN_0084f130`. That is the expected "registry/loader references many of a system's strings" pattern: `FUN_0084f130` is not a per-shader method, it is the engine's shader-program **registry/loader** that registers ~480 shaders by name. These strings belong to the rendering-shaders layer, not the foundation/glue this doc covers; they resolve here only because the trimmed inventory carried the `Pg*` shader names.

| Symbol / class | PC function | Bridge | Role |
|---|---|---|---|
| ~480 `Pg*FP` / `Pg*VP` / `*.sho` shader names | `FUN_0084f130` | string | shader-program registry/loader (high confidence as a loader; low confidence per-name) |
| `PgWater*` / `PgUnderwaterFP` shader names | `FUN_00484380` | string | water-shader sub-loader, tail-called by `FUN_0084f130` |
| `PgMeshVPNoColor` / `PgMeshVPNoTangentNoColor` / `PgDiffSpecNorm*` (as defaults) | `FUN_004a8f30` | string | fourcc block/asset parser (references a couple of mesh-VP names as fallback shaders; not a shader loader) |

Confidence: the *loader role* of `FUN_0084f130`/`FUN_00484380` is high (the bodies are unmistakable). The *individual symbol-to-function* mapping is low — a shader name appearing in a 480-call registry tells you only that the registry knows that shader, not that the function "is" that shader.

### `FUN_0084f130` — the shader-program registry/loader (string bridge)

The body is a flat sequence of ~480 registration calls, each binding a shader name to its compiled `.sho` file, with config bits (`DAT_01176288 + 0x5e4`) selecting platform/quality variants:

```c
FUN_0085ac90(s_PgBlurHFP_00be34ac, s_PgBlurHFP_sho_00be349c, 0);
FUN_0085ac90(s_PgMeshVP_00be3510, s_PgMeshVP_sho_00be3500, 0);
...
if ((*(uint *)(DAT_01176288 + 0x5e4) >> 2 & 1) == 0) {
    pcVar3 = s_PgMeshVP_sho_00be3500;          // no ambient-wind variant
} else {
    pcVar3 = s_PgMeshVPAmbientWind_sho_00be371c; // ambient-wind variant
}
FUN_0085ac90(s_PgMeshAmbientWindVP_00be3734, pcVar3, 0);
```

The first argument is the in-engine shader *name* (`PgMeshVP`), the second is the compiled-shader *file* (`PgMeshVP.sho`). This is exactly the string evidence the Xbox build exposed as the `Pg*VP`/`Pg*FP`/`.sho` symbol pairs.

### `FUN_0085ac90` — the per-shader register/init helper

Each registration call lands here. It hashes the name, copies the name string inline into a freshly built shader-program record, stores the `.sho` filename and flag, then dispatches a virtual load:

```c
iVar2 = FUN_00824270();          // name -> hash
param_1[1] = iVar2;
param_1[0x23] = param_4;          // flag
do { ... } while (cVar1 != '\0'); // inline-copy name into object (+0xb)
(**(code **)(*param_1 + 8))((int)param_1 + 0xb, 0); // vtable: load by name
```

This confirms the registry interpretation: the engine keeps name-keyed shader-program records, which matches the asset-type-registry-by-name pattern described above for the `.data` `Pg*` singletons.

### `FUN_00484380` — water-shader sub-loader (string bridge)

Tail-called by `FUN_0084f130` (caller list includes `0x008522ca` inside `FUN_0084f130`). Same `FUN_0085ac90(name, .sho, 0)` registration pattern, but specialized to the `PgWater*`/`PgUnderwater*` family, branching on render-path config bits to register `_R2VB` / `_NVT` variants. `PgUnderwaterFP`/`PgUnderwaterFP.sho` resolved directly to this function (its only distinctive owner) — that pair is the one genuinely specific string match in the set.

## Evidence & confidence

- The trimmed inventory `pangea-engine-core.txt` has 564 lines, but the overwhelming majority are GPU shader program names (`Pg*FP`/`Pg*VP`/`.sho`, e.g. `PgDiffSpec*`, `PgSkin*VP`, `PgScaleform*`) that belong to the rendering-shaders doc and are **excluded** here. This doc cites ~50 genuinely core foundation/glue symbols.
- Distinct symbols/strings cited from evidence files: **~50** (the `PgSys*` framework, `PgUpdateState`/`PgRunState`, `PgModelStateMachine*`, `PgScriptEventManager`, `MrxActionHijack`, the `.data` asset-registry singletons, the heap-report and framerate-mode tunables, and the `Pimp*`/`Pal*` sources/asserts).
- Symbols/strings I re-verified by grep against the strings/source-path/RTTI files before writing: **~40+** (every `PgSys*`, `PgUpdateState`, `PgRunState`, `PgModelStateMachine`, `PgScriptEventManager`, `PgDecompressionManager`, `PgLobbyGameState`, `PgMusicStateMachine`, `PgGui::BeginFrame`, `PgScene::EndFrame`, `PgJunk::EndFrame`, `MrxActionHijack`, `MtAccessChecking`, the heap/framerate strings, the `Pimp*` assert block, all 10 claimed source paths, and the asset-registry name table).

Every `Pg*`/`Mrx*`/`Pal*`/`Pimp*` symbol, source path, offset, and quoted string above literally exists at the cited offset/line in the evidence files.

The architecture/behavior claims are interpretation: that `PgSys*` are tickable systems registered with a `PgGameSystem` manager; that `PgUpdateState`/`PgRunState` gate the main loop and its framerate policy; that the `.data` `Pg*` singletons are asset-type registries; that `PgModelStateMachine` is the per-entity state machine driven by `PgScriptEventManager`. No `Pg*`/`Mrx*` RTTI class descriptors exist to confirm class layout — these names are debug-string/source-path evidence only. Where the symbol name alone does not establish behavior, the doc says so rather than speculating.

## How it works (decompiled)

Source: the Xbox 360 Profile-build decompilation `output/_ghidra_x360/xenon_decomp_named.c` (image base `0x82000000`). The `PgSys*` constructors *are* named in this build, and their bodies confirm the system-registry architecture the doc inferred from names alone.

### The `PgSys*` registry is a 32-bit slot bitmask + parallel name table
`PgSysVehicle @82373600` is the clearest example. It claims a free slot from a 32-bit global allocation bitmask, writes its own name string into a parallel name array, and returns the slot index:

```c
void PgSysVehicle(int param_1) {                       // @82373600
  uVar3 = 1; uVar2 = 0;
  do {
    if ((DAT_830f982c & uVar3) == 0) {                  // global system-slot bitmask
      DAT_830f982c = DAT_830f982c | uVar3;              // claim this bit
      uVar3 = ~uVar2;                                    // slot index (bitwise-NOT encoded)
      *(char **)(&DAT_830f98b0 + uVar2 * 4) = "PgSysVehicle";  // parallel name table
      goto LAB_82373654;
    }
    uVar2 = uVar2 + 1; uVar3 = uVar3 << 1;
  } while ((int)uVar2 < 0x20);                            // up to 32 systems
  ...
  *(uint *)(param_1 + 0x10) = uVar3;                      // store slot id into this system object
  uVar1 = FUN_8246cf08(0xffffffff830ff930,0xffffffff82020e58); // register 3 callbacks into named managers
  ...
}
```

`PgSysNetworking @82593618` repeats the identical pattern against a *different* 32-slot bitmask (`DAT_8318a8a4`, name table `&DAT_8318a928`, name string `"PgSysNetworking"`), confirming each subsystem family owns its own 32-entry registry rather than one global table. `0x20` (=32) is the hard cap per registry — matching the Pimp "Too many Jobtypes"/bounded-registry pattern documented in jobs-threading. (Verified: both bodies present at the cited VAs; `"PgSysVehicle"`/`"PgSysNetworking"` are inline literals.)

### Callback/listener registration: two fixed-capacity slot allocators
The `FUN_8246cf08` and `FUN_822073b8` calls peppered through every `PgSys*` ctor are **listener-slot registrars**, not asset-DB lookups. They take a manager pointer + an identity pointer (an `.rdata` name string) and drop the identity into the first free slot of a small fixed array:

```c
uint FUN_8246cf08(int param_1,undefined4 param_2) {     // @8246cf08 — 8-slot (byte bitmask)
  bVar1 = 1; uVar2 = 0;
  do {
    if ((bVar1 & *(byte *)(param_1 + 4)) == 0) {          // bitmask at manager+4
      *(byte *)(param_1 + 4) = bVar1 | *(byte *)(param_1 + 4);
      *(undefined4 *)((uVar2 + 10) * 4 + param_1) = param_2;  // store at +0x28 + slot*4
      return ~uVar2;
    }
    uVar2 = uVar2 + 1; bVar1 = bVar1 << 1;
  } while ((int)uVar2 < 8);                                // 8 slots
  return 0;
}
```

`FUN_822073b8 @822073b8` is the same shape with a **ushort** bitmask (16 slots, payload stored at `(slot+0x12)*4`). So managers expose either an 8-entry or 16-entry observer array, bitmask-tracked at `+4`. This is the real mechanism behind "each `PgSys<Name>` is registered with the manager."

### Per-frame update-list registration (`PgSysPopulation`)
`PgSysPopulation @823641f0` shows the *frame-tick* side: it caches two callback handles, then appends its update function `FUN_82364058` to a global update-fn list, bounded by a count/cap pair:

```c
void PgSysPopulation(void) {                            // @823641f0
  if (DAT_83793dd0 == 0) DAT_83793dd0 = FUN_822073b8(0xffffffff83109cb0,0xffffffff8202080c); // 16-slot
  if (DAT_83793dd4 == 0) DAT_83793dd4 = FUN_822ed8c0(0xffffffff830f9828,0xffffffff8202080c);
  cVar1 = FUN_8235dd88(0xffffffff82364058);              // already registered?
  if ((cVar1 == '\0') && (DAT_82c2160c < DAT_82c21610)) { // count < cap
    (&DAT_82c215c8)[DAT_82c2160c] = FUN_82364058;         // append update fn
    DAT_82c2160c = DAT_82c2160c + 1;
  }
}
```

The `0x8202080c` second argument is the `.rdata` `"PgSysPopulation"` name pointer reused as the manager key — confirming the name string doubles as the registration key, exactly as the asset-registry-by-name interpretation claimed.

### Per-entity object/state-machine wiring (`ObjectStateUpdate`, `PgModelStateMachine`)
`ObjectStateUpdate @8231ce10` installs a vtable and **prepends itself to a linked update list** hung off an engine object at `+0x74`, then builds the state-transition table:

```c
void ObjectStateUpdate(void) {                          // @8231ce10
  if ((DAT_836dba20 & 1) == 0) { ... DAT_836dba18 = &PTR_FUN_8201e2e0; ... }  // one-shot init + vtable
  iVar2 = FUN_824d01f0();
  DAT_836dba1c = *(undefined4 *)(iVar2 + 0x74);           // save old list head
  *(undefined ****)(iVar2 + 0x74) = &DAT_836dba18;        // become the new head
  CreateStateTransTable();                                 // @823163d8 (named) — build transition table
  ...
  iVar2 = FUN_8290bc68(uVar1,0xffffffff83cb28f4,0x100);    // register a named perf zone (hash table, 256 buckets)
  *(ulonglong *)(&DAT_83cb20f4 + iVar2 * 8) = CONCAT44(0xff800080,uStack_1c); // zone color
  DAT_83cb20e8 = DAT_83cb20e8 + 1;
}
```

`CreateStateTransTable @823163d8` is independently named, confirming the `CreateStateTransTable`/`OnStateChange`/`SetStateOnTimer` state-machine vocabulary the doc lists from strings is backed by real functions. The trailing `FUN_8290bc68(... ,0x83cb28f4,0x100)` block is a **named profiler-zone registrar** — an open-addressing hash insert into a 256-bucket table with a packed RGBA color and a running count `DAT_83cb20e8`; the same block appears in `SyncCPUGPU @824c5f60`. This is the engine's PIX/named-timer zone system, shared across systems.

### Device-heap operations are real and match the inventory offsets
`PimpDeviceHeap__Defrag @82905c00` calls a get/put pair (`FUN_8290ba80`/`FUN_82902f90`) against exactly the three `.rdata` name pointers `0x820c585c` (`PimpAllocFromDeviceHeap`), `0x820c5844` (`PimpFreeToDeviceHeap`), `0x820c582c` (`PimpDeviceHeap::Defrag`) — the same three offsets the jobs-threading inventory lists, confirming those names are co-located device-heap operations.

## Corrections & open questions

- **Confirmed (was "inferred"): `PgSys*` are slot-registered systems.** The doc said "no RTTI class layout confirms it." The decomp now confirms the registry is a **32-bit-per-family allocation bitmask + parallel name-string table** (`PgSysVehicle @82373600`, `PgSysNetworking @82593618`), capped at 32 systems per family. Promote this from inference to code-backed fact.
- **Confirmed: the name string is the registration key.** Every `PgSys*` ctor passes its `.rdata` name pointer (e.g. `0x82020e58` for "PgSysVehicle", `0x8202080c` for "PgSysPopulation") as the manager-registration argument — backing the "asset/system registry keyed by name" claim with code.
- **Corrected nuance: `FUN_8246cf08`/`FUN_822073b8` are listener-slot allocators, not asset-DB queries.** They are fixed-capacity (8 and 16 slot) bitmask allocators that store a callback identity, not name→asset lookups. The doc's general "system-registry / per-frame Update dispatch" framing is right, but the specific helpers do *registration into bounded observer arrays*.
- **`CreateStateTransTable` is real (`@823163d8`).** The model-state-machine vocabulary the doc lists from strings (`CreateStateTransTable`, `OnStateChange`, `SetStateOnTimer`) is backed by at least this named function; `ObjectStateUpdate @8231ce10` calls it during per-entity init.
- **Not supported by the decomp: the heap-report and framerate-mode behavior.** The heap-partition printout and the `Variable/Hybrid/Adaptive Framerate` mode strings are real in the strings table but are **not inlined** in `xenon_decomp_named.c`, so the run-loop/framerate-policy state machine (`PgRunState`/`PgUpdateState`) **cannot be code-grounded in this build** — those remain string-only.
- **Open question: the `PgGameSystem` master tick.** I located the per-system *registration* (ctors) and one update-list append (`PgSysPopulation`), but not a single master `PgGameSystem::Update` that iterates the 32-slot tables in order. It is likely among the `FUN_829167xx`-stubbed or unnamed functions; its dispatch order is undetermined here.
- **Decomp gap caveat:** many small engine helpers (`FUN_829167e0`..`ec`, and several `thunk_FUN_*`) decompile to empty `return;` stubs in this build — Ghidra did not recover them. No behavioral claim is made about those.
