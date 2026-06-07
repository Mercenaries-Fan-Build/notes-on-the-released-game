// FUN_007e0780 is the component-container insert: writes table[i]={id=*param_1, ptr=param_1[1]}.
// Find its callers (the component-registration sites) and decompile them, plus callers-of-callers
// where needed, to reach the ECS-node loader that supplies the component ptr. Also decompile the
// scene populator: any function that WRITES scene+0x18 (param_1[6], entity array base) and +0x1C.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

public class AddCompCallers extends GhidraScript {
    private static final long ADD = 0x007E0780L;
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\add_comp_callers.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileVa(long va, String tag) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ") " + tag); return; }
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 120, mon);
            w("  >>> " + f.getName() + " @" + f.getEntryPoint() + "  " + tag);
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("    DECOMP FAIL");
        } catch (Exception e) { w("    EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            w("############### XREFS to FUN_007E0780 (component insert) ###############");
            Set<Long> callers = new LinkedHashSet<>();
            for (Reference r : getReferencesTo(addr(ADD))) {
                Function ff = getFunctionContaining(r.getFromAddress());
                w(String.format("  from 0x%08x  %s  [%s]", r.getFromAddress().getOffset(),
                    r.getReferenceType(), ff != null ? ff.getName() : "DATA"));
                if (r.getReferenceType().isCall() && ff != null) callers.add(r.getFromAddress().getOffset());
            }
            w("");
            w("############### decompiled callers ###############");
            for (long c : callers) decompileVa(c, "calls FUN_007E0780");
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
