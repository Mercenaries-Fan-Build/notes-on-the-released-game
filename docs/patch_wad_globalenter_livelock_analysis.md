# Patch-WAD GlobalEnter busy-poll livelock + data-as-code faults — live-debug analysis

> **⚠️ STATUS UPDATE (2026-06-04): the "GlobalEnter livelock" in this doc is a TEST-HARNESS ARTIFACT, not a shipping bug.**
> §13 (2026-06-03) establishes that the `0x2004FFB0` / `0x004B1180` spin **does not occur with the full
> `vz-patch.wad`**. It is manufactured by `trim_patch_wad` dropping block 2196 (`scripts_vz`) while keeping
> `commonlocations` → `dlccon*` references, which orphans the contract ASET entries and yields
> `STATUS_OBJECT_NAME_NOT_FOUND`. With the complete WAD the contracts resolve and the spin never appears.
> The harness that produced this was a developer-experience detour, now retired.
> **Treat §1–§11 as superseded by §12–§13.** The real full-WAD load faults are: render-view `0xFFFF` stall
> (block 18), NULL-ptr AV at `0x858DB8` (effect-object table miss), and the compact-ECS byte-order converter
> gap (blocks 0/4/15/16/17). Do **not** chase the GlobalEnter livelock as a load blocker.

**Date:** 2026-06-02  
**Binary:** `…\Mercenaries 2 World in Flames\Mercenaries2.exe` (cracked v1.1, image base
`0x00400000`, VAs map 1:1 — same EXE as the render-view and spatial-hash analyses).  
**Repro target:** Xbox-360→PC DLC patch WAD `data\vz-patch.wad` on VZ level load.  
**Method:** read-only live x32dbg observation (register dumps, memory reads, disasm range
reads — **no** breakpoints, **no** thread switching). Per-minute lightweight polling
(`IsDebugging`/`IsDebugActive` + one `GetThreadList`) plus five GUI-paused captures.  
**Primary artifact:** `output/_scratch/xdbg_monitor_20260602T225505Z.jsonl` (5 samples + 1
summary row).  
**Status:** **THREE distinct faults isolated this session.** Fault #1 (script NULL deref)
**FIXED** by removing the offending ASI. Faults #2 (GlobalEnter livelock) and #3
(data-as-code control-flow corruption) are **patch-WAD-induced, ASI-exonerated, OPEN** —
root cause not yet pinned to a specific block; the 334 unconverted textures are the prime
data-side suspect (hypothesis, not proven).

> **Related crash docs:** this analysis is distinct from but cross-linked with
> [`render_view_handle_crash_analysis.md`](render_view_handle_crash_analysis.md) (the
> `0xFFFF` handle-table over-resolve) and
> [`spatial_hash_crash_analysis.md`](spatial_hash_crash_analysis.md) (the CHDR/EFCT
> byte-swap gate crashes). The render-view slot stayed intact throughout this session
> (see §4), so the render-view path is **not** involved in the faults documented here.

---

## 1. Fault #1 — script-command NULL deref at `0x005AE372` (ASI-caused, FIXED)

**Fault site:** `0x005AE372`, `mov eax,[esi+0x40]` with `esi = NULL` → read of `0x40`.

**Root cause (HIGH confidence):** `mod_enable.asi` (game `scripts\mod_enable.asi`) runs a
Lua bootstrap `import("modloader")` on VZ level load. The requested script asset is:

| Field | Value |
|-------|-------|
| name | `"modloader"` |
| `pandemic_hash_m2("modloader")` | `0xF0E7B55E` |
| type | `0x42498680` ("script") |

That script asset is **ABSENT** from both base and patch WADs. Confirmed by a canonical
FFCS ASET parse:

| WAD | ASET rows | `0xF0E7B55E` hits |
|-----|-----------|-------------------|
| `vz.wad` (base) | 30,645 | 0 |
| `vz-patch.wad` (patch) | 5,448 | 0 |

The script-type registry returns NULL for the unresolved hash, and the stock script
command then dereferences it at `0x005AE372`. This is a **mod-induced missing-asset**
fault: `mod_enable.asi` imports a script that `tools/build_mod_patch.py` never packaged.

**Fix applied & verified:** removed `mod_enable.asi` from `scripts\` → the crash is
eliminated (fresh boot never faulted at `0x005AE372`). The historic crash-guard that used
to sit at `0x005AE372` lived in the now-absent `dlc_enable.asi`; it was only a band-aid
masking the unresolved import, not a real fix.

**Real fix if the mod is wanted:** author `modloader.lua` and rebuild the patch WAD so
`0xF0E7B55E` resolves; do not reintroduce the band-aid guard.

---

## 2. Fault #2 — GlobalEnter busy-poll livelock (patch-WAD-induced, OPEN)

**Loop:** main thread spins in the loop at `0x004B1180` ("GlobalEnter"). Observed
`cip = 0x004B1215`; the loop-frame return address on the stack is `0x004B1201`
(`0x004B1180 + 0x81`). Paired with the streaming worker thread started at `0x00876400`,
which sits in `NtDelayExecution` (a Sleep-poll).

### Cycle-delta evidence — the textbook paired busy-poll signature (HIGH confidence)

From `output/_scratch/xdbg_monitor_20260602T225505Z.jsonl`, samples 1–3 (the process was
left RUNNING and only GUI-paused to read). Per-minute cycle growth:

| Thread | TID | s2 Δcyc/min | s3 Δcyc/min |
|--------|-----|-------------|-------------|
| main (`0x004B1180` loop) | 14692 | +469.3 ×10⁹ | +449.7 ×10⁹ |
| worker `0x00876400` (`NtDelayExecution`) | 7088 | +462.1 ×10⁹ | +434.7 ×10⁹ |
| idle reference thread | 5160 | +5.6 ×10⁶ | +5.6 ×10⁶ |

Main and the `0x876400` worker burn **~440–470 billion cycles/minute in lockstep**, while
every other thread stays flat at **~5 million/minute**. Healthy idle workers sit in
WrQueue/event waits totaling only tens of millions of cycles. The two hot threads moving
together at ~5 orders of magnitude above the idle floor is the canonical paired
busy-poll / spin signature.

### Reproduction conditions — patch-WAD-induced, ASI-exonerated (HIGH confidence)

This reproduces with **PATCH WAD ONLY and ZERO ASIs loaded**. Therefore it is **not**
ASI-induced and is **not** masked by any ASI's `STREAMING_FIX`. A clean vanilla boot (no
patch, no ASIs) succeeds; a patch-WAD-only boot (no ASIs) reproduces #2 and then #3.

### Interpretation (MEDIUM confidence)

The GlobalEnter work-queue drain loop is perpetually **re-enqueuing a streaming WAD-block
container item that never passes its readiness gate**: main spins draining/re-checking the
queue while the `0x876400` streaming worker Sleep-polls for a completion that never
arrives. The readiness predicate never satisfies, so neither thread makes forward
progress.

---

## 3. Fault #3 — data-as-code control-flow corruption (patch-WAD-induced, OPEN)

Two instances of the same class were observed: a saved/indirect target that is a **data
object executed as code**, not a valid code address.

### 3a. `cip = 0x00000B70` (earlier run) — corrupted saved return address

A `ret` popped a corrupted saved return address `= 0x00000B70` (proof: `esp-4` still held
`0xB70` post-pop). The same value mirrored a heap object field `[edi+0x14] = 0x00000B70`
with `edi = 0x4743A1E0`. That object had:

- **No vtable** (`[edi+0] = 0`).
- Fields that read as small **DATA** (id / flags / count), not pointers.
- Adjacency to freed-heap fill `0xFEEEFEEE`, with a UTF-16 `\??\C:\U…` NT path nearby.

**Refuted hypothesis:** this is **NOT** a mis-byteswapped pointer — `0xB70` byte-reversed
is `0x700B0000`, which is not a valid module/code address.

**Classification:** use-after-free / type-confusion — a freed or wrong object's data was
treated as control flow.

### 3b. `cip = esi = 0x2004FFB0` (patch-only monitored run, samples 4–5) — wild indirect transfer

Samples 4–5 of the monitor JSONL captured a `PAUSED_FAULT` with `cip == esi ==
0x2004FFB0`: a wild indirect call/jmp through a data pointer, into a non-code heap address
in the `0x20000000` range. The memory at the target is a **record, not instructions** —
its first words were:

```
0xFFFFFFFF 0xFFFFFFFE 0x00000001 0x00003964(=14692, the main TID)
0x00000000 0x020007D0 0x00001B6A 0x00000000
```

(The embedded `0x00003964 = 14692` is the main thread's TID — confirming this is a
bookkeeping record, not code.)

**Stack unwind through the GlobalEnter loop** (from sample 4 `stack_esp`):

| Return address | Meaning |
|----------------|---------|
| `0x004B1201` | GAME — GlobalEnter loop frame (`0x004B1180 + 0x81`) |
| `0x004C9C80` | GAME |

**This links #2 and #3:** the wild transfer unwinds through the GlobalEnter loop frame, so
the livelock and the data-as-code corruption are the same failure chain — the GlobalEnter
loop processes a malformed/never-ready patch-WAD streaming item and eventually transfers
control into that item's data (`0x2004FFB0`; and, in the earlier run, `0x00000B70`).

The faults were **NOT resumed** (read-only protocol; see §6).

---

## 4. Render-view slot stayed intact (NOT involved)

Throughout all five samples, the render-view singleton slot `[0x00DFC2F8]` held its valid
resolved pointer `0x017CFAF0` (the live render-view sub-object). It was **never** seen as
`0xFFFF`. The non-idempotent handle over-resolve documented in
[`render_view_handle_crash_analysis.md`](render_view_handle_crash_analysis.md) is **not**
the mechanism here, and the cross-WAD dedupe of redundant resident singletons (§7 of that
doc) that fixed the duplicate render-view registration is **holding**.

---

## 5. Cross-cutting conclusions

- **ASIs are exonerated** for the livelock (#2) and the data-as-code faults (#3). Only the
  script crash (#1) was ASI-caused (`mod_enable.asi`). Vanilla clean boot (no patch, no
  ASIs) succeeds; patch-WAD-only boot (no ASIs) reproduces #2 → #3.
- **Render-view path is not involved** (§4): slot `[0x00DFC2F8]` stayed `0x017CFAF0`.
- **Patch WAD data defect is the prime suspect (HYPOTHESIS, not proven):**
  `tools/validate_patch_wad.py` reports **334 CRITICAL** "texture still in Xbox 360 format"
  issues — unconverted FourCC `0x1a200152` / `0x1a200154` found at texture `INFO` bytes
  `[14:18]` (the `INFO`/`_TYPE_TEXTURE` check, `validate_patch_wad.py` Check 1). A
  malformed block sitting in the streaming queue is a plausible single mechanism for **both**
  the never-satisfied readiness gate (livelock #2) **and** the data-as-code corruption (#3:
  the loop chokes on an item whose body is misread, then transfers control into it).
  **This is not yet proven to be THE item the GlobalEnter loop chokes on.**
- **Validator false-positives / cosmetics:** the same validator run also emitted **28 WARN**
  `ecs_node` "Expected ASCII name prefix" issues (Check 6, `tag == "info"`,
  `type_hash 0xE6B81A54`) that are **false positives** — those `info` bodies are not
  plain-ASCII-prefixed but are otherwise valid. Separately, `validate_patch_wad.py` raises a
  **cosmetic `UnicodeEncodeError`** when it prints the `⚠` glyph in the summary lines
  (`main()`, after all findings have already printed) on the Windows `cp1252` console; it is
  **non-blocking** (all findings print first) and could be fixed with an encoding-safe print
  — **left unfixed** here by instruction.

---

## 6. Debugger fragility note (protocol)

Setting breakpoints, switching threads, or reading process memory **while the process was
HOT** (spinning in the livelock) crashed x32dbg multiple times. The safe protocol adopted
afterward, which was stable:

- **Read-only only:** `GetRegisterDump` / `MemoryRead` / `DisasmGetInstructionRange`.
- **No breakpoints, no thread-switch.** GUI-pause only when a snapshot was needed.
- **Lightweight per-minute polling:** `IsDebugging` / `IsDebugActive` + a single
  `GetThreadList` per minute — stable across the whole session.

This is why all evidence here is observational (register/memory/cycle snapshots) rather
than from instrumented breakpoints.

---

## 7. Open items / next-step backlog

1. ~~**Root-cause the GlobalEnter loop `0x004B1180`**~~ **Partial (2026-06-03):**
   220/220 unconverted textures were a **real defect** (fixed; validator clean) but **not the
   sole livelock cause** — bisect §8 pins the remaining trigger to blocks **1–1099**.
   Original texture diagnosis: `tools/diagnose_unconverted_textures.py` →
   `output/_scratch/unconverted_texture_diagnosis.json`.

2. ~~**Fix the 334 unconverted textures**~~ **FIX IMPLEMENTED (2026-06-03) — necessary but NOT sufficient:**
   - Rust: expanded `apply_texture_untile` in `convert.rs` (full / prefix / single-mip /
     tail-page / stream-page + INFO-only stubs with `FF FF` resident sentinel).
   - Python mirror: `xbox_texture_codec.convert_streamed_texture` + `ucfx_be_to_le`.
   - Post-fix on existing WAD: `tools/fix_patch_textures.py` →
     `output/data/vz-patch-fixed.wad` (**0 CRITICAL**, 0 unconverted textures;
     validate 2026-06-03). **Redeploy confirmed; GlobalEnter livelock persists** — see §8.

3. **(Optional) Fix the cosmetic `UnicodeEncodeError`** in `validate_patch_wad.py`'s summary
   print (encoding-safe output / ASCII fallback for the warning glyph).

4. **Second-stage bisect (2026-06-03, §8):** culprit region narrowed to patch blocks
   **1–1099**; run `q1-lo` / `q1-hi` / `q2-lo` / `q2-hi` trims next.

---

## 8. Patch-WAD bisect results (2026-06-03)

**Artifacts:** `output/_bisection_results/` (14 variants × main-menu + load outcome snapshots;
index: `manifest.json`). Captured via `tools/capture_bisect_snapshot.py` + x32dbg MCP
(read-only, process paused).

### Outcome matrix

| Variant | VZ load | Blocks kept (approx.) | Notes |
|---------|---------|----------------------:|-------|
| **hi-half** | **PASS** | 1100–2195 | `PAUSED_IN_WORLD`; no GlobalEnter spin |
| **q3** | **PASS** | 1100–1649 | Same |
| **q4** | **PASS** | 1650–2195 | Same |
| lo-half | FAIL | 1–1099 | `PAUSED_LIVELOCK` @ GlobalEnter |
| **q1** | **FAIL** | 1–549 | Same failure class |
| **q2** | **FAIL** | 550–1099 | Same failure class |
| step2-retest | FAIL | 2191 (full − state overlays) | Baseline broken patch |
| no-bootstrap | FAIL | 2190 | Bootstrap not sole cause |
| no-base | FAIL | 2189 | dlc01_base + commonlocations not sole cause |
| no-c3 | FAIL | 1645 | Removing all 546 c3 cells not sufficient |
| no-dlc01-meshes | FAIL | 2081 | Removing all 114 dlccon blocks not sufficient |
| no-scripts-vz | FAIL | 2190 | scripts_vz path not sole cause |
| no-state | FAIL | 2191 | Same as step2-retest (state already ruled out) |
| no-top5-scan | FAIL | 2186 | Default scan suspects not sole cause |

All trims carry forward ruled-out indices **0, 4, 12, 15, 16, 17** and exclude bootstrap
**2196** on half/quarter cuts.

### Conclusion (HIGH confidence)

The GlobalEnter livelock is **induced by at least one asset in patch blocks 1–1099**
(lower half). Blocks **1100–2195 alone are load-clean** (hi-half reaches in-world).

**Both q1 and q2 fail independently** — each quarter is *sufficient* to trigger the hang
without the other. That implies either **two independent trigger blocks** (one in each
quarter) or **multiple blocks in each quarter** that can each trigger the same streaming
defect class.

### Failure signature (stable across all FAIL snapshots)

- Main + `0x876400` worker paired high cycle growth since main-menu pause.
- Queue ring / data object **`0x2004FFB0`** on stack; GlobalEnter loop ref **`0x004B1197`**.
- Stride gate **`[0x01176078] = 0x38`** — Transform pipeline reached before hang.
- Stuck stack record includes requester **`0x0148498C`** (same as pre-bisect session).
- PASS snapshots: main in game/heap code or `DelayExecution`; **no** `0x2004FFB0` spin.

### Content skew (why wholesale excludes failed)

| Content | q1 (FAIL) | q2 (FAIL) | q3 (PASS) | q4 (PASS) |
|---------|----------:|----------:|----------:|----------:|
| dlccon mesh blocks | 52 | 62 | 0 | 0 |
| terrain blocks | 83 | 82 | 1 | 4 |
| c3 cells | 125 | 62 | 229 | 130 |
| dlc01_base / commonlocations | 1 / 1 | — | — | — |

- **hi-half has zero dlccon** — strong correlation, but **`no-dlc01-meshes` on the full
  patch still livelocks**, so dlccon removal alone does not fix load when lower-half content
  remains.
- **q3/q4 carry hundreds of c3 cells and pass** — c3 cells are not universally toxic;
  the bad interaction is tied to **lower-index / load-relevant** blocks (dlccon, terrain,
  early c3, base bootstrap data in q1), not the c3 corpus as a whole.

### Ruled out as *sole* cause

Bootstrap @2196, dlc01_base @3, commonlocations @5, all dlc01_state overlays (already
excluded), scripts_vz path, all c3 cells, all dlccon blocks, texture INFO untile (220 fixes
deployed — validator clean, livelock unchanged).

### Recommended next bisect

1. **Within q1:** `keep-only-indices 1-274` vs `275-549` (find first failing slice).
2. **Within q2:** `keep-only-indices 550-824` vs `825-1099`.
3. **Combinatoric check:** `hi-half` blocks **plus** `q1-lo` only — confirms whether q1-lo
   triggers when upper-half assets are present (expected FAIL if q1-lo contains a trigger).
4. **Path-focused trims on lo-half only:** `--exclude-path-substr terrain` and
   `--exclude-path-substr dlccon` on a **lo-half WAD** (not full patch) to see if either
   class clears the hang within the known-bad index range.

Regenerate trims: `tools/emit_bisect_variants.py` · capture: `tools/capture_bisect_snapshot.py`.

---

## 9. Additive bisect results (2026-06-03) — THREE distinct faults, not one

**Artifacts:** `output/_bisection_results/{arena-hi,blk18-hi,blk464-hi,arena-resident-hi,
dlccon-core-hi,q1-c3-hi,q2-lo-hi,q2-hi-hi}/`. Each variant = known-good **hi-half
(1100–2195)** + a lower-half subset. This is the decisive round: it shows the lower half
does **not** share one bug — the §8 "all FAIL" matrix conflated **three independent fault
classes** that happen to coexist in blocks 1–1099.

### Outcome + fault matrix

| Variant | Lo-half added | Outcome | Fault class | Key evidence |
|---------|---------------|---------|-------------|--------------|
| **blk464-hi** | 464 (`resident`) | **PASS** | — | in-world; render-view `0x017CFAF0` |
| **blk18-hi** | 18 (`dlccon004_roads`) | FAIL | **render-view 0xFFFF stall** | slot `0x00DFC2F8` → `0x0000FFFF`; no `0x2004FFB0` |
| **arena-hi** | 1–19 | FAIL | render-view 0xFFFF stall | slot → `0x0000FFFF` |
| **arena-resident-hi** | 1–19 + 464 | FAIL | render-view 0xFFFF stall | slot → `0x0000FFFF` (464 does not rescue) |
| **dlccon-core-hi** | 2,3,6,8,10,13,18 | FAIL | render-view 0xFFFF stall | slot → `0x0000FFFF` |
| **q1-c3-hi** | 20–549 (c3, no arena) | FAIL | **NULL-ptr AV** | `0x00858DB8` `mov cx,[eax+8]`, `eax=0` |
| **q2-lo-hi** | 550–824 | FAIL | **GlobalEnter livelock** | `cip 0x87458F`, esi `0x2004FFB0` |
| **q2-hi-hi** | 825–1099 | FAIL | GlobalEnter livelock | `cip 0x87458F`, esi `0x2004FFB0` |

### The three faults map to three regions

1. **Arena blocks 1–19 → render-view `0xFFFF` handle crash.** Render-view slot
   `[0x00DFC2F8]` degrades from healthy `0x017CFAF0` to `0x0000FFFF` — the over-resolve
   documented in [`render_view_handle_crash_analysis.md`](render_view_handle_crash_analysis.md).
   **Block 18 (`dlccon004_roads`) alone is sufficient** (`blk18-hi`). Adding the script
   resident 464 does **not** fix it (`arena-resident-hi`), so the 464 redundant-singleton
   path is **not** the driver in this build.
2. **q1 c3 cells 20–549 → NULL-ptr AV at `0x00858DB8`** (`mov cx,[eax+0x08]`, `eax=0`),
   unwinding through the GlobalEnter caller chain (`0x004B11D8 → 0x004C9C80`). Same class as
   the `step2-retest` NULL AV. **Distinct from the livelock** (it faults, doesn't spin).
3. **q2 blocks 550–1099 → GlobalEnter busy-poll livelock** — the canonical `0x87458F` /
   esi `0x2004FFB0` paired spin from §2/§8. **This is the only region that reproduces the
   true livelock in isolation.**

### Why the §8 subtractive matrix looked uniform

`q1` (1–549) contains **both** arena (1–19) and c3 (20–549), so it could fault via either
the render-view crash or the NULL AV — whichever fires first wins, and the single capture
labelled it "livelock-class." Splitting arena off (`arena-hi` vs `q1-c3-hi`) separates them.
**`lo-half`/`q1`/`q2` all "FAIL" but for three different reasons.**

### Notable corrections

- **Block 464 is exonerated in isolation** (`blk464-hi` PASS). The resident-singleton
  duplication is either already stripped in this build or only harmful with arena blocks
  present — either way it is **not** an independent load-blocker here.
- **Block 18 is the render-view trigger**, consistent with the spatial-hash analysis naming
  18 as the primary toxic block — but the *runtime symptom* here is the `0xFFFF` render-view
  degrade / loading stall, not the `0x248BB*` spatial-hash AV (that on-disk CHDR defect is
  fixed in the converter; this is a separate runtime effect of the same block).
- The "GlobalEnter livelock" is **one of three** faults, localized to **q2 (550–1099)**.

### Recommended next bisect (per fault)

1. **Render-view (arena):** single-block `+hi` for each of 1–19 to confirm 18 is the *only*
   trigger, or find co-triggers. Then root-cause the `0xFFFF` over-resolve on block 18's
   registered render object.
2. **NULL AV (q1 c3):** split `20–284` vs `285–549` (`+hi`); read `[ebp+8]`→object at the
   `0x00858DB8` fault to name the asset whose `+0x08` field is read through a NULL base.
3. **Livelock (q2):** split `550–687` vs `688–824` and `825–962` vs `963–1099` (`+hi`);
   at the spin read requester `0x0148xxxx` to name the unresolved streamed texture.

Each region needs its own fix; clearing one will reveal the next at load time.

---

## 10. Arena re-bisect with block 18 removed (2026-06-03) — livelock is SYSTEMIC, not block-specific

**Artifacts:** `output/_bisection_results/{arena-1-10-hi,arena-1-10-clean-hi,
arena-11-20-no18-hi,arena-11-20-clean-hi}/`. Each variant = hi-half (1100–2195) + an
arena sub-range, **all with block 18 (`dlccon004_roads`) absent**. The "clean" pair also
removes the rest of the known-bad road/race family (6 `dlccon002_roads`, 13
`dlccon002_race`).

### Outcome + fault matrix (all FAIL, all the same fault)

| Variant | Arena blocks | Known-bad removed | Outcome | render-view `[0x00DFC2F8]` | data obj | GlobalEnter caller |
|---------|--------------|-------------------|---------|----------------------------|----------|--------------------|
| **arena-1-10-hi** | 1–10 | none (6 present) | livelock | `0x017CFAF0` ✅ healthy | `0x2004FFB0` | `0x004B1201` |
| **arena-1-10-clean-hi** | 1–10 | 6 | livelock | `0x017CFAF0` ✅ healthy | `0x2004FFB0` | `0x008745B6` |
| **arena-11-20-no18-hi** | 11–17,19,20 | 18 (13 present) | livelock | `0x017CFAF0` ✅ healthy | `0x2004FFB0` | `0x00874577` |
| **arena-11-20-clean-hi** | 11–17,19,20 | 13, 18 | livelock | `0x017CFAF0` ✅ healthy | `0x2004FFB0` | `0x00874577` |

All four: `kind = globalenter_livelock`, main+worker paired high cycle growth, esi/target
`0x2004FFB0`, stride gate `[0x01176078] = 0x38`. The `0x2004FFB0` record carries the classic
pending sentinel (`u32[0..1] = 0xFFFFFFFF / 0xFFFFFFFE`, then `0x020007D0`, `0x00001B6A`).

### Two firm conclusions

1. **Removing block 18 unmasks the GlobalEnter livelock — it does not fix the load.** With 18
   present (`blk18-hi`, `arena-hi`, §9) the **render-view `0xFFFF` stall fires first** and
   hides everything behind it. With 18 absent, render-view stays **healthy `0x017CFAF0`** in
   all four runs and the load proceeds far enough to hit the canonical `0x2004FFB0`
   GlobalEnter spin. The render-view crash was an **earlier, masking** symptom; the livelock
   is the deeper terminal fault.

2. **The livelock is systemic across DLC arena content, not tied to a single block.** Arena
   **1–10** and **11–20** share *no* blocks, yet **both** reproduce the identical
   `0x2004FFB0` spin when added to the clean hi-half (which passes alone). Stripping the
   known-bad road/race family `{6,13}` from each half changes **nothing**. So:
   - `{6, 13, 18}` are **render-view-stall** triggers — **not** the livelock cause.
   - The `0x2004FFB0` livelock fires for **essentially any** arena DLC geometry/state block,
     which is why §8's `q1`/`q2`/`lo-half` and now both arena halves all "FAIL" alike, and
     why §9's "localized to q2 (550–1099)" was **too narrow** — q2 was just the only range
     in that round with block 18 absent *and* no c3-NULL-AV firing first.

### Consequence for strategy — stop per-block bisecting the livelock

Two disjoint block sets reproduce the same hang, so **block bisection cannot isolate it**.
Pivot from "which block" to "**which streaming request at `0x2004FFB0` never completes**":

1. At the spin, dump the `0x2004FFB0` record + back-chase its requester
   (`0x0148xxxx` / `0x0148498C` from §8) and the worker frame at `0x7705951C` to name the
   **asset handle / type_hash** being waited on.
2. Check whether that handle resolves to a hi-half asset that is present but never marked
   ready (streaming page never satisfied) vs. a DLC-only asset with no PC residency — the
   former points at the INFO/residency sentinel, the latter at a missing fallback path.
3. Decide fix at the streaming layer (force-resident the waited asset, or break the
   busy-poll's never-satisfied predicate), not by deleting arena blocks.

### Layered-fault model (current best understanding)

```
load DLC arena content
   ├─ block 18/13 present? ──► render-view 0xFFFF stall   (fix: remove/repair 18)  [fault A]
   └─ render-view healthy ──► GlobalEnter livelock @ 0x2004FFB0                     [fault B, SYSTEMIC]
                               (c3-only ranges instead hit NULL-ptr AV @0x858DB8)  [fault C]
```

Fault A masks B; clearing A (drop block 18) exposes B across the whole arena. C is the
c3-cell variant seen in `q1-c3-hi`. **B is now the blocking issue** and is not block-local.

---

## 11. Compact-ECS `info` byte-order bug (2026-06-03) — PROVEN, converter gap

**Deterministic proof (rosetta byte-exact vs retail `game-files/vz.wad`, LE ground truth).**

`ecs_node` (`0xE6B81A54`) component descriptors use two `info` layouts:

- **Full** (retail PC uses this everywhere): `[ASCII name]\0 [u32 name_hash LE] [u32…LE metadata]`.
- **Compact** (DLC authored some this way): `[u32 comp_hash] [3× u32 metadata]`, 16 bytes, no
  ASCII name.

`tools/ucfx_be_to_le.py::_convert_ecs_info()` (≈line 1699) only handles the **full** form: it
does `be.find(b"\x00")`, computes `u32_start = nul+1`, and if `u32_start+16 > len` it returns
the body **unchanged**. The compact 16-byte form trips exactly that bail → **passes through
big-endian, unswapped**.

### Byte-exact comparison (retail full-form hash vs patch compact-form hash)

| Component (hash) | Retail PC `vz.wad` (LE) | Patch compact (BE, unswapped) |
|------------------|-------------------------|-------------------------------|
| Transform `0x753EB623` | `23 b6 3e 75` + meta `01 00 00 00` | `75 3e b6 23` + meta `00 00 00 01` |
| HibernationControl `0xE18AFD65` | `65 fd 8a e1` + `53 00 00 00` | `e1 8a fd 65` + `00 00 00 53` |
| Name `0x1DE5C824` | `24 c8 e5 1d` | `1d e5 c8 24` |
| Label `0x06DA8775` | `75 87 da 06` | `06 da 87 75` |
| Path `0xBCFE6314` | `14 63 fe bc` | `bc fe 63 14` |

Each patch value is the exact byte-reverse of retail. The LE engine therefore reads e.g.
`0x23B63E75` instead of `0x753EB623` → component **unidentifiable**, and the metadata u32s
decode as huge garbage (`0x01000000` instead of `1`).

### Blast radius (whole patch WAD, all 2197 blocks)

```
compact ecs info with comp hash BE (WRONG/unswapped): 21
compact ecs info with comp hash LE (correct):          0
affected blocks: 0, 4, 15, 16, 17   (terrain + dlccon003/missionhub state overlays)
components: Transform×5 Hibernation×4 Name×4 Label×2 ObjectRegistry×2 Path×2 LaneData×1
```

These five blocks overlap the arena ranges that livelock (§10): `arena-1-10-clean` kept block
**4**; `arena-11-20-clean` kept blocks **15,16,17** — both halves carried corrupt-ECS blocks.

### Status: causal link tested (2026-06-03) — SUFFICIENT, not NECESSARY

Two control trims captured (`output/_bisection_results/{ecs-corrupt-hi,arena-noecs-hi}/`):

| Variant | = hi-half + | Tests | Outcome | render-view | data obj |
|---------|-------------|-------|---------|-------------|----------|
| `ecs-corrupt-hi` | only {0,4,15,16,17} | sufficiency | **FAIL** livelock | — (MCP dropped) | `0x2004FFB0` |
| `arena-noecs-hi` | arena 1–20 minus {0,4,15,16,17}+{6,13,18} | necessity | **FAIL** livelock | `0x017CFAF0` ✅ | `0x2004FFB0` |

**FAIL / FAIL → the compact-ECS bug is one *independent sufficient* trigger, but NOT the
sole cause.** `ecs-corrupt-hi` (only the 5 corrupt blocks) hangs, so they alone reproduce the
livelock. But `arena-noecs-hi` also hangs while carrying **zero** unconverted compact records
(verified by simulating `_convert_ecs_info` on every `ecs_node` `info` body patch-wide —
`output/_scratch/ecs_unconverted_scan.py`: all 13 unconverted bodies are in {0,4,15,16,17};
none in the arena-noecs blocks 1,2,3,5,7,8,9,10,11,12,14,19).

**Conclusion:** the `0x2004FFB0` livelock is a **shared streaming wait reached by multiple
arena content paths**. The compact-ECS byte-order defect is real and must be fixed (proven
byte-exact), but fixing it will **not** clear the load hang on its own — at least one more
independent trigger exists in the clean DLC arena geometry. Root-causing should target the
`0x2004FFB0` streaming request itself (§10 plan), which is the common denominator.

### Fix (still required for correctness, independent of the livelock)

Add a compact-form branch to `_convert_ecs_info` that swaps `[u32 comp_hash][n× u32]` when
there is no valid leading ASCII identifier; mirror into the parity harness; rebuild patch WAD;
re-run `validate_patch_wad` + `verify_ucfx_endian`. Probe: `output/_scratch/ecs_info_probe.py`.

---

## 12. Live root-cause: the `0x2004FFB0` wait is unresolved DLC **contract** ECS assets (2026-06-03)

Inspected the running livelock directly via x32dbg MCP (paused mid-spin, then resumed).
Signature confirmed: main+streaming-worker (`start 0x876400`) paired at ~100e9 cycles,
**`lastStatus = STATUS_OBJECT_NAME_NOT_FOUND`** on the main thread.

### Following the stuck work item

```
0x2004FFB0 (work item)
  +0x14 → 0x020007D0   = generated code thunk (bytes 90 90 90 90 50 … = nop;nop;nop;nop;push eax)
  +0x28 → 0x208CE510   = array of {heap 0x1ED2A240, static 0x0148A6FC, 0x3E018014, 0x00023D5E}
                          (0x3E018014 / 0x00023D5E recur on every stuck-item stack, §9–§11)
0x1ED2A240 (registry)  = ecs_node container — type_hash 0xE6B81A54 at +0x08 —
                          strlen-prefixed ASCII entries, stride 0x1C:
                          [u32 flags=0x204][u32 guid][u32 len=9][16-byte name]
```

### The unresolved assets are named DLC **contracts**

Read straight out of the registry (name + adjacent guid u32):

| Name | guid field | | Name | guid field |
|------|-----------|---|------|-----------|
| `gurcon050` | `0x18D3F2A8` | | `oilcon005` | `0xA79ED346` |
| `pmccon032` | `0x8F61C466` | | `gurjob002` | `0xA3253E8B` |
| `allcon002` | `0x59575914` | | `oilcon002` | `0x595724E6` |
| `oilcon052` | `0xC576A1A9` | | `pircon004` | `0x1B237E64` |
| `oiljob011` | `0x672F5772` | | `chicon001` | `0xE13AFA54` |

These are guerrilla/PMC/allied/oil/pirate **contract + job** entities — the `dlccon00x`
("DLC contract") block family. The adjacent u32 is **not** `pandemic_hash_m2` of the name
(checked: 0/10) — likely an instance GUID — but the strlen-prefixed strings are unambiguous.

### Root cause (common denominator for all §10/§11 livelocks)

The streaming/load busy-poll at `0x2004FFB0` is waiting on **contract ECS assets that resolve
to `STATUS_OBJECT_NAME_NOT_FOUND`**. Any DLC content that references contracts (the `dlccon`
blocks in *both* arena halves, the state overlays in `{0,4,15,16,17}`) reaches this same wait —
which is exactly why §10/§11 saw multiple disjoint block sets hang on the *same* object and why
removing the compact-ECS-corrupt blocks didn't help (`arena-noecs-hi` still has `dlccon004`,
`dlccon001`, …).

### Next deterministic step (no debugger needed)

Decide **missing vs. misregistered**: search the patch WAD's decompressed `dlccon00x` blocks /
ASET for these contract names + GUIDs.
- **Absent** → the contract assets were never ported into `vz-patch.wad` (build/extraction gap).
- **Present** → they exist but are registered under a name/hash the loader can't match
  (lookup-key conversion bug) — tie back to ASET/PTHS hashing in the DLC port.

This determines whether the fix is "port the missing contract assets" or "correct the contract
asset lookup key", and is independent of the (separately-required) compact-ECS byte-order fix.

---

## 13. Root-cause identified: bisect-induced ASET orphan, not a converter bug (2026-06-03)

### The `0x2004FFB0` GlobalEnter livelock is a **testing artifact**

Following the data trail from §12 to its conclusion:

1. **All 10 contract names exist in the retail base-game `vz.wad`** (block 3197, `scripts_vz`),
   with `u32_1=0xFFFFFFFF`, `low16=0xFFFF`, `type_id=35`.
2. **The full patch WAD also registers them** — on block 2196 (`scripts_vz` DLC bootstrap),
   with `low16 = 0x0070..0x006A` (sub-entry offsets, not `0xFFFF`).
3. **`trim_patch_wad` excludes block 2196** (the `BOOTSTRAP` constant) from every bisect
   variant, but **keeps `commonlocations` (block 5)** — which directly references
   `dlccon001`–`dlccon004`, triggering contract script `import()` calls.
4. With block 2196 trimmed, the patch ASET no longer carries the contract entries. But the
   retail base-game ASET *does* point to block 3197 — **except the "last-opened-file wins"
   asset lookup cannot find contract bytecodes inside the DLC content blocks** because those
   blocks are ECS structure / mesh / placement data, not script containers. The engine's
   streaming worker issues `STATUS_OBJECT_NAME_NOT_FOUND` → GlobalEnter spin at `0x2004FFB0`.

### Proof: hi-half passes, arena-with-commonlocations fails

- **hi-half** (blocks 1100–2195, no `commonlocations`, no `scripts_vz`): **PASS** — no
  contract import references → no lookup → no livelock.
- **arena-noecs-hi** (arena 1–20 minus corrupt-ECS/known-bad, includes `commonlocations`):
  **FAIL** — `commonlocations` references `dlccon001–004` → contract import → lookup fails →
  `STATUS_OBJECT_NAME_NOT_FOUND` → GlobalEnter livelock.
- The full patch (`step2-retest`, 2191 blocks including block 2196 `scripts_vz`): hit
  **NULL-ptr AV** (`0x858DB8`), **not** the GlobalEnter livelock — the contract scripts
  *were* found because block 2196 was present.

### Consequence

The `0x2004FFB0` GlobalEnter livelock **does not exist in the full patch WAD**. It is an
artifact of `trim_patch_wad` breaking the ASET/block dependency graph by including content
blocks (`commonlocations` → `dlccon*`) but excluding the script block they reference (2196).

**This means the §8/§9/§10/§11 "three faults" matrix over-counted:** the "systemic GlobalEnter
livelock" was not present in the shipping build. The actual load faults in the full patch are:

| Fault | Cause | Status |
|-------|-------|--------|
| Render-view `0xFFFF` stall | Block 18 (`dlccon004_roads`) | Confirmed (§9) |
| NULL-ptr AV at `0x858DB8` | c3 cells / general load-path (original `step2-retest`) | Open |
| Compact-ECS byte-order bug | Blocks {0,4,15,16,17} — BE info bodies not swapped | **Proven converter gap** (§11); correctness fix required |

The NULL-ptr AV is now the **primary remaining load blocker** for the full patch. The
render-view stall from block 18 fires before it in many configurations, so removing or
fixing block 18 is prerequisite to isolating the NULL AV cleanly.

### Recommendations

1. **Fix the compact-ECS byte-order bug** (§11) — proven wrong regardless of livelock.
2. **Fix block 18** render-view trigger (§9) — prerequisite for clean NULL-AV isolation.
3. **Investigate the NULL-ptr AV at `0x858DB8`** with the full rebuilt patch (both above
   fixes applied) — this is the real remaining load blocker.
4. **Do not exclude block 2196 from bisect trims** that include `commonlocations` or any
   `dlccon*` content — it creates a false livelock.

---

## 14. TRUE root cause: ASET block-index namespace collision (2026-06-03)

**The patch WAD's ASET entries use patch-local block indices (0–2196) that the engine
interprets as base-game block indices (0–11370), causing 3,660 asset lookups to be
redirected to wrong blocks.**

### Audit results (retail `vz.wad` vs patch `vz-patch.wad`)

```
Retail ASET:   30,645 entries across 11,371 blocks
Patch ASET:     5,448 entries across  2,197 blocks
Shared hashes:  3,773 (assets that exist in both)

  Same block path (correct override):    113   (  3%)
  Different block path (CROSS-WIRED):  3,660   ( 97%)
  Type_id mismatches (wrong asset type):    42
  c3 cell → wrong c3 cell:                585
  c3 cell ↔ non-c3 block:                 263
```

### How it works (the bug)

1. `ffcs_patch_wad.py` line 216 writes ASET entries with `blk_idx << 16` where `blk_idx` is
   the block's position **within the patch WAD** (0–2196).
2. The engine's `RedVirtualDisk` "last-opened-file wins" lookup finds the patch's ASET entry
   for a shared hash and reads the block index as a **global** index.
3. But the patch's block 50 is `c30509`, while the base game's block 50 is something else
   entirely. The engine loads the wrong block → wrong data → crash/AV.

### Examples of cross-wiring

| asset_hash | retail block | patch block | result |
|------------|-------------|-------------|--------|
| `0xAA6E0024` | 1461 `c30885` (type 27) | 50 `c30509` (type 27) | **wrong c3 cell** |
| `0x8EA18772` | 3185 `resident` (type 28) | 2 `dlccon004` (type 27) | **type mismatch** |
| `0xB2B756EE` | 3185 `resident` (type 28) | 3 `dlc01_base` (type 27) | **type mismatch** |
| `0x1259A027` | 1700 `c31215` (type 27) | 8 `dlc01_speedcity` (type 27) | **wrong cell** |

### This explains ALL three fault classes from §9

1. **Render-view `0xFFFF` stall (block 18):** An asset hash that should resolve to a
   specific base-game block instead resolves to the DLC `dlccon004_roads` block — loading
   incompatible data into the render-view pipeline → handle corruption.
2. **NULL-ptr AV at `0x858DB8` (c3 cells):** 860 c3 cell hashes are cross-wired — the
   engine loads spatial partition data from the wrong cell → NULL pointer in the expected
   data structure layout.
3. **GlobalEnter livelock (bisect artifact, §13):** Trimming block 2196 broke contract
   script resolution — a secondary effect of the same ASET problem.

### The fix

The patch WAD's ASET must **not** re-register assets that already exist in the base game
with patch-local block indices, unless the patch intentionally overrides those assets. For
assets that are DLC-only (not in the base game), the block index is correct (it's
patch-local and the engine knows which WAD it came from). For shared assets, either:

**(a)** Don't include them in the patch ASET at all (let the base game's entries stand), or
**(b)** Offset the block indices so they don't collide with the base-game namespace.

The correct approach depends on how `RedVirtualDisk` resolves block indices across WADs.

### §14.1 — Engine ASET resolution: per-WAD namespace, NOT global (CONFIRMED)

Each WAD's ASET block index is **local to that WAD's INDX**. When `RequestAsset()`
finds a match in the patch WAD's ASET, it reads block `N` from the **patch WAD's
INDX** — not the base game's. The block index doesn't need to be globally unique
because the engine tracks which `_Library[]` entry (i.e. which WAD) supplied the hit.

Evidence:
- Both retail `vz.wad` and `vz-patch.wad` use `page_idx` starting at 65
  (= `DATA_OFFSET / PAGE_SIZE` = `0x208000 / 0x8000`). If there were a global
  namespace, the patch would need to start at `78294` (retail's last page + 1).
- `docs/patch_wad_format.md` §4: the engine opens base and patch WADs into
  separate `_Library[]` slots and searches in reverse. Each library maintains
  its own INDX.

This means the problem is **not** a namespace collision where two WADs compete
for global slot 50. The problem is that **the patch WAD falsely claims ownership
of 3,773 base-game assets**. When the engine asks "who has asset `0xAA6E0024`?",
the patch WAD answers "I do — it's in my block 50" (which is `c30509`). The
correct answer is "the base game has it — in retail block 1461 (`c30885`)."

### §14.2 — Source of the shared ASET entries (CONFIRMED)

All 3,773 shared entries were inherited directly from the **Xbox 360 DLC source WAD**:

```
Xbox DLC source:     30,553 ASET entries (11,087 blocks — FULL game + DLC)
Retail PC (vz.wad):  30,645 ASET entries (11,370 blocks — PC base game)
Patch WAD:            5,448 ASET entries ( 2,197 blocks — DLC port)

Shared retail<->patch:     3,773  — ALL from Xbox source (0 synthesized)
DLC-only (patch - retail): 1,622  — ALL synthesized during port (0 from Xbox)
```

The Xbox 360 DLC was distributed as a **complete replacement WAD** (the entire
base game + DLC content in a single file), not as a differential patch. When
`dlc_port.py` extracted the 2,197 DLC blocks, it also carried the Xbox ASET
rows referencing base-game assets that happened to be in those same blocks.

`dlc_port.py` has `dedupe_asset_hash_across_blocks()` for intra-patch dedup
(same hash on multiple patch blocks), but **no step strips ASET entries whose
`asset_hash` already exists in the retail base-game WAD**. The fix is option (a):
strip those 3,773 entries.

### §14.3 — The fix

#### v1 (REMOVED): blunt ASET collision strip

`_strip_base_game_aset_collisions()` was added to `dlc_port.py` and proved the
concept — the `dedup-strip` variant reached in-world.  However, it stripped ALL
3,773 shared entries, including ~113 legitimate DLC overrides (e.g. `scripts_vz`,
modified c3 cells), making DLC content invisible at runtime.  The function and its
associated base-game override mechanism (`_OVERRIDE_TYPE_HASHES`,
`_extract_base_entry_ucfx`, etc.) were removed during the "DLC port deoverride
cleanup" phase.

#### v2 (CURRENT): content-validated ASET filtering

`_validate_aset_against_content()` replaces the blunt strip with a precision
pass that uses each block's actual UCFX content as ground truth:

1. For each converted block: decompress, parse the UCFX entry table, collect the
   set of `asset_hash` values actually present in the block.
2. For each ASET entry on that block: **keep** if the hash exists in the block's
   content, **remove** if it does not (ghost/false-ownership entry).
3. Blocks with zero surviving ASET entries are dropped entirely.
4. Bootstrap `scripts_vz` entry hashes are protected (always kept).

This is strictly correct: an ASET entry should only claim ownership of an asset
that actually exists in that block's data.  No base-game comparison is needed —
the block's own content is the sole source of truth.

- **Legitimate overrides** (DLC block genuinely contains the asset): ASET entry
  survives → engine loads DLC version (last-opened-wins).
- **Ghost entries** (Xbox ASET inherited hash but block doesn't contain it): ASET
  entry removed → engine correctly falls through to retail `vz.wad`.

CLI flag `--no-aset-validation` skips this pass for debugging/comparison.

### §14.4 — Why base-game copies existed

The Xbox 360 DLC source is a **complete replacement WAD** (11,087 blocks = full
base game + DLC), not a differential patch.  `dlc_port.py` extracted only the
~2,197 DLC-range blocks, but those blocks contained UCFX entries for base-game
assets co-located alongside DLC content.  The existing `_OVERRIDE_TYPE_HASHES`
mechanism (`_extract_base_entry_ucfx`) further substituted Xbox UCFX bodies with
byte-identical PC retail copies for animations, textures, meshes, etc.  This
produced blocks that were correct in *data* but carried ASET registrations that
silently hijacked base-game asset lookups.

**Probe:** `output/_scratch/aset_source_audit.py`, `output/_scratch/aset_collision_audit.py`

---

## Appendix — VA / address map

| VA / address | Role |
|--------------|------|
| `0x005AE372` | script command `mov eax,[esi+0x40]` — NULL deref (fault #1) |
| `0xF0E7B55E` | `pandemic_hash_m2("modloader")`, type `0x42498680` (script) — absent from both WADs |
| `0x004B1180` | GlobalEnter work-queue drain loop (fault #2 spin) |
| `0x004B1215` | observed `cip` inside the GlobalEnter loop (samples 1–3) |
| `0x004B1201` | GlobalEnter loop-frame return address (`0x004B1180 + 0x81`) on the fault stack |
| `0x004C9C80` | GAME return address on the fault stack (caller chain) |
| `0x00876400` | streaming worker thread start (sits in `NtDelayExecution`, TID 7088) |
| `0x2004FFB0` | data record executed as code (fault #3b; `cip == esi`; embeds main TID 14692) |
| `0x00000B70` | corrupted saved return address (fault #3a; mirrors `[edi+0x14]`, `edi=0x4743A1E0`) |
| `0x00DFC2F8` | render-view singleton slot — `0x017CFAF0` healthy; **`0x0000FFFF` only when block 18 present (§9); stays healthy once 18 removed, exposing the livelock (§10)** |
| `0x1a200152` / `0x1a200154` | unconverted Xbox-360 texture FourCC at `INFO[14:18]` (334×, §5) |
| `0x00858DB8` | `mov cx,[eax+0x08]` with `eax=0` — NULL-ptr AV from q1 c3 cells 20–549 (§9) |
| `0x0087458F` | GlobalEnter caller site at the q2 livelock spin (esi=`0x2004FFB0`) (§9) |
| `0x020007D0` | generated code thunk referenced by the `0x2004FFB0` work item (+0x14) (§12) |
| `0x208CE510` | array of stuck-item records `{0x1ED2A240, 0x0148A6FC, 0x3E018014, 0x00023D5E}` (§12) |
| `0x1ED2A240` | `ecs_node` registry (type `0xE6B81A54`) listing unresolved DLC contract entities (§12) |
| STATUS_OBJECT_NAME_NOT_FOUND | main-thread `lastStatus` at the live livelock — contract asset lookup fails (§12) |

**Artifact:** `output/_scratch/xdbg_monitor_20260602T225505Z.jsonl` (samples 1–3 RUNNING/livelock, 4–5 PAUSED_FAULT, + SUMMARY).
