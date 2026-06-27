# default.xex — the disc boot executable (Mercs2_Xenon_F.exe)

**Scope:** Unpack and document `default.xex` from the Jul 11 2008 X360 preview disc, and contrast it with the game executable (`mercs2_xenon_p_EN_FR.xex` → `Mercs2_Xenon_P.pdb`).
**Provenance:** Mercenaries 2: World in Flames, Jul 11 2008 X360 preview prototype, Pandemic "Pangea" engine. Disc: `game-files/Mercenaries 2 World in Flames (Jul 11, 2008 prototype)/...iso`.

> Cross-links: [`jul08_prototype_iso.md`](jul08_prototype_iso.md) (disc/file table), `docs/mercs2-pdb-analysis/` (system docs from the game exe).

---

## TL;DR — most notable findings

- **`default.xex` is NOT a thin loader — it is a complete 26 MB game executable.** Unpacked PE = **26,476,544 B**, PowerPC (machine `0x1F2`), 13 sections, image base `0x82000000`. The "loader" intuition is wrong; on Xbox 360 `default.xex` *is* the title the dashboard boots.
- **It is the `Final` build, while the separately-shipped game xex is the `Profile` build.** Embedded CodeView/RSDS PDB path = `d:\projects\releaseline\mercs2\pangea\Build\Xbox 360\**Final**\Mercs2_Xenon_F.pdb` (GUID `60142614-8E44-4696-B3D9-27EDA41D5CBB`, age 5). The game xex's PDB is the `Profile` variant `...\Profile\Mercs2_Xenon_P.pdb` (GUID `BADD1353-A81D-4C91-A6F8-75CC9483D5A7`).
- **Original PE name = `Mercs2_Xenon_F.exe`**; XEX title ID = **`45410828`** (EA / Mercenaries 2). Build timestamp (PE FileHeader) = **2008-07-12 01:35:28 UTC** — the game (Profile) exe was linked 105 s later at 01:37:13 UTC the same day.
- The `Final` build is **smaller** than the `Profile` build (`.text` 0x8E79AC vs 0x9B5074; `.data` 0xE2C93C vs 0x12DDC9C; whole PE 26.5 MB vs 32.4 MB) — Profile carries extra instrumentation/symbols, consistent with a profiling/dev configuration.
- Build-farm log path leaked in `.data`: **`\\mcbain\MERCS\PangeaLogs`**.

---

## 1. Unpack

```
$ python tools/xex_unpack.py output/_scratch/jul08_iso/default.xex --devkit \
      --out output/jul08_prototype/default_xex.pe.bin
=== default.xex
  enc=1 comp=2  pe_off=0x4000 sec_off=0x100 image_size=26,476,544
  wrapped_key=6710fddc488d705950c633de02de79e1 -> file_key=edd665a79a9aee837c5ffdb9ad2732f7 (devkit KEK)
  LZX window_size=0x8000 first_block_size=0x10000
  deblocked OK: 79 blocks -> 4,636,020 B LZX stream  [AES KEY VALID]
  PE image: 26,476,544 B  magic=b'MZ'  (MZ ok)
  wrote output\jul08_prototype\default_xex.pe.bin
```

Devkit-encrypted (`encryption=1`) + LZX-compressed (`compression=2`), same packaging as the game xex. The devkit KEK decrypted the AES file key cleanly (key valid).

## 2. XEX header (`tools/xex_info.py`)

```
=== default.xex (4,739,072 B) magic=b'XEX2'
  module_flags=0x00000001  pe_data_off=0x4000  opt_headers=13
  flags: TITLE
    ImageBaseAddr    = 0x8257eb20
    OriginalPEName?  -> "Mercs2_Xenon_F.exe"   (string @ xex+0x28a8)
    ImportLibraries  = 0x28bc
  BaseFileFormat: encryption=1 (ENCRYPTED)  compression=2 (compressed)
```

- **OriginalPEName** (opt header `0x00018002`): `Mercs2_Xenon_F.exe` — note the **`_F`** (Final) suffix vs the game exe's **`_P`** (Profile).
- **module flag = `TITLE`** (`0x1`): this is a title executable, i.e. the bootable game, not a system/loader stub.
- **ResourceInfo** (opt `0x2FF`): resource title/name = `45410828`, addr `0x83890000`, size `0xACD33`.
- **ExecutionInfo** (opt `0x40006`): **title ID `45410828`**, version/baseversion `00000000` (typical for a preview/dev build — no shipped version stamped).

### Import libraries (from `.idata`/header region)
```
XAPILIB  D3D9  D3DX9  XGRAPHC  XBOXKRNL  XNET  XONLINE  XHV  LIBCMT  XAUD  XMP
```
These are the standard XDK title imports (D3D9/D3DX9 graphics, XNET/XONLINE/XHV live, XAUD/XMP audio, XBOXKRNL kernel, LIBCMT CRT). A pure launcher would not link D3D9/D3DX9/XAUD — further evidence this is the full game, not a stub.

## 3. PE sections (PowerPC, machine 0x1F2, 13 sections, imagebase 0x82000000)

Parsed from `default_xex.pe.bin` (e_lfanew `0x138`, optmagic `0x10B` PE32):

| Section  | VA          | VSize    | RawPtr   | Notes |
|----------|-------------|----------|----------|-------|
| .rdata   | 0x00000600  | 0xFFFBC  | 0x600    | read-only data; **RSDS @ file 0xF9504** |
| .pdata   | 0x00100600  | 0x456C8  | 0x100600 | PPC exception/unwind |
| BINKBSS  | 0x00145E00  | 0x28E0   | 0x145E00 | Bink video BSS |
| .text    | 0x00150000  | 0x8E79AC | 0x148800 | code |
| BINK     | 0x00A37A00  | 0x10848  | 0xA30200 | Bink video code |
| .data    | 0x00A50000  | 0xE2C93C | 0xA40C00 | data |
| .XBMOVIE | 0x0187CA00  | 0xC      | —        | |
| .tls     | 0x0187CC00  | 0x1D     | —        | thread-local |
| BINKDATA | 0x0187CE00  | 0x3D88   | —        | |
| .edata   | 0x01890000  | 0xA25    | —        | exports |
| .idata   | 0x018A0000  | 0x4B2    | —        | imports |
| .XBLD    | 0x018B0000  | 0xB0     | —        | Xbox loader metadata |
| .reloc   | 0x018B0200  | 0xF82E8  | —        | relocations |

Identical section *layout/order* to the game exe (same engine, same toolchain); only sizes differ. The presence of `BINK`/`BINKBSS`/`BINKDATA` (RAD Bink video) and `.XBMOVIE` again shows full game content.

## 4. Embedded debug identity (CodeView RSDS)

```
RSDS @ 0xF9504 (in .rdata)
  GUID = 60142614-8E44-4696-B3D9-27EDA41D5CBB
  age  = 5
  path = d:\projects\releaseline\mercs2\pangea\Build\Xbox 360\Final\Mercs2_Xenon_F.pdb
```

This is the matching PDB needed to symbolicate `default.xex`. It is a **different PDB** from the game exe (different GUID, `Final` vs `Profile` directory, `_F` vs `_P` basename). The PDB itself is not on the disc.

## 5. How it differs from the game exe (`Mercs2_Xenon_P`)

| Property            | default.xex (this doc)                 | game xex (mercs2_xenon_p)             |
|---------------------|----------------------------------------|---------------------------------------|
| OriginalPEName      | `Mercs2_Xenon_F.exe`                    | `Mercs2_Xenon_P.exe` (`_P`)           |
| Build config        | **Final**                              | **Profile**                           |
| PDB path            | `...\Final\Mercs2_Xenon_F.pdb`          | `...\Profile\Mercs2_Xenon_P.pdb`      |
| PDB GUID            | `60142614-8E44-4696-B3D9-27EDA41D5CBB`  | `BADD1353-A81D-4C91-A6F8-75CC9483D5A7`|
| Unpacked PE size    | 26,476,544 B                           | 32,374,784 B                          |
| `.text` VSize       | 0x8E79AC                               | 0x9B5074                              |
| `.data` VSize       | 0xE2C93C                               | 0x12DDC9C (~19 MB)                    |
| `.rdata` VSize      | 0xFFFBC                                | 0x117DDC                             |
| Entry point (RVA)   | 0x57EB20                                | 0x610C50                              |
| Image base          | 0x82000000                             | 0x82000000                            |
| PE TimeDateStamp    | 0x48780A60 = 2008-07-12 01:35:28 UTC   | 0x48780AC9 = 2008-07-12 01:37:13 UTC  |
| Machine             | PowerPC 0x1F2                           | PowerPC 0x1F2                         |
| Title ID            | 45410828                               | 45410828 (same title)                 |

**Interpretation (inference):** these are two configurations of the *same* source tree built back-to-back from the same build line (`d:\projects\releaseline\mercs2\pangea`). On disc, `default.xex` is the executable the 360 dashboard launches — here it is the leaner **Final** build. The separately-named `mercs2_xenon_p_EN_FR.xex` is the **Profile** build (larger: extra profiling instrumentation, more `.text`/`.data`/`.rdata`), likely the dev/instrumented variant kept on the preview disc alongside the bootable one. The ~105 s gap in link timestamps is consistent with one CI run producing both configs.

## 6. Strings of interest

- `d:\projects\releaseline\mercs2\pangea\Build\Xbox 360\Final\Mercs2_Xenon_F.pdb` — build path + config.
- `Mercs2_Xenon_F.pdb`, `Mercs2_Xenon_F.exe` — Final-config names.
- **`\\mcbain\MERCS\PangeaLogs`** — UNC path to the build/farm log share (`LogPath \\mcbain\MERCS\PangeaLogs`). Internal Pandemic infrastructure hostname `mcbain`.
- `BuiltinTypeRegistry@@` — RTTI/reflection symbol (Pangea type registry), consistent with the ECS/reflection system documented under `docs/mercs2-ecs/`.
- No standalone `.cpp`/assert source paths surfaced in the header debug scan (`xex_info` reported 0 unique `.pdb`/source/assert in the *xex header* region; the RSDS lives in the unpacked PE `.rdata`, found at file offset `0xF9504`).

---

## Provenance of every number above
- Unpack + key/section/size lines: `python tools/xex_unpack.py output/_scratch/jul08_iso/default.xex --devkit --out output/jul08_prototype/default_xex.pe.bin`.
- XEX header / OriginalPEName / imports / title ID: `python tools/xex_info.py output/_scratch/jul08_iso/default.xex` plus direct parse of `default.xex` opt-header offsets (`0x28a8` PE name string, `0x28bc` import libs, `0x2864` ResourceInfo, `0x2980` ExecutionInfo).
- Section table, entry point, image base, TimeDateStamp, RSDS GUID/path: direct struct parse of `output/jul08_prototype/default_xex.pe.bin` (PE at e_lfanew `0x138`).
- Game-exe comparison values: same parse of `output/jul08_prototype/mercs2_xenon_p.pe_full.bin`.

*Inferences are labelled "(inference)" / "Interpretation"; everything else is read directly from the extracted bytes.*
