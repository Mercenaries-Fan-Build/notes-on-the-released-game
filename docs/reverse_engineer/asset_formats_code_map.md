# Asset containers & formats — Xbox↔PC code map

**Scope:** scoreboard row 11 (Assets / formats) — the on-disk container/asset pipeline and the
exact PC parser functions that consume each chunk, married to their Xbox 360 counterparts. This is
the row whose **PC parse path was already the most heavily recovered** of any subsystem
([`../engine_load_path_map.md`](../engine_load_path_map.md),
[`ghidra_knowledge_inventory.md`](ghidra_knowledge_inventory.md) Part C), so the value-add here is
**(a)** the Xbox↔PC marriage, **(b)** a single consolidated *format → PC fn → struct-offset*
reference, and **(c)** first-hand re-reads of the six core parser bodies to pin the offsets. Image
base `0x00400000` (PC retail, unpacked), Xbox base `0x82000000` (Jul-08 Profile devkit).

**Sources.** PC: the 27k-fn Ghidra decomp of the unpacked exe (read first-hand below — every parser
body was fetched from the corpus, not inferred), [`../engine_load_path_map.md`](../engine_load_path_map.md),
[`ghidra_knowledge_inventory.md`](ghidra_knowledge_inventory.md) Part B/C,
[`../comprehensive_engine_understanding.md`](../comprehensive_engine_understanding.md) §2,
[`../format_reference.md`](../format_reference.md), [`../ecs_components.md`](../ecs_components.md),
[`../exe_analysis_agent_b.md`](../exe_analysis_agent_b.md) §4. Xbox: the descriptor mechanism from
[`../mercs2-pdb-analysis/world-streaming.md`](../mercs2-pdb-analysis/world-streaming.md) §"How it
works" and the Havok field-binders from
[`../mercs2-pdb-analysis/animation-skeleton.md`](../mercs2-pdb-analysis/animation-skeleton.md)
§"PC decompilation cross-reference". Ground-truth format knowledge:
[`../../tools/wad_simulator/crates/mercs2_formats/`](../../tools/wad_simulator/crates/mercs2_formats/)
(the Rust parsers) and [`../../tools/ucfx_be_to_le.py`](../../tools/ucfx_be_to_le.py) /
`convert.rs` (the BE→PC converter encodes every chunk's layout). Companion memory:
[[chdr-dual-layout-mesh-vs-placement]], [[world-placements-no-model-hash]],
[[phy2-havok-chunk-not-u32]], [[fun-858790-mtrl-parse-stdcall]], [[worldload-0x84dd5b-texhandle-corruption]].

**Method / honesty model.** Same discipline as the sibling maps
([`population_spawner_code_map.md`](population_spawner_code_map.md),
[`world_streaming_code_map.md`](world_streaming_code_map.md)). Every PC address is decomp-verified;
each parser row states whether the body was **READ** first-hand this pass or **inferred**. The Xbox
side is mostly the shared **descriptor mechanism** (`&PTR_FUN_82030fa0` + seed `0x9e3779b9` +
`@0x829fXXXX` registrars) — the Xbox *parser* functions are almost never string-anchored (the
retail-equivalent Ghidra of the PPC build recovered ~41 string labels in 38k functions), so most
Xbox parser bodies are **unlocated by name** and the marriage is PC-anchored + confirmed by the
identical on-disk format both builds consume. Confidence: **H** = format+body proves it (magic /
offset / stride that can't coincide) · **M** = role+structure, one strong signal · **L/open** =
positional or confirm-live.

---

## 0. Result in one line

The PC asset-parse path is **fully in the clear and read first-hand**: the FFCS/sges/entry-table
container pipeline, the CHDR dispatcher (`0x654940`) and the placement CHDR-tree deserializer
(`0x4cf340`), the entry reader (`0x464780`), and the six per-type consumers (MTRL `0x858790`,
texture INFO `0x750a30`, vert-stream STRM `0x4a4770`, index IBUF `0x4a48f0`, mesh `0x478270`, MANM
`0x67a7fa`) are all pinned to their exact on-disk layouts. The Xbox marriage is the **shared
stream-deserialize descriptor mechanism** (`&PTR_FUN_82030fa0`/`0x9e3779b9` ⇔ PC
`&PTR_CopyFromStream_*`/`0x9e3779b9`, cross-build-confirmed) plus the Havok packfile field-binders
(`FUN_0089c0c0`/`FUN_00957240`); the individual **Xbox parser bodies stay unlocated by name** — the
format is identical on both builds, which is what carries the marriage.

---

## 1. Container pipeline (disk → typed chunk tree)

```
vz.wad  (FFCS archive, image-independent)
 ├─ FFCS header  magic "FFCS" + u32 ver + 12B chunk rows {tag, offset_u32, meta_u32}
 │    ├─ INDX  N×12B  {page_index, packed, flags_pagecount};  page_index<<15 = file offset
 │    ├─ DATA  the sges blocks (first block at page 0x41 → 0x208000)
 │    ├─ CSUM  N×?    (FFCS-level; purpose still open)
 │    ├─ ASET  N×16B  {asset_hash, secondary_ref, (block_idx<<16)|sub, type_id}   §6
 │    └─ PTHS  path strings + mandatory 258B trailer
 │                                   ▲ opened via the Chunk_GetEntryReader family (0x464780/0x654940)
 ▼
 sges block  magic "sges" + u16 major(==4) + u16 nSeg + u32 ? + u32 uncomp_size + segtable(8B×nSeg)
 │    payload = raw-deflate segments (windowBits −15), 16B-aligned, 0-decomp ⇒ 64KB sentinel
 │       validator  @VA 0x005148B0  (magic/ver/size checks; exe_analysis_b §4)
 │       inflate    zlib 1.2.3  @0x00794700  (game's own copy, .rdata)
 ▼
 decompressed block =  u32 count  +  count×16B {name_hash, type_hash, field_c, chunk_size}
 │                     + concatenated UCFX chunks, each with an 8B "CSUM" trailer
 │                       (CRC-32 reflected, init=0, no final XOR — verified 53,765 chunks)
 ▼
 UCFX chunk  magic(4B) + 4×u32 header;  data_base = ucfx_off + u0
 │    20B chunk rows {tag, u0..u3}
 ▼
 typed chunk tree  ── CHDR dispatcher  FUN_00654940  (reads CHDR{u16,u16,u32}; routes COMP/enum/flgs…)
                   ├─ placement/ECS   Chunk_DeserializeCHDR  FUN_004cf340  (CHDR/NODE/CEXE/INFO/STAT/SWIT)
                   ├─ MANM name table Chunk_DeserializeMANM  FUN_0067a7fa  (FNV-1a name→id)
                   └─ per-type consumers (§4):
                        Mesh 0x478270 / Skin 0x4796f0 →  STRM 0x4a4770 · IBUF 0x4a48f0
                        Renderable 0x4a5230 →  MTRL Mtrl_Parse 0x858790
                        Texture 0x4b1000 →  INFO/BODY Tex_ConsumeChunk 0x750a30
                        Descriptor ATRB 0x492af0
                   every leaf reader = Chunk_GetEntryReader FUN_00464780 (0x14-stride cursor)
                   allocations = Chunk_Alloc FUN_0084ac20
```

The world/FFCS block-open path is the `Chunk_GetEntryReader` family, **not** a symbol named
`OpenStreamFile` (that Xbox symbol is the *audio* `.pws` stream pair — see
[`world_streaming_code_map.md`](world_streaming_code_map.md) §2.4). Confirmed here: `FUN_00464780`'s
caller set is dominated by `FUN_00654940` (the CHDR dispatcher, 8 call sites) and the block-entry
walkers `FUN_0045b0d0`/`FUN_0045dbb0`/`FUN_0045de70`/`FUN_0045dff0`.

---

## 2. Master marriage table (format / chunk → Xbox → PC → married-by → conf)

Xbox column: a `@0x829fXXXX` = the descriptor registrar (stream-deserialize); `&PTR_FUN_82030fa0` =
the shared deserialize vtable; **"unlocated"** = the Xbox parser body is not name-anchored and the
marriage is PC-anchored by the identical on-disk format. Every PC address below was **read
first-hand this pass** unless noted "(ref)".

| Format / chunk | Xbox | PC addr | Married by | Conf |
|---|---|---|---|---|
| **FFCS archive open** (INDX/DATA/ASET/PTHS) | unlocated (`LoadLevel`/`OpenStreamFile` not string-ref'd) | entry-reader family `FUN_00464780` / dispatch `FUN_00654940` | identical FFCS layout; INDX `page<<15`; both = the 0x14-stride reader | M |
| **sges block decompress** | unlocated (Saboteur `compressed.hpp` = same `SEGS`) | validator `@0x005148B0` + inflate `0x00794700` (zlib 1.2.3) | magic/ver-4/size-≤ checks + raw-deflate segtable, 64KB sentinel — byte-identical both builds | H |
| **block entry table** {name,type,field_c,size} | shared reader | `FUN_00464780` (0x14 stride) | READ: idx gate `[+8]`, base `[+0x10]`, `idx*0x14`, `+4≥0 && +8≠0`, vcall `+0x28` | H |
| **CHDR** dispatcher {u16,u16,u32} | unlocated | `FUN_00654940` | READ: `short@+0→[0117607c]`, `short@+2→[01176078]` (stride gate), `u32@+4` flags | H |
| **CHDR/NODE/CEXE/INFO/STAT/SWIT** placement tree | `&PTR_FUN_82030fa0` deserialize | `FUN_004cf340` | READ: FNV keys `0x9da97065`/`0xdb41017d`; NODE stride 0x14; relocating pack | H |
| **COMP {info,schm,data}** component records | descriptor `@0x829fXXXX` + `0x9e3779b9` | in `FUN_00654940` (schm→`thunk_024e31f0`) | READ: COMP subtree tags `data`/`schm`/`info`; type-hash resolve; seed `0x9e3779b9` both builds | H |
| **MANM** name→id table | unlocated | `FUN_0067a7fa` | (ref) MANM/info, FNV-1a name hash, spawns class `PTR_FUN_00bcdb70` | M |
| **MESH / GEOM** (model `0x5B724250`) | unlocated | `FUN_00478270` (root `0x478120`) | (ref) dispatch STRM/IBUF/BSHI/BSHP/PRMT/AREA/INFO; PRMG stride 0x1c4 | H |
| **skinned mesh** | unlocated | `FUN_004796f0` (root `0x479590`) | (ref) INFO(0x38)/IBUF/BSHI/BSHP/STRM/PRMT | M |
| **STRM** vertex stream {data,decl,info} | unlocated | `FUN_004a4770` | READ: `data`→`0x752890`, `decl`→`0x752b30`, `info`→12B via vcall+0x14→`0x7524a0` | H |
| **`decl`** vertex declaration | Xbox 12B BE elems | validate/clamp `FUN_0074d6d0`; consumed in STRM | (ref) 8B `D3DVERTEXELEMENT9`, format-translation table `&DAT_00b97630` stride 0xc | H |
| **IBUF** index buffer {info,data} | unlocated | `FUN_004a48f0` | READ: `info`→4B count; `data`→memcpy `cnt*stride`, 16/32-bit via bit9→`0x2000` | H |
| **MTRL** material (`0xF011157A` slot sentinel) | unlocated | `Mtrl_Parse FUN_00858790` (`__stdcall`) | READ: 8×float4; u16 tex-count `@+0xa2`; **fixed 10 slots** `{hash,0xF011157A,handle}` @+0x144, 0xc stride | H |
| **INFO/BODY** texture (`0xF011157A`) | unlocated | `Tex_ConsumeChunk FUN_00750a30` | READ: NAME(0x454d414e)+INFO(w@+4,h@+6,mip flag@+2a…)+BODY mip-chain build | H |
| **ATRB** descriptor properties | unlocated | `Descriptor_ConsumeATRB FUN_00492af0` | (ref) ATRB → 32-bit property-hash → setter dispatch | M |
| **stream-deserialized ECS descriptors** (Terrain/Region/Hibernation/…) | `@0x829fXXXX` registrars, `&PTR_FUN_82030fa0`, seed `0x9e3779b9`, field-table `FUN_824fcac8` | `&PTR_CopyFromStream_*` + `0x9e3779b9`; ctors `FUN_0064xxxx` | **cross-build confirmed**: same seed + shared deserialize vtable in both builds | H |
| **Havok packfile** `data` (anim `0x18166555`) / `PHY2` | field-binders `FUN_0089c0c0`/`FUN_00957240` (both builds share names) | conversion binders `FUN_0089*`/`FUN_008a*` (e.g. `FUN_0089d280`) | string-anchored to `hierarchy`/`referencePose`/`numberOfPoses` field names; 48B `hkQsTransform` copy | M |
| **CSUM** per-chunk trailer | (n/a — integrity only) | (validated in tooling; not a runtime gate found) | CRC-32 reflected init=0 no-xor; 53,765 chunks | H |

---

## 3. Container pipeline — read first-hand

### 3.1 Block entry reader `FUN_00464780` = `Chunk_GetEntryReader` (H, READ)

The single leaf every consumer calls to advance across the block's 16/0x14-byte entry table. Body
(97 B), read verbatim:

```c
int FUN_00464780(int param_1) {           // param_1 = block object; in_EAX = entry index
  if (in_EAX < 0 || *(int*)(param_1+8) <= in_EAX) return 0;     // +8 = entry count
  iVar1 = *(int*)(param_1+0x10) + in_EAX*0x14;                   // +0x10 = table base, stride 0x14
  if (-1 < *(int*)(iVar1+4) && *(int*)(iVar1+8) != 0) {          // +4 offset ≥0, +8 size ≠0
    (**(code**)(*(int*)(param_1+0x18)+0x28))();                  // reset reader object @+0x18 (vcall +0x28)
    FUN_00825e40();                                              // seed cursor
    return param_1 + 0x18;                                       // returns the 0x14-stride reader
  }
  return 0;
}
```

This confirms Part C.2's entry stride **0x14** `{+0 magic/tag, +4 offset, +8 size, +0xc flag, +0x10
skip}` and the reader object's cursor triple `+0x10 cursor / +0x14 carry / +0x18 data-base` — every
downstream body advances the cursor as `*puVar = *puVar + N; carry += (0xffffffff{b|d} < old)`,
which is the 64-bit-carry idiom for a 32-/16-bit read.

### 3.2 CHDR dispatcher `FUN_00654940` (H, READ) — the stride gate lives here

The chunk-tree walker that opens each sub-UCFX with a **CHDR** and routes the body. The CHDR arm
(tag `0x52444843`) is the decisive read:

```c
else if (uVar14 == 0x52444843) {                    // 'CHDR'
  iVar8 = FUN_00464780(param_1);
  _DAT_0117607c = (int)*(short*)(...);              // u16 @+0  -> fieldA
  ...cursor += 2;
  sVar2 = *(short*)(...);  DAT_01176078 = (int)sVar2;// u16 @+2  -> THE TRANSFORM STRIDE GATE
  ...cursor += 2;
  uVar15 = *(uint*)(...);                            // u32 @+4  -> flags
  bVar16 = (uVar15 & 1) != 0;  if (bVar16) FUN_0084ac20(0x800,1);
  DAT_01176053 = (byte)(uVar15 >> 2) & 1;
}
```

`DAT_01176078` is the process-global the Transform record builder `0x0063D7C0` reads: stride **42
iff gate ≥ 0x2A (56 → 42)** else **40** ([[chdr-dual-layout-mesh-vs-placement]], `ecs_components.md`
§CHDR). This is why a whole-`u32` swap of the CHDR header transposes the two u16s, zeroes the gate,
and drifts every Transform by 2 B → spatial-hash AV `0x0248BBE2`. The dispatcher also handles
`enum`(0x6d756e65), **`COMP`**(0x504d4f43), `UNIQ`(0x51494e55), `flgs`(0x73676c66),
`flgt`(0x74676c66); the COMP subtree reads `data`(0x61746164)/`schm`(0x6d686373, → SecuROM
`thunk_FUN_024e31f0`)/`info`(0x6f666e69) and resolves the component type through the name-hash
tables. Its cleanup tail calls `thunk_FUN_024ecab0` per record — the **same SecuROM worker** the
`SetHibernationDistance` cfunc uses (world-streaming map §4), tying placement load to the
hibernation-distance install. Callers: `FUN_0045e5f0`, `FUN_004646b0` (the block dispatch), so this
is squarely the FFCS block-content walker.

### 3.3 Placement CHDR-tree deserializer `FUN_004cf340` (H, READ)

The generic property-tree deserializer (943 B, vtable `0xBB12B4`; the `0x4CF58B` world-load AV
site). Read confirms the tag set and the FNV-keyed field routing:

- **`CHDR`** (0x52444843): reads `{key u32, count u32}`; `key == 0x9da97065` → binds to `STAT+0x4`,
  `key == 0xdb41017d` → `STAT+0xc` (the `-0x62568f9b`/`-0x24befe83` immediates); allocs `count*4`.
- **`NODE`** (0x45444f4e): `{_, count}`; allocs `count*0x14 + 4` (count prefix + records), inits via
  `FUN_00401860(ptr,0x14,count)` → **record stride 0x14**.
- **`CEXE`** (0x45584543): fills the current key's `count`-length u32 array element-by-element.
  *(Part C.1 / load-path map spell this "CECE"; the immediate `0x45584543` decodes to `CEXE` —
  reconcile to CEXE.)*
- **`INFO`** (0x4f464e49): reads two counts into `in_EAX+4`/`in_EAX+0xc`, sizes the relocating pack.
- **`STAT`** (0x54415453): bumps the sub-record index, zero-inits a 0x14 record.
- **`SWIT`** (0x54495753): copies `in_EAX+0xc` u32 switch entries into the scratch array.

The tail is a single relocating allocation (`FUN_0084dce0` fast → `FUN_0084d760` slow under CS
`DAT_00ff4570`, sizing loop `local_8`) that `memcpy`s the node array + STAT records + their inner
u32 arrays into one contiguous block and fixes up the pointers — the "flatten placement tree into
one alloc" pass.

### 3.4 sges decompress + INDX offset (M/H)

The engine's sges validator is at **VA `0x005148B0`** (file offset `0x1148B0`; `exe_analysis_b`
§4): `CMP [EBX],'sges'` / `CMP WORD [EBX+4],4` (major==4) / `CMP [EBX+0xC],[EAX+0x14]`
(decomp_size ≤ expected). It then walks the 8B-per-entry segment table at `+0x12`; the low bit of
the compressed-size word is the compression flag (set → raw deflate, clear → stored), and a zero
decompressed-size means the 64KB default. Decompression uses the game's own **zlib inflate 1.2.3 at
`0x00794700`** (a second copy, inflate 1.2.2 at `0x01FE3C70`, is SecuROM's). INDX resolution is
arithmetic, not a function: `file_offset = page_index << 15` (× 0x8000); retail's first block sits
at page `0x41` = `0x208000`. The Xbox parser is unlocated by name but the Saboteur's
`compressed.hpp` proves the format is shared verbatim (same `SEGS` struct, `-MAX_WBITS`, `== 0 ?
0x10000` sentinel), so the marriage is format-anchored **H** for the layout, **M** for the Xbox VA.

---

## 4. Per-type consumers — read first-hand

### 4.1 `Mtrl_Parse FUN_00858790` (H, READ) — the fixed-10-slot texture array

`__stdcall`, ret 8 ([[fun-858790-mtrl-parse-stdcall]]). Reads **8× float4** into `mat[0..7]`
(the shader-constant preamble), a run of scalar params, then:

```c
sVar4 = *(short*)(cursor);  ...cursor += 2;
*(short*)((int)param_1 + 0xa2) = sVar4;             // u16 tex-count @ mat+0xa2
local_38 = (int*)((int)param_1 + 0x144);            // texture-hash array base
pbVar14 = (byte*)((int)param_1 + 0xac);             // per-slot record {hash, F011157A, handle}
do {
    *local_38 = read_u32();                          // texture name-hash
    if (slot changed) { pbVar14[-8]=hash; write 7a 15 11 f0 (=0xF011157A) at pbVar14[-4..] }
    local_38++; pbVar14 += 0xc;                       // slot stride 0xc
} while (++i < *(ushort*)(param_1+0xa2));
if (9 < i) goto done;                                 // <-- FIXED 10 SLOTS
for (k = 10 - i; k; k--) *puVar18++ = 0;              // zero-fill remaining of the 10
```

This is the `0x84DD5B` root cause verbatim: a byte-swapped tex-count (e.g. `0x80`) drives the loop
past 10 records and overruns `mat+0x144` into the pool freelist. The `0xF011157A` sentinel (bytes
`7a 15 11 f0`) is the resource-type key; the "cleared handle" compare is `-0xfeeea86`
(= `0xF011157A` sign-flipped). Slot stride **0xc** `{name-hash, 0xF011157A, runtime-handle}`,
count field **`@mat+0xa2`**, array **`@mat+0x144`** — matches Part C.2 exactly.

### 4.2 `Tex_ConsumeChunk FUN_00750a30` (H, READ) — INFO header + BODY mip build

Loops the block, dispatching `NAME`(0x454d414e, → `Chunk_ReadCString` into a 0x100 buf),
`INFO`(0x4f464e49), `BODY`(0x59444f42). The INFO arm reads the texture header into the resource at
`unaff_EDI`: `u16 @+4` (width), `u16 @+6` (height), further u16s `@+8/+0xa/+0x28`, a **byte `@+0x2a`
= surface/DXT flag**, `u32 @+0x24` and `@+0x20`, then u16s `@+0x2c/+0x2e/+0x30/+0x32` (surface-array
descriptors). The BODY arm branches on `@+0x2a == 1` (build the DXT block mip chain via
`FUN_0085cbd0`, halving w/h per mip with `>> (bitcount)`) vs `== 2` (6-face cubemap path,
`FUN_0085ccd0`, loop `< 6`). This is the concrete engine reader behind `format_reference.md` §4.3's
tool-view (`w@+0, h@+2, mip@+6, fourcc@+14, total@+22`) — the tool offsets are relative to the INFO
*body*, the exe offsets are relative to the texture *resource object*.

### 4.3 `VertStream_ConsumeSTRM FUN_004a4770` (H, READ)

Three sub-tags: **`data`** (0x61746164) → resolves the body ptr as `block+0xc + entry.offset`, sets
it via `FUN_00752890`; **`decl`** (0x6c636564) → `FUN_00752b30(block+0xc + offset)` installs the
decoded vertex declaration (or `FUN_00752b30(0)` for the empty-decl reskin case); **`info`**
(0x6f666e69) → reads a 12-byte stream descriptor via the reader's vcall `+0x14`, then
`FUN_007524a0(stream, size, stride)` where the stride is `8` (or `8 &~7` gated on `DAT_011759c2` —
the platform stream-desc size toggle).

### 4.4 `IndexBuf_ConsumeIBUF FUN_004a48f0` (H, READ)

Two sub-tags: **`info`** (0x6f666e69) reads the 4-byte index count via vcall `+0x14`;
**`data`** (0x61746164) allocates via `FUN_00751fd0((*(ushort*)(stream+0x10) >> 9 & 1) << 0xd)` —
i.e. bit 9 of the stream flags selects a `0x2000` (32-bit index) buffer — and `memcpy`s
`count*stride` bytes (`*(stream+0xc) * *(stream+8)`). The `DAT_01175a3c`/`DAT_01175a40` path is the
index-remap variant (halved size `iVar4*2`) used on one platform branch. Confirms the load-path
map's "16/32-bit aware memcpy."

### 4.5 Mesh / MANM / ATRB (M, ref)

`Mesh_ConsumeChunk FUN_00478270` (root `0x478120`) dispatches STRM/IBUF/BSHI/BSHP/PRMT/AREA/INFO and
allocs the blendshape/prim/material arrays (PRMG record stride **0x1c4** = 452 B, the `0x47AA5C`
null-handle site). `Chunk_DeserializeMANM FUN_0067a7fa` builds the FNV-1a name→id table
(`Chunk_ReadCString FUN_00825dc0`), spawning class `PTR_FUN_00bcdb70`. `Descriptor_ConsumeATRB
FUN_00492af0` reads ATRB then dispatches on a 32-bit property-hash to per-property setters. These
were read in prior passes (load-path map) and are cited by reference, not re-read here.

---

## 5. The stream-deserialize descriptor mechanism (the Xbox↔PC keystone) — H

This is the load-path backbone and the **cleanest cross-build marriage** in the whole subsystem.
Every world-content ECS component that streams from the WAD is registered by a tiny run-once
descriptor function that wires the **shared** stream-deserialize vtable and the golden-ratio hash
seed:

| | Xbox (Jul-08 Profile) | PC retail |
|---|---|---|
| descriptor registrar | `@0x829fXXXX` (e.g. `TerrainGuidMappingHighResToLowRes @0x829f6ba8`) | ctor `FUN_0064xxxx` (e.g. `HibernationControl FUN_00640a40`) |
| shared deserialize vtable | `&PTR_FUN_82030fa0` (wired into **232** descriptors) | `&PTR_CopyFromStream_00bbf430` / `&PTR_CopyFromStream_*` |
| reflection hash seed | `0x9e3779b9` (in `FUN_824fcac8`) | `0x9e3779b9` (in every descriptor ctor) |
| field-hash table init | `FUN_824fcac8(desc, elem_size)` | inline (`DAT_…19c = size`) |
| element size (the on-disk stride) | the `FUN_824fcac8` size arg (e.g. `RuntimeTerrainBound` 0x1c, `TerrainKey` 4) | the `DAT_…19c` store (e.g. `HibernationControl` = **6**) |

The seed `0x9e3779b9` appearing in **both** builds' field-table initializers, plus the shared
deserialize pointer, is the coincidence-proof link — it independently confirms that the PC
`CopyFromStream` path and the Xbox `&PTR_FUN_82030fa0` path deserialize the **same** stream format.
The descriptor's element-size arg **is** the on-disk chunk stride the Rust `placement.rs` parses
(e.g. HibernationControl size 6 = `{dist0:u16, dist1:u8, dist2:u8, dist3:u8, flag:u8}`). Do **not**
read the `Name 14080`/`768`/`512` string rows as `sizeof` — those are pool-count/alignment, not
element size (world-streaming.md Corrections).

---

## 6. Type-hash + FourCC reference block

**Asset type hashes** (`pandemic_hash_m2` of the type name; build-invariant — same on Xbox & PC;
these key the block entry table's `type_hash` field and the ASET `type_id`):

| Hash | Type | Hash | Type |
|---|---|---|---|
| `0xF011157A` | texture (also the MTRL slot sentinel) | `0x5608BD5A` | effect |
| `0x5B724250` | model | `0xF753F6D0` | wavebank |
| `0x18166555` | animation (Havok packfile) | `0x9F8BCA10` | soundbank |
| `0x7C569307` | terrainmesh | `0xE5273C14` | sounddb |
| `0x1602815C` | lowresterrain | `0x39E5E978` | stringdb |
| `0xE6B81A54` | layer (placement) | `0x99E77ACE` | font |
| `0x42498680` | script (Lua bytecode) | `0x59B9DF6A` | materialtable |
| `0xBCFE6314` | path (registry) | `0x4D7D30C4` | watermap |
| `0x3B0AABF8` | decaltable (per task brief) | `0x34612F86` | foliage |
| `0x600B904E` | *(shader resource, unresolved)* | `0x8F0A54E2` | binary |

**FourCC magics** (stored LE; compared as the u32 immediate). Verified in the parser bodies read
above:

| Tag | u32 (LE) | Parsed in |
|---|---|---|
| `CHDR` | `0x52444843` | `0x654940`, `0x4cf340` |
| `NODE` | `0x45444f4e` | `0x4cf340` |
| `CEXE` | `0x45584543` | `0x4cf340` (spelled "CECE" in older notes) |
| `INFO` | `0x4f464e49` | `0x4cf340`/`0x750a30`/`0x4a4770`/`0x4a48f0`/`0x478270` |
| `STAT` | `0x54415453` | `0x4cf340` |
| `SWIT` | `0x54495753` | `0x4cf340` |
| `COMP` | `0x504d4f43` | `0x654940` |
| `enum` | `0x6d756e65` | `0x654940` |
| `schm` | `0x6d686373` | `0x654940` (→ SecuROM `024e31f0`) |
| `data` | `0x61746164` | `0x654940`/`0x4a4770`/`0x4a48f0` |
| `flgs`/`flgt` | `0x73676c66`/`0x74676c66` | `0x654940` |
| `UNIQ` | `0x51494e55` | `0x654940` |
| `NAME` | `0x454d414e` | `0x750a30` |
| `BODY` | `0x59444f42` | `0x750a30` |
| `decl` | `0x6c636564` | `0x4a4770` |
| `MTRL` | `0x4c52544d` | `0x858790` (dispatched from `0x4a5230`) |
| `MANM` | `0x4d4e414d` | `0x67a7fa` |
| `PRMG`/`PRMT`/`IBUF`/`STRM`/`BSHI`/`BSHP`/`AREA` | `0x474d5250`/`0x544d5250`/`0x46554249`/`0x4d525453`/`0x49485342`/`0x50485342`/`0x41455241` | `0x478270`/`0x4796f0` |

**Sentinels:** `0xF011157A` (texture/shader resource-type, 2nd word of the MTRL `{hash,type,handle}`
key; cleared-handle compare `-0xfeeea86`) · `0xFFFF` (empty u16 / decl-END / ASET "no body") ·
`0xABABABAB` (heap-uninit fill). Hash: FNV-1a seed `0x811c9dc5`, mul `0x1000193`, lowercase via
`|0x20`, finalize `(h ^ 0x2a) * mul` (`Hash_String 0x00824270`); open-addressing probe
`HashTable_Probe 0x008242b0`.

---

## 7. Havok packfile (`data` / `PHY2`) conversion path — M

The animation `data` chunk (type `0x18166555`) and the collision `PHY2` chunk are both **Havok 5.5
packfiles** (magic `57 E0 E0 57 10 C0 C0 10`, word-palindromic so it survives a naive swap). The
runtime side is Havok's own loader; the **recovered PC functions are the schema field-binders** that
migrate old packfile field-names to the current names during deserialize
([`../mercs2-pdb-analysis/animation-skeleton.md`](../mercs2-pdb-analysis/animation-skeleton.md)
§"PC decompilation cross-reference"):

| Field(s) migrated | PC binder | Role |
|---|---|---|
| `hierarchy`→`parentIndices`, `bones`, `referencePose` | `FUN_0089d280` | skeleton reference-pose builder; copies `poseCount × 0x30` (48B `hkQsTransform`) per bone |
| `numberOfPoses` | `FUN_0089ce90`, `FUN_008a4550` | pose-count field-name conversion |
| `numberOfBoneTracks` | `FUN_0089cd40` | track-count conversion |
| `animationBoneInfo`/`ragdollBoneInfo` | `FUN_008a5dd0` | bone-info array conversion |
| `catchFallDirectionRagdollBone`/`velocity…` | `FUN_008a7280` | catch-fall modifier fields (default `0xffff`) |
| *(the field-copy primitives)* | `FUN_0089c0c0`, `FUN_00957240` | the shared field-binder both builds share by name |

Both builds share the **binder names** (`FUN_0089c0c0`/`FUN_00957240`), which is the marriage; the
Xbox build has no matching named function to re-confirm the 0x30 stride, so cite the PC VA for it.
The **BE→PC converter** encodes the full packfile layout ([`../format_reference.md`](../format_reference.md)
§15.2, [[phy2-havok-chunk-not-u32]]): 48B header + `__classnames__`/`__types__`/`__data__` sections,
section-aware conversion with per-class field widths from `hk_class_layouts.py` (the `hka*`
animation classes are registered → correct u16/u8 widths; `hkp*` physics classes are **unregistered
→ blind u32 sweep**, the remaining gap). `PHY2` additionally carries a `[u32 header][packfile][u32
self-offset trailer]` wrapper (crashes `0x00414B4C` scrambled-classnames and `0x0248C13E`
BE-trailer if mis-converted). The wavelet/delta/spline sample decode itself is **solved and
out-of-scope** here ([[wavelet-decode-solved-live-capture]], 168/168 tests).

---

## 8. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **sges validator/inflate VAs** — break `0x005148B0` (validator) and `0x00794700` (inflate 1.2.3)
   during a world load to confirm the file-offset→VA mapping (`0x1148B0`+`0x400000`) and read a live
   segment table; confirm the low-bit compression flag on a real segment.
2. **INDX arithmetic** — break the FFCS-open path (`FUN_00464780` callers `FUN_0045dbb0` family) and
   read a live INDX row to confirm `page_index << 15` and the retail page-`0x41` base.
3. **CHDR stride gate** — break `FUN_00654940` CHDR arm; read `[0x01176078]` and confirm
   `0x0063D7C0` picks stride 42/40 accordingly on a placement vs mesh block.
4. **MTRL overrun guard** — break `FUN_00858790` entry; read `[param_1+0xa2]` (tex-count) on a real
   MTRL to confirm ≤10 in shipping data (and that the zero-fill loop runs for count<10).
5. **SecuROM workers** — `thunk_FUN_024e31f0` (schm handler) and `thunk_FUN_024ecab0` (the shared
   hibernation-distance/placement worker in `0x654940`'s tail) live in the self-decrypting overlay;
   read the unpacked bodies live.
6. **Xbox parser VAs** — the Xbox `StreamManagerUpdate`/`LoadLevel`/`OpenStreamFile` bodies are not
   string-anchored; if the Xbox devkit is ever driven under a debugger, break the FFCS open to bind
   the Xbox counterparts of `0x464780`/`0x654940`/`0x858790` (all currently PC-anchored).

---

## 9. Open / unlocated (honest)

- **Xbox parser bodies** — the individual Xbox FFCS-open, sges-decompress, CHDR-dispatch, MTRL, and
  texture-INFO *function bodies* are **unlocated by name** on the Jul-08 build (the format is what
  carries the marriage). Only the **descriptor mechanism** (`@0x829fXXXX` + `&PTR_FUN_82030fa0` +
  `0x9e3779b9`) and the Havok field-binder **names** are Xbox-side ground truth.
- **FFCS-level `CSUM` chunk** — its `offset` exceeds file size (it's a hash/id, not an offset) and
  its runtime purpose is unresolved; no PC function found that reads it (distinct from the per-UCFX
  CRC-32 trailer, which tooling validates but no runtime *gate* was located).
- **MTRL 8×float4 + scalar preamble semantics** — the field *widths* are read (§4.1) but the shader
  meaning of the 104-byte preamble is not fully named (medium gap; Saboteur WSAO hashes may resolve).
- **`hkp*` physics `__data__` field widths** — unregistered in `hk_class_layouts.py`, so PHY2 inner
  u16/u8 fields fall back to a blind u32 sweep (§7).
- **17 of 35 type_hashes** remain unresolved (resident-only singletons / rare types).
- **`decl` vertex-format bitfield** (`0x1B` tag byte reported in Saboteur decls) — not yet used to
  replace the PC stride heuristics.

---

## 10. Reconciliation with `mercs2_engine` / `mercs2_formats` (row 11 = ✅)

Row 11 is the engine's **strongest** column: the `mercs2_formats` Rust crate is the ground-truth
parser for every format above and is held byte-identical to the exe oracle by golden tests. This map
is the exe-side authority those parsers already mirror:

- `ffcs.rs` / `sges.rs` implement the exact container pipeline in §1/§3.4 (INDX `page<<15`, sges
  `-15` deflate + 64KB sentinel, entry table + UCFX + CSUM); `crc32.rs` = the §6 reflected-init-0
  variant, validated across 53,765 chunks.
- `ucfx.rs` / `world.rs` / `placement.rs` walk the CHDR/COMP/NODE/STAT tree (§3.2/§3.3) — the CHDR
  per-field swap in `convert.rs::swap_chdr_header_inplace` exists precisely because of the
  `DAT_01176078` stride gate read in §3.2; `placement.rs::parse_hibernation_records` reads the 6-byte
  stride the §5 descriptor proves.
- `texture.rs` (INFO/BODY, §4.2), the mesh/STRM/IBUF/`decl` readers, and `havok.rs`/`anim*.rs`/
  `skeleton.rs` (§7) mirror `0x750a30`/`0x4a4770`/`0x4a48f0`/`0x858790` and the Havok field-binders.
- The one exe-side detail worth carrying into the engine is the **fixed 10-slot MTRL cap** (§4.1) —
  the converter/engine must clamp/validate tex-count to ≤10 (the `0x84DD5B` guard), which
  `probe_mtrl.rs` already checks.

Net: this document is the **marriage layer** on top of an already-complete parser corpus — it binds
each Rust parser and each PC function to the on-disk format and to the Xbox descriptor mechanism,
and enumerates the handful of genuinely-unlocated Xbox bodies so no one re-surveys them.
