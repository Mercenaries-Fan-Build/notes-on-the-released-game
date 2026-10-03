# Mercenaries 2 effect container format

**Status:** specification, measured against all 314 retail effects in PC `vz.wad`: every one
parses into the model below and re-encodes to the identical bytes, and the computed `EFCT` header
equals the stored one in 314/314 (`mercs2_formats/tests/effect_retail_roundtrip.rs`).
**Implementation:** `mercs2_formats::fxdict::{parse_effect_container, write_effect_container,
EffectContainer}`.
**Loader:** `mercs2_unpacked.exe` — effect driver `FUN_00491920`, PTYP-child reader `FUN_00492af0`,
EMIT walker `FUN_0048cc30`, TRFM-channel reader `FUN_00493150`.

Confidence labels: **PROVEN** = checked against retail bytes or a decomp read this pass;
**INFERRED** = reasoned from the decomp or the data, not exercised; **UNKNOWN** = carried verbatim,
meaning not established.

---

## 1. The asset

| Field | Value |
|---|---|
| Type hash | `0x5608BD5A` |
| ASET type id | 29 |
| Retail count | 314, all in `blocks\VZ\effects_P000_Q3` |
| Asset name | `pandemic_hash_m2(<effect name>)`, e.g. `global_explosion_c4` = `0x41B4326E` |

A world template names its effect with the placement / template name minus `particle_`:
`global_particle_env_godray2` → `global_env_godray2` (`0xDB331999`),
`global_particle_explosion_c4` → `global_explosion_c4` (`0x41B4326E`). **PROVEN** by hash match
against the 314. For the C4 template the world-entity data agrees: the `RedEffectComponent` record
of entity `0x80008028` carries `0x41B4326E` in its `name` field (`0x1DE5C824`).

**The field that carries a template's effect** is `RedEffectComponent`'s `name` (`0x1DE5C824`, schm
code 6, offset 0): in 524 of the 538 retail `RedEffectComponent` records it is the name hash of one
of the 314 effects (PROVEN by the data, [`worldentity_container_format.md`](worldentity_container_format.md)
§4). `ObjectState.StartEmitter` passes a **template** name hash, not an effect hash:
`FUN_004D28C0` resolves it through the template lookup `FUN_00672F60` and spawns that template with
`FUN_006746D0`. That the spawned template's `RedEffectComponent` `name` is what starts the effect
is INFERRED; the code from it to PgFX was not read.

The container is a UCFX tree — see [`ucfx_tree_container.md`](ucfx_tree_container.md) for rows,
`x2`/`x3`, marker rows, contiguous bodies and `CSUM`.

---

## 2. Tree

```text
EFCT                          18 B    nine u16, computed (§3)
├─ EMTR                        2 B    u16 = number of GEOM children
│  └─ GEOM × n                        u32 k, then k × 13 f32         (emitter shapes)
├─ EMIT  (marker)                     ┐
│  ├─ TRFM                    64 B    │ 4×4 f32
│  │  └─ ATRB × 9                     │ the nine channels (§5.1)
│  └─ GEOM (optional)          4 B    │ u16 shape index, u16          } one pair per emitter
├─ PTYP                        4 B    │ u32 flags
│  ├─ ATRB × 19                       │ (§5.2, fixed order)
│  ├─ COLR                   800 B    │ (§6)
│  ├─ ATRB × 13                       │ (§5.2, fixed order)
│  └─ TEXT                            ┘ u32 n, n × u32 texture hash
└─ FRCE × k                           u32 kind hash + kind parameters (§7)
   └─ ATRB × (7 + kind extras)
```

Every `ATRB` may own one curve:

```text
ATRB                          12 B    { u32 hash, u32 flags, u32|f32 value }
└─ ANIM                        4 B    u32 = number of AKEY children
   └─ AKEY × n                 8 B    { f32 time, f32 value }
```

Order is fixed: `EMTR` first, then (`EMIT`, `PTYP`) pairs, then the `FRCE`s. **PROVEN** (314/314).
There is no `POFF` in any retail effect.

| Node | Rule | Evidence |
|---|---|---|
| `EMTR` | u16 equals its GEOM child count; every retail EMTR has ≥ 1 | PROVEN; loader allocates `count × 4` |
| `EMTR/GEOM` | `4 + 52·k` bytes; each record is 13 f32 | PROVEN; loader allocates `k × 0x34`, copies 13 words |
| `EMIT` | marker; children `TRFM` then optional `GEOM` (811 of 820 have one) | PROVEN |
| `EMIT/GEOM` | u16 shape index into the EMTR table (`shapes[u16]`), then a u16 stored at `+0x00` of the EMIT record (UNKNOWN meaning) | decomp `FUN_0048cc30` |
| `PTYP` | u32 flags: bit 0 → emitter `+0x205`, bit 1 → `+0x206`; no other bit is read; retail uses 0–3 | decomp `FUN_00491920` |
| `TEXT` | u32 n, then n texture hashes; `4 + 4n` bytes; n ≥ 1 (the loader reads one frame when n ≤ 1) | PROVEN sizes; decomp `FUN_00492af0` |

---

## 3. `EFCT` — computed header

Nine u16. The loader reads them as a count pair and three `(entries, words)` table reservations
(`FUN_00491920`). A writer computes every word:

| Word | Value |
|---|---|
| 0 | emitters (PTYP count) |
| 1 | `0x0226` (read and skipped) |
| 2 | forces (FRCE count) |
| 3 | linear-table entries: TRFM channel curves + PTYP *linear* curves + FRCE curves |
| 4 | linear-table words: `2 × keys` per curve; a TRFM curve with flag bit 8 reserves 100 |
| 5, 6 | 0 (a third table, empty in all of retail) |
| 7 | stream-table entries: `COLR` + `TEXT` per emitter + PTYP *resampled* curves |
| 8 | stream-table words: 200 per `COLR`, 200 per `TEXT`, 100 per resampled curve |

Whether a PTYP curve is *linear*, *resampled* or *not counted* is decided by the handler its
attribute hash dispatches to in `FUN_00492af0`, **not** by the flag bits:

| Handler (thunk) | Curve class | Hashes |
|---|---|---|
| `0x024E2380` | resampled (100 words, stream table) | `size` `0x8C3654C2`, `0x497A1895`, `0x35ACBAB7` |
| `0x024EEC10` | linear (`2 × keys`, linear table) | `rate`, `speed`, `spread`, `inheritvel`, `life` |
| `0x024EEBE0` | not counted | `speedvar`, `spreadvar`, `lifevar`, `inheritvelvar` |

- The rule is **PROVEN** by 314/314. The handler table is the dispatch in `FUN_00492af0`; the
  handler bodies are SecuROM-relocated and not decompiled, so the *class* names are INFERRED from
  what each handler's hashes do to `EFCT`.
- `size` curves count as resampled with flags `0x401` as well as `0x701`: bit 8 does not decide it.
- Retail carries two `speedvar` curves (effect `0xBB86EA9B`). They are in the file and not in
  `EFCT` — consistent with their handler not consuming a curve.
- FRCE curves (retail puts them on `ampl`, `posx`, `posy`, `posz`) count as linear. PROVEN by the
  data; the FRCE-child dispatch is behind an unresolved jump table.
- TRFM curves go through `FUN_00493150`: flag bit 8 clear → `2 × keys` words; bit 8 set → 100
  resampled words. Both branches write through the same table pointer, so a bit-8 TRFM curve
  counts in words 3/4 with 100 words. INFERRED — no retail TRFM curve has bit 8.
- `TEXT` counts 200 words in every retail effect, including the 80 PTYPs with bit 1 set. With bit 1
  the loader actually reserves `2 × n` words for the frames (`FUN_00492af0`), so bit 1 with more
  than 100 frames would overrun the reservation. INFERRED; the reference writer refuses it.

The byte-swapping note for the Xbox path (EFCT read as u16 vs byteswapped as u32 → NULL `[+0x60]`
→ fault at `0x00493102`) is in [`spatial_hash_crash_analysis.md`](spatial_hash_crash_analysis.md).

---

## 4. `ATRB`

```text
+0  u32 hash      pandemic_hash_m2(attribute name)
+4  u32 flags
+8  u32 value     f32 when flags bit 0 is set, else u32
```

| Bit | Name | Rule |
|---|---|---|
| 0 | float | set ⇔ the value is an f32. Derived. |
| 7 | option | authored; meaning UNKNOWN |
| 8 | resample | authored; `FUN_00493150` takes the 100-sample branch for a TRFM curve |
| 9 | option | authored; meaning UNKNOWN |
| 10 | curve | set ⇔ the ATRB has an `ANIM` child. Derived. PROVEN on all 1,880 retail curves. |

`FUN_00493150` packs bits 7–10 into a nibble as `b7<<3 | b10<<2 | b8<<1 | b9`. No retail ATRB sets
any other bit, and no u32-valued ATRB sets any bit. A writer derives bits 0 and 10 and refuses an
authored flag word that disagrees.

`ANIM` = u32 key count, equal to its `AKEY` child count (PROVEN). `AKEY` = `{f32 time, f32 value}`;
retail times run 0–100.

---

## 5. Attribute positions

### 5.1 TRFM channels (9, in order)

`posx` `0x7D1117EB`, `posy` `0x9B0F088E`, `posz` `0xFD165E99`, `rotx` `0xF6B55F38`,
`roty` `0x20B7DFED`, `rotz` `0x9EB05782`, `sclx` `0xC5574C5F`, `scly` `0xE3553D02`,
`sclz` `0x655CC56D`. All f32; all may carry a curve (`FUN_0048cc30` → `FUN_00493150`).

### 5.2 PTYP (32, fixed order, 820/820 retail)

Before `COLR`:

| # | Hash | Name | Value | Curve |
|---|---|---|---|---|
| 0 | `0x1DE5C824` | name | u32 | — |
| 1 | `0x8C3654C2` | size | f32 | resampled |
| 2 | `0xC1008E25` | sizevar | f32 | — |
| 3 | `0xC3AEB321` | mass | f32 | — |
| 4 | `0x47035D90` | massvar | f32 | — |
| 5 | `0xD3AE67AF` | life | f32 | linear |
| 6 | `0xC7CFE6AA` | lifevar | f32 | not counted |
| 7 | `0x497A1895` | *unresolved* | f32 | resampled |
| 8 | `0x1792B524` | *unresolved* | f32 | — |
| 9 | `0x10831673` | *unresolved* | f32 | — |
| 10 | `0xB6197EFE` | *unresolved* | f32 | — |
| 11 | `0x6CF0BE14` | *unresolved* | f32 | — |
| 12 | `0xBE968D3B` | *unresolved* | f32 | — |
| 13 | `0xC558C9D8` | *unresolved* | f32 | — |
| 14 | `0xD80DF37F` | *unresolved* | f32 | — |
| 15 | `0x720F22F8` | *unresolved* | f32 | — |
| 16 | `0x4712719F` | *unresolved* | f32 | — |
| 17 | `0xB3DBB6C0` | *unresolved* | f32 | — |
| 18 | `0x4C49B137` | *unresolved* | f32 | — |

After `COLR`:

| # | Hash | Name | Value | Curve |
|---|---|---|---|---|
| 19 | `0xC3592BB7` | *unresolved* | u32 (2 in all retail) | — |
| 20 | `0xEEE1A341` | scale | u32 (loader clamps to ≥ 1) | — |
| 21 | `0x062F0D37` | rate | f32 | linear |
| 22 | `0x70653182` | ratevar | f32 | — |
| 23 | `0x437F66EC` | spread | f32 (retail 0–180) | linear |
| 24 | `0xB8A95DE3` | spreadvar | f32 | not counted |
| 25 | `0x15BA509E` | speed | f32 | linear |
| 26 | `0x9BE62E41` | speedvar | f32 | not counted |
| 27 | `0xB4247BF3` | inheritvel | f32 | linear |
| 28 | `0xB15ABB7E` | inheritvelvar | f32 | not counted |
| 29 | `0x35ACBAB7` | *unresolved* | f32 | resampled |
| 30 | `0x1B878602` | *unresolved* | f32 | — |
| 31 | `0x270C9E9D` | emissiondir | u32 (0, 1, 2 in retail) | — |

"—" = no retail effect has a curve there and the loader's handling of one is not decoded; the
reference writer refuses a curve at that position.

### 5.3 FRCE (7 common + kind extras)

Common, in order: `ampl` `0x3DC3D9DF`, `posx`, `posy`, `posz`, `rotx`, `roty`, `rotz`. Curves
appear on `ampl` and `pos*` (linear).

| Kind | Extra attributes |
|---|---|
| gravity, wind | none |
| drag | `0x2F68CD8F` (unresolved, f32) |
| attractor | `local` `0x201B5A86` (u32), `range` `0xE0686A68`, `decay` `0xC2783A55` |
| vortex | `local`, `range`, `decay`, `radial` `0xB46F1F0C` |

### 5.4 Names

Every name above is `pandemic_hash_m2(name) == hash`, PROVEN. Sixteen hashes (15 PTYP positions
and the drag extra) are unresolved and kept as hashes.

---

## 6. `COLR` — 800 bytes

`FUN_00492af0` copies exactly 800 bytes and reserves 200 stream words for it. The body is 100 keys
of 8 bytes, spread over the particle's life (key `i` at age `i / 99`):

```text
+0  u8[4]   colour
+4  u16     binary16 bit pattern
+6  u16     0
```

- The trailing u16 is 0 in all 82,000 retail keys. PROVEN.
- The colour bytes read as three near-equal bytes plus a fourth that fades to 0 over the keys
  (retail god-ray: `3f 3f 3f 29`). That the order is R, G, B, A is UNKNOWN; carry them as data.
- The binary16 is `0x3C00` (1.0) or `0xBC00` (−1.0) in the samples read. Its role is UNKNOWN.

Earlier notes gave COLR as 200 bytes of 50 RGBA stops (the 200 is the stream-word reservation, not
the byte size) and as an 8-byte record `[0xBC, 0, 0, R, G, B, A, 0]` (that reading is the key
layout shifted by five bytes).

---

## 7. `FRCE` — forces

`u32 kind` (`pandemic_hash_m2` of the kind name, PROVEN) then fixed parameters
(`FUN_00491920`, FRCE arm). Field names that state a meaning are INFERRED; the rest are named by the
runtime offset the loader writes.

| Kind | Hash | Bytes | Mode | Parameters |
|---|---|---|---|---|
| wind | `0xC9F7A9D7` | 20 | 0 | f32 magnitude → `+0x12C`; vec3 direction → `+0x110`; sets effect `+0x94 \|= 2` |
| gravity | `0x14BD1BBD` | 20 | 1 | f32 magnitude → `+0x12C`; vec3 direction → `+0x110` |
| drag | `0xED791C4B` | 8 | 2 | f32 magnitude → `+0x12C` |
| attractor | `0xC235456B` | 32 | 3 | f32 → `+0x12C`; u32 (read `!= 0`) → `+0x13C`; f32 → `+0x130`; f32 → `+0x134`; vec3 → `+0x104` |
| vortex | `0xF4D85A49` | 60 | 4 | as attractor, plus f32 → `+0x138`; vec3s → `+0x104`, `+0x110`, `+0x11C` (a basis is built from the cross product of the last two) |

Retail: 225 gravity, 255 drag, 42 wind, 27 attractor, 110 vortex. No other kind hash occurs, and the
loader reads nothing for one.

---

## 8. Writing an effect

1. Build shapes (≥ 1), emitters (≥ 1; each with 9 TRFM channels and 32 PTYP attributes in the
   order above, a `COLR`, a `TEXT` with ≥ 1 frame), and forces.
2. Derive each ATRB's bits 0 and 10; set only bits 7/8/9 by hand.
3. Compute `EFCT` (§3).
4. Flatten per [`ucfx_tree_container.md`](ucfx_tree_container.md) and append `CSUM`.

The reference writer refuses: a flag word that disagrees with its value or curve; a bit outside
{0, 7, 8, 9, 10}; options or a curve on a u32 attribute; an empty curve; an attribute out of
position or of the wrong value type; a curve at a position marked "—"; a `GEOM` shape index past the
shape table; PTYP flag bits other than 0 and 1; an empty `TEXT`; PTYP bit 1 with more than 100
frames.
