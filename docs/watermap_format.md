# Watermap (`0x4D7D30C4`) / `watr` Chunk

**Verified:** retail PC `blocks\VZ\resident_P000_Q3.block` (2026-05-30)  
**Tools:** `tools/watermap_probe.py`, `tools/watermap_decode.py`

---

## Location

| Field | Value |
|-------|-------|
| type_hash | `0x4D7D30C4` (`pandemic_hash_m2("watermap")`) |
| ASET entries | 1 (singleton) |
| Block | `resident_P000_Q3` |
| UCFX | Single chunk tag `watr`, ~495,669 bytes |

---

## `watr` layout

| Offset | Size | Type | Field | Status |
|--------|------|------|-------|--------|
| +0 | 4 | u32 | `layer_count` (= 5) | confirmed |
| +4 | 4 | u32 | `grid_width` (= 257) | confirmed |
| +8 | 4 | u32 | `grid_height` (= 257) | confirmed |
| +12 | 4 | f32 | `cell_size_m` (= 32.0) | confirmed |
| +16 | 4 | f32 | `height_min_m` (= -50.0) | confirmed |
| +20 | 4 | f32 | `height_max_m` (~325.26) | confirmed |
| +24 | 4 | f32 | `field_b` (= 64.0) | unknown |
| +28 | 4 | f32/u32 | `field_c` (= 0) | unknown |
| +32 | 4 | f32/u32 | `field_d` (= 0) | unknown |
| +36 | 264,196 | f32[66049] | **Layer 0 — height (m)** | confirmed |
| +264,232 | 66,049 | u8[66049] | **Layer 1 — wet mask** | confirmed |
| +330,281 | 66,049 | u8[66049] | **Layer 2 — coastal variant** | hypothesis |
| +396,330 | 66,049 | u8[66049] | **Layer 3 — sparse override** | hypothesis |
| +462,379 | 33,290 | — | **Layer 4 — footer blob** | confirmed size |

**Size check:** `36 + 66049×4 + 66049×3 = 462,379` + footer `33,290` = **495,669** bytes.

`layer_count = 5` is the count of logical layers above (height + 3 grids + footer), not five same-sized rasters.

---

## Layer semantics

### Layer 0 — height (f32)

- Metres in game **Y-up** space.
- **Dry cells:** often exactly **-50.0** (matches `height_min_m`).
- **Wet cells:** plateau near **-36.0** m (open water surface in the watermap).
- Inland water and bathymetry use values between these extremes (max ~325 m on retail).

### Layer 1 — wet mask (u8)

| Value | Meaning | Status |
|-------|---------|--------|
| `0` | Dry / land | confirmed |
| `255` | Wet / water column | confirmed |

Cell counts on retail: ~27,973 dry, ~38,070 wet.

### Layers 2–3

Mostly `255` with sparse other bytes at shores and isolated cells. Likely coastal/shore typing and per-cell overrides — **not confirmed** in EXE.

### Footer (33,290 B)

Does not divide `257×257`; not a height/mask grid. Starts with `0xFFFFFFFF` then packed floats/bytes — purpose **unknown** (flow table, indices, or engine-only metadata).

---

## World extent mapping

| Quantity | Value | Status |
|----------|-------|--------|
| Sample grid | 257 × 257 | confirmed |
| Cell size | 32 m | confirmed (header) |
| Span (256 intervals) | 8192 m × 8192 m on X/Z | confirmed |
| Game coord coverage | ≈ ±4096 m (centred grid — **origin alignment unverified**) | partial |
| Playable bbox (AGENTS.md) | X/Z ≈ ±3900 m | reference |

**Index → game XZ (hypothesis until EXE documents origin):**

```
x = (ix - (grid_width  - 1) / 2) * cell_size_m
z = (iz - (grid_height - 1) / 2) * cell_size_m
y = height[iy * grid_width + ix]
```

**Sea level in this asset:** wet-surface height ≈ **-36 m** (not terrain Y=0 open-water tiles).

---

## UE5 (`setup_water.py`) constants

| Constant | Current value | `watr` tie-in |
|----------|---------------|---------------|
| `OCEAN_HALF_M` | 5000 | OK margin over 4096 m half-span |
| `WORLD_BBOX_HALF_M` | 4000 | Matches playable ±3900 m |
| `SEA_LEVEL_UE` | -2500 (empirical) | **Not calibrated** to -36 m game height |

**Next step for raster-driven water:** sample layer 0 + mask 1 → spawn `WaterBodyOcean` / custom mesh; map game Y to UE Z via `game_to_ue` (100×, swap Y↔Z). Calibrate ocean Z against a known coastal placement + wet-cell height.

---

## Extraction

```bash
.venv/Scripts/python tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --path "blocks\VZ\resident_P000_Q3.block"

.venv/Scripts/python tools/watermap_decode.py --wad game-files/pc-game-vz.wad \
  --out output/watermap_decode.json --png
```

PNG exports (16-bit): `output/_scratch/watermap/layer00_height_u16.png`, `layer01..03_mask_u8_stretched.png`.
