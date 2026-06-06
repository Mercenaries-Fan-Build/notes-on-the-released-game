// Decompile the chunk-deserializer at ~0x67A8E0 (call sites 0x67A9C8/AA8F/AB2D build
// count*elemSize arrays from GetChunkDataReader 0x464780 data; one overflows the 512-byte
// class-122 pool block). Ghidra has an analysis gap here (no function defined), so we scan
// backward for the prologue (55 8B EC), create the function, decompile it, and decompile its
// callers (the chunk-type dispatch). Writes output/_ghidra/chunkparser_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileChunkParser extends GhidraScript {

    private static final long INSIDE_VA = 0x0067A9C3L;   // a call inside the target function
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    private Function ensureFunction(long insideVa) throws Exception {
        FunctionManager fm = currentProgram.getFunctionManager();
        Function f = fm.getFunctionContaining(addr(insideVa));
        if (f != null) return f;

        // Scan backward for a `push ebp; mov ebp,esp` (55 8B EC) prologue.
        Memory mem = currentProgram.getMemory();
        long e = -1;
        for (long a = insideVa; a > insideVa - 0x4000; a--) {
            try {
                if ((mem.getByte(addr(a)) & 0xff) == 0x55 &&
                    (mem.getByte(addr(a + 1)) & 0xff) == 0x8b &&
                    (mem.getByte(addr(a + 2)) & 0xff) == 0xec) { e = a; break; }
            } catch (Exception ex) { /* unmapped — keep scanning */ }
        }
        if (e < 0) { w("  could not locate prologue"); return null; }
        w(String.format("  located prologue at 0x%08x; disassembling + creating function", e));
        disassemble(addr(e));
        f = createFunction(addr(e), null);
        if (f == null) f = fm.getFunctionContaining(addr(insideVa));
        return f;
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "chunkparser_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");

            w("# Mercs2 chunk-deserializer (class-122 / 512B u32-array overflower)");
            w("# program: " + currentProgram.getName());
            w("");

            w(bar);
            w(String.format("TARGET function containing 0x%08x", INSIDE_VA));
            Function f = ensureFunction(INSIDE_VA);
            if (f == null) { w("  FAILED to define function"); fp.close(); return; }
            w("  function: " + f.getName() + "  entry=" + f.getEntryPoint()
                + "  size=" + f.getBody().getNumAddresses());

            // Callers (chunk-type dispatch).
            w("  callers:");
            int nc = 0;
            for (Reference r : rm.getReferencesTo(f.getEntryPoint())) {
                if (!r.getReferenceType().isCall()) continue;
                Function cf = fm.getFunctionContaining(r.getFromAddress());
                w(String.format("    <- 0x%08x %s", r.getFromAddress().getOffset(),
                    cf != null ? cf.getName() : "(no fn)"));
                nc++;
            }
            if (nc == 0) w("    (none found — entry may be reached indirectly)");
            w("");

            try {
                DecompileResults res = decomp.decompileFunction(f, 120, mon);
                if (res != null && res.decompileCompleted()) {
                    w(res.getDecompiledFunction().getC());
                } else {
                    w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
                }
            } catch (Exception ex) { w("  DECOMP EXC: " + ex); }
            w("");

            // Decompile direct callers too (to see the chunk-type dispatch).
            w(bar);
            w("CALLERS (chunk-type dispatch context):");
            int done = 0;
            for (Reference r : rm.getReferencesTo(f.getEntryPoint())) {
                if (!r.getReferenceType().isCall()) continue;
                Function cf = fm.getFunctionContaining(r.getFromAddress());
                if (cf == null || done >= 3) continue;
                done++;
                w(bar);
                w("CALLER " + cf.getName() + " @ " + cf.getEntryPoint());
                try {
                    DecompileResults res = decomp.decompileFunction(cf, 90, mon);
                    if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
                    else w("  DECOMP FAILED");
                } catch (Exception ex) { w("  DECOMP EXC: " + ex); }
                w("");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
