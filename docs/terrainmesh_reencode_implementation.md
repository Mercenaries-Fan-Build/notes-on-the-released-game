# Terrainmesh (mesh_A / `0x7C569307`) Xbox 360 → PC re-encode — implementation

Implements the converged plan from `terrainmesh_reencode_investigation_A.md` and
`…_B.md`. The transform lives in `tools/wad_simulator/crates/ucfx_byteswap/src/convert.rs`,
gated on `type_hash == TYPE_HASH_TERRAIN_MESH (0x7C569307)`, in a new post-pass
`apply_terrainmesh_reencode` (runs last in `convert_container`, after the generic
body sweep, `apply_decl_translate`, and `apply_strm_vertex_fix`).

PC retail terrainmesh is a **genuine re-encode** (~+170 KB larger per mesh), not a
byte-swap. The pass rebuilds the container's data area chunk-by-chunk and reframes
every descriptor offset (PC bodies are contiguous, zero-gap, no alignment pad —
verified across the worked corpus, so a simple concatenation reproduces the shape).

## The DEC3N normal — pinned empirically

The Xbox 4-byte packed NORMAL/TANGENT is **11-11-10 signed-normalized** (the Xbox
360 `D3DDECLTYPE_DEC3N` / "HEND3N" variant), read from the raw big-endian u32:

```
X = sign_extend(bits[0:11])  / 1023        (11-bit signed)
Y = sign_extend(bits[11:22]) / 1023        (11-bit signed)
Z = sign_extend(bits[22:32]) / 511         (10-bit signed)
W = 1.0
```

then the vector is normalized and each component re-encoded to IEEE-754 binary16.

**Evidence.** Extracted 24,282 clean `(raw-Xbox-BE-u32 ↔ PC-FLOAT16_4)` NORMAL
pairs from the three worked terrainmeshes (`output/_scratch/terrain_A/`, scripts
`dec3n_extract.py` / `dec3n_solve3.py` / `dec3n_verify.py`). A per-axis brute force
over `(start, width, divisor, sign)` found this layout with per-axis RMS
≈ 0.0005. Worked decodes (raw BE u32 → unit normal):

| Xbox u32 | decoded normal | PC normal (f16) |
|---|---|---|
| `0x001ff007` | (0.0068, 1.000, 0.002) | (0.0076, 1.000, 0.0004) |
| `0x055ff007` | (0.0068, 0.999, 0.041) | (0.0077, 0.999, 0.0421) |
| `0x1c5c4659` | (−0.413, 0.883, 0.221) | (−0.4131, 0.8833, 0.2216) |

The decode is **geometry-correct, not byte-exact**: PC's FLOAT16_4 normals were
quantized from the original high-precision source mesh, so they differ from this
lossy-Xbox decode by ≤1–2 half-float ULP. Across all 42,712 NORMAL/TANGENT samples
the **mean angular error is 0.05°, max 0.124°** — the direction is reproduced to
well within lighting tolerance, but the exact half-float bytes are not invertible
from the lossy 4-byte Xbox value (confirmed: best byte-exact rate by any decode +
normalization combo is ≤2%). There was **no pre-existing DEC3N decoder** in the
repo (`grep -rn DEC3N tools/` → only a passing comment in `convert.rs`).

Implemented in `dec3n_to_half4_le` + `f32_to_f16_bits` (round-to-nearest-even,
matches `f32 as f16`). Unit tests: `dec3n_decodes_known_normals`,
`f16_encode_roundtrip_matches_std`.

## Per-chunk transforms

| chunk | transform | result |
|---|---|---|
| `decl`, `POFF`, GEOM `INFO` (clean words) | unchanged (already byte-exact) | **byte-exact** |
| STRM `info` (12B) | rewrite stride field: `pc_stride = be_stride + 4×(#FLOAT16_4 in decl)` | **byte-exact** |
| STRM `data` — POSITION (FLOAT16_4 @0) | undo the generic u32-swap = swap each u16 half | **byte-exact** |
| STRM `data` — FLOAT16_2 | same u16-half undo | **byte-exact** |
| STRM `data` — D3DCOLOR/UBYTE4 | copy the generic-swapped bytes verbatim (the generic u32-reverse already equals PC component order) | **byte-exact** |
| STRM `data` — NORMAL/TANGENT (FLOAT16_4) | DEC3N 4B → 8B widen (above) | **geometry-correct** (~0.05°), not byte-exact |
| IBUF `data` | de-strip: Xbox tri-strip w/ `0xFFFF` restart → tri-list (drop degenerates, alternating winding) | **geometry-correct**, not byte-exact |
| IBUF `info` (4B) | rewrite to the new (de-stripped) index count | follows the de-strip |
| MTRL | per-record count-pair walker (fix transposed `[count][0]`→`[0][count]`) | **engine-correct**, not byte-exact (PC also shrinks) |

`rebuild_terrain_vertices` drives the vertex widening off the (already
PC-translated) `decl`: position prefix (8B) + each declared element, emitting the
wider PC stride. `destrip_indices` does the strip→list expansion.
`mtrl_fix_transposed_counts` walks material records (stride `116 + count*4`, count
pair at `record+104`) and restores the count pair the generic `convert_mtrl` only
fixed for record 0.

### Verified per-offset agreement (worked asset `0xCA67E07B`, STRM #1, stride 20)

All 1073 vertices: offsets 0–7 (POSITION) and 8–11 (D3DCOLOR) are **100% byte-exact**;
**every** differing byte is confined to offsets 12–19 (the FLOAT16_4 normal), and
even the W-half (18–19) matches. STRM vertex buffers are 84% byte-exact overall
(the 16% is exactly the lossy normal field).

## Oracle results (before → after)

Whole-asset SHA (the oracle's pass/fail gate):

```
mesh_A:  400 PC-only / 0 compared   →   400 compared, 400 MISMATCH, 0 crashes/skips
```

The whole-asset count stays at 400 **mismatch** because three independent
proprietary codecs are inherently non-byte-exact (normals, index re-strip, MTRL
shrink), and the oracle compares the full payload SHA — so a single lossy byte
fails the whole asset. The real, measurable progress is **per-chunk**, on the three
worked assets (`output/_scratch/terrain_A/chunkdiff.py`):

| tag | n | size-eq (before→after) | byte-eq (before→after) | byte-agreement on size-eq |
|---|---|---|---|---|
| `decl` | 78 | 78 → 78 | 78 → 78 | 100% |
| `POFF` | 48 | 48 → 48 | 48 → 48 | 100% |
| `info` (STRM 12B + IBUF 4B) | 156 | 156 → 156 | 1 → **78** | 87.8% |
| `data` (STRM + IBUF) | 156 | **1 → 78** | 0 → 0 | STRM data **84.5%** byte-exact (rest = lossy normal) |
| `MTRL` | 3 | 0 → 0 | 0 → 0 | first-diff 236 → **568** (records 0–3 counts fixed) |
| `INFO` (32/44B) | 129 | 129 → 129 | 48 → 48 | 87.7% |

Container size (conv vs PC): `+183 KB` / `+120 KB` / `+178 KB` for the three assets —
larger than PC because the de-stripped triangle **list** carries more indices than
PC's single degenerate-stitched strip (see below). The output is structurally valid
(`--strict` validation passes, exit 0) and engine-loadable.

## What is byte-exact vs geometry-correct vs unsolved

- **Byte-exact:** `decl`, `POFF`, STRM `info` (stride), and the POSITION /
  FLOAT16_2 / D3DCOLOR vertex elements of STRM `data`.
- **Geometry-correct (not byte-exact):**
  - **NORMAL/TANGENT** — DEC3N decode is direction-correct to 0.05°; PC's exact
    half-floats come from the lost source-mesh precision (not invertible).
  - **IBUF indices** — a correct triangle list of the de-stripped geometry. PC
    instead emits a **single degenerate-triangle-stitched strip with a
    vertex-cache re-index** (the triangle *sets* don't even match: PC has fewer,
    re-indexed triangles). Reproducing PC byte-for-byte needs replicating its
    mesh-compiler stitch + cache optimizer (e.g. Forsyth / D3DXOptimizeFaces).
- **Engine-correct but not byte-exact:**
  - **MTRL** — the per-record count-pair transposition is fixed (records walk via
    stride `116 + count*4`); but PC additionally **drops sub-records / shrinks the
    body ~14.7 KB**, which is not reproducible from the Xbox data.

## Follow-ups / not done

- **PRMG/GEOM `INFO` (44B) count words** — words 4, 10 (and sometimes 7) are
  transposed `[u16][u16]` pairs (a real generic-u32-swap bug, value-preserved and
  field-fixable); words 0, 2, 3, 6, 9 are **geometry-recomputed counts** (e.g. the
  root INFO's 304→267) that depend on the non-byte-exact index re-encode and so
  can't be made byte-exact. Left as the generic u32 swap (engine-loadable) — fixing
  only the two clean u16-pair words yields no whole-chunk byte-exactness and adds
  risk, so it was deferred.
- **PRMT** — 20-byte draw-call records; PC drops/merges records (shrinks ~5 KB).
  Left as the existing u16 swap.
- **Index re-strip to match PC byte-for-byte** — would require the PC mesh
  compiler's stitch + vertex-cache re-index; out of scope (geometry-correct list
  is emitted instead).

## Reproduction

```
# build
cd tools/wad_simulator && cargo build --release -p ucfx_byteswap && cargo test -p ucfx_byteswap

# chunk-level diff on the worked assets (fast)
cd output/_scratch/terrain_A && python chunkdiff.py

# DEC3N pinning evidence
python dec3n_extract.py CA67E07B   # extract (BE u32 ↔ PC f16x4) normal pairs
python dec3n_solve3.py             # per-axis bit-layout brute force
python dec3n_verify.py             # byte-exact / angular-error survey

# full oracle (whole WAD; uses the main repo's game-files)
python tools/wad_be_le_oracle.py --converter rust --type 0x7C569307 --jobs 8 \
    --xbox-wad game-files/xbox-vz.wad --pc-wad game-files/vz.wad \
    --out-dir output/_scratch/rosetta_terrain_impl
```
