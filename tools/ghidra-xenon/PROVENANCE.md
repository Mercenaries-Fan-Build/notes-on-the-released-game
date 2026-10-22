# GhidraXenon (local build) — provenance

Committed: this file, `build.sh`, `reimport.sh` and `.gitignore`. Local only, not committed, not
distributed (mixed and unknown licences, below): `GhidraXenon/`, `upstream/` and `dist/`, which
`.gitignore` excludes.

## Upstream

- Repository: https://github.com/freeqaz/ghidra-xenon-extension
- Commit: `3db42fe7db507f45d413b9536e259a08e427d23b` (2026-02-12, "Include SLEIGH source files in
  extension zip"), recorded in `upstream/COMMIT.txt`.
- Unmodified upstream files kept for reference in `upstream/`: `vmx128.sinc`, `ppc_xenon.ldefs`,
  `ppc_64_xenon.slaspec`, `extension.properties`, `Module.manifest`.

## Licence status

- The upstream repository has no LICENSE file. Its licence is unknown.
- `vmx128.sinc` line 1 reads: `# Based on https://github.com/NationalSecurityAgency/ghidra/files/8405335/vmx128.txt`
  — a file attached to a Ghidra GitHub issue. The licence of that attachment is unknown.
- Upstream's `ghidra_scripts/RecoverMSVCSwitchTables.java` and `TestMSVCSwitchRecovery.java`
  carry the Ghidra Apache-2.0 header ("IP: GHIDRA"). They are not part of this build.

## Files in `GhidraXenon/data/languages/`

Copies of Ghidra 12.1.4 `Ghidra/Processors/PowerPC/data/languages/` (Apache-2.0), byte-identical:
`ppc_common.sinc`, `ppc_instructions.sinc`, `lmwInstructions.sinc`, `lswInstructions.sinc`,
`mulhwInstructions.sinc`, `stmwInstructions.sinc`, `stswiInstructions.sinc`, `ppc_embedded.sinc`,
`vsx.sinc`, `ppc_a2.sinc`, `quicciii.sinc`, `FPRC.sinc`, `ppc_64.pspec`, `ppc_64_32.cspec`,
`ppc.dwarf`.

Copies of Ghidra 12.1.4 files (Apache-2.0), modified — the only change is `@ifndef XENON_VMX128` /
`@endif` lines around constructors (see Changes, item 2):
`altivec.sinc`, `ppc_isa.sinc`.

Derived from Ghidra 12.1.4 `ppc_64_isa_altivec_be.slaspec` (Apache-2.0): `ppc_64_xenon.slaspec`.

From upstream GhidraXenon (licence unknown): `vmx128.sinc` (modified, see Changes), `ppc_xenon.ldefs`
(unmodified).

## Research references (read only, not copied)

Xenia (BSD licence, header of each file), commit `95a5c3ee250f80c3b9d139658649d9ffb6db3eec`,
`src/xenia/cpu/ppc/`:
- `ppc_instr.h:294-308` — VX128_P format: PERMh bits 6-8, VB128l bits 11-15, PERMl bits 16-20,
  `PERM = PERMl | (PERMh << 5)`.
- `ppc_decode_data.h:639-658` — the same VX128_P layout and `UIMM() = PERMl | (PERMh << 5)`.
- `ppc_emit_altivec.cc:1216-1227` — `InstrEmit_vpermwi128`: `VD.x = VB.uimm[6-7]`, `VD.y = VB.uimm[4-5]`,
  `VD.z = VB.uimm[2-3]`, `VD.w = VB.uimm[0-1]`.
- `ppc_emit_altivec.cc:1202-1214` — `InstrEmit_vperm_` (`Permute(VC, VA, VB, INT8_TYPE)`) is used by
  both `InstrEmit_vperm` and `InstrEmit_vperm128`.
- `ppc_emit_altivec.cc:36-42` and `ppc_opcode_table_gen.cc` — VMX128 opcode values and per-format masks,
  used as the oracle for the encoding-space check.

## Changes

1. Rebase onto Ghidra 12.1.4. Upstream bundled older copies of `ppc_common.sinc`,
   `ppc_instructions.sinc`, `ppc_isa.sinc`, `altivec.sinc` and `ppc_64.pspec`; these are replaced by
   the 12.1.4 files listed above. `ppc_64_xenon.slaspec` is 12.1.4's `ppc_64_isa_altivec_be.slaspec`
   plus `@define XENON_VMX128 "1"` and `@include "vmx128.sinc"`. Upstream's `@define NO_STVEPX` is
   replaced by the `XENON_VMX128` guard (item 2).
2. Later-ISA constructors whose encodings are VMX128 encodings are excluded from this language with
   `@ifndef XENON_VMX128` guards. Without them they win SLEIGH's specificity match and VMX128
   instructions decode as them (or, for `stvepx`/`stvepxl`, sleigh refuses to compile: identical patterns
   with `lvlxl`/`lvrxl`). Guarded constructors:
   - `altivec.sinc`: `vaddecuq`, `vaddeuqm`, `vcmpequd`, `vcmpgtsd`, `vcmpgtud`, `vpopcntb`, `vpopcnth`,
     `vsubecuq`, `vsubeuqm` (ISA 2.07 group, p-code ops `altv207_*`); `vabsdub`, `vabsduh`,
     `vcmpneb`, `vcmpneb.`, `vcmpneh`, `vcmpneh.`, `vcmpnew`, `vcmpnezb.`, `vcmpnezh.`, `vcmpnezw`,
     `vpermr` (ISA 3.0 group, p-code ops `altv300_*`).
   - `ppc_isa.sinc`: `stvepx`, `stvepxl`; `maddhd`, `maddhdu`, `maddld`.
   The list is exactly the set of constructors that took a VMX128 encoding in an exhaustive check of
   the low 11 bits of primary opcodes 4, 5, 6 and 31 against Xenia's VMX128 opcode table; none of these
   mnemonics appears in Xenia's Xenon opcode table.
3. `vmx128.sinc`, `vpermwi128`: the PERM low 5 bits are read from bits 16-20 (field `permL_16_20`), not
   11-15 (the VB register field). Element i of vD (element 0 = bits 96-127) is word
   `(PERM >> (6 - 2*i)) & 3` of vB.
4. `vmx128.sinc`, register file: VMX128 vr0-vr31 are the AltiVec registers. The VMX128 register
   operands for 0-31 (`vregD/vregA/vregB` bank 00 and `vregC_06_08`) export `vs32`-`vs63`, the storage
   12.1.4 uses for AltiVec v0-v31, and display as `vr0`-`vr31` through separate name fields
   (`*_00n`, `vregC_06_08n`). Only `vr32`-`vr127` are defined as new registers (offset 0x10000).
5. `vmx128.sinc`, `vperm128`: the body is the single p-code op `vectorPermute(vA, vB, vC)`, the op
   12.1.4's `altivec.sinc` uses for `vperm` (declared in `ppc_common.sinc`). Xenia
   `ppc_emit_altivec.cc:1202-1214`: `InstrEmit_vperm128` calls `InstrEmit_vperm_`, the same
   implementation as `vperm`. Upstream's 16-lane body with internal branches made the decompiler fail
   with "Unable to find unique hash for varnode" on functions using `vperm128`.
6. `GhidraXenon/extension.properties`: written for this build (`version=12.1.4`).
7. Not included from upstream: `ghidra_scripts/`, the prebuilt upstream `.sla`, `build_extension.sh`.

## Build and use

- `build.sh <outZip>` compiles `ppc_64_xenon.slaspec` with Ghidra 12.1.4's `support/sleigh` and zips
  `GhidraXenon/`. The current build is `dist/ghidra_12.1.4_PUBLIC_GhidraXenon.zip`.
- The extension is loaded without installing it: unzip into
  `<settingsdir>/<user>-ghidra/ghidra_12.1.4_PUBLIC/Extensions/` and start Ghidra with
  `-Dapplication.settingsdir=<settingsdir>` (headless: `GHIDRA_HEADLESS_JAVA_OPTIONS`).
- `reimport.sh <extensionZip> <inputPE> <funcStarts> <rttiTsv> <outDir> <projectName> <decompPrefix>`
  imports one Xbox 360 PE into a new project with `PowerPC:BE:64:Xenon` using the seeded pipeline of
  the existing `_ghidra_x360*` projects, with the notes repo's
  `scripts/ghidra_scripts/RecoverReferencedTables.java` as the first postScript. That script's log is
  `<outDir>/recover_tables.log`; its forensic ledger (every table, flow case or conflict no rule
  classifies, left unchanged in the program) is `<outDir>/recover_tables_ledger.tsv`. The rtti sidecar
  is the image's `output/_exemap_exports/<id>.rtti.tsv`. The classification rules, ledger kinds and
  per-build results are in the notes repo's `docs/xbox360_ghidra_xenon.md` and the script's header.

## Known Ghidra decompiler bug (not in this language)

Ghidra 12.1.4's decompiler fails one function per Xbox build with
"Low-level Error: Conditional execution: Illegal op in iblock" (retail 825e9970, Jul 2008 final
825e3a48, Jul 2008 profile 826825c8; all 140 bytes).

- The error is thrown at `Ghidra/Features/Decompiler/src/decompile/cpp/condexe.cc:261`
  (`ConditionalExecution::resolveIblockRead`).
- `ConditionalExecution::testOpRead` (`condexe.cc:120-142`) accepts a COPY in the iblock whose input is
  defined outside the iblock. `resolveIblockRead` (`condexe.cc:242-262`) handles a COPY only when its
  input is unwritten or a MULTIEQUAL in the iblock; every other COPY reaches the throw.
- In 825e9970 the COPY is `or r3,r29,r29` at 825e99b4 (r29 is set at 825e997c), in the iblock
  825e99b0-825e99bc. Replacing that word in a scratch copy with `addi r3,r29,1` (an INT_ADD with a
  constant, which takes the pullback path) makes the function decompile. Replacing it with
  `addi r3,r29,0`, or removing the `extsb` at 825e99b0, does not.
- Stock `PowerPC:BE:64:A2ALT-32addr` does not reach this code: it marks `__savegprlr` (82861bd8) as
  non-returning, so 825e9970's body is two instructions.
