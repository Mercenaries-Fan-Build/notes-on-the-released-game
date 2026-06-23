# Mercenaries 2 (Jul 11 2008 X360 preview) — Imports & Exports / Platform API Surface

**Scope:** the XEX optional-header library blocks — the **StaticLibraries** list
(statically-linked XDK libs + versions + implied features) **and** the genuine
**ImportLibraries** list (the dynamically-bound system XEX/EXE modules) — plus the PE
import/export tables of the game executable `mercs2_xenon_p_EN_FR.xex` /
`Mercs2_Xenon_P.exe`. This maps the *platform API surface* (which Xbox 360 system
libraries the title binds against → online, voice, audio, graphics, debug) and what,
if anything, the title itself exports.

> **Note on terminology (corrected):** On Xbox 360 the XEX has **two distinct** library
> blocks. (a) **StaticLibraries** (optional-header key `0x000200ff`, here @ file `0x313c`)
> = the XDK libraries linked *into* the PE at build time. (b) **ImportLibraries**
> (key `0x000103ff`, here @ file `0x46fc`) = the external system modules the title
> *dynamically imports* (`xam.xex`, `xboxkrnl.exe`, `xbdm.xex`). The `0x313c` list named
> below is the **StaticLibraries** block, **not** the import table; the real import table
> is covered in §1b.

**Provenance:** Mercenaries 2: World in Flames, "Jul 11 2008" Xbox 360 preview ISO,
Pandemic "Pangea" engine, devkit "Profile" build. Source binaries:
- XEX (game): `output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex` (5,140,480 B)
- Recovered PE: `output/jul08_prototype/mercs2_xenon_p.pe_full.bin` (32,374,784 B, PE32
  machine **0x01F2 = PowerPC (Xbox 360)**, 13 sections, ImageBase 0x82000000)

Cross-links: [`jul08_prototype_iso.md`](../reverse_engineer/jul08_prototype_iso.md)
(recovery + debug-symbol provenance), [`networking.md`](networking.md),
[`audio-pal.md`](audio-pal.md), [`rendering-shaders.md`](rendering-shaders.md),
[`README.md`](README.md).

> GROUND RULE: every number/name/offset below was produced by running an extraction on
> the files above; commands are shown inline. Inferences are marked *(inferred)*.

---

## TL;DR — most notable findings

1. **12 statically-linked XDK libraries** (in the XEX **StaticLibraries** block @ `0x313c`,
   header size `0xc4` = 4 + 12×0x10), all the same XDK toolset, with `XRTLLIBI` and
   `D3D9I` one revision behind the other ten. The raw version dword is `0x1b534000` for
   the bulk and `0x1b530000` for `XRTLLIBI`/`D3D9I`. **Version-label is unreconciled:**
   `tools/xex_info.py` decodes this as **`2.0.6995.x`** (build 6995), whereas the
   standard `xex2_version` bitfield reading (`build = bits[8:24]`) gives **build 21312**
   (`0x5340`) / 21248 (`0x5300`). Both readings of the *same* bytes agree only that it is
   a single 2008-era XDK toolset — consistent with a July-2008 preview. The specific
   build number is **not unambiguously determined by the binary alone**.
2. The static-link set proves the **full online/multiplayer + voice feature stack** is
   linked in: `XNET` (sockets), `XONLINE` (Live), **`XHV` (Xbox High-level Voice / in-game
   voice chat)**, plus `XAUD` (XAudio) and `XMP` (background music player). (These are
   *statically-linked* libraries, not entries in the dynamic import table.)
3. **The title exports nothing usable.** The XEX `module_flags = 0x01` is **TITLE only**
   (no `EXPORTS_TO_TITLE` bit); the reconstructed PE `.idata` (0x1e40000, 0x4f2 B) is
   **entirely zero** and `.edata` (0x1e30000) contains a tiny ordinal-style stub with
   **no name strings** — classic Xbox 360 title behavior (imports are resolved by the
   XEX loader via thunks, not a classic PE `.idata`/`.edata`).
4. The XEX's genuine **ImportLibraries** block (key `0x000103ff` @ 0x46fc) names three
   system modules it dynamically binds against — **`xam.xex` (220 import records),
   `xboxkrnl.exe` (313), and `xbdm.xex` (2)** — and the presence of **`xbdm.xex`
   (Xbox Debug Monitor)** corroborates the devkit/debug provenance.
5. Graphics surface = **`D3D9I` + `D3DX9` + `XGRAPHC`** (Direct3D9 for Xbox 360 +
   D3DX helper + Xbox graphics core), confirming a standard Pandemic D3D9-on-Xenos
   renderer rather than anything exotic.

---

## 1a. XEX StaticLibraries (statically-linked XDK libs)

The libraries the title links **into** its PE at build time live in the XEX
**StaticLibraries** optional header (key `0x000200ff`), at file offset **0x313c**.
`tools/xex_info.py` reports this block under its correct name:

```
$ python tools/xex_info.py output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex
  ...
    opt 0x000103ff ImportLibraries  = 0x46fc      <- genuine import table (see §1b)
    opt 0x000200ff StaticLibraries  = 0x313c      <- the list below
  module_flags=0x00000001  flags: TITLE
  BaseFileFormat: encryption=1 (ENCRYPTED)  compression=2 (LZX)
```

Raw parse of the StaticLibraries block at 0x313c. The header dword is the block size
**0x00000004 + 12×0x10 = 0xc4** → **12** records, each 0x10 bytes (8-byte name +
`major.minor` u16s + version dword), starting at **0x3140**:

```
# raw parse of mercs2_xenon_p_EN_FR.xex StaticLibraries @ 0x313c  (size dword = 0xc4 => 12 records)
0x3140  XRTLLIBI   ver dword 0x1b530000
0x3150  XAPILIB    ver dword 0x1b534001
0x3160  D3D9I      ver dword 0x1b530000
0x3170  D3DX9      ver dword 0x1b534000
0x3180  XGRAPHC    ver dword 0x1b534000
0x3190  XBOXKRNL   ver dword 0x1b534000
0x31a0  XNET       ver dword 0x1b534000
0x31b0  XONLINE    ver dword 0x1b534000
0x31c0  XHV        ver dword 0x1b534000
0x31d0  LIBCMT     ver dword 0x1b534000
0x31e0  XAUD       ver dword 0x1b534000
0x31f0  XMP        ver dword 0x1b534000
```

(The earlier revision of this doc started at 0x3150/XAPILIB and counted 11 — it dropped
the first record **XRTLLIBI** @ 0x3140. The correct count is **12**.)

### Version decode (unreconciled between tools)

The version dword is `0x1b534000` for ten of the twelve libraries, and `0x1b530000` for
**XRTLLIBI** and **D3D9I** (one revision behind); **XAPILIB** is `0x1b534001` (qfe=1).
The decode of these bytes is **not agreed between the two toolchains used here**:

| Reading | XRTLLIBI / D3D9I (`0x1b530000`) | the rest (`0x1b534000`) |
|---------|---------------------------------|-------------------------|
| **`tools/xex_info.py`** (high 16 bits = build) | `2.0.6995.0` | `2.0.6995.16384` (XAPILIB `…16385`) |
| **xex2_version bitfield** (`maj:4 min:4 build:16 qfe:8`) | build **21248** (`0x5300`) | build **21312** (`0x5340`) |

Both readings agree only that this is a **single 2008-era XDK toolset** with XRTLLIBI/D3D9I
one revision behind — matching the Jul-11-2008 preview date. **The specific build number
(6995 vs 21312) is not unambiguously determined by the binary alone**; the earlier doc's
flat "build 21312" / "major=1 minor=11" claim is flagged here as **unreconciled**.

### What each static library implies (feature surface)

| Library    | Role | What it tells us |
|------------|------|------------------|
| **XRTLLIBI** | Xbox runtime library (internal RTL) | Low-level runtime support; one revision behind the rest. |
| **XBOXKRNL** | Xbox 360 kernel import stub (`xboxkrnl.exe`) | Core OS: threads, memory, I/O, sync. (Also a genuine import — see §1b.) |
| **XAPILIB**  | Xbox application/CRT shim layer | Std app/runtime glue over the kernel. |
| **D3D9I**    | Direct3D9 for Xbox 360 (Xenos) | The renderer is **D3D9-on-Xenos** (Pandemic standard). One rev behind. |
| **D3DX9**    | D3DX helper library | Texture/mesh/math helpers atop D3D9. |
| **XGRAPHC**  | Xbox graphics core (`xgraphics`) | Low-level GPU resource / tiling / texture-format support (the engine's texture path; cf. [`rendering-shaders.md`](rendering-shaders.md), [`world-streaming.md`](world-streaming.md)). |
| **XNET**     | Xbox networking (sockets/secure transport) | **Multiplayer transport is linked in** (co-op/online). See [`networking.md`](networking.md). |
| **XONLINE**  | Xbox LIVE client services | **Xbox LIVE integration**: sessions, matchmaking, presence, user data. |
| **XHV**      | Xbox **High-level Voice** engine | **In-game voice chat** (encode/decode/mix of headset voice). Strong signal that co-op voice was a shipping feature. |
| **XAUD**     | XAudio (Xbox 360 audio engine) | The game's sound mixing/DSP path. See [`audio-pal.md`](audio-pal.md). |
| **XMP**      | Xbox Music Player | Background/custom-soundtrack ("My Music") playback support. |
| **LIBCMT**   | Multithreaded C runtime (static) | Standard static MSVC CRT — not a feature, just the toolchain. |

> **`XAM` is NOT in this static list.** The 12th slot is `XRTLLIBI`. `XAM` (Xbox App
> Manager) appears only in the genuine **ImportLibraries** as `xam.xex` (§1b) — the
> earlier doc conflated the two by listing an "XAM" row among the static libs.

**Inference (well-supported):** the combination `XNET + XONLINE + XHV` confirms the
title is built as an **online, Xbox-LIVE-enabled, voice-chat-capable** game (consistent
with Mercs 2's shipping 2-player co-op), and `XAUD + XMP` confirm the full audio stack
including custom-soundtrack support — all already present in this July-2008 preview.

---

## 1b. XEX ImportLibraries (the genuine dynamic import table)

The title's actual **external dynamic dependencies** live in the **ImportLibraries**
optional header (key `0x000103ff`), at file offset **0x46fc** — a *different* block from
the StaticLibraries list in §1a. Raw parse of its header (`hdr_size`, `string_table_size`,
`count`, then the module name strings):

```
# raw parse of ImportLibraries @ 0x46fc:  hdr_size=0x904  strtab_size=0x24  count=3
  xam.xex        ver=2.0.6995.0  ver_min=2.0.1861.0  records=220   (name @ file 0x4708)
  xboxkrnl.exe   ver=2.0.6995.0  ver_min=2.0.1861.0  records=313   (name @ file 0x4710)
  xbdm.xex       ver=2.0.6995.0  ver_min=2.0.1861.0  records=2     (name @ file 0x4720)
```

This is the **real platform API surface** the loader resolves at run time:

- **`xam.xex`** (Xbox App Manager, **220 import records**) — dashboard/system services:
  blades, sign-in, storage device picker, achievements, guide. *This* is where `XAM`
  belongs (not the static list).
- **`xboxkrnl.exe`** (Xbox 360 kernel, **313 records**) — the bulk of the OS surface:
  threads, memory, I/O, sync, etc.
- **`xbdm.xex`** (**Xbox Debug Monitor**, **2 records**) — the debug-monitor module. Its
  presence corroborates the devkit/"Profile" provenance documented in
  [`jul08_prototype_iso.md`](../reverse_engineer/jul08_prototype_iso.md).

### ExecutionId (the `EA\x08(` bytes)

Immediately after the StaticLibraries block, the **ExecutionId** optional header
(key `0x00040006` @ file 0x3210) contains the title's identity. The bytes `b'EA\x08('`
seen at file **0x321c** are **not a mystery tag** — they are the big-endian
**`title_id = 0x45410828`** field of ExecutionId (`'EA'` = publisher EA, title `0x0828`),
decoded by `tools/xex_info.py` as:

```
ExecutionId: title_id=0x45410828 (pub='EA' num=0x0828)  media_id=0x00000000  version=0.0.0.0
```

---

## 2. PE export table (`.edata`)

The recovered PE header (parsed little-endian PE32; section RawPtr ≠ RVA — this is a
file-layout reconstruction, not a flat memory image) declares an Export data directory:

```
$ parse PE NT headers of mercs2_xenon_p.pe_full.bin
machine=0x1f2 (PowerPC)  ImageBase=0x82000000  13 sections
Data directory:
  DD[ 0] Export     RVA=0x1e30000 size=0xa25
  DD[ 1] Import     RVA=0x1e40000 size=0x50
  DD[12] IAT        RVA=0x600     size=0x458
.edata  VA=0x01e30000  RawPtr=0xd63a00  RawSz=0xc00
.idata  VA=0x01e40000  RawPtr=0xd64600  RawSz=0x600
```

But the `.edata` contents are **not a usable named-export table**. Dumping the section
(file 0xd63a00) shows a repeating small-record stub with **zero name strings**:

```
.edata first words (BE u32):
  +0x000: 0x00000002  +0x004: 0x00000009  +0x008: 0x1f000000  +0x00c: 0x00000018
  +0x010: 0x00000002  +0x014: 0x0000000a  +0x018: 0x0000001f  +0x01c: 0x00000000
  ...
ASCII strings in .edata: (none)
```

There are **no exported function name strings** anywhere in the section, and the XEX
`module_flags` lacks the `EXPORTS_TO_TITLE` (0x02) bit (it is `0x01` = TITLE only).

**Conclusion:** `Mercs2_Xenon_P.exe` is a **leaf title that exports no public API** —
exactly as expected for a game executable (only system DLLs/XEX modules export). The
`.edata`/`Export` directory is a vestigial stub from the toolchain, not a real export
surface.

---

## 3. PE import table (`.idata` / IAT)

On Xbox 360 the IAT is fixed up by the **XEX loader via import thunks** (driven by the
`ImportLibraries` block in §1b), so the classic PE `.idata` import directory is empty.
Confirmed by dumping the section at file 0xd64600:

```
.idata (RVA 0x1e40000, 0x4f2 bytes): every dword == 0x00000000
ASCII strings in .idata: (none)
```

So there is **no PE-level import descriptor / no import name table** to read — the
authoritative dependency list is the XEX library lists in §1a/§1b. (The PE IAT directory
`DD[12] RVA=0x600 size=0x458` lives inside `.rdata` and holds thunk slots that the XEX
loader patches at load time; the symbolic mapping of those slots to library functions is
not recoverable from the static PE alone and would require the XEX import patch records —
marked *out of scope / not extracted here*.)

---

## Reproduction commands

```bash
# XEX header + import-library offset
python tools/xex_info.py output/_scratch/jul08_iso/mercs2_xenon_p_EN_FR.xex

# StaticLibraries (key 0x000200ff @ 0x313c): 12 records @ 0x3140 (0x10 stride),
#   version dword at rec+0xc; first record XRTLLIBI @ 0x3140.
# ImportLibraries (key 0x000103ff @ 0x46fc): hdr_size 0x904, count 3; module filenames
#   xam.xex / xboxkrnl.exe / xbdm.xex at file 0x4708/0x4710/0x4720 (220/313/2 records).
# ExecutionId (key 0x00040006 @ 0x3210): title_id 0x45410828 ('EA'+0x0828) at file 0x321c.

# PE sections / data directories / export+import dumps:
#   output/jul08_prototype/mercs2_xenon_p.pe_full.bin
#   .edata @ file 0xd63a00 (RVA 0x1e30000) -> ordinal stub, no names
#   .idata @ file 0xd64600 (RVA 0x1e40000) -> all zero
```

All offsets/values above were produced by directly parsing the two named binaries.
