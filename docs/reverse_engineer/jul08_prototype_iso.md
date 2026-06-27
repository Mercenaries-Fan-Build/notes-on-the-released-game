# Mercenaries 2 — "Jul 11 2008" Xbox 360 Preview ISO: recovery + debug-symbol findings

Source: `game-files/Mercenaries 2 World in Flames (Jul 11, 2008 prototype)/Mercenaries 2 Preview X360 (Jul 11 2008).iso`
(6,344,605,696 bytes, XDVDFS / single-layer rebuilt image, partition base 0).

## TL;DR — yes, this build has debug symbols

The game executable `mercs2_xenon_p_EN_FR.xex` (original PE name **`Mercs2_Xenon_P.exe`**,
"_P" = Preview) is:
- **DEVKIT-encrypted** (the XEX AES session key unwraps with the all-zero devkit KEK,
  not the retail key) → a **non-retail development build**.
- Its PE carries an **IMAGE_DEBUG_TYPE_CODEVIEW (type 2) debug directory entry** → it
  references a PDB (symbol file).
- The first decompressed 70 KB of `.rdata` is **full of debug strings**: Havok source
  paths (`..\Havok\Source\Common/Base/Memory/Memory/Malloc/hkMallocMemory.h`),
  assert/warning/report text, and thousands of C++ symbol names
  (`PgPhysicsActor::Init`, `PgHavokManager::Update`, vehicle tuning fields, bone names,
  the build tag `CLIENT.PhAn.Pandemic_CentralTechAndTools`).

This is dramatically richer than retail and is a strong RE target.

## Full ISO contents (56 files, 3 dirs)

See `output/jul08_prototype/iso_filelist.txt`. Highlights:
- `default.xex` (4.7 MB) and `mercs2_xenon_p_EN_FR.xex` (5.1 MB) — both XEX2, devkit, LZX-compressed.
- `vz.wad` (2.0 GB) — note: smaller than retail's 2.56 GB (earlier content).
- `english.wad`, `french.wad`, `loading.wad`, `shell.wad`, `shaders.bin`.
- `audios/*.pws` (ambience, music, vo_stream EN/FR), `movies/*.bik` (Bink), `$systemupdate/`.

Extract any file with:
```
python tools/xdvdfs_extract.py "<iso>" --extract <out_dir> [--glob SUBSTR]
```

## XEX executable details (`mercs2_xenon_p_EN_FR.xex`)

| | |
|---|---|
| Format | XEX2, module flag TITLE, 14 optional headers |
| Original PE name | `Mercs2_Xenon_P.exe` |
| Base file format | encryption=1 (**devkit KEK**), compression=2 (**LZX**, window 0x8000) |
| Image | PE32, machine 0x01F2 (PowerPC / Xenon), 13 sections |
| Sections | `.rdata .pdata BINKBSS .text(10MB) BINK .data(19MB) .tls .XBMOVIE BINKDATA .edata .idata .XBLD .reloc` |
| XDK imports | XRTLLIBI, XAPILIB, D3D9I, D3DX9, XGRAPHC, XBOXKRNL, XNET, XONLINE, XHV, LIBCMT, XAUD, XMP |
| Debug dir | 1 entry, **type 2 = CodeView** at RVA 0x111298 (PDB reference; path string is in block 1) |

## Tooling written (reusable)

- `tools/xdvdfs_extract.py` — XDVDFS (Xbox 360 disc) reader: `--list` / `--extract`. **Works fully.**
- `tools/xex_info.py` — XEX2 header dump + plaintext debug-string scan.
- `tools/xex_unpack.py` — XEX → PE: unwrap session key (devkit/retail), AES-128-CBC decrypt,
  deblock the LZX stream (self-validates the AES key), then LZX-decompress. Use `--devkit`.
- `tools/lzx_decompress.py` — MS-LZX decompressor.

## Recognizable chunks across the whole ISO (signature scan)

A full 6.3 GB signature sweep (`tools/_iso_sig_scan` logic) found:

- **`shaders.bin` is a debug-symbol goldmine.** It embeds **344 shader debug-database
  paths** of the form
  `d:\projects\ReleaseLine\Mercs2\Pangea\Shaders\Xbox 360\<Shader>.updb`
  (`.updb` = microcode/shader program debug DB), plus 7,422 readable strings total.
  This reveals the **build-machine tree**: `d:\projects\ReleaseLine\Mercs2\Pangea\…`.
  The exe's PDB almost certainly lives under that same `d:\projects\ReleaseLine\Mercs2\`
  tree. Full list: `output/jul08_prototype/shaders_bin_updb_paths.txt`
  (sample: Pg2DDepth, PgAtmosphere, PgBillboardTree, PgBloom, PgCloud, PgDecal…).
- **23 extra `XEX2` signatures** beyond the 2 real executables (embedded modules /
  resources; mostly clustered just after `shaders.bin`).
- **DDS textures** and **Bink** video (the `movies/*.bik`).
- The scattered `RSDS`/`NB10`/`SDSR` hits in the raw image are **coincidental** 4-byte
  matches inside compressed data — none is a real CodeView record (no GUID + `.pdb`
  path follows). The exe's real CodeView/PDB record is inside the compressed XEX
  (LZX block ≥ 1), so it does not appear in the raw scan.

## RESOLVED — full PE recovered, PDB identified

The full 32,374,784-byte PE decompresses cleanly. The blocker was that my hand-rolled
`tools/lzx_decompress.py` lacked the **per-frame 16-bit bitstream realignment** that MS-LZX
performs every 32,768 output bytes (libmspack `lzxd.c`). Rather than keep hand-rolling, we
vendored the community reference decoder `sp00nznet/360tools` (pure-Python, mspack-faithful) at
`tools/external/x360tools/lzx_decompress.py`, and `tools/xex_unpack.py` now uses it.
**`python tools/xex_unpack.py <xex> --devkit` produces the full PE end-to-end.**

### The PDB (the prize)

| | |
|---|---|
| **PDB path** | **`d:\projects\releaseline\mercs2\pangea\Build\Xbox 360\Profile\Mercs2_Xenon_P.pdb`** |
| **PDB GUID** | `5313ddba-1da8-914c-a6f8-75cc9483d5a7` (CodeView RSDS at PE off 0x111298) |
| Build config | **`Profile`** — a profiling build (explains devkit-signed + symbols retained) |

The `.pdb` *file* is not on the disc (it lived on the build machine), but the GUID+age uniquely
identify it for any symbol-server match, and the recovered PE itself is a symbol goldmine.

### Symbol haul from the recovered PE

- **57,161 strings**, **324 RTTI C++ class names** (demanglable; RTTI was on for Havok —
  `hkXmlParser`, `hkpStorageExtendedMeshShape`, `hkSingleton<…>`, etc.).
- **48 source-file paths** mapping the engine tree under `d:\projects\ReleaseLine\Mercs2\`:
  `Pangea\` (graphics + Havok), `Pal\` (Pandemic Audio Library), `pimp\` (job/threading system,
  under `d:\mainline\mercs2\pimp\`), `Lua-5.1.2\src\` (the Lua VM — ldo.c, lparser.c, lgc.c…).
- Earlier finds still hold: Havok source paths, asserts, `PgPhysicsActor`/`PgHavokManager`
  symbols, vehicle tuning fields, etc.

### Saved artifacts (`output/jul08_prototype/`)

- `mercs2_xenon_p.pe_full.bin` — the full 32 MB recovered PE (PowerPC, 13 sections).
- `mercs2_xenon_p.pe_full_strings.txt` — all 57,161 strings.
- `mercs2_xenon_p.rtti_classes.txt` — 324 RTTI class names.
- `mercs2_xenon_p.source_paths.txt` — 48 source-file build paths.
- `mercs2_xenon_p.lzxstream.bin` — decrypted+deblocked LZX stream (for reference).
- `shaders_bin_updb_paths.txt`, `iso_filelist.txt` — see above.

### Community resources used

- `sp00nznet/360tools` — pure-Python XEX→PE (its LZX decoder is what fixed us). VENDORED.
- `GoobyCorp/Xbox-360-Crypto` — DLL-backed LZX (revealed the `0x8000` frame/chunk constant).
- `emoose/idaxex` (`xex1tool`) and `xextool` (`-c u -e u`) — C++ reference XEX tools.

## Deep-dive analyses (the rest of the disc)

Beyond the game executable's symbol map ([../mercs2-pdb-analysis/](../mercs2-pdb-analysis/)),
nine parallel deep dives covered the remaining untouched aspects (each independently verified):

| Doc | Covers | Headline |
|---|---|---|
| [default_xex.md](default_xex.md) | the boot loader executable | `default.xex` = `Mercs2_Xenon_F.exe` (distinct from the game's `_P`); own PE/PDB |
| [xex_metadata.md](xex_metadata.md) | XEX2 identity headers (both exes) | title_id `0x45410828` (pub `EA`), media/version zeroed (preview), 12 XDK static libs |
| [imports-exports.md](../mercs2-pdb-analysis/imports-exports.md) | XDK/kernel API surface | dynamic imports incl. **`xbdm.xex`** (debug monitor → devkit); `XHV` voice, `XONLINE` Live, `XAUD`/`XMP` audio |
| [pdata-functions.md](../mercs2-pdb-analysis/pdata-functions.md) | complete function inventory | `.pdata` = 8-byte BE-absolute-VA records → **~39,000 functions** in `.text` |
| [data-defaults.md](../mercs2-pdb-analysis/data-defaults.md) | `.data` (19 MB) config/default tables | reflection default tables → concrete tunable values |
| [embedded_xex_modules.md](embedded_xex_modules.md) | the 23 extra `XEX2` signature hits | which disc files they fall in / what they are |
| [disc_media_inventory.md](disc_media_inventory.md) | `movies/*.bik`, `audios/*.pws`, `$systemupdate/` | Bink cinematics + EN/FR-only VO streams |
| [vz_wad_prototype.md](vz_wad_prototype.md) | prototype `vz.wad` structure vs retail | FFCS/PTHS block-table diff (2.0 GB vs retail 2.56 GB) |
| [prototype_vs_retail.md](prototype_vs_retail.md) | what makes this a prototype | Profile build, leaked source tree, dlctest01 lineage, debug/test strings |

> **DONE — full Ghidra decompilation of the Xbox PPC `.text`:** [xbox_ppc_decompilation.md](xbox_ppc_decompilation.md).
> **38,581 functions, 0 decompile failures, 538 named** from the build's own debug strings →
> `output/_ghidra_x360/xenon_decomp_named.c` (12.6 MB). Names the game-layer `Pg*`/`Tt*` functions
> the PC-retail pairing couldn't reach (incl. Live/store + traffic-debug toggles). Known gap:
> Xenon VMX128 vector instructions aren't in stock Ghidra PowerPC.
