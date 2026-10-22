# PS3 EBOOT in Ghidra

How a PS3 executable becomes a Ghidra project, a functions export and part of the corpus. The
PS3 code images are rows of `tools/wad_simulator/crates/mercs2_exemap/data/images.tsv`; their
saved projects are rows of `scripts/ghidra_projects.tsv`.

| image_id | build | regional variants (same code) |
|---|---|---|
| `ps3-v100` | NA disc 1.00 (`BLUS30056`) | — |
| `ps3-v103-na` | NA update 1.03 | `ps3-v103-de`, `ps3-v103-eu` |
| `ps3-v100-jp` | JP disc 1.00 (`BLJM60101`) | — |
| `ps3-v101-eu` | EU disc 1.01 (`BLES00323`) | `ps3-v101-de` |

The game's `VZ.WAD` needs none of this: it is a plain big-endian `SCFF` file
([`format_reference.md` §2](format_reference.md#2-ffcs-wad-container)).

## 1. The ELF

`exemap derive <image_id> --from <container> --out <EBOOT.elf>` decrypts the SELF (and unpacks
the update PKG) and prints the result's sha256, which must be the image's `images.tsv` sha256.

| image_id | `--from` |
|---|---|
| `ps3-v100` | `game-files/ps3-version/EBOOT.BIN` |
| `ps3-v103-na` | `game-files/ps3-version/updates/UP0006-BLUS30056_00-MERCS2PATCHNA103-A0103-V0100-PE.pkg` |
| `ps3-v100-jp` | `game-files/Mercenaries 2 - WiF (Japan) [BLJM60101]/Mercenaries 2 - World in Flames (Japan) [BLJM60101]/PS3_GAME/USRDIR/EBOOT.BIN` |
| `ps3-v101-eu` | `game-files/Mercenaries 2 - WiF (Europe) (En,Fr,De,Es,It,Ru) [BLES00323]/Mercenaries 2 - World in Flames (Europe) (En,Fr,De,Es,It,Ru) [BLES00323]/PS3_GAME/USRDIR/EBOOT.BIN` |

`exemap` is `tools/wad_simulator/target/release/exemap` (`cargo build --release -p mercs2_exemap`).

## 2. The project

```bash
GHIDRA_HEADLESS_MAXMEM=32G <analyzeHeadless> "$PWD/<project_dir>" <project_name> \
  -import "$PWD/<EBOOT.elf>" -overwrite \
  -processor PowerPC:BE:64:default -loader ElfLoader \
  -scriptPath "$PWD/tools/ghidra_x360" \
  -preScript SeedOpdFunctionsNoDisasm.java <opd_va> <opd_size> \
  < /dev/null > <run.log> 2>&1
```

- `<analyzeHeadless>` is the `ghidra_headless` key of `tools/wad_simulator/.mercs2-local.toml`;
  `<project_dir>`, `<project_name>` and the program name are the image's `ghidra_projects.tsv` row.
- The section names are stripped, so `SeedOpdFunctionsNoDisasm.java` takes the `.opd`
  function-descriptor table as an address range: section 24 of the ELF's section header table.
  It creates one function per 8-byte descriptor (`u32 code, u32 toc`) and leaves the
  disassembly to auto-analysis.

  | image_id | `<opd_va>` | `<opd_size>` | descriptors |
  |---|---|---|---:|
  | `ps3-v100` | `0x00ff93b8` | `0x0004d7e0` | 39,676 |
  | `ps3-v103-na` | `0x00ff9588` | `0x0004da18` | 39,747 |
  | `ps3-v100-jp` | `0x00ff93e0` | `0x0004d7e8` | 39,677 |
  | `ps3-v101-eu` | `0x00ff93b8` | `0x0004d7e0` | 39,676 |

- Auto-analysis took 45,774 s (`ps3-v101-eu`) and 46,270 s (`ps3-v100-jp`) on 2026-10-21/22.
- The projects were built with `tools/ghidra_x360/NameFromStrings.java` as a postScript too; on
  every PS3 image it finds 3,667 (`ps3-v100-jp`: 3,679) `Class::Method` strings and names 0
  functions.

## 3. Sidecars, exports, match graph, corpus

Every export reads `output/_exemap_exports/`; run in this order:

1. `exemap rtti <EBOOT.elf> --out output/_exemap_exports/<id>.rtti.tsv` and
   `exemap luareg <EBOOT.elf> --out output/_exemap_exports/<id>.luareg.tsv`.
2. `exemap imports <id> --from <container> --exports output/_exemap_exports` — the PRX import
   stubs (`<id>.imports.tsv`), which `FnMnemonicSig.java` and `ExportFunctions.java` require.
3. `FnMnemonicSig.java` on the saved project, read-only:

   ```bash
   GHIDRA_HEADLESS_MAXMEM=32G <analyzeHeadless> "$PWD/<project_dir>" <project_name> \
     -process <program> -readOnly -noanalysis -scriptPath "$PWD/scripts/ghidra_scripts" \
     -postScript FnMnemonicSig.java <outDir> SECTION1,SECTION2,SECTION3,SECTION4 \
       "$PWD/scripts/ghidra_scripts/pe_import_ordinals.tsv" "$PWD/output/_exemap_exports/<id>.imports.tsv"
   ```

   then copy `<outDir>/fnsig_<program>.json` to `output/_exemap_exports/<id>.fnsig.json`. The block
   list is the row's `code_blocks` column.
4. `GHIDRA_HEADLESS_MAXMEM=32G GHIDRA_THREADS=<n> scripts/ghidra_export_functions.sh <id>` →
   `output/_ghidra_exports/<id>.functions.jsonl`.
5. `exemap match <id> <other> --exports output/_exemap_exports --evidence vtable,lua,bytes,string,callee
   --out output/_exemap_exports/match-v3/<id>__<other>.tsv --conflicts …/<id>__<other>.conflicts.tsv`
   against `ps3-v100` and `ps3-v103-na`, then
   `exemap coverage --matches output/_exemap_exports/match-v3 --out … --contradictions …`, which
   must report 0 contradictions.
6. `exemap annotate` for **every** exported code image (a new graph image adds translations to all
   of them), then `cd tools/corpus_mcp && node src/ingest.js --sources ghidra`.

## Static anchors (ps3-v100)

Image `ps3-v100` (`images.tsv`; sha256 `dfb5b1c5…`, `game-files/ps3-version/EBOOT.elf`). Read from
the ELF's PT_LOAD bytes, 2026-10-22.

| Anchor | VA | Bytes |
|---|---|---|
| `VZ.WAD` string | `0x00DDAB78` | `VZ.WAD\0` |
| Filename table slot for `VZ.WAD` | `0x00FC63B4` | `0x00DDAB78` |
| `FxArchiveStoreFile` vtable | `0x00FB4D60` | first entry `.opd` descriptor `0x01046A70` → code `0x00DB2A30`, toc `0x0104EB98` |
| `FxArchiveStoreFile` typeinfo name | `0x00DF06A8` | `N6OC3Ent4Face18FxArchiveStoreFileE` |
| `IsDLC` string | `0x00DF0530` | `IsDLC\0` |
| `SetMasterScriptName` string | `0x00DE16F8` | `SetMasterScriptName\0` |

A vtable entry is the address of an `.opd` descriptor, not of code; the code address is the
descriptor's first word. Functions use the TOC in `r2`: string and table references are
TOC-relative, so direct code xrefs to a string are often empty — go through the table slot or
the class.
