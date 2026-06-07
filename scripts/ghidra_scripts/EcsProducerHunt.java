// Find the PRODUCER that writes the bad ECS component-table entry (entity+0xA0 table[i].ptr).
// Consumer chain: FUN_00791820 -> FUN_007E0420 (iterator). Entity vtable cluster 0x00BDB410;
// (de)structor FUN_00790170; container at entity+0xA0 (= field [0x28]); container dtor FUN_007E0280.
// We want the entity CONSTRUCTOR / ECS-node deserializer that allocates the container and writes
// table[count]={id,ptr}; count++. Strategy:
//   1. Decompile FUN_00791820 (entity update) + FUN_00790170 (dtor).
//   2. xref the entity vtable 0x00BDB410 and the container dtor FUN_007E0280 and iterator
//      FUN_007E0420 -> their callers are construction/registration sites; decompile them.
// Writes output/_ghidra/ecs_producer.txt.
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

public class EcsProducerHunt extends GhidraScript {
    private static final long ENTITY_VTABLE = 0x00BDB410L;
    private static final long[] DIRECT = { 0x00791820L, 0x00790170L };
    private static final long[] XREF_TARGETS = { 0x00BDB410L, 0x007E0280L, 0x007E0420L };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\ecs_producer.txt";
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
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
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
            w("############### DIRECT ###############");
            for (long t : DIRECT) decompileVa(t, "direct");
            for (long t : XREF_TARGETS) {
                w("");
                w(String.format("############### XREFS to 0x%08x ###############", t));
                for (Reference r : getReferencesTo(addr(t))) {
                    Address from = r.getFromAddress();
                    Function ff = getFunctionContaining(from);
                    w(String.format("  from 0x%08x  %s  [%s]", from.getOffset(), r.getReferenceType(),
                        ff != null ? ff.getName() : "DATA"));
                }
            }
            w("");
            w("############### decompiled callers of FUN_007E0280 (container dtor) ###############");
            for (Reference r : getReferencesTo(addr(0x007E0280L))) {
                if (r.getReferenceType().isCall()) decompileVa(r.getFromAddress().getOffset(), "calls FUN_007E0280");
            }
            w("");
            w("############### decompiled code refs to entity vtable 0x00BDB410 ###############");
            for (Reference r : getReferencesTo(addr(ENTITY_VTABLE))) {
                Function ff = getFunctionContaining(r.getFromAddress());
                if (ff != null) decompileVa(r.getFromAddress().getOffset(), "refs entity vtable");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
