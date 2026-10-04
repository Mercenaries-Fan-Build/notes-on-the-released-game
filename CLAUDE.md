# AGENTS.md — Mercenaries 2 Reverse-Engineering & Recreation Project

Persistent routing guidance for AI coding agents working on this repository. Points to the tools,
canonical docs, and standing mandates. **Capability status, task progress, and "what works now"
belong in Q/A with the user — not in this file.** Read this whole file once before acting.

---

## What this project is

A research + toolchain hub for reverse-engineering *Mercenaries 2: World in Flames* (Pandemic
Studios, 2008, "Pangea"/`Pg*`-lineage engine) and rebuilding it. Several programs share one
corpus of knowledge and one asset-format layer:

1. **Reverse engineering** — the shipped 32-bit PC exe is the **specification and oracle**, never
   the shipping artifact. Decomp + x32dbg live bridge + per-subsystem code maps.
2. **64-bit Rust/wgpu engine reimplementation** — the north star. `tools/wad_simulator/` workspace,
   consumes original assets, reimplements one gated system at a time.
3. **Unofficial fix-pack** — bug fixes on the retail engine, delivered as layered `-patch.wad`
   overlays.
4. **Asset injection / modding / DLC port** — additive content via a `vz-patch.wad` overlay.
5. **Online restore** — FESL/Theater emulator + TLS shim.

> Every data claim must be verified from the original game binary or shipped bytes. No guessing.
> Where the exe can't be read statically, read it live in x32dbg — do not assume.

---

## 0. START HERE — the corpus-first reflex (MANDATE)

**`mcp__corpus__corpus_search` is the FIRST action on any non-trivial task** — before grep, before
Read, before spawning readers, before re-deriving anything. The corpus (`corpus` MCP server,
registered in `.mcp.json`) is a LanceDB index over docs + memory + past conversations + mods +
tools + commits + the Ghidra decomp. Three questions, in order:

1. **Have we already solved this?** (Don't redo work.)
2. **What's related / where does it live?**
3. **Do the results match what I expected?** (Nothing returned is itself a finding.)

Tools: `corpus_search`, `corpus_xref` (chunks mentioning an address — `FUN_…`/`0x…`
spelling-independent), `corpus_get` (full chunks of one doc), `corpus_callgraph` (BFS
callers/callees), `corpus_coverage` (which fns are documented — the naming queue), `corpus_stats`,
`corpus_status`, `corpus_ingest`.

- Every hit carries a `date`. Transcripts are `unreviewed` and rank **below** written-up docs.
  Docs declare `status:` and `evidence:` — prefer current + proven + recent over merely confident.
- **Search at each decision, not once at task open.**
- If a freshly-written fact seems missing, run `corpus_status` — a stale index is why. Refresh:
  `cd tools/corpus_mcp && npm run ingest` (incremental), or `corpus_ingest` in a session.

The persistent memory lives at `~/.claude/projects/…/memory/` (indexed as source `memory`). Routed
by `MEMORY.md`; full index in `MEMORY-CATALOGUE.md`.

---

## 1. Repository topology

Two git repos in this tree. Confusing them has cost real work.

| Path | Repo | Notes |
|---|---|---|
| `.` (`notes-on-the-released-game`) | **Parent** — notes/research + toolchain | Tracks `tools/corpus_mcp` and `game-scripts/` as ordinary files. |
| `tools/wad_simulator/` | **Nested repo** (own `.git`, **gitignored** from parent) | The Rust engine workspace. Use `git -C tools/wad_simulator …`. A clean parent `git status` says nothing about this tree. |

- `tools/corpus_mcp/` — corpus MCP server (Node/ESM). Part of the parent repo.
- Bundled, portable, no install:
  - `tools/ghidra_12.1_PUBLIC/` — Ghidra 12.1 (headless + GUI).
  - `tools/jdk21/` — JDK Ghidra runs on. Wire via `JAVA_HOME` env; keep
    `support/launch.properties` `JAVA_HOME_OVERRIDE=` **empty**.
  - `tools/ffmpeg/bin/` — ffmpeg (bundled; MP3/XMA/XMA2 decoders enabled).
  - `tools/external/unluac/unluac.jar` — Lua 5.1 bytecode disassembler/assembler. Also
    `tools/jdk21` for the JRE.
  - `tools/pandemic_hash.py --m2` — the Pandemic hash computer.

Sibling repos on the Desktop (not in this tree — don't look here for them):
`Mercenaries 2 World in Flames` (retail install), `mercs2-modkit` (Tauri/Vue installer),
`mercs2-lua-essentials` (Wally's in-game Lua stdlib "Ess").

---

## 2. Standing mandates (non-negotiable — from the user)

Each is a correction after a real failure. They override defaults.

- **★ Corpus-first** (§0). `corpus_*` before grep/Read/re-derivation.
- **★ Novel assets must be ADDITIVE.** Overwriting a shipped asset invalidates the work.
  **Never merge into `vz.wad`** — the base archive stays pristine; injected content ships via the
  `vz-patch.wad` overlay, made resident by Lua preload, never by rewriting the base.
- **★ Never invent a hash.** Every hash = `pandemic_hash_m2(<real name>)` — the *name* is the
  identity (verify with `tools/pandemic_hash.py --m2`). Registry insert is **first-wins**, so a
  fabricated 32-bit constant that collides silently drops *your* asset. A hash match alone is not
  evidence a name is real.
- **★ Cracked names go into the rainbow files** — tracked home is
  `docs/data/aset_discovered_names.json`, match indent, not a side `--emit` fragment.
  `tools/rainbow_table.json` is gitignored; `rainbow_table.json.bak` is a tracked ~75 MB file
  (not scratch).
- **★ Use Rust tooling, not Python.** Pipeline is the Rust `wad_simulator` workspace; Python
  under `tools/` is legacy/reference. (DCC prep in Blender is the one orthogonal exception.)
- **★ Probe binaries live ONLY in `mercs2_probe`.** Every probe/mint/forge/verify binary is a
  `mercs2_probe` subcommand — never a `src/bin/` in `mercs2_game` or `mercs2_formats`.
- **★ No hiding features behind flags.** Wire real behaviour in unconditionally and
  data-driven; only diagnostics may be toggled.
- **★ x32dbg: NEVER resume the process** (§3.1). Read-only while PAUSED; the USER drives execution.
- **★ Verify artifacts by hash.** sha256 every deployed WAD/binary before AND after. Size/mtime lie.
- **★ Gate on exit code, never a printed count** — and beware the silent-skip trap (§5), which
  defeats even exit-code checks.
- **★ SecuROM is not a blocker.** Do not mark work blocked on DRM; split-thunks forward to real
  `.text` bodies. See §3.1 for the toolchain.
- **★ No status in standing docs.** CLAUDE.md and committed docs route to tools, paths, and
  mandates. "Proven", "landed", "WIP", "not yet", "shipped", "currently blocked" belong in Q/A
  with the user, not in CLAUDE.md and not as meta-commentary in code.
- **Minimal edits in others' code**; no comment rewording. **Ask, don't assume** on unverified
  setup/intent facts. **No give-up suggestions** — give technical next steps, never "shelve it."
  **Direct work style** — report findings and proceed, no meta-commentary.

---

## 3. The programs

### 3.1 Reverse engineering — the exe as oracle

The shipped PC exe is symbol-less and SecuROM-wrapped. Toolchain:

- **Ghidra decomp**: `output/_ghidra/securom_dump/mercs2_unpacked.exe` (unpacked, rebuilt PE)
  decompiled to `output/_ghidra/mercs2_unpacked.exe_decomp.txt`, indexed in the corpus as source
  `ghidra`.
  - Headless run: set `JAVA_HOME` to `tools/jdk21/…`, then
    `tools/ghidra_12.1_PUBLIC/support/analyzeHeadless.bat <proj> <name> -import <exe> -scriptPath scripts/ghidra_scripts -postScript <Script>.java`.
  - Post-scripts in `scripts/ghidra_scripts/`: `DecompileAllByName.java`,
    `DecompileAllFunctions.java` (both call `clearFalseNoReturn()` — fix for x87 sqrt/abs
    helpers that truncate float-heavy fns), `RecoverSecuromCode.java`, `CoverageReport.java`,
    `FnMnemonicSig.java` (build matching).
  - `mercs2_reassemble` (`cargo run -p mercs2_reassemble --release`) left-joins every attribution
    source onto the decomp by virtual address (`FUN_00478120` == `0x478120`), then propagates
    residue by locality + call-graph. Output: `output/engine_reassembled/`. Evidence is **graded**
    — never conflate a propagated `inferred` guess with a decompiled fact.

- **x32dbg live bridge** — the `mcp__x32dbg__*` tools inspect the already-unpacked process in
  memory. Read-only inspection: `MemoryRead`, `StringGetAt`, `DisasmGetInstructionRange`,
  `GetRegisterDump`, `GetCallStack`, `PatternFindMem`. You MAY set breakpoints for the user to
  hit; you may NOT drive execution.
  - **Session-killers:** never put a **conditional** breakpoint on a **hot per-frame** function —
    x32dbg goes down and takes the game with it. Break on rare fns, use single-shot BPs,
    HW-write watchpoints, only offsets proven from decomp. During a livelock: read-only snapshots
    only, no BPs, GUI-pause only.

- **SecuROM toolchain** — the on-disk exe is wrapped; the in-memory image is clean.
  - `securom_unwrap` crate turns a decrypted exe (dumped past OEP) into a SecuROM-free PE —
    repoints OEP, rebuilds a clean IAT, preserves every section byte-for-byte.
  - `scripts/ghidra_scripts/RecoverSecuromCode.java` force-disassembles the SecuROM VM partition
    (indexed in corpus as `ghidra/FUN_02xxxxxx`); dispatcher is `FUN_02a30028`.
  - `make crack-game RETAIL_EXE=… OUTPUT=./output` + `tools/apply_securom_patch.py` apply the
    retail bypass. DRM never touches data files — modding needs no DRM bypass.
  - Split-thunks: a `thunk_FUN_024xxxxx` is one of three cases: (1) a forwarder that jumps 1–3
    hops back to a real `.text` body — follow it via `corpus_xref`; (2) VM-virtualized residue —
    read live in x32dbg; (3) not SecuROM at all — a plain Ghidra coverage gap, force-decompile.
    "binding-only" in a code map usually means Ghidra never walked there (no static caller), not
    encrypted — disassemble directly. Memory: `binding-only-is-not-a-wall-disassemble.md`.

- **Format decoders** — tools and corresponding doc per format:
  - MOPP (Havok BV-tree): `mercs2_formats::mopp` + `docs/reverse_engineer/mopp_bytecode_format.md`.
  - Havok anim: `mercs2_formats::havok` + `havok_extract` + period-correct HCT 5.5
    `AssetCc2.exe` (external oracle). Memory: `havok-anim-toolchain-roundtrip-proven.md`.
  - Wavelet anim: `tools/hk_anim/wavelet.py`, Rust successor in `havok_extract`.
  - Name registry / spawn-by-hash: `pandemic_hash_m2` keys events, templates, tunables, spawn.
    PC impl `Hash_String FUN_00824270`; rainbow at `tools/rainbow_table.json.bak` +
    `docs/data/aset_discovered_names.json`.

- **Tracing ASI mods** in `mods/`: `engine_trace_asi` (INT3 audio call-chain capture),
  `lua_trace_asi`, `surface_a_probe` (asset→struct dumps for the reimpl's Surface-A gate),
  `crowd_fog_couple`. Behavioral oracles the reimpl gates against.

### 3.2 The 64-bit Rust/wgpu engine reimplementation

**Charter:** `docs/modernization/00_charter.md`. **Scoreboard** (authoritative live status —
update it, don't re-survey, don't duplicate here):
`docs/modernization/engine_support_inventory.md`.

Rebuild Mercs2 as a native 64-bit, maintainable, faithful, faster open engine consuming the
original assets. Locked decisions: **Rust** on the `wad_simulator` workspace (D2);
renderer = **`wgpu`** (D3); **no DXVK bridge** — exe kept purely as oracle (D4); original exe +
Ghidra decomp + x32dbg = **oracle/spec** (D6).

**Governing principle:** *Implementation is free; behavior is gated.* The constraint is provable
behavioral **equivalence**, not implementation fidelity.

**Lua runtimes:**
- `mercs2_script` — Lua 5.4 via `mlua` with a 5.1 compatibility prelude for behavioral parity
  (native i64, so money/economy is `i64` for free).
- `mercs2_luac` — exact Lua 5.1.5 library (float `lua_Number`, 32-bit `size_t`) for byte-exact
  bytecode/VM work; emits LuaQ chunks the retail game accepts.
- When precision matters, say which one you mean.

**Regression harness** — two oracle surfaces: *Surface A* (asset→struct, byte-identical vs x32dbg
dumps), *Surface B* (script→engine-binding call-trace equivalence). Plus render-golden hashes,
`loadprobe`-scored milestone gates, record/replay determinism.

**Structure** — the dependency graph is **inverted**. `mercs2_engine` owns and `pub use`-re-exports
all mechanism crates + `mercs2_script`. `mercs2_game` depends on only `mercs2_engine` +
`mercs2_core` + `mercs2_formats` and reaches mechanisms via `mercs2_engine::<name>::…`
(alias traps: `mercs2_water`→`::water_sim`, `mercs2_ui`→`::widgets`). One app loop lives in
`mercs2_engine::app` (a `Game` trait + `run<G: Game>`). ECS World is the single source of truth —
host shares the live `Rc<RefCell<hecs::World>>` via `attach_world`.

**Parallelization plan:** `docs/modernization/reimplementation_parallelization_plan.md` carves
work into 16 silos.

### 3.3 The unofficial fix-pack (retail engine)

**Backlog:** `docs/fixpack/bug_register.md` (status vocab
`reported→confirmed→fix-designed→built→verified`). **The USER supplies every bug — never
invent one.** Memory: `mercs2-fixpack-project`.

Four independently-installable tiers: **T1 text (stringdb)** · **T2 Lua/data** · **T3 exe patch**
· **T4 restored/cut content**.

**Delivery routes:**
- **T1 text → a single `English-patch.wad`** — mounts last and overrides both stringdb copies.
- **T2 Lua → MERGE into the live `vz-patch.wad`** via
  `mercs2_formats::patch_wad::merge_patch_wads` — never overwrite.

**WAD mount rules — three simultaneous, opposite:**
- The WAD stack is **last-mounted-WINS**.
- The chunk registry (once resident) is **first-wins**.
- String DBs (`AddStringDb`) are **last-registered-wins, capped at 8** (the 9th silently gets
  nothing).
- `shell.wad` and `vz.wad` share the single `<level>.wad` slot and ship a byte-identical English
  stringdb — patch only one and you fix only half the game.

**stringdb format:** LITTLE-endian, bodies UTF-16LE, tags `KEYS`/`STRS` (reversed `SYEK`/`SRTS`
are Xbox BE misread), `STRS` header = u16 code-unit count.

**stringdb tooling (all Rust):** `mercs2_formats::stringdb`, `mercs2_probe --bin stringdb_dump` /
`stringdb_roundtrip`, `wad_builder --bin stringdb_patch`, `mercs2_probe --bin wad_dupes` +
`docs/fixpack/wad_duplicate_inventory.md`. Trap: a string in the table is not proof it's
displayed — confirm the key is live first (`Enter vehicle` exists but the live prompt composes
`Drive %s`).

**Modkit** — three setup paths (`memory/modkit-two-setup-paths-licensed-dxwrapper`) so a
legally-owned copy is never force-cracked: `drm_free` (a `mercs2_nodrm_v*.exe` importing
`pmc_bb.dll` directly), `licensed` (dxwrapper loads plugins; pmc_bb stands down), `crack`. One
`pmc_bb.dll` on all paths, deconflicted at runtime via `DxWrapperOwnsPlugins`. Logging build is
`pmc_bb_log.dll`.

### 3.4 Asset injection / modding / DLC port (additive, via `vz-patch.wad`)

**Authoritative process:** `docs/asset_injection_playbook.md`.
**Field guide of corpus-cited traps:** `docs/modding/field_guide.md` — read it. This engine
"almost never tells you what you did wrong" — a typo is a valid hash that resolves to nothing,
silently.

**Four-stage pipeline:**
- **A0** DCC preprocess: Blender headless, `tools/fbx_preprocess.py` (tri budget < ~10.9k,
  verts < 65535, single mesh/material).
- **A** Import & verify: `tools/gltf_to_ucfx_model.py` maps into donor vertex space; preserves
  `INFO/HIER/MTRL/SEGM/PHY2/STAM` byte-for-byte.
- **B** Textures fully-resident: `mercs2_formats::texture::build_resident_texture`; slot order
  **0=diffuse / 1=SPECULAR / 2=NORMAL**, normal is DXT5nm.
- **C** Inject via `smuggler` (by-hash overlay builder). Override-by-hash works; a *new* asset
  needs its own ASET row or world-load wedges.
- **D** Placement per class: static = `Pg.Spawn(hash,x,y,z)`; wardrobe = `_tOutfits`; store =
  `tSupportData`.

**Injection tooling in `tools/wad_simulator/crates/`:** `smuggler` (by-hash overlay),
`wad_builder` (raw→engine `vz-patch.wad`, byte-exact identity oracle), `densify` (additive veg
scatter), `anim_patch`, `mercs2_workshop` (native-renderer asset browser), `mercs2_poc`
(`inject_character`).

**★ Gate EVERY build with `aset_refcheck`** — a builder that remaps only `_P000` while
`_P001/2/3` dangle sends the engine chasing a 549 GB buffer request → livelock.

**★ `mercs2_workshop --render <name|0xHASH>` IS the iteration loop** — headless, textured +
skinned + posed from packed bytes. Use it instead of in-game screenshots. `--no-auto-patch` is
mandatory while iterating. Render a known baseline (e.g. `pmc_hum_mattias`) beside the import.

**Character/skin/DLC references:**
- Rig/skeleton: `docs/modding/character_kit.md`, memory `pandemic-shared-human-rig-mercs2-saboteur`
  (Mercs2 and Saboteur share one human skeleton — identical bone name-hashes and bind pose).
  Cross-game port is a name-hash JOIN, not a weight transfer.
- Skinned custom-character import: `retarget:` on `add_outfit`; dense foreign rigs > 48 bones
  need `single_group: true`; skins bind only when shipped fully-resident. BLENDINDICES are
  per-group palette-relative.
- Store items: `docs/modding/character_kit.md` + `smuggler` (faction keying matters — Eva's PMC
  shop queries faction `"Pmc"`).
- `Pg.Spawn` of a novel template: name→handle into registry `@0xDF6B88` is the SDK ASI route;
  the entity template body into the live worldentity pools is a separate injection.
  Memory: `spawn-registry-runtime-injection`.
- Vehicle template subgraph (functional boat/vehicle): decoded in
  memory `boat-vehicle-template-spec` — components `_BoatPhysics`+`SeatLink`+`EntranceLink`+
  `PhysicalLink`+`ModelName`+`Health`, not a static collision shape.
- **DLC01 port pipeline** — crates: `dlc_port` (BE→LE), `ps3_dlc_crypt` (PS3 PKG→EDAT→SELF),
  `mercs2_formats::patch_wad::merge_patch_wads` (compose into PC `vz-patch.wad`).
  Deliverables with per-mechanism detail: `docs/_dlc01_pipeline_readiness.md`,
  `docs/_dlc_port_xbox_doh_side_oracle.md`, `docs/_ps3_terrain_native_reinterleave.md`,
  `docs/_dlc01_shader_triage.md`, `docs/_dlc01_shader_name_recovery.md`,
  `docs/_descriptor_walker_oracle.md`.

### 3.5 Online restore (dead EA services)

`coopserver/` — FESL / Theater / DNS emulator (Python) that revives matchmaking. `tlsterm/` —
TLS termination shim. The game's FESL client is statically-linked **OpenSSL 0.9.8d (SSLv3/RC4)**,
locked by the library — correct architecture is SSLv3 on the loopback game↔proxy leg + modern
TLS on the proxy↔internet upstream (which `tlsterm` does). `webapp/` is a FastAPI + Alembic app
over the corpus.

### 3.6 Legacy: UE5 / Python extraction pipeline (reference only)

The original fan recreation used Unreal Engine 5 driven by Python extraction tools. The Rust
reimpl (§3.2) is the active path. Still referenced for:

- `game-scripts/` — UE5 Editor Python (import/populate/setup). Kept for reference.
- `tools/*.py` + `scripts/*.sh` + top-level `Makefile` — the extraction/conversion pipeline
  (`make extract-all`, `review-all`, `extract-placements`, `ue5-bundle`, …). Full target list:
  `make help`.
- Per the Rust-tooling mandate, prefer `wad_simulator` crates for new work; several Python tools
  have Rust successors (converter, byteswap, loadprobe, havok extract).

Single-block probing: `tools/extract_single_block.py` (extract → decompress → optional decode →
clean up). Never bulk `sges_decompress` for a single lookup.

---

## 4. The `wad_simulator` workspace

Nested repo at `tools/wad_simulator/`. Use `git -C tools/wad_simulator`. Ground truth for the
crate list is the workspace `Cargo.toml` (not any `README`). Build: `cargo build --release`
(binaries → `target/release/`); single crate: `cargo build --release -p <crate>`.
Boots: `mercs2_game` (default = full-world; `--stream` = streaming dev boot; `--ecs` = ECS
render path).

**Engine pillars:** `mercs2_engine` (64-bit wgpu engine + app loop; owns/re-exports mechanism
crates), `mercs2_core` (sim spine: `hecs` World + fixed `Time` + `Schedule` + `GuidMap`),
`mercs2_game` (game exe), `mercs2_script` (Lua host), `mercs2_luac` (exact Lua 5.1.5 lib +
bytecode compiler).

**Gameplay/system crates** (re-exported by `mercs2_engine`): `mercs2_physics`, `mercs2_ai`,
`mercs2_combat`, `mercs2_vehicle`, `mercs2_water`, `mercs2_ui`, `mercs2_population`,
`mercs2_anim`, `mercs2_audio`, `mercs2_decal`, `mercs2_destruction`, `mercs2_faction`,
`mercs2_player`, `mercs2_net`, `mercs2_jobs`.

**Formats / asset layer:** `mercs2_formats` (WAD/sges/UCFX/mesh/texture/terrain + `stringdb`,
`mopp`, `patch_wad`, `save_write`), `mercs2_mesh`, `ucfx_byteswap`.

**RE / probe / diagnostics:** `mercs2_probe` (the only home for probe/mint/forge/verify bins),
`loadprobe`, `mercs2_reassemble`, `mercs2_bridge` (live TCP REPL into the running game via
Wally's lua-bridge ASI, `127.0.0.1:27050`), `mercs2_poc`.

**Asset pipeline / mod tooling:** `wad_simulator` (engine-accurate consumption simulator),
`mercs2_quartermaster` (`qm` CLI + Shipment mod format), `smuggler`, `wad_builder`, `densify`,
`anim_patch`, `dlc_port`, `havok_extract`, `destruction_extract`, `ps3_dlc_crypt`,
`securom_unwrap`, `mercs2_workshop`.

**`qm` mod pipeline:** `qm lint ./shipment` (hermetic, CI-safe, no game needed) / `qm build` /
`qm link`. Gated on exit code (0 clean / 1 findings / 2 could-not-run).

---

## 5. Testing & verification discipline

- **★ WAD-dependent tests SKIP SILENTLY.** Any test needing a real `vz.wad` prints
  `SKIPPING: no vz.wad discovered` and **returns — the test PASSES, exit 0.** Before trusting a
  WAD-dependent run: run `bash tools/wad_simulator/scripts/find-vz-wad.sh --write` (writes the
  gitignored `.mercs2-local.toml`) or set `MERCS2_GAME_DIR`/`VZ_WAD`, then grep the run for
  `SKIPPING` and confirm the positive marker printed (e.g. `retail scripts_vz: 114 entries`).
- **★ Gate on exit code, never a printed count** — the skip trap defeats even exit-code checks
  (exit is 0). Compare files by **hash**, not `ls`/`git`/mtime.
- **★ Verify artifacts by sha256** before AND after deploy.
- **Analyze game runs with `loadprobe`, never by eye** (skill: `analyze-game-log`). It scores
  `pmc_blackbox.log` against the phase ladder. `0x874E7D` is a hard-close/teardown, NOT a
  crash — classify by what the run was doing before it.
- **`pmc_bb` native Lua logging** routes every game `print`/`Printf` to `pmc_blackbox.log`
  (`[lua]` = each print, `[world]` = milestones) — the ground-truth world-load signal.
- **Ess live-test loop** (skill: `ess-live-test`) — for the `mercs2-lua-essentials` framework,
  iterate against the running game (`tools/xpad.py` virtual controller started **before** launch,
  `tools/launch.py`, `tools/lua_repl.py` — result comes back via `lua_loader_printf.log`, not
  the socket). Reading source only proves it compiles; this is the feedback loop. OnLoad changes
  need a level reload, not a `--code` resend.
- **`wad_simulator` clean ≠ correct** — structural check only; one gate among several
  (`wad_simulator` → sha256 → `loadprobe`).

---

## 6. Key technical facts (formats, hash, coordinates)

- **Name hash `pandemic_hash_m2`:** FNV-1a variant with a `|0x20` case-fold and `^0x2A · prime`
  finalization; identical in Mercs2 and The Saboteur. PC impl `Hash_String FUN_00824270`;
  `String.GetHash` funnels into it. Verify with `tools/pandemic_hash.py --m2`. Bone hashes are
  case-insensitive.
- **Container stack:** FFCS `.wad` (magic `FFCS`; chunks INDX/DATA/CSUM/ASET/PTHS) → `sges`
  blocks (raw deflate, `zlib` windowBits `-15`, multi-segment, 64 KB sentinel; identical to
  The Saboteur) → entry table → **UCFX** (`CHDR/COMP/GEOM/MESH/PRMG/STRM/IBUF/MTRL/SEGM/PHY2/…`).
  CSUM = CRC-32 (poly `0xEDB88320`). Master ref: `docs/format_reference.md`; ASET decode:
  `docs/aset_format.md`.
- **ASET `(block, sub)`:** both words hold block indices —
  `packed_block_ref` = [hi16 `_P000` | lo16 `_P001`], `secondary_ref` = [hi16 `_P002` | lo16
  `_P003`]. Single-block only when BOTH are sentinel (`AsetEntry::is_single_block()`), never
  `is_primary()` alone.
- **`CHDR` has two layouts:** placement/ECS: `{u16, u16 stride, u32}`; MESH (`0x5B724250`):
  `{u32 hash, u32 count}` → full u32 swap. Branch on `type_hash`. **`PHY2` is a Havok packfile**,
  not a u32 array (`[u32 hdr][Havok 5.5 packfile][trailing collision wrapper]`; section-aware
  swap, preserve `__classnames__`).
- **Coordinates:** source is **left-handed Y-up** (D3D9): X E–W, Y elevation, Z N–S. Range
  X≈±3900, Y≈−103..+393, Z≈±3900. glTF export writes game LH directly (no Z-negate/winding
  flip); only UV V is flipped (`v = 1−v`, D3D9 V=0-top → glTF V=0-bottom). Placements stay in
  game LH metres; `game_to_ue` maps `(x,y,z)`→UE `(100·x, 100·z, 100·y)`. Rotations are unit
  quaternions; `unreal.Rotator()` positional order is `(roll, pitch, yaw)` — always keyword
  args. **Do not add extra swizzles anywhere.** Units are meters (Parque Central towers = 220
  units ≈ 225 m).
- **Terrain collision is a MOPP-baked mesh**, not a heightfield — every terrain cell ships
  `WpMeshShape16` + baked `hkpMoppCode`. New-geometry terrain collision needs a MOPP bake
  (`mercs2_formats::mopp`).
- **Havok:** version **5.5**; anim = interleaved/delta/wavelet. Packfile decode in
  `mercs2_formats::havok` + `havok_extract`.

---

## 7. Where knowledge lives

- **The corpus** (§0) — search it first, always.
- **`docs/modernization/`** — reimpl: `00_charter.md`, `engine_support_inventory.md` (scoreboard),
  `reimplementation_parallelization_plan.md`, `world_streaming_spec.md`, per-subsystem specs.
- **`docs/reverse_engineer/`** — per-subsystem PC code maps,
  `mopp_bytecode_format.md`, `ghidra_knowledge_inventory.md`.
- **`docs/format_reference.md`** / `aset_format.md` — binary layouts (source of truth; add
  discoveries here).
- **`docs/fixpack/`** — `bug_register.md`, `wad_duplicate_inventory.md`.
- **`docs/modding/`** — `field_guide.md`, `character_kit.md`, `manifest_format.md`,
  `asset_injection_playbook.md` (top-level).
- **`MEMORY.md`** — persistent-memory router (per-domain). Full list in `MEMORY-CATALOGUE.md`.

When you discover a new binary structure, add it to the appropriate `docs/` file — those are the
source of truth. When you learn something durable and non-obvious that isn't in the code or git
history, write a memory and add its one-line pointer to `MEMORY.md`.
