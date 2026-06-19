---
name: analyze-game-log
description: >-
  Analyze the Mercenaries 2 game log (pmc_blackbox.log) with the `loadprobe` tool to
  quantify how far the world-load got and classify the end-state. USE THIS whenever the
  user shares, pastes, or points at pmc_blackbox.log, or asks things like "how far did the
  load get", "did it crash / hang / load", "where did it stop", "analyze the log", "what
  happened on the last run", or after the user re-runs the game. Do NOT eyeball the raw log —
  run loadprobe; it is more accurate (e.g. it knows 0x874E7D is a hard-close, not a crash).
---

# Analyze the game log with `loadprobe`

`loadprobe` is a Rust CLI in this repo that parses `pmc_blackbox.log` (written next to the game
exe by `pmc_bb.dll`) and produces a forensic dump: a `LOADED X%` banner, an end-state VERDICT,
a 0–20 phase timeline, pool/texture-component health, acts/jobs progression, flagged diagnostics,
and an undetected-content guard.

## How to run it

1. **Build once if the binary is missing** (`tools/wad_simulator/target/release/loadprobe.exe`):
   ```bash
   cd tools/wad_simulator && cargo build --release -p loadprobe
   ```
2. **Run it.** Always pass `--no-color` when capturing output for analysis:
   ```bash
   tools/wad_simulator/target/release/loadprobe.exe --no-color [LOGPATH]
   ```
   - With no `LOGPATH` it defaults to the live game log:
     `C:/Users/Shadow/Desktop/Mercenaries 2 World in Flames/pmc_blackbox.log`.
   - Example captures for reference live in `storage/pmc_blackbox-*.log`.
   - Add `--json` when you want to parse fields programmatically; `--milestones` prints the phase
     ladder; `--routine`, `--hang-secs`, `--top-gaps`, `--signals` tune the analysis.

## How to read the result

- **`BUILD / RUN IDENTITY`** binds the run to the exact bytes (no size/mtime guessing).
  `pmc_bb.dll` writes `[blackbox] BUILD <kind>=<name> sha256=<hex> size=<n>` lines at boot
  (qsha256 = head+tail+size for files >1GiB, i.e. base `vz.wad`); loadprobe surfaces them plus the
  log file's own sha256. **Always report the deployed `vz-patch.wad` sha when stating a result.**
  If you see `⚠ no [blackbox] BUILD lines — NOT self-attributing`, the run used an old pmc_bb
  without the fingerprint emitter — hash the deployed WAD by hand before attributing the log, and
  never infer the build from file size/mtime.
- **`LOADED X%` + VERDICT** is the headline. Verdicts:
  - `REACHED-WORLD` (exit 0) — load completed (`GlobalExit - Complete`). A crash noted as
    POST-LOAD is gameplay/exit, not a load blocker.
  - `CRASH @0xEIP` (exit 10) — a *real* terminal crash that blocked the load (non-teardown EIP,
    before GlobalExit). The report names the suspected subsystem.
  - `HANG` (exit 11) — the load wedged (steady `[pool] free=N`, no progress). This is the common
    real blocker; note the `free=` value and last phase.
  - `TRUNCATED` (exit 12) — log ends mid-load with no crash/hang signature (or a hard-close).
- **Phase timeline (0–20)** shows the furthest milestone + timestamps/deltas; phases not reached
  are dimmed. Acts (`***Staging Act`), player spawn, faction jobs, and portals appear in
  PROGRESSION.
- **TEXTURE-COMPONENT POOL HEALTH** — `DISTINCT texture hashes: N / 5120 cap` is the key gauge
  (the metric that tracked the MTRL/ASET fixes); plus the caller histogram and GARBAGE keys.
- **COVERAGE / UNDETECTED** — surfaces unknown source tags, unparsed lines, and **unrecognized
  crash EIPs** ("candidate NEW crash site"). If you see this, the tool found something it hasn't
  been taught — add it to `tools/wad_simulator/crates/loadprobe/src/phases.rs` (the milestone
  ladder / `KNOWN_EIPS` are the single source of truth).
- **LAST ACTIVITY** — always shows what the log was doing at the end (the lead for any wedge).

## Critical gotcha

**`EIP=0x00874E7D` is a HARD-CLOSE / teardown artifact, not a bug** — it's the texture-streaming
worker faulting when the game is force-closed (AV target=`F011157A`, EDI mid-read on the
`english.wad` path). `loadprobe` already treats it as a hard-close, so a log ending there is
classified by what it was doing *before* (booted fine, or a HANG the user killed). Never report
0x874E7D as a load-blocking crash.

## Extending
New milestone strings, crash EIPs (set `teardown: true` for force-close signatures), and faction
job prefixes all live in `tools/wad_simulator/crates/loadprobe/src/phases.rs`. Re-run
`cargo build --release -p loadprobe` and the fixture tests (`cargo test -p loadprobe`) after edits.
