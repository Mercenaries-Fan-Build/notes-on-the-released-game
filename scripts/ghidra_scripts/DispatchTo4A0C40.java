// Find what dispatches into FUN_004a0c40 (the mesh/render ECS component stream-deserializer)
// and the component TYPE HASH that routes to it. Look for:
//   - all xrefs (call + data/vtable) to 0x004a0c40
//   - decompile the code callers (the dispatcher / factory)
//   - for data refs (vtable/factory table), dump nearby table dwords to find an associated hash
// Writes output/_ghidra/dispatch_4a0c40.txt.
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

public class DispatchTo4A0C40 extends GhidraScript {
    private static final long TARGET = 0x004A0C40L;
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\dispatch_4a0c40.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private Memory mem;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileVa(long va, String tag) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ") " + tag); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
            w("  >>> " + f.getName() + " @" + f.getEntryPoint() + "  " + tag);
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("    DECOMP FAIL");
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
            w("======= XREFS to FUN_004a0c40 =======");
            for (Reference r : getReferencesTo(addr(TARGET))) {
                Address from = r.getFromAddress();
                Function ff = getFunctionContaining(from);
                w(String.format("  from 0x%08x  %s  [%s]", from.getOffset(), r.getReferenceType(),
                    ff != null ? ff.getName() : "DATA/table"));
                if (ff == null) {
                    // likely a factory/vtable table slot; dump +/- 8 dwords around it
                    long base = from.getOffset();
                    w("    table dwords around 0x" + Long.toHexString(base) + ":");
                    for (long a = base - 0x20; a <= base + 0x20; a += 4) {
                        try {
                            int v = mem.getInt(addr(a));
                            w(String.format("      0x%08x: 0x%08x", a, ((long) v) & 0xffffffffL));
                        } catch (Exception e) {}
                    }
                    // who references this table slot?
                    for (Reference vr : getReferencesTo(from)) {
                        Function vf = getFunctionContaining(vr.getFromAddress());
                        w(String.format("    table used by 0x%08x [%s]", vr.getFromAddress().getOffset(),
                            vf != null ? vf.getName() : "?"));
                    }
                }
            }
            w("");
            w("======= decompiled code callers =======");
            for (Reference r : getReferencesTo(addr(TARGET))) {
                Function ff = getFunctionContaining(r.getFromAddress());
                if (ff != null) decompileVa(r.getFromAddress().getOffset(), "caller of FUN_004a0c40");
            }
            // Also decompile users of any factory table slots
            w("");
            w("======= decompiled table users =======");
            for (Reference r : getReferencesTo(addr(TARGET))) {
                if (getFunctionContaining(r.getFromAddress()) != null) continue;
                for (Reference vr : getReferencesTo(r.getFromAddress())) {
                    Function vf = getFunctionContaining(vr.getFromAddress());
                    if (vf != null) decompileVa(vr.getFromAddress().getOffset(), "uses factory slot");
                }
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
