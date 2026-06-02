# Patch-WAD GlobalEnter busy-poll livelock + data-as-code faults — live-debug analysis

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

1. **Root-cause the GlobalEnter loop `0x004B1180`:** identify the work item it polls, the
   readiness predicate that never satisfies, and the path by which a patch block becomes the
   data-as-code transfer target (`0x2004FFB0` / `0x00000B70`). Relevant frames:
   `0x004B1201`, `0x004C9C80`; paired worker started at `0x00876400`.
2. **Fix the 334 unconverted textures** (FourCC `0x1a200152` / `0x1a200154`): determine which
   build/override step failed to convert them, rebuild the patch WAD, and retest whether the
   livelock clears. (Tests the §5 hypothesis directly.)
3. **(Optional) Fix the cosmetic `UnicodeEncodeError`** in `validate_patch_wad.py`'s summary
   print (encoding-safe output / ASCII fallback for the `⚠` glyph).

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
| `0x00DFC2F8` | render-view singleton slot — held `0x017CFAF0` throughout (intact; §4) |
| `0x1a200152` / `0x1a200154` | unconverted Xbox-360 texture FourCC at `INFO[14:18]` (334×, §5) |

**Artifact:** `output/_scratch/xdbg_monitor_20260602T225505Z.jsonl` (samples 1–3 RUNNING/livelock, 4–5 PAUSED_FAULT, + SUMMARY).
