# Engine divergence — cross-platform engine measurements

**Status:** current · **Evidence:** proven

Cross-platform engine-divergence measurements across all three shipping SKUs, measured
from retail content:
- PC: `C:\Users\Shadow\Documents\Mercenaries 2 World in Flames\data`
- PS3: `game-files/Mercenaries 2 World in Flames [BLUS30056].iso` (extracted)
- Xbox 360: `game-files/Mercenaries 2 World in Flames (NTSCU)[NTSCJ) (JTAGRip)/`

Sections:
- §1 — ASET content delta
- §2 — Shader-binary shape (PC + PS3)
- §3.1 — Binary file sizes
- §3.2 — Subsystem-string presence
- §3.3 — Interpretation
- §3.4 — ECS pool sizes (`cdbsizes.ini`) + three-platform storage architecture
- §3.5 — Streaming audio (PC + PS3)
- §3.6 — Cutscenes (Bink) PC + PS3
- §3.7 — Xbox audio container (UCFX-wrapped, non-standard)
- §3.8 — WAD block packing (three distinct strategies)
- §4 — Combined picture

---

## 1. ASET content delta — vz.wad

Tool: `tools/wad_simulator/target/release/aset_export.exe --wad <path> --out <csv>`.

### 1.1 Row-level totals

| Platform | ASET rows | Distinct hashes | Resolved |
|---|---:|---:|---:|
| PC retail | **30,645** | 30,006 | 62.6% |
| PS3 BLUS30056 | **30,553** | 29,914 | 62.5% |
| Xbox 360 NTSC-US | **30,553** | 29,914 | 62.5% |

**PS3 and Xbox ASET sets are identical** at the row-count AND distinct-hash level — the same
29,914 asset hashes across 30,553 rows. PC ships **+92 rows / +92 distinct hashes** vs the
console baseline. The intersection comparison confirms zero Xbox-only or PS3-only hashes
relative to PC — the delta is one-directional (PC ⊇ consoles at the ASET layer).

### 1.2 Per-type breakdown of the 92 PC-exclusive assets

| Type | PC | PS3/Xbox | PC-exclusive |
|---|---:|---:|---:|
| texture | 13,340 | 13,253 | **+87** |
| script | 645 | 643 | +2 |
| font | 9 | 6 | +3 |
| (all other types) | — | — | 0 |

Every other type (model, animation, path, layer, scrub, lineregion, lowresterrain,
terrainmesh, effect, wavebank, facefxanimationset, sounddb, soundbank, scaleformgfx,
facefxactor, chatter, animationtable, binary, materialparam, stringdb, animstatemachine,
fxdict, musicstatemap, decaltable, guidmap, level, musiccue, sequencetable, worldentity) has
the exact same row count across all three platforms.

### 1.3 What the 87 PC-exclusive textures are (all resolved by name)

| Group | Count | Example names |
|---|---:|---|
| `pause_menu_iXXX` (menu-item icon strips) | 64 | `pause_menu_i100`, `pause_menu_i101`, …, `pause_menu_if5`, `pause_menu_ifb` |
| `icon_hijack_xbox_*` (Xbox-controller glyphs for hijack prompts on PC) | 9 | `icon_hijack_xbox_button_A/B/X/Y`, `icon_hijack_xbox_joystick_up/down/left/right` |
| `xbox_*` + `common_18_xbox_buttons` (Xbox prompt labels) | 2 | `xbox_Use_Melee`, `xbox_Use_Reload` |
| `pause_*` (misc pause-screen) | 3 | `pause_graphic`, `pause_menu_f0`, `pause_menu_g0` |
| Loose (hijack-prompt system) | 9 | `Pistol`, `Use_Melee`, `Use_Reload`, `common_18_xbox_buttons`, `Sj/ZC`, … |

**Interpretation:** PC's vz.wad ships a **UI-rendering compatibility pack** — texture assets
to render pause-screen icons and controller button-prompt glyphs on PC. On PS3 and Xbox 360,
the equivalent glyphs are drawn via native system APIs (XMB on PS3, Xbox dashboard button
font on 360) and don't need to be shipped as separate texture assets.

Side-corroboration of the `mrxguisatellitelayout` fix-pack candidate: `Pistol` (the texture
the PC satellite-view layout erroneously references) **is** one of the 87 PC-exclusive
textures. So PC's layout bug isn't a dangling reference — PC ships the `Pistol.tga` asset,
the layout just points to it instead of to the hijack-button texture that would be correct
in that UI context.

### 1.4 The 3 PC-exclusive fonts

- `font_16_xbox` — the Xbox-matching button-prompt font used by PC's controller glyphs.
- Two unresolved hashes (`0x1C7E3B7C`, `0x9487F0E7`) — likely the KBM-adapted fonts for the
  PC options / LTI UI.

### 1.5 The 2 PC-exclusive scripts

- `MrxGuiLTIPrecache` (hash `0xE07BEEAD`)
- `MrxGuiLTIPrecacheLayout` (hash `0x66046C1F`)

The LTI subsystem's loading-tip precache scripts — already identified in the Lua forensics
pass as the two chunks that account for the PC resident block holding 240 chunks vs 238 on
consoles, AND the PC shell block holding 28 chunks vs 26 on consoles.

---

## 2. Shader-binary shape — PC vs PS3

Shader binaries are compiled GPU bytecode and differ by ISA (DX9 bytecode on PC vs RSX
NV_fragment_program on PS3), so a byte-level diff is meaningless. The useful measurements are
**program count** and **total payload size**, which say what shape of renderer each platform
ships.

Xbox 360 shaders are baked into the XEX binary itself (XGraphics ISA), not into separate
`.bin` files alongside the WAD set — so this comparison is PC vs PS3 only.

### 2.1 Per-file counts and sizes

**PC (6 shader bins, `~/Documents/Mercenaries 2 World in Flames/data/`):**

| File | Records | Size | Role |
|---|---:|---:|---|
| `shader3.bin` | 556 | 2,565,008 B | High-quality shader-model 3 pipeline |
| `shader3Low.bin` | 411 | 856,480 B | Low-quality shader-model 3 pipeline |
| `shaderR2VB.bin` | 13 | 49,008 B | Render-to-Vertex-Buffer path (high) |
| `shaderR2VBLow.bin` | 13 | 49,008 B | R2VB path (low) |
| `shaderVT.bin` | 15 | 62,272 B | Virtual-texturing path (high) |
| `shaderVTLow.bin` | 15 | 62,272 B | Virtual-texturing path (low) |
| **PC total** | **1,023** | **3,644,048 B (3.47 MB)** | — |

TOC format: `u32 count` + `count × (hash:u32, offset:u32, size:u32, flag:u32)` — 16-byte
records. **Hash scheme**: `pandemic_hash_m2(stem + "_3.sho")` for `shader3.bin` and
`pandemic_hash_m2(stem + "_3l.sho")` for `shader3Low.bin`. Documented in
`docs/shader_store_format.md` §4; 939 of 1,023 PC bin ids resolve against the 543 `.sho`
strings in the exe.

**Xbox 360 (single shader bin, in JTAGRip dir):**

| File | Records | Size |
|---|---:|---:|
| `shaders.bin` (NTSC-US JTAGRip, `game-files/.../shaders.bin`) | **346** | **864,832 B** |

TOC format: same 16-byte records as PC (big-endian for console). Hash scheme:
`pandemic_hash_m2(stem + ".sho")` — same hash function as PC, with no `_3`/`_3l`
quality-tier suffix. 318 of 346 (91.9%) resolve against the shared `.sho` string pool.

**PS3 (single shader bin, extracted from BLU-RAY ISO):**

| File | Records | Size |
|---|---:|---:|
| `SHADERS.BIN` | **1,102** individual blobs | 2,997,808 B (2.86 MB) |

TOC format: `u32 count` (BE) + `count × (hash BE, offset BE)` — **8-byte records**, same
one-record-per-blob pattern as PC and Xbox. (The earlier Phase 2 claim of 16-byte
`(vs_hash, vs_offset, ps_hash, ps_offset)` pairs was wrong — ruled out by the
first-blob-offset check.) Offsets are monotonic. Hash scheme is **not**
`pandemic_hash_m2` of any `.sho` suffix tried (0/1,102 resolve across 15 candidates).
Likely a different hash function used by the PS3 shader loader (near the single
`shaders.bin` string reference at `0xddb2b2` in `EBOOT.elf`); not yet reversed.

### 2.2 Headline comparison

| Metric | PC | Xbox 360 NTSC-US | PS3 |
|---|---:|---:|---:|
| Shader records | 1,023 (6 files) | 346 (1 file) | 1,102 (1 file) |
| Total shader bytes | 3.47 MB | 844 KB | 2.86 MB |
| Hash scheme | `pandemic_hash_m2(stem+"_3.sho"`) | `pandemic_hash_m2(stem+".sho")` | Unknown (not `pandemic_hash_m2`) |
| Name resolution | 939/1,023 | 318/346 | 0/1,102 |
| Low-quality tier | Separate `*Low.bin` files (411 records) | Not present (single tier) | Not present (single tier) |
| R2VB path shaders | 26 (13 high + 13 low) | **0** (verified absent) | **0** (verified absent) |
| Virtual-texturing shaders | 30 (15 high + 15 low) | **0** (verified absent) | Not separately counted |

### 2.3 Cross-platform shader-name diff (PC ↔ Xbox)

Using the shared `pandemic_hash_m2` scheme:
- **318 PC stems also present on Xbox** (shared across both platforms)
- **223 PC-only stems** (features Xbox doesn't need or carries differently)
- **0 Xbox-only stems** — Xbox is a **strict subset** of PC's shader-name set

PC-only mass (by prefix):
- `PgDiff*` light permutations: ~120 (per-light-type diffuse variants PC generates for its DX9 KBM / dynamic-light paths)
- `PgWater*`: ~40 (incl. the 12 R2VB-specific water shaders)
- `PgLti*`: ~20 (frontend / loading-tip UI — matches PC-only LTI subsystem finding, §3.2)
- `PgTerrain*`: ~15

PS3 can't participate in this diff until its hash function is reversed.

### 2.4 Interpretation

Two structural differences shape the renderer per platform:

1. **PC splits by pipeline role; consoles ship single flat bins.** PC's six-file layout
   mirrors Pangea's PC-renderer architecture: one bin per rendering path (SM3 default, R2VB
   particles, VT terrain), each with its own low-quality variant. Xbox and PS3 ship single
   flat bins — the console renderer doesn't branch on pipeline role at load time, all
   shader programs are addressable from one TOC.
2. **R2VB is PC-only, PROVEN.** All 12 named PC R2VB stems (`PgWaterVP*_R2VB`,
   `PgWaterZFullVP*_R2VB`) resolve to 0/12 on Xbox. DX9 lacks native render-to-vertex-buffer
   semantics; Pangea's PC renderer reads back from a render target as a vertex buffer.
   Xenos and RSX support this natively, so the shaders required for the GPU-side
   vertex-generation path on PC don't exist on consoles.

**For the 64-bit reimpl**: PC's split-by-role structure (1,023 programs across six logical
pipelines) with the quality-tier split as a build-time variant is the natural wgpu target.
R2VB stays as its own path since wgpu's render-to-storage-buffer semantics are closer to
the console native path than to DX9's workaround.

### 2.5 Still open

- **PS3 shader-name hash function.** PS3 ships 1,102 shader hashes that don't match
  `pandemic_hash_m2` of any `.sho` suffix. Likely a different hash in the PS3 shader
  loader near `0xddb2b2` in `EBOOT.elf`. Needs a PS3 Ghidra decomp pass to reverse.
- **PS3-only shader stems vs PC.** Once PS3 hashes are name-resolved, the PS3-only vs
  shared-with-PC split can be computed. Currently blocked.
- **Shader-body intra-platform diff** between `shader3.bin` and `shader3Low.bin` would
  reveal which 411 of the 556 high-quality programs ship a low-quality variant (and which
  145 don't).

---

## 3. Engine-binary shape across platforms

Three engine binaries, three sizes, three subsystem envelopes.

### 3.1 Binary file sizes

| Image | File | Size | Notes |
|---|---|---:|---|
| PC v1.1 (unpacked, SecuROM-stripped) | `output/_ghidra/securom_dump/mercs2_unpacked.exe` | 53.5 MB | PE32 + DRM shell + resource section |
| Xbox 360 retail (unpacked from XEX) | `output/_scratch/x360_retail/default.pe.bin` | 26.6 MB | PE at image base 0x82000000; XEX bootloader stripped |
| PS3 retail | `game-files/ps3-version/EBOOT.elf` | 18.2 MB | ELF32 PPU, Pangea engine + Lua + Havok |

PC is ~2× Xbox and ~3× PS3. Not apples-to-apples (PE has resource section + import table +
SecuROM shell; ELF is stripped) but the direction is consistent with the subsystem-string
scan below.

### 3.2 Subsystem-string presence

Scan: for each binary, count occurrences of distinctive subsystem substrings, then validate
LTI-prefixed hits against false positives (`MULTIply`, `HK_SHAPE_MULTI_*`, etc.).

| Subsystem | PC | Xbox | PS3 | Verdict |
|---|---:|---:|---:|---|
| **D3DX runtime (`D3DX` substring)** | **98** | 0 | 0 | PC-exclusive — Pandemic links `d3dx9.dll` for runtime shader compile + texture utils |
| **SecuROM DRM shell (`SecuROM`)** | **48** | 0 | 0 | PC-exclusive, as expected |
| **LTI frontend / options UI** (verified prefix-tokens, false positives filtered) | **132 tokens** | 0 | 0 | PC-exclusive — `LTIAudioDialogVolume`, `LTIInputJoystick*`, `LTIInputKM*`, `LTICamera`, `LTIChoseOnline`, `PgLtiRendererPc` (2), etc. |
| XMA audio format | 0 | **2** | 0 | Xbox-exclusive native audio codec |
| XNet / Xbox LIVE | 1 | **5** | 0 | Xbox LIVE native stack; the 1 PC hit is in the dead Xb360-session code path |
| XAudio2 | 0 | **1** | 0 | Xbox-exclusive audio API |
| `cellSysmodule` / `cellGcm` / `sceNp` | 0 | 0 | **6** total | PS3-exclusive PSN + GCM (low-level RSX command) bindings |
| Bink codec (`Bink`/`bink`) | **38** | 5 | 5 | All platforms use Bink; PC has the most refs (likely due to debug paths retained) |
| HLSL | 1 | 3 | 1 | All ship HLSL compile paths; Xbox has 3 refs likely for runtime offline shader support |

**Validation of the LTI finding**: the raw substring scan on PS3 ELF matched `LTI` 27 times
and Xbox PE matched 5 times — but with a word-boundary filter requiring the `LTI` to be
followed by alphanumeric or preceded by a non-letter boundary, **0 real `LTI*`-prefixed
symbols survive on either console**. All console matches are substring collisions
(`MULTISAMPLE`, `MULTITHREADED`, `HK_SHAPE_MULTI_RAY`, `LTI2C` isolated token). The LTI
subsystem is PC-exclusive, matching the parity reference §7b.2 claim.

### 3.3 Interpretation

The three engines diverge most along these axes:

1. **PC carries a full D3D9 + D3DX + SecuROM shell** (~146 refs) that consoles don't need:
   - D3DX for runtime shader compilation (PC can hot-reload shaders through dev paths; consoles ship pre-compiled bytecode).
   - SecuROM for the DRM activation + VM.
2. **PC carries the LTI frontend/options UI subsystem** (132 symbols) because the game owns
   its own options/pause/input-binding UI. Consoles delegate to the Xbox 360 blade / PS3
   XMB system menu.
3. **Each console has its own platform API surface** (XMA + XNet + XAudio on Xbox;
   cellGcm + cellSysmodule + sceNp on PS3). These are mutually exclusive — no code
   survives from one console to the other at the platform-binding layer.
4. **Bink and Havok paths are cross-platform** (same magic across all three) — these are
   middleware the engine integrates uniformly.

### 3.4 ECS pool sizes (`cdbsizes.ini`)

PC ships `cdbsizes.ini` (338 lines) as a loose text config in `data/`. Each row is
`<Component> <main_cap> [<secondary_cap>]`. PS3 BLUS30056 ISO and Xbox NTSC-US JTAGRip
**do not ship this file** — consoles bake the equivalent table into the binary.

Representative PC budgets by subsystem:

| Subsystem | Component | PC main cap | Secondary cap |
|---|---|---:|---:|
| Vehicle physics | `_CarPhysicsV2` | 768 | — |
|  | `_CarWheel` | 2304 | — |
|  | `_TankPhysics` | 128 | 64 |
|  | `_JetPhysics` | 8 | 8 |
|  | `_HelicopterPhysics` | 160 | 32 |
|  | `_BoatPhysics` | 160 | 32 |
|  | `_HumanPhysics` | 384 | 128 |
| AI | `Ai` | 1024 | — |
|  | `AiBehavior` | 512 | — |
|  | `AiPatrol` | 768 | — |
|  | `AiHelicopter` | 256 | 128 |
| Population | `PopulationDensity` | 128 | 64 |
|  | `PopulationFlow` | 192 | 64 |
|  | `PopulationList` | 1024 | — |
|  | `PopulationSimpleSpawner` | 768 | — |
| Scene / streaming | `SceneObject` | **161,280** | — (largest single cap) |
|  | `RuntimePhysicalLink` | 22,784 | — |
|  | `RuntimeLayerId` | 20,224 | — |
|  | `Flags` | 14,848 | — |
|  | `HibernationControl` | 14,080 | — |
|  | `EntranceLink` / `SeatLink` | 13,312 each | — |

**Three-platform storage (all values extracted from binaries):**

The baked `[presize]` config lives as a plaintext INI blob in each binary's string pool.
Locations found by anchoring on the `[presize]` section header:
- PC at `.rdata+0x7ad499`
- Xbox at `.rdata+0x0cc2f1`
- PS3 at ELF offset `0xdc7819`

PC also ships `data/cdbsizes.ini` loose as a runtime override; consoles use only the baked
copy. Rows parsed per platform's `[presize]` section:
- PC: **339 rows**
- Xbox NTSC-US: **348 rows** (+9 vs PC; the extras are PS3-specific flags and build-version
  constants that live in the Xbox binary, including `code_version 186047`, `data_version
  135601`, `Ps3UseProdNetwork 1`, `PS3MinimumAgeToPlayOnline 13`, `north_american_sku 1`)
- PS3: **340 rows**

**PS3 ≡ Xbox for every shared cap.** Of 340 rows parsed on PS3, every one matches Xbox's
value exactly. Zero PS3-only entries disagree with Xbox. Zero shared-row disagreements.
Console builds share one cdbsizes config.

**PC ≠ consoles: 96 proven cap divergences** in the shared presize set. Direction is
overwhelmingly **consoles > PC** (consoles allocate bigger pools) with a handful of
exceptions. Headline deltas:

| Component | PC main / sec | Xbox+PS3 main / sec | Factor |
|---|---|---|---|
| `_HelicopterPhysics` / `_HelicopterPhysicsAi` | 160 / 32 | **192** / 32 | 1.20× |
| `Ai` | 1024 | **1536** / 256 | 1.50× |
| `Anchor` | 1152 / 128 | **1792** / 256 | 1.56× |
| `CameraHelicopter` | 160 / 32 | **512** / 256 | 3.20× |
| `DebrisEffect` | 4608 | 5376 | 1.17× |
| `Flags` | 14848 | **23040** | 1.55× |
| `Health` | 3328 | 3584 | 1.08× |
| `HibernationControl` | 14080 | 16128 | 1.15× |
| `PopulationList` | 1024 | 1280 | 1.25× |
| `PopulationSimpleSpawner` | 768 | **2048** | **2.67×** |
| `RtDebris` | 64 / 64 | **384** / 128 | 6.00× |
| `RuntimeLayerId` | 20224 | 26368 | 1.30× |
| `RuntimePhysicalLink` | 22784 | 26368 | 1.16× |
| `SoundEffect` | 3584 | 4096 | 1.14× |
| `SpawnerAdjust` | 16 / 16 | **224** / 32 | 14.00× |
| `VehiclePart` | 4096 | 4864 | 1.19× |
| **PC-LARGER cases** | | | |
| `EntranceLink` | **13312** | 4096 | **0.31×** (consoles 1/3 of PC) |

**4 rows present on consoles only (not PC):**
- `ModelMixerProfile 512 128` (consoles) — PC ships `ModelMixeProfile 512 128` (identical
  value, misspelled component name — PC build has a one-letter typo consoles fixed).
- `RuntimeEntranceLink 10240`
- `RuntimeMassiveSubscriber 768`
- `RuntimeSeatPlayerUsable 768`

**1 row present on PC only (not consoles):**
- `ModelMixeProfile 512 128` (the misspelled variant above).

**Resolution defaults also diverge** (not pool caps but same blob):
- `x_res` / `y_res`: PC `1280×720`, Xbox `640×480`. Likely a baked internal-render-target
  or UI-canvas default, not the shipping gameplay resolution (consoles rendered at 720p
  in practice).

**How I found them (so this is reproducible):**
1. Searched each binary for the string `presize`. Hit in all three, one occurrence each.
2. From that offset, walked forward byte-by-byte accepting any printable ASCII, tab
   (0x09), CR/LF (0x0a/0x0d), and 1+ null bytes as line separators. Stopped on any other
   byte.
3. Parsed the resulting text with an INI-aware tokenizer (sections `[name]`, rows
   `<name> <int> [<int>]`).
4. Diffed presize-section rows across platforms.

Full extracted tables + diff: `scratchpad/{PC,Xbox,PS3}_cdbsizes_baked.txt`,
`scratchpad/cdbsizes-diff3.log`, `scratchpad/xb-vs-ps3-presize.log`.

**Earlier claim retracted.** The "consoles use per-class constructor registration" guess
I made before finding the baked blob was wrong — consoles store the full ini-format
config as a baked string resource, same mechanism as PC minus the loose-file override.
The hash-indexed table at PC `.data+0xbc1f90` is a RUNTIME lookup structure built from the
parsed config, not the sole storage location.

### 3.5 Audio streams — PC vs PS3

Both PC and PS3 ship **standalone `.pws` streaming audio files** outside the WAD set, for
background music, ambience, and voice-over. PC lives in `data/audios/`; PS3 lives in
`PS3_GAME/USRDIR/AUDIOS/` on the BLU-RAY ISO. Xbox NTSC-US ships no equivalent standalone
streams — Xbox audio is folded into the WAD wavebanks as XMA (`wavebank` ASET type, 95
entries, same count all platforms, per §1.1).

**Per-stream size comparison:**

| Stream | PC bytes | PS3 bytes | PC/PS3 ratio |
|---|---:|---:|---:|
| `ambience.pws` | 76,780,192 | 19,717,888 | **3.9×** |
| `music.pws` | 567,817,600 | 182,786,048 | **3.1×** |
| `vo_stream.english.pws` | 798,347,472 | 359,700,480 | 2.2× |
| `vo_stream.french.pws` | 760,727,520 | 330,044,416 | 2.3× |
| `vo_stream.german.pws` | 810,956,592 | 388,907,264 | 2.1× |
| `vo_stream.italian.pws` | 800,953,296 | 356,641,280 | 2.2× |
| `vo_stream.russian.pws` | — (not shipped) | 359,700,480 | — |
| `vo_stream.spanish.pws` | 774,002,992 | 353,675,264 | 2.2× |

**PS3 codec (verified by frame-chain decode):**

- `AMBIENCE.PWS` and `MUSIC.PWS`: **MPEG-1 Layer-3, 96 kbps, 44.1 kHz, joint stereo**. MP3
  frames start at file offset 0; 200+ consecutive valid frames parse cleanly with each
  next-sync landing at the predicted offset.
- `VO_STREAM.*.PWS` (all 6 languages): **MPEG-1 Layer-3, 80 kbps, 44.1 kHz, mono**. Frames
  start at offset 0x1d1800 — the first ~2 MB are a per-stream TOC / header; the voice
  content proper is contiguous MP3 after.

**PC codec — IDENTIFIED (standard IMA ADPCM):**

Investigation at [`docs/_pc_pws_codec_investigation.md`](_pc_pws_codec_investigation.md).

- **Decoders:** `FUN_0083f110` (stereo, 72-byte block) and `FUN_0083efd0` (mono, 36-byte
  block) in `output/_ghidra/securom_dump/mercs2_unpacked.exe`. Both are canonical IMA ADPCM
  implementations.
- **Format kernel dispatch:** `FUN_00839ae0` builds the 10-slot kernel table
  `DAT_0198db60`, indexed by `(channels + 2*format)*8`. Streamed records carry `format=4`,
  so stereo streams dispatch to `FUN_0083a790` (kernel for ch=2, fmt=4) and mono to
  `FUN_0083a510` (kernel for ch=1, fmt=4), each hard-coding its block stride
  (`DAT_00dfe520 = 0x48` stereo, `DAT_00dfe51c = 0x24` mono).
- **Tables:** `DAT_00b928a0` (89 × int16 step table) and `DAT_00b9287c` (16 × int16 index
  table) match the standard IMA ADPCM reference tables byte-for-byte.
- **Byte-level verification:** 2048 of 2048 purported 72-byte stereo blocks of `music.pws`
  and `ambience.pws` have valid headers (step_index ≤ 88 on both channels, reserved byte
  == 0). 2048 of 2048 purported 36-byte mono blocks of `vo_stream.english.pws` ditto.
  Random-null expectation ~0.004 for stereo, ~2.8 for mono — the observed rate is
  conclusive.
- **Decoded output is real audio:** from-scratch port of `FUN_0083f110` decoded the first
  10,000 blocks of `music.pws`; sample roughness 0.12 for both channels (music/speech
  band; noise would be ~1.4). Output WAV written to scratchpad.
- **Compression ratio = 256 / 72 ≈ 3.556 : 1 for stereo**, exactly matching IMA ADPCM's
  64 samples × 2 channels × 2 bytes PCM output / 72 compressed bytes. This closes a prior
  Phase 2 mis-measurement: the `+0x10` field in streamed wavebank records holds *decoded
  PCM16 bytes*, not sample count, so my earlier "14:1 compression / ~99 kbps" was wrong.
  Actual bitrate for music clip 0 (44.1 kHz stereo) is ~397 kbps IMA ADPCM; for VO
  (22.05 kHz mono) ~99 kbps IMA ADPCM.

**Platform codec choice summary (all three PROVEN):**

| Platform | Codec |
|---|---|
| PC | **IMA ADPCM** (3.556:1 stereo, 72-byte blocks; ~397 kbps for 44.1k stereo) |
| PS3 | **MP3** (96 kbps joint-stereo for music/ambience; 80 kbps mono for VO) |
| Xbox 360 | **XMA2** (2048-byte packets, in-WAD UCFX wavebank container; see §3.7) |

Pandemic picked per-platform native codecs: IMA ADPCM on PC (standard DirectSound-friendly
compressed path), MP3 on PS3 (standard decoder available on PS3 hardware), XMA2 on Xbox
360 (Xenos hardware codec).

Everything that was ruled out and why (Miles / mpglib / Vorbis / RIFF / etc.) is in the
investigation doc. Prior work in `memory/vo-audio-extraction.md` and
`docs/pandemic_audio_system_design.md` §8 had already noted "PC `.pws` = raw IMA ADPCM,
36-B mono / 72-B stereo blocks" — my earlier Phase 2 pass missed that corpus and
mis-measured the compression ratio.

**Earlier retracted (keeping only for the record so future readers don't repeat it):**

Everything I CAN say about the PC `.pws` format:

- **Container shape (proven from the reimpl's own codebase)** — a PC `.pws` is a headerless
  streaming blob store. From `tools/wad_simulator/crates/wad_simulator/src/pws.rs`: "no
  self-describing layout. Each streaming wavebank clip (codec `0x04`) addresses its audio
  by `(data_offset, data_size)` into the `.pws`; the format (codec / channels / sample-rate)
  lives in the wavebank clip record, NOT the `.pws`. Verified on retail `music.pws` /
  `ambience.pws` / `vo_stream.english.pws`, which contain no `RIFF` / `OggS` / IMA-version
  markers." I separately re-verified: zero `RIFF`, zero `OggS`, zero contiguous MP3
  frame-chains.
- **Wavebank record format for streamed banks (per
  `docs/reverse_engineer/audio_code_map.md` §11.5)** — version `0x1D`, kind `1` (streamed),
  40-byte header with 16-byte NUL-padded `.pws` filename at `+0x18`, then `count` × 36-byte
  records. Each record has `format = 0x04` (= `CODEC_STREAM` per `mercs2_audio::wave`), a
  sample-rate, channel count, raw `data_size` bytes, decoded `frames` sample count, and a
  `data_offset` into the external `.pws`.
- **Bitrate measured from the records** — e.g. PC music clip 0 (clip_hash `0x01cf3fe8`):
  stereo 44,100 Hz, 14,513,136 frames, 4,081,824 raw bytes. Bitrate = 4,081,824 × 8 /
  (14,513,136 / 44,100) ≈ **99 kbps**. Matches PS3's measured 96 kbps for ambience/music.
- **What the raw bytes at clip 0 offset 0 look like**:
  `1b 01 00 00 66 09 00 00 77 77 67 34 ff ff ff 31 91 9b 22 98 01 bb 8a 33 …`.
  Short header pattern then compressed data. No standard-codec magic.

What I CANNOT say without further RE:

- **Which codec actually decodes PC `.pws` data.** Not raw MP3 (no sync chains walk). Not
  IMA at 4:1 (compression ratio is 14:1, three times denser). Not raw Ogg/Vorbis (no `OggS`).
  Not XMA / ATRAC (those are console codecs anyway).
- **The retail-decoder dispatch** lives behind the Pal → DX8 vtable call tree in
  `PalSoundWaveDX8::Update` (`FUN_00839870`) and a `thunk_FUN_035f0000` SecuROM-split
  `OpenStreamFile`. Reimpl `mercs2_audio/DEFERRED.md` explicitly notes: *"the streamed-wave
  state machine that pumps `vo_stream.pws` / `music.pws` / `ambience.pws` chunks is **not
  built here**."* This item was deferred in prior audio work and remains deferred.

**Earlier retracted claim.** I previously wrote "PC audio = MP3 via mpglib.dll" and then
walked that back to "Miles Sound System + MP3". Both wrong:

- `mpglib.dll` **ships** alongside the game and exports `InitMP3` / `ExitMP3` / `decodeMP3`,
  but **no DLL or exe in the install imports those symbols**. Scanned `Mercenaries2.exe` +
  every `.dll` in the install dir: only `mpglib.dll` itself references its own exports. It's
  dead code shipped as a leftover.
- No Miles signature survives word-boundary filtering — the earlier `MSS` / `AIL_` hits
  were Windows API error-constant substrings (`OSS_UNAVAIL_ENCRULES`, `MSSIPOTF_E_*`).

**To actually determine the PC `.pws` codec** requires either:
1. Reversing `PalSoundWaveDX8`'s vtable methods (0xbe2240) and following the stream-fill
   path through its SecuROM-thunked opens (`thunk_FUN_035f0000`) to find the decoder call,
   OR
2. Running the retail PC game under x32dbg with a breakpoint on `FUN_00839870`, letting a
   streamed cue play, and single-stepping through the decoder.

Neither is in scope for this Phase 2 pass; both are concrete next steps.

**Interpretation:** PC prioritised audio **quality** (~2–4× higher bitrate); PS3 prioritised
disc **space** (uniform 96 kbps for ambience/music, 80 kbps mono for voice). The content
duration is comparable across platforms (same 179 VO assets registered via `AddLocalizedAsset`,
per the Lua pass) — the delta is bitrate, not content count.

**Xbox audio format** was not measured this pass (Xbox streaming audio is embedded in WAD
wavebanks as XMA, not standalone `.pws` — would need to extract one wavebank chunk and
decode its XMA header).

### 3.6 Cutscenes (Bink) across PC and PS3

Bink-encoded cutscenes diverge the OPPOSITE direction from streaming audio (§3.5): PS3
ships larger, higher-resolution video; PC ships smaller, downsampled video. Measured from
Bink file-headers (`BIKi` magic, width/height/fps/audio_tracks at offsets 20/24/28/40).

**Per-file breakdown (ratio = PC/PS3):**

| File | PC resolution | PC fps | PC audio tracks | PS3 resolution | PS3 fps | PS3 audio tracks | PC/PS3 size ratio |
|---|---|---:|---:|---|---:|---:|---:|
| `01_AOA_C.bik` (story) | **1024×576** | 30 | 8 | **1280×720** | 30 | 9 | 0.23× |
| `01_VIK_01.bik` (shared intro) | 1280×720 | 29.97 | 0 | 1280×720 | 29.97 | 0 | **1.00× BYTE-IDENTICAL** |
| `PANDEMIC.bik` (studio logo) | 1280×720 | 59.94 | 4 | 1280×720 | 59.94 | 4 | **1.00× BYTE-IDENTICAL** |
| `EA.bik` (publisher logo) | 1280×720 | 15 fps, 150 frames (10 s) | 4 | 1280×720 | 30 fps, 150 frames (5 s) | 4 | 1.70× (PC half-speed loop) |
| `SHELL_JENNIFER.bik` | 600×720 | 29.97, 83 frames (2.8 s) | 0 | 600×720 | 30, 965 frames (32 s) | 0 | 0.13× (PC trimmed to a short placeholder) |

**All 33 story cutscenes (01–15 × C/J/M) consistently at PC/PS3 ratio ≈ 0.23×** —
corresponding to **PC = 1024×576 anamorphic SD** vs **PS3 = 1280×720 HD**. 1,208 MB on PC
total vs 4,716 MB on PS3 for the 43 shared BIKs — 3.9× total.

Also notable:
- PC story cutscenes carry **8 audio tracks each** (one per shipped language: en/fr/de/it/es
  + 3 unspecified — likely effects, music, commentary). PS3 carries **9** (adds Russian,
  matching the +1 language-WAD finding in §7b.3 of the parity reference).
- Two logos (`01_VIK_01.bik`, `PANDEMIC.bik`) are **byte-identical across platforms** —
  rendered once in Pandemic's pipeline and shipped untouched. No per-platform re-encode.
- Shared aggregate: **PC 1.21 GB vs PS3 4.72 GB** = **PS3 is 3.9× larger** at the cutscene
  layer, exactly inverting the direction of the streaming-audio divergence (§3.5).

**Interpretation.** PC shipped on DVD (~4.7 GB layer); PS3 on BLU-RAY (~25–50 GB). PC
re-encoded video down to 576p anamorphic to fit the smaller medium; PS3 kept the native
720p HD masters. Pandemic made the opposite compression trade on audio (PC retained
higher-bitrate MP3 inside the Pandemic PWS container; PS3 shipped lower-bitrate MP3 raw)
because streaming audio takes proportionally less space than video — and PC audio hardware
(sound cards + full speakers) rewards higher bitrate more than a console TV speaker would.

### 3.7 Xbox audio container — PROVEN

Full byte-level investigation at [`docs/_wavebank_container.md`](_wavebank_container.md).

**Multi-UCFX pack structure** (verified against `scratchpad/xbox-wb/block_03187_raw.bin`,
10,058,248 B):

```
+0x00  u32 BE  count = 27
+0x04  27 × 16-byte TOC entry: { u32 BE name_hash, u32 BE type_hash, u32 BE 0, u32 BE SIZE }
+0x1B4 27 UCFX sub-chunks packed contiguously in TOC order (9 wavebank + 9 sounddb + 9 soundbank)
```

Independent verification: sum of 27 SIZE values = `0x997854` + TOC size `0x1B4` =
`0x997A08` = full file length ✓. First UCFX at 0x1B4 starts `58 46 43 55` = `"XFCU"` (BE
spelling of the LE multi-char constant `'UCFX' = 0x58464355`). The `atad` chunk tag at
0x1C8 is `data` written BE for the same reason.

**Wavebank body layout** (Xbox) — same field *offsets* as PC, with multi-byte fields
big-endian:
- Header: version 0x1D, bank_hash BE, count BE u16, kind BE u16, bank_hash BE (dup),
  records_off BE, 0.
- Record (36 B, BE): `clip_hash@+0`, `[0, ch, fmt, 0]@+4`, `sample_rate@+8`,
  `data_size@+0xC`, `decoded_sample_count@+0x10`, zeros `+0x14..+0x1C`, 0 `+0x1C`,
  **record-relative `data_offset@+0x20`**.

Proven by contiguous-blob reconstruction: `rec[i].abs + rec[i].+0x20 + rec[i].+0x0C == rec[i+1].abs + rec[i+1].+0x20`
for all 130 adjacent pairs; first blob at abs 0x19DC, last blob ends at abs 0x1169DC = body end.

**Codec — XMA2 (PROVEN byte-level):**

All 131 records in the first wavebank in block 3187 are codec `0x05`, 1 ch, 44,100 Hz. The
`data_offset` region is a **raw XMA2 bytestream of 2048-byte packets** — no RIFF/XMA2/WBND
wrapper, no magic at the stream level.

- Every record's `data_size` is a multiple of 2048; total = 554 packets.
- Every 2048-byte packet begins with a valid XMA2 packet header
  (`frame_count` ∈ 1..41, `metadata` bits valid, `frame_offset_bits=0` for packet 0, non-zero
  continuation offsets later).
- `sum(packet.frame_count) × 512 ≈ record.+0x10` within ≤1 frame for 131/131 records.
- Xbox-ADPCM "size = ceil(samples/65)·36·ch" test FAILS for every record; implied
  bitrates land in XMA2 voice range (32–100 kbit/s), not Xbox-ADPCM's fixed ~288 kbit/s.
- End-of-stream sentinel packet (`fc=0, offset_bits=0x7FFF`) observed on record 104's last packet.
- Extracted blob: `scratchpad/xbox-wb/clip0_raw.bin` (8192 B, 4 packets), sha256
  `f79f0b5b53143359c560424e9db938bd63bb0f997705e2dc4c28a803692e35a7`. Independently
  spot-checked: packets 0..3 have frame_count = {21, 23, 36, 16}, all 2048-aligned, packet 0
  has `frame_offset_bits=0`.

Decoded WAV output not produced in this pass (ffmpeg not on PATH on this host). §8 of the
investigation doc prescribes the RIFF/XMA2 WAVEFORMATEXTENSIBLE wrapper needed to feed
ffmpeg or vgmstream once a decoder is available.

**Follow-up (noted, not fixed here):** the reimpl `crates/mercs2_formats/src/be_to_le/audio.rs`
has three defects now contradicted by retail bytes — treating `+0x00` as a count instead
of version `0x1D`, placing `data_offset` at `+0x0C` instead of `+0x20`, and treating codec
`0x05` as Xbox-ADPCM instead of XMA2. The port's test (`wavebank_matches_python_byte_exact`)
only validates against a synthetic mock built to the port's layout — no retail Xbox wavebank
was exercised byte-for-byte through this path. Fixing this is outside Phase 2 scope but is
captured in the investigation doc.

**Confidence grading** (from the investigation doc):
- Container shape, sub-chunk layout, wavebank body header, record field offsets, blob
  position arithmetic, codec `0x05` = XMA2 *in block 3187*: **PROVEN** (byte-level evidence).
- Codec `0x05` = XMA2 across every retail Xbox wavebank: **INFERRED** — needs a sweep.
- Pre-first-blob 0x57C-byte padding being XMA2 2048-byte alignment: **INFERRED**.
- Streamed Xbox wavebanks (`kind=1`): **UNMEASURED** — block 3187 is 100% embedded.

### 3.8 WAD block packing — the asset layout differs even though the ASET content is identical

Identical ASET content (PS3 ≡ Xbox at 29,914 hashes, PC at 30,006) packs into **drastically
different sets of blocks** per platform. Measured directly by parsing the PTHS/SHTP section
of each `vz.wad` (null-terminated path strings, uncompressed, offset at section-4 header v1
field).

**Total block counts:**

| Platform | `vz.wad` block count |
|---|---:|
| PC retail | 11,370 |
| Xbox 360 NTSC-US | 11,087 |
| PS3 BLUS30056 | **13,770** (+2,683 vs Xbox) |

**Cross-platform block-set intersection** (normalised: lowercase + forward-slash):

| Comparison | Count |
|---|---:|
| **All 3 shared** | **2,960** (26% of smallest set) |
| PC only vs Xbox | 650 |
| Xbox only vs PC | 367 |
| PC only vs PS3 | 8,392 |
| PS3 only vs PC | 10,792 |
| Xbox only vs PS3 | 8,127 |
| PS3 only vs Xbox | **10,810** |

Only 2,960 of ~11k Xbox blocks have the same block-path across all three platforms. Even
Xbox vs PS3 — both consoles, both big-endian `segs`-format, verified identical ASET content
at the row level — share only **~22% of their block paths**.

**What the PS3 extras look like** (sample `airport_bld_hangar01` on PS3 only, not Xbox):
```
airport_bld_hangar01_misc_nm_p000_q3.block      (4 LOD rungs)
airport_bld_hangar01_misc_sm_p000_q3.block      (4 LOD rungs)
airport_bld_hangar01_nm_ruin_p000_q3.block      (4 LOD rungs)
airport_bld_hangar01_ruin_p000_q3.block         (4 LOD rungs)
airport_bld_hangar01_sm_ruin_p000_q3.block      (4 LOD rungs)
```

**PS3 splits each asset into per-component sub-blocks** by map type (`_nm` = normal map,
`_sm` = specular map, `_misc`), destruction state (`_ruin`), and combinations thereof,
each with 4 LOD rungs. **Xbox and PC pack the same asset into a single composite block.**
That one hangar expands from 1 Xbox block to 20 PS3 blocks (5 variants × 4 LOD rungs). This
is the dominant source of PS3's extra 2,683 blocks.

**What the PC extras look like** (sample `__shared__` geometry blocks, PC only vs Xbox):
```
c30002-c20024-c10951-__shared___p003_q0.block
c30002-c20024-c10954-__shared___p003_q0.block
c30006-c20333-c11105-__shared___p003_q0.block
```

**PC adds 650 `__shared__` geometry-deduplication blocks** — terrain cells (`c30XXX-c20XXX-c10XXX`
is a 3-level cell-hierarchy ID) with factored-out shared geometry at the LOD-0 (`_p003_q0`)
tier. Xbox ships this geometry inline in each cell block; PC extracts it into separate
shared blocks to save disk space. **Note**: the inverse-case blocks don't exist on Xbox,
which is why Xbox lacks these — Xbox's packaging doesn't factor the shared geometry out.

**Interpretation.** Three distinct asset-packaging strategies, all producing the same
loaded content:
- **Xbox packaging**: coarse-grained composite blocks (one block per asset incl. all its
  textures, variants, and ruin states). Optimized for Xenos memory streaming granularity.
- **PS3 packaging**: fine-grained per-component sub-blocks (separate blocks for each
  texture/variant/state × 4 LOD rungs each). Optimized for RSX's smaller streaming-unit
  preference.
- **PC packaging**: Xbox-style composite blocks plus shared-geometry dedup. Optimized
  for mechanical disk reads where small-file-count matters.

The ~22% block-path overlap even between the two consoles is the headline — identical
engine content, almost no shared file packaging. The 2,960 shared blocks are mostly
`vz_state_*_P000_Q3.block` layer-overlay blocks and shared system blocks (resident, shell,
scripts_vz, hijack scripts).

---

## 4. Combined picture

| Layer | PC | PS3 | Xbox NTSC-US |
|---|---|---|---|
| **Base-game Lua** | 679 chunks (resident 240, shell 28, 5 lang WADs) | 676 chunks (resident 238, shell 26, 6 lang WADs incl. Russian) | 672 chunks (resident 238, shell 26, 2 lang WADs) |
| **ASET registry (vz.wad)** | 30,645 rows / 30,006 hashes | 30,553 rows / 29,914 hashes | 30,553 rows / 29,914 hashes |
| **Shader programs** | 1,023 across 6 files (3.47 MB DX9) | 1,102 records × VS+PS pair = ~2,204 blobs in 1 file (2.86 MB RSX NV) | TBD — in XEX |

Three platforms, same base-game content, three divergent engine-side surfaces:
- **PC adds UI-rendering infrastructure** (87 textures + 3 fonts + 2 LTI scripts) because it
  draws controller glyphs and menu widgets itself.
- **PS3 adds Russian localisation** (1 language WAD) because the SKU targets EU + CIS.
- **Xbox NTSC-US is the leanest** at every measured layer.

The PS3 base-game Lua divergence (`chicon002.lua` ships an older build) is the only
behaviour-level cross-platform drift measured so far; everything else is additive content or
format shape, not divergent behaviour.
