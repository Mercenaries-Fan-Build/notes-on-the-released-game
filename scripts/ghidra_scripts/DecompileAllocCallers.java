// Decompile the OTHER class-122 (512-byte) allocation callers seen in poolguard's per-class
// history (besides the chunk parser 0x67A7FA): 0x85BFB0, 0x471B4A, 0x632692. One of these is
// the real overflower (allocator of `below`). Ghidra has analysis gaps, so scan back for the
// prologue, create the function, decompile. Writes output/_ghidra/alloc_callers_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.mem.Memory;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class DecompileAllocCallers extends GhidraScript {

    private static final long[] INSIDE = { 0x0085BFB0L, 0x00471B4AL, 0x00632692L };
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
        Memory mem = currentProgram.getMemory();
        long e = -1;
        for (long a = insideVa; a > insideVa - 0x4000; a--) {
            try {
                if ((mem.getByte(addr(a)) & 0xff) == 0x55 &&
                    (mem.getByte(addr(a + 1)) & 0xff) == 0x8b &&
                    (mem.getByte(addr(a + 2)) & 0xff) == 0xec) { e = a; break; }
            } catch (Exception ex) { }
        }
        if (e < 0) return null;
        w(String.format("  (prologue at 0x%08x)", e));
        disassemble(addr(e));
        f = createFunction(addr(e), null);
        if (f == null) f = fm.getFunctionContaining(addr(insideVa));
        return f;
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "alloc_callers_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
            String bar = new String(new char[78]).replace("\0", "=");

            w("# Mercs2 other class-122 (512B) allocation callers");
            w("# program: " + currentProgram.getName());
            w("");
            for (long va : INSIDE) {
                w(bar);
                w(String.format("CALLER SITE 0x%08x", va));
                Function f = ensureFunction(va);
                if (f == null) { w("  (could not define function)"); w(""); continue; }
                w("  function: " + f.getName() + "  entry=" + f.getEntryPoint()
                    + "  size=" + f.getBody().getNumAddresses());
                try {
                    DecompileResults res = decomp.decompileFunction(f, 90, mon);
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
