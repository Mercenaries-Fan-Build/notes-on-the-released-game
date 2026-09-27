# Terrain cell format (`terrainmesh`, `0x7C569307`) — PC retail

**Scope:** the byte format of the 400 hi-res terrain cells in PC retail `vz.wad`, what an encoder must
keep true when it edits one, and how the cell's collision relates to its render mesh. Written as an open
specification: everything below is enough to read and write a cell without any other tool.

**Status:** layout PROVEN on all 400 retail cells (a decoder built from this spec re-encodes every one
byte-for-byte). Fields marked *not decoded* are carried verbatim; nothing here guesses their meaning.
In-game behaviour of an edited cell is **not verified** — no edited cell has been loaded by the game.

**Reference implementation:** `mercs2_formats::terrainmesh` (wad_simulator workspace,
`crates/mercs2_formats/src/terrainmesh.rs`) and its retail gates in
`crates/mercs2_formats/tests/terrainmesh_retail.rs`. Companion docs:
[`terrainmesh_reencode_implementation.md`](terrainmesh_reencode_implementation.md) (the Xbox→PC
converter for the same asset), [`reverse_engineer/terrain_collision_regeneration.md`](reverse_engineer/terrain_collision_regeneration.md)
(the collider), [`reverse_engineer/mopp_bytecode_format.md`](reverse_engineer/mopp_bytecode_format.md)
(the MOPP bytecode), [`ucfx_tag_registry.md`](ucfx_tag_registry.md) §2 (UCFX conventions).

## 1. Conventions

- All integers and floats are **little-endian**. `f16` is IEEE-754 binary16; `f32` binary32.
- Coordinates are native game space (left-handed, +Y up, metres). No axis flips anywhere.
- *Patch-local* = as stored in a vertex. *Cell-local* = patch-local + the patch's `POFF`. *World* =
  cell-local + the cell's placement (§2).

## 2. Identification and placement

| Property | Value | Confidence |
|---|---|---|
| UCFX `type_hash` | `0x7C569307` (`pandemic_hash_m2("terrainmesh")`) | PROVEN |
| ASET `type_id` | 32; exactly 400 rows in PC `vz.wad` | PROVEN (400/400) |
| Carrying block | a c3 cell block (e.g. `blocks\VZ\c31411_P000_Q3.block`), alongside one terrain texture and several `scrub` (`0x600B904E`) ground-cover packages | PROVEN (example) |
| Placement | a `TerrainObject` COMP record `{u32 entity_key, u32 terrainmesh_hash}` in `layers_static`, joined by key to the entity's `Transform` in the same sub-block. Every record has one: across all 747 `layers_static` / `vz_state_*` layers, 400/400 `TerrainObject` (and 1,043/1,043 `ScrubObject`) records join, counted against the raw COMP records | PROVEN (400/400) |
| Grid | 20 × 20 cells of 400 m. Every tile sits at `(-3800 + 400·col, 0, -3800 + 400·row)` with identity rotation; 396 carry the entity name `Terrain_rRR_cCC 0`, 4 carry an empty name and sit on the same grid | PROVEN (400/400) |

Worked example: the PMC HQ (2647, 10, -951) lies in `Terrain_r07_c16`, terrainmesh `0xA241BC0C`, centre
(2600, 0, -1000).

**There is no heightmap.** The ground is a triangle mesh (§5) and the collider is a Havok
`WpMeshShape16` + MOPP (§8). Zero sampled-heightfield shapes are serialized anywhere in `vz.wad`
([`terrain_collision_regeneration.md`](reverse_engineer/terrain_collision_regeneration.md) §1).

## 3. Container

A cell is one UCFX container:

```text
+0   "UCFX"
+4   u32 data_off      = 20 + 20·n
+8   u32 0
+12  u32 0
+16  u32 n             descriptor row count
+20  n × row {tag[4], u32 u0, u32 size, u32 x2, u32 x3}
data_off …             leaf bodies
end-8  "CSUM" u32 crc  CRC-32 (poly 0xEDB88320, init 0, no final XOR) of every byte before "CSUM"
```

Rows are the pre-order flattening of a tree:

- **Container row:** `u0 = 0xFFFFFFFF`, `size = 0`, `x3` = number of descendant rows (its whole
  subtree). Its children are the rows that follow, consuming exactly `x3` rows.
- **Leaf row:** body at `data_off + u0`, `size` bytes, `x3 = 0`.
- **`x2`** = the row's reverse ordinal among its siblings (last sibling 0).

In every retail cell the leaf bodies are **packed in row order**: the first leaf at `u0 = 0`, each
next leaf at the previous leaf's `u0 + size`, no gaps, no alignment padding, and the last body ends
exactly at the `CSUM` trailer. (PROVEN 400/400.) An encoder that keeps this rule reproduces retail
byte-for-byte.

## 4. Tree

```text
INFO                 root info (32 B)
MTRL                 materials
GEOM × 16            one per 100 m patch
  INFO               patch info (44 B)
  POFF               patch offset (12 B)
  PRMG × k           draw groups, k = patch INFO word 0
    INFO             draw-group info (44 B)
    PRMT             draw records
    STRM
      info           12 B
      decl           vertex declaration
      data           vertices
    IBUF
      info           4 B
      data           indices
PHY2                 collider
```

The order is fixed: exactly these tags, in exactly this order, in all 400 cells.

### 4.1 Root `INFO` (32 B)

| Off | Type | Field | Notes |
|---|---|---|---|
| 0 | `f32[3]` | min | cell-local box |
| 12 | `f32[3]` | max | |
| 24 | `u32` | material_count | = number of `MTRL` records (PROVEN 400/400) |
| 28 | `u32` | geom_count | = number of `GEOM`s; 16 in every cell |

The box is **exactly** the union over patches of `patch box + POFF` (float-equal, 400/400).

### 4.2 `MTRL`

`material_count` records, then `material_count` blocks of 256 bytes.

Record (stride `116 + 4·tex_count`):

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | word 0 — *not decoded*; not a float (read as one it takes values like `-8.8e17`, `3.2e37`) |
| 4 | `f32[25]` | parameters — *not decoded* |
| 104 | `u16` | flags (0 or 128 in retail) |
| 106 | `u16` | tex_count (1…10) |
| 108 | `u32[tex_count]` | texture hashes; `0xA3CD72A7` separates detail layers |
| 108 + 4·tex_count | `u32[2]` | tail — *not decoded* |

The 256-byte blocks (64 words each) follow the last record; their count equals `material_count` in
every cell (PROVEN 400/400). Contents *not decoded*.

### 4.3 `GEOM` patch

**`INFO` (44 B):**

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | prmg_count — number of `PRMG` children |
| 4 | `f32[3]` | sphere centre (patch-local) |
| 16 | `f32` | sphere radius |
| 20 | `f32[3]` | box min (patch-local) |
| 32 | `f32[3]` | box max |

The sphere is the box's centre and half-diagonal: across all 6,400 retail patches the centre agrees
to 3.8e-6 and the radius to 1.5e-5 (f32 rounding). A retail box can sit up to one f16 step inside the
stored vertex positions (INFERRED cause: computed before the positions were quantized to f16).

**`POFF` (12 B):** `f32[3]` patch offset. The 16 patches of a cell use x, z ∈ {−150, −50, 50, 150} —
every combination once — and y = 0 (PROVEN 400/400). A cell therefore spans ±200 m cell-local.

### 4.4 `PRMG` draw group

**`INFO` (44 B):**

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | draw_count — the first `draw_count` `PRMT` records |
| 4 | `u32` | alt_draw_count — the remaining records |
| 8 | 3 × 12 B | pass groups `{u32 draw_count, u16, u16, u16 alt_draw_count, u16 index}` |

Across all 8,859 retail draw groups: the pass groups' `draw_count`s sum to word 0, their
`alt_draw_count`s (always 1) sum to word 1 (always 3), and `index` is the group's position 0, 1, 2.
The two middle `u16`s are *not decoded*.

**`PRMT`:** `(draw_count + alt_draw_count)` records of 20 bytes:

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | hash — *not decoded* (a small set recurs across cells) |
| 4 | `u32` | *not decoded* |
| 8 | `u32` | start_index into the `IBUF` |
| 12 | `u16` | prim_count |
| 14 | `u16` | min index |
| 16 | `u16` | max index |
| 18 | `u16` | *not decoded* |

min/max equal the smallest/largest index in the draw's range for 130,049 of the 130,224 retail draws.
The alternate draws are all hash `0xA9EA4CF7`.

**`STRM`:**

- `info` = `{u32 decl_rows, u32 stride, u32 vertex_count}`, where `decl_rows` counts the terminator.
- `decl` = `D3DVERTEXELEMENT9[]` `{u16 stream, u16 offset, u8 type, u8 method, u8 usage, u8 usage_index}`,
  terminated by `D3DDECL_END` (`FF 00 00 00 11 00 00 00`). `stride` equals the extent of the declared
  elements.
- `data` = `vertex_count × stride` bytes.

**`IBUF`:** `info` = `{u32 index_count}`; `data` = `index_count × u16`.

## 5. Geometry

### 5.1 Vertex declarations

Retail carries four declarations (usage: 0 POSITION, 3 NORMAL, 5 TEXCOORD, 6 TANGENT, 10 COLOR; type:
4 D3DCOLOR, 15 FLOAT16_2, 16 FLOAT16_4):

| Stride | Elements (offset:type/usage) | Draw groups |
|---|---|---|
| 20 | 0:F16x4/POS · 8:D3DCOLOR/COLOR · 12:F16x4/NORMAL | 6,400 — the **ground**, exactly one per patch |
| 20 | 0:F16x4/POS · 8:F16x2/TEX · 12:F16x4/NORMAL | 15 |
| 28 | 0:F16x4/POS · 8:F16x2/TEX · 12:F16x4/NORMAL · 20:F16x4/TANGENT | 692 |
| 32 | 0:F16x4/POS · 8:F16x2/TEX · 12:D3DCOLOR/COLOR · 16:F16x4/NORMAL · 24:F16x4/TANGENT | 1,752 |

Read the layout from `decl`, never from the stride. POSITION and NORMAL are always `FLOAT16_4` on
stream 0; positions are patch-local. The ground group is not always the first `PRMG` of its patch.

### 5.2 Triangle strips — one per draw

Indices are **D3D triangle strips**. Each draw covers `[start_index, start_index + prim_count + 2)`
and is its own strip: triangle *i* of the range is `(s[i], s[i+1], s[i+2])` for even *i* and
`(s[i], s[i+2], s[i+1])` for odd *i*, **counting from the draw's start**. Triples with a repeated
index are the degenerate stitches that join runs, and draw nothing.

Consequences an implementation must respect:

- **Do not destrip a whole `IBUF` as one strip.** The draws are separate strips; one pass over the
  buffer invents junction triangles and flips the winding of every draw that starts on an odd index.
- **Index slots no draw references are not drawn** and must be carried verbatim. In a 40-cell sample,
  556 draw groups had such slots and 400 of them held only zeros there.
- The same triangle is drawn by several draws (layered passes and the alternate draws). The
  geometry of a draw group is the set of distinct triangles over all its draws.
- There is no `0xFFFF` primitive restart on PC.

With winding taken this way, ground triangles face up and the retail normals follow
`(b − a) × (c − a)` (§5.3).

### 5.3 Normals and tangents

A NORMAL's xyz halves are a unit direction; its w half is carried. On cell `0xA241BC0C`'s ground,
the per-draw-group area-weighted sum of incident face normals `(b − a) × (c − a)` reproduces the
stored normals to a median of 0.96° (90th percentile 6.1°). They are not an exact function of the
stored triangles (INFERRED: baked from finer source geometry). Vertices are duplicated at creases, so
welding by position across a draw group smooths away edges that retail keeps hard.

A TANGENT (28- and 32-byte decls) is `xyz` = the per-draw-group sum of the incident triangles'
texture-u gradients `∂P/∂u`, made orthogonal to the normal (Gram–Schmidt) and normalized, and `w` =
+1 when `(n × t) · ∂P/∂v < 0`, −1 when `> 0`. On `0xA241BC0C` this reproduces the stored tangents to
a median of 0.33° (90th percentile 0.92°) and `w` on 14,484 of the 14,520 vertices where
`(n × t) · ∂P/∂v ≠ 0` (2 vertices have it exactly 0, where the handedness is not defined by the
geometry).

### 5.4 Cell edges

A cell's footprint is ±200 m cell-local. Ground vertices on the edge line coincide with the
neighbour's edge vertices: on the PMC HQ cell's four edges, 89–98 samples per edge sit at the same
along-edge position in both cells with heights equal to within one f16 step, and 0–6 samples per edge
exist on one side only (retail T-junctions). Moving an edge vertex in one cell without its twin in
the neighbour opens a crack.

## 6. Editing rules

An encoder that changes a cell must keep:

1. **Every derived word** — `x2`, `x3`, `data_off`, all counts (`material_count`, `geom_count`,
   `prmg_count`, PRMG `INFO` words 0/1, `STRM info`, `IBUF info`) — consistent with the tree.
2. **Packed bodies** and a recomputed `CSUM`.
3. **Bounds:** patch box ⊇ its vertices; sphere = box centre + half-diagonal; root box = union of
   `patch box + POFF`.
4. **Normals and tangents** consistent with moved geometry (§5.3).
5. **Cell edges** fixed, or edited together with the neighbour.
6. **Collision** rebuilt when the ground moves (§8) — the MOPP partitions on triangle bounds, so even
   a pure height edit needs a re-bake.

A vertical edit (move POSITION.y only) changes no topology: `PRMT`, `IBUF`, `decl` and every vertex
byte other than POSITION.y, NORMAL.xyz and TANGENT stay as they are. Moving every draw group, not only the ground,
keeps overlays (roads, decals) on the ground.

## 7. What moves with the ground and what does not

**Ground cover** (`scrub`, `0x600B904E`) is instanced in the cell's cell-local frame and must be moved
with the ground: see [`scrub_ground_cover_format.md`](scrub_ground_cover_format.md). A container is
paired with its cell by its `ScrubObject` placement (which sits exactly on the cell's `TerrainObject`
position), not by the block it is stored in.

**World entities** placed by `layers_static` / `vz_state_*` `Transform` records are independent of the
cell and do not follow a terrain edit: an entity standing on ground that is raised ends up buried, and
one on ground that is lowered floats. The PMC HQ pyramid example (§9) has 36 placements in its
footprint (rocks, a `Road` entity, outpost walls and lampposts, mission vehicles and path nodes); they
stay where they are.

## 8. `PHY2` — the collider

```text
+0   12 × u32 prefix  [0x39, cell hash, 2, 1, 1, 0, 0, collision vertex count, packfile size, 0, 0, 0]
+48  Havok 5.5 packfile (magic 57 E0 E0 57 10 C0 C0 10)
…    engine wrapper (Pandemic runtime-object snapshot; pointers are PHY2-body-absolute offsets)
```

Every retail prefix has exactly this form (PROVEN 400/400). Word 2 is 2 in every cell while each cell
carries **one** shape, so it is not a shape count; its meaning is *not decoded*.

Every retail cell's packfile holds one `WpArray` → one `hkpMoppBvTreeShape` → {`hkpMoppCode`,
`WpMeshShape16`} (400/400), in cell-local coordinates (vertices span ±200 m). The retail collision mesh
is **not** the render mesh: on `0xA241BC0C` it has 8,669 vertices and 16,995 triangles, and 981 of its
8,093 distinct positions (rounded to 0.1 m) have no render vertex there (INFERRED: built from different
source geometry). Across the 400 cells the largest collider has 30,106 triangles and the most vertices
are 14,955.

A collider rebuilt from the render triangles keeps the retail shape count: the reference
implementation welds every draw group of the cell into one soup and bakes one `WpMeshShape16` + MOPP
through `phy2_build::build_phy2_multi_hashed`, keyed by the cell hash. A whole cell's MOPP is well past
64 KiB (the largest retail rebuild is 81,619 triangles, a 1.76 MB `PHY2`), so its split offsets need
the JUMP24 trampoline described in
[`reverse_engineer/mopp_bytecode_format.md`](reverse_engineer/mopp_bytecode_format.md). The rebuilt
collider re-parses, its MOPP walk reaches every byte and yields every triangle key once, and a query at
each triangle's box returns that triangle (no-miss, 32,618 queries on the edited HQ cell). Whether the
game accepts a rebuilt terrain collider is **not verified in game**.

## 9. Verification

With the game (`MERCS2_GAME_DIR` = install root, `data` folder, or `vz.wad`), from the wad_simulator
workspace:

```
cargo test -p mercs2_formats --test terrainmesh_retail -- --nocapture
```

| Gate | Result |
|---|---|
| decode → encode of every cell | 400/400 byte-identical; typed decode reflexive |
| layout invariants (§3–§4) | hold on all 400 cells / 6,400 patches / 8,859 draw groups |
| every draw strip → triangles → strip → triangles | 130,224 draws, 27,310,164 triangles, winding preserved |
| normal convention (§5.3) | median 0.96°, p90 6.1° on `0xA241BC0C` ground |
| edges vs neighbours (§5.4) | HQ cell: within one f16 step on all 4 edges |
| 40 m pyramid on `0xA241BC0C` (base half-width 60 m, apex at cell-local (−120, −120)) | 1,706 vertices moved (1,975 re-normalized, 480 re-tangented), apex −13.125 → 26.875 m, edge untouched, container re-parses |
| tangent convention (§5.3) | median 0.33°, p90 0.92°; `w` 14,484/14,520 on `0xA241BC0C` |
| rebuilt collider, HQ cell edited | one shape; re-parses; MOPP no-miss over all 32,618 edited triangles |
| rebuilt collider, every cell | 400/400 one-shape colliders rebuild and re-parse (largest soup 81,619 triangles / 35,790 vertices) |
