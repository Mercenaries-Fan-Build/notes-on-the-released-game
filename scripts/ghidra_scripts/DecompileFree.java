// Find + decompile the custom pool allocator's free/realloc (siblings of the
// alloc FUN_0084AC20 / FUN_0084DCE0) via the shared allocator critical section
// DAT_00FF4570, and the size-class table base DAT_00DFD108. Goal: locate the
// `free` entry + its pointer argument so a minimally-perturbing inline hook can
// flag out-of-arena (garbage) frees. Writes output/_ghidra/free_decomp.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

public class DecompileFree extends GhidraScript {

    // shared allocator critical section + size-class table base
    private static final long[] ANCHORS = { 0x00FF4570L, 0x00DFD108L };
    private static final String OUT_DIR =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra";

    private PrintWriter fp;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }

    @Override
    public void run() throws Exception {
        new File(OUT_DIR).mkdirs();
        File out = new File(OUT_DIR, "free_decomp.txt");
        fp = new PrintWriter(out, "UTF-8");
        try {
            FunctionManager fm = currentProgram.getFunctionManager();
            ReferenceManager rm = currentProgram.getReferenceManager();
            DecompInterface decomp = new DecompInterface();
            decomp.openProgram(currentProgram);
            ConsoleTaskMonitor mon = new ConsoleTaskMonitor();

            w("# Mercs2 pool allocator free/realloc decompilation");
            w("# program: " + currentProgram.getName());
            w("");
            String bar = new String(new char[78]).replace("\0", "=");

            // collect every function that touches the allocator CS or table base
            Set<Long> fns = new LinkedHashSet<>();
            for (long a : ANCHORS) {
                for (Reference r : rm.getReferencesTo(addr(a))) {
                    Function cf = fm.getFunctionContaining(r.getFromAddress());
                    if (cf != null) fns.add(cf.getEntryPoint().getOffset());
                }
            }
            w(String.format("Functions referencing the allocator CS/table (%d):", fns.size()));
            for (long e : fns) {
                Function fn = fm.getFunctionContaining(addr(e));
                w(String.format("  %s @ 0x%08x  size=%d", fn.getName(), e, fn.getBody().getNumAddresses()));
            }
            w("");

            for (long e : fns) {
                Function fn = fm.getFunctionContaining(addr(e));
                w(bar);
                w(String.format("FUNCTION %s @ 0x%08x", fn.getName(), e));
                // who calls it (helps tell alloc vs free vs realloc by usage)
                int nc = 0;
                for (Reference r : rm.getReferencesTo(fn.getEntryPoint())) {
                    if (!r.getReferenceType().isCall()) continue;
                    Function cf = fm.getFunctionContaining(r.getFromAddress());
                    w(String.format("    caller 0x%08x %s", r.getFromAddress().getOffset(),
                        cf != null ? cf.getName() : "(no fn)"));
                    if (++nc >= 8) { w("    ..."); break; }
                }
                try {
                    DecompileResults res = decomp.decompileFunction(fn, 60, mon);
                    if (res != null && res.decompileCompleted()) {
                        w(""); w(res.getDecompiledFunction().getC());
                    } else {
                        w("  DECOMP FAILED: " + (res != null ? res.getErrorMessage() : "no result"));
                    }
                } catch (Exception ex) { w("  DECOMP EXC: " + ex); }
                w("");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("wrote " + out.getAbsolutePath());
    }
}
