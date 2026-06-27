# Xbox 360 PPC decompilation of the recovered game executable

Full Ghidra decompilation of the recovered **`Mercs2_Xenon_P.exe`** (Jul 11 2008 preview,
devkit **Profile** build, PowerPC/Xenon). This is the capstone of the prototype recovery: the
symbol-rich Xbox build decompiled to C, with functions named from its *own* debug strings —
the game-layer (`Pg*`/`Tt*`) detail the PC-retail pairing couldn't reach.

## Output

| Artifact | |
|---|---|
| `output/_ghidra_x360/xenon_decomp_named.c` | **12.6 MB**, **38,581 functions, 0 decompile failures**, **863 named** |
| [xbox_ppc_named_functions.md](xbox_ppc_named_functions.md) | the 863 named functions (VA · name · size) |
| `output/_ghidra_x360/xenon_decomp.c` | same, before the naming pass (all `FUN_` names) |
| `output/_ghidra_x360/proj/` | the saved Ghidra project (re-runnable for more scripts) |
| `output/_ghidra_x360/func_starts.txt` | 38,919 function entry VAs from `.pdata` |

Each function block is delimited `==== <name> @<VA>  size=<bytes> ====` then its decompiled C
(same format as the PC-retail `output/_ghidra/all_functions_decomp.txt`, so the existing tools
work on both). String literals resolve inline as `s_<name>_<addr>` references.

## How it was produced (re-runnable)

1. **Fix the image-dump PE for Ghidra** — the decompressed XEX basefile is laid out by RVA
   (file offset == RVA), but its section headers still carry the original on-disk
   `PointerToRawData`, so Ghidra's PE loader reads zeros. `tools/fix_xbox_pe_for_ghidra.py`
   rewrites each section so `PointerToRawData = VirtualAddress` →
   `output/jul08_prototype/mercs2_xenon_p.pe_ghidra.bin`.
2. **Load** with language **`PowerPC:BE:64:A2ALT-32addr`** (Xenon: PPC64 instructions, 32-bit
   addresses), image base `0x82000000`. Verified it decodes real code
   (`82170000: mfspr r12,LR`).
3. **Create functions** from the `.pdata` exception table (8-byte big-endian absolute-VA
   records) — Ghidra can't auto-parse machine 0x1F2 exceptions, so `CreateFunctions.java` seeds
   all 38,919 entry points (catches even uncalled leaf functions).
4. **Auto-analyze**, then **decompile-export** every function (`DecompileExport.java`).
5. **Name** functions two ways:
   - `NameFromStrings.java` — a `Class::Method`/CamelCase identifier string referenced by exactly
     one function is that function's own assert/registration name (458 named; +~80 from analysis).
   - `RttiNameCtors.java` — walk the build's MSVC RTTI (`tools/.../rtti_vtables.txt`, computed by a
     PE-level RTTI walk: `.?AV…@@` name → TypeDescriptor → COL → vtable). A function referencing
     exactly one class vtable is its constructor → named `<Class>_ctor`. **308 vtables labeled
     `<Class>__vftable`, 325 constructors named.** This is the Xbox-side equivalent of the PC
     vtable bridge — but done on the build's own RTTI.
   Total: **863 named functions** (the rest remain `FUN_<va>`).

Tooling: `tools/ghidra_x360/` (`fix`/`CreateFunctions`/`DecompileExport`/`NameFromStrings` +
`Validate`/`Diag`). Ghidra 12.1 at `tools/ghidra_12.1_PUBLIC` (Java scripts — PyGhidra not enabled).
Run via `analyzeHeadless.bat` with `JAVA_HOME=tools/jdk21/...` and `MAXMEM=8G`.

## Known limitation — VMX128

Xenon's **VMX128** vector instructions (128 vector regs, graphics/SIMD math) are **not** in stock
Ghidra PowerPC, so vector-heavy functions show decode gaps ("unable to resolve constructor"
warnings during analysis). Most game-logic functions are unaffected; full vector coverage would
need a VMX128 SLEIGH extension. This does not stop decompilation — all 38,581 functions still
produced C output.

## Notable named functions (sample)

- **Xbox Live / store:** `GetEntitlementByBundle`, `GetPayingStatus`, `GetPricingSelectionsByCode`
  (the monetization/entitlement layer — matches the `XONLINE` import).
- **Gameplay:** `PgSysGrapplingHook`, `GrapplingHookMessages`, `ExpireAllChunks`, `MemCheck`.
- **Debug/cheat toggles** (traffic & spawning system): `DisplayLanePops`, `RoadEndbits`,
  `LaneConnect`, `RenderLanes`, `NoSidewalkSpawn`, `NoRoadSpawn`, `SpawnTargets`,
  `RenderSpawnPoints`, `RenderFCStates`, `FreezeViewport`, `GlobalSpawning`, `MindKiller`.

## Relationship to the other docs

This completes the trio:
- [../mercs2-pdb-analysis/](../mercs2-pdb-analysis/) — *what exists and what it's called* (symbols).
- `output/_ghidra/all_functions_decomp.txt` — the **PC retail** logic (named via the cross-build
  pairing, [../mercs2-pdb-analysis/symbol-map.md](../mercs2-pdb-analysis/symbol-map.md)).
- **this** — the **Xbox Profile** logic, named from its *own* retained debug strings. Because the
  Xbox build kept the strings the PC release stripped, it directly names many `Pg*`/`Tt*`
  game-layer functions. The two decompilations cross-validate each other.

### Next refinements (optional)
- Relax the single-reference string-naming rule (with verification) to lift the count further.
- Associate functions to source modules via their `*.cpp` assert strings (gives module, not name).
- Add a VMX128 SLEIGH module for full vector decode.
