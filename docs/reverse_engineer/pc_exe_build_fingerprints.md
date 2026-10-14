---
status: current
evidence: proven
verified_on: 2026-10-14
supersedes: cross_platform_parity_reference.md#12, modding_deep_dive.md#version-identification, reverse_engineer/exe_images.md
---

# PC exe build fingerprints — the discriminator spec

The authoritative reference for identifying any Mercenaries 2 PC executable. Supersedes the
scattered version tables in `cross_platform_parity_reference.md`, `modding_deep_dive.md`, and the
one-line labels in `reverse_engineer/exe_images.md`. Backed by live-process memory dumps + byte
tests against Ghidra-identified v1.0-vs-v1.1 divergent function VAs — captured 2026-10-14.

## TL;DR

- **sha256 is the primary discriminator** — look it up in
  [`tools/wad_simulator/crates/mercs2_exemap/data/builds.tsv`](../../tools/wad_simulator/crates/mercs2_exemap/data/builds.tsv).
- **PE TimeDateStamp is UNRELIABLE on packed/cracked exes** — the EA Authenticode signer sets it
  to the shell's link time, and crack tools can rewrite it. It is only reliable on untouched
  unpacked ≥50 MB images (`dump-v11-securom-unpacked`, `v10-securom-unwrap`, etc.).
- **File size is a trap** — the 17.1 MB `v10-ea-signed` wraps v1.1 game code; the 53.9 MB
  `v11-patched-securom` wraps the same v1.1 code; cracked v1.1 shrinks to 53.5 MB. Any
  `size < 20 MB → v1.0` heuristic misclassifies the EA-signed v1.1 compact shell.
- **For live-process identification** (what pmc_bb needs), fingerprint by **byte-match at three
  Ghidra-identified v1.0-vs-v1.1 divergent function VAs**: `0x5c37f0`, `0x683ce0`, `0x6a5970`.

## The naming trap

Three catalogued `build_id`s have names that are historical misnomers — they predate the byte
analysis that corrected them. Treat the names as opaque identifiers; the `code_version` column
in `builds.tsv` is authoritative:

| build_id (misleading) | sha256 prefix | What the name implies | What it actually is |
|---|---|---|---|
| `v10-ea-signed` | `a1532b4c…` | v1.0 code, EA-signed | **v1.1 game code**, EA-signed SecuROM 7.38 compact shell, 17.1 MB |
| `v10-cracked-pmcbb` | `958eb227…` | v1.0 code, cracked | v1.1-derived cracked exe with pmc_bb.dll substituted; byte-restored to v1.0-shape at SecuROM-touched functions |
| `archived-1-cracked-cruise` | `23fe7f38…` | v1.0 cracked archive | same pattern as `v10-cracked-pmcbb` but keeps `cruise.dll` import |

Why the names stuck: the original cataloguing used file size as a proxy for code version (17 MB
"must be v1.0" / 53 MB "must be v1.1"), and labeled the cracked outputs by the PE TimeDateStamp
the crack writes (`0x48a370c7`, which is v1.0's compile time, used as an identity marker).
Neither signal survives careful byte testing.

## The three code groups (proven)

Byte-match at `VA 0x5c37f0` / `0x683ce0` / `0x6a5970` (the three biggest v1.0-vs-v1.1 differing
functions per the Ghidra decomp cross-reference). Captured 2026-10-14 from
`game-files/memory-dumps/*/image.bin`:

| Group | Members (sha256 prefix) | Live `.text` prologue @ `0x5c37f0` |
|---|---|---|
| **v1.0 game code** | `ada55455`, `2ae4a2e0`, `23fe7f38`, `958eb227` | `53 56 57 8d 84 24 f8 02 00 00` (push ebx/esi/edi; lea eax, [esp+0x2f8]) |
| **v1.1 game code** | **`a1532b4c`**, `7a348847` | `55 8b ec 83 e4 f8 b8 6c 15 00 00` (push ebp; mov ebp, esp; and esp, 0xfffffff8; mov eax, 0x156c) |
| **demo** | `9da26832` | `33 c0 b1 3d 90 38 8c 04 f8 02 00 00` (xor eax, eax; mov cl, 0x3d; ...) |

Full byte trace: `scratchpad/fn_compare.log`.

## On-disk static signals

For a file you haven't run yet, these on-disk signals corroborate the sha-based identity:

| Signal | v1.0 code | v1.1 code | demo |
|---|---|---|---|
| On-disk import directory (unique DLLs) | 19 (packed in SecuROM 7.37) or 21 (SecuROM 7.38 shell + VERSION + WSOCK32 shadow) | **22** (base 19 + SHLWAPI + VERSION + WSOCK32) | 18 |
| SecuROM-DRM shell string | `SecuROM-DRM_7_37` (v1.0 unsigned) or `SecuROM-DRM_7_38` (v1.0 EA-signed) | `SecuROM-DRM_7_38` | `SecuROM-DRM_7_38` |
| Unpacked PE TimeDateStamp (reliable only on unpacked ≥50 MB files) | `0x48a370c7` | `0x48cae190` | `0x48cb59e8` |
| `Stext` (encrypted .text) vsize in SecuROM 7.38 shell | ~7,034,672 | ~7,036,928 | n/a |

**None of these alone is sufficient.** sha256 catalogue lookup is. The signals above are
corroborating evidence for files not yet in the catalogue.

## The v1.0 → v1.1 → cracked chain

The official EA v1.1 patcher SFX (sha256 `b27fedc2…`, found in `game-files/Mercs2 WiF v1.1 Patch/mercenaries2_patch1_*.exe`) is the only step that actually upgrades game code. It takes
`archived-2-disk-dump` (`ada55455…`, v1.0 unsigned retail) and produces `v10-ea-signed`
(`a1532b4c…`, **v1.1 game code in a compact SecuROM 7.38 EA-signed shell**).

Verified empirically on 2026-10-14: user ran the official SFX on the disc dump; output sha =
`a1532b4c…` byte-exact.

```
ada55455… (v1.0, 16.8 MB SecuROM 7.37)
      │
      ▼  official v1.1 patcher b27fedc2…  OR  mercs2-securom-bypass:patches/v10_unsigned_to_v11.bspatch
      │
      ├─▶ a1532b4c… (v1.1 code, 17.1 MB SecuROM 7.38 compact signed shell)   ◄── EA retail v1.1 shipping form
      │        │
      │        ▼  mercs2-securom-bypass:patches/v10_signed_to_v11.bspatch   (shell transform only — code is already v1.1)
      │        │
      │        ▼
      └─▶ 7a348847… (v1.1 code, 53.9 MB SecuROM 7.38 roomy shell)   ◄── v11-patched-securom
                 │
                 ▼  mercs2-securom-bypass:patches/v11_to_cracked.bspatch   (strips SecuROM, swaps cruise.dll → pmc_bb.dll, restores v1.0-shape bytes at the 3 divergent VAs)
                 │
                 ▼
          958eb227… (v10-cracked-pmcbb, 53.5 MB, pmc_bb.dll import)   ◄── the apply_crack shipping output
                 │
                 ▼  COFF Characteristics[0x1FE] 0x0103 → 0x0123 (one-byte LAA flip)
                 │
                 ▼
          3a388d66… (v10-drmfree-laa)
```

A parallel chain produces the main-repo `tools/patches/*.bspatch` outputs with slightly
different byte layouts (`23fe7f38…` keeps the cruise.dll import). Both the sibling-repo and
main-repo cracks produce v1.0-shape bytes at the three divergent VAs — consistent with the crack
process restoring pre-SecuROM function bodies at SecuROM-touched addresses.

## Discriminator strategy for the exemap identifier

Implementing a `identify_build(bytes) -> BuildId` should layer the signals in this order:

1. **sha256 against `builds.tsv`** — exact match → return the row's `build_id` and `code_version`.
2. **Catalogued-size fallback with warning** — if sha256 doesn't match any row but the size does,
   warn "unrecognized SHA-256; patching may corrupt" (this mirrors `apply_crack`'s current
   `detect.rs` fallback).
3. **For a file with no `.securom` section AND size ≥ 50 MB** — read `IMAGE_FILE_HEADER.TimeDateStamp`
   from the on-disk PE and map `0x48a370c7 → v1.0`, `0x48cae190 → v1.1`, `0x48cb59e8 → demo`.
   Mark as `code_version` with low confidence and offer sha256 as the lookup key.
4. **For a packed exe (has `.securom` or similar S\* section) not in the catalogue** — refuse to
   assert a game-code version. Return `UnknownPacked` with sha256 and recommend adding the row to
   `builds.tsv` after verifying via byte-match at the three divergent VAs (requires running the
   exe to decrypt).
5. **For live-process identification** (pmc_bb at startup) — read bytes at the three divergent
   VAs from the live image and compare to the known fingerprints above. Three byte-matches at
   known-divergent locations is an unfakeable signal that neither SecuROM nor any crack can
   mimic without actually swapping the game code bytes.

## What NOT to use (traps catalogued here so future readers don't rediscover them)

- `size < 20 MB → v1.0`: breaks on `v10-ea-signed` (17.1 MB, v1.1 code).
- `PE TimeDateStamp of a packed exe → code version`: breaks on `v10-ea-signed` (shell linked
  Sep 12 2008 = coincidentally v1.1's compile date; file wraps v1.1 code either way).
- `SecuROM-DRM version string → code version`: `SecuROM-DRM_7_38` is present on v1.0 EA-signed,
  v1.1 patched, AND the demo. Only `7_37` is distinctive (v1.0 unsigned).
- `Live import-directory count → code version`: SecuROM is sometimes still being set up at menu
  capture time, causing the directory to show fewer imports than the final game. The on-disk
  import directory (post-unpack) is reliable; the live transitional view is not.
- `VERSIONINFO resource strings → code version`: Pandemic/EA shipped every build (v1.0, v1.1,
  demo) with `FileVersion = ProductVersion = "0, 1, 0, 0"`. Never a discriminator.
- `.text first-1MB hash → code version`: contains shell-polluted IAT thunks and SecuROM stubs
  that differ by shell variant even when the underlying game code is identical. Use the three
  divergent-VA byte comparison instead.
- **A code comment claiming X about this file**: no amount of commentary in `detect.rs` or
  elsewhere is proof. Trust the catalogued sha256 and the byte test.

## Verification recipe

To add a new build to the catalogue or to verify an existing one is still what it claims to be:

1. Compute sha256 and PE TimeDateStamp.
2. If `builds.tsv` has the sha256, cross-check md5, size, and pe_timestamp against the row.
3. If size ≥ 50 MB and no `.securom` section, trust the PE TimeDateStamp as the code version.
4. Otherwise, run the exe under x32dbg + ScyllaHide on a Shadow or local Windows env, break at
   OEP, let the game reach the main menu, and dump the image via
   [`game-files/memory-dumps/capture.ps1`](../../game-files/memory-dumps/capture.ps1).
5. Compare bytes at `VA 0x5c37f0`, `VA 0x683ce0`, `VA 0x6a5970` to the fingerprints in **The
   three code groups** above. Three independent byte matches at known-divergent locations is
   definitive.
6. Add the row to `builds.tsv` with the proven `code_version`, and record the finding here.

## Historical corrections landed 2026-10-14

- `v10-ea-signed` (`a1532b4c…`) was recorded with `code_version = 1.1` in `builds.tsv`
  (correct), but the build_id and the shipped `apply_crack::detect::ExeVersion::V10Signed` enum
  variant imply v1.0. Both naming artifacts are historical misnomers; the file wraps v1.1 code.
  See the "Group B" byte test above.
- `builds.tsv` row 15 (`v11-patched-securom`) previously claimed a recipe where the "official
  v1.1 patcher b27fedc2 run on the installed game" produces `7a348847…` directly. Empirical
  test: the EA patcher on the disc dump (`ada55455…`) produces `a1532b4c…` (compact shell),
  NOT `7a348847…`. The row's recipe list has been corrected to remove that step; the EA
  patcher's actual output is now recorded on row 13 (`v10-ea-signed`).
- `tools/patches/mercs2_v1.0_to_v1.1_update.bspatch` was found to be byte-equivalent (in behavior)
  to the sibling-repo `v10_signed_to_v11.bspatch`, NOT `v10_unsigned_to_v11.bspatch`. Applying
  it to `ada55455…` fails on a control-block shape mismatch; applying it to `a1532b4c…`
  produces `7a348847…` byte-exact. Any doc that treats this patch as "the v1.0 → v1.1 update"
  without qualification is inaccurate.
- `tools/patches/mercs2_v1.1_securom_bypass.bspatch` is a DIFFERENT patch from the sibling-repo
  `v11_to_cracked.bspatch`. Main-repo applied to `7a348847…` yields `23fe7f38…` (keeps
  cruise.dll); sibling-repo applied to the same input yields `958eb227…` (substitutes pmc_bb.dll).
- `apply_crack::detect::ExeVersion::V10Signed`'s doc comment "v1.0 retail, EA-signed" is wrong;
  the enum discriminates by sha256 (which is correct) but the human-readable label misrepresents
  the game-code version. Fixed in the sibling repo on this same date.

## See also

- [`tools/wad_simulator/crates/mercs2_exemap/data/builds.tsv`](../../tools/wad_simulator/crates/mercs2_exemap/data/builds.tsv)
  — the catalogue, source of truth for sha256 ↔ `code_version`.
- `/Volumes/Projects/mercs2-securom-bypass/src/detect.rs` — the shipping sha-based identifier
  used by the `apply_crack` end-user tool.
- `/Volumes/Projects/mercenaries-game/game-files/memory-dumps/` — the seven live-process dumps
  that provide ground truth for byte comparison.
