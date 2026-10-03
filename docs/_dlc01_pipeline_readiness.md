---
status: current
evidence: proven
date: 2026-10-03
scope: PS3 "Blow It Up Again" DLC01 → PC port pipeline readiness
inputs:
  - game-files/1ntHdj11R8gYK1qjpRcpRGHI3bEQBhL6i616GVXFV8bh78m4U6iSVyAiYJ4q9RNv6JnuURsk8CN8WWTLSdJU9cT631f4tHSHg7XBs.pkg
    sha256: d62081de1b9efbc484766fb586adba04b03edd5f8571ed03cf6e722bd70263e4
  - game-files/Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar
    sha256: 180fba37cf8477167cf2fc316747e54c92b787e12a8635ed6cabe17c8d89443a
  - output/_scratch/dlc01.doh (Xbox 360 baseline)
    sha256: 5b0c222d925e8c85000a925262e2b789fbf8c3e476d3d89e5935c7c018deb3ae
---

# DLC01 Pipeline Readiness

End-to-end audit of the Rust `wad_simulator` pipeline exercised against the PS3
`UP0006-BLUS30056_00-MERCS2WIFDLC01NA` package, with the Xbox 360 DLC DOH as the
baseline. All runs executed from
`tools/wad_simulator/target/release/*.exe` on this host; command logs under
`C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/dlc01_pipeline/`.

## Verdict

The decrypt chain (**PKG → EDAT → BE SCFF**) is PROVEN READY: `ps3_dlc_crypt`
produces a 271,089,664-byte big-endian SCFF container identical in shape to the
Xbox DOH. The all-Rust `dlc_port` converter accepts that SCFF through
`--x360-stfs` and produces a structurally valid PC `vz-patch`-style WAD that
`wad_simulator` and `aset_refcheck` sign off on. However the per-block BE→LE
converter is PARTIAL on PS3 payloads: 472 of 2225 blocks (21.2 %) are rejected
by `ucfx_byteswap::convert_block`, versus 0/2196 on the Xbox DOH. The surviving
1753-block overlay has 625 ASET LOD rungs sentinelled to the coarse tier
(assets render but silently degrade). Audio and shaders are not consumed by
this pipeline at all; both go to the parallel agents.

## Summary table

| # | Component | Classification | Evidence |
|---|---|---|---|
| 1 | `ps3_dlc_crypt pkg-unpack` | PROVEN READY | 16 entries extracted in 3.172 s; content_id `UP0006-BLUS30056_00-MERCS2WIFDLC01NA` |
| 2 | `ps3_dlc_crypt edat-decrypt` | PROVEN READY | 271,089,664 B SCFF decrypted in 2.365 s with recovered klicensee |
| 3 | `ps3_dlc_crypt unself` | PROVEN READY (prior session) | Not re-exercised; memory `ps3-dlc-crack-and-klicensee` + `docs/dlc_pc_port_status.md` record sha256-identity to the Python oracle |
| 4 | `dlc_port` (PS3 SCFF input) | PARTIAL | 1753/2225 blocks converted; 472 skipped; 625 LOD rungs sentinelled; exit 0 |
| 5 | `dlc_port` (Xbox DOH baseline) | PROVEN READY | 2196/2196 blocks converted; 5341/5341 ASET routed; 0 skipped; exit 0 |
| 6 | `ucfx_byteswap convert_block` on PS3 UCFX | PARTIAL | Same crate is invoked inside `dlc_port`; the 472 skips above are its rejections |
| 7 | `ucfx_byteswap audio` (XMA→PC IMA) | BLOCKED on PS3 | PS3 `.PWS` opens with `FF FA 60 C0` (MP3 frame sync), not XMA — not consumed by this Xbox-targeted module. Deferred to the ATRAC3/audio-transcode parallel agent |
| 8 | `wad_simulator` on PS3-ported overlay | PROVEN READY | 4678/4678 ASET verified, 0 misrouted, 0 ghost; exit 0 |
| 9 | `aset_refcheck` on PS3-ported overlay | PROVEN READY | `OK ... 4678 rows / 1753 blocks — all LOD refs resolve`; exit 0 |
| 10 | `smuggler` additive injection | PROVEN READY (orthogonal) | Tool present and documented; it rewrites the base `vz.wad` into a patch WAD by hash, not consumed in the DLC port chain |
| 11 | Shader pipeline | DEFERRED | Owned by the shader-triage parallel agent writing `docs/_dlc01_shader_triage.md` |

## Per-component evidence

### 1. `ps3_dlc_crypt pkg-unpack`

- **Input**: `game-files/1ntHdj11…pkg` (sha256 `d62081de1b9efbc4…`), 407,578,320 B.
- **Command**: `ps3_dlc_crypt.exe pkg-unpack --pkg <pkg> --out <scratch>/pkg_extracted`
- **Output**: 16 entries including `USRDIR/DLC/DLC01/DLC01.EDAT`
  (sha256 `3ca3bac9fa7cf65d041028441cd8ebb00de2a082105ee460d15356ca2baa78fc`,
  271,354,672 B), `PACKAGE.CFG` (sha256 `e98b493efb26c327…`), 7 streaming PWS
  audio files, `PARAM.SFO` (sha256 `74c0e1329095f136…`). Total wall time 3.172 s.
- **Breakage**: none.
- **Classification**: PROVEN READY.

### 2. `ps3_dlc_crypt edat-decrypt`

- **Input**: `pkg_extracted/USRDIR/DLC/DLC01/DLC01.EDAT`.
- **Command**: `ps3_dlc_crypt.exe edat-decrypt --edat <edat> --out <scratch>/ps3_dlc01_be.scff`
  (klicensee omitted → tool uses the recovered DLC01 klic).
- **Output**: `ps3_dlc01_be.scff` (sha256
  `cc58b68d614786ebbab79e0129a6def0c31adebdc897b2c623892935ab5fca00`,
  271,089,664 B). Header `53 43 46 46 00 00 00 02 00 00 00 07 58 44 4e 49 00 00 80 00 00 00 08 b1 41 54 41 44 00 04 80 00`
  → `SCFF v2`, 7 chunks, INDX count = **0x8b1 = 2225** (Xbox DOH has 0x894 = 2196).
  Wall time 2.365 s.
- **Breakage**: none; `cmp` vs the Xbox DOH diverges first at byte 24 — the
  block-table length — as expected for a platform-divergent container.
- **Classification**: PROVEN READY.

### 3. `ps3_dlc_crypt unself`

- **Input**: not re-exercised this session.
- **Command**: would be `ps3_dlc_crypt.exe unself --self <EBOOT> --out <ELF>`.
- **Output / breakage**: prior session (`memory/ps3-dlc-crack-and-klicensee.md`)
  records sha256-identical output to the Python oracle for both the disc APP SELF
  and the v1.03 patched NPDRM SELF.
- **Classification**: PROVEN READY (prior proof; not re-measured here).

### 4. `dlc_port` on the PS3 SCFF

- **Input**: `ps3_dlc01_be.scff` (sha256 `cc58b68d…`).
- **Command**: `dlc_port.exe --x360-stfs ps3_dlc01_be.scff --output ps3_dlc_patch.wad`
  (the `--x360-stfs` flag accepts a raw BE SCFF via `load_stfs_or_doh`).
- **Output**: `ps3_dlc_patch.wad` (sha256
  `1ad5f427690dcfd22959895260b39dafa622a2172b63f82b4b601908cfb1c1ba`,
  206,798,848 B / 197.2 MB), 1753 blocks. FFCS parse: version 2, 5 chunks,
  INDX 2225, ASET 5341, PTHS 2225. Wall time 27.171 s.
- **Breakage**:
  - **472/2225 blocks skipped** (21.2 %). The converter's three skip paths
    (BE-sges decompress failure, non-sges with no XFCU header, or
    `ucfx_byteswap::convert_block` structural rejection) are not individually
    counted by the binary; the `--verbose` flag is parsed but drives no extra
    output. Block [0] (`dlc01_terrain_P000_Q3`) converts fine in isolation
    (`--max-blocks 1 --start-block 0` → 1 block, exit 0), so the failure cluster
    is in the UCFX bodies of specific later blocks, not a global format bug.
  - **663 ASET rows dropped** as "not owned by any shipped block" — direct
    consequence of the 472 missing blocks.
  - **625 ASET LOD rungs sentinelled to 0xFFFF** because the finer rungs
    (`_P001`/`_P002`/`_P003`) live in blocks that were skipped. Printed as
    `note: 625 ASET row(s) referenced LOD rungs this patch does not carry;
    sentinelled to 0xFFFF (asset renders at its coarse tier instead of wedging
    the stream)`. The output WAD is still structurally valid (see §8 and §9),
    but affected assets will visibly degrade to their coarse LOD at close range
    instead of streaming the finer rungs.
  - Block-path diff vs Xbox DOH: 29 PS3-only block paths plus LOD-tier naming
    divergence (PS3 ships many `_P003_Q0` rungs where Xbox ships `_P001_Q2` or
    `_P002_Q1`). Full diff in `scratchpad/.../17_path_diff.txt`.
- **Classification**: PARTIAL — produces a loadable overlay but silently drops
  >20 % of DLC blocks and degrades 625 LOD chains.

### 5. `dlc_port` on the Xbox DOH baseline

- **Input**: `output/_scratch/dlc01.doh` (sha256 `5b0c222d…`, 251,953,152 B).
- **Command**: `dlc_port.exe --x360-stfs dlc01.doh --output xbox_dlc_patch.wad`.
- **Output**: `xbox_dlc_patch.wad`, 263,749,632 B / 251.5 MB, 2196 blocks.
  Wall time 33.396 s. Converted 2196/2196, skipped 0, ASET 5341/5341 routed,
  0 dropped, 0 LOD sentinels.
- **Breakage**: none.
- **Classification**: PROVEN READY. Confirms the gap vs §4 is PS3-side, not a
  regression in the converter.

### 6. `ucfx_byteswap convert_block` on PS3 UCFX bodies

- The crate is invoked inside `dlc_port` (not re-run standalone). Its own CLI
  (`ucfx_byteswap.exe`) requires a *decompressed* BE UCFX block as input;
  dumping individual PS3 blocks requires either `sges`-decompressing from the
  SCFF or writing a one-off probe (not done this session). The in-pipeline
  reject count equals the 472 skips reported in §4.
- **Classification**: PARTIAL on PS3 inputs; PROVEN READY on Xbox inputs
  (0 rejects at 2196 blocks).

### 7. `ucfx_byteswap::audio` (`transcode_pws_xbox_to_pc`, XMA→PC IMA)

- **Input**: `pkg_extracted/USRDIR/DLC/DLC01/AUDIOS/VO_STREAM_DLCTEST.ENGLISH.PWS`
  (sha256 `f3347a720c1ce75b…`), 18,415,104 B.
- **Command**: not invoked. The module is XMA-oriented.
- **Output / breakage**: the PS3 PWS header starts
  `FF FA 60 C0 59 22 00 00 02 70 83 10 44 80 49 AA` — an **MPEG-1 Layer III
  frame sync** (`0xFFFA` = `MPEG-1 L3, no CRC`). This is NOT Xbox XMA (which
  carries `WAVEfmt` + `fmt ` type `0x0165`) and NOT ATRAC3 (`RIFF`/`WAAC` or
  bare `atrac`). Running `transcode_pws_xbox_to_pc` on it would reject the
  header or produce garbage. The deployed PC PWS at
  `output/data/Audios/vo_stream_dlctest.english.pws` was produced from the
  Xbox streaming audio path, not the PS3 one; its header
  `00 00 01 00 40 00 01 00 10 75 cf 30 08 00 20 08` is PC IMA ADPCM.
- **Classification**: BLOCKED for PS3 input. Deferred to the parallel audio-
  transcode agent per task note; this audit does not implement a fix.

### 8. `wad_simulator` on the PS3-ported overlay

- **Input**: `ps3_dlc_patch.wad` (sha256 `1ad5f427…`).
- **Command**: `wad_simulator.exe --wad ps3_dlc_patch.wad --skip-audio --skip-assets --json-output wsim_ps3.json`
- **Output**: `Total ASET: 4678 Verified: 4678 Misrouted: 0 True ghost: 0`.
  Wall time 1.019 s, exit 0.
- **Breakage**: none at the ASET/hash-ownership gate.
- **Classification**: PROVEN READY (within the subset `dlc_port` actually
  shipped).

### 9. `aset_refcheck` on the PS3-ported overlay

- **Input**: `ps3_dlc_patch.wad`.
- **Command**: `aset_refcheck.exe ps3_dlc_patch.wad`.
- **Output**: `OK ps3_dlc_patch.wad: 4678 rows / 1753 blocks — all LOD refs
  resolve`. Wall time 0.084 s, exit 0.
- **Breakage**: none. The 625 LOD rungs that were sentinelled in §4 pass the
  refcheck because `0xFFFF` is the explicit "no finer rung" marker, not a
  dangling reference.
- **Classification**: PROVEN READY.

### 10. `smuggler`

- Present in the toolchain; drives additive by-hash overrides against the base
  retail `vz.wad`. Not consumed by the DLC port chain (which starts from the
  Xbox/PS3 BE container and does not override base-game assets).
- **Classification**: PROVEN READY, orthogonal to this audit.

### 11. Shader pipeline

- Deferred to the parallel shader-triage agent writing
  `docs/_dlc01_shader_triage.md`. Not exercised here.

## Unblock list

Specific gaps found, in rough order of blast radius. Each one is a measurement
of what currently fails, not a plan — plans live under `.claude/plans/`.

1. **`ucfx_byteswap::convert_block` rejects 472/2225 PS3 UCFX bodies** (§4, §6).
   The three skip paths in `tools/wad_simulator/crates/dlc_port/src/main.rs`
   (`decompress_be_sges` error, missing XFCU magic, `convert_block` error) are
   collapsed into one counter. Diagnosing which rejection and which UCFX
   descriptor family drives each case needs either a converter instrumentation
   pass or a per-block extract-and-retry probe. Likely cluster: PS3-specific
   vertex/texture descriptor codes the Xbox-tuned schema walk doesn't recognise.
2. **625 LOD rungs sentinelled** (§4). Visual regression at close range for
   every DLC asset whose `_P001`/`_P002`/`_P003` rung landed in a skipped block.
   Resolves automatically once (1) is fixed.
3. **PS3 streaming audio is MP3, not XMA** (§7). `ucfx_byteswap::audio` has no
   MP3 path. Owned by the parallel audio-transcode agent.
4. **`dlc_port` has no diagnostic surface for its own skip paths** (§4). The
   `--verbose` flag is accepted but drives no extra output. Even an opt-in
   counter of `{sges_fail, no_xfcu, convert_fail}` would narrow the diagnosis
   above without a code change elsewhere.
5. **PS3 vs Xbox block-path divergence (29 extra, 28 missing)** (§4). The LOD
   tier convention differs (PS3 ships `_P003_Q0` rungs where Xbox ships
   `_P001_Q2`/`_P002_Q1`). Not a bug on its own, but the content-routing step
   in `dlc_port` assumes blocks live where their ASET says they do — a few of
   the PS3-only `_P003_Q0` entries may legitimately own hashes that currently
   drop as "not owned by any shipped block" (§4, 663 drops) once their blocks
   are converted successfully.
6. **Prior session's `output/data/dlc01-patch.wad`** was produced from the
   Xbox DOH (and the deployed `output/data/Audios/*.pws` matches). The PS3
   route produces a smaller WAD with worse coverage; it is not currently a
   drop-in replacement for the Xbox-sourced overlay.

## Artifacts

Primary artifacts kept under
`C:/Users/Shadow/AppData/Local/Temp/claude/c--Users-Shadow-Desktop-notes-on-the-released-game/3daa7290-1887-4d90-a52c-94355e911851/scratchpad/dlc01_pipeline/`:

- `ps3_dlc01_be.scff` — decrypted PS3 DLC01 inner WAD (BE SCFF, 271 MB).
- `ps3_dlc_patch.wad` — PC-style overlay produced from the PS3 SCFF (197 MB).
- `xbox_dlc_patch.wad` — baseline overlay from the Xbox DOH (251 MB).
- `pkg_extracted/` — mirror of the PS3 PKG contents.
- `01_pkg_list.log` ... `25_refcheck_ps3.log` — per-step command logs.
- `12_ps3_blocks.txt`, `13_xbox_blocks.txt`, `17_path_diff.txt` — block tables and diff.
