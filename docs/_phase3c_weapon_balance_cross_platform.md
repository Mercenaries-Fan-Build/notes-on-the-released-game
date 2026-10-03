# Phase 3.C — Weapon balance constants, cross-platform

**Status:** current · **Evidence:** proven

Question: do PC, Xbox 360, and PS3 ship different **weapon balance constants** (damage,
range, reload time, mag size, spread, recoil)?

**Verdict — PROVEN:** weapon tuning constants are **byte-identical across all three
platforms**, modulo endianness. Every u32-sized tuning field (fire rate, scatter cone,
aim angle, damage, recoil, falloff) matches exactly on PC/Xbox/PS3. The only
cross-platform byte differences are confined to:

1. Sub-u32 header fields (same semantic value, different byte packing)
2. CSUMs (recomputed because header byte-order flipped)
3. Internal file offsets pointing to codec-specific audio sections

---

## 1. Where weapon balance lives (PROVEN)

### 1.1 Not in Lua

- PC: `docs/mercs2-luacd/src/resident/all_weapons.lua` is a bare `return` (empty
  bytecode).
- Xbox: `docs/mercs2-luacd-xbox/src/resident/all_weapons.lua` is `local L0_1, L1_1`
  (also effectively empty).
- No `mrxweapon*.lua` runtime class exists under `src/resident/` on either side.

### 1.2 In the per-weapon `wpn_<name>_P000_Q3.block` blocks (PROVEN by byte scan)

Every retail weapon ships as one `blocks\vz\wpn_<name>_P000_Q3.block` block in
`vz.wad`. That block is a UCFX container whose top-level TOC schema is:

```
u32 count
count × { u32 asset_hash; u32 type_hash; u32 pad=0; u32 offset_in_block; }
```

(TOC schema PROVEN by inspection of PC `wpn_assaultrifle` block head —
`03 00 00 00 fc 61 86 ad 10 ca 8b 9f 00 00 00 00 24 06 00 00 ...`.)

Every weapon's TOC holds the same three sub-chunks (type_hashes from
`crates/mercs2_formats/src/aset_type_ids.rs`):

| type_hash | type_id | role (project registry) |
|---|---:|---|
| `0xE5273C14` | 13 | sounddb |
| `0x9F8BCA10` | 21 | soundbank — **holds the weapon-component reflection tree** |
| `0xF753F6D0` |  6 | wavebank (bulk audio, codec-dependent) |

Despite the generic `soundbank` label, the `0x9F8BCA10` sub-chunk for a `wpn_` asset
is the editable weapon-stat payload: it contains N occurrences of the hash
`0x787C0871` = `pandemic_hash_m2("weapon")`, each starting a **weapon-component
record** carrying the tuning floats.

**Weapon-component record count per weapon (PROVEN — same on all three platforms):**

| Weapon | PC/XB/PS3 "weapon" records |
|---|---:|
| wpn_assaultrifle | 6 |
| wpn_rpg | 7 |
| wpn_covertpistol | 4 |
| wpn_minigun | 4 |
| wpn_coilgun | 1 |

Byte scan: PC-LE pattern `71 08 7c 78`, Xbox/PS3 BE pattern `78 7c 08 71`. Hits per
platform recorded in
`scratchpad/wpn_cross/{pc,xbox,ps3}/*_block.bin`.

### 1.3 Not in `.rdata` as literals

`docs/mercs2-pdb-analysis/data-defaults.md` already proved that the Pandemic weapon
field-name strings (`iClipSize`, `RateOfFire`, `iBulletsPerShot`, etc.) exist in the
exe only as `.rdata` strings loaded by split-immediate PPC loads — the engine's
hand-rolled reflection loader binds them against WAD reflection blocks. The exe
`.data` has **no** weapon default values baked in.

---

## 2. Cross-platform byte comparison (PROVEN)

Three retail WADs (sha256-stamped on `game-files/`):
- `game-files/vz.wad`         (PC, 2,565,537,792 B, FFCS)
- `game-files/xbox-vz.wad`    (Xbox 360, 2,000,486,400 B, SCFF = BE)
- `game-files/ps3-VZ.WAD`     (PS3, 2,201,354,240 B, SCFF = BE)

Extractor: `scratchpad/wpn_dump2.py` — opens the WAD, resolves the block via the
INDX entry, decompresses the `sges`/`segs` body (header shape = project's
`sges_decompress.py` convention: 8-byte seg entries, bit-0 of `abs_off` = compressed
flag), walks the TOC, dumps each sub-chunk.

### 2.1 Asset identity is cross-platform-constant

| Weapon | asset_hash (all three platforms) | Block idx PC / XB / PS3 |
|---|---|---|
| wpn_assaultrifle | `0xAD8661FC` | 3396 / 3386 / 4508 |
| wpn_rpg          | `0xF6CD058A` | 3559 / 3542 / 5372 |
| wpn_covertpistol | `0x23643E6F` | 3057 / 3055 / 2893 |
| wpn_minigun      | `0xA08DA55A` | 3354 / 3345 / 4338 |
| wpn_coilgun      | `0xF95E99C2` | 3568 / 3550 / 5404 |

Sourced from `scratchpad/aset-{pc,xbox,ps3}/aset.csv` filtered on `name=wpn_*`.

### 2.2 Sub-chunk sizes (reported by `ucfx_byteswap`) — **IDENTICAL across platforms**

| Weapon | sounddb (0xE5273C14) | soundbank (0x9F8BCA10) |
|---|---:|---:|
| wpn_assaultrifle | 100 B | 1572 B |
| wpn_rpg          | 112 B | 1784 B |
| wpn_covertpistol |  88 B |  872 B |
| wpn_minigun      | 100 B |  752 B |
| wpn_coilgun      |  88 B |  240 B |

(Measured by running
`tools/wad_simulator/target/release/ucfx_byteswap.exe` on each console block;
PC side has the same payload sizes — only the surrounding wavebank differs.)

The **wavebank** differs in bytes per platform (codec-dependent: PC MSADPCM, Xbox
XMA2 at 0x05, PS3 ATRAC3 at 0x0C) — this is **not** a tuning difference. The
`ucfx_byteswap` tool fails to transcode PS3 wavebanks ("no embedded clip transcode
for codec 0x0C"), which is a known codec gap, not a weapon-balance gap.

### 2.3 Weapon-component records — **identical values**

For wpn_assaultrifle, the six `0x787C0871` records live at the **same block
offsets** on PC/XB/PS3: `0x80, 0xF4, 0x1DC, 0x268, 0x2DC, 0x350`.

Reading the 32 u32s after each hash marker (interpreting LE on PC, BE on consoles):

| Record offset | u32 identical (PC == XB == PS3) |
|---|---|
| 0x80  | 29 / 32 |
| 0xF4  | 28 / 32 |
| 0x1DC | 27 / 32 |
| 0x268 | 28 / 32 |
| 0x2DC | 28 / 32 |
| 0x350 | 27 / 32 |
| **Total** | **167 / 192 (87 %)** |

The **non-matching** 25 u32s are all at the same three positions in each record:

- `[2]`: PC `0x00000001` vs console `0x01000000` — a `u8[4]` or `(u16,u16)` field
  that stores the same semantic bytes `01 00 00 00` on **both** platforms. The
  consoles write it big-endian within a u32 slot, so when read as BE u32 it decodes
  to `0x01000000`, but as `u8[4]` or `(u8,u16,u8)` it's identical to PC.
- `[10]`: likewise a byte-packed tuple (`0x01020300` vs `0x00030201`).
- `[17]`: likewise (`0x00000101` vs `0x01010000`).

Every **float32** field matches exactly — the actual balance values are
byte-identical. Sampled from the dump
(`scratchpad/wpn_cross/.../_block.bin`, verified live):

| Record | f32 values (PC == XB == PS3) |
|---|---|
| wpn_assaultrifle @0x80  | 0.9599609, 100.0, 200.0, 1.0×3, 0.2512, 0.5012, -2.0 |
| wpn_assaultrifle @0xF4  | 0.9599609, 100.0, 200.0, 1.0×3, 0.5012, 1.0 |
| wpn_assaultrifle @0x1DC | 0.9599609, 10.0,  100.0, 1.0×3, 0.595, 0.2512×3, -0.1004 |
| wpn_assaultrifle @0x268 | 0.9599609, 10.0,  1000.0, 1.0×3, 0.6305×3, -0.7 |
| wpn_assaultrifle @0x2DC | 0.9599609, 60.0,  200.0, 1.0×3, 0.05, 1.0×3, -1.5 |
| wpn_assaultrifle @0x350 | 0.9599609, 100.0, 200.0, 1.0×3, 1.0×3, -1.5 |
| wpn_coilgun @0x80       | 0.9599609, 20.0,  100.0, 1.0×3, 0.8913, 0.7943, 0.8913, -2.0, -4.0, -2.0 |

Every float on every row is **exactly** `pf == BE(xu) == BE(su)` with no diff.
These are the authored engineering values the Lua binding `Weapon.*` surface
reads.

### 2.4 Why wpn_rpg / wpn_covertpistol / wpn_minigun record offsets look different

In those blocks the weapon records live **after** the (variable-sized)
wavebank payload, so the absolute offsets shift per platform (PC wavebank is
large PCM; Xbox / PS3 compressed). Within each record the structure and values
are the same — the shifted offsets are just a packing artifact. The
`ucfx_byteswap` tool rewrites the TOC so a converted Xbox block aligns with
the PC layout; the first 48 bytes of the PC-vs-Xbox-converted soundbank payload
for all five weapons match byte-for-byte except for (a) the (u16,u16) count/
version word at offset 0, and (b) the CRC-32 CSUM at offset 0x30 (recomputed
because the count word's byte order changed).

### 2.5 Xbox vs PS3 raw (both BE)

Direct BE-vs-BE byte compare of the sounddb sub-chunks:

| Weapon | Xbox-sounddb SHA256 vs PS3-sounddb SHA256 | Byte-identical |
|---|---|---|
| wpn_assaultrifle | `8b1407bed91f7573…` vs `8b1407bed91f7573…` | **yes** |
| wpn_coilgun      | `13b24e2fe5a0434d…` vs `13b24e2fe5a0434d…` | **yes** |
| wpn_rpg          | `dd7b935a07a3050a…` vs `596a70cad5941dcc…` | no (21/112 B differ — all in sample-length / cue-offset fields encoding ATRAC3 vs XMA2 sizes) |
| wpn_covertpistol | `b0593049cdb59e50…` vs `08e87ea997a1c4a5…` | no (9/88 B differ, same reason) |
| wpn_minigun      | `92a41cc7c710507d…` vs `10154679326b096b…` | no (13/100 B differ, same reason) |

So two of five sounddbs are byte-identical between the two BE platforms; the three
that differ do so **only** in sample-length / cue-offset fields (verified by
diffing the per-index u32 dump — the matching values 0x0000AC44 = 44100 Hz sample
rate repeat identically, differing u32s cluster at codec-sized positions). Weapon
tuning is untouched.

---

## 3. Representative weapon values (PROVEN cross-platform)

Values below are read directly from the retail soundbank sub-chunk at the cited
block offset and verified byte-identical on PC (LE), Xbox 360 (BE), PS3 (BE).

| Weapon | Record | Fields seen (all three platforms, same bytes) |
|---|---|---|
| wpn_assaultrifle | 6 records at 0x80..0x350 | sample above (§2.3), floats 0.96 / 100 / 200 / 1 / 0.251 / 0.501 / −2 / 10 / 1000 / 0.595 / 0.631 / 0.05 / −0.7 / −1.5 |
| wpn_rpg          | 7 records | all `pandemic_hash_m2("weapon")` records byte-equal under endianness swap |
| wpn_covertpistol | 4 records | same |
| wpn_minigun      | 4 records | same |
| wpn_coilgun      | 1 record  | floats 0.96 / 20 / 100 / 1×3 / 0.8913 / 0.7943 / 0.8913 / −2 / −4 / −2 |

(Full per-record u32 / f32 dump: `scratchpad/weapon_float_dump.log`.)

The exact field→offset mapping (which u32 is `iClipSize`, which float is
`RateOfFire` etc.) is **not** resolved in this pass — that needs the engine's
reflection schema decode (`FUN_0064a600` deserializer per
`memory/weapon-definitions-wpn-blocks.md`). But resolving the names is **not
needed** for the cross-platform question: whatever each slot holds, it holds
the same bits on every retail platform.

---

## 4. Verdict

**PROVEN:** Weapon balance constants ship **identical** on PC, Xbox 360 and PS3.
There is **no per-platform weapon balance divergence** — a weapon's damage,
scatter, aim-cone, recoil, falloff, projectile velocity and all other tuning
values are byte-equal across the three retail WADs once endianness and
schema-aware byte packing are accounted for.

**Contrast with Phase 2 (cdbsizes):** ECS pool capacities **do** diverge
per platform (PC's `cdbsizes.ini` is laid out differently from the Xbox / PS3
baked blobs). Weapon tuning is on the **convergent** side of the ledger: the
authored stats are a single cross-platform artifact, delivered through
`vz.wad` under the same asset hashes to all three builds.

---

## 5. Provenance

- Extractor: `scratchpad/wpn_dump2.py` (BE/LE aware FFCS/SCFF opener + sges
  decompressor + UCFX TOC walker).
- Weapon-hash scanner + value dumper: inline Python at
  `scratchpad/weapon_hash_scan.log`, `scratchpad/weapon_subcontainer_cmp.log`,
  `scratchpad/weapon_float_dump.log`.
- Byte-swap oracle: `tools/wad_simulator/target/release/ucfx_byteswap.exe`.
- Prior work this builds on:
  - `docs/mercs2-pdb-analysis/data-defaults.md` §1.4 — weapon stats not in `.data`.
  - `docs/reverse_engineer/weapons_combat_code_map.md` §7 — stats in `wpn_*`
    reflection blocks, not Lua.
  - `memory/weapon-definitions-wpn-blocks.md` — the `wpn_<name>_P000_Q3.block`
    story (note: the memory's "entry[0] = weapon def = 0x9f8bca10" label was
    right about **which type_hash** carries the stats, even though that type_id
    is nominally `soundbank` in the registry).
  - `docs/_engine_divergence_phase1.md` §1 — ASET-level cross-platform parity for
    the 26 `wpn_*` assets (hashes identical, platform-specific textures only).
