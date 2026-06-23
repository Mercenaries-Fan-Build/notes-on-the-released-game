# Store-item injection experiment — resident Lua script loading

Goal: add a new purchasable PMC vehicle ("Russian Transport Heli") to the in-game store, and
**empirically determine how the engine loads resident Lua scripts from a patch WAD** (the
"overlaid but not accessed" question). These four variants isolate the *script-registration*
mechanism only — none override the model, so the spawned heli is the stock mi26 until we layer
the (proven) model override onto whichever variant wins.

All four pass offline `wad_simulator` validation (full consumption, 0 violations). The real
test is in-game.

## What we already know
- Patch WAD is opened natively by the engine (`FUN_004bfef0`, builds `%s-patch.wad`, soft-fail).
  Confirmed in the binary, not the docs.
- Resident scripts are individual UCFX entries in block **3185** (`resident_P000_Q3`), each
  `INFO` + `DEPS` + `BINN(LuaQ)`, type `0x42498680`, name-hash = `pandemic_hash_m2(name)`.
- `DEPS` = `[u8 count][count × u32 m2(script-name)]` — the lazy-import edges.
- Scripts are believed **lazy-loaded via DEPS import** (past mods crashed on *interaction/spawn*,
  not at boot), so an orphan appended chunk never runs.
- Resident-block patch is full-block replacement (`build_patch_wad.py --block-index 3185`), so
  every original chunk must be carried forward.

## The catalog entry (constant across variants)
`tSupportData.russianheli` — a `mrxsupportcopterdelivery` of `"Mi26 (PMC) (Driver)"`, `sType="Heli"`,
`nCashCost=5000`, pre-unlocked `tUnlockStatus={Pmc=1}` — plus registration in the PMC list
(`MrxRewardData.GetAllPotentialShopItems` → append `"russianheli"`).

## Variants

| # | WAD | Mechanism | Hypothesis it tests |
|---|-----|-----------|---------------------|
| **V1** | `vz-patch-V1.wad` (2.1 MB) | Per-hash override of `mrxsupportdata` + `mrxrewarddata` (cube_mod `--inject-extra`, type 35) | Individual script-asset override **is** accessed (scripts lazy-load by hash). If item appears → per-hash works and "overlaid but not accessed" is wrong. |
| **V2** | `vz-patch-V2.wad` (14.7 MB) | Full resident block 3185 rebuilt; `mrxsupportdata.Init` + `mrxrewarddata` edited **in place** | Full-block replacement works; editing already-on-path scripts. If item appears → full block is the lever, in-place edit is fine. |
| **V3** | `vz-patch-V3.wad` (14.7 MB) | Full block + **appended** new `mrxrussianheli` hook chunk, hash wired into **`mrxshop`** DEPS | A genuinely new script, pulled via the store's DEPS host, runs its top-level (monkey-patches `Init`/`GetAllPotentialShopItems`). |
| **V4** | `vz-patch-V4.wad` (14.7 MB) | Same as V3 but wired into **`mrxsupportdata`** DEPS | Which DEPS host actually pulls the new chunk in. |

`mrxrussianheli` chunk: `m2("mrxrussianheli")=0x3679F003`, DEPS = `MrxRewardData`,`MrxSupportData`,
`mrxsupportcopterdelivery`; top-level wraps `MrxSupportData.Init` (+ direct add) and
`MrxRewardData.GetAllPotentialShopItems`.

## Test procedure (per variant)
```bash
cp /tmp/heli_variants/vz-patch-V<N>.wad "<game>/data/vz-patch.wad"
# boot game → open PMC store / vehicle-delivery menu → look for "Russian Transport Heli" (5000)
# then: loadprobe --no-color pmc_blackbox.log
```
Recommended order: **V1 → V2 → V3 → V4** (cheapest mechanism first).

## Results (round 1)
| # | Loaded? | Item in store? | Meaning |
|---|---|---|---|
| V1 | yes (normal) | **no** | **Per-hash script override is NOT accessed.** Resident scripts load from the block, not per-asset ASET. "Overlaid but not accessed" CONFIRMED for scripts. |
| V2 | yes (normal) | **no** | Full-block replacement loads fine, but the in-place registration didn't surface the item → a *logic* issue (faction id / store / gate), not loading. |
| V3 | **HANG** (post-menu load, forever) | — | Appended chunk **was pulled & executed** (lazy DEPS injection works!) but **hung on a dependency cycle**. |
| V4 | **HANG** | — | Same cycle (direct: `mrxsupportdata` ↔ ours). |

**Key finding:** resident scripts require **full-block replacement** (V1 ruled out), and a new
appended chunk **does get pulled via a DEPS edge** (V3/V4 hung rather than no-op'd). The hang was a
**dependency cycle**, confirmed: `mrxshop` DEPS `mrxsupportdata`, and `mrxsupportdata` DEPS `mrxshop`
— so `mrxshop → mrxrussianheli → mrxsupportdata → mrxshop` loops. (V4 is also wrong *timing*: a chunk
in `mrxsupportdata`'s DEPS runs before `mrxsupportdata` defines `Init`.)

## Round 2 — V3fix (deployed)
`vz-patch-V3fix.wad`: appended `mrxrussianheli` with **empty DEPS** (no cycle — relies on `mrxshop`
having already loaded `mrxsupportdata`/`mrxrewarddata` as globals before our chunk, since we append
last), wired into `mrxshop` DEPS, **instrumented** with `Debug.Printf("RUSSIANHELI: …")`. Booting this
+ the blackbox log answers: did the chunk load (`chunk loaded`), what is the store's faction id
(`GetAllPotentialShopItems faction=…` — the likely V2 culprit), and did registration fire
(`catalog entry added` / `inserted into Pmc list`).

| round-2 | Loaded? | Item? | RUSSIANHELI log lines seen | faction id observed |
|---|---|---|---|---|
| V3fix | **HANG** (world-load, TRUNCATED 40%) | — | **none** (chunk never ran) | — |

### V3fix result + root cause
V3fix hung in world-load identically to V3/V4. loadprobe: TRUNCATED at phase 8, ending mid-asset
("1 outstanding"), **no `RUSSIANHELI` lines** → our chunk never executed. Cause: an appended chunk
is a **new asset hash** and needs its own **ASET entry**; `build_patch_wad --block-index` only
carried block 3185's *existing* 7018 entries. With no ASET row for `0x3679F003`, `mrxshop`'s DEPS
request for it was unresolvable → the asset op never completed → silent world-load wedge (not a
crash). **The empty-DEPS cycle fix was correct; the missing ASET entry was the real blocker.**

## Round 3 — V3fix2 (deployed)
`vz-patch-V3fix2.wad`: V3fix **+ an ASET entry** for `0x3679F003` (cloned from `mrxsupportdata`'s
row → block 3185, sub `0xFFFF`, type 35). This is the genuine **new-asset injection** the name-hash
solve enabled. Confirmed: `0x3679F003` now in the patch ASET, and `wad_simulator` consumes **644**
scripts (was 643) — it sees the new chunk. Same `RUSSIANHELI:` instrumentation.

| round-3 | Past loading screen? | Item in store? | RUSSIANHELI lines | faction id |
|---|---|---|---|---|
| V3fix2 | | | | |

**Lesson (documented):** adding a new resident script = (1) full resident-block replacement,
(2) append the chunk with `INFO`/`DEPS`/`BINN`, (3) wire its hash into a non-cyclic parent's DEPS,
(4) **add an ASET entry for its hash** (block-idx + sub `0xFFFF` + type 35). Step 4 is the one that
bites — without it the loader wedges silently.

## What each outcome means
- **V1 appears** → resident scripts *are* accessed per-hash from the patch overlay; per-hash is the
  simple path. "Overlaid but not accessed" disproven for scripts.
- **V1 fails, V2 appears** → per-hash override is ignored for resident scripts; full-block
  replacement is required. In-place editing of on-path scripts is sufficient.
- **V3/V4 appears** → new scripts can be added and pulled via a DEPS edge; whichever host worked
  is the live pull-point for future new content. (If V3 works and V4 doesn't, `mrxshop` is pulled
  but `mrxsupportdata` isn't at the right time, etc.)
- **Crash on opening the store** → the recompiled/minted bytecode loaded but faulted; capture the
  EIP. **Crash only on buy/spawn** → script path is fine; it's the spawn/model path.

Once a variant registers the item cleanly, layer the model override (`0x3177639B` → russian, the
proven per-hash path) onto it for the full result.
