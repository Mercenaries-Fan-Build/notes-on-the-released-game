# SecuROM Full Removal — Un-Splice / Devirtualization Study + `securom_unwrap`

**Status: de-SecuROM'd base BOOTS STANDALONE; shipped as a reusable crate
(2026-06-30).** Source of record: memory `securom-unsplice-project`. Distinct from
`how-to-bypass-securom-drm.md` and `securom_forensic_analysis.md`, which cover the
bypass/repack path — this documents **full removal** and why in-place devirtualization
was rejected.

The user chose FULL SecuROM removal (zero loader/triggers), not a bypass. The study
answered "can we statically restore the game's original bytes?" (no) and "what is the
correct end-state?" (keep the SecuROM sections dead, kill the loader + triggers, rebuild
the PE).

## Source image + PE facts

- **Source:** `output/_ghidra/securom_dump/image.bin` — flat decrypted memory dump of the
  RELOADED-cracked + pmc_bb-patched `Mercenaries2.exe` (53 MB, `file_off == RVA`,
  ImageBase `0x400000`).
- **Real OEP = RVA `0x5ee71c`** (`WinMainCRTStartup`). The current PE entry `0x704c2e` is
  a SecuROM/mod stub that: hooks `USER32!SendMessageA` (magic-arg trigger → `.securom`),
  `LoadLibraryA("pmc_bb.dll")`, then `jmp 0x5ee71c`. So pmc_bb is injected by an
  **entry-point patch**, and the SendMessageA magic-trigger is the only entry-installed
  SecuROM hook.
- **Import table is clean-separable:** descriptors [0]–[18] = the game's real 19 DLLs /
  404 imports (INT intact, names readable); descriptors [19]+ are SecuROM's own imports
  in `.securom` (drop). TLS dir has no callbacks.
- SecuROM section range (RVA) = `0x1649000 .. 0x3301000`
  (`Stext / Sitext / Srdata / Sdata / Sidata / .securom`, then `reloaded`).

## Double-blind census verdict (2 investigators + 1 evaluator, HIGH confidence)

- **743 REAL** instruction-aligned splice sites (of 1410 raw `.text → SR` rel-branches);
  695 jmp / 48 call. Artifacts: `output/_scratch/securom_real_splices.json`,
  `_classify_out.json`.
- **`Stext` is RELOCATED GAME CODE, not a VM** — 96.1% internal rel-calls, textbook CRT
  (chkstk/strlen/memcmp), entropy ≈ `.text`, ~11% of funcs carry localized SecuROM glue.
  **MUST KEEP.**
- **Static stolen-byte reversion is UNRELIABLE.** 387 macros look liftable but 96%
  reference SR addresses via an indirect-load idiom that reads SR table slots which are
  **NULL on disk** (runtime-resolved); control flow is flattened across `.securom`; the
  engine at `0x1a53f50` is runtime-decrypted (static = `add al,0x24; ret`). Recovery would
  need a runtime oracle.
- **No original-byte backup table exists** — the build runs fully virtualized and never
  restores stolen bytes in place. There is no clean-`.text` state to recover.
- **Conclusion: full zero-SR-byte devirtualization is NOT worth it** (multi-week fragile
  runtime trace harness, no functional gain). Best end-state = the textbook SecuROM-7
  endgame: **keep the SR sections, kill the loader/triggers, rebuild the PE.**

## The working de-SecuROM'd exe (`mercs2_nodrm_v2.exe`)

**CRITICAL LESSON — build from the ON-DISK cracked exe, not the memory dump.** RELOADED
already decrypted the code to disk (flat raw == virtual), so on-disk `.text` == dump
`.text`, but the dump's `.data` holds MUTATED runtime state (stale heap pointers). v1
(built from the dump) crashed `0xc0000005` at RVA `0x44e046` because dump
`.data[0x9fd108]` = `0x1807ab00` (stale) vs on-disk = 0 (clean).

**v2 = on-disk exe + 3 header patches** (sha `bb119233`):
1. entry `0x704c2e` → OEP `0x5ee71c`
2. import dir truncated to the 19 game DLLs (null after descriptor [18] @ `0x330117c`,
   size `0x190`)
3. IAT dir = `0x705000` / `0x690`; checksum 0

It boots with no disc / activation / RELOADED / SecuROM-trigger / pmc_bb. The NULL-SR-slot
risk did not materialize — with entry → OEP the SendMessageA trigger is never armed, so the
dispatcher slots stay NULL and no hot-path macro faults. "Keep SR sections, kill loader/
triggers" is validated.

**Remaining optional polish:** deeper play-test (load a level); shrink the ~19 MB
`.securom` zero-fill + tidy the PE; optional live x32dbg confirm the triggers never fire;
a modded variant layering pmc_bb/ASIs on v2. The recipe generalizes to the other SecuROM
PC builds via their on-disk decrypted counterparts.

## The real deliverable — the `securom_unwrap` crate

The transform (not the one exe) shipped as `securom_unwrap` (lib + CLI) in the
`wad_simulator` workspace, branch `feat/securom-unwrap` (now contained in
`build-mercs2-engine`). `securom_unwrap::unwrap(data, &Options) -> (bytes, Report)`:

- **Derives OEP** with a tiny opcode walker that follows the entry stub to its `jmp` into
  the `call; jmp` `WinMainCRTStartup` signature (`--oep` override).
- **Partitions imports** — drops descriptors whose thunk array lives in a SecuROM-named
  section (`DEFAULT_SECUROM_SECTIONS`); derives the IAT dir.
- **In-place header edits only** (layout preserved).

Golden-tested: reproduces v2 byte-identically except it derives the precise IAT size
`0x69c` vs the hand-built `0x690`. Synthetic-PE unit tests pass.

> **Consumption note:** the modkit (Tauri app at `Desktop/mercs2-modkit`) depends on the
> crates.io **1.0** versions; the local workspace crate is `0.1.0`. To wire it in, publish
> `securom_unwrap`, add the dep, and expose a Tauri command.
