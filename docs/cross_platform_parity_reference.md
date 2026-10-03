---
name: cross_platform_parity_reference
description: "Itemized, RE-verified list of every difference we have proven between the three 'next-gen' Mercs 2 releases (PC / PS3 / Xbox 360) — for modders bringing them to parity. Distinguishes proven-from-bytes vs unverified community claims."
status: current
evidence: mixed
verified_on: 2026-10-02
---

# Mercenaries 2 — PC / PS3 / Xbox 360 parity reference

**Written for:** mod-makers working on Mercenaries 2: World in Flames who want a
single itemized list of every difference between the three "next-gen" versions
(PC, PS3, Xbox 360), with enough evidence to actually go and *fix* each one.

**Not covered:** PS2/Wii "Mercenaries 2" is a separate game (older engine, different
content) — nothing in this repo has reversed it, so it is out of scope. The three
versions below are the ones that share the **Pangea / `Pg*`** engine and the same
Lua/asset lineage.

**How to read this:** each row is scored on evidence.
- **PROVEN** — measured out of the shipped bytes / a working RE oracle in the repo.
- **INFERRED** — reasoned from adjacent evidence but not directly verified this session.
- **COMMUNITY-CLAIMED** — asserted online but we have NOT verified it here; flagged so
  modders don't act on it without a byte-level check first. Send the specific forum
  thread / evidence and we'll fold it in.

Confidence beats confidence-sounding. A rumor that reproduces in the file table is
better than a devlog that doesn't.

**One provenance clarification.** Where this document says "Xbox 360", the byte-level
comparison is against the **Jul 11 2008 Profile devkit build** (`Mercs2_Xenon_P.exe`,
symbolised, 38k-fn decomp at `output/_ghidra_x360/xenon_decomp_named.c`) — not the
shipped **Final retail** `Mercs2_Xenon_F.exe`. The two share the same title ID and were
built ~2 minutes apart; the retail differs in that it is stripped of dev-only debug
menus and profiling instrumentation. So where we say "Xbox has X but PC doesn't", we
mean *the devkit build we can read* has it. For features the retail Xbox actually
shipped (shaders, DLC, cutscenes), this is a distinction without a difference. For
debug/profiling infrastructure it is worth remembering.

**Since 2026-09-06, both Xbox retail Final (`output/_ghidra_x360_final/`, 52 MB) and
Xbox retail (`output/_ghidra_x360_retail/`, 55 MB) have their own Ghidra decomps**,
and a PS3 retail EBOOT decomp (`output/_ghidra_ps3_retail/`) exists but is undersized
(~1.7 MB vs Xbox retail's 55 MB — the `.opd` seeder didn't complete). Findings in
this doc have **not** yet been re-verified against those retail images; a follow-up
pass would cross-check each "PC missing X" claim against `xenon_retail_decomp_named.c`
rather than the Profile devkit. Expect most to hold — retail Final ships the same
shaders and Lua binding surface as Profile — but the pass is the honest work.

---

## 0. The one-line summary

At the **content** level, PS3 and Xbox 360 are effectively the **same build**
re-encoded — 5,287 ASET name-hashes identical, 0 platform-only assets, 36/36 DLC
Lua chunks structurally identical, 671 common PC↔Xbox base-game Lua pairs
diffed to the byte with the Rust `lua_structural_dump` tool: **~87% portable,
13.3% real-divergence overwhelmingly in the GUI/menu layer**, plus one
single-constant PC placeholder bug Xbox got fixed. PC is the odd one out:
**PC is the port that got starved**, at the cutscene, audio, DLC and
post-processing layers. Every place community lore says "PC is worse" it's
true and *measurable*. Every place community lore says "the versions ship
different missions" it is **not** — mission logic, dialogue, subtitles,
contracts, tutorials are all the same set of Lua scripts across all three.

Source: [`memory/ps3-dlc-crack-and-klicensee.md`](../memory/ps3-dlc-crack-and-klicensee.md),
[`memory/multiplatform-compile-backend-assessment.md`](../memory/multiplatform-compile-backend-assessment.md),
[`docs/modding/cross_platform_lua_porting_guide.md`](./modding/cross_platform_lua_porting_guide.md).

---

## 1. Cutscenes — the largest and most porta­ble delta

**PROVEN.** Full catalog: [`docs/movies_pc_vs_ps3_catalog.md`](./movies_pc_vs_ps3_catalog.md).

For the **36 story cutscenes** (`01_AOA` through `15_ACK`, each × three merc
variants `_C / _J / _M`):

| Axis                | PC                 | PS3                | PS3 advantage |
|---------------------|--------------------|--------------------|---------------|
| Resolution          | 1024×576 (0.59 MP) | 1280×720 (0.92 MP) | true 720p, +56% pixels |
| Video bitrate       | ~3.9 Mbps          | ~17 Mbps           | ~4.4× |
| Audio sample rate   | 22 050 Hz          | 48 000 Hz          | 2.18× |
| Audio tracks        | 8                  | 9                  | +1 |
| Total set size      | 1.2 GB             | 4.4 GB             | ~3.9× |
| Duration / fps / edit | 30 fps, identical | 30 fps, identical | — |

Xbox side: **not diffed yet** — Xbox stores movies inside the DVD image not as
loose `.bik`, so a same-methodology diff needs someone to extract them first.
Community consensus is Xbox ≈ PS3 quality; unverified here.

**Menu / shell videos** (`shell_chris`, `shell_mainmenu`, `shell_mattias`): both
600×720, minor bitrate edge to PS3 (~4.19 vs ~3.6 Mbps).

**Anomaly worth flagging:** PC ships `shell_jennifer.bik` as a **truncated 2.77 s / 2.2 MB
stub**. PS3 has the full 32.2 s / 16.9 MB clip. The PC file is a placeholder, not
a downscale — a shipping oversight, not a compression decision.

**PC-only files:** `title_esrb.bik`, `title_logo.bik` (both 720p) — no PS3 counterpart.
Nothing lost there.

### How to reach parity
Verified 2026-06-30: **the full PS3 `.BIK` set drops into PC `Data\Movies\` and
plays with no crash**, no re-encode needed. See
[`memory/ps3-movies-dropin-on-pc.md`](../memory/ps3-movies-dropin-on-pc.md).
- Runtime is `binkw32.dll` v1.9a; both platforms ship Bink 1 (`BIKi`), same
  format generation.
- PC engine already plays 1280×720 Bink (EA/Pandemic/VIK/title_logo are 720p on PC).
- Movie audio is picked **by track ID** in `FUN_00709d70 @0x00709d70`, not by
  count — missing/extra tracks play silence, not crash.
- **One caveat for localized audio:** PS3 story tracks are `{0,2,3,7d1,7d2,7d3,7d4,7d5,7d9}`
  vs PC `{0,2,3,7d1,7d3,7d4,7d5,7d6}`. English (`0x7d1`) is on both — English
  users are fine. The engine's `case-2` language (mapped to `0x7d6`) will play
  silent on a PS3 drop-in, because PS3 uses `0x7d2` for that slot instead. Fix
  needs RAD Video Tools (ffmpeg cannot mux Bink) to remap the track IDs.

---

## 2. Post-processing / rendering — PC's silent regression

**PROVEN.** Source: [`docs/reverse_engineer/sky_post_hdr_code_map.md`](./reverse_engineer/sky_post_hdr_code_map.md) §7.

- **Motion blur / velocity shaders are ABSENT on PC.** `PgVelocityFP` and
  `PgMotionBlurFP` shader strings exist only in the Xbox 360 image. On PC the
  `MotionBlur` INI flag exists and writes `DAT_00dfc363`, but there is no shader
  to consume it — dead toggle. Community claim "PC is missing motion blur" is
  therefore **confirmed**.
- **PS3 status:** unverified. The RSX runtime is native-engine only; the shipped
  content doesn't tell us which post FX are wired. Community lore says PS3 has
  motion blur; we have no byte-level proof either way. **Please flag the specific
  claim / screenshot and we'll dig further.**
- `PgAntiAliasingFP` is registered on PC but has no dedicated quad in the
  composite pass — likely folded into the composite. Unconfirmed which platforms
  ship a real AA pass.

**Parity work required:** the Xbox velocity/motion-blur shaders would need to be
ported to PC HLSL/D3D9 and wired into the composite pass. Non-trivial — this is
the one graphics feature we've proven the PC binary is *missing native code for*,
not just missing data.

**Second PC-side placebo control** (added 2026-09-24): the video-options
**`ViewDistance` slider is fog-only** on PC. Its sole reader is the fog function
`FUN_007140b0`; the menu getter is a `return 1` stub. Community reports of "PC
draw distance is smaller than console" cannot be fixed by that setting. The
actual levers are hardcoded per-band constants (`DAT_00b984ac = 50 m` ambient
ring; per-frame LOD-budget hysteresis in `FUN_0084ae70`). The `crowd_fog_couple`
ASI in `mods/crowd_fog_couple/` already redirects these operands and gets fog +
crowd + LOD out to ~800 m on a stock exe. Source:
[`docs/reverse_engineer/render_distance_and_density_levers.md`](./reverse_engineer/render_distance_and_density_levers.md).

---

## 3. Ambient population / crowd density — understood, scalable, small label open

**PROVEN.** Sources:
[`docs/reverse_engineer/population_spawner_code_map.md`](./reverse_engineer/population_spawner_code_map.md) §5,
[`docs/reverse_engineer/render_distance_and_density_levers.md`](./reverse_engineer/render_distance_and_density_levers.md),
[`mods/crowd_fog_couple/`](../mods/crowd_fog_couple/) — the working mod that
scales density on the retail PC engine.

**Bottom line.** The population system is well-understood on PC. Ambient density
is **data-driven per region** from WAD `PopulationDensity` / `PopulationFlow` /
`PopulationDynamicRoad` COMP records, read at region-select by
`FUN_004d60e0`, which writes per-player desired ped/veh counts into
`DAT_00ed55c8[]` / `DAT_00ed55b0[]`. `DensityUpdate` (`FUN_005051a0`) then
spawns toward those ceilings using hardcoded batch/trickle rates (10/10/2/2
per frame). **`crowd_fog_couple.asi` MinHooks `FUN_004d60e0`** to multiply
those desired counts, and pushes crowd extent to ~800–1000 m via targeted
operand rewrites. Live-tested, in production; no "PC crowd ceiling" gap remains
that isn't reachable from a mod.

**Small unresolved label.** The **kept-population ring** is labeled 64 on
Xbox (`@0x837D38A8`) vs 8 on PC (`DAT_00ed55d4[]`) in
`population_spawner_code_map.md` §5, with the pipeline-stage-vs-cap question
tagged `confirm-live`. This is a naming/interpretation question, not the load-
bearing density ceiling — the density system above is what actually controls
"how many peds/vehs on screen", and it doesn't route through this ring. Do
not treat the 8-vs-64 label as a headline parity gap; it's a small unresolved
label on a well-understood system.

**Trap for whoever measures pool sizes next.** `[presize]` and registrar-
immediate values do not read the same from every image. Live dumps (memory
snapshots) show runtime state that `[presize]` has already re-tuned; clean
on-disk exes show only the registrar's compile-time immediate. See
[`docs/reverse_engineer/inventory_equipment_code_map.md`](./reverse_engineer/inventory_equipment_code_map.md)
§"Capacity and shift are RUNTIME state" — an unrelated pool where the disk
image reads `0` and the live dump reads the real capacity. Compare live
dumps of both platforms, or both clean exes' registrar immediates, but
never mix.

---

## 3b. The stripped-binding family — Xbox has ~60 cfuncs PC ships as `return 0`

**PROVEN.** Sources: [`docs/lua_capi_comprehensive_audit.md`](./lua_capi_comprehensive_audit.md) §"Stub Function: 0x006D5640",
[`docs/reverse_engineer/scripting_host_binding_code_map.md`](./reverse_engineer/scripting_host_binding_code_map.md) §5.4,
[`docs/reverse_engineer/diagnostics_code_map.md`](./reverse_engineer/diagnostics_code_map.md) §5,
`tools/debug_binding_report.py`.

On the PC binary, a **single shared 3-byte stub** — `xor eax, eax; ret` at
`0x006D5640` — backs **62 Lua bindings across 13 tables**. On the Xbox devkit
build the same names have real function bodies. Some are genuinely dev-only and
their absence is not a regression; some are **functionally missing features** in
the shipped PC game.

Real functional gaps (not just diagnostics):

| Binding                  | What it does (Xbox)                                        |
|--------------------------|------------------------------------------------------------|
| `Ai.SetTrafficSpawning`  | Enable/disable road traffic ambient spawner globally       |
| `Ai.SetSidewalkSpawning` | Enable/disable sidewalk crowd ambient spawner globally     |
| `Ai.SetRoadSpawning`     | Enable/disable road network ambient spawner globally       |
| `Ai.SetLaneActive`       | Turn a road-graph lane on/off at runtime                   |
| `Ai.SetExclusionZone`    | Push/pop a zone the population system won't spawn into     |
| `Gui.AddObjective`       | Generic objective HUD entry (the specific radar/marker/PDA/tray variants of `SendEvent_*Objective` DO work on PC — only the abstract pair is stubbed) |
| `Net.SendEvent_AddObjective` / `RemoveObjective` | Ditto — the generic pair only     |
| `Sys.SetSky`, `Sys.Water`, `Talk`, `Feed`        | Live world-tuning hooks           |
| `Search`, `LoadScript`, `LoadData`               | Debug asset introspection         |

Debug/diagnostic gaps (stub is faithful — do not "fix"):
- `Debug.Printf`, `Debug.Assert`, `print`, `LogError` / `LogWarning` / `LogInfo`,
  `GetCallstack`, `DumpAssets`, `DumpTextures`, `Pg.Dump*` — the whole retail
  Debug menu.
- Retail also stubs `RenderLanes` / `RenderFCStates` / `RenderSpawnPoints` /
  `RenderConstraints` — the native debug-draw overlays. On the Profile devkit
  Xbox build these are on toggles `DAT_836dba4x`. Community can't read them on
  retail Xbox either.

**The one surviving debug sink on PC is `Sys.WriteToConsole`** (table `0x00B98A78`).
`pmc_bb.dll` re-hooks the `Debug.*` slots at boot so `[lua]` lines appear at all;
a licensed dxwrapper install without `pmc_bb_log.dll` gets **no Lua output** —
worse than a hard-to-spot line.

### Modder actionable
- The functional stubs are recoverable by porting the Xbox bodies back — they
  are real code in `xenon_decomp_named.c`, not virtualized SecuROM residue.
- Simpler: an ASI can replace the `luaL_Reg` entry pointers (do not inline-hook
  `0x006D5640` itself — 62 unrelated bindings share it). `tools/debug_binding_report.py`
  is the surveyor.
- For "PC feels dead vs consoles" specifically: **`mods/crowd_fog_couple/`
  already implements the fix path** — MinHook on `FUN_004d60e0` (region density
  writer) multiplies desired ped/veh counts, redirects the placement-radius
  operand, and redirects the 9 cull-distance thresholds. Uses `cdbsizes.ini`
  to raise pools + `LARGE_ADDRESS_AWARE` on the exes. Live-tested; scales to
  ~800 m of fully-populated world.

---

## 4. DLC ("Blow It Up Again Pack" — 4 arena game modes, Caicara level)

**PROVEN.** Sources: [`docs/dlc_loader_cross_reference.md`](./dlc_loader_cross_reference.md),
[`docs/xbox360_dlc_analysis.md`](./xbox360_dlc_analysis.md),
[`docs/dlc_pc_port_status.md`](./dlc_pc_port_status.md),
[`memory/ps3-dlc-crack-and-klicensee.md`](../memory/ps3-dlc-crack-and-klicensee.md).

The famous PC gap: EA cancelled the PC DLC program. **The DLC was released on
Xbox 360 and PS3 only.** But this is *not* an engine gap — the PC engine has a
full DLC loader, we just have to hand it a WAD.

| Aspect              | PC                            | Xbox 360                          | PS3                    |
|---------------------|-------------------------------|-----------------------------------|------------------------|
| Container           | `vz-patch.wad` (FFCS, LE)     | `DLC01.doh` (FFCS, BE) inside STFS | `DLC01.EDAT` inside PKG |
| Registration        | Automatic (`*-patch.wad` scan) | `package.cfg` datafile/scriptname | PSN package system     |
| Byte order          | Little-endian                 | Big-endian                         | Big-endian             |
| Compression         | `sges`                        | `segs` (BE)                        | `segs` (BE, same as X360) |
| Script entry        | Lua `SetMasterScriptName`     | `scriptname` in package.cfg        | Same PC-style          |
| DLC audio codec     | IMA ADPCM                     | XMA                                | MP3                    |
| Shipped commercially| **No** (cancelled)            | Yes                                | Yes                    |

**Content: PS3 == Xbox at the WAD level.**
- **5,287 ASET name-hashes identical** across PS3 and Xbox — 0 platform-only assets.
- **36/36 DLC Lua scripts byte-identical** between PS3 and Xbox
  (`docs/mercs2-dlc-luacd/src/dlc01`).
- Byte differences are pure re-encoding — Xenos tile vs RSX linear textures,
  Xbox-ADPCM/XMA vs MP3, vertex packing.

**PC port status (in this project):**
- PS3 DLC is fully decrypted end-to-end (PKG→NPDRM EDAT→SELF; recovered title
  klicensee `1896170d86be49b983b7135c96d6fb79`).
- The `dlc_port` crate + `vz-patch.wad` overlay bring the Xbox DLC to PC.
- Working PC delivery: WAD carrying 2196 DLC blocks + `dlc01` script appended as
  entry 115, activated via `dlc_enable.asi` calling `import("dlc01")`.

**Content shipped by the DLC** (net-new content the base game does not have on
*any* platform): skins `pmc_hum_obama` / `mattias_v5` / `sarah`; vehicles `m1a1` /
`m1a3` tanks + `nukeracer` gadget car + `milpanhard` / `armoredmonster` trucks;
weapons `minigun` + `chaingun20mm`; money/speed/timer pickups; arena game modes
Arms Race / Death Race / Mercs Blitz / Urban Rampage; Caicara / Speed City level
data. Full catalog: `scratchpad/inventory_ps3.json`.

### Modder actionable
- Xbox → PC: solved via `dlc_port` + `vz-patch.wad`. See `docs/dlc_pc_activation_checklist.md`.
- PS3 → PC: the assets are identical to Xbox, so re-porting from PS3 gains
  nothing — do it once from Xbox, both console versions are covered.
- Bringing DLC to PC *does not* need any DRM bypass; it is a data-side overlay
  the retail engine already scans for.

---

## 5. Audio — the codec matrix and its embedded bugs

**PROVEN.** Sources: [`docs/xbox360_dlc_analysis.md`](./xbox360_dlc_analysis.md) §"Format Comparison",
[`memory/vo-audio-extraction.md`](../memory/vo-audio-extraction.md),
[`memory/multiplatform-compile-backend-assessment.md`](../memory/multiplatform-compile-backend-assessment.md).

| Layer                 | PC                        | Xbox 360               | PS3          |
|-----------------------|---------------------------|------------------------|--------------|
| Stream container      | `.pws` (LE 4-byte header) | `.pws` (same file ext) | `.pws`       |
| VO stream codec       | MS-IMA ADPCM              | XMA                    | MP3 (`codec 0x0C`) |
| SFX / wavebank codec  | IMA / PCM                 | XMA / Xbox-ADPCM       | (unmeasured, likely mixed) |
| VO track count        | English + 5 langs         | English + 5 langs      | English + 5 langs |
| Sample rate (stream)  | 22 050 Hz (matches movies) | 44 / 48 kHz            | 44 / 48 kHz  |

Community perception that the PS3 audio "sounds cleaner" is likely two things at
once:
1. Movies audio is 48 kHz on PS3 / 22 kHz on PC (§1).
2. PS3 VO is MP3 (lossy at higher rates), PC VO is MS-IMA ADPCM at 22 kHz.

Both are *encode-time* choices; no engine feature is missing to close the gap.

### Modder actionable
- `tools/pws_xbox_to_pc.py` (Python) and `mercs2_formats::audio` (Rust) already
  transcode Xbox ADPCM / XMA payloads to PC IMA. Same tooling handles PS3 MP3
  streams via ffmpeg → WAV → IMA re-encode.
- A PS3-to-PC VO upgrade is technically achievable but the target codec is
  22 kHz IMA — the PC bottleneck is not the source data; **the PC engine plays
  higher-quality audio when handed higher-quality assets**. Nothing prevents
  shipping a 44 kHz IMA VO overlay in a `-patch.wad`.
- Wavebank XMA→IMA transcoding is solved (see `session_2026-06-10_validator_trust_and_audio_port.md`).
  **XMA encoding is the one true wall going the other direction** (PC → console
  mod ship) — no free encoder exists.

---

## 6. Container / asset format — endianness and byte-swap

**PROVEN.** Source: [`docs/xbox360_dlc_analysis.md`](./xbox360_dlc_analysis.md),
[`docs/aset_format.md`](./aset_format.md),
[`memory/multiplatform-compile-backend-assessment.md`](../memory/multiplatform-compile-backend-assessment.md).

Structural summary of the WAD/asset stack across all three:

| Feature                | PC (x86)                  | Xbox 360 (PPC)           | PS3 (Cell) |
|------------------------|---------------------------|--------------------------|------------|
| Container ext.         | `.wad`                    | `.doh` in STFS           | `.EDAT`→WAD in PKG |
| FFCS magic             | `FFCS`                    | `SCFF`                   | `SCFF`     |
| FFCS version           | 2                         | 2                        | 2          |
| Chunk row size         | 12 B                      | 12 B                     | 12 B       |
| Chunk types (INDX/…)   | `INDX DATA CSUM ASET PTHS` | `XDNI ATAD MUSC TESA SHTP` | `XDNI ATAD MUSC TESA SHTP` |
| sges header            | 16 B                      | 32 B (+16 per-seg meta)  | 32 B (same as X360) |
| Segment boundary       | —                         | 64 KB + 4-byte pad       | 64 KB + 4-byte pad |
| UCFX magic             | `UCFX`                    | `XFCU`                   | `XFCU`     |
| Lua endianness flag    | `01` (LE)                 | `00` (BE)                | `00` (BE)  |
| Cert blob (FFCS+0x48)  | All zeros                 | Xbox LIVE signed         | Not diffed |
| ASET `packed_block_ref`| `[hi16 _P000][lo16 _P001]` | `[hi16 _P001][lo16 _P000]` — MIRRORED | Not diffed |

**★ Trap for ASET porters:** the Xbox layout is *mirrored* — every u32 has its
two u16 halves swapped versus PC. Applying the PC decode rule to a 360 WAD gives
you nonsense. Also: the Xbox ASET chunk is mixed-endian — `type_id` is stored LE
inside otherwise-BE rows. See [`docs/aset_format.md`](./aset_format.md) §"Xbox
layout is MIRRORED".

**PS3 base-game WAD envelope: not literally cracked, but functionally moot.**
The first `0x80800` bytes of `ps3-VZ.WAD` are enveloped by an unknown stream
cipher (`tools/ps3_wad_header_crack.py` recovered an 18-byte keystream prefix as
of 2026-05-21). We haven't gone further because the payoff would be zero: the
PS3 DLC crack proved **PS3 content == Xbox content** (5287 ASET name-hashes
identical, 0 platform-only, 36/36 DLC Lua byte-identical). Base-game deltas
between PS3 and Xbox would live in this envelope, but the identity finding on
the decrypted portion is strong evidence that nothing gameplay-relevant is
different. Treat the envelope as "solved for our purposes" — see
[`memory/ps3-dlc-crack-and-klicensee.md`](../memory/ps3-dlc-crack-and-klicensee.md).

---

## 7. Mission / gameplay logic — the community can put this one to bed

**PROVEN at scale.** Sources: [`docs/mercs2-luacd-xbox/_structural_diff_report.md`](./mercs2-luacd-xbox/_structural_diff_report.md),
[`docs/mercs2-dlc-luacd/_ps3_xbox_structural_diff.md`](./mercs2-dlc-luacd/_ps3_xbox_structural_diff.md),
[`docs/_lua_corpus_coverage_audit.md`](./_lua_corpus_coverage_audit.md),
[`docs/modding/cross_platform_lua_porting_guide.md`](./modding/cross_platform_lua_porting_guide.md).

**As of 2026-10-02 every shipped Lua chunk on PC and Xbox has been extracted, decompiled, and structurally diffed cross-platform** using the Rust `lua_structural_dump` tool. 671 common PC↔Xbox pairs (plus 36 Xbox↔PS3 DLC pairs). The complete picture:

| | PC chunks | Xbox chunks | Classification |
|---|---:|---:|---|
| Three big host blocks (vz, resident, shell) | 382 | 378 | 192 identical / 98 debug-stripped / 88 real-divergence |
| Gap-closure corpus (missions, hijacks, subtitles, guilayouts, loaders) | 293 | 294 | 265 identical / 27 debug-stripped / 1 real-divergence |
| **Combined base-game totals (all WADs)** | **679** | **672** | 457 identical / 125 debug-strip / 89 raw-divergent; the 89 reduce to **9 real behaviour drops** once ASSERT + print debug-trace strip are discounted (231/240 PC resident chunks ≡ Xbox at 96.25%) |
| PS3 BLUS30056 base-game | — | **676** | 642/643 `vz` chunks ≡ Xbox (one real divergence: `chicon002.lua`); 26/26 shell ≡ Xbox; +4 non-Xbox-NTSC language stubs (de/it/ru/es). See [`_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md). |
| Xbox↔PS3 DLC pairs | 36 | 36 | 36/36 structurally identical (13 also byte-identical; 23 differ only in Havok filler cohabiting the block) |

**Headline cross-platform-content facts, byte-level proven:**

- **~96% of PC resident chunks are behaviourally equivalent to Xbox** once ASSERT + print debug-trace strip are discounted. Only 9 chunks of 240 are real behaviour divergence — the 7 KBM/UI shell-GUI scripts (`mrxguishell`, `mrxguipausescreen`, `mrxguinumericbox`, `mrxguidialogbox`, `mrxguipda`, `mrxguibase`, `mrxguishellbootstrap`) that drop 1–29 KBM-specific protos on Xbox, plus the 2 PC-only LTI scripts. See [`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md).
- **Mission dialogue "spiel" chunks (222) and subtitles (36) are 100% IDENTICAL** across PC and Xbox — data-only tables, no logic, no debug. Portable without any per-platform build.
- **Hijack scripts are 93% debug-strip** — `Debug.Printf`-dense, but no actual logic divergence.
- **PS3 DLC Lua ≡ Xbox DLC Lua** — same compiler output, 13/36 byte-identical in the raw block.
- **PS3 base-game Lua ≡ Xbox base-game Lua** except one chunk (`scripts_vz/chicon002.lua`, Chinese Contract 002 — PS3 ships an older build missing the `_GetFlag` destruction-event checks that PC and Xbox retail carry). PS3 strips debug info more aggressively than Xbox (resident block is 2.04 MB smaller on PS3; all 238/238 chunks structurally identical).

**Bottom line for modders:** any community claim that "mission X plays differently on PS3/Xbox" is not backed by the Lua bytecode on any extracted platform. If a divergence exists, it lives in the C engine (spawn budgets, physics constants, population caps), not in the Lua.

---

## 7b. Lua source-level cross-platform differences — the specifics

**PROVEN.** Source: [`docs/mercs2-luacd-xbox/_structural_diff_report.md`](./mercs2-luacd-xbox/_structural_diff_report.md).

The 89 real-divergence scripts cluster in four areas, listed by mod-author impact:

### 7b.1 Entire GUI functions missing on Xbox (biggest single cluster)

The PC KBM menu-interaction layer that consoles don't need. Pause-screen alone drops 29 functions from PC → Xbox:

| Script | PC protos | Xbox protos | Functions dropped on Xbox |
|---|---:|---:|---:|
| `mrxguishell` (resident+shell copies) | 59 | 37 | **22** |
| `mrxguipausescreen` | 49 | 20 | **29** |
| `mrxguibase` | 184 | 183 | 1 |
| `mrxguipda` | 83 | 81 | 2 |
| `mrxguidialogbox` | 32 | 30 | 2 |
| `mrxguinumericbox` | 18 | 15 | 3 |

### 7b.2 ★ The LTI subsystem — PC's entire frontend/options UI backbone is PC-only

`"LTI"` is Pandemic's internal name for the PC frontend / options / input-binding UI subsystem; source lives at `D:\Projects\Mercs2_PC\mercs2\LTI\Src\PgLtiRendererPc.cpp` (literal `_Pc` suffix in the module name). Spans ~70 PC-only Lua entry points covering video options (`LTIVideoSetGamma`, `LTIVideoSetRes`, `LTIVideoSetVSync`, …), KBM input binding, joystick binding, audio sliders, mouse controls, start screen, text input, general settings, localization. **PS3 EBOOT has 0 LTI-UI hits; Xbox retail decomp 0.** Consoles delegate these to the platform's native system menu (Xbox 360 blade, PS3 XMB).

Related Lua: `mrxguiltiprecache` + `mrxguiltiprecachelayout` ship on PC only (in both resident and shell blocks); `mrxbriefing` and `wifpmcinterior` on PC reference an `LTILibName` global Xbox lacks. See [`docs/modding/cross_platform_lua_porting_guide.md#42-the-lti-subsystem--pcs-entire-frontendoptions-ui-backbone--is-pc-only`](./modding/cross_platform_lua_porting_guide.md).

### 7b.3 Language-loader WADs — per-SKU

Language-WAD shipping is a per-SKU decision, not a cross-platform divergence. The three measured SKUs ship:

| SKU | Language WADs shipped |
|---|---|
| PC retail (complete install) | 5: English, French, German, Italian, Spanish |
| PS3 BLUS30056 | 6: English, French, German, Italian, Russian, Spanish |
| Xbox 360 NTSC-US (JTAGRip) | 2: English, French |

Each `<lang>.wad` ships **exactly one Lua chunk** — the same 4-proto / 562-insn template with a 179-entry `vo_asset_table` and a single `AddLocalizedAsset(".<lang>")` call. All 13 shipped chunks (5 PC + 6 PS3 + 2 Xbox) have the same normalised string-pool SHA-12 (`b6eef55f5c79`), differing only in endian, debug retention, and the single lang-suffix string constant.

**Platform-exclusive language chunks:**
- **PS3-only:** `russian.luac` (1 chunk) — not shipped by PC retail or Xbox NTSC-US.
- **PC+PS3 but not Xbox NTSC-US:** German, Italian, Spanish stubs. Likely present on PAL Xbox variants; only NTSC-US JTAGRip measured here.
- **Xbox-NTSC-US-only:** none.

Full measurement: [`docs/_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md).

### 7b.4 ★ NEW — `mrxguisatellitelayout` placeholder bug (fix-pack candidate)

A legit PC build mistake Xbox got fixed before shipping. Satellite-overlay button widget:

| Field | PC Retail | Xbox 360 |
|---|---|---|
| Button name constant | `"Pistol"` | `"icon_hijack_button_A"` |
| Texture path | `.../buttons/Pistol.tga` | `.../buttons/icon_hijack_button_A.tga` |

Someone forgot to swap the placeholder before PC build; Xbox got the proper asset. **One-constant Lua fix-pack candidate** — single `replace_lua`-type Quartermaster entry would backport the Xbox-correct asset to PC.

### 7b.5 Other mentions worth knowing

- **`vzacon001`** — only clear case of Xbox *adding* a literal PC lacks (`"[Tutorial.SupportMenu]\n[Tutorial.UseSupport]"` combined stringdb key)
- **`mrxactionhijack`** — hijack minigame has `charGuid` global PC-only, 4,134-line raw diff dominated by `Debug.Printf` scaffolding
- **Long tail** — 8× `Object`-related, 5× `LTILibName`, 4× `table`-related, plus ~45 singletons. Full list in the structural diff report.

### 7b.6 Reserved-name slots mod authors can safely target

- **12 PC resident scripts are empty-shipping stubs** (compiled body is literally `RETURN r0 1`): `all_debug`, `all_gui`, `all_hijack`, `all_humans`, `all_objectscript`, `all_preload`, `all_sound`, `all_testscript`, `all_vehicles`, `all_weapons`, `common_asset`, `healthpickup`. Xbox siblings also empty. **Safe injection points** — overriding doesn't collide with any shipped behavior.
- **7 cut-contract names** referenced by PC + PS3 engine binaries but with no Lua body shipped on any platform: `AllCon009`, `ChiCon005`, `GurCon051`, `PmcCon011`, `PmcCon012`, `PmcCon014`, `PmcCon017`. Mod-registered content against any of these names is engine-reachable with no collision.
- **293 Phase-2 chunks** (missions, hijacks, subtitles, guilayouts, loaders) all contain real content but zero empty stubs; each is a named override target.

---

## 8. Multiplayer / online — three parallel dead services, one alive stack

**PROVEN.** Sources: [`docs/teknogods_coop_research.md`](./teknogods_coop_research.md) §4.2,
[`docs/mercs2_install_registry_contract.md`](./mercs2_install_registry_contract.md),
[`docs/reverse_engineer/networking_code_map.md`](./reverse_engineer/networking_code_map.md).

| Aspect                       | PC                                | Xbox 360           | PS3                |
|------------------------------|-----------------------------------|--------------------|--------------------|
| FESL hostname                | `fesl.ea.com` (per-service ID)    | `360FeslServiceId` | `mercs2-ps3.fesl.ea.com` (152.53.15.83) |
| Matchmaking backend          | Dead — EA shut it down            | Dead               | Dead (some Arcadia coverage) |
| Third-party emulator status  | `coopserver/` in-repo works (this project) | none | **Arcadia** (C# / .NET) "Online (no leaderboards)" |
| Peer mesh / network layer    | GM `NetworkManager` + `MassiveSocket` | same C code | same C code   |
| Co-op mode                   | 2-player co-op                    | 2-player co-op     | 2-player co-op     |
| Split-screen local           | **No** (never wired to input)     | **No**             | **No**             |

Community note: none of the three ever had **split-screen co-op**. All had
2-player online-only co-op. Community claim "consoles had split-screen" is
**false** — the multiplayer sub-system is a peer-mesh network layer on every
platform.

The FESL protocol is one wire format across PC/X360/PS3 with different service
IDs. `coopserver/` + `tlsterm/` in this repo revive it for PC. Arcadia (an
external C# emulator) revives it for PS3 without leaderboards. Xbox 360 has no
public revival stack that we've catalogued.

---

## 9. Achievements — same 30 IDs, mapped

**PROVEN.** Source: [`docs/mercs2-luacd/src/resident/mrxachievements.lua`](./mercs2-luacd/src/resident/mrxachievements.lua),
[`docs/mercs2-pdb-analysis/game-systems.md`](./mercs2-pdb-analysis/game-systems.md) §"Achievements".

- Same **30 `ACHIEVEMENT_*` IDs** shipped on all three platforms — the list is
  authored in `mrxachievements.lua` and is byte-identical between builds.
- Xbox additionally maps each ID to a **Xbox 360 achievement ID** via
  `Achievement #%d - (Group: %s)(Id: %s)(Xbox360Id: %i [0x%x])`.
- PS3 maps them to Trophies; the specific trophy hash mapping is not in-corpus,
  but the shipped set matches 1:1.
- PC: `Pg.AchievementAddCount` is wired but has **no back-end** — the Xbox Live
  / PSN reporting stack is dead. Nothing writes achievements to a live service.

Community claim "PC achievements never worked" is **confirmed** — not because
they weren't implemented, but because the EA Blaze / `fesl.ea.com` telemetry
backend the PC build reports to is offline.

---

## 10. Localization — same 6 languages, PC's UI hardcoded to 7

**PROVEN.** Sources: [`docs/reverse_engineer/eighth_language_wiring.md`](./reverse_engineer/eighth_language_wiring.md),
[`docs/loading_shell_wad_analysis.md`](./loading_shell_wad_analysis.md) §"Language / Localization Blocks",
[`memory/novel-language-stringdb-residency.md`](../memory/novel-language-stringdb-residency.md).

All three ship the same six full localizations: English, French, German,
Italian, Spanish, Russian (russian VO == english VO, verified — a shipping
oversight, cross-platform). Japanese ships fonts but not a full stringdb.

Platform-specific quirks:
- **PC has no in-game language selector.** Language is picked at boot from the
  Windows registry / OS locale. Adding a genuine 8th language on PC needs an ASI
  patch, not a data edit — the 9-entry pointer table in `.data` and its `index ≤ 8`
  bound are hardcoded.
- Consoles pick language from the system UI at OS level. No PC-style registry
  keying trap.

---

## 11. Save format — same on-disk shape, `ProfileHash` was the sticking point

**PROVEN.** Sources: [`memory/profile-hash-is-crc32-bzip2.md`](../memory/profile-hash-is-crc32-bzip2.md) (via corpus),
[`docs/reverse_engineer/save_serialize_code_map.md`](./reverse_engineer/save_serialize_code_map.md).

- Save filename shapes match: `NoTRCSave%02d.sav` and `ConvertNoTRCSave%02d.sav`.
- Save integrity hash **is `CRC-32/BZIP2` (non-reflected)** over bytes `[4:]` —
  same algorithm on all three platforms (`save_write::profile_hash`).
- Console save-icon binaries (`ps3saveassets_*_P000_Q3`, 214 B rows w/
  `type_hash = 0x8F0A54E2`) are **still present in the PC WAD** as dead PS3
  metadata remnants (French, Italian, no-locale variants).

Cross-platform save transfer is not proven from the corpus, but with the same
hash and same on-disk shape it is likely tractable.

---

## 12. Version families (executable / patch history)

**PROVEN.** Source: [`docs/modding_deep_dive.md`](./modding_deep_dive.md) §"Version identification",
[`docs/mercs2_install_registry_contract.md`](./mercs2_install_registry_contract.md).

| Executable                     | Size       | SecuROM version | Notes |
|--------------------------------|------------|-----------------|-------|
| PC Demo (`Merc2-Demo.exe`)     | 16.3 MB    | v7.38           | PDB path `SecuROM-DRM_7_38` |
| PC Retail v1.0                 | 16.1 MB    | v7.37           | `SecuROM-DRM_7_37` |
| PC Update v1.1                 | 51.4 MB    | v7.38           | `SecuROM-DRM_7_38` |
| PC v1.1 (uncracked, this repo) | 53.94 MB   | v7.38           | Byte-verified against `is_canonical_v11` |
| Xbox 360 Jul-11-2008 preview   | (STFS)     | n/a             | `Profile` devkit build with 38,581 fns |
| Xbox 360 retail                | (STFS)     | n/a             | `Final` build — stripped debug strings |
| PS3 v1.03 patch                | (EBOOT)    | n/a             | Ships `VZ-PATCH.WAD` / `SHELL-PATCH.WAD` — same last-wins overlay as PC |

PC users on multiplayer need normalized registry `Region` for matchmaking parity
(the modkit does this). Version-mismatch on retail v1.0 vs v1.1 is a common
"can't see each other" cause.

Xbox and PS3 both received post-release patches; PS3's `v1.03` also ships the
overlay-WAD mechanism, confirming the WAD-overlay design is not a PC-only
invention.

---

## 13. Cases where PC is *ahead* of consoles

**PROVEN.**

- **Verbose debug strings retained** — mission scripts on PC ship with all the
  `Printf` / `Debug` / `@source:` / `@locvar:` metadata Xbox strips. Useful for
  RE and modding, invisible in play.
- **DLC loader is more automated on PC** — no `package.cfg` needed; the engine
  auto-scans for `*-patch.wad` next to every base WAD. Consoles need explicit
  registration.
- **Modding is entirely tractable** — PC has an unpacked exe, a working ASI
  loader ecosystem, `dxwrapper` for licensed installs, and the `qm`/Quartermaster
  pipeline. Console modding has no equivalent stack.
- **Higher-resolution rendering is possible in principle** — PC is D3D9, so any
  post-processing added would run at the user's chosen resolution, not a fixed
  console output.

---

## 14. What we still don't know (open items for parity work)

**HONEST GAPS.** Send bytes/evidence and we'll close each of these.

1. **Xbox 360 cutscene set** — not yet extracted for a same-methodology diff vs
   PS3/PC. Community says "Xbox ≈ PS3 quality" but we haven't measured.
2. **PS3 post-processing** — is motion blur actually on PS3, and is the pipeline
   the same set of shaders as Xbox? Not measured.
3. **PS3 vs PC Bink track-ID full remap table** — we know `0x7d6` is silent on a
   PS3 drop-in; the full track-ID mapping across all 8 shipped languages hasn't
   been catalogued.
4. **Vehicle physics constants across platforms** — some community reports of
   "vehicles handle differently" have not been checked byte-level. Physics
   tuning constants (Havok tuning parameters, custom drive-model rings and pump
   values) sit in ECS `[presize]` and could be diffed against console binaries
   if we get an Xbox / PS3 image extract in.
5. **Kept-population ring cap-vs-stage interpretation** — the 8 vs 64 label on
   `DAT_00ed55d4` (§3) is still labeled `confirm-live` in the code map. Not
   load-bearing (density scaling works around it), but a live break on the
   ring writer would close the interpretation cleanly.

**Not open (dropped from earlier drafts):**
- ~~PS3 base-game `VZ.WAD` diff vs Xbox~~ — moved to "solved for our purposes".
  PS3 content == Xbox content (5287 identical ASET hashes, 36/36 DLC Lua
  byte-identical) makes the envelope crack functionally moot. See §6 and
  [`memory/ps3-dlc-crack-and-klicensee.md`](../memory/ps3-dlc-crack-and-klicensee.md).
- ~~PC 8-slot vs Xbox 64-slot population ring, framed as a "smaller ambient
  cache"~~ — reframed in §3. The density system is understood and scalable;
  the ring label is a small interpretation detail moved to item 5 above.
- **Full base-game Lua cross-platform divergence survey** (CLOSED).
  All **679 PC + 676 PS3 + 672 Xbox NTSC-US** base-game Lua chunks extracted, decompiled,
  and structurally diffed across all three platforms. **231/240 = 96.25%** of PC resident
  chunks are behaviourally ≡ Xbox once ASSERT + print debug-trace strip are discounted;
  only 9 real behaviour divergences (7 KBM-UI drops + 2 PC-only LTI chunks). PS3 ≡ Xbox for
  642/643 vz chunks and 26/26 shell chunks; one real divergence (`scripts_vz/chicon002.lua`
  ships an older build on PS3). One PC placeholder bug Xbox got fixed in
  `mrxguisatellitelayout` (§7b.4) — fix-pack candidate. Language-WAD footprint is per-SKU
  (§7b.3). See §7, §7b, [`docs/_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md),
  [`docs/_ps3_base_game_lua_diff.md`](_ps3_base_game_lua_diff.md), and
  [`docs/_ps3_full_wad_set_lua_diff.md`](_ps3_full_wad_set_lua_diff.md).

---

## 15. Community claims we've NOT verified — send us the source

If you or the modders you're working with have specific claims from forum
threads / video comparisons / GameFAQs pages, they belong here so we can either
confirm or refute them from bytes. Please pass through the *specific* claim +
where it came from, and we'll cross-check. Common ones we've heard but not
measured:

- "PS3 shadows are higher-res than Xbox / PC."
- "PC has worse draw distance."
- "Xbox has better anti-aliasing."
- "Certain vehicles/weapons behave differently across platforms." — **partially closed at the Lua layer** (vehicle hijack scripts are 93% debug-strip, 0% real-divergence per §7). May still be true at the native-engine physics layer; see §14 item 4.
- "The PS3 version's frame-rate is worse in dense combat."
- "Water rendering differs between PS3 and Xbox."
- "PC's HUD/UI layout differs slightly from consoles." — **confirmed true at the Lua layer** (see §7b.1 — Xbox GUI drops 22+29+1+2+2+3 = 59 functions across the pause/shell/dialog/numeric-box family; PC ships KBM menu-interaction methods consoles don't). Open at the stringdb-layout / native-HUD level.

Most of the above are still answerable — needs the specific target
and a way to acquire the counterpart bytes for a diff.

---

## Reference — the RE artefacts this document sits on

- `docs/dlc_loader_cross_reference.md` — DLC loader mechanism across all three.
- `docs/xbox360_dlc_analysis.md` — Xbox DOH / STFS format vs PC.
- `docs/dlc_pc_port_status.md` — PC-side status of the DLC port.
- `docs/movies_pc_vs_ps3_catalog.md` — full per-file Bink cutscene diff.
- `docs/aset_format.md` §"Xbox layout is MIRRORED" — the u16-swap trap.
- `docs/contract_analysis_{chi_all,gur_pir,oil_vza,pmc_jet_mec}.md` —
  per-region mission-script cross-platform diffs.
- `docs/reverse_engineer/sky_post_hdr_code_map.md` §7 — motion blur / velocity.
- `docs/reverse_engineer/population_spawner_code_map.md` §5 — the 64 vs 8 ring.
- `docs/reverse_engineer/eighth_language_wiring.md` — PC language enumeration.
- `docs/teknogods_coop_research.md` §4.2 — Arcadia PS3 FESL emulator.
- `memory/ps3-dlc-crack-and-klicensee.md` — PS3 DLC full decrypt chain, the
  "PS3 content == Xbox" finding.
- `memory/ps3-movies-dropin-on-pc.md` — verified PS3 Bink → PC drop-in.
- `memory/multiplatform-compile-backend-assessment.md` — the "one console
  backend serves both" finding.
