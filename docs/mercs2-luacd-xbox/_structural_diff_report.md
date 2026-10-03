# Mercenaries 2 — Lua bytecode PC Retail vs Xbox 360 structural diff

Produced from the output of `tools/wad_simulator/crates/mercs2_probe/src/bin/lua_structural_dump.rs`
run over every paired bytecode file under `output/analysis/cross_platform/scripts_{vz,resident,
shell}_comparison/`. Each pair's structural JSON (header + per-proto constants / globals / call
targets / child protos) was compared with a classifier that normalises the three known baseline
deltas — endian byte, `source_name`, and stripped upvalue names — plus Lua-compiler artefacts that
shift when any instruction is stripped (the `@pcN` suffix on backward-walked call targets, and the
`U[idx]` fallback for upvalue names on the Xbox stripped-debug side).

## Summary — Phase 1 (three big host blocks: `resident`, `shell`, `vz`)

**A combined Phase 1 + Phase 2 totals table lives at the end of the Phase 2 section below. This
Phase 1 table is preserved verbatim so the historical count is readable.** Phase 2 (gap-closure
corpus: missions, hijacks, subtitles, guilayouts, loading, english) added 293 pairs; see the
Phase 2 section at the end.

| Category | Count | Share |
|---|---:|---:|
| IDENTICAL-MODULO-DUMP-FLAGS | 192 | 50.8% |
| DEBUG-SOURCE-STRIPPED       | 98 | 25.9% |
| REAL-DIVERGENCE             | 88 | 23.3% |
| PARSE-FAIL                  | 0 | 0.0% |
| **TOTAL pairs**             | **378** | |
| PC-only (no Xbox pair)      | 4 | — |

**Reader's takeaway for mod portability.** Roughly half of base-game Lua is bit-equivalent across
PC and Xbox once dump flags are normalised. Another quarter differs **only** by Debug/ASSERT
stripping — porting a mod that patches these scripts is safe as long as the mod does not depend on
`Debug.*` or `ASSERT` being resident (they aren't on Xbox). The remaining quarter has real logic
divergence: an Xbox-only string literal, a global reference removed, a function body deleted
entirely. These are the pairs where a cross-platform mod needs a per-platform build.

## Classification method

Each pair's two JSONs are walked in lock-step through the full proto tree (`main`, recursively via
`child_protos`). Per proto we compare `num_instructions`, `num_params`, `num_upvalues`, `is_vararg`,
`max_stack`, `constants[]`, `globals_accessed[]`, `call_targets[]`, `child_protos[]`. The rules:

- **IDENTICAL-MODULO-DUMP-FLAGS** — every proto's fields are equal after normalising the known
  baseline (endian, `source_name`, upvalue names). Includes the SIZE-ONLY-STRIP case: Xbox smaller
  by exactly the stripped-debug fingerprint with no behavioural delta.
- **DEBUG-SOURCE-STRIPPED** — Xbox never ADDS a constant, global, or call target (multiset check:
  `multiset(xb) - multiset(pc)` is empty on all three lists), and every item PC has but Xbox
  lacks is Debug-shaped: a `Debug`/`ASSERT` global, a `Debug.Printf`-style method or
  local-GETTABLE call, or — inside a proto that also removed a `Debug` global — a co-removed
  helper such as `tostring`/`type`/`print` or a format-string literal. Multiset (not subsequence)
  because debug-strip changes the K-pool first-encounter order of constants that are ALSO used
  outside the stripped Debug lines (classically `tostring`), which otherwise looks like a reorder.
- **REAL-DIVERGENCE** — anything else: proto-count differs; a non-Debug global/call is removed;
  Xbox has added a constant/global/call; `max_stack` or `num_instructions` grows on Xbox.

## Top-10 REAL-DIVERGENCE findings

The pairs most likely to bite a mod author porting between platforms.

### 1. `resident+shell/mrxguishell.luac` — PC 40,531 B, Xbox 17,553 B (Δ -22,978)

PC has 59 protos, Xbox has 37 — 22 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

(Also present in `shell` with the SAME bytecode — the shell overlay ships a copy of this resident GUI script.)

### 2. `resident/mrxguipausescreen.luac` — PC 28,712 B, Xbox 12,922 B (Δ -15,790)

PC has 49 protos, Xbox has 20 — 29 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

### 3. `resident+shell/mrxguibase.luac` — PC 88,097 B, Xbox 51,642 B (Δ -36,455)

PC has 184 protos, Xbox has 183 — 1 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

(Also present in `shell` with the SAME bytecode — the shell overlay ships a copy of this resident GUI script.)

### 4. `resident/mrxguipda.luac` — PC 75,084 B, Xbox 42,247 B (Δ -32,837)

PC has 83 protos, Xbox has 81 — 2 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

### 5. `resident+shell/mrxguidialogbox.luac` — PC 38,860 B, Xbox 19,189 B (Δ -19,671)

PC has 32 protos, Xbox has 30 — 2 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

(Also present in `shell` with the SAME bytecode — the shell overlay ships a copy of this resident GUI script.)

### 6. `resident+shell/mrxguinumericbox.luac` — PC 28,678 B, Xbox 10,895 B (Δ -17,783)

PC has 18 protos, Xbox has 15 — 3 nested function body(ies) absent on Xbox, indicating one or more functions were deleted or inlined-out of the source before Xbox compile.

(Also present in `shell` with the SAME bytecode — the shell overlay ships a copy of this resident GUI script.)

### 7. `resident/mrxbriefing.luac` — PC 125,439 B, Xbox 70,636 B (Δ -54,803)

At `main.proto[31]`, PC references global `LTILibName` (via GETGLOBAL) that Xbox does not. The name isn't a Debug/ASSERT helper nor a known debug-coremove, so this is a real code difference — the symbol was removed from the Xbox source.

Accompanying debug-strip signals (consistent with release-mode compile but NOT the only delta): removed-const at `main.proto[1]`; removed-global at `main.proto[1]`; removed-call at `main.proto[1]`.

### 8. `vz/vzacon001.luac` — PC 49,361 B, Xbox 34,111 B (Δ -15,250)

At `main.proto[27]`, Xbox constants pool contains item(s) PC does not have: `string:'[Tutorial.SupportMenu]\n[Tutorial.UseSupport]'`. Constant adds (not just removes) rule out a pure Debug-strip; the Xbox source has a literal that PC's does not.

Accompanying debug-strip signals (consistent with release-mode compile but NOT the only delta): removed-const at `main.proto[3]`; removed-global at `main.proto[3]`; removed-call at `main.proto[3]`.

### 9. `resident/mrxactionhijack.luac` — PC 66,205 B, Xbox 31,318 B (Δ -34,887)

At `main.proto[11]`, PC references global `charGuid` (via GETGLOBAL) that Xbox does not. The name isn't a Debug/ASSERT helper nor a known debug-coremove, so this is a real code difference — the symbol was removed from the Xbox source.

Accompanying debug-strip signals (consistent with release-mode compile but NOT the only delta): removed-const at `main.proto[2]`; removed-global at `main.proto[2]`; removed-call at `main.proto[2]`.

### 10. `vz/wifpmcinterior.luac` — PC 80,025 B, Xbox 49,001 B (Δ -31,024)

At `main.proto[57]`, PC references global `LTILibName` (via GETGLOBAL) that Xbox does not. The name isn't a Debug/ASSERT helper nor a known debug-coremove, so this is a real code difference — the symbol was removed from the Xbox source.

Accompanying debug-strip signals (consistent with release-mode compile but NOT the only delta): removed-const at `main.proto[3]`; removed-global at `main.proto[3]`; removed-call at `main.proto[3]`.


## Spot-check: IDENTICAL-MODULO-DUMP-FLAGS verified

Picking `resident/beacon.luac` (PC 1,082 B, Xbox 789 B) — classified
**IDENTICAL-MODULO-DUMP-FLAGS**. `main.num_upvalues = 0` on PC, so no upvalue-name strings exist to be stripped — this is the irreducible 2-hunk minimum. The `diff -u` of the two structural-dump JSONs
(2 hunk(s)):

```diff
--- pc-retail/beacon.luac
+++ xbox-360/beacon.luac
@@ -1,6 +1,6 @@
 {
   "header": {
-    "endian": "little",
+    "endian": "big",
     "format": 0,
     "instr_size": 4,
     "int_size": 4,
@@ -254,7 +254,7 @@
     "num_instructions": 7,
     "num_params": 0,
     "num_upvalues": 0,
-    "source_name": "beacon"
+    "source_name": null
   },
   "path": "beacon.luac"
 }
```

This is the baseline-only diff: `path`, `endian`, `source_name` (PC keeps the module name, Xbox
has had the debug string stripped to `null`), plus any upvalue-name strings in the proto tree. No
instruction count, no constant, no global, no call target differs — the two platforms were
compiled from the same source with the same compiler, differing only in `luaU_dump` flags.


## PC-only pairs (no Xbox counterpart)

These scripts exist only in the PC build:

| Group | Script |
|---|---|
| resident | `mrxguiltiprecache.luac` |
| resident | `mrxguiltiprecachelayout.luac` |
| shell | `mrxguiltiprecache.luac` |
| shell | `mrxguiltiprecachelayout.luac` |

The two `mrxguiltiprecache*` files are the loading-tip precache screen; the Xbox UI pipeline uses a
different code path entirely, so neither was shipped. (The resident and shell groups each hold both
files because the shell overlay ships a copy of the resident GUI set.)

## Parse failures

None — all 378 pairs parsed cleanly on both platforms.

## Full classification table (378 pairs)

| Group | Script | PC bytes | Xbox bytes | Δ bytes | Category |
|---|---|---:|---:|---:|---|
| resident | `Init.luac` | 1,094 | 805 | -289 | IDENTICAL |
| resident | `Multi.luac` | 1,939 | 731 | -1,208 | DEBUG-STRIP |
| resident | `airplane.luac` | 552 | 345 | -207 | IDENTICAL |
| resident | `airstrike_atomsphere_bombrun.luac` | 2,520 | 1,677 | -843 | IDENTICAL |
| resident | `airstrike_atomsphere_carpetbomb.luac` | 2,441 | 1,639 | -802 | IDENTICAL |
| resident | `airstrike_atomsphere_clusterbomb.luac` | 2,519 | 1,672 | -847 | IDENTICAL |
| resident | `airstrike_atomsphere_daisycutter.luac` | 2,639 | 1,764 | -875 | IDENTICAL |
| resident | `airstrike_atomsphere_fuelairbomb.luac` | 2,634 | 1,759 | -875 | IDENTICAL |
| resident | `airstrike_atomsphere_moab.luac` | 2,632 | 1,764 | -868 | IDENTICAL |
| resident | `airstrike_atomsphere_tactnuke.luac` | 2,631 | 1,759 | -872 | IDENTICAL |
| resident | `alarm.luac` | 10,314 | 6,413 | -3,901 | REAL |
| resident | `all_debug.luac` | 78 | 64 | -14 | IDENTICAL |
| resident | `all_gui.luac` | 76 | 64 | -12 | IDENTICAL |
| resident | `all_hijack.luac` | 79 | 64 | -15 | IDENTICAL |
| resident | `all_humans.luac` | 79 | 64 | -15 | IDENTICAL |
| resident | `all_objectscript.luac` | 85 | 64 | -21 | IDENTICAL |
| resident | `all_preload.luac` | 80 | 64 | -16 | IDENTICAL |
| resident | `all_sound.luac` | 78 | 64 | -14 | IDENTICAL |
| resident | `all_testscript.luac` | 83 | 64 | -19 | IDENTICAL |
| resident | `all_vehicles.luac` | 81 | 64 | -17 | IDENTICAL |
| resident | `all_weapons.luac` | 80 | 64 | -16 | IDENTICAL |
| resident | `antiair.luac` | 13,853 | 7,900 | -5,953 | REAL |
| resident | `autogunship.luac` | 5,223 | 2,831 | -2,392 | REAL |
| resident | `barbell.luac` | 262 | 171 | -91 | IDENTICAL |
| resident | `beacon.luac` | 1,082 | 789 | -293 | IDENTICAL |
| resident | `bench.luac` | 780 | 502 | -278 | IDENTICAL |
| resident | `binoculars.luac` | 192 | 125 | -67 | IDENTICAL |
| resident | `blippable.luac` | 4,834 | 2,879 | -1,955 | DEBUG-STRIP |
| resident | `bountycopter.luac` | 2,479 | 1,435 | -1,044 | DEBUG-STRIP |
| resident | `collectable.luac` | 1,982 | 1,284 | -698 | IDENTICAL |
| resident | `common_asset.luac` | 81 | 64 | -17 | IDENTICAL |
| resident | `crate.luac` | 2,060 | 1,203 | -857 | IDENTICAL |
| resident | `danceradio.luac` | 3,296 | 2,296 | -1,000 | IDENTICAL |
| resident | `dangerousbuilding.luac` | 16,918 | 9,479 | -7,439 | REAL |
| resident | `despawner.luac` | 191 | 125 | -66 | IDENTICAL |
| resident | `dropoff.luac` | 3,684 | 2,186 | -1,498 | DEBUG-STRIP |
| resident | `emplaced.luac` | 3,237 | 1,993 | -1,244 | DEBUG-STRIP |
| resident | `enemyblippable.luac` | 4,134 | 2,454 | -1,680 | DEBUG-STRIP |
| resident | `factionzone.luac` | 3,914 | 2,445 | -1,469 | IDENTICAL |
| resident | `foodcart.luac` | 190 | 125 | -65 | IDENTICAL |
| resident | `fountain.luac` | 606 | 395 | -211 | IDENTICAL |
| resident | `friendlygate.luac` | 9,671 | 5,832 | -3,839 | IDENTICAL |
| resident | `fueltank.luac` | 1,156 | 714 | -442 | IDENTICAL |
| resident | `gamebootstrap.luac` | 3,657 | 2,175 | -1,482 | REAL |
| resident | `goal.luac` | 2,075 | 1,291 | -784 | DEBUG-STRIP |
| resident | `gurpodium.luac` | 4,584 | 2,912 | -1,672 | DEBUG-STRIP |
| resident | `hackybench.luac` | 240 | 161 | -79 | IDENTICAL |
| resident | `healthpickup.luac` | 81 | 64 | -17 | IDENTICAL |
| resident | `heavymg.luac` | 735 | 510 | -225 | IDENTICAL |
| resident | `helicopter.luac` | 1,041 | 636 | -405 | IDENTICAL |
| resident | `hero.luac` | 18,447 | 9,962 | -8,485 | REAL |
| resident | `hijackcontractmanager.luac` | 873 | 399 | -474 | DEBUG-STRIP |
| resident | `homingmissile.luac` | 1,672 | 1,086 | -586 | IDENTICAL |
| resident | `inheritable.luac` | 1,627 | 1,008 | -619 | IDENTICAL |
| resident | `islandfortress.luac` | 4,303 | 2,444 | -1,859 | DEBUG-STRIP |
| resident | `jammer.luac` | 4,228 | 3,022 | -1,206 | IDENTICAL |
| resident | `laptop.luac` | 4,249 | 2,823 | -1,426 | DEBUG-STRIP |
| resident | `levelbootstrap.luac` | 912 | 497 | -415 | DEBUG-STRIP |
| resident | `lifestyle_oillif001_table.luac` | 1,280 | 613 | -667 | DEBUG-STRIP |
| resident | `livingworldprop.luac` | 296 | 193 | -103 | IDENTICAL |
| resident | `materialanimation_largecanopy01.luac` | 814 | 541 | -273 | IDENTICAL |
| resident | `materialanimation_largecanopy02.luac` | 820 | 547 | -273 | IDENTICAL |
| resident | `materialanimation_treeplaza02.luac` | 810 | 539 | -271 | IDENTICAL |
| resident | `mine.luac` | 3,017 | 1,922 | -1,095 | DEBUG-STRIP |
| resident | `monument.luac` | 190 | 125 | -65 | IDENTICAL |
| resident | `moonpatrol.luac` | 6,507 | 4,208 | -2,299 | IDENTICAL |
| resident | `mrxachievements.luac` | 13,844 | 7,999 | -5,845 | REAL |
| resident | `mrxactionhijack.luac` | 66,205 | 31,318 | -34,887 | REAL |
| resident | `mrxai.luac` | 2,082 | 1,432 | -650 | IDENTICAL |
| resident | `mrxapcdrop.luac` | 5,792 | 3,375 | -2,417 | DEBUG-STRIP |
| resident | `mrxartillery.luac` | 3,947 | 2,532 | -1,415 | IDENTICAL |
| resident | `mrxartilleryattack.luac` | 1,787 | 893 | -894 | IDENTICAL |
| resident | `mrxboatdelivery.luac` | 732 | 499 | -233 | IDENTICAL |
| resident | `mrxbombingrun.luac` | 3,241 | 1,897 | -1,344 | DEBUG-STRIP |
| resident | `mrxbootstrap.luac` | 5,511 | 3,701 | -1,810 | DEBUG-STRIP |
| resident | `mrxbriefing.luac` | 125,439 | 70,636 | -54,803 | REAL |
| resident | `mrxbunkerbuster.luac` | 6,182 | 3,368 | -2,814 | REAL |
| resident | `mrxcarpetbomb.luac` | 3,643 | 2,337 | -1,306 | IDENTICAL |
| resident | `mrxcheatbootstrap.luac` | 16,718 | 10,384 | -6,334 | IDENTICAL |
| resident | `mrxchicon001rescue.luac` | 5,824 | 3,257 | -2,567 | REAL |
| resident | `mrxcinematic.luac` | 1,039 | 622 | -417 | IDENTICAL |
| resident | `mrxclusterbomb.luac` | 4,001 | 2,388 | -1,613 | IDENTICAL |
| resident | `mrxcombatairpatrol.luac` | 4,363 | 2,462 | -1,901 | REAL |
| resident | `mrxcoop.luac` | 6,376 | 3,588 | -2,788 | IDENTICAL |
| resident | `mrxcopterdrop.luac` | 4,479 | 2,475 | -2,004 | DEBUG-STRIP |
| resident | `mrxcratedelivery.luac` | 970 | 700 | -270 | IDENTICAL |
| resident | `mrxcruisemissile.luac` | 4,875 | 2,749 | -2,126 | DEBUG-STRIP |
| resident | `mrxdaisycutter.luac` | 4,102 | 2,364 | -1,738 | DEBUG-STRIP |
| resident | `mrxfactionmanager.luac` | 64,653 | 37,809 | -26,844 | REAL |
| resident | `mrxfollow.luac` | 10,448 | 6,136 | -4,312 | REAL |
| resident | `mrxfuelairbomb.luac` | 6,517 | 3,609 | -2,908 | IDENTICAL |
| resident | `mrxgui.luac` | 16,772 | 10,953 | -5,819 | REAL |
| resident | `mrxguiattractlayout.luac` | 1,816 | 1,200 | -616 | IDENTICAL |
| resident | `mrxguiattractmode.luac` | 3,828 | 2,367 | -1,461 | DEBUG-STRIP |
| resident | `mrxguibase.luac` | 88,097 | 51,642 | -36,455 | REAL |
| resident | `mrxguibinoculars.luac` | 10,656 | 6,075 | -4,581 | IDENTICAL |
| resident | `mrxguibootstrap.luac` | 2,328 | 1,697 | -631 | IDENTICAL |
| resident | `mrxguicinematic.luac` | 20,321 | 11,370 | -8,951 | DEBUG-STRIP |
| resident | `mrxguicinematiclayout.luac` | 3,311 | 2,145 | -1,166 | IDENTICAL |
| resident | `mrxguidialogbox.luac` | 38,860 | 19,189 | -19,671 | REAL |
| resident | `mrxguigarage.luac` | 8,484 | 5,362 | -3,122 | IDENTICAL |
| resident | `mrxguihudactionhijack.luac` | 17,574 | 8,049 | -9,525 | REAL |
| resident | `mrxguihudammocountersnew.luac` | 23,108 | 14,927 | -8,181 | IDENTICAL |
| resident | `mrxguihuddamageindicator.luac` | 3,631 | 2,135 | -1,496 | IDENTICAL |
| resident | `mrxguihudfactionbuffer.luac` | 10,635 | 5,944 | -4,691 | DEBUG-STRIP |
| resident | `mrxguihudfactiongauge.luac` | 27,047 | 15,218 | -11,829 | REAL |
| resident | `mrxguihudhealthcounter.luac` | 16,542 | 9,478 | -7,064 | DEBUG-STRIP |
| resident | `mrxguihudmelee.luac` | 3,452 | 2,141 | -1,311 | IDENTICAL |
| resident | `mrxguihudmessage.luac` | 45,957 | 29,148 | -16,809 | REAL |
| resident | `mrxguihudobjectivetray.luac` | 6,883 | 3,936 | -2,947 | IDENTICAL |
| resident | `mrxguihudradar.luac` | 11,163 | 7,155 | -4,008 | IDENTICAL |
| resident | `mrxguihudresourcecounter.luac` | 19,581 | 12,596 | -6,985 | IDENTICAL |
| resident | `mrxguihudreticle.luac` | 23,685 | 14,476 | -9,209 | IDENTICAL |
| resident | `mrxguihudsupportmenu.luac` | 86,499 | 50,970 | -35,529 | DEBUG-STRIP |
| resident | `mrxguihudvehicledisguise.luac` | 12,174 | 7,493 | -4,681 | IDENTICAL |
| resident | `mrxguiinterface.luac` | 78,953 | 44,584 | -34,369 | DEBUG-STRIP |
| resident | `mrxguiloadlayout.luac` | 2,249 | 1,516 | -733 | IDENTICAL |
| resident | `mrxguiloadscreen.luac` | 7,525 | 4,891 | -2,634 | IDENTICAL |
| resident | `mrxguimanager.luac` | 15,062 | 8,930 | -6,132 | REAL |
| resident | `mrxguinumericbox.luac` | 28,678 | 10,895 | -17,783 | REAL |
| resident | `mrxguipauselayout.luac` | 1,690 | 1,148 | -542 | IDENTICAL |
| resident | `mrxguipausescreen.luac` | 28,712 | 12,922 | -15,790 | REAL |
| resident | `mrxguipda.luac` | 75,084 | 42,247 | -32,837 | REAL |
| resident | `mrxguisatellite.luac` | 39,356 | 23,835 | -15,521 | DEBUG-STRIP |
| resident | `mrxguishell.luac` | 40,531 | 17,553 | -22,978 | REAL |
| resident | `mrxguishellbootstrap.luac` | 6,723 | 3,788 | -2,935 | REAL |
| resident | `mrxguishelllayout.luac` | 2,595 | 1,777 | -818 | IDENTICAL |
| resident | `mrxguisniperscope.luac` | 11,383 | 6,771 | -4,612 | IDENTICAL |
| resident | `mrxguisupportshop.luac` | 17,804 | 10,227 | -7,577 | REAL |
| resident | `mrxguitextbuffer.luac` | 27,095 | 15,559 | -11,536 | IDENTICAL |
| resident | `mrxguitutorial.luac` | 18,874 | 10,280 | -8,594 | IDENTICAL |
| resident | `mrxgunship.luac` | 5,682 | 3,195 | -2,487 | IDENTICAL |
| resident | `mrxharmstrike.luac` | 4,434 | 2,336 | -2,098 | DEBUG-STRIP |
| resident | `mrxhq.luac` | 32,242 | 19,451 | -12,791 | REAL |
| resident | `mrxhqmanager.luac` | 8,990 | 4,192 | -4,798 | REAL |
| resident | `mrxlaserguidedbomb.luac` | 4,495 | 2,881 | -1,614 | IDENTICAL |
| resident | `mrxlayermanager.luac` | 16,747 | 6,978 | -9,769 | REAL |
| resident | `mrxmissionboundary.luac` | 9,549 | 6,040 | -3,509 | IDENTICAL |
| resident | `mrxmissionflow.luac` | 41,760 | 23,453 | -18,307 | REAL |
| resident | `mrxmoab.luac` | 1,227 | 805 | -422 | IDENTICAL |
| resident | `mrxmultipagemenu.luac` | 4,760 | 2,690 | -2,070 | REAL |
| resident | `mrxmunitionspickup.luac` | 10,174 | 6,140 | -4,034 | REAL |
| resident | `mrxmusic.luac` | 23,914 | 14,326 | -9,588 | REAL |
| resident | `mrxoilcon002delivery.luac` | 7,148 | 3,715 | -3,433 | REAL |
| resident | `mrxoutpostmanager.luac` | 1,774 | 1,034 | -740 | DEBUG-STRIP |
| resident | `mrxparkinglotmanager.luac` | 8,439 | 5,390 | -3,049 | DEBUG-STRIP |
| resident | `mrxplayer.luac` | 36,788 | 20,509 | -16,279 | REAL |
| resident | `mrxplaystate.luac` | 5,056 | 3,043 | -2,013 | REAL |
| resident | `mrxpmc.luac` | 20,270 | 11,702 | -8,568 | REAL |
| resident | `mrxrewarddata.luac` | 46,090 | 27,057 | -19,033 | REAL |
| resident | `mrxrocketartillery.luac` | 3,813 | 2,223 | -1,590 | IDENTICAL |
| resident | `mrxsatclusterbomb.luac` | 4,041 | 2,313 | -1,728 | IDENTICAL |
| resident | `mrxsatelliteguidedbomb.luac` | 4,092 | 2,482 | -1,610 | DEBUG-STRIP |
| resident | `mrxshootinggallery.luac` | 9,729 | 5,235 | -4,494 | REAL |
| resident | `mrxshop.luac` | 14,499 | 7,077 | -7,422 | DEBUG-STRIP |
| resident | `mrxsmartbomb.luac` | 3,492 | 2,147 | -1,345 | DEBUG-STRIP |
| resident | `mrxsoldierdelivery.luac` | 8,194 | 5,091 | -3,103 | REAL |
| resident | `mrxsound.luac` | 8,796 | 6,631 | -2,165 | DEBUG-STRIP |
| resident | `mrxsoundbanks.luac` | 7,873 | 4,681 | -3,192 | REAL |
| resident | `mrxsoundbootstrap.luac` | 18,909 | 12,331 | -6,578 | DEBUG-STRIP |
| resident | `mrxsoundcategories.luac` | 3,378 | 1,999 | -1,379 | IDENTICAL |
| resident | `mrxstarter.luac` | 22,414 | 12,840 | -9,574 | REAL |
| resident | `mrxstartermanager.luac` | 5,779 | 3,092 | -2,687 | DEBUG-STRIP |
| resident | `mrxstate.luac` | 16,035 | 8,667 | -7,368 | REAL |
| resident | `mrxstatsmanager.luac` | 29,522 | 15,740 | -13,782 | IDENTICAL |
| resident | `mrxstrategicmissile.luac` | 4,827 | 2,651 | -2,176 | DEBUG-STRIP |
| resident | `mrxsubtitle.luac` | 1,640 | 937 | -703 | IDENTICAL |
| resident | `mrxsupport.luac` | 29,710 | 18,690 | -11,020 | REAL |
| resident | `mrxsupportcopterdelivery.luac` | 6,794 | 4,258 | -2,536 | DEBUG-STRIP |
| resident | `mrxsupportdata.luac` | 69,754 | 45,864 | -23,890 | DEBUG-STRIP |
| resident | `mrxsupportdelivery.luac` | 9,420 | 5,768 | -3,652 | DEBUG-STRIP |
| resident | `mrxsupportdesignator.luac` | 10,972 | 6,726 | -4,246 | DEBUG-STRIP |
| resident | `mrxsupportdesignatorbeacon.luac` | 873 | 625 | -248 | IDENTICAL |
| resident | `mrxsupportdesignatorflare.luac` | 1,849 | 1,340 | -509 | IDENTICAL |
| resident | `mrxsupportdesignatorlaser.luac` | 2,812 | 1,982 | -830 | IDENTICAL |
| resident | `mrxsupportdesignatorsatellite.luac` | 6,503 | 4,492 | -2,011 | IDENTICAL |
| resident | `mrxsupportdesignatorsmoke.luac` | 5,716 | 3,964 | -1,752 | DEBUG-STRIP |
| resident | `mrxsupportmanager.luac` | 15,472 | 9,295 | -6,177 | DEBUG-STRIP |
| resident | `mrxsupportpickup.luac` | 11,788 | 8,138 | -3,650 | IDENTICAL |
| resident | `mrxsupporttransit.luac` | 21,338 | 13,307 | -8,031 | DEBUG-STRIP |
| resident | `mrxsurgicalstrike.luac` | 4,004 | 2,498 | -1,506 | IDENTICAL |
| resident | `mrxtankbuster.luac` | 4,607 | 2,663 | -1,944 | DEBUG-STRIP |
| resident | `mrxtask.luac` | 17,987 | 9,162 | -8,825 | REAL |
| resident | `mrxtaskcontract.luac` | 20,080 | 11,937 | -8,143 | REAL |
| resident | `mrxtaskcontractoutpost.luac` | 9,150 | 6,253 | -2,897 | DEBUG-STRIP |
| resident | `mrxtaskcontractplaceholder.luac` | 573 | 429 | -144 | IDENTICAL |
| resident | `mrxtaskjob.luac` | 17,200 | 9,701 | -7,499 | DEBUG-STRIP |
| resident | `mrxtaskjobcollecttype.luac` | 4,127 | 2,625 | -1,502 | IDENTICAL |
| resident | `mrxtaskjobdestroyset.luac` | 4,162 | 2,904 | -1,258 | IDENTICAL |
| resident | `mrxtaskjobdestroytype.luac` | 2,403 | 1,681 | -722 | IDENTICAL |
| resident | `mrxtaskjobverifyset.luac` | 6,769 | 4,642 | -2,127 | IDENTICAL |
| resident | `mrxtaskmission.luac` | 4,103 | 2,506 | -1,597 | IDENTICAL |
| resident | `mrxtaskobjective.luac` | 30,723 | 18,036 | -12,687 | REAL |
| resident | `mrxtaskobjectiveaccept.luac` | 1,536 | 912 | -624 | DEBUG-STRIP |
| resident | `mrxtaskobjectiveaction.luac` | 3,954 | 2,417 | -1,537 | DEBUG-STRIP |
| resident | `mrxtaskobjectivecaptureoutpost.luac` | 2,324 | 1,632 | -692 | IDENTICAL |
| resident | `mrxtaskobjectivedeliver.luac` | 26,964 | 16,638 | -10,326 | DEBUG-STRIP |
| resident | `mrxtaskobjectivedestroy.luac` | 3,175 | 2,048 | -1,127 | DEBUG-STRIP |
| resident | `mrxtaskobjectiveentervehicle.luac` | 5,507 | 3,327 | -2,180 | DEBUG-STRIP |
| resident | `mrxtaskobjectiveextract.luac` | 8,319 | 5,313 | -3,006 | DEBUG-STRIP |
| resident | `mrxtaskobjectiveprotect.luac` | 2,641 | 1,692 | -949 | DEBUG-STRIP |
| resident | `mrxtaskobjectiverelease.luac` | 4,741 | 2,813 | -1,928 | DEBUG-STRIP |
| resident | `mrxtaskobjectiveverify.luac` | 29,977 | 19,253 | -10,724 | DEBUG-STRIP |
| resident | `mrxtaskrace.luac` | 13,284 | 8,542 | -4,742 | DEBUG-STRIP |
| resident | `mrxtaskstate.luac` | 967 | 655 | -312 | DEBUG-STRIP |
| resident | `mrxtimer.luac` | 5,530 | 3,541 | -1,989 | IDENTICAL |
| resident | `mrxtransit.luac` | 17,639 | 9,934 | -7,705 | REAL |
| resident | `mrxtutorial.luac` | 3,007 | 1,836 | -1,171 | IDENTICAL |
| resident | `mrxtutorialmanager.luac` | 8,046 | 4,962 | -3,084 | DEBUG-STRIP |
| resident | `mrxunlockfanfare.luac` | 6,439 | 3,942 | -2,497 | DEBUG-STRIP |
| resident | `mrxutil.luac` | 43,973 | 22,880 | -21,093 | REAL |
| resident | `mrxutil_shell.luac` | 1,255 | 632 | -623 | IDENTICAL |
| resident | `mrxverifymanager.luac` | 15,756 | 9,524 | -6,232 | DEBUG-STRIP |
| resident | `mrxvosequence.luac` | 10,450 | 5,019 | -5,431 | REAL |
| resident | `munitions.luac` | 27,869 | 17,468 | -10,401 | REAL |
| resident | `oilrig.luac` | 13,098 | 8,514 | -4,584 | DEBUG-STRIP |
| resident | `opentankhatch.luac` | 421 | 273 | -148 | IDENTICAL |
| resident | `orientedblippable.luac` | 1,381 | 862 | -519 | DEBUG-STRIP |
| resident | `outhouse.luac` | 190 | 125 | -65 | IDENTICAL |
| resident | `outpost.luac` | 26,484 | 16,779 | -9,705 | DEBUG-STRIP |
| resident | `paradrop.luac` | 3,044 | 1,980 | -1,064 | IDENTICAL |
| resident | `paradroplocation.luac` | 1,148 | 772 | -376 | IDENTICAL |
| resident | `paratrooper.luac` | 1,492 | 1,002 | -490 | IDENTICAL |
| resident | `pmcgate.luac` | 647 | 446 | -201 | IDENTICAL |
| resident | `proximitymine.luac` | 1,859 | 1,264 | -595 | IDENTICAL |
| resident | `pursuitcopter.luac` | 4,741 | 2,682 | -2,059 | REAL |
| resident | `randomlyteleportplayer.luac` | 1,843 | 928 | -915 | DEBUG-STRIP |
| resident | `repairpad.luac` | 1,695 | 1,100 | -595 | IDENTICAL |
| resident | `shootinggallerytarget.luac` | 537 | 323 | -214 | IDENTICAL |
| resident | `soldier.luac` | 2,511 | 1,376 | -1,135 | IDENTICAL |
| resident | `spyhunter.luac` | 12,828 | 8,125 | -4,703 | REAL |
| resident | `supportairplane.luac` | 2,599 | 1,716 | -883 | IDENTICAL |
| resident | `tank.luac` | 1,100 | 630 | -470 | DEBUG-STRIP |
| resident | `telephone.luac` | 191 | 125 | -66 | IDENTICAL |
| resident | `treetrunk.luac` | 790 | 539 | -251 | IDENTICAL |
| resident | `treetrunkpalm.luac` | 893 | 536 | -357 | DEBUG-STRIP |
| resident | `vehicleblippable.luac` | 4,270 | 2,415 | -1,855 | REAL |
| resident | `verify_flash.luac` | 2,232 | 1,499 | -733 | IDENTICAL |
| shell | `mrxgui.luac` | 16,772 | 10,953 | -5,819 | REAL |
| shell | `mrxgui_shellonly.luac` | 10,816 | 7,304 | -3,512 | IDENTICAL |
| shell | `mrxguiattractlayout.luac` | 1,816 | 1,200 | -616 | IDENTICAL |
| shell | `mrxguiattractmode.luac` | 3,828 | 2,367 | -1,461 | DEBUG-STRIP |
| shell | `mrxguibase.luac` | 88,097 | 51,642 | -36,455 | REAL |
| shell | `mrxguibootstrap_shellonly.luac` | 1,758 | 1,265 | -493 | IDENTICAL |
| shell | `mrxguicinematic.luac` | 20,321 | 11,370 | -8,951 | DEBUG-STRIP |
| shell | `mrxguicinematiclayout.luac` | 3,311 | 2,145 | -1,166 | IDENTICAL |
| shell | `mrxguidialogbox.luac` | 38,860 | 19,189 | -19,671 | REAL |
| shell | `mrxguiloadlayout.luac` | 2,249 | 1,516 | -733 | IDENTICAL |
| shell | `mrxguiloadscreen.luac` | 7,525 | 4,891 | -2,634 | IDENTICAL |
| shell | `mrxguimanager.luac` | 15,062 | 8,930 | -6,132 | REAL |
| shell | `mrxguinumericbox.luac` | 28,678 | 10,895 | -17,783 | REAL |
| shell | `mrxguishell.luac` | 40,531 | 17,553 | -22,978 | REAL |
| shell | `mrxguishellbootstrap.luac` | 6,723 | 3,788 | -2,935 | REAL |
| shell | `mrxguishelllayout.luac` | 2,595 | 1,777 | -818 | IDENTICAL |
| shell | `mrxmultipagemenu.luac` | 4,760 | 2,690 | -2,070 | REAL |
| shell | `mrxmusic.luac` | 23,914 | 14,326 | -9,588 | REAL |
| shell | `mrxshellbootstrap.luac` | 1,366 | 974 | -392 | DEBUG-STRIP |
| shell | `mrxsound.luac` | 8,796 | 6,631 | -2,165 | DEBUG-STRIP |
| shell | `mrxsoundbanks.luac` | 7,873 | 4,681 | -3,192 | REAL |
| shell | `mrxsoundcategories.luac` | 3,378 | 1,999 | -1,379 | IDENTICAL |
| shell | `mrxsoundshellbootstrap.luac` | 7,300 | 4,736 | -2,564 | DEBUG-STRIP |
| shell | `mrxutil_shell.luac` | 1,255 | 632 | -623 | IDENTICAL |
| shell | `shell.luac` | 411 | 337 | -74 | IDENTICAL |
| shell | `shellbootstrap.luac` | 5,309 | 2,688 | -2,621 | REAL |
| vz | `allcon001.luac` | 14,633 | 10,116 | -4,517 | DEBUG-STRIP |
| vz | `allcon002.luac` | 41,328 | 25,999 | -15,329 | REAL |
| vz | `allcon003.luac` | 5,786 | 4,382 | -1,404 | IDENTICAL |
| vz | `allcon008.luac` | 7,876 | 5,069 | -2,807 | REAL |
| vz | `allcon050.luac` | 1,344 | 1,153 | -191 | IDENTICAL |
| vz | `allcon052.luac` | 1,134 | 963 | -171 | IDENTICAL |
| vz | `allcon053.luac` | 1,133 | 962 | -171 | IDENTICAL |
| vz | `alljob002.luac` | 4,612 | 3,731 | -881 | IDENTICAL |
| vz | `alljob003.luac` | 435 | 332 | -103 | IDENTICAL |
| vz | `alljob020.luac` | 6,714 | 5,271 | -1,443 | IDENTICAL |
| vz | `chicon001.luac` | 13,548 | 9,276 | -4,272 | REAL |
| vz | `chicon002.luac` | 19,296 | 13,481 | -5,815 | REAL |
| vz | `chicon003.luac` | 7,201 | 5,329 | -1,872 | IDENTICAL |
| vz | `chicon008.luac` | 9,247 | 6,796 | -2,451 | DEBUG-STRIP |
| vz | `chicon009.luac` | 11,838 | 8,568 | -3,270 | DEBUG-STRIP |
| vz | `chicon050.luac` | 1,133 | 962 | -171 | IDENTICAL |
| vz | `chicon051.luac` | 1,344 | 1,153 | -191 | IDENTICAL |
| vz | `chicon053.luac` | 1,331 | 1,144 | -187 | IDENTICAL |
| vz | `chijob002.luac` | 3,700 | 3,049 | -651 | IDENTICAL |
| vz | `chijob003.luac` | 436 | 333 | -103 | IDENTICAL |
| vz | `chijob020.luac` | 3,846 | 3,115 | -731 | IDENTICAL |
| vz | `gurcon001.luac` | 19,862 | 14,074 | -5,788 | REAL |
| vz | `gurcon002.luac` | 37,511 | 25,351 | -12,160 | REAL |
| vz | `gurcon003.luac` | 20,789 | 13,460 | -7,329 | DEBUG-STRIP |
| vz | `gurcon005.luac` | 2,568 | 1,891 | -677 | IDENTICAL |
| vz | `gurcon050.luac` | 884 | 778 | -106 | IDENTICAL |
| vz | `gurcon052.luac` | 939 | 825 | -114 | IDENTICAL |
| vz | `gurcon053.luac` | 2,336 | 1,878 | -458 | IDENTICAL |
| vz | `gurjob001.luac` | 907 | 720 | -187 | IDENTICAL |
| vz | `gurjob002.luac` | 1,956 | 1,268 | -688 | IDENTICAL |
| vz | `gurjob006.luac` | 432 | 329 | -103 | IDENTICAL |
| vz | `gurjob020.luac` | 5,759 | 4,424 | -1,335 | IDENTICAL |
| vz | `jetcon001.luac` | 21,147 | 13,963 | -7,184 | DEBUG-STRIP |
| vz | `meccon001.luac` | 32,405 | 22,754 | -9,651 | DEBUG-STRIP |
| vz | `mecjob.luac` | 14,461 | 9,841 | -4,620 | DEBUG-STRIP |
| vz | `mecjob001.luac` | 983 | 772 | -211 | IDENTICAL |
| vz | `mecjob002.luac` | 701 | 586 | -115 | IDENTICAL |
| vz | `mecjob003.luac` | 1,333 | 1,029 | -304 | IDENTICAL |
| vz | `oilcon001.luac` | 87,130 | 58,463 | -28,667 | DEBUG-STRIP |
| vz | `oilcon002.luac` | 67,552 | 42,292 | -25,260 | REAL |
| vz | `oilcon003.luac` | 17,077 | 11,712 | -5,365 | DEBUG-STRIP |
| vz | `oilcon005.luac` | 7,521 | 4,999 | -2,522 | DEBUG-STRIP |
| vz | `oilcon020.luac` | 35,017 | 23,425 | -11,592 | DEBUG-STRIP |
| vz | `oilcon021.luac` | 22,302 | 15,595 | -6,707 | DEBUG-STRIP |
| vz | `oilcon050.luac` | 2,088 | 1,675 | -413 | IDENTICAL |
| vz | `oilcon051.luac` | 921 | 807 | -114 | IDENTICAL |
| vz | `oilcon052.luac` | 921 | 807 | -114 | IDENTICAL |
| vz | `oiljob004.luac` | 438 | 335 | -103 | IDENTICAL |
| vz | `oiljob008.luac` | 4,681 | 3,858 | -823 | IDENTICAL |
| vz | `oiljob011.luac` | 3,127 | 2,310 | -817 | IDENTICAL |
| vz | `pircon001.luac` | 10,337 | 6,653 | -3,684 | DEBUG-STRIP |
| vz | `pircon002.luac` | 17,341 | 11,680 | -5,661 | DEBUG-STRIP |
| vz | `pircon003.luac` | 25,113 | 17,386 | -7,727 | DEBUG-STRIP |
| vz | `pircon004.luac` | 34,753 | 20,704 | -14,049 | REAL |
| vz | `pircon051.luac` | 939 | 825 | -114 | IDENTICAL |
| vz | `pircon052.luac` | 939 | 825 | -114 | IDENTICAL |
| vz | `pirjob001.luac` | 432 | 329 | -103 | IDENTICAL |
| vz | `pirjob012.luac` | 3,217 | 2,658 | -559 | IDENTICAL |
| vz | `pirjob020.luac` | 4,015 | 3,228 | -787 | IDENTICAL |
| vz | `pmccon001.luac` | 34,490 | 22,337 | -12,153 | REAL |
| vz | `pmccon002.luac` | 13,380 | 9,739 | -3,641 | IDENTICAL |
| vz | `pmccon003.luac` | 43,811 | 26,874 | -16,937 | REAL |
| vz | `pmccon004.luac` | 27,265 | 16,980 | -10,285 | REAL |
| vz | `pmccon013.luac` | 8,283 | 5,524 | -2,759 | DEBUG-STRIP |
| vz | `pmccon015.luac` | 5,830 | 4,165 | -1,665 | DEBUG-STRIP |
| vz | `pmccon016.luac` | 8,488 | 6,264 | -2,224 | DEBUG-STRIP |
| vz | `pmccon018.luac` | 30,755 | 20,102 | -10,653 | REAL |
| vz | `pmccon031.luac` | 43,362 | 31,186 | -12,176 | REAL |
| vz | `pmccon032.luac` | 34,714 | 24,142 | -10,572 | DEBUG-STRIP |
| vz | `pmccon033.luac` | 35,458 | 24,864 | -10,594 | DEBUG-STRIP |
| vz | `pmccon034.luac` | 31,349 | 21,933 | -9,416 | REAL |
| vz | `pmcjob001.luac` | 842 | 582 | -260 | DEBUG-STRIP |
| vz | `stagingact1.luac` | 4,951 | 3,437 | -1,514 | DEBUG-STRIP |
| vz | `vzacon001.luac` | 49,361 | 34,111 | -15,250 | REAL |
| vz | `wifbios.luac` | 3,759 | 2,735 | -1,024 | IDENTICAL |
| vz | `wifbriefingdata.luac` | 167,832 | 93,912 | -73,920 | IDENTICAL |
| vz | `wifcheatstockpile.luac` | 6,693 | 4,195 | -2,498 | IDENTICAL |
| vz | `wifequipmentdata.luac` | 4,923 | 2,956 | -1,967 | IDENTICAL |
| vz | `wiffreeplay.luac` | 3,269 | 2,255 | -1,014 | IDENTICAL |
| vz | `wifhints.luac` | 9,274 | 5,992 | -3,282 | IDENTICAL |
| vz | `wifhqdata.luac` | 10,976 | 8,255 | -2,721 | IDENTICAL |
| vz | `wifmissiondata.luac` | 24,605 | 16,700 | -7,905 | IDENTICAL |
| vz | `wifmissionflow.luac` | 67,605 | 51,449 | -16,156 | IDENTICAL |
| vz | `wifpmcgarage.luac` | 31,225 | 16,396 | -14,829 | REAL |
| vz | `wifpmcinterior.luac` | 80,025 | 49,001 | -31,024 | REAL |
| vz | `wifrecommendationdata.luac` | 5,488 | 3,243 | -2,245 | IDENTICAL |
| vz | `wifstarterdata.luac` | 15,593 | 11,116 | -4,477 | IDENTICAL |
| vz | `wiftutorialairstrikeinterrupt.luac` | 1,816 | 1,378 | -438 | IDENTICAL |
| vz | `wiftutorialalarm.luac` | 534 | 404 | -130 | IDENTICAL |
| vz | `wiftutorialallieshonk.luac` | 2,888 | 1,863 | -1,025 | DEBUG-STRIP |
| vz | `wiftutorialapc.luac` | 996 | 751 | -245 | IDENTICAL |
| vz | `wiftutorialboat.luac` | 1,164 | 754 | -410 | REAL |
| vz | `wiftutorialc4.luac` | 2,285 | 1,526 | -759 | IDENTICAL |
| vz | `wiftutorialc4switch.luac` | 1,052 | 762 | -290 | IDENTICAL |
| vz | `wiftutorialcollateraldamage.luac` | 852 | 609 | -243 | IDENTICAL |
| vz | `wiftutorialcollectibles.luac` | 3,223 | 1,995 | -1,228 | IDENTICAL |
| vz | `wiftutorialcooprevive.luac` | 543 | 408 | -135 | IDENTICAL |
| vz | `wiftutorialcooptether.luac` | 539 | 404 | -135 | IDENTICAL |
| vz | `wiftutorialgatehonk.luac` | 1,236 | 889 | -347 | IDENTICAL |
| vz | `wiftutorialhelicopter.luac` | 1,024 | 772 | -252 | IDENTICAL |
| vz | `wiftutorialhelirepairpad.luac` | 1,035 | 732 | -303 | IDENTICAL |
| vz | `wiftutoriallowfuel.luac` | 537 | 405 | -132 | IDENTICAL |
| vz | `wiftutorialnofuel.luac` | 535 | 404 | -131 | IDENTICAL |
| vz | `wiftutorialswimming.luac` | 1,191 | 845 | -346 | IDENTICAL |
| vz | `wiftutorialtank.luac` | 1,008 | 762 | -246 | IDENTICAL |
| vz | `wiftutorialtankhijack.luac` | 2,065 | 1,188 | -877 | DEBUG-STRIP |
| vz | `wiftutorialtrespass.luac` | 845 | 610 | -235 | IDENTICAL |
| vz | `wiftutorialvehicledisguise.luac` | 4,284 | 2,642 | -1,642 | IDENTICAL |
| vz | `wiftutorialwheeledvehiclebasic.luac` | 1,687 | 1,082 | -605 | REAL |
| vz | `wifvzambience.luac` | 1,859 | 825 | -1,034 | REAL |
| vz | `wifvzatmosphere.luac` | 3,861 | 2,097 | -1,764 | DEBUG-STRIP |
| vz | `wifvzboundary.luac` | 9,826 | 5,946 | -3,880 | REAL |
| vz | `wifvzregionnames.luac` | 7,055 | 4,613 | -2,442 | DEBUG-STRIP |
| vz | `xQ!L.luac` | 38,202 | 29,554 | -8,648 | REAL |

## Caveats

**Regrade — `resident/mrxparkinglotmanager.luac`: REAL → DEBUG-STRIP (human review).**
The classifier flagged this pair REAL because `main.proto[3]` has a removed `GETGLOBAL print`
without a co-removed `Debug`/`ASSERT` global in the same proto — the pattern that normally
indicates real logic divergence. Reading the decompiled source shows the removed call is
`print(" =-= PARKING LOT adding: ", uVehicle)` at the top of `_TrackVehicle`
(`docs/mercs2-luacd/src/resident/mrxparkinglotmanager.lua:42`), a lone diagnostic log in a
function whose body (`ipairs` / `table.remove` / `table.insert` on `_tParkingLotCandidates`) is
otherwise identical on Xbox. The ` =-= ` prefix is the exact convention used by every
`Debug.Printf` call elsewhere in the file (`" =-= _MarkVehicle "`, `" =-= UnmarkVehicle "`,
`"=-= num candidates: "`, `"=-= MOVING VEHICLE "`, …), three of which are co-stripped in protos
4/6/7 of the same file. The call is an author typo — `print` instead of `Debug.Printf` — that
the Xbox release-mode strip caught as diagnostic along with the rest. No logic diverges, only
the log line is gone. Row reclassified to DEBUG-SOURCE-STRIPPED; the summary count updated 97 →
98 DEBUG-STRIP, 89 → 88 REAL.


## Phase 2 — gap-closure corpus (newly-added categories)

A follow-up extraction landed **293 common PC/Xbox pairs** across six categories that Phase 1 did
not touch — mission dialogue spiels, vehicle-hijack sequences, mission subtitles, UI layout tables,
and the top-level `loading.luac` + `english.luac` bootstraps — plus one Xbox-only chunk (`french`).
Classification was run with the same tool (`lua_structural_dump`) and the same classifier
(`scratchpad/classify.py`, unchanged — the Phase 1 debug-strip signature is sufficient for every
new category; a thin wrapper in `scratchpad/classify_phase2.py` only swaps the directory list).

### Phase 2 classification table

| Category | IDENTICAL | DEBUG-STRIP | REAL | PARSE-FAIL | Pairs |
|---|---:|---:|---:|---:|---:|
| missions   | 222 | 0  | 0 | 0 | 222 |
| hijacks    | 2   | 27 | 0 | 0 | 29 |
| subtitles  | 36  | 0  | 0 | 0 | 36 |
| guilayouts | 3   | 0  | 1 | 0 | 4 |
| loading    | 1   | 0  | 0 | 0 | 1 |
| english    | 1   | 0  | 0 | 0 | 1 |
| **TOTAL**  | **265** | **27** | **1** | **0** | **293** |
| PC-only    | — | — | — | — | 0 |
| Xbox-only  | — | — | — | — | 1 (`french/french.luac`) |

(Counts shown are **after** the single Phase 2 regrade below: raw classifier output was 26 DEBUG-STRIP
+ 2 REAL in hijacks; the second REAL — `hijack_mi35_solano.luac` — is reclassified to DEBUG-STRIP on
the same grounds Phase 1 used for `mrxparkinglotmanager.luac`. See *Caveats*.)

**Reader's takeaway.** The gap-closure corpus is **far more homogeneous** than the Phase 1 "three big
host blocks". Three categories are 100% IDENTICAL-MODULO-DUMP-FLAGS — mission spiels (222/222),
subtitles (36/36), and both top-level bootstraps — because they are **data-only tables**: no
`Debug.Printf`, no logic branches to strip, nothing but string / number / bool literals in table
constructors. Any shrink is pure Xbox dump-flag reduction (`source_name` → null, upvalue names
dropped). This is the opposite pattern from `resident/` (which is 24% REAL): mission data **ports
without a per-platform build**. Hijacks are the Phase 2 outlier at 93% DEBUG-STRIP — vehicle-hijack
scripts are heavy on `Debug.Printf` traces; Xbox strips them all, nothing else changes.

### Combined-corpus totals (Phase 1 + Phase 2)

| Category | Phase 1 (378) | Phase 2 (293) | Combined (671) | Share |
|---|---:|---:|---:|---:|
| IDENTICAL-MODULO-DUMP-FLAGS | 192 | 265 | **457** | 68.1% |
| DEBUG-SOURCE-STRIPPED       | 98  | 27  | **125** | 18.6% |
| REAL-DIVERGENCE             | 88  | 1   | **89**  | 13.3% |
| PARSE-FAIL                  | 0   | 0   | **0**   | 0.0% |

The combined corpus roughly doubles our confidence in the Phase 1 reader's takeaway: **about two
thirds of all shipped Lua is byte-equivalent across PC and Xbox once dump flags are normalised**
(up from 51% because Phase 2 is data-table-dominant). About one fifth differs only by Debug/ASSERT
stripping. Only one in seven pairs carries real logic divergence — and all but one of those (88 of
89) live in Phase 1's `resident/shell/vz` host blocks. The gap-closure corpus added almost no new
cross-platform logic divergence: **1 REAL case out of 293 Phase 2 pairs** (0.34%).

### Top findings — Phase 2 REAL-DIVERGENCE

Only two pairs tripped the REAL classifier; after regrade, one survives as real.

#### 1. `guilayouts/mrxguisatellitelayout.luac` — PC 16,974 B, Xbox 10,305 B (Δ -6,669)

**Content divergence, portable to the PC fix-pack.** At `main`, Xbox's constants pool
contains three items PC does not have: the string `"icon_hijack_button_A"`, the
texture path `D:/projects/Branches/Snapshot/Data/Src/Map/GLOBAL/HUD/TEXTURES/buttons/icon_hijack_button_A.tga`,
and the number `0.5`. Reading the decompiled layout
(`docs/mercs2-luacd/src/vz_guilayouts/mrxguisatellitelayout.lua:234–235`) shows the matching PC
constants are `"Pistol"` + `D:/.../buttons/Pistol.tga` on the `satbutton` widget — a leftover
placeholder/wrong icon that the Xbox build fixed to the correct hijack button graphic. The
satellite overlay's prompt widget is literally pointing at a pistol icon on PC and a hijack-A
button icon on Xbox. This is a bug-fix the PC port never received, and the right-icon TGA path is
preserved on the PC retail disc under the same tree — a one-constant patch (string + path)
could replicate the Xbox fix in a `vz-patch.wad` overlay.

#### 2. `hijacks/hijack_mi35_solano.luac` — PC 70,372 B, Xbox 58,223 B (Δ -12,149) → regraded DEBUG-STRIP

Raw classifier output: REAL, with first delta at `main.proto[0]` = removed `GETGLOBAL print`
without a co-removed `Debug`/`ASSERT` in the same proto. Human review (see *Caveats*) reclassifies
this as DEBUG-SOURCE-STRIPPED on the same grounds as the Phase 1 `mrxparkinglotmanager.luac`
regrade — the removed `print` calls are the author's lone diagnostics (`print("Hijack_Mi35_Solano:
Loading vehicle animation assets")` and sibling lines in `Init`/`Deinit`/mount/dismount), stripped
by the same release-mode scrub that stripped the file's many `Debug.Printf` calls (classifier
confirms removed `Debug/Printf/********************* Hijack_Mi35_Solano: ...` in proto 4 and 6).
No logic diverges.

### Notable Phase 2 IDENTICAL-MODULO-DUMP-FLAGS findings

These are not divergences, but they are the big "wait, really 100%?" results worth calling out:

- **`loading/loading.luac` — PC 66,522 B, Xbox 66,362 B (Δ only -160 B).** The near-zero shrink is
  because the file is almost entirely a giant string table (preload tip strings) — practically no
  upvalues or Debug lines to strip. The two platforms ship bit-equivalent loading-tips code.
- **`guilayouts/mrxguihudlayout2.luac` — PC 77,674 B, Xbox 43,813 B (Δ -33,861).** The biggest Phase 2
  size delta that's still IDENTICAL — this is the HUD widget tree, pure table literals. The shrink
  is dominated by stripped upvalue names + the long `D:/projects/Branches/...` source-name header.
- **All 222 mission spiels (`spiel_*.luac`) IDENTICAL.** These are 1-to-3 KB per-NPC/per-mission
  dialogue schedulers, almost entirely table literals and `Pg.Spiel.*` calls — no logic to diverge
  on. Mod ports targeting mission dialogue are **cross-platform-safe without a per-platform build**.
- **All 36 `subtitles_*.luac` IDENTICAL.** Subtitle-cue tables; same reason.

### Platform-only names

**Xbox-only:** `scripts_french_comparison/Xbox 360/bytecode/french.luac` (4,030 B, big-endian,
`source_name = null`, 4 protos, 553 main instructions, 80 main constants). The file is the Xbox
locale pack for French — PC ships French strings via the stringdb route rather than a Lua chunk,
so no PC counterpart exists. Parses cleanly on the Xbox side with the stripped-debug reader.

**PC-only:** none in Phase 2 (every PC file in the six common categories has an Xbox pair).

### Classifier reuse — no extension needed

`scratchpad/classify.py` was reused verbatim. The Phase 1 debug-strip signature (removed-globals
restricted to `{Debug, ASSERT, assert, Printf, Print, Echo, Trace, Log, Dprintf, Warning, Assert}`
plus co-removed helpers `{tostring, print, string, io, type, pairs, ipairs, tonumber, Dprintf}` once
a proto has already shown a `Debug` strip) correctly handled every Phase 2 category, including the
26 hijack scripts with heavy `Debug.Printf` density. The only wrapper
(`scratchpad/classify_phase2.py`) swaps the GROUPS list for the six new comparison roots and adds a
`xb_only` collection path for the French-only chunk; no classifier logic was changed.


### Caveats (Phase 2)

**Regrade — `hijacks/hijack_mi35_solano.luac`: REAL → DEBUG-STRIP (human review).**
Same pattern as the Phase 1 regrade of `resident/mrxparkinglotmanager.luac`. The classifier flagged
this pair REAL because `main.proto[0]` has a removed `GETGLOBAL print` without a co-removed
`Debug`/`ASSERT` global in the *same* proto. Reading the decompiled source
(`docs/mercs2-luacd/src/vz_hijacks/hijack_mi35_solano.lua`) shows the removed calls are a cluster of
bare-`print` diagnostic lines the author wrote instead of `Debug.Printf`:
`print("Hijack_Mi35_Solano: Loading vehicle animation assets")` (line 31),
`print("Hijack_Mi35_Solano: Unloading vehicle animation assets")` (line 61),
`print("Solano MI35: attaching pistol: " .. tostring(bResult) ...)` (line 99),
`print("Solano MI35: attaching ak47: " .. tostring(bResult) ...)` (line 103),
`print("Solano MI35: Player Character: " .. tostring(HeroName))` (line 128),
`print("Solano MI35: OnActionHijackComplete: remove gun: " ...)` (line 1136),
`print("Solano MI35: OnActionHijackComplete: remove ak47: " ...)` (line 1139),
`print("UNGST!!!")` (line 1143),
`print("@@@@@@@@@@ BUNKER DOORS OPENING!!!!!")` (line 1155),
`print("ALL DONE!")` (line 1159).
The naming convention and `=-= / @@@@@` prefix match the file's `Debug.Printf` lines (which the
classifier **did** detect as removed from protos 4 and 6: `Debug / Printf /
"********************* Hijack_Mi35_Solano: Complete event posted"` and `"... Cancel event posted"`).
The Xbox release-mode debug strip caught these bare-`print` diagnostics along with the
`Debug.Printf` cluster. No logic diverges. Row reclassified to DEBUG-SOURCE-STRIPPED; the Phase 2
summary count updated 26 → 27 DEBUG-STRIP, 2 → 1 REAL.

## Phase 2 — full classification table (293 pairs)

| Group | Script | PC bytes | Xbox bytes | Δ bytes | Category |
|---|---|---:|---:|---:|---|
| missions | `spiel_job_all01_chris.luac` | 334 | 264 | -70 | IDENTICAL |
| missions | `spiel_job_all01_jennifer.luac` | 425 | 352 | -73 | IDENTICAL |
| missions | `spiel_job_all01_mattias.luac` | 427 | 355 | -72 | IDENTICAL |
| missions | `spiel_job_all02_chris.luac` | 418 | 348 | -70 | IDENTICAL |
| missions | `spiel_job_all02_jennifer.luac` | 419 | 346 | -73 | IDENTICAL |
| missions | `spiel_job_all02_mattias.luac` | 330 | 258 | -72 | IDENTICAL |
| missions | `spiel_job_all03_chris.luac` | 418 | 348 | -70 | IDENTICAL |
| missions | `spiel_job_all03_jennifer.luac` | 331 | 258 | -73 | IDENTICAL |
| missions | `spiel_job_all03_mattias.luac` | 421 | 349 | -72 | IDENTICAL |
| missions | `spiel_job_all04_chris.luac` | 335 | 265 | -70 | IDENTICAL |
| missions | `spiel_job_all04_jennifer.luac` | 428 | 355 | -73 | IDENTICAL |
| missions | `spiel_job_all04_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_all05_chris.luac` | 335 | 265 | -70 | IDENTICAL |
| missions | `spiel_job_all05_jennifer.luac` | 428 | 355 | -73 | IDENTICAL |
| missions | `spiel_job_all05_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_all06_chris.luac` | 335 | 265 | -70 | IDENTICAL |
| missions | `spiel_job_all06_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_all06_mattias.luac` | 428 | 356 | -72 | IDENTICAL |
| missions | `spiel_job_all07_chris.luac` | 332 | 262 | -70 | IDENTICAL |
| missions | `spiel_job_all07_jennifer.luac` | 423 | 350 | -73 | IDENTICAL |
| missions | `spiel_job_all07_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_all09_chris.luac` | 425 | 355 | -70 | IDENTICAL |
| missions | `spiel_job_all09_jennifer.luac` | 337 | 264 | -73 | IDENTICAL |
| missions | `spiel_job_all09_mattias.luac` | 424 | 352 | -72 | IDENTICAL |
| missions | `spiel_job_chi01_chris.luac` | 420 | 350 | -70 | IDENTICAL |
| missions | `spiel_job_chi01_jennifer.luac` | 333 | 260 | -73 | IDENTICAL |
| missions | `spiel_job_chi01_mattias.luac` | 423 | 351 | -72 | IDENTICAL |
| missions | `spiel_job_chi02_chris.luac` | 329 | 259 | -70 | IDENTICAL |
| missions | `spiel_job_chi02_jennifer.luac` | 420 | 347 | -73 | IDENTICAL |
| missions | `spiel_job_chi02_mattias.luac` | 422 | 350 | -72 | IDENTICAL |
| missions | `spiel_job_chi03_chris.luac` | 329 | 259 | -70 | IDENTICAL |
| missions | `spiel_job_chi03_jennifer.luac` | 420 | 347 | -73 | IDENTICAL |
| missions | `spiel_job_chi03_mattias.luac` | 422 | 350 | -72 | IDENTICAL |
| missions | `spiel_job_chi04_chris.luac` | 419 | 349 | -70 | IDENTICAL |
| missions | `spiel_job_chi04_jennifer.luac` | 332 | 259 | -73 | IDENTICAL |
| missions | `spiel_job_chi04_mattias.luac` | 422 | 350 | -72 | IDENTICAL |
| missions | `spiel_job_chi05_chris.luac` | 420 | 350 | -70 | IDENTICAL |
| missions | `spiel_job_chi05_jennifer.luac` | 332 | 259 | -73 | IDENTICAL |
| missions | `spiel_job_chi05_mattias.luac` | 419 | 347 | -72 | IDENTICAL |
| missions | `spiel_job_chi06_chris.luac` | 457 | 355 | -102 | IDENTICAL |
| missions | `spiel_job_chi06_jennifer.luac` | 551 | 446 | -105 | IDENTICAL |
| missions | `spiel_job_chi06_mattias.luac` | 552 | 448 | -104 | IDENTICAL |
| missions | `spiel_job_chi07_chris.luac` | 329 | 259 | -70 | IDENTICAL |
| missions | `spiel_job_chi07_jennifer.luac` | 422 | 349 | -73 | IDENTICAL |
| missions | `spiel_job_chi07_mattias.luac` | 419 | 347 | -72 | IDENTICAL |
| missions | `spiel_job_chi09_chris.luac` | 425 | 355 | -70 | IDENTICAL |
| missions | `spiel_job_chi09_jennifer.luac` | 427 | 354 | -73 | IDENTICAL |
| missions | `spiel_job_chi09_mattias.luac` | 336 | 264 | -72 | IDENTICAL |
| missions | `spiel_job_gur01_chris.luac` | 330 | 260 | -70 | IDENTICAL |
| missions | `spiel_job_gur01_jennifer.luac` | 421 | 348 | -73 | IDENTICAL |
| missions | `spiel_job_gur01_mattias.luac` | 423 | 351 | -72 | IDENTICAL |
| missions | `spiel_job_gur02_chris.luac` | 588 | 454 | -134 | IDENTICAL |
| missions | `spiel_job_gur02_jennifer.luac` | 687 | 550 | -137 | IDENTICAL |
| missions | `spiel_job_gur02_mattias.luac` | 682 | 546 | -136 | IDENTICAL |
| missions | `spiel_job_gur03_chris.luac` | 549 | 447 | -102 | IDENTICAL |
| missions | `spiel_job_gur03_jennifer.luac` | 553 | 448 | -105 | IDENTICAL |
| missions | `spiel_job_gur03_mattias.luac` | 463 | 359 | -104 | IDENTICAL |
| missions | `spiel_job_gur04_chris.luac` | 421 | 351 | -70 | IDENTICAL |
| missions | `spiel_job_gur04_jennifer.luac` | 334 | 261 | -73 | IDENTICAL |
| missions | `spiel_job_gur04_mattias.luac` | 424 | 352 | -72 | IDENTICAL |
| missions | `spiel_job_gur06_chris.luac` | 422 | 352 | -70 | IDENTICAL |
| missions | `spiel_job_gur06_jennifer.luac` | 334 | 261 | -73 | IDENTICAL |
| missions | `spiel_job_gur06_mattias.luac` | 421 | 349 | -72 | IDENTICAL |
| missions | `spiel_job_gur07_chris.luac` | 422 | 352 | -70 | IDENTICAL |
| missions | `spiel_job_gur07_jennifer.luac` | 424 | 351 | -73 | IDENTICAL |
| missions | `spiel_job_gur07_mattias.luac` | 333 | 261 | -72 | IDENTICAL |
| missions | `spiel_job_gur08_chris.luac` | 422 | 352 | -70 | IDENTICAL |
| missions | `spiel_job_gur08_jennifer.luac` | 424 | 351 | -73 | IDENTICAL |
| missions | `spiel_job_gur08_mattias.luac` | 333 | 261 | -72 | IDENTICAL |
| missions | `spiel_job_gur09_chris.luac` | 420 | 350 | -70 | IDENTICAL |
| missions | `spiel_job_gur09_jennifer.luac` | 333 | 260 | -73 | IDENTICAL |
| missions | `spiel_job_gur09_mattias.luac` | 423 | 351 | -72 | IDENTICAL |
| missions | `spiel_job_gur11_chris.luac` | 423 | 353 | -70 | IDENTICAL |
| missions | `spiel_job_gur11_jennifer.luac` | 425 | 352 | -73 | IDENTICAL |
| missions | `spiel_job_gur11_mattias.luac` | 334 | 262 | -72 | IDENTICAL |
| missions | `spiel_job_oil00_chris.luac` | 845 | 683 | -162 | IDENTICAL |
| missions | `spiel_job_oil00_jennifer.luac` | 760 | 595 | -165 | IDENTICAL |
| missions | `spiel_job_oil00_mattias.luac` | 846 | 682 | -164 | IDENTICAL |
| missions | `spiel_job_oil01_chris.luac` | 424 | 354 | -70 | IDENTICAL |
| missions | `spiel_job_oil01_jennifer.luac` | 336 | 263 | -73 | IDENTICAL |
| missions | `spiel_job_oil01_mattias.luac` | 423 | 351 | -72 | IDENTICAL |
| missions | `spiel_job_oil02_chris.luac` | 423 | 353 | -70 | IDENTICAL |
| missions | `spiel_job_oil02_jennifer.luac` | 424 | 351 | -73 | IDENTICAL |
| missions | `spiel_job_oil02_mattias.luac` | 335 | 263 | -72 | IDENTICAL |
| missions | `spiel_job_oil03_chris.luac` | 426 | 356 | -70 | IDENTICAL |
| missions | `spiel_job_oil03_jennifer.luac` | 338 | 265 | -73 | IDENTICAL |
| missions | `spiel_job_oil03_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_oil04_chris.luac` | 426 | 356 | -70 | IDENTICAL |
| missions | `spiel_job_oil04_jennifer.luac` | 338 | 265 | -73 | IDENTICAL |
| missions | `spiel_job_oil04_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_oil05_chris.luac` | 424 | 354 | -70 | IDENTICAL |
| missions | `spiel_job_oil05_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_oil05_mattias.luac` | 335 | 263 | -72 | IDENTICAL |
| missions | `spiel_job_oil08_chris.luac` | 594 | 460 | -134 | IDENTICAL |
| missions | `spiel_job_oil08_jennifer.luac` | 693 | 556 | -137 | IDENTICAL |
| missions | `spiel_job_oil08_mattias.luac` | 688 | 552 | -136 | IDENTICAL |
| missions | `spiel_job_oil09_chris.luac` | 423 | 353 | -70 | IDENTICAL |
| missions | `spiel_job_oil09_jennifer.luac` | 425 | 352 | -73 | IDENTICAL |
| missions | `spiel_job_oil09_mattias.luac` | 334 | 262 | -72 | IDENTICAL |
| missions | `spiel_job_oil11_chris.luac` | 423 | 353 | -70 | IDENTICAL |
| missions | `spiel_job_oil11_jennifer.luac` | 336 | 263 | -73 | IDENTICAL |
| missions | `spiel_job_oil11_mattias.luac` | 426 | 354 | -72 | IDENTICAL |
| missions | `spiel_job_pir01_chris.luac` | 335 | 265 | -70 | IDENTICAL |
| missions | `spiel_job_pir01_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_pir01_mattias.luac` | 428 | 356 | -72 | IDENTICAL |
| missions | `spiel_job_pir02_chris.luac` | 425 | 355 | -70 | IDENTICAL |
| missions | `spiel_job_pir02_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_pir02_mattias.luac` | 337 | 265 | -72 | IDENTICAL |
| missions | `spiel_job_pir03_chris.luac` | 422 | 352 | -70 | IDENTICAL |
| missions | `spiel_job_pir03_jennifer.luac` | 335 | 262 | -73 | IDENTICAL |
| missions | `spiel_job_pir03_mattias.luac` | 425 | 353 | -72 | IDENTICAL |
| missions | `spiel_job_pir04_chris.luac` | 425 | 355 | -70 | IDENTICAL |
| missions | `spiel_job_pir04_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_pir04_mattias.luac` | 337 | 265 | -72 | IDENTICAL |
| missions | `spiel_job_pir07_chris.luac` | 425 | 355 | -70 | IDENTICAL |
| missions | `spiel_job_pir07_jennifer.luac` | 426 | 353 | -73 | IDENTICAL |
| missions | `spiel_job_pir07_mattias.luac` | 337 | 265 | -72 | IDENTICAL |
| missions | `spiel_job_pir10_chris.luac` | 554 | 452 | -102 | IDENTICAL |
| missions | `spiel_job_pir10_jennifer.luac` | 470 | 365 | -105 | IDENTICAL |
| missions | `spiel_job_pir10_mattias.luac` | 559 | 455 | -104 | IDENTICAL |
| missions | `spiel_job_pir11_chris.luac` | 463 | 361 | -102 | IDENTICAL |
| missions | `spiel_job_pir11_jennifer.luac` | 557 | 452 | -105 | IDENTICAL |
| missions | `spiel_job_pir11_mattias.luac` | 558 | 454 | -104 | IDENTICAL |
| missions | `spiel_minorcontract_all05_chris.luac` | 454 | 374 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all05_jennifer.luac` | 455 | 372 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all05_mattias.luac` | 356 | 274 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_all06_chris.luac` | 354 | 274 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all06_jennifer.luac` | 457 | 374 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all06_mattias.luac` | 454 | 372 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_all08_chris.luac` | 452 | 372 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all08_jennifer.luac` | 355 | 272 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all08_mattias.luac` | 455 | 373 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_all50_chris.luac` | 450 | 370 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all50_jennifer.luac` | 353 | 270 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all50_mattias.luac` | 453 | 371 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_all52_chris.luac` | 348 | 268 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all52_jennifer.luac` | 449 | 366 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all52_mattias.luac` | 451 | 369 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_all53_chris.luac` | 452 | 372 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_all53_jennifer.luac` | 354 | 271 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_all53_mattias.luac` | 451 | 369 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi05_chris.luac` | 449 | 369 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi05_jennifer.luac` | 451 | 368 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi05_mattias.luac` | 350 | 268 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi06_chris.luac` | 449 | 369 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi06_jennifer.luac` | 351 | 268 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi06_mattias.luac` | 448 | 366 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi08_chris.luac` | 444 | 364 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi08_jennifer.luac` | 347 | 264 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi08_mattias.luac` | 447 | 365 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi50_chris.luac` | 447 | 367 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi50_jennifer.luac` | 449 | 366 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi50_mattias.luac` | 348 | 266 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi51_chris.luac` | 446 | 366 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi51_jennifer.luac` | 348 | 265 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi51_mattias.luac` | 445 | 363 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_chi53_chris.luac` | 445 | 365 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_chi53_jennifer.luac` | 446 | 363 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_chi53_mattias.luac` | 347 | 265 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur03_chris.luac` | 447 | 367 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur03_jennifer.luac` | 448 | 365 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur03_mattias.luac` | 349 | 267 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur04_chris.luac` | 451 | 371 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur04_jennifer.luac` | 452 | 369 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur04_mattias.luac` | 353 | 271 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur05_chris.luac` | 446 | 366 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur05_jennifer.luac` | 447 | 364 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur05_mattias.luac` | 348 | 266 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur50_chris.luac` | 449 | 369 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur50_jennifer.luac` | 351 | 268 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur50_mattias.luac` | 448 | 366 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur52_chris.luac` | 347 | 267 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur52_jennifer.luac` | 450 | 367 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur52_mattias.luac` | 447 | 365 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_gur53_chris.luac` | 346 | 266 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_gur53_jennifer.luac` | 449 | 366 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_gur53_mattias.luac` | 446 | 364 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_oil03_chris.luac` | 347 | 267 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_oil03_jennifer.luac` | 448 | 365 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_oil03_mattias.luac` | 450 | 368 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_oil04_chris.luac` | 452 | 372 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_oil04_jennifer.luac` | 453 | 370 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_oil04_mattias.luac` | 354 | 272 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_oil05_chris.luac` | 349 | 269 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_oil05_jennifer.luac` | 452 | 369 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_oil05_mattias.luac` | 449 | 367 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_oil21_chris.luac` | 1,281 | 1,033 | -248 | IDENTICAL |
| missions | `spiel_minorcontract_oil21_jennifer.luac` | 1,195 | 944 | -251 | IDENTICAL |
| missions | `spiel_minorcontract_oil21_mattias.luac` | 1,288 | 1,038 | -250 | IDENTICAL |
| missions | `spiel_minorcontract_oil51_chris.luac` | 451 | 371 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_oil51_jennifer.luac` | 453 | 370 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_oil51_mattias.luac` | 352 | 270 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_oil52_chris.luac` | 347 | 267 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_oil52_jennifer.luac` | 448 | 365 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_oil52_mattias.luac` | 450 | 368 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pir01_chris.luac` | 456 | 376 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pir01_jennifer.luac` | 458 | 375 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pir01_mattias.luac` | 357 | 275 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pir02_chris.luac` | 609 | 497 | -112 | IDENTICAL |
| missions | `spiel_minorcontract_pir02_jennifer.luac` | 515 | 400 | -115 | IDENTICAL |
| missions | `spiel_minorcontract_pir02_mattias.luac` | 614 | 500 | -114 | IDENTICAL |
| missions | `spiel_minorcontract_pir03_chris.luac` | 600 | 488 | -112 | IDENTICAL |
| missions | `spiel_minorcontract_pir03_jennifer.luac` | 505 | 390 | -115 | IDENTICAL |
| missions | `spiel_minorcontract_pir03_mattias.luac` | 601 | 487 | -114 | IDENTICAL |
| missions | `spiel_minorcontract_pir04_chris.luac` | 603 | 491 | -112 | IDENTICAL |
| missions | `spiel_minorcontract_pir04_jennifer.luac` | 509 | 394 | -115 | IDENTICAL |
| missions | `spiel_minorcontract_pir04_mattias.luac` | 608 | 494 | -114 | IDENTICAL |
| missions | `spiel_minorcontract_pir51_chris.luac` | 351 | 271 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pir51_jennifer.luac` | 452 | 369 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pir51_mattias.luac` | 454 | 372 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pir52_chris.luac` | 346 | 266 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pir52_jennifer.luac` | 449 | 366 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pir52_mattias.luac` | 446 | 364 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pmc11_chris.luac` | 451 | 371 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pmc11_jennifer.luac` | 452 | 369 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pmc11_mattias.luac` | 353 | 271 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pmc13_chris.luac` | 451 | 371 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pmc13_jennifer.luac` | 353 | 270 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pmc13_mattias.luac` | 450 | 368 | -82 | IDENTICAL |
| missions | `spiel_minorcontract_pmc14_chris.luac` | 455 | 375 | -80 | IDENTICAL |
| missions | `spiel_minorcontract_pmc14_jennifer.luac` | 357 | 274 | -83 | IDENTICAL |
| missions | `spiel_minorcontract_pmc14_mattias.luac` | 454 | 372 | -82 | IDENTICAL |
| hijacks | `helicopterhijack.luac` | 8,630 | 6,026 | -2,604 | IDENTICAL |
| hijacks | `hijack_ah1z.luac` | 15,328 | 10,070 | -5,258 | DEBUG-STRIP |
| hijacks | `hijack_alouette3.luac` | 10,177 | 6,464 | -3,713 | DEBUG-STRIP |
| hijacks | `hijack_amx30.luac` | 39,130 | 31,631 | -7,499 | DEBUG-STRIP |
| hijacks | `hijack_amx30aa.luac` | 5,450 | 3,101 | -2,349 | DEBUG-STRIP |
| hijacks | `hijack_banktruck.luac` | 5,807 | 3,462 | -2,345 | DEBUG-STRIP |
| hijacks | `hijack_f35b.luac` | 9,187 | 6,413 | -2,774 | IDENTICAL |
| hijacks | `hijack_huey.luac` | 9,798 | 6,249 | -3,549 | DEBUG-STRIP |
| hijacks | `hijack_ka29b.luac` | 11,547 | 8,714 | -2,833 | DEBUG-STRIP |
| hijacks | `hijack_lav3.luac` | 8,343 | 6,525 | -1,818 | DEBUG-STRIP |
| hijacks | `hijack_m113.luac` | 6,230 | 3,590 | -2,640 | DEBUG-STRIP |
| hijacks | `hijack_m1a2.luac` | 19,896 | 11,338 | -8,558 | DEBUG-STRIP |
| hijacks | `hijack_m2a3.luac` | 9,539 | 6,916 | -2,623 | DEBUG-STRIP |
| hijacks | `hijack_m551.luac` | 9,048 | 6,406 | -2,642 | DEBUG-STRIP |
| hijacks | `hijack_md500.luac` | 19,332 | 15,371 | -3,961 | DEBUG-STRIP |
| hijacks | `hijack_mh53j.luac` | 22,343 | 18,566 | -3,777 | DEBUG-STRIP |
| hijacks | `hijack_mi26.luac` | 6,190 | 3,840 | -2,350 | DEBUG-STRIP |
| hijacks | `hijack_mi35.luac` | 9,420 | 5,618 | -3,802 | DEBUG-STRIP |
| hijacks | `hijack_mi35_solano.luac` | 70,372 | 58,223 | -12,149 | DEBUG-STRIP† |
| hijacks | `hijack_pgz95.luac` | 10,937 | 8,289 | -2,648 | DEBUG-STRIP |
| hijacks | `hijack_plz45.luac` | 10,698 | 8,106 | -2,592 | DEBUG-STRIP |
| hijacks | `hijack_scorpion90.luac` | 29,968 | 23,555 | -6,413 | DEBUG-STRIP |
| hijacks | `hijack_stingrayii.luac` | 51,210 | 44,330 | -6,880 | DEBUG-STRIP |
| hijacks | `hijack_wz10.luac` | 32,516 | 27,254 | -5,262 | DEBUG-STRIP |
| hijacks | `hijack_wz551.luac` | 11,225 | 8,915 | -2,310 | DEBUG-STRIP |
| hijacks | `hijack_zbd2000.luac` | 15,026 | 12,388 | -2,638 | DEBUG-STRIP |
| hijacks | `hijack_ztz63a.luac` | 8,280 | 5,624 | -2,656 | DEBUG-STRIP |
| hijacks | `hijack_ztz98.luac` | 8,278 | 5,637 | -2,641 | DEBUG-STRIP |
| hijacks | `tankhijack.luac` | 7,645 | 5,148 | -2,497 | DEBUG-STRIP |
| subtitles | `subtitles_01_aoa_c.luac` | 2,232 | 1,749 | -483 | IDENTICAL |
| subtitles | `subtitles_01_aoa_j.luac` | 2,333 | 1,850 | -483 | IDENTICAL |
| subtitles | `subtitles_01_aoa_m.luac` | 2,331 | 1,848 | -483 | IDENTICAL |
| subtitles | `subtitles_02_aob_c.luac` | 5,866 | 4,627 | -1,239 | IDENTICAL |
| subtitles | `subtitles_02_aob_j.luac` | 5,898 | 4,659 | -1,239 | IDENTICAL |
| subtitles | `subtitles_02_aob_m.luac` | 5,926 | 4,675 | -1,251 | IDENTICAL |
| subtitles | `subtitles_06_ynh_c.luac` | 1,174 | 955 | -219 | IDENTICAL |
| subtitles | `subtitles_06_ynh_j.luac` | 1,189 | 970 | -219 | IDENTICAL |
| subtitles | `subtitles_06_ynh_m.luac` | 1,270 | 1,035 | -235 | IDENTICAL |
| subtitles | `subtitles_07_rhe_c.luac` | 1,266 | 1,027 | -239 | IDENTICAL |
| subtitles | `subtitles_07_rhe_j.luac` | 1,275 | 1,036 | -239 | IDENTICAL |
| subtitles | `subtitles_07_rhe_m.luac` | 1,272 | 1,033 | -239 | IDENTICAL |
| subtitles | `subtitles_08_rme_c.luac` | 1,372 | 1,121 | -251 | IDENTICAL |
| subtitles | `subtitles_08_rme_j.luac` | 1,378 | 1,127 | -251 | IDENTICAL |
| subtitles | `subtitles_08_rme_m.luac` | 1,376 | 1,125 | -251 | IDENTICAL |
| subtitles | `subtitles_09_rje_c.luac` | 1,763 | 1,424 | -339 | IDENTICAL |
| subtitles | `subtitles_09_rje_j.luac` | 1,775 | 1,436 | -339 | IDENTICAL |
| subtitles | `subtitles_09_rje_m.luac` | 1,771 | 1,432 | -339 | IDENTICAL |
| subtitles | `subtitles_10_brv_c.luac` | 1,131 | 924 | -207 | IDENTICAL |
| subtitles | `subtitles_10_brv_j.luac` | 1,140 | 933 | -207 | IDENTICAL |
| subtitles | `subtitles_10_brv_m.luac` | 1,137 | 930 | -207 | IDENTICAL |
| subtitles | `subtitles_11_sr1_s.luac` | 811 | 664 | -147 | IDENTICAL |
| subtitles | `subtitles_11_sr2_s.luac` | 880 | 693 | -187 | IDENTICAL |
| subtitles | `subtitles_12_car_c.luac` | 889 | 718 | -171 | IDENTICAL |
| subtitles | `subtitles_12_car_j.luac` | 884 | 713 | -171 | IDENTICAL |
| subtitles | `subtitles_12_car_m.luac` | 888 | 717 | -171 | IDENTICAL |
| subtitles | `subtitles_13_avi_c.luac` | 1,223 | 996 | -227 | IDENTICAL |
| subtitles | `subtitles_13_avi_j.luac` | 1,238 | 1,011 | -227 | IDENTICAL |
| subtitles | `subtitles_13_avi_m.luac` | 1,233 | 1,006 | -227 | IDENTICAL |
| subtitles | `subtitles_14_cvi_c.luac` | 1,051 | 852 | -199 | IDENTICAL |
| subtitles | `subtitles_14_cvi_j.luac` | 1,060 | 861 | -199 | IDENTICAL |
| subtitles | `subtitles_14_cvi_m.luac` | 1,057 | 858 | -199 | IDENTICAL |
| subtitles | `subtitles_15_ack_c.luac` | 815 | 660 | -155 | IDENTICAL |
| subtitles | `subtitles_15_ack_j.luac` | 821 | 666 | -155 | IDENTICAL |
| subtitles | `subtitles_15_ack_m.luac` | 819 | 664 | -155 | IDENTICAL |
| subtitles | `technov.luac` | 231 | 203 | -28 | IDENTICAL |
| guilayouts | `mrxguibinocularslayout.luac` | 28,994 | 16,983 | -12,011 | IDENTICAL |
| guilayouts | `mrxguihudlayout2.luac` | 77,674 | 43,813 | -33,861 | IDENTICAL |
| guilayouts | `mrxguipdalayout.luac` | 2,190 | 1,494 | -696 | IDENTICAL |
| guilayouts | `mrxguisatellitelayout.luac` | 16,974 | 10,305 | -6,669 | REAL |
| loading | `loading.luac` | 66,522 | 66,362 | -160 | IDENTICAL |
| english | `english.luac` | 6,450 | 4,059 | -2,391 | IDENTICAL |

