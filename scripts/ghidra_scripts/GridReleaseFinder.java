// Find the PRODUCER that pushes a (wrong) pointer into the static grid pool free-list.
// The grid is a STATIC global built by FUN_004cbef0:
//   base      = 0x016568b0  (vtable ptr @+0 -> PTR_FUN_00bb1090)
//   cells     = 0x016608bc  (0x1400 * 0x54 bytes)
//   table     = 0x016c98bc  (base+0x7300c) free-list slots
//   count     = 0x016ce8c0  (base+0x78010)
//   capacity  = 0x016ce8c4  (base+0x78014) = 0x1400
//   sentinel  = 0x016ce8bc  (base+0x7800c) = 0
// Pop = FUN_004cc030 (vtbl+0x1c). We want the PUSH/release: writers of count 0x016ce8c0
// and the table 0x016c98bc. Dump the vtable (32 entries) and decompile every function that
// references the static count, the table base, or the grid base.
// Writes output/_ghidra/grid_release.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

public class GridReleaseFinder extends GhidraScript {
    private static final long VTABLE = 0x00bb1090L;
    private static final long GRID_BASE = 0x016568b0L;
    private static final long GRID_COUNT = 0x016ce8c0L;
    private static final long GRID_TABLE = 0x016c98bcL;
    private static final long GRID_CAP = 0x016ce8c4L;
    private static final long[] PROBE = { GRID_COUNT, GRID_TABLE, GRID_BASE, GRID_CAP };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\grid_release.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private Memory mem;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileFn(Function f) {
        if (f == null) { w("    (null fn)"); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
            if (res != null && res.decompileCompleted()) { w("    >>> " + f.getName() + " @" + f.getEntryPoint()); w(res.getDecompiledFunction().getC()); }
            else w("    DECOMP FAIL " + f.getName());
        } catch (Exception e) { w("    EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        mem = currentProgram.getMemory();
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            // 1. Dump the vtable (32 dwords)
            w("================= GRID VTABLE @0x00bb1090 =================");
            for (int i = 0; i < 32; i++) {
                long slot = VTABLE + i * 4;
                int v;
                try { v = mem.getInt(addr(slot)); } catch (Exception e) { break; }
                long fn = ((long) v) & 0xffffffffL;
                Function f = getFunctionContaining(addr(fn));
                w(String.format("  vtbl[+0x%02x] @0x%08x -> 0x%08x  %s", i * 4, slot, fn,
                    f != null ? f.getName() : "?"));
            }
            w("");
            // 2. For each static field, list referrers and collect functions to decompile
            Set<Function> toDecomp = new LinkedHashSet<>();
            for (long p : PROBE) {
                w(String.format("================= REFS to 0x%08x =================", p));
                Reference[] refs = getReferencesTo(addr(p));
                for (Reference r : refs) {
                    Address from = r.getFromAddress();
                    Function ff = getFunctionContaining(from);
                    w(String.format("  from 0x%08x  %s  [%s]", from.getOffset(), r.getReferenceType(),
                        ff != null ? ff.getName() : "DATA"));
                    if (ff != null) toDecomp.add(ff);
                }
                w("");
            }
            // 3. Decompile each referencing function once
            w("================= DECOMPILED REFERRERS =================");
            for (Function f : toDecomp) {
                w("------------------------------------------------------------");
                decompileFn(f);
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
