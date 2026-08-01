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

## BUG-004 — Profile autosave: five setters never dirty the profile, so their changes are not saved

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`player_code_map.md`](../reverse_engineer/player_code_map.md) §4 item 1, double-blind validated in
  [`player_validation.md`](../reverse_engineer/validation/player_validation.md) P2-6)
- **Symptom:** a change to cash, fuel capacity, profile character, profile costume or the available-costume
  roster — *alone*, with nothing else touched — is not picked up by the autosave.
- **Root cause.** The profile singleton carries a dirty byte at `+0x11`. `FUN_00614540` (the function
  carrying the `"autoSave"` literal `0x00BBC4E8`) gates the save on it:

  ```
  0x0061488C  mov  eax, [0x01176054]
  0x00614891  cmp  byte [eax + 0x11], 0     ; dirty?
  0x00614895  je   0x006148CE               ;   not dirty -> skip the save
  0x006148C2  call 0x00634460               ; ★ THE SAVE
  ```

  The well-behaved setters use compare-then-`setne`-then-`or` (`SetFuel` `0x005DF64E-57`,
  `SetProfileUpgrade` `0x005DF8C3-D0`), so they dirty only on a real change. **Five setters contain no
  `or byte [.. + 0x11]` at all:** `SetCash` (`0x005DF4FE`, a bare `mov`), `SetFuelCapacity`
  (`0x005DF778`), `SetProfileCharacter` (`0x005DF828`), `SetProfileCostume` (`0x005DF978`),
  `SetAvailableCostumes` (`0x005DFB98`).
- **★ Enumeration matters.** Earlier revisions of the map listed **three** offenders. There are **five**;
  a fix built from the old list is an incomplete fix. A second gate exists at `+0x25F` (must be non-zero
  for the save to run) — role inferred from position only, confidence **L**; do not patch it blind.
- *Reproduce (static):* disassemble each setter body and grep for `or byte ptr [e?? + 0x11]`.

---

## BUG-005 — `SetAllWeapons` silently truncates to 2+2, and a 5th primary is re-classed as a secondary

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`inventory_equipment_code_map.md`](../reverse_engineer/inventory_equipment_code_map.md) §4.5,
  validated in [`inventory_equipment_validation.md`](../reverse_engineer/validation/inventory_equipment_validation.md) A13 —
  *"best-evidenced claim in the map"*)
- **Symptom:** weapons vanish from the loadout across any path that snapshots and restores it.
- **Root cause.** The bucket loop at `0x005BF310`–`0x005BF35E` collects into two **4-wide**
  bounds-checked buckets, but the call site forwards only four values:

  ```
  0x005BF39F  mov eax, [esp+0x48]     ; PRIMARY[0]   -> register arg
  0x005BF3A4  mov ecx, [esp+0x50]     ; PRIMARY[1]   -> register arg
  0x005BF39E/A3  push SECONDARY[1], SECONDARY[0]
  0x005BF3A9  call 0x006F8EF0         ; (char, P0, P1, S0, S1)
  ```

  `PRIMARY[2..3]` and `SECONDARY[2..3]` are collected and then **discarded**. Max expressible loadout is
  **2 primary + 2 secondary**.
- **★ Not merely truncation — it changes slot class.** `cmp ebp,4 / jge 0x5BF337` jumps *into* the
  secondary-store block rather than past it, so the **5th–8th primaries are written into the SECONDARY
  bucket** and can surface as `S[0]`/`S[1]`.
- **Reachable from shipped script, two ways:**
  1. **Hero swap** — `MrxPlayer._RestoreEquipment` ([mrxplayer.lua:695-701](../mercs2-luacd/src/resident/mrxplayer.lua#L695-L701))
     re-applies the saved loadout through `SetAllWeapons`.
  2. **Five PMC contract missions** (`pmccon018/031/032/033/034`) do
     `GetAllWeapons` → *mission* → `SetAllWeapons` to take the guns away and give them back.
  `GetAllWeapons` returns up to **12**; `SetAllWeapons` accepts **4**. Anything past 2-per-class is lost
  on the way back.
- ⚠ **Ghidra alone shows this as a 2-slot call** (`FUN_006f8ef0(unaff_EDI, local_34[0], local_34[1])`) and
  misleads. The register args must be read from raw disassembly — see [[binding-only-is-not-a-wall-disassemble]].
- **Confirm-live before fixing:** the shipped `ResetWeapons` loadout is 1+2 and fits, so the truncation
  only bites a player who is carrying more than 2 of a class at the moment of a swap/restore. Worth an
  in-game repro to establish how easily a normal playthrough reaches it.

---

## BUG-006 — Hero swap silently refills the magazine (clip ammo is never saved)

- **Tier:** T2 (Lua) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`inventory_equipment_code_map.md`](../reverse_engineer/inventory_equipment_code_map.md) §7.3 —
  the map itself files this as a `bug_register` candidate)
- `MrxPlayer.SaveSingleton` ([mrxplayer.lua:666](../mercs2-luacd/src/resident/mrxplayer.lua#L666)) saves
  `{ Object.GetParent(uEquipment), Weapon.GetReserveAmmo(uEquipment) }` per weapon — **reserve ammo only**.
- `SetAllWeapons` destroys and re-creates the weapon *instances*, and clip ammo lives on the instance. The
  restore path re-applies reserve by hand (deferred behind `Event.ObjectHibernation`) but never touches
  clip. **A hero swap therefore hands the magazine back full**, regardless of how empty it was.
- Smallest faithful fix: extend the saved tuple with `Weapon.GetClipAmmo` and re-apply it in the same
  `ObjectHibernation` callback that already restores reserve. Pure T2 — no exe patch.

---

## BUG-007 — Three PDA-blip binders dereference NULL (crash)

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`hud_widget_code_map.md`](../reverse_engineer/hud_widget_code_map.md) §2, §9.1; validated in
  [`hud_widget_validation.md`](../reverse_engineer/validation/hud_widget_validation.md) A8, P2.5)
- On their failure path all three binders `xor eax,eax`, control **merges**, and the very next access is
  an unguarded dereference:

  | binder | VA | fail path | faulting instruction |
  |---|---|---|---|
  | `_GuiInternal.AddPdaMapBlips` | `0x005BCE70` | `005BCEE8 xor eax,eax` | `005BCEEF cmp dword [eax+0x10], 6` |
  | `_GuiInternal.UpdatePdaBlip` | `0x005BCF90` | `005BD008 xor eax,eax` | `005BD00F cmp dword [eax+0x10], 6` |
  | `_GuiInternal.RemovePdaBlip` | `0x005BD0C0` | `005BD135 xor eax,eax` | `005BD139 cmp dword [eax+0x10], 6` |

  All three then use a branchless `setne bl / sub ebx,esi / and ebx,eax` to pass `0` to the callee — which
  is *why* there is no null check: the author folded "not a flash widget ⇒ NULL" into arithmetic and
  overlooked that the tag read itself dereferences. Every other widget binder does `test reg,reg / jne`
  first (`SetWidgetLocation 0x005B5018`, `DeleteWidget 0x005B4F89`, …).
- **Two reaching conditions**, not one: the id range check fails, **or** it passes on a slot holding NULL —
  a deleted widget, reachable because ids are reused (`FUN_00618D50 = Manager::Delete` clears `slots[id]`
  and resets `widget+0x18 = -1`). The slot array has **zero slack** (`push 0x200`, cap `0x80`), so
  `id == cap` is a real 4-byte heap over-read whose garbage pointer is then dereferenced.
- ★ **Scope is three binders, not one.** The map and the first validation pass both named only
  `AddPdaMapBlips`.
- *Script repro:* `_GuiInternal.RemovePdaBlip(-1, "x")` → `eax = 0` at `005BD135`, `005BD139` reads linear
  address `0x00000010` → AV. Arg 2 is irrelevant: its type check happens *after* the fault.
- *x32dbg repro (read-only, PAUSED):* one-shot bp at `0x005BD139`, trigger a PDA close/reopen with a stale
  blip id, read EAX. ⚠ **Do not** set a conditional bp here — these sit next to per-frame work
  ([[x32dbg-mcp-pitfalls]]).

---

## BUG-008 — `Gui.ShowLoadingHints(false)` is a one-way switch

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`hud_widget_code_map.md`](../reverse_engineer/hud_widget_code_map.md) §5.1; validated instruction-exact
  in [`hud_widget_validation.md`](../reverse_engineer/validation/hud_widget_validation.md) A7/D1)
- `0x005B4C30`: an **absent** argument defaults to `1` and falls into the write; an explicit `true` writes;
  an explicit **`false` branches to the epilogue at `0x005B4C60`, before the store and before the secondary
  notify `0x00608590`**. `[gui+0x39]` is written in exactly one place, so **the flag can never be cleared**.
  8 Lua call sites.
- *Repro:* call with `true`, then `false`, then load a level — hints still show. HW write watchpoint on
  `[[0x01175FB0]+0x39]` fires on the `true` and omitted calls, **never** on `false`.
- **Fix scope is not a one-byte flip.** Killing the `je` at `0x005B4C60` is necessary but not sufficient —
  a correct build also needs the notify at `0x005B4C74` made reachable. Small patch region, not a nop.

---

## BUG-009 — `Pg.UnloadLayer` NULL-derefs on a co-op client with no current game state

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`mission_contract_flow_code_map.md`](../reverse_engineer/mission_contract_flow_code_map.md) §5.2 —
  *"Reachable, not theoretical. Belongs in `docs/fixpack/bug_register.md`"*; validated in
  [`mission_contract_flow_validation.md`](../reverse_engineer/validation/mission_contract_flow_validation.md))
- The head gate is `cmp byte [0xdfbd77], 0; je 0x5d4e6c` (`0x005D4E49`, `Net.IsClient`) followed
  **immediately** by `mov eax, [0x1175c7c]; cmp dword [eax+4], 0x7d0b162c` (`0x005D4E55`) — **with no null
  check on `eax`**.
- §3.2 of the same map proves an unrecognised `Sys.RequestGameState` string leaves `DAT_01175C7C == NULL`.
  So a **client** calling `Pg.UnloadLayer` while no game state is current dereferences `NULL+4`.

---

## BUG-010 — PDA support quick-slot: the feature is dead at both ends

- **Tier:** T4 (restored content) / T2 · **Status:** `confirmed` (static) · **Needs in-game repro**
- **Reported by:** machine-derived ([`lti_movie_pda_code_map.md`](../reverse_engineer/lti_movie_pda_code_map.md) §8.2;
  [`lti_movie_pda_validation.md`](../reverse_engineer/validation/lti_movie_pda_validation.md) M4 —
  *"the fix-pack entry is stronger than §8.2 says and survives"*)
- Three findings, each independently re-derived:
  1. **Flash never raises the event.** `LTIupdateSupportQuickSlot` (and the bare `updateSupportQuickSlot`)
     appear in **none of the 83 shipped `.gfx` movies** — `Map.gfx`, the movie the handler is attached to,
     and `SUPPORT.gfx` included. Extraction is provably complete: `aset_export.csv` lists 83 assets of
     `type_hash 0xFE0E8320`, and `output/gfx_movies/` holds exactly 64 + 16 + 3.
  2. **The engine forwarder is a no-op stub.**
  3. **The Lua implementation exists and is orphaned.** `mrxguipda.lua:1861` defines `EnableQuickSlot(sId)`
     — ~37 lines that do the real work (look up `tSupportIdIndex[sId]`, `AddItem`, `SetSupportName` /
     `SetFuelCost` / `SetCashCost` / `Commence`, animate the ammo counter) — with **zero callers anywhere
     in either Lua corpus**. It is dead code three lines below the forwarder that would have called it.
- Plausible one-line repair: point `_LTIupdateSupportQuickSlot` at `EnableQuickSlot(sParm)`. **Reproduce
  in-game before building** — establish what the player is currently missing.

---

## BUG-011 — `Object.GetInfiniteAmmo` is absent on retail PC, so the DLC PDA cheat toggle is a silent no-op

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`object_entity_core_code_map.md`](../reverse_engineer/object_entity_core_code_map.md) §8.A;
  [`object_entity_core_validation.md`](../reverse_engineer/validation/object_entity_core_validation.md) P6)
- The retail PC `Object` table at `0x00B99608` has **87** entries (walked three times, terminator
  `0x00B998C0`) and no `GetInfiniteAmmo`. The DLC PDA calls it and is **feature-guarded**:

  ```lua
  132  L0_2 = Object.GetInfiniteAmmo
  133  if not L0_2 then return end                              -- _CheatToggleInfiniteAmmo bails entirely
  510  if L2_2 then L2_2 = Object.GetInfiniteAmmo(L0_2) end     -- OnPlayerJoin state sync
  ```

  So `_CheatToggleInfiniteAmmo` does nothing on retail PC and the PDA cannot read its own toggle state on
  join. The DLC was authored against a build that had the getter.
- The container is pinned: **`CheatInfiniteAmmo`**, stride 1, cap 128, written by `FUN_00649180`, erased by
  vtable `+0x64` — exactly the shape a `Get`/`Set` pair wants. Adding the getter is a bounded exe patch.

---

## BUG-012 — `DebrisEffect` fields 8/9 are registered under the chunk-*velocity* names

- **Tier:** T3 (exe) · **Status:** `confirmed` · **Reported by:** machine-derived
  ([`fire_ignition_code_map.md`](../reverse_engineer/fire_ignition_code_map.md) §6;
  [`fire_ignition_validation.md`](../reverse_engineer/validation/fire_ignition_validation.md))
- The schema function passes fields 8 and 9 the **same two string pointers** as 6 and 7 —
  `0x00BCAE9C "MinChunkVel"`, `0x00BCAEA8 "MaxChunkVel"` — and `"Trail"` follows immediately at
  `0x00BCAEB4`, so **no `MinChunkTime`/`MaxChunkTime` string exists in the image at all.**
- The shipped schema record in `vz.wad` gives fields 8/9 the distinct hashes `0x83BA82B5` / `0x51D7BD57`,
  and `pandemic_hash_m2("MinChunkTime") == 0x83BA82B5`, `pandemic_hash_m2("MaxChunkTime") == 0x51D7BD57`
  (verified). **Retail registers the two chunk-lifetime fields under the chunk-velocity names** — a
  copy-paste bug invisible to either source alone.
- Impact is authoring-side, not player-side: it mis-names fields for anyone reading the reflection registry.
  Low priority for a *player* fix pack, but it must not be "corrected" out of our own tooling — the shipped
  data is keyed by the correct hashes.

---

## Latent traps — real defects, NOT reachable from shipped content

Recorded so the fix pack does not ship a fix for something no player can hit, and so a future modder does
not re-derive them. **None of these has an observable retail symptom.** All are machine-derived from the
2026-07-26 code-map pass.

| # | Defect | Why it is latent | Source |
|---|---|---|---|
| L1 | **`GetAllWeapons`' fill loop has no bound check** (`0x005BEED0`). A 7th primary writes `sec[0]`; a **13th carried weapon writes the live iterator** — a stack smash inside the loop walking it. | The only writer (`SetAllWeapons`) caps at 4, so retail cannot reach it. **A mod that attaches weapons by another route can.** | [inventory §4.4](../reverse_engineer/inventory_equipment_code_map.md) |
| L2 | **Object-filter compiler: `!` before `(` is silently broken.** Operators are counted only at paren depth 0, so `"!(A&&B)"` compiles to `[NOT, hash("(A&&B)")]`, the leaf always misses, and `NOT` turns the miss into a match — **`SetFilter(f,"!(A&&B)")` matches every object unconditionally.** | Zero shipped expressions contain `!`. | [object_filter §4.2.1](../reverse_engineer/object_filter_code_map.md) |
| L3 | **`ReloadAll(uChar)` with one argument is a silent no-op returning `nil`** — arg 2 is mandatory; the bail is at `0x005BF737`, before any reload work. | All **three** shipped call sites pass two args (`xQ!L.lua:761`, `dlc01.lua:492`, `dlctest01.lua:158`). An API trap for new script authors only. | [inventory §4.8](../reverse_engineer/inventory_equipment_code_map.md) |
| L4 | **`SetCash`/`SetFuel` take an undocumented optional second boolean that suppresses the write entirely** — `SetFuel` skips the store *and* the dirty OR. | No shipped script passes it. ⚠ **Directly relevant to BUG-004:** a fix-pack or cheat path calling `SetCash(n, true)` silently no-ops. | [player §4 item 3](../reverse_engineer/player_code_map.md) |
| L5 | **Both `Sys.RequestGameState` refusal paths push `true`** — a caller checking the return (`mrxutil.lua:113`) cannot tell a swallowed request from an accepted one. | Shipped behaviour with no known symptom. Promote if a wedge is ever traced to a request issued during `unloading`. | [mission_contract_flow §3.4](../reverse_engineer/mission_contract_flow_code_map.md) |
| L6 | **`mrxtaskjob.lua:349` binds `GetObjects(f,false)` to `tExcludedObjects`** — the local and the `bExcluded` test at `:352` actually mean *"is included"*. | Neutralised: the unconditional `AddObject(f,uGuid,false)` at `:361` follows both branches and the add primitive de-duplicates, so both branches end with the GUID included. **Naming + dead-code defect, net behaviour = intent.** | [object_filter §6](../reverse_engineer/object_filter_code_map.md) |
| L7 | **22 of 56 LTI cfuncs declare a Lua result they never push** (only `FirstRun` and `Movie.Start` actually push). | Callers do not read the values. | [lti_movie_pda §8.3](../reverse_engineer/lti_movie_pda_code_map.md) |
| L8 | **`Junk.InstallToHDD` / `Junk.UseExistingInstall` are no-ops on PC** (console install-to-HDD); **`Junk.IsInstallable` `0x005C0340` shares its body with `Sys.NoHud`** — a two-name/one-body alias, so it certainly does not answer "can this be installed". 15 of 24 `Junk` rows are the shared `return-0` stub. | Dev commands, not player-facing. | [mission_contract_flow §2](../reverse_engineer/mission_contract_flow_code_map.md) |

### Diagnosis, not a bug — co-op mission authority

Recorded because it explains a class of co-op symptom rather than being a defect to patch. All eleven real
`Net.SendEvent_*Objective*` senders open with `cmp byte [0xdfbd74],0` (`Net.IsEnabled`) then
`cmp byte [0xdfbd78],0` (`Net.IsServer`), each falling to an early `ret`. Combined with `Pg.LoadLayer`
being refused outright on a client: **a co-op client receives mission layers and objective markers only by
replication from the server, and both refusals are silent.** If the wrong peer runs mission Lua it loads no
layers, emits no objective events, and nothing errors.
([`mission_contract_flow_code_map.md`](../reverse_engineer/mission_contract_flow_code_map.md) §6)

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

### ~~⚠ Do not trust `type_id` tables when building fix-pack assets~~ ★ FIXED IN CODE 2026-08-01

> **★ The code is now correct and self-checking.** `mercs2_formats::{types, aset_type_ids}` were
> regenerated from the WAD's own table at `0x48`, and
> `mercs2_formats/tests/type_ids_match_the_wad.rs` reads that table at test time and asserts both
> mappings against it — so this cannot drift again without a red test. Re-measured on the way in:
> 12 of 35 `aset_type_ids` rows and 7 of 23 paired `types` constants were still wrong, exactly as
> recorded below; `type_name` was keyed on the same wrong ids and was corrected too.
>
> The warning below stands as history, and its advice — take the ids from the in-WAD table — is now
> what the code does. It had cost something in the meantime: the Workshop Library's VFX category was
> built on `TYPE_ID_FX_DICTIONARY` and therefore browsed `watermap`.

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
