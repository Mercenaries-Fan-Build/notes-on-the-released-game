# Diagnostics — Xbox↔PC code map

**Scope:** scoreboard **row 32 (Diagnostics)** — the developer **debug/cheat menu**, the **F-key
hotkey layer**, the **profiler-zone / timer-tree** system, the **debug-string / logging sink**, and
the **per-system dump toggles** (`Toggle Stream Debug`, `Dump resources map`, `RenderLanes`, …). This
marries the **Xbox 360 devkit (Jul-08 Profile build)** symbol/PDB ground truth to the **PC retail
decompilation** (`Mercenaries2.exe`, unpacked image, base `0x00400000`).

**This row is structurally different from every other map in this folder** — and that asymmetry *is*
the finding (§0). The other rows recover a rich runtime that ships on both builds; here the Xbox
**Profile** build carries a huge, fully-wired ~250-item debug surface that the **PC retail (`Final`)
build deliberately strips or stubs**. So this document is honestly an **Xbox debug-menu inventory +
exactly-what-survives-vs-strips on PC + the profiler-zone system + our own RE diagnostics**, not a
symmetric runtime marriage.

**Sources.** Xbox oracle: [`docs/mercs2-pdb-analysis/debug-cheat-menu.md`](../mercs2-pdb-analysis/debug-cheat-menu.md)
(the full decompiled debug/cheat menu, every VA verified in `output/_ghidra_x360/xenon_decomp_named.c`,
base `0x82000000`) + [`prototype_vs_retail.md`](prototype_vs_retail.md) / [`jul08_prototype_iso.md`](jul08_prototype_iso.md)
(why the Profile config carries the menu and retail doesn't) + [`world-streaming.md`](../mercs2-pdb-analysis/world-streaming.md)
(profiler markers) + [`rendering-shaders.md`](../mercs2-pdb-analysis/rendering-shaders.md) §"Debug
rendering & profiling". PC: the 27k-fn Ghidra decomp of the unpacked exe (function bodies read
first-hand and cited as `ghidra/FUN_xxxx`), the pimp/scheduler maps
[`pimp_job_system_code_map.md`](pimp_job_system_code_map.md) §4–§5 +
[`scheduler_tick_code_map.md`](scheduler_tick_code_map.md), the stub inventory
[`docs/lua_capi_comprehensive_audit.md`](../lua_capi_comprehensive_audit.md) + the binding-report tool
`tools/debug_binding_report.py`, and the Lua cheat corpus
[`docs/mercs2-luacd/07_player_core_cheats_managers.md`](../mercs2-luacd/07_player_core_cheats_managers.md).
Our-own-diagnostics reconciliation: memory [[loadprobe-tool-and-0x874e7d-hardclose]],
[[pmc-bb-native-lua-logging]], [[lua-trace-asi-surface-b-oracle]], [[mercs2-workshop-devtool]], and
`docs/modernization/engine_support_inventory.md` row 32.

**Method / honesty model.** Same discipline as the sibling maps. The Xbox side is **code-fact** (the
debug menu is fully decompiled with quoted bodies). The PC side splits three ways and the row says
which: **stub** (points at the shared `0x006D5640` `return-0` thunk — read-confirmed), **stripped**
(no PC string / compiled out of the `Final` config — inferred), **survives** (real PC body present).
Confidence: **H** can't-coincide fingerprint (read body / read stub bytes / string-anchored) · **M**
one strong structural signal · **L/open** positional / confirm-live.

---

## 0. Result in one line

Row 32 is **asymmetric by construction**: the Xbox **Profile** build ships a fully-wired ~250-item
developer debug/cheat menu (registrar `FUN_82279978`, 27 identical toggle bodies flipping
`DAT_836dba4x`/`DAT_837e5bxx` bools, F-key layer `EnableFunctionKeys`), and the **PC retail build
strips it** — the Lua-facing debug toggles/setters (`SetTrafficSpawning`, `SetRoadSpawning`,
`Printf`, `DumpAssets`, …) collapse to a **single shared `return-0` stub `0x006D5640`** and the native
debug-render/menu strings are gone. What genuinely **survives on PC** is the *machinery underneath*:
the **profiler-zone hash registry** (`Hash_String FUN_00824270` + `Hash_Probe FUN_008242b0`, the PC
twin of the Xbox `FUN_8290ba80` FNV markers) and the **per-CPU timer tree** (`FUN_008243a0`/
`FUN_008763c0`/`FUN_008271c0`) — but their **zone-name strings are stripped**, so the specific
profiler table is confirm-live. The **cheats are Lua** (`_G.Cheat.DisplayOptions`), applying effects
through real single-purpose native bindings (`Object.SetInfiniteAmmo`, `Object.SetInvincible`) —
resolving the debug-cheat-menu open question. Our engine's **row 32 is ✅ "different shape"**: 24
headless RE diagnostic fns + 2 env flags + the external RE-tooling belt (loadprobe, pmc_bb, lua_trace,
workshop, mercs2_probe) are the modern analog that serves the RE workflow rather than an in-game menu.

---

## 1. Master table (whole row at a glance)

PC status legend: **stub** = routes to the shared `0x006D5640` `xor eax,eax; ret` thunk (read-confirmed);
**stripped** = no PC string / not in the `Final` config (inferred from build-config asymmetry);
**survives** = real PC body present; **Lua** = implemented in the script layer, not native.

| Debug feature | Xbox VA (base `0x82000000`) | PC status | Evidence | Conf |
|---|---|---|---|---|
| **Menu-item registrar** `AddMenuItem` | `FUN_82279978` → stub `FUN_829167d8` | **stripped** | Xbox thunk into an un-decompiled menu API; no PC menu string survives | H (Xbox) |
| Debug-menu builder (AI/spawn/lane, cat 5) | `RollingCacheDbg @0x8227aa80` | **stripped** | wires each `name→callback` VA, stashes item handle in `DAT_830ba9xx` | H (Xbox) |
| Debug-menu builders (cat 8 / guarded) | `FUN_8227b480` / `FUN_8227b908` (stride `0x14b0`) | **stripped** | second page + 10-subobject guarded registrar | H (Xbox) |
| **27-toggle template** (flip 1 bool + re-stamp label) | 27 bodies, size 188–192 | **stripped** (native) / **stub** (Lua-facing) | flips `DAT_836dba4x`/`DAT_837e5bxx`; labels via "On/Off" `@0x82011aa0/aa4`, fmt `@0x82011a88` | H (Xbox) |
| `GlobalSpawning` toggle | `@0x82276c90` (→`DAT_836dba46`) | **stripped** | template body; Lua `SetTrafficSpawning`/`SetRoadSpawning` siblings = **stub** (§5) | H |
| `RenderLanes` / `RenderSpawnPoints` / `RenderFCStates` | `@0x82276f90` / `@0x82277350` / `@0x82277290` | **stripped** | `DAT_836dba44/4b/43`; PC debug-draw names absent (§4) | H (Xbox) |
| `ShowCurrentRegion` / `ShowSkirmishZones` | `@0x822774d0` / `@0x82277590` | **stripped** | `DAT_836dba4d` / `DAT_836dba50` | H (Xbox) |
| `FreezeViewport` / `BoxCollect` | `@0x82277410` / `@0x82277a10` | **stripped** | `DAT_836dba4c` / `DAT_837e5b24` | H (Xbox) |
| `MindKiller` (mirrors AI state, no own bool) | `@0x82276be0` (via `FUN_8240a108`) | **stripped** | special-case toggle; AI kill-switch state owned by sim | H (Xbox) |
| **F-key hotkey layer** `EnableFunctionKeys` | `@0x8227bad8` (~14 `DAT_830ba8xx` latches) | **stripped** | key hash `FUN_8290ba80`, pressed `FUN_82912240`/`FUN_82911d88` | H (Xbox) |
| **Profiler marker hash** (FNV-1a) | `FUN_8290ba80` (seed `0x811c9dc5`, prime `0x1000193`, `\|0x20`, `^0x2a`) | **survives** | PC twin = `Hash_String FUN_00824270` + core `FUN_0082427f` (identical constants, §3) | H |
| Profiler zone push / pop | `FUN_8290ba80` / `FUN_82902f90` | **survives (probe), name-stripped** | PC `Hash_Probe FUN_008242b0` (`key%256`, 8-way); table global not pinned | M |
| Profiler zone-name **insert** | `FUN_8290bc68` → table `0x83cb28f4` / `DAT_83cb20f4` (count `DAT_83cb20e8`) | **survives, name-stripped** | 27 Xbox call sites; PC has *multiple* 256-bucket probe tables → specific zone table confirm-live | M |
| CPU↔GPU fence + zone register | `SyncCPUGPU @0x824c5f60` | **survives, name-stripped** | PC fence + zone-insert sibling not positively pinned (strings stripped) | L |
| **Asset-load profiler markers** | `ReadyToReload @0x822ed658`: `AssetLoading @0x82017e04`, `WaitForDma @0x82017df8`, `ReadyToDie @0x82017dec`; ARGB `0xff006400` | **stripped** (strings) | marker names gone on PC; the phases exist in the streaming spine (row 8) | M |
| Native debug-render overlays | `Debug::Render @0x0011854`, `DebugRendering @0x00012f8`, `DebugRenderTimers @0x00132d4`, `RenderTimers @0x00c57b4`, `LogRenderCalls @0x0026b64` | **stripped** | Xbox `.rdata` names; no PC string anchors (`rendering-shaders.md` §"Debug rendering") | M |
| **Debug logging sink** `Debug.Printf` / `print` / `Log*` | (Lua binding family) | **stub** `0x006D5640` | read-confirmed: `tools/debug_binding_report.py` (`VA_DEBUG_TABLE 0x00B98828`, Printf ptr `+4` → stub) | H |
| Engine console sink `Sys.WriteToConsole` | (Lua binding) | **survives** (real VA, **not** the stub) | `debug_binding_report.py` resolves it from the `Sys` table `@0x00B98A78`; `is_stub=false` | H |
| Per-system dump toggles (`SetTraffic/Road/Sidewalk/LaneSpawning`, `SetLaneActive`, `DumpAssets`, `DumpTextures`, `LoadScript`…) | (Lua bindings) | **stub** `0x006D5640` | `lua_capi_comprehensive_audit.md` §"Stub Function" enumerates ~60+ → shared stub | H |
| **Cheat menu** (God Mode / Demigod / Infinite Ammo) | strings only; builder not native | **Lua** | `_G.Cheat.DisplayOptions` (`mrxcheatbootstrap.lua:281`); effects via native `Object.SetInvincible`/`SetInfiniteAmmo` (§6) | H |
| Per-CPU timer tree (`RootTimer`/`TimersThread%d`/`TimerBegin/End/EndFrame`) | string-only on Xbox | **survives, name-stripped** | PC freq `FUN_008243a0`, `Time_NowMs FUN_008763c0`, timer thread `FUN_008271c0`, node insert `FUN_00826f90`; ms/µs scales prove it (§3) | M |

---

## 2. Why the asymmetry — Profile devkit vs `Final` retail

The disc that seeds all of our Xbox RE is the **`Profile` devkit configuration** of the game
([`prototype_vs_retail.md`](prototype_vs_retail.md)): PDB path `…\Build\Xbox 360\**Profile**\Mercs2_Xenon_P.pdb`,
the `_P` exe, unpacked PE **32,374,784 B** — *larger* than the sibling `Final` boot exe
(`Mercs2_Xenon_F.exe`, 26,476,544 B) precisely because it carries extra profiling/instrumentation.
The `Profile` build compiles in:

- **A full developer Debug Menu + Cheat Menu** — ~150–250 contiguous menu-item strings
  (`Debug Menu page %d / %d`, `Open Cheat Menu`, `God Mode`, `Teleport`, `Spawn "…"`), each a *live*
  registered callback (debug-cheat-menu.md proves the wiring, not just dead strings).
- Pre-release character/costume debug-spawn entries, the source-tree paths, and verbose per-script
  debug instrumentation.

Retail Mercenaries 2 ships the **stripped `Final`-style** title. The PC decomp we work from is that
retail lineage, and it shows the strip two ways: (1) the whole native menu/registrar surface and its
`.rdata` name strings are **gone** (no PC anchor to marry against — this is the honest "unlocated"
majority of this row), and (2) the *Lua-facing* debug entry points that survived as binding-table
names are **redirected to a single shared `return-0` stub** (§5). The mission-script corpus confirms
the same policy at the content layer: after BE normalization, **7 of 13 contract scripts differ
only in debug/`Printf` strings** — "Xbox builds strip verbose debug instrumentation"
([`contract_analysis_oil_vza.md`](../contract_analysis_oil_vza.md) §"PC vs Xbox String Pool").

**So the marriage here is intentionally lop-sided:** Xbox = code-fact inventory; PC = a stub map + the
few surviving low-level machines. That is the correct, honest shape for row 32.

---

## 3. The profiler-zone system (the part that genuinely survives on PC)

This is the one debug subsystem with a real, readable PC body — because it is *infrastructure* (the
pimp profiler + the engine-wide named-zone registry) rather than the menu that drives it.

### 3.1 The marker-hash primitive — Xbox `FUN_8290ba80` ≡ PC `Hash_String FUN_00824270` (H)

The Xbox profiler-marker idiom is "hash the marker name, then register/look-up the timer by that
hash+name". `FUN_8290ba80` is **not** a profiler-enter — its body is an **FNV-1a string hash**:
seed `0x811c9dc5`, prime `0x1000193`, lowercase-folds via `| 0x20`, final `^ 0x2a`
(`world-streaming.md` §`ReadyToReload`). The PC keeps this verbatim: **`Hash_String FUN_00824270`**
with FNV core **`FUN_0082427f`** (`h = (h ^ (c|0x20)) * 0x1000193`, final `^0x2a`) — the *identical*
constant chain, which is why the marriage is H (`pimp_job_system_code_map.md` §5). This is the same
`pandemic_hash_m2` used for ASET type IDs (`tools/pandemic_hash.py`; verified
`m2("model")==0x5B724250`), so the profiler markers are keyed by the engine's universal name hash.

### 3.2 The 256-bucket zone registry (survives, name-stripped)

- **Xbox:** the zone push/pop pair `FUN_8290ba80`/`FUN_82902f90` and the open-addressing insert
  **`FUN_8290bc68`** write the global profiler color/name table **`0x83cb28f4`** / `DAT_83cb20f4`
  (count `DAT_83cb20e8`); **27 functions** in the image register named zones into it, and the
  `0xff006400`/`0xff4763ff`/`0xff808080`/`0xff000000` words beside each name are the zone's **ARGB
  debug color** (`havok-physics.md` §"Profiler-zone registration is a shared idiom";
  `world-streaming.md` §`ReadyToReload`). `SyncCPUGPU @0x824c5f60` is one such registrar.
- **PC:** the mechanism is **`Hash_Probe FUN_008242b0`** (`key % 256`, 8-way linear probe) — the PC
  256-bucket registry. The honest limit: on PC there are **multiple** 256-bucket `Hash_Probe` tables
  (e.g. the render-resource registry `DAT_0197da48`; per-object dispatch tables), and because the
  **zone-name strings were stripped** the *specific* PC profiler-zone table global, the PC
  `SyncCPUGPU` fence, and the zone-insert sibling are **not positively pinned** → **confirm-live**.

### 3.3 The per-CPU timer tree (survives, name-stripped)

The timing backbone the zones feed is recovered on PC (`pimp_job_system_code_map.md` §4):
freq init **`FUN_008243a0`** (`QueryPerformanceFrequency` → ticks/ms/µs scales `DAT_017d40c0…d4`),
**`Time_NowMs FUN_008763c0`** (`QueryPerformanceCounter` / `__aulldiv` by the ms scale, ~40 call
sites), the **timer thread `FUN_008271c0`** (spawned by `FUN_00826f20`), node insert
**`FUN_00826f90`**, node-tree aging `FUN_00873cf0`/`FUN_00873530`. The **`RootTimer`/`TimersThread%d`/
`TimerBegin/End/EndFrame`** node-struct names are **stripped on PC** — the ms/µs scales prove the
subsystem exists but the RootTimer node layout can't be string-grounded → confirm-live (walk the timer
tree from a worker TEB in x32dbg).

### 3.4 Asset-load phase markers (Xbox strings, PC stripped)

`ReadyToReload @0x822ed658` registers the load-path timers **`AssetLoading` (`@0x82017e04`)** →
**`WaitForDma` (`@0x82017df8`)** → **`ReadyToDie` (`@0x82017dec`)** with color `0xff006400`. These
name the DMA-based asset-streaming phases of the streaming spine (row 8) — the phases exist on PC but
the marker *names* are stripped, so they're pinned by role, not string.

---

## 4. Native debug-render overlays (Xbox-named, PC-stripped)

`rendering-shaders.md` §"Debug rendering & profiling" lists the Xbox developer debug-draw layer:
**`Debug::Render` (`0x0011854`)**, `DebugRendering` (`0x00012f8`), **`DebugRenderTimers`
(`0x00132d4`)**, `RenderTimers` (`0x00c57b4`), `LogRenderCalls` (`0x0026b64`), plus the
family the menu toggles drive — `RenderLanes`, `RenderFCStates`, `RenderSpawnPoints`,
`RenderConstraints`, `RenderDelayedCasts`. These are the *native* overlays gated by the
`DAT_836dba4x` toggle bools (§1). On the PC retail image these names carry **no string anchor** and
the toggle bools are inaccessible (their Lua setters are stubbed, §5), so the whole debug-draw layer
is **stripped/compiled-out for row-32 purposes** — there is nothing to marry. This is the single
largest "unlocated by design" block in the row and it is honest to leave it so.

---

## 5. The shared debug/logging stub `0x006D5640` (PC — read-confirmed)

The concrete mechanism by which retail neuters the *Lua-facing* debug surface is a **single shared
thunk**:

```
0x006D5640:  33 C0    xor eax, eax     ; return 0
             C3       ret
```

Many binding-table entries point their function pointer straight at this VA
([`lua_capi_comprehensive_audit.md`](../lua_capi_comprehensive_audit.md) §"Stub Function"). The
enumerated stub set (~60+) includes the entire logging/dump/dev family and the debug spawn toggles:

`print`, `Printf`, `LogError`, `LogWarning`, `LogInfo`, `Assert`, `GetCallstack`, `Search`,
`DumpAssets`, `DumpTextures`, `LoadScript`, `LoadData`, **`SetTrafficSpawning`**,
**`SetSidewalkSpawning`**, **`SetRoadSpawning`**, **`SetLaneActive`**, `SetExclusionZone`, `SetSky`,
`Water`, `Talk`, `Feed`, … — i.e. the PC counterparts of the Xbox `GlobalSpawning`/`NoRoadSpawn`/
`NoSidewalkSpawn` debug toggles are all present in the binding table **but wired to `return 0`**.

**`Debug.Printf` is read-confirmed at the stub** (`tools/debug_binding_report.py`): the Debug table is
at `VA_DEBUG_TABLE = 0x00B98828`, the `Printf` function-pointer slot at `+4` (`0x00B9882C`), and it
resolves to `0x006D5640` (`stub=True`). This is also why the `pmc_bb`/`lua_trace` tracers see
`Debug.Printf @0x6D5640` **double-hooked** (memory [[lua-trace-asi-surface-b-oracle]] bug#6: the
co-hooked argc:-1 case is exactly this shared stub).

**The one survivor: `Sys.WriteToConsole`.** The same tool resolves `WriteToConsole` from the `Sys`
binding table (`VA_SYS_TABLE = 0x00B98A78`) to a **real VA with `is_stub=false`** — the engine keeps a
live console sink even though `Debug.Printf` is dead. So on PC the surviving debug-output path is
`Sys.WriteToConsole`, not the `Debug.*` logging family. (Base table `@0x00B924B8` holds the global
`print`, also stubbed.)

---

## 6. Cheat-table resolution (closes the debug-cheat-menu.md open question)

debug-cheat-menu.md left open whether God Mode / Demigod / Infinite Ammo are native toggles. **They
are not — they are Lua**, and the Lua corpus resolves it fully:

- **The menu is script.** `_G.Cheat = { DisplayOptions = DisplayOptions }`
  (`mrxcheatbootstrap.lua:281`) — the entire cheat UI is `MrxCheatBootstrap` built on
  `MrxMultiPageMenu`, triggered by `Cheat.DisplayOptions()` from any Lua/console reach
  ([`07_player_core_cheats_managers.md`](../mercs2-luacd/07_player_core_cheats_managers.md) §2). It is
  imported by `mrxmissionflow.lua` (`import("MrxCheatBootstrap")`).
- **The effects are real single-purpose native bindings**, not a native "God Mode" toggle:
  - **Infinite Ammo** → `Object.SetInfiniteAmmo(uCharacter, bEnable)` (native binding; used by the
    shooting-gallery minigame and pmccon031–034 co-op finale).
  - **God Mode / invincibility** → `Object.SetInvincible(uCharacter, bEnable)`.
  - **Grapple cheat** → `WifMissionFlow.SetGrappleEnabled(bEnable)`.
  - The net-replicated cheat path (`NETEVENT_CHEAT_INFINITE_AMMO_PRIMARY_ON/OFF`,
    `NETEVENT_CHEAT_GRAPPLE_ON`, …) in `dlc01_mrxguipda.lua` dispatches to exactly these bindings for
    each of `Player.GetPrimaryCharacter()` / `GetSecondaryCharacter()`.

So the verdict is: **cheat *menu* = Lua (`Cheat.*` table); cheat *effect* = a per-character component
flag set by a real native binding.** "God Mode is a native debug toggle" is **not supported** — it is
a Lua orchestration over `Object.SetInvincible`/`SetInfiniteAmmo`. This also ties to the game-systems
content gate `HasPlayerUnlockedCode` (`game-systems.md`), which is the unlock check the Lua cheat menu
consults, not a native cheat implementation.

---

## 7. Confirm-live inventory (x32dbg, read-only while PAUSED — [[x32dbg-mcp-no-resume]])

1. **PC profiler-zone table** — break `Hash_Probe FUN_008242b0` during a frame; capture the caller's
   table base to disambiguate the profiler-zone table from the render-resource registry
   (`DAT_0197da48`) and the per-object dispatch tables. Recovers the PC twin of Xbox `0x83cb28f4`.
2. **PC `SyncCPUGPU` fence + zone-insert sibling** — the strings are stripped; find them by breaking a
   worker's end-of-frame and following the register-into-256-bucket-table call (mirror of Xbox
   `FUN_8290bc68` from `SyncCPUGPU @0x824c5f60`).
3. **RootTimer node struct** — walk the per-CPU timer tree from a pimp worker TEB (worker proc
   `FUN_00876400`, `Time_NowMs FUN_008763c0`) to recover the `TimerBegin/End/EndFrame` node layout
   (name-stripped).
4. **`Sys.WriteToConsole` body** — dump the real (non-stub) console sink resolved by
   `debug_binding_report.py`; confirm it is the surviving PC debug-output path and where it writes.
5. **Confirm the stub bytes live** — break/read `0x006D5640` = `33 C0 C3`; sample a handful of the
   ~60 stubbed bindings' function-pointer slots to confirm they all target it (SecuROM decrypts these
   at runtime; verify the unpacked image matches the static `xor eax,eax; ret`).
6. **Asset-load phase markers on PC** — the `AssetLoading`/`WaitForDma`/`ReadyToDie` names are gone;
   break the streaming node lifecycle (row 8 `FUN_008739e0`) and check whether a zone is pushed with
   the corresponding hashes to confirm the phases are still instrumented.

---

## 8. Reconciliation with `mercs2_engine` (scoreboard row 32 = ✅ different-shape)

**Status: ✅ — a faithful in-game debug *menu* is deliberately NOT reimplemented; the engine's row-32
surface is RE-workflow diagnostics of a different shape, which is the correct target for a
modernization/reverse-engineering project.** (`engine_support_inventory.md` row 32.)

- **What the engine has instead of the ~250-item menu:** **24 headless RE diagnostic functions**
  (animation-gate probes, streaming probes, placement/hash hunting) + **2 env-flag toggles** — these
  serve the reverse-engineering workflow, not an end-user debug overlay.
- **The external RE-tooling belt is the real modern analog** of the Profile build's per-system dumps
  and the profiler markers:
  - **`loadprobe`** scores `pmc_blackbox.log` to quantify how far world-load got and classify the
    end-state (knows `0x874E7D` = hard-close, not a crash) — the modern `Toggle Stream Debug` /
    `Dump resources map` ([[loadprobe-tool-and-0x874e7d-hardclose]]).
  - **`pmc_bb.dll`** captures the game's Lua `Debug.Printf`/`[world]` output to `pmc_blackbox.log` —
    the ground-truth logging sink that retail stubbed at `0x006D5640` ([[pmc-bb-native-lua-logging]]).
  - **`lua_trace.asi`** traces every Lua→engine binding call (~1216 hooks, NDJSON) — a live
    binding-level profiler ([[lua-trace-asi-surface-b-oracle]]).
  - **`mercs2_probe`** subcommands (the sanctioned home for new diagnostics per
    [[no-debug-probes-in-game-exe]]) + **poolguard** + the engine-rendered **`mercs2_workshop`**
    (asset browse/inspect/remix + sandbox, [[mercs2-workshop-devtool]]) cover the asset-dump / inspect
    / VidMem-View slots the Xbox menu had.
- **The faithful-impl reference this map hands the engine** (if an in-engine profiler is ever wanted):
  the profiler-zone registry is a **256-bucket open-addressed table keyed by the universal
  `pandemic_hash_m2` name hash** (§3.1–3.2) feeding a **per-CPU timer tree** (§3.3) — reuse the
  engine's existing name-hash and fixed-tick schedule rather than inventing a new marker system.
- **Do NOT** try to reconstruct the Xbox debug *menu* on PC data: the native registrar, toggle bodies,
  and debug-render overlays are stripped/compiled-out of the retail lineage (§4) and the Lua toggles
  are `return-0` stubs (§5) — there is no runtime there to faithfully mirror. The authentic behaviour
  to preserve is the **stub** (retail returns 0) and the **Lua cheat table** (§6), both of which the
  script layer already carries.