# Lua forensics — closed loose ends (appendix)

**Status:** current · **Evidence:** proven · **Date:** 2026-10-03

Companion to the two bigger write-ups from this pass:
- [`_ps3_base_game_lua_diff.md`](_ps3_base_game_lua_diff.md) — PS3 vz.wad vs Xbox vz.wad.
- [`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md) —
  rebuilding the 89-chunk divergence count into 9 real divergences.

This file collects the five smaller loose ends that didn't need their own doc.

---

## A. `french.luac` boot trace (Xbox-only Lua chunk)

**Question:** what loads `french.luac` on Xbox, and why doesn't PC ship it?

**Finding:** `french.luac` is a **pure data script** — identical structure to
`english.luac` (both ship `vo_asset_table` of 179 `{name, type}` entries covering every VO
soundbank, sounddb and wavebank), differing only in a single line:

```lua
AddLocalizedAsset(".english")  -- in english.luac
AddLocalizedAsset(".french")   -- in french.luac
```

`AddLocalizedAsset` is an **engine-side Lua binding** (not script-defined); the chunk's
loader is **native language-mount code**, not Lua. On Xbox, when system language = French,
the engine mounts `French.wad`; its `resident_P000_Q3` block contains `french.luac`, which
runs at mount and registers 179 VO assets under the `.french` suffix. On PC, Pandemic shipped
no `French.wad` — French is unavailable at the engine level and there is no Lua chunk to
run.

**Fix-pack implication:** adding French to PC = ship a `French.wad` whose
`resident_P000_Q3` carries a compiled `french.luac` with 179 soundbank entries + the
`.french` AddLocalizedAsset call, plus the matching VO wave assets. The Lua side is trivial;
the asset side is the work.

---

## B. `vz_guilayouts` block — full 4-chunk diff

**Question:** we knew `mrxguisatellitelayout` was PC-broken; are the other three
guilayouts chunks fine?

**Finding:** 3 of 4 are structurally and byte-equivalent across PC and Xbox:

| chunk | PC protos / insns | Xbox protos / insns | Jaccard | Verdict |
|---|---|---|---:|---|
| `mrxguihudlayout2` | 2 / 8,415 | 2 / 8,415 | **1.000** | BYTE ≡ |
| `mrxguibinocularslayout` | 2 / 2,951 | 2 / 2,951 | **1.000** | BYTE ≡ |
| `mrxguipdalayout` | 2 / 124 | 2 / 124 | **1.000** | BYTE ≡ |
| `mrxguisatellitelayout` | 2 / 1,624 | 2 / 1,624 | 0.970 | **ONE CONST DIFF** |

**The `mrxguisatellitelayout` divergence is precisely one texture reference:**

| | PC | Xbox |
|---|---|---|
| String | `Pistol` | `icon_hijack_button_A` |
| Full path | `D:/projects/Branches/Snapshot/Data/Src/Map/GLOBAL/HUD/TEXTURES/buttons/Pistol.tga` | `D:/projects/Branches/Snapshot/Data/Src/Map/GLOBAL/HUD/TEXTURES/buttons/icon_hijack_button_A.tga` |
| Extra numeric | — | `0.5` |

**Interpretation:** the satellite / strategic view renders a prompt for triggering a hijack
action against a highlighted target. On Xbox the prompt is the controller **A-button
glyph** (`icon_hijack_button_A.tga`). On PC the texture reference was never updated and
accidentally points at `Pistol.tga` — a placeholder that ships as a visible rendering bug.
Xbox also shipped an extra `0.5` numeric constant used to position/scale the icon.

**Fix-pack scope:** patch the PC `mrxguisatellitelayout` chunk to reference the
hijack-button texture and add the `0.5` positioning constant. Two options: ship an
`English-patch.wad` (per the [patch route in CLAUDE.md](../CLAUDE.md)) with the recompiled
layout, or author a PC-appropriate glyph if the KBM equivalent is desired.

**Decompiled sources:** `docs/mercs2-luacd/src/vz_guilayouts/mrxguisatellitelayout.lua` (PC)
and `docs/mercs2-luacd-xbox/src/vz_guilayouts/mrxguisatellitelayout.lua` (Xbox).

---

## C. The 7 "cut-contract" reserved names — only 1 is actually engine-wired

**Question:** the parity reference §7b.6 lists 7 cut-contract names
(`AllCon009`, `ChiCon005`, `GurCon051`, `PmcCon011`, `PmcCon012`, `PmcCon014`, `PmcCon017`)
as "referenced by PC + PS3 engine binaries". Cross-reference for mod-injection safety.

**Finding — six of seven are plain numbering gaps, not engine-reserved slots.**

| Contract | WifMissionFlow state entries | ASET terrain geometry | Lua body shipped | Engine wiring |
|---|---|---|---|---|
| `ChiCon005` | **3** (`Vz_State_ChiCon005_a/b/c_Pristine`) | **12 blocks** in both PC and PS3 `vz.wad` (`vz_state_chicon005_*_pristine_tinygeometry_*`) | ❌ | **Full map + state slot pre-wired** |
| `AllCon009` | — | — | ❌ | None found |
| `GurCon051` | — | — | ❌ | None found |
| `PmcCon011` | — | — | ❌ | None found |
| `PmcCon012` | — | — | ❌ | None found |
| `PmcCon014` | — | — | ❌ | None found (documented as "gap in numbering" in `docs/contract_analysis_pmc_jet_mec.md`) |
| `PmcCon017` | — | — | ❌ | Same |

**Impact on mod injection:**

- **`ChiCon005` is the real cut-mission slot.** Author a Lua mission script with that name
  and the engine already has terrain-state tracking for its 3 pristine sub-areas AND state
  entries in the WifMissionFlow table (which drives the per-map "pristine → ruined" overlay
  system). Save-file persistence for its state slots is free.
- **The other 6 are numbering gaps.** Mod injection against those names is safe
  (collision-free), but you get **no free engine hooks** — no map state, no WifMissionFlow
  entries, no ASET backing. You'd need to also author the terrain patches, state entries,
  and whatever else your mission needs.

**Correction to parity reference §7b.6**: the "all 7 are engine-reachable" claim is
overstated. Only ChiCon005 is engine-reachable with free hooks. The other 6 are free of
collision only.

**Searched sources (all negative for the 6 numbering-gap names):**
- `docs/mercs2-luacd/src/**` (PC Lua corpus)
- `docs/mercs2-luacd-xbox/src/**` (Xbox Lua corpus)
- `output/_ghidra/mercs2_unpacked.exe_decomp.txt` (PC Ghidra decomp, 27k fns)
- `docs/data/aset_discovered_names.json` + `aset_external_names.csv` (ASET name tables)

---

## D. PC `technov.lua` subtitle outlier — not a bug

**Question:** PC `vz_subtitles/technov.lua` is 34 B, flagged as "tiny" in the completion
manifest. Is it a stub placeholder or an extraction artefact?

**Finding:** both platforms ship the same 2-line placeholder:

```lua
Type = "Time"
SubtitleData = {}
```

The Xbox decompile adds a few redundant local-var intermediates (`L0_1 = "Time"; Type = L0_1;
L0_1 = {}; SubtitleData = L0_1`), explaining the different byte count after decompile. Both
compile from a semantically-identical source: a subtitle registration record with no entries.

**Interpretation:** the `technov` cutscene has **no spoken dialogue** — it's set to the
"Time" subtitle regime (ticked by in-game time, not VO lines) with an empty
`SubtitleData = {}`. Shipping the stub keeps the subtitle registry's membership consistent
across all cutscenes even for silent ones.

**Not a bug, not a divergence.** Completion-manifest line can be de-flagged.

---

## E. Xbox Profile devkit Lua — BLOCKED on content

**Question:** compare Profile devkit Lua to Xbox Final / Retail.

**Finding:** the engine atlas uses the Profile devkit **XEX binary** (`output/_ghidra_x360/`)
for symbol/offset cross-referencing — but no Profile devkit **WAD files** are on disk under
`game-files/`. The devkit extraction we have is PE-only.

**To close this loose end:** extract the Profile devkit's `vz.wad` / `shell.wad` /
per-language WADs from the devkit disc image (if we obtain one), then re-run
`lua_chunk_scan --wad <profile-vz.wad>` + the structural-pair comparison described in
[`_pc_xbox_resident_divergence_characterization.md`](_pc_xbox_resident_divergence_characterization.md)
to classify any Profile-specific Lua divergence.

Expected finding (not yet verified): Profile devkit likely ships Lua chunks with the SAME
code graph as Final/Retail but with **debug info and ASSERTs retained** — essentially the
"non-stripped" version of the console Lua, bridging the gap between the PC debug-rich build
and the console retail-stripped builds.
