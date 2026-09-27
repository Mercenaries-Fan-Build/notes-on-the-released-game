# Ground cover format (`scrub`, `0x600B904E`) — PC retail

**Scope:** the byte format of the instanced ground-cover packages (grass, rocks, clutter) in PC retail
`vz.wad`, how they are placed, and how to keep them on the ground when a terrain cell is edited.
Written as an open specification. Companion to [`terrain_cell_format.md`](terrain_cell_format.md).

**Status:** layout PROVEN on all 1,026 retail containers (a decoder built from this spec re-encodes
every one byte-for-byte); field sizes and counts are the retail loader's own (§3). Fields marked
*not decoded* are carried verbatim. In-game behaviour of edited ground cover is **not verified**.

**Reference implementation:** `mercs2_formats::scrub` (wad_simulator workspace,
`crates/mercs2_formats/src/scrub.rs`), `placement::load_scrub_placements`, and the retail gates in
`crates/mercs2_formats/tests/scrub_retail.rs`.

## 1. Identification

| Property | Value | Confidence |
|---|---|---|
| UCFX `type_hash` | `0x600B904E` (`pandemic_hash_m2("scrub")`) | PROVEN |
| ASET `type_id` | 12; 1,026 rows in 261 blocks | PROVEN |
| Carrying block | usually its terrain cell's c3 block; the `vz_state_mar_city_ruined` ground cover is in c3 blocks that carry no terrain cell (`c34109`, `c34362`–`c34367`) | PROVEN |
| Placement | a `ScrubObject` COMP record `{u32 entity_key, u32 scrub_hash}` in `layers_static` or a `vz_state_*` layer, joined by key to the entity's `Transform` | PROVEN (1,043 records) |

## 2. Container

A UCFX container with the conventions of [`terrain_cell_format.md`](terrain_cell_format.md) §3
(20-byte rows `{tag, u0, size, x2, x3}`, bodies packed in row order, `CSUM` trailer). 6 retail
containers have no rows at all (28 bytes: header with `n = 0`, then `CSUM`). The other 1,020 have
exactly this tree:

```text
INFO                  16 B
SCRB × mesh_count     one instanced mesh each
  INFO                20 B
  MTRL                one material record
  STRM → info · decl · data
  IBUF → info · data
INST                  instance_count × 24 B
PTCH                  patch_count × 56 B
PTMS                  range_count × 8 B
```

### 2.1 `INFO` (16 B)

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | mesh_count — number of `SCRB` |
| 4 | `u32` | patch_count — `PTCH` records |
| 8 | `u32` | range_count — `PTMS` records |
| 12 | `u32` | instance_count — `INST` records |

### 2.2 `SCRB` mesh

- **`INFO` (20 B):** *not decoded* (two hash-like words, then `30.0` and `50.0` in the samples read, then 0).
- **`MTRL`:** exactly one material record in the terrain `MTRL` record layout
  ([`terrain_cell_format.md`](terrain_cell_format.md) §4.2): 120 bytes with one texture (3,733 meshes)
  or 128 bytes with three (267).
- **`STRM`:** `info {decl rows incl. terminator, stride, vertex_count}`, `decl` (`D3DVERTEXELEMENT9[]`
  + `D3DDECL_END`), `data`. Three declarations across the 4,000 retail meshes:

  | Stride | Elements (offset:type/usage) | Meshes |
  |---|---|---|
  | 24 | 0:F16x4/POS · 8:F16x4/TEX · 16:F16x4/NORMAL | 3,523 |
  | 28 | 0:F16x4/POS · 8:F16x4/TEX · 16:D3DCOLOR/COLOR · 20:F16x4/NORMAL | 210 |
  | 32 | 0:F16x4/POS · 8:F16x4/TEX · 16:F16x4/NORMAL · 24:F16x4/TANGENT | 267 |

- **`IBUF`:** `info {u32 index_count}`, `data` `u16` indices. Primitive type *not decoded*.

### 2.3 `INST` (24 B)

A 3 × 4 row-major affine matrix of IEEE half floats:

```text
[ r00 r01 r02 tx ]
[ r10 r11 r12 ty ]
[ r20 r21 r22 tz ]
```

The translation is relative to the owning patch's origin. In container `0x43E54D25` (7,760 instances)
the 3 × 3 part is a rotation about +Y times a uniform scale of 0.75–1.75.

### 2.4 `PTCH` (56 B)

| Off | Type | Field |
|---|---|---|
| 0 | `f32[3]` | origin — cell-local; the mean of the patch's instance translations is 0 |
| 12 | `f32[3]` | sphere centre (patch-local) |
| 24 | `f32` | sphere radius |
| 28 | `f32[3]` | box min (patch-local) |
| 40 | `f32[3]` | box max |
| 52 | `u16` | first `PTMS` range |
| 54 | `u16` | range count |

The box is the union of the patch's instances' transformed mesh vertices (within 1.6 cm of retail
across 30,972 patches; INFERRED cause of the residue: computed before the matrices were quantized to
f16). The sphere is the box's centre and half-diagonal (centre within 1.9e-6, radius within 3.8e-6).

### 2.5 `PTMS` (8 B)

| Off | Type | Field |
|---|---|---|
| 0 | `u32` | first instance |
| 4 | `u16` | instance count |
| 6 | `u16` | mesh — index of the `SCRB` the run instances |

## 3. Engine evidence

From the Ghidra decompilation of the unpacked retail `Mercenaries2.exe`:

- `FUN_004a4c40` (the container reader) reads `INFO` as the `SCRB`/`PTCH`/`PTMS`/`INST` counts and
  allocates `count × 0x1d0` (in-memory mesh record), `× 0x38`, `× 8` and `× 0x18` bytes for them.
- `FUN_004a53d0` copies `PTCH +0x0c..+0x1c` (4 floats) and `+0x1c..+0x34` (6 floats) into the patch's
  render object — the sphere and the box.
- `FUN_004a5670` walks a patch's ranges from `PTCH +0x34` (first) / `+0x36` (count), sums the `PTMS
  +4` counts, and converts each `INST` record's 3 × 4 halves to floats.
- `FUN_004a5830` (the draw) resolves `PTMS +6` as the `SCRB` index (`× 0x1d0` into the mesh records).

## 4. Frame and placement

Every `ScrubObject` placement sits at exactly a terrain tile's `TerrainObject` position, with identity
rotation (1,043/1,043). Instance *k* of patch *p* therefore sits at

```text
cell-local position = PTCH[p].origin + INST[k].translation
```

in the frame of that terrain cell. Measured over every placed container: 1,767,664 instances lie over
their cell's render surface with a median height above it of 0.000 m (1st percentile −0.236, 99th
0.135; 98.7 % within 25 cm — the rest are authored sunk or raised, e.g. half-buried rocks), and 19 lie
a few millimetres past the cell edge, over the neighbouring cell. Every non-empty container is placed;
17 `ScrubObject` records name a scrub hash `vz.wad` does not carry.

**Pair a container with its cell through its placement, not its block.** The ruined-city ground
cover is stored in blocks without a terrain cell yet sits on a cell like the rest.

## 5. Following an edited cell

When a cell's heights change (see [`terrain_cell_format.md`](terrain_cell_format.md) §6), every
container placed on it must follow:

1. For each instance, find the cell's render triangles (every draw group) under its cell-local XZ, and
   take the one whose height there is nearest the instance's height — the surface it stands on.
2. Move the instance's `ty` by that triangle's height change at the same barycentric point. The
   authored height above the ground is kept.
3. Recompute the box and sphere of every patch with a moved instance (§2.4).
4. An instance past the cell edge stands on the neighbour, whose ground an edit that keeps the edge
   fixed does not change: leave it. An instance **inside** the cell with no triangle under it cannot be
   placed — refuse the edit.

On the PMC HQ pyramid (40 m, `0xA241BC0C`) this moves 1,819 instances across the 6 containers placed
on the cell and re-bounds 57 patches; the height above the re-selected surface is kept to a median of
0.000 m (99th percentile 7 mm). Where two draw groups overlap (ground and road) their triangulations
of the pyramid differ, so the height above the *other* surface can change by up to 1.18 m there.

## 6. Verification

```
cargo test -p mercs2_formats --test scrub_retail -- --nocapture
```

| Gate | Result |
|---|---|
| decode → encode of every container | 1,026/1,026 byte-identical (6 empty); typed decode reflexive |
| patch bounds (§2.4) | box within 1.6 cm of transformed meshes; sphere = box centre + half-diagonal |
| placement frame (§4) | 1,043 placements on cell centres; instances on their cell's surface (median 0.000 m) |
| HQ pyramid (§5) | 1,819 instances moved, 57 patches re-bounded, edited containers re-parse |
