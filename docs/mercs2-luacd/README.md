# Mercenaries 2 (PC) — Decompiled Lua Corpus & Reference

Decompiled, human-readable Lua source for the **base PC retail game**, plus a categorized
documentation set (defaults, APIs, logic, logging, cross-references) for modding / RE work.

## Provenance (verified clean base game — NOT DLC)

| | |
|---|---|
| Source WAD | `game-files/vz.wad` — **byte-identical** to the game's deployed `data/vz.wad` (size `2565537792`, qsha256 head+tail `502e290f…863696f`) |
| Verified | Game loads this WAD cleanly to 100% (`loadprobe` REACHED-WORLD); **no DLC scripts present** (no `dlccon*`/blitz/arena); base contracts (pmccon/gurcon/chicon) all present |
| Blocks | `blocks\VZ\resident_P000_Q3.block` (idx 3185), `scripts_vz_P000_Q3.block` (idx 3197), `shell.wad` block 17 |
| Script counts (base) | **resident 240, scripts_vz 114, shell 28** — re-pulled fresh (the earlier counts came from a stale June-2 cache; fresh pull confirms identical numbers) |
| Decompiler | `unluac` (`tools/external/unluac/unluac.jar` + `tools/jdk21`) on `lua51-mercs2` float-bytecode |
| Decompiled OK | **370 / 382** → `src/`. The 12 failures (`_decompile_failures.txt`) are the empty `all_*` stubs (`all_weapons`, `all_vehicles`, …) + 2 goto-heavy scripts — no content lost. |

## Layout

- `src/resident/` (228) — Mrx engine/library modules + world-entity scripts
- `src/vz/` (114) — contracts, jobs, tutorials, WIF data tables
- `src/shell/` (28) — front-end menu / shell GUI
- `_manifests/` — the per-category file lists used to generate the docs
- `0N_*.md` — the eight category references below

## Documentation set

| Doc | Covers | Headline finds |
|---|---|---|
| [01_support_economy_delivery.md](01_support_economy_delivery.md) | Store / supply-drop / airstrike / delivery | `tSupportData` catalog (~120 items, cash 5k–1M, fuel 40–900); **free-item gate** `nCost <= GetCashQty()` in `MrxShop._ShopSelection`; consume order fuel→freebie/cash→stockpile; `_kMaxStock=99`; `AddSupportData` (DLC-gated) |
| [02_mission_task_framework.md](02_mission_task_framework.md) | Mission/task tree, MrxState machine, briefing, rewards | Load-gate states `STATE_*` (WAITFORGAME=4, WAITFORSTREAMING=2…) + refcount logic; **the world-load log markers** (`GlobalEnter/Exit`, `MrxState.Enter/Exit … refcount=N`); why DLC missions hang on streaming |
| [03_contracts_jobs.md](03_contracts_jobs.md) | 74 contract/job content scripts | Full catalog by faction/type; 7 archetypes; pmccon031–034 = the `Object.SetInfiniteAmmo` shooting galleries; outpost health 3–6; gallery timers 240/150/90 |
| [04_tutorials_wifdata.md](04_tutorials_wifdata.md) | Tutorials + WIF data tables | **Equipment table** (FuelTank1–8 = 100k/200, 9–14 = 250k/700, Grapple 100k); cheat-stockpile loadouts; starter/HQ/recommendation tables; 22 tutorials w/ triggers+timings |
| [05_gui_hud_shell.md](05_gui_hud_shell.md) | GUI toolkit, HUD, PDA, shell menus | HUD native fields (`PrimaryClipSize`/`PrimaryCurrentAmmo`/`sReticleType`…); minimap marker names + the "marker not found" warning source; Scaleform `.gfx` map |
| [06_ai_world_entities.md](06_ai_world_entities.md) | AI + world/object scripts | Entity OO hierarchy + awake-gating; outpost capture AI; health/spawn/pickup tables (soldier pickup every 3rd death, munitions blip 175, fuel 50/500/5000, cash 100000) |
| [07_player_core_cheats_managers.md](07_player_core_cheats_managers.md) | Player, economy (MrxPmc), **cheat menu**, managers | Full cheat menu (`_G.Cheat.DisplayOptions()`: add cash/fuel/support, "The Works!", modify attitude, unlock LZs, dispense rewards); fuel cap [300,9999], cash [0,1e9]; default loadout Pistol/Grenade/C4; ASI cheat-injection entry points |
| [08_audio_presentation.md](08_audio_presentation.md) | Sound/music/VO, cinematics, fanfares | Sound/wave bank registry; music cue naming `mu_fac_<faction>_<role>_NN`; fanfare types (`contact`/`support`/`stockpile`/`landingzone`/`bounty`/…) |

## Quick "where do I find…" index

- **Weapon stats (velocity/spread/damage)** → NOT in Lua; in `wpn_*` WAD blocks (see memory `weapon-definitions-wpn-blocks`). Lua only sees runtime ammo state (HUD fields in doc 05).
- **Make a store item free** → `nCashCost = 0` (doc 01) — the `_ShopSelection` gate passes trivially.
- **Infinite ammo** → `Object.SetInfiniteAmmo(Player.GetPrimaryCharacter(), true)` (docs 03 + 07).
- **Cheats** → `_G.Cheat.DisplayOptions()` and direct `MrxPmc`/`Player` pokes (doc 07).
- **World-load log markers** → doc 02 (`mrxstate.lua`) — the ground-truth strings `loadprobe` keys on.
- **Default values / tunables** → every doc has a "Defaults & tunables" table; richest are 01, 04, 06, 07.

> Note: docs cite real line numbers as `[name.lua:LINE](src/<group>/<name>.lua#LLINE)`. A handful of
> decompiler artifacts (undefined locals, duplicate keys, precedence quirks) are flagged inline in
> each doc — they are unluac output noise, not necessarily engine bugs; verify against disasm before acting.
