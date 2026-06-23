# Mercenaries 2 — Decompiled DLC Lua Corpus

Decompiled, human-readable Lua source for the **"Blow It Up Again" / DLC01** content
that ships in the Xbox 360 DLC package. Companion to the base-game corpus in
[`docs/mercs2-luacd/`](../mercs2-luacd/README.md) — this set is the **DLC-only**
scripts (all 36 are net-new; none override a base-game script name).

## Provenance (Xbox 360 DLC — big-endian source)

| | |
|---|---|
| Source archive | `game-files/Mercenaries.2.World.In.Flames.DLC.RF.X360-ZTM.rar` (`sha256 180fba37…89443a`) |
| Container | STFS package → `DLC01.doh` FFCS WAD (`SCFF`, big-endian; `sha256 5b0c222d…deb3ae`, 251,953,152 B) |
| Block | All Lua lives in one block: idx **464** `blocks\dlc01\resident_P000_Q3.block` (decompressed 3,763,027 B, 36 `LuaQ` chunks). A full scan of all 2,196 blocks found Lua **only** here. |
| Bytecode | Xbox Lua 5.1, **big-endian, 4-byte float** (`\x1bLuaQ` header `1b4c75615100000404040400`; byte 6 = `0x00` = BE) |
| Decompiler | `unluac` (`tools/external/unluac/unluac.jar` + `tools/jdk21`) — reads the header's endianness flag, so the raw BE chunk decompiles with **no byte-swap** |
| Decompiled OK | **36 / 36** → `src/dlc01/`. (3 are empty stubs: `dlc01_assets`, `dlc01_aliases`, `dlctest01_all_sound`.) |
| Tool | `tools/decompile_dlc_lua.py` (re-runnable end-to-end: STFS → block 464 → LuaQ split → unluac → cleanup) |

> Note: script names are recovered from each entry's `BINN` section (stored
> reversed as `NNIB` in the big-endian WAD) — the embedded Lua source-name field
> is stripped (length 0) in these shipped chunks.

## ⚠ The retail DLC bytecode is debug-STRIPPED

Unlike the PC base game (which kept debug info, so unluac reconstructs real
`local`/function names), the **retail Xbox DLC was shipped with debug info
stripped** — no local-variable names, no source name. With nothing to name them,
unluac can only emit VM-register names (`L0_1`, `A0_2`) and one statement per
assignment, so a single source line such as `import("MrxSupport", false)` decompiles
as four lines of register soup. The original local names are **unrecoverable**.

To make this readable, `src/dlc01/` has been run through a conservative
**copy-propagation pass** (`tools/lua_unluac_cleanup.py`) that folds single-use
temporaries back into expressions and drops dead `local` declarations:

```
-- raw/dlc01 (verbatim unluac)        -- src/dlc01 (cleaned)
L0_1 = import                         import("MrxSupport", false)
L1_1 = "MrxSupport"                   uCargoToDeliver = Pg.GetGuidByName("box")
L2_1 = false
L0_1(L1_1, L2_1)
```

The pass is **cosmetic only and verified faithful** (`tools/_verify_cleanup.py`):
for every file the multiset of non-register tokens (strings/numbers/identifiers)
is identical before/after, and the cleaned output introduces **zero** new syntax
errors. Registers that survive (`L0_1`) are genuine multi-use locals that can't be
named. When in doubt, `raw/dlc01/` is the authoritative 1:1 of the bytecode.

> Several files don't compile with vanilla `luac -p` — unluac emits `goto`/labels
> (`lbl_NN`) for some control flow, which is Lua 5.2+ syntax. This is a property of
> the raw decompile (the raw files fail identically); the cleanup pass never adds it.

## Bonus: unstripped prototype scripts (`src/dlctest01/`)

The retail content has no unstripped source anywhere, but two early DLC test
builds (`DLC Blow It Up Again Pack B` / `Amazon Pack` prototypes) **do** retain
debug info. They contain a different, earlier 6-script test set (`dlctest01`,
`dlctestcon01`, `dlc_mrxgreengoblinbomb` + 3 stubs) with **real names** —
base-game-quality decompile, no cleanup needed. Useful as a readable reference for
the DLC's early structure, but note it is *not* the shipped retail content.

## Layout

- `src/dlc01/` (36) — retail DLC modules, readability-cleaned. **Start here.**
- `raw/dlc01/` (36) — verbatim unluac output; authoritative when verifying a value.
- `src/dlctest01/` (3) — unstripped prototype scripts, real names.

## Contents by area

| Area | Scripts |
|---|---|
| **Contracts / missions** | `dlccon001` `dlccon002` `dlccon003` `dlccon004a` `dlccon004_cash` `dlccon004_timer_pickup` `dlccon004_tower` `dlccon050` `dlc_moonpatrol` `dlcescalation` |
| **Mission framework / flow** | `dlc01missionflow` `dlc01_missionhub` `dlc01_briefing` `dlc01_starterdata` |
| **GUI / HUD** | `dlc01_mrxguihudradar` `dlc01_mrxguipda` `dlc_mrxguidialogbox` `dlc01_pausescreen` `dlccombometer` `dlcspeedtimer` |
| **Player / interior / bootstrap** | `dlc01` `dlc01_hero` `dlc01_player` `dlc01_pmcinterior` |
| **Vehicles / weapons / pickups** | `dlcvehiclestrike` `dlc_mrxtankbuster` `tankbusterpickup` `emplacedtowvendor` `ammobay` `repairbay` `dlccopterdrop` `speedtools` |
| **Audio** | `dlctest01_soundbootstrap` |
| **Empty stubs** | `dlc01_assets` `dlc01_aliases` `dlctest01_all_sound` |

## Caveats

- `src/dlc01/` is `unluac` output + a copy-propagation cleanup; surviving `L0_1`
  locals are unnameable (stripped). For a faithful 1:1, read `raw/dlc01/`.
- This is the **Xbox** DLC build. Values here are the DLC's authored defaults but
  were never shipped on PC retail; cross-check the base corpus for shared modules.

## Regenerating

```
python tools/decompile_dlc_lua.py     # retail (raw + cleaned) + prototype
python tools/_verify_cleanup.py        # faithfulness gate for the cleanup pass
```

`decompile_dlc_lua.py` re-extracts the STFS DOH from the RAR (cached at
`output/_scratch/dlc_doh/dlc.doh`), re-splits block 464, runs unluac into
`raw/dlc01/`, applies `lua_unluac_cleanup.cleanup` into `src/dlc01/`, and pulls the
unstripped prototype scripts into `src/dlctest01/`.
