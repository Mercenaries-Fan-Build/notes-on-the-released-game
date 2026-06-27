# Mercenaries 2 — Ghidra Knowledge Inventory

A location-keyed inventory of **everything reverse-engineered in [`output/_ghidra/`](../output/_ghidra/)**:
what is documented where (file + line), every identified function, how on-disk WAD
values map into the running exe, and — from the **live x32dbg session** — the exe's
memory map and the parts that are still unmapped / unidentified.

`Mercenaries2.exe`, x86 32-bit PC retail. Ghidra image base `0x00400000`. Live process
image span `0x00400000–0x03702000` (size `0x3302000`, matches the loaded module).

Companion docs: [`engine_load_path_map.md`](engine_load_path_map.md) (named load-path index),
[`comprehensive_engine_understanding.md`](comprehensive_engine_understanding.md),
[`ghidra_annotation_guide.md`](ghidra_annotation_guide.md),
[`scripts/mercs2_annotations.json`](../scripts/mercs2_annotations.json).

---

## Part A — Corpus file inventory (what's in each `output/_ghidra/` file)

Line counts are exact. "Anchors" are the line numbers where the key function/section starts.

### A.1 Top-level reference dumps

| File | Lines | Contents | Key anchors |
|---|---|---|---|
| `all_functions_decomp.txt` | 1,275,819 | **Whole-binary decompilation** — every Ghidra function. Grep, never read whole. | `FUN_004fd9f0` road graph @L128697; `Pool_BestFit` @L635513; `Hash_Probe` @L605768; `Pool_FreeListPop` @L635816 |
| `Mercenaries2_exe_findings.txt` | 381 | **String → referencing-function map** (62 distinct fns) + the memory-block table. | Mem blocks @L5; string hits @L22; "Distinct referencing functions: 62" @L381 |
| `proj/` (`mercs2.gpr`, `mercs2.rep/`) | — | The Ghidra project DB itself (idata/versioned/user). | — |
| `proj_prepatch/` | — | Pre-patch Ghidra project snapshot. | — |
| `sim_*.json` / `sim_*.log` | ~2.7 MB ea | WAD-simulator captures (not exe knowledge): `sim_base/schema/fix_base/fix_patch.json`, `sim_vzpatch*.log`, `sim_sgesfix.log`. | — |
| `headless_*.log`, `process_*.log`, `*_headless.log`, `*_run.log` | — | Ghidra headless-run logs (provenance only, no knowledge). | — |

### A.2 Allocator / pool dumps

| File | Lines | Contents | Key anchors (line) |
|---|---|---|---|
| `free_decomp.txt` | 10,347 | 51 allocator-CS functions, full bodies. | `Pool_AllocFast` FUN_0084ac20 @L1212; `Pool_FreeListPop` FUN_0084dce0 @L10005; `FUN_0084dc40` size-class @L10114; `Shader_StreamLoad` FUN_0085b3f0 @L616; `PostFX_ChainBuild` FUN_0046b590 @L738; `ECS_PlacementParse` FUN_004cf340 @L2825; `TexCluster_Load` FUN_00470f90 @L7494; `MeshDecl_Read` FUN_004a0c40 @L6916; growable-array `FUN_006323e0` @L6414 |
| `alloc_callers_decomp.txt` | 244 | 3 allocator-caller bodies (pool-overflow suspects). | entries @L4, L81, L108 |
| `heap_crash_decomp.txt` | 184 | `0x84DD5B` free-list-pop crash (`FUN_0084dce0`). | @L4, L77, L121 |
| `table_crash_decomp.txt` | 137 | `0x4CC064` null-slot pool-pop. | @L4, L62, L96 |
| `gridcrash_decomp.txt` | 148 | grid pool pop crash detail. | @L3, L43, L72, L113 |
| `overflower_decomp.txt` | 19 | 4 "512-byte pool overflow suspect" target addresses. | @L4–L16 |

### A.3 Grid / spatial pool

| File | Lines | Contents | Key anchors |
|---|---|---|---|
| `grid_release.txt` | 412 | Grid **vtable @0x00bb1090** full slot map + referrers. | vtable @L1; `FUN_004cbef0` GridPool_Init @L55; `FUN_004c13a0` @L83; `FUN_004bef00` block bootstrap @L147 |
| `grid_xrefs.txt` | 528 | All xrefs to the grid globals (`0x016ce8c4` capacity etc.). | — |

### A.4 Texture pool

| File | Lines | Contents | Key anchors |
|---|---|---|---|
| `texbuf_overflow.txt` | 836 | Texture-slot overflow path; 7 fns. | `FUN_004cf340` @L2; `FUN_0085bed0` decl-copy @L288; `FUN_0046fe50` tex-comp builder @L373; load-pump `FUN_004c09c0` @L474; `FUN_00630ef0` scene tick @L604; step-dispatch `FUN_00631670` @L669 |
| `texcomp_producer.txt` | 4,824 | Texture-component producer/consumer chain. | — |

### A.5 World-load / chunk-parse / streaming

| File | Lines | Contents | Key anchors |
|---|---|---|---|
| `ecs_node_loader.txt` | 29,199 | The ECS node loader (huge). | chunk dispatch + struct layouts (read in chunks) |
| `cf340_disasm.txt` | 314 | **Byte-level disasm of `FUN_004cf340`** (CHDR/placement parser). | FourCC `CHDR` cmp @L48; `NODE` @L51; `CEXE` @L53; `INFO` @L55; `STAT` @L217; `SWIT` @L219 |
| `worldload_crash_decomp.txt` | 748 | `0x4CF58B` null-inner-array world-load crash + load pump. | sections @L5, L265, L475, L632 |
| `chunkparser_decomp.txt` | 298 | `FUN_0067a7fa` MANM/INFO chunk parser. | @L4 |
| `chunkreader_decomp.txt` | 329 | Chunk-reader / stream cursor. | @L4, L28, L41 |
| `block_entry_reader.txt` | 146 | `FUN_00464780` block-entry reader (stride 0x14 entries). | — |
| `entry_offset_use.txt` | 7,482 | All uses of the block-entry offsets. | — |
| `loadstep_decomp.txt` | 802 | World-init load-step chain. | @L4, L91, L425, L554, L606 |
| `loadstep2_decomp.txt` | 228 | Load-step continuation. | @L4, L72, L149 |
| `scene_loader.txt` | 388 | Scene construct/destruct (`FUN_007c5970`/`FUN_007c5de0`). | — |
| `consumers_decomp.txt` | 485 | Per-chunk consumer functions. | @L4, L76, L206, L461 |
| `dispatch_4a0c40.txt` | 5 | Pointer note for `FUN_004a0c40` mesh/decl reader. | — |

### A.6 ECS component system

| File | Lines | Contents |
|---|---|---|
| `ecs_producer.txt` | 356 | ECS component producer. |
| `comp_container_add.txt` | 725 | Component-container add path (`FUN_007e0780` insert). |
| `comp_add_writer.txt` | 517 | Component writer. |
| `add_comp_callers.txt` | 127 | Callers of the component-add path. |

### A.7 Render / physics / crash

| File | Lines | Contents | Key anchors |
|---|---|---|---|
| `render_handle_decomp.txt` | 1,477 | Per-frame scene tick + handle resolution. | `FUN_004c14f0` @L26; `FUN_00630ef0` @L52; `FUN_004c0730` reinit-enum @L120; `thunk_FUN_024e84e0` @L276 |
| `render_handle_decomp2.txt` | 2,095 | More render-handle / Scaleform. | — |
| `gfx_crash_decomp.txt` | 235 | `0x7939C0` GFx UI loader null-chain crash + `FUN_007e03d0` ECS type-confusion. | @L4, L159, L192 |
| `crash_decomp.txt` | 182 | Spatial-hash insert family (`FUN_00516c00`/`b10`) — ruled-out/superseded. | @L5, L57, L163 |
| `around_414b0b.txt` | 152 | Raw disasm of the obfuscated `0x414A40–0x414BC0` overlay (PHY2/Havok name-lookup AV). | — |

---

## Part B — Function index (address → role → where documented)

Confidence: ✅ strong (owns a string cluster / decomp-verified), 🟡 structural inference.
"Doc" = corpus file the body lives in. See Part A for line anchors.

### B.1 Memory allocator & pools
| Address | Name / role | Conf | Doc |
|---|---|---|---|
| `0x0084d760` | `Pool_Alloc` — main alloc, arg2 = raw byte size | ✅ | all_functions L635816 |
| `0x0084d390` | `Pool_BestFit` — single shared free-region list | ✅ | all_functions L635513 |
| `0x0084dce0` | `Pool_FreeListPop` — O(1) bucket pop (0x84DD5B crash) | ✅ | free_decomp L10005; heap_crash |
| `0x0084ac20` | `Pool_AllocFast` — entry wrapper, takes lock `DAT_00ff4570` | ✅ | free_decomp L1212 |
| `0x0084acd0` | `Pool_Free` | ✅ | free_decomp |
| `0x0084dc40` | `Pool_SizeClassSelect` (0xffff→0) | ✅ | free_decomp L10114 |
| `0x00401860` | `Pool_PlacementNewN(base,stride,count,ctor)` | ✅ | grid_release |
| `0x008242b0` | `Hash_Probe(key)` — modulo + 8-way linear probe table | ✅ | all_functions L605768 |
| `0x00824270` | `Hash_String` — FNV (seed 0x811c9dc5, mul 0x1000193) | ✅ | all_functions |
| `DAT_00ff4570` | global allocator CriticalSection (one lock, all sizes) | ✅ | free_decomp |
| `DAT_017d50b0` | allocator object (stride 0xb per class selector) | ✅ | free_decomp |
| `DAT_00dfd108` | bucket descriptor base (stride 0x18) | ✅ | heap_crash |

### B.2 Grid / spatial & texture pools
| Address | Name / role | Conf | Doc |
|---|---|---|---|
| `0x004cbef0` | `GridPool_Init` — caps at 0x1400=5120 (3 immediates) | ✅ | grid_release L55 |
| `0x004cbf60` | `GridPool_BuildFreeList` — 0x400×5, stride 0x1a4 | ✅ | grid_release |
| `0x004cc030` | `GridPool_PopSlot` — null-slot → 0x4CC064 crash | ✅ | table_crash, gridcrash |
| `0x004cc0d0`/`0x004cc130` | `GridPool_Lookup*` — `Hash_Probe(0x1400)` modulus | ✅ | grid_release |
| `0x004b0ec0` | grid element ctor (vtable + 0xFFFF/0x1918 sentinels) | ✅ | table_crash |
| vtable `0x00bb1090` | grid object vtable | ✅ | grid_release L1 |
| `_DAT_016ce8c4` | grid capacity word (=0x1400) | ✅ | grid_xrefs |
| `0x0046fe50` | texture-component builder | ✅ | texbuf_overflow L373 |
| tex slot expr `(DAT_00ff464c*0x1400+idx)*0x40` | 5120 slots × 64B per bank | ✅ | texbuf_overflow |

### B.3 World-load / chunk parse / streaming
| Address | Name / role | Conf | Doc |
|---|---|---|---|
| `0x004c09c0` | `Loader_Frame` — load/active pump (`Sleep(100)` ~+0xce) | ✅ | texbuf_overflow L474; worldload_crash |
| `0x004c0ec0`→`0x004c9740` | `WorldBuild_*` chain | ✅ | worldload_crash |
| `0x004cf340` | `ECS_PlacementParse` — CHDR/NODE/INFO/STAT/SWIT/CEXE | ✅ | cf340_disasm; free_decomp L2825 |
| `0x00464780` | `Chunk_GetEntryReader` — block entries stride 0x14 | ✅ | block_entry_reader |
| `0x0067a7fa` | `Chunk_Deserialize` — MANM/INFO, per-node sprintf+FNV | ✅ | chunkparser |
| `0x00478120` | `PRMG_Build` — INFO→count, PRMG stride 0x1c4 | ✅ | all_functions |
| `0x004a0c40` | `MeshDecl_Read` — bulk u32 stream → vtx/index | ✅ | free_decomp L6916 |
| `0x0074d6d0` | `ValidateVertexElement` — 8B decl elems, 0xff term | ✅ | all_functions |
| `0x00858790` | `Mtrl_Parse` (`__stdcall`, ret 8) — 10-slot tex array | ✅ | all_functions L642101 |
| `0x004bef00` | `Block_TypeTableBootstrap` — ~40 vtable singletons via `Hash_Probe(0x100)` | ✅ | grid_release L147 |
| `0x00873140`/`0x008731f0` | `Node_StatusResolve` (status→4 transition) | 🟡 | consumers |
| `0x00631670` | step-dispatch table `DAT_019f904c` setup (8B slots) | ✅ | texbuf_overflow L669 |

### B.4 ECS runtime (entity / container / scene)
| Address | Name / role | Conf | Doc |
|---|---|---|---|
| `0x007c5970` / `0x007c5de0` | Scene ctor / dtor (vtable 0xbdf1c8) | 🟡 | scene_loader |
| `0x00790170` | Entity (de)structor (vtable 0xbdb410) | 🟡 | scene_loader |
| `0x007e0420` | `ECS_ContainerDispatch` — main per-node dispatch | ✅ | comp_container_add |
| `0x007e0780` | `ECS_ComponentInsert` — grows container | ✅ | comp_container_add |
| `0x007dfc40` | `ECS_FindComponentByType` — **binary search** | ✅ | all_functions |
| `0x007e0650` | `ECS_RenderIterate` (dup +0x84 vcall) | ✅ | all_functions |
| `0x007e03d0` | `ECS_ReverseDispatch` (+0x58 vcall — type-confusion site) | ✅ | gfx_crash |
| `0x0064ee60` | **Primary ECS component registry** (23,111 B — largest fn) | ✅ | all_functions |
| `0x0066f300` | **Secondary ECS component registry** (9,911 B) | ✅ | all_functions |
| `0x0064aa70` | bootstrap caller of `FUN_0064ee60` | ✅ | all_functions |

### B.5 Subsystems identified via string clusters (`Mercenaries2_exe_findings.txt`)
| Address | Subsystem / role | Conf |
|---|---|---|
| `0x0084f130` | **Shader registry / `.sho` loader** — owns ~120 `PgDiffSpecSSS*`/`PgRoad*` strings | ✅ |
| `0x0089e1f0` | Havok local-transform setup (`transformA/B`, `TYPE_SET_LOCAL_TRANSFORMS`) | ✅ |
| `0x008d7b80` | Havok broadphase setup (`Broadphase`, `broadPhaseBorder`) | ✅ |
| `0x008bfb60` | Havok shape dispatch (`HK_SHAPE_CONVEX_TRANSFORM`/`_TRANSFORM`) | ✅ |
| `0x008f3a55`/`0x0092cb25` | `LtBroadPhase` update (ST / MT) — has `rdtsc`+TLS monitor markers | ✅ |
| `0x0096ed60` | LAN/reservation config (`GameReservationTimeoutSecs`, `LanBroadcastPort`) | ✅ |
| `0x009a6e50` | GMLAN socket bind (`Cannot bind/open broadcast`) | ✅ |
| `0x009922c0`/`0x009962b0` | reliable broadcast / playgroup sync | ✅ |
| `0x0064ac50` | multi-prop descriptor (`HealthBucket*`, `Hibernation`, `Transform`, `DynamicRoadTypeEnum`) | ✅ |
| `0x006420d0`,`0x00644100`,`0x00647040`,`0x00643330`,`0x00643fa0` | road/AI component factories (PopulationDynamicRoad, RoadIntersection, Rt…, RedEffect, Massive) | ✅ |
| `0x00662860` / `0x02467440` | `UseWeaponTransform` / `PgHardpoints::FindTransforms` (latter in overlay) | ✅ |
| `0x00a4e842` | **HRESULT/error-code → string decoder** (WBEM/WSA/DPNERR/SCARD/OLE) | ✅ |
| `0x00a604f0` | secondary error-message decoder | ✅ |
| `0x0079cdc0`,`0x0079eae0`,`0x007b3a90`,`0x007b4360` | Scaleform (`hasScreenBroadcast`, `setTransform`, `colorTransform`) | ✅ |

### B.6 Per-frame runtime (road / physics)
| Address | Name / role | Conf | Doc |
|---|---|---|---|
| `0x004fd9f0` | `RoadGraph_Rebuild` — memset+gen-bump+per-element CS (L128753–55) | ✅ | all_functions L128697 |
| `0x024611a3` | `RoadHandle_Resolve` (`.securom` overlay) | ✅ | all_functions |
| `0x004fe660`/`0x004ff6a0` | `Road_SnapNearest` (O(N)) / `Road_RouteRequest` | ✅ | all_functions |
| `0x0040bbd0`→`0x0040b8b0`/`0x0040cbb0` | `PhysActor_HibernationTick` (3D sqr / 2D sqrt) | ✅ | all_functions |
| `0x008db880`/`0x008dba60` | `Havok_ClosestPoints` / `_Penetrations` | ✅ | all_functions |

### B.7 Render-submission (🔵 already optimal — leave alone)
| Address | Role |
|---|---|
| `0x00748e70` | `Dx9_SetRenderState` — **shadow-cached** |
| `0x00484280` | `Dx9_SetTexture` — shadow-cached |
| `0x00748ee0`/`0x00748f50` | `Dx9_SetSamplerState` / `SetTextureStageState` — shadow-cached |
| `0x007518b0` | `RenderList_Replay` — pre-recorded display-list interpreter |
| `0x00748d40` | `Dx9_SetVertexShaderConstantF` — the one uncached setter (behind SecuROM) |

> Optimization analysis (which of these are worth patching, with risk/verification)
> was produced alongside this inventory; the actionable shortlist: force the Havok
> monitor buffer-full guard always-false; drop the 32 KB memset in `Shader_StreamLoad`;
> gate `Sleep(100)`; precompute constant FNV hashes; `sqrt`→squared in `PhysActor_Sweep2D`.
> **Refuted:** per-size-class allocator locks (single shared free-list → corruption).
> **Needs cadence proof:** the `RoadGraph_Rebuild` dirty-flag.

---

## Part C — WAD → EXE value mapping

How bytes in the WAD asset stream are consumed by the exe. FourCCs are stored
little-endian on disk; the engine compares them as the `u32` immediates below.

### C.1 Chunk FourCC → parsing function
| FourCC (ASCII) | u32 immediate (LE) | Parsed by (exe addr) | Compare site |
|---|---|---|---|
| `CHDR` | `0x52444843` | `ECS_PlacementParse` 0x4cf340 | cf340 L48 (`0x4cf3bb`) |
| `NODE` | `0x45444f4e` | 0x4cf340 | cf340 L51 (`0x4cf3cd`) |
| `CEXE` | `0x45584543` | 0x4cf340 | cf340 L53 (`0x4cf3d9`) |
| `INFO` | `0x4f464e49` | 0x4cf340; `PRMG_Build` 0x478120; `Chunk_Deserialize` 0x67a7fa | cf340 L55 (`0x4cf3e1`) |
| `STAT` | `0x54415453` | 0x4cf340 | cf340 L217 (`0x4cf5cf`) |
| `SWIT` | `0x54495753` | 0x4cf340 | cf340 L219 (`0x4cf5d7`) |
| `PRMG` | `0x474d5250` | `PRMG_Build` 0x478120 | all_functions |
| `MANM` | `0x4d4e414d` | `Chunk_Deserialize` 0x67a7fa (spawns class `PTR_FUN_00bcdb70`) | chunkparser |
| `DHDR` | `0x52444844` | **not a handler** — only the `JA`/`JZ` sort boundary in cf340's binary-search dispatch | cf340 L48 |

### C.2 Chunk field → exe struct offset
| WAD field | On parse | In-memory target | Notes |
|---|---|---|---|
| block entry table | `Chunk_GetEntryReader` 0x464780 | block+0x10, count block+0x08 | entry stride **0x14**: `{+0 magic, +4 offset, +8 size, +0xc flag, +0x10 skip}` |
| stream cursor | reader object | `+0x10` cursor, `+0x14` carry, `+0x18` data base | 4-byte read advances +4; carry pattern `0xfffffffb<old` |
| `CHDR {key,count}` | 0x4cf340 | key `0x9da97065`→STAT+0x4, `0xdb41017d`→STAT+0xc | keys are **FNV hashes** of property names, not ASCII |
| `NODE {_,count}` | 0x4cf340 | alloc `count*0x14+4` (count prefix + records) | NODE/STAT record stride **0x14** |
| `PRMG` | 0x478120 | alloc `count*0x1c4+4` | PRMG record stride **0x1c4 (452B)** |
| `MTRL` material | `Mtrl_Parse` 0x858790 | 8× float4 @mat[0..7]; **u16 tex-count @mat+0xa2**; tex array @mat+0x144 | tex slot stride **0xc** = `{name-hash, 0xF011157A, handle}`; **fixed 10 slots** — count>10 (e.g. byte-swapped 0x80) overruns → 0x84DD5B corruption |
| `INFO` texture hdr | streaming chain (`FUN_00875b00`/`FUN_008273f0`) | mip count @INFO[6]; residency desc @INFO[26:32]==0 ⟺ resident | dest buffer = `page_count<<15` (32KB pages), `page_count=u24@page_rec+4` |
| vertex `decl` | `ValidateVertexElement` 0x74d6d0 | 8B elems `{u16 stream,u16 off,u8 type,method,usage,idx}`, `0xff` term | FLOAT16_2(0xf)→FLOAT2(1), FLOAT16_4(0x10)→FLOAT4(3); type table `&DAT_00b97630` stride 0xc |
| ECS component record | `TexCluster_Load`/`FUN_00470f90` | per-entity stride **0xb0 (176B)**; component-table entries 8B `{ptr,type}` | the type-confusion crash reads `entry[1]+0x58` vcall |

### C.3 Magic sentinel constants
| Constant | Meaning |
|---|---|
| `0xF011157A` | texture/shader resource-type sentinel (2nd word of `{name-hash, 0xF011157A}` lookup key). Bytes `7a 15 11 f0`. Also written as `-0xfeeea86` in the "cleared handle" compare. |
| `0xFFFF` | empty/unset u16 slot; decl-stream end; ASET base-texture "no body" marker |
| `0xABABABAB` | heap-debug uninit fill (mip overclaim detection) |
| FNV `seed 0x811c9dc5`, `mul 0x1000193`, final `(h^0x2a)*mul`, lowercase via `\|0x20` | property/class-name hashing — produces keys like `0x9da97065` |
| class-name FNV keys | `0x5B724250` MESH; `0xE6B81A54`; `0x140E8728` (`FUN_004cbc90`); `0x56471E89`+`0x9fe1234a` (Scaleform GRefCount/GImage pair) |

---

## Part D — Crash signatures (where root-caused, what bytes are bad)

Each maps a crash VA → faulting fn → bad data → corpus file. (See [`MEMORY.md`](../memory/MEMORY.md) for fix status.)

| Crash VA | Fault fn | Root cause (data) | Doc |
|---|---|---|---|
| `0x4CC064` | `GridPool_PopSlot` 0x4cc030 | null free-list slot — pool over-iterated / 5120 cap exceeded → wild vcall | table_crash, gridcrash |
| `0x4CF58B` | `ECS_PlacementParse` 0x4cf340 | `local_c` inner-array ptr null — CHDR key matches neither magic (**CHDR dual-layout**: placement `{u16,u16,u32}` swap applied to MESH `{hash,count}` half-swaps the hash) | worldload_crash, cf340 |
| `0x84DD5B` | `Pool_FreeListPop` 0x84dce0 | free-list head corrupt (`0xD28FA5B0`) — **MTRL u16 tex-count @106 scrambled** by blanket u32 swap → `Mtrl_Parse` overran 10-slot array into pool | heap_crash |
| `0x7939C0` | GFx loader 0x7938c0 | `this+0x188` sub-object zeroed → null callback vcall (`+0x10`→`+0x2c`) — scaleformgfx CFX blind-swap | gfx_crash |
| `0x7E0404` | `ECS_ReverseDispatch` 0x7e03d0 | component entry `[1]` points into adjacent component data → `[ptr+0x58]` wild vcall (texture-component type confusion) | gfx_crash |
| `0x414B4C` | obfuscated overlay `0x414A40+` | PHY2 Havok packfile u32-swapped → class-name strings scrambled → name lookup fails → AV; record stride 0x190, Mtrl_Parse'd per record | around_414b0b, overflower |
| `0x47AA5C` | `PRMG_Build` path | PRMG terrain record null handle (record+4=0) — vtable 0xBAB258 | (memory only; PRMG stride 0x1c4 @0x478120) |
| `0x4AB26B` | terrainmesh render | segment pointer off-by-4 (RESOLVED) | (memory) |
| `0x248BBxx` | spatial-hash thunk (JIT) | superseded/ruled-out; clean callers `FUN_00516c00`/`b10` | crash_decomp |

---

## Part E — Live memory map (x32dbg, process currently loaded)

Captured live this session. Module `mercenaries2.exe` base `0x400000`, size `0x3302000`,
entry `0xb04c2e`, 13 sections. **The Ghidra section map matches the live map exactly.**

### E.1 EXE PE sections — live protections
| Base | Size | Live protect | Section | Notes |
|---|---|---|---|---|
| `0x00400000` | `0x1000` | `-R-` IMG | PE header | |
| `0x00401000` | `0x704000` | `ER-` IMG | `.text` | main code (7.3 MB) |
| `0x00B05000` | `0xF1000` | **`-RW`** IMG | `.rdata` | mapped writable live (not RO) |
| `0x00BF6000` | `0xE04000` | `-RW` IMG | `.data` | globals/pools (`DAT_016xxxxx` grid caps live here) |
| `0x019FA000` | `0x1000` | `-RW` IMG | `extdata` | |
| `0x019FB000` | `0x1000` | `-RW` IMG | `.tls` | |
| `0x019FC000` | `0x4D000` | `-R-` IMG | `.rsrc` | |
| `0x01A49000` | `0x63B000` | **`ERW`** IMG | `Stext` | SecuROM-wrapped code (writable+exec) |
| `0x02084000` | `0x7000` | `ER-` IMG | `Sitext` | |
| `0x0208B000` | `0x5A000` | `ER-` IMG | `Srdata` | |
| `0x020E5000` | `0x2FE000` | **`ERW`** IMG | `Sdata` | |
| `0x023E3000` | `0x6000` | `-RW` IMG | `Sidata` | |
| `0x023E9000` | `0x1318000` | **`ERW`** IMG | `.securom` | **the `FUN_024xxxxx` overlay code lives here** (decrypts in place) |
| `0x03701000` | `0x1000` | `ERW` IMG | `reloaded` | ends at `0x3702000` = exact image end |

**No gaps inside the image.** Every page `0x400000–0x3702000` is committed IMG, contiguous.
This corrects the earlier guess that `0x024xxxxx` thunks were separate PRV — they are
**in-image** `.securom` (`ERW`), self-decrypting, which is exactly why an ASI can't
cleanly detour them: the bytes you'd patch may be re-decrypted/checksummed at runtime.

### E.2 Decrypted-thunk / generated-code scratch (PRV, executable, outside image)
56 small `ER-` PRV pages — the SecuROM-decrypted trampoline scratch (NOT `0x024xxxxx`):
- Cluster A: `0x06810000–0x06880000` (8 pages, 0x1000–0x2000 each)
- Cluster B: `0x075B0000–0x07760000` and `0x07D40000–0x07FA0000` (~46 pages, 0x1000–0x3000)
- Stray: `0x03D70000` `0x1000` `ERW` (just above the image)

These are where SecuROM stitches control flow at runtime. They're transient and
page-granular — treat as **unidentified generated code**, not stable targets.

### E.3 Game heaps / pools (PRV `-RW`, outside image)
- **`0x18040000` size `0x26226000` (~610 MB) `ERW` PRV** — the dominant arena (right after binkw32).
- **~24 × `0xFCF000` (15 MB) `-RW` PRV pool runs**: `0xEE60000`, `0xFE30000`, `0x10E00000`,
  `0x11DD0000`, `0x12DA0000`, `0x13D70000`, `0x14D40000`, `0x15D10000`, `0x16CE0000`,
  `0x3E270000`, `0x3F240000`, `0x42720000`, `0x436F0000`, `0x46960000`, `0x47930000`,
  `0x58AB0000`, `0x59A80000`, `0x5AA50000`, `0x5BA20000`, `0x5CAE0000`, `0x5DAB0000`,
  `0x5EA80000`, `0x5FD10000`, `0x60DE0000` — the fixed-size pool backing store.
- `Heap (ID 0)` `0x3EB0000` `0xFF000`; plus many 1–7 MB anon sub-pools; ~40 per-thread stacks.

### E.4 Game-owned / injected modules
| Module | Base | Role |
|---|---|---|
| `mercenaries2.exe` | `0x400000` | the game |
| `pmc_bb.dll` | `0x691B0000` | **our blackbox/instrumentation** (`.text` @0x691B1000 0x6000) |
| `windowed_mode.asi` | `0x691A0000` | windowed-mode ASI hook |
| `binkw32.dll` | `0x18000000` | Bink video (own BINKY/BINKP code segs) |
| `d3dx9_36.dll` | `0x69540000` | D3DX helper |
| `xinput1_3.dll` | `0x3E80000` | controller |

---

## Part F — What is still UNMAPPED / UNIDENTIFIED

The reverse-engineering is deep but narrow. Honest accounting of the gaps:

1. **~24,000 functions, ~250 named.** The Ghidra DB has the full `.text` decompiled
   (`all_functions_decomp.txt`), but only the load/alloc/ECS/physics/render/road
   functions in Part B are *identified*. The vast majority are unnamed `FUN_xxxxxxxx`.

2. **The `.securom` overlay (`0x023E9000–0x03701000`, in-image `ERW`).** Functions
   `FUN_024xxxxx` / `thunk_FUN_024xxxxx` (e.g. `RoadHandle_Resolve` 0x24611a3,
   `PgHardpoints::FindTransforms` 0x2467440) live here and **self-decrypt at runtime**.
   Ghidra sees post-decrypt bytes only partially; control flow is obfuscated
   (junk bytes, `PUSH addr; RET` trampolines, XOR-with-`[0245faf8]`). Not safely patchable.

3. **Generated-code scratch (`0x068xxxxx`, `0x075x–0x07Fxxxxx` PRV `ER-`).** 56 transient
   pages of SecuROM-stitched thunks — exist only at runtime, no static counterpart.

4. **Unattributed `.text` gaps.** Some real call targets sit in regions Ghidra didn't
   form into functions — e.g. the **sole caller of `RoadGraph_Rebuild` at `0x4b9ad7`**
   is in an anonymous gap, which is why the road-rebuild cadence is still unproven.
   Crash fault sites `0x4CC064`, `0x51812F`, `0x63DA1F`, `0x790F02` likewise have no
   enclosing Ghidra function (inlined / generated).

5. **Streaming texture-header parse** (`FUN_00875b00`/`FUN_008273f0`) and the
   **node status→4 transition** (`0x873140`/`0x8731f0`) are referenced but not fully
   decompiled in the corpus — the buffer-sizing math is from the memory engine-chain note.

6. **ECS component *producer*** of the bad component pointer (type-confusion root) is
   still TBD — we have the consumer (`0x7e03d0`) but not who writes the mislocated ptr.

### Suggested next captures (to shrink the unmapped set)
- Live-dump the decrypted `.securom` pages (`0x23E9000+`) while running, re-feed to Ghidra.
- Set a counter BP on `0x4fd9f0` to resolve the road-rebuild cadence (Part B.6 open question).
- Decompile `0x873140`/`0x8731f0`/`0x875b00` to close the streaming-buffer chain.
- Name the `0x064ee60`/`0x066f300` registries' per-field calls to enumerate the full
  ECS component schema (the `FUN_00593c60`/`FUN_00824270` registration helpers).

---

*Built from the `output/_ghidra/` corpus + a multi-agent extraction pass (allocator,
load path, per-frame runtime, render, crash RCA, format internals) and a live x32dbg
memory-map capture. Line anchors are exact; VA constants are decomp-verified; items
depending on runtime cadence or post-decrypt `.securom` bytes are flagged as open.*
