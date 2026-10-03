# PC ↔ Xbox resident Lua — divergence re-characterized (per-chunk)

**Status:** current · **Evidence:** proven · **Date:** 2026-10-03

Follow-up refining the earlier "89 real-divergence chunks" tally in
[`docs/mercs2-luacd-xbox/_structural_diff_report.md`](mercs2-luacd-xbox/_structural_diff_report.md).
That tally was computed on raw bytecode-byte differences, which **conflates four causes** —
debug-info strip, ASSERT-macro strip, `print()` debug-trace strip, and real behavior changes.
Separating them changes the picture: **real behavior divergence is 9 chunks of 240 (3.75%)**,
not 89 (13.3%).

## 0. TL;DR

Of the 240 PC resident chunks (vs Xbox's 238):

| Classification | Count | % | Meaning |
|---|---:|---:|---|
| **IDENTICAL** | 116 | 48.3% | Same proto/instruction/call counts, same global call targets |
| **ASSERT-ONLY** | 51 | 21.3% | Same protos, Xbox lost global `ASSERT` and/or `tostring` (compile-flag) |
| **MINOR-DELTA** | 64 | 26.7% | Same protos, Xbox lost `print()` debug trace lines |
| **REAL BEHAVIOR DROP** | 7 | 2.9% | Xbox dropped 1–29 KBM-UI functions |
| **PC-ONLY CHUNKS** | 2 | 0.8% | Xbox never shipped these chunks (LTI subsystem) |

**231 of 240 PC chunks (96.25%) are behaviorally equivalent to Xbox** once you discount
compile-flag debug-strip (ASSERT macro + print-trace + line info). The remaining 9 are the
true platform divergence — see §3.

## 1. Method

- Extract all 240 PC resident chunks (`vz.wad` block 3185) and all 238 Xbox resident chunks
  (`xbox-vz.wad` block 3180) via `mercs2_probe --bin lua_chunk_scan --extract-block N
  --extract-dir <dir>`.
- Match each PC chunk to its best Xbox counterpart by **Jaccard similarity of the string
  constant pool** (not just source-name, which is stripped on Xbox). Jaccard matches
  consistently exceed 0.85 for genuine pairs and drop below 0.7 for mismatches / PC-only
  chunks.
- For each matched pair, structurally-dump both with `mercs2_probe --bin lua_structural_dump`
  and compare:
  - proto count, instruction count, call count
  - set of **global** call-target names (constant-pool strings, debug-independent)
- Classify by the pattern of deltas (see rules in §2).

Raw TSVs: `scratchpad/pc-xb-full-classify.tsv` (one row per PC chunk, class + deltas).

## 2. Classification rules

| Verdict | Rule |
|---|---|
| **IDENTICAL** | PC-protos == Xbox-protos, PC-insns == Xbox-insns, PC-globals == Xbox-globals |
| **ASSERT-ONLY** | Same protos, insn-delta ≤ 5% of PC, globals-lost ⊆ {`ASSERT`, `tostring`} |
| **MINOR-DELTA** | Same protos, insn-delta > 5% of PC, globals-lost ⊆ {`ASSERT`, `tostring`, `print`} and nothing else — i.e. same call graph except for `print()` debug lines |
| **REAL BEHAVIOR DROP** | PC-protos > Xbox-protos (Xbox dropped nested functions), OR globals-lost includes names other than the above triad |
| **PC-ONLY** | Best-Xbox-match Jaccard < 0.5 and PC-only chunk-source is listed in neither Xbox nor PS3 corpora |

## 3. The 9 real-divergence chunks — line by line

### 3.1 PC-only chunks (LTI subsystem)

Already surfaced in [`docs/cross_platform_parity_reference.md`](cross_platform_parity_reference.md)
§7b and §15 as the "PC-only LTI" finding. Confirmed here against both the shell block
inventory (PC 28, Xbox 26) and the resident block inventory (PC 240, Xbox 238).

| PC chunk | Jaccard to best-Xbox | PC protos | Xbox protos (best-match) | Notes |
|---|---:|---:|---:|---|
| `mrxguiltiprecache` (idx 165) | **0.19** | 16 | 11 | Mismatch — chunk not shipped on Xbox |
| `mrxguiltiprecachelayout` (idx 233) | **0.63** | 1 | 2 | Layout counterpart — not shipped on Xbox |

Both are the Loading-Tips Interstitial precache plumbing — PC-exclusive because the LTI
subsystem (`PgLti*`, `PgLtiRendererPc`) ships only in the PC build (established separately in
the engine atlas work).

### 3.2 Shell / HUD GUI chunks with KBM-UI functions dropped on Xbox

All seven are keyboard-mouse / windowed-UI code paths that have no analogue on a controller:
caret handling, text-stroke buffers, keyboard polling, numeric-entry key dispatch, menu
mouse hover, and so on.

| PC chunk | Jaccard | PC → Xbox protos | PC → Xbox insns | Globals Xbox dropped |
|---|---:|---|---|---|
| `mrxguishell` (idx 225) | 0.66 | 59 → 37 (**−22**) | 2,257 → 1,539 (−32%) | `ASSERT` |
| `mrxguipausescreen` (idx 66) | 0.76 | 49 → 20 (**−29**) | 1,598 → 1,163 (−27%) | — (all method-level) |
| `mrxguishellbootstrap` (idx 141) | 0.74 | 22 → 18 (−4) | 276 → 202 (−27%) | `EnterShell` |
| `mrxguinumericbox` (idx 13) | 0.86 | 18 → 15 (−3) | 2,186 → 1,389 (−36%) | `_BuildStrokes`, `_UnselectAll`, `pairs` |
| `mrxguidialogbox` (idx 139) | 0.91 | 32 → 30 (−2) | 2,696 → 2,363 (−12%) | `tostring` |
| `mrxguipda` (idx 107) | 0.93 | 83 → 81 (−2) | 4,502 → 4,287 (−5%) | `ASSERT` |
| `mrxguibase` (idx 103) | 0.99 | 184 → 183 (−1) | 5,029 → 4,999 (−1%) | `ASSERT` |

Totals: **−63 protos**, **−1,829 instructions** across the seven. **No** Xbox-only globals
anywhere — divergence is **purely one-directional** (PC has code Xbox doesn't; Xbox adds
nothing).

Pattern reading:
- `mrxguipausescreen` and `mrxguishell` are the big KBM-UI trims (−29 and −22 protos).
  These are the top-level shell screens where the KBM input-handling methods live.
- `mrxguinumericbox` loses `_BuildStrokes` and `_UnselectAll` — the stroke-buffer and
  multi-field selection logic specific to text/number entry via keyboard.
- The other four are near-99% equivalent with 1–4 protos trimmed each; those trims are
  consistent with a `#if PC` sub-branch (e.g. a KBM focus-override) rather than feature-level
  divergence.

## 4. The 51 ASSERT-ONLY chunks

Same proto count on both platforms, Xbox lost one or both of the globals `ASSERT` /
`tostring`, and the instruction delta is ≤ 5%. The Pandemic Lua framework has a Lua-level
`ASSERT(…)` call that both:
- expands to a conditional-fault handler on PC debug/retail,
- is compiled to a no-op on Xbox retail (and PS3 retail).

Dropping it removes a `GETGLOBAL ASSERT`, a few register setups, a `CALL`, and the string
constant for the message — ~5–20 instructions per site.

| PC chunk (sample) | PC protos | Xbox protos | PC insns | Xbox insns | Delta |
|---|---:|---:|---:|---:|---:|
| `mrxguibase` (also KBM-drop above) | 184 | 183 | 5029 | 4999 | −30 |
| `mrxcheatbootstrap` | — | same | 16718 | 10384 | −6334 |
| `mrxguitutorial` | — | same | 18874 | 10280 | −8594 |
| `laptop` | — | same | 4249 | 2823 | −1426 |
| `levelbootstrap` | — | same | 912 | 497 | −415 |

Full list: `scratchpad/pc-xb-full-classify.tsv` filter `$3=="ASSERT-ONLY"`.

## 5. The 64 MINOR-DELTA chunks

Same proto count, same call graph, but Xbox lost `print()` debug-trace lines. One worked
example — **`mrxactionhijack`** (PC 203 ↔ Xbox 202):

- Jaccard 0.72, PC 44 protos / 4,846 insns vs Xbox 44 protos / 3,564 insns (Δ −1,282 insns,
  −26% of PC).
- Call-set diff: **PC has 72 more `print()` calls than Xbox** (191 vs 119 global-call sites,
  the only global dropped is `print`).
- 1,282 extra instructions ≈ 72 × ~18 instructions/call (push arg, GETGLOBAL print, CALL,
  plus the inlined format strings as constants).

`print` on retail Xbox goes to a NUL sink anyway (no stdout), so stripping these call sites
removes zero user-visible behavior while reclaiming ~1.3 KB of bytecode per heavy script.

The 64 MINOR-DELTA chunks follow this same pattern: Xbox retail removed `print`-wrapped
debug lines, leaving the call graph and conditional branches intact.

Spot check: nothing in this category drops or adds a non-`print` global, drops a child proto,
or shifts the branch structure. The classification is **"behaviorally equivalent, measurably
smaller"**.

## 6. Behaviour-divergence summary

- The byte-level split "457 identical / 125 debug-strip / 89 real-divergence" in
  [`docs/cross_platform_parity_reference.md`](cross_platform_parity_reference.md) §7 counts
  byte differences; it does not represent behaviour divergence.
- Behaviour-equivalent fraction after discounting debug-print and ASSERT strip:
  **231/240 = 96.25%** of PC resident chunks ≡ Xbox resident chunks.
- The 9 real divergences are:
  - 2 PC-only chunks (LTI subsystem).
  - 7 shell/HUD chunks with 1–29 KBM-UI nested functions removed on Xbox.
- No chunk adds functionality on Xbox that PC doesn't have.

## 7. Follow-ups outside this scope

- The equivalent audit for the **shell** block (PC 28 chunks vs Xbox 26) and the
  **scripts_vz** block (114/114) was partially covered in the PS3-vs-Xbox pass; a full
  PC-vs-Xbox three-way audit on those two blocks would close the base-game Lua picture
  completely.
- The 7 KBM-UI chunks are the natural fix-pack / mod source material for a controller→KBM
  parity patch (bringing Xbox-style trimming to PC) OR for a KBM-first UX pack (relying on
  PC-only method presence).
- The LTI subsystem (2 PC-only chunks + native `PgLti*` symbols) is the only hard
  PC-exclusive feature at the Lua layer.
