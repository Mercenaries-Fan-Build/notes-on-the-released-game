# DLC PC Activation Checklist

Validation workflow for the DLC Enable pipeline. Run on the **game PC**
(or against `output/data/vz-patch.wad` before deploy).

**Current strategy:** "Nohook" — don't modify existing retail scripts, only append
`dlc01` as entry 115. ASI uses multi-strategy `luaL_loadbuffer` + `lua_pcall` with
60s VZ-load delay and 5s post-flow-init unlock delay.

**Row 13 bar (Phase 1):** boot to menu is **not** sufficient — require `import("dlc01")`,
`AddStringDb`, and **4 Fiona contracts** (see [`dlc_research_index.md`](dlc_research_index.md)).

## Phase 0 — Mac gates (before Windows bisect)

```bash
make dlc-phase0 OUTPUT=./output SOURCE_WAD=game-files/vz.wad
make verify-dlc-import-chain OUTPUT=./output SOURCE_WAD=game-files/vz.wad
make inventory-dlc-patch OUTPUT=./output
```

| Gate | Pass |
|------|------|
| `verify_dlc_import_chain` | `RESULT: ALL CHECKS PASSED` |
| Resident block 464 LuaQ | 0 BE, >0 LE |
| `dlc01` ASET | `type_id=35` on **scripts_vz** block (2196) |
| Script ASET dupes | No `wifmissionflow` / `wifpmcinterior` on **resident** block 464 — run `make fix-patch-script-aset` |
| `_fix_stringdb_descriptors` | **Off** unless `dlc_stringdb_forensic` proves need |

**Crash at `[lua] Shell exited` with no further lines:** the crash is in **native code**
between shell Lua teardown and `MrxSoundBootstrap.Init` — **before** VZ-load ASI
bootstrap runs. Look for flushed `Checkpoint: Shell exited` and `Watchdog: +N ms` lines
in `scripts/dlc_enable_crash.log`.

### What still runs with `mingw-nobootstrap` (bootstrap=OFF)?

| Component | Active? | Notes |
|-----------|---------|-------|
| `REG_PATCH` (Debug.Printf + print) | **Yes** | Replaces stub with `Hook_LogPrintf`; logs every string print |
| `NET` hooks | **Yes** | Inline hooks on `IsOnlineConnected`, `HasPlayerUnlockedCode`, `IsMatchmakingInternet` |
| `ARENA` transition | Compiled | Inactive until `bootstrap_ok=1` |
| Bootstrap inject | **No** | No `import("dlc01")` |
| `CRASH_PATCH` @ 0x005AE372 | **No** (unless default `mingw`) | User tested CRASH_PATCH=0 — still crashes |
| Global crash guard | **Yes** | Logs `FATAL: exception …` to crash log |
| Shell watchdog | **Yes** | Logs `Watchdog: +N ms` every 50 ms after Shell exited |

**MINIMAL** (`make dlc-asi-native-minimal`): NET hooks only — no print patch.
**NO_HOOKS** (`make dlc-asi-native-nohooks`): DllMain log + global crash guard only.

### Engine transition after Shell exited

Successful vanilla log sequence (from working runs):

```text
[lua] Shell exited
[lua] MrxSoundBootstrap.Init
[lua] ##@ GameBootstrap - bailing because finished shell
… later …
[lua] Loading vz level with vz masterscript
```

- **`vz-patch.wad` mounts at game startup** when `vz.wad` opens (not at Shell exited).
  ASET rows are indexed then; block **decompression** is on-demand via `RequestAsset()`.
- **Block 2196 (`scripts_vz`)** adds ASET overrides for `wifmissionflow`, `vz`, `dlc01`, etc.
  Even without `import("dlc01")`, those ASET rows shadow base retail lookups.
- **Prior bisect:** 2196 DLC asset blocks **without** scripts_vz bootstrap (`dlc-port-assets-only`)
  reached full freeplay stably; hang/crash tied to **scripts_vz ASET shadowing** or **string mods**
  (see [`analysis/cross_platform/pc_bisect_results.md`](../analysis/cross_platform/pc_bisect_results.md)).

Common causes (2026-05-23 investigation):

| Cause | Mac gate? | Fix / test |
|-------|-----------|------------|
| Duplicate script ASET on resident block 464 | `fix_patch_script_aset_dupes --dry-run` | `make fix-dlc01-aset OUTPUT=./output` |
| BE LuaQ / bad DEPS in patch | `verify_dlc_import_chain` LuaQ scan | Rebuild with current `ucfx_be_to_le.py` |
| ASI hooks (REG_PATCH / NET) | N/A | `make dlc-asi-native-minimal` or remove ASI |
| scripts_vz bootstrap block 2197 | N/A | `make dlc-port-assets-only` → deploy as `vz-patch.wad` |
| ASI `CRASH_PATCH` code cave at `0x005AE372` | N/A | `make dlc-asi-native-no-crash-patch` |
| Patch WAD not exercised yet (log flush) | N/A | Look for `Checkpoint: Shell exited` then `MrxSoundBootstrap` |

---

## Windows bisect matrix (run in order)

Each test: launch game → load save → wait through shell movies → note last log line.
Log file: `<game>/scripts/dlc_enable_crash.log` (or PMC Blackbox console).

### Build ASI variants (on Mac/Linux host)

```bash
make dlc-asi-native-nobootstrap OUTPUT=./output   # REG_PATCH+NET (current failing config)
make dlc-asi-native-minimal OUTPUT=./output       # NET only
make dlc-asi-native-nohooks OUTPUT=./output       # zero hooks
make dlc-asi-native OUTPUT=./output               # full VZ bootstrap + CRASH_PATCH
make dlc-port-assets-only DLC_RAR=... SOURCE_WAD=game-files/vz.wad OUTPUT=./output
```

### Matrix

| # | ASI | Patch WAD | Expected if this layer is the cause |
|---|-----|-----------|--------------------------------------|
| **A** | **None** (delete `scripts/dlc_enable.asi`) | **None** (`ren vz-patch.wad vz-patch.wad.off`) | **Must pass** — vanilla baseline |
| **B** | None | Full `vz-patch.wad` (2197 blocks) | Crash → **patch WAD alone** (not ASI) |
| **C** | None | Assets-only (2196 blocks, no scripts_vz) | Pass → **scripts_vz block 2196** is suspect |
| **D** | `nohooks` | Full patch | Crash → ASI loader/DllMain side effect (rare) |
| **E** | `minimal` (NET only) | Full patch | Pass → **REG_PATCH** (`Hook_LogPrintf`) is suspect |
| **F** | `nobootstrap` (REG_PATCH+NET) | Full patch | Current failure mode |
| **G** | `nobootstrap` | Assets-only | Pass → scripts_vz ASET shadowing confirmed |
| **H** | Full bootstrap | Full patch | Row 13 target — only after A–G isolate cause |

### Windows deploy commands (PowerShell)

Assume game at `C:\Mercs2`, shared folder `Z:\` from Mac build host.

**Test A — vanilla baseline:**

```powershell
cd C:\Mercs2\scripts
if (Test-Path dlc_enable.asi) { Rename-Item dlc_enable.asi dlc_enable.asi.off }
cd C:\Mercs2\data
if (Test-Path vz-patch.wad) { Rename-Item vz-patch.wad vz-patch.wad.off }
# Launch game, load save, exit shell movies
```

**Test B — patch only, no ASI:**

```powershell
cd C:\Mercs2\scripts
if (Test-Path dlc_enable.asi) { Rename-Item dlc_enable.asi dlc_enable.asi.off }
copy Z:\output\data\vz-patch.wad C:\Mercs2\data\vz-patch.wad
```

**Test C — assets-only WAD, no ASI:**

```powershell
copy Z:\output\data\vz-patch-assets-only.wad C:\Mercs2\data\vz-patch.wad
# (no ASI)
```

**Test E — minimal ASI (NET only):**

```powershell
copy Z:\output\scripts\dlc_enable.asi C:\Mercs2\scripts\dlc_enable.asi
copy Z:\output\data\vz-patch.wad C:\Mercs2\data\vz-patch.wad
# Log must show: Build: MINIMAL … REG_PATCH=0 NET=1
```

**Test F — nobootstrap (current):**

```powershell
# Build: make dlc-asi-native-nobootstrap on host first
copy Z:\output\scripts\dlc_enable.asi C:\Mercs2\scripts\dlc_enable.asi
# Log must show: bootstrap=OFF … REG_PATCH=1 NET=1 VZ_LOAD=0
```

### Reading the crash log

```text
Checkpoint: Shell exited (L=0x... bootstrap_ok=0 vz_pending=0)
Expect next: [lua] MrxSoundBootstrap.Init — crash in native gap if missing
[lua] Shell exited
Watchdog: started (+0 ms post-Shell-exited)
Watchdog: +50 ms post-Shell-exited (still alive)    ← crash before this = immediate AV
FATAL: exception 0xC0000005 at 0x........ fault=0x........   ← if global guard catches it
```

If **no `FATAL:` line** and **no `Watchdog:` after `+0 ms`**: hard terminate (stack overflow,
`TerminateProcess`, or guard miss) — try Test A first.

---

## Prerequisites

- Cracked retail EXE (53,482,288 bytes)
- `pmc_bb.dll` in game directory (provides console logging)
- Ultimate ASI Loader (`dinput8.dll`) installed

---

## G1 — `dlc01` in patch WAD

```bash
.venv/bin/python3 tools/verify_patch_dlc01.py --wad "<game>/Data/vz-patch.wad"
```

**Pass:** `OK: dlc01 ASET looks correct for import() on PC`
**Expect:** `type_id=35`, block path contains `scripts_vz`, `>= 2197` PTHS blocks.

## G2 — WAD structure valid (PTHS trailer)

```bash
make verify-patch-wad-structure OUTPUT=./output WAD_VARIANT=full WAD_EXPECT_BLOCKS=2197
```

**Pass:** `PTHS trailer: PRESENT` and `OK: patch WAD structure looks valid`
**Fail:** Missing 258-byte trailer — rebuild with current `dlc_port.py`.

## G3 — ASI bootstrap build

```bash
make dlc-asi-native OUTPUT=./output
```

Deploy `output/scripts/dlc_enable.asi` to `<game>/scripts/` (NOT game root — one ASI only).

**Pass log lines (in `dlc_enable_crash.log`):**

```text
Build: VZ_LOAD luaL_loadbuffer+pcall bootstrap (multi-strategy)
VZ-load bootstrap: scheduled on game thread (L=0x..., delay 60000 ms)
DLC bootstrap: strategy 1 succeeded
DLC bootstrap [vz]: import("dlc01") succeeded
DLC bootstrap [vz]: tMissionData registration succeeded
Late bootstrap: scheduled after mission flow init (delay 5000 ms, unlock only)
[dlc_unlock] 4 DLC missions unlocked via wifmissionflow
DLC bootstrap [late]: unlock + UI refresh succeeded
```

## G4 — In-game verification

1. Launch game, load save, reach PMC interior
2. Talk to Fiona — 4 DLC contracts should appear: *Mercs Blitz*, *Arms Race*, *Urban Rampage*, *Death Race*
3. Accept one — briefing uses placeholder slides (expected until Spiel gfx are ported)
4. Mission should load and be playable

## Deploy Checklist

| File | Destination | Required? |
|------|-------------|-----------|
| `vz-patch.wad` | `<game>/Data/` | Yes |
| `dlc_enable.asi` | `<game>/scripts/` | Yes |
| `pmc_bb.dll` | `<game>/` | Recommended (logging) |
| `dinput8.dll` | `<game>/` | Yes (ASI Loader) |
| `vo_stream_dlctest.english.pws` | `<game>/Data/Audios/` | Optional (voice) |
| `dlctest_streaming.pws` | `<game>/Data/Audios/` | Optional (voice) |

## Build Variants

| Variant | Command | Use Case |
|---------|---------|----------|
| Full (DLC + bootstrap) | `make dlc-port DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` | First-time build |
| DLC blocks only | `make dlc-port-assets-only DLC_RAR=... SOURCE_WAD=... OUTPUT=./output` | Asset testing (2196 blocks) |
| Nohook bootstrap only | `make dlc-bootstrap SOURCE_WAD=... OUTPUT=./output` | Script testing |
| ASI (default) | `make dlc-asi-native OUTPUT=./output` | Standard bootstrap |
| ASI nobootstrap | `make dlc-asi-native-nobootstrap OUTPUT=./output` | REG_PATCH+NET bisect |
| ASI minimal | `make dlc-asi-native-minimal OUTPUT=./output` | NET-only bisect |
| ASI nohooks | `make dlc-asi-native-nohooks OUTPUT=./output` | Zero-hook bisect |
| ASI no crash patch | `make dlc-asi-native-no-crash-patch OUTPUT=./output` | Skip 0x005AE372 cave |
| ASI (debug popup) | `make dlc-asi-native-debug OUTPUT=./output` | MessageBox on load |

## What Not To Do

- Do not call `lua_pushstring` from ASI (LTCG — AV at `0x0085DFCA`)
- Do not use `error()` in inject chunks (often shadowed)
- Do not modify existing retail `scripts_vz` entries (causes masterscript hang)
- Do not call `dynamic_import("dlccon*")` (causes AV via re-entrant block loading)
- Do not fire bootstrap during the 408-layer loading sequence (re-entrancy deadlock)
- Do not place `dlc_enable.asi` in the game root — only `scripts/` folder
