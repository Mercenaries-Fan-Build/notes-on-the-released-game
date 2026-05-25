# Saboteur Toolset ↔ Mercenaries 2 Engine Comparison

Cross-reference analysis of [PredatorCZ/SaboteurToolset](https://github.com/PredatorCZ/SaboteurToolset) against our Mercenaries 2 reverse engineering work. Both games were developed by Pandemic Studios on closely related engines (the README calls The Saboteur's engine "probably WildStar internally").

---

## 1. Hash Algorithm — **IDENTICAL (Mercs 2 variant)**

### The Saboteur's implementation

From `include/hashstorage.hpp`:

```cpp
constexpr uint32 GetHash(std::string_view str) {
  if (str.empty()) {
    return 0;
  }
  uint32 retVal = 0x811C9DC5;
  for (auto c : str) {
    retVal = (retVal ^ (uint8(c) | 0x20)) * 0x1000193;
  }
  return 0x1000193 * (retVal ^ 0x2a);
}

static_assert(GetHash("ANY") == 3976557093);
```

### Our Mercs 2 implementation

From `tools/pandemic_hash.py`:

```python
FNV1A_OFFSET_BASIS = 0x811C9DC5
FNV1A_PRIME = 0x01000193

def pandemic_hash_m2(text: str) -> int:
    if not text:
        return 0
    h = FNV1A_OFFSET_BASIS
    for ch in text:
        h ^= (ord(ch) | 0x20)
        h = (h * FNV1A_PRIME) & 0xFFFFFFFF
    h ^= 0x2A
    h = (h * FNV1A_PRIME) & 0xFFFFFFFF
    return h
```

### Verdict: **Byte-for-byte identical algorithm**

Both use:
- FNV-1a with offset basis `0x811C9DC5` and prime `0x01000193`
- Case suppression via `| 0x20` on each byte before XOR
- **Post-processing finalization:** `hash ^= 0x2A; hash *= prime`

This is the **Mercs 2 variant** (not the Mercs 1 variant, which lacks the `^0x2A, *prime` finalization). The Saboteur inherited the hash directly from Mercenaries 2's codebase.

The compile-time assertion `GetHash("ANY") == 3976557093` (= `0xED057225`) provides an independent verification point — and our `pandemic_hash_m2("ANY")` produces the same value, confirmed via `--test`.

### Implications for our project

- The `pandemic_hash_m2` function can hash Saboteur asset names and get matching results
- The `saboteur_strings.txt` file (2 MB, shipped with the toolset) contains ~50k+ known asset path strings — we could hash these and compare against unknown ASET hashes in our WAD to find naming patterns, since both games share many asset naming conventions
- Confirms our disassembly analysis of 166+ call sites was correct about the finalization step

---

## 2. Archive Format — Megapack (`MP00`) vs FFCS

### The Saboteur's archive hierarchy

The Saboteur uses a layered archive system:

| Level | Format | Magic | Purpose |
|-------|--------|-------|---------|
| **Outer** | Megapack | `MP00` | Top-level archive: `mega0.megapack`, `dynamic.megapack`, `palettes.megapack` |
| **Inner** | SBLA pack | `SBLA` | Per-asset sub-pack inside megapacks (contains meshes, textures, physics, layouts) |
| **Mesh wrapper** | MSHA | `MSHA` | Inside SBLA: wraps a MESH + data pair with name and compression info |
| **Compression** | SEGS (= `sges`) | `sges` | Same deflate compression as Mercs 2 |
| **Map index** | MAP6 | `MAP6` | World map descriptor (tile references, dynamic object lists) |

### Megapack structure (`megapack.hpp`)

```cpp
static constexpr uint32 MP_ID = CompileFourCC("00PM"); // "MP00" LE

struct FileId {
  uint32 crc;    // hash/crc of the asset
  uint32 index;  // asset index used for lookup
};

struct File {
  FileId id;
  uint32 size;
  uint64 offset;  // 64-bit file offset (megapacks can be >4GB)
};
```

### Comparison with FFCS

| Feature | Mercs 2 FFCS | Saboteur Megapack |
|---------|-------------|-------------------|
| Magic | `FFCS` | `MP00` |
| Index format | INDX chunk: 12-byte entries (page_index, packed, flags) | File array: `{crc, index, size, offset}` |
| Offset size | 32-bit (page × 0x8000) | 64-bit native |
| Path strings | PTHS chunk (null-separated, trailing marker) | No embedded paths; hash-only with external `saboteur_strings.txt` lookup |
| Asset set | ASET chunk (16-byte rows, hash-based) | Moved to MAP6 descriptor files |
| Checksums | CSUM chunk + per-UCFX CRC-32 trailers | `crc` field in FileId (different hash/crc) |
| Compression | `sges` blocks (multi-segment raw deflate) | `sges` blocks (identical format!) OR plain zlib |
| Sub-packing | Blocks contain UCFX containers | SBLA packs contain typed assets (mesh, texture, physics, layout) |
| Endian support | LE only (PC) | LE + BE (PS3 via `FByteswapper`) |

### Key evolution points

1. **`sges` compression is identical.** The Saboteur's `compressed.hpp` defines the same `SEGS` struct (`id, version, numChunks, uncompressedSize, compressedSize`) with per-chunk `(compressedSize, uncompressedSize, offset)` entries and raw deflate (`-MAX_WBITS`). They even use the same `c.uncompressedSize == 0 ? 0x10000 : c.uncompressedSize` sentinel for 64KB chunks.

2. **Path strings were removed from the archive.** FFCS embeds PTHS; megapack doesn't. The Saboteur relies entirely on hash lookups with an external string dictionary (`saboteur_strings.txt`). This suggests Pandemic considered PTHS a debugging/development artifact.

3. **64-bit offsets.** Megapack uses native uint64 offsets instead of FFCS's page-based addressing (page_index × 0x8000). This is a practical upgrade for larger archives.

4. **SBLA replaces the monolithic block model.** Instead of one big `sges`-compressed UCFX blob per block, The Saboteur uses SBLA packs that explicitly enumerate their mesh count, texture count, physics count, etc. This is more structured than FFCS's opaque UCFX containers.

---

## 3. Lua Script Storage — `luap` vs BINN/UCFX

### The Saboteur's `.luap` format

From `luapack/luap_extract.cpp`:

```cpp
struct File {
  uint32 id0;           // hash
  uint32 id1;           // hash
  uint32 offset;        // absolute offset within the luap
  uint32 compressedSize;
  uint32 uncompressedSize;
};

// Each entry is a LuaQ 5.1 bytecode file
struct Lua {
  uint32 id;            // "\x1BLua" magic
  uint8 version;        // Lua version
  uint8 format;
  uint8 endian;
  uint8 intSize;
  uint8 size_tSize;
  uint8 instructionSize;
  uint8 numberSize;
  uint8 internalFlag;
};
```

Key observations:
- The `.luap` file starts with a `numFiles` count, followed by `File` descriptors
- Each script is stored as **uncompressed** LuaQ 5.1 bytecode (`assert(f.compressedSize == f.uncompressedSize)`)
- Source path strings are embedded inside the Lua bytecode's debug info (extracted via `rd.ReadContainer(sourceName)` after the Lua header)
- Script paths follow patterns like `scripts/<name>.lua`

### Comparison with Mercs 2

| Feature | Mercs 2 | The Saboteur |
|---------|---------|-------------|
| Container | BINN chunks inside UCFX blocks in `vz.wad` | Standalone `luascripts.luap` file |
| Bytecode version | Lua 5.1 (LuaQ) | Lua 5.1 (LuaQ) |
| Compression | Inside `sges` blocks (zlib deflate) | Uncompressed (`compressedSize == uncompressedSize`) |
| Path info | Hash-based lookup; paths in PTHS | Source path embedded in bytecode debug info |
| Index | FFCS block index → UCFX → BINN | Simple count + file descriptor array |
| Script names | e.g. `wifmissionflow`, `wifbriefingdata` | e.g. `scripts/missions/...` |

### Evolution insight

The Saboteur simplified Lua script packaging dramatically — from being embedded deep inside compressed UCFX containers to a flat indexed file. Both use the same Lua 5.1 bytecode format, confirming the scripting engine didn't change between games. This means our `ChunkSpy.lua` disassembly approach works for both.

---

## 4. Mesh Format — MESH vs UCFX GEOM/MESH/PRMG/STRM/IBUF

### The Saboteur's mesh format

From `mesh/mesh_to_gltf.cpp`, the MESH format is a structured binary:

```
MESH header:
  - BBOX (bounding box)
  - name (hash)
  - numBones0, numBoneRemaps
  - numStreams, numPrimitives, numDrawCalls

Optional skeleton:
  - boneIds[], localTMS[], bones[], transforms[], parentIds[]

BoneRemaps[] (if skinned)
Streams[] (vertex/index buffer descriptors)
Primitives[] (sub-mesh draw ranges)
DrawCalls[] (material + primitive + bone binding)
```

**Stream descriptor:**
```cpp
struct Stream {
  uint32 numVertices;
  uint32 format;              // packed vertex format bitfield
  uint32 vertexBufferOffset;  // into companion .dat file
  uint32 vertexBufferSize;
  uint32 vertexBufferStride;
  uint32 indexBufferOffset;
  uint32 indexBufferSize;
  uint32 faceType;            // always 1 (triangle list)
  uint32 numIndices;
};
```

**Vertex format bitfield (`format` field):**
```cpp
struct VertexFormat {
  VertexFormat_e positionType : 2;  // 2 = half-float
  VertexFormat_e skinType : 2;      // 0 = none, 1 = 4-bone
  uint32 numVertexColors : 4;
  uint32 numTexCoords : 4;
  uint32 useNormal : 1;
  uint32 useTangent : 1;
  uint32 reserved : 10;
  uint32 constTag : 8;             // always 0x1B
};
```

Known format codes and their vertex layouts:

| Format | Components |
|--------|-----------|
| `0x1b001102` | Position(f16) + UV + Normal |
| `0x1b001112` | Position(f16) + Color + UV + Normal |
| `0x1b003102` | Position(f16) + UV + Normal + Tangent |
| `0x1b003112` | Position(f16) + Color + UV + Normal + Tangent |
| `0x1b001106` | Position(f16) + BoneWeights + BoneIndices + UV + Normal |
| `0x1b003106` | Position(f16) + BoneWeights + BoneIndices + UV + Normal + Tangent |
| ... | (18 known combinations total) |

**Primitive descriptor:**
```cpp
struct Primitive {
  BBOX bbox;
  uint32 streamIndex;
  uint32 indexOffset;
  uint32 numFaces;
  uint32 numIndices;
};
```

**Draw call:**
```cpp
struct Drawcall {
  uint32 primitiveIndex;
  StringHash material;    // hashed material name
  uint16 parentBone;
  uint16 unk;
};
```

### Comparison with our UCFX mesh system

| Feature | Mercs 2 UCFX | Saboteur MESH |
|---------|-------------|---------------|
| Container | UCFX → GEOM → MESH → PRMG → STRM/IBUF hierarchy | Flat MESH header + arrays of streams/primitives/drawcalls |
| Chunk tags | 4-byte ASCII tags (GEOM, MESH, PRMG, STRM, IBUF, INFO, MTRL, etc.) | Single `MESH` magic; typed arrays instead of tagged chunks |
| VB/IB storage | Inline in the decompressed block (offsets relative to `data_base`) | Separate `.dat` companion file |
| Position encoding | Half-float (f16) or SNorm16 with bbox remap | Half-float (f16) with `R16G16B16A16` format |
| Vertex stride | Detected heuristically from `decl` chunk or `vb_len / n_verts` | Explicit `vertexBufferStride` field |
| Vertex format | Implicit; `decl` chunk gives stride, layout inferred | Explicit bitfield with known component map |
| Index format | u16 triangle strips (with degenerate separators) | u16 triangle lists (`faceType == 1`; no strips) |
| Material binding | PRMT chunk maps draw calls to MTRL table entries | DrawCall struct references material by hash directly |
| Skeleton | HIER chunk (176-byte nodes with local transform + parent chain) | Explicit bone arrays with RTS transforms and parent IDs |
| HIER→MESH mapping | INDX chunk (u16 per MESH group → HIER node) | DrawCall.parentBone |
| Bounding boxes | PRMG INFO (60 bytes, sphere center+radius + bbox min/max) | Per-primitive BBOX |
| LOD | P000_Q# naming; pick by bbox volume | Not evident in toolset (possibly external LOD system) |
| Damage states | SWIT chunk pairs in HIER | Not observed |

### Key insights for our project

1. **Position encoding confirmed as half-float.** The Saboteur uses `R16G16B16A16` (half-float) positions, matching our f16_vec3 detection. The `constTag = 0x1B` in the format bitfield is interesting — we should check if Mercs 2's `decl` chunk contains a similar tag byte.

2. **Explicit vertex format bitfield.** The Saboteur encodes vertex layout as a bitfield (`positionType:2 | skinType:2 | numColors:4 | numUVs:4 | normal:1 | tangent:1 | reserved:10 | constTag:8`). Our `decl` chunk in Mercs 2 may encode something similar — the stride-guessing heuristic in `ucfx_mesh_codec.py` could potentially be replaced with proper `decl` parsing if we can identify the same bitfield structure.

3. **Triangle lists replaced triangle strips.** The Saboteur switched entirely to triangle lists (`faceType == 1`), while Mercs 2 uses triangle strips with degenerate separators. This is a natural GPU-era evolution.

4. **Companion .dat file pattern.** The Saboteur splits mesh metadata (.msh) from buffer data (.dat) via the `MSHA` wrapper, while Mercs 2 keeps everything in one UCFX blob. The MSHA header is:
   ```cpp
   struct MSHA {
     uint32 id;  // "MSHA"
     uint32 uncompressedSize0;  // mesh metadata
     uint32 uncompressedSize1;  // buffer data
     uint32 compressedSize0;
     uint32 compressedSize1;
     char name[0x100];
   };
   ```

5. **Bone weight encoding.** Saboteur uses UNORM R8G8B8A8 for bone weights and UINT R8G8B8A8 for bone indices — 4 bones per vertex. Our HIER/skin stream format likely uses the same encoding.

---

## 5. Material Format — `WSAO` vs MTRL/PRMT

### The Saboteur's material system

From `materials/materials_extract.cpp`, materials are stored in `.materials` files with magic `WSAO` (or `OASW` in LE). The system is highly structured with multiple sub-blocks:

| Block | Magic | Content |
|-------|-------|---------|
| `WSMA` | `AMSW` | Material definitions (uid, textures, render pass index) |
| `WSTX` | `XTSW` | Texture hash references |
| `WSPA` | `APSW` | Render passes (pixel shader, vertex shader, property indices) |
| `WSST` | `TSSW` | State/sampler settings (two sets) |
| `WSCP` | `PCSW` | Constant properties (id + float[4] each) |
| `WSPP` | `PPSW` | Pixel shader properties (float[4] arrays) |
| `WSVP` | `PVSW` | Vertex shader properties (float[4] arrays) |

**Material structure (assembled):**
```json
{
  "uid": "material_name_hash",
  "textures": ["diffuse_hash", "normal_hash", ...],
  "renderPass": "pass_hash",
  "flags": 0,
  "pixelShader": "shader_hash",
  "vertexShader": "shader_hash",
  "constantProperties": [{"id": 0, "data": [1.0, 0.5, 0.3, 1.0]}, ...],
  "pixelProperties": [[1.0, 0.0, 0.0, 1.0], ...],
  "vertexProperties": [[0.0, 1.0, 0.0, 0.0], ...]
}
```

### Comparison with our MTRL/PRMT

| Feature | Mercs 2 MTRL/PRMT | Saboteur WSAO |
|---------|-------------------|---------------|
| Location | Inline UCFX chunk per block | Standalone `.materials` file (shared across assets) |
| Texture refs | u32 asset hashes in MTRL body (1-3 per material: diffuse, specular, normal) | WSTX block: array of texture hashes, index range per material |
| Shader refs | Not decoded (shader hashes may be in MTRL preamble) | Explicit pixel/vertex shader hashes in WSPA |
| Properties | Float properties at offsets +16/+17 in MTRL record (specular power/intensity) | Structured WSCP/WSPP/WSVP blocks with named IDs |
| Per-draw binding | PRMT 16-byte records (material_index, start_index, index_count, etc.) | DrawCall struct references material by hash |
| Material IDs | Positional index in MTRL chunk | Hash-based UIDs with collision detection |

### Insights for our MTRL decoding

1. **The 104-byte MTRL preamble** in Mercs 2 (`_MTRL_PREAMBLE = 104`) likely contains a shader hash and default color/emissive/specular properties — the same data The Saboteur stores explicitly in WSAO sub-blocks. We could try hashing known Saboteur shader names against the first u32 of our MTRL preamble.

2. **Texture slot ordering** is consistent: diffuse → specular → normal, matching our `tex_count` × 4-byte hash layout in MTRL records.

3. **State/sampler blocks (WSST)** don't appear in our UCFX — sampler state may be hardcoded per shader in Mercs 2 or encoded in an undecoded chunk.

---

## 6. Texture Format — `DTEX` vs DDS-in-UCFX

### The Saboteur's texture format

From `texture/dtex_to_dds.cpp`:

```cpp
struct Texture {
  uint32 format;             // FourCC (DXT1, DXT5) or numeric (21 = B8G8R8A8)
  uint32 unk;
  uint16 width;
  uint16 height;
  uint16 numMips;
  uint32 uncompressedSize;
  uint32 numStreams;         // multi-stream for progressive loading
};
```

DTEX files have:
- Magic `DTEX` (or `XETD` big-endian)
- A name string (the asset name)
- Texture header with format, dimensions, mip count
- Multiple zlib-compressed streams (progressive loading)
- Supported formats: DXT1 (BC1), DXT5 (BC3), format 21 (B8G8R8A8 uncompressed)

### Comparison with Mercs 2

| Feature | Mercs 2 | Saboteur |
|---------|---------|----------|
| Container | UCFX INFO + BODY chunks | Standalone DTEX files |
| Header fields | width(u16), height(u16), mip_count(u16), FourCC at +14, total_size at +22 | format(u32), unk, width(u16), height(u16), numMips(u16), uncompSize, numStreams |
| Compression | Raw DDS data inside sges-compressed blocks | Per-stream zlib inside DTEX |
| Formats | DXT1, DXT3, DXT5 | DXT1, DXT5, B8G8R8A8 |
| Streaming | texture_index.json cross-block mip assembly | `numStreams` field for progressive decoding |
| Naming | Hash-only (resolved via texture_index) | Embedded name string in DTEX |

The DTEX format is a simplified, self-contained evolution of Mercs 2's texture-in-UCFX approach. The multi-stream zlib compression is similar in spirit to our cross-block mip assembly but formalized into the file format.

---

## 7. DLC Architecture

### The Saboteur's DLC approach

From `globalmap/global_extract.cpp` and `francemap/france_extract.cpp`:

```cpp
// In global_extract.cpp, DLC is handled by:
// "Input path is a folder, where Saboteur.exe or EBOOT.BIN resides
//  or DLC/01 folder (tool will extract DLC content as well)"

// In france_extract.cpp, MAP6 detects DLC:
const bool isDLC = numTiles == 0;
```

The Saboteur DLC:
- Lives in a `DLC/01` folder alongside the main game
- Uses the same `MAP6` format but with `numTiles == 0` as a DLC flag
- Contains its own dynamic pack descriptors within the MAP6 file
- Assets are extracted using the same megapack/SBLA/MSHA pipeline
- `global_extract` transparently handles DLC when pointed at the game folder

### Comparison with Mercs 2

| Feature | Mercs 2 | Saboteur |
|---------|---------|----------|
| DLC format | Xbox 360 STFS → block injection into `vz-patch.wad` | DLC/01 folder with MAP6 + megapacks |
| Activation | Lua hook modifications (`wifmissionflow`) + bootstrap block | MAP6 descriptor with `isDLC` flag |
| Asset overlay | WAD overlay (patch blocks replace/extend base blocks) | Megapack lookup chain (DLC packs searched alongside base) |
| Complexity | Very complex: FFCS structure, PTHS trailer, ASET, block injection | Straightforward: folder-based, same tools |

### Insight

The Saboteur dramatically simplified DLC handling. Instead of patching a monolithic WAD, DLC is just another folder with self-describing MAP6 files. The `global_extract` tool searches for DLC automatically. This suggests Pandemic learned from the pain of Mercs 2's WAD overlay system and designed something more modular.

---

## 8. Animation Format — `AP0L` vs Havok 5.5

### The Saboteur's animation system

From `animpack/anim_extract.cpp`, animations are stored in `animations.pack` with magic `AP0L`:

The pack contains multiple named block types:

| Block | Magic | Content |
|-------|-------|---------|
| `ANIM` | `MINA` | Animation clips (duration, bone lists, flags) + embedded HKX blob |
| `SEQC` | `CQES` | Animation sequences (looping, blend metadata) |
| `TRAN` | `NART` | State machine transitions (from/to animation, tags) |
| `EDGE` | `EGDE` | Edge data (5030 entries — FSM graph) |
| `BANK` | `KNAB` | Animation banks (parent hierarchy, grouped clips) |
| `SSP0` | `0PSS` | Streamed animation packs (offset/size into separate data) |
| `INTV` | `VTNI` | Interruption definitions |
| `ALPH` | `HPLA` | Alpha/blend tree references |
| `ADD1` | `1DDA` | Additive animation references |
| `ANMA` | `AMNA` | Animation metadata (spl2 data) |

**ANIM struct (each animation clip):**
```cpp
struct ANIM {
  bool streamed;        // if true, HKX data is in SSP0 section
  bool unk1;
  bool unk4;
  float duration;
  float unk0[8];
  std::vector<StringHash> bones;
  std::vector<ANIMStruct0> unk2;
  std::vector<ANIMStruct1> unk3;
  StringHash id;
};
```

After all ANIM entries, a single concatenated HKX blob is written:
```cpp
uint32 numAnims;
rd.Read(numAnims);
uint32 hkSize;
rd.Read(hkSize);
ectx->NewFile("animations.hkx");
// ... writes hkSize bytes as one big HKX file
```

### Comparison with Mercs 2

| Feature | Mercs 2 | Saboteur |
|---------|---------|----------|
| Container | `animgroup` blocks in vz.wad → UCFX wrappers → individual HKX slices | Single `animations.pack` (AP0L) → metadata + one big HKX blob |
| Havok version | Havok 5.5 (`Havok-5.5.0-r1`) | HKX format (version not specified but likely 5.5 or 6.x) |
| Metadata | Record table (16 bytes each: checksum, magic 0x18166555, reserved, size) | Rich FSM metadata: sequences, transitions, banks, interruptions |
| Compression types | Interleaved, Delta, Wavelet (per-clip) | Not decoded in toolset (HKX blob extracted as-is) |
| State machine | Not extracted (may be in game Lua) | Full FSM graph: SEQC, TRAN, EDGE, BANK blocks |
| Streaming | All in WAD blocks | `streamed` flag on ANIM; SSP0 for offset-based streaming |

### Insights

1. **The Saboteur exposed the full animation state machine.** Mercs 2 likely has similar FSM data (sequences, transitions, banks) but we haven't found it — it may be in undecoded UCFX chunks or in the game's Lua scripts.

2. **Havok version continuity.** Both games use Havok binary animation data. The Saboteur's toolset doesn't decode HKX content (just extracts it), but the same `hkaInterleavedUncompressedAnimation`, `hkaDeltaCompressedSkeletalAnimation`, and `hkaWaveletSkeletalAnimation` classes from our Mercs 2 work would apply.

3. **SSP0 streaming pattern.** The `offset`/`size` fields for streamed animations mirror how Mercs 2 stores animations at specific offsets within `animgroup` blocks.

---

## 9. Compression — Shared `sges` Format

The Saboteur's `compressed.hpp` defines:

```cpp
struct SEGS {              // Note: code reads "sges" magic as CompileFourCC
  uint32 id;
  uint16 version;
  uint16 numChunks;
  uint32 uncompressedSize;
  uint32 compressedSize;
};

struct SEGSChunk {
  uint16 compressedSize;   // 0 means 0x10000 (64KB)
  uint16 uncompressedSize; // 0 means 0x10000 (64KB)
  uint32 offset;
};
```

This is **byte-for-byte identical** to our `sges` decompressor (`tools/sges_decompress.py`):
- Same magic: `sges` (read as `SEGS` due to endian)
- Same header layout: 16 bytes (magic + version/numChunks + sizes)
- Same chunk descriptor: 8 bytes (compSize + uncompSize + offset)
- Same decompression: raw deflate (`-MAX_WBITS`)
- Same 64KB sentinel: `uncompressedSize == 0 ? 0x10000 : uncompressedSize`

The Saboteur additionally supports fallback to plain zlib (`MAX_WBITS`) for non-SEGS compressed data.

---

## 10. World/Map System — MAP6 vs FFCS Blocks

### The Saboteur's map descriptor

From `globalmap/global_extract.cpp`:

```cpp
// MAP6 header, then:
struct DynamicPackDesc {
  uint32 assetIndex;       // lookup key into megapack
  std::string name;        // asset name
  uint8 data[28];          // transform/placement?
  std::vector<uint32> textures;
  std::vector<uint32> meshes;
  uint32 dataOffset;
  uint32 numMeshes;
  uint32 numTextures;
  uint32 numPhys;
  // ...
};
```

And from `tilepack/tilepack_extract.cpp`, the height/terrain system:

```cpp
struct HeightHeader {
  uint32 id;               // HEI1
  uint32 numWBlocks;
  uint32 numHBlocks;
  float width;
  float height;
};
```

### Comparison with Mercs 2

| Feature | Mercs 2 | Saboteur |
|---------|---------|----------|
| World index | FFCS INDX chunk → block files → UCFX containers | MAP6 → DynamicPackDesc → megapack → SBLA packs |
| Placement | 42-byte records in UCFX COMP/flgs chunks | `DynamicPackDesc.data[28]` (likely transform) + explicit mesh/texture lists |
| Terrain | 20×20 `low_res_terrain` grid, f16 vertices, snorm16 bbox remap | HEI1 heightfield (`numWBlocks × numHBlocks`), separate tile packs |
| Tile format | UCFX per tile, merged into one GLB | SBLA tile packs with mesh + texture + layout + masks |
| Cell blocks | `c30NNN` cell blocks with high-res terrain textures | Megapack-indexed tile packs |

The Saboteur's world system is much more explicit about asset dependencies (each MAP6 entry lists its mesh count, texture count, etc.) compared to Mercs 2's opaque UCFX containers where we have to probe for GEOM/MESH/INFO chunks.

---

## 11. Endian Support

The Saboteur's toolset includes `FByteswapper` templates for every struct, plus magic checks for both LE and BE variants (e.g., `MP00`/`00PM`, `MESH`/`HSEM`). This confirms **PS3 support** was built into the engine at the format level, matching our observation that Mercs 2's PS3 EBOOT has the same structures.

---

## 12. Summary: Key Insights for Mercenaries 2 Work

### Confirmed findings

| Finding | Confidence | Impact |
|---------|------------|--------|
| Hash algorithm is identical (FNV-1a + `|0x20` + `^0x2A` finalization) | **100%** | Cross-validate our hash; use `saboteur_strings.txt` for pattern matching |
| `sges` compression is identical (same header, chunks, raw deflate) | **100%** | No further work needed on decompression |
| Vertex positions use half-float (f16) | **High** | Confirms our `f16_vec3` detection path is correct |
| Texture slot order: diffuse → specular → normal | **High** | Validates our MTRL parsing |
| Lua 5.1 bytecode across both games | **100%** | Same ChunkSpy approach works |
| `pandemic_hash_m2("animation") == 0x18166555` | **100%** | This is the magic value in our animgroup record table headers — confirms those records are typed by the hash of `"animation"` |

### Actionable improvements

1. **Parse `decl` chunks as vertex format bitfields.** The Saboteur's `format` field is a bitfield with `constTag=0x1B`. Our UCFX `decl` chunks may contain the same or similar bitfield. If we can decode it, we can replace all stride-guessing heuristics with exact vertex layout knowledge. Look for `0x1B` as the high byte of a u32 in our `decl` payloads.

2. **Use `saboteur_strings.txt` for hash resolution.** Many asset names are shared between games (vehicle names, weapon names, common shader names). Hashing the 50k+ Saboteur strings through `pandemic_hash_m2` and comparing against our unknown ASET hashes could resolve many mystery entries.

3. **Material preamble analysis.** The Saboteur's `WSAO` format suggests our 104-byte MTRL preamble likely contains shader hashes and default material properties (diffuse color, emissive, specular). We should compare the first 4-8 bytes of our MTRL preamble against hashes of known Saboteur shader names.

4. **Animation FSM search.** The Saboteur stores full state machine data (sequences, transitions, banks) alongside animations. Mercs 2 likely has similar data in undecoded UCFX chunks or in separate blocks. Look for `SEQC`, `TRAN`, `BANK`-like patterns in our raw block data.

5. **DLC pattern recognition.** The Saboteur's clean DLC system (folder + MAP6) suggests that Pandemic originally wanted a simpler approach. Our WAD overlay method may actually be closer to a debug/patching workflow that was formalized in The Saboteur.

### Format genealogy

```
Pandemic Engine Lineage (asset formats):

Mercenaries 1 (2005) — Zero Engine / Pebble
├── FNV-1a + |0x20 case suppression (NO finalization)
├── Unknown archive format
└── D3D8-era rendering

    ↓ (hash finalization added: ^0x2A * prime)

Mercenaries 2 (2008) — upgraded Pandemic engine
├── FNV-1a + |0x20 + ^0x2A * prime  ← CONFIRMED SAME
├── FFCS archives (INDX/DATA/CSUM/ASET/PTHS)
├── sges compression                  ← CONFIRMED SAME
├── UCFX containers (chunk-tagged binary)
├── f16 vertex positions              ← CONFIRMED SAME
├── Triangle strips + degenerate separators
├── MTRL/PRMT materials (inline)
├── Havok 5.5 animations
└── Lua 5.1 bytecode (in BINN/UCFX)

    ↓ (archive and mesh restructured, materials externalized)

The Saboteur (2009) — "WildStar" engine
├── FNV-1a + |0x20 + ^0x2A * prime  ← IDENTICAL
├── MP00 megapacks + SBLA sub-packs
├── sges compression                  ← IDENTICAL
├── Flat MESH format (no UCFX chunk tree)
├── f16 vertex positions + explicit format bitfield
├── Triangle lists only (no strips)
├── WSAO materials (external .materials files)
├── Havok animations (AP0L pack)
├── Lua 5.1 bytecode (in .luap)
└── MAP6 world descriptors + DLC/01 folder
```

---

## Appendix A: Source Files Analyzed

| File | Lines | Key structs/functions |
|------|-------|-----------------------|
| `include/hashstorage.hpp` | ~55 | `hash::GetHash()` — the hash function |
| `src/hashstorage.cpp` | ~90 | Hash string storage + collision detection |
| `hash/hash_string.cpp` | ~25 | CLI hash utility |
| `include/compressed.hpp` | ~95 | `SEGS`, `SEGSChunk`, `Extract()` — sges decompression |
| `include/megapack.hpp` | ~55 | `MP00`, `FileId`, `File`, `LoadMegaPack()` |
| `include/meshpack.hpp` | ~55 | `MSHA` — mesh archive wrapper |
| `mesh/mesh_to_gltf.cpp` | ~520 | Full MESH→glTF converter: `Stream`, `Primitive`, `Drawcall`, `MESHSkeleton`, vertex format map |
| `materials/materials_extract.cpp` | ~290 | `WSAO` material system: WSMA, WSTX, WSPA, WSST, WSCP, WSPP, WSVP |
| `animpack/anim_extract.cpp` | ~480 | `AP0L` animation pack: ANIM, SEQC, TRAN, BANK, SSP0, INTV, etc. |
| `luapack/luap_extract.cpp` | ~80 | `.luap` Lua bytecode archive |
| `megapack/megapack_extract.cpp` | ~65 | Megapack extraction |
| `globalmap/global_extract.cpp` | ~230 | `MAP6` + global asset extraction + DLC handling |
| `francemap/france_extract.cpp` | ~340 | France map + cinematic extraction + DLC detection |
| `tilepack/tilepack_extract.cpp` | ~215 | Tile pack extraction: HEI1 heightfield + SBLA tile packs |
| `texture/dtex_to_dds.cpp` | ~105 | DTEX→DDS texture converter |
| `loosefiles/loosefiles_extract.cpp` | ~45 | Loosefiles archive extractor |

## Appendix B: Cross-validation Test Vectors

```
Saboteur: hash::GetHash("ANY") == 3976557093 (0xED057225)
Mercs 2:  pandemic_hash_m2("ANY") == 0xED057225  ✓ VERIFIED MATCH

Saboteur: hash::GetHash("") == 0
Mercs 2:  pandemic_hash_m2("") == 0

Mercs 2:  pandemic_hash_m2("texture") == 0xF011157A
Mercs 2:  pandemic_hash_m2("model")   == 0x5B724250
```

These can be verified with:
```bash
.venv/bin/python3 tools/pandemic_hash.py --m2 --test 0xED057225 ANY
.venv/bin/python3 tools/pandemic_hash.py --m2 --test 0xF011157A texture
.venv/bin/python3 tools/pandemic_hash.py --m2 --test 0x5B724250 model
```
