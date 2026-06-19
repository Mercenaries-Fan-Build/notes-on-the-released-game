// Find the "add/register component" producer for the entity component container (entity+0xA0).
// The container is { table, count, cap }; entries are 8 bytes {id, ptr}. The iterator
// FUN_007E0420 reads *container (table) and container[1] (count). The producer appends an
// entry: table[count] = {id, ptr}; count++. Container mgmt clusters at 0x7E0280..0x7E0420.
// This script:
//   1. Decompiles FUN_007E0280 (container dtor) and any functions in 0x7E0280..0x7E0420.
//   2. Lists + decompiles CALLERS of FUN_007E0420 (the iterator) — they hold containers.
//   3. Lists + decompiles CALLERS of FUN_0084E3A0 (texture-component processor) — the ECS
//      construction sites that build texture components.
// Writes output/_ghidra/comp_container_add.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionIterator;
import ghidra.program.model.symbol.Reference;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;
import java.util.LinkedHashSet;
import java.util.Set;

public class CompContainerAdd extends GhidraScript {
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\comp_container_add.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private final Set<Long> done = new LinkedHashSet<>();
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileFn(Function f, String tag) {
        if (f == null) return;
        long key = f.getEntryPoint().getOffset();
        if (!done.add(key)) { w("  (dup " + f.getName() + ") " + tag); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
            w("  >>> " + f.getName() + " @" + f.getEntryPoint() + "  " + tag);
            if (res != null && res.decompileCompleted()) w(res.getDecompiledFunction().getC());
            else w("    DECOMP FAIL");
        } catch (Exception e) { w("    EXC " + e); }
    }
    private void decompileVa(long va, String tag) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("  (no fn @0x" + Long.toHexString(va) + ") " + tag); return; }
        decompileFn(f, tag);
    }
    private void callersOf(long target, String tag) {
        w("======= CALLERS of 0x" + Long.toHexString(target) + " (" + tag + ") =======");
        for (Reference r : getReferencesTo(addr(target))) {
            if (!r.getReferenceType().isCall()) continue;
            Function ff = getFunctionContaining(r.getFromAddress());
            w(String.format("  from 0x%08x  [%s]", r.getFromAddress().getOffset(),
                ff != null ? ff.getName() : "DATA"));
        }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        try {
            w("############### container mgmt 0x7E0280..0x7E0420 ###############");
            FunctionIterator it = currentProgram.getListing().getFunctions(addr(0x007E0280L), true);
            while (it.hasNext()) {
                Function f = it.next();
                if (f.getEntryPoint().getOffset() >= 0x007E0420L) break;
                decompileFn(f, "container-region");
            }
            w("");
            callersOf(0x007E0420L, "iterator");
            w("");
            callersOf(0x0084E3A0L, "tex-comp processor");
            w("");
            w("############### decompiled callers of FUN_0084E3A0 ###############");
            for (Reference r : getReferencesTo(addr(0x0084E3A0L))) {
                if (!r.getReferenceType().isCall()) continue;
                decompileVa(r.getFromAddress().getOffset(), "calls tex-comp FUN_0084E3A0");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
