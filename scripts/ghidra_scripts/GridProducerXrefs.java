// Find who PRODUCES the bad grid pointer: xrefs to the grid builder/pop functions locate the grid
// class vtable + constructor + the manager-table registration that stores the (wrong) pointer.
//   0x004CBF60  grid builder (+0x7300C table)
//   0x004CC030  grid pop (vtable method) -> its DATA xref = the grid vtable
//   0x004CC130  grid vtable[0xC] method
//   0x008731F0  consumer (manager+8 per-context table)
//   0x008242B0  per-context index function
// For each: list xrefs (code callers + data refs). For data refs (vtables), list THEIR xrefs
// (constructors). Decompile the code callers of the grid builder (grid init/register sites).
// Writes output/_ghidra/grid_xrefs.txt.
//
// @category Mercs2
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.Address;
import ghidra.program.model.listing.Function;
import ghidra.program.model.symbol.Reference;
import ghidra.program.model.symbol.ReferenceManager;
import ghidra.util.task.ConsoleTaskMonitor;

import java.io.File;
import java.io.PrintWriter;

public class GridProducerXrefs extends GhidraScript {
    private static final long[] TARGETS = { 0x004CBF60L, 0x004CC030L, 0x004CC130L, 0x008731F0L, 0x008242B0L };
    private static final String OUT =
        "C:\\Users\\Shadow\\Desktop\\notes-on-the-released-game\\output\\_ghidra\\grid_xrefs.txt";
    private PrintWriter fp;
    private DecompInterface decomp;
    private ConsoleTaskMonitor mon;
    private void w(String s) { fp.println(s); }
    private Address addr(long v) {
        return currentProgram.getAddressFactory().getDefaultAddressSpace().getAddress(v);
    }
    private void decompileAt(long va) {
        Function f = getFunctionContaining(addr(va));
        if (f == null) { try { disassemble(addr(va)); f = createFunction(addr(va), null); } catch (Exception e) {} }
        if (f == null) { w("    (no function at 0x" + Long.toHexString(va) + ")"); return; }
        try {
            DecompileResults res = decomp.decompileFunction(f, 90, mon);
            if (res != null && res.decompileCompleted()) { w("    >>> " + f.getName()); w(res.getDecompiledFunction().getC()); }
            else w("    DECOMP FAIL " + f.getName());
        } catch (Exception e) { w("    EXC " + e); }
    }
    @Override
    public void run() throws Exception {
        new File(OUT).getParentFile().mkdirs();
        fp = new PrintWriter(new File(OUT), "UTF-8");
        decomp = new DecompInterface(); decomp.openProgram(currentProgram);
        mon = new ConsoleTaskMonitor();
        ReferenceManager rm = currentProgram.getReferenceManager();
        try {
            for (long t : TARGETS) {
                w("==================================================================");
                w(String.format("XREFS to 0x%08x", t));
                Reference[] refs = getReferencesTo(addr(t));
                for (Reference r : refs) {
                    Address from = r.getFromAddress();
                    Function ff = getFunctionContaining(from);
                    w(String.format("  from 0x%08x  %s  [%s]", from.getOffset(), r.getReferenceType(),
                        ff != null ? ff.getName() : "DATA/vtable?"));
                    // if the xref is from a data region (vtable), list xrefs to that data slot's owner
                    if (ff == null) {
                        Reference[] vrefs = getReferencesTo(from);
                        for (Reference vr : vrefs) {
                            Function vf = getFunctionContaining(vr.getFromAddress());
                            w(String.format("      vtable used by 0x%08x [%s]", vr.getFromAddress().getOffset(),
                                vf != null ? vf.getName() : "?"));
                        }
                    }
                }
                w("");
            }
            // decompile the code callers of the grid builder 0x4CBF60 (grid init/register)
            w("==================================================================");
            w("DECOMP: code callers of grid builder 0x004CBF60");
            for (Reference r : getReferencesTo(addr(0x004CBF60L))) {
                Function ff = getFunctionContaining(r.getFromAddress());
                if (ff != null && r.getReferenceType().isCall()) decompileAt(r.getFromAddress().getOffset());
            }
            decomp.dispose();
        } finally { fp.close(); }
        println("done");
    }
}
