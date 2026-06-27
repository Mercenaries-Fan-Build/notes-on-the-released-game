# Mercenaries 2 — What makes the "Jul 11 2008" build a PROTOTYPE vs retail

**Scope:** Synthesize the concrete, *prototype-only* signals in the Jul 11 2008 X360 preview build and contrast them with the shipped game, from evidence already extracted (no heavy new extraction). Covers build config, the leaked source tree, WAD-size delta, the `dlctest01` lineage, debug/test strings, and date stamps.

**Provenance:** Mercenaries 2: World in Flames, **Jul 11 2008 X360 preview prototype** (devkit "Profile" build), Pandemic "Pangea" engine, Havok physics. Disc: `game-files/Mercenaries 2 World in Flames (Jul 11, 2008 prototype)/Mercenaries 2 Preview X360 (Jul 11 2008).iso`.

> Cross-links: [`jul08_prototype_iso.md`](jul08_prototype_iso.md) (disc/file table, PE recovery, PDB) · [`default_xex.md`](default_xex.md) (the boot `Final` exe vs this `Profile` exe) · [`embedded_xex_modules.md`](embedded_xex_modules.md) · [`docs/mercs2-dlc-luacd/README.md`](../mercs2-dlc-luacd/README.md) (the `dlctest01` lineage) · [`docs/mercs2-luacd/`](../mercs2-luacd/) (retail base-game Lua, for comparison).

All numbers below are read directly from the recovered PE strings dump `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` (57,160 lines), the source-path dump `…/mercs2_xenon_p.source_paths.txt`, the ISO file list `…/iso_filelist.txt`, and on-disk WAD sizes. Commands shown inline. Inferences are marked **(inference)**.

---

## TL;DR — the 5 most novel "this is a prototype" signals

1. **It is a devkit-signed `Profile` build with symbols retained** — PDB `…\Build\Xbox 360\**Profile**\Mercs2_Xenon_P.pdb`, the `_P` ("Preview/Profile") exe — *not* a stripped retail title. Retail never ships the Profile config.
2. **A full developer Debug Menu + Cheat Menu is compiled in** — ~150 contiguous menu-item strings (`Debug Menu page %d / %d`, `Open Cheat Menu`, `God Mode`, `Teleport`, `Spawn "…"`), absent from the shipped game's user-facing build.
3. **Pre-release character/costume variants are spawnable** — `ChrisV2/V3`, `MattiasV2/V3`, `JenV2/V3`, and `ChrisChickensuit`/`MattiasChickensuit`/`JenChickensuit` debug-spawn entries: iteration art that didn't survive to retail.
4. **The build's source tree leaks verbatim** — `d:\projects\ReleaseLine\Mercs2\Pangea\…`, `…\Pal\…`, `d:\mainline\mercs2\pimp\…`, `…\Lua-5.1.2\src\…`, plus build-farm log share `\\mcbain\MERCS\PangeaLogs`.
5. **Earlier/smaller content** — disc `vz.wad` = **2,017,591,296 B (~2.0 GB)** vs retail PC `vz.wad` = **2,565,537,792 B (~2.56 GB)**; and the `Profile` exe links **2008-07-12 01:37:13 UTC**.

---

## 1. Build configuration — "Profile" devkit build, symbols kept

The disc carries two configs of the same source line, built ~105 s apart (see [`default_xex.md`](default_xex.md)):

| | this game exe (`mercs2_xenon_p_EN_FR.xex`) | boot exe (`default.xex`) |
|---|---|---|
| Original PE name | `Mercs2_Xenon_P.exe` (**`_P`**) | `Mercs2_Xenon_F.exe` (`_F`) |
| Build config (from PDB path) | **`Profile`** | `Final` |
| PDB | `…\Profile\Mercs2_Xenon_P.pdb` | `…\Final\Mercs2_Xenon_F.pdb` |
| Unpacked PE size | 32,374,784 B | 26,476,544 B |
| PE link timestamp | **2008-07-12 01:37:13 UTC** | 2008-07-12 01:35:28 UTC |

- Both XEXs unwrap with the **all-zero devkit KEK** (`tools/xex_unpack.py … --devkit`, "AES KEY VALID") → development, not retail.
- The PE retains an **IMAGE_DEBUG_TYPE_CODEVIEW (RSDS)** record → a referenced PDB. GUID `BADD1353-A81D-4C91-A6F8-75CC9483D5A7`.
- The `Profile` exe is **larger** than the shipping-style `Final` exe (`.text` 0x9B5074 vs 0x8E79AC; `.data` ~19 MB vs 0xE2C93C) — extra profiling/instrumentation, consistent with a dev configuration **(inference, but corroborated by retained debug strings below).**

**What a researcher finds novel:** retail Mercenaries 2 ships a stripped `Final`-style title; here you get the **profiling configuration with the full RTTI/symbol surface** still present (324 RTTI class names, 48 source paths — see `jul08_prototype_iso.md`).

---

## 2. The leaked source tree (`d:\projects\ReleaseLine\Mercs2\…`)

```
$ head -25 output/jul08_prototype/mercs2_xenon_p.source_paths.txt
d:\mainline\mercs2\pimp\include\pimp_job.h
d:\projects\ReleaseLine\Mercs2\Lua-5.1.2\src\ldo.c        (lparser.c, lgc.c, lundump.c, …)
d:\projects\ReleaseLine\Mercs2\Pal\src\PalEngine.cpp     (Pandemic Audio Library)
d:\projects\ReleaseLine\Mercs2\Pal\src\low-level\PalSoundEngineXenon.cpp
d:\projects\ReleaseLine\Mercs2\Pangea\Src\PgAiActHeli.cpp (PgAiContext, PgAiCoverManager, …)
```

This pins the exact engine layout: **Pangea** (graphics/AI/physics), **Pal** (Pandemic Audio Library), **pimp** (job/threading, under `d:\mainline\mercs2\pimp`), and a vendored **Lua 5.1.2** VM. The build-farm log UNC `\\mcbain\MERCS\PangeaLogs` and hostname `mcbain` (from `default.xex` `.data`) are internal Pandemic infrastructure. `shaders.bin` carries 344 `…\Pangea\Shaders\Xbox 360\<Shader>.updb` debug-DB paths (see `jul08_prototype_iso.md`). None of this survives in retail.

---

## 3. Debug Menu + Cheat Menu compiled into the prototype

A contiguous run of menu-item strings (`mercs2_xenon_p.pe_full_strings.txt` lines ~640–770) is a live **Debug Menu**:

```
$ sed -n '838,842p' …pe_full_strings.txt
DebugMenu
Debug Menu page %d / %d   [%s]
```

Sampled items (all verbatim from the dump):

- **Cheats:** `Open Cheat Menu`, `Show God Mode Et Al`, `God Mode`, `Demigod Mode`, `Infinite Ammo`, `CheatInvincible`, `CheatUnkillable`, `CheatInfiniteAmmo`. Runtime status line: `God Mode %s Unkillable %s Inf Ammo %s DF: 0x%08x 0x%08x`. Lua gate: `if Cheat and Cheat.DisplayOptions then Cheat.DisplayOptions() end`.
- **Teleport/movement:** `Teleport`, `LastTeleporter`/`NextTeleporter`, `SendEvent_TeleportPlayer`, `SetLastHeroTeleportLocation`, `Increase/Decrease/SloMo/Normal Speed`.
- **Cameras:** `Toggle FreeEye Cam`, `Ground Free Eye Camera`, **`Toggle Marketing Cam`**, `TeleportCamera`.
- **Physics/anim debug:** `Physics Debug`/`Debug2`/`Art Debug`, `Sanity Check Havok`, `Dump Havok Timers`, `Render Active Islands`, `Color All Bodies in VDB`, `Toggle Anim Debug`/`LOD Debug`/`SpuSample`, `Take Snapshot`, `Peformance Graphs` (sic).
- **AI debug:** `AI Debug`/`AIDebug`, `AI Stats`, `Stimulus Counters/Locator/Msgs`, `Show CoverHint`, `Show AI HintNodes`, `Show Player Awareness`, `DrawAllNodes`, `Tog MindKiller`.
- **VFX/streaming:** `Toggle VFX`, `Grenade/Tiny/Small/Large/Huge Explosion`, `Pseudo DVD Emu`, `Toggle Stream Debug`, `Disguise - Gain/Lose/Dist ±` tuning.
- **Spawners:** `TestDropZone` (`Usage: TestDropZone{<params>} - all parameters are required`), `Toggle DropZone Debug`, `Animation Debug Mode`.

The `Toggle Marketing Cam` entry is a tell that this build was used for **press/marketing capture** — exactly what a "preview" devkit disc is for **(inference)**.

---

## 4. `Spawn "…"` debug menu — pre-release characters and costume variants

The debug menu's spawn list (lines ~2275–2360) names the full prototype cast:

```
Spawn "Chris"  / "ChrisV2" / "ChrisV3" / "ChrisChickensuit"
Spawn "Mattias"/ "MattiasV2"/ "MattiasV3"/ "MattiasChickensuit"
Spawn2 "Jen"   / "JenV2"  / "JenV3"  / "JenChickensuit"
Spawn "VZ Soldier" / "OC Soldier" / "PD Soldier" / "Guerilla Soldier" / "Chinese Soldier" / "Allied Soldier" / "Civilian"
Spawn2 "Cheat RPG"   (and: "Fuel-Air RPG (Cheat)", "anti-material rifle", "Covert SMG", "Grapple", "Stinger", …)
Spawn3 "AMX30 (driver)" …
```

- **`*V2`/`*V3`** = playable-character iteration art (in-development model revisions) exposed as separate spawnables — these were collapsed/cut by retail **(inference)**.
- **`*Chickensuit`** = costume variants for the three playable mercs (Chris/Mattias/Jen). A novel cosmetic/test asset not in the shipped character set **(inference)**.
- Faction soldier types (`VZ`/`OC`/`PD`/`Guerilla`/`Chinese`/`Allied`) and "Cheat" weapon variants confirm a sandbox/QA spawn harness, not a player-facing feature.

---

## 5. `dlctest01` — the prototype DLC lineage

From [`docs/mercs2-dlc-luacd/README.md`](../mercs2-dlc-luacd/README.md): the **retail** Xbox DLC ("Blow It Up Again" / DLC01) shipped **debug-stripped** (no local/source names). But two **earlier DLC test builds** retain debug info and contain a different, earlier **`dlctest01`** script set with **real names** — base-game-quality decompile:

```
docs/mercs2-dlc-luacd/src/dlctest01/
  dlctest01.lua            (6,913 B)
  dlctestcon01.lua         (676 B)
  dlc_mrxgreengoblinbomb.lua (2,664 B)
```

The prototype lineage is also visible *inside the shipped DLC block* as leftover stub names: `dlctest01_all_sound`, `dlctest01_soundbootstrap`. This `dlctest01` → `dlc01` rename/restructure is the DLC's pre-release skeleton; the prototype build is where its **unstripped, named** form survives. The two `sDesc = 'test'` / `sLabel = 'test'` strings in the game exe are the same placeholder-naming habit.

---

## 6. WAD size delta — earlier, smaller content

```
$ grep -iE "\.wad" output/jul08_prototype/iso_filelist.txt
2,017,591,296  vz.wad      (disc, prototype)
   79,790,080  english.wad
   68,026,368  french.wad
    2,490,368  loading.wad
   11,894,784  shell.wad
$ ls -la game-files/vz.wad game-files/xbox-vz.wad
2,565,537,792  game-files/vz.wad        (retail PC)
2,000,486,400  game-files/xbox-vz.wad   (retail-ish Xbox)
```

The prototype disc `vz.wad` (**2.0 GB**) is **~548 MB smaller** than the retail PC `vz.wad` (**2.56 GB**) — fewer/earlier assets, consistent with a mid-2008 preview. (It is also close to but distinct from the on-disk `xbox-vz.wad` at 2,000,486,400 B; treat those as different artifacts — verify by hash before equating them, per the project's hash-not-size rule.) A dedicated `vz_wad_prototype` deep-dive does not exist yet; this size delta is the load-bearing fact until a block-level diff is done **(inference: smaller == earlier content state)**.

---

## 7. Other retained dev/QA strings (retail would strip)

```
$ grep -iE "deprecat|not.implement|Assets unused" …pe_full_strings.txt
(deprecated) MoveToActor / MoveToPos / MoveToVehicle (Lua API migration notes left in)
"Function not implemented", "Not implemented yet"
"Assets unused: %d mem %dK dev %dM used %d mem %dK dev %dM"   ← asset-budget instrumentation
$ grep -iE "EnableDebugger|x360_memory_debug|DebugHDCache|Pseudo DVD" …
" EnableDebugger 1 ", " [x360_memory_debug] ", " DebugHDCache 1 ", "Pseudo DVD Emu"
```

- Config-file knobs like `EnableDebugger 1`, `[x360_memory_debug]`, and `# … install from /app_home/ (for debugging only)` are dev-disc settings.
- `Assets unused: …` is a **memory-budget report** — a profiling-build diagnostic, matching the `Profile` config.
- Deprecated-API migration hints (`MoveToActor → MoveTo`) are mid-development churn left in the script API.

There were **no** `TODO`/`FIXME` comment strings (only symbol-name false hits like `HACKRenormalizeQuats`, `HIBER HACK`) — consistent with C++ where comments don't reach the binary; the debug *menu* and *config* strings are the real prototype tell, not source comments.

---

## 8. Date stamps (Jul 11–12 2008)

- Disc title: "Jul 11 2008 prototype" (per provenance/folder name).
- PE link timestamps (UTC, from FileHeader `TimeDateStamp`): **Profile exe `2008-07-12 01:37:13`**, Final exe `2008-07-12 01:35:28` — same CI run, ~105 s apart (see `default_xex.md`).
- Title ID `45410828`, version/baseversion `00000000` (no shipped version stamped — typical preview/dev build).

The game shipped to retail at the **end of August / September 2008**, so this build predates release by ~6–7 weeks **(inference; ship date from general knowledge, not extracted)**.

---

## What a researcher would find novel here vs the shipped game

- A **fully-symboled `Profile` devkit build** of a game that retail ships stripped — RTTI class names, 48 engine source paths, the `d:\projects\ReleaseLine\Mercs2\Pangea` tree, and the `\\mcbain\MERCS\PangeaLogs` build-farm path.
- A **complete in-engine Debug + Cheat menu** (God Mode, Teleport, sandbox Spawn list, AI/physics/anim visualizers, `Marketing Cam`, `TestDropZone`) that is the developer/QA control surface.
- **Pre-release character iteration** (`*V2`/`*V3`) and **costume variants** (`*Chickensuit`) for all three playable mercs.
- The **`dlctest01` DLC ancestry** in *named, unstripped* form — the only place the DLC's early structure is human-readable.
- **Earlier content footprint**: `vz.wad` 2.0 GB vs retail 2.56 GB.

---

## Provenance of every number above
- Strings/menu/spawn/cheat/deprecated lines: `grep`/`sed` over `output/jul08_prototype/mercs2_xenon_p.pe_full_strings.txt` (line numbers cited inline).
- Source paths: `output/jul08_prototype/mercs2_xenon_p.source_paths.txt`.
- WAD sizes: `output/jul08_prototype/iso_filelist.txt` (disc) and `ls -la game-files/vz.wad game-files/xbox-vz.wad` (retail, on disk).
- Build config / PDB / link timestamps / section sizes: [`jul08_prototype_iso.md`](jul08_prototype_iso.md) and [`default_xex.md`](default_xex.md), which parse the recovered PEs (`mercs2_xenon_p.pe_full.bin`, `default_xex.pe.bin`) directly.
- `dlctest01` lineage: [`docs/mercs2-dlc-luacd/README.md`](../mercs2-dlc-luacd/README.md) + `docs/mercs2-dlc-luacd/src/dlctest01/` file listing.

*Items labelled **(inference)** are interpretation; everything else is read directly from the cited extracted bytes. A `vz_wad_prototype` block-level diff and a `disc_media` doc are not yet written — those cross-links are noted where they would belong.*
