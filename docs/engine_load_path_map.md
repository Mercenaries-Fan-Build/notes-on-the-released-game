# Mercenaries 2 — Engine Asset-Load / Streaming / Chunk-Parse Function Map

Base-truth named-function index for the WAD/asset-load, chunk-parse, streaming and
allocator code path of `Mercenaries2.exe` (PC retail, image base `0x00400000`).
Scoped to the load/stream/parse/alloc path and its immediate neighbors
(63 functions named), **not** the full ~24k-function binary.

Machine-readable companion: [`scripts/mercs2_annotations.json`](../scripts/mercs2_annotations.json).

> **Schema note.** `scripts/ghidra_mercs2_annotate.py` consumes a *different* JSON
> shape (top-level `known_vas` / `string_database` / `lua_registrations` /
> `rtti_patterns`, produced by `ghidra_mercs2_preanalysis.py` from Mercs-1 source).
> The task here asked for a function-map schema (`"0x<ADDR>" -> {name, role,
> confidence, callers, callees}`), so the JSON follows **that** schema (plus
> `phase`/`evidence`), not annotate.py's. A thin adapter can emit
> `known_vas:[{va,name,type,comment}]` from it if Ghidra labeling is wanted.

## Overview — load pipeline phases

```
 [init]        Stream_InitPools (pimpQueue rings)  +  *_RegisterStreamJobs (job table)
                         │
 [load-driver] Loader_Frame ─► LoadingScreen_FrameLoop ─► Stream_Manager_Update
                         │                                        │
 [streaming]   Stream_SubmitJob ─► (pimpQueue ring) ─► Stream_WorkerThread
                         │                                        │  dispatch DAT_019f904c[type]
                         │                                        ▼
 [chunk-parse] Chunk_GetEntryReader ◄── Chunk_DeserializeCHDR / Chunk_DeserializeMANM
                         │                       (CHDR/NODE/CECE/INFO/STAT tree)
                         ▼
 [consumers]   Mesh_ConsumeChunk · VertStream_ConsumeSTRM · IndexBuf_ConsumeIBUF ·
               Renderable_ConsumeChunk(MTRL→Mtrl_Parse) · Tex_ConsumeChunk(INFO hdr) ·
               Descriptor_ConsumeATRB
                         │
 [allocator]   Chunk_Alloc ─► Pool_AllocFast / Pool_AllocSlow ;  SmallObj_PoolAlloc
                         │
 [scene/ecs]   Scene_Construct ─► Entity ─► CompContainer  (boundary into ECS)
```

### FourCC magics (stored little-endian; read as the reversed ASCII)
`CHDR`=0x52444843 · `NODE`=0x45444f4e · `CECE`=0x45584543 · `INFO`=0x4f464e49 ·
`STAT`=0x54415453 · `MANM`=0x4d4e414d · `STRM`=0x4d525453 · `IBUF`=0x46554249 ·
`BSHI`=0x49485342 · `BSHP`=0x50485342 · `PRMT`=0x544d5250 · `MTRL`=0x4c52544d ·
`AREA`=0x41455241 · `NAME`=0x454d414e · `ATRB`=0x42525441 · `data`=0x61746164 ·
`decl`=0x6c636564 · `info`=0x6f666e69

### Data anchors
| Symbol | Meaning |
|---|---|
| `DAT_019f9044` / `DAT_019f9048` | stream ring-table ptrs (small/mid pimpQueue) |
| `DAT_019f904c` | job-type dispatch table (handler fnptr, stride 8) |
| `DAT_019f9050` | job-type FourCC id table (parallel to 0x19f904c) |
| `DAT_00ff45e8/4618/4650` | the three `pimpQueue` rings (mutex + head/tail) |
| `DAT_00ff4570` | global alloc critical section |
| `DAT_017d50b0` | per-class pool-descriptor array base |
| `DAT_00dfd108` | fast-pool slab array base |

Confidence: **high** = body/string/magic directly proves it · **med** = strong
structural inference · **low** = role plausible, name provisional (`?`-grade).

---

## Phase: init / job registration
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x0084af70 | Stream_InitPools | Builds 3 mutex-guarded `pimpQueue` job rings (0x400/0x1000/0x10), wires ring ptrs DAT_019f9044/48 | ←0x03280006 · →0x84dce0,0x84d760,CreateMutexA |
| 0x0046a440 | Tex_RegisterStreamJobs | Installs 6 texture job-type handlers (LAB_0046a210..320) + FourCC ids into DAT_019f904c | →0x4a4470,0x484380,0x46a920 |
| 0x00489dd0 | Render_RegisterStreamJobs | Installs render-resource job handlers (alloc 0x84ac00, decoders 0x82c100/0x8780d0/…) | →0x84ac00,0x82c100,0x8780d0 |
| 0x00402e90 | Core_RegisterAllocJob | Registers base allocator job handler 0x4036b0 | →0x4036b0,0x84ac20 |

## Phase: load driver
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x004c0ec0 | Loader_Frame | Loader frame wrapper around the loading-screen loop | ←0x4c0b6a · →0x4c9740 |
| 0x004c9740 | LoadingScreen_FrameLoop | Per-frame world-load pump; drives Stream_Manager_Update when load-stage>2 | ←0x4c0ed6 · →0x872d30,0x8765c0 |

## Phase: streaming manager / worker
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x00876400 | **Stream_WorkerThread** | Worker loop: pops ring items, dispatches via DAT_019f904c[type], Interlocked completion, Sleep(0) idle | →DAT_019f904c[*],TryEnterCriticalSection |
| 0x004c00e0 | Stream_SubmitJob_Init | Registers a job handler then pushes an init item into the 0x400 pimpQueue ring | →0x8765c0 |
| 0x008739e0 | **Stream_Manager_Tick** | Completion/eviction gate: `(*(node+0x30))(lvl)==4`, node size @+0x4c, recycles finished nodes | ←0x872d54 · →0x874410,0x875a50 |
| 0x00872d30 | Stream_Manager_Update | Flush + tick + retry/promote; sets busy flag @+0x4c35c | ←0x4c9cbd,0x4bf9c0 · →0x8738f0,0x872e60,0x8739e0,0x873cf0 |
| 0x008738f0 | Stream_EvictCompleted | Frees finished nodes (body+header via 0x84acd0), dec resident bytes @+0x4c368 | ←0x872d3b · →0x875d80,0x84acd0 |
| 0x00873cf0 | Stream_RetryPromoteQueue | Ages pending nodes (attempt count @+0xd), QPC-timestamps, re-queues/completes | ←0x872d5a · →0x876330,0x876070,0x874ba0 |
| 0x00872e60 | Stream_ForceFlush | Blocking flush when backlog @+0x4c36c>0 | ←0x872d4e,0x872dc3 |
| 0x00875760 | Stream_Node_Submit | Node-submit entry: per-thread slot, builds node record, pushes producer ring | →0x873410 |
| 0x00873410 | Stream_Node_Produce | Pops node from ring @+0x3ffe8, inits via Stream_Node_Init | ←0x875892 · →0x8743c0,0x8759c0 |
| 0x008759c0 | **Stream_Node_Init** | Node producer: copies src descriptor → node (node[+0x5A]=src[+0xA]) | ←0x873456 |
| 0x008743c0 | Stream_Node_Unlink | List-splice helper (produce/evict) | ←0x87447d,0x873449 |
| 0x00874410 | Stream_Node_Recycle | Returns completed/cancelled node to free pool | ←0x873bac,0x873d93,0x873747,0x873873 · →0x8743c0 |
| 0x00875a50 | Stream_Node_Finalize | Finalize paired with Recycle at all completion sites | ←0x873bb7,0x873d9e,0x873752,0x87387e |
| 0x00873140 | Stream_Resource_Acquire | Locks a streamable handle (2× CS DAT_01174ffc), sets state @+0x14=4 | →0x874150,0x8731f0,0x874a30 |
| 0x008731f0 | Stream_Resource_LookupOrCreate | Handle-table lookup-or-create (hash 0x8242b0) | →0x8242b0,0x874a30 |

## Phase: chunk-parse / deserialize
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x004cf340 | **Chunk_DeserializeCHDR** | Generic chunk-tree deserializer (vtable 0xBB12B4); CHDR/NODE/CECE/INFO/STAT → nested {prop,count,array}; world-load 0x4CF58B AV site | →0x464780,0x84ac20,0x401860 |
| 0x0067a7fa | Chunk_DeserializeMANM | MANM/info tree deserializer; decompresses body (0x956d90), builds FNV-1a name→id table | →0x464780,0x84ac20,0x956d20,0x956d90,0x825dc0 |
| 0x00464780 | **Chunk_GetEntryReader** | GetChunkDataReader: bounds-check entry idx, return 0x14-stride reader @this+0x18 | (called by every consumer) · →0x825e40 |
| 0x00825dc0 | Chunk_ReadCString | Reads a NUL-terminated string from the chunk stream | →0x4fe43a |

## Phase: per-type consumer — mesh / vertex / index
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x00478120 | MeshLOD_ReadChunks | Mesh/LOD reader root feeding 0x478270 | →0x478270 |
| 0x00478270 | Mesh_ConsumeChunk | Dispatch STRM/IBUF/BSHI/BSHP/PRMT/AREA/INFO; allocs blendshape/prim/material arrays | ←0x47822c · →0x4a4770,0x4a48f0,0x84ac20 |
| 0x00479590 | MeshSkin_ReadChunks | Skinned-mesh reader root feeding 0x4796f0 | →0x4796f0 |
| 0x004796f0 | MeshSkin_ConsumeChunk | INFO(0x38)/IBUF/BSHI/BSHP/STRM/PRMT for skinned meshes | ←0x4796a4 · →0x4a4770,0x4a48f0,0x84ac20 |
| 0x004a4770 | VertStream_ConsumeSTRM | STRM: data(body)/decl(vertex decl)/info(stream desc) | ←(7 mesh consumers) · →0x752890,0x752b30,0x7524a0 |
| 0x004a48f0 | IndexBuf_ConsumeIBUF | IBUF: info(count)+data(memcpy index data, 16/32-bit aware) | ←(5 mesh consumers) · →0x751fd0,0x752170,0x751ee0 |
| 0x0074d6d0 | VertDecl_ValidateClamp | Vertex-declaration validator/clamp (seed) | — |
| 0x00752890 | VertStream_SetBody | Sets vertex-stream body ptr (STRM/data callee) | ←0x4a47.. |
| 0x00752b30 | VertDecl_Set | Installs decoded vertex decl (STRM/decl callee) | ←0x4a47.. |
| 0x00956d20 | Mesh_ComputePackedSize | Packed mesh-body size (submesh spans + 0x30 record + 0x20 hdr) | ←0x67a962 · →0x88f880 |
| 0x00956d90 | Mesh_RelocateBody | Mesh body serializer/relocator (magic 0xd5109142, 0x30-byte records, ptr fixups) | ←0x67a99f · →0x88f810,0x88f900 |
| 0x0088f880 | Mesh_AlignSize | Size-alignment helper for packed size | ←0x956d35 |

## Phase: per-type consumer — material
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x00858790 | **Mtrl_Parse** | MTRL parser: u16 tex-count @106 → 10-slot {hash,0xF011157A,0} array @+0xac; the 0x84DD5B AV source (converter u32-swap bug) | ←0x4a1727,0x4a1731,0x4a52a5,0x4a9006,0x4acb91 |
| 0x004a4c40 | Model_ConsumeChunks | Model/renderable consumer root (owns MTRL parse) | →0x4a5230 |
| 0x004a5230 | Renderable_ConsumeChunk | STRM/IBUF/MTRL(→0x858790)/INFO; sets fallback material vtable @+0x1c4 | ←0x4a4cf8 · →0x4a4770,0x4a48f0,0x858790 |
| 0x004a0c40 | Renderable_ConsumeChunk_Mtrl0 | Primary material consumer (2 sites into Mtrl_Parse) | →0x858790 |
| 0x004a8f30 | Renderable_ConsumeChunk_Mtrl2 | INFO+MTRL consumer | →0x858790 |
| 0x004ac8e0 | Renderable_ConsumeChunk_Mtrl3 | INFO+MTRL consumer | →0x858790 |
| 0x004a83d0 | Renderable_ConsumeChunks_VarB ? | Renderable reader root feeding 0x4a8690 | →0x4a8690 |
| 0x004a8690 | Renderable_ConsumeChunk_VarB ? | IBUF/STRM variant | ←0x4a84d9 · →0x4a4770,0x4a48f0 |
| 0x004a9da0 | Renderable_ConsumeChunk_VarC ? | IBUF/STRM/INFO variant | ←0x4a9ce6 · →0x4a4770,0x4a48f0,0x464780 |

## Phase: per-type consumer — texture / descriptor
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x00750a30 | **Tex_ConsumeChunk** | NAME + INFO(0x3c hdr: w/h/mip/format @+4..0x2e, surface-array size/flags) — the DXT mip-count parser | ←0x4b102f · →0x464780,0x825dc0 |
| 0x0046b590 | TexLoader_BuildResource ? | Large texture/resource builder; wires GPU resource into table | ←0x74dc32 · →0x84ac20 |
| 0x00466850 | Loader_TeardownResources ? | Loader/object teardown (frees pools, CS, handles) | ←0x46a7ec,0x46a88a · →0x84acd0 |
| 0x00492af0 | Descriptor_ConsumeATRB | ATRB consumer: reads ATRB then dispatches on 32-bit property-hash to setters | ←0x491c33 · →0x464780,0x493550,0x4934f0 |

## Phase: allocators / support
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x0084ac20 | **Chunk_Alloc** | Primary load allocator: fast(0x84dce0)→slow(0x84d760) under CS DAT_00ff4570 | (every consumer) · →0x84dce0,0x84d760 |
| 0x0084d760 | Pool_AllocSlow | Slow/large block fallback (__stdcall poolDesc,size,rounded) | ←0x84acaa,many · →0x84d7b0,0x54420c |
| 0x0084dce0 | Pool_AllocFast | Fast pool: size-class freelist pop from DAT_00dfd108 slabs + histogram | ←0x84ac85,many · →0x84dc40,0x84db30 |
| 0x0088cb70 | SmallObj_PoolAlloc | Small-object pool (<=0x2000 freelist @+0x38, else vtable +0xc) | ←0x41a308,many · →0x88ca10 |
| 0x0084acd0 | Chunk_Free | Counterpart free for Chunk_Alloc | (stream teardown) |
| 0x008242b0 | **HashTable_Probe** | Open-addressing hash lookup (8-way unrolled linear probe) | ←0x404566,0x874167,many |
| 0x00401860 | Array_InitStride | Zero/placement-init N elements of a stride (builds record arrays post-alloc) | (many consumers) |
| 0x008765c0 | Stream_BeginTimedScope ? | Profiling/checkpoint marker between load stages | ←0x4c9740,many |

## Phase: scene / ECS (boundary — not recursed)
| Addr | Name | Role | callers→ / callees→ |
|---|---|---|---|
| 0x007c5970 | Scene_Construct | World/scene container ctor (vtable 0xbdf1c8); allocs sub-managers, entity arrays | →0x7bef60,0x7bb1a0,0x7677f0 |
| 0x007c5de0 | Scene_Destruct | Scene container dtor; tears down entities + sub-managers | →0x7e0280,0x7caa20 |
| 0x00790170 | Entity_Destruct | Entity (de)structor (vtable 0xbdb410); unlinks component container | ←0x790143 · →0x7e0280 |
| 0x007e0280 | CompContainer_Destruct | **ECS boundary** — component-container dtor (entity+0x28/+0xA0) | ←0x7901d2,0x79378d,0x7c5e4d |
| 0x007e0420 | CompContainer_Iterate | **ECS boundary** — component iterator; wild-vcall site in world-load ECS crash | ←0x7919d0 |

---

## Cross-references to existing RCA notes
- `Mtrl_Parse` (0x858790) — the 0x84DD5B texture-handle corruption (MTRL u16 @106). See `worldload-0x84dd5b-texhandle-corruption.md`.
- `Chunk_DeserializeCHDR` (0x4cf340) — CHDR dual-layout / 0x4CF58B world-load AV. See `chdr-dual-layout-mesh-vs-placement.md`, `worldload_crash_decomp.txt`.
- `Tex_ConsumeChunk` (0x750a30) — texture INFO header (w/h/mip/format) feeding the DXT mip-count work. See `worldload-livelock-dxt1-buffer-too-small.md`.
- `Stream_WorkerThread` (0x876400) / `Stream_Manager_Tick` (0x8739e0) — the streaming livelock. See `streaming-livelock-invalid-parameter.md`, `worldload-livelock-is-ecs-layer-not-texture.md`.
- `CompContainer_*` (0x7e0280/0x7e0420) — ECS component type-confusion. See `ecs-texture-component-typeconfusion.md`.
