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

## 4. effect UCFX container

**Specified in [`effect_container_format.md`](effect_container_format.md)**, measured against all
314 retail effects (each re-encodes byte for byte; the computed `EFCT` equals the stored one in
314/314). The container flattening is in [`ucfx_tree_container.md`](ucfx_tree_container.md).
Summary:

- One tree rooted at `EFCT` (18 B, nine u16, computed). Children: `EMTR` (u16 = GEOM child count;
  each `GEOM` = u32 k + k × 13 f32), then one (`EMIT` marker, `PTYP`) pair per emitter, then the
  `FRCE`s.
- `EMIT` → `TRFM` (64 B 4×4) with the nine channel `ATRB`s (`posx`…`sclz`), and an optional
  `GEOM` (u16 shape index, u16).
- `PTYP` (u32 flags; bits 0/1 read) → 19 `ATRB`, `COLR`, 13 `ATRB`, `TEXT`, in a fixed order.
- `ATRB` (12 B `{u32 hash, u32 flags, u32|f32 value}`) may own `ANIM` (u32 key count) → `AKEY`
  × n (8 B `{f32 time, f32 value}`). `ANIM` and `AKEY` exist; 1,880 retail curves.
- `COLR` is **800 bytes** = 100 × `{u8×4 colour, binary16, u16 0}`. (The 200 the loader stores is
  the stream-word reservation, not the byte size.)
- `TEXT` = u32 n + n texture hashes (`4 + 4n` bytes in every retail TEXT).
- `FRCE` = u32 kind (`gravity`, `drag`, `wind`, `attractor`, `vortex` — all `pandemic_hash_m2`
  of the name) + 16 / 4 / 16 / 28 / 56 bytes of parameters, then the force's `ATRB`s.
- No retail effect contains `POFF`.

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
| effect tree, sizes and EFCT rule | **High** — 314/314 byte-identical re-encode ([`effect_container_format.md`](effect_container_format.md)) |
| COLR key structure (100 × 8 B) | **High** for the layout; colour channel order and the binary16's role unknown |

---

## 7. Encoder (Rust, native)

[`mercs2_formats::fxdict`](../tools/wad_simulator/crates/mercs2_formats/src/fxdict.rs) reads and
writes both containers.

**fxdict:** `parse_fxdict` / `parse_fxdict_container` and `write_fxparam` / `write_fxdict_dict` /
`write_fxdict_info` / `write_fxdict_container`. The container is two top-level leaves, `INFO`
(`x2 = 1`) then `DICT` (`x2 = 0`). The retail container re-encodes byte for byte.

**effect:** `parse_effect_container(&[u8]) -> Result<EffectContainer, String>` and
`write_effect_container(&EffectContainer) -> Result<Vec<u8>, String>`, over a typed model:

| Type | Holds |
|---|---|
| `EffectContainer` | `shapes` (EMTR GEOMs), `emitters`, `forces` |
| `Emitter` | TRFM matrix, 9 channel `Atrb`s, optional `EmitterGeom`, `ParticleType` |
| `ParticleType` | PTYP flags, 32 `Atrb`s, `Colr`, `Text` |
| `Atrb` | `hash`, `flags`, `value` (`AtrbValue::F32`/`U32`), `curve` (`Option<Vec<AnimKey>>`) |
| `Colr` | 100 `ColrKey { colour: [u8; 4], half_bits: u16 }` |
| `Force` | `ForceKind` (typed per kind) + its `Atrb`s |

- `EFCT` is computed (`EffectContainer::efct_words`), never stored in the model.
- `ATRB` flag bits 0 (f32 value) and 10 (has curve) are derived; an authored flag word that
  disagrees is an error.
- Attribute runs are checked against the position tables (`TRFM_CHANNELS`,
  `PTYP_ATTRIBUTES_BEFORE_COLR` / `_AFTER_COLR`, `FRCE_*_ATTRIBUTES`), which also carry the
  recovered names.
- The container is flattened by `ucfx::write_ucfx_tree` (computed `x2`/`x3`, marker rows,
  contiguous bodies, `CSUM`) and read by the strict `ucfx::parse_ucfx_tree`.

Tests: `cargo test -p mercs2_formats fxdict ucfx` (hermetic: every FRCE kind's size, COLR 800 B,
CSUM, flag rejection, an authored one-emitter `magenta_burst` effect that re-parses and satisfies
the tree rules) and `tests/effect_retail_roundtrip.rs` (game-gated: 314/314 byte-identical,
computed `EFCT` 314/314, fxdict container byte-identical, C4 effect name resolution).

The previous encoder wrote a 16-byte `EFCT`, `EMTR` as count + refs, a float `EMIT` body, a `POFF`
chunk, a 1-byte `PTYP`, a 200-byte `COLR` and FRCE params clamped to four, and padded bodies to
4 bytes with `x2 = x3 = 0`; none of that is what retail contains.

## 8. Related docs

- [`type_hash_registry.md`](type_hash_registry.md) — type hashes
- [`format_reference.md`](format_reference.md) — UCFX chunk header layout
- [`audio_ue5_path.md`](audio_ue5_path.md) §2 — Niagara conversion plan
