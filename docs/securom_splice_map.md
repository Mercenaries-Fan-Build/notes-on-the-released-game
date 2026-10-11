# SecuROM splice map — where the game's code really runs

How SecuROM rearranged the PC executables' code, per build, so a patch is placed where the code
actually executes. Companion to `securom_unwrap_devirtualization.md` (why the SecuROM sections
stay in the DRM-free exe).

## Builds and projects

| image (exemap) | file | Ghidra project |
|---|---|---|
| `pc-v10-drmfree` | `game-files/mercs2_nodrm_v3.exe` (sha256 `3a388d66…`, static, DRM-free v1.0) | `output/_ghidra_pc_v10_drmfree/proj`, `pc_v10_drmfree` |
| `pc-v10` | `output/_ghidra/securom_dump/mercs2_unpacked.exe` (v1.0 process dump) | `output/_ghidra_pc_v10/proj`, `pc_v10` |
| `pc-v11` | `output/_ghidra/securom_dump/genuine_patched_unpacked.exe` (v1.1 process dump) | `output/_ghidra_pc_v11/proj`, `pc_v11` |

Each project is a clean import with Ghidra's default auto-analysis (`scripts/ghidra_securom_import.sh`),
plus the functions `CreateMovedFunctions.java` adds (below).

## What a splice is

SecuROM replaced code in `.text` with a transfer into code it placed in its own blocks (`Stext`,
`Sitext`, `Srdata`, `Sdata`, `.securom`). `scripts/ghidra_scripts/SpliceMap.java` lists every
`.text` instruction whose direct flow target lies in those blocks and follows the code Ghidra
decodes from there (fall-through, both arms of conditional jumps, direct jumps; calls are recorded,
not entered). Export: `_exemap_exports/<image>.splices.tsv`.

| | pc-v10-drmfree | pc-v10 | pc-v11 |
|---|---|---|---|
| sites | 2,200 | 2,119 | 2,079 |
| site is a function's first instruction (`JMP dword ptr [slot]`) | 1,546 | 1,504 | 1,427 |
| outcome `moved` (every path ends in a return, an import or `.text`) | 1,178 | 1,149 | 1,233 |
| outcome `terminal` (reaches SecuROM's single entry) | 994 | 939 | 826 |
| outcome `unresolved` | 28 | 31 | 20 |
| SecuROM entry every `terminal` path reaches | `0x01aaff10` | `0x01aaff10` | `0x01b950a0` |

- **`moved`**: a game function body SecuROM moved out of `.text`. The `.text` function is one
  `JMP dword ptr [slot]` (or a jump mid-function); the code that runs is at `target`. **Patch the
  moved code at `target`, not the `.text` bytes after the jump** — those never execute.
- **`terminal`**: the code calls SecuROM's entry (Ghidra marks it non-returning). What runs after
  that is decided by SecuROM at runtime; it is not followed.
- **`unresolved`**: mostly `overlap` — the target sits inside an instruction Ghidra decoded at
  another address that something falls through into. The target bytes begin
  `68 <target+10> e8 …` (push of a return address, then a call): SecuROM's return-address idiom.
  Listed, not reconstructed.

## Moved bodies as functions

348 `moved` targets (pc-v10-drmfree) had no function in Ghidra — entered only by `JMP [slot]` —
so they had no signature and could not be matched. `CreateMovedFunctions.java` creates them
(353 created in pc-v10-drmfree, 332 in pc-v10, 378 in pc-v11; saved in the projects; per-target
log `out/moved_functions_r1.tsv`).

## The dumps differ from the DRM-free file: runtime-rewritten slots

pc-v10 (dump) and pc-v10-drmfree run the same code, yet 90 sites exist only in the DRM-free
file and 17 shared sites have a different target. For 98 of them the `[slot]` the site jumps
through holds a different value: on disk it points at the moved copy in `.securom`; in the
running SecuROM game it points back into `.text` (e.g. slot `0x0244f59c`: `0x024b7eb0` on disk,
`0x00515af6` in the dump). So the DRM-free exe runs the `.securom` copies; the protected game
can be redirected elsewhere at runtime. Checked by reading the slot's 4 bytes from both files at
`file offset = VA - 0x400000` (both layouts have raw offset = RVA).

## Reachability of SecuROM-block functions

`SecuromFunctionRefs.java` lists every reference into each function that starts in a SecuROM
block and labels it (`_exemap_exports/<image>.securom_reach.tsv`):

| reach | pc-v10-drmfree | pc-v10 | pc-v11 |
|---|---|---|---|
| `text` (referenced by a `.text` instruction) | 1,800 | 1,742 | 1,733 |
| `text-chain` (by a function that is reached) | 6 | 7 | 18 |
| `securom-only` (only by SecuROM-block code that is not reached) | 5,644 | 5,643 | 5,477 |
| `data-only` | 917 | 918 | 892 |
| `none` | 243 | 242 | 271 |

Statically, `Stext` is a closed island: ~3,100 functions per build reference each other and are
referenced from `Sdata`, but nothing in `.text` reaches them except through the SecuROM entry.
`Stext` is relocated game/CRT code (see the devirtualization study); it is presumably entered via
SecuROM's dispatcher at runtime (INFERRED — not provable statically). All of it is kept in the
exports, labelled by reach.

## Known duplicate: SecuROM's service installer

Each build carries two byte-identical copies of a routine that calls `OpenSCManagerA`,
`CreateServiceA`, `StartServiceA`, `DeleteService` (SecuROM's driver install), one in `Stext`
(`0x01c46961` in v1.0) and one in `Sdata` (`0x0232a708` in v1.0). They are not game code.
