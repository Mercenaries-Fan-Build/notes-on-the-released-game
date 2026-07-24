# Mercenaries 2 Unofficial Fix Pack — Bug Register

Running list of defects targeted by the fix pack. **The user supplies the bugs**; this file is the
canonical backlog. Nothing gets an entry unless it is either user-reported or machine-derived from
game data — no invented bugs.

- **Target install:** `C:\Users\Shadow\Desktop\Mercenaries 2 World in Flames`
- **Delivery:** engine-native `*-patch.wad` overlay (additive; retail WADs never modified).
  The install already carries a live `vz-patch.wad` from the character-import work, so fix-pack
  blocks must be **merged** into it (`mercs2_formats::patch_wad::merge_patch_wads`), never
  written over it.
- **Tiers:** T1 text · T2 Lua/data · T3 exe patch · T4 restored content. Shipped as separate,
  independently-installable layers.

## Status vocabulary

| Status | Meaning |
|---|---|
| `reported` | Described, not yet checked against source/data |
| `confirmed` | Root cause traced to specific code/data, cited |
| `fix-designed` | A concrete patch exists on paper, not yet built |
| `built` | Patch produced |
| `verified` | Observed fixed in-game, and the bug reproduced before the fix |

---

## BUG-001 — Toolbox collectible count inflates on reload (up to 100/100 without collecting)

- **Tier:** T2 (Lua) · **Status:** `confirmed` · **Reported by:** user (agent investigation)
- **Symptom:** The toolbox counter (`X/100`) climbs on its own across save/reload cycles. Collecting
  a few near HQ looks correct; driving across Maracaibo then restarting inflates the count by
  roughly however much streamed in that session. A few restarts walk it to 100. Milestone reward
  vehicles are awarded spuriously along the way.
- **Not** a threshold bug at 50 — it is a **race with world streaming**.

### Root cause (verified against the decompiled corpus)

On load, `MrxTaskJobCollectType._Go` tries to neutralize already-collected toolboxes **two** ways
([mrxtaskjobcollecttype.lua:13-54](../mercs2-luacd/src/resident/mrxtaskjobcollecttype.lua#L13-L54)):

1. **Label** them `CollectableInvalidated` (`_DisableCollectable`), so `collectable.Create`
   self-destructs them on stream-in.
2. **Exclude** them from the objective's target filter via `vTgtExclude`.

Route 2 is the one that would prevent a re-count, **and it silently fails.**
`_ProcessElement` gates the exclusion on `self._IsValidTarget(uGuid)`
([mrxtaskobjective.lua:27-38](../mercs2-luacd/src/resident/mrxtaskobjective.lua#L27-L38)), which for a
destroy objective is `Object.IsAlive`
([mrxtaskobjectivedestroy.lua:65-75](../mercs2-luacd/src/resident/mrxtaskobjectivedestroy.lua#L65-L75)).
A toolbox that has not streamed in yet **is not alive**, so `ObjectFilter.AddObject(..., bExclude)`
is never called for it. No error, no warning.

Route 1 then *completes the job on its behalf*: `collectable.Create` sees the label and calls
`Object.Kill` ([collectable.lua:18-22](../mercs2-luacd/src/vz/collectable.lua#L18-L22)) — the **exact
same call** a genuine pickup makes via `OnContextAction`
([collectable.lua:37-39](../mercs2-luacd/src/vz/collectable.lua#L37-L39)). The still-subscribed
`Event.ObjectDeath` handler on `_uTgtObjFilter`
([mrxtaskobjectivedestroy.lua:5-7](../mercs2-luacd/src/resident/mrxtaskobjectivedestroy.lua#L5-L7))
cannot tell the two apart — `_TargetDestroyed` gates only on `bHeroOnly`, and this job does not set
it — so it runs a full `CompletePart`:

- `_nCompleted + 1`
- `MrxStatsManager.CompleteToolboxPart()` → +1 on the X/100 stat
- `MrxPmc.AddCashQty(...)` → **re-pays** the toolbox's cash value
- `_TargetComplete` → bumps `_nTargetsComplete`, awarding any `PmcJob001_MilestoneN` key crossed
  → the milestone vehicles

### Confirming tell on a real save

`tSaveData.tCollected` is a **guid-keyed set**, so the saved collected list stays at the true count
(e.g. 50) while `nCompletedToolboxes` climbs. **Save and HUD disagree** — that divergence is the
signature, and it also means the underlying save data is not corrupted, only the stat.

### Fix direction (not yet designed)

The exclusion must not depend on the target being resident. Options to evaluate: exclude by GUID
without the liveness gate; or make the invalidation path kill *without* routing through the same
death event the objective listens to; or have `CompletePart` reject GUIDs already in
`_tCollectedItems`. The last is the smallest and most defensive — `_Go` already populates
`self._tCollectedItems[uGuid] = true` before the objective is created. **Design pending.**

---

## BUG-002 — `MrxTaskJob._ExcludeCompletedTargets` is an unimplemented stub

- **Tier:** T2 (Lua) · **Status:** `confirmed` · **Reported by:** user (found alongside BUG-001)
- `MrxTaskJob._ExcludeCompletedTargets` is a bare `return` stub
  ([mrxtaskjob.lua:169-171](../mercs2-luacd/src/resident/mrxtaskjob.lua#L169-L171)) and **no subclass
  overrides it**, though four jobs call it — `MrxTaskJobCollectType._Go` calls it as its very first
  action.
- This was the intended safety net for exactly the class of defect in BUG-001, and it was never
  written. Shipped unfinished.
- Relevant to the BUG-001 fix: this stub is the *designed* extension point, so implementing it may
  be the most faithful-to-intent repair rather than patching around it.

---

## BUG-003 — `MrxTaskJobCollectType.LoadAssets` iterates an array with `pairs()`, de-dup pass is inert

- **Tier:** T2 (Lua) · **Status:** `confirmed` · **Reported by:** user (found alongside BUG-001)
- `SaveInstance` writes `tSaveData.tCollected` as an **array** via `table.insert(..., uGuid)` —
  integer keys, GUID values
  ([mrxtaskjobcollecttype.lua:82-91](../mercs2-luacd/src/resident/mrxtaskjobcollecttype.lua#L82-L91)).
- `LoadAssets` reads it back with `pairs()`
  ([mrxtaskjobcollecttype.lua:70-80](../mercs2-luacd/src/resident/mrxtaskjobcollecttype.lua#L70-L80)),
  so the two loop variables are **swapped relative to their names**: `uGuid` receives the array
  **index** (1, 2, 3…) and `bCollected` receives the **actual GUID**. The guard `if bCollected then`
  is therefore always true (a GUID is truthy), and the call becomes
  `Object.AddLabel(1, "CollectableInvalidated")` — labelling integers. **Inert.**
- `_Go` reads the same table correctly with `ipairs`
  ([mrxtaskjobcollecttype.lua:21](../mercs2-luacd/src/resident/mrxtaskjobcollecttype.lua#L21)).
- Net effect: the de-duplication was written twice; **one copy is dead (`LoadAssets`), the other is
  racy (`_Go`).** Fixing BUG-001 must account for both rather than repairing only the live one.

---

## Machine-derived candidates (from the string corpus, not yet triaged)

Surfaced by `stringdb_dump` over `shell.wad` — **observations, not yet accepted as bugs.** Awaiting
your call on whether these are in scope.

- **Console strings shipped in the PC build.** e.g. `You must sign up for PLAYSTATION®Network.
  (80130183)` — a PS3 network error present in the PC `english` stringdb. Suggests the PC text was
  branched from a console SKU without a pass. Needs a full sweep for `PLAYSTATION`/`Xbox`/`LIVE`/
  button-glyph references reachable on PC.
- **Inconsistent apostrophe typography.** The corpus mixes U+2019 (`There's`, `Let's`) and U+0027
  (`She'll`, `You've`) — sometimes within adjacent lines. A consistency pass is a natural T1 item,
  but it is high-volume and cosmetic; confirm you want it before I spend edits on it.

---

## ★ Where the game's text actually lives (measured, not assumed)

Surveyed via `stringdb_dump` + `docs/data/aset_export.csv` (type_id 7):

| WAD | stringdb blocks | Notes |
|---|---|---|
| `shell.wad` | english, french, german, italian, russian, spanish | 18,299 keys each |
| `vz.wad` | **english**, japanese, allcaps | english = 18,299 keys |
| `English.wad` | **none** | 483 MB, all VO audio — no text at all |
| `Loading.wad` | none | |

**★ The English text is DUPLICATED.** `shell.wad::english_P000_Q3` and `vz.wad::english_P000_Q3`
are **content-identical**: same 18,299 keys, same heap size (1,229,064 B), same sha256 over
`key_hash → text`.

**RESOLVED 2026-07-22** — full analysis in
[`wad_duplicate_inventory.md`](wad_duplicate_inventory.md). **Neither copy "wins": they never
compete.** `shell.wad` and `vz.wad` occupy the *same* mount slot (the generic `%s\%s.wad` level
reader, one basename buffer). shell.wad's copy serves the front end; vz.wad's serves gameplay.

Mount order (`FUN_004BFAF0` @ `0x004BFAF0`, seven readers):

```
Loading.wad → loading-patch.wad → <level>.wad → <level>-patch.wad → [gated] → English.wad → English-patch.wad
```

**Collision rule is LAST-MOUNTED WINS** (`proven`) — slots claimed lowest-free-first, resolution
walks the array *backwards* from `count-1`. Confirmed by shipped data: the 6 divergent duplicates
are all localized art in `English.wad` registered under the *base* asset's hash
(`pause_graphic_english` ships under `hash("pause_graphic")`), which only works under last-wins.

> The project memory rule *"registry insert is FIRST-wins"* is **confirmed but is a different
> layer** — `FUN_004CC130`, runtime chunk cells once a block is resident. It does not govern which
> WAD serves an asset. Both rules are true; don't conflate them.

### T1 delivery consequence — two routes

1. **Patch both** `shell-patch.wad` *and* the live `vz-patch.wad` (merge, don't overwrite). Certain
   to work, but doubles the payload and entangles T1 with the character-import patch WAD.
2. **★ Ship one `English-patch.wad`** — it mounts *last in every session*, so under last-wins it
   outranks both the shell and vz copies. One file, no merge, no entanglement with existing mods.
   **`inferred`, not proven** — `English.wad` currently carries no stringdb at all, so this relies
   on the mount-order rule generalising to an asset type that WAD has never served.

### ★ SETTLED 2026-07-22 — Route 2 PROVEN IN-GAME, both slots

Test builds via `stringdb_patch`, deployed as `data/English-patch.wad` (a new file; nothing
overwritten), equal-length edits only so only the edited text + CSUM differ.

| Probe | Slot exercised | Result |
|---|---|---|
| `MULTIPLAYER` → `FIXPACK OK!`, `CREDITS` → `PATCHED` | front end (`shell.wad`) | ✅ shown on main menu |
| `Drive %s` → `VZ OK %s` | gameplay (`vz.wad`) | ✅ shown on live vehicle prompt |
| `Racing Inferno` → `VZ SLOT WINS!!` | gameplay (`vz.wad`) | ✅ composed together as `VZ OK VZ SLOT WINS!!` |

**T1 ships as a single `English-patch.wad`.** No merge against the live `vz-patch.wad`, no
entanglement with the character-import work.

Worth recording: this works **even though `English.wad` ships no stringdb at all**. The patch WAD
introduces an asset type its own base WAD never served, and last-wins still awards it the lookup.
Do not assume a patch WAD is limited to the asset types present in its base.

### ⚠ Trap learned during the test — a string in the table is not a string on screen

The first gameplay probe patched `Enter vehicle`, which **exists in the table but is never
displayed**. The real prompt composes `Drive %s` (`0x0E85FC73`) with a localized vehicle name from a
*separate* key (`Racing Inferno` = `0x3D38F3A2`). Cost one test-build cycle.

With 18,299 keys carrying many near-duplicates and dead entries — `Enter vehicle` matched 3 distinct
key hashes with identical text — **confirm a key is actually rendered before shipping a correction
to it**, or the fix pack will ship fixes to strings nobody ever sees.

Also present and worth a look: `vz.wad::allcaps_P000_Q3` — the exe's language config lists
`#allcaps 1` as a commented-out **debug mode**. A shipped debug string table.

### ⚠ Do not trust `type_id` tables when building fix-pack assets

The duplicate survey found `docs/type_hash_registry.md` and `mercs2_formats::aset_type_ids` are
**wrong for 12 of 36 type ids** (e.g. `0xC122545A` is id 8, not 26). The authoritative table lives
**inside each WAD at file offset `0x48`** (count = header dword 8 = 36), identical across all four
WADs, validated 139 hit / 0 miss. `aset_export.csv`'s `type_name`/`type_hash` columns inherit the
error; its `type_id` and `asset_hash` columns are sound.

Not currently biting us — the stringdb tooling keys off `type_hash` (`0x39E5E978`), not `type_id` —
but any new ASET row the fix pack writes must take its `type_id` from the in-WAD table.

## Tooling built for this project

| Tool | Purpose |
|---|---|
| [`mercs2_formats::stringdb`](../../tools/wad_simulator/crates/mercs2_formats/src/stringdb.rs) | Stringdb **codec — read and write**. `parse()` / `build()` / `set_by_hash()` / `set_by_name()` / `replace_exact_text()`. Supports **arbitrary-length** corrections by rebuilding the heap and re-pointing offsets. 5 unit tests. |
| [`stringdb_dump`](../../tools/wad_simulator/crates/mercs2_probe/src/bin/stringdb_dump.rs) | Extract `key_hash → text` for every stringdb container in a WAD. `cargo run -p mercs2_probe --bin stringdb_dump -- --wad <wad> [--filter english] [--out f.tsv]` |
| [`stringdb_roundtrip`](../../tools/wad_simulator/crates/mercs2_probe/src/bin/stringdb_roundtrip.rs) | **Proves the writer against retail data.** Rebuilds a shipped table with no edits and requires byte-identical output, then applies a length-changing edit and re-parses. |

### Writer status: PROVEN against retail

```
6 container(s) checked, 0 failure(s)      # shell.wad, all six languages
PASS blocks\Shell\english_P000_Q3.block#2 [KEYS/STRS]: 18299 keys, 1229064 B heap — rebuild byte-identical
      edit-reparse OK: heap 1229064 B -> 1229142 B, all 18298 other strings intact
```

Byte-identical rebuild matters because it makes any post-edit difference attributable to the edit
alone. Arbitrary-length corrections are therefore available — we are not limited to the
equal-length in-place swaps the old Python tool could do.

### ★ Format corrections discovered while building it

[`docs/format_reference.md`](../format_reference.md) §4.1 states stringdb SYEK/SRTS bodies are
**"natively big-endian on all platforms"** and that the SRTS header is `total_string_bytes`.
**Both are wrong for the PC build.** Measured across all six language blocks in retail `shell.wad`:

- SYEK entry table and the UTF-16 text heap are both **little-endian**.
- The SRTS header is a **u16 code-unit count, not a byte count** — `heap_bytes == 2 × header` exactly,
  in all six languages (english `1229064 == 2 × 614532`, german `1326564 == 2 × 663282`, …).

- The chunk tags are **`KEYS`/`STRS`** on PC, not `SYEK`/`SRTS`. The reversed spellings are the
  big-endian byte order read as ASCII. Code looking up `SYEK` on a PC WAD finds nothing and
  **silently skips the table.**

`tools/build_shell_string_patch.py`'s UTF-16**LE** assumption was the correct one.
✅ `format_reference.md` §4.1 has been corrected (2026-07-22) on all three points.
