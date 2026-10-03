# Phase 3c — Shader cross-platform identification

**Status:** current · **Evidence:** proven (all per-row claims labelled PROVEN / INFERRED)
· **Date:** 2026-10-03

Can we identify which shipped shader programs are platform-exclusive vs shared? Short answer:
**yes for PC vs Xbox 360** (both use `pandemic_hash_m2` over the shader's registered name, so the
sets are directly diff-able), **no for PS3** (its hash scheme is not `pandemic_hash_m2` of any name
suffix we have tried; names must come from a different oracle). Even without PS3 names, the
structural evidence settles the two main hypotheses.

Supersedes: `docs/_engine_divergence_phase1.md` §2 — the PS3 TOC stride and the "Xbox shaders are
baked into the XEX" claim were both wrong. Corrected below.

---

## 1. TOC record format — three platforms (PROVEN)

Parsed with: `scratchpad/*.log`, source files below. Monotonic-offset check succeeds for every
layout; the alternate layouts all fail it.

| Platform | File(s) | TOC endian | Record stride | Record fields | Blob count |
|---|---|---|---|---|---:|
| PC | 6 bins in `data/shader*.bin` | LE | 16 B | `u32 id, u32 off, u32 size, u32 kind` (1=VS, 0=PS) | **1,023** (1,021 unique) |
| Xbox 360 retail | `shaders.bin` | BE | **8 B** | `u32 id, u32 off` (size implicit = next_off − off) | **346** |
| PS3 retail | `USRDIR/SHADERS.BIN` | BE | **8 B** | `u32 id, u32 off` (size implicit) | **1,102** |

Note: the "`stride=16 BE (vs_hash,vs_off,ps_hash,ps_off)` PS3 pairs" guess in Phase 1/2 §2 is
**FALSIFIED (PROVEN)** by this run:
- Under the pair hypothesis, only 621/1,102 records have both offsets inside the file and the
  first "blob offset" collapses to 1 (impossible). Under the stride-8 hypothesis, 1,102/1,102
  offsets are monotonic and in-range, and the first blob lands exactly at the first 16-aligned
  byte past the TOC (0x2280 after a 2772-byte table + 60-byte pad on PS3; 0x0ae0 after a
  2772-byte table + 12-byte pad on Xbox) — the same layout rule as PC. See `scratchpad/ps3-toc.log`
  and `scratchpad/console-toc.log`.
- Consequence: **PS3 ships 1,102 individual shader blobs**, not 2,204 VS/PS pairs. Avg 2.71 KB
  per blob (vs PC avg 3.54 KB, Xbox avg 2.49 KB).

Xbox 360 ships its shader store **as a separate file**, not inside the XEX — Phase 1 §3 said
otherwise; see `game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/shaders.bin`
(864,832 B). (The Jul 11 2008 Xbox prototype `shaders.bin` is a different file with 344 `.updb`
debug strings; retail strips those.)

---

## 2. Hash scheme per platform

### 2.1 PC — PROVEN

```
id = pandemic_hash_m2(stem + "_3.sho")    # shader3.bin, shaderVT.bin, shaderR2VB.bin
id = pandemic_hash_m2(stem + "_3l.sho")   # shader3Low.bin, shaderVTLow.bin, shaderR2VBLow.bin
```

Where `stem` is the registered `.sho` file name minus `.sho`. This is settled in
`docs/shader_store_format.md` §4 (anchor: `FUN_0085b6f0`, which copies the registered name,
cuts its last four chars, appends `DAT_00be87e8 = "_3l.sho"` or `DAT_00be87f0 = "_3.sho"` based
on `DAT_00dfc345`, and hashes via `FUN_00824270 → pandemic_hash_m2`). **Not** a D3DCompile
output hash or MD5-of-source. Phase 1 §2's "likely D3D shader-signature hash" guess is
FALSIFIED.

Coverage test, this session: extracted 543 distinct `*.sho` strings from the exe, hashed each
stem under both suffixes, intersected with each bin's record ids:

| Bin | records | named by stem+suffix |
|---|---:|---|
| `shader3.bin` | 556 | **515** under `_3.sho` |
| `shader3Low.bin` | 411 | **372** under `_3l.sho` |
| `shaderVT.bin` | 15 | **13** under `_3.sho` |
| `shaderVTLow.bin` | 15 | **13** under `_3l.sho` |
| `shaderR2VB.bin` | 13 | **13** under `_3.sho` |
| `shaderR2VBLow.bin` | 13 | **13** under `_3l.sho` |
| **Total** | **1,023** | **939 (91.8%)** |

The 84 unresolved are shader stems that have no `*.sho` string in the exe. Reproduces
`shader_store_format.md` §4 byte-for-byte. Script: `scratchpad/pc-names.log`.

### 2.2 Xbox 360 — PROVEN

```
id = pandemic_hash_m2(stem + ".sho")      # single tier, bare .sho
```

**Same hash function as PC, different suffix.** Xbox ships one unified `shaders.bin` so there is
no `_3`/`_3l` quality tag. Verified by hashing the 541 PC `.sho` stems with each candidate
suffix and intersecting against the Xbox id set (`scratchpad/pc-xbox-diff.log`):

| Suffix tried | Xbox hits |
|---|---:|
| `""` | 0 |
| `.sho` | **318 / 346 (91.9%)** |
| `_3.sho`, `_3l.sho` | 0 each |
| `_rsx.sho`, `_ps3.sho`, `_nv.sho`, `_x360.sho`, `_xbox.sho` | 0 each |

The 91.9% coverage ratio is **identical to PC's 91.8%** — the 28 unresolved Xbox hashes are the
same class of "no `.sho` string in the shipping exe" as the 84 PC unresolved.

### 2.3 PS3 — INFERRED NEGATIVE (hash scheme not `pandemic_hash_m2`)

Not `pandemic_hash_m2` of any name suffix we have tried. Searched 15 suffix candidates on the
union of 191 PC + PS3 shader logical names, plus the material-level (stripped `VP`/`FP`) names,
plus the bare-stem form; **every combination returned 0/1,102 hits** against PS3 ids
(`scratchpad/pc-xbox-diff.log` + follow-up).

PS3 engine evidence (from `game-files/ps3-version/EBOOT.elf` strings):
- 0 strings matching `*.sho` (vs 543 on PC, 318 names reachable on Xbox).
- 1 reference to literal `shaders.bin`; 3 refs to the `.sho` substring.
- Separate shader class hierarchy with `Ps3` suffixes: `CShaderBase / CVertexShader /
  CFragmentShader`, modules named `ShaderCompositePs3`, `ShaderBloomPs3`, `ShaderBlurPs3`,
  `ShaderCloudGen`, `ShaderMotionBlurPs3`, `ShaderToneMappingPs3`, etc.
- Metadata strings `shaderEntryPoint`, `shaderIncludePaths`, `shaderFile` suggest the NVIDIA
  Cg Toolkit is in use for the RSX pipeline.
- Only 117 `Pg*(VP|FP)` logical names in the ELF but 1,102 TOC records → ~9.4× permutation ratio,
  consistent with a content-derived hash or a `hash(name, variant_mask)` scheme.

**Verdict: PS3 names cannot be resolved from the PC/Xbox string tables.** Resolving them needs
the PS3 shader loader (likely in `EBOOT.elf` reachable from the sole `shaders.bin` reference at
offset `0xddb2b2`) — out of scope for this phase.

Cross-platform raw-hash collision counts (sanity):
`PC ∩ Xbox = 0`, `PC ∩ PS3 = 0`, `Xbox ∩ PS3 = 0`.
Expected — the suffix convention differs between PC and Xbox even where the name is the same,
and PS3 uses a different function entirely.

---

## 3. Cross-platform shader name diff (PC vs Xbox)

The 541 PC named stems break down as:

| PC coverage | Count |
|---|---:|
| In both High and Low tier bins | 396 |
| High-tier bin(s) only | 144 |
| Low-tier bin(s) only | 1 |
| **Total PC named stems** | **541** |

Projecting PC stems onto Xbox:

| Set | Count |
|---|---:|
| PC named stems also present on Xbox | **318** |
| PC named stems NOT on Xbox (PC-only) | **223** |
| Xbox named stems NOT in PC bins | **0** |

**Every Xbox-resolvable name also exists in PC's exe string pool and matches a PC-bin stem.** So
Xbox is a near-strict subset of PC at the name level, consistent with PC being a port that added
more variants (quality tiers, R2VB, VT, extra light permutations). Payload file:
`scratchpad/pc_only_stems.json`.

### 3.1 PC-only families (what makes PC's shader set larger)

Grouped by `Pg*` prefix family of the 223 PC-only stems:

| Family | PC-only count | Nature |
|---|---:|---|
| `PgDiff*` (diffuse-light perms) | 120 | PC compiles `*_pl_li`, `*_pl_sl_li`, `*_sl_li` as separate shaders; Xbox collapses the point-light × shadow-light combos |
| `PgWater*` | 40 | R2VB, VT, DWE, `_LI` variants of water surface |
| `PgLti*` | 20 | "Loading Tip" + skinned ambient-wind variants (shell/UI subsystem) |
| `PgTerrain*` | 15 | PC-only terrain light permutations |
| `PgScrub*` | 8 | Scrub (foliage) light permutations |
| `PgSkin*AmbientWind*` | 4 | Skinned ambient-wind VS variants |
| `PgMesh*AmbientWind*` | 4 | Mesh ambient-wind VS variants |
| `PgFast*`, `PgShadow*`, `PgDecal2*`, `PgBillboardTreeZPass*`, `PgColorFPConst`, `PgZPassWater*` | 8 | Remaining |

### 3.2 R2VB-is-PC-only — PROVEN

PC's 13-shader `shaderR2VB.bin` (plus the identical Low pair) contains these 12 named stems
(13th is unnamed):

```
PgWaterVP0_R2VB         PgWaterZFullVP0_R2VB
PgWaterVP0Occ_R2VB      PgWaterZFullVP2_R2VB
PgWaterVP2_R2VB         PgWaterZFullVP3_R2VB
PgWaterVP2Occ_R2VB      PgWaterZFullVP5_R2VB
PgWaterVP3_R2VB
PgWaterVP3Occ_R2VB
PgWaterVP5_R2VB
PgWaterVP5Occ_R2VB
```

**0/12** appear in the Xbox hash set (checked by hashing with `.sho` and `_3.sho` suffixes).
The DX9 render-to-vertex-buffer code path is PC-exclusive — Xbox Xenos has native vertex-fetch
(and PS3 RSX has native output-to-vertex-buffer), so neither console ships these shaders.

### 3.3 VT-is-PC-only — PROVEN

PC's 15-shader `shaderVT.bin` (plus the identical Low pair) contains these 12 named stems
(13 total named across the pair; 2 unnamed):

```
PgWaterVP0        PgWaterZFullVP0
PgWaterVP0Occ     PgWaterZFullVP2
PgWaterVP2        PgWaterZFullVP3
PgWaterVP2Occ     PgWaterZFullVP5
PgWaterVP3
PgWaterVP3Occ
PgWaterVP5
PgWaterVP5Occ
```

Same **0/12** result on Xbox. The vertex-texture-fetch path PC uses here is also PC-exclusive at
the shipping-shader level. (Xbox Xenos does the same workload through a different code path and
reuses its unified water shaders.)

### 3.4 PS3 — structural comparison only

Since names don't resolve, the structural signal is: **PS3 ships no R2VB-bin equivalent.** A
single flat `SHADERS.BIN` holds everything; there is no analogue of PC's 13-record R2VB.bin or
15-record VT.bin as a separate container. Under the stride-8 record format this is a mechanical
statement, not a structural inference.

PS3's +79 blob count over PC (1,102 vs 1,023) is NOT explained by RSX-specific additions in a
way we can prove by name. The INFERRED explanation is that PS3's permutation emitter spells
more light × tier combos than PC's does, consistent with the 117 Pg logical names → 1,102 TOC
records ratio in the ELF.

---

## 4. Size histograms

Per-platform blob size distribution, this run:

| Set | N | min | median | mean | max | total |
|---|---:|---:|---:|---:|---:|---:|
| PC `shader3.bin` | 556 | 124 | 4,130 | 4,591 | 20,992 | 2,552,788 |
| PC `shader3Low.bin` | 411 | 124 | 2,100 | 2,061 | 20,396 | 847,480 |
| PC `shaderVT.bin` | 15 | 980 | 4,352 | 4,127 | 7,224 | 61,908 |
| PC `shaderVTLow.bin` | 15 | 980 | 4,352 | 4,127 | 7,224 | 61,908 |
| PC `shaderR2VB.bin` | 13 | 864 | 3,148 | 3,747 | 7,108 | 48,720 |
| PC `shaderR2VBLow.bin` | 13 | 864 | 3,148 | 3,747 | 7,108 | 48,720 |
| **PC combined** | **1,023** | **124** | **2,552** | **3,540** | **20,992** | **3,621,524** |
| **Xbox 360 `shaders.bin`** | **346** | **256** | **2,384** | **2,491** | **5,664** | **862,048** |
| **PS3 `SHADERS.BIN`** | **1,102** | **64** | **2,608** | **2,712** | **6,608** | **2,988,976** |

Interpretation:
- Xbox and PS3 both cap at ~6-7 KB per blob; PC's DX9 bytecode occasionally reaches 20 KB
  (the heavy `PgDiff*_pl_sl_li` light-combined permutations).
- Xbox 346 blobs / 862 KB vs PC combined 1,023 / 3.62 MB: Xbox ships ~34% of the shader count
  and ~24% of the payload. Both ratios match the "PC has 2 quality tiers + R2VB + VT + more
  light perms, Xbox has one unified set" picture.
- PS3 has 1,102 blobs / 2.99 MB — more blobs than PC combined, but 83% of the payload. Smaller
  avg (2.71 KB) is RSX NV bytecode being denser than DX9 SM3.

---

## 5. R2VB-is-PC-only verdict (PROVEN)

The hypothesis holds against the retail data:
- Xbox: 0/12 named R2VB PC stems resolve to any Xbox id (and no additional Xbox stems look
  like R2VB variants).
- PS3: no separate R2VB container; neither the ELF strings nor the SHADERS.BIN layout suggest
  an R2VB code path. (We cannot resolve PS3 names, so this is PROVEN at the container level
  only — a PS3 name resolution would strengthen it to the per-shader level.)

---

## 6. What this does and does not settle

Settled (PROVEN this session):
- PC hash scheme is `pandemic_hash_m2(stem + "_3.sho" | "_3l.sho")`.
- Xbox 360 hash scheme is `pandemic_hash_m2(stem + ".sho")`.
- PC and Xbox name sets are directly comparable; 318 shared, 223 PC-only, 0 Xbox-only.
- R2VB and VT shader paths are PC-only at the ship-asset level.
- PS3 TOC format is 8-byte `(hash, offset)` BE records — **NOT** the (VS, PS) pair format
  Phase 1 inferred. There are 1,102 individual blobs, not 2,204.
- Xbox 360 ships a separate `shaders.bin` (864,832 B); the Phase 1 "baked into XEX" claim is
  wrong.

Open (INFERRED or UNRESOLVED):
- PS3 hash function. The anchor is probably reachable from the single `shaders.bin` string
  reference at ELF offset `0xddb2b2`; the three callers of a `pandemic_hash_m2`-equivalent
  function would decide it quickly. Not pursued here.
- Whether the 28 unnamed Xbox hashes and 84 unnamed PC hashes overlap by name (both samples
  depend on the exe not shipping the string, but both exes may well omit the same shader name).
- The 2 duplicate ids inside the PC bin set (1,021 unique of 1,023) — expected because VT and
  R2VB share one record id per quality tier per `shader_store_format.md` §1 (never resident
  together), but not re-verified this session.

---

## Files

Produced in `scratchpad/`:
- `pc_sho_strings.txt` — 543 `.sho` string stems from the PC exe
- `pc_shader_names.json` — PC bin id → name mapping (where resolvable)
- `pc_stem_to_bins.json` — PC stem → list of bins it appears in
- `xbox_stem_names.json` — 318 Xbox stems resolved
- `pc_only_stems.json` — the 223 PC-only stems
- `xbox_only_stems.json` — empty (every Xbox name is also in PC's exe)

Logs: `/tmp/{toc-scan,ps3-toc,console-toc,pc-names,pc-xbox-diff,size-hist}.log`.

Oracles used: the PC exe (`output/_ghidra/securom_dump/mercs2_unpacked.exe`), PS3 ELF
(`game-files/ps3-version/EBOOT.elf`), Xbox and PS3 shader bins; `tools/pandemic_hash.py` for the
hash itself; the already-settled `docs/shader_store_format.md` §4 for the PC suffix convention.
