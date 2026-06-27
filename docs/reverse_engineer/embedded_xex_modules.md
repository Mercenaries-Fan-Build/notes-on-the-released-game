# Mercenaries 2 "Jul 11 2008" X360 Preview ISO — the 23 "extra" XEX2 signatures

**Scope:** Resolve the **25 total `XEX2` signature hits** found in a full-ISO byte scan beyond the 2 real game/loader executables, mapping each ISO offset to the disc file it lives in and identifying what it actually is.
**Provenance:** `game-files/Mercenaries 2 World in Flames (Jul 11, 2008 prototype)/Mercenaries 2 Preview X360 (Jul 11 2008).iso` (6,344,605,696 bytes, XDVDFS, partition base 0). Devkit "Profile" build, Pandemic "Pangea" engine. See also [`jul08_prototype_iso.md`](jul08_prototype_iso.md).

## TL;DR

The 23 "extra" hits are **not** game/engine modules. They resolve to:

- **22 of 23** fall inside one disc file: **`$systemupdate/su2008d200_00000000`** — an Xbox 360 **`LIVE,` STFS System‑Update package** (content type `0x000b0000`). It carries:
  - **1 genuine TITLE executable — the Xbox 360 Dashboard, original PE name `dash.exe`** (title id `0xFFFE07D1`, image base `0x92000000`, entrypoint `0x92133078`).
  - **21 genuine XEX *delta‑patch* modules** (modflags `0x50`, each with a Delta‑Patch‑Descriptor optional header `0x000005ff`) — i.e. the system-software update payload that patches console system DLLs.
- **1 of 23** is a **false positive**: a coincidental `XEX2` 4‑byte match inside the Bink-compressed video `movies/06_YNH_J.bik`.

None of the 23 are embedded *game* modules. They are the bundled console **System Update** (recovery update `2008d200`) that disc-based titles shipped so the console could self-update before launch, plus one incidental match. **Not worth extracting for game RE**, but the dashboard + patch set is a clean, separable Xbox 360 system-update artifact if ever needed.

## Method

Full 6.3 GB `XEX2`-signature sweep, then each hit mapped to a disc file by computing every file's byte range as `sector * 0x800 .. + size` from `output/jul08_prototype/iso_filelist.txt` and binning the offset.
Scan + mapping script: `scratchpad/scan_xex.py`; header decoders: `scratchpad/probe2.py … probe5.py` (this session). XEX2 optional-header layout per `tools/xex_info.py`.

```
total XEX2 hits: 25
```

The 2 known executables (both at file start, `rel=0`):

| ISO offset | file | what |
|---|---|---|
| `0xb7db2000` | `mercs2_xenon_p_EN_FR.xex` | the game (devkit, `Mercs2_Xenon_P.exe`) |
| `0xb8299000` | `default.xex` | the loader shim |

That leaves **23 extra** hits, resolved below.

## Finding 1 — `$systemupdate/su2008d200_00000000` is a `LIVE,` STFS System-Update package

Disc file: 8,257,536 B @ sector 1510972 → byte range `0xb871e000 .. 0xb8efe000` (= base + 8,257,536; the STFS content payload `0x7d5000` ends earlier at `0xb8ef3000`).

```
SU file header bytes : 4c4956452c53c163...   ("LIVE,S…")
content type @0x344  : 0x000b0000            (System Update)
content size @0x34c  : 0x00000000007d5000
exec-id block @0x354 : media/title = 2008d200 2008d200  (matches the filename su2008d200)
```

`LIVE,` is the Xbox 360 STFS package magic; content type `0x000b0000` is **System Update**. So this file is the console software-update bundle, keyed `2008d200` (a 2008 system update), shipped on the disc so an out-of-date console could update before running the preview. 22 of the 23 stray `XEX2` hits are the XEX modules *inside* this STFS package (all land at sector-aligned offsets within it, consistent with packed module blocks).

## Finding 2 — the one TITLE module inside is the Xbox 360 Dashboard (`dash.exe`)

At ISO `0xb87ce000` (rel `0xb0000` within the SU file):

```
modflags = 0x00000001 (TITLE)     optional-header count = 17
orig PE name = dash.exe
title id    = 0xFFFE07D1
entrypoint  = 0x92133078
image base  = 0x92000000
```

This is a full module (17 optional headers incl. imports/TLS/resources), distinguishing it from the patch stubs below. It is the **system dashboard** delivered by the update — *not* anything Mercenaries-specific.

## Finding 3 — the other 21 SU modules are XEX delta-patches

The remaining 21 SU hits all share:

```
modflags = 0x00000050              (= 0x10 PATCH | 0x40 DELTA_PATCH)
optional-header count = 2
  key 0x000003ff  -> Base File Format
  key 0x000005ff  -> Delta Patch Descriptor
orig PE name      = (none)
```

Example Delta-Patch-Descriptor (module @ rel `0xd000`), confirming source→target image versions:

```
delta patch desc @+0x1d0 : size=0x394  target_ver=0x200dc000  source_ver=0x20076000  + digest words
```

Two optional headers and a delta-patch descriptor (no PE name, no imports) is exactly an **XEX delta-patch stub**: it carries a binary diff that the updater applies to an already-installed system XEX (xam, kernel, system libraries). These are the actual system-update payload. They are genuine XEX2 records, but they are *patches to console system software*, not standalone executables and not game content.

Full SU module map (rel = offset within the `$systemupdate` file):

| rel offset | modflags | kind |
|---|---|---|
| `0x0000d000` | 0x50 | delta-patch |
| `0x00029000` | 0x50 | delta-patch |
| `0x00098000` | 0x50 | delta-patch |
| `0x000a6000` | 0x50 | delta-patch |
| **`0x000b0000`** | **0x01** | **TITLE — `dash.exe`** |
| `0x00444000` | 0x50 | delta-patch |
| `0x00447000` | 0x50 | delta-patch |
| `0x0045b000` | 0x50 | delta-patch |
| `0x0047e000` | 0x50 | delta-patch |
| `0x00496000` | 0x50 | delta-patch |
| `0x004b7000` | 0x50 | delta-patch |
| `0x004cc000` | 0x50 | delta-patch |
| `0x004fa000` | 0x50 | delta-patch |
| `0x0050a000` | 0x50 | delta-patch |
| `0x00515000` | 0x50 | delta-patch |
| `0x0051f000` | 0x50 | delta-patch |
| `0x0052b000` | 0x50 | delta-patch |
| `0x0052f000` | 0x50 | delta-patch |
| `0x00542000` | 0x50 | delta-patch |
| `0x0055a000` | 0x50 | delta-patch |
| `0x0074b000` | 0x50 | delta-patch |
| `0x007da000` | 0x50 | delta-patch |

That's **1 dashboard + 21 delta-patches = 22 modules** in the SU file (22 table rows above).

## Finding 4 — 1 hit is a false positive inside a Bink movie

At ISO `0x5029f810`, rel `0x859010` inside `movies/06_YNH_J.bik`:

```
context : …4f44f6f3 ac899199 693c9fbb  58455832  7cacf8fd a09edff3…
                                        ^XEX2^    (no valid module-flags/PE-offset follow)
```

The 4 bytes happen to spell `XEX2` inside Bink-compressed video; the following bytes (`7cacf8fd…`) are not a sane XEX header (no plausible module flags, PE-data offset, or optional-header count). **Coincidental match, not a module.** This matches the earlier ISO-doc note that scattered signature hits inside compressed data are incidental.

## Tally

| group | count | verdict |
|---|---|---|
| real game/loader XEX (`mercs2…`, `default.xex`) | 2 | the 2 known executables (excluded from "extra") |
| `dash.exe` TITLE inside `$systemupdate` | 1 | genuine module — Xbox 360 dashboard (system, not game) |
| delta-patch stubs inside `$systemupdate` | 21 | genuine XEX patch records — system-update payload |
| false positive in `movies/06_YNH_J.bik` | 1 | incidental 4-byte match in Bink data |
| **extra total** | **23** | **0 are game/engine modules** (1 + 21 + 1 = 23) |

## Conclusion / RE value

None of the 23 extra `XEX2` hits are embedded *Mercenaries 2* modules, shaders, or wad content. 22 belong to the on-disc **Xbox 360 System Update** STFS bundle (`su2008d200`) — the dashboard plus 21 system delta-patches — and 1 is a coincidental match in a Bink video. For game reverse-engineering they can be ignored; the only real game executables remain `mercs2_xenon_p_EN_FR.xex` (the prize, already fully recovered — see [`jul08_prototype_iso.md`](jul08_prototype_iso.md)) and `default.xex` (loader shim). If a console-side system-update artifact is ever wanted, the `dash.exe` TITLE at SU-rel `0xb0000` is the cleanly separable, full module.
