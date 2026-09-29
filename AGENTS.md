# AGENTS.md — Mercenaries 2 Reverse-Engineering & Recreation Project

Persistent guidance for AI coding agents working on this repository. **Read this whole file once
before acting.** Several rules here are standing user mandates; violating them silently invalidates
real work.

---

## What this project actually is

This repo is the **research + toolchain hub** for reverse-engineering *Mercenaries 2: World in Flames*
(Pandemic Studios, 2008, "Pangea"/`Pg*`-lineage engine) and rebuilding it. It is **not** one program —
it is several, sharing one corpus of knowledge and one asset-format layer:

1. **Reverse engineering** — a 27k-function named Ghidra decompilation of the unpacked PC exe, a live
   x32dbg oracle bridge, and per-subsystem code maps. The shipped 32-bit exe is the **specification
   and oracle**, never the shipping artifact.
2. **The 64-bit Rust/wgpu engine reimplementation** — the north star. A ~40-crate Rust workspace
   (`tools/wad_simulator/`) that consumes the **original game's WAD/script/model assets** and
   reimplements the engine one gated system at a time.
3. **The unofficial fix-pack** — turning the rushed PC port into a revitalized release **on the retail
   engine**, shipped as layered `-patch.wad` overlays.
4. **Asset injection / modding / DLC port** — novel models, skins, and Xbox/PS3 DLC brought to the PC
   game **additively**, via a `vz-patch.wad` overlay.
5. **Online restore** — a FESL/Theater emulator (`coopserver/`) + TLS shim (`tlsterm/`) that revives
   the dead EA online services.

> **This is a recreation/RE project — every data claim must be verified from the original game binary
> or shipped bytes. No guessing.** Where the exe can't be read statically, the answer is *read it live
> in x32dbg*, not *assume*.

---

## 0. START HERE — the corpus-first reflex (MANDATE)

**`mcp__corpus__corpus_search` is the FIRST action on any non-trivial task — before grep, before
Read, before spawning readers, before re-deriving anything.** The corpus (`corpus` MCP server,
registered in `.mcp.json`) is a LanceDB index over **docs + memory + past conversations + mods + tools
+ commits + the 27k-function Ghidra decomp**. It answers three questions, in order:

1. **Have we already solved this?** (Don't redo months of work — it has happened.)
2. **What's related / where does it live?**
3. **Do the results match what I expected?** (A search that returns *nothing* is itself a finding.)

Tools: `corpus_search` (hybrid semantic+keyword; filter by `sources`/`path_prefix`), `corpus_xref`
(every chunk mentioning an address — `FUN_…`/`0x…` spelling-independent), `corpus_get` (full chunks of
one doc), `corpus_callgraph` (BFS callers/callees, annotated with where documented), `corpus_coverage`
(which of the 27k fns are documented — the naming queue), `corpus_stats`, `corpus_status`,
`corpus_ingest`.

- Every hit carries a `date`. Transcripts are `unreviewed` and rank **below** written-up docs. Docs
  declare `status:` (current/superseded/retracted) and `evidence:` (proven/inferred/speculative).
  **Prefer current + proven + recent over merely confident.**
- **Search at each decision, not once at task open.** The failure mode is not searching again once work
  is underway.
- If a freshly-written fact seems missing, run `corpus_status` — a stale index is why. Refresh:
  `cd tools/corpus_mcp && npm run ingest` (incremental; re-runs are seconds via hash-skip), or
  `corpus_ingest` from inside a session.

The persistent memory (`~/.claude/projects/…/memory/`, indexed as source `memory`) has its own router,
`MEMORY.md` — a per-domain map, not a catalogue. Full index in `MEMORY-CATALOGUE.md`.

---

## 1. Repository topology — the git repos & toolchain

Getting this wrong costs real work (a clean parent `git status` has twice been mistaken for a clean
nested tree). There are **two git repos in this tree**:

| Path | Repo | Notes |
|---|---|---|
| `.` (`notes-on-the-released-game`) | **Parent** — the notes/research + toolchain hub | Tracks `tools/corpus_mcp` and `game-scripts/` as ordinary files. |
| `tools/wad_simulator/` | **Nested repo** (own `.git`, **gitignored** from parent) | The Rust engine workspace. **Use `git -C tools/wad_simulator …`.** A clean parent `git status` says *nothing* about this tree. |

- `tools/corpus_mcp/` — the corpus MCP server (Node/ESM). **Part of the parent repo** (no own `.git`).
- **Usable RE toolchain, bundled in-repo (portable, no install):**
  - `tools/ghidra_12.1_PUBLIC/` — Ghidra 12.1 (headless + GUI).
  - `tools/jdk21/jdk-21.0.11+10/` — the JDK Ghidra runs on (needs 17+, 21 recommended). Wire it via the
    `JAVA_HOME` env var; keep `support/launch.properties` `JAVA_HOME_OVERRIDE=` **empty**.

**Sibling repos on the Desktop (not in this tree — do not look for them here):**
`Mercenaries 2 World in Flames` (the retail install; the fix-pack/modding target), `mercs2-modkit`
(the Tauri/Vue installer), `mercs2-lua-essentials` (Wally's in-game Lua stdlib "Ess").

---

## 2. Standing mandates (non-negotiable — from the user)

These are corrections the user has made, each after a real failure. They override defaults.

- **★ SecuROM is SOLVED — never a blocker.** See §3.1. Do not write "SecuROM-thunked → wall" or mark
  work blocked on DRM.
- **★ Corpus-first** (§0). `corpus_*` before grep/Read/re-derivation.
- **★ Novel assets must be ADDITIVE.** Overwriting a shipped asset invalidates the work. **Never merge
  into `vz.wad`** — the base archive stays pristine; injected content ships via the `vz-patch.wad`
  overlay, made resident by Lua preload, never by rewriting the base.
- **★ Never invent a hash.** Every hash = `pandemic_hash_m2(<real name>)` — the *name* is the identity
  (verify with `tools/pandemic_hash.py --m2`). Registry insert is **first-wins**, so a fabricated
  32-bit constant that collides silently drops *your* asset. A hash match alone is not evidence a name
  is real.
- **★ Cracked names go into the rainbow files** — the tracked home is
  `docs/data/aset_discovered_names.json`, matching indent, **not** a side `--emit` fragment.
  `tools/rainbow_table.json` is **gitignored**; `rainbow_table.json.bak` is a **tracked 75 MB** file
  (not scratch).
- **★ Use Rust tooling, not Python.** The pipeline is the Rust `wad_simulator` workspace; Python under
  `tools/` is legacy/reference. (DCC prep in Blender is the one orthogonal exception.)
- **★ Probe binaries live ONLY in `mercs2_probe`.** Every probe/mint/forge/verify binary is a
  `mercs2_probe` subcommand — never a `src/bin/` in `mercs2_game` (the exe) or `mercs2_formats` (the
  library).
- **★ No hiding features behind flags.** Wire real behaviour in unconditionally and data-driven; only
  diagnostics may be toggled.
- **★ x32dbg: NEVER resume the process** (§3.1). Read-only while PAUSED; the USER drives execution.
- **★ Verify artifacts by hash.** sha256 every deployed WAD/binary before AND after. Size/mtime lie.
- **★ Gate on exit code, never a printed count** — and beware the silent-skip trap (§5), which defeats
  even exit-code checks.
- **Minimal edits in others' code**; no comment rewording. **Ask, don't assume** on unverified
  setup/intent facts. **No give-up suggestions** — give technical next steps, never "shelve it."
  **Direct work style** — report findings and proceed, no meta-commentary.

---

## 3. The programs

### 3.1 Reverse engineering — the exe as oracle (and SecuROM is solved)

The shipped PC exe is symbol-less and SecuROM-packed; three assets make RE tractable:

- **Ghidra decompilation** — `output/_ghidra/securom_dump/mercs2_unpacked.exe` (an unpacked, rebuilt
  PE), fully decompiled to `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (~27k named fns) and indexed
  in the corpus as source `ghidra` (one row per function with caller/callee edges).
  - Headless run (PowerShell): set `JAVA_HOME` to `tools/jdk21/…`, then
    `tools/ghidra_12.1_PUBLIC/support/analyzeHeadless.bat <proj> <name> -import <exe> -scriptPath scripts/ghidra_scripts -postScript <Script>.java`.
  - Key post-scripts in `scripts/ghidra_scripts/`: `DecompileAllByName.java` / `DecompileAllFunctions.java`
    (both call `clearFalseNoReturn()` — the fix for the x87 sqrt/abs helpers whose bad `noreturn` flag
    truncated every float-heavy fn), `RecoverSecuromCode.java`, `CoverageReport.java`,
    `FnMnemonicSig.java` (v1.0↔v1.1 build matching).
  - **`mercs2_reassemble`** (`cargo run -p mercs2_reassemble --release`) left-joins **every** attribution
    source (code maps, RTTI vtables, FID signatures, the Lua binding surface,
    `scripts/mercs2_annotations.json`) onto the decomp **by virtual address** (`FUN_00478120` == `0x478120`),
    then propagates residue by locality + call-graph. Output `output/engine_reassembled/`. Evidence is
    **graded** — never conflate a propagated `inferred` guess with a decompiled fact.

- **x32dbg live bridge** — the `mcp__x32dbg__*` tools inspect the *running, already-unpacked* process,
  where SecuROM code and strings the on-disk decomp can't see ARE present.
  - **★ NEVER resume the process.** Do not call `DebugRun`/step/any execution control — it wedges the
    bridge and kills the session. Treat x32dbg as a **read-only inspector of the current paused state**
    (`MemoryRead`, `StringGetAt`, `DisasmGetInstructionRange`, `GetRegisterDump`, `GetCallStack`,
    `PatternFindMem`). You MAY set breakpoints for the **user** to hit; the **user** drives execution.
  - **★ Session-killers:** never put a **conditional** breakpoint on a **hot per-frame** function (it
    traps int3 + evaluates every call → x32dbg goes down and takes the game with it). Break on rare
    (once-per-spawn) fns, use single-shot BPs, HW-write watchpoints, and only offsets **proven** from
    decomp. During a livelock hang: read-only snapshots only, no BPs, GUI-pause only.

- **★ SecuROM is fully solved — it is NEVER a legitimate reason to mark work blocked.** (User mandate,
  stated twice.)
  - **Decrypted:** run to the main menu (past OEP → all sections decrypted in memory), dump, rebuild as
    a clean PE. Coverage of the unpacked image ~**87%** overall, **~99% of actual code**.
  - **Decompiled:** the SecuROM VM partition is in the corpus (`ghidra/FUN_02xxxxxx`, ~5.8k fns); the VM
    dispatcher is `FUN_02a30028`. `RecoverSecuromCode.java` force-disassembles it.
  - **Removable:** working DRM-free builds already exist (`mercs2_nodrm_v2.exe` / `v3.exe` boot with no
    disc/activation/loader). The crate **`securom_unwrap`** turns a *decrypted* exe into a SecuROM-free
    one (repoints OEP, rebuilds a clean IAT, preserves every section byte-for-byte).
  - **Why it's not a wall — split-thunks:** a `thunk_FUN_024xxxxx` is one of three cases: (1) a
    forwarder that jumps 1–3 hops back to a real `.text` body — **follow it** (`corpus_xref` the thunk;
    53/56 auto-resolve back in-region); (2) VM-virtualized residue — **read it live** in x32dbg; (3)
    not SecuROM at all — a plain Ghidra coverage gap → force-decompile. "binding-only" in a code map
    almost always means Ghidra never walked there (no static caller), **not** that the body is
    encrypted — disassemble it directly (`memory/binding-only-is-not-a-wall-disassemble.md`).
  - **DRM never touches data files** — modding assets requires zero DRM bypass. `make crack-game
    RETAIL_EXE=… OUTPUT=./output` + `tools/apply_securom_patch.py` apply the retail bypass; full
    un-splicing of all splice sites is *parked* (zero functional gain — working DRM-free builds exist).

- **Recently-proven RE milestones (don't re-derive):**
  - **★ MOPP bytecode DECODED + native compiler proven in-game** (`docs/reverse_engineer/mopp_bytecode_format.md`).
    The Havok 5.5 `hkpMoppCode` BV-tree instruction set is fully decoded; decoder+encoder landed in
    `mercs2_formats::mopp` (validated against 43 real vz.wad buffers; from-scratch native bytecode
    accepted by the retail Havok VM live). A portable, no-DLL MOPP compiler regenerates game-valid
    collision.
  - **★ Havok anim toolchain roundtrip proven in retail** — the period-correct HCT 5.5 `AssetCc2.exe`
    round-trips Mercs2 wavelet clips (97/97 Mattias clips rebuilt, animate normally in-game;
    `--strip --rules4101`; a clip = Havok packfile + a separate `trnm` binding that must be preserved).
    The oracle for the native Rust encoder.
  - **Wavelet anim decode solved** (`tools/hk_anim/wavelet.py`, Rust successor `havok_extract`) —
    numerically validated against a live capture.
  - **Name registry / spawn-by-hash** — events, templates, tunables, spawn all keyed by
    `pandemic_hash_m2` (`Hash_String FUN_00824270`). The 733k-entry rainbow table is its inverse.

- **Tracing ASI mods** (`mods/`): `engine_trace_asi` (INT3 audio call-chain capture), `lua_trace_asi`,
  `surface_a_probe` (asset→struct dumps for the reimpl's Surface-A gate), `crowd_fog_couple`. These are
  the behavioral oracles the reimpl gates against.

### 3.2 The 64-bit Rust/wgpu engine reimplementation (the north star)

**Charter:** `docs/modernization/00_charter.md`. **Do not re-survey — read the charter + the
scoreboard.**

Rebuild Mercs2 as a **native 64-bit, maintainable, faithful, faster** open engine consuming the
**original assets**, reimplementing systems one at a time. Locked decisions: **Rust** on the existing
`wad_simulator` workspace (D2); renderer = **`wgpu`** (D3); **no DXVK bridge** — exe kept purely as
oracle (D4); original exe + Ghidra decomp + x32dbg = **oracle/spec** (D6).

**Governing principle:** *Implementation is free; behavior is gated.* Anything is allowed as long as it
passes an oracle gate — the constraint is provable behavioral **equivalence**, not implementation
fidelity.

**On Lua (state it accurately):** the script host (`mercs2_script`) targets **Lua 5.4 via `mlua`** with
a 5.1 compatibility prelude for behavioral parity (native i64 → money/economy is `i64` for free). A
parallel **exact Lua 5.1.5** library (`mercs2_luac`, float `lua_Number`, 32-bit `size_t`) also exists
for byte-exact bytecode/VM work — it emits LuaQ chunks the retail game accepts. When precision matters,
say which one you mean.

**Regression harness = two oracle surfaces:** *Surface A* (asset→struct, byte-identical vs x32dbg
dumps), *Surface B* (script→engine-binding **call-trace** equivalence — this is what makes upgrading
Lua safe: assert the same ordered C-binding calls, not *how* the VM computes). Plus render-golden
hashes, `loadprobe`-scored milestone gates, and record/replay determinism.

**Structure — the "game-on-engine" refactor (LANDED):** the dependency graph is inverted.
`mercs2_engine` **owns and `pub use`-re-exports all mechanism crates + `mercs2_script`**; `mercs2_game`
depends on only `mercs2_engine` + `mercs2_core` + `mercs2_formats` and reaches mechanisms via
`mercs2_engine::<name>::…` (alias traps: `mercs2_water`→`::water_sim`, `mercs2_ui`→`::widgets`). One app
loop lives in `mercs2_engine::app` (a `Game` trait + `run<G: Game>`). **Lua is a core engine pillar**
(the binding surface *is* the engine's scripting API), so the script host moved into `mercs2_engine`;
the game drives it. **ECS World is the single source of truth** — the host shares the live
`Rc<RefCell<hecs::World>>` via `attach_world`; name/position/health/economy are migrated off shadow
tables onto real components (`mercs2_core::GuidMap`).

**Status — the 32-row scoreboard is `docs/modernization/engine_support_inventory.md` (authoritative;
update it, don't re-survey).** One-line read: a faithful streaming-world **renderer + spine** (rows
1–18 green/yellow) **plus a now-built gameplay fleet** — physics, animation, vehicles, weapons, audio
migrated to tested crates and **wired into the fixed tick** (`mercs2_game::gameplay::GameplaySystems`;
a car drives end-to-end). **~26 of 32 subsystems have real implementations.** The dominant remaining
effort is **not** new subsystems but the **connection layer** — feeding the wired systems real game
entities via the spawn/population/mission-Lua path (K1 persistent mission-Lua host, K2 single world
path on the playable boot, K3 actor-realization archetype). ECS coverage is the visible gap: **4 native
components vs 231 registry classes** (the `schm` field-schema deser exists; wiring the rest is the
unblock). Work is carved into **16 silos** (`docs/modernization/reimplementation_parallelization_plan.md`)
so N owners don't collide.

### 3.3 The unofficial fix-pack (retail engine)

Turn the rushed PC port into a revitalized release **on the shipped engine**. **The USER supplies every
bug — never invent one.** Backlog: `docs/fixpack/bug_register.md` (status vocab
`reported→confirmed→fix-designed→built→verified`). Memory: `mercs2-fixpack-project`.

Four independently-installable tiers: **T1 text (stringdb)** · **T2 Lua/data** · **T3 exe patch** ·
**T4 restored/cut content**. Delivery routes (settled):
- **T1 text → a single `English-patch.wad`** — mounts **last** and overrides both stringdb copies
  (proven in-game).
- **T2 Lua → MERGE into the live `vz-patch.wad`** via `mercs2_formats::patch_wad::merge_patch_wads` —
  never overwrite it.

**WAD mount order = LAST-mounted-WINS** — but note **three simultaneous, opposite rules**: the WAD stack
is last-wins, the chunk registry (once resident) is **first-wins**, and string DBs (`AddStringDb`) are
last-registered-wins **capped at 8** (the 9th silently gets nothing). `shell.wad` and `vz.wad` share
the single `<level>.wad` slot and ship a byte-identical 18,299-key English stringdb — patch only one and
you fix only half the game (hence the `English-patch.wad` one-file route).

**stringdb is LITTLE-endian**, bodies UTF-16LE, tags `KEYS`/`STRS` (the reversed `SYEK`/`SRTS` are Xbox
BE misread), `STRS` header = u16 code-unit count. Tooling (all Rust): `mercs2_formats::stringdb`,
`mercs2_probe --bin stringdb_dump` / `stringdb_roundtrip`, `wad_builder --bin stringdb_patch`,
`mercs2_probe --bin wad_dupes` (+ `docs/fixpack/wad_duplicate_inventory.md`). **Trap:** a string in the
table is *not* proof it's displayed — confirm a key is live first (`Enter vehicle` exists but the live
prompt composes `Drive %s`).

**Modkit has three setup paths** (`memory/modkit-two-setup-paths-licensed-dxwrapper`) so a legally-owned
copy is never force-cracked: `drm_free` (a `mercs2_nodrm_v*.exe` importing `pmc_bb.dll` directly),
`licensed` (dxwrapper loads plugins; pmc_bb stands down), `crack`. One `pmc_bb.dll` on all paths,
deconflicted at runtime via `DxWrapperOwnsPlugins`. The logging build is `pmc_bb_log.dll`.

### 3.4 Asset injection / modding / DLC port (additive, via `vz-patch.wad`)

**Authoritative process:** `docs/asset_injection_playbook.md`. **Field guide of 17 corpus-cited traps:**
`docs/modding/field_guide.md` — read it; this engine "almost never tells you what you did wrong" (a
typo is a valid hash that resolves to nothing, silently).

Four-stage pipeline: **A0** DCC preprocess (Blender headless, `tools/fbx_preprocess.py`; tri budget
< ~10.9k, verts < 65535, single mesh/material) → **A** import & verify (`tools/gltf_to_ucfx_model.py`,
maps into donor vertex space; preserves `INFO/HIER/MTRL/SEGM/PHY2/STAM` byte-for-byte) → **B** textures
**fully-resident** (`mercs2_formats::texture::build_resident_texture`; slot order **0=diffuse /
1=SPECULAR / 2=NORMAL**, normal is DXT5nm) → **C** inject via **`smuggler`** (override-by-hash is proven;
a *new* asset needs its own ASET row or it wedges world-load) → **D** placement per class (static =
`Pg.Spawn(hash,x,y,z)`; wardrobe = `_tOutfits`; store = `tSupportData`).

Injection tooling in `tools/wad_simulator/crates/`: **`smuggler`** (by-hash overlay builder),
**`wad_builder`** (raw→engine `vz-patch.wad`, byte-exact identity oracle), **`densify`** (additive veg
scatter), **`anim_patch`**, **`mercs2_workshop`** (native-renderer asset browser), **`mercs2_poc`**
(`inject_character`). **★ Gate EVERY build with `aset_refcheck`** — a builder that remaps only `_P000`
while `_P001/2/3` dangle → 549 GB buffer request → livelock.

**★ `mercs2_workshop --render <name|0xHASH>` IS the iteration loop** — headless, textured + skinned +
posed straight from packed bytes; use it instead of in-game screenshots. `--no-auto-patch` is mandatory
while iterating (else it renders the deployed build); render `pmc_hum_mattias` beside the import as
baseline.

Character/skin/DLC facts worth knowing before you start (all corpus-backed):
- **★ Pandemic shares ONE human skeleton** — Mercs2 == Saboteur, identical bone name-hashes and bind
  pose (mm-level, 127 models). Cross-game port = a **name-hash JOIN, not a weight transfer**. Pick a
  donor on bone count/textures, **never proportions**.
- Skinned custom-character import is **solved** (`retarget:` on `add_outfit`; dense foreign rigs >48
  bones need `single_group: true`; skins bind only when shipped fully-resident). BLENDINDICES are
  per-group palette-relative.
- **Store item injection solved** — the blocker was faction keying (Eva's PMC shop queries faction
  `"Pmc"`), not the load mechanism.
- **`Pg.Spawn` of a novel template needs TWO live injections** — name→handle into registry `@0xDF6B88`
  is **proven** (mercs2-sdk ASI); the entity **template body** into the live worldentity pools is the
  remaining gap.
- **A functional boat/vehicle** = a vehicle-template subgraph (decoded from retail `al_veh_boat_lcur`:
  `_BoatPhysics`+`SeatLink`+`EntranceLink`+`PhysicalLink`+`ModelName`+`Health`), not a static collision
  shape.
- **DLC01 is a LEVEL, not an injection** — a peer master script booted via `LevelBootstrap.LoadLevel`;
  the DLC WAD is a full level replacement. Treat DLC as a **mode** (mount + boot `dlc01`; unmount to
  play base). Re-port with `dlc_port`. **PS3 DLC is cracked** (PKG→EDAT→SELF, `ps3_dlc_crypt`); PS3
  content == Xbox.

### 3.5 Online restore (dead EA services)

`coopserver/` — a FESL / Theater / DNS emulator (Python) that revives matchmaking; `tlsterm/` — a TLS
termination shim. The game's FESL client is a statically-linked **OpenSSL 0.9.8d (SSLv3/RC4)**, locked
by the library — the correct architecture is SSLv3 on the loopback game↔proxy leg + modern TLS on the
proxy↔internet upstream (which `tlsterm` does). `webapp/` is a FastAPI + Alembic app over the corpus.

### 3.6 Legacy: the UE5 / Python extraction pipeline (reference only)

The original effort was a fan recreation in **Unreal Engine 5** driven by Python extraction tools. The
`UnrealEngineGame/` project no longer exists in this tree, and the Rust reimpl (§3.2) has superseded it,
but much of the extraction pipeline is still used and referenced:

- `game-scripts/` — UE5 Editor Python (import/populate/setup). Kept for reference; not the active path.
- `tools/*.py` + `scripts/*.sh` + the top-level `Makefile` — the extraction/conversion pipeline
  (`make extract-all`, `review-all`, `extract-placements`, `ue5-bundle`, …). Still the route for
  bulk asset extraction and the three.js `viewer/`. Full target list: `make help`.
- Per the Rust-tooling mandate, prefer the `wad_simulator` crates for new work; the Python tools are
  legacy/reference and several have Rust successors (converter, byteswap, loadprobe, havok extract).

Single-block probing: **`tools/extract_single_block.py`** (extract → decompress → optional decode →
clean up) — one block at a time, never bulk `sges_decompress` for a single lookup.

---

## 4. The `wad_simulator` workspace (crate map + build)

Nested repo at `tools/wad_simulator/` — **`git -C tools/wad_simulator`**. ~40 member crates
(`Cargo.toml` is ground truth — the workspace README's 5-crate list is stale). Build:
`cargo build --release` (binaries → `target/release/`); single crate: `cargo build --release -p <crate>`.
Boots: `mercs2_game` (default = full-world; `--stream` = streaming dev boot; `--ecs` = ECS render path).

**Engine pillars** — `mercs2_engine` (the 64-bit wgpu engine + app loop; owns/re-exports the rest),
`mercs2_core` (the sim spine: `hecs` World + fixed `Time` + `Schedule` + `GuidMap`), `mercs2_game` (the
game exe; boots from the player's save), `mercs2_script` (the Lua host — the game's own Lua runs on it),
`mercs2_luac` (the exact Lua 5.1.5 lib + bytecode compiler).

**Gameplay/system crates** (mechanism; re-exported by `mercs2_engine`) — `mercs2_physics`, `mercs2_ai`,
`mercs2_combat`, `mercs2_vehicle`, `mercs2_water`, `mercs2_ui`, `mercs2_population`, `mercs2_anim`,
`mercs2_audio`, `mercs2_decal`, `mercs2_destruction`, `mercs2_faction`, `mercs2_player`, `mercs2_net`,
`mercs2_jobs`.

**Formats / asset layer** — `mercs2_formats` (WAD/sges/UCFX/mesh/texture/terrain + `stringdb`, `mopp`,
`patch_wad`, `save_write`; used by everything), `mercs2_mesh`, `ucfx_byteswap`.

**RE / probe / diagnostics** — **`mercs2_probe`** (the ONLY home for probe/mint/forge/verify bins),
`loadprobe`, `mercs2_reassemble`, `mercs2_bridge` (live TCP REPL into a running game via Wally's
lua-bridge ASI), `mercs2_poc`.

**Asset pipeline / mod tooling** — `wad_simulator` (engine-accurate consumption simulator),
`mercs2_quartermaster` (the `qm` CLI + Shipment mod format), `smuggler`, `wad_builder`, `densify`,
`anim_patch`, `dlc_port` (WIP; Python still authoritative), `havok_extract`, `destruction_extract`,
`ps3_dlc_crypt`, `securom_unwrap`, `mercs2_workshop`.

**The `qm` mod pipeline:** `qm lint ./shipment` (hermetic, CI-safe, no game needed) / `qm build` /
`qm link`. Gated on exit code (0 clean / 1 findings / 2 could-not-run).

---

## 5. Testing & verification discipline (read before quoting any "pass")

- **★ WAD-dependent tests SKIP SILENTLY.** Any test needing a real `vz.wad` prints
  `SKIPPING: no vz.wad discovered` and **returns — the test PASSES, exit 0.** Retail-parity gates have
  passed *vacuously* this way for whole phases. **Before trusting a WAD-dependent run:** run
  `bash tools/wad_simulator/scripts/find-vz-wad.sh --write` (writes the gitignored `.mercs2-local.toml`)
  or set `MERCS2_GAME_DIR`/`VZ_WAD`, then **grep the run for `SKIPPING` and confirm the positive marker
  printed** (e.g. `retail scripts_vz: 114 entries`). A rising total-test count after a "fix" means
  earlier runs weren't measuring what they appeared to.
- **★ Gate on exit code, never a printed count** — and remember the skip trap defeats even exit-code
  checks (exit is 0). Compare files by **hash**, not `ls`/`git`/mtime.
- **★ Verify artifacts by sha256** before AND after deploy.
- **Analyze game runs with `loadprobe`, never by eye** (skill: `analyze-game-log`). It scores
  `pmc_blackbox.log` against a 21-phase ladder and knows **`0x874E7D` is a hard-close/teardown, NOT a
  crash** — classify by what the run was doing before it.
- **`pmc_bb` native Lua logging** routes every game `print`/`Printf` to `pmc_blackbox.log`
  (`[lua]` = each print, `[world]` = milestones) — the ground-truth world-load signal.
- **Ess live-test loop** (skill: `ess-live-test`) — for the `mercs2-lua-essentials` framework, iterate
  against the **running game** (`tools/xpad.py` virtual controller started **before** launch,
  `tools/launch.py`, `tools/lua_repl.py` — result comes back via `lua_loader_printf.log`, not the
  socket). Reading source only proves it compiles; there is no screenshot capability, so this **is** the
  feedback loop. OnLoad changes need a level reload, not a `--code` resend.
- **`wad_simulator` clean ≠ correct** — it's a structural check, one gate among several
  (`wad_simulator` → sha256 → `loadprobe`).

---

## 6. Key technical facts (formats, hash, coordinates)

- **Name hash — `pandemic_hash_m2`:** FNV-1a variant with a `|0x20` case-fold and `^0x2A · prime`
  finalization; identical in Mercs2 and The Saboteur. PC impl `Hash_String FUN_00824270`;
  `String.GetHash` funnels into it. Verify with `tools/pandemic_hash.py --m2`. Bone hashes are
  case-insensitive. (See §2 mandates.)
- **Container stack:** FFCS `.wad` (magic `FFCS`; chunks INDX/DATA/CSUM/ASET/PTHS) → `sges` blocks
  (raw deflate, `zlib` windowBits `-15`, multi-segment, 64 KB sentinel; identical to The Saboteur) →
  entry table → **UCFX** (`CHDR/COMP/GEOM/MESH/PRMG/STRM/IBUF/MTRL/SEGM/PHY2/…`). CSUM = CRC-32
  (poly `0xEDB88320`). Master ref: `docs/format_reference.md`; ASET decode: `docs/aset_format.md`.
  - **ASET `(block, sub)` is settled by measurement:** both words hold block indices —
    `packed_block_ref` = [hi16 `_P000` | lo16 `_P001`], `secondary_ref` = [hi16 `_P002` | lo16 `_P003`].
    Single-block only when BOTH are sentinel (`AsetEntry::is_single_block()`), never `is_primary()` alone.
  - **`CHDR` has two layouts** — placement/ECS: `{u16, u16 stride, u32}`; MESH (`0x5B724250`):
    `{u32 hash, u32 count}` → full u32 swap. Branch on `type_hash`. **`PHY2` is a Havok packfile**, not
    a u32 array (`[u32 hdr][Havok 5.5 packfile][trailing collision wrapper]`; section-aware swap,
    preserve `__classnames__`).
- **Coordinates:** source is **left-handed Y-up** (D3D9): X E–W, Y elevation, Z N–S. Range X≈±3900,
  Y≈−103..+393, Z≈±3900. glTF export writes game LH directly (no Z-negate/winding flip); only the UV V
  is flipped (`v = 1−v`, D3D9 V=0-top → glTF V=0-bottom). Placements stay in game LH metres; `game_to_ue`
  maps `(x,y,z)`→UE `(100·x, 100·z, 100·y)`. Rotations are unit quaternions; `unreal.Rotator()` positional
  order is `(roll, pitch, yaw)` — **always keyword args**. **Do not add extra swizzles anywhere.** Units
  are **meters** (Parque Central towers = 220 units ≈ 225 m).
- **Terrain collision is a MOPP-baked mesh**, not a heightfield — every terrain cell ships
  `WpMeshShape16` + baked `hkpMoppCode` (362/362 cells, 0 heightfields). New-geometry terrain collision
  needs a MOPP bake (now native — `mercs2_formats::mopp`).
- **World data:** 62,458 static placements in `layers_static` (173 UCFX sub-blocks); ~3,500 conditional
  in `vz_state` overlays (pristine visible / ruined + staging + act-specific hidden); vz.wad = 11,370
  blocks.
- **Havok:** version **5.5**; anim = interleaved/delta/wavelet (wavelet decode solved); packfile decode
  in `mercs2_formats::havok` + `havok_extract`.

---

## 7. Where knowledge lives

- **The corpus** (§0) — search it first, always.
- **`docs/modernization/`** — the reimpl: `00_charter.md`, `engine_support_inventory.md` (the
  scoreboard), `reimplementation_parallelization_plan.md`, `world_streaming_spec.md`, per-subsystem specs.
- **`docs/reverse_engineer/`** — per-subsystem PC code maps (each tagged to a scoreboard row),
  `mopp_bytecode_format.md`, `ghidra_knowledge_inventory.md`.
- **`docs/format_reference.md`** / `aset_format.md` — binary layouts (the source of truth; add
  discoveries here).
- **`docs/fixpack/`** — `bug_register.md`, `wad_duplicate_inventory.md`.
- **`docs/modding/`** — `field_guide.md`, `character_kit.md`, `manifest_format.md`,
  `asset_injection_playbook.md` (top-level).
- **`MEMORY.md`** — the persistent-memory router (per-domain). Full list in `MEMORY-CATALOGUE.md`.

When you discover a new binary structure, add it to the appropriate `docs/` file — those are the source
of truth. When you learn something durable and non-obvious that isn't in the code or git history, write
a memory (and add its one-line pointer to `MEMORY.md`).
