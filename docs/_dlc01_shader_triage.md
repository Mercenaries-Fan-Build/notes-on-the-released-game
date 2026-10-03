# DLC01 shader-reference triage — does PC lack any shader DLC01 needs?

**Status:** current · **Evidence:** proven (per-row grading below) · **Date:** 2026-10-03

Companion to `docs/_phase3c_shader_cross_platform.md`. Phase 3.C established that
PC ships 1,023 shader-store programs and PS3 ships 1,102 (an on-disk count
delta of 79), but with `PC ∩ PS3 = 0` on raw store-TOC hashes because the two
platforms use different hash functions for store IDs. The "79-program gap"
is therefore not computable at the raw store-ID level.

The porting-blocker question lives one layer up, at the **material binding**
layer: MTRL records reference a pixel shader by `pandemic_hash_m2(<logical
PS name>)` (`docs/shader_store_format.md` §6; `FUN_00858790` reads the key
and probes the shader pool via `FUN_008242b0(0x800)`). That key space is
the same across PC and Xbox 360 (Phase 3.C §2.1/2.2). PS3 DLC01 content is
byte-identical to Xbox 360 DLC01 content at the ASET and Lua layers
(`docs/dlc_pc_port_status.md`: 5,287/5,287 ASET name hashes equal; 36/36
DLC Lua scripts equal), so DLC01's MTRL shader-key hashes are the same
three-platform set.

---

## 1. Verdict

**2 shader-key hashes referenced by DLC01 materials are PC-unregistered.**

| Metric | Value |
|---|---:|
| DLC01 UCFX containers scanned | 7,795 |
| DLC01 material records parsed | 1,020 |
| Distinct shader-key hashes referenced | **21** |
| Resolved to a PC-registered logical name | **19** |
| **Unresolved on PC** | **2** |

The 2 unresolved hashes are referenced by **219 of 1,020 (21.5%)** of the
DLC01 material records.

---

## 2. Cross-platform table — every DLC01 shader-key hash

Shader hash in column 1 is the u32 pixel-shader key read from each MTRL
record at offset `108 + 4·tex_count` (parser: scratchpad
`extract_dlc01_from_vz_patch.py`). `Logical name` is `pandemic_hash_m2`
reversed against the 1,148 Pg*/Sm* strings and the 32,726 null-terminated
identifier-like strings in `output/_ghidra/securom_dump/mercs2_unpacked.exe`.

| Shader hash | Logical name | PC | PS3 | Uses | Context |
|---|---|---|---|---:|---|
| `0x0ed6b62d` | `PgDiffSpecAmbOccFP` | YES | YES | 2 | mesh materials |
| `0x1123e113` | `PgDiffRimFP` | YES | YES | 17 | mesh materials |
| `0x1560a817` | `PgDiffSpecNormAmbOccFP` | YES | YES | 60 | mesh materials |
| `0x322fcd56` | `PgDiffSpecReflNormAmbOccRimFP` | YES | YES | 1 | skinned templates |
| `0x343af931` | `PgDiffFP` | YES | YES | 94 | mesh materials |
| **`0x3973c300`** | **unresolved** | **NO** | YES | **29** | **`rocks01_*` LOD rocks** |
| `0x3e9a1b40` | `PgDiffAmbOccRimFP` | YES | YES | 46 | mesh materials |
| `0x646add0f` | `PgDiffSpecReflNormFP` | YES | YES | 55 | mesh materials |
| `0x73e7041e` | `PgDiffSpecNormRimFP` | YES | YES | 41 | mesh materials |
| `0x7c326572` | `PgDiffSpecSSSNormAmbOccFP` | YES | YES | 22 | mesh materials |
| `0x7ebc162e` | `PgFastFP` | YES | YES | 40 | fast-path materials |
| `0x83b06225` | `PgDiffSpecSSSNormRimFP` | YES | YES | 6 | mesh materials |
| `0x8925f9e1` | `PgDiffSpecNormAmbOccRimFP` | YES | YES | 78 | mesh materials |
| `0xb68e1be7` | `PgDiffSpecMetalNormFP` | YES | YES | 111 | mesh materials |
| `0xc5faa369` | `PgDiffSpecReflNormRimFP` | YES | YES | 13 | mesh materials |
| `0xcaefe1fe` | `PgDiffSpecNormFP` | YES | YES | 136 | mesh materials |
| `0xde1808c2` | `PgDiffSpecSSSNormAmbOccRimFP` | YES | YES | 36 | mesh materials |
| `0xe48464a0` | `PgDiffAmbOccFP` | YES | YES | 37 | mesh materials |
| **`0xf931343a`** | **unresolved** | **NO** | YES | **190** | **`tinygeometry_*` tiny-mesh scatter** |
| `0xfa98175c` | `PgDiffSpecFP` | YES | YES | 2 | mesh materials |
| `0xfaf74bb1` | `PgDiffSpecMetalNormRimFP` | YES | YES | 4 | mesh materials |

Column notes:
- **PC = YES** means the hash equals `pandemic_hash_m2(name)` for a string
  present in the PC retail exe and registered through `FUN_0084f130`'s
  `FUN_0085ac90(logical_name, name.sho, variant)` run.
- **PS3 = YES** is INFERRED from `docs/dlc_pc_port_status.md` (PS3 DLC01
  content byte-identical to Xbox 360 DLC01 at the ASET/MTRL layer and 36/36
  Lua byte-identical). The shader-key bytes in the MTRL stream are the
  same three-platform value; whether PS3's own engine resolves the key to
  an RSX Cg program is settled by the engine binding path on PS3, not by
  this content check.
- **Uses** is the material-record count that cites that key.

---

## 3. Evidence — the 2 unresolved hashes (PROVEN)

Both `0xf931343a` and `0x3973c300`:

1. Match **0 strings** out of **1,148** `(Pg|Sm)…(FP|VP|…)…` candidates in
   `mercs2_unpacked.exe` under `pandemic_hash_m2`. (Scan:
   `scratchpad/dlc01_shaders/extract_pc_shader_names.py`.)
2. Match **0 strings** out of **32,726** null-terminated ASCII
   identifier-like strings in `mercs2_unpacked.exe`.
3. Match **0 identifiers** out of **133,981** unique identifiers in the
   Xbox 360 retail Ghidra decomp
   (`output/_ghidra_x360_retail/xenon_retail_decomp_named.c`).
4. Match **0 identifiers** in the Xbox 360 preview-prototype PE
   (`output/jul08_prototype/mercs2_xenon_p.pe_full.bin`, 43,002 identifiers).
5. Appear **0 times** as a 32-bit LE constant anywhere in
   `mercs2_unpacked.exe`.
6. Appear **0 times** as any hex-form substring (`08x`/`08X`/`0x…`/decimal)
   in the full 66,580,257-byte `output/_ghidra/mercs2_unpacked.exe_decomp.txt`.
7. Are **not** in any PC shader-store TOC:
   `shader3.bin` 556 recs, `shader3Low.bin` 411, `shaderVT.bin` 15,
   `shaderVTLow.bin` 15, `shaderR2VB.bin` 13, `shaderR2VBLow.bin` 13 — 0 hits.
8. Are referenced by DLC01 MTRL records only in two narrow asset classes:
   `0xf931343a` — all 190 uses are in `blocks\dlc01\…tinygeometry_tgr*_tgc*…`
     (speed city + Chinese Contract 002 tiny-scatter instanced geometry).
   `0x3973c300` — all 29 uses are in `blocks\dlc01\…rocks01_r*_c*…`
     (DLC Chinese Contract 002 rock-LOD meshes).

Material-record layout read for each hash: 104-byte preamble, then at
offset `+104` the `(tex_count<<16)|flags&0x0080` marker, then
`tex_count × u32` texture asset hashes, then the shader key at
`+108+4·tex_count` (parse verified against `0xcaefe1fe = PgDiffSpecNormFP`
appearing at offset 120 in a 3-tex record and at offset 112 in a 1-tex
record). All 1,020 records resolve the marker before extracting the key.

Mtrl_Parse body (`ghidra/FUN_00858790` chunk 2) confirms the key is used
as the probe into `FUN_008242b0(0x800)` against the shader pool
`DAT_01977a3c`/`DAT_01977a40`: on a miss (`iVar15 < 0`) it falls back to
`&DAT_01977a3c` (slot 0, a sentinel), and the u16 shader handle stored at
`material+0x182` becomes whatever sentinel slot 0 carries. The material
renders without a valid pixel-shader binding until the engine's fallback
path takes over.

---

## 4. Interpretation (INFERRED)

The two unresolved keys are hashes of logical pixel-shader names that
PC's `FUN_0084f130` registry never calls `FUN_0085ac90(name, "*.sho", …)`
on. The context — one is used across 112 `tinygeometry_*` blocks and the
other only on `rocks01_*` LOD rocks of Chinese Contract 002 — fits the
shape of **Pandemic Xbox/PS3 specialisation shaders** (tiny-mesh batched
scatter PS and rock LOD PS) that the PC port either did not compile or
registered under names stripped from the retail exe strings. PC's
registry is explicitly a port of Xbox's: Phase 3.C showed PC's
`shader3.bin` is a near-strict superset of Xbox retail's `shaders.bin`
*at the base-game level* (223 PC-only vs 0 Xbox-only). DLC01 is Xbox-side
content; its shader surface was not folded into that port's logical-name
set.

Not DRM, not SecuROM-virtualized, not a corrupt record — a straight
missing-registration gap at the renderer-material binding layer.

---

## 5. Porting next steps per gap

For each PC-missing key, the port needs one of:

| Shader hash | Options |
|---|---|
| `0xf931343a` (`tinygeometry_*`, 190 uses) | **(a)** Add a PC-side registration in a shim/ASI that calls the equivalent of `FUN_0085ac90(<name>, <name>.sho, 0)` and ships the `.sho` blob in a `shader3.bin` append. The logical name must be the one whose `pandemic_hash_m2` equals `0xf931343a` — currently unknown (candidate `Pg(Tiny|MeshTiny…)FP` + light perm families all rejected, 58,912 candidate names tested). Finding the name needs the PS3 EBOOT's shader class strings (`CFragmentShader*Ps3`) or the Xbox retail `shaders.bin`-adjacent `.updb` symbol path. **(b)** Repoint affected DLC01 MTRL records at a PC substitute (likely `PgMeshTinyShadowVP`/`PgMeshTiny*` equivalent FP, `0xcaefe1fe` as a conservative stand-in — these are all 1-tex records). **(c)** Install a PC-side default-fallback shader for the pool slot 0 sentinel. |
| `0x3973c300` (`rocks01_*`, 29 uses) | Same three options; the scope is 10 blocks (DLC Chinese Contract 002 rocks only), so (b) is cheapest — repoint to a PC `PgDiffFP`/`PgDiffAmbOccFP` equivalent (both 1-tex). |

---

## Files

Scratchpad (session scratch, under
`C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/dlc01_shaders/`):

- `extract_pc_shader_names.py` — PC retail exe → shader-name hash set
- `extract_dlc01_from_vz_patch.py` — vz-patch.wad DLC01 → MTRL shader keys
- `resolve_and_cross_check.py` — join tables, print verdict
- `xbox_resolve.py` — Xbox decomp/PE identifier scan
- `dump_mtrl.py` / `debug_block464.py` — manual MTRL record inspection
- `pc_shader_logical_hashes.json` — 1,148 PC Pg*/Sm* name → hash map
- `pc_shader_store_hashes.json` — 1,821 PC `<stem>_3.sho` / `_3l.sho` / `.sho` → hash map
- `dlc01_shader_refs.json` — 21 keys × 1,020 material records + per-block table
- `dlc01_shader_resolution.json` — final per-key resolution table

Oracles:
- `game-files/vz-patch.wad` (185,761,792 B) — holds the merged DLC01 content;
  the 2,196 `blocks\dlc01\…` entries decompress to 7,795 UCFX containers.
- `game-files/shader3.bin` + 5 siblings — PC shader stores.
- `output/_ghidra/securom_dump/mercs2_unpacked.exe` — PC retail exe.
- `output/_ghidra_x360_retail/xenon_retail_decomp_named.c` — Xbox retail
  decomp.
- `output/_ghidra/mercs2_unpacked.exe_decomp.txt` — full PC Ghidra decomp.
- `tools/pandemic_hash.py --m2` — hash validator.
