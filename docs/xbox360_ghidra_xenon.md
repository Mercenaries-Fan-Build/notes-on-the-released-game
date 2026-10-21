# Xbox 360 Ghidra projects with the Xenon language

The three Xbox 360 builds are analysed in Ghidra 12.1.4 with the language `PowerPC:BE:64:Xenon`
(PowerPC 64-bit, 32-bit addressing, AltiVec and the Xenon VMX128 vector extension). The language
is a local Ghidra extension at `/Volumes/Projects/mercenaries-game/tools/ghidra-xenon/`. It is
not part of this repository and is not installed into the Ghidra install or the user's Ghidra
settings; its upstream source has no licence.

## Projects

| Build | Input PE | Project |
|---|---|---|
| Retail | `output/_ghidra_x360_retail/default.pe_ghidra.bin` | `output/_ghidra_x360_retail_xenon/proj/mercs2xenon_retail_xenon` |
| Jul 2008 preview, Final config | `output/jul08_prototype/default_xex.pe_ghidra.bin` | `output/_ghidra_x360_final_xenon/proj/mercs2xenon_final_xenon` |
| Jul 2008 preview, Profile config | `output/jul08_prototype/mercs2_xenon_p.pe_ghidra.bin` | `output/_ghidra_x360_preview_xenon/proj/mercs2xenon_preview_xenon` |

Paths are relative to `/Volumes/Projects/mercenaries-game/`. Each project directory also holds
`func_starts.txt` (the `.pdata` function starts used as seeds), `run.log`, `recover_tables.log`,
`recover_tables_ledger.tsv` (the forensic ledger, see below), the decompile exports (`*_decomp.c`, `*_decomp_named.c`) and `ghidra_settings/`, a Ghidra settings
directory that contains the Xenon extension.

The `output/_ghidra_x360`, `output/_ghidra_x360_final` and `output/_ghidra_x360_retail` projects
are separate imports with the stock language `PowerPC:BE:64:A2ALT-32addr`.

## Opening a project

Ghidra finds the language only when it runs with the project's settings directory:

```
GHIDRA_HEADLESS_JAVA_OPTIONS="-Dapplication.settingsdir=<project dir>/ghidra_settings" \
  /opt/homebrew/Cellar/ghidra/12.1.4/libexec/support/analyzeHeadless \
  <project dir>/proj <project name> -process <program> -readOnly -postScript <script> ...
```

Ghidra adds a `<user>-ghidra/ghidra_12.1.4_PUBLIC/` level under the settings directory; the
extension is in `ghidra_settings/<user>-ghidra/ghidra_12.1.4_PUBLIC/Extensions/GhidraXenon/`.

## Pipeline

`analyzeHeadless -import <PE> -processor PowerPC:BE:64:Xenon` with:

1. preScript `tools/ghidra_x360/CreateFunctions.java <func_starts.txt>`;
2. auto-analysis (no timeout);
3. postScript `scripts/ghidra_scripts/RecoverReferencedTables.java <recover_tables.log>
   <rtti sidecar> <recover_tables_ledger.tsv>`; the rtti sidecar is
   `output/_exemap_exports/<id>.rtti.tsv`;
4. postScripts `DecompileExport.java`, `NameFromStrings.java`, `DecompileExport.java`
   (`tools/ghidra_x360/`).

## RecoverReferencedTables

Ghidra's "Create Address Tables" analyzer breaks tables at referenced addresses and drops pieces
shorter than 5 entries, which loses the short vtables that constructors reference one at a time,
and Ghidra's switch analysis leaves some jump tables unresolved. The script examines every address
an instruction references with a data reference. A table is the run of 4-byte words from that
address in which each word is a valid code pointer (`PseudoDisassembler.isValidSubroutine`); the run
ends at the next referenced address, an instruction, or defined data of another type. Each table
is classified by how the referencing instructions use it:

- **NOT POINTERS** — every referencing instruction is a load other than a 4-byte word load (byte,
  halfword, float, doubleword or vector). Nothing is changed.
- **SWITCH** — instruction flow and register def-use lead from a referencing instruction to an
  indexed word load from the table, `mtspr CTR` and `bctr`, the index stride (from the `rlwinm` or
  `mulli` that defines the index register) is 4, and no target is a function entry. The words are
  typed as pointers, the targets disassembled, the `bctr` gets a `COMPUTED_JUMP` reference to every
  target and the dispatching function's body is recomputed. No function is created at a case.
  When the dispatcher is in no function and a store writes the address where its fall-from chain
  starts, that address is a proven function entry and a function is created there (`ENTRY` in the
  log).
- **FUNCTION TABLE** — positive evidence that the words are function pointers:

  | evidence | meaning |
  |---|---|
  | store | a store writes the table address |
  | rtti | a table word is a vtable slot in the rtti sidecar |
  | bctrl | a table word is loaded, moved to CTR and called with `bctrl` |
  | lwz | a non-indexed word load from the table |
  | arg | the table address is put in r3-r10 and reaches a `bl` / `bctrl` unchanged |
  | loaded-arg | a table word is loaded into r3-r10 and reaches a `bl` / `bctrl` unchanged |
  | loaded-store | a loaded table word is stored as a value |
  | fp-variable | a store writes into the table word and the word's initial target is a function entry |
  | record-array | an indexed dispatcher with a stride other than 4 and a function at a target |

  The words are typed as pointers, the targets disassembled and a function created at each target
  that is not already a function entry.

The script repeats, with auto-analysis after each pass, until a pass changes nothing. It fails
only on internal errors and on a function-table target still inside another function's body at
that point.

### Forensic ledger

Every table, dispatcher or conflict that no rule classifies is written to
`<project dir>/recover_tables_ledger.tsv` and left unchanged in the program. Columns: pass, kind,
table address, word count, every referencing instruction (address, text, operand index and
reference type), flow context, each target's state, and the reason. The last line of
`recover_tables.log` gives the count per kind. Kinds:

| kind | meaning |
|---|---|
| NO_EVIDENCE | neither a switch dispatch nor function-table evidence |
| STRIDE_FUNCTION | the dispatcher's stride and the presence of a function at a target disagree |
| STRIDE_UNKNOWN | the dispatcher's index stride cannot be determined |
| FLOW_AMBIGUOUS | one referencing instruction reaches several `bctr`s, or one `bctr` with two strides |
| FLOW_UNHANDLED | a load or add on the table path writes no single register |
| SWITCH_NOFUNC | a dispatcher in no function whose code start no store writes |
| CONFLICT | a valid code pointer on a word covered by defined data of another type |

### Results per build

| | Retail | Final config | Profile config |
|---|---|---|---|
| tables | 3,146 | 3,129 | 3,354 |
| SWITCH | 431 | 425 | 471 |
| FUNCTION TABLE | 2,715 | 2,704 | 2,883 |
| of which record-array | 1 | 1 | 1 |
| NOT POINTERS | 2 | 2 | 1 |
| functions created | 4,883 | 4,875 | 4,375 |
| proven entries (`ENTRY`) | 8264d798 | 82647878 | 826e6428 |
| case references added | 33 | 33 | 4 |
| passes | 2 | 2 | 2 |
| ledger rows | 29 | 28 | 41 |
| CONFLICT | 28 | 27 | 40 |
| SWITCH_NOFUNC | 1 | 1 | 1 |

Each proven entry is written by `stw r10,0x1c8(r31)` (retail 82644a64, Final config 8263eb44,
Profile config 826dcc7c). No function is created at a switch case target in any build.

Retail tables per evidence kind (a table can carry several): store 2,425, arg 1,142, rtti 321,
lwz 296, loaded-arg 138, loaded-store 57, fp-variable 36, bctrl 8, record-array 1.

## What the Xenon language decodes

- The VMX128 instructions in Xenia's Xenon opcode table, with vector registers vr0-vr127. Encodings
  whose reserved fields are non-zero (for example `vrefp128` with bits 16-20 set) do not decode.
  vr0-vr31 are the same registers as AltiVec v0-v31 in the decompiler's data flow.
- VMX128 loads and stores to vr32-vr127 decode as VMX128 instructions; the stock language decodes
  them as later-ISA compares (`vcmpequd`, `vcmpneb.` and others) or not at all.
- `vpermwi128` reads its 8-bit permute immediate from bits 6-8 and 16-20.
- Every word outside the VMX128 encodings decodes exactly as in stock 12.1.4.

## Results (retail; seeded pipeline)

| | stock | Xenon |
|---|---|---|
| functions | 34,770 | 43,804 |
| instructions | 1,131,025 | 2,313,370 |

Final config: 43,720 functions, 2,306,968 instructions. Profile config: 48,247 functions,
2,515,533 instructions.

At every address both disassemble, the instruction text is identical except at the words stock
mis-decodes (177 in retail and in the Final config, 187 in the Profile config). In each build 34
instructions that stock disassembles are not disassembled by Xenon (see Open items).

## Stock language: savegprlr treated as non-returning

The stock-language projects mark 38 functions as non-returning (41 in the Profile config), among
them the 16 `__savegprlr` entry points 82861ba0-82861bdc in retail. Every function that calls one
of them is cut off after the call:

| Build | non-returning functions | call references | calling functions | functions |
|---|---|---|---|---|
| Retail | 38 | 10,579 | 10,186 | 34,770 |
| Final config | 38 | 10,553 | 10,161 | 34,710 |
| Profile config | 41 | 11,856 | 11,421 | 38,586 |

The Xenon projects mark none of these functions non-returning.

## Decompiler bug: "Conditional execution: Illegal op in iblock"

Ghidra 12.1.4's decompiler fails on one function per build: retail 825e9970, Final config
825e3a48, Profile config 826825c8. The error is thrown at `condexe.cc:261`
(`ConditionalExecution::resolveIblockRead`): `testOpRead` (`condexe.cc:120-142`) accepts a COPY in
the iblock whose input is defined outside the iblock, and `resolveIblockRead` (`condexe.cc:242-262`)
has no case for such a COPY. In 825e9970 the COPY is `or r3,r29,r29` at 825e99b4. Replacing that
word with `addi r3,r29,1` in a scratch copy makes the function decompile.

## Open items

- Ledger CONFLICT rows: most are strings that Ghidra defined starting on the last byte of a vtable
  slot. Retail vtable 8205c8ec holds 826e8670, 826e86c8, 826e8660 and then "RequestClose"; the
  string is defined from the slot's last byte (0x60, '`'). The slot's target 826e8660
  (`lis r11,0x82b5; lwz r3,-0x3a88(r11); blr`) is not disassembled. Retail targets left undefined
  this way: 826e8660, 826ea158, 826fd520, 82738f50, 827bd430. The Profile config also has CONFLICT
  rows on `word` (3) and `ImageBaseOffset32` (1) data.
- Ledger SWITCH_NOFUNC rows: the dispatcher at retail 8265a0ac (Final config 8265418c, Profile
  config 826ef284) is in no function. Its code starts at 8265a078 (Final config 82654158, Profile
  config 826ef250); no store writes that address. In retail 8265a078 is referenced only by a `b`
  from 8265a118.
- `vupkhsh128` / `vupklsh128`: the language decodes these two mnemonics at encodings that Xenia's
  opcode table assigns to `vupkhsb128` / `vupklsb128` (Xenia ignores bit 5 and bit 10 there).
  Which reading is correct is not established.
- Stock-only instructions (34 per build), all reached in stock only through pointers that no
  instruction references:
  - pointer tables that no instruction references and that Ghidra's address-table analysis accepts
    in stock but not in the Xenon run, where `AddressTable.getEntry` returns null (retail 82100634 and
    821009ac; Final config 82100154 and 821004cc; Profile config 82117ee4, 82117f1c and 821182ac);
  - a single pointer that no instruction references (retail 820f8b2c, Final config 820f8644);
  - Profile config only: the table at 820be8a0 ends at its 11th entry because
    `PseudoDisassembler.isValidSubroutine` rejects the target 828c2ad8, a 5-instruction virtual call
    thunk ending in `bctr`.
