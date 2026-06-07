// The scene/world dtor FUN_007c5de0 (vtable 0x00BDF1C8) iterates an entity array
// (base param_1[6], count param_1[7], 8-byte stride) tearing down each entity+0xA0 container.
// The PRODUCER is the scene CONSTRUCTOR / ECS-node deserializer that builds that entity array and
// writes each entity's component-table entries (entity+0xA0 table[i]={id,ptr}).
// Find it: xref scene vtable 0x00BDF1C8 / 0x00BDF274, decompile code referrers (ctor + builders).
// Also xref FUN_00790170 (entity ctor/dtor) callers — the per-entity construction.
// Writes output/_ghidra/scene_loader.txt.
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

public class SceneLoaderHunt extends GhidraScript {
    private static final long[] SCENE_VT = { 0x00BDF1C8L, 0x00BDF274L };
    private static final long ENTITY_DTOR = 0x00790170L;
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\scene_loader.txt";
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
            for (long vt : SCENE_VT) {
                w(String.format("############### XREFS to scene vtable 0x%08x ###############", vt));
                for (Reference r : getReferencesTo(addr(vt))) {
                    Function ff = getFunctionContaining(r.getFromAddress());
                    w(String.format("  from 0x%08x  %s  [%s]", r.getFromAddress().getOffset(),
                        r.getReferenceType(), ff != null ? ff.getName() : "DATA"));
                }
            }
            w("");
            w("############### decompiled code referrers of scene vtables ###############");
            for (long vt : SCENE_VT) {
                for (Reference r : getReferencesTo(addr(vt))) {
                    Function ff = getFunctionContaining(r.getFromAddress());
                    if (ff != null) decompileVa(r.getFromAddress().getOffset(), "refs scene vtable 0x" + Long.toHexString(vt));
                }
            }
            w("");
            w("############### XREFS (callers) to entity (de)structor FUN_00790170 ###############");
            for (Reference r : getReferencesTo(addr(ENTITY_DTOR))) {
                Function ff = getFunctionContaining(r.getFromAddress());
                w(String.format("  from 0x%08x  %s  [%s]", r.getFromAddress().getOffset(),
                    r.getReferenceType(), ff != null ? ff.getName() : "DATA"));
            }
            w("");
            w("############### decompiled code callers of FUN_00790170 ###############");
            for (Reference r : getReferencesTo(addr(ENTITY_DTOR))) {
                if (!r.getReferenceType().isCall()) continue;
                decompileVa(r.getFromAddress().getOffset(), "calls entity (de)structor");
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
