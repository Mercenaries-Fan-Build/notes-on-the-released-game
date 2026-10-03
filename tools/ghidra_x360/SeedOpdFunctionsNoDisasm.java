// preScript: seed functions from the PS3 .opd function-descriptor table WITHOUT
// pre-disassembling. Paired variant of SeedOpdFunctions.java — designed to
// escape the super-linear register-context walk that bulk DisassembleCommand
// triggers on ~40k entries (crashes with ClosedException after hours of 100%
// single-core, per the 2026-09-07 diagnosis in exe_images.json).
//
// PS3 PPU 32-bit ABI: each 8-byte .opd entry = {u32 code, u32 toc}; the first
// word is the real code entry point. Section names are stripped from the EBOOT,
// so pass (start,size) as script args (same as SeedOpdFunctions.java).
//
// Design difference from SeedOpdFunctions.java:
//   * NO bulk DisassembleCommand — that's what didn't scale.
//   * Goes through FunctionManager.createFunction() directly, NOT
//     FlatProgramAPI.createFunction() — the latter auto-triggers per-address
//     disasm, replicating the super-linear behaviour. Direct FunctionManager
//     just creates a stub function with a single-address body.
//   * The downstream auto-analyzer's flow-based passes (which DO use worker
//     pools across all cores) will expand each stub body and disassemble as
//     they walk. That parallelism gets us the throughput single-thread
//     disasm can't.
//   * NO r2/TOC paint — the RegisterValueStore blowup on 14 MB exec range is
//     what killed attempts 3-5. Decompiler won't resolve TOC-relative globals
//     as cleanly; acceptable for a first-pass baseline.
//
// args: <opdStartHex> <opdSizeHex>
//   (no tocR2, no analyze — outer -analysisTimeoutPerFile handles analysis)
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.Address;
import ghidra.program.model.address.AddressSet;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.*;
import ghidra.program.model.symbol.SourceType;

public class SeedOpdFunctionsNoDisasm extends GhidraScript {
    public void run() throws Exception {
        String[] args = getScriptArgs();
        if (args.length < 2) {
            println("USAGE: SeedOpdFunctionsNoDisasm <opdStartHex> <opdSizeHex>");
            return;
        }
        long opdStart = Long.decode(args[0]);
        long opdSize  = Long.decode(args[1]);
        Memory mem = currentProgram.getMemory();
        FunctionManager fm = currentProgram.getFunctionManager();

        long exLo = Long.MAX_VALUE, exHi = 0;
        for (MemoryBlock b : mem.getBlocks()) {
            if (b.isExecute()) {
                exLo = Math.min(exLo, b.getStart().getOffset());
                exHi = Math.max(exHi, b.getEnd().getOffset());
            }
        }
        println("SeedOpdNoDisasm: exec " + Long.toHexString(exLo) + ".."
                + Long.toHexString(exHi) + " opd " + Long.toHexString(opdStart)
                + " size " + Long.toHexString(opdSize));

        int made = 0, existed = 0, oor = 0, err = 0, walked = 0;
        for (long off = 0; off + 8 <= opdSize; off += 8) {
            if (monitor.isCancelled()) break;
            walked++;
            int code;
            try { code = mem.getInt(toAddr(opdStart + off)); }
            catch (MemoryAccessException e) { break; }
            long ca = code & 0xffffffffL;
            if (ca < exLo || ca > exHi) { oor++; continue; }
            Address ea = toAddr(ca);
            if (fm.getFunctionAt(ea) != null) { existed++; continue; }
            try {
                // Direct FunctionManager path — creates a stub function whose
                // body is just the entry-point address. Auto-analyzer will
                // grow the body via flow analysis during its normal passes.
                fm.createFunction(null, ea, new AddressSet(ea, ea),
                                  SourceType.ANALYSIS);
                made++;
            } catch (Exception e) {
                err++;
            }
            if (made > 0 && (made % 5000) == 0) {
                println("  ...stubs created: " + made + " (walked " + walked + ")");
            }
        }
        println("SeedOpdNoDisasm: made=" + made + " existed=" + existed
                + " oor=" + oor + " err=" + err + " walked=" + walked);
    }
}
