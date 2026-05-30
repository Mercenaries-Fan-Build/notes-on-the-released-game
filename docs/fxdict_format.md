# fxdict and effect binary formats

**Date:** 2026-05-30  
**Status:** Partial decode from retail PC `vz.wad` (resident + effects blocks)  
**Tools:** `tools/fxdict_parser.py`, `tools/effect_block_probe.py`, `tools/fxdict_codec.py`

---

## 1. Asset locations (ASET-verified)

| Asset | type_id | type_hash | ASET count | Block file | Block entry table |
|-------|---------|-----------|------------|------------|-------------------|
| **fxdict** | 25 | `0xFA46D8A8` | 1 | `blocks\VZ\resident_P000_Q3.block` | 1× fxdict in resident |
| **effect** | 29 | `0x5608BD5A` | 314 | `blocks\VZ\effects_P000_Q3.block` | 314× effect + 46× mesh (`0x5B724250`) |

**Correction:** Earlier notes placed fxdict inside the effects block file. ASET points to the **resident** singleton. The effects block holds all particle definitions; they share the global dictionary loaded from resident.

- fxdict asset hash = `pandemic_hash_m2("fx")` = **`0x86BF6C5B`**
- Retail probe: resident entry index **5889**, body **12 672** bytes (2026-05-30)

Extraction (single-block policy):

```bash
.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --path "blocks\VZ\resident_P000_Q3" \
  --keep --scratch-root output/_scratch/fx_probe

.venv/Scripts/python.exe tools/extract_single_block.py \
  --wad game-files/pc-game-vz.wad \
  --path "blocks\VZ\effects_P000_Q3" \
  --keep --scratch-root output/_scratch/fx_probe
```

---

## 2. Block file envelope

Same as other VZ blocks (`docs/format_reference.md`):

```
u32 entry_count
entry_count × 16 bytes: asset_hash, type_hash, reserved, payload_size
payloads packed sequentially (each payload is usually UCFX + CSUM in archive;
decompressed .block.bin strips CSUM wrapper per entry)
```

---

## 3. fxdict UCFX container

### 3.1 Chunk table

Standard UCFX header (`dao` + chunk count) with **two** leaf chunks on retail:

| Chunk | rel_off | Typical size | Role |
|-------|---------|--------------|------|
| **INFO** | 0 | 4 | `u32 entry_count` |
| **DICT** | 4 | `entry_count × 20` | Parameter records |

Verified retail: **630** entries, **12 600** DICT bytes, zero trailing slack.

### 3.2 DICT record (20 bytes) — **~85% confidence**

| Offset | Type | Field | Notes |
|--------|------|-------|-------|
| +0x00 | `u32` | `name_hash` | Parameter key; referenced from effect `TEXT` / overrides (not always in rainbow table) |
| +0x04 | `f32` | `default` | Default scalar value |
| +0x08 | `f32` | `value_b` | Likely **max** bound (~0.3–0.9 on samples) — **hypothesis** |
| +0x0C | `f32` | `value_c` | Often **`0.03125` (1/32)** — likely **min** bound — **hypothesis** |
| +0x10 | `u32` | `flags` | Unknown; values like `0x3CF40017`, `0x3D000000` |

**Not verified:** Original C++ field names (`RedEffect`); string names for `name_hash` are not in `tools/rainbow_table.json` (path/asset oriented).

### 3.3 JSON output

`tools/fxdict_parser.py` writes:

- `entry_count`, full `parameters[]` with hashes and floats
- `top10_by_default_magnitude` with Niagara mapping **hypotheses**
- Per-row `resolved_names` from rainbow table when present

Default path: `output/_scratch/fx_probe/fxdict.json`

---

## 4. effect UCFX container — **~70% confidence**

Each of the **314** effect payloads is a UCFX container. Chunk sets are mostly consistent; first retail effect (`asset_hash 0xFE62017A`) includes:

| Chunk | Payload size | Header hints | Probable role |
|-------|--------------|--------------|---------------|
| **EFCT** | 18 | — | Effect header (version/type, emitter count guess at +4) |
| **EMTR** | 2 | `u2=9`, `u3=2` | Emitter table metadata (counts in header) |
| **EMIT** | 0 | `u2` = 1–7 typical | Emitter count / spawn slots (**histogram verified**) |
| **GEOM** | 4 | — | Unknown index / LOD hook |
| **TRFM** | 64 | — | 4×4 row-major `f32` transform |
| **ATRB** | 12 | — | Render/blend attribute scalars |
| **PTYP** | 4 | `u2` particle type | Particle class id |
| **ANIM** | 4 | `u3=4` | Animation driver |
| **AKEY** | 8 | — | Animation keys |
| **COLR** | ~800 (varies) | 16-byte stride | Color over life (~50 keys when 800 B) — **layout hypothesis** |
| **TEXT** | ~260 | leading `u32` | Texture / param hash list (`u32` after first word) |
| **FRCE** | 20 | — | Force / acceleration |

Effect-specific tags also referenced in `tools/ucfx_be_to_le.py`: `PTYP`, `COLR`, `TEXT`, `FRCE`, `ANIM`, `AKEY`, `ATRB`, `TRFM`, `EFCT`, `EMTR`.

### 4.1 TEXT chunk — **~75% confidence**

- First `u32` often `0x40` (64) — may be count or byte length (**hypothesis**).
- Following words are **`u32` asset hashes** (texture or fxdict parameter hashes).
- Cross-check: `0x8410A32A` appears in both fxdict DICT row 9 and effect0 `TEXT` — parameter/texture hash namespace is shared.

### 4.2 COLR chunk — **~50% confidence**

- Stride **16 bytes** per key when `len % 16 == 0`.
- Bytes look like **BGRA-ish** color stops with time; exact field order not confirmed.

---

## 5. UE5 mapping (downstream)

| Game | UE5 target |
|------|------------|
| fxdict 630 floats | `UNiagaraParameterCollection` or DataTable `FX_ParamDefaults` |
| effect 314 defs | `UNiagaraSystem` per `asset_hash` |
| TEXT hashes | Soft object paths to textures (after PNG extract) |
| placements `particle` / `fx_` | `ANiagaraActor` via future `populate_effects.py` |

See [`audio_ue5_path.md`](audio_ue5_path.md) §2.

---

## 6. Confidence summary

| Area | Confidence |
|------|------------|
| ASET block locations (resident vs effects) | **High** |
| fxdict INFO `u32` count + DICT `20×count` | **High** |
| DICT `default` / `value_b` / `value_c` as three `f32` + `flags` | **Medium–high** |
| DICT `value_b`/`value_c` semantics (max/min) | **Hypothesis** |
| Parameter string names | **Low** (hash-only) |
| effect per-chunk field map | **Medium** (tags + sizes; few payloads fully semantic) |
| COLR key structure | **Low–medium** |

---

## 7. Related docs

- [`type_hash_registry.md`](type_hash_registry.md) — type hashes
- [`format_reference.md`](format_reference.md) — UCFX chunk header layout
- [`audio_ue5_path.md`](audio_ue5_path.md) §2 — Niagara conversion plan
