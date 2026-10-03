# Engine divergence — Phase 3 queue

Follow-up to the Phase 2 cross-platform engine measurement at
[`docs/_engine_divergence_phase1.md`](../../docs/_engine_divergence_phase1.md).

Not started. Items are independent — pick in whatever order fits the current work.

---

## A. Validate the Phase 2 `INFERRED` claims

Phase 2 marked several items `INFERRED` explicitly. Promote each to `PROVEN` with a
targeted test.

- **§2 PS3 shader TOC as (VS, PS) pairs.** Currently inferred from offset-delta
  consistency. Prove by locating the shader-loader function in a PS3 Ghidra decomp
  (pending on local run) and reading the TOC-record stride.
- **§3.7 codec `0x05` = XMA2 across EVERY retail Xbox wavebank.** Currently proven only
  for block 3187. Sweep all 95 wavebank ASET entries, extract each sub-chunk, run the
  structural XMA2 packet-header test. Pass criteria: 95/95 show 2048-byte-aligned packets
  with valid frame_counts.
- **§3.7 pre-first-blob 0x57C-byte padding = 2048-byte XMA2 alignment.** Currently
  inferred. Prove by checking the `(0x800-aligned-from-body-origin)` relation across all
  95 wavebanks.
- **§3.5 PS3 `chicon002` behaviour under runtime.** Phase 2 proved the bytecode delta but
  not the gameplay effect. Load the Chinese Contract 002 mission in RPCS3 (or real PS3)
  and verify the specific missed `_GetFlag` destruction-event callback.

## B. Fix the reimpl wavebank layout defects

Three concrete defects in `tools/wad_simulator/crates/mercs2_formats/src/be_to_le/audio.rs`
surfaced by Phase 2 §3.7:

1. Reads `+0x00` as a "count" field — it's version `0x1D` (same as PC).
2. Places `data_offset` at `+0x0C`, `data_size` at `+0x10`. Real retail layout:
   `data_size@+0x0C`, `decoded_sample_count@+0x10`, `data_offset@+0x20` (record-relative).
3. Treats codec `0x05` as Xbox-ADPCM and nibble-swaps 36-byte blocks. Real data is XMA2;
   dispatch produces silence/garbage on retail wavebanks.

Current test (`wavebank_matches_python_byte_exact`) only validates against a synthetic
mock built to the wrong layout. Fix path: rewrite the parser against the proven layout in
`docs/_xbox_wavebank_container.md`, add a retail `xbox-vz.wad` wavebank as a byte-level
test fixture, confirm each clip's XMA2 bytestream re-encodes losslessly.

Reimpl work stream, not an engine-divergence task — captured here because it's a direct
consequence of Phase 2.

## C. Deep-dive one subsystem across all three platforms

Phase 2 showed the SHAPE of divergence per subsystem. Phase 3 can prove exact
cross-platform caps for one specific subsystem. Candidates:

- **Physics tuning.** `_CarPhysicsV2`, `_HelicopterPhysics`, `_HumanPhysics`, car-mass,
  car-grip values from the vehicle data — do console retail tuning constants match PC?
- **Weapon balance.** Damage, range, spread, reload — hashed component descriptors shipped
  per weapon type.
- **Population AI budgets.** PS3+Xbox ship `PopulationSimpleSpawner 2048` vs PC 768. Does
  this translate to 2.67× more NPCs on consoles in practice, or does the engine cap elsewhere?
- **Shader program-level diff.** PC's 1,023 vs PS3's 1,102. Which are RSX-only effects
  (PRSX framebuffer post-process, RSX tiled rendering helpers) vs features PC drops?

Each would surface a per-subsystem divergence table like §3.4's cdbsizes.

## D. Lua binding surface across platforms

Phase 2 established PC/PS3/Xbox ship 679/676/672 Lua chunks. The host-side bindings — C
functions each platform exposes to Lua (`Sound.*` / `VO.*` / `Pg.*` / `Mrx*`) — were not
diffed. Would surface which engine-side features Lua can touch per platform.

## E. Save-file and settings format — done (`docs/_phase3e_save_format_cross_platform.md`)

Written up: same engine serializer, same `ProfileHash = CRC-32/BZIP2 over [4:]` identifier
on all three platforms, same inner `return { … }` Lua zlib payload. PC settings
(`Mercs2.ini`, 47 Win32 call sites) are PC-only; Xbox and PS3 ship no user-settings INI.
PS3 does **not** import `cellSaveData` → saves are plain-filesystem files under
`/dev_hdd0/.../BLUS30056_00/`, not PFD-wrapped. PS3 adds `AddProfile1/2Data` +
`sProfileName1/2` — a two-slot local-profile hook not on PC/Xbox.

Follow-ups left BLOCKED by missing bytes / undersized decomps:

1. **Capture one retail Xbox 360 save file** and one retail PS3 save tree. Byte-dump
   the first 0x468 bytes and confirm the LE header + CRC-32/BZIP2 match on each
   platform. Current console-side hash-algorithm claim is INFERRED (symbol-anchored),
   not byte-proven.
2. **Re-seed the PS3 retail Ghidra project** (A.1 blocker here too — `.opd` function-start
   seeder is incomplete; current decomp 1.7 MB vs Xbox retail 55 MB). Needed to locate
   `20PgSysSaveGameManager` / `21PgSaveGameDataManager` function bodies and the native
   `cellFs*`-anchored write site.
3. **String-anchor the Xbox retail Final decomp** (`output/_ghidra_x360_final/`, 52 MB)
   to resolve the STFS CON/LIVE/PIRS wrap question — `save:\` is a devkit TRC-drive
   artifact, retail is almost certainly wrapped. Look for `XContentCreateEx` /
   `XContentOpenFile` call sites.
4. **Resolve PC `.profile@0x462..0x467`** — the 2× u16 immediately before the zlib
   stream are constant across fixtures but unlabelled. HW-write-breakpoint at `0x462`
   during a save event.
5. **Locate the PC load-side corruption-compare site** — `FUN_00614080` *raises*
   `hasCorruptedSave`, but the upstream byte-level check (hash + version + size
   invariants) that sets it is unlocated in the dump. Required to prove the full set
   of invariants a transferred save must satisfy on load.

## F. UI render pipeline resolution — PC closed, consoles partial

Deliverable: `docs/_phase3f_ui_resolution_cross_platform.md`. Status:
- PS3 values PROVEN: `[pcwin] 1280×720`, `[ps3] 1280×720`, `[x360] 640×480` baked at
  EBOOT offsets `0xdc5615` / `0xdc5879` / `0xdc5d1b`. Phase 2 missed them because the PS3
  EBOOT has two disjoint cdbsizes blobs separated by ~0x2200 bytes; Phase 2 started at
  the second blob (`[presize]` at `0xdc7818`).
- Section/role: `x_res`/`y_res` sit under per-platform engine-config sections
  `[pcwin]`/`[ps3]`/`[x360]` (not `[presize]`, `[Render]`, or any memory section).
- PC role PROVEN: parser `FUN_004c2c20` (called from `FUN_004c2190`) reads `[pcwin]
  x_res`/`y_res` by hash (`0x3777aa44` / `0x8d48b9bd`) into `_DAT_00d289f0` / `_DAT_00d289f4`.
  **Both sinks are dead writes** — only the two writes exist in the 27k-fn decomp; no
  consumer. The real PC framebuffer dimensions come from `Mercs2.ini [Render] ScrW/ScrH`
  via `FUN_00753280` → `DAT_00dfc328/32c` (defaults `0x400/0x300`).
- Console role BLOCKED on the A.1 cross-platform-decomp gate (no PS3/Xbox decomp text).
  Opening a PS3 decomp pass would let us check whether the `[ps3] 1280×720` sink is
  consumed, and settle the `[x360] 640×480` anomaly.
