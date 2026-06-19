// Find the component-container "add" function (writer of entity+0xA0 {table,count,cap}; entries
// 8B {id,ptr}) and the per-node component deserializer. Approach:
//   1. Decompile the whole 0x7E0xxx container family (0x7E0420 iterator + neighbours 0x7E0480..0x7E0780)
//      to find the push/add (grows count, writes table[count]={id,ptr}).
//   2. Decompile FUN_00875fd0 (per-node type dispatcher driven by FUN_004bf8c0's type-ordered passes).
//   3. Decompile the worldentity/ECS-node component build: callers of FUN_004cae80(returns 0x5647c35d)
//      and FUN_004cbc90(returns 0x140e8728) and FUN_0045e480(returns 0xe6b81a54) — these getters are
//      used as type tags; their callers are the entity/component constructors.
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

public class CompAddWriter extends GhidraScript {
    private static final long[] DIRECT = {
        0x007E0420L, 0x007E0480L, 0x007E04E0L, 0x007E0540L, 0x007E05A0L,
        0x007E0600L, 0x007E0660L, 0x007E06C0L, 0x007E0730L, 0x007E0780L,
        0x00875FD0L
    };
    private static final long[] XREF_GETTERS = { 0x004CAE80L, 0x004CBC90L, 0x0045E480L };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\comp_add_writer.txt";
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
            w("############### container family + node dispatcher ###############");
            for (long t : DIRECT) decompileVa(t, "direct");
            for (long g : XREF_GETTERS) {
                w("");
                w(String.format("############### callers of getter 0x%08x ###############", g));
                for (Reference r : getReferencesTo(addr(g))) {
                    if (!r.getReferenceType().isCall()) continue;
                    decompileVa(r.getFromAddress().getOffset(), "calls getter 0x" + Long.toHexString(g));
                }
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
